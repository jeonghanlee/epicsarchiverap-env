#!/usr/bin/env perl
# Verifies config.d through the real install rules, the installed Tomcat wrappers and four real WARs.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA ();
use File::Basename qw(basename dirname);
use File::Glob qw(bsd_glob);
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use IO::Select ();
use IO::Socket::INET ();
use IO::Uncompress::Unzip qw($UnzipError);
use JSON::PP ();
use Pod::Usage qw(pod2usage);
use POSIX ();
use Socket qw(PF_INET SOCK_STREAM SOL_SOCKET SO_REUSEADDR inet_aton sockaddr_in);

=head1 NAME

config-d-runtime.pl - check the config.d layer of an installed appliance with real Tomcat, Java and WAR files

=head1 SYNOPSIS

  perl tests/config-d-runtime.pl --tomcat-home <tomcat_home> --war-dir <war_directory> [--port-base <port>]
  perl tests/config-d-runtime.pl --help

=head1 DESCRIPTION

Installs the appliance with the shipped Make rules into a fresh temporary directory (SQLite backend, no systemd
units) and starts the four real applications through the installed launcher: the generated wrappers directly with
globbing disabled, the manual startup and restart actions, and the foreground service action. After each start it
compares the environment and the command line of the four JVMs with the settings of the config.d files, checks that the
health and status actions read the threshold, edits a config.d file while the service runs (the running JVMs keep the
old environment, health reads the new threshold) and restarts the service. Last, a config.d file with a syntax error
must make the launcher and every generated wrapper fail and name the file, with and without bash -f.
The installed loader must restore allexport, component assignments must reach the real JVM environment, and shutdown
must remove stale PID files containing the PID of a real child that the test has already reaped.

A failed run, or a run with KEEP_WORKSPACE=1, keeps the directory archappl-config-runtime-* below TMPDIR, else below
work/scratch/tmp of the checkout, which the test creates when it is missing, and prints its path: installed files, source
hashes, commands, application logs, readiness responses, JVM observations and the verdict. A passing run removes it.
SIGINT and SIGTERM stop the JVMs before the test ends with status 130 or 143.

Required: Java of the version the WARs were compiled for (21 for the current source) first on the PATH, a readable and
executable Tomcat 9 distribution, built appliance WARs with the folder tomcat-log4j beside them, journald, unused
local ports (offsets 0 to 3 for HTTP, 5 for the cluster, 10 to 13 for shutdown; a port that a process listens on fails
the check), and the programs bash, make, git, sqlite3 and unzip. AA_TEST_SOURCE_PATH must name the real Git source
checkout; its default is the parent of the WAR directory. Required Perl modules
beyond the core of Perl 5.26: none, but on Rocky Linux Digest::SHA is the separate package perl-Digest-SHA,
IO::Uncompress::Unzip the package perl-IO-Compress and JSON::PP the package perl-JSON-PP.

=head1 OPTIONS

=over 4

=item B<--tomcat-home> I<directory>

Tomcat 9 installation whose bin/startup.sh, bin/shutdown.sh and bin/catalina.sh are readable and executable.

=item B<--war-dir> I<directory>

Directory with the four built WAR files and, beside them, the folder tomcat-log4j.

=item B<--port-base> I<port>

First of the local ports; default 29665, at most 65522.

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when every check passed, 1 when a check failed, 2 for a usage error or an environment error, 130 or 143 after SIGINT
or SIGTERM.

=cut

my @SERVICES = qw(mgmt engine etl retrieval);
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

# A folder that this run created below the temporary folder: absolute, not a link, equal to its resolved path.
sub run_folder_is_safe {
    my ($path) = @_;
    return 0 unless defined $path && $path =~ m{\A/} && -d $path && !-l $path;
    my $resolved = abs_path($path);
    my $root = temp_root();
    return defined $resolved && $resolved eq $path && index($path, "$root/") == 0;
}

