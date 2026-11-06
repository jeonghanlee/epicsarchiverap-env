#!/usr/bin/env perl
# Runs the shipped configuration targets and shell consumers of the database layer in isolated workspaces.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use File::Basename qw(dirname basename);
use File::Copy qw(copy);
use File::Glob qw(bsd_glob);
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use IO::Socket::INET;
use Pod::Usage qw(pod2usage);
use POSIX ();
use Test::More;
use Time::HiRes ();

BEGIN {
    require(dirname(abs_path($0)) . '/lib/ArchiverTest.pm');
    ArchiverTest->import(qw(slurp spew usage_error which));
}

=head1 NAME

database-config.pl - run the shipped database configuration targets and shell consumers in isolated workspaces

=head1 SYNOPSIS

  perl tests/database-config.pl [--case NAME]...
  sudo env AA_TEST_DISPOSABLE_HOST=YES perl tests/database-config.pl --integration
  perl tests/database-config.pl --help

=head1 DESCRIPTION

Without options, runs the configuration cases: the real Make targets render the site templates for each database
backend, the XML and the shell assignments they write are read back, the installer helper functions run with only the
outer sudo and systemctl commands replaced, and the system entry points are checked to refuse to report success. Each
case works in its own aa-db-config-* workspace under TMPDIR, a copy of the tracked and untracked-unignored checkout
files; a workspace of a failed case, or of every case when KEEP_WORKSPACE=1, is kept and its path printed.

With B<--integration>, runs the two integration cases instead: a real SQLite schema load, and a private real MariaDB
server for account identity, special-character passwords, schema loading, backup, restore, dump failure, publication
races and preservation of unrelated accounts. They need root, AA_TEST_DISPOSABLE_HOST=YES, the SQLite and MariaDB
tools and the source checkout, and no sudo, client, clock or publication command is replaced.

The source checkout is epicsarchiverap-maven-src beside the repository unless AA_TEST_SOURCE_PATH names another. The
checkout under test must be a Git work tree. Required programs: bash, make, git, curl, xmllint, and the Perl modules
Test::More and Time::HiRes (on Rocky Linux the packages perl-Test-Simple and perl-Time-HiRes). The integration cases
also need sqlite3, gzip, the MariaDB server and client, and the programs lsof and tree that the shipped database
helper requires (on Rocky Linux lsof and tree are separate packages).

=head1 OPTIONS

=over 4

=item B<--integration>

Run the integration cases instead of the configuration cases.

=item B<--case> NAME

Run only the named case of the selected set; repeat the option for more. The names are listed by B<--help>.

=item B<--help>

Print this text and the case names and exit 0.

=back

=head1 EXIT STATUS

0 when every case passed, nonzero when an assertion failed or the run aborted, 2 for a usage error, 77 when
B<--integration> was requested without root or without AA_TEST_DISPOSABLE_HOST=YES.

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

my $SOURCE_TOP = $ENV{AA_TEST_SOURCE_PATH} // "$TOP/epicsarchiverap-maven-src";
my $SCHEMA_TOP = "$SOURCE_TOP/src/main/org/epics/archiverappliance/config/persistence";
my @DB_TARGETS = qw(db.conf db.conf.show db.secure db.addAdmin db.rmAdmin db.create db.drop db.show);
my @SQL_TARGETS = qw(sql.fill sql.show sql.update sql.update.show sql.table.fill sql.table.show sql.drop
    sql.table.drop);
my @QUERY_TARGETS = qw(PVRequests.show DataServers.show PVAliases.show PVTypeInfo.show);
my @HELPER_ACTIONS = qw(secureSetup localAdminAdd hostnameAdminAdd localAdminRemove hostnameAdminRemove adminAdd
    adminRemove dbCreate dbUserCreate dbShow dbUserDrop userDrop dbDrop isDb dbBackup dbBackupList dbRestore
    tableShow tableDrop aaShow query queryFile);
my $capture_dir;
my $capture_count = 0;
my @workspaces;
my @cleanup;

$| = 1;

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

sub trim {
    my ($text) = @_;
    $text =~ s/\A\s+//;
    $text =~ s/\s+\z//;
    return $text;
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
    my $path = tempdir($prefix . 'XXXXXX', DIR => temp_root());
    push @workspaces, $path;
    return $path;
}

