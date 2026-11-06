#!/usr/bin/env perl
# Runs the inspection CLI against files produced by the shipped install rules and real Maven artifacts.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname basename);
use File::Copy qw(copy);
use File::Find ();
use File::Glob qw(bsd_glob);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray);
use IO::Handle;
use JSON::PP;
use Pod::Usage qw(pod2usage);
use POSIX ();
use Test::More;

=head1 NAME

local-install-inspect.pl - check the installed-appliance inspection using real install rules

=head1 SYNOPSIS

  AA_TEST_TOMCAT_HOME=/path/to/tomcat perl tests/local-install-inspect.pl
  perl tests/local-install-inspect.pl --tomcat-home /path/to/tomcat --case unchanged
  perl tests/local-install-inspect.pl --helper /path/to/scratch/helper.bash --case configuration

=head1 DESCRIPTION

Copies the shipped Make inputs into a retained workspace, clones the supplied source locally, and runs db.conf,
conf.archapplproperties, conf.install, services.install, serveroption.install, install.systemd and conf.storage with
all destinations below that workspace and the current user/group. The four real WARs and logging JARs come from the
supplied Maven target directory. No systemd reload, service start, schema load, package install or sudo runs.

The copied server.xml template is restricted to mode 0600 before the real installation; installed server.xml files
must have mode 0644 so the checkout owner can inspect them after ownership changes to the service account.
Invokes the complete inspection script with --skip-runtime and --no-sudo. Cases cover installed permissions, an unchanged installation,
missing version.txt, absent WARs, changed source, configuration, classpath selection, systemd files, source schema,
storage, the skipped runtime observation, refusals and usage errors. Schema cases create commits only in the temporary
source clone. They test classification and acceptance, not database loading. Runtime checks establish only the
explicitly skipped observation contract, not live health or HTTP readiness.

Every command has a 120-second timeout and retains its arguments, stdout, stderr, native status and UTC bounds before
assertions run. Source hashes, installed snapshots and TAP are retained under work/m17-inspection/inspect-* even after
success. Missing prerequisites or interrupted commands are environment errors, never passing or skipped assertions.
Requires real Java and readable Tomcat, Bash, Git, Make, coreutils, diffutils (cmp), unzip, and Perl with Test::More, JSON::PP and
Digest::SHA. The language baseline is Perl 5.26.3; a run on a newer host does not verify that baseline.

=head1 OPTIONS

=over 4

=item B<--source-dir> DIR

Source Git repository. Defaults to AA_TEST_SOURCE_PATH or epicsarchiverap-maven-src below this checkout.

=item B<--war-dir> DIR

Real Maven target directory. Defaults to the supplied source directory's target subdirectory.

=item B<--tomcat-home> DIR

Readable Tomcat directory. Defaults to AA_TEST_TOMCAT_HOME; one of these is required.

=item B<--helper> FILE

Complete inspection script, optionally a scratch mutation. Defaults to the shipped helper.

=item B<--java-home> DIR

Real JDK directory. Defaults to JAVA_HOME or the resolved location of /usr/bin/java.

=item B<--case> NAME

Run only this case; repeat to select several. --help lists all names.

=item B<--help>

Print usage and case names, then exit 0.

=back

=head1 EXIT STATUS

0 when every selected assertion passed; 1 for an observed assertion failure; 2 for invalid usage or incomplete
execution. If incomplete execution follows an observed assertion failure, the result remains failed (1).

=cut

my $TOP = abs_path(dirname(abs_path($0)) . '/..');
my @SERVICES = qw(mgmt engine etl retrieval);
my @LAYERS = qw(program configuration systemd schema storage);
my @CONFIG = qw(archappl.conf appliances.xml archappl.properties policies.py archappl.bash archappl-config.bash);
my @CLASSPATH = qw(ARCHAPPL_APPLIANCES ARCHAPPL_PROPERTIES_FILENAME ARCHAPPL_POLICIES);
my @REQUIRED_TOOLS = qw(bash git make timeout unzip sha256sum cmp awk comm sort grep sed stat cp install chown);
my @TOOL_PATH = qw(/usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin);
my $APP = 'epicsarchiverap-maven';
my $SQL = 'src/main/org/epics/archiverappliance/config/persistence/archappl_sqlite.sql';
my $JSON = JSON::PP->new->canonical->pretty;
my ($WORK, $CHECKOUT, $SOURCE, $INSTALL, $SYSTEMD, $RENDERED, $COMMIT, $HELPER, $WAR, $USER, $JAVA_HOME);
my (@INSPECT, @STORES, @WAR_FILES);
my $sequence = 0;
$| = 1;

