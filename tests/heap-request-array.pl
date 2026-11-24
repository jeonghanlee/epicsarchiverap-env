#!/usr/bin/env perl
# Checks the array request client through its command line against a real HTTP server, real files and a silent server.
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
use Time::HiRes qw(sleep);

=head1 NAME

heap-request-array.pl - check tests/heap/request-array.pl

=head1 SYNOPSIS

  perl tests/heap-request-array.pl [--tool FILE]
  perl tests/heap-request-array.pl --help

=head1 DESCRIPTION

Runs the real client as a subprocess. The usage cases and the plan cases need no server. The request cases send the requests of
plans to C<python3 -m http.server>, which serves a real file of 48 MiB of random bytes under a name that the client takes for the
retrieval address (only the HTTP server stands in for the retrieval service), and compare the status, the number of bytes and the
SHA-256 of each response with C<wc> and C<sha256sum>. Four clients and two groups check that the requests of the clients overlap in time
(from the monotonic clock of the rows) and that a group starts after the previous one has ended. A missing file is recorded as status 404
with the text of the server, and a server that accepts the connection and never answers is recorded as status 0 with its reason
after the time limit. A second run into the same directory is refused, and the plan hash of C<run.json> is compared with C<sha256sum>.

The temporary directory is removed after the run. Required: Perl 5.26 or newer, Test::More, JSON::PP, python3 (the http.server module),
sha256sum, wc and Linux.

=head1 OPTIONS

=over 4

=item B<--tool> FILE

The client to check (default C<tests/heap/request-array.pl> of this checkout).

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when every check passes, 1 when an assertion fails, 2 for invalid usage or an environment error.

=cut

my $TESTS = dirname(abs_path($0));
my $REPOSITORY = dirname($TESTS);
my $TOOL = "$REPOSITORY/tests/heap/request-array.pl";
my $SERVED_BYTES = 48 * 1024 * 1024;
my $SERVER_WAIT_TRIES = 50;
my $TIMEOUT_SECONDS = 2;
my $TIMEOUT_MIN_MS = 1500;
my $TIMEOUT_MAX_MS = 4500;
my $HEADER = 'group,client,sequence,name,pv,from,to,time_utc,monotonic_s,end_utc,ms,http,bytes,sha256,error';
my $PLAN = "name,pv,from,to\nframe-1,TEST:ARRAY,2026-11-24T06:55:05.000Z,2026-11-24T06:55:05.001Z\n"
    . "frame-3,TEST:ARRAY,2026-11-24T06:55:00.000Z,2026-11-24T06:56:00.000Z\n";
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

sub write_bytes {
    my ($path, $bytes) = @_;
    make_path(dirname($path));
    open(my $handle, '>:raw', $path) or die "open $path: $!\n";
    print {$handle} $bytes or die "write $path: $!\n";
    close($handle) or die "close $path: $!\n";
    return;
}

sub text_tool {
    my ($script, @arguments) = @_;
    my ($status, $stdout, $stderr) = run_command('sh', '-c', $script, 'sh', @arguments);
    $status == 0 or die "text tool failed with $status: $stderr\n";
    $stdout =~ s/\A\s+|\s+\z//g;
    return $stdout;
}

sub spawn {
    my (@command) = @_;
    my $pid = fork();
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

sub free_port {
    my $socket = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp') or die "port: $!\n";
    my $port = $socket->sockport;
    close($socket);
    return $port;
}

# Reads a result file into an array of hashes keyed by the header columns.
sub read_rows {
    my ($path) = @_;
    open(my $handle, '<', $path) or return ();
    my $header = <$handle>;
    chomp $header;
    my @names = split /,/, $header;
    my @rows;
    while (my $line = <$handle>) {
        chomp $line;
        my @fields = $line =~ /\G(?:"((?:[^"]|"")*)"|([^,]*))(?:,|$)/g;
        my @values;
        while (@fields) { my ($quoted, $plain) = splice(@fields, 0, 2); push @values, defined $quoted ? $quoted =~ s/""/"/gr : $plain }
        pop @values while @values > @names;
        my %row;
        @row{@names} = @values;
        push @rows, \%row;
    }
    close($handle);
    return @rows;
}

