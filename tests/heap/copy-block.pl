#!/usr/bin/env perl
# Copies the growing files of a source tree into a cumulative destination tree and writes one verified manifest per block.
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA;
use File::Basename qw(dirname);
use File::Find ();
use File::Path qw(make_path);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
use Pod::Usage qw(pod2usage);
use POSIX qw(strftime);
use Time::HiRes qw(clock_gettime gettimeofday CLOCK_MONOTONIC);

=head1 NAME

copy-block.pl - copy the evidence files of one block and verify that earlier content is unchanged

=head1 SYNOPSIS

  perl tests/heap/copy-block.pl --source DIR --dest DIR --block N
  perl tests/heap/copy-block.pl --help

=head1 DESCRIPTION

Copies every regular file below C<--source> (for example the evidence directory of the guest, reached through a mount
or a staging copy) into the cumulative tree C<DEST/data>, and writes C<DEST/manifests/block-NNNN.json> for block N.
Blocks are numbered from 1 and each block needs the manifest of the previous one. A file is copied as it was at the start
of its copy: its size is read once and exactly that many bytes are copied, so bytes a running writer appends later are
left for the next block.

For a file the previous manifest records with C<bytes> and C<sha256>, the first C<bytes> bytes of the source must still
hash to that C<sha256>, which proves the earlier copy is a byte prefix of the new one. Only the bytes after that prefix
are appended to the destination file, and the SHA256 of the whole destination file is then compared with the SHA256 of
the bytes that were read. A file that fails the prefix check, has become shorter, or whose destination file does not have
the recorded length is not touched and keeps its previous record, so the next block checks it again. A file recorded
earlier that is absent from the source is reported and keeps its record.

The manifest lists for every file C<path> (relative to the source), C<status> (C<ok>, C<prefix_mismatch>, C<shrunk>,
C<dest_inconsistent> or C<missing_in_source>), C<bytes>, C<sha256>, C<appended_bytes> and C<last_newline_end> (the offset
after the last newline, 0 when there is none; the bytes after it are an unfinished line). It also records the block number,
the absolute source path, the copy time as UTC (C<copied_utc>) and CLOCK_MONOTONIC seconds (C<copied_monotonic_s>), the
entries that are not regular files (C<skipped>) and C<ok>, true when every file has status C<ok>. File names must be valid
UTF-8 without control characters. The prefix check reads every earlier byte again, so the time of a block grows with the
total size of the files.
Required: Perl 5.26 or newer.

=head1 OPTIONS

=over 4

=item B<--source> DIR

The directory to copy. Required.

=item B<--dest> DIR

The destination root, created when missing. Required.

=item B<--block> N

The block number, a positive integer. Required.

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when every file was copied and verified, 3 when the manifest was written but a file has a status other than C<ok>, 1
when a file could not be read or written, 77 when the source is missing, a file name is not usable or the manifest of the
previous block is missing or invalid, 2 for invalid usage or a block that already has a manifest.

=cut

my $CHUNK_BYTES = 1048576;
my $MANIFEST_DIR = 'manifests';
my $DATA_DIR = 'data';

# An invalid or missing input is an expected outcome with its own exit status.
sub incomplete {
    my ($message) = @_;
    die { incomplete => $message };
}

# A failure to read or store the data ends the program with its own exit status.
sub storage_failure {
    my ($message) = @_;
    die { failure => $message };
}

sub manifest_path {
    my ($dest, $block) = @_;
    return sprintf('%s/%s/block-%04d.json', $dest, $MANIFEST_DIR, $block);
}

sub timestamps {
    my ($seconds, $microseconds) = gettimeofday();
    my $utc = strftime('%Y-%m-%dT%H:%M:%S', gmtime($seconds)) . sprintf('.%03dZ', int($microseconds / 1000));
    return ($utc, sprintf('%.3f', clock_gettime(CLOCK_MONOTONIC)));
}

# Returns the sorted relative paths of the regular files below the root and the list of other entries.
sub list_files {
    my ($root) = @_;
    my (@files, @skipped);
    File::Find::find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            return if $path eq $root || -d $path && !-l $path;
            my $relative = substr($path, length($root) + 1);
            if (-l $path || !-f $path) {
                push @skipped, $relative;
                return;
            }
            push @files, $relative;
        },
    }, $root);
    for my $name (@files, @skipped) {
        my $copy = $name;
        utf8::decode($copy) && $copy !~ /[\x00-\x1f\x7f]/ or incomplete("File name is not valid UTF-8 text without control characters: $name");
    }
    return ([ sort @files ], [ sort @skipped ]);
}

