#!/usr/bin/env perl
# Checks the shipped resource sampler through its command line against real processes and the real /proc and df.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage qw(pod2usage);
use POSIX ();
use Test::More;
use Time::HiRes qw(sleep);
use Time::Local qw(timegm);

BEGIN {
    require(dirname(abs_path($0)) . '/lib/ArchiverTest.pm');
    ArchiverTest->import(qw(slurp usage_error));
}

=head1 NAME

heap-sample-resources.pl - check the exit statuses, diagnostics and figures of tests/heap/sample-resources.pl

=head1 SYNOPSIS

  perl tests/heap-sample-resources.pl
  perl tests/heap-sample-resources.pl --help

=head1 DESCRIPTION

Runs the real sampler as a subprocess. Its usage errors, a missing process (including a real zombie), a missing path and
an output file that cannot be opened need no sampled process. The sampling cases run it on a real C<sleep> process and
on this checkout's filesystem. Every expected figure (resident set size and thread count from ps, the process start
tick from /proc, the memory total from /proc/meminfo, the block and inode totals from df, the wall clock from date)
comes from those tools, not from the sampler. The cases also cover the exact rows and header of a run, the sample spacing
on the monotonic clock, the five-second default interval, an appended second run (one header), a process that ends while it is sampled, a run ended by a
duration and a run ended by SIGTERM (whole samples only).

The temporary directory uses TMPDIR when writable, otherwise work/scratch/tmp of the checkout; it is removed after the
run. Required: Perl 5.26 or newer, Test::More, Time::HiRes, Linux /proc, sh, ps, sed, awk, df, date and sleep.

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
my $TOOL = "$REPOSITORY/tests/heap/sample-resources.pl";
my $HEADER = 'time_utc,monotonic_s,scope,name,metric,value';
my $HOST_METRICS = 2;
my $PROCESS_METRICS = 6;
my $FILESYSTEM_METRICS = 8;
my $SAMPLE_ROWS = $HOST_METRICS + $PROCESS_METRICS + $FILESYSTEM_METRICS;
my $RSS_TOLERANCE_KIB = 64;
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

# Starts a command in the background and remembers it so the END block can stop it.
sub spawn {
    my (@command) = @_;
    my $pid = fork;
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        open(STDOUT, '>', '/dev/null') or POSIX::_exit(126);
        open(STDERR, '>', '/dev/null') or POSIX::_exit(126);
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
    @CHILDREN = grep { $_ != $pid } @CHILDREN;
    return;
}

# Runs a shell script with the standard text tools and returns its trimmed output.
sub text_tool {
    my ($script, @arguments) = @_;
    my ($status, $stdout, $stderr) = run_command('sh', '-c', $script, 'sh', @arguments);
    $status == 0 or die "text tool failed with $status: $stderr\n";
    $stdout =~ s/\A\s+|\s+\z//g;
    return $stdout;
}

# Reads the sample file and returns the rows grouped by sample, each row a hash of the six columns.
sub read_samples {
    my ($path) = @_;
    my @lines = split /\n/, slurp($path);
    my $header = shift @lines;
    my (@samples, %index);
    for my $line (@lines) {
        my %row;
        @row{qw(time_utc monotonic_s scope name metric value)} = split /,/, $line, 6;
        my $key = "$row{time_utc} $row{monotonic_s}";
        push @samples, [] unless exists $index{$key};
        $index{$key} //= $#samples;
        push @{ $samples[ $index{$key} ] }, \%row;
    }
    return ($header, \@samples);
}

sub metric {
    my ($sample, $scope, $name, $metric) = @_;
    my ($row) = grep { $_->{scope} eq $scope && $_->{name} eq $name && $_->{metric} eq $metric } @{$sample};
    return defined $row ? $row->{value} : undef;
}

sub epoch_of {
    my ($utc) = @_;
    my ($y, $mo, $d, $h, $mi, $s, $ms) = $utc =~ /^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\.(\d{3})Z$/ or return;
    return timegm($s, $mi, $h, $d, $mo - 1, $y) + $ms / 1000;
}

