#!/usr/bin/env perl
# Checks the two Perl tools of the array cases (hash-events.pl and classify-cells.pl) through their command lines with real files.
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

=head1 NAME

heap-array-cases.pl - check tests/heap/array-cases/hash-events.pl and classify-cells.pl

=head1 SYNOPSIS

  perl tests/heap-array-cases.pl [--dir DIRECTORY]
  perl tests/heap-array-cases.pl --help

=head1 DESCRIPTION

Runs the real tools as subprocesses. The expected hash of every event is not taken from Perl's own C<pack>: the test writes the
elements as little-endian bytes by arithmetic and takes C<sha256sum> of that file. The reader is checked on an event of 300,000
elements that crosses many blocks, with up to eight bytes of padding before it so that the block ends fall on other digits, on
pretty-printed input, on events of zero and one element, on a response without events and on malformed responses. The classifier is
checked on a run directory made by the test, with a quoted error field that holds commas, doubled quotes and a line break, with every
outcome class, the order of the cells, and the cases that must end with status 77.

The temporary directory is removed after the run. Required: Perl 5.26 or newer, Test::More and sha256sum.

=head1 OPTIONS

=over 4

=item B<--dir> DIRECTORY

The directory with the tools (default C<tests/heap/array-cases> of this checkout).

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when all checks pass, 1 when a check fails, 2 for invalid usage.

=cut

my $EXIT_USAGE = 2;

my $help = 0;
my $directory = dirname(abs_path($0)) . '/heap/array-cases';
GetOptionsFromArray(\@ARGV, 'dir=s' => \$directory, 'help|h' => \$help) or do { print STDERR "heap-array-cases.pl: invalid option\n"; exit $EXIT_USAGE };
if ($help) {
    pod2usage(-verbose => 1, -exitval => 0, -output => \*STDOUT);
}
@ARGV == 0 or do { print STDERR "heap-array-cases.pl: no argument is expected\n"; exit $EXIT_USAGE };
my $HASH_TOOL     = "$directory/hash-events.pl";
my $CLASSIFY_TOOL = "$directory/classify-cells.pl";
-f $HASH_TOOL && -f $CLASSIFY_TOOL or do { print STDERR "heap-array-cases.pl: the tools are not in $directory\n"; exit $EXIT_USAGE };

my $work = tempdir('array-cases-XXXXXX', TMPDIR => 1, CLEANUP => 1);

sub slurp {
    my ($path) = @_;
    open(my $in, '<:raw', $path) or die "open $path: $!\n";
    local $/;
    my $data = <$in>;
    close($in) or die "close $path: $!\n";
    return $data // '';
}

sub spew {
    my ($path, $data) = @_;
    open(my $out, '>:raw', $path) or die "open $path: $!\n";
    print {$out} $data or die "write $path: $!\n";
    close($out) or die "close $path: $!\n";
    return;
}

# Runs a command without a shell and returns its status, standard output and standard error.
sub run_tool {
    my (@command) = @_;
    my $stdout = "$work/stdout.$$";
    my $stderr = "$work/stderr.$$";
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if ($pid == 0) {
        open(STDOUT, '>', $stdout) or POSIX::_exit(126);
        open(STDERR, '>', $stderr) or POSIX::_exit(126);
        exec { $command[0] } @command or POSIX::_exit(127);
    }
    waitpid($pid, 0);
    return ($? >> 8, slurp($stdout), slurp($stderr));
}

# SHA-256 of the elements as unsigned 16-bit little-endian bytes, written by arithmetic and hashed by sha256sum.
sub oracle_sha256 {
    my (@values) = @_;
    my $path = "$work/oracle.bin";
    spew($path, join('', map { chr($_ & 255) . chr(($_ >> 8) & 255) } @values));
    my ($status, $out) = run_tool('sha256sum', $path);
    $status == 0 or die "sha256sum failed\n";
    return (split ' ', $out)[0];
}

