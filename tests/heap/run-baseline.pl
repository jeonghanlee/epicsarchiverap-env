#!/usr/bin/env perl
# Controller of the 48-hour heap baseline observation: schedule, collectors, registration, query clients, evidence blocks and watchdog.
use 5.010;    # defined-or operator
use strict;
use warnings;
use Cwd qw(abs_path);
use Fcntl qw(:DEFAULT);
use File::Basename qw(basename dirname);
use File::Path qw(make_path);
use File::Temp qw(tempfile);
use Getopt::Long qw(GetOptionsFromArray);
use HTTP::Tiny;
use IO::Handle;
use JSON::PP;
use Pod::Usage qw(pod2usage);
use POSIX ();
use Time::HiRes ();
use Time::Local qw(timegm);

=head1 NAME

run-baseline.pl - drive and watch the 48-hour heap baseline observation of one guest

=head1 SYNOPSIS

  perl tests/heap/run-baseline.pl plan --r-time UTC [--collectors-start UTC] [--scale SECONDS]
  perl tests/heap/run-baseline.pl link-queries --queries-dir DIR --staging DIR
  perl tests/heap/run-baseline.pl prepare --guest USER@HOST --guest-dir DIR --service-account NAME
  perl tests/heap/run-baseline.pl run --evidence-dir DIR --guest USER@HOST --guest-dir DIR --service-account NAME --camonitor FILE --pvs-csv FILE
                                      [--r-time UTC] [--scale SECONDS]
  perl tests/heap/run-baseline.pl watch --evidence-dir DIR --guest USER@HOST --guest-dir DIR
  perl tests/heap/run-baseline.pl --help

=head1 DESCRIPTION

C<R> is the time at which all 100 PVs report C<Being archived>. The schedule, in hours after C<R> and scaled by
C<--scale> (seconds per hour, default 3600): warm-up until 6, evidence blocks at 6, 12, ..., 48, four query clients from
42 to the cutoff at 48. The collectors (resource sampler and CA observer) start on the guest before C<R> and run for 48.5
hours from their start, so they end 0.5 hours after the cutoff whatever the time that the registration took; one more
block is copied 120 seconds after they end.

B<plan> prints the schedule as lines C<event TAB UTC>, from C<--r-time> and the start of the collectors
(C<--collectors-start>, default C<R>); it changes nothing.

B<link-queries> makes the files below C<--queries-dir> appear in C<STAGING/queries> as hard links (C<rsync --link-dest>), so that
the staging folder holds no second copy of the response files.

B<prepare> copies the sampler and the CA observer to C<GUEST-DIR/tools> on the guest, creates its C<samples> and C<ca> folders and
writes C<tools/sampler.args> from the process ids of the four JVMs of the appliance, the soft IOC and the database.

B<run> starts the port forward (stopped again when the run ends or fails), the collectors and, without C<--r-time>, registers the PVs of C<--pvs-csv> and waits until
all report C<Being archived>; then it waits for each event of the schedule and performs it: the stage records, the block
copies (rsync of the guest files into C<EVIDENCE/staging>, hard-linked query files, C<copy-block.pl>) and the query clients
(C<query-archive.pl> under a memory limit). Every step is appended to C<EVIDENCE/stages.csv> and the plan to
C<EVIDENCE/plan.json>. A failed step is recorded and ends the run with status 1; a failed block copy is recorded and the
run goes on.

B<watch> reads C<EVIDENCE/plan.json> and checks the guest and the clients at fixed intervals (300 seconds, 60 seconds while the queries
run, scaled), appends one line per check to C<EVIDENCE/watch.log> and ends with an C<ALERT> line at the first deviation or a
C<WATCH-END> line after the end of the run. It only reads.

Required: Perl 5.26 or newer, HTTP::Tiny, JSON::PP, Linux, ssh, rsync, sudo and systemd-run on the guest, systemd-run and python3 on the host
(python3 runs the registration tool of tests/soak-903pv), and the tools of tests/heap. The guest paths and names are checked against a conservative character set before use.

=head1 OPTIONS

=over 4

=item B<--r-time> UTC

The time C<R> as C<YYYY-MM-DDTHH:MM:SSZ>. Required by B<plan>. B<run> registers the PVs when it is absent.

=item B<--collectors-start> UTC

The start of the collectors for B<plan> (default C<--r-time>).

=item B<--scale> SECONDS

Seconds that stand for one hour of the schedule, a positive integer (default 3600). A smaller value rehearses the driver.

=item B<--evidence-dir> DIR

The evidence folder of the run, created with mode 0700.

=item B<--guest> USER@HOST, B<--guest-dir> DIR

The ssh target and the working folder on the guest (absolute path). The guest folder holds C<tools>, C<samples>, C<ca>.

=item B<--camonitor> FILE

The path of C<camonitor> on the guest. Required by B<run>.

=item B<--pvs-csv> FILE

The CSV of the PVs for the registration and for the query clients. Required by B<run>.

=item B<--pv-names> FILE

The file of PV names on the guest, absolute or relative to the guest folder (default C<ioc/iocBoot/iocAasoak/pvnames.txt>).

=item B<--service-account> NAME, B<--appliance-unit> NAME, B<--gc-dir> DIR

The account of the appliance JVMs (required by B<prepare> and B<run>), its systemd unit (default C<epicsarchiverap-maven>) and the folder of the GC
logs (default C</arch/gc>).

=item B<--mgmt-port> PORT, B<--retrieval-port> PORT

The local ports of the port forward to the management and retrieval interfaces of the guest (defaults 28665 and 28668).