sub slurp {
    my ($path) = @_;
    open(my $fh, '<:raw', $path) or die "open $path: $!\n";
    local $/;
    my $data = <$fh>;
    close($fh) or die "close $path: $!\n";
    return $data // '';
}

sub spew {
    my ($path, $data) = @_;
    open(my $fh, '>:raw', $path) or die "open $path: $!\n";
    print {$fh} $data or die "write $path: $!\n";
    close($fh) or die "close $path: $!\n";
    return;
}

sub stamp {
    return POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime);
}

# Persists native output and status before returning; timeout and signal outcomes are incomplete execution.
sub run {
    my (@command) = @_;
    my $prefix = sprintf('%s/commands/%04d', $WORK, ++$sequence);
    my $receipt = { command => \@command, started => stamp(), timeout_seconds => 120 };
    spew("$prefix.json", $JSON->encode($receipt));
    my $pid = fork();
    defined $pid or die "fork: $!\n";
    if (!$pid) {
        chdir($WORK) or POSIX::_exit(126);
        open(STDIN, '<', '/dev/null') or POSIX::_exit(126);
        open(STDOUT, '>:raw', "$prefix.stdout") or POSIX::_exit(126);
        open(STDERR, '>:raw', "$prefix.stderr") or POSIX::_exit(126);
        delete @ENV{qw(MAKEFLAGS MFLAGS MAKEOVERRIDES BASH_ENV ENV CDPATH)};
        $ENV{LC_ALL} = 'C';
        exec { 'timeout' } 'timeout', '--kill-after=5s', '120s', @command or POSIX::_exit(127);
    }
    my ($waited, $raw, $interrupted);
    eval {
        do { $waited = waitpid($pid, 0) } while ($waited == -1 && $! == POSIX::EINTR());
        $waited == $pid or die "waitpid $pid: $!\n";
        $raw = $?;
        1;
    } or do {
        $interrupted = $@;
        # timeout owns its process group; target the PID too if interruption preceded its setup.
        kill('TERM', -$pid);
        kill('TERM', $pid);
        do { $waited = waitpid($pid, 0) } while ($waited == -1 && $! == POSIX::EINTR());
        $raw = $?;
    };
    $receipt->{signal} = $raw & 127;
    $receipt->{status} = ($raw & 127) ? 128 + ($raw & 127) : $raw >> 8;
    $receipt->{finished} = stamp();
    $receipt->{interrupted} = $interrupted if defined $interrupted;
    spew("$prefix.json", $JSON->encode($receipt));
    die $interrupted if defined $interrupted;
    my $result = { %{$receipt}, stdout => slurp("$prefix.stdout"), stderr => slurp("$prefix.stderr") };
    die "Incomplete command ($result->{status}): see $prefix\n"
        if $receipt->{signal} || $receipt->{status} == 124 || $receipt->{status} >= 126;
    return $result;
}

sub must_run {
    my (@command) = @_;
    my $result = run(@command);
    die "Preparation failed ($result->{status}): @command\n$result->{stderr}\n" if $result->{status};
    return $result->{stdout};
}

sub copy_input {
    my ($from, $to) = @_;
    make_path(dirname($to));
    copy($from, $to) or die "copy $from to $to: $!\n";
    chmod((stat($from))[2] & 07777, $to) or die "chmod $to: $!\n";
    return;
}

