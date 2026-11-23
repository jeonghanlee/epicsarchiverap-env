#!/usr/bin/env perl
# Checks the schedule, the usage errors and the hard-linked staging of the baseline driver through its command line.
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

heap-run-baseline.pl - check the schedule, usage errors and staging of tests/heap/run-baseline.pl

=head1 SYNOPSIS

  perl tests/heap-run-baseline.pl [--tool FILE]
  perl tests/heap-run-baseline.pl --help

=head1 DESCRIPTION

Runs the real driver as a subprocess. The usage cases need no guest. The schedule cases compare the C<plan> output with dates
that C<date -u -d> computes independently from the start time and the declared offsets (hours after the start for the scale of
3600 seconds, minutes for the scale of 60), event by event for the scale of 3600 and as one text for the scale of 60, with a
collectors start that differs from the start time. The staging cases run C<link-queries> on a real tree of files in
nested folders and compare the inode numbers and link counts that C<stat> reports, a second run and a file that appears later.
The collectors, the registration, the query clients, the block copies and the watchdog need a guest and are checked by the
run of the driver itself.

The temporary directory is removed after the run. Required: Perl 5.26 or newer, Test::More, Linux, rsync, date and stat.

=head1 OPTIONS

=over 4

=item B<--tool> FILE

The driver to check (default C<tests/heap/run-baseline.pl> of this checkout); a scratch copy of the driver can be given here.

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when every check passes, 1 when an assertion fails, 2 for invalid usage or an environment error.

=cut

my $TESTS = dirname(abs_path($0));
my $REPOSITORY = dirname($TESTS);
my $TOOL = "$REPOSITORY/tests/heap/run-baseline.pl";
my $START = '2026-12-01T00:00:00Z';
my $COLLECTORS_START = '2026-11-30T23:55:00Z';
my $COLLECTORS_START_SCALED = '2026-11-30T23:59:50Z';
my @EVENTS = qw(warmup_end block_1 block_2 block_3 block_4 block_5 block_6 block_7 query_start block_8 cutoff collectors_end final_block);

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

sub date_of {
    my ($base, $offset) = @_;
    my ($status, $stdout, $stderr) = run_command('date', '-u', '-d', "$base $offset", '+%Y-%m-%dT%H:%M:%SZ');
    $status == 0 or die "date failed with $status: $stderr\n";
    chomp $stdout;
    return $stdout;
}

sub write_bytes {
    my ($path, $bytes) = @_;
    make_path(dirname($path));
    open(my $handle, '>', $path) or die "open $path: $!\n";
    binmode($handle);
    print {$handle} $bytes or die "write $path: $!\n";
    close($handle) or die "close $path: $!\n";
    return;
}

sub inode_and_links {
    my ($path) = @_;
    my ($status, $stdout, $stderr) = run_command('stat', '-c', '%i %h', $path);
    $status == 0 or die "stat of $path failed with $status: $stderr\n";
    chomp $stdout;
    return $stdout;
}

# Expected schedule: offsets of every event as declared, in units after the start (hours or minutes) and seconds after the collectors start.
sub expected_schedule {
    my ($unit, $collectors_start) = @_;
    my %at = (warmup_end => 6, query_start => 42, cutoff => 48);
    $at{"block_$_"} = 6 * $_ for 1 .. 8;
    my %utc = map { $_ => date_of($START, "+$at{$_} $unit") } keys %at;
    my $whole = $unit eq 'hours' ? '48 hours 30 minutes' : '48 minutes 30 seconds';
    $utc{collectors_end} = date_of($collectors_start, "+$whole");
    $utc{final_block} = date_of($utc{collectors_end}, '+2 minutes');
    return \%utc;
}

