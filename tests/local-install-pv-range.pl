#!/usr/bin/env perl
# Checks the inclusive time bounds of the CSV extraction through the shipped PV verifier and a real soft IOC.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(basename dirname);
use File::Glob qw(bsd_glob);
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP ();
use Pod::Usage qw(pod2usage);
use POSIX ();
use Time::Local qw(timegm);

BEGIN {
    require(dirname(abs_path($0)) . '/lib/ArchiverTest.pm');
    ArchiverTest->import(qw(slurp spew usage_error fail check));
}

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

Four additional cases check a sample below the lower bound, one second plus one nanosecond before its real CA
observation, nonzero alarm severity, and valid JSON returned with a nonzero transport status. Before-range advances
only the initial clock read by five seconds and retains both times; CA timestamps and later clock reads remain
native. The real CA observation selected for the lower-bound sample must be within one second of that sample.

The HTTP transport is replaced: this file runs again as the C<curl> of the verifier's PATH. It reads the real IOC with
the supplied caget for status requests. Data responses use the actual CA records persisted by the verifier, with only
the named fault applied. Upper-edge samples differ by one nanosecond and must stay within one second of the actual
CA observation; the test retains the selected records and query bounds. The same file is the time-range
fixture of tests/local-install-pv-menu.pl. The runs work in a folder local-pv-range.* below TMPDIR,
else below work/scratch/tmp of the checkout, which the test creates when it is missing. A passing run removes it and the
evidence folders of the verifier; a failed run, or KEEP_WORKSPACE=1, keeps them and prints their path.

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
0 when the request was answered, 7 for an unsupported request or an unexposed query edge, 1 when required CA evidence
cannot be read, and 18 for the deliberate transport failure after a valid JSON response.

=cut

my $TOP = abs_path(dirname(abs_path($0)) . '/..');

# The temporary folder: TMPDIR when it names a writable folder, else work/scratch/tmp of the checkout, created when missing.
sub temp_root {
    my $dir = $ENV{TMPDIR};
    return abs_path($dir) if defined $dir && $dir ne '' && -d $dir && -w _;
    my $local = "$TOP/work/scratch/tmp";
    make_path($local);
    -d $local && -w _ or die "cannot create the temporary folder $local\n";
    return abs_path($local);
}

# A folder that this run created below the temporary folder: absolute, not a link, equal to its resolved path.
sub run_folder_is_safe {
    my ($path) = @_;
    return 0 unless defined $path && $path =~ m{\A/} && -d $path && !-l $path;
    my $resolved = abs_path($path);
    my $root = temp_root();
    return defined $resolved && $resolved eq $path && index($path, "$root/") == 0;
}