=item B<--prefix> NAME

The prefix of the unit names (default C<base>): C<NAME-sampler>, C<NAME-camonitor>, C<NAME-tunnel> and C<NAME-q0> to C<NAME-q3>.

=item B<--queries-dir> DIR, B<--staging> DIR

Used by B<link-queries>.

=back

=head1 EXIT STATUS

0 when the command finished (for B<run>, all steps; for B<watch>, no deviation), 1 when a step of B<run> failed or B<watch> found a
deviation, 2 for invalid usage or an environment error.

=cut

# Schedule in hours after R.
my $WARMUP_HOURS         = 6;
my $BLOCK_HOURS          = 6;
my $BLOCK_COUNT          = 8;
my $QUERY_START_HOURS    = 42;
my $CUTOFF_HOURS         = 48;
my $COLLECTOR_MARGIN_HOURS = 0.5;
my $FINAL_BLOCK_DELAY_S  = 120;
my $SECONDS_PER_HOUR     = 3600;

# Registration, collectors, query clients and tunnel.
my $REGISTRATION_TIMEOUT_S = 3600;
my $READINESS_POLL_S       = 10;
my $PV_COUNT               = 100;
my $SAMPLER_INTERVAL_S     = 5;
my $SAMPLER_MEMORY         = '64M';
my $OBSERVER_MEMORY        = '128M';
my $QUERY_CLIENTS          = 4;
my $QUERY_MEMORY           = '512M';
my $QUERY_PAUSE_S          = 2;
my $TUNNEL_MEMORY          = '64M';
my $GUEST_MGMT_PORT        = 17665;
my $GUEST_RETRIEVAL_PORT   = 17668;
my $CA_ENVIRONMENT         = 'EPICS_CA_ADDR_LIST=127.0.0.1 EPICS_CA_AUTO_ADDR_LIST=NO EPICS_CA_MAX_ARRAY_BYTES=16384';
my $IOC_COMM               = 'st.cmd';
my $DATABASE_COMM          = 'mysqld';

# Watchdog thresholds (the resource set).
my $WATCH_INTERVAL_S       = 300;
my $WATCH_QUERY_INTERVAL_S = 60;
my $WATCH_END_MARGIN_S     = 900;
my $MIN_AVAILABLE_KIB      = 200 * 1024;
my $MAX_DISK_PERCENT       = 80;
my $MIN_FREE_INODE_PERCENT = 10;
my $MIN_EVIDENCE_FREE_BYTES = 200 * 1024 * 1024 * 1024;
my $ROWS_STALL_S           = 30;
my $UNIT_START_GRACE_S     = 30;
my $QUERY_GRACE_S          = 60;
my $QUERY_GRACE_MIN_S      = 5;

my $EXEC_FAILURE = 127;
my $WORD         = qr{^[A-Za-z0-9_./:@+=-]+$};
my $HERE         = dirname(abs_path($0));
my $JSON         = JSON::PP->new->canonical->pretty->indent_length(2);
my %OPTION_NAMES = (
    'r-time' => 'time', 'collectors-start' => 'time', 'scale' => 'integer', 'evidence-dir' => 'path', 'guest' => 'word',
    'guest-dir' => 'path', 'camonitor' => 'path', 'pvs-csv' => 'path', 'pv-names' => 'path', 'service-account' => 'word',
    'appliance-unit' => 'word', 'gc-dir' => 'path', 'mgmt-port' => 'integer', 'retrieval-port' => 'integer',
    'prefix' => 'word', 'queries-dir' => 'path', 'staging' => 'path',
);

sub usage_error {
    my ($message) = @_;
    die "run-baseline: $message\n";
}

# Parses YYYY-MM-DDTHH:MM:SSZ into epoch seconds.
sub parse_utc {
    my ($text) = @_;
    my ($y, $mo, $d, $h, $mi, $s) = $text =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z$/
        or usage_error("not a UTC time of the form YYYY-MM-DDTHH:MM:SSZ: $text");
    my $epoch = eval { timegm($s, $mi, $h, $d, $mo - 1, $y) };
    defined $epoch or usage_error("not a valid UTC time: $text");
    return $epoch;
}

sub format_utc {
    my ($epoch) = @_;
    return POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime($epoch));
}

