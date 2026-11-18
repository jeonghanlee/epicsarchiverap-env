#!/usr/bin/env perl
# Checks the shipped Channel Access observer through its command line against a real soft IOC and the real camonitor.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use IO::Socket::INET;
use JSON::PP;
use Pod::Usage qw(pod2usage);
use POSIX ();
use Test::More;
use Time::HiRes qw(sleep time);
use Time::Local qw(timegm);

BEGIN {
    require(dirname(abs_path($0)) . '/lib/ArchiverTest.pm');
    ArchiverTest->import(qw(slurp spew usage_error));
}

=head1 NAME

heap-observe-ca.pl - check the exit statuses, files and run record of tests/heap/observe-ca.pl

=head1 SYNOPSIS

  AA_TEST_EPICS_BIN=<bin/host_arch folder of a real EPICS Base> perl tests/heap-observe-ca.pl
  perl tests/heap-observe-ca.pl --help

=head1 DESCRIPTION

Runs the real observer as a subprocess. Its usage errors, a missing camonitor, a missing or empty PV list and an
output directory that cannot be created need no IOC and always run. The observation cases need AA_TEST_EPICS_BIN, the
bin/host_arch folder of a real EPICS Base; without it they are skipped and the run says so. They start the real softIoc
on tests/heap/fixtures/observe.db (a counter that grows every 0.1 s, a constant 42 and one PV that does not exist) on
loopback ports and run the real camonitor through the observer. The expected figures come from other tools: the values
from caget and awk, the sizes from wc, the working directory from sh, the times from date and the process state from
/proc. The cases cover a run ended by duration, raw output kept and appended to, options passed to camonitor, a camonitor
that exits by itself, a run ended by SIGTERM (clean exit, camonitor gone) and the refusal of a directory that holds a
run record.

The temporary directory uses TMPDIR when writable, otherwise work/scratch/tmp of the checkout; it is removed after the
run. Required: Perl 5.26 or newer, Test::More, JSON::PP, Time::HiRes, Linux /proc, sh, awk, grep, wc and date.

=head1 OPTIONS

=over 4

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when every check passes, 1 when an assertion fails, 2 for invalid usage or an environment error.

=cut

my $TESTS = dirname(abs_path($0));
my $REPOSITORY = dirname($TESTS);
my $TOOL = "$REPOSITORY/tests/heap/observe-ca.pl";
my $DATABASE = "$REPOSITORY/tests/heap/fixtures/observe.db";
my $PREFIX = 'OBS:';
my $FIRST_PORT = 15000;
my $DURATION_SECONDS = 3;
my @CHILDREN;

END {
    local $?;    # waitpid sets it, and the value at the end of the program is the exit status
    for my $pid (@CHILDREN) {
        kill 'KILL', $pid;
        waitpid($pid, 0);
    }
}

sub run_command {
    my (@command) = @_;
    my $error_file = File::Temp->new;
    my $pid = open(my $out, '-|');
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        open(STDERR, '>&', $error_file) or POSIX::_exit(126);
        {
            no warnings 'exec';    # the exit below reports a failed exec
            exec { $command[0] } @command;
        }
        POSIX::_exit(127);
    }
    my $stdout = do { local $/; <$out> };
    close($out);
    my $status = ($? & 127) ? 'signal ' . ($? & 127) : $? >> 8;
    seek($error_file, 0, 0);
    my $stderr = do { local $/; <$error_file> };
    return ($status, defined $stdout ? $stdout : '', defined $stderr ? $stderr : '');
}

sub run_tool {
    my (@arguments) = @_;
    return run_command($^X, $TOOL, @arguments);
}

# Starts a command in the background in the given directory and remembers it so the END block can stop it.
sub spawn {
    my ($directory, $log, @command) = @_;
    my $pid = fork;
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        chdir($directory) or POSIX::_exit(126);
        open(STDOUT, '>', $log) or POSIX::_exit(126);
        open(STDERR, '>&', \*STDOUT) or POSIX::_exit(126);
        {
            no warnings 'exec';    # the exit below reports a failed exec
            exec { $command[0] } @command;
        }
        POSIX::_exit(127);
    }
    push @CHILDREN, $pid;
    return $pid;
}

