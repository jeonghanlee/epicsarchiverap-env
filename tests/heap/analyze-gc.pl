#!/usr/bin/env perl
# Computes per-JVM garbage collection statistics and post-GC heap trends from G1 unified logging output.
use strict;
use warnings;
use Digest::SHA ();
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP ();
use List::Util qw(max min sum);
use Pod::Usage qw(pod2usage);

=head1 NAME

analyze-gc.pl - compute GC pause statistics and post-GC heap trends from G1 unified logs

=head1 SYNOPSIS

  perl tests/heap/analyze-gc.pl --log engine=engine-gc.log [--log etl=etl-gc.log ...]
      [--from SECONDS] [--to SECONDS] [--min-events N]
      [--tolerance-mib MIB --tolerance-mib-per-hour MIB] [--events]
  perl tests/heap/analyze-gc.pl --help

=head1 DESCRIPTION

Reads one G1 unified logging file per JVM lifetime (written with C<-Xlog:gc*> and decorators that include
C<uptime>, the default) and writes one JSON document to stdout. Each completed pause is the summary line
C<GC(n) Pause ... before->after(capacity) time>; it is identified by the JVM label, its GC ID and its pause class
(the Remark and Cleanup pauses of one concurrent cycle share the GC ID of that cycle), and its before and after heap
values and pause time stay paired. A start line without a summary line (an interrupted pause) is not an event.

Pauses are classified without merging types: Mixed is C<Pause Young (Mixed)>, Young is every other
C<Pause Young>, Full is C<Pause Full>, and Remark, Cleanup and Other are reported separately. Heap values are
converted to MiB. For each class the output holds the pause count, the pause time statistics (count, sum, median,
nearest-rank 99th percentile, maximum, all in milliseconds) and the after-GC heap statistics. A class without events
reports count zero and no percentile. C<heap_precision_mib> is the coarsest unit that the log prints for a heap
value, so it is the log-reported precision of every heap figure.

For Young, Mixed and Full the comparison interval (uptime C<--from> to C<--to>, whole log by default) is divided into
four bins of equal duration. Each bin reports its event count and the median after-GC heap. When every bin holds at
least C<--min-events> events, the trend is computed: the ordinary least-squares slope of the four medians at their bin
midpoints (MiB per hour) and the last-bin median minus the first-bin median (MiB). A bin below the minimum makes the
trend C<inconclusive>. With both tolerances given, C<growth> is true when the slope and the median increase both
exceed their tolerance; otherwise it is null.

Threads write log lines slightly out of order, so an uptime that steps back by up to one second is accepted. A log
that is not unified logging output, an empty log, a repeated GC ID within one pause class or an uptime that falls back
by more than one second (a JVM restart inside one file) is refused. The JSON holds the SHA256 of each log and no file path, so the same bytes give the same output.
Required: Perl 5.26 or newer, Digest::SHA, JSON::PP and List::Util.

=head1 OPTIONS

=over 4

=item B<--log> LABEL=FILE

One JVM lifetime. LABEL (letters, digits, dot, underscore, hyphen) names the JVM in the output. Repeat for several
JVMs. At least one is required.

=item B<--from> SECONDS

Start of the comparison interval in JVM uptime seconds. Default 0.

=item B<--to> SECONDS

End of the comparison interval in JVM uptime seconds. Default is the highest uptime in the log. Must be greater
than C<--from>.

=item B<--min-events> N

Smallest event count a bin needs for a computed trend. Default 5.

=item B<--tolerance-mib> MIB

Smallest last-bin minus first-bin median increase that counts as growth. Needs C<--tolerance-mib-per-hour>.

=item B<--tolerance-mib-per-hour> MIB

Smallest slope that counts as growth. Needs C<--tolerance-mib>.

=item B<--events>

Add every event of the interval (GC ID, uptime, class, heap values, pause time) to each log's result.

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when the JSON was written, 77 when a log is missing, empty, not unified logging output or inconsistent (no JSON is
written), 2 for invalid usage.

=cut

