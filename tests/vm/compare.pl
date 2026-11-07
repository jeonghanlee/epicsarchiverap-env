#!/usr/bin/env perl
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
use Pod::Usage qw(pod2usage);
use lib dirname(abs_path(__FILE__)) . '/../lib';
use ArchiverTest qw(slurp check);

my $HEADER = 'time_utc,secs,nanos,value,severity,status';
my @REGISTRATION = qw(pvName creationTime applianceIdentity samplingMethod samplingPeriod
    DBRType elementCount scalar usePVAccess dataStores archiveFields);

sub json_file {
    my ($path) = @_;
    my $value = JSON::PP->new->decode(slurp($path));
    ref($value) eq 'HASH' or die "$path: expected a JSON object\n";
    return $value;
}

sub csv_rows {
    my ($path) = @_;
    my @lines = split /\n/, slurp($path);
    @lines && shift(@lines) eq $HEADER or die "$path: invalid CSV header\n";
    my @rows;
    for my $line (@lines) {
        my @fields = split /,/, $line, -1;
        @fields == 6 && $fields[1] =~ /^\d+$/ && $fields[2] =~ /^\d+$/
            && $fields[2] < 1_000_000_000 && $fields[3] =~ /^\d+(?:\.0+)?$/
            && $fields[4] =~ /^\d+$/ && $fields[5] =~ /^\d+$/
            or die "$path: invalid scalar-counter CSV row\n";
        push @rows, { text => $line, sec => 0 + $fields[1], nano => 0 + $fields[2],
            value => 0 + $fields[3], severity => 0 + $fields[4], status => 0 + $fields[5] };
    }
    return \@rows;
}