# Waits for a remembered child and forgets it, so the END block never signals a recycled process ID.
sub reap {
    my ($pid) = @_;
    waitpid($pid, 0);
    my $status = $?;
    @CHILDREN = grep { $_ != $pid } @CHILDREN;
    return $status;
}

# Runs a shell script with the standard text tools and returns its trimmed output.
sub text_tool {
    my ($script, @arguments) = @_;
    my ($status, $stdout, $stderr) = run_command('sh', '-c', $script, 'sh', @arguments);
    $status == 0 or die "text tool failed with $status: $stderr\n";
    $stdout =~ s/\A\s+|\s+\z//g;
    return $stdout;
}

sub epoch_of {
    my ($utc) = @_;
    my ($y, $mo, $d, $h, $mi, $s, $ms) = $utc =~ /^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\.(\d{3})Z$/ or return;
    return timegm($s, $mi, $h, $d, $mo - 1, $y) + $ms / 1000;
}

sub read_record {
    my ($directory) = @_;
    return decode_json(slurp("$directory/run.json"));
}

sub run_usage_cases {
    my ($workspace) = @_;
    my $list = "$workspace/usage-pvs.txt";
    spew($list, "$PREFIX" . "tick\n");
    my @cases = (
        ['no option', [], qr/--pv-list is required/],
        ['no output directory', ['--pv-list', $list], qr/--output-dir is required/],
        ['unknown option', ['--bogus'], qr/Unknown option/],
        ['zero duration', ['--pv-list', $list, '--output-dir', "$workspace/u1", '--duration', '0'], qr/--duration must be a number greater than zero/],
        ['non-numeric duration', ['--pv-list', $list, '--output-dir', "$workspace/u2", '--duration', 'x'], qr/--duration must be a number/],
    );
    my ($status, $stdout) = run_tool('--help');
    is($status, 0, 'help: exit status');
    like($stdout, qr/--pv-list/, 'help: names the PV list option');
    for my $case (@cases) {
        my ($name, $arguments, $pattern) = @{$case};
        my ($code, undef, $stderr) = run_tool(@{$arguments});
        is($code, 2, "usage $name: exit status");
        like($stderr, $pattern, "usage $name: diagnostic");
    }
    ok(!-e "$workspace/u1" && !-e "$workspace/u2", 'usage cases: no output directory was created');
    return;
}

sub run_missing_input_cases {
    my ($workspace) = @_;
    my $good = "$workspace/good-pvs.txt";
    my $empty = "$workspace/empty-pvs.txt";
    my $control = "$workspace/control-pvs.txt";
    spew($good, "${PREFIX}tick\n");
    spew($empty, "# only a comment\n\n   \n");
    spew($control, "${PREFIX}tick\nbad\x01name\n");
    my @cases = (
        ['camonitor missing', ['--pv-list', $good, '--output-dir', "$workspace/m1", '--camonitor', "$workspace/no-camonitor"], qr/camonitor not found/],
        ['camonitor not in PATH', ['--pv-list', $good, '--output-dir', "$workspace/m2", '--camonitor', 'no-such-camonitor-program'], qr/camonitor not found/],
        ['PV list missing', ['--pv-list', "$workspace/no-list.txt", '--output-dir', "$workspace/m3", '--camonitor', '/bin/true'], qr/Cannot read PV list/],
        ['PV list empty', ['--pv-list', $empty, '--output-dir', "$workspace/m4", '--camonitor', '/bin/true'], qr/has no PV/],
        ['control character in a PV name', ['--pv-list', $control, '--output-dir', "$workspace/m5", '--camonitor', '/bin/true'], qr/Invalid PV name.*line 2/],
    );
    for my $case (@cases) {
        my ($name, $arguments, $pattern) = @{$case};
        my ($code, undef, $stderr) = run_tool(@{$arguments});
        is($code, 77, "missing input $name: exit status");
        like($stderr, $pattern, "missing input $name: diagnostic");
    }
    ok(!-e "$workspace/m1/run.json" && !-e "$workspace/m4/run.json", 'missing input cases: no run record was written');

    my $blocker = "$workspace/blocker";
    spew($blocker, "a file, not a directory\n");
    my ($code, undef, $stderr) = run_tool('--pv-list', $good, '--output-dir', "$blocker/sub", '--camonitor', '/bin/true');
    is($code, 1, 'output directory below a file: exit status');
    like($stderr, qr/FAILURE: mkdir/, 'output directory below a file: diagnostic');
    return;
}

