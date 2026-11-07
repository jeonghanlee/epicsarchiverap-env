#!/usr/bin/env perl
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
use POSIX qw(strftime);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use Pod::Usage qw(pod2usage);
use lib dirname(abs_path(__FILE__)) . '/../lib';
use ArchiverTest qw(slurp spew check pause_for which);

my @COMPONENTS = qw(mgmt engine etl retrieval);
my $HERE = dirname(abs_path(__FILE__));
my $JSON = JSON::PP->new->canonical->pretty;
my ($C, $WORK, $PV, $IOC, $VERIFIER);
my $STAGE = 'prerequisites';
my $LIMIT = 180;
my $FAILURE = '';
my @INSTALL;

sub utc {
    my ($seconds) = @_;
    return strftime('%Y-%m-%dT%H:%M:%SZ', gmtime(defined($seconds) ? $seconds : time));
}

sub save_json {
    my ($path, $value) = @_;
    spew($path, $JSON->encode($value));
    return;
}

sub object {
    my ($text, $label) = @_;
    my $value = $JSON->decode($text);
    ref($value) eq 'HASH' or die "$label: expected JSON object\n";
    return $value;
}

sub capture {
    my ($name, $limit, @command) = @_;
    my $directory = "$WORK/$name";
    -e $directory and die "$directory: evidence already exists\n";
    make_path($directory, {mode => 0700});
    my $started = clock_gettime(CLOCK_MONOTONIC);
    save_json("$directory/command.json", {argv => \@command, cwd => $C->{repository},
        timeout_seconds => $limit, started_utc => utc()});
    my $pid = fork();
    defined($pid) or die "fork: $!\n";
    if (!$pid) {
        $SIG{INT} = $SIG{TERM} = $SIG{QUIT} = 'DEFAULT';
        open(STDOUT, '>:raw', "$directory/stdout") or POSIX::_exit(126);
        open(STDERR, '>:raw', "$directory/stderr") or POSIX::_exit(126);
        open(STDIN, '<', '/dev/null') or POSIX::_exit(126);
        chdir($C->{repository}) or POSIX::_exit(126);
        {
            no warnings 'exec';
            exec {'timeout'} 'timeout', '--signal=TERM', '--kill-after=10', $limit, @command;
        }
        POSIX::_exit(127);
    }
    my $raw;
    my $done = eval {
        my $waited;
        do { $waited = waitpid($pid, 0); } while $waited == -1 && $! == POSIX::EINTR();
        $waited == $pid or die "waitpid $pid: $!\n";
        $raw = $?;
        1;
    };
    if (!$done) {
        my $error = $@;
        # Preserve the interrupted command's output before caller cleanup.
        kill 'TERM', $pid;
        waitpid($pid, 0);
        $raw = $?;
        save_json("$directory/result.json", {interrupted => $error, wait_status => $raw,
            ended_utc => utc(), elapsed_seconds => clock_gettime(CLOCK_MONOTONIC) - $started});
        die $error;
    }
    my $result = {exit => ($raw & 127) ? 128 + ($raw & 127) : $raw >> 8,
        signal => $raw & 127, elapsed_seconds => clock_gettime(CLOCK_MONOTONIC) - $started,
        ended_utc => utc()};
    save_json("$directory/result.json", $result);
    $result->{stdout} = slurp("$directory/stdout");
    return $result;
}

sub require_result {
    my ($result, $label, $failure) = @_;
    if ($result->{exit}) {
        die (($failure ? 'ASSERTION: ' : '') . "$label exited $result->{exit}\n");
    }
    return $result->{stdout};
}

sub observe {
    my ($name, @command) = @_;
    return require_result(capture($name, 30, @command), $name, 0);
}

sub properties {
    my ($text) = @_;
    my %values;
    for my $line (split /\n/, $text) {
        next unless $line =~ /^([A-Za-z_][A-Za-z_0-9]*)=(.*)$/;
        my ($key, $value) = ($1, $2);
        $value =~ s/^"(.*)"$/$1/;
        $value =~ s/^'(.*)'$/$1/;
        $values{$key} = $value;
    }
    return \%values;
}