sub response_json {
    my (@events) = @_;
    my $data = join(',', map { sprintf('{"secs": %d, "val": [%s]}', $_->{secs}, join(',', @{ $_->{values} })) } @events);
    return '[ { "meta": { "name": "T:ARR" , "PREC": "0" },"data": [' . $data . '] } ]';
}

my @big = map { ($_ * 7919) % 65536 } 0 .. 299_999;

# --- hash-events.pl: usage and input errors
{
    my ($status) = run_tool('perl', $HASH_TOOL);
    is($status, 2, 'hash-events: no argument is a usage error');
    ($status) = run_tool('perl', $HASH_TOOL, '--bogus');
    is($status, 2, 'hash-events: an unknown option is a usage error');
    my $out;
    ($status, $out) = run_tool('perl', $HASH_TOOL, '--help');
    is($status, 0, 'hash-events: --help ends with status 0');
    like($out, qr/hash-events\.pl FILE/, 'hash-events: --help prints the text');
    my $err;
    ($status, $out, $err) = run_tool('perl', $HASH_TOOL, "$work/missing.json");
    is($status, 77, 'hash-events: a missing file ends with status 77');
    like($err, qr/missing\.json: No such file/, 'hash-events: the message names the file and the cause');
}

# --- hash-events.pl: the hash of events of different sizes against sha256sum
{
    my @events = (
        { secs => 1795684249, values => [ 0, 1, 255, 256, 65535, 4096 ] },
        { secs => 1795684279, values => [ 42 ] },
        { secs => 1795684309, values => [] },
        { secs => 1795684339, values => [@big] },
    );
    my $path = "$work/events.json";
    spew($path, response_json(@events));
    my ($status, $out, $err) = run_tool('perl', $HASH_TOOL, $path);
    is($status, 0, 'hash-events: a response of four events is read');
    my @lines = split /\n/, $out;
    is(scalar @lines, 4, 'hash-events: one line per event, also for an event of zero elements');
    for my $index (0 .. 3) {
        my $event    = $events[$index];
        my $expected = sprintf('secs=%d elements=%d sha256=%s', $event->{secs}, scalar @{ $event->{values} }, oracle_sha256(@{ $event->{values} }));
        is($lines[$index], $expected, "hash-events: event $index equals the count and the sha256sum of the little-endian bytes");
    }
    is($err, '', 'hash-events: nothing on standard error');
}

# --- hash-events.pl: block ends on other digits
{
    my $expected = oracle_sha256(@big);
    my @wrong;
    for my $padding (0 .. 7) {
        my $path = "$work/padded-$padding.json";
        spew($path, ' ' x $padding . response_json({ secs => 7, values => [@big] }));
        my ($status, $out) = run_tool('perl', $HASH_TOOL, $path);
        push @wrong, $padding unless $status == 0 && $out eq sprintf("secs=7 elements=300000 sha256=%s\n", $expected);
    }
    is_deeply(\@wrong, [], 'hash-events: the same event gives the same line with 0 to 7 bytes of padding in front of it');
}