# Returns a TCP port that nothing listens on now, found by binding and releasing one.
sub free_port {
    my ($start) = @_;
    for my $port ($start .. $start + 200) {
        my $socket = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => $port, Proto => 'tcp', Listen => 1, ReuseAddr => 1);
        return $port if $socket;
    }
    die "no free port from $start\n";
}

# Starts the real soft IOC on loopback and returns its process ID once a real caget reads the constant PV.
sub start_ioc {
    my ($epics, $workspace) = @_;
    my $base = abs_path("$epics/../..");
    my @dbd = -f "$base/dbd/softIoc.dbd" ? ('-D', "$base/dbd/softIoc.dbd") : ();
    my $directory = "$workspace/ioc";
    make_path($directory);
    my $pid = spawn($directory, "$workspace/ioc.log", "$epics/softIoc", @dbd, '-S', '-m', "P=$PREFIX", '-d', $DATABASE);
    for (1 .. 50) {
        my ($status, $stdout) = run_command("$epics/caget", '-t', '-w', '1', "${PREFIX}fixed");
        return $pid if $status == 0 && $stdout =~ /\A42\s*\z/;
        kill(0, $pid) or die "softIoc ended early: " . slurp("$workspace/ioc.log") . "\n";
        sleep(0.2);
    }
    die "softIoc did not serve ${PREFIX}fixed: " . slurp("$workspace/ioc.log") . "\n";
}

