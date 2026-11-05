#!/usr/bin/env perl
# Exercises the shipped configuration loader, the launcher and the configuration install rules in isolated workspaces.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use IO::Socket::INET;
use Pod::Usage qw(pod2usage);
use POSIX ();
use Test::More;

=head1 NAME

config-d.pl - run the shipped configuration loader, launcher and install rules against filesystem inputs

=head1 SYNOPSIS

  perl tests/config-d.pl [--case NAME]...
  perl tests/config-d.pl --help

=head1 DESCRIPTION

Runs an unchanged copy of scripts/archappl.bash and scripts/archappl-config.bash in a workspace with an archappl.conf
and a config.d directory, and checks absent and empty directories, ordered overrides, quoted and empty values, file
selection, unreadability, syntax errors, the export option, the preflight mode, the last-command status behavior, the
health path and the single evaluation of the configuration by status and health. The real Make targets that render and
install the configuration run twice in a copy of the checkout to check that the bytes of an operator-owned file
survive. Each case works in its own archappl-config-d-* workspace under TMPDIR; its commands.log holds every command,
its status and its output. The workspace of a failed case, or of every case when KEEP_WORKSPACE=1, is kept and its path
printed.

The cases that need a real Java executable report a skip when it is missing, and the unreadability case reports a skip
for root; every skip prints a line that starts with C<SKIP:>. Required programs: bash, make, curl and the Perl module
Test::More (on Rocky Linux the package perl-Test-Simple).

=head1 OPTIONS

=over 4

=item B<--case> NAME

Run only the named case; repeat the option for more. Without the option every case runs. The names are listed by
B<--help>.

=item B<--help>

Print this text and the case names and exit 0.

=back

=head1 EXIT STATUS

0 when every case passed or was skipped, nonzero when an assertion failed or the run aborted, 2 for a usage error.

=cut

my $TOP = abs_path(dirname(abs_path($0)) . '/..');

# The temporary folder: TMPDIR when it names a writable folder, else work/scratch/tmp of the checkout, created when missing.
sub temp_root {
    my $dir = $ENV{TMPDIR};
    return abs_path($dir) if defined $dir && $dir ne '' && -d $dir && -w _;
    my $local = "$TOP/work/scratch/tmp";
    make_path($local);
    -d $local && -w _ or die "cannot create the temporary folder $local\n";
    return abs_path($local);
}

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

sub append {
    my ($path, $data) = @_;
    open(my $handle, '>>:raw', $path) or die "open $path: $!\n";
    print {$handle} $data or die "write $path: $!\n";
    close($handle) or die "close $path: $!\n";
    return;
}

