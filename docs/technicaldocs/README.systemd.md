# Systemd for Archiver Appliance

One service runs the appliance. Its main process is the launcher
`archappl.bash` in service mode, which starts the four Tomcat instances in the
foreground in the order mgmt, engine, etl, retrieval, and stops them in the
order engine, retrieval, etl, mgmt. The global configuration `archappl.conf`
sits in `INSTALL_LOCATION`, and each instance keeps the standard Tomcat
`webapp` layout with its own `bin/startup.sh`, `bin/shutdown.sh` and
`bin/run.sh`. The first two remain for a shell user outside the service; the
service uses `run.sh`, which sources the same configuration and replaces
itself with `catalina.sh run`, so the launcher holds the JVM's PID.

The unit is generated from
`site-template/systemd/epicsarchiverap-maven.service.in`. With the default
configuration, `AA_INSTALL_LOCATION` is `/opt/epicsarchiverap-maven` and
`SYSTEMD_FILENAME` is `epicsarchiverap-maven.service`. `SYSTEMD_SERVICES` adds
site-specific prerequisites to both `After` and `Requires`;
`SYSTEMD_TIMEOUT_STOP_SECONDS` (default 300) bounds the ordered stop, which
includes the ETL's consolidation on shutdown. Both can be set in
`../CONFIG_SITE.local`, the override file outside the tree that
`make <os>.conf` does not rewrite.

The following is the source template; its placeholders are substituted during
`make sd_install`:

```ini
[Unit]
Description=EPICS Archiver Appliance for @ARCHAPPL_SITEID@
Documentation=@DOCURL@
After=network.target mariadb.service @SYSTEMD_SERVICES@
Requires=mariadb.service @SYSTEMD_SERVICES@
SourcePath=@INSTALL_LOCATION@/@ARCHAPPL_MAIN_SCRIPT@

[Service]
User=@USERID@
Group=@GROUPID@
ExecStart=/bin/bash "@INSTALL_LOCATION@/@ARCHAPPL_MAIN_SCRIPT@" service
Type=simple
KillMode=mixed
Restart=no
TimeoutStopSec=@TIMEOUT_STOP_SECONDS@s

[Install]
WantedBy=multi-user.target
Alias=archappl.service
```

`Type=simple` rather than `Type=exec` because Rocky Linux 8 ships systemd 239,
which predates `Type=exec`; for a launcher that stays up the two behave the
same. `KillMode=mixed` delivers `systemctl stop` as SIGTERM to the launcher
alone, which sends SIGTERM to each JVM in the stop order and waits for it to
leave; Tomcat's shutdown hook stops the webapps, and the ETL consolidates its
`consolidateOnShutdown` stores in that path. Processes still alive at
`TimeoutStopSec` receive SIGKILL, which cuts a consolidation short, so the
timeout is sized from a measured stop: a test host with three PVs stopped in
about 10 s, the 300 s default leaves room for a loaded ETL, and a site sets
its own value after timing its stop. There is no `ExecStop`.

## Instance lifecycle

| Event | Launcher behavior | Unit result |
| --- | --- | --- |
| `systemctl stop` | SIGTERM to engine, retrieval, etl, mgmt in turn, each waited for | inactive |
| One JVM exits or is killed | The survivors stop in order; the launcher exits non-zero | failed, no restart (`Restart=no`) |
| One `systemd-cat` exits | Treated like a dead JVM, since the JVM would keep running while its output is lost | failed, no restart |
| A shell user runs `archappl.bash shutdown` while the service runs | The stopped JVMs are dead children to the launcher | failed, no restart |

`Restart=no` is deliberate: a dead instance is reported by the health pair
below and recovered by an operator. The PID file `temp/<instance>.pid`
carries the JVM PID in service mode too; `status`, `health` and the
interactive `shutdown` read it.

## Logs

Tomcat writes nothing under `logs/` except the access log. Each instance's
stdout and stderr pass through `systemd-cat` into the journal under the
identifier `archappl-<instance>`. Two log4j2 configurations write to that
stream:

| Configuration | Where | Lines it formats |
| --- | --- | --- |
| Tomcat level | `$CATALINA_BASE/log4j/log4j2-tomcat.xml`, loaded through `bin/setenv.sh` with `log4j-appserver` and `log4j-jul` | Tomcat's own records, and every `java.util.logging` record in the JVM, including the CA client's inside the engine WAR |
| WAR level | `log4j2.xml` inside each WAR, or the site file named by `ARCHAPPL_LOG4J_SITE_FILE` | The application's log4j2, SLF4J and commons-logging output |

