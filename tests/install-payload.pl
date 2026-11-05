#!/usr/bin/env perl
# Compares the real install targets of the four appliance services against two supplied build artifact sets.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA;
use File::Basename qw(dirname basename);
use File::Copy qw(copy);
use File::Find ();
use File::Glob qw(bsd_glob);
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use IO::Uncompress::Unzip qw($UnzipError);
use Pod::Usage qw(pod2usage);
use POSIX ();

=head1 NAME

install-payload.pl - compare the real install target against two supplied build artifact sets

=head1 SYNOPSIS

  perl tests/install-payload.pl OLD_TARGET NEW_TARGET --old-log4j DIR
  perl tests/install-payload.pl --help

=head1 DESCRIPTION

Runs the shipped install.mgmt, install.engine, install.etl and install.retrieval targets twice under a temporary
prefix, once with the old and once with the new WAR and logging JAR set, and compares every installed payload file with
the new set. It checks that logs, external configuration, work and temp files, other webapps and a storage marker
survive, and that missing, ambiguous and damaged WAR inputs, a WAR without WEB-INF/web.xml, missing JARs and unsafe
destinations are rejected without changing the installed mgmt payload. A failed final write to /dev/full must restore
the previous WAR and JAR contents through the shipped Make target. The test requires zip, unzip and /dev/full.
No systemd unit or running appliance is changed. A passing run removes its workspace
below TMPDIR, else below work/scratch/tmp of the checkout; a failed run, or KEEP_WORKSPACE=1, keeps the workspace and its
log and prints the path.

=head1 OPTIONS

=over 4

=item B<OLD_TARGET>, B<NEW_TARGET>

Two real Maven target directories, each holding exactly one WAR per service. NEW_TARGET also holds tomcat-log4j.

=item B<--old-log4j> DIR

A directory with real old log4j JAR files, named log4j-*.jar.

=item B<--help>

Print this text and exit 0.

=back

=head1 EXIT STATUS

0 when every check passed, 1 when an assertion failed, 2 for a usage error or an environment error.

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

# A folder that this run created below the temporary folder: absolute, not a link, equal to its resolved path.
sub run_folder_is_safe {
    my ($path) = @_;
    return 0 unless defined $path && $path =~ m{\A/} && -d $path && !-l $path;
    my $resolved = abs_path($path);
    my $root = temp_root();
    return defined $resolved && $resolved eq $path && index($path, "$root/") == 0;
}

# Ends a folder of this run: removed after a pass, kept and named after a failure or with KEEP_WORKSPACE=1.
sub finish_workspace {
    my ($path, $passed) = @_;
    return unless defined $path && -e $path;
    if ($passed && ($ENV{KEEP_WORKSPACE} // '') ne '1' && run_folder_is_safe($path)) {
        remove_tree($path);
        return;
    }
    print "Workspace retained: $path\n";
    return;
}

my @SERVICES = qw(mgmt engine etl retrieval);
my $WORKSPACE;
my @MAKE;

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

sub digest_file {
    my ($path) = @_;
    open(my $handle, '<:raw', $path) or die "open $path: $!\n";
    my $digest = Digest::SHA->new(256)->addfile($handle)->hexdigest;
    close($handle) or die "close $path: $!\n";
    return $digest;
}

sub glob_in {
    my ($directory, $pattern) = @_;
    (my $escaped = $directory) =~ s/([\\\[\]{}*?~])/\\$1/g;
    return sort { $a cmp $b } grep { -f } bsd_glob("$escaped/$pattern");
}

sub files_under {
    my ($directory) = @_;
    my %files;
    return %files unless -d $directory;
    File::Find::find({
        no_chdir => 1,
        wanted   => sub {
            return unless -f $File::Find::name;
            $files{ substr($File::Find::name, length($directory) + 1) } = 1;
            return;
        },
    }, $directory);
    return %files;
}

sub python_list {
    return '[' . join(', ', map { "'$_'" } @_) . ']';
}

# Runs one command without a shell and returns its status, stdout and stderr; a signal reads as 128 plus its number.
sub run_command {
    my ($timeout, @command) = @_;
    my $out = File::Temp->new;
    my $err = File::Temp->new;
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        open(STDIN, '<', '/dev/null') or POSIX::_exit(126);
        open(STDOUT, '>&', $out) or POSIX::_exit(126);
        open(STDERR, '>&', $err) or POSIX::_exit(126);
        exec { $command[0] } @command or POSIX::_exit(127);
    }
    my $raw;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $timeout;
        waitpid($pid, 0);
        $raw = $?;
        alarm 0;
        1;
    } or do {
        my $error = $@;
        alarm 0;
        kill('KILL', $pid);
        waitpid($pid, 0);
        die "command timed out after ${timeout}s: @command\n" if $error eq "timeout\n";
        die $error;
    };
    my $status = ($raw & 127) ? 128 + ($raw & 127) : $raw >> 8;
    seek($out, 0, 0);
    seek($err, 0, 0);
    my $stdout = do { local $/; <$out> } // '';
    my $stderr = do { local $/; <$err> } // '';
    return ($status, $stdout, $stderr);
}

