#!/usr/bin/env perl
# Appends periodic host, process and filesystem samples to one CSV file until a count, a duration or a signal ends it.
use strict;
use warnings;
use Getopt::Long qw(GetOptionsFromArray);
use IO::Handle;
use Pod::Usage qw(pod2usage);
use POSIX qw(strftime);
use Time::HiRes qw(clock_gettime gettimeofday CLOCK_MONOTONIC);

=head1 NAME

sample-resources.pl - append host, process and filesystem samples to a CSV file

=head1 SYNOPSIS

  perl tests/heap/sample-resources.pl --output samples.csv [--interval SECONDS]
      [--count N] [--duration SECONDS]
      [--process LABEL=PID ...] [--filesystem LABEL=PATH ...]
  perl tests/heap/sample-resources.pl --help

=head1 DESCRIPTION

Samples the machine it runs on every C<--interval> seconds (default 5) and appends the samples to C<--output>.
The file starts with the header C<time_utc,monotonic_s,scope,name,metric,value>; a file that already holds data is
appended to without a second header. Every row is one metric of one sample. C<time_utc> is the wall clock in UTC with
milliseconds and C<monotonic_s> is CLOCK_MONOTONIC in seconds, so UTC steps and durations stay separate. All rows of one
sample share both values and are written together.

Scope C<host> (name C<host>) reports C<mem_total_kib> and C<mem_available_kib> from /proc/meminfo. Scope C<process>
(name is the label of C<--process>) reports C<alive>, and while the process runs C<rss_kib>, C<threads>,
C<cpu_utime_ticks>, C<cpu_stime_ticks> and C<start_ticks>; C<start_ticks> identifies the process instance, so a changed
value between samples is a restart. A process that is gone or a zombie reports C<alive> 0 and nothing else, and the
sampling continues. Scope C<filesystem> (name is the label of C<--filesystem>) reports C<total_kib>, C<used_kib>,
C<available_kib>, C<used_percent>, C<inodes_total>, C<inodes_used>, C<inodes_free> and C<inodes_used_percent> from df.

Sample times are scheduled from the start on the monotonic clock, so a slow sample does not shift the later ones.
The run ends before the sample that would start at or after C<--duration> seconds, after C<--count> samples, or when
SIGTERM or SIGINT arrives (the sample in progress is finished first); with none of these it runs until a signal.
Required: Perl 5.26 or newer, Linux /proc, df.

=head1 OPTIONS

=over 4

=item B<--output> FILE

The CSV file to append to. Required.

=item B<--interval> SECONDS

Seconds between samples, greater than zero. Default 5.

=item B<--count> N

Stop after N samples (positive integer).

=item B<--duration> SECONDS

Stop before the first sample that would start at or after this many seconds (greater than zero).

=item B<--process> LABEL=PID

A running process to sample. LABEL (letters, digits, dot, underscore, hyphen) names it in the file. Repeatable.

=item B<--filesystem> LABEL=PATH

An existing path whose filesystem is sampled with df. LABEL as above. Repeatable.

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when the run ended by count, duration or signal, 1 when a sample could not be written or df failed (the sampler
stops), 77 when a named process is not running or a path does not exist at the start, 2 for invalid usage.

=cut

my $HEADER = 'time_utc,monotonic_s,scope,name,metric,value';
my $DEFAULT_INTERVAL_SECONDS = 5;
my $NUMBER = qr/\d+(?:\.\d+)?/;
my $LABEL = qr/[A-Za-z0-9_.-]+/;
my $STOP = 0;

# An invalid or missing input is an expected outcome with its own exit status.
sub incomplete {
    my ($message) = @_;
    die { incomplete => $message };
}

# A failure of the collection itself ends the sampler with its own exit status.
sub collection_failure {
    my ($message) = @_;
    die { failure => $message };
}

sub read_text {
    my ($path) = @_;
    open(my $handle, '<', $path) or return;
    local $/;
    my $text = <$handle>;
    close($handle);
    return $text;
}