# Ends a folder of this run: removed after a pass, kept and named after a failure or with KEEP_WORKSPACE=1.
sub finish_workspace {
    my ($path, $passed) = @_;
    return unless defined $path && -e $path;
    if ($passed && ($ENV{KEEP_WORKSPACE} // '') ne '1' && run_folder_is_safe($path)) {
        remove_tree($path);
        return;
    }
    print "Workspace retained: $path\n";
    return;
}

my $INTERRUPT;

$| = 1;

sub fail($) {
    my ($message) = @_;
    die "ASSERTION: $message\n";
}

sub check($$) {
    my ($condition, $message) = @_;
    $condition or fail($message);
    return;
}

sub slurp {
    my ($path) = @_;
    open(my $handle, '<:raw', $path) or die "open $path: $!\n";
    local $/;
    my $data = <$handle>;
    close($handle) or die "close $path: $!\n";
    return $data // '';
}

sub spew {
    my ($path, $data, $mode) = @_;
    my $flags = $mode && $mode eq 'append' ? '>>:raw' : '>:raw';
    open(my $handle, $flags, $path) or die "open $path: $!\n";
    print {$handle} $data or die "write $path: $!\n";
    close($handle) or die "close $path: $!\n";
    return;
}

# Quotes a word for a shell the way Python shlex.quote does.
sub shell_quote {
    my ($text) = @_;
    return "''" if $text eq '';
    return $text unless $text =~ m{[^A-Za-z0-9_@%+=:,./-]};
    $text =~ s/'/'"'"'/g;
    return "'$text'";
}

sub json_text {
    my ($data) = @_;
    return JSON::PP->new->canonical->pretty->indent_length(2)->encode($data);
}

sub which {
    my ($name) = @_;
    for my $directory (split /:/, $ENV{PATH} // '') {
        next if $directory eq '';
        return "$directory/$name" if -f "$directory/$name" && -x _;
    }
    return;
}

sub pause_for {
    my ($seconds) = @_;
    select(undef, undef, undef, $seconds);
    return;
}

# State letter of a process; empty when the process is gone.
sub process_state {
    my ($pid) = @_;
    my $text = eval { slurp("/proc/$pid/stat") };
    return unless defined $text;
    my $at = rindex($text, ') ');
    return if $at < 0;
    return substr($text, $at + 2, 1);
}

# Copies a tree, following links, and keeps the modes and the modification times that the Make rules compare.
sub copy_tree {
    my ($source, $target) = @_;
    mkdir($target) or die "mkdir $target: $!\n";
    opendir(my $directory, $source) or die "opendir $source: $!\n";
    my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir($directory);
    closedir($directory);
    for my $name (@names) {
        my $from = "$source/$name";
        my $to = "$target/$name";
        if (-d $from) {
            copy_tree($from, $to);
            next;
        }
        copy_file($from, $to);
    }
    my @stat = stat($source) or die "stat $source: $!\n";
    chmod($stat[2] & 07777, $target) or die "chmod $target: $!\n";
    utime($stat[8], $stat[9], $target) or die "utime $target: $!\n";
    return;
}

sub copy_file {
    my ($from, $to) = @_;
    spew($to, slurp($from));
    my @stat = stat($from) or die "stat $from: $!\n";
    chmod($stat[2] & 07777, $to) or die "chmod $to: $!\n";
    utime($stat[8], $stat[9], $to) or die "utime $to: $!\n";
    return;
}

sub sha256_file {
    my ($path) = @_;
    return Digest::SHA->new(256)->addfile($path, 'b')->hexdigest;
}

# Runs a command in / with the output in two files; returns the status (negative for a signal), stdout and stderr.
sub command {
    my ($state, $arguments, %option) = @_;
    my $expected = $option{expected} // 0;
    my $timeout = $option{timeout} // 120;
    my $stdout = "$state->{root}/command.out";
    my $stderr = "$state->{root}/command.err";
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        chdir('/') or POSIX::_exit(126);
        open(STDOUT, '>', $stdout) or POSIX::_exit(126);
        open(STDERR, '>', $stderr) or POSIX::_exit(126);
        { no warnings 'exec'; exec { $arguments->[0] } @{$arguments}; }
        POSIX::_exit(127);
    }
    my $deadline = time() + $timeout;
    my $status;
    my $ok = eval {
        while (1) {
            my $result = waitpid($pid, POSIX::WNOHANG());
            if ($result == $pid) {
                $status = $?;
                last;
            }
            if (time() >= $deadline) {
                kill('KILL', $pid);
                waitpid($pid, 0);
                fail('Command timed out after ' . $timeout . ' seconds: ' . join(' ', map { shell_quote($_) } @{$arguments}));
            }
            pause_for(0.05);
        }
        1;
    };
    if (!$ok) {
        my $error = $@;
        if (!defined $status) {
            kill('TERM', $pid);
            waitpid($pid, 0);
        }
        die $error;
    }
    my $code = ($status & 127) ? -($status & 127) : $status >> 8;
    my $out = slurp($stdout);
    my $err = slurp($stderr);
    spew("$state->{root}/commands.log",
        'command=' . join(' ', map { shell_quote($_) } @{$arguments}) . "\nexit=$code\n$out$err\n", 'append');
    check($code == $expected, 'Command exited ' . $code . ', expected ' . $expected . ': '
        . join(' ', map { shell_quote($_) } @{$arguments}) . "\n$out$err");
    return { code => $code, stdout => $out, stderr => $err };
}

