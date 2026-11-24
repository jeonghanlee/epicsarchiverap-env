#!/usr/bin/env perl
# Checks the frame feeder of the array cases through its command line against ImageMagick, real Java and a real soft IOC.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
use Pod::Usage qw(pod2usage);
use POSIX ();
use Test::More;
use Time::HiRes qw(sleep);

=head1 NAME

heap-feed-frames.pl - check tests/heap/feed-frames.py

=head1 SYNOPSIS

  perl tests/heap-feed-frames.pl [--maven DIR] [--tool FILE]
  AA_TEST_EPICS_BIN=<bin/host_arch folder> perl tests/heap-feed-frames.pl --maven DIR [--laser-frame FILE]
  perl tests/heap-feed-frames.pl --help

=head1 DESCRIPTION

Runs the real feeder as a subprocess. The usage and input cases need no other tool. The decoding cases compare the pixels of
C<laser.png> and C<airy.png> (the folder C<src/test/js/analyzer/reference/images> of the C<--maven> checkout) with the 8-bit gray
stream that ImageMagick C<convert> writes, and compare the SHA-256 that the feeder prints with C<sha256sum> of the file it wrote. The
Java case runs the C<imageFrame> method, copied text for text from C<AnalyzerFixtureData.java> of the checkout, and C<java.util.Random>
under the real Java, and compares the first normal values and the SHA-256 of the C<bound> frame. The IOC cases need softioc, numpy and
the EPICS tools (C<AA_TEST_EPICS_BIN>): they start a real soft IOC on a private Channel Access port, read the C<laser> waveform back with
C<caget> and C<camonitor>, and compare the elements, the field type, the element count, the timestamps and the log of the feeder. A case
whose tool or input is missing is skipped with its reason.

The temporary directory is removed after the run. Required: Perl 5.26 or newer, Test::More, JSON::PP, Digest::SHA, python3, Linux.

=head1 OPTIONS

=over 4

=item B<--maven> DIR

The C<epicsarchiverap-maven> checkout that holds the PNG files and C<AnalyzerFixtureData.java>.

=item B<--tool> FILE

The feeder to check (default C<tests/heap/feed-frames.py> of this checkout).

=item B<--laser-frame> FILE

The laser frame (1405025 elements as unsigned 16-bit little-endian values) that the IOC cases compare the read-back elements and the
logged SHA-256 with. Give a file that was written and checked elsewhere against ImageMagick (the decoding cases on a host that has it);
without it the cases compare with the output of the feeder itself, which cannot see an error that changes both in the same way.

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when every executed check passes, 1 when an assertion fails, 2 for invalid usage or an environment error.

=cut

my $TESTS = dirname(abs_path($0));
my $REPOSITORY = dirname($TESTS);
my $TOOL = "$REPOSITORY/tests/heap/feed-frames.py";
my $MAVEN;
my $LASER_FRAME;
my $IMAGES_FOLDER = 'src/test/js/analyzer/reference/images';
my $FIXTURE_SOURCE = 'src/test/org/epics/archiverappliance/retrieval/AnalyzerFixtureData.java';
my $CA_PORT = 5164;
my $PERIOD = 2;
my $MONITOR_UPDATES = 3;
my $MINIMUM_ROWS = 3;
my $MONITOR_TIMEOUT = 60;
my $PERIOD_TOLERANCE = 0.6;
my $LASER_ELEMENTS = 1405025;

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
    return run_command('python3', '-I', $TOOL, @arguments);
}

sub slurp_bytes {
    my ($path) = @_;
    open(my $handle, '<:raw', $path) or die "open $path: $!\n";
    my $data = do { local $/; <$handle> };
    close($handle) or die "close $path: $!\n";
    return $data;
}

sub sha256_of {
    my ($path) = @_;
    return Digest::SHA->new(256)->addfile($path, 'b')->hexdigest;
}

sub have {
    my ($program) = @_;
    my ($status) = run_command('sh', '-c', "command -v $program");
    return $status == 0;
}

