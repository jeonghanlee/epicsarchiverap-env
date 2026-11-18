#!/usr/bin/env perl
# Checks the shipped GC log analyzer through its command line against logs written by real JVMs.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP ();
use Pod::Usage qw(pod2usage);
use POSIX ();
use Test::More;

BEGIN {
    require(dirname(abs_path($0)) . '/lib/ArchiverTest.pm');
    ArchiverTest->import(qw(slurp spew which usage_error));
}

=head1 NAME

heap-analyze-gc.pl - check the exit statuses, diagnostics and figures of tests/heap/analyze-gc.pl

=head1 SYNOPSIS

  perl tests/heap-analyze-gc.pl
  perl tests/heap-analyze-gc.pl --help

=head1 DESCRIPTION

Runs the real analyzer as a subprocess. The usage cases (missing and malformed options, a missing, an empty and a
non-log input) need no JVM. The log cases first run the real fixture tests/heap/fixtures/Alloc.java in two real JVMs
with C<-Xlog:gc*,safepoint> and G1, so the analyzer reads logs that a JVM wrote. Every expected figure (event counts
per class, median, 99th percentile and maximum of the Young pauses, the heap values of the first Young pause, the
event counts of an interval, the SHA256 of the log) comes from grep, sed, awk, sort and sha256sum applied to the same
log file, not from the analyzer. A copy of the real log with a growing after-GC heap checks the bin counts and medians,
the least-squares slope, the last-minus-first median and the growth verdicts against awk and sort. Single changes to the real log (a repeated GC ID, a log written twice, removed uptime
decorators) must end with status 77, an uptime that steps back by one millisecond must be accepted, and a copy of the
log in another directory must give byte-identical output.
When no java is in PATH the log cases are not run and the test says so.

The temporary directory uses TMPDIR when writable, otherwise work/scratch/tmp of the checkout; it is removed after the
run. Required: Perl 5.26 or newer, Test::More, JSON::PP, sh, grep, sed, awk, sort, sha256sum and, for the log cases,
a JDK 17 or newer that runs a single source file.

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
my $TOOL = "$REPOSITORY/tests/heap/analyze-gc.pl";
my $FIXTURE = "$REPOSITORY/tests/heap/fixtures/Alloc.java";
my @JVM_OPTIONS = ('-Xms64m', '-Xmx64m', '-XX:+UseG1GC');
my $LOG_DECORATORS = 'uptime,level,tags';
my $TOLERANCE = 0.000001;

# The summary line of a completed pause: GC ID, description, before->after(capacity) heap and the pause time.
my $HEAP_AND_TIME = '[0-9.]+[KMG]->[0-9.]+[KMG]\([0-9.]+[KMG]\) [0-9.]+ms$';
my %CLASS_PATTERN = (
    all => 'GC\([0-9]+\) Pause .* ' . $HEAP_AND_TIME,
    Mixed => 'GC\([0-9]+\) Pause Young \(Mixed\) .* ' . $HEAP_AND_TIME,
    Young => 'GC\([0-9]+\) Pause Young \(.* ' . $HEAP_AND_TIME,
    Full => 'GC\([0-9]+\) Pause Full .* ' . $HEAP_AND_TIME,
    Remark => 'GC\([0-9]+\) Pause Remark ' . $HEAP_AND_TIME,
    Cleanup => 'GC\([0-9]+\) Pause Cleanup ' . $HEAP_AND_TIME,
);

# Shell script of trend_oracle: arguments are the log, the Young line pattern, the interval start and end and a scratch
# directory; it prints the four bin counts, the four bin medians, the slope and the last-minus-first median.
my $TREND_SCRIPT = <<'SCRIPT';
grep -E "$2" "$1" | grep -v "Pause Young (Mixed)" | sed -E "s/^\[([0-9.]+)s\].* ([0-9.]+)M->([0-9.]+)M\(.*/\1 \3/" |
  awk -v from="$3" -v to="$4" '{ t=$1; if (t<from || t>to) next; w=(to-from)/4; i=int((t-from)/w); if (i>3) i=3; print i, $2 }' > "$5/binned.txt"
