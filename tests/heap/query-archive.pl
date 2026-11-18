#!/usr/bin/env perl
# Sends getData requests for random PVs to the retrieval service and stores each full response with its SHA256.
use strict;
use warnings;
use Digest::SHA;
use File::Path qw(make_path);
use Getopt::Long qw(GetOptionsFromArray);
use HTTP::Tiny;
use IO::Handle;
use Pod::Usage qw(pod2usage);
use POSIX qw(strftime);
use Time::HiRes qw(clock_gettime gettimeofday CLOCK_MONOTONIC);

=head1 NAME

query-archive.pl - read random PVs from the archive retrieval service and keep every full response

=head1 SYNOPSIS

  perl tests/heap/query-archive.pl --pv-csv FILE --output-dir DIR [--url URL] [--client N]
      [--pause SECONDS] [--timeout SECONDS] [--count N] [--duration SECONDS]
  perl tests/heap/query-archive.pl --help

=head1 DESCRIPTION

One client of the retrieval load. Each request picks a PV at random from the C<pv> column of C<--pv-csv> and reads
the window that ends now: one hour, or for a PV of group scan C<1 second> whose name has no C<WF> a random choice of one
hour or one day. The request is C<URL?pv=NAME&from=START&to=END> with both times in UTC with milliseconds
(C<2026-11-18T12:00:00.000Z>). The client waits C<--pause> seconds (default 2) after each completed request and then sends
the next. The random choice is seeded with C<--client> (default 0), so the same client number and PV file give the same
sequence of PVs and windows; run one process per client number for parallel clients.

The full response, whatever its status, is streamed to C<DIR/responses/c<client>-<sequence>.json> without being held in
memory, and its SHA256 is computed on the bytes written. C<DIR/requests-<client>.csv> gets one row per request with the
header C<time_utc,monotonic_s,client,pv,window,http,ms,bytes,samples,sha256,file,error>: C<time_utc> and C<monotonic_s>
are the start of the request, C<http> is the status code (0 when no response arrived, with the reason in C<error>), C<ms>
is the elapsed time on the monotonic clock, C<bytes> the response size and C<samples> the number of C<"secs"> keys in
the response. A client whose request file already exists is refused, so a file always holds one run.

The run ends before the next request after C<--duration> seconds, after C<--count> requests, or when SIGTERM or SIGINT
arrives (the request in progress and its row are finished first); with none of these it runs until a signal.
Required: Perl 5.26 or newer, HTTP::Tiny (plain http only).

=head1 OPTIONS

=over 4

=item B<--pv-csv> FILE

A CSV file with a header line that contains the columns C<pv>, C<group> and C<scan>. Required.

=item B<--output-dir> DIR

The directory for the request file and the C<responses> directory; created when missing. Required.

=item B<--url> URL

The getData.json address. Default C<http://localhost:17668/retrieval/data/getData.json>.

=item B<--client> N

The client number, a non-negative integer (default 0); it seeds the random choice and names the files.

=item B<--pause> SECONDS

Wait after each completed request (default 2); 0 sends the next request at once.

=item B<--timeout> SECONDS

Time limit of one request (default 120).

=item B<--count> N

Stop after N requests (positive integer).

=item B<--duration> SECONDS

Stop before the first request that would start at or after this many seconds (greater than zero).

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when the run ended by count, duration or signal (a failed request is a row with its status, not a failure of the
client), 1 when a file could not be written, 77 when the CSV file is missing or has no usable PV, 2 for invalid usage.

=cut

my $DEFAULT_URL = 'http://localhost:17668/retrieval/data/getData.json';
my $DEFAULT_PAUSE_SECONDS = 2;
my $DEFAULT_TIMEOUT_SECONDS = 120;
my $SLICE_SECONDS = 0.1;
my %WINDOW_SECONDS = ('1h' => 3600, '1d' => 86400);
my $DAY_SCAN = '1 second';
my $WAVEFORM_MARK = 'WF';
my $SAMPLE_KEY = '"secs"';
my $HEADER = 'time_utc,monotonic_s,client,pv,window,http,ms,bytes,samples,sha256,file,error';
my $NUMBER = qr/\d+(?:\.\d+)?/;
my $STOP = 0;

# An invalid or missing input is an expected outcome with its own exit status.
sub incomplete {
    my ($message) = @_;
    die { incomplete => $message };
}

