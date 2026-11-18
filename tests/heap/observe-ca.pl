#!/usr/bin/env perl
# Runs camonitor for a list of PVs, stores its output unmodified and appends a run record when it ends.
use strict;
use warnings;
use Cwd qw(getcwd);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
use Pod::Usage qw(pod2usage);
use POSIX qw(strftime);
use Time::HiRes qw(clock_gettime gettimeofday CLOCK_MONOTONIC);

=head1 NAME

observe-ca.pl - run camonitor for a PV list and keep its raw output with a run record

=head1 SYNOPSIS

  perl tests/heap/observe-ca.pl --pv-list FILE --output-dir DIR [--duration SECONDS]
      [--camonitor PATH] [-- CAMONITOR_OPTION ...]
  perl tests/heap/observe-ca.pl --help

=head1 DESCRIPTION

Starts one camonitor process for all PVs of C<--pv-list> (one PV per line; empty lines and lines starting with C<#> are
ignored) and writes its standard output to C<DIR/camonitor.out> and its standard error to C<DIR/camonitor.err>,
unmodified, appending to the files. Arguments after C<--> are passed to camonitor before the PV names.
The camonitor program is taken from C<--camonitor> or found in PATH; the Channel Access environment (for example
EPICS_CA_ADDR_LIST) is inherited unchanged.

When the run ends, C<DIR/run.json> records the camonitor command line (C<argv>), the working directory (C<cwd>), the
camonitor process id, start and end as UTC (C<start_utc>, C<end_utc>) and as CLOCK_MONOTONIC seconds (C<start_monotonic_s>,
C<end_monotonic_s>), how the run ended (C<ended_by>: C<camonitor_exit>, C<duration> or C<signal>), the exit status
(C<exit_status>, null when a signal ended camonitor), the terminating signal (C<signal>, null otherwise), the size in bytes of
both files (C<stdout_bytes>, C<stderr_bytes>) and the number of PVs (C<pv_count>). A directory that already holds a
C<run.json> is refused, so a record always describes the files beside it.

The run ends when camonitor exits, when C<--duration> seconds have passed (camonitor receives SIGTERM), or when this
program receives SIGTERM or SIGINT (camonitor receives SIGTERM).
Required: Perl 5.26 or newer.

=head1 OPTIONS

=over 4

=item B<--pv-list> FILE

The PV names. Required.

=item B<--output-dir> DIR

The directory for the three files; it is created when missing. Required.

=item B<--duration> SECONDS

End the run after this many seconds (greater than zero).

=item B<--camonitor> PATH

The camonitor program. Default: camonitor from PATH.

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when the run ended and the record was written (whatever the camonitor exit status was), 1 when a file could not be
written, 77 when camonitor, the PV list or a PV name is missing or the list is empty, 2 for invalid usage.

=cut

my $POLL_SECONDS = 0.1;
my $STOP = 0;
my @FILES = (stdout => 'camonitor.out', stderr => 'camonitor.err');

# An invalid or missing input is an expected outcome with its own exit status.
sub incomplete {
    my ($message) = @_;
    die { incomplete => $message };
}

# A failure to store the observation ends the program with its own exit status.
sub storage_failure {
    my ($message) = @_;
    die { failure => $message };
}

sub timestamps {
    my ($seconds, $microseconds) = gettimeofday();
    my $utc = strftime('%Y-%m-%dT%H:%M:%S', gmtime($seconds)) . sprintf('.%03dZ', int($microseconds / 1000));
    return ($utc, sprintf('%.3f', clock_gettime(CLOCK_MONOTONIC)));
}

# Returns the path of an executable named directly or found in PATH, or nothing.
sub find_program {
    my ($name) = @_;
    return -f $name && -x _ ? $name : undef if $name =~ m{/};
    for my $directory (split /:/, $ENV{PATH} // '') {
        my $path = ($directory eq '' ? '.' : $directory) . "/$name";
        return $path if -f $path && -x _;
    }
    return;
}

sub read_pv_list {
    my ($path) = @_;
    open(my $handle, '<', $path) or incomplete("Cannot read PV list $path: $!");
    my @pvs;
    while (my $line = <$handle>) {
        $line =~ s/\s+\z//;
        $line =~ s/\A\s+//;
        next if $line eq '' || $line =~ /\A#/;
        $line =~ /\A[^\s\x00-\x1f]+\z/ or incomplete("Invalid PV name in $path line $.: $line");
        push @pvs, $line;
    }
    close($handle);
    @pvs or incomplete("PV list $path has no PV");
    return @pvs;
}

sub prepare_directory {
    my ($directory) = @_;
    -d $directory or mkdir($directory) or -d $directory or storage_failure("mkdir $directory: $!");
    -e "$directory/run.json" and die { usage => "$directory already holds a run.json" };
    return;
}