for i in 0 1 2 3; do
  awk -v b=$i '$1==b{print $2}' "$5/binned.txt" | sort -n |
    awk '{v[NR]=$1} END{n=NR; m=(n%2)?v[(n+1)/2]:(v[n/2]+v[n/2+1])/2; printf "%d %.6f\n", n, m}'
done > "$5/medians.txt"
awk -v from="$3" -v to="$4" '{c[NR]=$1; y[NR]=$2; x[NR]=(from+(NR-0.5)*(to-from)/4)/3600}
  END{for(i=1;i<=4;i++){sx+=x[i]; sy+=y[i]} mx=sx/4; my=sy/4;
      for(i=1;i<=4;i++){n+=(x[i]-mx)*(y[i]-my); d+=(x[i]-mx)^2}
      printf "%d %d %d %d %.6f %.6f %.6f %.6f %.6f %.6f\n", c[1],c[2],c[3],c[4],y[1],y[2],y[3],y[4],n/d,y[4]-y[1]}' "$5/medians.txt"
SCRIPT

sub run_command {
    my ($command_line) = @_;
    my @command = @{$command_line};
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
    return run_command([$^X, $TOOL, @arguments]);
}

# Runs a shell script over the log file with the standard text tools and returns its trimmed output.
sub text_tool {
    my ($script, @arguments) = @_;
    my ($status, $stdout, $stderr) = run_command(['sh', '-c', $script, 'sh', @arguments]);
    $status == 0 or die "text tool failed with $status: $stderr\n";
    $stdout =~ s/\A\s+|\s+\z//g;
    return $stdout;
}

sub count_lines {
    my ($log, $pattern) = @_;
    return text_tool('grep -E "$2" "$1" | wc -l', $log, $pattern) + 0;
}

# Counts the lines of one class; Young excludes the Mixed pauses that share the Pause Young prefix.
sub class_count {
    my ($log, $class) = @_;
    return text_tool('grep -E "$2" "$1" | grep -v "Pause Young (Mixed)" | wc -l', $log, $CLASS_PATTERN{Young}) + 0
        if $class eq 'Young';
    return count_lines($log, $CLASS_PATTERN{$class});
}

# Median, nearest-rank 99th percentile and maximum of the Young pause times, computed by sort and awk.
sub young_pause_oracle {
    my ($log) = @_;
    my $script = 'grep -E "$2" "$1" | grep -v "Pause Young (Mixed)" | sed -E "s/.* ([0-9.]+)ms\$/\1/" | sort -n | '
        . q{awk '{v[NR]=$1} END{n=NR; m=(n%2)?v[(n+1)/2]:(v[n/2]+v[n/2+1])/2; r=int((99*n+99)/100); printf "%.6f %.6f %.6f\n", m, v[r], v[n]}'};
    return [ split ' ', text_tool($script, $log, $CLASS_PATTERN{Young}) ];
}

# Counts the Young pauses whose uptime lies in the closed interval.
sub young_in_interval {
    my ($log, $from, $to) = @_;
    my $script = 'grep -E "$2" "$1" | grep -v "Pause Young (Mixed)" | sed -E "s/^\[([0-9.]+)s\].*/\1/" | '
        . q{awk -v lo="$3" -v hi="$4" '$1>=lo && $1<=hi' | wc -l};
    return text_tool($script, $log, $CLASS_PATTERN{Young}, $from, $to) + 0;
}

# Before, after and capacity (MiB) of the first Young pause line.
sub first_young_heap {
    my ($log) = @_;
    my $script = 'grep -E "$2" "$1" | grep -v "Pause Young (Mixed)" | head -1 | '
        . 'sed -E "s/.* ([0-9.]+)M->([0-9.]+)M\(([0-9.]+)M\) .*/\1 \2 \3/"';
    return [ split ' ', text_tool($script, $log, $CLASS_PATTERN{Young}) ];
}

sub near {
    my ($left, $right, $tolerance) = @_;
    $tolerance = $TOLERANCE unless defined $tolerance;
    return abs($left - $right) < $tolerance ? 1 : 0;
}