sub host_metrics {
    my $text = read_text('/proc/meminfo');
    defined $text or collection_failure('cannot read /proc/meminfo');
    my @metrics;
    for my $pair (['MemTotal', 'mem_total_kib'], ['MemAvailable', 'mem_available_kib']) {
        $text =~ /^\Q$pair->[0]\E:\s+(\d+) kB$/m or collection_failure("no $pair->[0] in /proc/meminfo");
        push @metrics, [$pair->[1], $1];
    }
    return @metrics;
}

# Returns the fields of /proc/PID/stat that follow the command name, or nothing for a missing or finished process.
sub process_stat {
    my ($pid) = @_;
    my $text = read_text("/proc/$pid/stat");
    defined $text or return;
    $text =~ s/\A\d+ \(.*\) //s or return;
    my @fields = split ' ', $text;
    return if !@fields || $fields[0] eq 'Z' || $fields[0] eq 'X';
    return @fields;
}

sub process_metrics {
    my ($pid) = @_;
    my @fields = process_stat($pid);
    return (['alive', 0]) unless @fields;
    my $status = read_text("/proc/$pid/status");
    return (['alive', 0]) unless defined $status;
    my @metrics = (['alive', 1]);
    push @metrics, ['rss_kib', $1] if $status =~ /^VmRSS:\s+(\d+) kB$/m;
    push @metrics, ['threads', $1] if $status =~ /^Threads:\s+(\d+)$/m;
    push @metrics, ['cpu_utime_ticks', $fields[11]], ['cpu_stime_ticks', $fields[12]], ['start_ticks', $fields[19]];
    return @metrics;
}

sub command_output {
    my (@command) = @_;
    my $pid = open(my $out, '-|');
    defined $pid or collection_failure("fork: $!");
    if (!$pid) {
        open(STDERR, '>', '/dev/null') or POSIX::_exit(126);
        $ENV{LC_ALL} = 'C';
        {
            no warnings 'exec';    # the exit below reports a failed exec
            exec { $command[0] } @command;
        }
        POSIX::_exit(127);
    }
    my $stdout = do { local $/; <$out> };
    close($out);
    $? == 0 or collection_failure("@command failed with status " . ($? >> 8));
    return defined $stdout ? $stdout : '';
}

# Reads the single data line of a POSIX df report: filesystem and four numbers with a percentage.
sub df_fields {
    my ($option, $path) = @_;
    my @lines = split /\n/, command_output('df', $option, $path);
    my @fields = split ' ', $lines[-1];
    @fields >= 5 or collection_failure("unexpected df output for $path");
    return @fields;
}

sub filesystem_metrics {
    my ($path) = @_;
    my (undef, $total, $used, $available, $percent) = df_fields('-Pk', $path);
    my (undef, $inodes, $inodes_used, $inodes_free, $inodes_percent) = df_fields('-Pi', $path);
    $percent =~ s/%\z//;
    $inodes_percent =~ s/%\z//;
    return (
        ['total_kib', $total], ['used_kib', $used], ['available_kib', $available], ['used_percent', $percent],
        ['inodes_total', $inodes], ['inodes_used', $inodes_used], ['inodes_free', $inodes_free],
        ['inodes_used_percent', $inodes_percent],
    );
}

# Formats the rows of one sample: every metric of the host, each process and each filesystem with one shared time.
sub sample_text {
    my ($processes, $filesystems) = @_;
    my ($seconds, $microseconds) = gettimeofday();
    my $monotonic = clock_gettime(CLOCK_MONOTONIC);
    my $utc = strftime('%Y-%m-%dT%H:%M:%S', gmtime($seconds)) . sprintf('.%03dZ', int($microseconds / 1000));
    my @groups = (['host', 'host', [host_metrics()]]);
    push @groups, ['process', $_->[0], [process_metrics($_->[1])]] for @{$processes};
    push @groups, ['filesystem', $_->[0], [filesystem_metrics($_->[1])]] for @{$filesystems};
    my $text = '';
    for my $group (@groups) {
        my ($scope, $name, $metrics) = @{$group};
        $text .= join(',', $utc, sprintf('%.3f', $monotonic), $scope, $name, $_->[0], $_->[1]) . "\n" for @{$metrics};
    }
    return $text;
}

