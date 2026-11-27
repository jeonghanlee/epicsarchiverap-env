#!/usr/bin/env perl
# Classifies the requests of the raw retrieval cells of one run against the reference responses and prints the counts per cell.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage qw(pod2usage);

=head1 NAME

classify-cells.pl - count the outcome classes of the requests of the raw retrieval cells of one run

=head1 SYNOPSIS

  perl tests/heap/array-cases/classify-cells.pl RUN_DIR
  perl tests/heap/array-cases/classify-cells.pl --check-reference MIN_BYTES RUN_DIR
  perl tests/heap/array-cases/classify-cells.pl --help

=head1 DESCRIPTION

C<RUN_DIR> is the output directory of one run of C<run-retrieval-cells.bash>: the one directory C<reference-E<lt>heapE<gt>/requests.csv> holds the reference
responses and each cell C<r<heap>-c<clients>/requests.csv> holds the requests of one retrieval heap and client count, in the
format of C<request-array.pl>. A request is C<Delivered> when its status is 200 and its SHA-256 equals that of the reference
response of the same name, C<Delivered-different> for another 200, C<Refused-503> and C<Refused-400> for those statuses,
C<Failed-500> for a 500 and C<Other> for every other status and for a request without an answer. Only a reference row with
status 200 counts as a reference.

For each cell, in the order of client count and heap, one line per request name (in the order of the first appearance) and
one line C<total> are printed:

  r256-c1 laser1 Delivered=3
  r256-c1 total Delivered=3 Failed-500=9

Only the classes with a count above zero are printed, in the fixed order of the list above.

With C<--check-reference MIN_BYTES> the cells are not classified: the tool checks that every row of the reference directory has
status 200 and at least C<MIN_BYTES> bytes, prints C<reference ok> and the number of rows, and ends with status 77 otherwise.

=head1 EXIT STATUS

0 after the classification, 2 for invalid usage, 77 for a run directory without a reference or without a cell, or a
C<requests.csv> that cannot be read or is malformed.

=cut

my $EXIT_OK    = 0;
my $EXIT_USAGE = 2;
my $EXIT_INPUT = 77;

my @CLASSES = qw(Delivered Delivered-different Refused-400 Refused-503 Failed-500 Other);
my @COLUMNS = qw(name http sha256 bytes);

sub fail_with {
    my ($status, $message) = @_;
    die { status => $status, message => $message };
}