# Bin counts and median after-GC heaps, the least-squares slope (MiB per hour) and the last-minus-first median of the
# Young pauses in the closed interval, computed by grep, sed, sort and awk from the log lines only.
sub trend_oracle {
    my ($log, $from, $to, $scratch) = @_;
    my @figures = split ' ', text_tool($TREND_SCRIPT, $log, $CLASS_PATTERN{Young}, $from, $to, $scratch);
    return { counts => [ @figures[0 .. 3] ], medians => [ @figures[4 .. 7] ], slope => $figures[8], increase => $figures[9] };
}

# Adds a growing after-GC heap to the Young pauses of the real log (one MiB per 100 ms of uptime) and compares the
# analyzer's bins, slope, increase and growth verdicts with the oracle computed from the same changed lines.
sub run_trend_cases {
    my ($workspace, $engine) = @_;
    my @lines = split /^/, slurp($engine);
    for my $line (@lines) {
        next unless $line =~ /^\[([0-9.]+)s\].* GC\(\d+\) Pause Young \((?!Mixed\))/;
        my $uptime = $1;
        next unless $line =~ /ms$/;
        $line =~ s{ ([0-9.]+)M->([0-9.]+)M\(}{" $1M->" . ($2 + int($uptime * 10)) . "M("}e;
    }
    my $grown = "$workspace/grown.log";
    spew($grown, join('', @lines));
    my ($from, $to) = (0, 3);
    my $expected = trend_oracle($grown, $from, $to, $workspace);
    my ($status, $stdout, $stderr) = run_tool('--log', "engine=$grown", '--from', $from, '--to', $to);
    is($status, 0, 'growing heap: exit status');
    my $young = parse_json($stdout)->{logs}{engine}{classes}{Young};
    is_deeply([ map { $_->{count} } @{ $young->{bins} } ], $expected->{counts}, "growing heap: bin counts equal the oracle (@{ $expected->{counts} })");
    my @medians = map { $_->{median_after_mib} } @{ $young->{bins} };
    ok(!grep({ !near($medians[$_], $expected->{medians}[$_]) } 0 .. 3), "growing heap: bin medians equal the oracle (@{ $expected->{medians} })");
    is($young->{trend}{status}, 'computed', 'growing heap: the trend is computed');
    ok(near($young->{trend}{slope_mib_per_hour}, $expected->{slope}, 0.001), "growing heap: slope equals the oracle ($expected->{slope} MiB per hour)");
    ok(near($young->{trend}{last_minus_first_median_mib}, $expected->{increase}, 0.001), "growing heap: increase equals the oracle ($expected->{increase} MiB)");
    cmp_ok($young->{trend}{slope_mib_per_hour}, '>', 0, 'growing heap: the slope is positive');
    cmp_ok($young->{trend}{last_minus_first_median_mib}, '>', 0, 'growing heap: the last bin is above the first');

    my @verdicts = (
        ['both tolerances exceeded', [ 1, 1 ], 1],
        ['increase below its tolerance', [ 1000000, 1 ], 0],
        ['slope below its tolerance', [ 1, 1000000 ], 0],
    );
    for my $case (@verdicts) {
        my ($name, $tolerances, $growth) = @{$case};
        ($status, $stdout, $stderr) = run_tool('--log', "engine=$grown", '--from', $from, '--to', $to,
            '--tolerance-mib', $tolerances->[0], '--tolerance-mib-per-hour', $tolerances->[1]);
        my $verdict = parse_json($stdout)->{logs}{engine}{classes}{Young}{trend}{growth};
        ok(JSON::PP::is_bool($verdict) && ($verdict ? 1 : 0) == $growth, "growth verdict: $name is " . ($growth ? 'true' : 'false'));
    }
    return;
}

sub parse_json {
    my ($text) = @_;
    my $data = eval { JSON::PP::decode_json($text) };
    return $data;
}

# Runs the fixture in a real JVM and returns the log it wrote.
sub write_real_log {
    my ($workspace, $name, $seconds, $retained_mib, $java) = @_;
    my $log = "$workspace/$name.log";
    my ($status, $stdout, $stderr) = run_command(
        [$java, @JVM_OPTIONS, "-Xlog:gc*,safepoint:file=$log:$LOG_DECORATORS", $FIXTURE, $seconds, $retained_mib]);
    $status == 0 or die "fixture JVM failed with $status: $stderr\n";
    -s $log or die "fixture JVM wrote no log: $log\n";
    return $log;
}

sub run_usage_cases {
    my ($workspace) = @_;
    my ($status, $stdout, $stderr) = run_tool('--help');
    is($status, 0, 'help: exit status');
    like($stdout, qr/--log/, 'help: names the log option');

    my $placeholder = "$workspace/placeholder.log";
    spew($placeholder, "x\n");
    my @cases = (
        ['no option', [], qr/--log is required/],
        ['unknown option', ['--bogus'], qr/Unknown option/],
        ['label without file', ['--log', 'engine'], qr/expects LABEL=FILE/],
        ['label with a space', ['--log', "a b=$placeholder"], qr/expects LABEL=FILE/],
        ['repeated label', ['--log', "a=$placeholder", '--log', "a=$placeholder"], qr/label is repeated: a/],
        ['non-numeric from', ['--log', "a=$placeholder", '--from', 'abc'], qr/--from must be a non-negative number/],
        ['negative to', ['--log', "a=$placeholder", '--to', '-1'], qr/--to must be a non-negative number/],
        ['to not after from', ['--log', "a=$placeholder", '--from', '5', '--to', '2'], qr/--to must be greater than --from/],
        ['zero min-events', ['--log', "a=$placeholder", '--min-events', '0'], qr/--min-events must be a positive integer/],
        ['one tolerance only', ['--log', "a=$placeholder", '--tolerance-mib', '1'], qr/given together/],
        ['bad tolerance', ['--log', "a=$placeholder", '--tolerance-mib', 'x', '--tolerance-mib-per-hour', '1'], qr/--tolerance-mib must be a non-negative number/],
        ['stray argument', ['--log', "a=$placeholder", 'extra'], qr/unexpected argument/],
    );
    for my $case (@cases) {
        my ($name, $arguments, $diagnostic) = @{$case};
        ($status, $stdout, $stderr) = run_tool(@{$arguments});
        is($status, 2, "$name: usage status");
        like($stderr, $diagnostic, "$name: diagnostic");
        is($stdout, '', "$name: nothing on stdout");
    }

    my $empty = "$workspace/empty.log";
    spew($empty, '');
    my $text = "$workspace/text.log";
    spew($text, "hello\nworld\n");
    @cases = (
        ['missing input', "$workspace/absent.log", qr/open .*absent\.log/],
        ['empty input', $empty, qr/Empty log/],
        ['not a unified log', $text, qr/Not unified logging output/],
    );
    for my $case (@cases) {
        my ($name, $path, $diagnostic) = @{$case};
        ($status, $stdout, $stderr) = run_tool('--log', "a=$path");
        is($status, 77, "$name: incomplete status");
        like($stderr, $diagnostic, "$name: diagnostic");
        is($stdout, '', "$name: nothing on stdout");
    }
    return;
}

sub run_log_cases {
    my ($workspace, $java) = @_;
    my $engine = write_real_log($workspace, 'engine', 4, 24, $java);
    my $etl = write_real_log($workspace, 'etl', 3, 12, $java);

    my ($status, $stdout, $stderr) = run_tool('--log', "engine=$engine", '--events');
    is($status, 0, 'real log: exit status');
    is($stderr, '', 'real log: no diagnostics');
    my $document = parse_json($stdout);
    ok(defined $document && ref $document eq 'HASH', 'real log: output is one JSON document') or return;
    my $result = $document->{logs}{engine};

    is($result->{sha256}, text_tool('sha256sum "$1" | cut -d" " -f1', $engine), 'real log: SHA256 equals sha256sum');
    is($result->{events_total}, count_lines($engine, $CLASS_PATTERN{all}), 'real log: all pause events counted');
    for my $class (qw(Young Mixed Full Remark Cleanup)) {
        is($result->{classes}{$class}{count}, class_count($engine, $class), "real log: $class event count");
    }
    cmp_ok($result->{classes}{Young}{count}, '>', 0, 'real log: the JVM wrote Young pauses');
    cmp_ok($result->{classes}{Mixed}{count}, '>', 0, 'real log: the JVM wrote Mixed pauses');
    is($result->{classes}{Other}{count}, 0, 'real log: no unclassified pause');
    is_deeply($result->{classes}{Full}{pause_ms}, { count => 0 }, 'real log: a class without events has count zero and no percentile');

    my ($median, $p99, $maximum) = @{ young_pause_oracle($engine) };
    my $young = $result->{classes}{Young}{pause_ms};
    ok(near($young->{median}, $median), "real log: Young pause median equals the awk median ($median)");
    ok(near($young->{p99}, $p99), "real log: Young pause nearest-rank p99 equals the awk value ($p99)");
    ok(near($young->{max}, $maximum), "real log: Young pause maximum equals the sort maximum ($maximum)");

    my ($before, $after, $capacity) = @{ first_young_heap($engine) };
    my ($first) = grep { $_->{class} eq 'Young' } @{ $result->{events} };
    ok(near($first->{before_mib}, $before) && near($first->{after_mib}, $after) && near($first->{capacity_mib}, $capacity),
        "real log: the first Young event keeps its own heap values ($before, $after, $capacity)");
    is($result->{heap_precision_mib}, 1, 'real log: heap precision is the 1 MiB unit of the log');
    my %seen;
    my @duplicates = grep { $seen{"$_->{gc_id} $_->{class}"}++ } @{ $result->{events} };
    is(scalar(@duplicates), 0, 'real log: every event is identified by its GC ID and class');

    my $trend = $result->{classes}{Young}{trend};
    is($trend->{status}, 'computed', 'real log: the Young trend is computed with the default minimum');
    is($trend->{growth}, undef, 'real log: growth is null without tolerances');
    my $bin_total = 0;
    $bin_total += $_->{count} for @{ $result->{classes}{Young}{bins} };
    is($bin_total, $result->{classes}{Young}{count}, 'real log: the four bins hold every Young event');

    ($status, $stdout, $stderr) = run_tool('--log', "engine=$engine", '--tolerance-mib', '1', '--tolerance-mib-per-hour', '1');
    my $toleranced = parse_json($stdout);
    ok(JSON::PP::is_bool($toleranced->{logs}{engine}{classes}{Young}{trend}{growth}), 'tolerances: growth is a boolean');

    ($status, $stdout, $stderr) = run_tool('--log', "engine=$engine", '--min-events', '1000000');
    my $strict = parse_json($stdout);
    like($strict->{logs}{engine}{classes}{Young}{trend}{reason}, qr/minimum is 1000000/, 'minimum events: the trend is inconclusive with its reason');

    is_deeply([ @{ $document->{settings} }{qw(min_events bins percentile)} ], [ 5, 4, 99 ], 'defaults: five events per bin, four bins, 99th percentile');
    run_trend_cases($workspace, $engine);

    ($status, $stdout, $stderr) = run_tool('--log', "engine=$engine", '--from', '1', '--to', '3');
    my $window = parse_json($stdout);
    is($window->{logs}{engine}{classes}{Young}{count}, young_in_interval($engine, 1, 3), 'interval: Young count equals the awk count between 1 and 3 seconds');

    ($status, $stdout, $stderr) = run_tool('--log', "engine=$engine", '--log', "etl=$etl");
    my $both = parse_json($stdout);
    is_deeply([ sort keys %{ $both->{logs} } ], [ 'engine', 'etl' ], 'two logs: each JVM keeps its label');
    is($both->{logs}{etl}{events_total}, count_lines($etl, $CLASS_PATTERN{all}), 'two logs: the second JVM counts its own events');

    my $copy_directory = "$workspace/copy";
    make_path($copy_directory);
    copy($engine, "$copy_directory/renamed.log") or die "copy: $!\n";
    my ($copy_status, $copy_stdout) = run_tool('--log', "engine=$copy_directory/renamed.log", '--events');
    is($copy_status, 0, 'separate copy: exit status');
    my (undef, $first_stdout) = run_tool('--log', "engine=$engine", '--events');
    is($copy_stdout, $first_stdout, 'separate copy: byte-identical output');

    run_mutation_cases($workspace, $engine);
    return;
}

# Applies one change at a time to the real log; a repeated GC ID, a log written twice and removed uptime decorators
# are refused with status 77, an uptime that steps back by one millisecond is accepted.
sub run_mutation_cases {
    my ($workspace, $engine) = @_;
    my $original = slurp($engine);
    my ($line) = $original =~ /^(\[[0-9.]+s\]\[info\]\[gc +\] GC\([0-9]+\) Pause Young \(Normal\)[^\n]* [0-9.]+ms)$/m;
    defined $line or die "no Young summary line in the real log\n";
    (my $later = $line) =~ s/^\[[0-9.]+s\]/[9999.000s]/;
    (my $undecorated = $original) =~ s/^\[[0-9.]+s\]//mg;
    my @cases = (
        ['repeated GC ID', "$original$later\n", qr/GC ID [0-9]+ is repeated for a Young pause/],
        ['log written twice', "$original$original", qr/Uptime decreases/],
        ['uptime decorator removed', $undecorated, qr/No uptime decorator/],
    );
    my $index = 0;
    for my $case (@cases) {
        my ($name, $content, $diagnostic) = @{$case};
        my $path = "$workspace/mutation-" . ++$index . '.log';
        spew($path, $content);
        my ($status, $stdout, $stderr) = run_tool('--log', "engine=$path");
        is($status, 77, "$name: incomplete status");
        like($stderr, $diagnostic, "$name: diagnostic");
        is($stdout, '', "$name: nothing on stdout");
    }

    # A real JVM writes lines of different threads slightly out of order; one millisecond back is accepted.
    my @lines = split /^/, $original;
    my $middle = int(scalar(@lines) / 2);
    my ($previous) = $lines[$middle - 1] =~ /^\[([0-9.]+)s\]/;
    defined $previous && $previous > 0.002 && $lines[$middle] =~ s/^\[[0-9.]+s\]/sprintf('[%.3fs]', $previous - 0.001)/e
        or die "cannot step the uptime of a real log line back\n";
    my $stepped = "$workspace/stepped.log";
    spew($stepped, join('', @lines));
    my ($status, $stdout, $stderr) = run_tool('--log', "engine=$stepped");
    is($status, 0, 'uptime one millisecond back: accepted');
    my $document = parse_json($stdout);
    is($document->{logs}{engine}{events_total}, count_lines($stepped, $CLASS_PATTERN{all}), 'uptime one millisecond back: every event counted');
    return;
}

sub main {
    my @arguments = @_;
    my $help;
    GetOptionsFromArray(\@arguments, 'help' => \$help) or return usage_error('heap-analyze-gc.pl', __FILE__, 'invalid option');
    if ($help) {
        pod2usage(-input => __FILE__, -exitval => 'NOEXIT', -verbose => 1, -output => \*STDOUT);
        return 0;
    }
    @arguments and return usage_error('heap-analyze-gc.pl', __FILE__, 'unexpected argument');
    -f $TOOL or die "missing analyzer: $TOOL\n";

    my $temporary_root = defined $ENV{TMPDIR} && -d $ENV{TMPDIR} && -w _ ? $ENV{TMPDIR} : "$REPOSITORY/work/scratch/tmp";
    make_path($temporary_root);
    my $workspace = tempdir('heap-analyze-XXXXXX', DIR => $temporary_root, CLEANUP => 1);

    run_usage_cases($workspace);

    my $java = which('java');
    if (defined $java) {
        run_log_cases($workspace, $java);
    }
    else {
        note('no java in PATH; the cases on logs written by a real JVM did not run');
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
    print STDERR "heap-analyze-gc.pl: $error";
    $status = 2;
};
exit($status == 0 && !Test::More->builder->is_passing ? 1 : $status);
