#!/usr/bin/env perl
# Inspects preserved soak inputs without executing their tools or contacting a VM.
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA ();
use Encode ();
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP ();
use Pod::Usage qw(pod2usage);
use POSIX ();

=head1 NAME

inspect-inputs.pl - inspect the preserved soak inputs of the heap measurement

=head1 SYNOPSIS

  perl tests/heap/inspect-inputs.pl --ansible-repository DIRECTORY --source-ref COMMIT_ID
  perl tests/heap/inspect-inputs.pl --help

=head1 DESCRIPTION

Reads the preserved original soak inputs from an explicitly selected Ansible checkout and writes a JSON inventory to
stdout. It verifies the requested full commit ID, the cleanliness of the source directory, the recorded file hashes,
the ordered PV increments, the unique PV and store identities and the 100, 500 and 903 PV stage populations. It does
not execute the preserved tools, modify either checkout, contact an appliance or create a VM. Git output is read as
bytes, so a file name that is not valid UTF-8 cannot abort the inspection. CSV files are read as strict UTF-8 with
CRLF, LF or CR record ends; a double quote in a CSV file is refused. Required: Perl 5.26 or newer, Digest::SHA,
JSON::PP, Encode and git in PATH.

=head1 OPTIONS

=over 4

=item B<--ansible-repository> DIRECTORY

The Ansible checkout that holds tests/archiver-soak. Required.

=item B<--source-ref> COMMIT_ID

The full lowercase 40-character commit ID that the checkout must have at HEAD. Required.

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when the inspection completed and the JSON inventory was written, 77 when an input is invalid or incomplete (no
inventory is written), 2 for invalid usage or an internal error.

=cut

my $FIXTURE_SHA256 = '037a92691bc23a6dcac37ec3613ad19c9f80b93b689209ec8dc403b519eaf594';
my $SOURCE_DIRECTORY = 'tests/archiver-soak';
my @CSV_FILES = ('pvs.csv', 'pvs-load1.csv', 'pvs-load2.csv');
my @REQUIRED_FILES = (
    'baseline/gen_soak.py', 'baseline/gen_load.py',
    'baseline/register.py', 'baseline/load_retrieval.py',
    'baseline/store-test.yml',
    'fixtures/aasoak.db', 'fixtures/load1.db', 'fixtures/load2.db',
    'fixtures/pvs.csv', 'fixtures/pvs-load1.csv',
    'fixtures/pvs-load2.csv', 'fixtures/pvs-all.csv',
);
my @CSV_FIELDS = qw(pv group scan method period policy store_key);
my @STAGES = (
    [100, { '1.0' => 80, '0.1' => 10, '10.0' => 10 }, 5, 24],
    [500, { '1.0' => 480, '0.1' => 10, '10.0' => 10 }, 5, 6],
    [903, { '1.0' => 783, '0.1' => 110, '10.0' => 10 }, 8, 27],
);

# An invalid or incomplete input is an expected outcome with its own exit status.
sub incomplete {
    my ($message) = @_;
    die { incomplete => $message };
}

sub git {
    my ($repository, @arguments) = @_;
    my @command = ('git', '-C', $repository, @arguments);
    my $pid = open(my $out, '-|');
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        open(STDERR, '>', '/dev/null') or POSIX::_exit(126);
        {
            no warnings 'exec';    # the exit below reports a failed exec
            exec { $command[0] } @command;
        }
        POSIX::_exit(127);
    }
    my $stdout = do { local $/; <$out> };
    close($out);
    my $status = $? >> 8;
    my $signal = $? & 127;
    $signal == 0 && $status == 0 or incomplete("git @arguments failed with status " . ($signal ? "signal $signal" : $status));
    $stdout = '' unless defined $stdout;
    $stdout =~ s/\A\s+//;
    $stdout =~ s/\s+\z//;
    return $stdout;
}

sub digest {
    my ($path) = @_;
    open(my $handle, '<:raw', $path) or incomplete("open $path: $!");
    my $checksum = Digest::SHA->new(256);
    $checksum->addfile($handle);
    close($handle) or incomplete("close $path: $!");
    return $checksum->hexdigest;
}

sub read_bytes {
    my ($path) = @_;
    open(my $handle, '<:raw', $path) or incomplete("open $path: $!");
    local $/;
    my $data = <$handle>;
    close($handle) or incomplete("close $path: $!");
    return defined $data ? $data : '';
}

# Splits text at CRLF, LF or CR like a CSV reader and drops the empty piece after a final record end.
sub split_records {
    my ($text) = @_;
    my @records = split /\r\n|\n|\r/, $text, -1;
    pop @records if @records && $records[-1] eq '';
    return @records;
}

sub read_csv {
    my ($path, $name) = @_;
    my $text = eval { Encode::decode('UTF-8', read_bytes($path), Encode::FB_CROAK | Encode::LEAVE_SRC) };
    defined $text or incomplete("Invalid UTF-8 in CSV input: $name");
    $text =~ /"/ and incomplete("Quoted CSV fields are not supported: $name");
    my @records = split_records($text);
    my $header = shift @records;
    defined $header && join(',', @CSV_FIELDS) eq join(',', split(/,/, $header, -1))
        or incomplete("Unexpected CSV columns: $name");
    my @rows;
    for my $record (@records) {
        next if $record eq '';    # a blank line is not a record
        my @values = split /,/, $record, -1;
        scalar(@values) == scalar(@CSV_FIELDS) or incomplete("Incomplete CSV input: $name");
        my %row;
        @row{@CSV_FIELDS} = @values;
        push @rows, \%row;
    }
    @rows or incomplete("Incomplete CSV input: $name");
    return @rows;
}