# --- hash-events.pl: a secs or val token cut by the end of a 256 KiB block
{
    my $block = 256 * 1024;
    my $head  = '[ { "meta": { "name": "T" },"data": [';
    my $tail  = '] } ]';
    my $first = '{"secs": 1, "val": [1,2,3]}';
    my $want  = sprintf("secs=1 elements=3 sha256=%s\nsecs=2 elements=3 sha256=%s\n", oracle_sha256(1, 2, 3), oracle_sha256(4, 5, 6));
    my (@lost_secs, @lost_val);
    for my $cut (1 .. 5) {
        # the token "secs" of the second event starts $cut bytes before the end of the first block
        my $before = length($head . $first) + length(',{');
        my $pad    = ' ' x ($block - $cut - $before);
        my $path   = "$work/straddle-secs-$cut.json";
        spew($path, $head . $first . $pad . ',{"secs": 2, "val": [4,5,6]}' . $tail);
        my ($status, $out) = run_tool('perl', $HASH_TOOL, $path);
        push @lost_secs, $cut unless $status == 0 && $out eq $want;

        # the token "val" of the second event starts $cut bytes before the end of the first block
        my $prefix = $head . $first . ',{"secs": 2,';
        $path = "$work/straddle-val-$cut.json";
        spew($path, $prefix . ' ' x ($block - $cut - length($prefix)) . '"val": [4,5,6]}' . $tail);
        ($status, $out) = run_tool('perl', $HASH_TOOL, $path);
        push @lost_val, $cut unless $status == 0 && $out eq $want;
    }
    is_deeply(\@lost_secs, [], 'hash-events: a secs token cut 1 to 5 bytes before the end of a block is found');
    is_deeply(\@lost_val, [], 'hash-events: a val token cut 1 to 5 bytes before the end of a block is found');
}

# --- hash-events.pl: layout, empty and malformed responses
{
    my $pretty = "$work/pretty.json";
    spew($pretty, "[\n  {\n    \"meta\": {\"name\": \"T\"},\n    \"data\": [\n      {\n        \"secs\": 5,\n        \"nanos\": 9,\n        \"val\": [\n          1,\n          2,\n          3\n        ]\n      }\n    ]\n  }\n]\n");
    my ($status, $out) = run_tool('perl', $HASH_TOOL, $pretty);
    is($out, sprintf("secs=5 elements=3 sha256=%s\n", oracle_sha256(1, 2, 3)), 'hash-events: pretty printed input with a nanos field');
    is($status, 0, 'hash-events: pretty printed input ends with status 0');

    spew("$work/empty.json", '[ { "meta": { "name": "T" },"data": [ ] } ]');
    ($status, $out) = run_tool('perl', $HASH_TOOL, "$work/empty.json");
    is_deeply([ $status, $out ], [ 0, '' ], 'hash-events: a response without events prints nothing and ends with status 0');

    spew("$work/error.html", '<!doctype html><html><body><h1>HTTP Status 500</h1></body></html>');
    ($status, $out) = run_tool('perl', $HASH_TOOL, "$work/error.html");
    is_deeply([ $status, $out ], [ 0, '' ], 'hash-events: an error page prints nothing and ends with status 0');

    my $err;
    spew("$work/float.json", '[{"data":[{"secs": 1, "val": [1,2.5,3]}]}]');
    ($status, $out, $err) = run_tool('perl', $HASH_TOOL, "$work/float.json");
    is($status, 77, 'hash-events: a non-integer element ends with status 77');
    like($err, qr/not an integer/, 'hash-events: the message says that an element is not an integer');

    spew("$work/open.json", '[{"data":[{"secs": 1, "val": [1,2,3,4');
    ($status, $out, $err) = run_tool('perl', $HASH_TOOL, "$work/open.json");
    is($status, 77, 'hash-events: an unclosed val array ends with status 77');
    like($err, qr/not closed/, 'hash-events: the message says that the array is not closed');
}