sub run_observation_cases {
    my ($workspace, $epics) = @_;
    my $camonitor = "$epics/camonitor";
    -x $camonitor or die "camonitor not found in AA_TEST_EPICS_BIN: $camonitor\n";
    my $port = free_port($FIRST_PORT);
    my $repeater = free_port($port + 1);
    local $ENV{EPICS_CA_SERVER_PORT} = $port;
    local $ENV{EPICS_CA_REPEATER_PORT} = $repeater;
    local $ENV{EPICS_CA_AUTO_ADDR_LIST} = 'NO';
    local $ENV{EPICS_CA_ADDR_LIST} = '127.0.0.1';
    local $ENV{EPICS_CAS_INTF_ADDR_LIST} = '127.0.0.1';
    my $ioc = start_ioc($epics, $workspace);

    my $list = "$workspace/pvs.txt";
    spew($list, "# observed PVs\n${PREFIX}tick\n\n  ${PREFIX}fixed  \n${PREFIX}nope\n");
    my $work = "$workspace/cwd";
    make_path($work);
    my $directory = "$workspace/run1";
    my @tool = ('--pv-list', $list, '--output-dir', $directory, '--camonitor', $camonitor);

    # Run 1: ended by duration, with a stale first line in the output file that must stay in front.
    make_path($directory);
    spew("$directory/camonitor.out", "stale line from an earlier run\n");
    my $before = text_tool('date -u +%s');
    my $code;
    {
        chdir($work) or die "chdir $work: $!\n";
        ($code) = run_tool(@tool, '--duration', $DURATION_SECONDS);
        chdir($TESTS) or die "chdir $TESTS: $!\n";
    }
    my $after = text_tool('date -u +%s');
    is($code, 0, 'duration run: exit status');
    my $record = read_record($directory);
    is($record->{ended_by}, 'duration', 'duration run: ended by duration');
    is($record->{signal}, 15, 'duration run: camonitor ended by SIGTERM');
    is($record->{exit_status}, undef, 'duration run: no exit status after a signal');
    is_deeply($record->{argv}, [$camonitor, "${PREFIX}tick", "${PREFIX}fixed", "${PREFIX}nope"], 'duration run: command line with the PVs in list order');
    is($record->{pv_count}, 3, 'duration run: PV count');
    is($record->{cwd}, text_tool('cd "$1" && pwd -P', $work), 'duration run: working directory');
    my ($start, $end) = (epoch_of($record->{start_utc}), epoch_of($record->{end_utc}));
    ok(defined $start && defined $end, 'duration run: UTC times parse');
    cmp_ok($start, '>=', $before - 1, 'duration run: start is not before the run began');
    cmp_ok($end, '<=', $after + 1, 'duration run: end is not after the run finished');
    my $elapsed = $record->{end_monotonic_s} - $record->{start_monotonic_s};
    cmp_ok($elapsed, '>=', $DURATION_SECONDS, 'duration run: monotonic span reaches the duration');
    cmp_ok($elapsed, '<', $DURATION_SECONDS + 2, 'duration run: monotonic span stays near the duration');
    cmp_ok(abs(($end - $start) - $elapsed), '<', 0.5, 'duration run: UTC and monotonic spans agree');
    ok(!kill(0, $record->{pid}), 'duration run: camonitor is gone');
    ok(!-e "$directory/run.json.tmp", 'duration run: no temporary record is left');

    my $out = "$directory/camonitor.out";
    is(text_tool('wc -c < "$1"', $out), $record->{stdout_bytes}, 'duration run: stdout size in the record');
    is(text_tool('wc -c < "$1"', "$directory/camonitor.err"), $record->{stderr_bytes}, 'duration run: stderr size in the record');
    is($record->{stderr_bytes}, 0, 'duration run: camonitor wrote nothing to stderr');
    is(text_tool('sed -n 1p "$1"', $out), 'stale line from an earlier run', 'duration run: earlier content stays in front (append)');
    is(text_tool('grep -c "^stale line" "$1"', $out), 1, 'duration run: earlier content appears once');

    my $constant = text_tool('grep "^$2 " "$1" | awk \'{print $NF}\'', $out, "${PREFIX}fixed");
    is($constant, text_tool('"$1" -t "$2"', "$epics/caget", "${PREFIX}fixed"), 'duration run: constant PV equals the value caget reads');
    is(text_tool('grep -c "^$2 " "$1"', $out, "${PREFIX}fixed"), 1, 'duration run: constant PV has one line');
    like(text_tool('grep "^$2 " "$1"', $out, "${PREFIX}nope"), qr/\*\*\* Not connected/, 'duration run: unknown PV is recorded as not connected');
    my @ticks = split /\n/, text_tool('grep "^$2 " "$1" | awk \'{print $NF}\'', $out, "${PREFIX}tick");
    cmp_ok(scalar(@ticks), '>=', 15, 'duration run: counter updates were stored');
    is_deeply([ grep { !/\A\d+\z/ } @ticks ], [], 'duration run: every stored counter value is an integer');
    my $steps = text_tool('grep "^$2 " "$1" | awk \'NR>1 && $NF-prev!=1 {n++} {prev=$NF} END {print n+0}\'', $out, "${PREFIX}tick");
    cmp_ok($steps, '<=', 1, 'duration run: counter steps by one between lines (no stored line altered)');
    my $latest = text_tool('"$1" -t "$2"', "$epics/caget", "${PREFIX}tick");
    cmp_ok($latest, '>=', $ticks[-1], 'duration run: caget reads at least the last stored counter value');
    unlike(slurp($out), qr/\r/, 'duration run: output has no carriage returns added');

    # A second run into the same directory is refused and leaves the first record as it was.
    my $record_hash = text_tool('sha256sum < "$1"', "$directory/run.json");
    my ($again, undef, $again_error) = run_tool(@tool, '--duration', 1);
    is($again, 2, 'existing run record: exit status');
    like($again_error, qr/already holds a run\.json/, 'existing run record: diagnostic');
    is(text_tool('sha256sum < "$1"', "$directory/run.json"), $record_hash, 'existing run record: record unchanged');

    # Run 2: options after -- reach camonitor (no timestamps).
    my $plain = "$workspace/run2";
    my ($plain_code) = run_tool('--pv-list', $list, '--output-dir', $plain, '--camonitor', $camonitor, '--duration', 2, '--', '-t', 'n');
    is($plain_code, 0, 'option run: exit status');
    my $plain_record = read_record($plain);
    is_deeply($plain_record->{argv}, [$camonitor, '-t', 'n', "${PREFIX}tick", "${PREFIX}fixed", "${PREFIX}nope"], 'option run: options precede the PVs');
    like(text_tool('grep "^$2 " "$1"', "$plain/camonitor.out", "${PREFIX}fixed"), qr/\A\Q${PREFIX}\Efixed\s+42\z/, 'option run: line carries no timestamp');

    # Run 3: camonitor ends by itself (an option it rejects); the observer still exits 0 and records the status.
    my $own = "$workspace/run3";
    my ($own_code) = run_tool('--pv-list', $list, '--output-dir', $own, '--camonitor', $camonitor, '--duration', 10, '--', '-Q');
    is($own_code, 0, 'camonitor exit run: exit status');
    my $own_record = read_record($own);
    is($own_record->{ended_by}, 'camonitor_exit', 'camonitor exit run: ended by camonitor');
    my ($direct_status) = run_command($camonitor, '-Q', "${PREFIX}tick");
    is($own_record->{exit_status}, $direct_status, 'camonitor exit run: exit status equals a direct camonitor run');
    is($own_record->{signal}, undef, 'camonitor exit run: no signal');
    cmp_ok($own_record->{stderr_bytes}, '>', 0, 'camonitor exit run: its diagnostic was stored');
    is($own_record->{stderr_bytes}, text_tool('wc -c < "$1"', "$own/camonitor.err"), 'camonitor exit run: stderr size in the record');
    cmp_ok($own_record->{end_monotonic_s} - $own_record->{start_monotonic_s}, '<', 5, 'camonitor exit run: did not wait for the duration');

    # Run 4: SIGTERM to the observer ends camonitor, the observer exits 0 and the record says signal.
    my $signalled = "$workspace/run4";
    my $observer = spawn($work, "$workspace/observer.log", $^X, $TOOL, '--pv-list', $list, '--output-dir', $signalled, '--camonitor', $camonitor);
    for (1 .. 50) {
        last if -s "$signalled/camonitor.out";
        sleep(0.1);
    }
    ok(-s "$signalled/camonitor.out", 'signal run: output arrives while the observer runs');
    kill('TERM', $observer);
    my $wait = reap($observer);
    is($wait, 0, 'signal run: observer exits 0 (not killed by the signal)');
    my $signal_record = read_record($signalled);
    is($signal_record->{ended_by}, 'signal', 'signal run: ended by signal');
    is($signal_record->{signal}, 15, 'signal run: camonitor ended by SIGTERM');
    ok(!-e "/proc/$signal_record->{pid}", 'signal run: camonitor process is gone');
    is($signal_record->{stdout_bytes}, text_tool('wc -c < "$1"', "$signalled/camonitor.out"), 'signal run: stdout size in the record');

    kill('TERM', $ioc);
    reap($ioc);
    return;
}

