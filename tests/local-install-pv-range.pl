#!/usr/bin/env perl
# Checks the inclusive time bounds of the CSV extraction through the shipped PV verifier and a real soft IOC.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(basename dirname);
use File::Glob qw(bsd_glob);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP ();
use Pod::Usage qw(pod2usage);
use POSIX ();
use Time::Local qw(timegm);

=head1 NAME

local-install-pv-range.pl - check the inclusive CSV time bounds through the PV verifier and a real soft IOC

=head1 SYNOPSIS

  AA_TEST_EPICS_BIN=<bin/host_arch folder of a real EPICS Base> perl tests/local-install-pv-range.pl
  perl tests/local-install-pv-range.pl --help

=head1 DESCRIPTION

Runs scripts/verify-local-pv.bash against a real soft IOC of the supplied EPICS Base five times, each time with a
different answer of the replaced HTTP transport: inside (two samples inside the query range), boundary (the last
sample exactly on the upper bound), outside (a sample just past the upper bound), time-skew (the first sample later
than its real observation) and wrong-pv (data of another PV). Each run must end with the status that the answer
requires, with the PASS line only when the samples are valid, and with the test IOC stopped, and the retrieval
requests must carry the expected samples and PV name.

Only the HTTP transport is replaced: this file runs again as the C<curl> of the verifier's PATH. As that C<curl> it
answers archive, status, pause and data requests from the real IOC (it reads the process variable with the caget of the
supplied Base) and records its observations under the evidence folder of the run. The same file is the time-range
fixture of tests/local-install-pv-menu.pl. The runs write their evidence under work/local-pv-range.* of the checkout,
which stays after the run; its path is printed.

Environment: AA_TEST_EPICS_BIN is required; AA_TEST_SOURCE_PATH names the source checkout, by default
epicsarchiverap-maven-src beside the repository. Required programs: bash. Required Perl module beyond the core of Perl
5.26: none, but on Rocky Linux JSON::PP is the separate package perl-JSON-PP.

=head1 OPTIONS

=over 4

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when every run passed, 1 when a check failed, 2 for a usage error or an environment error. As the C<curl> fixture:
0 when the request was answered, 7 for a request it does not know, 1 when the IOC cannot be read.

=cut

my $TOP = abs_path(dirname(abs_path($0)) . '/..');
my $JSON = JSON::PP->new->canonical;

$| = 1;

sub fail {
    my ($message) = @_;
    die "ASSERTION: $message\n";
}

sub check {
    my ($condition, $message) = @_;
    $condition or fail($message);
    return;
}

sub slurp {
    my ($path) = @_;
    open(my $handle, '<:raw', $path) or die "open $path: $!\n";
    local $/;
    my $data = <$handle>;
    close($handle) or die "close $path: $!\n";
    return $data // '';
}

sub spew {
    my ($path, $data) = @_;
    open(my $handle, '>:raw', $path) or die "open $path: $!\n";
    print {$handle} $data or die "write $path: $!\n";
    close($handle) or die "close $path: $!\n";
    return;
}

sub append {
    my ($path, $data) = @_;
    open(my $handle, '>>:raw', $path) or die "open $path: $!\n";
    print {$handle} $data or die "write $path: $!\n";
    close($handle) or die "close $path: $!\n";
    return;
}

# Epoch seconds of an ISO 8601 UTC time; the fraction is cut off and the zone must be UTC.
sub epoch {
    my ($text) = @_;
    $text =~ /\A(\d{4})-(\d\d)-(\d\d)[T ](\d\d):(\d\d):(\d\d)(?:\.\d+)?(?:Z|\+00:00)?\z/
        or die "not an ISO 8601 UTC time: $text\n";
    return timegm($6, $5, $4, $3, $2 - 1, $1);
}

# ---------------------------------------------------------------------------------------------------------------------
# The curl of the verifier's PATH.
# ---------------------------------------------------------------------------------------------------------------------

