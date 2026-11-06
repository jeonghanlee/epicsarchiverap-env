#!/usr/bin/env perl
# Exercises the shipped PV verifier with a real soft IOC, real signals, and HTTP/evidence-file faults.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP ();
use Pod::Usage qw(pod2usage);
use POSIX ();
require 'syscall.ph';

BEGIN {
    require(dirname(abs_path($0)) . '/lib/ArchiverTest.pm');
    ArchiverTest->import(qw(slurp spew usage_error which shell_quote fail check pause_for));
}

=head1 NAME

local-install-pv-signals.pl - check the clean-up of the PV verifier when it is interrupted, with a real soft IOC

=head1 SYNOPSIS

  AA_TEST_EPICS_BIN=<bin/host_arch folder of a real EPICS Base> perl tests/local-install-pv-signals.pl
  perl tests/local-install-pv-signals.pl --help

=head1 DESCRIPTION

Runs scripts/verify-local-pv.bash against a real soft IOC of the supplied EPICS Base seven times with a C<curl> on the
PATH that refuses the archive request and delays the pause request, and ends each run in a different way: no signal
(failure-control), SIGTERM or SIGINT while the verifier cleans up (failure-cleanup-term, failure-cleanup-int), SIGTERM or
SIGINT during the registration and again during the clean-up (term-then-term, int-then-int), and Ctrl-C typed on a
pseudo-terminal during the clean-up and during the registration and the clean-up (terminal-cleanup-ctrlc,
terminal-ctrlc-then-ctrlc). Each run must end with the status of the way out (1, or 128 plus the signal number), with the
test IOC (identified by PID and start time) stopped, the pause request answered, and the messages about the stopped IOC
and the paused PV visible.

Three additional cases verify actual cleanup: exit-wait uses Linux ptrace to observe SIGTERM and withhold the real IOC's
exit notification beyond the cleanup polling window; completion must wait for release. Stopped-ioc applies SIGSTOP and verifies
the T state before requiring cleanup through SIGKILL. Missing-pause-evidence moves the real response file aside at
the HTTP boundary and requires an unconfirmed-pause warning without a success message. The archive boundary waits
until the test has observed the actual IOC identity before returning failure.

Only HTTP and the named evidence-file fault are substituted; process signals, waits and the kernel exit event are real.
The pseudo-terminal comes from script(1) of util-linux. The runs work in a folder
local-pv-signals.* below TMPDIR, else below work/scratch/tmp of the checkout, which the test creates when it is missing. A
passing run removes it and the evidence folders of the verifier; a failed run, or KEEP_WORKSPACE=1, keeps them and prints
their path.

Environment: AA_TEST_EPICS_BIN is required; AA_TEST_SOURCE_PATH names the source checkout, by default
epicsarchiverap-maven-src beside the repository. Required programs: bash and script. Linux ptrace access to the test's
own descendant IOC and Perl's syscall.ph are required. Required Perl module beyond the
core of Perl 5.26: none, but on Rocky Linux JSON::PP is the separate package perl-JSON-PP.

=head1 OPTIONS

=over 4

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when every run passed, 1 when a check failed, 2 for a usage error or an environment error.

=cut

my $TOP = abs_path(dirname(abs_path($0)) . '/..');
my $PTRACE_CONT = 7;
my $PTRACE_DETACH = 17;
my $PTRACE_SEIZE = 0x4206;
my $PTRACE_O_TRACEEXIT = 64;
my $PTRACE_EVENT_EXIT = 6;
my $WAIT_ALL = 0x40000000;

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

# State letter and start time of a process; empty when the process is gone. A PID alone does not prove ownership.
sub process_identity {
    my ($pid) = @_;
    my $text = eval { slurp("/proc/$pid/stat") };
    return unless defined $text;
    my $at = rindex($text, ') ');
    return if $at < 0;
    my @fields = split ' ', substr($text, $at + 2);
    return ($fields[0], $fields[19]);
}

# Reaps the child once when it has ended and keeps its status; returns true while it still runs.
sub child_running {
    my ($child) = @_;
    return 0 if defined $child->{status};
    my $result = waitpid($child->{pid}, POSIX::WNOHANG());
    if ($result == $child->{pid}) {
        $child->{status} = ($? & 127) ? 128 + ($? & 127) : $? >> 8;
        return 0;
    }
    return 1;
}

sub wait_marker {
    my ($marker, $child) = @_;
    my $deadline = time() + 40;
    until (-e $marker) {
        fail("Boundary not reached: $marker") if !child_running($child) || time() >= $deadline;
        pause_for(0.05);
    }
    return;
}