sub run_usage_cases {
    my ($workspace) = @_;
    my $output = "$workspace/usage.csv";
    my @cases = (
        ['no option', [], qr/--output is required/],
        ['unknown option', ['--bogus'], qr/Unknown option/],
        ['zero interval', ['--output', $output, '--interval', '0'], qr/--interval must be a number greater than zero/],
        ['non-numeric interval', ['--output', $output, '--interval', 'x'], qr/--interval must be a number/],
        ['zero duration', ['--output', $output, '--duration', '0'], qr/--duration must be a number greater than zero/],
        ['zero count', ['--output', $output, '--count', '0'], qr/--count must be a positive integer/],
        ['fractional count', ['--output', $output, '--count', '1.5'], qr/--count must be a positive integer/],
        ['process without a pid', ['--output', $output, '--process', 'engine'], qr/expects LABEL=VALUE/],
        ['process with pid zero', ['--output', $output, '--process', 'engine=0'], qr/expects LABEL=VALUE/],
        ['repeated process label', ['--output', $output, '--process', 'a=1', '--process', 'a=2'], qr/label is repeated: a/],
        ['repeated filesystem label', ['--output', $output, '--filesystem', "a=$workspace", '--filesystem', "a=$workspace"], qr/label is repeated: a/],
        ['stray argument', ['--output', $output, 'extra'], qr/unexpected argument/],
    );
    my ($status, $stdout, $stderr) = run_tool('--help');
    is($status, 0, 'help: exit status');
    like($stdout, qr/--process/, 'help: names the process option');
    for my $case (@cases) {
        my ($name, $arguments, $diagnostic) = @{$case};
        ($status, $stdout, $stderr) = run_tool(@{$arguments});
        is($status, 2, "$name: usage status");
        like($stderr, $diagnostic, "$name: diagnostic");
        is($stdout, '', "$name: nothing on stdout");
    }
    ok(!-e $output, 'usage errors create no output file');
    return;
}

sub run_missing_input_cases {
    my ($workspace) = @_;
    my $output = "$workspace/missing.csv";
    my $pid_max = text_tool('cat /proc/sys/kernel/pid_max') + 0;
    my $absent = $pid_max - 1;
    die "pid $absent unexpectedly exists\n" if -d "/proc/$absent";

    my $zombie = fork;
    defined $zombie or die "fork: $!\n";
    POSIX::_exit(0) if !$zombie;
    push @CHILDREN, $zombie;
    sleep 0.3;
    my $zombie_state = text_tool('sed -n "s/^State:\s*\(.\).*/\1/p" /proc/$1/status', $zombie);
    is($zombie_state, 'Z', 'control: the child that ended without being waited for is a real zombie');

    my @cases = (
        ['process that does not exist', ['--process', "gone=$absent"], qr/Process $absent \(gone\) is not running/],
        ['zombie process', ['--process', "dead=$zombie"], qr/Process $zombie \(dead\) is not running/],
        ['path that does not exist', ['--filesystem', "x=$workspace/absent"], qr/Path does not exist: .*absent \(x\)/],
    );
    for my $case (@cases) {
        my ($name, $arguments, $diagnostic) = @{$case};
        my ($status, $stdout, $stderr) = run_tool('--output', $output, '--count', '1', @{$arguments});
        is($status, 77, "$name: incomplete status");
        like($stderr, $diagnostic, "$name: diagnostic");
        is($stdout, '', "$name: nothing on stdout");
    }
    ok(!-e $output, 'a missing input creates no output file');
    reap($zombie);

    my ($status, $stdout, $stderr) = run_tool('--output', "$workspace/no-such-directory/samples.csv", '--count', '1');
    is($status, 1, 'unwritable output: collection failure status');
    like($stderr, qr/FAILURE: open .*samples\.csv/, 'unwritable output: diagnostic');
    return;
}