sub main {
    my (@arguments) = @_;
    my $help;
    GetOptionsFromArray(\@arguments, 'help' => \$help, 'tool=s' => \$TOOL, 'maven=s' => \$MAVEN, 'laser-frame=s' => \$LASER_FRAME) or pod2usage(-exitval => 2, -verbose => 0);
    if ($help) {
        pod2usage(-exitval => 'NOEXIT', -verbose => 99, -sections => [qw(NAME SYNOPSIS DESCRIPTION OPTIONS)], -output => \*STDOUT);
        return 0;
    }
    -f $TOOL or die "$TOOL: no such file\n";
    have('python3') or die "python3 is required\n";
    my $base = $ENV{TMPDIR} && -w $ENV{TMPDIR} ? $ENV{TMPDIR} : "$REPOSITORY/work/scratch/tmp";
    make_path($base);
    my $dir = tempdir('heap-feed-frames.XXXXXX', DIR => $base, CLEANUP => 1);
    my $images = defined $MAVEN ? "$MAVEN/$IMAGES_FOLDER" : undef;

    # Usage and input statuses.
    my ($status, $stdout, $stderr) = run_tool('--help');
    is($status, 0, 'help: exit status');
    ($status, $stdout, $stderr) = run_tool();
    is($status, 2, 'no command: exit status');
    ($status, $stdout, $stderr) = run_tool('serve', '--names', 'nonsense', '--period', '1', '--log', "$dir/x.csv");
    is($status, 2, 'serve with an unknown frame name: exit status');
    {
        local $ENV{EPICS_CA_MAX_ARRAY_BYTES} = '16384';
        ($status, $stdout, $stderr) = run_tool('serve', '--names', 'laser', '--period', '1', '--log', "$dir/x.csv", '--images', $images // '/nonexistent');
        ok(($status == 2 && $stderr =~ /EPICS_CA_MAX_ARRAY_BYTES must be at least 5620100/) ? 1 : 0, 'serve with a too small array limit: refused with the needed size');
    }
    ($status, $stdout, $stderr) = run_tool('frame', '--name', 'laser', '--output', "$dir/laser.u16");
    ok(($status == 77 && $stderr =~ /--images is required for laser/) ? 1 : 0, 'frame laser without --images: input error');
    ($status, $stdout, $stderr) = run_tool('frame', '--name', 'bound', '--output', "$dir/no-such-folder/bound.u16");
    is($status, 1, 'frame to an unwritable path: write error status');

    SKIP: {
        my ($modules) = run_command('python3', '-c', 'import softioc, numpy');
        skip 'softioc and numpy are installed, so the missing module case cannot occur here', 1 if $modules == 0;
        local $ENV{EPICS_CA_MAX_ARRAY_BYTES} = '24000000';
        ($status, $stdout, $stderr) = run_command('python3', $TOOL, 'serve', '--names', 'bound', '--period', '1', '--log', "$dir/modules.csv");
        ok(($status == 77 && $stderr =~ /serve needs the Python modules softioc and numpy/ && $stderr !~ /Traceback/) ? 1 : 0,
            'serve without softioc or numpy: input error with the modules named and no traceback');
    }

    SKIP: {
        skip 'no --maven checkout with the PNG files', 6 unless defined $images && -f "$images/laser.png";
        # Decoding against ImageMagick.
        SKIP: {
            skip 'ImageMagick convert is not installed', 4 unless have('convert');
            for my $name (qw(laser airy)) {
                ($status, $stdout, $stderr) = run_tool('frame', '--name', $name, '--images', $images, '--output', "$dir/$name.u16");
                my ($pin) = decode_json($stdout || '{}');
                my ($cstatus, $cout) = run_command('convert', "$images/$name.png", '-depth', '8', "gray:$dir/$name.gray");
                my $feeder = $status == 0 ? slurp_bytes("$dir/$name.u16") : '';
                my $gray = -f "$dir/$name.gray" ? slurp_bytes("$dir/$name.gray") : '';
                my $low = join('', map { substr($feeder, $_ * 2, 1) } 0 .. length($gray) - 1);
                ok(($status == 0 && length($gray) > 0 && $low eq $gray && length($feeder) == 2 * length($gray)) ? 1 : 0,
                    "$name: the pixels equal the gray stream of ImageMagick and the frame has two bytes per pixel");
                is($pin->{sha256}, -f "$dir/$name.u16" ? sha256_of("$dir/$name.u16") : '', "$name: the printed SHA-256 is that of the written file");
            }
        }
        # Files that are not usable PNG files.
        write_bytes("$dir/truncated.png", substr(slurp_bytes("$images/laser.png"), 0, 5000));
        run_command('convert', '-size', '1307x1075', 'xc:red', "$dir/rgb.png");
        mkdir "$dir/bad" or die "mkdir $dir/bad: $!\n";
        rename "$dir/truncated.png", "$dir/bad/laser.png" or die "rename: $!\n";
        ($status, $stdout, $stderr) = run_tool('frame', '--name', 'laser', '--images', "$dir/bad", '--output', "$dir/out.u16");
        is($status, 77, 'a truncated PNG file: input error status');
        SKIP: {
            skip 'ImageMagick convert is not installed', 1 unless have('convert') && -f "$dir/rgb.png";
            mkdir "$dir/rgbdir" or die "mkdir $dir/rgbdir: $!\n";
            rename "$dir/rgb.png", "$dir/rgbdir/laser.png" or die "rename: $!\n";
            ($status, $stdout, $stderr) = run_tool('frame', '--name', 'laser', '--images', "$dir/rgbdir", '--output', "$dir/out.u16");
            ok(($status == 77 && $stderr =~ /only gray 8-bit PNG files/) ? 1 : 0, 'a colour PNG file: input error with the supported form named');
        }
    }

    # The bound frame and java.util.Random against the real Java.
    SKIP: {
        skip 'no java or no --maven checkout with AnalyzerFixtureData.java', 2 unless defined $MAVEN && -f "$MAVEN/$FIXTURE_SOURCE" && have('java');
        my $source = slurp_bytes("$MAVEN/$FIXTURE_SOURCE");
        my ($method) = $source =~ /(    static int\[\] imageFrame\(.*?\n    \}\n)/s;
        skip 'imageFrame was not found in AnalyzerFixtureData.java', 2 unless defined $method;
        my $java = <<"JAVA";
import java.util.Random; import java.security.MessageDigest; import java.nio.ByteBuffer; import java.nio.ByteOrder;
public class Oracle {
$method
    public static void main(String[] args) throws Exception {
        Random g = new Random(20261113L);
        StringBuilder text = new StringBuilder();
        for (int i = 0; i < 6; i++) text.append(g.nextGaussian()).append(' ');
        Random r = new Random(20261113L);
        int[] p = imageFrame(2560, 2160, 40000.0, 500.0, 1280.0, 1080.0, 160.0, 90.0, 10.0, r);
        ByteBuffer bb = ByteBuffer.allocate(p.length * 2).order(ByteOrder.LITTLE_ENDIAN);
        for (int v : p) bb.putShort((short) v);
        StringBuilder hex = new StringBuilder();
        for (byte x : MessageDigest.getInstance("SHA-256").digest(bb.array())) hex.append(String.format("%02x", x));
        System.out.println("gauss " + text);
        System.out.println("sha256 " + hex);
    }
}
JAVA
        make_path("$dir/java");
        write_bytes("$dir/java/Oracle.java", $java);
        my ($jstatus, $jout, $jerr) = run_command('sh', '-c', "cd '$dir/java' && java Oracle.java");
        my ($gauss) = $jout =~ /^gauss (.*?) *$/m;
        my ($sha) = $jout =~ /^sha256 (\w+)$/m;
        ($status, $stdout, $stderr) = run_tool('frame', '--name', 'bound', '--output', "$dir/bound.u16");
        my $pin = $status == 0 ? decode_json($stdout) : {};
        ok((defined $sha && ($pin->{sha256} // '') eq $sha) ? 1 : 0, 'bound: the SHA-256 of the frame equals that of the real Java imageFrame with java.util.Random');
        my ($pstatus, $pout) = run_command('python3', '-I', '-c', 'import importlib.util,sys; s=importlib.util.spec_from_file_location("ff", sys.argv[1]); m=importlib.util.module_from_spec(s); s.loader.exec_module(m); r=m.JavaRandom(20261113); print(" ".join(repr(r.next_gaussian()) for _ in range(6)))', $TOOL);
        chomp $pout;
        ok((defined $gauss && $pout eq $gauss) ? 1 : 0, 'the first six normal values of the port equal those of the real java.util.Random');
    }

    # A real soft IOC read back with the EPICS tools.
    SKIP: {
        my $bin = $ENV{AA_TEST_EPICS_BIN};
        skip 'AA_TEST_EPICS_BIN is not set', 5 unless defined $bin && -x "$bin/caget" && -x "$bin/camonitor";
        my ($istatus) = run_command('python3', '-c', 'import softioc, numpy');    # softioc may live in the user site, which -I hides
        skip 'softioc or numpy is not installed', 5 unless $istatus == 0;
        skip 'no --maven checkout with the PNG files', 5 unless defined $images && -f "$images/laser.png";
        my $log = "$dir/frames.csv";
        local $ENV{EPICS_CAS_SERVER_PORT} = $CA_PORT;
        local $ENV{EPICS_CA_SERVER_PORT} = $CA_PORT;
        local $ENV{EPICS_CAS_INTF_ADDR_LIST} = '127.0.0.1';
        local $ENV{EPICS_CAS_AUTO_BEACON_ADDR_LIST} = 'NO';
        local $ENV{EPICS_CA_MAX_ARRAY_BYTES} = '24000000';
        local $ENV{EPICS_CA_ADDR_LIST} = "127.0.0.1:$CA_PORT";
        local $ENV{EPICS_CA_AUTO_ADDR_LIST} = 'NO';
        my $pid = fork();
        defined $pid or die "fork: $!\n";
        if ($pid) {
            push @CHILDREN, $pid;
        }
        if (!$pid) {
            open(STDOUT, '>', "$dir/ioc.out") or POSIX::_exit(126);
            open(STDERR, '>&', \*STDOUT) or POSIX::_exit(126);
            {
                no warnings 'exec';
                exec { 'python3' } 'python3', $TOOL, 'serve', '--names', 'laser', '--period', $PERIOD,
                    '--log', $log, '--images', $images, '--prefix', 'HEAPTEST:';
            }
            POSIX::_exit(127);
        }
        my $ready = 0;
        for (1 .. 60) {
            sleep(0.5);
            my ($cs, $co) = run_command("$bin/caget", '-t', '-g10', '-w', '1', 'HEAPTEST:LASER.NELM');
            if ($cs == 0 && $co =~ /^\s*$LASER_ELEMENTS\s*$/) { $ready = 1; last }
        }
        my ($monitor_status, $monitor) = run_command('timeout', $MONITOR_TIMEOUT, "$bin/camonitor", '-t', 's', "-#$MONITOR_UPDATES", 'HEAPTEST:LASER');
        my ($gstatus, $got) = run_command('timeout', $MONITOR_TIMEOUT, "$bin/caget", '-t', 'HEAPTEST:LASER');
        my ($fstatus, $ftvl) = run_command('timeout', $MONITOR_TIMEOUT, "$bin/caget", '-t', '-S', 'HEAPTEST:LASER.FTVL');
        kill('TERM', $pid);
        waitpid($pid, 0);
        ok($ready ? 1 : 0, 'the IOC serves HEAPTEST:LASER with 1405025 elements');
        my ($count, @values) = split ' ', $got;
        my $frame_file = $LASER_FRAME // "$dir/laser-ioc.u16";
        run_tool('frame', '--name', 'laser', '--images', $images, '--output', $frame_file) unless defined $LASER_FRAME;
        my $expected = -f $frame_file ? slurp_bytes($frame_file) : '';
        my @expected = unpack('v*', $expected);
        ok((defined $count && $count == $LASER_ELEMENTS && @values == @expected && !grep({ $values[$_] != $expected[$_] } 0 .. $#expected)) ? 1 : 0,
            'the elements read back with caget equal the elements of the frame');
        like($ftvl // '', qr/USHORT/, 'the record has the field type USHORT');
        my @times;
        for my $line (split /\n/, $monitor) {
            my ($seconds) = $line =~ /^\S+\s+\d{4}-\d\d-\d\d (\d\d):(\d\d):(\d\d\.\d+)/ ? ($1 * 3600 + $2 * 60 + $3) : ();
            push @times, $seconds if defined $seconds;
        }
        my @gaps = map { $times[$_] - $times[$_ - 1] } 1 .. $#times;
        ok((@times >= 2 && !grep { abs($_ - $PERIOD) > $PERIOD_TOLERANCE } @gaps) ? 1 : 0,
            'the IOC timestamps of the publications are about the period apart');
        my @rows = -f $log ? map { [ split /,/ ] } split(/\n/, slurp_bytes($log)) : ();
        shift @rows;
        my $pin = -f $frame_file ? sha256_of($frame_file) : '';
        ok((@rows >= $MINIMUM_ROWS && !grep { $_->[4] ne $pin || $_->[3] != $LASER_ELEMENTS } @rows) ? 1 : 0,
            'the log has at least three rows, each with the element count and the SHA-256 of the frame');
    }
    done_testing();
    return 0;
}

sub write_bytes {
    my ($path, $bytes) = @_;
    make_path(dirname($path));
    open(my $handle, '>:raw', $path) or die "open $path: $!\n";
    print {$handle} $bytes or die "write $path: $!\n";
    close($handle) or die "close $path: $!\n";
    return;
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    print STDERR "heap-feed-frames: $error";
    $status = 2;
};
$status = 1 if !$status && !Test::More->builder->is_passing;
exit $status;