sub read_previous {
    my ($dest, $block) = @_;
    return {} if $block == 1;
    my $path = manifest_path($dest, $block - 1);
    open(my $handle, '<:raw', $path) or incomplete("Cannot read the manifest of the previous block $path: $!");
    my $text = do { local $/; <$handle> };
    close($handle);
    my $manifest = eval { decode_json($text) };
    ref $manifest eq 'HASH' && ref $manifest->{files} eq 'ARRAY' or incomplete("Invalid manifest of the previous block: $path");
    my %entries;
    for my $entry (@{ $manifest->{files} }) {
        ref $entry eq 'HASH' && defined $entry->{path} && $entry->{bytes} =~ /\A\d+\z/ && $entry->{sha256} =~ /\A[0-9a-f]{64}\z/
            or incomplete("Invalid file record in the manifest of the previous block: $path");
        utf8::encode(my $key = $entry->{path});
        $entries{$key} = $entry;
    }
    return \%entries;
}

# Reads up to the given number of bytes in chunks, feeding each chunk to the callback; returns the bytes read.
sub read_bytes {
    my ($handle, $limit, $callback, $name) = @_;
    my $done = 0;
    while ($done < $limit) {
        my $want = $limit - $done < $CHUNK_BYTES ? $limit - $done : $CHUNK_BYTES;
        my $count = sysread($handle, my $chunk, $want);
        defined $count or storage_failure("read $name: $!");
        last if $count == 0;
        $callback->($chunk);
        $done += $count;
    }
    return $done;
}

sub sha256_of_file {
    my ($path) = @_;
    open(my $handle, '<:raw', $path) or storage_failure("open $path: $!");
    my $digest = Digest::SHA->new(256);
    read_bytes($handle, ~0 >> 1, sub { $digest->add($_[0]) }, $path);
    close($handle);
    return $digest->hexdigest;
}