# Reads the real IOC and returns its time stamp and value; the diagnostics of the client stay in a separate file.
sub read_ca {
    my ($pv) = @_;
    my $root = $ENV{RANGE_EVIDENCE};
    pipe(my $reader, my $writer) or die "pipe: $!\n";
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        close($reader);
        open(STDOUT, '>&', $writer) or POSIX::_exit(126);
        open(STDERR, '>>', "$root/ca-boundary.err") or POSIX::_exit(126);
        my $caget = "$ENV{RANGE_EPICS}/caget";
        exec { $caget } $caget, '-a', '-f0', '-w', '1', $pv or POSIX::_exit(127);
    }
    close($writer);
    my $line = do { local $/; <$reader> } // '';
    close($reader);
    waitpid($pid, 0);
    die "caget of $pv failed with status " . ($? >> 8) . "\n" if $?;
    my @fields = split ' ', $line;
    return { secs => epoch("$fields[1]T$fields[2]"), val => $fields[3] + 0 };
}

sub answer {
    my ($payload, @args) = @_;
    my $encoded = $JSON->encode($payload);
    for my $i (0 .. $#args) {
        if ($args[$i] eq '--output') {
            spew($args[$i + 1], $encoded);
            print '200';
            return 0;
        }
    }
    print "$encoded\n";
    return 0;
}

sub curl_fixture {
    my (@args) = @_;
    my $url = $args[-1];
    my $root = $ENV{RANGE_EVIDENCE};
    my $mode = $ENV{RANGE_MODE};
    my %query;
    for my $i (0 .. $#args) {
        if ($args[$i] eq '--data-urlencode') {
            my ($key, $value) = split /=/, $args[$i + 1], 2;
            $query{$key} = $value;
        }
    }
    my $payload;
    if ($url =~ m{/archivePV\z}) {
        my ($request) = map { $args[$_ + 1] } grep { $args[$_] eq '--data-binary' } 0 .. $#args;
        my $pv = $JSON->decode(slurp(substr($request, 1)))->[0]{pv};
        $payload = [ { pvName => $pv, status => 'Archive request submitted' } ];
    }
    elsif ($url =~ m{/getPVStatus\z}) {
        my $pv = $query{pv};
        append("$root/observations.jsonl", $JSON->encode(read_ca($pv)) . "\n");
        $payload = [ { pvName => $pv, status => 'Being archived' } ];
    }
    elsif ($url =~ m{/pauseArchivingPV\z}) {
        $payload = { status => 'ok' };
    }
    elsif ($url =~ m{/getData\.json\z}) {
        my @observed = map { $JSON->decode($_) } split /\n/, slurp("$root/observations.jsonl");
        my $first = $observed[0];
        my $last = read_ca($query{pv});
        my $end = epoch($query{to});
        my $bad = $mode eq 'outside';
        my @data = (
            { %{$first}, nanos => 0, severity => 0, status => 0 },
            { %{$last}, secs => ($mode eq 'boundary' || $mode eq 'outside' ? $end : $last->{secs}),
                nanos => ($bad ? 999999999 : 0), severity => 0, status => 0 },
        );
        if ($mode eq 'time-skew') {
            $data[0]{secs} += 1;
            $data[0]{nanos} = 999999999;
        }
        my $name = $mode eq 'wrong-pv' ? "$query{pv}:Wrong" : $query{pv};
        $payload = [ { meta => { name => $name }, data => \@data } ];
        spew("$root/query.json", $JSON->encode(\%query));
        spew("$root/response.json", $JSON->encode($payload));
    }
    else {
        return 7;
    }
    return answer($payload, @args);
}

# ---------------------------------------------------------------------------------------------------------------------
# The test.
# ---------------------------------------------------------------------------------------------------------------------

# Runs the verifier with its output in a file and returns its status; a run longer than the limit is killed and fails.
sub run_verifier {
    my ($env, $log, @command) = @_;
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        %ENV = %{$env};
        open(STDIN, '<', '/dev/null') or POSIX::_exit(126);
        open(STDOUT, '>', $log) or POSIX::_exit(126);
        open(STDERR, '>&', \*STDOUT) or POSIX::_exit(126);
        exec { $command[0] } @command or POSIX::_exit(127);
    }
    my $raw;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 40;
        waitpid($pid, 0);
        $raw = $?;
        alarm 0;
        1;
    } or do {
        my $error = $@;
        alarm 0;
        kill('KILL', $pid);
        waitpid($pid, 0);
        fail('The verifier ran longer than 40 seconds: ' . slurp($log)) if $error eq "timeout\n";
        die $error;
    };
    return ($raw & 127) ? 128 + ($raw & 127) : $raw >> 8;
}