# --- classify-cells.pl: a run directory made by the test
sub write_requests {
    my ($path, @rows) = @_;
    make_path(dirname($path));
    my $header = 'group,client,sequence,name,pv,from,to,time_utc,monotonic_s,end_utc,ms,http,bytes,sha256,error';
    my @lines = ($header);
    for my $row (@rows) {
        my ($name, $http, $sha, $error, $bytes) = @{$row};
        my $field = defined $error ? '"' . ($error =~ s/"/""/gr) . '"' : '';
        push @lines, join(',', 1, 1, 1, $name, "P:$name", 'F', 'T', 'U', '1.0', 'E', 5, $http, $bytes // 10, $sha, $field);
    }
    spew($path, join("\n", @lines) . "\n");
    return;
}

my $run = "$work/run";
write_requests("$run/reference-512/requests.csv", [ 'laser1', 200, 'aaa' ], [ 'airy1', 200, 'bbb' ], [ 'bound1', 500, 'ccc', 'failed' ]);
write_requests("$run/r384-c4/requests.csv",
    [ 'laser1', 200, 'aaa' ], [ 'laser1', 200, 'zzz' ], [ 'airy1', 503, 'e3b', "refused, \"memory\"\ncheck" ], [ 'airy1', 400, 'e3b', 'bad' ], [ 'bound1', 200, 'ccc' ]);
write_requests("$run/r256-c1/requests.csv", [ 'laser1', 200, 'aaa' ], [ 'airy1', 500, 'e3b', 'oom' ], [ 'airy1', 0, 'e3b', 'timeout' ], [ 'airy1', 404, 'e3b', 'x' ]);
write_requests("$run/r512-c1/requests.csv", [ 'laser1', 200, 'aaa' ]);
{
    my ($status, $out, $err) = run_tool('perl', $CLASSIFY_TOOL, $run);
    is($status, 0, 'classify: a run directory is classified');
    is($out, join('', map { "$_\n" } (
        'r256-c1 laser1 Delivered=1',
        'r256-c1 airy1 Failed-500=1 Other=2',
        'r256-c1 total Delivered=1 Failed-500=1 Other=2',
        'r512-c1 laser1 Delivered=1',
        'r512-c1 total Delivered=1',
        'r384-c4 laser1 Delivered=1 Delivered-different=1',
        'r384-c4 airy1 Refused-400=1 Refused-503=1',
        'r384-c4 bound1 Delivered-different=1',
        'r384-c4 total Delivered=1 Delivered-different=2 Refused-400=1 Refused-503=1',
    )), 'classify: counts per request and per cell, one-client cells first, a quoted field with commas, quotes and a line break read correctly, an answered request whose reference failed counts as different');
    is($err, '', 'classify: nothing on standard error');
}

# --- classify-cells.pl: the check of the reference group
{
    write_requests("$work/refok/reference-512/requests.csv", [ 'laser1', 200, 'aaa', undef, 2_000_000 ], [ 'airy1', 200, 'bbb', undef, 1_500_000 ]);
    my ($status, $out, $err) = run_tool('perl', $CLASSIFY_TOOL, '--check-reference', 1_000_000, "$work/refok");
    is_deeply([ $status, $out ], [ 0, "reference ok rows=2\n" ], 'classify: a reference group of large answers passes the check');
    ($status, $out, $err) = run_tool('perl', $CLASSIFY_TOOL, '--check-reference', 1_500_000, "$work/refok");
    is($status, 0, 'classify: an answer of exactly the minimum size passes the check');
    ($status, $out, $err) = run_tool('perl', $CLASSIFY_TOOL, '--check-reference', 1_600_000, "$work/refok");
    is($status, 77, 'classify: an answer below the minimum size fails the check with status 77');
    like($err, qr/reference of airy1 has status 200 and 1500000 bytes, below 1600000/, 'classify: the message names the request, its status and its size');
    write_requests("$work/refbad/reference-512/requests.csv", [ 'laser1', 200, 'aaa', undef, 2_000_000 ], [ 'airy1', 500, 'bbb', 'oom', 0 ]);
    ($status, $out, $err) = run_tool('perl', $CLASSIFY_TOOL, '--check-reference', 1000, "$work/refbad");
    is($status, 77, 'classify: a reference row with status 500 fails the check with status 77');
}

# --- the outcome function of an engine attempt, every combination of its four inputs that matters
{
    my $common = "$directory/array-common.bash";
    my @table = (
        [ [ 1, 1, 1, 1 ], 'Failed',                    'the JVM ended, the PV was archived and matched' ],
        [ [ 1, 0, 0, 1 ], 'Failed',                    'the JVM ended and the PV was not archived' ],
        [ [ 0, 1, 2, 2 ], 'Archived',                  'both PVs archived and matched' ],
        [ [ 0, 1, 1, 2 ], 'Connected-without-storage', 'archived but one PV has no matching frames' ],
        [ [ 0, 1, 0, 1 ], 'Connected-without-storage', 'archived without matching frames' ],
        [ [ 0, 0, 1, 1 ], 'Not-connected',             'matching frames of a PV that never reached the archived state (a paused PV)' ],
        [ [ 0, 0, 0, 1 ], 'Not-connected',             'nothing archived and nothing stored' ],
    );
    for my $case (@table) {
        my ($inputs, $expected, $label) = @{$case};
        my ($status, $out) = run_tool('bash', '-c', 'source "$1"; shift; decide_outcome "$@"', 'bash', $common, @{$inputs});
        is_deeply([ $status, $out ], [ 0, "$expected\n" ], "outcome $expected: $label");
    }
}

# --- classify-cells.pl: usage and input errors
{
    my ($status) = run_tool('perl', $CLASSIFY_TOOL);
    is($status, 2, 'classify: no argument is a usage error');
    my $out;
    ($status, $out) = run_tool('perl', $CLASSIFY_TOOL, '--help');
    is($status, 0, 'classify: --help ends with status 0');
    like($out, qr/classify-cells\.pl RUN_DIR/, 'classify: --help prints the text');
    my $err;
    ($status, $out, $err) = run_tool('perl', $CLASSIFY_TOOL, "$work/nothing");
    is($status, 77, 'classify: a directory that does not exist ends with status 77');

    make_path("$work/noref/r256-c1");
    write_requests("$work/noref/r256-c1/requests.csv", [ 'laser1', 200, 'aaa' ]);
    ($status, $out, $err) = run_tool('perl', $CLASSIFY_TOOL, "$work/noref");
    is($status, 77, 'classify: a run without a reference ends with status 77');
    like($err, qr/reference/, 'classify: the message names the reference');

    write_requests("$work/tworef/reference-512/requests.csv", [ 'laser1', 200, 'aaa' ]);
    write_requests("$work/tworef/reference-384/requests.csv", [ 'laser1', 200, 'aaa' ]);
    write_requests("$work/tworef/r256-c1/requests.csv", [ 'laser1', 200, 'aaa' ]);
    ($status) = run_tool('perl', $CLASSIFY_TOOL, "$work/tworef");
    is($status, 77, 'classify: two reference directories end with status 77');

    write_requests("$work/nocell/reference-512/requests.csv", [ 'laser1', 200, 'aaa' ]);
    ($status, $out, $err) = run_tool('perl', $CLASSIFY_TOOL, "$work/nocell");
    is($status, 77, 'classify: a run without a cell ends with status 77');

    write_requests("$work/badcsv/reference-512/requests.csv", [ 'laser1', 200, 'aaa' ]);
    make_path("$work/badcsv/r256-c1");
    spew("$work/badcsv/r256-c1/requests.csv", "group,client,sequence,name,pv,from,to,time_utc,monotonic_s,end_utc,ms,http,bytes,sha256,error\n1,1,1,laser1,P,F,T,U,1.0,E,5,200,10,aaa,\"unterminated\n");
    ($status, $out, $err) = run_tool('perl', $CLASSIFY_TOOL, "$work/badcsv");
    is($status, 77, 'classify: a quoted field that never ends ends with status 77');

    make_path("$work/nocolumn/r256-c1");
    write_requests("$work/nocolumn/reference-512/requests.csv", [ 'laser1', 200, 'aaa' ]);
    spew("$work/nocolumn/r256-c1/requests.csv", "group,name,sha256\n1,laser1,aaa\n");
    ($status, $out, $err) = run_tool('perl', $CLASSIFY_TOOL, "$work/nocolumn");
    is($status, 77, 'classify: a header without the http column ends with status 77');
    like($err, qr/no column http/, 'classify: the message names the missing column');
}

done_testing();