# Starts camonitor with its output appended to the two files and returns the process id.
sub start_camonitor {
    my ($directory, @command) = @_;
    my %path = (@FILES);
    my $pid = fork();
    defined $pid or storage_failure("fork: $!");
    if (!$pid) {
        open(STDIN, '<', '/dev/null') or POSIX::_exit(126);
        open(STDOUT, '>>', "$directory/$path{stdout}") or POSIX::_exit(126);
        open(STDERR, '>>', "$directory/$path{stderr}") or POSIX::_exit(126);
        {
            no warnings 'exec';    # the exit below reports a failed exec
            exec { $command[0] } @command;
        }
        POSIX::_exit(127);
    }
    return $pid;
}

# Waits for camonitor, ends it with SIGTERM at the duration or on a stop request, and returns how it ended and its status.
sub wait_camonitor {
    my ($pid, $start, $duration) = @_;
    my $ended_by = 'camonitor_exit';
    my $terminated = 0;
    while (1) {
        my $done = waitpid($pid, POSIX::WNOHANG());
        return ($ended_by, $?) if $done == $pid;
        $done < 0 and storage_failure("waitpid $pid: $!");
        if (!$terminated) {
            if ($STOP) {
                $ended_by = 'signal';
            }
            elsif (defined $duration && clock_gettime(CLOCK_MONOTONIC) - $start >= $duration) {
                $ended_by = 'duration';
            }
            if ($ended_by ne 'camonitor_exit') {
                kill('TERM', $pid);
                $terminated = 1;
            }
        }
        Time::HiRes::sleep($POLL_SECONDS);
    }
}

sub write_record {
    my ($directory, $record) = @_;
    my $path = "$directory/run.json";
    open(my $handle, '>', "$path.tmp") or storage_failure("open $path.tmp: $!");
    print {$handle} JSON::PP->new->canonical->pretty->encode($record) or storage_failure("write $path.tmp: $!");
    close($handle) or storage_failure("close $path.tmp: $!");
    rename("$path.tmp", $path) or storage_failure("rename $path.tmp: $!");
    return;
}

sub observe {
    my ($options, $camonitor, $extra, $pvs) = @_;
    my $directory = $options->{output_dir};
    prepare_directory($directory);
    my @command = ($camonitor, @{$extra}, @{$pvs});
    my ($start_utc, $start_monotonic) = timestamps();
    local $SIG{TERM} = sub { $STOP = 1 };
    local $SIG{INT} = sub { $STOP = 1 };
    my $pid = start_camonitor($directory, @command);
    my ($ended_by, $wait_status) = wait_camonitor($pid, $start_monotonic, $options->{duration});
    my ($end_utc, $end_monotonic) = timestamps();
    my %path = (@FILES);
    my $signal = $wait_status & 127;
    write_record($directory, {
        argv => \@command,
        cwd => getcwd(),
        pid => $pid + 0,
        start_utc => $start_utc,
        start_monotonic_s => $start_monotonic + 0,
        end_utc => $end_utc,
        end_monotonic_s => $end_monotonic + 0,
        ended_by => $ended_by,
        exit_status => $signal ? undef : $wait_status >> 8,
        signal => $signal ? $signal : undef,
        stdout_bytes => (-s "$directory/$path{stdout}") + 0,
        stderr_bytes => (-s "$directory/$path{stderr}") + 0,
        pv_count => scalar @{$pvs},
    });
    return;
}

sub usage_status {
    my ($message) = @_;
    print STDERR "observe-ca.pl: $message\n";
    pod2usage(-input => __FILE__, -verbose => 0, -exitval => 'NOEXIT', -output => \*STDERR);
    return 2;
}

sub main {
    my @arguments = @_;
    my ($help, %options);
    my $camonitor_name = 'camonitor';
    GetOptionsFromArray(
        \@arguments,
        'help' => \$help,
        'pv-list=s' => \$options{pv_list},
        'output-dir=s' => \$options{output_dir},
        'duration=s' => \$options{duration},
        'camonitor=s' => \$camonitor_name,
    ) or return usage_status('invalid option');
    if ($help) {
        pod2usage(-input => __FILE__, -verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        return 0;
    }
    for my $name (qw(pv_list output_dir)) {
        defined $options{$name} && length $options{$name} or return usage_status('--' . ($name =~ s/_/-/r) . ' is required');
    }
    if (defined $options{duration}) {
        $options{duration} =~ /\A\d+(?:\.\d+)?\z/ && $options{duration} > 0
            or return usage_status('--duration must be a number greater than zero');
        $options{duration} += 0;
    }

    my $failed = eval {
        my $camonitor = find_program($camonitor_name) // incomplete("camonitor not found: $camonitor_name");
        my @pvs = read_pv_list($options{pv_list});
        observe(\%options, $camonitor, \@arguments, \@pvs);
        1;
    };
    return 0 if $failed;
    my $error = $@;
    ref $error eq 'HASH' or die $error;
    if (exists $error->{usage}) {
        return usage_status($error->{usage});
    }
    if (exists $error->{incomplete}) {
        print STDERR "INCOMPLETE: $error->{incomplete}\n";
        return 77;
    }
    print STDERR "FAILURE: $error->{failure}\n";
    return 1;
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    print STDERR "observe-ca.pl: $error";
    $status = 2;
};
exit $status;