sub make_run {
    my ($expected, @arguments) = @_;
    my ($status, $stdout, $stderr) = run_command(120, @MAKE, @arguments);
    open(my $log, '>>', "$WORKSPACE/run.log") or die "open run.log: $!\n";
    print {$log} "exit=$status\n$stdout$stderr";
    close($log) or die "close run.log: $!\n";
    check($status == $expected, "make exit $status, expected $expected: $stderr");
    return ($stdout, $stderr);
}

# Digest of every non-directory entry of a ZIP archive, keyed by entry name.
sub zip_entries {
    my ($archive) = @_;
    my %entries;
    my $zip = IO::Uncompress::Unzip->new($archive) or die "cannot read $archive: $UnzipError\n";
    my $status = 1;
    while ($status > 0) {
        my $name = $zip->getHeaderInfo->{Name};
        if ($name !~ m{/\z}) {
            my $digest = Digest::SHA->new(256);
            my ($buffer, $count);
            $digest->add($buffer) while (($count = $zip->read($buffer, 65536)) > 0);
            $count < 0 and die "cannot read entry $name of $archive: $UnzipError\n";
            $entries{$name} = $digest->hexdigest;
        }
        $status = $zip->nextStream;
    }
    $status < 0 and die "cannot read $archive: $UnzipError\n";
    return \%entries;
}

sub snapshot {
    my ($install) = @_;
    my @lines;
    for my $directory ("$install/mgmt/webapps/mgmt", "$install/mgmt/log4j") {
        my %files = files_under($directory);
        push @lines, map { "$directory/$_\t" . digest_file("$directory/$_") } sort keys %files;
    }
    return join("\n", @lines);
}

sub copy_checkout {
    my ($root) = @_;
    my ($status, $stdout, $stderr) = run_command(60, 'git', '-C', $TOP, 'ls-files', '-z', '--cached', '--others', '--exclude-standard');
    $status == 0 or die "git ls-files failed: $stderr\n";
    for my $name (split /\0/, $stdout) {
        next unless $name eq 'Makefile' or $name =~ m{\A(?:configure|scripts|site-template)/};
        next unless -f "$TOP/$name";
        make_path(dirname("$root/$name"));
        copy("$TOP/$name", "$root/$name") or die "copy $name: $!\n";
    }
    return;
}