Both files write the same priority prefix and read the root level from
`ARCHAPPL_ROOT_LOGGER_LEVEL` (default `INFO`), which `archappl.conf` exports;
set it in `../CONFIG_SITE.local`, then run `make conf.archapplproperties`,
`make install` and `make sd_restart`. Both files
carry `monitorInterval="30"`: a level edited in the site file, or in an
instance's installed `$CATALINA_BASE/log4j/log4j2-tomcat.xml`, takes effect
within about 30 seconds without a restart. A site file starts as a copy of
the WAR's file, which each installed instance already holds unpacked, for
example `/opt/epicsarchiverap-maven/mgmt/webapps/mgmt/WEB-INF/classes/log4j2.xml`.
The WAR's own file cannot be edited in place, and the next `make install` overwrites an edit of
`log4j2-tomcat.xml` with the shipped copy.

```bash
journalctl -u epicsarchiverap-maven.service -t archappl-engine -f
journalctl -t archappl-mgmt --since today
```

An application logger's level can also change at runtime, per component,
through the launcher, which calls the mgmt BPL (`getLogLevel`,
`setLogLevel`) with `curl`; any local user may run it:

```bash
/opt/epicsarchiverap-maven/archappl.bash loglevel engine
/opt/epicsarchiverap-maven/archappl.bash loglevel engine root debug
/opt/epicsarchiverap-maven/archappl.bash loglevel engine root info
```

The component is `mgmt`, `engine`, `etl` or `retrieval`, the logger defaults
to `root`, and the level is one of `OFF`, `FATAL`, `ERROR`, `WARN`, `INFO`,
`DEBUG`, `TRACE`, `ALL` in any case; without a level the command prints the
current one. The reply is the BPL's JSON (`component`, `logger`, `level`, and
`previousLevel` for a set), and each change writes a WARN audit line; a
change on engine was observed under `archappl-engine`, not `archappl-mgmt`:
`SetLogLevel - Log level of logger [] changed from INFO to DEBUG`, where `[]`
is the root logger. A change lasts until the next change, a restart or a reload of
an edited site file. It reaches the WAR-level configuration only: Tomcat's
own loggers and the `java.util.logging` loggers, such as the CA client's,
follow `log4j2-tomcat.xml`. The command exits 2 for an invalid argument, a
missing `curl`, or an installed `archappl.conf` without `ARCHAPPL_MGMT_PORT`
(written before the command existed; run `make conf.archapplproperties` and
`make install` again), and exits 1 when the request fails: with the service
stopped, or when the BPL answers with a status other than 200.