sub run_mode {
    my ($mode, $workspace, $epics, $source) = @_;
    my $evidence = "$workspace/$mode";
    mkdir($evidence) or die "mkdir $evidence: $!\n";
    my %env = (%ENV, PATH => "$workspace:$ENV{PATH}", RANGE_EVIDENCE => $evidence, RANGE_EPICS => $epics,
        RANGE_MODE => $mode);
    my @command = ('bash', "$TOP/scripts/verify-local-pv.bash", '--epics-bin', $epics, '--cleanup', 'stop', '--timeout', '20',
        'http://127.0.0.1:33665/mgmt/bpl', 'http://127.0.0.1:33668/retrieval', $source);
    my $status = run_verifier(\%env, "$evidence/log", @command);
    my $text = slurp("$evidence/log");
    my $expected = ($mode eq 'outside' || $mode eq 'time-skew' || $mode eq 'wrong-pv') ? 1 : 0;
    check($status == $expected, "$mode: status $status, expected $expected: $text");
    check((index($text, 'PV acquisition, storage and retrieval: PASS') >= 0 ? 1 : 0) == ($expected == 0 ? 1 : 0),
        "$mode: the PASS line does not match the status: $text");
    check(index($text, 'Test IOC stopped.') >= 0, "$mode: no stop message: $text");
    my ($retained) = $text =~ /^Evidence: (.*)$/m;
    check(defined $retained, "$mode: no evidence folder printed: $text");
    (my $pid = slurp("$retained/ioc.pid")) =~ s/\s+\z//;
    check(!-e "/proc/$pid", "$mode: the test IOC is still running");
    my $query = $JSON->decode(slurp("$evidence/query.json"));
    my $response = $JSON->decode(slurp("$evidence/response.json"));
    my $upper = epoch($query->{to});
    my @valid = grep { $_->{secs} < $upper || ($_->{secs} == $upper && $_->{nanos} == 0) } @{ $response->[0]{data} };
    check(scalar(@valid) == ($mode eq 'outside' ? 1 : 2), "$mode: " . scalar(@valid) . ' valid samples');
    if ($mode eq 'wrong-pv') {
        check($response->[0]{meta}{name} ne $query->{pv}, "$mode: the answer names the requested PV");
        my $logs = join '', map { slurp($_) } bsd_glob("$retained/extract-*.log");
        check(index($logs, 'does not identify the requested test PV') >= 0, "$mode: the wrong PV was not reported");
    }
    check(scalar(my @retrieved = bsd_glob("$retained/retrieval-*.json")) > 0, "$mode: no retrieval answer was kept");
    print "PASS: $mode; exit=$status; PV and time checks; IOC stopped\n";
    return;
}

sub main {
    my (@arguments) = @_;
    my $help;
    GetOptionsFromArray(\@arguments, 'help' => \$help) or return usage_error();
    if ($help) {
        pod2usage(-verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        return 0;
    }
    return usage_error('unexpected argument: ' . $arguments[0]) if @arguments;
    my $epics = $ENV{AA_TEST_EPICS_BIN};
    die "AA_TEST_EPICS_BIN is required\n" unless defined $epics && $epics ne '';
    my $source = $ENV{AA_TEST_SOURCE_PATH} || "$TOP/epicsarchiverap-maven-src";
    make_path("$TOP/work");
    my $workspace = tempdir('local-pv-range.XXXXXXXX', DIR => "$TOP/work");
    symlink(abs_path($0), "$workspace/curl") or die "symlink: $!\n";
    my $ok = eval {
        run_mode($_, $workspace, $epics, $source) for qw(inside boundary outside time-skew wrong-pv);
        1;
    };
    my $error = $@;
    print "Time range test evidence: $workspace\n";
    die $error unless $ok;
    return 0;
}

sub usage_error {
    my ($message) = @_;
    print STDERR "local-install-pv-range.pl: $message\n" if defined $message;
    pod2usage(-verbose => 0, -exitval => 'NOEXIT', -output => \*STDERR);
    return 2;
}

my $status;
if (basename($0) eq 'curl') {
    $status = eval { curl_fixture(@ARGV) };
    if (!defined $status) {
        print STDERR "local-install-pv-range.pl: $@";
        $status = 1;
    }
    exit $status;
}
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    if ($error =~ s/\AASSERTION: //) {
        print STDERR "FAIL: $error";
        $status = 1;
    }
    else {
        print STDERR "local-install-pv-range.pl: $error";
        $status = 2;
    }
};
exit $status;
