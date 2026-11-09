#!/usr/bin/env perl
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempfile);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
use Pod::Usage qw(pod2usage);
use POSIX ();
use lib dirname(abs_path(__FILE__)) . '/../lib';
use ArchiverTest qw(slurp check which);

my $JSON = JSON::PP->new->canonical->pretty;

sub attributes {
    my ($path) = @_;
    my $xml = slurp($path);
    $xml =~ s/<!--.*?-->//sg;
    my @resources = $xml =~ m{<Resource\s+(.*?)/>}sg;
    @resources == 1 or die "$path: expected one generated Resource\n";
    my ($remaining, %values) = ($resources[0]);
    my %entities = (amp => '&', lt => '<', gt => '>', quot => '"', apos => "'");
    while ($remaining =~ s/^\s*([A-Za-z][A-Za-z0-9]*)="([^"<]*)"//s) {
        my ($key, $value) = ($1, $2);
        exists($values{$key}) and die "$path: duplicate attribute\n";
        $value =~ /&(?!amp;|lt;|gt;|quot;|apos;|#(?:10|13|9);)/
            and die "$path: unsupported XML entity\n";
        $value =~ s/&(amp|lt|gt|quot|apos|#10|#13|#9);/
            exists($entities{$1}) ? $entities{$1} : chr(substr($1, 1))/ge;
        $values{$key} = $value;
    }
    $remaining =~ /^\s*$/ or die "$path: unsupported generated Resource syntax\n";
    for my $key (qw(name driverClassName url username password)) {
        defined($values{$key}) or die "$path: missing $key\n";
    }
    return \%values;
}