sub main {
    my (@arguments) = @_;
    my $help;
    GetOptionsFromArray(\@arguments, 'help' => \$help, 'tool=s' => \$TOOL) or pod2usage(-exitval => 2, -verbose => 0);
    if ($help) {
        pod2usage(-exitval => 'NOEXIT', -verbose => 99, -sections => [qw(NAME SYNOPSIS DESCRIPTION OPTIONS)], -output => \*STDOUT);
        return 0;
    }
    -f $TOOL or die "$TOOL: no such file\n";
    for my $program (qw(python3 sha256sum wc)) {
        my ($status) = run_command('sh', '-c', "command -v $program");
        $status == 0 or die "$program is required\n";
    }
    my $base = $ENV{TMPDIR} && -w $ENV{TMPDIR} ? $ENV{TMPDIR} : "$REPOSITORY/work/scratch/tmp";
    make_path($base);
    my $dir = tempdir('heap-request-array.XXXXXX', DIR => $base, CLEANUP => 1);
    plan tests => 21;

    write_bytes("$dir/plan.csv", $PLAN);
    my ($status, $stdout, $stderr) = run_tool('--help');
    is($status, 0, 'help: exit status');
    ($status, $stdout, $stderr) = run_tool('--output-dir', "$dir/o");
    ok(($status == 2 && $stderr =~ /--plan is required/) ? 1 : 0, 'no --plan: usage error naming the option');
    ($status, $stdout, $stderr) = run_tool('--plan', "$dir/plan.csv");
    is($status, 2, 'no --output-dir: exit status');
    ($status, $stdout, $stderr) = run_tool('--plan', "$dir/plan.csv", '--output-dir', "$dir/o", '--clients', '0');
    is($status, 2, '0 clients: exit status');
    ($status, $stdout, $stderr) = run_tool('--plan', "$dir/plan.csv", '--output-dir', "$dir/o", '--clients', '5');
    is($status, 2, '5 clients: exit status');
    ($status, $stdout, $stderr) = run_tool('--plan', "$dir/plan.csv", '--output-dir', "$dir/o", '--groups', '0');
    is($status, 2, '0 groups: exit status');
    ($status, $stdout, $stderr) = run_tool('--plan', "$dir/missing.csv", '--output-dir', "$dir/o");
    is($status, 77, 'a plan file that does not exist: input error status');
    write_bytes("$dir/nocolumn.csv", "name,pv,from\nx,P,2026-11-24T06:55:05.000Z\n");
    ($status, $stdout, $stderr) = run_tool('--plan', "$dir/nocolumn.csv", '--output-dir', "$dir/o");
    is($status, 77, 'a plan without the column to: input error status');
    write_bytes("$dir/badtime.csv", "name,pv,from,to\nx,P,2026-11-24 06:55:05,2026-11-24T06:55:05.001Z\n");
    ($status, $stdout, $stderr) = run_tool('--plan', "$dir/badtime.csv", '--output-dir', "$dir/o");
    is($status, 77, 'a plan with a time of the wrong form: input error status');

    # Real HTTP server serving a real file.
    make_path("$dir/srv");
    text_tool('head -c "$1" /dev/urandom > "$2"', $SERVED_BYTES, "$dir/srv/getData.json");
    my $expected_sha = text_tool('sha256sum < "$1" | cut -d" " -f1', "$dir/srv/getData.json");
    my $expected_size = text_tool('wc -c < "$1"', "$dir/srv/getData.json");
    my $port = free_port();
    spawn('python3', '-m', 'http.server', '--bind', '127.0.0.1', '--directory', "$dir/srv", $port);
    my $up = 0;
    for (1 .. $SERVER_WAIT_TRIES) {
        sleep(0.2);
        if (IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp')) { $up = 1; last }
    }
    $up or die "the HTTP server did not start\n";
    my $url = "http://127.0.0.1:$port/getData.json";
    ($status, $stdout, $stderr) = run_tool('--plan', "$dir/plan.csv", '--output-dir', "$dir/one", '--url', $url, '--timeout', '60');
    is($status, 0, 'one client, one group: exit status');
    my @rows = read_rows("$dir/one/requests.csv");
    open(my $first, '<', "$dir/one/requests.csv") or die "open: $!\n";
    my $header = <$first>;
    close($first);
    chomp $header if defined $header;
    is($header // '', $HEADER, 'the result file has the documented header');
    ok((@rows == 2 && !grep { $_->{http} ne '200' } @rows) ? 1 : 0, 'both requests of the plan are recorded with status 200');
    ok((@rows == 2 && !grep { $_->{bytes} ne $expected_size } @rows) ? 1 : 0, 'the recorded bytes equal the size of the served file');
    ok((@rows == 2 && !grep { $_->{sha256} ne $expected_sha } @rows) ? 1 : 0, 'the recorded SHA-256 equals sha256sum of the served file');
    my $plan_sha = text_tool('sha256sum < "$1" | cut -d" " -f1', "$dir/plan.csv");
    my $record = -f "$dir/one/run.json" ? decode_json(do { local $/; open(my $h, '<', "$dir/one/run.json") or die; <$h> }) : {};
    is($record->{plan_sha256} // '', $plan_sha, 'run.json holds the SHA-256 of the plan');
    ($status, $stdout, $stderr) = run_tool('--plan', "$dir/plan.csv", '--output-dir', "$dir/one", '--url', $url);
    ok(($status == 2 && $stderr =~ /already holds a requests.csv/) ? 1 : 0, 'a directory that holds results is refused');

    # Four clients, two groups.
    ($status, $stdout, $stderr) = run_tool('--plan', "$dir/plan.csv", '--output-dir', "$dir/four", '--url', $url, '--clients', '4', '--groups', '2', '--timeout', '120');
    @rows = read_rows("$dir/four/requests.csv");
    is(scalar(@rows), 16, 'four clients, two groups and two requests give 16 rows');
    my @first_group = grep { $_->{group} == 1 && $_->{sequence} == 1 } @rows;
    my @starts = map { $_->{monotonic_s} } @first_group;
    my @ends = map { $_->{monotonic_s} + $_->{ms} / 1000 } @first_group;
    my ($latest_start) = sort { $b <=> $a } @starts;
    my ($earliest_end) = sort { $a <=> $b } @ends;
    ok((@first_group == 4 && defined $latest_start && $latest_start < $earliest_end) ? 1 : 0, 'the first requests of the four clients overlap in time');
    my @group_one = grep { $_->{group} == 1 } @rows;
    my @group_two = grep { $_->{group} == 2 } @rows;
    my ($group_one_end) = sort { $b <=> $a } map { $_->{monotonic_s} + $_->{ms} / 1000 } @group_one;
    my ($group_two_start) = sort { $a <=> $b } map { $_->{monotonic_s} } @group_two;
    ok((@group_one == 8 && @group_two == 8 && $group_two_start >= $group_one_end) ? 1 : 0, 'group 2 starts after group 1 has ended');

    # A missing file and a silent server.
    ($status, $stdout, $stderr) = run_tool('--plan', "$dir/plan.csv", '--output-dir', "$dir/missing", '--url', "http://127.0.0.1:$port/missing.json");
    @rows = read_rows("$dir/missing/requests.csv");
    ok(($status == 0 && @rows == 2 && !grep { $_->{http} ne '404' || $_->{error} !~ /not found/i } @rows) ? 1 : 0,
        'a missing file is recorded with status 404 and the text of the server, and the run is complete');
    my $silent_port = free_port();
    my $listener = IO::Socket::INET->new(Listen => 5, LocalAddr => '127.0.0.1', LocalPort => $silent_port, Proto => 'tcp', ReuseAddr => 1) or die "listen: $!\n";
    my $silent = fork();
    defined $silent or die "fork: $!\n";
    if (!$silent) {
        while (my $client = $listener->accept) { sleep(60) }
        POSIX::_exit(0);
    }
    push @CHILDREN, $silent;
    close($listener);
    write_bytes("$dir/one-request.csv", "name,pv,from,to\nframe-1,TEST:ARRAY,2026-11-24T06:55:05.000Z,2026-11-24T06:55:05.001Z\n");
    ($status, $stdout, $stderr) = run_tool('--plan', "$dir/one-request.csv", '--output-dir', "$dir/silent", '--url', "http://127.0.0.1:$silent_port/getData.json",
        '--timeout', $TIMEOUT_SECONDS);
    @rows = read_rows("$dir/silent/requests.csv");
    ok(($status == 0 && @rows == 1 && $rows[0]{http} eq '0' && $rows[0]{error} =~ /timeout|timed out/i && $rows[0]{ms} >= $TIMEOUT_MIN_MS && $rows[0]{ms} <= $TIMEOUT_MAX_MS) ? 1 : 0,
        'a server that never answers is recorded with status 0, the reason and a time near the limit');
    return 0;
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    print STDERR "heap-request-array: $error";
    $status = 2;
};
$status = 1 if !$status && !Test::More->builder->is_passing;
exit $status;