sub compare_history {
    my ($before, $after, $contains) = @_;
    my $expected = csv_rows($before);
    my $observed = csv_rows($after);
    @$expected >= 2 or die "$before: historical baseline requires at least two samples\n";
    my %counts;
    $counts{$_->{text}}++ for @$observed;
    for my $row (@$expected) {
        check(($counts{$row->{text}} // 0) > 0,
            'historical sample fields and occurrence counts are preserved');
        $counts{$row->{text}}--;
    }
    check(@$expected == @$observed, 'historical query has no additional samples') unless $contains;
    return scalar @$expected;
}

sub compare_samples {
    my ($ca_path, $csv_path, $from, $to) = @_;
    defined($from) && defined($to) && $from =~ /^\d+$/ && $to =~ /^\d+$/ && $from < $to
        or die "samples requires integer --from and --to with from < to\n";
    my %ca;
    for my $line (split /\n/, slurp($ca_path)) {
        my ($sec, $value, $nano, @extra) = split /\t/, $line;
        defined($nano) && !@extra && $sec =~ /^\d+$/ && $value =~ /^\d+$/
            && $nano =~ /^\d+$/ && $nano < 1_000_000_000
            or die "$ca_path: invalid CA observation\n";
        next if $sec < $from || $sec > $to || ($sec == $to && $nano > 0);
        push @{ $ca{0 + $value} }, [0 + $sec, 0 + $nano];
    }
    keys(%ca) >= 2 or die "$ca_path: fewer than two distinct CA values in the observation interval\n";
    my %matched;
    for my $row (@{csv_rows($csv_path)}) {
        next if $row->{sec} < $from || $row->{sec} > $to
            || ($row->{sec} == $to && $row->{nano} > 0)
            || $row->{severity} || $row->{status};
        for my $seen (@{$ca{$row->{value}} // []}) {
            # Integer nanosecond differences preserve subsecond evidence.
            my $delta = ($row->{sec} - $seen->[0]) * 1_000_000_000 + $row->{nano} - $seen->[1];
            $matched{$row->{value}} = 1 if abs($delta) <= 1_000_000_000;
        }
    }
    check(keys(%matched) >= 2, 'two distinct stored values match new CA values and timestamps');
    return scalar keys %matched;
}

sub compare_registration {
    my ($before, $after) = @_;
    my $expected = json_file($before);
    my $observed = json_file($after);
    my $json = JSON::PP->new->canonical->allow_nonref;
    for my $key (@REGISTRATION) {
        exists($expected->{$key}) && exists($observed->{$key})
            or die "registration: missing required field $key\n";
        defined($expected->{$key}) && defined($observed->{$key})
            or die "registration: null required field $key\n";
        check($json->encode($expected->{$key}) eq $json->encode($observed->{$key}),
            "registration preserves $key");
    }
    return scalar @REGISTRATION;
}

sub compare_processes {
    my ($before, $after, $unchanged) = @_;
    my $expected = json_file($before);
    my $observed = json_file($after);
    for my $record ($expected, $observed) {
        for my $key (qw(boot invocation processes configuration wars)) {
            exists($record->{$key}) or die "process observation: missing $key\n";
        }
        for my $key (qw(boot invocation configuration wars)) {
            defined($record->{$key}) && !ref($record->{$key}) && length($record->{$key})
                or die "process observation: invalid $key\n";
        }
        $record->{invocation} =~ /^[a-f0-9]{32}$/ or die "process observation: invalid invocation ID\n";
        ref($record->{processes}) eq 'HASH' or die "process observation: invalid processes\n";
    }
    check($expected->{boot} eq $observed->{boot}, 'guest boot identity is unchanged');
    check(($expected->{invocation} eq $observed->{invocation}) == $unchanged,
        $unchanged ? 'service invocation is unchanged' : 'service invocation changed after restart');
    for my $component (qw(mgmt engine etl retrieval)) {
        for my $record ($expected, $observed) {
            defined($record->{processes}{$component}) && !ref($record->{processes}{$component})
                && $record->{processes}{$component} =~ /^\d+:\d+$/
                or die "process observation: missing $component lifetime\n";
        }
        check(($expected->{processes}{$component} eq $observed->{processes}{$component}) == $unchanged,
            "$component lifetime " . ($unchanged ? 'is unchanged' : 'changed after restart'));
    }
    for my $key (qw(configuration wars)) {
        check($expected->{$key} eq $observed->{$key}, "$key is unchanged");
    }
    return 8;
}

sub main {
    my (@args) = @_;
    my ($mode, $from, $to, $help);
    GetOptionsFromArray(\@args, 'mode=s' => \$mode, 'from=s' => \$from,
        'to=s' => \$to, 'help' => \$help) or die "invalid options\n";
    if ($help) { pod2usage(-verbose => 2, -noperldoc => 1, -exitval => 'NOEXIT'); return 0; }
    defined($mode) && @args == 2 or die "supply --mode and two evidence paths; see --help\n";
    my $count;
    if ($mode eq 'history' || $mode eq 'contains') {
        $count = compare_history(@args, $mode eq 'contains');
    } elsif ($mode eq 'samples') {
        $count = compare_samples(@args, $from, $to);
    } elsif ($mode eq 'registration') {
        $count = compare_registration(@args);
    } elsif ($mode eq 'restart' || $mode eq 'unchanged') {
        $count = compare_processes(@args, $mode eq 'unchanged');
    } else { die "unknown comparison mode: $mode\n"; }
    print "[PASS] $mode: $count records or checks\n";
    return 0;
}

my $status;
eval { $status = main(@ARGV); defined($status) or die "missing exit status\n"; 1 }
    or do { my $error = $@; print STDERR $error; $status = $error =~ /^ASSERTION:/ ? 1 : 2; };
exit $status;

=head1 NAME

compare.pl - compare retained VM installation observations

=head1 SYNOPSIS

  perl tests/vm/compare.pl --mode history before.csv after.csv
  perl tests/vm/compare.pl --mode samples --from 1793960000 --to 1793960015 ca.tsv samples.csv
  perl tests/vm/compare.pl --mode registration before.json after.json

=head1 DESCRIPTION

Runs the comparisons consumed by install.pl. Requires Perl 5.26.3 or later
with JSON::PP and the repository's ArchiverTest module. Does not contact an
appliance, register a PV, or change evidence.

=head1 OPTIONS

=over

=item --mode history|contains|samples|registration|restart|unchanged

History compares every CSV field and occurrence count, ignoring row order.
Contains requires the first CSV's rows to occur in the second, permitting
additional rows. Both require at least two baseline samples; fewer samples
make the comparison Incomplete. With a valid baseline, lost observed samples
fail the comparison. CSV input is the pinned client's six-column scalar-counter
format. Samples matches at least two distinct healthy stored values to CA
observations (seconds, value, nanoseconds, tab separated), within one second.
Missing or malformed observations are Incomplete, not a data-path failure.

Registration compares PV identity, creation time, appliance, sampling settings,
type, transport, stores and archived fields. Missing or null required fields
make the comparison Incomplete. Runtime rate estimates,
modification time and the source's restart-initialized chunkKey are not stable
registration settings. Restart requires changed service and JVM lifetimes;
unchanged requires identical lifetimes. Both preserve boot, configuration and
WAR observations. Process records are written by install.pl.

=item --from SECONDS --to SECONDS

Required inclusive UTC epoch-second bounds for samples. A sample after the
whole-second upper bound is excluded, preserving nanosecond precision.

=item --help

Print help and exit successfully.

=back

=head1 EXIT STATUS

0: comparison passed. 1: observed assertion violation. 2: invalid arguments,
missing or malformed evidence, or another tool error. A passing comparison
alone does not establish installation acceptance.

=cut
