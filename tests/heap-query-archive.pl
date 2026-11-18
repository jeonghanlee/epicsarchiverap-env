#!/usr/bin/env perl
# Checks the shipped retrieval query client through its command line against a real HTTP server serving real files.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use IO::Socket::INET;
use Pod::Usage qw(pod2usage);
use POSIX ();
use Test::More;
use Time::HiRes qw(sleep);

BEGIN {
    require(dirname(abs_path($0)) . '/lib/ArchiverTest.pm');
    ArchiverTest->import(qw(slurp spew usage_error));
}

=head1 NAME

heap-query-archive.pl - check the exit statuses, files and rows of tests/heap/query-archive.pl

=head1 SYNOPSIS

  perl tests/heap-query-archive.pl
  perl tests/heap-query-archive.pl --help

=head1 DESCRIPTION

Runs the real query client as a subprocess against C<python3 -m http.server> serving a real getData.json file of 100000
samples from a temporary directory, so only the HTTP server is a stand-in for the retrieval service. Usage errors and
unusable PV files need no server. Every expected figure comes from another tool: the sizes from wc, the sample count from
grep, the SHA256 from sha256sum, the key count from grep, the URL encoding from python3, the window lengths from date and the requests as the
server logged them. The cases cover the exact header and rows, the stored responses, the window rule (one day only for a
1 second scalar), a repeatable choice per client number, the pause, a status 404 and a refused connection recorded as
rows, a run ended by duration, a run ended by SIGTERM between requests and one in the middle of a slow request, and the
refusal of an existing request file.

The temporary directory uses TMPDIR when writable, otherwise work/scratch/tmp of the checkout; it is removed after the
run. Required: Perl 5.26 or newer, Test::More, Time::HiRes, python3, sh, awk, grep, wc, sha256sum and date.

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
my $TOOL = "$REPOSITORY/tests/heap/query-archive.pl";
my $HEADER = 'time_utc,monotonic_s,client,pv,window,http,ms,bytes,samples,sha256,file,error';
my $SAMPLES = 100000;
my $DENSE_KEYS = 500000;
my $FIRST_PORT = 18000;
my $EMPTY_SHA256 = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
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

sub sha256_of {
    my ($path) = @_;
    return text_tool('sha256sum < "$1" | awk \'{print $1}\'', $path);
}

# Reads a request file and returns its header line and the rows as hashes.
sub read_rows {
    my ($path) = @_;
    my @lines = split /\n/, slurp($path);
    my $header = shift @lines;
    my @rows;
    for my $line (@lines) {
        my %row;
        @row{qw(time_utc monotonic_s client pv window http ms bytes samples sha256 file error)} = split /,/, $line, -1;
        push @rows, \%row;
    }
    return ($header, \@rows);
}