# Runs one command without a shell. Options: cwd, env (a hash reference replacing the environment), input (standard
# input text) and timeout (seconds, default 30). Returns a hash with status (a signal reads as 128 plus its number; -1
# after a timeout), stdout and stderr.
sub run_command {
    my ($command, %option) = @_;
    my $timeout = $option{timeout} // 30;
    my $id = ++$capture_count;
    my ($in_path, $out_path, $err_path) = ("$capture_dir/in.$id", "$capture_dir/out.$id", "$capture_dir/err.$id");
    spew($in_path, $option{input} // '');
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        if (defined $option{cwd}) {
            chdir($option{cwd}) or POSIX::_exit(126);
        }
        %ENV = %{ $option{env} } if $option{env};
        open(STDIN, '<', $in_path) or POSIX::_exit(126);
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

# Runs a command whose exit status must equal the expected one (default 0); returns its stdout.
sub run_expect {
    my ($command, %option) = @_;
    my $expected = delete($option{expected}) // 0;
    my $run = run_command($command, %option);
    is($run->{status}, $expected, "@{$command}[0 .. ($#{$command} > 5 ? 5 : $#{$command})] exits $expected")
        or diag(combined($run));
    return $run->{stdout};
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
# Shared fixture: a copy of the tracked and untracked-unignored checkout files in a workspace.
# ---------------------------------------------------------------------------------------------------------------------

my ($TEMP, $ROOT);

sub setup {
    $TEMP = workspace('aa-db-config-');
    $ROOT = "$TEMP/checkout";
    make_path($ROOT);
    my $list = run_command(['git', '-C', $TOP, 'ls-files', '-z', '--cached', '--others', '--exclude-standard']);
    die "git ls-files failed: $list->{stderr}\n" if $list->{status} != 0;
    for my $item (split /\0/, $list->{stdout}) {
        next unless $item eq 'Makefile' || $item =~ m{\A(?:configure|site-template|scripts)/};
        next unless -f "$TOP/$item";
        make_path(dirname("$ROOT/$item"));
        copy_file("$TOP/$item", "$ROOT/$item");
    }
    return;
}

sub run_in_root {
    my ($command, %option) = @_;
    return run_expect($command, cwd => $ROOT, %option);
}

sub make {
    my (@args) = @_;
    return run_in_root(['make', '--no-print-directory', '-s', @args]);
}

# Value of a shell variable after sourcing a file.
sub value {
    my ($file, $name) = @_;
    return run_in_root(['bash', '-c', 'source "$1"; printf "%s" "${!2}"', 'test', $file, $name]);
}

# Value of an XPath string expression over an XML file.
sub xml_string {
    my ($file, $expression) = @_;
    my $run = run_command(['xmllint', '--xpath', "string($expression)", $file]);
    ok($run->{status} == 0, "xmllint reads $expression of $file") or diag(combined($run));
    (my $text = $run->{stdout}) =~ s/\n\z//;
    return $text;
}

# Splits the shipped installer script before its final invocation, so that its functions can be sourced alone.
sub write_functions_harness {
    my ($name) = @_;
    my $script = slurp("$ROOT/scripts/install-local-common.bash");
    my $marker = "\nmain \"\$@\"; exit \"\$?\"";
    my $at = rindex($script, $marker);
    ok($at >= 0, 'the installer script ends with its main invocation');
    my $functions = substr($script, 0, $at);
    my $invocation = substr($script, $at + length $marker);
    is(trim($invocation), '', 'nothing follows the main invocation');
    spew("$ROOT/scripts/$name", $functions . "\n");
    return "$ROOT/scripts/$name";
}

sub write_executable {
    my ($path, $text) = @_;
    spew($path, $text);
    chmod(0755, $path) or die "chmod $path: $!\n";
    return;
}

# ---------------------------------------------------------------------------------------------------------------------
# Configuration cases.
# ---------------------------------------------------------------------------------------------------------------------

sub case_passwords_survive_make_xml_and_shell {
    setup();
    my $template = "$ROOT/site-template";
    for my $password ('ReviewPlain123', 'Review&Value', qq{a:b|c/d\\e'" <>& \@DB_USER_PASS\@},
        '$(touch INJECTED) `touch INJECTED` $HOME ; * ?', '', "line\nnext\tend") {
        (my $label = $password) =~ s/([^ -~])/sprintf('\\x%02x', ord $1)/ge;
        # GNU Make uses $$ for a literal dollar in variable values.
        (my $value = $password) =~ s/\$/\$\$/g;
        make('conf.context', 'db.conf', "DB_USER_PASS=$value", "DB_ADMIN_PASS=$value");
        is(xml_string("$template/context.xml", '/*/Resource[1]/@password'), $password, "XML password '$label'");
        for my $key (qw(DB_USER_PASS DB_ADMIN_PASS)) {
            is(value("$template/mariadb.conf", $key), $password, "shell $key '$label'");
        }
        ok(!-e "$ROOT/INJECTED", "password '$label' was not executed");
    }
    return;
}

sub case_supported_os_presets_preserve_custom_java_paths {
    setup();
    my $custom = '/custom/review-jdk21';
    spew("$TEMP/CONFIG_SITE.local", "JAVA_HOME := $custom\n");
    for my $preset (qw(debian13 rocky8 rocky10 ubuntu24 ubuntu26)) {
        make("$preset.conf");
        is(trim(make('print-JAVA_HOME')), $custom, "$preset JAVA_HOME");
        is(trim(make('print-JAVA_PATH')), "$custom/bin", "$preset JAVA_PATH");
    }
    return;
}

sub case_database_help_describes_supported_schema_creation {
    setup();
    make('db.conf');
    my $run = run_command(['bash', '-p', 'scripts/mariadb_setup.bash', 'tableCreate'], cwd => $ROOT);
    is($run->{status}, 1, 'tableCreate exits 1');
    my $output = combined($run);
    ok(index($output, 'make sql.fill') >= 0, 'the help names make sql.fill');
    for my $command (qw(tableCreate viewCreate sProcCreate allCreate allViews allDrop)) {
        ok(index($output, $command) < 0, "the help does not name $command");
    }
    return;
}

sub case_password_from_local_override_file {
    setup();
    my $password = q{Local& |/'" $HOME #literal};
    (my $value = $password) =~ s/\$/\$\$/g;
    $value =~ s/#/\\#/g;
    spew("$TEMP/CONFIG_SITE.local", "DB_USER_PASS := $value\n");
    make('conf.context', 'db.conf');
    my $template = "$ROOT/site-template";
    is(xml_string("$template/context.xml", '/*/Resource[1]/@password'), $password, 'XML password');
    is(value("$template/mariadb.conf", 'DB_USER_PASS'), $password, 'shell password');
    return;
}

sub case_database_password_file_is_private_on_creation_and_replacement {
    setup();
    my $config = "$ROOT/site-template/mariadb.conf";
    for my $existing (0, 1) {
        my $label = $existing ? 'replacement' : 'creation';
        if ($existing) {
            chmod(0666, $config) or die "chmod $config: $!\n";
        }
        run_in_root(['bash', '-c', 'umask 000; make --no-print-directory -s db.conf']);
        is((stat $config)[2] & 0777, 0600, "$label: mode 0600");
        is(value($config, 'DB_USER_PASS'), 'archappl', "$label: default password");
    }
    return;
}

sub case_installers_require_clean_source_inputs_in_checkouts_and_worktrees {
    setup();
    my $source = "$ROOT/source";
    run_in_root(['git', 'clone', '--quiet', '--shared', $SOURCE_TOP, $source]);
    my $exclude = "$source/.git/info/exclude";
    make_path(dirname($exclude));
    append($exclude, "\n/.mvn/maven.config\n/.mvn/jvm.config\n/.mvn/extensions.xml\n");
    my $worktree = "$ROOT/source-worktree";
    run_in_root(['git', '-C', $source, 'worktree', 'add', '--quiet', '--detach', $worktree, 'HEAD']);
    for my $tree ($source, $worktree) {
        my $tree_name = basename($tree);
        spew("$ROOT/configure/CONFIG_VARS.local", "SRC_PATH:=$tree_name\n");
        make_path("$tree/src/sitespecific/als");
        spew("$tree/src/sitespecific/als/GeneratedReviewMarker.txt", "Generated site overlay.\n");
        for my $mode (qw(sqlite mariadb-uds mariadb-tcp)) {
            my @entry = ('bash', "scripts/install-local-$mode.bash", '--plan', '--skip-packages');
            my $label = "$tree_name $mode";
            run_in_root(\@entry);
            my $marker = "$tree/src/resources/main/ReviewPinMarker.txt";
            spew($marker, "Untracked build input.\n");
            run_in_root(['git', '-C', $tree, 'diff', '--quiet']);
            my $run = run_command(\@entry, cwd => $ROOT);
            isnt($run->{status}, 0, "$label: untracked file refused");
            ok(index($run->{stderr}, 'untracked files') >= 0, "$label: untracked files named");
            unlink($marker) or die "unlink $marker: $!\n";
            $marker = "$tree/src/resources/main/ReviewPinMarker.swp";
            spew($marker, "Ignored build input.\n");
            $run = run_command(\@entry, cwd => $ROOT);
            isnt($run->{status}, 0, "$label: ignored file refused");
            ok(index($run->{stderr}, 'ignored build inputs') >= 0, "$label: ignored build inputs named");
            unlink($marker) or die "unlink $marker: $!\n";
            for my $name (qw(maven.config jvm.config extensions.xml)) {
                $marker = "$tree/.mvn/$name";
                make_path(dirname($marker));
                spew($marker, "Ignored Maven build configuration.\n");
                run_in_root(['git', '-C', $tree, 'check-ignore', $marker]);
                $run = run_command(\@entry, cwd => $ROOT);
                isnt($run->{status}, 0, "$label $name: ignored Maven configuration refused");
                ok(index($run->{stderr}, 'ignored build inputs') >= 0, "$label $name: ignored build inputs named");
                ok(index($run->{stderr}, ".mvn/$name") >= 0, "$label $name: file named");
                unlink($marker) or die "unlink $marker: $!\n";
            }
            my $tracked = "$tree/pom.xml";
            my $original = slurp($tracked);
            spew($tracked, $original . "\n<!-- Local source modification. -->\n");
            $run = run_command(\@entry, cwd => $ROOT);
            isnt($run->{status}, 0, "$label: tracked change refused");
            ok(index($run->{stderr}, 'tracked changes') >= 0, "$label: tracked changes named");
            spew($tracked, $original);
        }
    }
    return;
}

sub case_tomcat_choices_and_backup_preserve_existing_files {
    setup();
    # Run shipped functions, real Make targets, and real directory moves.
    my $harness = write_functions_harness('tomcat-functions.bash');
    my $home = "$ROOT/tomcat";
    make_path("$home/bin");
    my $marker = "$home/bin/catalina.sh";
    spew($marker, "#!/bin/sh\nexit 0\n");
    chmod(0640, $marker) or die "chmod: $!\n";
    my $original = slurp($marker);
    my $preset = "$ROOT/configure/CONFIG_SITE.local";
    spew($preset, "TOMCAT_INSTALL_LOCATION:=$home\n");
    my $setup = 'source "$1"; tomcat_home="$2"; service_user=review; service_unit=review.service; ';
    my $command = $setup . 'choose_tomcat; printf "Selected: %s\n" "$tomcat_action"';
    for my $case (["1\n", 'existing'], ["2\n", 'replace']) {
        my ($reply, $action) = @{$case};
        my $output = run_in_root(['bash', '-c', $command, 'review', $harness, $home], input => $reply);
        ok(index($output, "Selected: $action") >= 0, "choice $action");
        is(slurp($marker), $original, "choice $action leaves the launcher");
    }
    for my $case (['', ''], ['', "x\n"], ['yes=1; ', '']) {
        my ($prefix, $reply) = @{$case};
        run_in_root(['bash', '-c', $setup . $prefix . 'choose_tomcat', 'review', $harness, $home],
            expected => 1, input => $reply);
        is(slurp($marker), $original, 'a cancelled or invalid choice leaves the launcher');
    }

    spew($preset, "TOMCAT_INSTALL_LOCATION:=$ROOT/default-tomcat\n");
    for my $case (['', "1\n", 0], ['', "2\n", 1], ['plan=1; ', '', 0]) {
        my ($prefix, $reply, $expected) = @{$case};
        my $run = run_command(['bash', '-c', $setup . $prefix . 'choose_tomcat', 'review', $harness, $home],
            input => $reply, cwd => $ROOT);
        is($run->{status}, $expected, "custom path '$prefix' reply exits $expected") or diag(combined($run));
        ok(index($run->{stdout}, '2) Unavailable') >= 0, 'replacement is shown unavailable');
        ok(index($run->{stdout}, '2) Back up') < 0, 'backup is not offered');
        is(slurp($marker), $original, 'the launcher is unchanged');
    }
    spew($preset, "TOMCAT_INSTALL_LOCATION:=$home\n");

    my $boundary = "$ROOT/boundary";
    make_path($boundary);
    my $sudo = "$boundary/sudo";
    write_executable($sudo, qq{#!/bin/bash\nset -eu\nprintf "%s\\n" "\$*" >> "\$BOUNDARY_LOG"\n}
        . qq{while (( \$# )); do\ncase "\$1" in\n-n|--) shift ;;\n-u) shift 2 ;;\n*) break ;;\nesac\ndone\n}
        . qq{exec "\$@"\n});
    write_executable("$boundary/systemctl", qq{#!/bin/bash\nset -eu\nprintf "%s\\n" "\$*" >> "\$BOUNDARY_LOG"\n}
        . qq{case "\$*" in\n*LoadState*) printf "loaded\\n" ;;\n}
        . qq{*ActiveState*) printf "%s\\n" "\${TEST_ACTIVE_STATE:-inactive}" ;;\n}
        . qq{stop*) exit 0 ;;\n*) exit 1 ;;\nesac\n});
    my $log = "$ROOT/boundary.log";
    my %env = (%ENV, BOUNDARY_LOG => $log, TEST_ACTIVE_STATE => 'active');
    $command = $setup . 'PATH="$3:$PATH"; backup_tomcat';
    my @args = ('bash', '-c', $command, 'review', $harness, $home, $boundary);
    run_in_root(\@args, expected => 1, env => \%env);
    is(slurp($marker), $original, 'an active appliance leaves the launcher');
    is(scalar(my @none = bsd_glob("$ROOT/tomcat.backup.*")), 0, 'an active appliance creates no backup');

    $env{TEST_ACTIVE_STATE} = 'inactive';
    run_in_root(\@args, env => \%env);
    my @backups = bsd_glob("$ROOT/tomcat.backup.*");
    is(scalar @backups, 1, 'one backup');
    is(slurp("$backups[0]/tomcat/bin/catalina.sh"), $original, 'the backup holds the original launcher');
    ok(!-e $home, 'the Tomcat directory moved');
    my $trace = slurp($log);
    cmp_ok(rindex($trace, 'stop review.service'), '<', index($trace, 'mktemp'), 'the service stops before the backup');
    cmp_ok(index($trace, 'sd_health_stop'), '<', index($trace, 'mktemp'), 'the monitor stops before the backup');
    ok(index($trace, 'sd_health_stop') >= 0 && index($trace, 'mktemp') >= 0, 'the trace names both steps');
    symlink("$backups[0]/tomcat", $home) or die "symlink: $!\n";
    run_in_root(\@args, expected => 1, env => \%env);
    is(scalar(my @again = bsd_glob("$ROOT/tomcat.backup.*")), 1, 'a symlinked Tomcat creates no second backup');

    # A readable launcher must still be rejected if sudo denies service access.
    unlink($home) or die "unlink $home: $!\n";
    mkdir($home) or die "mkdir $home: $!\n";
    mkdir("$home/bin") or die "mkdir: $!\n";
    my $launcher = "$home/bin/catalina.sh";
    spew($launcher, $original);
    chmod(0100, $launcher) or die "chmod: $!\n";
    $command = $setup . 'PATH="$3:$PATH"; tomcat_action=existing; prepare_tomcat';
    @args = ('bash', '-c', $command, 'review', $harness, $home, $boundary);
    my $run = run_command(\@args, cwd => $ROOT, env => \%env);
    is($run->{status}, 1, 'an unreadable launcher is rejected') or diag(combined($run));
    ok(index($run->{stderr}, "Service user review cannot read $launcher\n") >= 0, 'the exact unreadable launcher is named');
    ok(index(slurp($log), "-n -u review -- test -r $launcher") >= 0, 'sudo tested readability');
    chmod(0755, $launcher) or die "chmod: $!\n";
    spew($sudo, qq{#!/bin/bash\nprintf "%s\\n" "\$*" >> "\$BOUNDARY_LOG"\nexit 1\n});
    $run = run_command(\@args, cwd => $ROOT, env => \%env);
    is($run->{status}, 1, 'a denied execution test is rejected') or diag(combined($run));
    ok(index($run->{stderr}, 'Service user review cannot execute') >= 0, 'the execute refusal is named');
    ok(index(slurp($log), "-n -u review -- test -x $launcher") >= 0, 'sudo tested executability');

    # The entry scripts accept only the generated include in the checkout file, so the site value moves to the parent
    # file.
    spew("$TEMP/CONFIG_SITE.local", "TOMCAT_INSTALL_LOCATION:=$home\n");
    unlink($preset) or die "unlink $preset: $!\n";
    for my $mode (qw(sqlite mariadb-uds mariadb-tcp)) {
        my @entry = ('bash', "scripts/install-local-$mode.bash", '--plan', '--skip-packages');
        run_in_root([@entry, '--tomcat', 'existing']);
        run_in_root([@entry, '--tomcat', 'invalid'], expected => 1);
        run_in_root([@entry, '--tomcat'], expected => 1);
    }
    return;
}

sub case_tomcat_replacement_rejects_protected_paths_before_side_effects {
    setup();
    my $harness = write_functions_harness('tomcat-path-functions.bash');
    my $home = "$ROOT/runtime/tomcat";
    make_path("$home/bin");
    my $marker = "$home/bin/catalina.sh";
    spew($marker, "Existing Tomcat launcher.\n");
    chmod(0640, $marker) or die "chmod: $!\n";
    my $original = slurp($marker);
    my $boundary = "$TEMP/boundary";
    mkdir($boundary) or die "mkdir $boundary: $!\n";
    my $log = "$boundary/commands.log";
    for my $name (qw(sudo systemctl wget curl)) {
        write_executable("$boundary/$name", qq{#!/bin/bash\nprintf "%s\\n" "\$*" >> "\$BOUNDARY_LOG"\nexit 97\n});
    }
    my %env = (%ENV, BOUNDARY_LOG => $log);
    my $preset = "$ROOT/configure/CONFIG_SITE.local";
    my $variables = "$ROOT/configure/CONFIG_VARS.local";
    my $setup = 'source "$1"; PATH="$2:$PATH"; read_settings; ';
    my @keys = qw(SRC_PATH AA_INSTALL_LOCATION ARCHAPPL_STORAGE_TOP ARCHAPPL_SHORT_TERM_FOLDER
        ARCHAPPL_MEDIUM_TERM_FOLDER ARCHAPPL_LONG_TERM_FOLDER ARCHAPPL_SQLITE_FILE);
    my @cases = (['checkout', $ROOT, []],
        ['checkout-with-external-data', $ROOT, [map { [$_, "$TEMP/external-$_"] } @keys]]);
    my $self_link = "$TEMP/self-tomcat";
    symlink('self-tomcat', $self_link) or die "symlink $self_link: $!\n";
    push @cases, ['self-referencing-symlink', $self_link, [map { [$_, "$TEMP/external-$_"] } @keys]];
    for my $key (@keys) {
        # Both containment directions and equality must fail.
        for my $relation (['equal', $home], ['child', "$home/protected"], ['parent', dirname($home)]) {
            push @cases, ["$key-$relation->[0]", $home, [[$key, $relation->[1]]]];
        }
        my $alias = "$TEMP/alias-$key";
        symlink($home, $alias) or die "symlink $alias: $!\n";
        push @cases, ["$key-alias", $home, [[$key, $alias]]];
    }
    for my $case (@cases) {
        my ($name, $candidate, $overrides) = @{$case};
        spew($preset, "TOMCAT_INSTALL_LOCATION:=$candidate\n"
            . join('', map { "$_->[0]:=$_->[1]\n" } grep { $_->[0] ne 'SRC_PATH' } @{$overrides}));
        spew($variables, join('', map { "$_->[0]:=$_->[1]\n" } grep { $_->[0] eq 'SRC_PATH' } @{$overrides}));
        for my $action ('tomcat_action=replace; prepare_tomcat', 'plan=1; tomcat_action=replace; prepare_tomcat',
            'backup_tomcat') {
            my $run = run_command(['bash', '-c', $setup . $action, 'review', $harness, $boundary],
                cwd => $ROOT, env => \%env);
            is($run->{status}, 1, "$name '$action' exits 1") or diag(combined($run));
            ok(index($run->{stderr}, 'Unsafe Tomcat replacement path') >= 0, "$name '$action': path refused");
            ok(!-e $log, "$name '$action': no download or service command ran");
            is(slurp($marker), $original, "$name '$action': launcher unchanged");
            ok(-f "$ROOT/Makefile", "$name '$action': checkout intact");
        }
        if ($candidate eq $home) {
            my $run = run_command(['bash', '-c', $setup . 'choose_tomcat', 'review', $harness, $boundary],
                input => "2\n", cwd => $ROOT, env => \%env);
            is($run->{status}, 1, "$name: replacement choice exits 1") or diag(combined($run));
            ok(index($run->{stdout}, '2) Unavailable') >= 0, "$name: replacement shown unavailable");
            ok(!-e $log, "$name: no command ran for the choice");
        }
    }

    # A shared parent and a lexical prefix are not directory overlap.
    spew($preset, "TOMCAT_INSTALL_LOCATION:=$home\n"
        . join('', map { "$_:=$home-other\n" } grep { $_ ne 'SRC_PATH' } @keys));
    spew($variables, "SRC_PATH:=$home-other\n");
    run_in_root(['bash', '-c', $setup . 'validate_tomcat_replacement', 'review', $harness, $boundary], env => \%env);
    my $output = run_in_root(['bash', '-c', $setup . 'choose_tomcat; printf "Selected: %s\n" "$tomcat_action"',
        'review', $harness, $boundary], input => "2\n", env => \%env);
    ok(index($output, 'Selected: replace') >= 0, 'a sibling path stays eligible');
    ok(!-e $log, 'no command ran for the sibling path');
    is(slurp($marker), $original, 'the launcher is unchanged');
    return;
}

# Starts a local HTTP server that answers every request with a 200 reply after three seconds; returns its port. The
# server process is stopped when the case ends.
sub start_slow_server {
    my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 16, ReuseAddr => 1)
        or die "listen: $!\n";
    my $port = $listener->sockport;
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        $SIG{CHLD} = 'IGNORE';
        $SIG{PIPE} = 'IGNORE';
        while (my $client = $listener->accept) {
            my $worker = fork();
            if (defined $worker && $worker == 0) {
                $listener->close;
                select(undef, undef, undef, 3);
                print {$client} "HTTP/1.0 200 OK\r\nContent-Length: 28\r\n\r\n" . '{"status":"STARTUP_COMPLETE"}';
                POSIX::_exit(0);
            }
            $client->close;
        }
        POSIX::_exit(0);
    }
    $listener->close;
    on_cleanup(sub { kill('TERM', $pid); waitpid($pid, 0); });
    return $port;
}

sub case_installer_readiness_obeys_deadline {
    setup();
    # Invoke the shipped functions without running the system installation.
    my $harness = write_functions_harness('readiness-functions.bash');
    my $boundary = "$ROOT/boundary";
    make_path($boundary);
    my $sudo = "$boundary/sudo";
    my $port = start_slow_server();
    my $url = "http://127.0.0.1:$port/startupState";
    my $command = 'source "$1"; PATH="$2:$PATH"; timeout=1; service_user=review; '
        . 'install_path=/unused; service_unit=review.service; health_timer=review.timer; '
        . 'component_urls=("$3" "$3" "$3" "$3"); mgmt_url="$3"; wait_ready';
    # Only the outer privilege boundary is replaced; HTTP uses real curl.
    for my $action ('exit 1', 'sleep 10') {
        write_executable($sudo, "#!/bin/sh\n$action\n");
        my $started = Time::HiRes::time();
        my $run = run_command(['bash', '-c', $command, 'review', $harness, $boundary, $url], cwd => $ROOT, timeout => 3);
        my $elapsed = Time::HiRes::time() - $started;
        is($run->{status}, 1, "privilege boundary '$action': wait_ready exits 1") or diag(combined($run));
        ok(index($run->{stderr}, 'within 1 seconds') >= 0, "privilege boundary '$action': deadline named");
        cmp_ok($elapsed, '<', 2, "privilege boundary '$action': deadline held");
    }
    $command = 'source "$1"; run_before_deadline "$((SECONDS + 5))" true; run_before_deadline "$SECONDS" true';
    run_in_root(['bash', '-c', $command, 'review', $harness], expected => 124);
    my $marker = "$ROOT/expired-command";
    $command = 'source "$1"; run_before_deadline "$SECONDS" touch "$2"';
    run_in_root(['bash', '-c', $command, 'review', $harness, $marker], expected => 124);
    ok(!-e $marker, 'a command is never started after its deadline');

    # Delay return from the real timeout utility to expose an elapsed deadline after a successful child.
    my $native_timeout = abs_path(which('timeout'));
    write_executable("$boundary/timeout", "#!/bin/bash\n" .
        '"$NATIVE_TIMEOUT" "$@"' . "\nstatus=\$?\nprintf '%s\\n' \"\$status\" > \"\$TIMEOUT_STATUS\"\n" .
        "sleep 2\nexit \"\$status\"\n");
    $command = 'source "$1"; PATH="$2:$PATH"; run_before_deadline "$((SECONDS + 1))" true';
    my %env = (%ENV, NATIVE_TIMEOUT => $native_timeout, TIMEOUT_STATUS => "$boundary/status");
    my $started = Time::HiRes::time();
    run_in_root(['bash', '-c', $command, 'review', $harness, $boundary], env => \%env, expected => 124);
    is(slurp("$boundary/status"), "0\n", 'the real timeout command completed its child successfully');
    cmp_ok(Time::HiRes::time() - $started, '>=', 2, 'the delayed return crossed the actual deadline');
    return;
}

sub case_configured_database_name_reaches_runtime {
    setup();
    my $template = "$ROOT/site-template";
    for my $backend (qw(mariadb sqlite)) {
        for my $key (qw(DB_NAME JDBC_DB_NAME)) {
            my $label = "$backend $key";
            make('conf.context', 'conf.archappl', "DB_BACKEND=$backend", "$key=review_archive");
            my $name = value("$template/archappl.conf", 'ARCHAPPL_DB_NAME');
            is($name, 'review_archive', "$label: ARCHAPPL_DB_NAME");
            is(xml_string("$template/context.xml", '/*/Resource[1]/@name'), "jdbc/$name", "$label: resource name");
            my $exported = run_in_root(['bash', '-c',
                'set -a; source "$1"; bash -c \'printf "%s" "$ARCHAPPL_DB_NAME"\'', 'test', "$template/archappl.conf"]);
            is($exported, 'review_archive', "$label: exported name");
        }
    }
    return;
}

sub case_archappl_render_failure_preserves_existing_configuration {
    setup();
    make('conf.archappl');
    my $config = "$ROOT/site-template/archappl.conf";
    my $previous = slurp($config);
    run_in_root(['make', '-s', 'conf.archappl', 'AA_INSTALL_LOCATION=/tmp/aa:invalid'], expected => 2);
    is(slurp($config), $previous, 'a failed render keeps the existing file');
    unlink($config) or die "unlink $config: $!\n";
    run_in_root(['make', '-s', 'conf.archappl', 'AA_INSTALL_LOCATION=/tmp/aa:invalid'], expected => 2);
    ok(!-e $config, 'a failed render creates no file');
    return;
}

sub case_socket_comments_match_jdbc_and_shell_transport {
    setup();
    my $template = "$ROOT/site-template";
    for my $socket_path ('/tmp/mariadb.sock', '') {
        spew("$TEMP/CONFIG_SITE.local", "DB_SOCKET := $socket_path   # local transport\n");
        make('conf.context', 'db.conf');
        is(value("$template/mariadb.conf", 'DB_SOCKET'), $socket_path, "socket '$socket_path': shell value");
        my $url = xml_string("$template/context.xml", '/*/Resource[1]/@url');
        my $expected = $socket_path ne '' ? "jdbc:mariadb://localhost/archappl?localSocket=$socket_path"
            : 'jdbc:mariadb://127.0.0.1:3306/archappl';
        is($url, $expected, "socket '$socket_path': JDBC URL");
    }
    return;
}

sub case_system_entrypoints_cannot_report_success {
    for my $args (["$TOP/tests/phase3-docker.bash"], ["$TOP/tests/phase4-vm.bash"],
        ["$TOP/tests/run-all-tests.bash", '--system']) {
        my $label = join(' ', map { basename($_) } @{$args});
        my $run = run_command(['bash', @{$args}], timeout => 10);
        is($run->{status}, 77, "$label exits 77") or diag(combined($run));
        unlike(combined($run), qr/\[PASS\]/, "$label reports no PASS");
        like($run->{stderr}, qr/INCOMPLETE/, "$label reports INCOMPLETE");
        if ($args->[-1] eq '--system') {
            like($run->{stdout}, qr/Phase 3/, "$label names Phase 3");
            like($run->{stdout}, qr/Phase 4/, "$label names Phase 4");
        }
    }
    return;
}

sub case_sqlite_configuration_targets_skip_without_prerequisites {
    setup();
    make('db.conf', 'DB_BACKEND=mariadb');
    my $template = "$ROOT/site-template";
    my $config = "$template/mariadb.conf";
    my $original = slurp($config);
    unlink("$template/mariadb.conf.in") or die "unlink: $!\n";
    unlink("$ROOT/scripts/mariadb_setup.bash") or die "unlink: $!\n";
    for my $target (qw(db.conf db.conf.show)) {
        spew("$ROOT/$target", '');
    }
    for my $existing (1, 0) {
        unlink($config) or die "unlink $config: $!\n" if !$existing;
        for my $target (qw(db.conf db.conf.show)) {
            my $label = "$target " . ($existing ? 'with the file' : 'without the file');
            my $out = make($target, 'DB_BACKEND=sqlite');
            ok(index($out, "[SKIP] $target") >= 0, "$label: skip reported");
            if ($existing) {
                is(slurp($config), $original, "$label: file unchanged");
            }
            else {
                ok(!-e $config, "$label: no file created");
            }
        }
    }
    return;
}

sub case_invalid_backends_fail_before_database_prerequisites {
    setup();
    for my $target (qw(conf.context conf.systemd0)) {
        for my $backend ('postgres', '', 'mariadb sqlite') {
            my $run = run_command(['make', '-s', $target, "DB_BACKEND=$backend"], cwd => $ROOT);
            is($run->{status}, 2, "$target rejects backend '$backend'") or diag(combined($run));
            like($run->{stderr}, qr/DB_BACKEND must be one of/, "$target reports the backend error on stderr");
        }
    }
    make('db.conf', 'DB_BACKEND=mariadb');
    my $config = "$ROOT/site-template/mariadb.conf";
    my $original = slurp($config);
    unlink("$ROOT/scripts/mariadb_setup.bash") or die "unlink: $!\n";
    for my $target (@DB_TARGETS, @SQL_TARGETS, @QUERY_TARGETS) {
        spew("$ROOT/$target", '');
        for my $backend ('postgres', '', 'mariadb sqlite', 'mariadb ') {
            my $label = "$target backend '$backend'";
            my $run = run_command(['make', '-s', $target, "DB_BACKEND=$backend"], cwd => $ROOT);
            isnt($run->{status}, 0, "$label: refused") or diag(combined($run));
            ok(index($run->{stderr}, 'DB_BACKEND must be one of') >= 0, "$label: backend message");
            is(slurp($config), $original, "$label: configuration unchanged");
            ok(!-e "$ROOT/site-template/sql/archappl_sqlite_updated.sql", "$label: no SQLite file rendered");
        }
    }
    return;
}

sub case_sqlite_account_operations_reject_without_helper {
    setup();
    unlink("$ROOT/scripts/mariadb_setup.bash") or die "unlink: $!\n";
    for my $target (qw(db.secure db.addAdmin db.rmAdmin)) {
        my $run = run_command(['make', '-s', $target, 'DB_BACKEND=sqlite'], cwd => $ROOT);
        isnt($run->{status}, 0, "$target: refused");
        ok(index($run->{stderr}, 'not supported for DB_BACKEND=sqlite') >= 0, "$target: reason named");
    }
    return;
}

sub case_standalone_helper_never_executes_generated_configuration {
    setup();
    my $config = "$ROOT/site-template/mariadb.conf";
    spew($config, "touch CONFIG_READ\nexit 99\n");
    for my $case (['mariadb', qw(dbShow isDb)], ['sqlite', qw(adminAdd userDrop dbUserCreate)],
        ['postgres', qw(dbShow isDb)], ['', qw(dbShow isDb)]) {
        my ($backend, @actions) = @{$case};
        for my $action (@actions) {
            my $run = run_command(['bash', '-p', 'scripts/mariadb_setup.bash', $action],
                cwd => $ROOT, env => { %ENV, DB_BACKEND => $backend });
            is($run->{status}, 2, "backend '$backend' $action exits 2") or diag(combined($run));
            ok(!-e "$ROOT/CONFIG_READ", "backend '$backend' $action: configuration not executed");
        }
    }
    unlink($config) or die "unlink $config: $!\n";
    spew("$TEMP/CONFIG_SITE.local", "DB_BACKEND:=sqlite\n");
    my %env = %ENV;
    delete $env{DB_BACKEND};
    my $run = run_command(['bash', '-p', 'scripts/mariadb_setup.bash', 'adminAdd'], cwd => $ROOT, env => \%env);
    is($run->{status}, 2, 'adminAdd with a SQLite site file exits 2');
    ok(index($run->{stderr}, 'unsupported for SQLite') >= 0, 'the SQLite refusal is named');
    my %incomplete = (%ENV, DB_BACKEND => 'sqlite', AA_DATABASE_SETTINGS_READY => 1, ARCHAPPL_SQLITE_FILE => '');
    delete $incomplete{DB_ADMIN_HOST};
    $run = run_command(['bash', '-p', 'scripts/mariadb_setup.bash', 'dbShow'], cwd => $ROOT, env => \%incomplete);
    is($run->{status}, 2, 'incomplete Make settings are refused');
    like($run->{stderr}, qr/Incomplete Make settings/, 'the missing Make setting is diagnosed');
    is(count_substring($run->{stderr}, 'Database operation refused:'), 1,
        'settings failure stops before downstream database validation');
    return;
}

# ---------------------------------------------------------------------------------------------------------------------
# Integration cases: root on a disposable host, real SQLite and a private real MariaDB server.
# ---------------------------------------------------------------------------------------------------------------------

sub case_real_sqlite_schema_load_and_list {
    setup();
    my $schema = "$SCHEMA_TOP/archappl_sqlite.sql";
    ok(-f $schema, 'The real SQLite source schema is required');
    my $db = "$TEMP/sqlite/archappl.sqlite";
    my $user = trim(run_in_root(['id', '-un']));
    my $group = trim(run_in_root(['id', '-gn']));
    my @options = ('DB_BACKEND=sqlite', 'APPNAME=aa-m1-python', "AA_USERID=$user", "AA_GROUPID=$group",
        "ARCHAPPL_SQLITE_FILE=$db", "SQL_AA_ORIG_SQLITE=$schema");
    make('db.conf', 'DB_BACKEND=mariadb');
    my $config = "$ROOT/site-template/mariadb.conf";
    my $before = slurp($config);
    make('db.conf', 'db.conf.show', 'db.create', 'db.show', @options);
    make('sql.fill', @options);
    make('sql.fill', @options);
    my $tables = make('sql.show', @options);
    for my $table (qw(ArchivePVRequests ExternalDataServers PVAliases PVTypeInfo)) {
        ok(index($tables, $table) >= 0, "table $table listed");
    }
    run_in_root(['sqlite3', $db, 'DROP TABLE PVAliases;']);
    make('sql.fill', @options);
    ok(index(make('sql.show', @options), 'PVAliases') >= 0, 'a dropped table is restored');
    is(slurp($config), $before, 'the MariaDB configuration is unchanged');
    return;
}

sub case_real_database_credentials_and_account_identity {
    setup();
    my $server = which('mariadbd') // which('mysqld');
    $server //= (grep { -x } qw(/usr/sbin/mariadbd /usr/libexec/mysqld))[0];
    my $initializer = which('mariadb-install-db') // which('mysql_install_db');
    ok(defined $server, 'mariadbd or mysqld is required') or return;
    ok(defined $initializer, 'mariadb-install-db or mysql_install_db is required') or return;
    my $datadir = "$TEMP/data";
    my $sock = "$TEMP/db.sock";
    my $general_log = "$TEMP/general.log";
    my $probe = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1) or die "probe: $!\n";
    my $port = $probe->sockport;
    $probe->close;
    run_in_root([$initializer, '--no-defaults', "--datadir=$datadir", '--auth-root-authentication-method=normal',
        '--skip-test-db']);
    my $process = fork();
    defined $process or die "fork: $!\n";
    if (!$process) {
        open(STDIN, '<', '/dev/null') or POSIX::_exit(126);
        open(STDOUT, '>', '/dev/null') or POSIX::_exit(126);
        open(STDERR, '>', '/dev/null') or POSIX::_exit(126);
        exec { $server } $server, '--no-defaults', '--user=root', "--datadir=$datadir", "--socket=$sock",
            "--pid-file=$datadir/server.pid", "--port=$port", '--bind-address=127.0.0.1',
            "--log-error=$datadir/server.log", '--skip-log-bin', '--general-log', "--general-log-file=$general_log"
            or POSIX::_exit(127);
    }
    on_cleanup(sub {
        kill('TERM', $process);
        waitpid($process, 0);
    });
    my @root = ('mysql', '--no-defaults', '--user=root', "--socket=$sock", '-N', '-B');
    my $ready = 0;
    for (1 .. 150) {
        if (run_command([@root, '-e', 'SELECT 1'])->{status} == 0) {
            $ready = 1;
            last;
        }
        if (waitpid($process, POSIX::WNOHANG()) != 0) {
            fail('The private MariaDB exited: ' . (-f "$datadir/server.log" ? slurp("$datadir/server.log") : ''));
            return;
        }
        select(undef, undef, undef, 0.1);
    }
    ok($ready, 'Private MariaDB became ready') or return;
    run_in_root([@root, '-e', q{CREATE USER 'admin'@'localhost'; CREATE USER 'admin'@'127.0.0.1';}]);
    my $password = q{Review& :|/\\ '" $HOME $(touch INJECTED) `touch INJECTED` ; *};
    (my $make_password = $password) =~ s/\$/\$\$/g;
    my @common = ('DB_ADMIN=review_admin', 'DB_USER=review_user', 'DB_NAME=review_archive',
        'DB_HOST_NAME=127.0.0.1', "DB_HOST_PORT=$port", "DB_ADMIN_PASS=$make_password",
        "DB_USER_PASS=$make_password");
    my $settings = sub {
        my (@transport) = @_;
        my @values = (@common, @transport, 'APPNAME=aa-m1-python');
        spew("$ROOT/configure/CONFIG_SITE.local", join('', map { s/=/ := /r . "\n" } @values));
    };
    $settings->("DB_SOCKET=$sock");
    make('db.conf');
    my @helper = ('bash', '-p', 'scripts/mariadb_setup.bash');
    run_in_root([@helper, 'adminAdd']);
    run_in_root([@helper, 'hostnameAdminAdd']);
    make('db.secure', @common, "DB_SOCKET=$sock");
    ok(index(run_in_root(['mysql', '--no-defaults', '--user=root', '--protocol=tcp', '--host=127.0.0.1',
        "--port=$port", '-N', '-B', '-e', 'SELECT CURRENT_USER()']), 'root@localhost') >= 0,
        'root over TCP is root@localhost');
    my $schema = "$SCHEMA_TOP/archappl_mysql.sql";
    ok(-f $schema, 'The real source schema is required');
    spew("$TEMP/CONFIG_SITE.local", "DB_SOCKET := $sock # local socket\n");
    for my $transport ([], ['DB_SOCKET=']) {
        my $kind = @{$transport} ? 'tcp' : 'socket';
        $settings->(@{$transport} ? @{$transport} : ("DB_SOCKET=$sock"));
        make('db.conf', @common, @{$transport});
        my $create_output = run_in_root([@helper, 'dbUserCreate']);
        ok(index($create_output, 'Password') < 0, "$kind: account creation prints no password");
        unlike($create_output, qr/\*[0-9A-Fa-f]{40}\b/, "$kind: account creation prints no hash");
        my $host = @{$transport} ? '127.0.0.1' : 'localhost';
        ok(index(run_in_root([@helper, 'query', 'SELECT CURRENT_USER()']), "review_user\@$host") >= 0,
            "$kind: account identity");
        make('sql.fill', "SQL_AA_ORIG_SQL=$schema");
        run_in_root([@helper, 'query', q{SELECT 'query-ok'}]);
        my $sql = "$TEMP/query file.sql";
        spew($sql, "SELECT 'file-ok';\n");
        ok(index(run_in_root([@helper, 'queryFile', $sql, '-N']), 'file-ok') >= 0, "$kind: queryFile");
        run_in_root([@helper, 'query',
            q{INSERT INTO ExternalDataServers (serverid, serverinfo) VALUES ('review-marker', 'http://localhost');}]);
        ok(index(make('DataServers.show'), 'review-marker') >= 0, "$kind: inserted row listed");
        my $config = "$ROOT/site-template/mariadb.conf";
        my $before_config = slurp($config);
        my $before_log = slurp($general_log);
        for my $backend ('sqlite', 'postgres', '', 'mariadb sqlite') {
            for my $target (@DB_TARGETS, @SQL_TARGETS, @QUERY_TARGETS) {
                next if $backend eq 'sqlite' && !grep { $_ eq $target } qw(db.conf db.conf.show db.secure db.addAdmin
                    db.rmAdmin);
                my @args = ('make', '-s', $target, @common, "DB_BACKEND=$backend");
                if ($backend eq 'sqlite' && ($target eq 'db.conf' || $target eq 'db.conf.show')) {
                    ok(index(run_in_root(\@args), '[SKIP]') >= 0, "$kind: $target for SQLite is skipped");
                }
                else {
                    run_in_root(\@args, expected => 2);
                }
            }
            for my $action (@HELPER_ACTIONS) {
                next if $backend eq 'sqlite' && !grep { $_ eq $action } qw(secureSetup adminAdd adminRemove
                    localAdminAdd hostnameAdminAdd localAdminRemove hostnameAdminRemove userDrop dbUserCreate
                    dbUserDrop);
                run_in_root([@helper, $action], expected => 2, env => { %ENV, DB_BACKEND => $backend });
            }
        }
        is(slurp($general_log), $before_log, "$kind: a skip or rejection does not connect to MariaDB");
        is(slurp($config), $before_config, "$kind: the configuration is unchanged");
        ok(index(make('DataServers.show'), 'review-marker') >= 0, "$kind: the row remains");
        my $backup = "$TEMP/backup $host";
        # Keep immediate collision assertions inside one native minute.
        my $second = (localtime)[0];
        sleep(60 - $second) if $second >= 50;
        run_in_root([@helper, 'dbBackup', $backup]);
        my ($archive) = bsd_glob("$backup/review_archive_*.sql.gz");
        ok(defined $archive, "$kind: a backup archive exists") or return;
        run_in_root(['gzip', '-t', $archive]);
        is((stat $archive)[2] & 0777, 0600, "$kind: archive mode 0600");
        my $original = slurp($archive);
        my $collision_run = run_command([@helper, 'dbBackup', $backup], cwd => $ROOT);
        is($collision_run->{status}, 1, "$kind: an existing backup is refused");
        like($collision_run->{stderr}, qr/Backup already exists; refusing to overwrite:/,
            "$kind: the existing backup is refused before starting another dump");
        is(slurp($archive), $original, "$kind: a second backup in the same minute leaves the archive");
        my $collision = "$TEMP/symlink $host";
        mkdir($collision) or die "mkdir $collision: $!\n";
        my $link = "$collision/" . basename($archive);
        symlink("$collision/absent", $link) or die "symlink: $!\n";
        run_in_root([@helper, 'dbBackup', $collision], expected => 1);
        ok(-l $link, "$kind: the colliding symlink remains");
        ok(!-e $link, "$kind: the symlink target was not created");
        # Race real dump publication against an independent filesystem writer.
        run_in_root([@helper, 'query',
            q{CREATE TABLE ReviewRace(payload LONGBLOB); INSERT INTO ReviewRace VALUES(REPEAT('x',1048576));}]);
        run_in_root([@helper, 'query', 'INSERT INTO ReviewRace SELECT payload FROM ReviewRace;']) for 1 .. 6;
        my $competing = "$TEMP/competing $host";
        my $contender = fork();
        defined $contender or die "fork: $!\n";
        if (!$contender) {
            chdir($ROOT) or POSIX::_exit(126);
            open(STDIN, '<', '/dev/null') or POSIX::_exit(126);
            open(STDOUT, '>', '/dev/null') or POSIX::_exit(126);
            open(STDERR, '>', '/dev/null') or POSIX::_exit(126);
            exec { $helper[0] } @helper, 'dbBackup', $competing or POSIX::_exit(127);
        }
        my ($destination, $contender_status);
        for (1 .. 3000) {
            my ($temporary) = bsd_glob("$competing/.review_archive_*");
            if (defined $temporary) {
                my $stem = basename($temporary);
                $stem =~ s/\A\.//;
                $stem =~ s/\..*\z//;
                $destination = "$competing/$stem.sql.gz";
                sysopen(my $stream, $destination, O_WRONLY | O_CREAT | O_EXCL) or die "create $destination: $!\n";
                print {$stream} "competitor\n";
                close($stream) or die "close $destination: $!\n";
                last;
            }
            if (waitpid($contender, POSIX::WNOHANG()) == $contender) {
                $contender_status = $?;
                last;
            }
            select(undef, undef, undef, 0.002);
        }
        ok(defined $destination, "$kind: actual dump staging was observed") or return;
        if (!defined $contender_status) {
            eval {
                local $SIG{ALRM} = sub { die "timeout\n" };
                alarm 30;
                waitpid($contender, 0);
                $contender_status = $?;
                alarm 0;
                1;
            } or do {
                alarm 0;
                kill('KILL', $contender);
                waitpid($contender, 0);
                $contender_status = $?;
            };
        }
        isnt($contender_status >> 8, 0, "$kind: the dump yields to the competing file");
        is(slurp($destination), "competitor\n", "$kind: the competing file is intact");
        run_in_root([@helper, 'query', 'DROP TABLE ReviewRace;']);
        run_in_root([@root, '-e', "REVOKE LOCK TABLES ON review_archive.* FROM 'review_user'\@'$host'"]);
        my $failed = "$TEMP/failed $host";
        run_in_root([@helper, 'dbBackup', $failed], expected => 1);
        opendir(my $dir, $failed) or die "opendir $failed: $!\n";
        my @left = grep { $_ ne '.' && $_ ne '..' } readdir($dir);
        closedir($dir);
        is(scalar @left, 0, "$kind: a failed dump leaves nothing");
        run_in_root([@helper, 'dbBackup', $backup], expected => 1);
        is(slurp($archive), $original, "$kind: the archive is unchanged");
        my $stamp = basename($archive);
        $stamp =~ s/\Areview_archive_//;
        $stamp =~ s/\.sql\.gz\z//;
        run_in_root([@helper, 'query', 'DELETE FROM ExternalDataServers']);
        run_in_root([@helper, 'dbRestore', $stamp, $backup]);
        ok(index(make('DataServers.show'), 'review-marker') >= 0, "$kind: the restore returns the row");
        run_in_root([@helper, 'tableShow']);
        run_in_root([@helper, 'aaShow', 'ReviewMissingTable'], expected => 1);
        # The empty-table result succeeds; a real missing table must fail through Make.
        run_in_root([@helper, 'query', 'DELETE FROM ExternalDataServers']);
        make('DataServers.show');
        run_in_root([@helper, 'query', 'DROP TABLE ExternalDataServers']);
        run_in_root(['make', '--no-print-directory', '-s', 'DataServers.show'], expected => 2);
        run_in_root([@helper, 'tableDrop']);
        # Primary account changes succeed; a real denied metadata query must propagate.
        run_in_root([@root, '-e', join(' ', map {
            "REVOKE SELECT ON *.* FROM 'review_admin'\@'$_'; "
            . "GRANT SELECT ON review_archive.* TO 'review_admin'\@'$_' WITH GRANT OPTION;"
        } ('localhost', '127.0.0.1'))]);
        for my $step (['dbUserCreate', 1], ['userDrop', 0], ['dbUserCreate', 1], ['dbUserDrop', 0]) {
            my ($action, $exists) = @{$step};
            my $run = run_command([@helper, $action], cwd => $ROOT);
            is($run->{status}, 1, "$kind: $action with a denied listing exits 1") or diag(combined($run));
            ok(index($run->{stderr}, 'Listing') >= 0, "$kind: $action names the denied listing");
            my $accounts = run_in_root([@root, '-e',
                "SELECT User FROM mysql.user WHERE User='review_user' AND Host='$host'"]);
            is(trim($accounts) ne '' ? 1 : 0, $exists, "$kind: account existence after $action");
        }
        run_in_root([@root, '-e', join(' ', map {
            "GRANT SELECT ON *.* TO 'review_admin'\@'$_' WITH GRANT OPTION;"
        } ('localhost', '127.0.0.1'))]);
        run_in_root([@helper, 'dbUserCreate']);
        my $output = run_in_root([@helper, 'userDrop']);
        unlike($output, qr/\*[0-9A-Fa-f]{40}\b/, "$kind: userDrop prints no hash");
        ok(index($output, 'authentication_string') < 0, "$kind: userDrop prints no authentication string");
        run_in_root([@helper, 'dbUserCreate']);
        $output = make('db.drop', @common, @{$transport});
        unlike($output, qr/\*[0-9A-Fa-f]{40}\b/, "$kind: db.drop prints no hash");
        ok(index($output, 'Password') < 0, "$kind: db.drop prints no password");
        ok(index($output, 'authentication_string') < 0, "$kind: db.drop prints no authentication string");
    }
    $settings->("DB_SOCKET=$sock");
    make('db.conf', @common, "DB_SOCKET=$sock");
    run_in_root([@helper, 'hostnameAdminRemove']);
    run_in_root([@helper, 'adminRemove']);
    my $users = run_in_root([@root, '-e',
        q{SELECT User, Host FROM mysql.user WHERE User IN ('admin','review_admin','review_user') ORDER BY User, Host}]);
    is_deeply([split /\n/, $users], ["admin\t127.0.0.1", "admin\tlocalhost"], 'unrelated admin accounts are preserved');
    ok(!-e "$ROOT/INJECTED", 'no password was executed');
    print "Real MariaDB: socket and TCP account/query/schema/backup/restore paths passed; unrelated admin accounts preserved.\n";
    return;
}

my @CASES = (
    ['passwords_survive_make_xml_and_shell', 'passwords survive Make, XML and shell', \&case_passwords_survive_make_xml_and_shell],
    ['supported_os_presets_preserve_custom_java_paths', 'supported OS presets preserve custom Java paths', \&case_supported_os_presets_preserve_custom_java_paths],
    ['database_help_describes_supported_schema_creation', 'database help describes supported schema creation', \&case_database_help_describes_supported_schema_creation],
    ['password_from_local_override_file', 'password from the local override file', \&case_password_from_local_override_file],
    ['database_password_file_is_private_on_creation_and_replacement', 'database password file is private on creation and replacement', \&case_database_password_file_is_private_on_creation_and_replacement],
    ['installers_require_clean_source_inputs_in_checkouts_and_worktrees', 'installers require clean source inputs in checkouts and worktrees', \&case_installers_require_clean_source_inputs_in_checkouts_and_worktrees],
    ['tomcat_choices_and_backup_preserve_existing_files', 'Tomcat choices and backup preserve existing files', \&case_tomcat_choices_and_backup_preserve_existing_files],
    ['tomcat_replacement_rejects_protected_paths_before_side_effects', 'Tomcat replacement rejects protected paths before side effects', \&case_tomcat_replacement_rejects_protected_paths_before_side_effects],
    ['installer_readiness_obeys_deadline', 'installer readiness obeys the deadline', \&case_installer_readiness_obeys_deadline],
    ['configured_database_name_reaches_runtime', 'configured database name reaches runtime', \&case_configured_database_name_reaches_runtime],
    ['archappl_render_failure_preserves_existing_configuration', 'archappl render failure preserves existing configuration', \&case_archappl_render_failure_preserves_existing_configuration],
    ['socket_comments_match_jdbc_and_shell_transport', 'socket comments match JDBC and shell transport', \&case_socket_comments_match_jdbc_and_shell_transport],
    ['system_entrypoints_cannot_report_success', 'system entry points cannot report success', \&case_system_entrypoints_cannot_report_success],
    ['sqlite_configuration_targets_skip_without_prerequisites', 'SQLite configuration targets skip without prerequisites', \&case_sqlite_configuration_targets_skip_without_prerequisites],
    ['invalid_backends_fail_before_database_prerequisites', 'invalid backends fail before database prerequisites', \&case_invalid_backends_fail_before_database_prerequisites],
    ['sqlite_account_operations_reject_without_helper', 'SQLite account operations reject without the helper', \&case_sqlite_account_operations_reject_without_helper],
    ['standalone_helper_never_executes_generated_configuration', 'standalone helper never executes generated configuration', \&case_standalone_helper_never_executes_generated_configuration],
);

my @INTEGRATION_CASES = (
    ['real_sqlite_schema_load_and_list', 'real SQLite schema load and list', \&case_real_sqlite_schema_load_and_list],
    ['real_database_credentials_and_account_identity', 'real database credentials and account identity', \&case_real_database_credentials_and_account_identity],
);

sub main {
    my (@arguments) = @_;
    my ($help, $integration, @wanted);
    GetOptionsFromArray(\@arguments, 'help' => \$help, 'integration' => \$integration, 'case=s' => \@wanted)
        or return usage_error('database-config.pl', __FILE__);
    if ($help) {
        pod2usage(-verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        print "\nConfiguration cases:\n", map({ "  $_->[0]\n" } @CASES);
        print "\nIntegration cases (with --integration):\n", map({ "  $_->[0]\n" } @INTEGRATION_CASES);
        return 0;
    }
    return usage_error('database-config.pl', __FILE__, 'unexpected argument: ' . $arguments[0]) if @arguments;
    my @set = $integration ? @INTEGRATION_CASES : @CASES;
    my %known = map { $_->[0] => 1 } @set;
    for my $name (@wanted) {
        return usage_error('database-config.pl', __FILE__, "unknown case: $name") unless $known{$name};
    }
    if ($integration && ($> != 0 || ($ENV{AA_TEST_DISPOSABLE_HOST} // '') ne 'YES')) {
        print STDERR "INCOMPLETE: --integration requires root and AA_TEST_DISPOSABLE_HOST=YES on a disposable "
            . "systemd guest.\n";
        return 77;
    }
    my %chosen = map { $_ => 1 } @wanted;
    my @selected = grep { !@wanted || $chosen{ $_->[0] } } @set;
    $capture_dir = tempdir('aa-db-config-capture-XXXXXX', DIR => temp_root(), CLEANUP => 1);
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
    print STDERR "database-config.pl: $error";
    $status = 2;
};
exit $status;
