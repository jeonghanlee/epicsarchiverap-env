#!/usr/bin/env perl
# Checks the exported helper contracts through real files, shells, imports and caller POD.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage qw(pod2usage);
use POSIX ();
use Test::More;
use Time::HiRes qw(time);
BEGIN {
    require(dirname(abs_path($0)) . '/lib/ArchiverTest.pm');
    ArchiverTest->import(qw(slurp spew which shell_quote shell_quote_shlex check pause_for usage_error));
}

=head1 NAME

perl-helpers.pl - check the public behavior of the shared Perl test helpers

=head1 SYNOPSIS

  perl tests/perl-helpers.pl
  perl tests/perl-helpers.pl --help

=head1 DESCRIPTION

Runs the real shared helpers against temporary files, a real POSIX shell, fresh Perl imports and the POD of a real
test script. It verifies byte reads and writes, append mode, PATH lookup, both quote formats, scalar prototypes,
failed-regex handling, pause behavior and usage rendering without process exit. No appliance, IOC or database runs.
The temporary directory uses TMPDIR when writable, otherwise work/scratch/tmp of the checkout. A passing run removes
it; a failed run or KEEP_WORKSPACE=1 retains it. Required: Perl 5.26 or newer, Test::More, Time::HiRes, /bin/sh and /dev/full.

=head1 OPTIONS

=over 4

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when every check passes, 1 when an assertion fails, 2 for invalid usage or an environment error.

=cut

my $TESTS = dirname(abs_path($0));
my $LIB = "$TESTS/lib";
my $SHELL = '/bin/sh';
my $WORKSPACE;
my @CALLERS = qw(install-payload.pl health-local.pl database-config.pl config-d.pl local-install-epics.pl
    local-install-pv-menu.pl local-install-pv-range.pl local-install-pv-signals.pl config-d-runtime.pl perl-helpers.pl);

sub run_command {
    my (@command) = @_;
    my $err = File::Temp->new(TMPDIR => 1);
    my $pid = open(my $out, '-|');
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        open(STDERR, '>&', $err) or POSIX::_exit(126);
        exec { $command[0] } @command or POSIX::_exit(127);
    }
    my $stdout = do { local $/; <$out> };
    close($out);
    my $native = $?;
    seek($err, 0, 0) or die "seek $err: $!\n";
    my $stderr = do { local $/; <$err> };
    close($err) or die "close $err: $!\n";
    return { status => ($native & 127) ? 128 + ($native & 127) : $native >> 8,
             stdout => $stdout // '', stderr => $stderr // '' };
}

