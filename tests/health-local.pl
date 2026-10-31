#!/usr/bin/env perl
# Exercises the shipped health command, storage command and systemd Make targets without systemd mutation or fake JVMs.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use IO::Select;
use Pod::Usage qw(pod2usage);
use POSIX ();
use Test::More;

=head1 NAME

health-local.pl - run the shipped health, storage and systemd Make paths in isolated workspaces

=head1 SYNOPSIS

  perl tests/health-local.pl [--case NAME]...
  perl tests/health-local.pl --help

=head1 DESCRIPTION

Runs an unchanged copy of scripts/archappl.bash under the real health, status, storage and help commands against
configuration files, PID files, real unrelated processes and a real zombie, and runs the shipped Make targets that
render and install the systemd units, the site templates, the Tomcat paths and ports and the storage ownership. Each
case works in its own archappl-health-* or archappl-units-* workspace under TMPDIR. A workspace of a failed case, or of
every case when KEEP_WORKSPACE=1, is kept and its path printed.

The cases that need a real Java executable, the JDK compiler, systemd-analyze or /dev/shm report a skip when it is
absent; the cases that need a non-root account report a skip for root. Every skip prints a line that starts with
C<SKIP:>. The checkout must be a Git work tree.
Required programs: bash, make, git, df, sleep, xmllint and the Perl module Test::More (on Rocky Linux the package
perl-Test-Simple).

=head1 OPTIONS

=over 4

=item B<--case> NAME

Run only the named case; repeat the option for more. Without the option every case runs. The names are:

  configuration_errors_and_privacy
  unreadable_configuration
  missing_pid_files
  launcher_help_names_supported_restart_command
  status_reports_missing_and_unrelated_processes
  storage_preserves_literal_paths_and_failure_status
  invalid_pid_files_are_preserved
  absent_process
  real_unrelated_process_is_not_signalled
  unrelated_java_with_tomcat_application_arguments
  pid_symlink_target_ancestor_permission_error
  inspection_error_takes_precedence
  nonregular_pid_file_does_not_block
  real_zombie_is_rejected
  invalid_cli
  real_file_install_default_and_alternate
  site_timing_overrides
  local_path_overrides
  local_tomcat_paths_and_ports
  external_storage_ownership_and_health
  explicit_derived_path_overrides
  sql_drop_backend_guard
  full_install_and_monitor_removal_command_order

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when every case passed or was skipped, nonzero when an assertion failed or the run aborted, 2 for a usage error.

=cut

my $TOP = abs_path(dirname(abs_path($0)) . '/..');
my @SERVICES = qw(mgmt engine etl retrieval);
my $capture_dir;
my $capture_count = 0;
my @workspaces;
my @cleanup;

$| = 1;

sub slurp {
    my ($path) = @_;
    open(my $handle, '<:raw', $path) or die "open $path: $!\n";
    local $/;
    my $data = <$handle>;
    close($handle) or die "close $path: $!\n";
    return $data // '';
}

sub spew {
    my ($path, $data) = @_;
    open(my $handle, '>:raw', $path) or die "open $path: $!\n";
    print {$handle} $data or die "write $path: $!\n";
    close($handle) or die "close $path: $!\n";
    return;
}

sub append_log {
    my ($path, $text) = @_;
    open(my $handle, '>>', $path) or die "open $path: $!\n";
    print {$handle} $text or die "write $path: $!\n";
    close($handle) or die "close $path: $!\n";
    return;
}

sub copy_file {
    my ($from, $to) = @_;
    copy($from, $to) or die "copy $from to $to: $!\n";
    return;
}

sub trim {
    my ($text) = @_;
    $text =~ s/\A\s+//;
    $text =~ s/\s+\z//;
    return $text;
}

sub which {
    my ($name) = @_;
    for my $directory (split /:/, $ENV{PATH} // '') {
        next if $directory eq '';
        return "$directory/$name" if -f "$directory/$name" && -x _;
    }
    return;
}

sub shell_quote {
    my ($text) = @_;
    $text =~ s/'/'\\''/g;
    return "'$text'";
}

sub count_substring {
    my ($text, $needle) = @_;
    my $count = 0;
    my $at = 0;
    while (($at = index($text, $needle, $at)) >= 0) {
        $count++;
        $at += length $needle;
    }
    return $count;
}

# Registers an action that runs, newest first, when the current case ends.
sub on_cleanup {
    my ($action) = @_;
    push @cleanup, $action;
    return;
}

# Creates a workspace under TMPDIR that is removed after a passing case.
sub workspace {
    my ($prefix) = @_;
    my $path = tempdir($prefix . 'XXXXXX', TMPDIR => 1);
    push @workspaces, $path;
    return $path;
}

# Runs one command without a shell. Returns status (a signal reads as 128 plus its number; -1 after a timeout),
# stdout and stderr in a hash.
sub run_command {
    my ($command, %option) = @_;
    my $timeout = $option{timeout} // 8;
    my $id = ++$capture_count;
    my ($out_path, $err_path) = ("$capture_dir/out.$id", "$capture_dir/err.$id");
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        if (defined $option{cwd}) {
            chdir($option{cwd}) or POSIX::_exit(126);
        }
        %ENV = %{ $option{env} } if $option{env};
        open(STDIN, '<', '/dev/null') or POSIX::_exit(126);
        open(STDOUT, '>', $out_path) or POSIX::_exit(126);
        open(STDERR, '>', $err_path) or POSIX::_exit(126);
        exec { $command->[0] } @{$command} or POSIX::_exit(127);
    }
    my ($raw, $timed_out);
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $timeout;
        waitpid($pid, 0);
        $raw = $?;
        alarm 0;
        1;
    } or do {
        my $error = $@;
        alarm 0;
        die $error if $error ne "timeout\n";
        kill('KILL', $pid);
        waitpid($pid, 0);
        $raw = $?;
        $timed_out = 1;
    };
    my $status = $timed_out ? -1 : ($raw & 127) ? 128 + ($raw & 127) : $raw >> 8;
    return {
        status => $status,
        stdout => slurp($out_path),
        stderr => slurp($err_path),
    };
}