my $BIN_COUNT = 4;
my $DEFAULT_MIN_EVENTS = 5;
my $PERCENTILE = 99;
my $UPTIME_JITTER_SECONDS = 1;
my $SECONDS_PER_HOUR = 3600;
my %MIB_PER_UNIT = (K => 1 / 1024, M => 1, G => 1024);
my @CLASSES = qw(Young Mixed Full Remark Cleanup Other);
my @TREND_CLASSES = qw(Young Mixed Full);
my $NUMBER = qr/\d+(?:\.\d+)?/;
my $HEAP = qr/($NUMBER)([KMG])->($NUMBER)([KMG])\(($NUMBER)([KMG])\)/;
my $EVENT = qr/^\s*GC\((\d+)\) (Pause .*?) $HEAP ($NUMBER)ms\s*$/;

# An invalid or inconsistent input is an expected outcome with its own exit status.
sub incomplete {
    my ($message) = @_;
    die { incomplete => $message };
}

sub round6 {
    my ($value) = @_;
    return 0 + sprintf('%.6f', $value);
}

sub digest {
    my ($path) = @_;
    open(my $handle, '<:raw', $path) or incomplete("open $path: $!");
    my $checksum = Digest::SHA->new(256);
    $checksum->addfile($handle);
    close($handle) or incomplete("close $path: $!");
    return $checksum->hexdigest;
}

sub classify {
    my ($description) = @_;
    return 'Full' if $description =~ /^Pause Full\b/;
    return 'Mixed' if $description =~ /^Pause Young \(Mixed\)/;
    return 'Young' if $description =~ /^Pause Young\b/;
    return 'Remark' if $description =~ /^Pause Remark\b/;
    return 'Cleanup' if $description =~ /^Pause Cleanup\b/;
    return 'Other';
}

# Reads one log: validates unified logging structure and uptime order and returns the completed pause events.
sub parse_log {
    my ($path) = @_;
    open(my $handle, '<:raw', $path) or incomplete("open $path: $!");
    my (@events, %seen);
    my ($lines, $decorated, $last_uptime, $precision) = (0, 0, undef, 0);
    while (my $line = <$handle>) {
        $lines++;
        $line =~ s/\r?\n\z//;
        $line =~ /^((?:\[[^\]]*\])+)(.*)$/ or next;
        my ($decorators, $rest) = ($1, $2);
        $decorated++;
        $decorators =~ /\[($NUMBER)s\]/ or incomplete("No uptime decorator at line $lines of the log");
        my $uptime = $1 + 0;
        defined $last_uptime && $uptime < $last_uptime - $UPTIME_JITTER_SECONDS
            and incomplete("Uptime decreases by more than $UPTIME_JITTER_SECONDS second at line $lines; one log must hold one JVM lifetime");
        $last_uptime = max($uptime, defined $last_uptime ? $last_uptime : 0);
        $rest =~ $EVENT or next;
        my ($gc_id, $description, @heap) = ($1, $2, $3, $4, $5, $6, $7, $8, $9);
        my $pause_ms = pop @heap;
        my $class = classify($description);
        exists $seen{"$gc_id $class"}
            and incomplete("GC ID $gc_id is repeated for a $class pause at line $lines; one log must hold one JVM lifetime");
        $seen{"$gc_id $class"} = 1;
        my @mib;
        my $event_precision = 0;
        while (my ($value, $unit) = splice(@heap, 0, 2)) {
            push @mib, $value * $MIB_PER_UNIT{$unit};
            $event_precision = max($event_precision, $MIB_PER_UNIT{$unit});
        }
        $precision = max($precision, $event_precision);
        push @events, {
            gc_id => $gc_id + 0, uptime => $uptime, class => $class,
            evacuation_failure => ($description =~ /\(Evacuation Failure\)/ ? 1 : 0),
            before_mib => $mib[0], after_mib => $mib[1], capacity_mib => $mib[2], pause_ms => $pause_ms + 0,
        };
    }
    close($handle) or incomplete("close $path: $!");
    $lines > 0 or incomplete("Empty log: $path");
    $decorated > 0 or incomplete("Not unified logging output: $path");
    return { events => \@events, lines => $lines, uptime_last => $last_uptime, precision => $precision };
}

sub median {
    my (@sorted) = sort { $a <=> $b } @_;
    my $count = scalar(@sorted);
    return $count % 2 ? $sorted[($count - 1) / 2] : ($sorted[$count / 2 - 1] + $sorted[$count / 2]) / 2;
}