sub query {
    my ($resource, $user, $sql) = @_;
    my $runuser = which('runuser') or die "missing prerequisite: runuser\n";
    my $client = which('mysql') or die "missing prerequisite: mysql\n";
    my @connection;
    my $database;
    if ($resource->{url} =~ m{^jdbc:mariadb://localhost/([A-Za-z0-9_]+)\?localSocket=(/[^\s?&]+)$}) {
        $database = $1;
        @connection = ('--protocol=SOCKET', "--socket=$2");
    } elsif ($resource->{url} =~ m{^jdbc:mariadb://(127\.0\.0\.1):([0-9]+)/([A-Za-z0-9_]+)$}) {
        $database = $3;
        @connection = ('--protocol=TCP', "--host=$1", "--port=$2");
    } else {
        die "unsupported installed MariaDB endpoint\n";
    }
    my @account = getpwnam($user);
    @account or die "service account is unavailable\n";
    my ($file, $path) = tempfile('archiver-db-XXXXXXXX', DIR => '/tmp', UNLINK => 1);
    chmod(0600, $path) == 1 or die "chmod client file: $!\n";
    chown($account[2], $account[3], $path) == 1 or die "chown client file: $!\n";
    print {$file} "[client]\n" or die "write client file: $!\n";
    for my $key (qw(username password)) {
        my $value = $resource->{$key};
        $value =~ s/\\/\\\\/g;
        $value =~ s/"/\\"/g;
        $value =~ s/\n/\\n/g; $value =~ s/\r/\\r/g; $value =~ s/\t/\\t/g;
        my $option = $key eq 'username' ? 'user' : 'password';
        print {$file} "$option=\"$value\"\n" or die "write client file: $!\n";
    }
    close($file) or die "close client file: $!\n";
    my @command = ($runuser, '-u', $user, '--', $client, "--defaults-file=$path",
        @connection, '--batch', '--raw', '--skip-column-names', "--database=$database", '--execute', $sql);
    my $pid = open(my $out, '-|');
    defined($pid) or die "fork database client: $!\n";
    if (!$pid) {
        { no warnings 'exec'; exec {$command[0]} @command; }
        POSIX::_exit(127);
    }
    my $text = do { local $/; <$out> };
    close($out);
    my $status = $?;
    ($status & 127) and die "database client terminated by signal " . ($status & 127) . "\n";
    (($status >> 8) == 126 || ($status >> 8) == 127) and die "database client could not execute\n";
    check($status == 0, 'installed MariaDB connection and query succeed as the service account');
    return $text // '';
}

sub main {
    my (@args) = @_;
    my ($config, $mode, $component, $pv, $help);
    GetOptionsFromArray(\@args, 'config=s' => \$config, 'mode=s' => \$mode,
        'component=s' => \$component, 'pv=s' => \$pv, 'help' => \$help) or die "invalid options\n";
    if ($help) { pod2usage(-verbose => 2, -noperldoc => 1, -exitval => 'NOEXIT'); return 0; }
    defined($config) && defined($mode) && !@args or die "supply --config and --mode\n";
    $mode =~ /^(context|schema|registration)$/ or die "invalid mode\n";
    $component //= 'mgmt';
    $component =~ /^(mgmt|engine|etl|retrieval)$/ or die "invalid component\n";
    $> == 0 or die "run through sudo to read installed credentials and select the service account\n";
    my $c = $JSON->decode(slurp($config));
    ref($c) eq 'HASH' or die "configuration must be an object\n";
    for my $key (qw(install user backend database database_user)) {
        defined($c->{$key}) && !ref($c->{$key}) or die "missing scalar configuration: $key\n";
    }
    my $expected;
    if ($c->{backend} eq 'mariadb-uds') {
        defined($c->{database_socket}) && !ref($c->{database_socket})
            && $c->{database_socket} =~ m{^/[^\s?&]+$} or die "invalid expected socket\n";
        $expected = "jdbc:mariadb://localhost/$c->{database}?localSocket=$c->{database_socket}";
    } elsif ($c->{backend} eq 'mariadb-tcp') {
        ($c->{database_host} // '') eq '127.0.0.1' && ($c->{database_port} // '') =~ /^[0-9]+$/
            or die "invalid expected TCP endpoint\n";
        $expected = "jdbc:mariadb://$c->{database_host}:$c->{database_port}/$c->{database}";
    } else { die "MariaDB backend required\n"; }
    my $resource = attributes("$c->{install}/$component/conf/context.xml");
    my $text;
    if ($mode eq 'registration') {
        defined($pv) && $pv =~ /^LocalInstall:[A-Za-z0-9]+:Value$/ or die "invalid verifier PV\n";
        $text = query($resource, $c->{user}, "SELECT typeInfoJSON FROM PVTypeInfo WHERE pvName='$pv';");
    } elsif ($mode eq 'schema') {
        $text = query($resource, $c->{user}, 'SELECT DATABASE(); SELECT CURRENT_USER(); SELECT @@socket; SELECT @@port; SHOW TABLES; SHOW COLUMNS FROM PVTypeInfo;');
        check($text =~ /^\Q$c->{database}\E\n\Q$c->{database_user}\E\@[^\n]+\n/, 'database and authenticated application account match input');
        for my $table (qw(ArchivePVRequests ExternalDataServers PVAliases PVTypeInfo)) {
            check($text =~ /^\Q$table\E$/m, "required database table $table");
        }
        check($text =~ /^pvName\t/m && $text =~ /^typeInfoJSON\t/m, 'PV metadata schema exists');
    }
    check($resource->{driverClassName} eq 'org.mariadb.jdbc.Driver'
        && $resource->{url} eq $expected && $resource->{username} eq $c->{database_user}
        && $resource->{name} eq "jdbc/$c->{database}", "$component uses the supplied MariaDB configuration");
    delete $resource->{password};
    print $mode eq 'context' ? $JSON->encode($resource) : $text;
    return 0;
}

my $status;
eval { $status = main(@ARGV); defined($status) or die "missing exit status\n"; 1 }
    or do { my $error = $@; print STDERR "database.pl: $error"; $status = $error =~ /^ASSERTION:/ ? 1 : 2; };
exit $status;

=head1 NAME

database.pl - inspect the installed MariaDB resource and query its database

=head1 SYNOPSIS

  sudo perl tests/vm/database.pl --config /absolute/case.json --mode schema

=head1 DESCRIPTION

Reads the shipped, generated context.xml format, decodes its XML attributes,
and checks the resource against the supplied installation case. Schema and
registration queries use the installed URL and application credentials with
the actual mysql client running as the service account. A private temporary
client file holds credentials; output never includes the password. No database
or application configuration is changed. Perl 5.26.3, JSON::PP, runuser and
the MariaDB client are required. The caller must bound execution with timeout.

=head1 OPTIONS

=over

=item --config FILE

Installation case JSON. MariaDB cases require database (name), database_user
and either database_socket or database_host and database_port.

=item --mode context|schema|registration

Validate and print password-free context attributes, inspect the database/schema,
or return the named PV's registration JSON. Queries open a new real connection.

=item --component NAME

Installed component whose resource is read; defaults to mgmt.

=item --pv NAME

Required for registration mode; accepts a PV created by the shipped verifier.

=item --help

Print help and exit 0.

=back

=head1 EXIT STATUS

0: required checks passed. 1: configuration, connection or schema assertion failed.
2: invalid input, unreadable files, unsupported resource syntax or tool error.

=cut