The launcher's own lines (`started pid`, `stopping pid`, `process <pid> is
gone`) carry no component identifier; `journalctl -u
epicsarchiverap-maven.service` without `-t` shows them between the instance
lines, which is where the stop order and the cause of a failed unit are read.

`systemd-cat` runs with `--level-prefix=true`: a line that starts with a
syslog priority prefix such as `<3>` lands at that priority, and the prefix is
stripped. Both configurations start each line with the prefix of its level
(`<3>` ERROR, `<4>` WARN, `<6>` INFO, `<7>` DEBUG and TRACE), so
`journalctl -p err..err` selects errors from Tomcat, `java.util.logging` and
the application; a line written straight to stdout without a prefix, such as
the JVM's start banner, lands at the default priority.
A stack trace becomes one journal entry per line, in order, under the same
identifier. Retention is a host setting of journald (`MaxRetentionSec`,
`SystemMaxUse`), not of the appliance.

The access log stays a file, `logs/localhost_access_log.<date>.txt` per
instance, rotated daily by Tomcat, which removes files older than
`maxDays="90"` after each start and rotation.

## Process monitoring

`epicsarchiverap-maven-health.timer` periodically invokes a separate oneshot
service as `AA_USERID:AA_GROUPID`. It observes the appliance state and, when
eligible, runs the launcher's process check. It has no dependency that starts,
stops or restarts the appliance. The existing appliance unit and its asymmetric
startup/shutdown order remain the lifecycle authority. A dead JVM ends the
service through the launcher's own ordered stop; the health pair reports the
state and never restarts anything. Monitoring provides no survivor guarantee.

This section describes the shipped contract. Runtime acceptance evidence,
including target systemd compatibility, is tracked in
[M23](../milestone-265f580.md#m23---make-a-dead-instance-visible-to-systemd).
HTTP readiness, sample continuity and retrieval correctness require separate
application checks.

### Direct process check

Use the installed launcher, replacing the default account and path if configured:

```bash
sudo -u tomcat /opt/epicsarchiverap-maven/archappl.bash health
```

The Linux-only `health` command checks every instance in startup order. Each
line names the instance, the observed PID when available, and `PRESENT`, `FAIL`
or `ERROR` with a reason. An aggregate line follows. It reads the installed
configuration, validates each PID file, checks the actual Java executable,
Tomcat bootstrap arguments, `catalina.base`, `catalina.home`, process state and
start time, then repeats observations to reject inconsistent identities. It
does not delete PID files or signal processes. Other launcher commands retain
their existing behavior; `status` is a diagnostic listing, not this check.

| Exit | Meaning |
| --- | --- |
| 0 | Four expected JVM processes verified at the observation; no application-readiness claim |
| 1 | One or more missing, dead or invalid instances |
| 2 | Inspection incomplete, including unreadable/invalid configuration or inaccessible process identity |

Exit 2 takes precedence when instance failures and inspection errors coexist.
Configuration contents and full process command lines are not printed. Run as
the service account so Linux process-access restrictions do not obscure its JVMs.

### Scheduled checks and timing

The oneshot queries systemd before and after process inspection and buffers its
process output until the appliance state and activation identity agree. Its own
`MainPID` and `ExecMainStartTimestampMonotonic` identify this check's start; the
appliance's `InactiveExitTimestampMonotonic` identifies the current startup.
This uses the same monotonic clock without depending on wall time or suspend
time in `/proc/uptime`. The allowance is evaluated at check start, so the first
eligible inspection need not occur exactly at the allowance boundary.

| Appliance state | Scheduled behavior |
| --- | --- |
| Inactive with successful result, or stopping | `SKIP`; no missing-process alarm |
| Starting/active within startup allowance | `SKIP`; the allowance is not renewed each tick |
| Active after allowance | Run the full process check |
| Still starting after allowance, or failed | `FAIL` with appliance reason |
| Missing/unreadable unit, invalid timestamp or unknown state | `ERROR` |
| Start newer than the check, or state/activation changes during inspection | `SKIP`; retry next tick without a mixed instance verdict |

Scheduled skips return 3, listed in `SuccessExitStatus`; they are successful
monitor executions, not healthy-process evidence. A successful check or skip
leaves the oneshot inactive. A failed check leaves it failed until another
activation, when it is temporarily activating again. A later success clears
the current failure; a skip also ends that invocation successfully without
establishing process recovery. The journal retains earlier results.

| Make setting | Default | Effect |
| --- | --- | --- |
| `SYSTEMD_HEALTH_STARTUP_SECONDS` | 60 | Allowance from the current appliance start |
| `SYSTEMD_HEALTH_INTERVAL_SECONDS` | 30 | Delay after a completed health invocation |
| `SYSTEMD_HEALTH_ACCURACY_SECONDS` | 1 | Timer expiry window |
| `SYSTEMD_HEALTH_TIMEOUT_SECONDS` | 5 | Maximum oneshot start/check duration |
| `SYSTEMD_HEALTH_STOP_SECONDS` | 1 | Termination wait before final kill of the health control group |

The timer first fires one second after activation, with randomized delay zero.
The health service has no Restart or RemainAfterExit and disables start-rate
limiting so repeated failures remain observable. Timeout termination is confined
to the health service's control group. Settings can be overridden in
`CONFIG_SITE.local`; regenerate and reinstall the units to apply them.
The 45-second detection limit is a VM acceptance target for the defaults on an
awake, responsive system, not a verified measurement or hard real-time guarantee.

### Install, start and inspect

`make install` stops the existing monitor before changing installed payloads.
`make sd_install` stops monitoring and installs the units and existing Tomcat
override; it does not install launcher/configuration changes. Use full install
when those files changed. Generation precedes file installation, and enable
runs after file installation, ownership and daemon reload. The repository's
global `.NOTPARALLEL` remains in effect even with `make -j8`.

Neither install nor enable starts monitoring. After installation:

```bash
make sd_start
systemctl status --no-pager epicsarchiverap-maven-health.timer
systemctl show epicsarchiverap-maven-health.service -p ActiveState -p Result -p ExecMainStatus
journalctl -u epicsarchiverap-maven-health.service -o short-precise
```

The timer is enabled under both `timers.target` and the appliance's Wants
directory. Direct systemctl starts therefore activate it at boot and appliance
start, without a reverse dependency from monitoring to the appliance. For an
already-running appliance after install, `make sd_start` explicitly starts the
timer as well. It does not restart an active appliance. A deliberate appliance
stop leaves the timer running and reporting skips.

Inspect failure reasons, fix the diagnosed problem, and use the existing full
appliance recovery procedure when a restart is necessary:

```bash
make sd_restart
```

This is an operator action, never an automatic health response. Confirm four
processes with direct `health`, then observe eligible scheduled checks after
the startup allowance and perform separate HTTP/functional checks.

### Disable and remove monitoring

```bash
make sd_health_disable
make sd_health_clean
```

The first target stops the timer, stops any running health check, then removes
timer enable links. The second also removes the health unit files and reloads
systemd. Neither stops or disables the appliance. A failed stop prevents removal.
To restore the pair without changing an already-installed launcher:

```bash
make sd_install
make sd_enable
make sd_start
```

`sd_disable` additionally disables the appliance without stopping it; `sd_clean`
additionally removes its unit file with the existing cleanup semantics. The
Tomcat override remains separate. Full `uninstall` retains its explicit
appliance stop and payload removal, and is not a monitor-only operation.