sub run_sampling_cases {
    my ($workspace) = @_;
    my $child = spawn('sleep', '60');
    sleep 0.3;
    my $output = "$workspace/samples.csv";
    my $before = text_tool('date -u +%s') + 0;
    my ($status, $stdout, $stderr) = run_tool('--output', $output, '--interval', '1', '--count', '3',
        '--process', "child=$child", '--filesystem', "repo=$REPOSITORY");
    my $after = text_tool('date -u +%s') + 0;
    is($status, 0, 'count run: exit status');
    is($stderr, '', 'count run: no diagnostics');
    my ($header, $samples) = read_samples($output);
    is($header, $HEADER, 'count run: the file starts with the header');
    is(scalar(@{$samples}), 3, 'count run: three samples');
    is_deeply([ map { scalar(@{$_}) } @{$samples} ], [ ($SAMPLE_ROWS) x 3 ], 'count run: every sample has every metric once');

    my @utc = map { $_->[0]{time_utc} } @{$samples};
    my @monotonic = map { $_->[0]{monotonic_s} } @{$samples};
    ok(!grep({ !defined epoch_of($_) } @utc), 'count run: wall clock is UTC with milliseconds');
    ok(epoch_of($utc[0]) >= $before - 1 && epoch_of($utc[0]) <= $after + 1, 'count run: the first sample time agrees with date');
    my @gaps = map { $monotonic[$_] - $monotonic[ $_ - 1 ] } 1 .. $#monotonic;
    ok(!grep({ $_ < 0.95 || $_ > 1.5 } @gaps), "count run: samples are one second apart on the monotonic clock (@gaps)");

    my $sample = $samples->[0];
    is(metric($sample, 'host', 'host', 'mem_total_kib'), text_tool('awk "/^MemTotal:/{print \$2}" /proc/meminfo'), 'host: memory total equals /proc/meminfo');
    my ($total, $available) = (metric($sample, 'host', 'host', 'mem_total_kib'), metric($sample, 'host', 'host', 'mem_available_kib'));
    ok($available > 0 && $available <= $total, 'host: available memory is positive and not above the total');

    is(metric($sample, 'process', 'child', 'alive'), 1, 'process: a running child is alive');
    my $rss = text_tool('ps -o rss= -p "$1"', $child);
    ok(abs(metric($sample, 'process', 'child', 'rss_kib') - $rss) <= $RSS_TOLERANCE_KIB, "process: resident set size agrees with ps ($rss KiB)");
    is(metric($sample, 'process', 'child', 'threads'), text_tool('ps -o nlwp= -p "$1"', $child), 'process: thread count agrees with ps');
    is(metric($sample, 'process', 'child', 'start_ticks'), text_tool('sed -E "s/^[0-9]+ \(.*\) //" /proc/$1/stat | cut -d" " -f20', $child), 'process: start tick equals /proc');
    is(metric($samples->[2], 'process', 'child', 'start_ticks'), metric($sample, 'process', 'child', 'start_ticks'), 'process: the start tick identifies the same instance in every sample');

    is(metric($sample, 'filesystem', 'repo', 'total_kib'), text_tool('df -Pk "$1" | tail -1 | awk "{print \$2}"', $REPOSITORY), 'filesystem: block total equals df');
    is(metric($sample, 'filesystem', 'repo', 'inodes_total'), text_tool('df -Pi "$1" | tail -1 | awk "{print \$2}"', $REPOSITORY), 'filesystem: inode total equals df');
    my $percent = metric($sample, 'filesystem', 'repo', 'used_percent');
    ok($percent =~ /^\d+$/ && $percent <= 100, 'filesystem: used percent is an integer up to 100');
    ok(metric($sample, 'filesystem', 'repo', 'used_kib') + metric($sample, 'filesystem', 'repo', 'available_kib') <= metric($sample, 'filesystem', 'repo', 'total_kib'),
        'filesystem: used plus available does not exceed the total');

    ($status, $stdout, $stderr) = run_tool('--output', $output, '--count', '1', '--filesystem', "repo=$REPOSITORY");
    is($status, 0, 'append run: exit status');
    my $text = slurp($output);
    is(scalar(() = $text =~ /^\Q$HEADER\E$/mg), 1, 'append run: the header appears once');
    is(scalar(split(/\n/, $text)), 1 + 3 * $SAMPLE_ROWS + $HOST_METRICS + $FILESYSTEM_METRICS, 'append run: the new sample follows the old rows');

    my $duration_output = "$workspace/duration.csv";
    ($status) = run_tool('--output', $duration_output, '--interval', '1', '--duration', '2.5');
    is($status, 0, 'duration run: exit status');
    (undef, $samples) = read_samples($duration_output);
    is(scalar(@{$samples}), 3, 'duration run: samples start at 0, 1 and 2 seconds and not at 3');

    my $default_output = "$workspace/default-interval.csv";
    ($status) = run_tool('--output', $default_output, '--count', '2');
    is($status, 0, 'default interval: exit status');
    (undef, $samples) = read_samples($default_output);
    my $default_gap = $samples->[1][0]{monotonic_s} - $samples->[0][0]{monotonic_s};
    ok($default_gap >= 4.5 && $default_gap <= 6.5, "default interval: samples are five seconds apart ($default_gap)");

    run_ending_process_case($workspace);
    run_signal_case($workspace);
    return;
}