sub pause_statistics {
    my (@values) = @_;
    return { count => 0 } unless @values;
    my @sorted = sort { $a <=> $b } @values;
    return {
        count => scalar(@sorted), sum => round6(sum(@sorted)), median => round6(median(@sorted)),
        p99 => round6($sorted[int(($PERCENTILE * scalar(@sorted) + 99) / 100) - 1]), max => round6($sorted[-1]),
    };
}

sub heap_statistics {
    my (@values) = @_;
    return { count => 0 } unless @values;
    return { count => scalar(@values), min => round6(min(@values)), median => round6(median(@values)), max => round6(max(@values)) };
}

# Splits the interval into equal bins and returns each bin's event count and median after-GC heap.
sub make_bins {
    my ($events, $from, $to) = @_;
    my $width = ($to - $from) / $BIN_COUNT;
    my @heaps = map { [] } 1 .. $BIN_COUNT;
    if ($width > 0) {
        for my $event (@{$events}) {
            my $index = int(($event->{uptime} - $from) / $width);
            $index = $BIN_COUNT - 1 if $index >= $BIN_COUNT;
            push @{ $heaps[$index] }, $event->{after_mib};
        }
    }
    my @bins;
    for my $index (0 .. $BIN_COUNT - 1) {
        my @values = @{ $heaps[$index] };
        push @bins, {
            start_s => round6($from + $index * $width), end_s => round6($from + ($index + 1) * $width),
            count => scalar(@values), median_after_mib => (@values ? round6(median(@values)) : undef),
        };
    }
    return \@bins;
}

# Computes the least-squares slope of the bin medians and the last-minus-first median, or states why it cannot.
sub trend {
    my ($bins, $from, $to, $options) = @_;
    return { status => 'inconclusive', reason => 'The interval has no duration' } unless $to > $from;
    for my $index (0 .. $#{$bins}) {
        my $count = $bins->[$index]{count};
        $count >= $options->{min_events}
            or return { status => 'inconclusive', reason => 'Bin ' . ($index + 1) . " has $count events, the minimum is $options->{min_events}" };
    }
    my $width = ($to - $from) / $BIN_COUNT;
    my @x = map { ($from + ($_ + 0.5) * $width) / $SECONDS_PER_HOUR } 0 .. $BIN_COUNT - 1;
    my @y = map { $_->{median_after_mib} } @{$bins};
    my ($x_mean, $y_mean) = (sum(@x) / $BIN_COUNT, sum(@y) / $BIN_COUNT);
    my ($numerator, $denominator) = (0, 0);
    for my $index (0 .. $BIN_COUNT - 1) {
        $numerator += ($x[$index] - $x_mean) * ($y[$index] - $y_mean);
        $denominator += ($x[$index] - $x_mean)**2;
    }
    my $slope = $numerator / $denominator;
    my $increase = $y[-1] - $y[0];
    my $growth = undef;
    if (defined $options->{tolerance_mib} && defined $options->{tolerance_mib_per_hour}) {
        $growth = ($slope > $options->{tolerance_mib_per_hour} && $increase > $options->{tolerance_mib}) ? JSON::PP::true : JSON::PP::false;
    }
    return { status => 'computed', slope_mib_per_hour => round6($slope), last_minus_first_median_mib => round6($increase), growth => $growth };
}

