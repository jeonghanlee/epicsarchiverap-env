#!/usr/bin/env perl
# Checks the shipped PV verifier menu with a real IOC and explicit HTTP and process-file boundaries.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(basename dirname);
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use IO::Select;
use Pod::Usage qw(pod2usage);
use POSIX ();

=head1 NAME

local-install-pv-menu.pl - check the test IOC ownership at the keep menu of the PV verifier

=head1 SYNOPSIS

  AA_TEST_EPICS_BIN=<bin/host_arch folder of a real EPICS Base> perl tests/local-install-pv-menu.pl
  perl tests/local-install-pv-menu.pl --help

=head1 DESCRIPTION

Runs scripts/verify-local-pv.bash against a real soft IOC from the supplied EPICS Base on a pseudo-terminal, answers its
keep menu with 2, and checks three ways out: the IOC kept alive and its test PV resumed (keep-live), the IOC stopped by
the test before the answer so the menu run must end without keeping it (menu-exit), and the IOC stopped by the resume
request itself (resume-exit). Each run checks that the process the verifier reports is the soft IOC of the supplied
Base started for the reported test PV, and that the verifier's exit status, messages and the state of that exact process
(identified by its start time, not only its PID) agree with the way out.

Four additional cases check normal stop, rejected resume, a changed process start time and a reported Z state.
Every case requires the final evidence path. Resume failures require the cleanup pause message after the menu,
and normal stop requires a successful native SIGTERM to the owned IOC.

A compiled libc boundary records real kill calls. For the two process identity faults it redirects only the owned
IOC's /proc/PID/stat read to a retained copy with a changed start time or Z state, and records actual fault exposure.
The actual IOC remains live; these cases do not claim actual PID reuse or a real zombie. The verifier must refuse
resume, and the test then stops its own IOC so the verifier can finish waiting.

The HTTP transport is replaced: this file runs again as the C<curl> of the verifier's PATH, answers the resume
request itself and hands every other request to the time-range fixture tests/local-install-pv-range.pl. The
pseudo-terminal comes from script(1) of util-linux. The runs work in a folder local-pv-menu.*
below TMPDIR, else below work/scratch/tmp of the checkout, which the test creates when it is missing. A passing run
removes it and the evidence folders of the verifier; a failed run, or KEEP_WORKSPACE=1, keeps them and prints their path.

Environment: AA_TEST_EPICS_BIN is required; AA_TEST_SOURCE_PATH names the source checkout, by default
epicsarchiverap-maven-src beside the repository. Required programs: bash, script and cc with Linux libc headers and libdl.

=head1 OPTIONS

=over 4

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when every way out passed, 1 when a check failed, 2 for a usage error or an environment error.

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


$| = 1;

sub fail($) {
    my ($message) = @_;
    die "ASSERTION: $message\n";
}