sub combined {
    my ($run) = @_;
    return $run->{stdout} . $run->{stderr};
}

# Starts a long-lived child that must stay unsignalled; it is terminated and reaped when the case ends.
sub start_sleeper {
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        exec { 'sleep' } 'sleep', '60' or POSIX::_exit(127);
    }
    on_cleanup(sub { kill('TERM', $pid); waitpid($pid, 0); });
    return $pid;
}

sub is_running {
    my ($pid) = @_;
    return waitpid($pid, POSIX::WNOHANG()) == 0;
}

# Runs one case: a fresh case-level cleanup list, and a workspace kept when the case failed or KEEP_WORKSPACE=1.
sub run_case {
    my ($name, $body) = @_;
    my $builder = Test::More->builder;
    my $failed_before = grep { !$_ } $builder->summary;
    @cleanup = ();
    @workspaces = ();
    subtest $name => sub {
        my $ok = eval { $body->(); 1 };
        my $error = $@;
        die $error if ref $error && ref $error eq 'Test::Builder::Exception';
        ok($ok, "$name completed without an internal error") or diag($error);
    };
    $_->() for reverse @cleanup;
    @cleanup = ();
    my $failed_after = grep { !$_ } $builder->summary;
    for my $path (@workspaces) {
        if ($failed_after > $failed_before || ($ENV{KEEP_WORKSPACE} // '') eq '1') {
            print "Workspace retained: $path\n";
        }
        else {
            remove_tree($path);
        }
    }
    return;
}

# Skips the rest of the current subtest; the SKIP: line is the form that the VM driver refuses as a complete run.
sub skip_case {
    my ($reason) = @_;
    print "SKIP: $reason\n";
    plan skip_all => $reason;
    return;
}

# ---------------------------------------------------------------------------------------------------------------------
# Health cases: an unchanged copy of the launcher runs in a workspace with the four service directories.
# ---------------------------------------------------------------------------------------------------------------------

my ($ROOT, $LAUNCHER, $CONFIG);

sub health_setup {
    $ROOT = workspace('archappl-health-');
    $LAUNCHER = "$ROOT/archappl.bash";
    copy_file("$TOP/scripts/archappl.bash", $LAUNCHER);
    copy_file("$TOP/scripts/archappl-config.bash", "$ROOT/archappl-config.bash");
    make_path("$ROOT/$_/temp") for @SERVICES;
    $CONFIG = "$ROOT/archappl.conf";
    return;
}

# Writes a store-bearing configuration with the real Java; returns false when no Java is installed.
sub configure {
    my $java = which('java');
    return 0 unless defined $java;
    my $java_home = dirname(dirname(abs_path($java)));
    # An installed archappl.conf always names the store; a 100 percent threshold keeps these instance checks
    # independent of the host's disk usage.
    spew($CONFIG, qq{JAVA_HOME="$java_home"\nCATALINA_HOME="$ROOT"\n}
        . qq{ARCHAPPL_STORAGE_TOP="$ROOT"\nARCHAPPL_STORAGE_ALARM_PERCENT=100\n});
    return 1;
}

sub require_java {
    configure() or skip_case('A real installed Java executable is required for PID-path tests');
    return;
}

sub pid_file {
    my ($name, $value) = @_;
    my $path = "$ROOT/$name/temp/$name.pid";
    spew($path, $value);
    return $path;
}

sub health {
    my ($expected, @args) = @_;
    my $run = run_command(['bash', $LAUNCHER, 'health', @args]);
    append_log("$ROOT/run.log", "exit=$run->{status}\n" . combined($run));
    is($run->{status}, $expected, "health @args exits $expected") or diag(combined($run));
    unlike($run->{stdout}, qr/ PRESENT /, 'health reports no PRESENT line');
    return combined($run);
}

sub all_reported {
    my ($output) = @_;
    for my $name (@SERVICES) {
        my $count = grep { index($_, "$name pid=") == 0 } split /\n/, $output;
        is($count, 1, "$name reported once");
    }
    return;
}

sub case_configuration_errors_and_privacy {
    health_setup();
    for my $value (undef, '', qq{JAVA_HOME="PRIVATE_CONFIG_CONTENT\n}, "false\n") {
        my $label = defined $value ? "config '" . ($value =~ s/\n/\\n/gr) . "'" : 'no config file';
        spew($CONFIG, $value) if defined $value;
        my $output = health(2);
        all_reported($output);
        like($output, qr/health ERROR/, "$label: health ERROR");
        unlike($output, qr/PRIVATE_CONFIG_CONTENT/, "$label: configuration content is not echoed");
    }
    return;
}

sub case_unreadable_configuration {
    skip_case('Permission denial requires a non-root test account') if $> == 0;
    health_setup();
    require_java();
    chmod(0, $CONFIG) or die "chmod $CONFIG: $!\n";
    on_cleanup(sub { chmod(0600, $CONFIG) });
    all_reported(health(2));
    return;
}

sub case_missing_pid_files {
    health_setup();
    require_java();
    my $output = health(1);
    all_reported($output);
    is(count_substring($output, 'missing-pid-file'), 4, 'four missing-pid-file reports');
    return;
}

sub case_launcher_help_names_supported_restart_command {
    health_setup();
    require_java();
    my $run = run_command(['bash', $LAUNCHER, 'help']);
    is($run->{status}, 1, 'help exits 1') or diag(combined($run));
    like($run->{stderr}, qr/restart/, 'help names restart');
    unlike($run->{stderr}, qr/restartup/, 'help does not name restartup');
    return;
}

sub case_status_reports_missing_and_unrelated_processes {
    health_setup();
    require_java();
    my $child = start_sleeper();
    for my $populated (0, 1) {
        my $label = $populated ? 'unrelated process' : 'empty PID files';
        if ($populated) {
            pid_file($_, "$child\n") for @SERVICES;
        }
        my $run = run_command(['bash', $LAUNCHER, 'status']);
        is($run->{status}, 1, "$label: status exits 1") or diag(combined($run));
        all_reported($run->{stdout});
        my $reason = $populated ? 'wrong-java-executable' : 'missing-pid-file';
        is(count_substring($run->{stdout}, $reason), 4, "$label: four $reason reports");
        unlike($run->{stdout}, qr/exists\./, "$label: no exists. text");
        unlike($run->{stdout}, qr/ PRESENT verified-process-presence/, "$label: no verified presence");
        ok(is_running($child), "$label: the unrelated process is still running");
    }
    return;
}

sub case_storage_preserves_literal_paths_and_failure_status {
    health_setup();
    my $store = "$ROOT/store\$(touch STORAGE_EVALUATED)`touch STORAGE_BACKTICK`";
    make_path($store);
    spew("$store/sample", "sample\n");
    spew($CONFIG, 'ARCHAPPL_STORAGE_TOP=' . shell_quote($store) . "\n");
    my $boundary = "$ROOT/boundary";
    make_path($boundary);
    # Only privilege transport is replaced; the shipped launcher and real du run.
    spew("$boundary/sudo", qq{#!/bin/bash\n[[ "\$1" == -- && "\$2" == du ]] || exit 2\nshift\nexec "\$@"\n});
    chmod(0700, "$boundary/sudo") or die "chmod: $!\n";
    my %env = (%ENV, PATH => "$boundary:$ENV{PATH}");
    for my $option ([], ['all']) {
        my $run = run_command(['bash', $LAUNCHER, 'storage', @{$option}], cwd => $ROOT, env => \%env);
        is($run->{status}, 0, "storage @{$option} exits 0") or diag(combined($run));
        my $name = (split m{/}, $store)[-1];
        ok(index($run->{stdout}, $name) >= 0, "storage @{$option} reports the literal path");
        ok(!-e "$ROOT/STORAGE_EVALUATED", "storage @{$option} did not evaluate the command substitution");
        ok(!-e "$ROOT/STORAGE_BACKTICK", "storage @{$option} did not evaluate the backticks");
    }
    spew($CONFIG, 'ARCHAPPL_STORAGE_TOP=' . shell_quote("$ROOT/absent") . "\n");
    my $run = run_command(['bash', $LAUNCHER, 'storage'], cwd => $ROOT, env => \%env);
    isnt($run->{status}, 0, 'storage of an absent store fails') or diag(combined($run));
    return;
}

sub case_invalid_pid_files_are_preserved {
    health_setup();
    require_java();
    for my $value ('', "0\n", "-1\n", "1 2\n", "1\n2\n", "1\0", '9' x 64, "text\n") {
        my $label = 'PID value ' . join('', map { sprintf('%s', ord($_) < 32 || ord($_) > 126 ? sprintf('\\x%02x', ord $_) : $_) } split //, $value);
        my @paths = map { pid_file($_, $value) } @SERVICES;
        my $output = health(1);
        all_reported($output);
        is(count_substring($output, 'invalid-pid-file'), 4, "$label: four invalid-pid-file reports");
        is(slurp($_), $value, "$label: PID file preserved") for @paths;
    }
    return;
}

sub case_absent_process {
    health_setup();
    require_java();
    my $unused = 2147483647;
    ok(!-e "/proc/$unused", 'the chosen PID is not in use');
    pid_file($_, "$unused\n") for @SERVICES;
    my $output = health(1);
    all_reported($output);
    is(count_substring($output, 'missing-process'), 4, 'four missing-process reports');
    return;
}

sub case_real_unrelated_process_is_not_signalled {
    health_setup();
    require_java();
    my $child = start_sleeper();
    my $value = "$child\n";
    my @paths = map { pid_file($_, $value) } @SERVICES;
    my $output = health(1);
    all_reported($output);
    is(count_substring($output, 'wrong-java-executable'), 4, 'four wrong-java-executable reports');
    ok(is_running($child), 'the unrelated process is still running');
    is(slurp($_), $value, 'PID file preserved') for @paths;
    return;
}

# Starts a real JVM whose stdout is a pipe; returns its PID and the read end.
sub start_jvm {
    my (@command) = @_;
    pipe(my $reader, my $writer) or die "pipe: $!\n";
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        close($reader);
        open(STDIN, '<', '/dev/null') or POSIX::_exit(126);
        open(STDOUT, '>&', $writer) or POSIX::_exit(126);
        open(STDERR, '>', "$ROOT/jvm.err") or POSIX::_exit(126);
        exec { $command[0] } @command or POSIX::_exit(127);
    }
    close($writer);
    return ($pid, $reader);
}

sub case_unrelated_java_with_tomcat_application_arguments {
    health_setup();
    require_java();
    my $java = abs_path(which('java'));
    my $javac = dirname($java) . '/javac';
    skip_case('The installed JDK compiler is required for the unrelated JVM test') unless -f $javac;
    my $build = run_command([$javac, '-d', $ROOT, "$TOP/tests/fixtures/UnrelatedJava.java"], timeout => 15);
    is($build->{status}, 0, 'the fixture compiles') or diag(combined($build));
    my @properties = ("-Dcatalina.base=$ROOT/mgmt", "-Dcatalina.home=$ROOT");
    for my $vm_properties (0, 1) {
        my $label = $vm_properties ? 'Tomcat properties as VM options' : 'Tomcat properties as application arguments';
        my @command = ($java, '-cp', $ROOT);
        push @command, $vm_properties ? (@properties, 'UnrelatedJava') : ('UnrelatedJava', @properties);
        push @command, 'org.apache.catalina.startup.Bootstrap', 'start';
        my ($pid, $reader) = start_jvm(@command);
        my $ready = IO::Select->new($reader)->can_read(5);
        ok($ready, "$label: JVM readiness output") or diag('No JVM readiness output');
        my $line = $ready ? <$reader> : undef;
        is($line, "ready\n", "$label: JVM reports ready");
        my $value = "$pid\n";
        my $path = pid_file('mgmt', $value);
        my $output = health(1);
        ok(index($output, "mgmt pid=$pid FAIL wrong-tomcat-identity") >= 0, "$label: wrong-tomcat-identity reported");
        ok(is_running($pid), "$label: the JVM is still running");
        is(slurp($path), $value, "$label: PID file preserved");
        kill('TERM', $pid);
        waitpid($pid, 0);
        close($reader);
    }
    return;
}

sub case_pid_symlink_target_ancestor_permission_error {
    skip_case('Permission denial requires a non-root test account') if $> == 0;
    health_setup();
    require_java();
    my $denied = "$ROOT/denied";
    my $target = "$denied/nested";
    make_path($target);
    spew("$target/mgmt.pid", "1\n");
    rmdir("$ROOT/mgmt/temp") or die "rmdir: $!\n";
    symlink($target, "$ROOT/mgmt/temp") or die "symlink: $!\n";
    chmod(0, $denied) or die "chmod $denied: $!\n";
    on_cleanup(sub { chmod(0700, $denied) });
    my $output = health(2);
    all_reported($output);
    like($output, qr/mgmt pid=- ERROR/, 'mgmt reports ERROR for the denied ancestor');
    return;
}

sub case_inspection_error_takes_precedence {
    skip_case('Permission denial requires a non-root test account') if $> == 0;
    health_setup();
    require_java();
    my $path = pid_file('engine', "1\n");
    chmod(0, $path) or die "chmod $path: $!\n";
    on_cleanup(sub { chmod(0600, $path) });
    my $output = health(2);
    all_reported($output);
    ok(index($output, 'engine pid=- ERROR unreadable-pid-file') >= 0, 'engine reports unreadable-pid-file');
    ok(index($output, 'mgmt pid=- FAIL missing-pid-file') >= 0, 'mgmt still reports missing-pid-file');
    return;
}

sub case_nonregular_pid_file_does_not_block {
    health_setup();
    require_java();
    POSIX::mkfifo("$ROOT/engine/temp/engine.pid", 0600) or die "mkfifo: $!\n";
    all_reported(health(2));
    return;
}

sub case_real_zombie_is_rejected {
    health_setup();
    require_java();
    my $child = fork();
    defined $child or die "fork: $!\n";
    POSIX::_exit(0) if !$child;
    on_cleanup(sub { waitpid($child, 0) });
    # The child is left unreaped until it shows state Z, so the launcher sees a real zombie.
    my $zombie = 0;
    for (1 .. 100) {
        my $stat = -r "/proc/$child/stat" ? slurp("/proc/$child/stat") : '';
        my $at = rindex($stat, ')');
        if ($at >= 0 && substr($stat, $at + 2, 1) eq 'Z') {
            $zombie = 1;
            last;
        }
        select(undef, undef, undef, 0.05);
    }
    ok($zombie, 'the child is a zombie');
    pid_file('mgmt', "$child\n");
    my $output = health(1);
    ok(index($output, "mgmt pid=$child FAIL dead-process") >= 0, 'the zombie is reported as dead-process');
    return;
}

sub case_invalid_cli {
    health_setup();
    like(health(2, 'unexpected'), qr/invalid-arguments/, 'an unexpected argument is rejected');
    like(health(2, '--systemd', 'bad/name', 'health.service', '60'), qr/invalid-arguments/,
        'an invalid systemd instance name is rejected');
    return;
}

# ---------------------------------------------------------------------------------------------------------------------
# Systemd and Make cases: a copy of the tracked and untracked-unignored checkout files in a workspace.
# ---------------------------------------------------------------------------------------------------------------------

my ($TEMP, $CHECKOUT, $UNITS);

sub units_setup {
    $TEMP = workspace('archappl-units-');
    $CHECKOUT = "$TEMP/checkout";
    make_path($CHECKOUT);
    my $list = run_command(['git', '-C', $TOP, 'ls-files', '-z', '--cached', '--others', '--exclude-standard']);
    die "git ls-files failed: $list->{stderr}\n" if $list->{status} != 0;
    for my $item (split /\0/, $list->{stdout}) {
        next if $item eq '' || !-f "$TOP/$item";
        next unless $item eq 'Makefile' || $item =~ m{\A(?:configure|site-template|scripts)/};
        make_path(dirname("$CHECKOUT/$item"));
        copy_file("$TOP/$item", "$CHECKOUT/$item");
    }
    $UNITS = "$TEMP/units";
    return;
}

# Runs the shipped Make target in the copy; the run must exit 0 and its stdout is returned.
sub make {
    my (@args) = @_;
    my $run = run_command(
        ['make', '--no-print-directory', '-C', $CHECKOUT, @args, 'SUDO=', "SYSTEMD_PATH=$UNITS"],
        timeout => 30);
    append_log("$TEMP/run.log", "exit=$run->{status}\n" . combined($run));
    is($run->{status}, 0, "make @args exits 0") or diag(combined($run));
    return $run->{stdout};
}

# Value of an XPath string expression over an XML file.
sub xml_string {
    my ($file, $expression) = @_;
    my $run = run_command(['xmllint', '--xpath', "string($expression)", $file]);
    ok($run->{status} == 0, "xmllint reads $expression of $file") or diag(combined($run));
    (my $value = $run->{stdout}) =~ s/\n\z//;
    return $value;
}

sub require_xmllint {
    defined which('xmllint') or die "xmllint is required to read the generated XML files\n";
    return;
}

sub case_real_file_install_default_and_alternate {
    units_setup();
    for my $set (['-j1', '/opt/epicsarchiverap-maven', 'tomcat'], ['-j8', '/srv/aa-test', 'aa-test']) {
        my ($jobs, $install, $user) = @{$set};
        # The shipped global .NOTPARALLEL remains in force in both runs. conf.systemd renders the units that
        # conf.install renders, without its record of the source commit, which needs the source clone;
        # install.systemd installs the rendered files and renders nothing itself.
        my @site = ("AA_INSTALL_LOCATION=$install", "AA_USERID=$user", "AA_GROUPID=$user");
        make($jobs, 'conf.systemd', @site);
        make($jobs, 'install.systemd', @site);
        for my $name ('epicsarchiverap-maven.service', 'epicsarchiverap-maven-health.service',
            'epicsarchiverap-maven-health.timer', 'tomcat9.service.d/override.conf') {
            my $path = "$UNITS/$name";
            is((stat $path)[2] & 0777, 0644, "$jobs $name has mode 0644");
            unlike(slurp($path), qr/\@[A-Z_]+\@/, "$jobs $name has no unrendered placeholder");
        }
        my $service = slurp("$UNITS/epicsarchiverap-maven-health.service");
        my $timer = slurp("$UNITS/epicsarchiverap-maven-health.timer");
        ok(index($service, qq{"$install/archappl.bash" health --systemd}) >= 0, "$jobs service runs the health command");
        ok(index($service, "User=$user\n") >= 0, "$jobs service user");
        ok(index($service, "TimeoutStartSec=5s\n") >= 0, "$jobs TimeoutStartSec");
        ok(index($service, "TimeoutStopSec=1s\n") >= 0, "$jobs TimeoutStopSec");
        ok(index($service, "SuccessExitStatus=3\n") >= 0, "$jobs SuccessExitStatus");
        ok(index($service, "StartLimitIntervalSec=0\n") >= 0, "$jobs StartLimitIntervalSec");
        ok(index($timer, "OnUnitInactiveSec=30s\n") >= 0, "$jobs OnUnitInactiveSec");
        ok(index($timer, "AccuracySec=1s\n") >= 0, "$jobs AccuracySec");
        ok(index($timer, "WantedBy=timers.target epicsarchiverap-maven.service\n") >= 0, "$jobs WantedBy");
        for my $directive ('Requires=', 'BindsTo=', 'PartOf=', 'OnFailure=', 'Restart=', 'ExecStop=') {
            ok(index($service . $timer, $directive) < 0, "$jobs units do not contain $directive");
        }
        if (which('systemd-analyze')) {
            my $verify = run_command(['systemd-analyze', 'verify', "$UNITS/epicsarchiverap-maven-health.service",
                "$UNITS/epicsarchiverap-maven-health.timer"], timeout => 20);
            is($verify->{status}, 0, "$jobs systemd-analyze verify") or diag(combined($verify));
        }
    }
    return;
}

sub case_site_timing_overrides {
    units_setup();
    spew("$TEMP/CONFIG_SITE.local", "SYSTEMD_HEALTH_STARTUP_SECONDS=90\nSYSTEMD_HEALTH_INTERVAL_SECONDS=20\n");
    make('conf.health.service', 'conf.health.timer');
    make('install.health.service', 'install.health.timer');
    ok(index(slurp("$UNITS/epicsarchiverap-maven-health.service"), ".service 90\n") >= 0, 'startup seconds applied');
    ok(index(slurp("$UNITS/epicsarchiverap-maven-health.timer"), "OnUnitInactiveSec=20s\n") >= 0,
        'interval seconds applied');
    return;
}

sub case_local_path_overrides {
    units_setup();
    # Move the shipped templates so a stale default cannot supply the inputs.
    my $templates = "$TEMP/templates";
    rename("$CHECKOUT/site-template", $templates) or die "rename: $!\n";
    my $store = "$TEMP/archive";
    for my $local ("$TEMP/CONFIG_SITE.local", "$CHECKOUT/configure/CONFIG_SITE.local") {
        for my $setting ('AA_INSTALL_PATH', 'AA_INSTALL_LOCATION') {
            my $label = "$setting in $local";
            my $base = "$TEMP/install";
            my $install = $setting eq 'AA_INSTALL_PATH' ? "$base/epicsarchiverap-maven" : $base;
            spew($local, "$setting=$base\nAA_SITE_TEMPLATE_PATH=$templates\n"
                . "ARCHAPPL_STORAGE_TOP=$store\nDB_BACKEND=sqlite\n");
            is(trim(make('-s', 'print-ARCHAPPL_TOP')), $install, "$label: ARCHAPPL_TOP");
            make('conf.archapplproperties', 'conf.systemd0');
            my $config = slurp("$templates/archappl.conf");
            my $policy = slurp("$templates/policies.py");
            ok(index($config, qq{ARCHAPPL_APPLIANCES="$install/appliances.xml"}) >= 0, "$label: appliances path");
            ok(index($config, qq{ARCHAPPL_STORAGE_TOP="$store"}) >= 0, "$label: storage top");
            for my $tier (['SHORT', 'sts'], ['MEDIUM', 'mts'], ['LONG', 'lts']) {
                my ($name, $directory) = @{$tier};
                my $folder = "$store/$directory/ArchiverStore";
                ok(index($config, qq{ARCHAPPL_${name}_TERM_FOLDER="$folder"}) >= 0, "$label: $name term folder");
                ok(index($policy, "rootFolder=$folder&") >= 0, "$label: $name policy root folder");
            }
            ok(index(slurp("$templates/context.xml"), "jdbc:sqlite:$store/config/archappl.sqlite?") >= 0,
                "$label: sqlite URL");
            for my $name ('policies.py', 'appliances.xml', 'archappl.properties') {
                ok(slurp("$templates/siteid/classpathfiles/$name") eq slurp("$templates/$name"),
                    "$label: classpath copy of $name");
            }
            my $service = slurp("$templates/systemd/epicsarchiverap-maven.service");
            ok(index($service, qq{"$install/archappl.bash" service}) >= 0, "$label: service ExecStart");
            # Inspect the shipped installation recipe; no WAR or Tomcat substitute.
            my $output = make('-n', 'install.mgmt');
            for my $script ('startup.sh', 'shutdown.sh', 'run.sh') {
                my @lines = grep { index($_, "$templates/$script.in") >= 0 } split /\n/, $output;
                is(scalar @lines, 1, "$label: one recipe line for $script");
                ok(@lines && index($lines[0], "s|\@ARCHAPPL_TOP\@|$install|g") >= 0, "$label: $script substitution");
            }
            # Check the resolved paths before a real filesystem operation.
            make('conf.storage', 'SUDOBASH=bash -c', "AA_USERID=$<", 'AA_GROUPID=' . ($( + 0));
            ok(-d "$store/$_/ArchiverStore", "$label: $_ directory created") for qw(sts mts lts);
        }
        unlink($local) or die "unlink $local: $!\n";
    }
    return;
}

sub case_local_tomcat_paths_and_ports {
    units_setup();
    require_xmllint();
    my $base = "$TEMP/install";
    my $template = "$CHECKOUT/site-template";
    my %port;
    @port{@SERVICES} = (18765 .. 18768);
    for my $location ("$TEMP/CONFIG_SITE.local", "$CHECKOUT/configure/CONFIG_SITE.local") {
        for my $preset (qw(debian12 debian13 rocky8)) {
            my $preset_line = "include \$(TOP)/configure/os/$preset.mk\n";
            spew("$CHECKOUT/configure/CONFIG_SITE.local", $preset_line);
            my $settings = "AA_INSTALL_PATH=$base\nARCHAPPL_CLUSTER_INETPORT=localhost:18870\n";
            for my $service (@SERVICES) {
                my $upper = uc $service;
                $settings .= "ARCHAPPL_${upper}_PORT=$port{$service}\n";
                $settings .= 'ARCHAPPL_SHUTDOWN_' . $upper . '_PORT=' . ($port{$service} + 100) . "\n";
            }
            for my $case (
                ['', "$base/tomcat9", "$base/tomcat9"],
                ["TOMCAT_INSTALL_LOCATION=$TEMP/tomcat-install\n", "$TEMP/tomcat-install", "$TEMP/tomcat-install"],
                ["TOMCAT_HOME=$TEMP/external-tomcat\n", "$TEMP/external-tomcat", "$base/tomcat9"],
            ) {
                my ($override, $expected_home, $expected_install) = @{$case};
                my $label = "$preset " . ($override eq '' ? 'default' : (split /=/, $override)[0]) . ' in ' . $location;
                my $prefix = $location eq "$CHECKOUT/configure/CONFIG_SITE.local" ? $preset_line : '';
                spew($location, $prefix . $settings . $override);
                make('conf.archapplproperties');
                my $config = slurp("$template/archappl.conf");
                ok(index($config, qq{CATALINA_HOME="$expected_home"}) >= 0, "$label: CATALINA_HOME");
                ok(index($config, "ARCHAPPL_MGMT_PORT=18765\n") >= 0, "$label: mgmt port");
                is(trim(make('-s', 'print-TOMCAT_INSTALL_LOCATION')), $expected_install, "$label: install location");
                is(trim(make('-s', 'print-TOMCAT_HOME')), $expected_home, "$label: Tomcat home");
                my $install_commands = make('-n', 'tomcat.src_install');
                ok(index($install_commands, qq{tar -C "$expected_install"}) >= 0, "$label: tar destination");
                is(xml_string("$template/appliances.xml", '/*/appliance[1]/cluster_inetport'), 'localhost:18870',
                    "$label: cluster port");
                for my $service (@SERVICES) {
                    my $url = xml_string("$template/appliances.xml", "/*/appliance[1]/${service}_url");
                    ok(index($url, ":$port{$service}/") >= 0, "$label: $service URL port");
                    my $server = "$base/epicsarchiverap-maven/$service/conf/server.xml";
                    make_path(dirname($server));
                    copy_file("$template/skel/conf/server.xml", $server);
                }
                make('serverxml.install');
                for my $service (@SERVICES) {
                    my $server = "$base/epicsarchiverap-maven/$service/conf/server.xml";
                    is(xml_string($server, '/*/@port'), $port{$service} + 100, "$label: $service shutdown port");
                    is(xml_string($server, '/*/Service/Connector[1]/@port'), $port{$service},
                        "$label: $service connector port");
                }
                make('conf.archappl', 'ARCHAPPL_MGMT_PORT=19965', 'TOMCAT_HOME=/srv/command-tomcat');
                $config = slurp("$template/archappl.conf");
                ok(index($config, "ARCHAPPL_MGMT_PORT=19965\n") >= 0, "$label: command-line mgmt port");
                ok(index($config, 'CATALINA_HOME="/srv/command-tomcat"') >= 0, "$label: command-line Tomcat home");
            }
        }
        unlink($location) or die "unlink $location: $!\n";
    }
    return;
}

sub case_external_storage_ownership_and_health {
    units_setup();
    my $java = which('java');
    skip_case('A real Java executable is required for health configuration') unless defined $java;
    my $store = "$TEMP/archive";
    my @tiers = map { "$TEMP/$_" } qw(short medium long);
    my @groups = split ' ', $(;
    my $primary = shift(@groups) + 0;
    my ($group) = grep { $_ != $primary } @groups;
    $group //= $primary;
    my $java_home = dirname(dirname(abs_path($java)));
    my $text = "ARCHAPPL_STORAGE_TOP=$store\nAA_USERID=$<\nAA_GROUPID=$group\n"
        . "JAVA_HOME=$java_home\nTOMCAT_HOME=$CHECKOUT\nARCHAPPL_STORAGE_ALARM_PERCENT=100\n";
    my @names = qw(SHORT MEDIUM LONG);
    $text .= "ARCHAPPL_$names[$_]_TERM_FOLDER=$tiers[$_]\n" for 0 .. 2;
    spew("$TEMP/CONFIG_SITE.local", $text);
    # Existing files outside the archive root must receive the configured group too.
    for my $path (@tiers) {
        make_path($path);
        spew("$path/existing.pb", '');
    }
    make('conf.storage', 'SUDOBASH=bash -c');
    for my $path ($store, @tiers, map { "$_/existing.pb" } @tiers) {
        my @status = stat $path;
        is($status[4], $<, "$path owner");
        is($status[5], $group, "$path group");
    }
    my $launcher = "$CHECKOUT/scripts/archappl.bash";
    for my $case ([[], 1], [["ARCHAPPL_MEDIUM_TERM_FOLDER=$TEMP/missing"], 2], [['ARCHAPPL_SHORT_TERM_FOLDER=/dev/shm'], 1]) {
        my ($overrides, $expected) = @{$case};
        my $label = @{$overrides} ? "override @{$overrides}" : 'no override';
        if (@{$overrides} && $overrides->[0] eq 'ARCHAPPL_SHORT_TERM_FOLDER=/dev/shm' && !-d '/dev/shm') {
            print "SKIP: separate-filesystem health check requires /dev/shm\n";
            pass("$label: skipped, separate-filesystem health check requires /dev/shm");
            next;
        }
        make('conf.archappl', @{$overrides});
        copy_file("$CHECKOUT/site-template/archappl.conf", "$CHECKOUT/scripts/archappl.conf");
        my $run = run_command(['bash', $launcher, 'health']);
        append_log("$TEMP/run.log", "exit=$run->{status}\n" . combined($run));
        is($run->{status}, $expected, "$label: health exits $expected") or diag(combined($run));
        my @lines = grep { index($_, 'storage path=') == 0 } split /\n/, $run->{stdout};
        is(scalar @lines, 4, "$label: four storage lines");
        if ($expected == 2) {
            ok(index($run->{stdout}, "storage path=$TEMP/missing mount=-") >= 0, "$label: missing path reported");
            ok(index($run->{stdout}, 'ERROR storage-unreadable') >= 0, "$label: storage-unreadable");
            ok(index($run->{stdout}, 'health ERROR inspection-incomplete') >= 0, "$label: inspection-incomplete");
        }
        else {
            my @paths = ($store, @tiers);
            $paths[1] = '/dev/shm' if @{$overrides};
            for my $path (@paths) {
                my $df = run_command(['df', '-P', $path]);
                my @fields = split ' ', (split /\n/, $df->{stdout})[1];
                ok(index($run->{stdout}, "storage path=$path mount=$fields[5] use=$fields[4] threshold=100% PRESENT") >= 0,
                    "$label: storage line of $path");
            }
        }
    }
    return;
}

sub case_explicit_derived_path_overrides {
    units_setup();
    my @values = (
        ['ARCHAPPL_TOP', "$TEMP/runtime"],
        ['ARCHAPPL_SITEID_TEMPATE_PATH', "$TEMP/overlay"],
        ['ARCHAPPL_SITEID_CLASSPATHFILES_PATH', "$TEMP/classpath"],
        ['ARCHAPPL_SHORT_TERM_FOLDER', "$TEMP/short"],
        ['ARCHAPPL_MEDIUM_TERM_FOLDER', "$TEMP/medium"],
        ['ARCHAPPL_LONG_TERM_FOLDER', "$TEMP/long"],
    );
    spew("$CHECKOUT/configure/CONFIG_SITE.local", join('', map { "$_->[0]=$_->[1]\n" } @values));
    is(trim(make('-s', "print-$_->[0]")), $_->[1], "$_->[0] override") for @values;
    return;
}

sub case_sql_drop_backend_guard {
    units_setup();
    spew("$TEMP/CONFIG_SITE.local", "DB_BACKEND=sqlite\n");
    for my $target ('sql.drop', 'sql.table.drop') {
        # Existing files with target names must not bypass the guard.
        spew("$CHECKOUT/$target", '');
        for my $backend ('invalid', '', 'sqlite mariadb') {
            for my $dry_run (1, 0) {
                my $label = "$target backend '$backend'" . ($dry_run ? ' dry run' : '');
                my @args = ('make', '--no-print-directory', '-C', $CHECKOUT, $target, "DB_BACKEND=$backend");
                push @args, '-n' if $dry_run;
                my $run = run_command(\@args, timeout => 10);
                isnt($run->{status}, 0, "$label: refused") or diag(combined($run));
                ok(index($run->{stderr}, 'DB_BACKEND must be one of:') >= 0, "$label: backend message");
                ok(index(combined($run), 'mariadb_setup.bash') < 0, "$label: no setup script reached");
            }
        }
        # Supported deletion paths are inspected only in this local check.
        for my $backend (qw(mariadb sqlite)) {
            my $output = make('-n', $target, "DB_BACKEND=$backend");
            ok(index($output, 'mariadb_setup.bash tableDrop') >= 0, "$target $backend: table drop recipe");
        }
    }
    return;
}

sub position {
    my ($mode, $text, $needle) = @_;
    my $at = $mode eq 'first' ? index($text, $needle) : rindex($text, $needle);
    ok($at >= 0, "found $mode '$needle'");
    return $at;
}

sub case_full_install_and_monitor_removal_command_order {
    units_setup();
    make('conf.archapplproperties');
    my $output = make('-j8', '-n', 'install');
    cmp_ok(position('first', $output, 'systemctl stop'), '<', position('first', $output, 'usergroup.postinst'),
        'stop precedes usergroup.postinst');
    cmp_ok(position('last', $output, 'chown -R'), '<', position('last', $output, 'systemctl daemon-reload'),
        'chown precedes daemon-reload');
    cmp_ok(position('last', $output, 'systemctl daemon-reload'), '<', position('first', $output, 'systemctl enable'),
        'daemon-reload precedes enable');
    ok(index($output, 'systemctl start') < 0, 'install does not start the service');
    my $removal = make('-n', 'sd_health_clean');
    cmp_ok(position('first', $removal, 'systemctl stop'), '<', position('first', $removal, 'systemctl disable'),
        'stop precedes disable');
    cmp_ok(position('first', $removal, 'systemctl disable'), '<', position('first', $removal, 'rm -f'),
        'disable precedes rm -f');
    ok(index($removal, 'systemctl stop epicsarchiverap-maven.service') < 0, 'removal leaves the main service');
    ok(index($removal, '--now') < 0, 'removal does not use --now');
    return;
}

my @CASES = (
    ['configuration_errors_and_privacy', 'configuration errors and privacy', \&case_configuration_errors_and_privacy],
    ['unreadable_configuration', 'unreadable configuration', \&case_unreadable_configuration],
    ['missing_pid_files', 'missing PID files', \&case_missing_pid_files],
    ['launcher_help_names_supported_restart_command', 'launcher help names the supported restart command', \&case_launcher_help_names_supported_restart_command],
    ['status_reports_missing_and_unrelated_processes', 'status reports missing and unrelated processes', \&case_status_reports_missing_and_unrelated_processes],
    ['storage_preserves_literal_paths_and_failure_status', 'storage preserves literal paths and failure status', \&case_storage_preserves_literal_paths_and_failure_status],
    ['invalid_pid_files_are_preserved', 'invalid PID files are preserved', \&case_invalid_pid_files_are_preserved],
    ['absent_process', 'absent process', \&case_absent_process],
    ['real_unrelated_process_is_not_signalled', 'real unrelated process is not signalled', \&case_real_unrelated_process_is_not_signalled],
    ['unrelated_java_with_tomcat_application_arguments', 'unrelated Java with Tomcat application arguments', \&case_unrelated_java_with_tomcat_application_arguments],
    ['pid_symlink_target_ancestor_permission_error', 'PID symlink target ancestor permission error', \&case_pid_symlink_target_ancestor_permission_error],
    ['inspection_error_takes_precedence', 'inspection error takes precedence', \&case_inspection_error_takes_precedence],
    ['nonregular_pid_file_does_not_block', 'nonregular PID file does not block', \&case_nonregular_pid_file_does_not_block],
    ['real_zombie_is_rejected', 'real zombie is rejected', \&case_real_zombie_is_rejected],
    ['invalid_cli', 'invalid command line', \&case_invalid_cli],
    ['real_file_install_default_and_alternate', 'real file install, default and alternate', \&case_real_file_install_default_and_alternate],
    ['site_timing_overrides', 'site timing overrides', \&case_site_timing_overrides],
    ['local_path_overrides', 'local path overrides', \&case_local_path_overrides],
    ['local_tomcat_paths_and_ports', 'local Tomcat paths and ports', \&case_local_tomcat_paths_and_ports],
    ['external_storage_ownership_and_health', 'external storage ownership and health', \&case_external_storage_ownership_and_health],
    ['explicit_derived_path_overrides', 'explicit derived path overrides', \&case_explicit_derived_path_overrides],
    ['sql_drop_backend_guard', 'SQL drop backend guard', \&case_sql_drop_backend_guard],
    ['full_install_and_monitor_removal_command_order', 'full install and monitor removal command order', \&case_full_install_and_monitor_removal_command_order],
);

sub usage_error {
    my ($message) = @_;
    print STDERR "health-local.pl: $message\n" if defined $message;
    pod2usage(-verbose => 0, -exitval => 'NOEXIT', -output => \*STDERR);
    return 2;
}

sub main {
    my (@arguments) = @_;
    my ($help, @wanted);
    GetOptionsFromArray(\@arguments, 'help' => \$help, 'case=s' => \@wanted) or return usage_error();
    if ($help) {
        pod2usage(-verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        return 0;
    }
    return usage_error('unexpected argument: ' . $arguments[0]) if @arguments;
    my %known = map { $_->[0] => 1 } @CASES;
    for my $name (@wanted) {
        return usage_error("unknown case: $name") unless $known{$name};
    }
    my %chosen = map { $_ => 1 } @wanted;
    my @selected = grep { !@wanted || $chosen{ $_->[0] } } @CASES;
    $capture_dir = tempdir('archappl-capture-XXXXXX', TMPDIR => 1, CLEANUP => 1);
    for my $case (@selected) {
        run_case($case->[1], $case->[2]);
    }
    done_testing();
    return Test::More->builder->is_passing ? 0 : 1;
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    print STDERR "health-local.pl: $error";
    $status = 2;
};
exit $status;
