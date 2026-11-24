#!/usr/bin/env perl
# Sends the raw getData requests of a request plan to the retrieval service, one or several clients at once, and records every outcome.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Digest::SHA;
use File::Path qw(make_path);
use Getopt::Long qw(GetOptionsFromArray);
use HTTP::Tiny;
use IO::Handle;
use JSON::PP;
use Pod::Usage qw(pod2usage);
use POSIX ();
use Time::HiRes qw(clock_gettime gettimeofday sleep CLOCK_MONOTONIC);

=head1 NAME

request-array.pl - send the requests of a plan to the retrieval service with overlapping clients and keep each outcome

=head1 SYNOPSIS

  perl tests/heap/request-array.pl --plan FILE --output-dir DIR [--url URL] [--clients N] [--groups G]
      [--timeout SECONDS] [--pause SECONDS]
  perl tests/heap/request-array.pl --help

=head1 DESCRIPTION

Reads the request plan C<--plan>, a CSV file with the header C<name,pv,from,to>: C<name> labels a request, C<pv> is the PV,
C<from> and C<to> are the window as UTC times with milliseconds (C<2026-11-24T06:55:05.000Z>). A group is one pass over the
plan by C<--clients> clients (1 to 4) that start together after a common release and send every request of the plan in
the plan order; the run repeats the group C<--groups> times, with C<--pause> seconds between two groups. The request is
C<URL?pv=NAME&from=START&to=END>.

The response is read to its end and hashed without being kept; for a status other than 200 its first 2048 bytes are kept as
the error text. A request ends with its answer or after C<--timeout> seconds in all (default 300), whichever comes first; a
request that has no answer is recorded with C<http> 0 and the reason. A failed or refused request is an outcome, not an error of the
tool.

C<DIR/requests.csv> gets one row per request with the header
C<group,client,sequence,name,pv,from,to,time_utc,monotonic_s,end_utc,ms,http,bytes,sha256,error>; C<time_utc> and C<monotonic_s> are the
start of the request, C<end_utc> its end, C<ms> the elapsed time on the monotonic clock and C<bytes> the size of the response. The rows are in the order of group, client and sequence.
C<DIR/run.json> records the command line, the SHA-256 of the plan, the start and the end of the run. A directory that already holds a
C<requests.csv> is refused. Required: Perl 5.26 or newer, HTTP::Tiny (plain http only), JSON::PP.

=head1 OPTIONS

=over 4

=item B<--plan> FILE

The request plan. Required.

=item B<--output-dir> DIR

The directory for C<requests.csv> and C<run.json>; created when missing. Required.

=item B<--url> URL

The getData.json address. Default C<http://localhost:17668/retrieval/data/getData.json>.

=item B<--clients> N

The number of clients that send a group together, 1 to 4 (default 1).

=item B<--groups> G

The number of groups, a positive integer (default 1).

=item B<--timeout> SECONDS

The time limit of one request in all (default 300).

=item B<--pause> SECONDS

The wait between two groups (default 0).

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when the run is complete (whatever the outcomes of the requests), 1 when a result file cannot be written, 2 for invalid usage,
77 for a plan that cannot be read or is malformed.

=cut

my $DEFAULT_URL = 'http://localhost:17668/retrieval/data/getData.json';
my $DEFAULT_TIMEOUT = 300;
my $MAX_CLIENTS = 4;
my $ERROR_BYTES = 2048;
my $TIME_PATTERN = qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$/;
my @COLUMNS = qw(group client sequence name pv from to time_utc monotonic_s end_utc ms http bytes sha256 error);
my $EXIT_OK = 0;
my $EXIT_WRITE = 1;
my $EXIT_USAGE = 2;
my $EXIT_INPUT = 77;

sub fail_with {
    my ($status, $message) = @_;
    die { status => $status, message => $message };
}

sub utc_now {
    my ($seconds, $micro) = gettimeofday();
    return POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime($seconds)) . sprintf('.%03dZ', $micro / 1000);
}

sub csv_field {
    my ($text) = @_;
    $text = '' unless defined $text;
    return $text =~ /[",\r\n]/ ? '"' . ($text =~ s/"/""/gr) . '"' : $text;
}

sub csv_split {
    my ($line) = @_;
    my @fields;
    while ($line =~ /\G(?:"((?:[^"]|"")*)"|([^,]*))(?:,|$)/gc) {
        push @fields, defined $1 ? $1 =~ s/""/"/gr : $2;
        last if pos($line) >= length($line);
    }
    return @fields;
}