sub parse_plan {
    my ($text) = @_;
    my @rows = map { [ split /\t/ ] } split /\n/, $text;
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
    for my $program (qw(date stat rsync)) {
        my ($status) = run_command('sh', '-c', "command -v $program");
        $status == 0 or die "$program is required\n";
    }
    my $base = $ENV{TMPDIR} && -w $ENV{TMPDIR} ? $ENV{TMPDIR} : "$REPOSITORY/work/scratch/tmp";
    make_path($base);
    my $dir = tempdir('heap-run-baseline.XXXXXX', DIR => $base, CLEANUP => 1);
    plan tests => 37;

    # Usage errors and statuses.
    my ($status, $stdout, $stderr) = run_tool('--help');
    is($status, 0, 'help: exit status');
    like($stdout, qr{Usage:\n\s+perl tests/heap/run-baseline\.pl plan}, 'help: prints the usage lines');
    ($status, $stdout, $stderr) = run_tool();
    is($status, 2, 'no command: exit status');
    like($stderr, qr/a command is required/, 'no command: message');
    ($status, $stdout, $stderr) = run_tool('nonsense');
    is($status, 2, 'unknown command: exit status');
    ($status, $stdout, $stderr) = run_tool('plan');
    is($status, 2, 'plan without --r-time: exit status');
    like($stderr, qr/plan needs --r-time/, 'plan without --r-time: message');
    ($status, $stdout, $stderr) = run_tool('plan', '--r-time', '2026-12-01 00:00:00');
    is($status, 2, 'plan with a time of the wrong form: exit status');
    ($status, $stdout, $stderr) = run_tool('plan', '--r-time', '2026-13-45T00:00:00Z');
    is($status, 2, 'plan with an impossible date: exit status');
    ($status, $stdout, $stderr) = run_tool('plan', '--r-time', $START, '--scale', '0');
    is($status, 2, 'plan with scale 0: exit status');
    ($status, $stdout, $stderr) = run_tool('link-queries', '--queries-dir', $dir);
    is($status, 2, 'link-queries without --staging: exit status');
    ($status, $stdout, $stderr) = run_tool('run', '--evidence-dir', "$dir/e", '--guest', 'u@h', '--guest-dir', '/g', '--service-account', 'svc', '--pvs-csv', '/p');
    is($status, 2, 'run without --camonitor: exit status');
    ($status, $stdout, $stderr) = run_tool('run', '--evidence-dir', "$dir/e", '--guest', 'u@h', '--guest-dir', '/g', '--camonitor', '/c', '--pvs-csv', '/p');
    ok(($status == 2 && $stderr =~ /run needs --service-account/) ? 1 : 0, 'run without --service-account: refused with its name');
    ($status, $stdout, $stderr) = run_tool('plan', '--r-time', $START, '--guest-dir', 'relative/dir');
    is($status, 2, 'a relative guest folder: exit status');

    # Schedule against independently computed dates.
    my $expected = expected_schedule('hours', $COLLECTORS_START);
    ($status, $stdout, $stderr) = run_tool('plan', '--r-time', $START, '--collectors-start', $COLLECTORS_START);
    my %actual = map { $_->[0] => $_->[1] } parse_plan($stdout);
    for my $event (@EVENTS) {
        is($actual{$event}, $expected->{$event}, "schedule at scale 3600: $event");
    }
    my $sorted = join(',', map { $_->[1] } parse_plan($stdout)) eq join(',', sort map { $_->[1] } parse_plan($stdout));
    ok($sorted ? 1 : 0, 'schedule at scale 3600: the events are in time order');
    ($status, $stdout, $stderr) = run_tool('plan', '--r-time', $START, '--collectors-start', $COLLECTORS_START);
    my @names = map { $_->[0] } parse_plan($stdout);
    my %position = map { $names[$_] => $_ } 0 .. $#names;
    ok(($position{query_start} < $position{block_7} && $position{cutoff} < $position{block_8}) ? 1 : 0,
        'schedule at scale 3600: the query start and the cutoff come before the block copy of the same time');
    ($status, $stdout, $stderr) = run_tool('plan', '--r-time', $START, '--collectors-start', date_of($START, '-150 minutes'));
    ok(($status == 2 && $stderr =~ /the collectors end before the cutoff/) ? 1 : 0, 'collectors that start 2.5 hours before R are refused');
    ($status, $stdout, $stderr) = run_tool('plan', '--r-time', $START, '--collectors-start', date_of($START, '-29 minutes'));
    is($status, 0, 'collectors that start 29 minutes before R are accepted');
    my $minutes = expected_schedule('minutes', $COLLECTORS_START_SCALED);
    my $expected_text = join("\n", sort map { "$_\t$minutes->{$_}" } @EVENTS);
    ($status, $stdout, $stderr) = run_tool('plan', '--r-time', $START, '--collectors-start', $COLLECTORS_START_SCALED, '--scale', '60');
    is(join("\n", sort split(/\n/, $stdout)), $expected_text, 'schedule at scale 60: whole plan, lines sorted');

    # Hard-linked staging.
    my $queries = "$dir/queries";
    my $staging = "$dir/staging";
    write_bytes("$queries/requests-0.csv", "a,b\n1,2\n");
    write_bytes("$queries/responses/client-0/r1.json", "{\"x\":1}\n");
    ($status, $stdout, $stderr) = run_tool('link-queries', '--queries-dir', $queries, '--staging', $staging);
    is($status, 0, 'link-queries: exit status');
    my ($source_inode, $source_links) = split ' ', inode_and_links("$queries/responses/client-0/r1.json");
    my ($staged_inode) = split ' ', inode_and_links("$staging/queries/responses/client-0/r1.json");
    is($staged_inode, $source_inode, 'a nested response file shares its inode with the staged file');
    my (undef, $links) = split ' ', inode_and_links("$staging/queries/requests-0.csv");
    is($links, 2, 'a staged request file has two links');
    my $before = inode_and_links("$staging/queries/requests-0.csv");
    ($status, $stdout, $stderr) = run_tool('link-queries', '--queries-dir', $queries, '--staging', $staging);
    is(inode_and_links("$staging/queries/requests-0.csv"), $before, 'a second run keeps the same file and link count');
    write_bytes("$queries/responses/client-0/r2.json", "{\"x\":2}\n");
    ($status, $stdout, $stderr) = run_tool('link-queries', '--queries-dir', $queries, '--staging', $staging);
    my ($new_source) = split ' ', inode_and_links("$queries/responses/client-0/r2.json");
    my ($new_staged) = split ' ', inode_and_links("$staging/queries/responses/client-0/r2.json");
    is($new_staged, $new_source, 'a file that appears later is linked by the next run');
    return 0;
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    print STDERR "heap-run-baseline: $error";
    $status = 2;
};
$status = 1 if !$status && !Test::More->builder->is_passing;
exit $status;