sub check_tools {
    my () = @_;
    my %paths;
    for my $tool (@REQUIRED_TOOLS) {
        my ($path) = grep { -f $_ && -x _ } map { "$_/$tool" } @TOOL_PATH;
        die "Missing prerequisite: $tool\n" unless defined $path;
        $paths{$tool} = abs_path($path);
    }
    spew("$WORK/tools.json", $JSON->encode(\%paths));
    return;
}

# Builds the installed fixture using the current shipped rules, without rewriting their internals.
sub prepare {
    my ($source, $tomcat) = @_;
    $CHECKOUT = "$WORK/checkout";
    $SOURCE = "$CHECKOUT/epicsarchiverap-maven-src";
    $INSTALL = "$WORK/opt/$APP";
    $SYSTEMD = "$WORK/systemd";
    $RENDERED = "$CHECKOUT/site-template";
    @STORES = map { "$WORK/storage$_" } ('', '/sts/ArchiverStore', '/mts/ArchiverStore', '/lts/ArchiverStore');
    make_path($CHECKOUT, $INSTALL, $SYSTEMD);
    $USER = getpwuid($<) // die "cannot resolve uid $<\n";
    my $group = must_run('id', '-gn');
    chomp $group;
    my $files = must_run('git', '-C', $TOP, 'ls-files', '-z', '--', 'Makefile', 'configure', 'scripts', 'site-template');
    my @hashes;
    for my $relative (split /\0/, $files) {
        copy_input("$TOP/$relative", "$CHECKOUT/$relative");
        push @hashes, sha256_hex(slurp("$TOP/$relative")) . "  $relative\n";
    }
    chmod(0600, "$RENDERED/skel/conf/server.xml") or die "chmod $RENDERED/skel/conf/server.xml: $!\n";
    push @hashes, sha256_hex(slurp(abs_path($0))) . "  tests/local-install-inspect.pl\n";
    spew("$WORK/source.sha256", join('', @hashes));
    copy_input($HELPER, "$WORK/helper.bash");
    spew("$WORK/helper.sha256", sha256_hex(slurp($HELPER)) . "  $HELPER\n");
    $COMMIT = must_run('git', '-C', $source, 'rev-parse', 'HEAD');
    chomp $COMMIT;
    must_run('git', 'clone', '--quiet', '--no-hardlinks', '--no-checkout', $source, $SOURCE);
    must_run('git', '-C', $SOURCE, 'checkout', '--quiet', '--detach', $COMMIT);
    for my $service (@SERVICES) {
        my @files = grep { -f $_ } bsd_glob("$WAR/*-" . substr($COMMIT, 0, 8) . "-$service.war");
        @files == 1 or die "Need exactly one real WAR of $COMMIT for $service in $WAR\n";
        push @WAR_FILES, $files[0];
    }
    spew("$WORK/artifacts.sha256", must_run('sha256sum', @WAR_FILES,
        grep { -f $_ } bsd_glob("$WAR/tomcat-log4j/*.jar")));
    my @make = ('make', '--no-print-directory', '-j1', '-C', $CHECKOUT, "AA_INSTALL_PATH=$WORK/opt",
        "AA_USERID=$USER", "AA_GROUPID=$group", "SYSTEMD_PATH=$SYSTEMD", 'ARCHAPPL_SITEID=als',
        'DB_BACKEND=sqlite', "JAVA_HOME=$JAVA_HOME", "TOMCAT_HOME=$tomcat", "ARCHAPPL_WARS_TARGET_PATH=$WAR",
        "ARCHAPPL_STORAGE_TOP=$STORES[0]", "ARCHAPPL_SHORT_TERM_FOLDER=$STORES[1]",
        "ARCHAPPL_MEDIUM_TERM_FOLDER=$STORES[2]", "ARCHAPPL_LONG_TERM_FOLDER=$STORES[3]");
    must_run(@make, 'db.conf', 'conf.archapplproperties', 'conf.install');
    must_run(@make, 'services.install', 'serveroption.install');
    must_run(@make, 'install.systemd', 'conf.storage');
    @INSPECT = ('--install-dir', $INSTALL, '--systemd-dir', $SYSTEMD, '--rendered-dir', $RENDERED,
        '--scripts-dir', "$CHECKOUT/scripts", '--source-dir', $SOURCE, '--war-dir', $WAR, '--sql-file', $SQL,
        '--service-user', $USER, '--service-unit', "$APP.service", '--health-timer', "$APP-health.timer",
        '--skip-runtime', '--no-sudo');
    push @INSPECT, ('--storage-dir', $_) for @STORES;
    for my $index (0 .. $#SERVICES) {
        push @INSPECT, ('--port', "$SERVICES[$index]=" . (17665 + $index), '--shutdown-port', "$SERVICES[$index]=-1");
    }
    spew("$WORK/environment.json", $JSON->encode({ source_commit => $COMMIT, perl => "$^V", user => $USER,
        tomcat => $tomcat, java_home => $JAVA_HOME, helper => $HELPER, war_dir => $WAR }));
    return;
}