sub analyze_log {
    my ($path, $options) = @_;
    my $log = parse_log($path);
    my $from = defined $options->{from} ? $options->{from} : 0;
    my $to = defined $options->{to} ? $options->{to} : $log->{uptime_last};
    my @in_interval = grep { $_->{uptime} >= $from && $_->{uptime} <= $to } @{ $log->{events} };
    my %classes;
    for my $class (@CLASSES) {
        my @events = grep { $_->{class} eq $class } @in_interval;
        my $entry = {
            count => scalar(@events),
            evacuation_failures => scalar(grep { $_->{evacuation_failure} } @events),
            pause_ms => pause_statistics(map { $_->{pause_ms} } @events),
            after_mib => heap_statistics(map { $_->{after_mib} } @events),
        };
        if (grep { $_ eq $class } @TREND_CLASSES) {
            $entry->{bins} = make_bins(\@events, $from, $to);
            $entry->{trend} = trend($entry->{bins}, $from, $to, $options);
        }
        $classes{$class} = $entry;
    }
    my $result = {
        sha256 => digest($path), lines => $log->{lines}, events_total => scalar(@{ $log->{events} }),
        uptime_last_s => round6($log->{uptime_last}), heap_precision_mib => round6($log->{precision}),
        interval => { from_s => round6($from), to_s => round6($to) }, classes => \%classes,
    };
    if ($options->{events}) {
        $result->{events} = [
            map {
                {
                    gc_id => $_->{gc_id}, uptime_s => $_->{uptime}, class => $_->{class},
                    before_mib => round6($_->{before_mib}), after_mib => round6($_->{after_mib}),
                    capacity_mib => round6($_->{capacity_mib}), pause_ms => $_->{pause_ms},
                    evacuation_failure => ($_->{evacuation_failure} ? JSON::PP::true : JSON::PP::false),
                }
            } @in_interval
        ];
    }
    return $result;
}

sub usage_status {
    my ($message) = @_;
    print STDERR "analyze-gc.pl: $message\n";
    pod2usage(-input => __FILE__, -verbose => 0, -exitval => 'NOEXIT', -output => \*STDERR);
    return 2;
}

sub main {
    my @arguments = @_;
    my ($help, @logs, %options);
    $options{min_events} = $DEFAULT_MIN_EVENTS;
    GetOptionsFromArray(
        \@arguments,
        'help' => \$help,
        'log=s' => \@logs,
        'from=s' => \$options{from},
        'to=s' => \$options{to},
        'min-events=s' => \$options{min_events},
        'tolerance-mib=s' => \$options{tolerance_mib},
        'tolerance-mib-per-hour=s' => \$options{tolerance_mib_per_hour},
        'events' => \$options{events},
    ) or return usage_status('invalid option');
    if ($help) {
        pod2usage(-input => __FILE__, -verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        return 0;
    }
    @arguments and return usage_status('unexpected argument');
    @logs or return usage_status('--log is required');
    for my $name (qw(from to tolerance_mib tolerance_mib_per_hour)) {
        next unless defined $options{$name};
        (my $flag = $name) =~ s/_/-/g;
        $options{$name} =~ /\A$NUMBER\z/ or return usage_status("--$flag must be a non-negative number");
        $options{$name} += 0;
    }
    $options{min_events} =~ /\A[1-9]\d*\z/ or return usage_status('--min-events must be a positive integer');
    $options{min_events} += 0;
    defined $options{from} && defined $options{to} && $options{to} <= $options{from}
        and return usage_status('--to must be greater than --from');
    (defined $options{tolerance_mib} xor defined $options{tolerance_mib_per_hour})
        and return usage_status('--tolerance-mib and --tolerance-mib-per-hour are given together');
    my (%paths, @labels);
    for my $log (@logs) {
        $log =~ /\A([A-Za-z0-9_.-]+)=(.+)\z/ or return usage_status("--log expects LABEL=FILE, got: $log");
        exists $paths{$1} and return usage_status("--log label is repeated: $1");
        $paths{$1} = $2;
        push @labels, $1;
    }
    my %results;
    my $failed = eval {
        $results{$_} = analyze_log($paths{$_}, \%options) for @labels;
        1;
    };
    if (!$failed) {
        my $error = $@;
        ref $error eq 'HASH' && exists $error->{incomplete} or die $error;
        print STDERR "INCOMPLETE: $error->{incomplete}\n";
        return 77;
    }
    my $document = {
        schema => 1,
        settings => {
            min_events => $options{min_events}, bins => $BIN_COUNT, percentile => $PERCENTILE,
            tolerance_mib => $options{tolerance_mib}, tolerance_mib_per_hour => $options{tolerance_mib_per_hour},
        },
        logs => \%results,
    };
    my $json = JSON::PP->new->canonical->indent->indent_length(2)->space_after;
    print $json->encode($document) or die "write stdout: $!\n";
    return 0;
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    print STDERR "analyze-gc.pl: $error";
    $status = 2;
};
exit $status;
