#!/usr/bin/env perl
# Checks the shipped block copier through its command line against real files, a real concurrent writer and real changes.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
use Pod::Usage qw(pod2usage);
use POSIX ();
use Test::More;
use Time::HiRes qw(sleep);
use Time::Local qw(timegm);

BEGIN {
    require(dirname(abs_path($0)) . '/lib/ArchiverTest.pm');
    ArchiverTest->import(qw(slurp usage_error));
}

=head1 NAME

heap-copy-block.pl - check the exit statuses, copies and manifests of tests/heap/copy-block.pl

=head1 SYNOPSIS

  perl tests/heap-copy-block.pl
  perl tests/heap-copy-block.pl --help

=head1 DESCRIPTION

Runs the real copier as a subprocess on real files. Usage errors, a missing source, a missing or invalid manifest of the
previous block and a file name that is not UTF-8 need no copy. The copy cases use a source tree of a log without a final
newline, a CSV, a response file, an empty file, a file of arbitrary bytes and a symbolic link, and check every figure
against other tools: the sizes against wc, the hashes against sha256sum, the bytes against cmp and the last newline against
python3. They cover the first block, a second block after appending (only the new bytes are appended and counted), a block
with no change, a block copied while a real process appends to a log (the copy is a byte prefix of the final file and the
next block completes it) and the four refusals that keep a file untouched with its previous record: changed earlier content,
a shorter file, a file removed from the source and a destination file of another length. A refused file is checked again
and found ok in the next block once its source is restored.

The temporary directory uses TMPDIR when writable, otherwise work/scratch/tmp of the checkout; it is removed after the
run. Required: Perl 5.26 or newer, Test::More, JSON::PP, Time::HiRes, Linux, sh, python3, wc, cmp, head, sha256sum and date.

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
my $TOOL = "$REPOSITORY/tests/heap/copy-block.pl";
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