# Ends a folder of this run: removed after a pass, kept and named after a failure or with KEEP_WORKSPACE=1.
sub finish_workspace {
    my ($path, $passed) = @_;
    return unless defined $path && -e $path;
    if ($passed && ($ENV{KEEP_WORKSPACE} // '') ne '1' && run_folder_is_safe($path)) {
        remove_tree($path);
        return;
    }
    print "Workspace retained: $path\n";
    return;
}

my $JSON = JSON::PP->new->canonical;

$| = 1;

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
    my ($fraction) = $fields[2] =~ /[.](\d+)/;
    my $nanos = substr(($fraction // '') . '000000000', 0, 9) + 0;
    return { secs => epoch("$fields[1]T$fields[2]"), nanos => $nanos, val => $fields[3] + 0 };
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
        spew("$root/verifier-evidence", dirname(substr($request, 1)));
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
        my $folder = slurp("$root/verifier-evidence");
        my @observed = map {
            my ($secs, $value, $nanos) = split /\t/;
            { secs => $secs + 0, val => $value + 0, nanos => $nanos + 0 }
        } split /\n/, slurp("$folder/ca.tsv");
        die "two distinct real CA observations are required\n"
            unless @observed >= 2 && $observed[0]{val} != $observed[-1]{val};
        my $first = $observed[0];
        my $last = $observed[-1];
        my $end = epoch($query{to});
        # Both the exact upper edge and the next nanosecond must match the real CA timestamp within one second.
        # Returning a transport failure lets the verifier collect another actual sample before retrying.
        my $near_edge = $last->{secs} == $end
            || ($last->{secs} == $end - 1 && $last->{nanos} >= 1);
        if (($mode eq 'boundary' || $mode eq 'outside') && !$near_edge) {
            append("$root/edge-not-exposed", "$last->{secs} $end\n");
            return 7;
        }
        spew("$root/response-observations.json", $JSON->encode(\@observed));
        my $bad = $mode eq 'outside';
        # Values and timestamps come from the real caget records persisted by the verifier. The HTTP boundary applies
        # only the named timestamp, identity, alarm or transport fault to those records.
        my @data = (
            { %{$first}, nanos => 0, severity => 0, status => 0 },
            { %{$last}, secs => ($mode eq 'boundary' || $mode eq 'outside' || $last->{secs} > $end ? $end : $last->{secs}),
                nanos => ($bad ? 1 : 0), severity => 0, status => 0 },
        );
        if ($mode eq 'time-skew') {
            $data[0]{secs} += 1;
            $data[0]{nanos} = 999999999;
        }
        if ($mode eq 'before-range') {
            my ($candidate) = grep { $_->{secs} == epoch($query{from}) || $_->{secs} == epoch($query{from}) - 1 } @observed;
            die "no real CA sample exposed the advanced query start\n" unless $candidate;
            spew("$root/lower-observation.json", $JSON->encode($candidate));
            $data[0] = { %{$candidate}, severity => 0, status => 0 };
            $data[0]{secs} = epoch($query{from}) - 1;
            $data[0]{nanos} = 999999999;
        }
        if ($mode eq 'lower-skew') {
            my $observed = $observed[-1];
            die "the real CA timestamp has no fraction for the borrow case\n" unless $observed->{nanos} > 0;
            $data[1] = { %{$observed}, secs => $observed->{secs} - 1,
                nanos => $observed->{nanos} - 1, severity => 0, status => 0 };
        }
        $data[0]{severity} = 1 if $mode eq 'alarm';
        my $name = $mode eq 'wrong-pv' ? "$query{pv}:Wrong" : $query{pv};
        $payload = [ { meta => { name => $name }, data => \@data } ];
        spew("$root/query.json", $JSON->encode(\%query));
        spew("$root/response.json", $JSON->encode($payload));
    }
    else {
        return 7;
    }
    my $status = answer($payload, @args);
    if ($mode eq 'transport-failure' && $url =~ m{/getData\.json\z}) {
        append("$root/transport-status", "18\n");
        return 18;
    }
    return $status;
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
    my %env = (%ENV, PATH => "$workspace:$ENV{PATH}", TMPDIR => temp_root(), RANGE_EVIDENCE => $evidence, RANGE_EPICS => $epics,
        RANGE_MODE => $mode);
    my @command = ('bash', "$TOP/scripts/verify-local-pv.bash", '--epics-bin', $epics, '--cleanup', 'stop', '--timeout', '20',
        'http://127.0.0.1:33665/mgmt/bpl', 'http://127.0.0.1:33668/retrieval', $source);
    my $status = run_verifier(\%env, "$evidence/log", @command);
    my $text = slurp("$evidence/log");
    my $expected = ($mode eq 'inside' || $mode eq 'boundary') ? 0 : 1;
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
    my $lower = epoch($query->{from});
    my @valid = grep { $_->{secs} >= $lower && ($_->{secs} < $upper || ($_->{secs} == $upper && $_->{nanos} == 0)) }
        @{ $response->[0]{data} };
    check(scalar(@valid) == ($mode eq 'outside' || $mode eq 'before-range' ? 1 : 2),
        "$mode: " . scalar(@valid) . ' samples inside the query range');
    my @observed = @{ $JSON->decode(slurp("$evidence/response-observations.json")) };
    if ($mode eq 'before-range') {
        my $observed = $JSON->decode(slurp("$evidence/lower-observation.json"));
        check($observed->{secs} == $lower || $observed->{secs} == $lower - 1,
            'before-range: no real CA sample exposed the lower bound');
        check(-s "$evidence/clock-offset", 'before-range: the clock boundary was not applied');
    }
    if ($mode eq 'lower-skew') {
        check($response->[0]{data}[1]{secs} == $observed[-1]{secs} - 1
            && $response->[0]{data}[1]{nanos} == $observed[-1]{nanos} - 1,
            'lower-skew: the HTTP sample was not one second plus one nanosecond before its real CA observation');
    }
    check(-s "$evidence/transport-status", 'transport-failure: the HTTP boundary did not return status 18')
        if $mode eq 'transport-failure';
    if ($mode eq 'wrong-pv') {
        check($response->[0]{meta}{name} ne $query->{pv}, "$mode: the answer names the requested PV");
        my $logs = join '', map { slurp($_) } bsd_glob("$retained/extract-*.log");
        check(index($logs, 'does not identify the requested test PV') >= 0, "$mode: the wrong PV was not reported");
    }
    check(scalar(my @retrieved = bsd_glob("$retained/retrieval-*.json")) > 0, "$mode: no retrieval answer was kept");
    finish_workspace($retained, 1);
    print "PASS: $mode; exit=$status; PV and time checks; IOC stopped\n";
    return;
}

sub main {
    my (@arguments) = @_;
    my $help;
    GetOptionsFromArray(\@arguments, 'help' => \$help) or return usage_error('local-install-pv-range.pl', __FILE__);
    if ($help) {
        pod2usage(-verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        return 0;
    }
    return usage_error('local-install-pv-range.pl', __FILE__, 'unexpected argument: ' . $arguments[0]) if @arguments;
    my $epics = $ENV{AA_TEST_EPICS_BIN};
    die "AA_TEST_EPICS_BIN is required\n" unless defined $epics && $epics ne '';
    my $source = $ENV{AA_TEST_SOURCE_PATH} || "$TOP/epicsarchiverap-maven-src";
    make_path("$TOP/work");
    my $workspace = tempdir('local-pv-range.XXXXXXXX', DIR => temp_root());
    symlink(abs_path($0), "$workspace/curl") or die "symlink: $!\n";
    my ($date) = grep { -x $_ } map { "$_/date" } split /:/, $ENV{PATH};
    defined $date or die "date is required\n";
    local $ENV{RANGE_DATE} = abs_path($date);
    symlink(abs_path($0), "$workspace/date") or die "symlink date: $!\n";
    my $ok = eval {
        run_mode($_, $workspace, $epics, $source)
            for qw(inside boundary outside time-skew wrong-pv before-range lower-skew alarm transport-failure);
        1;
    };
    my $error = $@;
    finish_workspace($workspace, $ok);
    die $error unless $ok;
    return 0;
}

my $status;
if (basename($0) eq 'date') {
    # Only the initial wall-clock read advances. CA timestamps and later clock reads remain native.
    my $marker = "$ENV{RANGE_EVIDENCE}/clock-offset";
    if ($ENV{RANGE_MODE} eq 'before-range' && join(' ', @ARGV) eq '-u +%s' && !-e $marker) {
        my $actual = time();
        spew($marker, "$actual " . ($actual + 5) . "\n");
        print $actual + 5, "\n";
        exit 0;
    }
    exec { $ENV{RANGE_DATE} } $ENV{RANGE_DATE}, @ARGV or die "exec date: $!\n";
}
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