sub copy_file {
    my ($from, $to) = @_;
    copy($from, $to) or die "copy $from to $to: $!\n";
    return;
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

# Registers an action that runs, newest first, when the current case ends.
sub on_cleanup {
    my ($action) = @_;
    push @cleanup, $action;
    return;
}

# Skips the rest of the current subtest; the SKIP: line is the form that the VM driver refuses as a complete run.
sub skip_case {
    my ($reason) = @_;
    print "SKIP: $reason\n";
    plan skip_all => $reason;
    return;
}

# Runs one command without a shell from the filesystem root. Options: env (a hash reference replacing the
# environment) and timeout (seconds, default 30). Returns a hash with status (a signal reads as 128 plus its number;
# -1 after a timeout), stdout and stderr.
sub run_command {
    my ($command, %option) = @_;
    my $timeout = $option{timeout} // 30;
    my $id = ++$capture_count;
    my ($out_path, $err_path) = ("$capture_dir/out.$id", "$capture_dir/err.$id");
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        chdir('/') or POSIX::_exit(126);
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

# ---------------------------------------------------------------------------------------------------------------------
# Fixture: a workspace with an archappl.conf and unchanged copies of the launcher and the loader.
# ---------------------------------------------------------------------------------------------------------------------

my ($ROOT, $CONFIG);

sub setup {
    $ROOT = tempdir('archappl-config-d-XXXXXX', DIR => temp_root());
    push @workspaces, $ROOT;
    $CONFIG = "$ROOT/archappl.conf";
    spew($CONFIG, "CONFIG_TEST_VALUE=base\nCONFIG_TEST_EMPTY=base\n");
    for my $name (qw(archappl.bash archappl-config.bash)) {
        copy_file("$TOP/scripts/$name", "$ROOT/$name");
    }
    return;
}

# Runs a command, appends it to the workspace log and checks its exit status (default 0).
sub run_logged {
    my ($command, %option) = @_;
    my $expected = delete($option{expected}) // 0;
    my $run = run_command($command, %option);
    append($ROOT . '/commands.log',
        'command=[' . join(', ', map { "'$_'" } @{$command}) . "]\nexit=$run->{status}\n$run->{stdout}$run->{stderr}\n");
    is($run->{status}, $expected, "$command->[0] $command->[-1] exits $expected")
        or diag($run->{stdout} . $run->{stderr});
    return $run;
}

# Runs the loader in a shell and returns the resulting environment as a hash, and the run.
sub load {
    my (%option) = @_;
    my $mode = $option{mode} // 'startup';
    my $prefix = $option{prefix} // '';
    my $script = $prefix . "\n. \"\$1/archappl-config.bash\"; archappl_load_configuration \"\$1\" \"\$2\" || exit \$?; env -0";
    my $run = run_logged(['bash', '-c', $script, 'config-test', $ROOT, $mode], expected => $option{expected});
    my %values;
    for my $item (split /\0/, $run->{stdout}) {
        next unless index($item, '=') >= 0;
        my ($key, $value) = split /=/, $item, 2;
        $values{$key} = $value;
    }
    return (\%values, $run);
}

sub drops {
    mkdir("$ROOT/config.d") unless -d "$ROOT/config.d";
    return "$ROOT/config.d";
}

sub launcher {
    my ($action, $status, %option) = @_;
    return run_logged(['bash', "$ROOT/archappl.bash", $action], expected => $status, %option);
}

# ---------------------------------------------------------------------------------------------------------------------
# Cases.
# ---------------------------------------------------------------------------------------------------------------------

sub case_absent_empty_and_export_option {
    setup();
    for my $present (0, 1) {
        drops() if $present;
        my ($values) = load();
        is($values->{CONFIG_TEST_VALUE}, 'base', 'value ' . ($present ? 'with' : 'without') . ' config.d');
    }
    my $script = '. "$1/archappl-config.bash"; set -a; archappl_load_configuration "$1"; [[ $- == *a* ]]';
    run_logged(['bash', '-c', $script, 'config-test', $ROOT]);
    $script = '. "$1/archappl-config.bash"; set +a; archappl_load_configuration "$1"; [[ $- != *a* ]]';
    run_logged(['bash', '-c', $script, 'config-test', $ROOT]);
    return;
}

sub case_order_quotes_empty_and_file_selection {
    setup();
    my $drops = drops();
    spew("$drops/20-last.conf", "CONFIG_TEST_VALUE='last value'\nCONFIG_TEST_EMPTY=''\n");
    spew("$drops/10-first.conf", "CONFIG_TEST_VALUE=first\nCONFIG_TEST_NEW='one two * \$three'\n");
    spew("$drops/15 with spaces.conf", "CONFIG_TEST_SPACE=yes\n");
    spew("$ROOT/linked.conf", "CONFIG_TEST_LINK=yes\n");
    symlink("$ROOT/linked.conf", "$drops/16-link.conf") or die "symlink: $!\n";
    for my $name ('.hidden.conf', '20-last.conf~', 'disabled.conf.bak') {
        spew("$drops/$name", "CONFIG_TEST_VALUE=wrong\nCONFIG_TEST_IGNORED=loaded\n");
    }
    mkdir("$drops/30-directory.conf") or die "mkdir: $!\n";
    spew("$drops/30-directory.conf/child.conf", "CONFIG_TEST_VALUE=wrong\n");
    spew("$drops/A-order.conf", "CONFIG_TEST_ORDER=upper\n");
    spew("$drops/a-order.conf", "CONFIG_TEST_ORDER=lower\n");
    my ($values, $run) = load(prefix => q{shopt -s dotglob; export GLOBIGNORE="$1/config.d/20-last.conf"});
    is($values->{CONFIG_TEST_VALUE}, 'last value', 'the last file in bytewise order wins');
    is($values->{CONFIG_TEST_EMPTY}, '', 'an empty value is kept');
    is($values->{CONFIG_TEST_NEW}, 'one two * $three', 'a quoted value is kept literally');
    is($values->{CONFIG_TEST_SPACE}, 'yes', 'a file name with spaces is loaded');
    is($values->{CONFIG_TEST_LINK}, 'yes', 'a symlink to a file is loaded');
    ok(!exists $values->{CONFIG_TEST_IGNORED}, 'hidden and disabled files are never evaluated');
    is($values->{CONFIG_TEST_ORDER}, 'lower', 'uppercase filenames precede lowercase filenames in bytewise order');
    is($run->{stderr}, '', 'selection produces no locale or shell diagnostics');
    return;
}

sub case_noglob_preserves_selection_and_caller_option {
    setup();
    spew(drops() . '/50-site.conf', "CONFIG_TEST_VALUE=local\n");
    my ($values) = load(prefix => 'set -f');
    is($values->{CONFIG_TEST_VALUE}, 'local', 'the selection works with noglob set');
    my $script = '. "$1/archappl-config.bash"; set -f; archappl_load_configuration "$1"; [[ $- == *f* ]]';
    run_logged(['bash', '-c', $script, 'config-test', $ROOT]);
    my $invalid = drops() . '/99-invalid.conf';
    spew($invalid, qq{CONFIG_TEST_VALUE="unterminated\n});
    for my $case (['startup', 1], ['service', 1], ['health', 2]) {
        my ($action, $status) = @{$case};
        my $run = run_logged(['bash', '-f', "$ROOT/archappl.bash", $action], expected => $status);
        ok(index($run->{stderr}, $invalid) >= 0, "$action names the invalid file");
    }
    return;
}

sub case_preflight_does_not_evaluate_configuration {
    setup();
    my $marker = "$ROOT/evaluated";
    spew($CONFIG, 'printf evaluated > ' . shell_quote($marker) . "\n");
    load(mode => 'preflight');
    ok(!-e $marker, 'preflight does not evaluate the configuration');
    my $invalid = drops() . '/99-invalid.conf';
    spew($invalid, qq{CONFIG_TEST_VALUE="unterminated\n});
    my (undef, $run) = load(expected => 1, mode => 'preflight');
    ok(index($run->{stderr}, $invalid) >= 0, 'preflight names the invalid file');
    ok(!-e $marker, 'preflight of an invalid file does not evaluate the configuration');
    return;
}

# Starts a local HTTP server that records the path of every request in a file and answers it with an empty JSON list;
# returns its port. The server process is stopped when the case ends.
sub start_recording_server {
    my ($log) = @_;
    my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 16, ReuseAddr => 1)
        or die "listen: $!\n";
    my $port = $listener->sockport;
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        $SIG{PIPE} = 'IGNORE';
        while (my $client = $listener->accept) {
            my $line = <$client> // '';
            while (defined(my $header = <$client>)) {
                last if $header =~ /\A\r?\n\z/;
            }
            append($log, "$1\n") if $line =~ m{\AGET (\S+)};
            print {$client} "HTTP/1.0 200 OK\r\nContent-Length: 2\r\n\r\n[]";
            $client->close;
        }
        POSIX::_exit(0);
    }
    $listener->close;
    on_cleanup(sub { kill('TERM', $pid); waitpid($pid, 0); });
    return $port;
}

sub case_loglevel_blocks_invalid_configuration_with_inherited_port {
    setup();
    my $log = "$ROOT/requests.log";
    spew($log, '');
    my $port = start_recording_server($log);
    my %env = (%ENV, ARCHAPPL_MGMT_PORT => $port);
    my @command = ('bash', "$ROOT/archappl.bash", 'loglevel', 'engine', 'root', 'DEBUG');
    # Establish that the actual launcher reaches the transport with valid settings.
    spew($CONFIG, "ARCHAPPL_MGMT_PORT=$port\n");
    run_logged(\@command, env => \%env);
    is(slurp($log), "/mgmt/bpl/setLogLevel?component=engine&logger=root&level=DEBUG\n", 'a valid configuration reaches the server');
    spew($log, '');
    my $invalid = drops() . '/99-invalid.conf';
    spew($invalid, qq{CONFIG_TEST_VALUE="unterminated\n});
    my $run = run_logged(\@command, expected => 1, env => \%env);
    ok(index($run->{stderr}, $invalid) >= 0, 'the invalid file is named');
    is(slurp($log), '', 'an invalid configuration reaches no server');
    return;
}

sub case_preflight_before_evaluation_or_component_start {
    setup();
    my $marker = "$ROOT/evaluated";
    spew($CONFIG, 'printf evaluated > ' . shell_quote($marker) . "\n");
    my $invalid = drops() . '/99-invalid.conf';
    spew($invalid, qq{CONFIG_TEST_VALUE="PRIVATE_CONFIG_CONTENT\n});
    my (undef, $run) = load(expected => 1);
    ok(index($run->{stderr}, $invalid) >= 0, 'the loader names the invalid file');
    ok(index($run->{stderr}, 'PRIVATE_CONFIG_CONTENT') < 0, 'the loader does not echo the content');
    ok(!-e $marker, 'the loader does not evaluate the configuration');
    for my $case (['startup', 1], ['service', 1], ['restart', 1], ['shutdown', 1], ['health', 2]) {
        my ($action, $status) = @{$case};
        $run = launcher($action, $status);
        ok(index($run->{stderr}, $invalid) >= 0, "$action names the invalid file");
        ok(!-e $marker, "$action does not evaluate the configuration");
        ok(index($run->{stdout} . $run->{stderr}, 'PRIVATE_CONFIG_CONTENT') < 0, "$action does not echo the content");
        if ($action eq 'health') {
            ok(index($run->{stdout}, 'unreadable-or-invalid-configuration') >= 0, 'health reports the configuration error');
        }
        else {
            ok(index($run->{stderr}, 'no instance was touched') >= 0, "$action touches no instance");
        }
    }
    return;
}

sub case_unreadable_file_and_directory {
    skip_case('Unreadability must be checked as an unprivileged user') if $> == 0;
    setup();
    my $drops = drops();
    my $private = "$drops/10-private.conf";
    spew($private, "CONFIG_TEST_VALUE=unreadable\n");
    chmod(0, $private) or die "chmod: $!\n";
    on_cleanup(sub { chmod(0600, $private) });
    my (undef, $run) = load(expected => 1);
    ok(index($run->{stderr}, $private) >= 0, 'the loader names the unreadable file');
    for my $case (['startup', 1], ['service', 1], ['health', 2]) {
        my ($action, $status) = @{$case};
        $run = launcher($action, $status);
        ok(index($run->{stderr}, $private) >= 0, "$action names the unreadable file");
    }
    chmod(0600, $private) or die "chmod: $!\n";
    chmod(0, $drops) or die "chmod: $!\n";
    on_cleanup(sub { chmod(0700, $drops) });
    (undef, $run) = load(expected => 1);
    ok(index($run->{stderr}, $drops) >= 0, 'the loader names the unreadable directory');
    return;
}

sub case_last_command_status_compatibility {
    setup();
    spew($CONFIG, "CONFIG_TEST_VALUE=base\nfalse\n");
    my ($values) = load();
    is($values->{CONFIG_TEST_VALUE}, 'base', 'startup ignores the status of the last command');
    my (undef, $run) = load(expected => 2, mode => 'health');
    ok(index($run->{stderr}, 'configuration evaluation failed') >= 0, 'health reports the evaluation failure');
    spew($CONFIG, "CONFIG_TEST_VALUE=base\nprintf 'configuration stdout\\n'\nprintf 'configuration stderr\\n' >&2\n");
    (undef, $run) = load(mode => 'health');
    ok(index($run->{stdout}, 'configuration stdout') < 0, 'health suppresses configuration stdout');
    is($run->{stderr}, '', 'health suppresses configuration stderr');
    return;
}

# Directory that holds bin/java, two levels above the resolved executable.
sub java_home {
    my $java = which('java');
    return unless defined $java;
    return dirname(dirname(abs_path($java)));
}

sub case_health_uses_local_runtime_paths {
    my $java_home = java_home();
    skip_case('A real Java installation is required') unless defined $java_home;
    setup();
    spew($CONFIG, "JAVA_HOME=/missing\nCATALINA_HOME=/missing\n");
    spew(drops() . '/50-runtime.conf', 'JAVA_HOME=' . shell_quote($java_home) . "\nCATALINA_HOME=" . shell_quote($ROOT)
        . "\nARCHAPPL_STORAGE_TOP=" . shell_quote($ROOT) . "\nARCHAPPL_STORAGE_ALARM_PERCENT=100\n");
    make_path("$ROOT/$_/temp") for @SERVICES;
    my $run = launcher('health', 1);
    ok(index($run->{stdout}, 'invalid-runtime-paths') < 0, 'the local runtime paths are accepted');
    ok(index($run->{stdout}, "storage path=$ROOT") >= 0, 'the storage line names the local store');
    return;
}

sub case_status_and_health_evaluate_configuration_once {
    my $java_home = java_home();
    skip_case('A real Java installation is required') unless defined $java_home;
    setup();
    spew($CONFIG, 'JAVA_HOME=' . shell_quote($java_home) . "\nCATALINA_HOME=" . shell_quote($ROOT)
        . "\nARCHAPPL_STORAGE_TOP=" . shell_quote($ROOT) . "\nARCHAPPL_STORAGE_ALARM_PERCENT=100\n");
    my $marker = "$ROOT/evaluations";
    my $local = drops() . '/50-site.conf';
    spew($local, "printf 'loaded\\n' >> " . shell_quote($marker) . "\n");
    for my $action (qw(status health)) {
        my $run = launcher($action, 1);
        ok(index($run->{stdout}, 'missing-pid-file') >= 0, "$action reports the missing PID files");
        is(slurp($marker), "loaded\n", "$action evaluates the configuration once");
        unlink($marker) or die "unlink $marker: $!\n";
    }
    spew($local, "false\n");
    for my $action (qw(status health)) {
        my $run = launcher($action, 2);
        ok(index($run->{stdout}, 'configuration-load-failed') >= 0, "$action reports a failed evaluation");
    }
    spew($local, "# No local runtime paths.\n");
    spew($CONFIG, 'ARCHAPPL_STORAGE_TOP=' . shell_quote($ROOT) . "\n");
    my %env = (%ENV, JAVA_HOME => $java_home, CATALINA_HOME => $ROOT);
    for my $action (qw(status health)) {
        my $run = launcher($action, 2, env => \%env);
        ok(index($run->{stdout}, 'invalid-runtime-paths') >= 0, "$action ignores paths from the environment");
    }
    return;
}

sub case_install_and_regeneration_preserve_local_bytes {
    setup();
    my $checkout = "$ROOT/checkout";
    mkdir($checkout) or die "mkdir: $!\n";
    for my $name (qw(configure site-template scripts)) {
        run_logged(['cp', '-R', "$TOP/$name", "$checkout/$name"]);
    }
    copy_file("$TOP/Makefile", "$checkout/Makefile");
    my $installed = "$ROOT/installed";
    my @command = ('make', '--no-print-directory', '-C', $checkout, 'SUDO=', "AA_INSTALL_LOCATION=$installed");
    run_logged([@command, 'conf.archappl']);
    run_logged([@command, 'archapplconf.install', 'archapplshell.install']);
    my $local_file = "$installed/config.d/90-site.conf";
    my $content = "CONFIG_TEST_VALUE='kept exactly'\n# Operator-owned settings.\n";
    spew($local_file, $content);
    run_logged([@command, 'conf.archappl']);
    run_logged([@command, 'archapplconf.install', 'archapplshell.install']);
    is(slurp($local_file), $content, 'the operator file is unchanged');
    is(slurp("$installed/archappl-config.bash"), slurp("$TOP/scripts/archappl-config.bash"),
        'the installed loader equals the shipped loader');
    return;
}

my @CASES = (
    ['absent_empty_and_export_option', 'absent, empty and export option', \&case_absent_empty_and_export_option],
    ['order_quotes_empty_and_file_selection', 'order, quotes, empty values and file selection', \&case_order_quotes_empty_and_file_selection],
    ['noglob_preserves_selection_and_caller_option', 'noglob preserves selection and caller option', \&case_noglob_preserves_selection_and_caller_option],
    ['preflight_does_not_evaluate_configuration', 'preflight does not evaluate configuration', \&case_preflight_does_not_evaluate_configuration],
    ['loglevel_blocks_invalid_configuration_with_inherited_port', 'loglevel blocks invalid configuration with an inherited port', \&case_loglevel_blocks_invalid_configuration_with_inherited_port],
    ['preflight_before_evaluation_or_component_start', 'preflight before evaluation or component start', \&case_preflight_before_evaluation_or_component_start],
    ['unreadable_file_and_directory', 'unreadable file and directory', \&case_unreadable_file_and_directory],
    ['last_command_status_compatibility', 'last command status compatibility', \&case_last_command_status_compatibility],
    ['health_uses_local_runtime_paths', 'health uses local runtime paths', \&case_health_uses_local_runtime_paths],
    ['status_and_health_evaluate_configuration_once', 'status and health evaluate configuration once', \&case_status_and_health_evaluate_configuration_once],
    ['install_and_regeneration_preserve_local_bytes', 'install and regeneration preserve local bytes', \&case_install_and_regeneration_preserve_local_bytes],
);

sub usage_error {
    my ($message) = @_;
    print STDERR "config-d.pl: $message\n" if defined $message;
    pod2usage(-verbose => 0, -exitval => 'NOEXIT', -output => \*STDERR);
    return 2;
}

sub main {
    my (@arguments) = @_;
    my ($help, @wanted);
    GetOptionsFromArray(\@arguments, 'help' => \$help, 'case=s' => \@wanted) or return usage_error();
    if ($help) {
        pod2usage(-verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        print "\nCases:\n", map({ "  $_->[0]\n" } @CASES);
        return 0;
    }
    return usage_error('unexpected argument: ' . $arguments[0]) if @arguments;
    my %known = map { $_->[0] => 1 } @CASES;
    for my $name (@wanted) {
        return usage_error("unknown case: $name") unless $known{$name};
    }
    my %chosen = map { $_ => 1 } @wanted;
    my @selected = grep { !@wanted || $chosen{ $_->[0] } } @CASES;
    $capture_dir = tempdir('archappl-config-d-capture-XXXXXX', DIR => temp_root(), CLEANUP => 1);
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
    print STDERR "config-d.pl: $error";
    $status = 2;
};
exit $status;