# Checks the CLI contract, retaining malformed or partial output as an assertion failure.
sub inspect {
    my ($label, $expected_status, %changes) = @_;
    my @args = @INSPECT;
    for my $index (0 .. $#args - 1) {
        $args[$index + 1] = $changes{$args[$index]} if exists $changes{$args[$index]};
    }
    push @args, '--accept-schema' if $changes{accept_schema};
    my $result = run('bash', "$WORK/helper.bash", @args);
    is($result->{status}, $expected_status, "$label: exit status");
    is($result->{stderr}, '', "$label: stderr");
    my %rows;
    for my $line (split /\n/, $result->{stdout}) {
        next if $line =~ /^#/;
        my ($name, $state, $reason) = split /\t/, $line, 3;
        ok(!exists $rows{$name}, "$label: unique $name row");
        $rows{$name} = { state => $state, reason => $reason // '' };
    }
    is_deeply([sort keys %rows], [sort ('installation', 'build', 'runtime', @LAYERS)], "$label: complete rows");
    return (\%rows, $result);
}

sub state_is {
    my ($rows, $layer, $expected, $label) = @_;
    is($rows->{$layer}{state}, $expected, "$label: $layer state");
    return;
}

# A byte, membership and metadata snapshot excludes access times, which reads may update.
sub snapshot {
    my () = @_;
    my %entries;
    File::Find::find({ no_chdir => 1, wanted => sub {
        my $path = $File::Find::name;
        my @st = lstat($path);
        @st or die "lstat $path: $!\n";
        $entries{$path} = { mode => $st[2], uid => $st[4], gid => $st[5], size => $st[7], mtime => $st[9],
            content => -l _ ? readlink($path) : -f _ ? sha256_hex(slurp($path)) : '' };
        return;
    } }, $INSTALL, $SYSTEMD, $RENDERED, $STORES[0]);
    return \%entries;
}

sub with_bytes {
    my ($path, $bytes, $callback) = @_;
    my $original = slurp($path);
    spew($path, $bytes);
    my $ok = eval { $callback->(); 1 };
    my $error = $@;
    spew($path, $original);
    die $error unless $ok;
    return;
}

sub with_absent {
    my ($path, $callback) = @_;
    my $saved = "$WORK/absent-" . ++$sequence;
    rename($path, $saved) or die "rename $path to $saved: $!\n";
    my $ok = eval { $callback->(); 1 };
    my $error = $@;
    rename($saved, $path) or die "restore $path: $!\n";
    die $error unless $ok;
    return;
}

sub with_mode {
    my ($path, $mode, $callback) = @_;
    my @st = stat($path);
    @st or die "stat $path: $!\n";
    chmod($mode, $path) or die "chmod $path: $!\n";
    my $ok = eval { $callback->(); 1 };
    my $error = $@;
    chmod($st[2] & 07777, $path) or die "restore mode $path: $!\n";
    die $error unless $ok;
    return;
}

# Commits a controlled source input only inside this run's independent clone.
sub source_change {
    my ($path, $bytes, $callback) = @_;
    spew("$SOURCE/$path", $bytes);
    must_run('git', '-C', $SOURCE, '-c', 'user.name=Inspection Test', '-c', 'user.email=inspection@example.invalid',
        '-c', 'core.hooksPath=/dev/null', '-c', 'commit.gpgSign=false', 'commit', '--quiet', '-m', 'Inspection fixture', '--', $path);
    my $ok = eval { $callback->(); 1 };
    my $error = $@;
    must_run('git', '-C', $SOURCE, 'checkout', '--quiet', '--detach', $COMMIT);
    die $error unless $ok;
    return;
}

my @CASES = (
    ['installed_permissions', sub {
        is((stat("$RENDERED/skel/conf/server.xml"))[2] & 07777, 0600, 'source server.xml has restrictive checkout permissions');
        for my $service (@SERVICES) {
            is((stat("$INSTALL/$service/conf/server.xml"))[2] & 07777, 0644,
                "$service server.xml is installed with explicit read permissions");
        }
    }],
    ['unchanged', sub {
        my $before = snapshot();
        spew("$WORK/unchanged-before.json", $JSON->encode($before));
        my ($rows) = inspect('unchanged', 0);
        state_is($rows, $_, 'unchanged', 'unchanged') for @LAYERS;
        state_is($rows, 'installation', 'present', 'unchanged');
        state_is($rows, 'build', 'not-needed', 'unchanged');
        is(slurp("$INSTALL/.versions"), slurp("$RENDERED/.versions"), 'installed source record matches rendering');
        my $after = snapshot();
        spew("$WORK/unchanged-after.json", $JSON->encode($after));
        is_deeply($after, $before, 'inspection leaves input bytes, membership and metadata unchanged');
    }],
    ['first', sub {
        with_absent("$INSTALL/mgmt/webapps/mgmt/ui/comm/version.txt", sub {
            my ($rows) = inspect('first', 0);
            state_is($rows, 'installation', 'first', 'first');
            state_is($rows, $_, 'changed', 'first') for @LAYERS;
            state_is($rows, 'build', 'needed', 'first');
        });
    }],
    ['missing_wars', sub {
        for my $missing ('all', @SERVICES) {
            my $dir = "$WORK/war-without-$missing";
            make_path($dir);
            for my $path (@WAR_FILES) {
                next if $missing eq 'all' || $path =~ /-\Q$missing\E\.war\z/;
                symlink($path, "$dir/" . basename($path)) or die "symlink $path: $!\n";
            }
            my ($rows) = inspect("missing WAR $missing", 0, '--war-dir' => $dir);
            state_is($rows, 'program', 'unchanged', "missing WAR $missing");
            state_is($rows, 'build', 'needed', "missing WAR $missing");
            like($rows->{build}{reason}, qr/no WAR of commit/, "missing WAR $missing: reason");
        }
    }],
    ['program', sub {
        source_change('pom.xml', slurp("$SOURCE/pom.xml") . "\n", sub {
            my ($rows) = inspect('changed source', 0);
            state_is($rows, 'program', 'changed', 'changed source');
            state_is($rows, 'schema', 'unchanged', 'changed source');
            state_is($rows, 'build', 'needed', 'changed source');
        });
    }],
    ['configuration', sub {
        my @files = (@CONFIG, map { ("$_/conf/context.xml", "$_/conf/$_.conf") } @SERVICES);
        for my $relative (@files) {
            my $path = "$INSTALL/$relative";
            with_bytes($path, slurp($path) . "\n", sub {
                my ($rows) = inspect("configuration $relative", 0);
                state_is($rows, 'configuration', 'changed', "configuration $relative");
                state_is($rows, 'build', 'not-needed', "configuration $relative");
                like($rows->{configuration}{reason}, qr/\Q$relative\E/, "configuration $relative: reason");
            });
        }
        my ($rows) = inspect('connector port', 0, '--port' => 'mgmt=27665');
        state_is($rows, 'configuration', 'changed', 'connector port');
        ($rows) = inspect('shutdown port', 0, '--shutdown-port' => 'mgmt=27666');
        state_is($rows, 'configuration', 'changed', 'shutdown port');
        with_absent("$INSTALL/mgmt/conf/server.xml", sub {
            my ($result) = inspect('missing server.xml', 0);
            state_is($result, 'configuration', 'changed', 'missing server.xml');
        });
    }],
    ['unreadable', sub {
        my @files = (
            (map { ["$INSTALL/$_/conf/server.xml", 'configuration'] } @SERVICES),
            ["$INSTALL/archappl.properties", 'configuration'],
            ["$RENDERED/archappl.properties", 'configuration'],
            ["$INSTALL/archappl.conf", 'configuration'],
            ["$SYSTEMD/$APP.service", 'systemd'],
            ["$RENDERED/systemd/$APP.service", 'systemd'],
            ["$INSTALL/mgmt/webapps/mgmt/ui/comm/version.txt", 'program'],
        );
        my $before = snapshot();
        for my $entry (@files) {
            my ($path, $layer) = @{$entry};
            with_mode($path, 0000, sub {
                ok(-f $path && !-r $path, "unreadable $path: real permission failure");
                my ($rows) = inspect("unreadable $path", 1);
                state_is($rows, $layer, 'refuse', "unreadable $path");
                state_is($rows, 'installation', 'present', "unreadable $path");
                like($rows->{$layer}{reason}, qr/cannot read.*\Q$path\E/, "unreadable $path: diagnostic names input");
                state_is($rows, 'schema', 'refuse', 'unknown installed version') if $layer eq 'program';
            });
        }
        is_deeply(snapshot(), $before, 'permission faults restore input bytes, membership and metadata');
    }],
    ['inaccessible_directories', sub {
        my @directories = (
            ["$INSTALL/mgmt/webapps/mgmt/ui/comm", 'program', 0400],
            ["$INSTALL/mgmt/webapps", 'program', 0400],
            (map { ["$INSTALL/$_/conf", 'configuration', 0400] } @SERVICES),
            [$RENDERED, 'configuration', 0400],
            ["$RENDERED/systemd", 'systemd', 0111],
            [$SYSTEMD, 'systemd', 0400],
            ["$SYSTEMD/tomcat9.service.d", 'systemd', 0400],
        );
        my $before = snapshot();
        for my $entry (@directories) {
            my ($path, $layer, $mode) = @{$entry};
            with_mode($path, $mode, sub {
                ok(-d $path && (!-r $path || !-x $path), "inaccessible $path: real permission failure");
                my ($rows) = inspect("inaccessible $path", 1);
                state_is($rows, $layer, 'refuse', "inaccessible $path");
                state_is($rows, 'installation', 'present', "inaccessible $path");
                like($rows->{$layer}{reason}, qr/cannot .*\Q$path\E/, "inaccessible $path: diagnostic names directory");
                state_is($rows, 'schema', 'refuse', 'unknown installed version') if $layer eq 'program';
            });
        }
        with_mode("$INSTALL/engine/conf", 0111, sub {
            ok(!-r "$INSTALL/engine/conf" && -x _, 'known filenames need search access, not directory listing');
            my ($rows) = inspect('searchable configuration directory', 0);
            state_is($rows, 'configuration', 'unchanged', 'searchable configuration directory');
        });
        is_deeply(snapshot(), $before, 'directory faults restore input bytes, membership and metadata');
        with_absent("$INSTALL/mgmt/webapps", sub {
            my ($rows) = inspect('missing version parent', 0);
            state_is($rows, 'installation', 'first', 'missing version parent');
        });
    }],
    ['classpath', sub {
        for my $variable (@CLASSPATH) {
            my $bytes = slurp("$INSTALL/archappl.conf");
            $bytes =~ s/^\Q$variable\E=.*\n//m or die "Missing fixture binding $variable\n";
            with_bytes("$INSTALL/archappl.conf", $bytes, sub {
                my ($rows) = inspect("classpath $variable", 0);
                state_is($rows, 'program', 'changed', "classpath $variable");
                state_is($rows, 'build', 'needed', "classpath $variable");
            });
        }
    }],
    ['systemd', sub {
        for my $relative ("$APP.service", "$APP-health.service", "$APP-health.timer", 'tomcat9.service.d/override.conf') {
            my $path = "$SYSTEMD/$relative";
            with_bytes($path, slurp($path) . "\n# Inspection input change.\n", sub {
                my ($rows) = inspect("systemd $relative", 0);
                state_is($rows, 'systemd', 'changed', "systemd $relative");
            });
            with_absent($path, sub {
                my ($rows) = inspect("missing systemd $relative", 0);
                state_is($rows, 'systemd', 'changed', "missing systemd $relative");
            });
        }
    }],
    ['schema', sub {
        my $original = slurp("$SOURCE/$SQL");
        source_change($SQL, $original . "\nCREATE TABLE InspectionFixture (id INTEGER PRIMARY KEY);\n", sub {
            my ($rows) = inspect('added table', 0);
            state_is($rows, 'schema', 'changed', 'added table');
            like($rows->{schema}{reason}, qr/only whole tables are added.*InspectionFixture/, 'added table: load reason');
        });
        (my $changed = $original) =~ s/typeInfoJSON TEXT/typeInfoJSON BLOB/
            or die "Cannot locate the source column for the schema input\n";
        source_change($SQL, $changed, sub {
            my ($rows, $result) = inspect('changed column', 1);
            state_is($rows, 'schema', 'refuse', 'changed column');
            like($result->{stdout}, qr/^# schema diff: .*typeInfoJSON BLOB/m, 'changed column: real diff');
            ($rows, $result) = inspect('accepted column', 0, accept_schema => 1);
            state_is($rows, 'schema', 'changed', 'accepted column');
            like($rows->{schema}{reason}, qr/accepted with --accept-schema/, 'accepted column: reason');
        });
    }],
    ['storage', sub {
        for my $path (@STORES) {
            with_absent($path, sub {
                my ($rows) = inspect("missing storage $path", 0);
                state_is($rows, 'storage', 'changed', "missing storage $path");
                like($rows->{storage}{reason}, qr/missing: \Q$path\E/, "missing storage $path: reason");
            });
        }
        my ($rows) = inspect('storage owner', 0, '--service-user' => 'root');
        state_is($rows, 'storage', 'changed', 'storage owner');
        like($rows->{storage}{reason}, qr/is owned by \Q$USER\E, not root/, 'storage owner: reason');
    }],
    ['runtime', sub {
        my ($rows) = inspect('runtime skipped', 0);
        state_is($rows, 'runtime', 'observed', 'runtime skipped');
        is($rows->{runtime}{reason}, 'not observed: skipped', 'runtime skipped: explicit limitation');
    }],
    ['refusals', sub {
        my $version = "$INSTALL/mgmt/webapps/mgmt/ui/comm/version.txt";
        with_bytes($version, "invalid version\n", sub {
            my ($rows) = inspect('invalid version', 1);
            state_is($rows, 'program', 'refuse', 'invalid version');
        });
        my $payload = "$INSTALL/mgmt/.payload.inspection-test";
        make_path($payload);
        my ($rows) = inspect('retained payload', 1);
        state_is($rows, 'program', 'refuse', 'retained payload');
        rename($payload, "$WORK/retained-payload") or die "move $payload: $!\n";
        for my $variable (qw(JAVA_HOME CATALINA_HOME)) {
            my $bytes = slurp("$RENDERED/archappl.conf");
            $bytes =~ s{^\Q$variable\E=.*}{$variable="$WORK/missing-runtime"}m
                or die "Missing fixture binding $variable\n";
            with_bytes("$RENDERED/archappl.conf", $bytes, sub {
                my ($result) = inspect("missing $variable", 1);
                state_is($result, 'configuration', 'refuse', "missing $variable");
            });
        }
    }],
    ['usage', sub {
        my $result = run('bash', "$WORK/helper.bash", '--help');
        is($result->{status}, 0, 'helper help exits successfully');
        for my $args ([], ['--unknown'], ['--install-dir']) {
            $result = run('bash', "$WORK/helper.bash", @{$args});
            is($result->{status}, 2, 'invalid helper arguments exit 2');
            like($result->{stderr}, qr/^inspect-local-install:/, 'invalid helper arguments have a diagnostic');
        }
    }],
);

sub main {
    my (@arguments) = @_;
    my $source = $ENV{AA_TEST_SOURCE_PATH} // "$TOP/epicsarchiverap-maven-src";
    my $tomcat = $ENV{AA_TEST_TOMCAT_HOME};
    $JAVA_HOME = $ENV{JAVA_HOME};
    my ($help, @wanted);
    $HELPER = "$TOP/scripts/inspect-local-install.bash";
    GetOptionsFromArray(\@arguments, 'help' => \$help, 'source-dir=s' => \$source, 'war-dir=s' => \$WAR,
        'tomcat-home=s' => \$tomcat, 'java-home=s' => \$JAVA_HOME, 'helper=s' => \$HELPER,
        'case=s' => \@wanted) or return 2;
    if ($help) {
        pod2usage(-verbose => 1, -exitval => 'NOEXIT', -output => \*STDOUT);
        print "\nCases:\n", map { "  $_->[0]\n" } @CASES;
        return 0;
    }
    die "Unexpected arguments: @arguments\n" if @arguments;
    my %known = map { $_->[0] => 1 } @CASES;
    die "Unknown case: $_\n" for grep { !$known{$_} } @wanted;
    die "Run as an ordinary user\n" if $< == 0;
    die "Set --tomcat-home or AA_TEST_TOMCAT_HOME to readable Tomcat\n" unless defined $tomcat && -r "$tomcat/conf/server.xml";
    $JAVA_HOME //= dirname(dirname(abs_path('/usr/bin/java') // die "Set --java-home to a real JDK\n"));
    die "No executable Java in $JAVA_HOME\n" unless -x "$JAVA_HOME/bin/java";
    $WAR //= "$source/target";
    for my $path (\$source, \$WAR, \$tomcat, \$HELPER, \$JAVA_HOME) {
        $$path = abs_path($$path) // die "Cannot resolve $$path\n";
        die "Make fixture paths must not contain whitespace: $$path\n" if $$path =~ /\s/;
    }
    make_path("$TOP/work/m17-inspection");
    $WORK = tempdir('inspect-XXXXXXXX', DIR => "$TOP/work/m17-inspection", CLEANUP => 0);
    make_path("$WORK/commands");
    print "# Evidence: $WORK\n";
    open(my $tap, '>', "$WORK/test.tap") or die "open test.tap: $!\n";
    Test::More->builder->output($tap);
    Test::More->builder->failure_output($tap);
    Test::More->builder->todo_output($tap);
    local $SIG{INT} = sub { die "Interrupted (SIGINT)\n" };
    local $SIG{TERM} = sub { die "Interrupted (SIGTERM)\n" };
    check_tools();
    prepare($source, $tomcat);
    my %wanted = map { $_ => 1 } @wanted;
    for my $case (@CASES) {
        next if @wanted && !$wanted{$case->[0]};
        subtest $case->[0] => $case->[1];
    }
    done_testing();
    my $passed = Test::More->builder->is_passing;
    spew("$WORK/result.json", $JSON->encode({ result => $passed ? 'Passed' : 'Failed', finished => stamp(),
        cases => [map { $_->[0] } grep { !@wanted || $wanted{$_->[0]} } @CASES] }));
    $tap->flush or die "flush $WORK/test.tap: $!\n";
    print slurp("$WORK/test.tap");
    print '# Result: ', $passed ? 'Passed' : 'Failed', "; TAP: $WORK/test.tap\n";
    return $passed ? 0 : 1;
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    print STDERR "local-install-inspect.pl: $error";
    $status = Test::More->builder->is_passing ? 2 : 1;
    if (defined $WORK) {
        spew("$WORK/incomplete.json", $JSON->encode({ error => $error, status => $status, finished => stamp() }));
        print "# Incomplete execution; evidence: $WORK\n";
    }
};
exit $status;