sub count_by {
    my ($rows, $column) = @_;
    my %count;
    $count{ $_->{$column} }++ for @{$rows};
    return \%count;
}

sub same_counts {
    my ($left, $right) = @_;
    return 0 unless scalar(keys %{$left}) == scalar(keys %{$right});
    for my $key (keys %{$left}) {
        return 0 unless exists $right->{$key} && $left->{$key} == $right->{$key};
    }
    return 1;
}

sub same_rows {
    my ($left, $right) = @_;
    return 0 unless scalar(@{$left}) == scalar(@{$right});
    for my $index (0 .. $#{$left}) {
        for my $field (@CSV_FIELDS) {
            return 0 unless $left->[$index]{$field} eq $right->[$index]{$field};
        }
    }
    return 1;
}

sub inspect_inputs {
    my ($repository, $source_ref) = @_;
    $source_ref =~ /\A[0-9a-f]{40}\z/ or incomplete('Source ref must be a full lowercase commit ID');
    git($repository, 'rev-parse', 'HEAD') eq $source_ref
        or incomplete('Ansible HEAD does not match the requested source ref');
    git($repository, 'status', '--porcelain', '--untracked-files=all', '--', $SOURCE_DIRECTORY) eq ''
        or incomplete('Preserved soak source directory is dirty');
    my $root = "$repository/$SOURCE_DIRECTORY";
    my $checksum_path = "$root/SHA256SUMS";
    git($repository, 'ls-files', '--', "$SOURCE_DIRECTORY/SHA256SUMS") ne ''
        or incomplete('Checksum list is not tracked');
    my $list = read_bytes($checksum_path);
    $list =~ /[^\x00-\x7f]/ and incomplete('Invalid checksum list encoding');
    my %recorded;
    for my $line (split_records($list)) {
        $line =~ /\A([0-9a-f]{64})  (.+)\z/ && !exists $recorded{$2} or incomplete('Invalid or duplicate checksum entry');
        $recorded{$2} = $1;
    }
    my %hashes;
    for my $name (@REQUIRED_FILES) {
        my $path = "$root/$name";
        (-l $path || !-f $path) and incomplete("Missing regular source file: $name");
        my $actual = digest($path);
        (exists $recorded{$name} && $recorded{$name} eq $actual) or incomplete("Source checksum mismatch: $name");
        $hashes{$name} = $actual;
    }
    $hashes{'fixtures/pvs-all.csv'} eq $FIXTURE_SHA256 or incomplete('Combined fixture differs from the original soak');
    my @rows_all = read_csv("$root/fixtures/pvs-all.csv", 'pvs-all.csv');
    my @cumulative;
    my @stages;
    for my $index (0 .. $#CSV_FILES) {
        my ($total, $periods, $waves, $hours) = @{ $STAGES[$index] };
        push @cumulative, read_csv("$root/fixtures/$CSV_FILES[$index]", $CSV_FILES[$index]);
        my $actual_periods = count_by(\@cumulative, 'period');
        my $actual_waves = scalar(grep { $_->{group} eq 'wave' || $_->{group} eq 'load2wave' } @cumulative);
        (scalar(@cumulative) == $total && same_counts($actual_periods, $periods) && $actual_waves == $waves)
            or incomplete('Stage population differs from the accepted plan');
        push @stages, {
            registered_pvs => $total, periods => $actual_periods,
            waveform_pvs => $actual_waves, observation_hours => $hours,
        };
    }
    same_rows(\@cumulative, \@rows_all) or incomplete('Combined fixture does not match the ordered increments');
    for my $column ('pv', 'store_key') {
        my %seen = map { $_->{$column} => 1 } @rows_all;
        scalar(keys %seen) == scalar(@rows_all) or incomplete("Duplicate fixture identity: $column");
    }
    return {
        schema => 1,
        ansible_commit => $source_ref,
        source_directory => $SOURCE_DIRECTORY,
        checksum_list_sha256 => digest($checksum_path),
        file_sha256 => \%hashes,
        stages => \@stages,
        registration_methods => count_by(\@rows_all, 'method'),
        execution_ready => JSON::PP::false,
        unverified_inputs => [
            'original installed policy and ETL properties',
            'original effective per-PV store URLs and post-processing',
            'accepted resource limits, client placement and evidence storage',
            'accepted analysis settings and published run source refs',
        ],
        runtime_verification => 'Not run',
    };
}

sub usage_status {
    my ($message) = @_;
    print STDERR "inspect-inputs.pl: $message\n";
    pod2usage(-input => __FILE__, -verbose => 0, -exitval => 'NOEXIT', -output => \*STDERR);
    return 2;
}

sub main {
    my @arguments = @_;
    my ($help, $repository, $source_ref);
    GetOptionsFromArray(
        \@arguments,
        'help' => \$help,
        'ansible-repository=s' => \$repository,
        'source-ref=s' => \$source_ref,
    ) or return usage_status('invalid option');
    if ($help) {
        pod2usage(-input => __FILE__, -verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        return 0;
    }
    @arguments and return usage_status('unexpected argument');
    defined $repository or return usage_status('--ansible-repository is required');
    defined $source_ref or return usage_status('--source-ref is required');
    my $resolved = abs_path($repository);
    $resolved = $repository unless defined $resolved;
    my $result = eval { inspect_inputs($resolved, $source_ref) };
    if (!defined $result) {
        my $error = $@;
        ref $error eq 'HASH' && exists $error->{incomplete} or die $error;
        print STDERR "INCOMPLETE: $error->{incomplete}\n";
        return 77;
    }
    my $json = JSON::PP->new->canonical->indent->indent_length(2)->space_after;
    print $json->encode($result) or die "write stdout: $!\n";
    return 0;
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    print STDERR "inspect-inputs.pl: $error";
    $status = 2;
};
exit $status;