# A child that ends during sampling is reported as not alive afterwards, and the sampler keeps running.
sub run_ending_process_case {
    my ($workspace) = @_;
    my $short = spawn('sleep', '2');
    my $output = "$workspace/ending.csv";
    my ($status, $stdout, $stderr) = run_tool('--output', $output, '--interval', '1', '--count', '4', '--process', "short=$short");
    is($status, 0, 'ending process: exit status');
    my (undef, $samples) = read_samples($output);
    is(scalar(@{$samples}), 4, 'ending process: all four samples are written');
    is(metric($samples->[0], 'process', 'short', 'alive'), 1, 'ending process: alive in the first sample');
    is(metric($samples->[3], 'process', 'short', 'alive'), 0, 'ending process: not alive in the last sample');
    is(metric($samples->[3], 'process', 'short', 'rss_kib'), undef, 'ending process: a dead process reports no resident set size');
    is(scalar(@{ $samples->[3] }), $HOST_METRICS + 1, 'ending process: a dead process reports only alive');
    reap($short);
    return;
}

# SIGTERM ends the run after the sample in progress; the file holds whole samples only.
sub run_signal_case {
    my ($workspace) = @_;
    my $output = "$workspace/signal.csv";
    my $sampler = spawn($^X, $TOOL, '--output', $output, '--interval', '1', '--filesystem', "repo=$REPOSITORY");
    sleep 2.5;
    kill 'TERM', $sampler;
    waitpid($sampler, 0);
    my $wait_status = $?;
    @CHILDREN = grep { $_ != $sampler } @CHILDREN;
    is($wait_status, 0, 'signal run: SIGTERM ends the sampler by a normal exit with status 0, not by the signal');
    my (undef, $samples) = read_samples($output);
    cmp_ok(scalar(@{$samples}), '>=', 2, 'signal run: at least two samples were written');
    is_deeply([ grep { scalar(@{$_}) != $HOST_METRICS + $FILESYSTEM_METRICS } @{$samples} ], [], 'signal run: every sample is whole');
    return;
}

sub main {
    my @arguments = @_;
    my $help;
    GetOptionsFromArray(\@arguments, 'help' => \$help) or return usage_error('heap-sample-resources.pl', __FILE__, 'invalid option');
    if ($help) {
        pod2usage(-input => __FILE__, -exitval => 'NOEXIT', -verbose => 1, -output => \*STDOUT);
        return 0;
    }
    @arguments and return usage_error('heap-sample-resources.pl', __FILE__, 'unexpected argument');
    -f $TOOL or die "missing sampler: $TOOL\n";

    my $temporary_root = defined $ENV{TMPDIR} && -d $ENV{TMPDIR} && -w _ ? $ENV{TMPDIR} : "$REPOSITORY/work/scratch/tmp";
    make_path($temporary_root);
    my $workspace = tempdir('heap-sample-XXXXXX', DIR => $temporary_root, CLEANUP => 1);

    run_usage_cases($workspace);
    run_missing_input_cases($workspace);
    run_sampling_cases($workspace);

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
    print STDERR "heap-sample-resources.pl: $error";
    $status = 2;
};
exit($status == 0 && !Test::More->builder->is_passing ? 1 : $status);