sub open_output {
    my ($path) = @_;
    my $new = !-s $path;
    open(my $handle, '>>', $path) or collection_failure("open $path: $!");
    $handle->autoflush(1);
    print {$handle} "$HEADER\n" or collection_failure("write $path: $!") if $new;
    return $handle;
}

sub run_sampling {
    my ($options, $processes, $filesystems) = @_;
    my $handle = open_output($options->{output});
    local $SIG{TERM} = sub { $STOP = 1 };
    local $SIG{INT} = sub { $STOP = 1 };
    my $start = clock_gettime(CLOCK_MONOTONIC);
    my $taken = 0;
    while (!$STOP) {
        my $due = $start + $taken * $options->{interval};
        last if defined $options->{duration} && $due - $start >= $options->{duration};
        my $wait = $due - clock_gettime(CLOCK_MONOTONIC);
        if ($wait > 0) {
            Time::HiRes::sleep($wait);
            next;
        }
        print {$handle} sample_text($processes, $filesystems) or collection_failure("write $options->{output}: $!");
        $taken++;
        last if defined $options->{count} && $taken >= $options->{count};
    }
    close($handle) or collection_failure("close $options->{output}: $!");
    return;
}

sub usage_status {
    my ($message) = @_;
    print STDERR "sample-resources.pl: $message\n";
    pod2usage(-input => __FILE__, -verbose => 0, -exitval => 'NOEXIT', -output => \*STDERR);
    return 2;
}

# Splits repeated LABEL=VALUE options and returns the pairs, or the usage message of the first malformed one.
sub label_pairs {
    my ($option, $values, $pattern) = @_;
    my (@pairs, %seen);
    for my $value (@{$values}) {
        $value =~ /\A($LABEL)=($pattern)\z/ or return (undef, "--$option expects LABEL=VALUE, got: $value");
        $seen{$1}++ and return (undef, "--$option label is repeated: $1");
        push @pairs, [$1, $2];
    }
    return (\@pairs, undef);
}

sub main {
    my @arguments = @_;
    my ($help, @processes, @filesystems, %options);
    $options{interval} = $DEFAULT_INTERVAL_SECONDS;
    GetOptionsFromArray(
        \@arguments,
        'help' => \$help,
        'output=s' => \$options{output},
        'interval=s' => \$options{interval},
        'count=s' => \$options{count},
        'duration=s' => \$options{duration},
        'process=s' => \@processes,
        'filesystem=s' => \@filesystems,
    ) or return usage_status('invalid option');
    if ($help) {
        pod2usage(-input => __FILE__, -verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        return 0;
    }
    @arguments and return usage_status('unexpected argument');
    defined $options{output} && length $options{output} or return usage_status('--output is required');
    for my $name (qw(interval duration)) {
        next unless defined $options{$name};
        $options{$name} =~ /\A$NUMBER\z/ && $options{$name} > 0 or return usage_status("--$name must be a number greater than zero");
        $options{$name} += 0;
    }
    defined $options{count} && $options{count} !~ /\A[1-9]\d*\z/ and return usage_status('--count must be a positive integer');
    my ($process_pairs, $process_error) = label_pairs('process', \@processes, qr/[1-9]\d*/);
    defined $process_pairs or return usage_status($process_error);
    my ($filesystem_pairs, $filesystem_error) = label_pairs('filesystem', \@filesystems, qr/.+/);
    defined $filesystem_pairs or return usage_status($filesystem_error);

    my $failed = eval {
        for my $pair (@{$process_pairs}) {
            process_stat($pair->[1]) or incomplete("Process $pair->[1] ($pair->[0]) is not running");
        }
        for my $pair (@{$filesystem_pairs}) {
            -e $pair->[1] or incomplete("Path does not exist: $pair->[1] ($pair->[0])");
        }
        run_sampling(\%options, $process_pairs, $filesystem_pairs);
        1;
    };
    if (!$failed) {
        my $error = $@;
        ref $error eq 'HASH' or die $error;
        if (exists $error->{incomplete}) {
            print STDERR "INCOMPLETE: $error->{incomplete}\n";
            return 77;
        }
        print STDERR "FAILURE: $error->{failure}\n";
        return 1;
    }
    return 0;
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    print STDERR "sample-resources.pl: $error";
    $status = 2;
};
exit $status;