# Returns the quoted form of a text as python3 writes it with no safe characters.
sub quoted {
    my ($text) = @_;
    return text_tool('python3 -c \'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))\' "$1"', $text);
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

sub start_server {
    my ($root, $log, $port) = @_;
    my $pid = spawn($root, $log, 'python3', '-m', 'http.server', $port, '--bind', '127.0.0.1');
    for (1 .. 50) {
        my $socket = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp');
        return $pid if $socket;
        kill(0, $pid) or die "http.server ended early: " . slurp($log) . "\n";
        sleep(0.1);
    }
    die "http.server did not listen on $port\n";
}

sub run_usage_cases {
    my ($workspace) = @_;
    my $csv = "$workspace/usage.csv";
    spew($csv, "pv,group,scan\nA:1,g,1 second\n");
    my @base = ('--pv-csv', $csv, '--output-dir', "$workspace/usage-out");
    my @cases = (
        ['no option', [], qr/--pv-csv is required/],
        ['no output directory', ['--pv-csv', $csv], qr/--output-dir is required/],
        ['unknown option', ['--bogus'], qr/Unknown option/],
        ['https address', [@base, '--url', 'https://localhost/getData.json'], qr/--url must be an http:\/\/ address/],
        ['address with a query', [@base, '--url', 'http://localhost/getData.json?pv=x'], qr/--url must be an http:\/\/ address/],
        ['negative client', [@base, '--client=-1'], qr/--client must be a non-negative integer/],
        ['fractional client', [@base, '--client', '1.5'], qr/--client must be a non-negative integer/],
        ['negative pause', [@base, '--pause=-1'], qr/--pause must be a number/],
        ['zero timeout', [@base, '--timeout', '0'], qr/--timeout must be a number greater than zero/],
        ['zero duration', [@base, '--duration', '0'], qr/--duration must be a number greater than zero/],
        ['zero count', [@base, '--count', '0'], qr/--count must be a positive integer/],
        ['fractional count', [@base, '--count', '1.5'], qr/--count must be a positive integer/],
        ['stray argument', [@base, 'extra'], qr/unexpected argument/],
    );
    my ($status, $stdout) = run_tool('--help');
    is($status, 0, 'help: exit status');
    like($stdout, qr/--pv-csv/, 'help: names the PV file option');
    for my $case (@cases) {
        my ($name, $arguments, $pattern) = @{$case};
        my ($code, undef, $stderr) = run_tool(@{$arguments});
        is($code, 2, "usage $name: exit status");
        like($stderr, $pattern, "usage $name: diagnostic");
    }
    ok(!-e "$workspace/usage-out", 'usage cases: no output directory was created');
    return;
}

sub run_missing_input_cases {
    my ($workspace) = @_;
    my %files = (
        'no-such.csv' => undef,
        'empty.csv' => '',
        'no-scan.csv' => "pv,group\nA:1,g\n",
        'no-rows.csv' => "pv,group,scan\n",
        'short-row.csv' => "pv,group,scan\nA:1,g\n",
        'bad-name.csv' => "pv,group,scan\nA 1,g,1 second\n",
    );
    my @cases = (
        ['file missing', 'no-such.csv', qr/Cannot read PV CSV/],
        ['file empty', 'empty.csv', qr/is empty/],
        ['no scan column', 'no-scan.csv', qr/has no scan column/],
        ['no rows', 'no-rows.csv', qr/has no PV/],
        ['short row', 'short-row.csv', qr/line 1: expected 3 columns|line 2: expected 3 columns/],
        ['PV name with a space', 'bad-name.csv', qr/invalid PV name/],
    );
    spew("$workspace/$_", $files{$_}) for grep { defined $files{$_} } sort keys %files;
    my $index = 0;
    for my $case (@cases) {
        my ($name, $file, $pattern) = @{$case};
        my $directory = "$workspace/missing-" . $index++;
        my ($code, undef, $stderr) = run_tool('--pv-csv', "$workspace/$file", '--output-dir', $directory, '--count', 1);
        is($code, 77, "missing input $name: exit status");
        like($stderr, $pattern, "missing input $name: diagnostic");
        ok(!glob("$directory/requests-*.csv"), "missing input $name: no request file was written");
    }
    my $blocker = "$workspace/blocker";
    spew($blocker, "a file, not a directory\n");
    spew("$workspace/one.csv", "pv,group,scan\nA:1,g,1 second\n");
    my ($code, undef, $stderr) = run_tool('--pv-csv', "$workspace/one.csv", '--output-dir', "$blocker/sub", '--count', 1);
    is($code, 1, 'output directory below a file: exit status');
    like($stderr, qr/FAILURE: mkdir/, 'output directory below a file: diagnostic');
    return;
}

# Checks the rows of one run against the response files, the served file and the requests the server logged.
sub check_rows {
    my ($label, $directory, $rows, $served, $log_lines, $first_log_index) = @_;
    my ($served_sha, $served_bytes) = (sha256_of($served), text_tool('wc -c < "$1"', $served));
    my $served_samples = text_tool('grep -o \'"secs"\' "$1" | wc -l', $served);
    my $bad = 0;
    for my $i (0 .. $#{$rows}) {
        my $row = $rows->[$i];
        my $file = "$directory/$row->{file}";
        $bad++ unless -f $file && sha256_of($file) eq $row->{sha256} && $row->{sha256} eq $served_sha;
        $bad++ unless text_tool('wc -c < "$1"', $file) == $row->{bytes} && $row->{bytes} == $served_bytes;
        $bad++ unless $row->{samples} == $served_samples && $row->{http} == 200 && $row->{error} eq '';
        $bad++ unless $row->{file} eq sprintf('responses/c%d-%06d.json', $row->{client}, $i + 1);
    }
    is($bad, 0, "$label: every row matches its stored response, the served file and wc, grep and sha256sum");

    my @logged = @{$log_lines}[$first_log_index .. $first_log_index + $#{$rows}];
    is(scalar(@logged), scalar(@{$rows}), "$label: the server logged one request per row");
    my $mismatch = 0;
    for my $i (0 .. $#{$rows}) {
        my $row = $rows->[$i];
        $logged[$i] =~ m{GET /retrieval/data/getData\.json\?pv=([^&]+)&from=([^&]+)&to=([^& ]+) HTTP/1\.[01]" 200} or do { $mismatch++; next };
        my ($pv, $from, $to) = ($1, $2, $3);
        my $seconds = $row->{window} eq '1d' ? 86400 : 3600;
        $mismatch++ unless $pv eq quoted($row->{pv}) && $to eq quoted($row->{time_utc});
        my $span = text_tool('echo $(( $(date -u -d "$2" +%s) - $(date -u -d "$1" +%s) ))', _unquote($from), _unquote($to));
        $mismatch++ unless $span == $seconds && _unquote($from) =~ /\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z\z/;
        $mismatch++ unless text_tool('date -u -d "$1" +%s.%3N', _unquote($to)) eq text_tool('date -u -d "$1" +%s.%3N', $row->{time_utc});
    }
    is($mismatch, 0, "$label: logged URL carries the PV, the window of its row and a window ending at the request start");
    return;
}

sub _unquote {
    my ($text) = @_;
    $text =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return $text;
}

sub log_lines {
    my ($log) = @_;
    return grep { /"GET / } split /\n/, slurp($log);
}

sub run_server_cases {
    my ($workspace) = @_;
    my $root = "$workspace/root";
    make_path("$root/retrieval/data");
    my $served = "$root/retrieval/data/getData.json";
    text_tool('awk -v n="$1" \'BEGIN { printf "["; for (i = 1; i <= n; i++) printf "%s{\"secs\":%d,\"val\":%d}", (i > 1 ? "," : ""), i, i; printf "]" }\' > "$2"', $SAMPLES, $served);
    is(text_tool('grep -o \'"secs"\' "$1" | wc -l', $served), $SAMPLES, 'served file: sample count is the generated one');

    my $csv = "$workspace/pvs.csv";
    spew($csv, "pv,group,scan,method,period,policy,store_key\nA:1,g,1 second,m,1,p,k\nB:WF,g,1 second,m,1,p,k\nC:2,g,.1 second,m,1,p,k\nD:3,g,1 second,m,1,p,k\n");
    my $port = free_port($FIRST_PORT);
    my $log = "$workspace/server.log";
    my $server = start_server($root, $log, $port);
    my $url = "http://127.0.0.1:$port/retrieval/data/getData.json";

    # Run 1: forty requests of client 3 without a pause.
    my $one = "$workspace/run1";
    my ($code, undef, $stderr) = run_tool('--pv-csv', $csv, '--output-dir', $one, '--url', $url, '--client', 3, '--pause', 0, '--count', 40);
    is($code, 0, 'count run: exit status');
    is($stderr, '', 'count run: nothing on stderr');
    my ($header, $rows) = read_rows("$one/requests-3.csv");
    is($header, $HEADER, 'count run: header');
    is(scalar(@{$rows}), 40, 'count run: one row per request');
    my @lines = log_lines($log);
    check_rows('count run', $one, $rows, $served, \@lines, 0);
    my %seen;
    $seen{$_->{pv}}++ for @{$rows};
    is_deeply([ sort keys %seen ], ['A:1', 'B:WF', 'C:2', 'D:3'], 'count run: every listed PV was chosen');
    is_deeply([ grep { $_->{window} eq '1d' && $_->{pv} !~ /\A[AD]:/ } @{$rows} ], [], 'count run: only a 1 second scalar gets a one-day window');
    is_deeply([ sort keys %{{ map { $_->{window} => 1 } grep { $_->{pv} =~ /\A[AD]:/ } @{$rows} }} ], ['1d', '1h'], 'count run: a 1 second scalar gets both windows');
    is_deeply([ grep { $_->{window} ne '1h' } grep { $_->{pv} =~ /\A[BC]:/ } @{$rows} ], [], 'count run: waveform and fast PVs stay at one hour');

    # The same client number repeats the choice; another number differs.
    my $again = "$workspace/run1-again";
    run_tool('--pv-csv', $csv, '--output-dir', $again, '--url', $url, '--client', 3, '--pause', 0, '--count', 40);
    my (undef, $again_rows) = read_rows("$again/requests-3.csv");
    is_deeply([ map { "$_->{pv} $_->{window}" } @{$again_rows} ], [ map { "$_->{pv} $_->{window}" } @{$rows} ], 'repeat run: same client gives the same PVs and windows');
    my $other = "$workspace/run1-other";
    run_tool('--pv-csv', $csv, '--output-dir', $other, '--url', $url, '--client', 4, '--pause', 0, '--count', 40);
    my (undef, $other_rows) = read_rows("$other/requests-4.csv");
    isnt(join(',', map { "$_->{pv} $_->{window}" } @{$other_rows}), join(',', map { "$_->{pv} $_->{window}" } @{$rows}), 'other client: a different sequence');

    # The pause: three requests, one second apart.
    my $paused = "$workspace/run-pause";
    my ($pause_code) = run_tool('--pv-csv', $csv, '--output-dir', $paused, '--url', $url, '--pause', 1, '--count', 3);
    is($pause_code, 0, 'pause run: exit status');
    my (undef, $paused_rows) = read_rows("$paused/requests-0.csv");
    is(scalar(@{$paused_rows}), 3, 'pause run: three rows');
    my @gaps = map { $paused_rows->[$_]{monotonic_s} - $paused_rows->[$_ - 1]{monotonic_s} } 1 .. 2;
    is(scalar(grep { $_ >= 1.0 && $_ < 1.5 } @gaps), 2, 'pause run: starts are one pause apart on the monotonic clock');

    # An existing request file is refused and stays as it was.
    my $hash = sha256_of("$one/requests-3.csv");
    my ($refused, undef, $refused_error) = run_tool('--pv-csv', $csv, '--output-dir', $one, '--url', $url, '--client', 3, '--count', 1);
    is($refused, 2, 'existing request file: exit status');
    like($refused_error, qr/requests-3\.csv already exists/, 'existing request file: diagnostic');
    is(sha256_of("$one/requests-3.csv"), $hash, 'existing request file: file unchanged');

    # A response made only of keys is cut inside a key by most chunk boundaries; the count must still be exact.
    my $dense = "$root/retrieval/data/dense.json";
    text_tool('awk -v n="$1" \'BEGIN { for (i = 1; i <= n; i++) printf "\"secs\""; }\' > "$2"', $DENSE_KEYS, $dense);
    is(text_tool('grep -o \'"secs"\' "$1" | wc -l', $dense), $DENSE_KEYS, 'dense file: key count is the generated one');
    my $dense_dir = "$workspace/run-dense";
    my ($dense_code) = run_tool('--pv-csv', $csv, '--output-dir', $dense_dir, '--url', "http://127.0.0.1:$port/retrieval/data/dense.json", '--pause', 0, '--count', 1);
    is($dense_code, 0, 'dense run: exit status');
    my (undef, $dense_rows) = read_rows("$dense_dir/requests-0.csv");
    is($dense_rows->[0]{samples}, $DENSE_KEYS, 'dense run: keys cut by chunk boundaries are counted once');
    is($dense_rows->[0]{sha256}, sha256_of($dense), 'dense run: hash of the full response');

    # A response file that cannot take the data is a failure of the client, not a row.
    my $full_dir = "$workspace/run-full";
    make_path("$full_dir/responses");
    symlink('/dev/full', "$full_dir/responses/c0-000001.json") or die "symlink: $!\n";
    my ($full_code, undef, $full_error) = run_tool('--pv-csv', $csv, '--output-dir', $full_dir, '--url', $url, '--pause', 0, '--count', 1);
    is($full_code, 1, 'full device: exit status');
    like($full_error, qr/FAILURE: (?:write|close) .*c0-000001\.json/, 'full device: diagnostic');

    # A status other than 200 is a row, not a failure of the client.
    my $missing = "$workspace/run-404";
    my ($missing_code) = run_tool('--pv-csv', $csv, '--output-dir', $missing, '--url', "http://127.0.0.1:$port/no/such/getData.json", '--pause', 0, '--count', 2);
    is($missing_code, 0, '404 run: exit status');
    my (undef, $missing_rows) = read_rows("$missing/requests-0.csv");
    is_deeply([ map { $_->{http} } @{$missing_rows} ], [404, 404], '404 run: both rows carry the status');
    my $page = "$missing/$missing_rows->[0]{file}";
    is($missing_rows->[0]{sha256}, sha256_of($page), '404 run: the error page is stored with its hash');
    is($missing_rows->[0]{bytes}, text_tool('wc -c < "$1"', $page), '404 run: size of the error page');
    cmp_ok($missing_rows->[0]{bytes}, '>', 0, '404 run: the error page is not empty');

    # A refused connection is a row with status 0 and an empty response.
    my $dead_port = free_port($port + 1);
    my $refused_dir = "$workspace/run-refused";
    my ($dead_code) = run_tool('--pv-csv', $csv, '--output-dir', $refused_dir, '--url', "http://127.0.0.1:$dead_port/retrieval/data/getData.json", '--pause', 0, '--count', 1);
    is($dead_code, 0, 'refused run: exit status');
    my (undef, $dead_rows) = read_rows("$refused_dir/requests-0.csv");
    is($dead_rows->[0]{http}, 0, 'refused run: status 0');
    is($dead_rows->[0]{bytes}, 0, 'refused run: no bytes');
    is($dead_rows->[0]{sha256}, $EMPTY_SHA256, 'refused run: hash of the empty response');
    like($dead_rows->[0]{error}, qr/\S/, 'refused run: the reason is recorded');
    is(text_tool('wc -c < "$1"', "$refused_dir/$dead_rows->[0]{file}"), 0, 'refused run: empty response file');

    # A duration ends the run before the next request.
    my $timed = "$workspace/run-duration";
    my $begin = time;
    my ($timed_code) = run_tool('--pv-csv', $csv, '--output-dir', $timed, '--url', $url, '--pause', 0.5, '--duration', 2);
    is($timed_code, 0, 'duration run: exit status');
    my (undef, $timed_rows) = read_rows("$timed/requests-0.csv");
    cmp_ok(scalar(@{$timed_rows}), '>=', 3, 'duration run: at least three requests');
    cmp_ok(scalar(@{$timed_rows}), '<=', 5, 'duration run: at most five requests');
    cmp_ok(time - $begin, '<', 6, 'duration run: ended in time');

    # SIGTERM between requests: whole rows only, clean exit.
    my $signalled = "$workspace/run-signal";
    my $client = spawn($workspace, "$workspace/client.log", $^X, $TOOL, '--pv-csv', $csv, '--output-dir', $signalled, '--url', $url, '--pause', 1);
    for (1 .. 50) {
        last if -s "$signalled/requests-0.csv" && slurp("$signalled/requests-0.csv") =~ /\n.*\n/;
        sleep(0.1);
    }
    kill('TERM', $client);
    is(reap($client), 0, 'signal run: exits 0 (not killed by the signal)');
    my (undef, $signalled_rows) = read_rows("$signalled/requests-0.csv");
    cmp_ok(scalar(@{$signalled_rows}), '>=', 1, 'signal run: at least one row');
    is(scalar(grep { scalar(split /,/, $_, -1) != 12 } split /\n/, slurp("$signalled/requests-0.csv")), 0, 'signal run: every line is a whole row');
    is(scalar(grep { $_->{http} != 200 } @{$signalled_rows}), 0, 'signal run: every request completed');

    kill('TERM', $server);
    reap($server);
    return;
}

# A signal in the middle of a slow request lets it finish: one whole row, the full response, a clean exit.
sub run_slow_case {
    my ($workspace) = @_;
    my $root = "$workspace/root";
    my $served = "$root/retrieval/data/getData.json";
    my $script = "$workspace/slow-server.py";
    my $marker = "$workspace/request-started";
    spew($script, <<'PYTHON');
import http.server, sys, time

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        open(sys.argv[2], "w").close()
        time.sleep(2)
        super().do_GET()

http.server.ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
PYTHON
    my $port = free_port($FIRST_PORT + 300);
    my $server = spawn($root, "$workspace/slow.log", 'python3', $script, $port, $marker);
    for (1 .. 50) {
        last if IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp');
        sleep(0.1);
    }
    my $csv = "$workspace/pvs.csv";
    my $directory = "$workspace/run-slow";
    my $client = spawn($workspace, "$workspace/slow-client.log", $^X, $TOOL, '--pv-csv', $csv, '--output-dir', $directory, '--url', "http://127.0.0.1:$port/retrieval/data/getData.json", '--pause', 1);
    for (1 .. 100) {
        last if -e $marker;
        sleep(0.1);
    }
    ok(-e $marker, 'slow run: the request reached the server');
    kill('TERM', $client);
    is(reap($client), 0, 'slow run: exits 0 after the request in progress');
    my (undef, $rows) = read_rows("$directory/requests-0.csv");
    is(scalar(@{$rows}), 1, 'slow run: exactly one row');
    is($rows->[0]{http}, 200, 'slow run: the request in progress completed');
    is($rows->[0]{sha256}, sha256_of($served), 'slow run: full response stored');
    is($rows->[0]{bytes}, text_tool('wc -c < "$1"', $served), 'slow run: full size');
    cmp_ok($rows->[0]{ms}, '>=', 1500, 'slow run: the request took the server delay');
    kill('TERM', $server);
    reap($server);
    return;
}

sub main {
    my @arguments = @_;
    my $help;
    GetOptionsFromArray(\@arguments, 'help' => \$help) or return usage_error('heap-query-archive.pl', __FILE__, 'invalid option');
    if ($help) {
        pod2usage(-input => __FILE__, -exitval => 'NOEXIT', -verbose => 1, -output => \*STDOUT);
        return 0;
    }
    @arguments and return usage_error('heap-query-archive.pl', __FILE__, 'unexpected argument');
    -f $TOOL or die "missing query client: $TOOL\n";

    my $temporary_root = defined $ENV{TMPDIR} && -d $ENV{TMPDIR} && -w _ ? $ENV{TMPDIR} : "$REPOSITORY/work/scratch/tmp";
    make_path($temporary_root);
    my $workspace = tempdir('heap-query-XXXXXX', DIR => $temporary_root, CLEANUP => 1);

    run_usage_cases($workspace);
    run_missing_input_cases($workspace);
    run_server_cases($workspace);
    run_slow_case($workspace);

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
    print STDERR "heap-query-archive.pl: $error";
    $status = 2;
};
exit($status == 0 && !Test::More->builder->is_passing ? 1 : $status);