# Starts a command in the background and remembers it so the END block can stop it.
sub spawn {
    my (@command) = @_;
    my $pid = fork;
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

# Waits for a remembered child and forgets it, so the END block never signals a recycled process ID.
sub reap {
    my ($pid) = @_;
    waitpid($pid, 0);
    @CHILDREN = grep { $_ != $pid } @CHILDREN;
    return;
}

# Runs a shell script with the standard text tools and returns its trimmed output.
sub text_tool {
    my ($script, @arguments) = @_;
    my ($status, $stdout, $stderr) = run_command('sh', '-c', $script, 'sh', @arguments);
    $status == 0 or die "text tool failed with $status: $stderr\n";
    $stdout =~ s/\A\s+|\s+\z//g;
    return $stdout;
}

sub write_bytes {
    my ($path, $bytes, $mode) = @_;
    make_path(dirname($path));
    open(my $handle, $mode // '>', $path) or die "open $path: $!\n";
    binmode($handle);
    print {$handle} $bytes or die "write $path: $!\n";
    close($handle) or die "close $path: $!\n";
    return;
}

sub sha256_of {
    my ($path) = @_;
    return text_tool('sha256sum < "$1" | awk \'{print $1}\'', $path);
}

sub size_of {
    my ($path) = @_;
    return text_tool('wc -c < "$1"', $path) + 0;
}

# Returns the offset after the last newline of a file as python3 computes it.
sub last_newline_end {
    my ($path) = @_;
    return text_tool('python3 -c \'import sys; print(open(sys.argv[1], "rb").read().rfind(b"\n") + 1)\' "$1"', $path) + 0;
}

sub epoch_of {
    my ($utc) = @_;
    my ($y, $mo, $d, $h, $mi, $s, $ms) = $utc =~ /^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\.(\d{3})Z$/ or return;
    return timegm($s, $mi, $h, $d, $mo - 1, $y) + $ms / 1000;
}

sub read_manifest {
    my ($dest, $block) = @_;
    my $path = sprintf('%s/manifests/block-%04d.json', $dest, $block);
    return { block => $block, files => [], skipped => [], ok => JSON::PP::false } unless -e $path;
    return decode_json(slurp($path));
}

sub by_path {
    my ($manifest) = @_;
    return { map { $_->{path} => $_ } @{ $manifest->{files} } };
}

# Builds the source tree of the copy cases.
sub make_source {
    my ($source) = @_;
    write_bytes("$source/gc/engine.log", "[0.001s][info][gc] one\n[0.002s][info][gc] two\n");
    write_bytes("$source/samples.csv", "time,value\n1,10\n2,20\n3,3");
    write_bytes("$source/responses/c0-000001.json", '[{"secs":1,"val":1}]');
    write_bytes("$source/empty", '');
    write_bytes("$source/binary.bin", "\x00\xff\xfe\r\n\x80 raw \x01\n\xc3\x28 end");
    symlink('gc/engine.log', "$source/link-to-log") or die "symlink: $!\n";
    return;
}

sub run_usage_cases {
    my ($workspace) = @_;
    my $source = "$workspace/usage-src";
    make_path($source);
    my @base = ('--source', $source, '--dest', "$workspace/usage-dest", '--block', 1);
    my @cases = (
        ['no option', [], qr/--source is required/],
        ['no destination', ['--source', $source, '--block', 1], qr/--dest is required/],
        ['no block', ['--source', $source, '--dest', "$workspace/usage-dest"], qr/--block is required/],
        ['unknown option', ['--bogus'], qr/Unknown option/],
        ['zero block', [@base[0 .. 3], '--block', 0], qr/--block must be a positive integer/],
        ['text block', [@base[0 .. 3], '--block', 'x'], qr/--block must be a positive integer/],
        ['fractional block', [@base[0 .. 3], '--block', '1.5'], qr/--block must be a positive integer/],
        ['stray argument', [@base, 'extra'], qr/unexpected argument/],
    );
    my ($status, $stdout) = run_tool('--help');
    is($status, 0, 'help: exit status');
    like($stdout, qr/--source/, 'help: names the source option');
    for my $case (@cases) {
        my ($name, $arguments, $pattern) = @{$case};
        my ($code, undef, $stderr) = run_tool(@{$arguments});
        is($code, 2, "usage $name: exit status");
        like($stderr, $pattern, "usage $name: diagnostic");
    }
    ok(!-e "$workspace/usage-dest", 'usage cases: no destination was created');
    return;
}

sub run_missing_input_cases {
    my ($workspace) = @_;
    my $source = "$workspace/miss-src";
    write_bytes("$source/a.log", "x\n");

    my ($code, undef, $stderr) = run_tool('--source', "$workspace/no-such-dir", '--dest', "$workspace/miss-d1", '--block', 1);
    is($code, 77, 'missing source: exit status');
    like($stderr, qr/Source directory not found/, 'missing source: diagnostic');
    ok(!-e "$workspace/miss-d1", 'missing source: no destination was created');

    ($code, undef, $stderr) = run_tool('--source', $source, '--dest', "$workspace/miss-d2", '--block', 2);
    is($code, 77, 'block 2 without block 1: exit status');
    like($stderr, qr/Cannot read the manifest of the previous block/, 'block 2 without block 1: diagnostic');
    ok(!-e "$workspace/miss-d2/manifests/block-0002.json", 'block 2 without block 1: no manifest was written');

    write_bytes("$workspace/miss-d3/manifests/block-0001.json", "not json\n");
    ($code, undef, $stderr) = run_tool('--source', $source, '--dest', "$workspace/miss-d3", '--block', 2);
    is($code, 77, 'invalid previous manifest: exit status');
    like($stderr, qr/Invalid manifest of the previous block/, 'invalid previous manifest: diagnostic');

    write_bytes("$workspace/miss-bad/ok.log", "x\n");
    write_bytes("$workspace/miss-bad/bad\xffname.log", "x\n");
    ($code, undef, $stderr) = run_tool('--source', "$workspace/miss-bad", '--dest', "$workspace/miss-d4", '--block', 1);
    is($code, 77, 'file name that is not UTF-8: exit status');
    like($stderr, qr/not valid UTF-8 text/, 'file name that is not UTF-8: diagnostic');
    ok(!-e "$workspace/miss-d4/manifests/block-0001.json", 'file name that is not UTF-8: no manifest was written');

    my $blocker = "$workspace/blocker";
    write_bytes($blocker, "a file, not a directory\n");
    ($code, undef, $stderr) = run_tool('--source', $source, '--dest', "$blocker/sub", '--block', 1);
    is($code, 1, 'destination below a file: exit status');
    like($stderr, qr/FAILURE: mkdir/, 'destination below a file: diagnostic');
    return;
}

# Checks every file record of a manifest against the source, the destination copy and the standard tools.
sub check_records {
    my ($label, $manifest, $source, $dest) = @_;
    my $bad = 0;
    for my $record (@{ $manifest->{files} }) {
        my ($path, $copy) = ("$source/$record->{path}", "$dest/data/$record->{path}");
        $bad++ unless $record->{status} eq 'ok';
        $bad++ unless -f $copy && $record->{sha256} eq sha256_of($copy) && $record->{bytes} == size_of($copy);
        $bad++ unless $record->{sha256} eq sha256_of($path) && $record->{bytes} == size_of($path);
        $bad++ unless text_tool('cmp "$1" "$2" && echo same', $path, $copy) eq 'same';
        $bad++ unless $record->{last_newline_end} == last_newline_end($copy);
    }
    is($bad, 0, "$label: every file is ok and equals its source in size, SHA256, bytes and last newline");
    return;
}

sub run_copy_cases {
    my ($workspace) = @_;
    my ($source, $dest) = ("$workspace/src", "$workspace/dest");
    make_source($source);

    my $before = text_tool('date -u +%s');
    my ($code, undef, $stderr) = run_tool('--source', $source, '--dest', $dest, '--block', 1);
    my $after = text_tool('date -u +%s');
    is($code, 0, 'block 1: exit status');
    is($stderr, '', 'block 1: nothing on stderr');
    my $first = read_manifest($dest, 1);
    is($first->{block}, 1, 'block 1: block number');
    ok($first->{ok}, 'block 1: manifest is ok');
    is($first->{source}, abs_path($source), 'block 1: absolute source path');
    my $copied = epoch_of($first->{copied_utc});
    ok(defined $copied && $copied >= $before - 1 && $copied <= $after + 1, 'block 1: copy time lies between the date readings');
    is_deeply([ map { $_->{path} } @{ $first->{files} } ], [qw(binary.bin empty gc/engine.log responses/c0-000001.json samples.csv)], 'block 1: regular files in sorted order');
    is_deeply($first->{skipped}, ['link-to-log'], 'block 1: the symbolic link is listed as skipped');
    check_records('block 1', $first, $source, $dest);
    my %one = %{ by_path($first) };
    is($one{'samples.csv'}{last_newline_end}, 21, 'block 1: the unfinished last line of the CSV is excluded from last_newline_end');
    is($one{'responses/c0-000001.json'}{last_newline_end}, 0, 'block 1: a file without a newline has last_newline_end 0');
    is_deeply([ grep { $_->{appended_bytes} != $_->{bytes} } @{ $first->{files} } ], [], 'block 1: every byte is new');
    ok(!-e "$dest/manifests/block-0001.json.tmp", 'block 1: no temporary manifest is left');
    ok(!-e "$dest/data/link-to-log", 'block 1: the symbolic link was not copied');

    my $record_hash = sha256_of("$dest/manifests/block-0001.json");
    my ($again, undef, $again_error) = run_tool('--source', $source, '--dest', $dest, '--block', 1);
    is($again, 2, 'block 1 again: exit status');
    like($again_error, qr/block-0001\.json already exists/, 'block 1 again: diagnostic');
    is(sha256_of("$dest/manifests/block-0001.json"), $record_hash, 'block 1 again: manifest unchanged');

    # Block 2: growth of two files and one new file.
    my %size_before = map { $_ => size_of("$source/$_") } qw(gc/engine.log samples.csv);
    write_bytes("$source/gc/engine.log", "[0.003s][info][gc] three\n", '>>');
    write_bytes("$source/samples.csv", "\n4,40\n5,50", '>>');
    write_bytes("$source/responses/c0-000002.json", '[{"secs":2,"val":2}]');
    ($code, undef, $stderr) = run_tool('--source', $source, '--dest', $dest, '--block', 2);
    is($code, 0, 'block 2: exit status');
    my $second = read_manifest($dest, 2);
    check_records('block 2', $second, $source, $dest);
    my %two = %{ by_path($second) };
    is($two{'gc/engine.log'}{appended_bytes}, size_of("$source/gc/engine.log") - $size_before{'gc/engine.log'}, 'block 2: appended bytes of the log equal its growth');
    is($two{'samples.csv'}{appended_bytes}, size_of("$source/samples.csv") - $size_before{'samples.csv'}, 'block 2: appended bytes of the CSV equal its growth');
    is($two{'responses/c0-000002.json'}{appended_bytes}, size_of("$source/responses/c0-000002.json"), 'block 2: a new file counts all its bytes');
    is($two{'binary.bin'}{appended_bytes}, 0, 'block 2: an unchanged file appends nothing');
    is($two{'samples.csv'}{last_newline_end}, last_newline_end("$source/samples.csv"), 'block 2: the line finished by the new bytes is complete');
    cmp_ok($second->{copied_monotonic_s}, '>', $first->{copied_monotonic_s}, 'block 2: the monotonic copy time advances');

    # Block 3: nothing changed.
    ($code) = run_tool('--source', $source, '--dest', $dest, '--block', 3);
    is($code, 0, 'block 3: exit status');
    my $third = read_manifest($dest, 3);
    check_records('block 3', $third, $source, $dest);
    is_deeply([ grep { $_->{appended_bytes} != 0 } @{ $third->{files} } ], [], 'block 3: nothing is appended');
    return;
}

sub run_concurrent_case {
    my ($workspace) = @_;
    my ($source, $dest) = ("$workspace/live-src", "$workspace/live-dest");
    make_path("$source/live");
    write_bytes("$source/live/writer.log", "start\n");
    my $writer = spawn('sh', '-c', 'i=0; while :; do i=$((i + 1)); printf "line %s\n" "$i" >> "$1"; sleep 0.02; done', 'sh', "$source/live/writer.log");
    for (1 .. 100) {
        last if size_of("$source/live/writer.log") > 200;
        sleep(0.05);
    }
    my ($code) = run_tool('--source', $source, '--dest', $dest, '--block', 1);
    is($code, 0, 'live block 1: exit status');
    my $first = read_manifest($dest, 1);
    my ($record) = @{ $first->{files} };
    is($record->{bytes}, size_of("$dest/data/live/writer.log"), 'live block 1: recorded size equals the destination size');
    is(text_tool('head -c "$1" "$2" | sha256sum | awk \'{print $1}\'', $record->{bytes}, "$source/live/writer.log"), $record->{sha256}, 'live block 1: recorded hash is that of the source prefix of that length');
    is(text_tool('cmp -n "$1" "$2" "$3" && echo same', $record->{bytes}, "$source/live/writer.log", "$dest/data/live/writer.log"), 'same', 'live block 1: the copy is a byte prefix of the file as it is now');
    sleep(0.3);
    kill('TERM', $writer);
    reap($writer);
    ($code) = run_tool('--source', $source, '--dest', $dest, '--block', 2);
    is($code, 0, 'live block 2: exit status');
    my $second = read_manifest($dest, 2);
    check_records('live block 2', $second, $source, $dest);
    my ($later) = @{ $second->{files} };
    is($later->{bytes}, size_of("$source/live/writer.log"), 'live block 2: the file is complete');
    is($later->{appended_bytes}, $later->{bytes} - $record->{bytes}, 'live block 2: only the bytes after block 1 were appended');
    return;
}

# Runs block 1, applies a change to the source and runs block 2; returns the exit status, stderr and both manifests.
sub violation_run {
    my ($workspace, $name, $change) = @_;
    my ($source, $dest) = ("$workspace/$name-src", "$workspace/$name-dest");
    write_bytes("$source/a.log", "alpha one\nalpha two\n");
    write_bytes("$source/b.log", "beta one\n");
    my ($first_code) = run_tool('--source', $source, '--dest', $dest, '--block', 1);
    $first_code == 0 or die "block 1 of $name failed: $first_code\n";
    $change->($source, $dest);
    my ($code, undef, $stderr) = run_tool('--source', $source, '--dest', $dest, '--block', 2);
    return ($code, $stderr, read_manifest($dest, 1), read_manifest($dest, 2), $source, $dest);
}

sub run_violation_cases {
    my ($workspace) = @_;
    my $grow_b = sub { write_bytes("$_[0]/b.log", "beta two\n", '>>') };

    # Changed earlier content: refused, left untouched, healed when the source is restored.
    my ($code, $stderr, $one, $two, $source, $dest) = violation_run($workspace, 'prefix', sub {
        write_bytes("$_[0]/a.log", 'X', '+<');
        $grow_b->(@_);
    });
    my ($a1, $a2, $b2) = (by_path($one)->{'a.log'}, by_path($two)->{'a.log'}, by_path($two)->{'b.log'});
    is($code, 3, 'changed content: exit status');
    like($stderr, qr/NOT OK: prefix_mismatch: a\.log/, 'changed content: the file is named on stderr');
    is($a2->{status}, 'prefix_mismatch', 'changed content: status');
    ok(!$two->{ok}, 'changed content: manifest is not ok');
    is(sha256_of("$dest/data/a.log"), $a1->{sha256}, 'changed content: the destination file is untouched');
    is_deeply([ @{$a2}{qw(bytes sha256 appended_bytes)} ], [ $a1->{bytes}, $a1->{sha256}, 0 ], 'changed content: the previous record is kept');
    is($b2->{status}, 'ok', 'changed content: another file is still copied');
    is(text_tool('cmp "$1" "$2" && echo same', "$source/b.log", "$dest/data/b.log"), 'same', 'changed content: the other file equals its source');
    write_bytes("$source/a.log", 'a', '+<');
    ($code) = run_tool('--source', $source, '--dest', $dest, '--block', 3);
    my $three = by_path(read_manifest($dest, 3));
    is($code, 0, 'restored content: exit status');
    is($three->{'a.log'}{status}, 'ok', 'restored content: the file is ok again');

    # A shorter file.
    ($code, $stderr, $one, $two, $source, $dest) = violation_run($workspace, 'shrunk', sub {
        write_bytes("$_[0]/a.log", "alpha\n");
    });
    ($a1, $a2) = (by_path($one)->{'a.log'}, by_path($two)->{'a.log'});
    is($code, 3, 'shorter file: exit status');
    is($a2->{status}, 'shrunk', 'shorter file: status');
    is(sha256_of("$dest/data/a.log"), $a1->{sha256}, 'shorter file: the destination file is untouched');

    # A file removed from the source.
    ($code, $stderr, $one, $two, $source, $dest) = violation_run($workspace, 'gone', sub {
        unlink("$_[0]/b.log") or die "unlink: $!\n";
    });
    my ($b1) = by_path($one)->{'b.log'};
    $b2 = by_path($two)->{'b.log'};
    is($code, 3, 'removed file: exit status');
    is($b2->{status}, 'missing_in_source', 'removed file: status');
    is_deeply([ @{$b2}{qw(bytes sha256)} ], [ $b1->{bytes}, $b1->{sha256} ], 'removed file: the previous record is kept');
    is(sha256_of("$dest/data/b.log"), $b1->{sha256}, 'removed file: the destination file is kept');

    # A destination file of another length.
    ($code, $stderr, $one, $two, $source, $dest) = violation_run($workspace, 'dest', sub {
        write_bytes("$_[1]/data/a.log", 'Z', '>>');
        $grow_b->(@_);
    });
    $a2 = by_path($two)->{'a.log'};
    is($code, 3, 'altered destination: exit status');
    is($a2->{status}, 'dest_inconsistent', 'altered destination: status');
    is(size_of("$dest/data/a.log"), by_path($one)->{'a.log'}{bytes} + 1, 'altered destination: the file is not modified further');
    is(by_path($two)->{'b.log'}{status}, 'ok', 'altered destination: another file is still copied');
    return;
}

sub main {
    my @arguments = @_;
    my $help;
    GetOptionsFromArray(\@arguments, 'help' => \$help) or return usage_error('heap-copy-block.pl', __FILE__, 'invalid option');
    if ($help) {
        pod2usage(-input => __FILE__, -exitval => 'NOEXIT', -verbose => 1, -output => \*STDOUT);
        return 0;
    }
    @arguments and return usage_error('heap-copy-block.pl', __FILE__, 'unexpected argument');
    -f $TOOL or die "missing block copier: $TOOL\n";

    my $temporary_root = defined $ENV{TMPDIR} && -d $ENV{TMPDIR} && -w _ ? $ENV{TMPDIR} : "$REPOSITORY/work/scratch/tmp";
    make_path($temporary_root);
    my $workspace = tempdir('heap-copy-XXXXXX', DIR => $temporary_root, CLEANUP => 1);

    run_usage_cases($workspace);
    run_missing_input_cases($workspace);
    run_copy_cases($workspace);
    run_concurrent_case($workspace);
    run_violation_cases($workspace);

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
    print STDERR "heap-copy-block.pl: $error";
    $status = 2;
};
exit($status == 0 && !Test::More->builder->is_passing ? 1 : $status);