sub main {
    my @arguments = @_;
    local $ENV{LC_ALL} = 'C';
    my ($old_log4j_option, $help);
    GetOptionsFromArray(\@arguments, 'old-log4j=s' => \$old_log4j_option, 'help|h' => \$help) or return usage_error();
    if ($help) {
        pod2usage(-verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        return 0;
    }
    return usage_error('Expected OLD_TARGET and NEW_TARGET') unless @arguments == 2;
    return usage_error('--old-log4j is required') unless defined $old_log4j_option;
    my ($old_target, $new_target) = @arguments;
    my $old_log4j_source = $old_log4j_option;
    for my $directory ($old_target, $new_target, $old_log4j_source) {
        -d $directory or die "Not a directory: $directory\n";
    }
    -c '/dev/full' && -w _ or die "A writable /dev/full is required for the rollback check\n";
    my ($zip_status, undef, $zip_error) = run_command(10, 'zip', '-v');
    $zip_status == 0 or die "zip is required to prepare a real WAR without WEB-INF/web.xml: $zip_error\n";

    $WORKSPACE = tempdir('aa-reinstall-XXXXXXXX', DIR => temp_root(), CLEANUP => 0);
    my $root = "$WORKSPACE/checkout";
    make_path($root);
    copy_checkout($root);
    my $install = "$WORKSPACE/installed";
    my ($gid) = split ' ', $(;
    @MAKE = ('make', '--no-print-directory', '-s', '-C', $root, 'SUDO=', "AA_USERID=$<", "AA_GROUPID=$gid",
             "AA_INSTALL_LOCATION=$install");

    make_run(0, 'conf.context');
    my $old_log4j = "$WORKSPACE/old-log4j";
    make_path($old_log4j);
    for my $jar (glob_in($old_log4j_source, 'log4j-*.jar')) {
        copy($jar, "$old_log4j/" . basename($jar)) or die "copy $jar: $!\n";
    }
    my @old_jars = glob_in($old_log4j, '*.jar');
    check(@old_jars > 0, 'Real old log4j JARs are required');

    my %protected;
    my $storage = "$WORKSPACE/storage/config/database.sqlite";
    make_path(dirname($storage));
    spew($storage, 'filesystem preservation marker');
    $protected{$storage} = slurp($storage);

    my $new_log4j = "$new_target/tomcat-log4j";
    for my $service (@SERVICES) {
        my $index = 0;
        for my $pair ([$old_target, $old_log4j], [$new_target, $new_log4j]) {
            my ($target, $log4j) = @{$pair};
            my @war = glob_in($target, "*$service.war");
            check(@war == 1, 'Each target must contain exactly one real WAR per service');
            print "WAR $war[0] sha256=" . digest_file($war[0]) . "\n";
            make_run(0, "install.$service", 'ARCHAPPL_WARS_TARGET_PATH=' . abs_path($target),
                     'ARCHAPPL_TOMCAT_LOG4J_PATH=' . abs_path($log4j));
            # Only filesystem boundary fixtures are synthetic; both deployed WARs and the old and new JAR sets are real build artifacts.
            if ($index == 0) {
                for my $relative ('logs/operator.log', 'conf/operator.conf', 'log4j/operator.xml', 'work/operator.cache',
                                  'temp/operator.pid', 'webapps/other/index.html') {
                    my $path = "$install/$service/$relative";
                    make_path(dirname($path));
                    spew($path, "preserved operator state\n");
                    $protected{$path} = slurp($path);
                }
            }
            $index++;
        }

        my ($war) = glob_in($new_target, "*$service.war");
        my $destination = "$install/$service/webapps/$service";
        my $entries = zip_entries($war);
        my %actual = files_under($destination);
        my @stale = sort grep { !exists $entries->{$_} } keys %actual;
        my @missing = sort grep { !exists $actual{$_} } keys %{$entries};
        my @mismatched = sort grep { exists $actual{$_} and digest_file("$destination/$_") ne $entries->{$_} } keys %{$entries};
        my %expected_jars = map { basename($_) => 1 } glob_in($new_log4j, '*.jar');
        my %actual_jars = map { basename($_) => 1 } glob_in("$install/$service/log4j", '*.jar');
        my @stale_jars = sort grep { !exists $expected_jars{$_} } keys %actual_jars;
        printf "%s: stale WAR files=%d; missing=%d; mismatched=%d\n", $service, scalar(@stale), scalar(@missing), scalar(@mismatched);
        print "$service: stale logging JARs=" . python_list(@stale_jars) . "\n";
        check(!@stale && !@missing && !@mismatched, "WAR payload differs: stale @stale");
        check(join("\0", sort keys %actual_jars) eq join("\0", sort keys %expected_jars), 'Installed logging JARs differ from the new set');
        for my $name (sort keys %expected_jars) {
            check(digest_file("$install/$service/log4j/$name") eq digest_file("$new_log4j/$name"), "Logging JAR differs: $name");
        }
        my @leaked = bsd_glob("$install/$service/.payload.*");
        check(!@leaked, 'Staging directory leaked');
    }

    my $before = snapshot($install);
    my $empty = "$WORKSPACE/empty";
    make_path($empty);
    my $ambiguous = "$WORKSPACE/ambiguous";
    make_path($ambiguous);
    my $position = 0;
    for my $target ($old_target, $new_target) {
        my ($mgmt) = glob_in($target, '*mgmt.war');
        symlink(abs_path($mgmt), "$ambiguous/$position-mgmt.war") or die "symlink: $!\n";
        $position++;
    }
    my $corrupt = "$WORKSPACE/corrupt";
    make_path($corrupt);
    my ($mgmt_war) = glob_in($new_target, '*mgmt.war');
    open(my $original, '<:raw', $mgmt_war) or die "open $mgmt_war: $!\n";
    read($original, my $head, 100) // die "read $mgmt_war: $!\n";
    close($original) or die "close $mgmt_war: $!\n";
    spew("$corrupt/broken-mgmt.war", $head);

    my $missing_webxml = "$WORKSPACE/missing-webxml";
    make_path($missing_webxml);
    my $missing_webxml_war = "$missing_webxml/missing-mgmt.war";
    copy($mgmt_war, $missing_webxml_war) or die "copy $mgmt_war: $!\n";
    my ($delete_status, $delete_stdout, $delete_stderr) = run_command(120, 'zip', '-q', '-d', $missing_webxml_war, 'WEB-INF/web.xml');
    check($delete_status == 0, "Cannot remove WEB-INF/web.xml from the real WAR: $delete_stdout$delete_stderr");
    my $missing_entries = zip_entries($missing_webxml_war);
    check(!exists $missing_entries->{'WEB-INF/web.xml'}, 'The missing-web.xml fixture still contains WEB-INF/web.xml');

    # A prefixed copy still extracts real application bytes, but unzip reports a nonzero warning.
    my $prefixed = "$WORKSPACE/prefixed";
    make_path($prefixed);
    my $prefixed_war = "$prefixed/prefixed-mgmt.war";
    open(my $source, '<:raw', $mgmt_war) or die "open $mgmt_war: $!\n";
    open(my $destination, '>:raw', $prefixed_war) or die "open $prefixed_war: $!\n";
    print {$destination} "Invalid ZIP prefix\n" or die "write $prefixed_war: $!\n";
    my ($buffer, $count);
    while (($count = read($source, $buffer, 65536))) {
        print {$destination} $buffer or die "write $prefixed_war: $!\n";
    }
    defined $count or die "read $mgmt_war: $!\n";
    close($source) or die "close $mgmt_war: $!\n";
    close($destination) or die "close $prefixed_war: $!\n";
    my $probe = "$WORKSPACE/prefixed-extraction";
    my ($extract_status, $extract_stdout, $extract_stderr) = run_command(120, 'unzip', '-q', $prefixed_war, '-d', $probe);
    print "Prefixed WAR extraction: exit=$extract_status\n$extract_stdout$extract_stderr";
    check($extract_status == 1 && index($extract_stdout . $extract_stderr, 'extra bytes') >= 0,
          'The prefixed WAR must produce the real unzip warning');
    check(-s "$probe/WEB-INF/web.xml", 'The prefixed WAR must extract WEB-INF/web.xml before reporting failure');
    check(digest_file("$probe/WEB-INF/web.xml") eq digest_file("$install/mgmt/webapps/mgmt/WEB-INF/web.xml"),
          'The prefixed WAR changed the real WEB-INF/web.xml');

    for my $case (['missing WAR', $empty, $new_log4j, ''], ['ambiguous WARs', $ambiguous, $new_log4j, ''],
                  ['truncated WAR', $corrupt, $new_log4j, ''],
                  ['missing JARs', $new_target, $empty, 'Missing Tomcat log4j JARs; build the source first.'],
                  ['missing WEB-INF/web.xml', $missing_webxml, $new_log4j, 'WAR has no WEB-INF/web.xml.'],
                  ['prefixed WAR', $prefixed, $new_log4j, '']) {
        my ($label, $target, $jars, $diagnostic) = @{$case};
        print "Checking: $label\n";
        my (undef, $stderr) = make_run(2, 'install.mgmt', 'ARCHAPPL_WARS_TARGET_PATH=' . abs_path($target),
                                     'ARCHAPPL_TOMCAT_LOG4J_PATH=' . abs_path($jars));
        check(index($stderr, $diagnostic) >= 0, "Missing diagnostic after $label: $diagnostic") if $diagnostic ne '';
        check(snapshot($install) eq $before, "Existing payload changed after $label");
        my @leaked = bsd_glob("$install/mgmt/.payload.*");
        check(!@leaked, "Staging directory leaked after $label");
        print "PASS: $label rejected; existing payload preserved.\n";
    }

    # The Make command prefix only redirects stdout; every original command still executes.
    spew("$root/scripts/full-output.pl", q{use strict;
use warnings;
if (@ARGV >= 3 && $ARGV[0] eq 'bash' && $ARGV[1] eq '-p' && $ARGV[2] eq 'scripts/install-payload.bash') {
    open(STDOUT, '>', '/dev/full') or die "open /dev/full: $!\n";
}
exec { $ARGV[0] } @ARGV or die "exec $ARGV[0]: $!\n";
});
    print "Checking: rollback after final output failure\n";
    my (undef, $rollback_stderr) = make_run(2, 'install.mgmt', "SUDO=$^X scripts/full-output.pl",
                                          'ARCHAPPL_WARS_TARGET_PATH=' . abs_path($old_target),
                                          'ARCHAPPL_TOMCAT_LOG4J_PATH=' . abs_path($old_log4j));
    check($rollback_stderr =~ /install-payload[.]bash: line [0-9]+: printf: write error:/,
          'The payload installer did not reach its final write to /dev/full');
    check(snapshot($install) eq $before, 'Existing payload was not restored after final output failure');
    my @rollback_stages = bsd_glob("$install/mgmt/.payload.*");
    check(!@rollback_stages, 'Staging directory leaked after final output failure');
    print "PASS: final output failure restored the previous WAR and JAR contents.\n";

    my $link = "$WORKSPACE/linked-instance";
    symlink("$install/mgmt", $link) or die "symlink: $!\n";
    # A path that climbs from the workspace to the filesystem root, whatever the depth of the workspace. A path that
    # does not resolve to the root would make the installer act on a real directory, so the test stops instead.
    my $depth = () = abs_path($WORKSPACE) =~ m{/}g;
    my $root_alias = $WORKSPACE . ('/..' x $depth);
    (abs_path($root_alias) // '') eq '/' or die "The root alias does not resolve to the filesystem root: $root_alias\n";
    for my $case (['/', 'mgmt', 'absolute non-root path'], [$root_alias, 'mgmt', 'resolves to the filesystem root'],
                  [$link, 'mgmt', 'must not be a symlink'], ["$install/mgmt", '../other', 'Unknown appliance service']) {
        my ($instance, $service, $reason) = @{$case};
        my ($status, $stdout, $stderr) = run_command(10, 'bash', '-p', "$root/scripts/install-payload.bash", $instance, $service,
                                                      abs_path($new_target), abs_path($new_log4j));
        check($status == 1 && index($stderr, $reason) >= 0, "Unexpected result for '$reason': status $status, $stderr");
        check(snapshot($install) eq $before, 'Path rejection changed the installed payload');
    }
    print "PASS: root, root alias, symlink and invalid service destinations rejected.\n";
    for my $path (sort keys %protected) {
        check(slurp($path) eq $protected{$path}, "Operator state changed: $path");
    }
    print "PASS: all four installed WARs and JAR sets match; operator state survived; invalid input preserved the payload.\n";
    finish_workspace($WORKSPACE, 1);
    return 0;
}

sub usage_error {
    my ($message) = @_;
    print STDERR "install-payload.pl: $message\n" if defined $message;
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
    finish_workspace($WORKSPACE, 0) if defined $WORKSPACE;
    if ($error =~ s/\AASSERTION: //) {
        print STDERR "FAIL: $error";
        $status = 1;
    }
    else {
        print STDERR "install-payload.pl: $error";
        $status = 2;
    }
};
exit $status;
