#!/usr/bin/env perl
# Exercises the shipped PV verifier and a real soft IOC with only the HTTP transport faulted, and sends signals to it.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP ();
use Pod::Usage qw(pod2usage);
use POSIX ();

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

Only the HTTP transport is replaced. The pseudo-terminal comes from script(1) of util-linux. The runs write their
evidence under work/local-pv-signals.* of the checkout, which stays after the run; its path is printed.

Environment: AA_TEST_EPICS_BIN is required; AA_TEST_SOURCE_PATH names the source checkout, by default
epicsarchiverap-maven-src beside the repository. Required programs: bash and script. Required Perl module beyond the
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

sub run_case {
    my ($name, $workspace, $env_base, $epics, $source, %option) = @_;
    my ($initial_signal, $cleanup_signal, $terminal) = @option{qw(initial_signal cleanup_signal terminal)};
    my $register_marker = "$workspace/$name.register";
    my $pause_marker = "$workspace/$name.pause";
    my $log = "$workspace/$name.log";
    my %env = (%{$env_base}, SIGNAL_REGISTER_MARKER => $register_marker, SIGNAL_PAUSE_MARKER => $pause_marker,
        SIGNAL_INITIAL => $initial_signal ? 'yes' : 'no');
    my @command = ('bash', "$TOP/scripts/verify-local-pv.bash", '--epics-bin', $epics, '--cleanup', 'stop', '--timeout', '30',
        'http://127.0.0.1:33665/mgmt/bpl', 'http://127.0.0.1:33668/retrieval', $source);
    if ($terminal) {
        @command = ('script', '--quiet', '--return', '--command', join(' ', map { shell_quote($_) } @command),
            "$workspace/$name.raw");
    }
    my ($child, $ioc_pid, @ioc_identity, $evidence, $code);
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
        wait_marker($pause_marker, $child);
        if ($cleanup_signal) {
            if ($terminal) { send_ctrl_c($child) }
            else { kill($cleanup_signal, $child->{pid}) }
        }
        $code = wait_child($child, 20);
        my $expected = $initial_signal ? 128 + $initial_signal : 1;
        check($code == $expected, "$name: status $code, expected $expected");
        my ($state, $start) = process_identity($ioc_pid);
        check(!defined $state || $state =~ /\A[ZX]\z/ || $start ne $ioc_identity[1], "$name: the test IOC is still running");
        my $answer = eval { JSON::PP->new->decode(slurp("$evidence/pause.json")) };
        check(ref $answer eq 'HASH' && ($answer->{status} // '') eq 'ok', "$name: the pause request was not answered ok");
        my $text = slurp($log);
        check(index($text, 'Test IOC stopped.') >= 0, "$name: no stop message");
        check(index($text, 'Test PV paused:') >= 0, "$name: no pause message");
        check(slurp("$evidence/register.json") eq '', "$name: the refused archive request left a response");
        print "PASS: $name; exit=$code; owned IOC stopped; cleanup messages visible\n";
        1;
    };
    my $error = $@;
    if ($child) {
        if (child_running($child)) {
            kill('TERM', $child->{pid});
            wait_child($child, 20) if !$ok;
            waitpid($child->{pid}, 0) unless defined $child->{status};
        }
        close($child->{stdin}) if $child->{stdin};
    }
    stop_ioc($ioc_pid, $ioc_identity[1]) if defined $ioc_pid && @ioc_identity;
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
    defined which('script') or die "the program script of util-linux is required for the terminal cases\n";
    my $source = $ENV{AA_TEST_SOURCE_PATH} || "$TOP/epicsarchiverap-maven-src";
    make_path("$TOP/work");
    my $workspace = tempdir('local-pv-signals.XXXXXXXX', DIR => "$TOP/work");
    my $boundary = "$workspace/boundary";
    mkdir($boundary) or die "mkdir $boundary: $!\n";
    spew("$boundary/curl", <<'STUB');
#!/bin/bash
case "${*: -1}" in
    */archivePV)
        touch "$SIGNAL_REGISTER_MARKER"
        if [[ "$SIGNAL_INITIAL" == yes ]]; then sleep 3; fi
        exit 7 ;;
    */pauseArchivingPV)
        touch "$SIGNAL_PAUSE_MARKER"
        sleep 3
        printf '%s\n' '{"status":"ok"}' ;;
    *) exit 7 ;;
esac
STUB
    chmod(0700, "$boundary/curl") or die "chmod: $!\n";
    my %env_base = (%ENV, PATH => "$boundary:$ENV{PATH}");
    my $term = POSIX::SIGTERM();
    my $int = POSIX::SIGINT();
    my @cases = (
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
    print "Signal test evidence: $workspace\n";
    die $error unless $ok;
    return 0;
}

sub usage_error {
    my ($message) = @_;
    print STDERR "local-install-pv-signals.pl: $message\n" if defined $message;
    pod2usage(-verbose => 0, -exitval => 'NOEXIT', -output => \*STDERR);
    return 2;
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
