#!/usr/bin/env perl
# Checks the shipped heap input inspector through its command line against real temporary Git repositories.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage qw(pod2usage);
use POSIX ();
use Test::More;

BEGIN {
    require(dirname(abs_path($0)) . '/lib/ArchiverTest.pm');
    ArchiverTest->import(qw(slurp spew usage_error));
}

=head1 NAME

heap-inspect-inputs.pl - check the exit statuses and diagnostics of tests/heap/inspect-inputs.pl

=head1 SYNOPSIS

  perl tests/heap-inspect-inputs.pl
  AA_HEAP_SOAK_REPO=<ansible-provision checkout> AA_HEAP_SOAK_REF=<full commit ID> perl tests/heap-inspect-inputs.pl
  perl tests/heap-inspect-inputs.pl --help

=head1 DESCRIPTION

Runs the real inspector as a subprocess against temporary Git repositories created by the real git command. The
cases cover a missing option (status 2), a malformed and a mismatched source ref (status 77), a dirty source
directory with an ASCII and with a non-UTF-8 file name (status 77, dirty diagnostic), and the diagnostics of a
repository that holds real preserved soak inputs. The non-UTF-8 case runs git with core.quotePath=false so that git
prints the raw name bytes.

When AA_HEAP_SOAK_REPO and AA_HEAP_SOAK_REF name a real preserved soak checkout, the test also exports its tracked
source directory into a temporary repository with git archive, requires the unchanged copy to pass (status 0), and
then applies one change per copy to real input (an altered fixture, a missing required file, an untracked checksum
list, a duplicate checksum entry and a combined fixture that differs with consistent checksums); each change must end
with status 77 and its own diagnostic. When AA_HEAP_REFERENCE_TOOL names another implementation of the inspector, every
run except the non-UTF-8 file name case is repeated with it and the exit status, the stdout bytes and, for status 77, the stderr text must agree.

The temporary directory uses TMPDIR when writable, otherwise work/scratch/tmp of the checkout; it is removed after the
run. Required: Perl 5.26 or newer, Test::More, Digest::SHA, git and tar in PATH.

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
my $TOOL = "$REPOSITORY/tests/heap/inspect-inputs.pl";
my $REFERENCE = $ENV{AA_HEAP_REFERENCE_TOOL};
my $SOURCE_DIRECTORY = 'tests/archiver-soak';