# Waits for the child and returns its status; a child that runs longer than the limit is killed and fails the run.
sub wait_child {
    my ($child, $seconds) = @_;
    return $child->{status} if defined $child->{status};
    my $deadline = time() + $seconds;
    while (child_running($child)) {
        if (time() >= $deadline) {
            kill('KILL', $child->{pid});
            waitpid($child->{pid}, 0);
            fail("The verifier did not end within $seconds seconds");
        }
        pause_for(0.05);
    }
    return $child->{status};
}

# Types Ctrl-C on the pseudo-terminal of script(1) through its standard input.
sub send_ctrl_c {
    my ($child) = @_;
    my ($written, $error);
    {
        local $SIG{PIPE} = 'IGNORE';
        $written = syswrite($child->{stdin}, "\x03");
        $error = "$!";
    }
    check(defined $written, "The terminal was closed before Ctrl-C was typed: $error");
    return;
}

sub start_child {
    my ($env, $log, $terminal, @command) = @_;
    my ($in_read, $in_write);
    if ($terminal) {
        pipe($in_read, $in_write) or die "pipe: $!\n";
    }
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        # A parent that ignores SIGINT would pass the ignore on, and the verifier could not trap it.
        $SIG{INT} = 'DEFAULT';
        %ENV = %{$env};
        if ($terminal) {
            close($in_write);
            open(STDIN, '<&', $in_read) or POSIX::_exit(126);
        }
        open(STDOUT, '>', $log) or POSIX::_exit(126);
        open(STDERR, '>&', \*STDOUT) or POSIX::_exit(126);
        exec { $command[0] } @command or POSIX::_exit(127);
    }
    close($in_read) if $terminal;
    return { pid => $pid, stdin => $in_write };
}

sub stop_ioc {
    my ($pid, $start) = @_;
    my ($state, $now) = process_identity($pid);
    return unless defined $state && $now eq $start && $state !~ /\A[ZX]\z/;
    kill('TERM', $pid);
    for (1 .. 50) {
        ($state, $now) = process_identity($pid);
        return if !defined $state || $now ne $start || $state =~ /\A[ZX]\z/;
        pause_for(0.1);
    }
    kill('KILL', $pid);
    return;
}

sub trace_process {
    my ($request, $pid, $signal) = @_;
    syscall(&SYS_ptrace, $request, $pid, 0, $signal) == 0
        or die "ptrace request $request on $pid failed: $!\n";
    return;
}

# Withholds the real IOC exit notification and observes the verifier before releasing it to the parent.
sub check_exit_wait {
    my ($pid, $child, $log, $events) = @_;
    my $deadline = time() + 15;
    my $term = 0;
    while (time() < $deadline) {
        my $waited = waitpid($pid, POSIX::WNOHANG() | $WAIT_ALL);
        if ($waited == $pid) {
            my $status = ${^CHILD_ERROR_NATIVE};
            spew($events, (-e $events ? slurp($events) : '') . "$status\n");
            check(($status & 255) == 127, 'exit-wait: the IOC ended without the required trace stop');
            my $signal = ($status >> 8) & 255;
            if (($status >> 16) == $PTRACE_EVENT_EXIT) {
                check($term, 'exit-wait: no actual SIGTERM was delivered to the owned IOC');
                my $until = time() + 7;
                while (time() < $until) {
                    check(child_running($child) && index(slurp($log), 'Test IOC stopped.') < 0,
                        'exit-wait: the verifier reported completion before the IOC exit was released');
                    pause_for(0.05);
                }
                my ($state) = process_identity($pid);
                check(defined $state && $state =~ /\A[tZ]\z/,
                    'exit-wait: the kernel exit notification was not retained');
                spew("$events.release-state", "$state\n");
                # Some kernels finish SIGKILL while the tracer still owns the unreaped exit notification.
                trace_process($PTRACE_CONT, $pid, 0) if $state eq 't';
                waitpid($pid, $WAIT_ALL);
                return;
            }
            $term = 1 if $signal == POSIX::SIGTERM();
            trace_process($PTRACE_CONT, $pid, $signal);
        }
        pause_for(0.01);
    }
    fail('exit-wait: the real IOC did not reach the kernel exit event');
    return;
}