sub make {
    my ($state, @targets) = @_;
    return command($state, [@{$state->{make_args}}, @targets]);
}

# One HTTP request over a plain socket; returns the body or dies with the reason, one second per operation.
sub http_get {
    my ($port, $path) = @_;
    my $socket = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Timeout => 1)
        or die "connection refused or timed out on port $port\n";
    print {$socket} "GET $path HTTP/1.0\r\nHost: 127.0.0.1:$port\r\nConnection: close\r\n\r\n"
        or die "write failed on port $port\n";
    my $select = IO::Select->new($socket);
    my ($response, $deadline) = ('', time() + 5);
    while (1) {
        die "read timed out on port $port\n" if !$select->can_read(1) || time() >= $deadline;
        my $read = sysread($socket, my $buffer, 65536);
        die "read failed on port $port: $!\n" if !defined $read;
        last if $read == 0;
        $response .= $buffer;
    }
    close($socket);
    my ($head, $body) = split /\r\n\r\n/, $response, 2;
    my ($code, $reason) = ($head // '') =~ m{\AHTTP/\d\.\d (\d+) ?([^\r\n]*)} or die "bad response on port $port\n";
    die "HTTP Error $code: $reason\n" if $code !~ /\A2/;
    return $body // '';
}

sub edit {
    my ($state, $value, $threshold) = @_;
    spew("$state->{installed}/config.d/90-site.conf",
        'CONFIG_TEST_LIVE=' . shell_quote($value) . "\nCONFIG_TEST_EMPTY=''\nARCHAPPL_STORAGE_ALARM_PERCENT=$threshold\n");
    return;
}

