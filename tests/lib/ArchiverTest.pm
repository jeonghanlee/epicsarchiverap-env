package ArchiverTest;
use 5.010;    # defined-or operator
use strict;
use warnings;
use Exporter qw(import);
use Pod::Usage qw(pod2usage);

our @EXPORT_OK = qw(slurp spew which shell_quote shell_quote_shlex fail check pause_for usage_error);

sub slurp {
    my ($path) = @_;
    open(my $handle, '<:raw', $path) or die "open $path: $!\n";
    local $/;
    my $data = <$handle>;
    close($handle) or die "close $path: $!\n";
    return $data // '';
}

sub spew {
    my ($path, $data, $mode) = @_;
    my $flags = $mode && $mode eq 'append' ? '>>:raw' : '>:raw';
    open(my $handle, $flags, $path) or die "open $path: $!\n";
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

sub shell_quote_shlex {
    my ($text) = @_;
    return "''" if $text eq '';
    return $text unless $text =~ m{[^A-Za-z0-9_@%+=:,./-]};
    $text =~ s/'/'"'"'/g;
    return "'$text'";
}

sub fail($) {
    my ($message) = @_;
    die "ASSERTION: $message\n";
}

sub check($$) {
    my ($condition, $message) = @_;
    $condition or fail($message);
    return;
}

sub pause_for {
    my ($seconds) = @_;
    select(undef, undef, undef, $seconds);
    return;
}

sub usage_error {
    my ($script_name, $pod_path, $message) = @_;
    print STDERR "$script_name: $message\n" if defined $message;
    pod2usage(-input => $pod_path, -verbose => 0, -exitval => 'NOEXIT', -output => \*STDERR);
    return 2;
}

1;

=head1 NAME

ArchiverTest - explicitly imported helpers for the Perl regression tests

=head1 SYNOPSIS

  use ArchiverTest qw(slurp spew check usage_error);
  spew($path, $bytes);
  check(slurp($path) eq $bytes, 'file bytes agree');
  return usage_error('example.pl', __FILE__, 'unexpected argument');

=head1 DESCRIPTION

No symbols are imported by default. Callers locate tests/lib from their real script location before importing helpers.
The module neither starts test processes nor exits the caller.

C<slurp> returns raw file bytes, including an empty string for an empty file. C<spew> writes raw bytes, replacing the
file unless its optional third argument is C<append>. File errors name the operation and path and raise an exception.
C<which> returns the first regular executable file in PATH, ignores empty PATH entries and returns undef if none exists.

C<shell_quote> always single-quotes its argument. C<shell_quote_shlex> leaves shell-safe text unquoted and preserves the
runtime test's shlex-compatible apostrophe format. Both forms represent one shell argument, including an empty string.

C<fail($)> raises C<ASSERTION: message> followed by a newline. C<check($$)> calls it for a false condition; both scalar
prototypes are available when imported. C<pause_for> waits with select for the supplied number of seconds.

C<usage_error> takes the diagnostic script name, the path to that script's POD and an optional message. It prints the
message when defined, renders the caller's short usage on stderr and returns 2 without exiting.

=cut