sub read_plan {
    my ($path) = @_;
    open(my $handle, '<', $path) or fail_with($EXIT_INPUT, "$path: $!");
    my $header = <$handle>;
    defined $header or fail_with($EXIT_INPUT, "$path: empty");
    $header =~ s/\r?\n$//;
    my @names = csv_split($header);
    my %index = map { $names[$_] => $_ } 0 .. $#names;
    for my $column (qw(name pv from to)) {
        defined $index{$column} or fail_with($EXIT_INPUT, "$path: the header has no column $column");
    }
    my @rows;
    while (my $line = <$handle>) {
        $line =~ s/\r?\n$//;
        next if $line eq '';
        my @fields = csv_split($line);
        my %row = map { $_ => $fields[$index{$_}] } qw(name pv from to);
        for my $column (qw(from to)) {
            ($row{$column} // '') =~ $TIME_PATTERN or fail_with($EXIT_INPUT, "$path: line $.: $column is not a UTC time with milliseconds");
        }
        defined $row{pv} && $row{pv} ne '' or fail_with($EXIT_INPUT, "$path: line $.: the pv is empty");
        push @rows, \%row;
    }
    close($handle) or fail_with($EXIT_INPUT, "$path: $!");
    @rows or fail_with($EXIT_INPUT, "$path: no request");
    return @rows;
}

sub sha256_file {
    my ($path) = @_;
    return Digest::SHA->new(256)->addfile($path, 'b')->hexdigest;
}

sub url_encode {
    my ($text) = @_;
    $text =~ s/([^A-Za-z0-9_.~:-])/sprintf('%%%02X', ord($1))/ge;
    return $text;
}

# Sends one request and returns the fields of its row after the plan columns.
sub send_request {
    my ($url, $row, $timeout) = @_;
    my $query = "$url?pv=" . url_encode($row->{pv}) . '&from=' . url_encode($row->{from}) . '&to=' . url_encode($row->{to});
    my $start_clock = clock_gettime(CLOCK_MONOTONIC);
    my $start_utc = utc_now();
    my $digest = Digest::SHA->new(256);
    my ($bytes, $head) = (0, '');
    my $response;
    my $done = eval {
        local $SIG{ALRM} = sub { die "timeout after $timeout seconds\n" };
        alarm($timeout);
        $response = HTTP::Tiny->new(timeout => $timeout)->request('GET', $query, {
            data_callback => sub {
                my ($chunk) = @_;
                $digest->add($chunk);
                $bytes += length($chunk);
                $head .= substr($chunk, 0, $ERROR_BYTES - length($head)) if length($head) < $ERROR_BYTES;
            },
        });
        alarm(0);
        1;
    };
    my $reason = $@;
    alarm(0);
    my $end_clock = clock_gettime(CLOCK_MONOTONIC);
    my ($http, $error) = (0, '');
    if (!$done) {
        $error = $reason =~ s/\n+$//r;
    }
    elsif ($response->{status} == 599) {
        $error = ($response->{content} // $response->{reason} // 'no answer') =~ s/\s+$//r;
    }
    else {
        $http = $response->{status};
        # HTTP::Tiny hands the body of an unsuccessful response to the caller instead of the callback.
        $error = substr($response->{content} // $head, 0, $ERROR_BYTES) =~ s/[\r\n]+/ /gr if $http != 200;
    }
    return ($start_utc, sprintf('%.6f', $start_clock), utc_now(), sprintf('%.0f', ($end_clock - $start_clock) * 1000), $http, $bytes,
        $http ? $digest->hexdigest : '', $error);
}

# Runs one client of one group: sends the whole plan in order and writes its rows to a private file.
sub run_client {
    my ($options, $rows, $group, $client, $path, $release) = @_;
    my $got = sysread($release, my $byte, 1);
    open(my $out, '>', $path) or POSIX::_exit(126);
    my $sequence = 0;
    for my $row (@$rows) {
        $sequence++;
        my @outcome = send_request($options->{url}, $row, $options->{timeout});
        print {$out} join(',', map { csv_field($_) } $group, $client, $sequence, @{$row}{qw(name pv from to)}, @outcome), "\n" or POSIX::_exit(126);
    }
    close($out) or POSIX::_exit(126);
    POSIX::_exit(0);
}

sub run_group {
    my ($options, $rows, $group, $directory, $results) = @_;
    my (@pids, @writers, @paths);
    for my $client (1 .. $options->{clients}) {
        pipe(my $read, my $write) or fail_with($EXIT_WRITE, "pipe: $!");
        my $path = "$directory/.part-$group-$client";
        my $pid = fork();
        defined $pid or fail_with($EXIT_WRITE, "fork: $!");
        if (!$pid) {
            close($write);
            run_client($options, $rows, $group, $client, $path, $read);
        }
        close($read);
        push @pids, $pid;
        push @writers, $write;
        push @paths, $path;
    }
    for my $write (@writers) {
        print {$write} '1';
        close($write);
    }
    my $failed = 0;
    for my $index (0 .. $#pids) {
        waitpid($pids[$index], 0);
        $failed = 1 if $? != 0;
    }
    $failed and fail_with($EXIT_WRITE, "a client of group $group could not write its rows");
    for my $path (@paths) {
        open(my $handle, '<', $path) or fail_with($EXIT_WRITE, "$path: $!");
        print {$results} $_ or fail_with($EXIT_WRITE, "write of the results: $!") while <$handle>;
        close($handle);
        unlink $path or fail_with($EXIT_WRITE, "$path: $!");
    }
    $results->flush or fail_with($EXIT_WRITE, "write of the results: $!");
    return;
}

sub main {
    my (@arguments) = @_;
    my %options = (url => $DEFAULT_URL, clients => 1, groups => 1, timeout => $DEFAULT_TIMEOUT, pause => 0);
    my $help;
    GetOptionsFromArray(\@arguments, \%options, 'plan=s', 'output-dir=s', 'url=s', 'clients=i', 'groups=i', 'timeout=i', 'pause=f', 'help' => \$help)
        or fail_with($EXIT_USAGE, 'invalid option');
    if ($help) {
        pod2usage(-exitval => 'NOEXIT', -verbose => 99, -sections => [qw(NAME SYNOPSIS DESCRIPTION OPTIONS)], -output => \*STDOUT);
        return $EXIT_OK;
    }
    @arguments and fail_with($EXIT_USAGE, "unexpected argument: $arguments[0]");
    defined $options{plan} or fail_with($EXIT_USAGE, '--plan is required');
    defined $options{'output-dir'} or fail_with($EXIT_USAGE, '--output-dir is required');
    $options{clients} >= 1 && $options{clients} <= $MAX_CLIENTS or fail_with($EXIT_USAGE, "--clients must be between 1 and $MAX_CLIENTS");
    $options{groups} >= 1 or fail_with($EXIT_USAGE, '--groups must be a positive integer');
    $options{timeout} >= 1 or fail_with($EXIT_USAGE, '--timeout must be a positive integer');
    $options{pause} >= 0 or fail_with($EXIT_USAGE, '--pause must not be negative');
    my @rows = read_plan($options{plan});
    my $directory = $options{'output-dir'};
    -e "$directory/requests.csv" and fail_with($EXIT_USAGE, "$directory already holds a requests.csv");
    make_path($directory);
    my $start_utc = utc_now();
    open(my $results, '>', "$directory/requests.csv") or fail_with($EXIT_WRITE, "$directory/requests.csv: $!");
    print {$results} join(',', @COLUMNS), "\n" or fail_with($EXIT_WRITE, "$directory/requests.csv: $!");
    $results->flush or fail_with($EXIT_WRITE, "$directory/requests.csv: $!");
    for my $group (1 .. $options{groups}) {
        run_group(\%options, \@rows, $group, $directory, $results);
        sleep($options{pause}) if $group < $options{groups} && $options{pause} > 0;
    }
    close($results) or fail_with($EXIT_WRITE, "$directory/requests.csv: $!");
    my $record = { argv => [ @ARGV ], plan_sha256 => sha256_file($options{plan}), plan_rows => scalar(@rows), clients => $options{clients},
        groups => $options{groups}, timeout_s => $options{timeout}, url => $options{url}, start_utc => $start_utc, end_utc => utc_now() };
    open(my $run, '>', "$directory/run.json") or fail_with($EXIT_WRITE, "$directory/run.json: $!");
    print {$run} JSON::PP->new->canonical->pretty->encode($record) or fail_with($EXIT_WRITE, "$directory/run.json: $!");
    close($run) or fail_with($EXIT_WRITE, "$directory/run.json: $!");
    return $EXIT_OK;
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    if (ref $error eq 'HASH') {
        print STDERR "request-array: $error->{message}\n";
        $status = $error->{status};
    }
    else {
        print STDERR "request-array: $error";
        $status = $EXIT_USAGE;
    }
};
exit $status;