sub main {
    my (@arguments) = @_;
    my $help;
    GetOptionsFromArray(\@arguments, 'help' => \$help)
        or return usage_error('perl-helpers.pl', __FILE__);
    if ($help) {
        pod2usage(-verbose => 2, -noperldoc => 1, -exitval => 'NOEXIT');
        return 0;
    }
    return usage_error('perl-helpers.pl', __FILE__, 'unexpected argument: ' . $arguments[0]) if @arguments;

    my $root = $ENV{TMPDIR};
    if (!defined $root || $root eq '' || !-d $root || !-w _) {
        $root = dirname($TESTS) . '/work/scratch/tmp';
        make_path($root);
        -d $root && -w _ or die "cannot create the temporary folder $root\n";
    }
    my $temporary = tempdir('archappl-perl-helpers-XXXXXXXX', DIR => abs_path($root), CLEANUP => 0);
    $WORKSPACE = $temporary;
    local $ENV{TMPDIR} = $temporary;
    my $path = "$temporary/byte file";
    my $bytes = "\x00\xff\r\nlast line";
    spew($path, $bytes);
    is(slurp($path), $bytes, 'raw bytes, CRLF and a missing final newline survive');
    spew($path, '');
    is(slurp($path), '', 'an empty file reads as an empty string');
    spew($path, 'first');
    spew($path, ' second', 'append');
    is(slurp($path), 'first second', 'append preserves earlier bytes');
    spew($path, 'replacement');
    is(slurp($path), 'replacement', 'the two-argument write replaces the file');
    spew($path, 'overwrite', 'other');
    is(slurp($path), 'overwrite', 'only the append mode appends');
    my $read_ok = eval { slurp("$temporary/absent"); 1 };
    my $read_error = $@;
    ok(!$read_ok, 'a missing input fails');
    like($read_error, qr/^open \Q$temporary\E\/absent: /, 'the read error names its path');
    my $write_ok = eval { spew("$temporary/absent/output", 'bytes'); 1 };
    my $write_error = $@;
    ok(!$write_ok, 'a missing output parent fails');
    like($write_error, qr/^open \Q$temporary\E\/absent\/output: /, 'the write error names its path');
    my $full_ok = eval { spew('/dev/full', $bytes); 1 };
    my $full_error = $@;
    ok(!$full_ok, 'the actual full device rejects the write');
    like($full_error, qr/^(?:write|close) \/dev\/full: /, 'buffered write failure names its path');

    my $first = "$temporary/first";
    my $second = "$temporary/second directory";
    mkdir($first) or die "mkdir $first: $!\n";
    mkdir($second) or die "mkdir $second: $!\n";
    spew("$first/perl-probe", 'not executable');
    chmod(0644, "$first/perl-probe") or die "chmod $first/perl-probe: $!\n";
    symlink($^X, "$second/perl-probe") or die "symlink $second/perl-probe: $!\n";
    mkdir("$first/directory") or die "mkdir $first/directory: $!\n";
    {
        local $ENV{PATH} = $first;
        ok(!defined which('perl-probe'), 'a non-executable file alone is not a program');
        $ENV{PATH} = ":${first}::${second}:";
        is(which('perl-probe'), "$second/perl-probe", 'PATH search skips non-executable files');
        ok(!defined which('directory'), 'an executable directory is not a program');
        ok(!defined which('missing-program'), 'an absent program returns undef');
        local $ENV{PATH} = '';
        ok(!defined which('perl-probe'), 'an empty PATH has no candidate');
        delete $ENV{PATH};
        ok(!defined which('perl-probe'), 'an unset PATH has no candidate');
    }

    is(shell_quote('safe'), "'safe'", 'the always-quoted form quotes safe text');
    is(shell_quote_shlex('safe'), 'safe', 'the shlex form preserves safe text');
    is(shell_quote("a'b"), q{'a'\''b'}, 'the always-quoted apostrophe format is preserved');
    is(shell_quote_shlex("a'b"), q{'a'"'"'b'}, 'the shlex apostrophe format is preserved');
    my @values = ('', 'safe', 'A_09@%+=:,./-', "a'b", "line one\nline two", q{$HOME; `id` "quoted" \ tail});
    for my $variant ([always => \&shell_quote], [shlex => \&shell_quote_shlex]) {
        for my $index (0 .. $#values) {
            my $result = run_command($SHELL, '-c', 'printf "%s" ' . $variant->[1]->($values[$index]));
            is($result->{status}, 0, "$variant->[0] value $index: shell succeeds");
            is($result->{stdout}, $values[$index], "$variant->[0] value $index: one exact argument");
            is($result->{stderr}, '', "$variant->[0] value $index: no diagnostic");
        }
    }

    is(prototype(\&check), '$$', 'the imported check has two scalar arguments');
    is(prototype(\&ArchiverTest::fail), '$', 'fail has one scalar argument');
    is(\&fail, \&Test::More::fail, 'Test::More retains its fail assertion');
    my $match_ok = eval { check('actual' =~ /absent/, 'failed regex'); 1 };
    my $match_error = $@;
    ok(!$match_ok, 'the actual imported call rejects a failed regex');
    is($match_error, "ASSERTION: failed regex\n", 'the assertion diagnostic is unchanged');
    ok(eval { check('actual' =~ /actual/, 'successful regex'); 1 }, 'the imported call accepts a successful regex');
    my $fail_ok = eval { ArchiverTest::fail('direct failure'); 1 };
    my $fail_error = $@;
    ok(!$fail_ok, 'fail raises an exception');
    is($fail_error, "ASSERTION: direct failure\n", 'fail preserves its exact message');
    my $started = time();
    is(pause_for(0.02), undef, 'pause returns no value');
    cmp_ok(time() - $started, '>=', 0.02, 'pause waits for the supplied duration');

    is(abs_path($INC{"$LIB/ArchiverTest.pm"}), "$LIB/ArchiverTest.pm", 'the module belongs to this checkout');
    my @exports = qw(slurp spew which shell_quote shell_quote_shlex fail check pause_for usage_error);
    my $default = run_command($^X, '-I', $LIB, '-MArchiverTest', '-e',
        'print join(" ", grep { defined &{"main::$_"} } @ARGV)', '--', @exports);
    is($default->{status}, 0, 'a default import compiles');
    is($default->{stdout}, '', 'a default import installs no helper');
    is($default->{stderr}, '', 'a default import has no warning');
    my $unknown = run_command($^X, '-I', $LIB, '-MArchiverTest=unknown_helper', '-e', '1');
    isnt($unknown->{status}, 0, 'an unknown export is refused');
    like($unknown->{stderr}, qr/unknown_helper.*not exported/, 'the refused export is named');
    my $usage = run_command($^X, '-I', $LIB, '-MArchiverTest=usage_error', '-e',
        'my $status = usage_error(@ARGV); print "returned\n"; exit $status', '--',
        'local-install-epics.pl', "$TESTS/local-install-epics.pl", 'bad option');
    is($usage->{status}, 2, 'usage_error returns the usage status');
    is($usage->{stdout}, "returned\n", 'usage_error does not exit the caller');
    like($usage->{stderr}, qr/^local-install-epics\.pl: bad option\n/, 'usage uses the supplied script prefix');
    like($usage->{stderr}, qr/Usage:.*local-install-epics\.pl/s, 'usage renders the real caller POD');
    unlike($usage->{stderr}, qr/ArchiverTest -/, 'usage does not render the module POD');

    my $copied = "$temporary/copied checkout/tests";
    my $missing = "$temporary/missing checkout/tests";
    make_path("$copied/lib", $missing);
    spew("$copied/lib/ArchiverTest.pm", slurp("$LIB/ArchiverTest.pm"));
    {
        local $ENV{PERL5LIB} = $LIB;
        local $ENV{PERL5OPT};
        delete $ENV{PERL5OPT};
        for my $name (@CALLERS) {
            my $source = slurp("$TESTS/$name");
            spew("$missing/$name", $source);
            my $absent = run_command($^X, "$missing/$name", '--help');
            isnt($absent->{status}, 0, "$name: missing local module stops compilation");
            like($absent->{stderr}, qr/Can't locate \Q$missing\/lib\/ArchiverTest.pm\E/,
                "$name: the error names the missing local module");
            is($absent->{stdout}, '', "$name: another checkout cannot supply the missing module");

            spew("$copied/$name", $source);
            my $entry = "$temporary/entry-$name";
            symlink("$copied/$name", $entry) or die "symlink $entry: $!\n";
            my $present = run_command($^X, $entry, '--help');
            is($present->{status}, 0, "$name: the copied module loads through a symlink");
            is($present->{stderr}, '', "$name: the copied import has no warning");
        }
    }

    done_testing();
    return Test::More->builder->is_passing ? 0 : 1;
}

my $status;
eval { $status = main(@ARGV); defined $status or die "main returned no status\n"; 1 } or do {
    my $error = $@;
    print STDERR "perl-helpers.pl: $error";
    $status = 2;
};
if (defined $WORKSPACE) {
    if ($status == 0 && ($ENV{KEEP_WORKSPACE} // '') ne '1') {
        remove_tree($WORKSPACE, {error => \my $errors});
        if (@{$errors}) {
            print STDERR "perl-helpers.pl: cannot remove workspace $WORKSPACE\n";
            $status = 2;
        }
    }
    print "Workspace retained: $WORKSPACE\n" if -d $WORKSPACE;
}
exit $status;