# Splits a whole CSV text into records; a quoted field may hold commas, doubled quotes and line breaks.
sub csv_records {
    my ($text, $path) = @_;
    my (@records, @fields);
    while ($text =~ /\G(?:"((?:[^"]|"")*)"|([^,\r\n"]*))(,|\r?\n|\z)/gc) {
        my ($quoted, $plain, $separator) = ($1, $2, $3);
        push @fields, defined $quoted ? $quoted =~ s/""/"/gr : $plain;
        if ($separator ne ',') {
            push @records, [@fields] unless @fields == 1 && $fields[0] eq '' && $separator eq '';
            @fields = ();
        }
        last if pos($text) >= length($text);
    }
    pos($text) == length($text) or fail_with($EXIT_INPUT, "$path: the CSV text is malformed near offset " . (pos($text) // 0));
    return \@records;
}

sub read_requests {
    my ($path) = @_;
    open(my $in, '<:raw', $path) or fail_with($EXIT_INPUT, "$path: $!");
    my $text = do { local $/; <$in> };
    close($in) or fail_with($EXIT_INPUT, "$path: $!");
    defined $text && length $text or fail_with($EXIT_INPUT, "$path: empty");
    my $records = csv_records($text, $path);
    my $header  = shift @{$records};
    my %index   = map { $header->[$_] => $_ } 0 .. $#{$header};
    for my $column (@COLUMNS) {
        defined $index{$column} or fail_with($EXIT_INPUT, "$path: the header has no column $column");
    }
    my @rows;
    for my $record (@{$records}) {
        push @rows, { map { $_ => ($record->[$index{$_}] // '') } @COLUMNS };
    }
    return \@rows;
}

sub classify {
    my ($row, $reference) = @_;
    my $http = $row->{http};
    return ($reference->{ $row->{name} } // '') eq $row->{sha256} ? 'Delivered' : 'Delivered-different' if $http eq '200';
    return 'Refused-400' if $http eq '400';
    return 'Refused-503' if $http eq '503';
    return 'Failed-500'  if $http eq '500';
    return 'Other';
}

sub counts_text {
    my ($counts) = @_;
    return join(' ', map { "$_=$counts->{$_}" } grep { $counts->{$_} } @CLASSES);
}

sub cell_order {
    my ($directory) = @_;
    my @cells;
    for my $path (glob("$directory/r*-c*")) {
        next unless -d $path;
        my ($name) = $path =~ m{([^/]+)\z};
        $name =~ /\Ar(\d+)-c(\d+)\z/ or next;
        push @cells, [ $name, $1, $2 ];
    }
    return map { $_->[0] } sort { $a->[2] <=> $b->[2] || $a->[1] <=> $b->[1] } @cells;
}

sub main {
    my @args = @_;
    my $help = 0;
    my $minimum;
    GetOptionsFromArray(\@args, 'help|h' => \$help, 'check-reference=i' => \$minimum) or return usage_error('invalid option');
    if ($help) {
        pod2usage(-verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        return $EXIT_OK;
    }
    @args == 1 or return usage_error('exactly one RUN_DIR is required');
    my $directory = $args[0];
    -d $directory or fail_with($EXIT_INPUT, "$directory: not a directory");
    my %reference;
    my @references = grep { -d $_ } glob("$directory/reference-*");
    @references == 1 or fail_with($EXIT_INPUT, "$directory: exactly one reference-<heap> directory is required");
    for my $row (@{ read_requests("$references[0]/requests.csv") }) {
        $reference{ $row->{name} } = $row->{sha256} if $row->{http} eq '200';
    }
    %reference or fail_with($EXIT_INPUT, "$references[0]/requests.csv: no request with status 200");
    if (defined $minimum) {
        my $rows = read_requests("$references[0]/requests.csv");
        for my $row (@{$rows}) {
            $row->{http} eq '200' && $row->{bytes} =~ /\A\d+\z/ && $row->{bytes} >= $minimum
                or fail_with($EXIT_INPUT, "$references[0]/requests.csv: the reference of $row->{name} has status $row->{http} and $row->{bytes} bytes, below $minimum");
        }
        printf("reference ok rows=%d\n", scalar @{$rows}) or fail_with($EXIT_INPUT, "stdout: $!");
        return $EXIT_OK;
    }
    my @cells = cell_order($directory);
    @cells or fail_with($EXIT_INPUT, "$directory: no cell directory r<heap>-c<clients>");
    for my $cell (@cells) {
        my (%by_name, @names, %total);
        for my $row (@{ read_requests("$directory/$cell/requests.csv") }) {
            push @names, $row->{name} unless $by_name{ $row->{name} };
            my $class = classify($row, \%reference);
            $by_name{ $row->{name} }{$class}++;
            $total{$class}++;
        }
        for my $name (@names) {
            print "$cell $name ", counts_text($by_name{$name}), "\n" or fail_with($EXIT_INPUT, "stdout: $!");
        }
        print "$cell total ", counts_text(\%total), "\n" or fail_with($EXIT_INPUT, "stdout: $!");
    }
    return $EXIT_OK;
}

sub usage_error {
    my ($message) = @_;
    print STDERR "classify-cells.pl: $message\n";
    return $EXIT_USAGE;
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    if (ref $error eq 'HASH') {
        print STDERR "classify-cells.pl: $error->{message}\n";
        $status = $error->{status};
    }
    else {
        print STDERR "classify-cells.pl: $error";
        $status = $EXIT_USAGE;
    }
};
exit $status;