sub curl {
    my ($name, $endpoint, @arguments) = @_;
    return capture($name, 12, 'curl', '-q', '--noproxy', '*', '--fail', '--silent',
        '--show-error', '--max-time', '10', @arguments, $endpoint);
}

sub ready {
    my ($phase) = @_;
    my $begin = clock_gettime(CLOCK_MONOTONIC);
    my $attempt = 0;
    while (clock_gettime(CLOCK_MONOTONIC) - $begin < $LIMIT) {
        my $all = 1;
        $attempt++;
        for my $component (@COMPONENTS) {
            my $result = curl("$phase/readiness-$attempt/$component", "$C->{urls}{$component}/startupState");
            $all = 0 if $result->{exit} || $result->{stdout} !~ /"status"\s*:\s*"STARTUP_COMPLETE"/;
        }
        if ($all) {
            my $elapsed = clock_gettime(CLOCK_MONOTONIC) - $begin;
            check($elapsed <= $LIMIT, 'all startup APIs completed within the readiness deadline');
            save_json("$WORK/$phase/readiness.json", {elapsed_seconds => $elapsed, attempts => $attempt});
            return;
        }
        pause_for(1);
    }
    check(0, 'all startup APIs completed within the readiness deadline');
    return;
}

sub process_identity {
    my ($phase, $pid, $privileged) = @_;
    $pid =~ /^\d+$/ or die "invalid PID\n";
    my @prefix = $privileged ? ('sudo', '-n') : ();
    my $stat = observe("$phase/stat", @prefix, 'cat', "/proc/$pid/stat");
    $stat =~ /^\d+ \(.*\) (.*)$/s or die "invalid process stat\n";
    my @fields = split /\s+/, $1;
    @fields > 19 && $fields[19] =~ /^\d+$/ or die "missing process start ticks\n";
    check($fields[0] ne 'Z' && $fields[0] ne 'X', 'observed process is alive');
    my $command = observe("$phase/cmdline", @prefix, 'cat', "/proc/$pid/cmdline");
    return {pid => $pid, ticks => $fields[19], command => $command};
}