# A failure to store the observation ends the client with its own exit status.
sub storage_failure {
    my ($message) = @_;
    die { failure => $message };
}

# Reads the PV rows of the CSV file as hashes of the three needed columns.
sub read_pv_rows {
    my ($path) = @_;
    open(my $handle, '<', $path) or incomplete("Cannot read PV CSV $path: $!");
    my $header = <$handle>;
    defined $header or incomplete("PV CSV $path is empty");
    $header =~ s/\r?\n\z//;
    my @names = split /,/, $header, -1;
    my %column;
    @column{@names} = (0 .. $#names);
    for my $name (qw(pv group scan)) {
        exists $column{$name} or incomplete("PV CSV $path has no $name column");
    }
    my @rows;
    while (my $line = <$handle>) {
        $line =~ s/\r?\n\z//;
        next if $line eq '';
        my @values = split /,/, $line, -1;
        @values == @names or incomplete("PV CSV $path line $.: expected " . scalar(@names) . ' columns');
        my %row = map { $_ => $values[ $column{$_} ] } qw(pv group scan);
        $row{pv} =~ /\A[\x21-\x7e]+\z/ or incomplete("PV CSV $path line $.: invalid PV name");
        push @rows, \%row;
    }
    close($handle);
    @rows or incomplete("PV CSV $path has no PV");
    return @rows;
}

sub escape {
    my ($text) = @_;
    $text =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord($1))/ge;
    return $text;
}

sub utc_text {
    my ($seconds, $microseconds) = @_;
    return strftime('%Y-%m-%dT%H:%M:%S', gmtime($seconds)) . sprintf('.%03dZ', int($microseconds / 1000));
}

# Picks the next PV and window from the seeded generator.
sub choose {
    my ($rows) = @_;
    my $row = $rows->[ int(rand(scalar @{$rows})) ];
    my $day_ok = $row->{scan} eq $DAY_SCAN && index($row->{pv}, $WAVEFORM_MARK) < 0;
    my $window = $day_ok && rand() < 0.5 ? '1d' : '1h';
    return ($row->{pv}, $window);
}