sub prepare {
    my ($state) = @_;
    my $first = $state->{port_base};
    check($first >= 1024 && $first <= 65522, 'Port base must leave room for HTTP, cluster, and shutdown ports');
    for my $name (qw(startup.sh shutdown.sh catalina.sh)) {
        my $path = "$state->{tomcat_home}/bin/$name";
        check(-r $path && -x $path, "Tomcat script is not readable and executable: $path");
    }
    for my $port ($first .. $first + 3, $first + 10 .. $first + 13, $first + 5) {
        socket(my $probe, PF_INET, SOCK_STREAM, 0) or die "socket: $!\n";
        # Address reuse lets closed connections that still hold the port pass; a listening socket still fails the bind.
        setsockopt($probe, SOL_SOCKET, SO_REUSEADDR, pack('l', 1)) or die "setsockopt: $!\n";
        bind($probe, sockaddr_in($port, inet_aton('127.0.0.1'))) or fail("Port $port is not free: $!");
        close($probe);
    }
    mkdir($state->{checkout}) or die "mkdir $state->{checkout}: $!\n";
    mkdir($state->{installed}) or die "mkdir $state->{installed}: $!\n";
    for my $name (qw(configure site-template scripts)) {
        copy_tree("$TOP/$name", "$state->{checkout}/$name");
    }
    copy_file("$TOP/Makefile", "$state->{checkout}/Makefile");
    my $java = which('java') // die "java was not found on the PATH\n";
    $state->{java} = abs_path($java);
    my $java_home = dirname(dirname($state->{java}));
    my $source = $ENV{AA_TEST_SOURCE_PATH} // dirname($state->{war_dir});
    command($state, ['git', '-C', $source, 'rev-parse', '--verify', 'HEAD']);
    my $store = "$state->{root}/store";
    mkdir($store) or die "mkdir $store: $!\n";
    for my $name (qw(sts mts lts)) {
        make_path("$store/$name/ArchiverStore");
    }
    my $user = (getpwuid($<))[0] // die "no account name for uid $<\n";
    my $group = (getgrgid((split ' ', $()[0]))[0] // die "no group name for gid $(\n";
    my @make = ('make', '--no-print-directory', '-C', $state->{checkout}, 'SUDO=', "AA_USERID=$user", "AA_GROUPID=$group",
        "AA_INSTALL_LOCATION=$state->{installed}", "JAVA_HOME=$java_home", "TOMCAT_HOME=$state->{tomcat_home}",
        'DB_BACKEND=sqlite', "ARCHAPPL_SQLITE_FILE=$state->{root}/archappl.sqlite", "ARCHAPPL_STORAGE_TOP=$store",
        'ARCHAPPL_STORAGE_ALARM_PERCENT=100', "ARCHAPPL_WARS_TARGET_PATH=$state->{war_dir}",
        "SRC_PATH=$source",
        'ARCHAPPL_HOST_IPADDR=127.0.0.1', 'ARCHAPPL_CLUSTER_INETPORT=127.0.0.1:' . ($first + 5));
    for my $offset (0 .. $#SERVICES) {
        my $upper = uc $SERVICES[$offset];
        push @make, "ARCHAPPL_${upper}_PORT=" . ($first + $offset), "ARCHAPPL_SHUTDOWN_${upper}_PORT=" . ($first + 10 + $offset);
    }
    $state->{make_args} = \@make;
    make($state, 'conf.archapplproperties', 'conf.install');
    make($state, 'services.install', 'serveroption.install');
    my @wars = bsd_glob("$state->{war_dir}/*-mgmt.war");
    check(@wars == 1, 'Expected one mgmt WAR in ' . $state->{war_dir} . ', found ' . scalar(@wars));
    my $zip = IO::Uncompress::Unzip->new($wars[0], Name => 'install/archappl_sqlite.sql')
        or die "unzip $wars[0]: $UnzipError\n";
    my $schema = do { local $/; <$zip> };
    close($zip);
    check(defined $schema && $schema ne '', "install/archappl_sqlite.sql is missing from $wars[0]");
    spew("$state->{root}/schema.sql", $schema);
    my $load = command($state, ['sqlite3', "$state->{root}/archappl.sqlite", ".read $state->{root}/schema.sql"]);
    check($load->{stderr} eq '', "sqlite3 reported: $load->{stderr}");
    spew("$state->{installed}/config.d/10-common.conf",
        q{CONFIG_TEST_NEW='quoted value * $literal'} . "\nCONFIG_TEST_EMPTY=nonempty\n"
        . 'PATH=' . shell_quote("$state->{root}/path-prefix") . q{:"$PATH"} . "\n"
        . "EPICS_CA_ADDR_LIST=127.0.0.1\nEPICS_CA_AUTO_ADDR_LIST=NO\n"
        . q{CATALINA_OPTS='-Xms64m -Xmx256m -XX:ActiveProcessorCount=2 -Dconfig.common=present'} . "\n");
    spew("$state->{installed}/engine/conf/engine.conf",
        "\n" . q{CATALINA_OPTS="$CATALINA_OPTS -Dconfig.component=engine"} . "\nCONFIG_TEST_COMPONENT=engine\n", 'append');
    edit($state, 'initial', 100);
    my @members = map { "$state->{installed}/$_" } qw(archappl.conf archappl.bash archappl-config.bash);
    for my $name (@SERVICES) {
        push @members, map { "$state->{installed}/$name/bin/$_" } qw(startup.sh shutdown.sh run.sh setenv.sh);
    }
    push @members, bsd_glob("$state->{war_dir}/*.war");
    spew("$state->{root}/sources.json", json_text({ map { $_ => sha256_file($_) } @members }));
    return;
}

# Child state of the foreground service launcher: true while it runs.
sub supervisor_running {
    my ($state) = @_;
    my $supervisor = $state->{supervisor};
    return 0 if !$supervisor || defined $supervisor->{status};
    my $result = waitpid($supervisor->{pid}, POSIX::WNOHANG());
    if ($result == $supervisor->{pid}) {
        $supervisor->{status} = ($? & 127) ? -($? & 127) : $? >> 8;
        return 0;
    }
    return 1;
}

sub start {
    my ($state, $mode, $label) = @_;
    $state->{round} = $label;
    if ($mode eq 'service') {
        my $log = "$state->{root}/$label-service.log";
        my $pid = fork();
        defined $pid or die "fork: $!\n";
        if (!$pid) {
            chdir('/') or POSIX::_exit(126);
            open(STDOUT, '>', $log) or POSIX::_exit(126);
            open(STDERR, '>&', \*STDOUT) or POSIX::_exit(126);
            { no warnings 'exec'; exec { 'bash' } 'bash', $state->{launcher}, 'service'; }
            POSIX::_exit(127);
        }
        $state->{supervisor} = { pid => $pid };
    }
    elsif ($mode eq 'direct') {
        command($state, ['bash', '-f', "$state->{installed}/$_/bin/startup.sh"]) for @SERVICES;
    }
    else {
        command($state, ['bash', $state->{launcher}, $mode]);
    }
    my $deadline = time() + 150;
    while (time() < $deadline) {
        check(!$state->{supervisor} || supervisor_running($state), 'Service launcher exited before readiness');
        my $ready = 1;
        my %states;
        for my $offset (0 .. $#SERVICES) {
            my $name = $SERVICES[$offset];
            my $pidfile = "$state->{installed}/$name/temp/$name.pid";
            if (-e $pidfile) {
                my $text = slurp($pidfile);
                $text =~ s/\A\s+|\s+\z//g;
                # An empty file is the moment between its creation and its content; text is a failure.
                my $is_number = $text =~ /\A[0-9]+\z/ ? 1 : 0;
                check($text eq '' || $is_number, "The pid file of $name does not hold a number: $pidfile");
                $state->{pids}{$name} = $text + 0 if $text ne '';
            }
            my $body = eval { http_get($state->{port_base} + $offset, "/$name/bpl/startupState") };
            if (defined $body) {
                $states{$name} = $body;
                $ready &&= index($body, '"STARTUP_COMPLETE"') >= 0;
            }
            else {
                $states{$name} = $@;
                $ready = 0;
            }
        }
        spew("$state->{root}/$label-startup.json", json_text(\%states));
        return if $ready && keys %{$state->{pids}} == 4;
        pause_for(0.25);
    }
    fail("Readiness timeout; inspect $state->{root}");
    return;
}

sub observe {
    my ($state, $label, $value, $threshold) = @_;
    my %wanted = (CONFIG_TEST_LIVE => $value, CONFIG_TEST_NEW => 'quoted value * $literal', CONFIG_TEST_EMPTY => '',
        EPICS_CA_ADDR_LIST => '127.0.0.1', EPICS_CA_AUTO_ADDR_LIST => 'NO');
    my $prefix = "$state->{root}/path-prefix";
    my %observations;
    for my $name (sort keys %{$state->{pids}}) {
        my $pid = $state->{pids}{$name};
        my $link = readlink("/proc/$pid/exe");
        check(defined $link && abs_path($link) eq $state->{java}, "JVM $name ($pid) does not run the java on the PATH");
        my %environ;
        for my $item (split /\0/, slurp("/proc/$pid/environ")) {
            my ($key, $text) = split /=/, $item, 2;
            $environ{$key} = $text if defined $text;
        }
        my @arguments = split /\0/, slurp("/proc/$pid/cmdline"), -1;
        my @path = split /:/, $environ{PATH} // die("JVM $name has no PATH\n"), -1;
        $observations{$name} = {
            pid => $pid + 0,
            environment => { map { $_ => $environ{$_} // '<missing>' } sort keys %wanted },
            component_environment => $environ{CONFIG_TEST_COMPONENT} // '<missing>',
            path_prefix_count => scalar(grep { $_ eq $prefix } @path),
            arguments => \@arguments,
        };
    }
    spew("$state->{root}/$label-jvms.json", json_text(\%observations));
    check(keys %observations == 4, 'Expected four JVMs, observed ' . scalar(keys %observations));
    for my $name (sort keys %observations) {
        my $observed = $observations{$name};
        my @arguments = @{$observed->{arguments}};
        for my $key (sort keys %wanted) {
            check($observed->{environment}{$key} eq $wanted{$key},
                "$label: $name: $key is '$observed->{environment}{$key}', expected '$wanted{$key}'");
        }
        check($observed->{path_prefix_count} == 1, "$label: $name: PATH has the prefix $observed->{path_prefix_count} times");
        check((grep { $_ eq '-Dconfig.common=present' } @arguments) > 0, "$label: $name: missing -Dconfig.common=present");
        check((grep { $_ eq "-Dcatalina.base=$state->{installed}/$name" } @arguments) > 0,
            "$label: $name: missing -Dcatalina.base=$state->{installed}/$name");
        if ($name eq 'engine') {
            check((grep { $_ eq '-Dconfig.component=engine' } @arguments) > 0, "$label: engine: missing -Dconfig.component=engine");
            check($observed->{component_environment} eq 'engine', "$label: engine: component configuration was not exported");
        }
    }
    for my $action (qw(health status)) {
        my $run = command($state, ['bash', $state->{launcher}, $action]);
        spew("$state->{root}/$label-$action.txt", $run->{stdout} . $run->{stderr});
        check(index($run->{stdout}, "threshold=$threshold%") >= 0, "$label: $action does not report threshold=$threshold%");
        check(index($run->{stdout}, 'all-four-processes-verified') >= 0, "$label: $action did not verify all four processes");
    }
    print "PASS: $label: four JVMs, component options, and health\n";
    return;
}

# The JVMs of this run by their command line: the installed tree is new for every run, so it names them whatever the
# pid files hold.
sub find_run_jvms {
    my ($state) = @_;
    my $prefix = "-Dcatalina.base=$state->{installed}/";
    my %found;
    opendir(my $proc, '/proc') or die "opendir /proc: $!\n";
    for my $entry (grep { /\A[0-9]+\z/ } readdir($proc)) {
        my $data = eval { slurp("/proc/$entry/cmdline") };
        next unless defined $data;
        for my $argument (split /\0/, $data) {
            $found{substr($argument, length $prefix)} = $entry + 0 if index($argument, $prefix) == 0;
        }
    }
    closedir($proc);
    return %found;
}

sub stop {
    my ($state, $normal) = @_;
    if ($state->{supervisor}) {
        kill('TERM', $state->{supervisor}{pid}) if supervisor_running($state);
        my $deadline = time() + 90;
        while (supervisor_running($state)) {
            fail('The service launcher did not stop within 90 seconds') if time() >= $deadline;
            pause_for(0.05);
        }
        my $status = $state->{supervisor}{status};
        $state->{supervisor} = undef;
        check($status == 0, "The service launcher ended with status $status") if $normal;
    }
    elsif (%{$state->{pids}} && $normal) {
        command($state, ['bash', $state->{launcher}, 'shutdown'], timeout => 90);
    }
    if (!$normal) {
        my %found = find_run_jvms($state);
        $state->{pids}{$_} //= $found{$_} for keys %found;
    }
    for my $name (sort keys %{$state->{pids}}) {
        my $pid = $state->{pids}{$name};
        my $current = process_state($pid);
        kill('TERM', $pid) if !$normal && defined $current && $current ne 'Z';
        my $deadline = time() + 30;
        while (defined($current = process_state($pid)) && $current ne 'Z') {
            fail("JVM $pid did not stop") if time() >= $deadline;
            pause_for(0.1);
        }
    }
    $state->{pids} = {};
    print "Stopped: $state->{round}\n";
    return;
}

# The launcher and every generated wrapper must refuse a config.d file with a syntax error and name it.
sub check_invalid_syntax {
    my ($state) = @_;
    my $invalid = "$state->{installed}/config.d/99-invalid.conf";
    spew($invalid, qq{CONFIG_TEST_LIVE="unterminated\n});
    for my $options ([], ['-f']) {
        for my $action (qw(startup service)) {
            my $run = command($state, ['bash', @{$options}, $state->{launcher}, $action], expected => 1);
            check(index($run->{stderr}, $invalid) >= 0, "launcher $action does not name $invalid");
            check(index($run->{stderr}, 'configuration preflight failed; no instance was touched') >= 0,
                "launcher $action did not reject invalid configuration at its preflight");
            for my $name (@SERVICES) {
                check(!-e "$state->{installed}/$name/temp/$name.pid", "launcher $action left a PID file of $name");
            }
        }
        for my $name (@SERVICES) {
            for my $script (qw(startup.sh shutdown.sh run.sh)) {
                my $run = command($state, ['bash', @{$options}, "$state->{installed}/$name/bin/$script"], expected => 1);
                check(index($run->{stderr}, $invalid) >= 0, "$name/bin/$script does not name $invalid");
            }
        }
    }
    return;
}

sub check_installed_loader_options {
    my ($state) = @_;
    my $script = 'set +a; . "$1/archappl-config.bash"; archappl_load_configuration "$1" || exit 2; [[ $- != *a* ]]';
    command($state, ['bash', '-c', $script, 'installed-loader', $state->{installed}]);
    print "PASS: installed loader restores the caller export option\n";
    return;
}

sub check_stale_pid_cleanup {
    my ($state) = @_;
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    POSIX::_exit(0) unless $pid;
    waitpid($pid, 0) == $pid or die "waitpid $pid: $!\n";
    check(!-e "/proc/$pid", 'the stale PID belongs to a terminated and reaped child');
    for my $name (@SERVICES) {
        spew("$state->{installed}/$name/temp/$name.pid", "$pid\n");
    }
    my $run = command($state, ['bash', $state->{launcher}, 'shutdown'], timeout => 30);
    check(index($run->{stdout}, 'PID file found but either no matching process was found') >= 0,
        'real Tomcat shutdown observed the stale PID');
    for my $name (@SERVICES) {
        check(!-e "$state->{installed}/$name/temp/$name.pid", "shutdown retained the stale PID file of $name");
    }
    print "PASS: successful installed shutdown wrappers remove stale PID files\n";
    return;
}

sub run_checks {
    my ($state) = @_;
    my $verdict = 'INCOMPLETE';
    my $ok = eval {
        prepare($state);
        check_installed_loader_options($state);
        start($state, 'direct', 'direct-noglob');
        observe($state, 'direct-noglob', 'initial', 100);
        stop($state, 1);
        start($state, 'startup', 'manual');
        observe($state, 'manual', 'initial', 100);
        start($state, 'restart', 'manual-restart');
        observe($state, 'manual-restart', 'initial', 100);
        stop($state, 1);
        start($state, 'service', 'service-before-edit');
        observe($state, 'service-before-edit', 'initial', 100);
        edit($state, 'changed', 99);
        observe($state, 'service-after-edit', 'initial', 99);
        stop($state, 1);
        start($state, 'service', 'service-after-restart');
        observe($state, 'service-after-restart', 'changed', 99);
        stop($state, 1);
        check_stale_pid_cleanup($state);
        check_invalid_syntax($state);
        $verdict = 'PASS';
        1;
    };
    my $error = $@;
    my $stopped = eval { stop($state, 0); 1 };
    my $stop_error = $@;
    if ($stopped) {
        spew("$state->{root}/verdict.txt", "$verdict\n");
    }
    finish_workspace($state->{root}, $ok && $stopped && $verdict eq 'PASS');
    die $error unless $ok;
    die $stop_error unless $stopped;
    print "$verdict: installed runtime configuration\n";
    return;
}

sub usage_error {
    my ($message) = @_;
    print STDERR "config-d-runtime.pl: $message\n" if defined $message;
    pod2usage(-verbose => 0, -exitval => 'NOEXIT', -output => \*STDERR);
    return 2;
}

sub resolve_directory {
    my ($path, $what) = @_;
    my $resolved = abs_path($path);
    die "$what is not an existing directory: $path\n" if !defined $resolved || !-d $resolved;
    return $resolved;
}

sub main {
    my (@arguments) = @_;
    my ($help, $tomcat_home, $war_dir);
    my $port_base = 29665;
    GetOptionsFromArray(\@arguments, 'help' => \$help, 'tomcat-home=s' => \$tomcat_home, 'war-dir=s' => \$war_dir,
        'port-base=i' => \$port_base) or return usage_error();
    if ($help) {
        pod2usage(-verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        return 0;
    }
    return usage_error('unexpected argument: ' . $arguments[0]) if @arguments;
    return usage_error('--tomcat-home is required') if !defined $tomcat_home;
    return usage_error('--war-dir is required') if !defined $war_dir;
    $tomcat_home = resolve_directory($tomcat_home, '--tomcat-home');
    $war_dir = resolve_directory($war_dir, '--war-dir');
    my $root = tempdir('archappl-config-runtime-XXXXXXXX', DIR => temp_root());
    my $state = { root => $root, checkout => "$root/checkout", installed => "$root/installed",
        launcher => "$root/installed/archappl.bash", tomcat_home => $tomcat_home, war_dir => $war_dir,
        port_base => $port_base, supervisor => undef, pids => {}, round => 'setup' };
    local $SIG{INT} = sub { $INTERRUPT = POSIX::SIGINT(); die "interrupted by SIGINT\n" };
    local $SIG{TERM} = sub { $INTERRUPT = POSIX::SIGTERM(); die "interrupted by SIGTERM\n" };
    run_checks($state);
    return 0;
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    if ($INTERRUPT) {
        print STDERR "config-d-runtime.pl: $error";
        $status = 128 + $INTERRUPT;
    }
    elsif ($error =~ s/\AASSERTION: //) {
        print STDERR "FAIL: $error";
        $status = 1;
    }
    else {
        print STDERR "config-d-runtime.pl: $error";
        $status = 2;
    }
};
exit $status;
