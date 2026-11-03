#!/usr/bin/env perl
# Exercises the shipped EPICS preflight and the three local installer entry points without installing anything.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Basename qw(basename dirname);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage qw(pod2usage);
use POSIX ();

=head1 NAME

local-install-epics.pl - check the EPICS preflight of the local installers without installing anything

=head1 SYNOPSIS

  perl tests/local-install-epics.pl
  AA_TEST_EPICS_BIN=<bin/host_arch folder of a real EPICS Base> perl tests/local-install-epics.pl
  perl tests/local-install-epics.pl --help

=head1 DESCRIPTION

Runs scripts/verify-local-pv.bash --check-epics with no Base, with a relative or absent EPICS_BASE, and, when
AA_TEST_EPICS_BIN names the bin/host_arch folder of a real EPICS Base, resolves that folder three ways (EPICS_BASE,
EPICS_BASE with EPICS_HOST_ARCH, and --epics-bin) and rejects an unknown architecture. It then starts each of
scripts/install-local-sqlite.bash, install-local-mariadb-uds.bash and install-local-mariadb-tcp.bash on a
pseudo-terminal, answers its optional PV verification question with y, and requires it to stop before any package,
build or sudo step because the EPICS environment is not prepared. Without AA_TEST_EPICS_BIN the Base resolution is
reported as C<SKIP: real Base binary resolution; AA_TEST_EPICS_BIN is unset.> and the other checks still run.

The pseudo-terminal comes from script(1) of util-linux. Required programs: bash and script; a missing script is an
environment error, reported before any check runs.

=head1 OPTIONS

=over 4

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when every check that ran passed, 1 when a check failed, 2 for a usage error or an environment error.

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

my $capture_dir;
my $capture_count = 0;

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

sub which {
    my ($name) = @_;
    for my $directory (split /:/, $ENV{PATH} // '') {
        next if $directory eq '';
        return "$directory/$name" if -f "$directory/$name" && -x _;
    }
    return;
}

sub shell_quote {
    my ($text) = @_;
    $text =~ s/'/'\\''/g;
    return "'$text'";
}

# Runs one command without a shell. Options: env (a hash reference replacing the environment), cwd, input (standard
# input text) and timeout (seconds). Returns a hash with status (a signal reads as 128 plus its number), stdout and
# stderr.
sub run_command {
    my ($command, %option) = @_;
    my $id = ++$capture_count;
    my ($in_path, $out_path, $err_path) = ("$capture_dir/in.$id", "$capture_dir/out.$id", "$capture_dir/err.$id");
    spew($in_path, $option{input} // '');
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        if (defined $option{cwd}) {
            chdir($option{cwd}) or POSIX::_exit(126);
        }
        %ENV = %{ $option{env} } if $option{env};
        open(STDIN, '<', $in_path) or POSIX::_exit(126);
        open(STDOUT, '>', $out_path) or POSIX::_exit(126);
        open(STDERR, '>', $err_path) or POSIX::_exit(126);
        exec { $command->[0] } @{$command} or POSIX::_exit(127);
    }
    my $raw;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $option{timeout};
        waitpid($pid, 0);
        $raw = $?;
        alarm 0;
        1;
    } or do {
        my $error = $@;
        alarm 0;
        kill('KILL', $pid);
        waitpid($pid, 0);
        die "command timed out after $option{timeout}s: @{$command}\n" if $error eq "timeout\n";
        die $error;
    };
    my $status = ($raw & 127) ? 128 + ($raw & 127) : $raw >> 8;
    return {
        status => $status,
        stdout => slurp($out_path),
        stderr => slurp($err_path),
    };
}

# The EPICS preflight of the shipped verifier, run with the given environment and options.
sub preflight {
    my ($env, @options) = @_;
    return run_command(['bash', "$TOP/scripts/verify-local-pv.bash", '--check-epics', @options],
        env => $env, timeout => 15);
}

# Starts one installer on a pseudo-terminal from script(1), answers its question with y and returns its status and
# the terminal output with carriage returns removed.
sub installer_on_terminal {
    my ($env, $backend) = @_;
    my $entry = "$TOP/scripts/install-local-$backend.bash";
    my $run = run_command(['script', '-q', '-e', '-c', 'bash ' . shell_quote($entry), '/dev/null'],
        env => $env, cwd => $TOP, input => "y\n", timeout => 20);
    (my $output = $run->{stdout} . $run->{stderr}) =~ s/\r//g;
    return ($run->{status}, $output);
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
    defined which('script') or die "the program script of util-linux is required for the pseudo-terminal of the installers\n";
    $capture_dir = tempdir('aa-local-install-epics-XXXXXX', DIR => temp_root(), CLEANUP => 1);
    my %env = %ENV;
    delete @env{qw(EPICS_BASE EPICS_HOST_ARCH)};

    my $result = preflight(\%env);
    check($result->{status} == 1 && index($result->{stderr}, 'Source your EPICS environment setup file') >= 0,
        "No EPICS_BASE did not stop with the setup message: status $result->{status}: $result->{stderr}");
    for my $base ('~/EPICS-env-distribution', '/nonexistent-epics-base') {
        $result = preflight({ %env, EPICS_BASE => $base });
        check($result->{status} == 1 && index($result->{stderr}, 'existing absolute Base directory') >= 0,
            "EPICS_BASE=$base was not refused: status $result->{status}: $result->{stderr}");
    }

    for my $backend (qw(sqlite mariadb-uds mariadb-tcp)) {
        my ($status, $output) = installer_on_terminal(\%env, $backend);
        check($status == 1, "install-local-$backend.bash exited $status: $output");
        check(index($output, 'No installation changes have been made') >= 0, "$backend made no such statement: $output");
        check(index($output, 'Source your EPICS environment setup file') >= 0, "$backend gave no setup message: $output");
        check(index($output, 'Install packages, build') < 0, "$backend reached the installation step: $output");
        check(index($output, '+ sudo') < 0 && index($output, '+ make') < 0, "$backend ran a sudo or make step: $output");
    }

    my $epics_bin = $ENV{AA_TEST_EPICS_BIN};
    if ($epics_bin) {
        my $base = dirname(dirname($epics_bin));
        my $arch = basename($epics_bin);
        for my $case ([{ %env, EPICS_BASE => $base }, ()],
            [{ %env, EPICS_BASE => $base, EPICS_HOST_ARCH => $arch }, ()],
            [\%env, '--epics-bin', $epics_bin]) {
            my ($case_env, @options) = @{$case};
            $result = preflight($case_env, @options);
            (my $printed = $result->{stdout}) =~ s/\A\s+|\s+\z//g;
            check($result->{status} == 0 && $printed eq $epics_bin,
                "The Base was not resolved to $epics_bin: status $result->{status}: $result->{stdout}$result->{stderr}");
        }
        $result = preflight({ %env, EPICS_BASE => $base, EPICS_HOST_ARCH => 'missing-architecture' });
        check($result->{status} == 1 && index($result->{stderr}, 'executable softIoc and caget') >= 0,
            "An unknown architecture was not refused: status $result->{status}: $result->{stderr}");
        print "PASS: EPICS preflight resolves the supplied real Base binaries.\n";
    }
    else {
        print "SKIP: real Base binary resolution; AA_TEST_EPICS_BIN is unset.\n";
    }
    print "PASS: all three installers require EPICS preparation before installation when PV verification is selected.\n";
    return 0;
}

sub usage_error {
    my ($message) = @_;
    print STDERR "local-install-epics.pl: $message\n" if defined $message;
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
        print STDERR "local-install-epics.pl: $error";
        $status = 2;
    }
};
exit $status;