sub main {
    my @arguments = @_;
    my $help;
    GetOptionsFromArray(\@arguments, 'help' => \$help) or return usage_error('heap-observe-ca.pl', __FILE__, 'invalid option');
    if ($help) {
        pod2usage(-input => __FILE__, -exitval => 'NOEXIT', -verbose => 1, -output => \*STDOUT);
        return 0;
    }
    @arguments and return usage_error('heap-observe-ca.pl', __FILE__, 'unexpected argument');
    -f $TOOL or die "missing observer: $TOOL\n";

    my $temporary_root = defined $ENV{TMPDIR} && -d $ENV{TMPDIR} && -w _ ? $ENV{TMPDIR} : "$REPOSITORY/work/scratch/tmp";
    make_path($temporary_root);
    my $workspace = tempdir('heap-observe-XXXXXX', DIR => $temporary_root, CLEANUP => 1);

    run_usage_cases($workspace);
    run_missing_input_cases($workspace);
    my $epics = $ENV{AA_TEST_EPICS_BIN};
    if (defined $epics && length $epics) {
        run_observation_cases($workspace, $epics);
    }
    else {
        diag('AA_TEST_EPICS_BIN is not set: the observation cases against a real soft IOC were skipped');
    }

    done_testing();
    return 0;
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    print STDERR "heap-observe-ca.pl: $error";
    $status = 2;
};
exit($status == 0 && !Test::More->builder->is_passing ? 1 : $status);