sub snapshot {
    my ($phase) = @_;
    ready($phase);
    my $boot = observe("$phase/boot", 'cat', '/proc/sys/kernel/random/boot_id');
    my $service = properties(observe("$phase/service", 'systemctl', 'show', $C->{service},
        '-p', 'User,Group,ExecStart,UnitFileState,ActiveState,SubState,InvocationID'));
    check(($service->{User} // '') eq $C->{user} && ($service->{Group} // '') eq $C->{group},
        'service uses the supplied account');
    check(($service->{ActiveState} // '') eq 'active' && ($service->{UnitFileState} // '') eq 'enabled',
        'appliance service is enabled and active');
    check(index($service->{ExecStart} // '', "$C->{install}/archappl.bash service") >= 0,
        'service executes the installed launcher');
    check(($service->{InvocationID} // '') =~ /^[a-f0-9]{32}$/, 'service invocation is available');
    my $timer = properties(observe("$phase/timer", 'systemctl', 'show', $C->{timer},
        '-p', 'UnitFileState,ActiveState'));
    check(($timer->{ActiveState} // '') eq 'active' && ($timer->{UnitFileState} // '') eq 'enabled',
        'health timer is enabled and active');
    require_result(capture("$phase/health", 30, 'sudo', '-n', '-u', $C->{user}, '--',
        "$C->{install}/archappl.bash", 'health'), 'installed health check', 1);
    my $info = object(require_result(curl("$phase/information", "$C->{urls}{mgmt}/getApplianceInfo"),
        'appliance information', 1), 'appliance information');
    check(($info->{identity} // '') eq $C->{identity}, 'appliance identity matches the supplied identity');
    check(index($info->{version} // '', substr($C->{appliance_revision}, 0, 8)) >= 0,
        'appliance API reports the pinned source');
    for my $component (@COMPONENTS) {
        check(($info->{"${component}URL"} // '') eq $C->{urls}{$component}, "$component runtime endpoint matches input");
    }
    check(($info->{dataRetrievalURL} // '') eq $C->{retrieval}, 'data retrieval endpoint matches input');
    my $source = observe("$phase/source", 'git', '-C', "$C->{repository}/$C->{source}", 'rev-parse', 'HEAD');
    chomp $source;
    check($source eq $C->{appliance_revision}, 'source checkout is pinned');
    my $config = properties(observe("$phase/config", 'sudo', '-n', 'cat', "$C->{install}/archappl.conf"));
    for my $key (sort keys %{$C->{configuration}}) {
        check(defined($config->{$key}) && $config->{$key} eq $C->{configuration}{$key}, "installed configuration $key");
    }
    my $policies = observe("$phase/policies", 'sudo', '-n', 'cat', "$C->{install}/policies.py");
    for my $path (@{$C->{storage}}[1..3]) {
        check(index($policies, "rootFolder=$path&") >= 0, "storage policy uses $path");
    }
    my $account = observe("$phase/uid", 'id', '-u', $C->{user});
    chomp $account;
    my %processes;
    my @files = map { "$C->{install}/$_" } qw(archappl.conf archappl.bash archappl-config.bash
        appliances.xml archappl.properties policies.py .versions);
    for my $component (@COMPONENTS) {
        my $root = "$C->{install}/$component";
        my $pid = observe("$phase/$component/pid", 'sudo', '-n', 'cat', "$root/temp/$component.pid");
        chomp $pid;
        my $identity = process_identity("$phase/$component/process", $pid, 1);
        check(index($identity->{command}, "-Dcatalina.base=$root\0") >= 0
            && index($identity->{command}, 'org.apache.catalina.startup.Bootstrap') >= 0,
            "$component is the installed Tomcat JVM");
        my $status = observe("$phase/$component/status", 'sudo', '-n', 'cat', "/proc/$pid/status");
        check($status =~ /^Uid:\s+\Q$account\E\s+\Q$account\E\s/m, "$component runs as the supplied service user");
        $processes{$component} = "$pid:$identity->{ticks}";
        my $version = observe("$phase/$component/version", 'sudo', '-n', 'cat', "$root/webapps/$component/ui/comm/version.txt");
        check(index($version, substr($C->{appliance_revision}, 0, 8)) >= 0, "$component version is pinned");
        my $context = observe("$phase/$component/context", 'sudo', '-n', 'cat', "$root/conf/context.xml");
        check(index($context, 'driverClassName="org.sqlite.JDBC"') >= 0
            && index($context, "url=\"jdbc:sqlite:$C->{database}?journal_mode=WAL\"") >= 0,
            "$component uses the supplied SQLite file");
        push @files, "$root/conf/server.xml", "$root/conf/context.xml", "$root/bin/setenv.sh";
    }
    my %distinct = map { $processes{$_} => 1 } @COMPONENTS;
    check(keys(%distinct) == 4, 'four distinct JVM lifetimes are present');
    my $index = 0;
    for my $path (@{$C->{storage}}) {
        $index++;
        my $owner = observe("$phase/storage-$index", 'stat', '-c', '%U:%G', $path);
        chomp $owner;
        check($owner eq "$C->{user}:$C->{group}", "storage ownership: $path");
        require_result(capture("$phase/storage-access-$index", 10, 'sudo', '-n', '-u', $C->{user}, '--',
            'test', '-w', $path), "service-account storage access: $path", 1);
    }
    my $database = observe("$phase/database", 'sudo', '-n', '-u', $C->{user}, '--', 'sqlite3', '-readonly',
        $C->{database}, 'PRAGMA database_list; SELECT name FROM sqlite_master WHERE type="table" ORDER BY name; PRAGMA table_info(PVTypeInfo);');
    check(index($database, "0|main|$C->{database}\n") == 0, 'database query uses the supplied SQLite file');
    for my $table (qw(ArchivePVRequests ExternalDataServers PVAliases PVTypeInfo)) {
        check($database =~ /^\Q$table\E$/m, "required database table $table");
    }
    check($database =~ /\|pvName\|/ && $database =~ /\|typeInfoJSON\|/, 'PV metadata schema exists');
    my $hashes = observe("$phase/configuration-hashes", 'sudo', '-n', 'sha256sum', @files);
    my $units = observe("$phase/effective-units", 'systemctl', 'cat', $C->{service}, $C->{timer}, $C->{health_service});
    my $war_dir = "$C->{repository}/$C->{source}/target";
    opendir(my $directory, $war_dir) or die "$war_dir: $!\n";
    my @entries = readdir($directory);
    closedir($directory) or die "$war_dir: $!\n";
    my @wars;
    for my $component (@COMPONENTS) {
        my @matches = grep { !/^\./ && /\Q$component.war\E$/ } @entries;
        check(@matches == 1, "exactly one built WAR for $component");
        push @wars, "$war_dir/$matches[0]";
    }
    my $wars = observe("$phase/war-state", 'stat', '-c', '%n %s %y', @wars);
    my $record = {boot => $boot, invocation => $service->{InvocationID}, processes => \%processes,
        configuration => "$hashes$units", wars => $wars};
    save_json("$WORK/$phase/state.json", $record);
    return "$WORK/$phase/state.json";
}

sub compare {
    my ($phase, $mode, @args) = @_;
    my $result = capture($phase, 15, $^X, "$HERE/compare.pl", '--mode', $mode, @args);
    require_result($result, "comparison $mode", $result->{exit} == 1);
    return;
}

sub pv_action {
    my ($phase, $action) = @_;
    my $response = object(require_result(curl($phase, "$C->{urls}{mgmt}/${action}ArchivingPV",
        '--get', '--data-urlencode', "pv=$PV"), "$action PV", 1), "$action PV");
    check(($response->{status} // '') eq 'ok', "$action PV succeeds");
    return;
}

sub registration {
    my ($phase) = @_;
    $PV =~ /^LocalInstall:[A-Za-z0-9]+:Value$/ or die "unexpected test PV name\n";
    my $text = observe($phase, 'sudo', '-n', '-u', $C->{user}, '--', 'sqlite3', '-readonly', $C->{database},
        "SELECT typeInfoJSON FROM PVTypeInfo WHERE pvName='$PV';");
    check(length($text) > 0, 'test PV registration exists in the configured database');
    my $data = object($text, 'PV registration');
    check(($data->{pvName} // '') eq $PV, 'database registration names the same test PV');
    save_json("$WORK/$phase/registration.json", $data);
    return "$WORK/$phase/registration.json";
}

sub query {
    my ($phase, $from, $to) = @_;
    my $base = "$WORK/$phase";
    local $ENV{AA_PV_CURL_BIN} = which('curl');
    local $ENV{AA_PV_EXPECTED} = $PV;
    local $ENV{AA_PV_RETRIEVAL_URL} = "$C->{retrieval}/data/getData.json";
    local $ENV{AA_PV_RESPONSE} = "$base/retrieval.json";
    local $ENV{PATH} = "$VERIFIER/client-bin:$ENV{PATH}";
    my $result = capture($phase, 20, 'bash', "$C->{repository}/$C->{source}/docs/book/src/samples/getDataToCsv.bash",
        '--timeout', '15', $C->{retrieval}, "$VERIFIER/pvs.txt", utc($from), utc($to), "$base/csv");
    require_result($result, 'pinned CSV query', 1);
    my $filename = $PV;
    $filename =~ s/[^A-Za-z0-9._-]/_/g;
    my $path = "$base/csv/$filename.csv";
    -f $path or die "$path: CSV output missing\n";
    return $path;
}

sub same_ioc {
    my ($phase) = @_;
    my $now = process_identity($phase, $IOC->{pid}, 0);
    check($now->{ticks} eq $IOC->{ticks} && $now->{command} eq $IOC->{command},
        'the original test IOC lifetime is unchanged');
    return;
}

sub new_data {
    my ($phase) = @_;
    same_ioc("$phase/ioc");
    my $start = clock_gettime(CLOCK_MONOTONIC);
    my $from = time;
    my $observations = '';
    for my $index (1..12) {
        my $line = observe("$phase/ca-$index", "$C->{epics_bin}/caget", '-a', '-f0', '-w', '1', $PV);
        my ($name, $day, $clock, $value) = split /\s+/, $line;
        defined($value) && $name eq $PV && $value =~ /^\d+$/ or die "unusable CA observation\n";
        my $stamp = observe("$phase/time-$index", 'date', '-u', '-d', "$day $clock", '+%s %N');
        $stamp =~ /^(\d+) (\d+)\s*$/ or die "unusable CA timestamp\n";
        $observations .= "$1\t$value\t$2\n";
        pause_for(1);
    }
    my $to = time;
    spew("$WORK/$phase/ca.tsv", $observations);
    pv_action("$phase/pause", 'pause');
    my $csv = query("$phase/query", $from, $to);
    compare("$phase/comparison", 'samples', '--from', $from, '--to', $to, "$WORK/$phase/ca.tsv", $csv);
    check(clock_gettime(CLOCK_MONOTONIC) - $start <= $LIMIT, 'new data observed within 180 seconds');
    pv_action("$phase/resume", 'resume');
    same_ioc("$phase/ioc-after");
    save_json("$WORK/$phase/window.json", {from => $from, to => $to,
        elapsed_seconds => clock_gettime(CLOCK_MONOTONIC) - $start});
    return;
}

sub finish {
    my () = @_;
    return unless defined $PV;
    local $SIG{INT} = 'IGNORE';
    local $SIG{TERM} = 'IGNORE';
    my @errors;
    eval { pv_action('final/pause', 'pause'); 1 } or push @errors, $@;
    eval {
        $IOC or die "retained IOC identity is unavailable\n";
        same_ioc('final/ioc-before');
        kill('TERM', $IOC->{pid}) or die "terminate test IOC: $!\n";
        my $end = clock_gettime(CLOCK_MONOTONIC) + 10;
        while (-e "/proc/$IOC->{pid}/stat" && clock_gettime(CLOCK_MONOTONIC) < $end) {
            my $stat = slurp("/proc/$IOC->{pid}/stat");
            last if $stat =~ /^\d+ \(.*\) [ZX] /;
            pause_for(0.2);
        }
        my $remaining = -e "/proc/$IOC->{pid}/stat" ? slurp("/proc/$IOC->{pid}/stat") : '';
        check($remaining eq '' || $remaining =~ /^\d+ \(.*\) [ZX] /, 'recorded test IOC stopped');
        spew("$WORK/final/ioc-after.txt", $remaining eq '' ? "absent\n" : $remaining);
        1;
    } or push @errors, $@;
    eval {
        my $record = registration('final/registration');
        check((object(slurp($record), 'final registration')->{paused} // '') eq 'true', 'test PV remains Paused');
        1;
    } or push @errors, $@;
    die join('', @errors) if @errors;
    save_json("$WORK/final/completion.json", {utc => utc(), pv => $PV, ioc_stopped => JSON::PP::true});
    return;
}

sub sequence {
    my () = @_;
    observe('prerequisites/sudo', 'sudo', '-n', 'true');
    my $environment = observe('prerequisites/environment-revision', 'git', '-C', $C->{repository}, 'rev-parse', 'HEAD');
    chomp $environment;
    $environment eq $C->{environment_revision} or die "environment revision differs from supplied input\n";
    my $patch = observe('prerequisites/environment-patch', 'git', '-C', $C->{repository},
        'diff', '--no-ext-diff', '--binary', 'HEAD');
    my $expected_patch = defined($C->{environment_patch}) ? slurp($C->{environment_patch}) : '';
    $patch eq $expected_patch or die "environment changes differ from supplied patch\n";
    observe('prerequisites/environment-index-clean', 'git', '-C', $C->{repository}, 'diff', '--cached', '--exit-code');
    -e $C->{install} and die "an appliance already exists; supply a fresh guest\n";
    -e "$C->{repository}/$C->{source}/target" and die "prebuilt source target exists\n";
    my $os = properties(observe('prerequisites/os', 'cat', '/etc/os-release'));
    ($os->{ID} // '') eq 'debian' && ($os->{VERSION_ID} // '') eq '13'
        or die "the actual guest is not Debian 13\n";
    observe('prerequisites/epics', 'bash', "$C->{repository}/scripts/verify-local-pv.bash",
        '--check-epics', '--epics-bin', $C->{epics_bin});
    observe('prerequisites/packages', 'dpkg-query', '-W');
    observe('prerequisites/source-hashes', 'sha256sum', "$HERE/install.pl", "$HERE/compare.pl",
        "$HERE/../lib/ArchiverTest.pm", "$C->{repository}/scripts/install-local-common.bash",
        "$C->{repository}/scripts/verify-local-pv.bash", "$C->{repository}/scripts/verify-local-pv-curl.bash");
    @INSTALL = ('bash', "$C->{repository}/scripts/install-local-sqlite.bash", '--yes', '--timeout', $LIMIT);
    $STAGE = 'T1'; print "T1: running the shipped installer\n";
    require_result(capture('t1/install', $C->{install_timeout}, @INSTALL), 'fresh installation', 1);
    $STAGE = 'T2'; print "T2: checking installed state and runtime\n";
    snapshot('t2');
    $STAGE = 'T3'; print "T3: running the shipped PV verifier\n";
    make_path("$WORK/pv", {mode => 0700});
    local $ENV{TMPDIR} = "$WORK/pv";
    my $verification = capture('t3/verifier', $LIMIT + 30, 'bash', "$C->{repository}/scripts/verify-local-pv.bash",
        '--epics-bin', $C->{epics_bin}, '--cleanup', 'keep', '--timeout', $LIMIT,
        $C->{urls}{mgmt}, $C->{retrieval}, "$C->{repository}/$C->{source}");
    require_result($verification, 'initial PV acquisition, storage and retrieval', 1);
    ($VERIFIER) = $verification->{stdout} =~ /^Evidence: (.+)$/m;
    defined($VERIFIER) && index($VERIFIER, "$WORK/pv/archiver-local-pv.") == 0
        or die "verifier evidence path missing\n";
    $PV = slurp("$VERIFIER/pvs.txt"); chomp $PV;
    my $pid = slurp("$VERIFIER/ioc.pid"); chomp $pid;
    $IOC = process_identity('t3/ioc', $pid, 0);
    check(index($IOC->{command}, "$C->{epics_bin}/softIoc\0") == 0
        && index($IOC->{command}, "$C->{repository}/scripts/fixtures/local-install-pv.db\0") >= 0,
        'retained IOC belongs to the shipped verifier');
    save_json("$WORK/ioc.json", $IOC);
    my ($initial) = $verification->{stdout} =~ /^CSV: (.+)$/m;
    defined($initial) && index($initial, "$VERIFIER/") == 0 or die "initial CSV missing\n";
    my @rows = split /\n/, slurp($initial); shift @rows;
    @rows >= 2 or die "initial CSV has fewer than two rows\n";
    my @seconds = sort {$a <=> $b} map { (split /,/)[1] } @rows;
    my ($from, $to) = ($seconds[0] - 1, $seconds[-1] + 1);
    pause_for(1) while time <= $to;
    save_json("$WORK/history-window.json", {pv => $PV, from => $from, to => $to,
        from_utc => utc($from), to_utc => utc($to)});
    pv_action('t3/history-pause', 'pause');
    my $history = query('t3/history', $from, $to);
    compare('t3/history-contains-initial', 'contains', $initial, $history);
    pv_action('t3/history-resume', 'resume');
    my $registration = registration('t3/registration');
    for my $action ('restart', 'unchanged') {
        $STAGE = $action eq 'restart' ? 'T4' : 'T5';
        print "$STAGE: checking $action and the same PV\n";
        my $phase = lc $STAGE;
        same_ioc("$phase/ioc-before");
        my $before = snapshot("$phase/before");
        if ($action eq 'restart') {
            require_result(capture("$phase/action", $LIMIT, 'make', '--no-print-directory', '-C',
                $C->{repository}, 'ARCHAPPL_SITEID=als', 'DB_BACKEND=sqlite', 'sd_restart'), 'service restart', 1);
        } else {
            my $result = capture("$phase/action", $C->{install_timeout}, @INSTALL);
            require_result($result, 'unchanged installer re-application', 1);
            check($result->{stdout} =~ /^build\s+not-needed\b/m, 'unchanged request does not need a build');
        }
        my $after = snapshot("$phase/after");
        compare("$phase/process-comparison", $action, $before, $after);
        compare("$phase/history-comparison", 'history', $history, query("$phase/history", $from, $to));
        new_data("$phase/new-data");
        compare("$phase/registration-comparison", 'registration', $registration, registration("$phase/registration"));
    }
    $STAGE = 'complete';
    return;
}

sub main {
    my (@args) = @_;
    my ($config, $help);
    GetOptionsFromArray(\@args, 'config=s' => \$config, 'work=s' => \$WORK, 'help' => \$help)
        or die "invalid options\n";
    if ($help) { pod2usage(-verbose => 2, -noperldoc => 1, -exitval => 'NOEXIT'); return 0; }
    defined($config) && defined($WORK) && !@args or die "supply --config and --work; see --help\n";
    $> != 0 or die "run as the ordinary checkout owner\n";
    $WORK =~ m{^/} && !-e $WORK or die "--work must be a new absolute directory\n";
    $C = object(slurp($config), $config);
    my %allowed = map {$_ => 1} qw(repository environment_revision appliance_revision os backend source epics_bin
        install service timer health_service user group identity database retrieval install_timeout storage urls configuration environment_patch);
    for my $key (keys %$C) { $allowed{$key} or die "unknown configuration field: $key\n"; }
    for my $key (qw(repository environment_revision appliance_revision os backend source epics_bin install
        service timer health_service user group identity database retrieval install_timeout)) {
        defined($C->{$key}) && !ref($C->{$key}) or die "missing scalar configuration: $key\n";
    }
    for my $key (qw(repository epics_bin install database)) {
        $C->{$key} =~ m{^/[^\r\n\0]+$} or die "$key must be an absolute path\n";
    }
    if (exists $C->{environment_patch}) {
        defined($C->{environment_patch}) && !ref($C->{environment_patch})
            && $C->{environment_patch} =~ m{^/[^\r\n\0]+$}
            or die "environment_patch must be an absolute file path\n";
    }
    $C->{source} =~ /^[A-Za-z0-9_-]+$/ or die "source must be a checkout directory name\n";
    $C->{os} eq 'debian13' && $C->{backend} eq 'sqlite'
        or die "this initial automation supports only Debian 13 SQLite\n";
    $C->{install_timeout} =~ /^\d+$/ && $C->{install_timeout} > 0
        or die "install_timeout must be positive integer seconds\n";
    for my $key (qw(environment_revision appliance_revision)) {
        $C->{$key} =~ /^[a-f0-9]{40}$/ or die "$key must be a full commit ID\n";
    }
    ref($C->{storage}) eq 'ARRAY' && @{$C->{storage}} == 4 or die "storage must name top, STS, MTS and LTS\n";
    for my $path (@{$C->{storage}}) {
        defined($path) && !ref($path) && $path =~ m{^/[^\r\n\0]+$}
            or die "storage must contain absolute paths\n";
    }
    ref($C->{urls}) eq 'HASH' && ref($C->{configuration}) eq 'HASH' or die "missing expected settings\n";
    for my $key (qw(ARCHAPPL_MYIDENTITY ARCHAPPL_STORAGE_TOP ARCHAPPL_SHORT_TERM_FOLDER
        ARCHAPPL_MEDIUM_TERM_FOLDER ARCHAPPL_LONG_TERM_FOLDER ARCHAPPL_MGMT_PORT)) {
        defined($C->{configuration}{$key}) && !ref($C->{configuration}{$key})
            or die "missing expected configuration: $key\n";
    }
    for my $component (@COMPONENTS) {
        ($C->{urls}{$component} // '') =~ m{^http://(?:localhost|127\.0\.0\.1):\d+/\Q$component\E/bpl$}
            or die "invalid local URL for $component\n";
    }
    ($C->{retrieval} // '') =~ m{^http://(?:localhost|127\.0\.0\.1):\d+/retrieval$}
        or die "invalid local retrieval URL\n";
    for my $tool (qw(timeout sudo git make curl date sha256sum stat systemctl dpkg-query)) {
        which($tool) or die "missing prerequisite: $tool\n";
    }
    umask 0077;
    make_path($WORK, {mode => 0700});
    $WORK = abs_path($WORK);
    save_json("$WORK/inputs.json", $C);
    $ENV{LC_ALL} = 'C'; $ENV{TZ} = 'UTC';
    $ENV{EPICS_CA_ADDR_LIST} = '127.0.0.1'; $ENV{EPICS_CA_AUTO_ADDR_LIST} = 'NO';
    $| = 1;
    local $SIG{INT} = sub { die "interrupted by INT\n"; };
    local $SIG{TERM} = sub { die "interrupted by TERM\n"; };
    my ($error, $cleanup_error) = ('', '');
    eval { sequence(); 1 } or do { $error = $@; };
    $FAILURE = $error if $error =~ /^ASSERTION:/;
    eval { finish(); 1 } or do { $cleanup_error = $@; };
    my $verdict = $FAILURE ? 'Failed' : $error || $cleanup_error ? 'Incomplete' : 'Passed';
    save_json("$WORK/result.json", {verdict => $verdict, stage => $STAGE, error => $error,
        cleanup_error => $cleanup_error, completed_utc => utc()});
    print "[VERDICT] $verdict\nEvidence: $WORK\n";
    print STDERR $error, $cleanup_error;
    return $verdict eq 'Passed' ? 0 : $verdict eq 'Failed' ? 1 : 2;
}

my $status;
eval { $status = main(@ARGV); defined($status) or die "missing exit status\n"; 1 }
    or do { my $error = $@; print STDERR "install.pl: $error"; $status = 2; };
exit $status;

=head1 NAME

install.pl - execute the first real VM installation acceptance sequence

=head1 SYNOPSIS

  perl tests/vm/install.pl --config /absolute/case.json --work /absolute/new-evidence

=head1 DESCRIPTION

Runs on an isolated fresh Debian 13 guest as its ordinary checkout owner with
noninteractive sudo. The caller obtains the guest from cloud-provision and
supplies a pinned checkout, site settings and real EPICS Base. This script
does not provision guests or prepare an appliance outside the shipped installer.
The example input is install.example.json. Perl 5.26.3 and JSON::PP are required;
check their availability before the run. Debian's perl package supplies them.

T1 calls install-local-sqlite.bash with packages enabled. T2 observes the
installed version, configuration, units, JVMs, database and health. T3 runs
verify-local-pv.bash independently with cleanup=keep. T4 restarts through the
shipped Make control. T5 repeats the identical installer request. Both actions
check the original registration, fixed historical query and new samples from
the same IOC/PV. compare.pl consumes the actual evidence for these comparisons.
No new registration is made for a continuation check.

Each command retains argv, stdout, stderr, native timeout-wrapper status, UTC
and monotonic elapsed time. Installation has the supplied finite deadline;
readiness and each new-data observation have a 180-second limit. One counter
PV and twelve CA observations per continuation window bound data volume.
CSV values, timestamps, severity, status and occurrence counts are retained.
Process lifetimes use boot ID, PID and start ticks. The final PV pause and
identified IOC stop retain registration, samples and evidence on every outcome.
After copying evidence, the caller sends cloud-provision its finished notice.

The six-case matrix, MariaDB transports, Rocky execution and T6 fault controls
remain outside this initial implementation. It proves neither host reboot
recovery, long-duration reliability nor storage-tier migration. Retained input
comparisons can be repeated with compare.pl; a replay is not a fresh installation.

=head1 OPTIONS

=over

=item --config FILE

JSON input with explicit expected source revisions, account, paths and endpoints.
The repository and its parent site inputs must be prepared before execution.
Optional environment_patch names an absolute file containing the exact binary
Git diff against environment_revision. Without it, tracked files must be clean.
The observed diff is retained; staged changes are always refused.
Credentials are not accepted in this SQLite input. A previous appliance or
source target directory refuses execution as Incomplete.

=item --work DIRECTORY

New absolute evidence directory. Existing evidence is never overwritten.

=item --help

Print help and exit successfully.

=back

=head1 EXIT STATUS

0: all T1-T5 outcomes and final cleanup passed. 1: an observed assertion failed.
2: missing prerequisites or evidence, interruption, cleanup failure or another
tool error. A confirmed failure remains Failed if later cleanup is incomplete.
SIGKILL or host loss can leave partial evidence and running processes; inspect
actual service and recorded IOC identity before recovery. Never retry an
uncertain installation without inspecting its actual state.

=cut