sub run_case {
    my ($name, $workspace, $env_base, $epics, $source, %option) = @_;
    my ($initial_signal, $cleanup_signal, $terminal) = @option{qw(initial_signal cleanup_signal terminal)};
    my $register_marker = "$workspace/$name.register";
    my $pause_marker = "$workspace/$name.pause";
    my $release_marker = "$workspace/$name.release";
    my $log = "$workspace/$name.log";
    my %env = (%{$env_base}, SIGNAL_REGISTER_MARKER => $register_marker, SIGNAL_PAUSE_MARKER => $pause_marker,
        SIGNAL_INITIAL => $initial_signal ? 'yes' : 'no', SIGNAL_MISSING_EVIDENCE => $option{missing_evidence} ? 'yes' : 'no',
        SIGNAL_RELEASE_MARKER => $release_marker);
    my @command = ('bash', "$TOP/scripts/verify-local-pv.bash", '--epics-bin', $epics, '--cleanup', 'stop', '--timeout', '30',
        'http://127.0.0.1:33665/mgmt/bpl', 'http://127.0.0.1:33668/retrieval', $source);
    if ($terminal) {
        @command = ('script', '--quiet', '--return', '--command', join(' ', map { shell_quote($_) } @command),
            "$workspace/$name.raw");
    }
    my ($child, $ioc_pid, @ioc_identity, $evidence, $code, $traced);
    my $ok = eval {
        $child = start_child(\%env, $log, $terminal, @command);
        wait_marker($register_marker, $child);
        # A pseudo-terminal ends its lines with CR LF, so the path stops at the first CR or LF.
        ($evidence) = slurp($log) =~ /^Evidence: ([^\r\n]*)/m;
        check(defined $evidence, "$name: the verifier printed no evidence folder");
        $ioc_pid = slurp("$evidence/ioc.pid") + 0;
        @ioc_identity = process_identity($ioc_pid);
        check(@ioc_identity && $ioc_identity[0] !~ /\A[ZX]\z/, "$name: the test IOC is not running");
        if ($initial_signal) {
            if ($terminal) { send_ctrl_c($child) }
            else { kill($initial_signal, $child->{pid}) }
        }
        spew($release_marker, "IOC identity observed\n");
        wait_marker($pause_marker, $child);
        if ($option{stopped_ioc}) {
            kill('STOP', $ioc_pid) == 1 or die "stop test IOC: $!\n";
            my $deadline = time() + 2;
            my ($state);
            do { ($state) = process_identity($ioc_pid); pause_for(0.01) }
                while (defined $state && $state ne 'T' && time() < $deadline);
            check(defined $state && $state eq 'T', "$name: SIGSTOP did not reach the actual IOC");
            spew("$workspace/$name.stopped", "$ioc_pid $ioc_identity[1] $state\n");
        }
        if ($option{trace_exit}) {
            trace_process($PTRACE_SEIZE, $ioc_pid, $PTRACE_O_TRACEEXIT);
            $traced = 1;
            check_exit_wait($ioc_pid, $child, $log, "$workspace/$name.trace");
            $traced = 0;
        }
        if ($cleanup_signal) {
            if ($terminal) { send_ctrl_c($child) }
            else { kill($cleanup_signal, $child->{pid}) }
        }
        $code = wait_child($child, 20);
        my $expected = $initial_signal ? 128 + $initial_signal : 1;
        check($code == $expected, "$name: status $code, expected $expected");
        my ($state, $start) = process_identity($ioc_pid);
        check(!defined $state || $state =~ /\A[ZX]\z/ || $start ne $ioc_identity[1], "$name: the test IOC is still running");
        my $text = slurp($log);
        check(index($text, 'Test IOC stopped.') >= 0, "$name: no stop message");
        if ($option{missing_evidence}) {
            check(!-e "$evidence/pause.json" && -e "$evidence/pause-missing.original",
                "$name: the pause evidence was not removed at the filesystem boundary");
            check(index($text, 'WARNING: PV pause was not confirmed') >= 0 && index($text, 'Test PV paused:') < 0,
                "$name: missing pause evidence was not reported as unconfirmed");
        }
        else {
            my $answer = eval { JSON::PP->new->decode(slurp("$evidence/pause.json")) };
            check(ref $answer eq 'HASH' && ($answer->{status} // '') eq 'ok', "$name: the pause request was not answered ok");
            check(index($text, 'Test PV paused:') >= 0, "$name: no pause message");
        }
        check(slurp("$evidence/register.json") eq '', "$name: the refused archive request left a response");
        finish_workspace($evidence, 1);
        print "PASS: $name; exit=$code; owned IOC stopped; cleanup messages visible\n";
        1;
    };
    my $error = $@;
    if ($traced) {
        # Best-effort release while another assertion is already being raised.
        my ($state) = process_identity($ioc_pid);
        if (defined $state && $state eq 'Z') { waitpid($ioc_pid, POSIX::WNOHANG() | $WAIT_ALL) }
        else { syscall(&SYS_ptrace, $PTRACE_DETACH, $ioc_pid, 0, 0) }
    }
    stop_ioc($ioc_pid, $ioc_identity[1]) if defined $ioc_pid && @ioc_identity;
    if ($child) {
        if (child_running($child)) {
            kill('TERM', $child->{pid});
            if (!$ok) {
                eval { wait_child($child, 20); 1 } or do { $error .= "Cleanup: $@" };
            }
            waitpid($child->{pid}, 0) unless defined $child->{status};
        }
        close($child->{stdin}) if $child->{stdin};
    }
    die $error unless $ok;
    return;
}

sub main {
    my (@arguments) = @_;
    my $help;
    GetOptionsFromArray(\@arguments, 'help' => \$help) or return usage_error('local-install-pv-signals.pl', __FILE__);
    if ($help) {
        pod2usage(-verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        return 0;
    }
    return usage_error('local-install-pv-signals.pl', __FILE__, 'unexpected argument: ' . $arguments[0]) if @arguments;
    my $epics = $ENV{AA_TEST_EPICS_BIN};
    die "AA_TEST_EPICS_BIN is required\n" unless defined $epics && $epics ne '';
    defined which('script') or die "the program script of util-linux is required for the terminal cases\n";
    my $source = $ENV{AA_TEST_SOURCE_PATH} || "$TOP/epicsarchiverap-maven-src";
    make_path("$TOP/work");
    my $workspace = tempdir('local-pv-signals.XXXXXXXX', DIR => temp_root());
    my $boundary = "$workspace/boundary";
    mkdir($boundary) or die "mkdir $boundary: $!\n";
    spew("$boundary/curl", <<'STUB');
#!/bin/bash
case "${*: -1}" in
    */archivePV)
        for arg in "$@"; do
            if [[ "$arg" == @*/request.json ]]; then printf '%s\n' "${arg:1}" > "$SIGNAL_REGISTER_MARKER"; fi
        done
        for attempt in {1..100}; do
            [[ ! -e "$SIGNAL_RELEASE_MARKER" ]] || break
            sleep 0.1
        done
        [[ -e "$SIGNAL_RELEASE_MARKER" ]] || exit 7
        if [[ "$SIGNAL_INITIAL" == yes ]]; then sleep 3; fi
        exit 7 ;;
    */pauseArchivingPV)
        touch "$SIGNAL_PAUSE_MARKER"
        sleep 3
        if [[ "$SIGNAL_MISSING_EVIDENCE" == yes ]]; then
            IFS= read -r request < "$SIGNAL_REGISTER_MARKER"
            mv -- "${request%/*}/pause.json" "${request%/*}/pause-missing.original" || exit 7
            exit 0
        fi
        printf '%s\n' '{"status":"ok"}' ;;
    *) exit 7 ;;
esac
STUB
    chmod(0700, "$boundary/curl") or die "chmod: $!\n";
    my %env_base = (%ENV, PATH => "$boundary:$ENV{PATH}", TMPDIR => temp_root());
    my $term = POSIX::SIGTERM();
    my $int = POSIX::SIGINT();
    my @cases = (
        ['exit-wait', trace_exit => 1],
        ['stopped-ioc', stopped_ioc => 1],
        ['missing-pause-evidence', missing_evidence => 1],
        ['failure-control'],
        ['failure-cleanup-term', cleanup_signal => $term],
        ['failure-cleanup-int', cleanup_signal => $int],
        ['term-then-term', initial_signal => $term, cleanup_signal => $term],
        ['int-then-int', initial_signal => $int, cleanup_signal => $int],
        ['terminal-cleanup-ctrlc', cleanup_signal => $int, terminal => 1],
        ['terminal-ctrlc-then-ctrlc', initial_signal => $int, cleanup_signal => $int, terminal => 1],
    );
    my $ok = eval {
        for my $case (@cases) {
            my ($name, %option) = @{$case};
            run_case($name, $workspace, \%env_base, $epics, $source, %option);
        }
        1;
    };
    my $error = $@;
    finish_workspace($workspace, $ok);
    die $error unless $ok;
    return 0;
}

my $status;
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
        print STDERR "local-install-pv-signals.pl: $error";
        $status = 2;
    }
};
exit $status;