# Copies one file and returns its manifest record; a failed check returns the previous record with a status and no change.
sub copy_file {
    my ($source_root, $data_root, $relative, $previous) = @_;
    my $source = "$source_root/$relative";
    my $target = "$data_root/$relative";
    my $before = defined $previous ? $previous->{bytes} + 0 : 0;
    my %kept = (path => $relative, bytes => $before, sha256 => defined $previous ? $previous->{sha256} : '', appended_bytes => 0,
        last_newline_end => defined $previous ? ($previous->{last_newline_end} // 0) + 0 : 0);
    open(my $in, '<:raw', $source) or storage_failure("open $source: $!");
    my $length = -s $in;
    defined $length or storage_failure("stat $source: $!");
    return { %kept, status => 'shrunk' } if $length < $before;
    my $target_bytes = -e $target ? -s $target : undef;
    if (defined $previous ? (!defined $target_bytes || $target_bytes != $before) : defined $target_bytes) {
        return { %kept, status => 'dest_inconsistent' };
    }

    my $digest = Digest::SHA->new(256);
    my ($offset, $last_newline_end) = (0, 0);
    my $scan = sub {
        my ($chunk) = @_;
        $digest->add($chunk);
        my $position = rindex($chunk, "\n");
        $last_newline_end = $offset + $position + 1 if $position >= 0;
        $offset += length $chunk;
    };
    if (defined $previous) {
        read_bytes($in, $before, $scan, $source) == $before or return { %kept, status => 'shrunk' };
        return { %kept, status => 'prefix_mismatch' } unless $digest->clone->hexdigest eq $previous->{sha256};
    }
    make_path(dirname($target));
    open(my $out, '>>:raw', $target) or storage_failure("open $target: $!");
    my $write = sub {
        my ($chunk) = @_;
        print {$out} $chunk or storage_failure("write $target: $!");
        $scan->($chunk);
    };
    my $read = read_bytes($in, $length - $before, $write, $source);
    close($out) or storage_failure("close $target: $!");
    close($in);
    if ($read != $length - $before) {
        truncate($target, $before) or storage_failure("truncate $target: $!");
        return { %kept, status => 'shrunk' };
    }
    my $sha256 = $digest->hexdigest;
    (-s $target) == $length && sha256_of_file($target) eq $sha256 or storage_failure("destination $target differs from the bytes read from $source");
    return {
        path => $relative, status => 'ok', bytes => $length, sha256 => $sha256, appended_bytes => $length - $before,
        last_newline_end => $last_newline_end,
    };
}

sub write_manifest {
    my ($path, $manifest) = @_;
    open(my $handle, '>:raw', "$path.tmp") or storage_failure("open $path.tmp: $!");
    print {$handle} JSON::PP->new->utf8->canonical->pretty->encode($manifest) or storage_failure("write $path.tmp: $!");
    close($handle) or storage_failure("close $path.tmp: $!");
    rename("$path.tmp", $path) or storage_failure("rename $path.tmp: $!");
    return;
}

# Copies the block and returns the exit status: 0 when every file is ok, 3 otherwise.
sub copy_block {
    my ($options) = @_;
    my ($source, $dest, $block) = @{$options}{qw(source dest block)};
    -d $source or incomplete("Source directory not found: $source");
    $source = abs_path($source);
    my $manifest_path = manifest_path($dest, $block);
    -e $manifest_path and die { usage => "$manifest_path already exists" };
    my ($files, $skipped) = list_files($source);
    my $previous = read_previous($dest, $block);
    make_path("$dest/$MANIFEST_DIR", "$dest/$DATA_DIR", { error => \my $errors });
    @{$errors} and storage_failure("mkdir $dest: " . join('; ', map { values %{$_} } @{$errors}));
    my ($copied_utc, $copied_monotonic) = timestamps();
    my %present = map { $_ => 1 } @{$files};
    my @records = map { copy_file($source, "$dest/$DATA_DIR", $_, $previous->{$_}) } @{$files};
    for my $name (sort grep { !$present{$_} } keys %{$previous}) {
        my $entry = $previous->{$name};
        push @records, { path => $name, status => 'missing_in_source', bytes => $entry->{bytes} + 0, sha256 => $entry->{sha256},
            appended_bytes => 0, last_newline_end => ($entry->{last_newline_end} // 0) + 0 };
    }
    @records = sort { $a->{path} cmp $b->{path} } @records;
    my @bad = grep { $_->{status} ne 'ok' } @records;
    utf8::decode($_->{path}) for @records;
    utf8::decode($_) for @{$skipped};
    my $manifest = {
        block => $block + 0, source => $source, copied_utc => $copied_utc, copied_monotonic_s => $copied_monotonic + 0,
        files => \@records, skipped => $skipped, ok => (@bad ? JSON::PP::false : JSON::PP::true),
    };
    write_manifest($manifest_path, $manifest);
    print STDERR "NOT OK: $_->{status}: $_->{path}\n" for @bad;
    return @bad ? 3 : 0;
}

sub usage_status {
    my ($message) = @_;
    print STDERR "copy-block.pl: $message\n";
    pod2usage(-input => __FILE__, -verbose => 0, -exitval => 'NOEXIT', -output => \*STDERR);
    return 2;
}

sub main {
    my @arguments = @_;
    my ($help, %options);
    GetOptionsFromArray(
        \@arguments,
        'help' => \$help,
        'source=s' => \$options{source},
        'dest=s' => \$options{dest},
        'block=s' => \$options{block},
    ) or return usage_status('invalid option');
    if ($help) {
        pod2usage(-input => __FILE__, -verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        return 0;
    }
    @arguments and return usage_status('unexpected argument');
    for my $name (qw(source dest block)) {
        defined $options{$name} && length $options{$name} or return usage_status("--$name is required");
    }
    $options{block} =~ /\A[1-9]\d*\z/ or return usage_status('--block must be a positive integer');

    my $status = eval { copy_block(\%options) };
    return $status if defined $status;
    my $error = $@;
    ref $error eq 'HASH' or die $error;
    return usage_status($error->{usage}) if exists $error->{usage};
    if (exists $error->{incomplete}) {
        print STDERR "INCOMPLETE: $error->{incomplete}\n";
        return 77;
    }
    print STDERR "FAILURE: $error->{failure}\n";
    return 1;
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    print STDERR "copy-block.pl: $error";
    $status = 2;
};
exit $status;