sub check($$) {
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

sub shell_quote {
    my ($text) = @_;
    $text =~ s/'/'\\''/g;
    return "'$text'";
}

sub which {
    my ($name) = @_;
    for my $directory (split /:/, $ENV{PATH} // '') {
        next if $directory eq '';
        return "$directory/$name" if -f "$directory/$name" && -x _;
    }
    return;
}

sub pause_for {
    my ($seconds) = @_;
    select(undef, undef, undef, $seconds);
    return;
}

# State letter and start time of a process; undef when the process is gone.
sub identity {
    my ($pid) = @_;
    my $text = eval { slurp("/proc/$pid/stat") };
    return unless defined $text;
    my $at = rindex($text, ') ');
    return if $at < 0;
    my @fields = split ' ', substr($text, $at + 2);
    return ($fields[0], $fields[19]);
}

# True while the very process (same PID and start time) runs and is not a zombie or dead.
sub alive {
    my ($owned) = @_;
    my ($state, $start) = identity($owned->{pid});
    return defined($state) && $start eq $owned->{start} && $state !~ /\A[ZXx]\z/;
}

sub stop_owned {
    my ($owned) = @_;
    return unless alive($owned);
    kill('TERM', $owned->{pid});
    for (1 .. 100) {
        return unless alive($owned);
        pause_for(0.05);
    }
    fail('Owned test IOC did not stop');
    return;
}

sub read_owned {
    my ($path) = @_;
    my ($pid, $start) = split ' ', slurp($path);
    return { pid => $pid, start => $start };
}

# Interposes only libc file opens and kill; all normal operations still use libc and the real kernel process.
sub build_process_boundary {
    my ($workspace) = @_;
    spew("$workspace/process-boundary.c", <<'C_SOURCE');
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

static int owned_pid(void) {
    const char *root = getenv("RANGE_EVIDENCE");
    char path[4096];
    int pid = 0;
    if (!root) return 0;
    snprintf(path, sizeof(path), "%s/ioc.txt", root);
    FILE *stream = fopen(path, "r");
    if (stream) { if (fscanf(stream, "%d", &pid) != 1) pid = 0; fclose(stream); }
    return pid;
}

static int boundary_open(const char *path, int flags, mode_t mode, const char *symbol) {
    int (*native)(const char *, int, ...) = dlsym(RTLD_NEXT, symbol);
    const char *root = getenv("RANGE_EVIDENCE");
    char target[80], replacement[4096], marker[4096];
    if (root && strncmp(path, "/proc/", 6) == 0) {
        snprintf(target, sizeof(target), "/proc/%d/stat", owned_pid());
        snprintf(replacement, sizeof(replacement), "%s/proc-stat", root);
        if (strcmp(path, target) == 0 && access(replacement, R_OK) == 0) {
            snprintf(marker, sizeof(marker), "%s/fault-read", root);
            FILE *stream = fopen(marker, "a");
            if (stream) { fprintf(stream, "%s\n", path); fclose(stream); }
            return native(replacement, flags, mode);
        }
    }
    return native(path, flags, mode);
}

int open(const char *path, int flags, ...) {
    mode_t mode = 0;
    if (flags & O_CREAT) { va_list ap; va_start(ap, flags); mode = va_arg(ap, int); va_end(ap); }
    return boundary_open(path, flags, mode, "open");
}

int open64(const char *path, int flags, ...) {
    mode_t mode = 0;
    if (flags & O_CREAT) { va_list ap; va_start(ap, flags); mode = va_arg(ap, int); va_end(ap); }
    return boundary_open(path, flags, mode, "open64");
}

int kill(pid_t pid, int signal) {
    int (*native)(pid_t, int) = dlsym(RTLD_NEXT, "kill");
    int result = native(pid, signal), saved = errno;
    const char *root = getenv("RANGE_EVIDENCE");
    if (root && pid == owned_pid()) {
        char path[4096];
        snprintf(path, sizeof(path), "%s/signals", root);
        FILE *stream = fopen(path, "a");
        if (stream) { fprintf(stream, "%d %d %d\n", pid, signal, result); fclose(stream); }
    }
    errno = saved;
    return result;
}
C_SOURCE
    my @command = ('cc', '-shared', '-fPIC', '-Wall', '-Wextra', '-Werror', '-o',
        "$workspace/process-boundary.so", "$workspace/process-boundary.c", '-ldl');
    system { $command[0] } @command;
    die "cannot compile the process boundary (status $?)\n" if $?;
    return "$workspace/process-boundary.so";
}

# The curl of the verifier's PATH: answers the resume request, hands everything else to the time-range fixture.
sub curl_boundary {
    my (@arguments) = @_;
    if ($arguments[-1] =~ m{/resumeArchivingPV\z}) {
        my $root = $ENV{RANGE_EVIDENCE};
        spew("$root/resume-called", "resume\n");
        stop_owned(read_owned("$root/ioc.txt")) if $ENV{MENU_MODE} eq 'resume-exit';
        print $ENV{MENU_MODE} eq 'resume-rejected' ? qq({"status":"error"}\n) : qq({"status":"ok"}\n);
        return 0;
    }
    my $fixture = $ENV{MENU_RANGE_CURL};
    exec { $fixture } $fixture, @arguments or die "exec $fixture: $!\n";
}

# Starts the verifier under script(1); returns the child PID, the handle that writes its terminal input and the handle
# that reads its output.
sub start_on_terminal {
    my ($env, $command) = @_;
    pipe(my $out_read, my $out_write) or die "pipe: $!\n";
    pipe(my $in_read, my $in_write) or die "pipe: $!\n";
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        close($out_read);
        close($in_write);
        %ENV = %{$env};
        open(STDIN, '<&', $in_read) or POSIX::_exit(126);
        open(STDOUT, '>&', $out_write) or POSIX::_exit(126);
        open(STDERR, '>&', $out_write) or POSIX::_exit(126);
        exec { 'script' } 'script', '-q', '-e', '-c', $command, '/dev/null' or POSIX::_exit(127);
    }
    close($out_write);
    close($in_read);
    return ($pid, $in_write, $out_read);
}