sub run_command {
    my ($environment, @command) = @_;
    my $error_file = File::Temp->new;
    my $pid = open(my $out, '-|');
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        open(STDERR, '>&', $error_file) or POSIX::_exit(126);
        @ENV{ keys %{$environment} } = values %{$environment};
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

sub git_environment {
    return {
        GIT_CONFIG_GLOBAL => '/dev/null',
        GIT_CONFIG_SYSTEM => '/dev/null',
        GIT_AUTHOR_NAME => 'fixture', GIT_AUTHOR_EMAIL => 'fixture@example.invalid',
        GIT_COMMITTER_NAME => 'fixture', GIT_COMMITTER_EMAIL => 'fixture@example.invalid',
    };
}

sub git_ok {
    my ($repository, @arguments) = @_;
    my ($status, $stdout, $stderr) = run_command(git_environment(), 'git', '-C', $repository, @arguments);
    $status == 0 or die "git @arguments failed with $status: $stderr\n";
    return $stdout;
}

sub commit_all {
    my ($repository, $message) = @_;
    git_ok($repository, 'add', '-A', '--', 'tests');
    git_ok($repository, 'commit', '--quiet', '--allow-empty', '-m', $message);
    my $head = git_ok($repository, 'rev-parse', 'HEAD');
    chomp $head;
    return $head;
}

sub make_source_repository {
    my ($workspace, $name) = @_;
    my $repository = "$workspace/$name";
    make_path("$repository/$SOURCE_DIRECTORY");
    git_ok($repository, 'init', '--quiet');
    spew("$repository/$SOURCE_DIRECTORY/README", "fixture\n");
    return ($repository, commit_all($repository, 'fixture'));
}

# Exports the tracked source directory of a real checkout into a new repository.
sub make_real_copy {
    my ($workspace, $name, $soak_repository, $soak_ref) = @_;
    my $repository = "$workspace/$name";
    make_path($repository);
    git_ok($repository, 'init', '--quiet');
    my $archive = "$workspace/$name.tar";
    git_ok($soak_repository, 'archive', '--format=tar', '--output', $archive, $soak_ref, $SOURCE_DIRECTORY);
    my ($status, undef, $stderr) = run_command({}, 'tar', '-xf', $archive, '-C', $repository);
    $status == 0 or die "tar failed with $status: $stderr\n";
    return ($repository, commit_all($repository, 'real soak inputs'));
}

# Runs the shipped inspector; with a reference implementation set, the two must agree.
sub run_tool {
    my ($label, $environment, @arguments) = @_;
    my @result = run_command($environment, $^X, $TOOL, @arguments);
    if (defined $REFERENCE) {
        my @reference = run_command($environment, 'python3', '-I', $REFERENCE, @arguments);
        is($reference[0], $result[0], "$label: reference exit status agrees");
        is($reference[1], $result[1], "$label: reference stdout agrees");
        is($reference[2], $result[2], "$label: reference stderr agrees") if $result[0] == 77;
    }
    return @result;
}

sub append_to {
    my ($path, $text) = @_;
    spew($path, $text, 'append');
    return;
}

sub run_synthetic_cases {
    my ($workspace) = @_;
    my ($status, $stdout, $stderr) = run_tool('missing options', {});
    is($status, 2, 'missing options: usage status');
    like($stderr, qr/--ansible-repository/, 'missing options: diagnostic names the option');

    my ($repository, $head) = make_source_repository($workspace, 'clean');
    ($status, $stdout, $stderr) = run_tool('malformed ref', {}, '--ansible-repository', $repository, '--source-ref', 'abc');
    is($status, 77, 'malformed ref: incomplete status');
    like($stderr, qr/full lowercase commit ID/, 'malformed ref: diagnostic');
    is($stdout, '', 'malformed ref: no inventory on stdout');

    ($status, $stdout, $stderr) = run_tool('mismatched ref', {}, '--ansible-repository', $repository, '--source-ref', '0' x 40);
    is($status, 77, 'mismatched ref: incomplete status');
    like($stderr, qr/does not match the requested source ref/, 'mismatched ref: diagnostic');

    ($repository, $head) = make_source_repository($workspace, 'dirty-ascii');
    spew("$repository/$SOURCE_DIRECTORY/untracked.txt", "x\n");
    ($status, $stdout, $stderr) = run_tool('dirty ASCII', {}, '--ansible-repository', $repository, '--source-ref', $head);
    is($status, 77, 'dirty source with ASCII name: incomplete status');
    like($stderr, qr/source directory is dirty/, 'dirty source with ASCII name: dirty diagnostic');

    ($repository, $head) = make_source_repository($workspace, 'dirty-raw');
    spew("$repository/$SOURCE_DIRECTORY/untracked-\xff.txt", "x\n");
    my $raw_environment = {
        GIT_CONFIG_COUNT => 1, GIT_CONFIG_KEY_0 => 'core.quotePath', GIT_CONFIG_VALUE_0 => 'false',
    };
    my ($raw_status, $raw_stdout) =
        run_command($raw_environment, 'git', '-C', $repository, 'status', '--porcelain', '--untracked-files=all', '--', $SOURCE_DIRECTORY);
    is($raw_status, 0, 'raw name control: git status succeeds');
    like($raw_stdout, qr/untracked-\xff\.txt/, 'raw name control: git prints the raw non-UTF-8 byte');
    ($status, $stdout, $stderr) = run_command($raw_environment, $^X, $TOOL, '--ansible-repository', $repository, '--source-ref', $head);
    is($status, 77, 'dirty source with non-UTF-8 name: incomplete status');
    like($stderr, qr/source directory is dirty/, 'dirty source with non-UTF-8 name: dirty diagnostic, not a decoding error');
    unlike($stderr, qr/codec|decode/i, 'dirty source with non-UTF-8 name: no decoding failure reported');
    return;
}

sub run_real_input_cases {
    my ($workspace, $soak_repository, $soak_ref) = @_;
    my ($status, $stdout, $stderr);
    my ($repository, $head) = make_real_copy($workspace, 'real-control', $soak_repository, $soak_ref);
    ($status, $stdout, $stderr) = run_tool('real copy', {}, '--ansible-repository', $repository, '--source-ref', $head);
    is($status, 0, 'real soak inputs: inspection status');
    like($stdout, qr/"execution_ready": false/, 'real soak inputs: not execution ready');
    like($stdout, qr/"runtime_verification": "Not run"/, 'real soak inputs: runtime not verified');
    like($stdout, qr/"registered_pvs": 903/, 'real soak inputs: the 903 PV stage is reported');
    like($stdout, qr/"registered_pvs": 100/, 'real soak inputs: the 100 PV stage is reported');

    my @mutations = (
        {
            name => 'altered fixture file',
            apply => sub { append_to("$_[0]/$SOURCE_DIRECTORY/fixtures/pvs.csv", "\n"); },
            diagnostic => qr{Source checksum mismatch: fixtures/pvs\.csv},
        },
        {
            name => 'missing required file',
            apply => sub { unlink("$_[0]/$SOURCE_DIRECTORY/fixtures/aasoak.db") or die "unlink: $!\n"; },
            diagnostic => qr{Missing regular source file: fixtures/aasoak\.db},
        },
        {
            name => 'untracked checksum list',
            apply => sub { unlink("$_[0]/$SOURCE_DIRECTORY/SHA256SUMS") or die "unlink: $!\n"; },
            diagnostic => qr/Checksum list is not tracked/,
        },
        {
            name => 'duplicate checksum entry',
            apply => sub {
                my ($copy) = @_;
                my $path = "$copy/$SOURCE_DIRECTORY/SHA256SUMS";
                my ($first) = split /\r?\n/, slurp($path);
                append_to($path, "$first\n");
            },
            diagnostic => qr/Invalid or duplicate checksum entry/,
        },
        {
            name => 'combined fixture differs with consistent checksums',
            apply => sub {
                my ($copy) = @_;
                my $root = "$copy/$SOURCE_DIRECTORY";
                append_to("$root/fixtures/pvs-all.csv", "\n");
                my $digest = sha256_hex(slurp("$root/fixtures/pvs-all.csv"));
                my $list = slurp("$root/SHA256SUMS");
                $list =~ s/^[0-9a-f]{64}(  fixtures\/pvs-all\.csv)$/$digest$1/m or die "no pvs-all.csv entry in SHA256SUMS\n";
                spew("$root/SHA256SUMS", $list);
            },
            diagnostic => qr/Combined fixture differs from the original soak/,
        },
    );
    my $index = 0;
    for my $mutation (@mutations) {
        $index++;
        my ($copy) = make_real_copy($workspace, "real-mutation-$index", $soak_repository, $soak_ref);
        $mutation->{apply}->($copy);
        my $mutated_head = commit_all($copy, $mutation->{name});
        ($status, $stdout, $stderr) = run_tool($mutation->{name}, {}, '--ansible-repository', $copy, '--source-ref', $mutated_head);
        is($status, 77, "$mutation->{name}: incomplete status");
        like($stderr, $mutation->{diagnostic}, "$mutation->{name}: its own diagnostic");
        is($stdout, '', "$mutation->{name}: no inventory on stdout");
    }
    return;
}

sub main {
    my @arguments = @_;
    my $help;
    GetOptionsFromArray(\@arguments, 'help' => \$help) or return usage_error('heap-inspect-inputs.pl', __FILE__, 'invalid option');
    if ($help) {
        pod2usage(-input => __FILE__, -exitval => 'NOEXIT', -verbose => 1, -output => \*STDOUT);
        return 0;
    }
    @arguments and return usage_error('heap-inspect-inputs.pl', __FILE__, 'unexpected argument');
    -f $TOOL or die "missing inspector: $TOOL\n";
    !defined $REFERENCE || -f $REFERENCE or die "missing reference tool: $REFERENCE\n";

    my $temporary_root = defined $ENV{TMPDIR} && -d $ENV{TMPDIR} && -w _ ? $ENV{TMPDIR} : "$REPOSITORY/work/scratch/tmp";
    make_path($temporary_root);
    my $workspace = tempdir('heap-inspect-XXXXXX', DIR => $temporary_root, CLEANUP => 1);

    run_synthetic_cases($workspace);

    my ($soak_repository, $soak_ref) = ($ENV{AA_HEAP_SOAK_REPO}, $ENV{AA_HEAP_SOAK_REF});
    if (defined $soak_repository && defined $soak_ref) {
        run_real_input_cases($workspace, $soak_repository, $soak_ref);
    }
    else {
        note('AA_HEAP_SOAK_REPO and AA_HEAP_SOAK_REF not set; the real preserved input cases did not run');
    }

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
    print STDERR "heap-inspect-inputs.pl: $error";
    $status = 2;
};
exit($status == 0 && !Test::More->builder->is_passing ? 1 : $status);