# Sends one request, streams the response to the file and returns the figures of the row.
sub fetch {
    my ($options, $pv, $window, $path) = @_;
    my ($seconds, $microseconds) = gettimeofday();
    my $start = clock_gettime(CLOCK_MONOTONIC);
    my $from = utc_text($seconds - $WINDOW_SECONDS{$window}, $microseconds);
    my $url = "$options->{url}?pv=" . escape($pv) . '&from=' . escape($from) . '&to=' . escape(utc_text($seconds, $microseconds));
    open(my $file, '>', $path) or storage_failure("open $path: $!");
    binmode($file);
    my $digest = Digest::SHA->new(256);
    my ($size, $samples, $tail, $write_error) = (0, 0, '', undef);
    my $callback = sub {
        my ($chunk) = @_;
        $write_error //= "write $path: $!" unless print {$file} $chunk;
        $digest->add($chunk);
        $size += length $chunk;
        # The carried tail is one character shorter than the key, so a key cut by a chunk boundary is counted once.
        my $data = $tail . $chunk;
        $samples += () = $data =~ /\Q$SAMPLE_KEY\E/g;
        $tail = substr($data, -(length($SAMPLE_KEY) - 1));
        return;
    };
    my $response = HTTP::Tiny->new(timeout => $options->{timeout}, agent => 'query-archive.pl')->get($url, { data_callback => $callback });
    # HTTP::Tiny streams only a successful body to the callback; the body of any other status is kept the same way.
    $callback->($response->{content}) if $response->{status} != 599 && !$response->{success} && length($response->{content} // '');
    my $milliseconds = int((clock_gettime(CLOCK_MONOTONIC) - $start) * 1000 + 0.5);
    close($file) or $write_error //= "close $path: $!";
    defined $write_error and storage_failure($write_error);
    my ($code, $error) = ($response->{status}, '');
    if ($code == 599) {
        $error = "$response->{content}";
        $error =~ s/[,"\r\n]+/ /g;
        $code = 0;
    }
    return {
        time_utc => utc_text($seconds, $microseconds), monotonic_s => sprintf('%.3f', $start), window => $window, http => $code,
        ms => $milliseconds, bytes => $size, samples => $samples, sha256 => $digest->hexdigest, error => $error,
    };
}

# Waits for the pause in short slices so a stop request ends it at once.
sub pause {
    my ($seconds) = @_;
    my $until = clock_gettime(CLOCK_MONOTONIC) + $seconds;
    while (!$STOP) {
        my $left = $until - clock_gettime(CLOCK_MONOTONIC);
        last if $left <= 0;
        Time::HiRes::sleep($left < $SLICE_SECONDS ? $left : $SLICE_SECONDS);
    }
    return;
}

sub run_client {
    my ($options, $rows) = @_;
    my $directory = $options->{output_dir};
    my $client = $options->{client};
    my $requests = "$directory/requests-$client.csv";
    -e $requests and die { usage => "$requests already exists" };
    make_path("$directory/responses", { error => \my $errors });
    @{$errors} and storage_failure("mkdir $directory/responses: " . join('; ', map { values %{$_} } @{$errors}));
    open(my $log, '>>', $requests) or storage_failure("open $requests: $!");
    $log->autoflush(1);
    print {$log} "$HEADER\n" or storage_failure("write $requests: $!");
    local $SIG{TERM} = sub { $STOP = 1 };
    local $SIG{INT} = sub { $STOP = 1 };
    srand($client);
    my $start = clock_gettime(CLOCK_MONOTONIC);
    my $sent = 0;
    while (!$STOP) {
        last if defined $options->{duration} && clock_gettime(CLOCK_MONOTONIC) - $start >= $options->{duration};
        $sent++;
        my ($pv, $window) = choose($rows);
        my $name = sprintf('responses/c%d-%06d.json', $client, $sent);
        my $row = fetch($options, $pv, $window, "$directory/$name");
        $row->{pv} = $pv;
        $row->{client} = $client;
        $row->{file} = $name;
        print {$log} join(',', @{$row}{qw(time_utc monotonic_s client pv window http ms bytes samples sha256 file error)}) . "\n"
            or storage_failure("write $requests: $!");
        last if defined $options->{count} && $sent >= $options->{count};
        pause($options->{pause});
    }
    close($log) or storage_failure("close $requests: $!");
    return;
}

sub usage_status {
    my ($message) = @_;
    print STDERR "query-archive.pl: $message\n";
    pod2usage(-input => __FILE__, -verbose => 0, -exitval => 'NOEXIT', -output => \*STDERR);
    return 2;
}

sub main {
    my @arguments = @_;
    my ($help, %options);
    @options{qw(url pause timeout client)} = ($DEFAULT_URL, $DEFAULT_PAUSE_SECONDS, $DEFAULT_TIMEOUT_SECONDS, 0);
    GetOptionsFromArray(
        \@arguments,
        'help' => \$help,
        'pv-csv=s' => \$options{pv_csv},
        'output-dir=s' => \$options{output_dir},
        'url=s' => \$options{url},
        'client=s' => \$options{client},
        'pause=s' => \$options{pause},
        'timeout=s' => \$options{timeout},
        'count=s' => \$options{count},
        'duration=s' => \$options{duration},
    ) or return usage_status('invalid option');
    if ($help) {
        pod2usage(-input => __FILE__, -verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        return 0;
    }
    @arguments and return usage_status('unexpected argument');
    for my $name (qw(pv_csv output_dir)) {
        defined $options{$name} && length $options{$name} or return usage_status('--' . ($name =~ s/_/-/r) . ' is required');
    }
    $options{url} =~ m{\Ahttp://[^\s?#]+\z} or return usage_status('--url must be an http:// address without a query');
    $options{client} =~ /\A\d+\z/ or return usage_status('--client must be a non-negative integer');
    $options{pause} =~ /\A$NUMBER\z/ or return usage_status('--pause must be a number of seconds, zero or more');
    for my $name (qw(timeout duration)) {
        next unless defined $options{$name};
        $options{$name} =~ /\A$NUMBER\z/ && $options{$name} > 0 or return usage_status("--$name must be a number greater than zero");
    }
    defined $options{count} && $options{count} !~ /\A[1-9]\d*\z/ and return usage_status('--count must be a positive integer');

    my $failed = eval {
        my @rows = read_pv_rows($options{pv_csv});
        run_client(\%options, \@rows);
        1;
    };
    return 0 if $failed;
    my $error = $@;
    ref $error eq 'HASH' or die $error;
    return usage_status($error->{usage}) if exists $error->{usage};
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
    print STDERR "query-archive.pl: $error";
    $status = 2;
};
exit $status;