# Returns the ordered events of the schedule as [name, epoch]. Events at the same time keep this order: the query start and the cutoff,
# which only start or mark something, come before the block copies, which take minutes; then the order of declaration.
sub schedule {
    my ($r_epoch, $collectors_epoch, $scale) = @_;
    my $at = sub { my ($hours) = @_; return $r_epoch + int($hours * $scale + 0.5) };
    my $collectors_end = $collectors_epoch + int(($CUTOFF_HOURS + $COLLECTOR_MARGIN_HOURS) * $scale + 0.5);
    $collectors_end >= $at->($CUTOFF_HOURS)
        or usage_error('the collectors end before the cutoff: they start more than ' . $COLLECTOR_MARGIN_HOURS . ' hours (scaled) before R');
    my @events = (['warmup_end', $at->($WARMUP_HOURS)]);
    push @events, ["block_$_", $at->($_ * $BLOCK_HOURS)] for 1 .. $BLOCK_COUNT;
    push @events, ['query_start', $at->($QUERY_START_HOURS)], ['cutoff', $at->($CUTOFF_HOURS)],
        ['collectors_end', $collectors_end], ['final_block', $collectors_end + $FINAL_BLOCK_DELAY_S];
    my $index = 0;
    my %first = (query_start => 0, cutoff => 0);
    return map { $_->[0] } sort { $a->[0][1] <=> $b->[0][1] || $a->[1] <=> $b->[1] || $a->[2] <=> $b->[2] }
        map { [$_, $first{ $_->[0] } // 1, $index++] } @events;
}

sub check_value {
    my ($name, $value) = @_;
    my $kind = $OPTION_NAMES{$name};
    if ($kind eq 'integer') {
        $value =~ /^[1-9][0-9]*$/ or usage_error("--$name needs a positive integer: $value");
    }
    elsif ($kind eq 'word' || $kind eq 'path') {
        $value =~ $WORD or usage_error("--$name holds a character that is not allowed: $value");
        $kind eq 'path' && $name =~ /^(?:guest-dir|gc-dir|evidence-dir|pvs-csv)$/ && $value !~ m{^/} and usage_error("--$name needs an absolute path: $value");
    }
    return;
}

sub parse_options {
    my ($mode, @arguments) = @_;
    my %options = (scale => $SECONDS_PER_HOUR, 'pv-names' => 'ioc/iocBoot/iocAasoak/pvnames.txt', 
        'appliance-unit' => 'epicsarchiverap-maven', 'gc-dir' => '/arch/gc', 'mgmt-port' => 28665, 'retrieval-port' => 28668,
        prefix => 'base');
    GetOptionsFromArray(\@arguments, \%options, map { "$_=s" } sort keys %OPTION_NAMES)
        or usage_error('invalid option');
    @arguments and usage_error("unexpected argument: $arguments[0]");
    check_value($_, $options{$_}) for sort keys %options;
    my %required = (
        plan => ['r-time'], 'link-queries' => ['queries-dir', 'staging'], prepare => ['guest', 'guest-dir', 'service-account'],
        run => ['evidence-dir', 'guest', 'guest-dir', 'service-account', 'camonitor', 'pvs-csv'], watch => ['evidence-dir', 'guest', 'guest-dir'],
    );
    for my $name (@{ $required{$mode} }) {
        defined $options{$name} or usage_error("$mode needs --$name");
    }
    return \%options;
}

sub exec_or_exit {
    my (@command) = @_;
    {
        no warnings 'exec';
        exec { $command[0] } @command;
    }
    POSIX::_exit($EXEC_FAILURE);
}

# Runs a command without a shell; returns (status, output) with standard error merged into the output.
sub run_capture {
    my ($input, @command) = @_;
    my $pid = open(my $out, '-|');
    defined $pid or die "$command[0]: fork: $!\n";
    if (!$pid) {
        open(STDERR, '>&', \*STDOUT) or POSIX::_exit(126);
        if (defined $input) {
            open(STDIN, '<', $input) or POSIX::_exit(126);
        }
        else {
            open(STDIN, '<', '/dev/null') or POSIX::_exit(126);
        }
        exec_or_exit(@command);
    }
    my $text = do { local $/; <$out> };
    close($out);    # the status is read from $?
    return (($? & 127) ? 128 + ($? & 127) : $? >> 8, defined $text ? $text : '');
}

sub ssh_command {
    my ($options, $remote) = @_;
    return ('ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=20', $options->{guest}, $remote);
}

sub guest_run {
    my ($options, $remote, $input) = @_;
    return run_capture($input, ssh_command($options, $remote));
}

sub shell_quote {
    my ($text) = @_;
    $text =~ s/'/'\\''/g;
    return "'$text'";
}

sub guest_user {
    my ($options) = @_;
    my ($user) = $options->{guest} =~ /^([^@]+)@/ or usage_error('--guest needs USER@HOST');
    return $user;
}

sub read_file {
    my ($path) = @_;
    open(my $fh, '<:raw', $path) or die "$path: $!\n";
    my $data = do { local $/; <$fh> };
    close($fh) or die "$path: $!\n";
    return $data;
}

sub atomic_write {
    my ($path, $data) = @_;
    my ($fh, $tmp) = tempfile('.' . basename($path) . '.XXXXXX', DIR => dirname($path));
    my $done = eval {
        binmode($fh) or die "$tmp: $!\n";
        print {$fh} $data or die "$tmp: $!\n";
        close($fh) or die "$tmp: $!\n";
        rename($tmp, $path) or die "$path: $!\n";
        1;
    };
    if (!$done) {
        my $error = $@;
        unlink $tmp;    # best-effort cleanup while another error is raised
        die $error;
    }
    return;
}

sub csv_field {
    my ($text) = @_;
    return $text =~ /[",\n]/ ? '"' . ($text =~ s/"/""/gr) . '"' : $text;
}

sub uptime_seconds {
    my $text = read_file('/proc/uptime');
    my ($seconds) = $text =~ /^(\S+)/;
    return $seconds;
}

# Appends one row to the stage record of the run.
sub stage {
    my ($options, $event, $detail) = @_;
    my $path = "$options->{'evidence-dir'}/stages.csv";
    my @now = Time::HiRes::gettimeofday();
    my $stamp = POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime($now[0])) . sprintf('.%03dZ', $now[1] / 1000);
    open(my $fh, '>>', $path) or die "$path: $!\n";
    print {$fh} join(',', $stamp, uptime_seconds(), csv_field($event), csv_field($detail)), "\n" or die "$path: $!\n";
    close($fh) or die "$path: $!\n";
    return;
}

sub wait_until {
    my ($epoch) = @_;
    while (Time::HiRes::time() < $epoch) {
        Time::HiRes::sleep(1);
    }
    return;
}

# plan: prints the schedule.
sub mode_plan {
    my ($options) = @_;
    my $r_epoch = parse_utc($options->{'r-time'});
    my $collectors = defined $options->{'collectors-start'} ? parse_utc($options->{'collectors-start'}) : $r_epoch;
    for my $event (schedule($r_epoch, $collectors, $options->{scale})) {
        print "$event->[0]\t", format_utc($event->[1]), "\n";
    }
    return 0;
}

# link-queries: hard-links the response files into the staging folder.
sub mode_link_queries {
    my ($options) = @_;
    my $source = abs_path($options->{'queries-dir'});
    defined $source && -d $source or die "$options->{'queries-dir'}: not a directory\n";
    my $target = "$options->{staging}/queries";
    make_path($target);
    my ($status, $text) = run_capture(undef, 'rsync', '-a', "--link-dest=$source", "$source/", "$target/");
    $status == 0 or die "rsync of the query files into $target failed with status $status: $text\n";
    return 0;
}

# Reads the pids of the four JVMs, the soft IOC and the database from the guest.
sub discover_pids {
    my ($options) = @_;
    my $account = $options->{'service-account'};
    my $remote = "ps -u $account -o pid=,args= | awk '/java/ { if (match(\$0, /-Dcatalina\\.base=[^ ]*/)) { n = substr(\$0, RSTART, RLENGTH); sub(/.*\\//, \"\", n); print n \"=\" \$1 } }'; "
        . "echo ioc=\$(pgrep -x '$IOC_COMM' | head -1); echo mariadb=\$(pgrep -x '$DATABASE_COMM' | head -1)";
    my ($status, $text) = guest_run($options, $remote);
    $status == 0 or die "reading the process ids on the guest failed with status $status: $text\n";
    my %pids = $text =~ /^(\w+)=(\d+)$/mg;
    for my $name (qw(mgmt engine etl retrieval ioc mariadb)) {
        defined $pids{$name} or die "no process id of $name on the guest: $text\n";
    }
    return \%pids;
}

sub mode_prepare {
    my ($options) = @_;
    my $dir = $options->{'guest-dir'};
    my ($status, $text) = guest_run($options, "mkdir -p $dir/tools $dir/samples $dir/ca");
    $status == 0 or die "creating the folders on the guest failed with status $status: $text\n";
    ($status, $text) = run_capture(undef, 'rsync', '-a', '-e', 'ssh -o BatchMode=yes', "$HERE/sample-resources.pl", "$HERE/observe-ca.pl",
        "$options->{guest}:$dir/tools/");
    $status == 0 or die "copying the tools to the guest failed with status $status: $text\n";
    my $pids = discover_pids($options);
    my $arguments = join(' ', map { "--process $_=$pids->{$_}" } qw(mgmt engine etl retrieval ioc mariadb)) . ' --filesystem root=/';
    my ($tmp_fh, $tmp) = tempfile();
    print {$tmp_fh} "$arguments\n" or die "$tmp: $!\n";
    close($tmp_fh) or die "$tmp: $!\n";
    ($status, $text) = guest_run($options, "cat > $dir/tools/sampler.args", $tmp);
    unlink $tmp;    # scratch file of this call
    $status == 0 or die "writing sampler.args on the guest failed with status $status: $text\n";
    print "$arguments\n";
    return 0;
}

sub start_collectors {
    my ($options, $seconds) = @_;
    my $dir = $options->{'guest-dir'};
    my $user = guest_user($options);
    my $prefix = $options->{prefix};
    my $names = $options->{'pv-names'} =~ m{^/} ? $options->{'pv-names'} : "$dir/$options->{'pv-names'}";
    my $unit = "systemd-run --unit=%s -p User=$user -p WorkingDirectory=$dir -p MemoryLimit=%s -p Type=simple";
    my $sampler = "cd $dir && sudo -n " . sprintf($unit, "$prefix-sampler", $SAMPLER_MEMORY)
        . " /usr/bin/perl tools/sample-resources.pl --output samples/samples.csv --interval $SAMPLER_INTERVAL_S --duration $seconds \$(cat tools/sampler.args)";
    my $observer = "cd $dir && sudo -n " . sprintf($unit, "$prefix-camonitor", $OBSERVER_MEMORY) . " -p Environment=" . shell_quote($CA_ENVIRONMENT)
        . " /usr/bin/perl tools/observe-ca.pl --pv-list $names --output-dir ca/run --camonitor $options->{camonitor} --duration $seconds";
    for my $remote ($sampler, $observer) {
        my ($status, $text) = guest_run($options, $remote);
        $status == 0 or die "starting a collector failed with status $status: $text\n";
    }
    return;
}

sub start_tunnel {
    my ($options) = @_;
    my $prefix = $options->{prefix};
    my ($status, $text) = run_capture(undef, 'systemd-run', '--user', "--unit=$prefix-tunnel", '-p', "MemoryMax=$TUNNEL_MEMORY", '/usr/bin/ssh', '-N',
        '-o', 'BatchMode=yes', '-o', 'ControlMaster=no', '-o', 'ControlPath=none', '-o', 'ExitOnForwardFailure=yes', '-o', 'ServerAliveInterval=30',
        '-L', "127.0.0.1:$options->{'mgmt-port'}:127.0.0.1:$GUEST_MGMT_PORT", '-L', "127.0.0.1:$options->{'retrieval-port'}:127.0.0.1:$GUEST_RETRIEVAL_PORT",
        $options->{guest});
    $status == 0 or die "starting the port forward failed with status $status: $text\n";
    return;
}

# Stops the port forward of the run so that a later run can create it again; returns the exit status of systemctl.
sub stop_tunnel {
    my ($options) = @_;
    my ($status) = run_capture(undef, 'systemctl', '--user', 'stop', "$options->{prefix}-tunnel.service");
    return $status;
}

# Waits until the management interface answers through the forward.
sub wait_for_mgmt {
    my ($options) = @_;
    my $http = HTTP::Tiny->new(timeout => 10);
    my $url = "http://127.0.0.1:$options->{'mgmt-port'}/mgmt/bpl/getVersions";
    for (1 .. 30) {
        return 1 if $http->get($url)->{success};
        Time::HiRes::sleep(1);
    }
    return 0;
}

sub pv_names {
    my ($options) = @_;
    open(my $fh, '<', $options->{'pvs-csv'}) or die "$options->{'pvs-csv'}: $!\n";
    my $header = <$fh>;
    defined $header or die "$options->{'pvs-csv'}: empty\n";
    chomp $header;
    my @columns = split /,/, $header;
    my ($index) = grep { $columns[$_] eq 'pv' } 0 .. $#columns;
    defined $index or die "$options->{'pvs-csv'}: no pv column\n";
    my @names;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line eq '';
        push @names, (split /,/, $line)[$index];
    }
    close($fh) or die "$options->{'pvs-csv'}: $!\n";
    return @names;
}

# Registers the PVs and waits until all report Being archived; returns the readiness time.
sub register_and_wait {
    my ($options) = @_;
    my @names = pv_names($options);
    @names == $PV_COUNT or die "$options->{'pvs-csv'} holds " . scalar(@names) . " PVs, not $PV_COUNT\n";
    my $mgmt = "http://127.0.0.1:$options->{'mgmt-port'}/mgmt/bpl";
    my ($status, $text) = run_capture(undef, 'python3', '-I', "$HERE/../soak-903pv/tools/register.py", $options->{'pvs-csv'},
        "$options->{'evidence-dir'}/register", 'registered.csv', $mgmt);
    $status == 0 or die "the registration failed with status $status: $text\n";
    my $http = HTTP::Tiny->new(timeout => 60);
    my $deadline = Time::HiRes::time() + $REGISTRATION_TIMEOUT_S;
    my $archived = 0;
    while (Time::HiRes::time() < $deadline) {
        my $response = $http->post("$mgmt/getPVStatus", { content => encode_json(\@names), headers => { 'Content-Type' => 'application/json' } });
        if ($response->{success}) {
            my $list = eval { JSON::PP->new->decode($response->{content}) };
            if (ref $list eq 'ARRAY') {
                $archived = grep { ref $_ eq 'HASH' && ($_->{status} // '') eq 'Being archived' } @$list;
                return Time::HiRes::time() if $archived == $PV_COUNT;
            }
        }
        Time::HiRes::sleep($READINESS_POLL_S);
    }
    die "only $archived of $PV_COUNT PVs report Being archived after $REGISTRATION_TIMEOUT_S seconds\n";
}

sub copy_block {
    my ($options, $number) = @_;
    my $evidence = $options->{'evidence-dir'};
    my $staging = "$evidence/staging";
    my $dir = $options->{'guest-dir'};
    stage($options, "block${number}_pull_start", 'rsync of the guest files into the staging folder');
    make_path("$staging/gc", "$staging/samples", "$staging/ca");
    my @pulls = (
        ['gc', ['--rsync-path=sudo rsync'], "$options->{guest}:$options->{'gc-dir'}/", "$staging/gc/"],
        ['samples', [], "$options->{guest}:$dir/samples/", "$staging/samples/"],
        ['ca', [], "$options->{guest}:$dir/ca/", "$staging/ca/"],
    );
    for my $pull (@pulls) {
        my ($name, $extra, $from, $to) = @$pull;
        my ($status, $text) = run_capture(undef, 'rsync', '-a', '-e', 'ssh -o BatchMode=yes', @$extra, $from, $to);
        if ($status != 0) {
            stage($options, "block${number}_pull_failed", "rsync of $name exit status $status: $text");
            return;
        }
    }
    if (-d "$evidence/queries") {
        eval { mode_link_queries({ 'queries-dir' => "$evidence/queries", staging => $staging }); 1 } or do {
            stage($options, "block${number}_pull_failed", "link of the query files: $@");
            return;
        };
    }
    stage($options, "block${number}_pull_end", 'staging complete');
    stage($options, "block${number}_copy_start", "copy-block.pl block $number");
    my ($status, $text) = run_capture(undef, $^X, "$HERE/copy-block.pl", '--source', $staging, '--dest', "$evidence/blocks", '--block', $number);
    stage($options, "block${number}_copy_end", "exit status $status");
    if ($status != 0 && $text ne '') {
        open(my $fh, '>>', "$evidence/copy-block.err") or die "$evidence/copy-block.err: $!\n";
        print {$fh} $text or die "$evidence/copy-block.err: $!\n";
        close($fh) or die "$evidence/copy-block.err: $!\n";
    }
    return;
}

sub start_query_clients {
    my ($options, $seconds) = @_;
    my $prefix = $options->{prefix};
    my $evidence = $options->{'evidence-dir'};
    make_path("$evidence/queries");
    for my $number (0 .. $QUERY_CLIENTS - 1) {
        my ($status, $text) = run_capture(undef, 'systemd-run', '--user', "--unit=$prefix-q$number", '-p', "MemoryMax=$QUERY_MEMORY", $^X,
            "$HERE/query-archive.pl", '--pv-csv', $options->{'pvs-csv'}, '--output-dir', "$evidence/queries", '--url',
            "http://127.0.0.1:$options->{'retrieval-port'}/retrieval/data/getData.json", '--client', $number, '--pause', $QUERY_PAUSE_S,
            '--duration', $seconds);
        $status == 0 or die "starting query client $number failed with status $status: $text\n";
    }
    return;
}

sub mode_run {
    my ($options) = @_;
    my $evidence = $options->{'evidence-dir'};
    make_path($evidence, { mode => 0700 });
    my $stages = "$evidence/stages.csv";
    if (!-s $stages) {
        open(my $fh, '>', $stages) or die "$stages: $!\n";
        print {$fh} "time_utc,uptime_s,event,detail\n" or die "$stages: $!\n";
        close($fh) or die "$stages: $!\n";
    }
    my $scale = $options->{scale};
    my $failed = sub {
        my ($message) = @_;
        stage($options, 'run_failed', $message);
        print STDERR "run-baseline: $message\n";
        return 1;
    };
    my $plan = { guest_dir => $options->{'guest-dir'}, prefix => $options->{prefix}, scale => $scale, 'service-account' => $options->{'service-account'},
        'appliance-unit' => $options->{'appliance-unit'} };
    my $tunnel_started = 0;
    my $result = eval {
        start_tunnel($options);
        $tunnel_started = 1;
        wait_for_mgmt($options) or die "the management interface does not answer through the port forward\n";
        stage($options, 'tunnel_up', "port forward $options->{'mgmt-port'} and $options->{'retrieval-port'}");
        $plan->{jvm_pids} = discover_pids($options);
        my $collectors_epoch = int(Time::HiRes::time());
        my $seconds = int(($CUTOFF_HOURS + $COLLECTOR_MARGIN_HOURS) * $scale + 0.5);
        start_collectors($options, $seconds);
        $plan->{collectors_start} = format_utc($collectors_epoch);
        $plan->{collectors_seconds} = $seconds;
        stage($options, 'collectors_start', "sampler $SAMPLER_MEMORY and CA observer $OBSERVER_MEMORY on the guest, $seconds s");
        atomic_write("$evidence/plan.json", $JSON->encode($plan));
        my $r_epoch;
        if (defined $options->{'r-time'}) {
            $r_epoch = parse_utc($options->{'r-time'});
            stage($options, 'readiness_given', "R $options->{'r-time'}");
        }
        else {
            stage($options, 'registration_request', "$PV_COUNT PVs of $options->{'pvs-csv'}");
            $r_epoch = int(register_and_wait($options));
            stage($options, 'readiness', 'all PVs report Being archived, R ' . format_utc($r_epoch));
        }
        $plan->{r_time} = format_utc($r_epoch);
        my @events = schedule($r_epoch, $collectors_epoch, $scale);
        $plan->{schedule} = [ map { { event => $_->[0], utc => format_utc($_->[1]) } } @events ];
        atomic_write("$evidence/plan.json", $JSON->encode($plan));
        stage($options, 'plan_written', "R $plan->{r_time}, cutoff " . format_utc($r_epoch + int($CUTOFF_HOURS * $scale + 0.5)));
        for my $event (@events) {
            my ($name, $epoch) = @$event;
            wait_until($epoch);
            my $late = int(Time::HiRes::time() - $epoch);
            my $detail = 'planned ' . format_utc($epoch) . ", late by $late s";
            if ($name =~ /^block_(\d+)$/) {
                stage($options, "block_$1", $detail);
                copy_block($options, $1);
            }
            elsif ($name eq 'query_start') {
                my $seconds_of_queries = int(($CUTOFF_HOURS - $QUERY_START_HOURS) * $scale + 0.5);
                start_query_clients($options, $seconds_of_queries);
                stage($options, 'query_clients_start', "$QUERY_CLIENTS clients, $seconds_of_queries s, MemoryMax $QUERY_MEMORY each; $detail");
            }
            elsif ($name eq 'final_block') {
                my ($status, $text) = guest_run($options, "systemctl is-active $options->{prefix}-sampler $options->{prefix}-camonitor | tr '\\n' ' '");
                stage($options, 'collectors_state_at_end', $text =~ s/\s+$//r);
                stage($options, 'final_block', $detail);
                copy_block($options, $BLOCK_COUNT + 1);
            }
            else {
                stage($options, $name, $detail);
            }
        }
        stage($options, 'run_complete', 'all blocks copied');
        0;
    };
    my $error = defined $result ? undef : $@ =~ s/\n+$//r;
    if ($tunnel_started) {
        my $stopped = stop_tunnel($options);
        stage($options, 'tunnel_stopped', "exit status $stopped");
    }
    return $failed->($error) if defined $error;
    return $result;
}

# The facts of one guest check as key=value lines; every command only reads.
sub guest_check_script {
    my ($options, $plan) = @_;
    my $prefix = $plan->{prefix};
    my $dir = $plan->{guest_dir};
    my $account = $plan->{'service-account'};
    my $script = join("\n",
        qq{printf "sampler=%s\\ncamonitor=%s\\napp=%s\\n" "\$(systemctl is-active $prefix-sampler)" "\$(systemctl is-active $prefix-camonitor)" "\$(systemctl is-active $plan->{'appliance-unit'})"},
        qq{printf "jvms=%s\\n" "\$(ps -u $account -o pid=,args= | awk '/java/ && /-Dcatalina\\.base=/ {print \$1}' | sort -n | tr '\\n' ' ' | sed 's/ \$//')"},
        qq{printf "available_kib=%s\\n" "\$(awk '/MemAvailable/ {print \$2}' /proc/meminfo)"},
        qq{printf "disk_percent=%s\\n" "\$(df --output=pcent / | tail -1 | tr -dc 0-9)"},
        qq{printf "free_inode_percent=%s\\n" "\$(df --output=ipcent / | tail -1 | tr -dc 0-9 | awk '{print 100 - \$1}')"},
        qq{for u in $prefix-sampler $prefix-camonitor; do d=/sys/fs/cgroup/memory/system.slice/\$u.service; printf "%s_failcnt=%s\\n%s_oom=%s\\n%s_rss=%s\\n%s_limit=%s\\n" "\$u" "\$(cat \$d/memory.failcnt 2>/dev/null)" "\$u" "\$(grep -E '^oom_kill ' \$d/memory.oom_control 2>/dev/null | cut -d' ' -f2)" "\$u" "\$(awk '/^rss / {print \$2}' \$d/memory.stat 2>/dev/null)" "\$u" "\$(cat \$d/memory.limit_in_bytes 2>/dev/null)"; done},
        qq{printf "samples_rows=%s\\n" "\$(wc -l < $dir/samples/samples.csv)"},
    );
    return $script;
}

# The sorted process ids of the four appliance JVMs recorded in the plan.
sub jvm_pid_list {
    my ($plan) = @_;
    return join(' ', sort { $a <=> $b } map { $plan->{jvm_pids}{$_} } qw(mgmt engine etl retrieval));
}

sub parse_facts {
    my ($text) = @_;
    my %facts;
    for my $line (split /\n/, $text) {
        $line =~ /^([^=]+)=(.*)$/ and $facts{$1} = $2;
    }
    return \%facts;
}

sub query_client_facts {
    my ($prefix) = @_;
    my $uid = $<;
    my $base = "/sys/fs/cgroup/user.slice/user-$uid.slice/user\@$uid.service/app.slice";
    my @facts;
    for my $number (0 .. $QUERY_CLIENTS - 1) {
        my ($status, $state) = run_capture(undef, 'systemctl', '--user', 'is-active', "$prefix-q$number.service");
        $state =~ s/\s+$//;
        my $dir = "$base/$prefix-q$number.service";
        my %value;
        for my $file (qw(memory.max memory.peak)) {
            $value{$file} = eval { read_file("$dir/$file") =~ s/\s+$//r } // '';
        }
        my $stat = eval { read_file("$dir/memory.stat") } // '';
        my ($anon) = $stat =~ /^anon (\d+)$/m;
        my $events = eval { read_file("$dir/memory.events") } // '';
        my ($oom) = $events =~ /^oom_kill (\d+)$/m;
        push @facts, { number => $number, state => $state, limit => $value{'memory.max'}, peak => $value{'memory.peak'}, anon => $anon, oom => $oom };
    }
    return @facts;
}

sub evidence_free_bytes {
    my ($evidence) = @_;
    my ($status, $text) = run_capture(undef, 'df', '--output=avail', '-B1', $evidence);
    $status == 0 && $text =~ /(\d+)\s*$/ or die "df of $evidence failed: $text\n";
    return $1;
}

sub mode_watch {
    my ($options) = @_;
    my $evidence = $options->{'evidence-dir'};
    my $log = "$evidence/watch.log";
    my $last_rows = -1;
    my $last_growth = Time::HiRes::time();
    while (1) {
        my $plan = eval { JSON::PP->new->decode(read_file("$evidence/plan.json")) };
        if (ref $plan ne 'HASH') {
            Time::HiRes::sleep(2);
            next;
        }
        my $scale = $plan->{scale};
        my $now = Time::HiRes::time();
        my $r_epoch = defined $plan->{r_time} ? parse_utc($plan->{r_time}) : undef;
        my $collectors_epoch = parse_utc($plan->{collectors_start});
        my $collectors_end = $collectors_epoch + $plan->{collectors_seconds};
        my $watch_end = $collectors_end + $FINAL_BLOCK_DELAY_S + $WATCH_END_MARGIN_S * $scale / $SECONDS_PER_HOUR;
        my $query_begin = defined $r_epoch ? $r_epoch + int($QUERY_START_HOURS * $scale + 0.5) : undef;
        my $query_end = defined $r_epoch ? $r_epoch + int($CUTOFF_HOURS * $scale + 0.5) : undef;
        if ($now >= $watch_end) {
            my $line = format_utc(int($watch_end)) . " WATCH-END no deviation seen until " . format_utc(int($watch_end)) . "\n";
            open(my $fh, '>>', $log) or die "$log: $!\n";
            print {$fh} $line or die "$log: $!\n";
            close($fh) or die "$log: $!\n";
            print $line;
            return 0;
        }
        my @alerts;
        my ($status, $text) = guest_run({ guest => $options->{guest} }, guest_check_script($options, $plan));
        my $facts = parse_facts($text);
        if ($status != 0) {
            push @alerts, "guest check failed with status $status: " . ($text =~ s/\s+/ /gr);
        }
        else {
            my $prefix = $plan->{prefix};
            my $collecting = $now >= $collectors_epoch + $UNIT_START_GRACE_S && $now < $collectors_end - $UNIT_START_GRACE_S;
            if ($collecting) {
                for my $name (qw(sampler camonitor)) {
                    ($facts->{$name} // 'missing') eq 'active' or push @alerts, "$name=" . ($facts->{$name} // 'missing') . ' expected active';
                }
                for my $unit ("$prefix-sampler", "$prefix-camonitor") {
                    ($facts->{"${unit}_oom"} // 'missing') eq '0' or push @alerts, "${unit}_oom=" . ($facts->{"${unit}_oom"} // 'missing') . ' expected 0';
                    my ($rss, $limit) = ($facts->{"${unit}_rss"} // 0, $facts->{"${unit}_limit"} // 1);
                    $rss * 10 < $limit * 9 or push @alerts, "$unit anonymous memory $rss at 90 percent of its limit $limit";
                }
            }
            ($facts->{app} // 'missing') eq 'active' or push @alerts, 'app=' . ($facts->{app} // 'missing') . ' expected active';
            my $jvms = $facts->{jvms} // '';
            my $expected = jvm_pid_list($plan);
            $jvms eq $expected or push @alerts, "jvms=$jvms expected $expected";
            ($facts->{available_kib} // 0) >= $MIN_AVAILABLE_KIB or push @alerts, "available_kib=" . ($facts->{available_kib} // 'missing') . " below $MIN_AVAILABLE_KIB";
            ($facts->{disk_percent} // 100) < $MAX_DISK_PERCENT or push @alerts, "disk_percent=" . ($facts->{disk_percent} // 'missing') . " at or above $MAX_DISK_PERCENT";
            ($facts->{free_inode_percent} // 0) >= $MIN_FREE_INODE_PERCENT or push @alerts, "free_inode_percent=" . ($facts->{free_inode_percent} // 'missing') . " below $MIN_FREE_INODE_PERCENT";
            my $rows = $facts->{samples_rows} // 0;
            if ($rows > $last_rows) {
                $last_growth = $now;
            }
            elsif ($collecting && $now - $last_growth > $ROWS_STALL_S) {
                push @alerts, "samples_rows=$rows did not grow for more than $ROWS_STALL_S seconds";
            }
            $last_rows = $rows;
        }
        my @clients = query_client_facts($plan->{prefix});
        my $grace = $QUERY_GRACE_S * $scale / $SECONDS_PER_HOUR;
        $grace = $QUERY_GRACE_MIN_S if $grace < $QUERY_GRACE_MIN_S;
        my $querying = defined $query_begin && $now > $query_begin + $grace && $now < $query_end - $grace;
        my $summary = '';
        for my $client (@clients) {
            $summary .= " q$client->{number}=$client->{state}(peak=" . ($client->{peak} || '-') . ',anon=' . ($client->{anon} // '-') . ')';
            $querying && $client->{state} ne 'active' and push @alerts, "query client q$client->{number} is $client->{state} during the query phase";
            if (defined $client->{anon} && $client->{limit} =~ /^\d+$/ && $client->{anon} * 10 >= $client->{limit} * 9) {
                push @alerts, "query client q$client->{number} anonymous memory $client->{anon} at 90 percent of its limit $client->{limit}";
            }
            defined $client->{oom} && $client->{oom} != 0 and push @alerts, "query client q$client->{number} oom_kill $client->{oom}";
        }
        my $free = evidence_free_bytes($evidence);
        $free >= $MIN_EVIDENCE_FREE_BYTES or push @alerts, "evidence free bytes $free below $MIN_EVIDENCE_FREE_BYTES";
        my $line = sprintf('%s check sampler=%s camonitor=%s app=%s jvms_same=%s avail_mib=%d disk=%s%% rows=%s evidence_free_gib=%d%s',
            format_utc(int($now)), $facts->{sampler} // '?', $facts->{camonitor} // '?', $facts->{app} // '?',
            (($facts->{jvms} // '') eq jvm_pid_list($plan) ? 'yes' : 'NO'),
            ($facts->{available_kib} // 0) / 1024, $facts->{disk_percent} // '?', $facts->{samples_rows} // '?', $free / (1024 * 1024 * 1024), $summary);
        open(my $fh, '>>', $log) or die "$log: $!\n";
        print {$fh} "$line\n" or die "$log: $!\n";
        if (@alerts) {
            my $alert = format_utc(int($now)) . ' ALERT ' . join(' ', @alerts) . "\n";
            print {$fh} $alert or die "$log: $!\n";
            close($fh) or die "$log: $!\n";
            print $alert;
            return 1;
        }
        close($fh) or die "$log: $!\n";
        my $interval = $WATCH_INTERVAL_S;
        $interval = $WATCH_QUERY_INTERVAL_S if defined $query_begin && $now >= $query_begin - 60 * $scale / $SECONDS_PER_HOUR && $now < $query_end;
        my $pause = $interval * $scale / $SECONDS_PER_HOUR;
        Time::HiRes::sleep($pause < 2 ? 2 : $pause);
    }
}

sub main {
    my (@arguments) = @_;
    if (@arguments && $arguments[0] eq '--help') {
        pod2usage(-exitval => 'NOEXIT', -verbose => 99, -sections => [qw(NAME SYNOPSIS DESCRIPTION OPTIONS)], -output => \*STDOUT);
        return 0;
    }
    my $mode = shift @arguments;
    defined $mode or usage_error('a command is required: plan, link-queries, prepare, run or watch');
    my %modes = (plan => \&mode_plan, 'link-queries' => \&mode_link_queries, prepare => \&mode_prepare, run => \&mode_run, watch => \&mode_watch);
    $modes{$mode} or usage_error("unknown command: $mode");
    my $options = parse_options($mode, @arguments);
    return $modes{$mode}->($options);
}

my $status;
eval {
    $status = main(@ARGV);
    defined $status or die "internal error: main returned no exit status\n";
    1;
} or do {
    my $error = $@;
    print STDERR $error =~ /^run-baseline: / ? $error : "run-baseline: $error";
    $status = 2;
};
exit $status;