# Reads from the handle until the pattern appears, the process ends or the deadline passes; returns the output so far.
sub read_until {
    my ($reader, $pid, $pattern, $seconds, $output) = @_;
    my $select = IO::Select->new($reader);
    my $deadline = time() + $seconds;
    until ($output =~ $pattern) {
        if (waitpid($pid, POSIX::WNOHANG()) == $pid) {
            fail("The verifier ended before the menu: $output");
        }
        fail("The menu did not appear in time: $output") if time() >= $deadline;
        if ($select->can_read(1)) {
            my $count = sysread($reader, my $chunk, 65536);
            fail("The output ended before the menu: $output") unless $count;
            $output .= $chunk;
        }
    }
    return $output;
}

sub run_mode {
    my ($mode, $workspace, $env_base, $epics, $source) = @_;
    my $evidence = "$workspace/$mode";
    mkdir($evidence) or die "mkdir $evidence: $!\n";
    my %env = (%{$env_base}, RANGE_EVIDENCE => $evidence, RANGE_MODE => 'inside', MENU_MODE => $mode);
    my $command = join ' ', map { shell_quote($_) } 'bash', "$TOP/scripts/verify-local-pv.bash", '--epics-bin', $epics,
        '--timeout', '40', 'http://127.0.0.1:33665/mgmt/bpl', 'http://127.0.0.1:33668/retrieval', $source;
    my ($pid, $writer, $reader) = start_on_terminal(\%env, $command);
    my ($owned, $status, $verifier_evidence);
    my $ok = eval {
        my $output = read_until($reader, $pid, qr/Select \[1\/2\]:/, 60, '');
        (my $plain = $output) =~ s/\r//g;
        my ($retained) = $plain =~ /^Evidence: (.*)$/m;
        check(defined $retained, "The verifier printed no evidence folder: $plain");
        $verifier_evidence = $retained;
        my $ioc_pid = slurp("$retained/ioc.pid") + 0;
        my ($state, $start) = identity($ioc_pid);
        check(defined $state && $state !~ /\A[ZXx]\z/, 'The reported IOC is not running');
        $owned = { pid => $ioc_pid, start => $start };
        (my $pv = slurp("$retained/pvs.txt")) =~ s/\s+\z//;
        check(readlink("/proc/$ioc_pid/exe") eq abs_path("$epics/softIoc"), 'The reported process is not the softIoc of the supplied Base');
        my @args = split /\0/, slurp("/proc/$ioc_pid/cmdline");
        (my $prefix = $pv) =~ s/Value\z//;
        check(scalar(grep { $_ eq "P=$prefix" } @args), "The IOC was not started for the test PV $pv");
        spew("$evidence/ioc.txt", "$ioc_pid $start\n");
        if ($mode =~ /^owner-/) {
            my $stat = slurp("/proc/$ioc_pid/stat");
            my $at = rindex($stat, ') ') + 2;
            my @fields = split ' ', substr($stat, $at);
            if ($mode eq 'owner-start') { $fields[19]++ }
            else { $fields[0] = 'Z' }
            spew("$evidence/proc-stat", substr($stat, 0, $at) . join(' ', @fields) . "\n");
            check(alive($owned), "$mode: the actual IOC stopped before the file fault");
        }
        stop_owned($owned) if $mode eq 'menu-exit';
        # Only this write ignores SIGPIPE, so that a verifier that has already ended is reported; the children started
        # earlier keep the default disposition.
        my ($written, $write_error);
        {
            local $SIG{PIPE} = 'IGNORE';
            $written = syswrite($writer, $mode eq 'menu-stop' ? "1\n" : "2\n");
            $write_error = "$!";
        }
        check(defined $written, "The verifier ended before its menu was answered: $write_error");
        my $select = IO::Select->new($reader);
        my $deadline = time() + 25;
        my $ended = 0;
        while (time() < $deadline) {
            if ($select->can_read(1)) {
                my $count = sysread($reader, my $chunk, 65536);
                if (!$count) {
                    $ended = 1;
                    last;
                }
                $output .= $chunk;
                # A rejected process identity intentionally prevents the verifier from signalling that PID.
                stop_owned($owned) if $mode =~ /^owner-/ && $output =~ /ERROR: Test IOC stopped while waiting/;
            }
        }
        check($ended, "The verifier did not end within 25 seconds: $output");
        waitpid($pid, 0);
        my $raw = $?;
        $status = ($raw & 127) ? 128 + ($raw & 127) : $raw >> 8;
        $pid = undef;
        (my $text = $output) =~ s/\r//g;
        spew("$evidence/log", $text);
        check(-s "$evidence/fault-read", "$mode: the verifier did not read the altered process file")
            if $mode =~ /^owner-/;
        check($text =~ /Evidence: \Q$retained\E\n\z/, "$mode: no final evidence path: $text");
        check(index($text, 'PV acquisition, storage and retrieval: PASS') >= 0, "The PV round trip did not pass: $text");
        if ($mode eq 'keep-live') {
            check($status == 0 && index($text, 'IOC retained: PID') >= 0, "keep-live: status $status: $text");
            check(alive($owned), 'The kept IOC is not running');
            check(-f "$evidence/resume-called", 'The resume request was not made');
        }
        else {
            my $expected = $mode eq 'menu-stop' ? 0 : 1;
            check($status == $expected && index($text, 'IOC retained: PID') < 0, "$mode: status $status: $text");
            check(!alive($owned), "$mode: the IOC is still running");
            check(index($text, 'Test IOC stopped.') >= 0, "$mode: no stop message: $text");
            check((-e "$evidence/resume-called" ? 1 : 0) == ($mode =~ /^resume-/ ? 1 : 0),
                "$mode: unexpected resume request state");
            my $after_menu = substr($text, index($text, 'Select [1/2]:'));
            check(index($after_menu, 'Test PV paused:') >= 0, "$mode: no cleanup pause message: $text")
                if $mode =~ /^resume-/;
            if ($mode eq 'menu-stop') {
                my $signals = -f "$evidence/signals" ? slurp("$evidence/signals") : '';
                check($signals =~ /^\Q$ioc_pid\E 15 0$/m, 'menu-stop: no successful native SIGTERM to the owned IOC');
            }
        }
        print "PASS: $mode; exit=$status; owned IOC state checked\n";
        1;
    };
    my $error = $@;
    if (defined $pid) {
        kill('TERM', $pid);
        waitpid($pid, 0);
    }
    close($writer);
    close($reader);
    stop_owned($owned) if $owned;
    finish_workspace($verifier_evidence, 1) if $ok;
    die $error unless $ok;
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
    defined which('script') or die "the program script of util-linux is required for the pseudo-terminal of the verifier\n";
    my $source = $ENV{AA_TEST_SOURCE_PATH} || "$TOP/epicsarchiverap-maven-src";
    make_path("$TOP/work");
    my $workspace = tempdir('local-pv-menu.XXXXXXXX', DIR => temp_root());
    my $boundary = "$workspace/boundary";
    mkdir($boundary) or die "mkdir $boundary: $!\n";
    symlink(abs_path($0), "$boundary/curl") or die "symlink: $!\n";
    my $fixture = "$workspace/range";
    mkdir($fixture) or die "mkdir $fixture: $!\n";
    symlink("$TOP/tests/local-install-pv-range.pl", "$fixture/curl") or die "symlink: $!\n";
    my $process_boundary = build_process_boundary($workspace);
    my %env_base = (%ENV, PATH => "$boundary:$ENV{PATH}", TMPDIR => temp_root(), RANGE_EPICS => $epics,
        MENU_RANGE_CURL => "$fixture/curl", LD_PRELOAD => $process_boundary);
    my $ok = eval {
        run_mode($_, $workspace, \%env_base, $epics, $source)
            for qw(keep-live menu-stop menu-exit resume-exit resume-rejected owner-start owner-zombie);
        1;
    };
    my $error = $@;
    finish_workspace($workspace, $ok);
    die $error unless $ok;
    return 0;
}

sub usage_error {
    my ($message) = @_;
    print STDERR "local-install-pv-menu.pl: $message\n" if defined $message;
    pod2usage(-verbose => 0, -exitval => 'NOEXIT', -output => \*STDERR);
    return 2;
}

my $status;
if (basename($0) eq 'curl') {
    $status = eval { curl_boundary(@ARGV) };
    if (!defined $status) {
        print STDERR "local-install-pv-menu.pl: $@";
        $status = 7;
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
        print STDERR "local-install-pv-menu.pl: $error";
        $status = 2;
    }
};
exit $status;
