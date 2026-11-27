#!/usr/bin/env perl
# Reads one getData.json response in blocks and prints, per event, the time, the element count and the SHA-256 of its elements.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Digest::SHA;
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage qw(pod2usage);

=head1 NAME

hash-events.pl - print the element count and the SHA-256 of the elements of each event of a getData.json response

=head1 SYNOPSIS

  perl tests/heap/array-cases/hash-events.pl FILE
  perl tests/heap/array-cases/hash-events.pl --help

=head1 DESCRIPTION

Reads a response of the form C<[{"meta":...,"data":[{"secs":N,"val":[...]},...]}]> and prints one line per event,
C<secs=N elements=COUNT sha256=HEX>. The hash is taken over the elements packed as unsigned 16-bit little-endian values,
the representation of the pinned frames of C<feed-frames.py>. The file is read in blocks of 256 KiB and each event is hashed
as it is read, so the memory use does not depend on the number of elements of an event; the number of events does not matter.
A response without events (an empty C<data> array or an error page) prints nothing and ends with status 0.

The elements must be integers; a value that is not an integer, or an event whose C<val> array is not closed, is a malformed
response.

=head1 EXIT STATUS

0 after the response was read, 2 for invalid usage, 77 for a file that cannot be read or a malformed response.

=cut

my $EXIT_OK    = 0;
my $EXIT_USAGE = 2;
my $EXIT_INPUT = 77;

my $BLOCK_BYTES = 256 * 1024;
my $TAIL_BYTES  = 64;    # bytes kept between blocks so that a token cut by a block end is found

sub fail_with {
    my ($status, $message) = @_;
    die { status => $status, message => $message };
}

# Adds the comma separated integers of one piece of a val array to the running hash and returns how many there were.
sub feed_values {
    my ($digest, $text, $path) = @_;
    $text =~ tr/ \t\r\n//d;
    return 0 if $text eq '';
    my @values = split /,/, $text, -1;
    for my $value (@values) {
        $value =~ /\A-?\d+\z/ or fail_with($EXIT_INPUT, "$path: an element is not an integer");
    }
    $digest->add(pack('v*', @values));
    return scalar @values;
}

# Walks the response block by block through the states looking for secs, looking for the val array and reading its values.
sub read_events {
    my ($path, $emit) = @_;
    open(my $in, '<:raw', $path) or fail_with($EXIT_INPUT, "$path: $!");
    my ($buffer, $state, $secs, $digest, $count) = ('', 'secs');
    while (1) {
        my $got = read($in, my $block, $BLOCK_BYTES);
        defined $got or fail_with($EXIT_INPUT, "$path: $!");
        $buffer .= $block;
        my $progress = 1;
        while ($progress) {
            $progress = 0;
            if ($state eq 'secs') {
                if ($buffer =~ s/\A.*?"secs"\s*:\s*(\d+)//s) {
                    $secs     = $1;
                    $state    = 'open';
                    $progress = 1;
                }
                elsif (length($buffer) > $TAIL_BYTES) {
                    $buffer = substr($buffer, -$TAIL_BYTES);
                }
            }
            elsif ($state eq 'open') {
                if ($buffer =~ s/\A.*?"val"\s*:\s*\[//s) {
                    $state    = 'values';
                    $digest   = Digest::SHA->new(256);
                    $count    = 0;
                    $progress = 1;
                }
                elsif (length($buffer) > $TAIL_BYTES) {
                    $buffer = substr($buffer, -$TAIL_BYTES);
                }
            }
            else {
                my $close = index($buffer, ']');
                if ($close >= 0) {
                    $count += feed_values($digest, substr($buffer, 0, $close), $path);
                    $buffer = substr($buffer, $close + 1);
                    $emit->($secs, $count, $digest->hexdigest);
                    $state    = 'secs';
                    $progress = 1;
                }
                else {
                    my $last = rindex($buffer, ',');
                    if ($last > 0) {
                        $count += feed_values($digest, substr($buffer, 0, $last), $path);
                        $buffer = substr($buffer, $last + 1);
                    }
                }
            }
        }
        last if $got == 0;
    }
    close($in) or fail_with($EXIT_INPUT, "$path: $!");
    $state eq 'values' and fail_with($EXIT_INPUT, "$path: the val array of the event at secs $secs is not closed");
    return;
}

sub main {
    my @args = @_;
    my $help = 0;
    GetOptionsFromArray(\@args, 'help|h' => \$help) or return usage_error('invalid option');
    if ($help) {
        pod2usage(-verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        return $EXIT_OK;
    }
    @args == 1 or return usage_error('exactly one FILE is required');
    read_events($args[0], sub {
        my ($secs, $count, $hex) = @_;
        printf("secs=%s elements=%d sha256=%s\n", $secs, $count, $hex) or fail_with($EXIT_INPUT, "stdout: $!");
    });
    return $EXIT_OK;
}

sub usage_error {
    my ($message) = @_;
    print STDERR "hash-events.pl: $message\n";
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
        print STDERR "hash-events.pl: $error->{message}\n";
        $status = $error->{status};
    }
    else {
        print STDERR "hash-events.pl: $error";
        $status = $EXIT_USAGE;
    }
};
exit $status;
