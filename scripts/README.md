# Appliance scripts

These scripts install a systemd-managed EPICS Archiver Appliance on Debian 13,
Rocky Linux 8, Rocky Linux 10.2, Ubuntu 24.04 LTS or Ubuntu 26.04 LTS.
Choose one entry script for the required database connection.
All three use [install-local-common.bash](install-local-common.bash), the
configured source pin, and the `als` site configuration.

| Entry script | Database connection |
| --- | --- |
| [install-local-sqlite.bash](install-local-sqlite.bash) | SQLite file selected by `ARCHAPPL_SQLITE_FILE` |
| [install-local-mariadb-uds.bash](install-local-mariadb-uds.bash) | MariaDB Unix domain socket selected by `--socket`, `DB_SOCKET`, or the OS default |
| [install-local-mariadb-tcp.bash](install-local-mariadb-tcp.bash) | MariaDB at `127.0.0.1`, using `DB_HOST_PORT` |

Run an entry script as the ordinary checkout owner with `sudo` access.
Keep storage, Tomcat, service-account, and database settings in
`../CONFIG_SITE.local`, relative to the repository root.
Read the [installation procedure](../docs/README.install.md#local-systemd-installation)
for prerequisites, configuration placement, and database preparation before
confirming installation.

## Script responsibilities and callers

This directory contains 13 Bash files. The three entry scripts above select the
database mode; the remaining scripts have these responsibilities:

| Script | Caller | Responsibility |
| --- | --- | --- |
| [install-local-common.bash](install-local-common.bash) | Three installation entry scripts | Preflight, installation order, database preparation, startup checks, and optional PV verification |
| [install_os_packages.bash](install_os_packages.bash) | Installer or host administrator | Detects the OS and installs its package list; SQLite mode excludes MariaDB packages |
| [install-payload.bash](install-payload.bash) | Make installation rules | Stages and replaces one component's WAR and logging JARs |
| [render-db-config.bash](render-db-config.bash) | Make configuration rules | Renders escaped shell or XML database settings |
| [check_storage_placement.bash](check_storage_placement.bash) | `make conf.storage` | Reports storage placement warnings; warnings do not fail the target |
| [archappl.bash](archappl.bash) | Installed systemd service or operator | Runs the four instances, checks process/storage health, and manages application log levels |
| [mariadb_setup.bash](mariadb_setup.bash) | Make database rules | Dispatches database, account, schema, backup, and restore operations |
| [mariadb_generic_function.bash](mariadb_generic_function.bash) | Sourced by `mariadb_setup.bash` | Builds MariaDB client arguments and executes SQL operations |
| [verify-local-pv.bash](verify-local-pv.bash) | Installer or operator | Starts a soft IOC and checks changing CA values against retrieved samples |
| [verify-local-pv-curl.bash](verify-local-pv-curl.bash) | CSV client during PV verification | Records retrieval HTTP evidence and checks the returned PV identity |

Use the installation entry scripts or Make targets for installation helpers.
The sourced libraries and retrieval adapter are not operator entry points.
The installed launcher's `health` command verifies actual process identities and
filesystem usage. Its `status` command displays UI URLs and journal commands,
then runs the same health check and returns its exit status. Run either check
as the service account so process-access restrictions do not obscure the JVMs.
Neither checks application readiness or PV acquisition.
The `storage` command runs `du` with the configured directory as a literal
argument; `storage all` includes individual files. A failed `du` returns nonzero.

## Supported OS defaults

Automatic detection accepts the following versions. Preset names also select
the corresponding Make configuration and package list.

| OS version | Preset | Package manager | Default MariaDB socket |
| --- | --- | --- | --- |
| Debian 13 | `debian13` | `apt-get` | `/run/mysqld/mysqld.sock` |
| Rocky Linux 8.x | `rocky8` | `dnf` | `/var/lib/mysql/mysql.sock` |
| Rocky Linux 10.2 | `rocky10` | `dnf` | `/var/lib/mysql/mysql.sock` |
| Ubuntu 24.04 LTS | `ubuntu24` | `apt-get` | `/run/mysqld/mysqld.sock` |
| Ubuntu 26.04 LTS | `ubuntu26` | `apt-get` | `/run/mysqld/mysqld.sock` |

The default JDK 21 path is `/usr/lib/jvm/java-21-openjdk-amd64` on Debian and
Ubuntu, and `/usr/lib/jvm/java-21-openjdk` on Rocky Linux. These are x86-64
distribution paths. All five presets preserve a custom `JAVA_HOME` in
`../CONFIG_SITE.local`; `JAVA_PATH` follows that directory unless overridden.
`--skip-packages` skips package installation but still applies the OS preset.
Package installation and a successful plan do not prove systemd startup or
PV acquisition on a host. Other OS versions are rejected by these entry scripts,
even when a separate legacy Make preset exists.

## Preview and Run

From the repository root, print the plan for your selected mode. The following
commands are alternatives; run only the line matching your choice:

```bash
bash scripts/install-local-sqlite.bash --plan
bash scripts/install-local-mariadb-uds.bash --plan
bash scripts/install-local-mariadb-tcp.bash --plan
```

The plan reads configuration and checks existing source inputs without changing
files, building, or starting services. To install, run the same entry script
without `--plan` and review the confirmation before answering `y`:

```bash
bash scripts/install-local-sqlite.bash
bash scripts/install-local-mariadb-uds.bash
bash scripts/install-local-mariadb-tcp.bash
```

The installer prepares packages, selects the source pin, prepares Tomcat 9, and
builds the appliance. When reusing Tomcat, it then stops an installed appliance, prepares the
database, replaces the payload, starts the service and health timer, and checks
startup readiness. The completion screen shows the management UI, all four
component startup API URLs, process/storage health, a health command, and the
appliance identity, version, and information API URL. Waiting messages appear
when the outstanding checks change. `localhost` refers to the installed host;
use that host's browser or SSH port forwarding from another machine.
The default management page is `http://localhost:17665/mgmt/ui/index.html`.
Use the complete page path; `/mgmt/ui` names a directory.

On failure, the installer displays the last observed result for each check,
including successful checks, UI and API URLs, and a journal command with `sudo`.
Unit checks report `NOT ACTIVE` only for an observed non-active state.
Permission and other query errors report `INSPECTION ERROR` with the diagnostic;
queries that exceed the startup deadline report `TIMED OUT`.
Early signal termination reports `INSPECTION ERROR` with the exit status,
including during health inspection.
A storage failure does not imply that the four components failed to start.
The message identifies filesystem usage at or above the configured limit and
keeps the nonzero verification result. Installed files and data remain; the
installer does not stop or restart the appliance after that failure.
The default storage limit remains 85%; the installer does not delete data
or change that limit.

The information API confirms that management responds. It does not prove that
the appliance receives or stores PV samples. The installer reports PV acquisition,
storage, and retrieval as `NOT CHECKED` until the optional test passes.

MariaDB installation creates or updates the configured database and accounts,
including existing account passwords and grants. `--existing-db` skips that
provisioning; schema loading still runs, and `DB_USER_PASS` must match the
existing application account. Failures after the appliance stop can leave it
stopped or partly replaced; there is no automatic rollback.

If the checkout owner cannot execute existing Tomcat, installation offers two
choices: check and use it as the service account, or back it up and install the
configured version. Use `--tomcat existing` or `--tomcat replace` to select
explicitly for unattended installation. Replacement stops an installed appliance
and retains the original default Tomcat directory in a unique sibling backup.
The menu marks replacement unavailable for custom, symlink, or overlapping paths.
Replacement refuses a Tomcat directory containing the checkout, or overlapping
the source checkout, appliance install directory, archive root, any archive tier,
or SQLite file. These checks run before download or service shutdown and resolve
symlink aliases in the protected paths. Existing
Tomcat checks require both read and execute access to `catalina.sh` as the
service account.

Each entry script accepts `--help`. See the
[installation options](../docs/README.install.md#local-systemd-installation)
for `--tomcat`, `--skip-packages`, `--socket`, `--existing-db`, `--timeout`, and `--yes`.

## Verify one changing PV

Before installation, answer `y` to select the optional soft IOC test. The installer
checks the exported `EPICS_BASE` and executable `softIoc` and `caget` before
installing packages or changing the appliance. If the environment is unavailable,
source your EPICS environment setup file in the same terminal and rerun the
installer. The installer does not source a setup file automatically.
The test requires
EPICS Base `softIoc` and `caget`, plus `curl`, `jq`, and the selected source
checkout's `getDataToCsv.bash` and `archiverClient.bash`. EPICS Base is not
installed by these scripts. The binary directory is resolved from
`$EPICS_BASE/bin/$EPICS_HOST_ARCH`, or from the single directory containing both
executables under `$EPICS_BASE/bin` when `EPICS_HOST_ARCH` is unset. No binary
directory prompt is shown after installation.
The appliance must discover the IOC on loopback using Channel Access.

The [verification script](verify-local-pv.bash) starts the shipped
[counter database](fixtures/local-install-pv.db), registers a unique PV through
`archivePV`, waits for archiving and five seconds of collection, and pauses the
PV to flush samples before extracting them through the pinned Maven CSV client.
The [retrieval adapter](verify-local-pv-curl.bash) retains the exact HTTP response
used by that client and requires its `meta.name` to match the requested PV.
The verifier requires at least two distinct archived values matching actual CA reads,
with sample timestamps within one second of those reads, compared using seconds
and nanoseconds, and within the requested
range. Empty CSV files do not pass. The result displays the latest matched
sample's UTC timestamp and value, the CSV path, and the evidence directory.
This checks short-term acquisition and retrieval; it does not check ETL movement
between storage tiers or long-term retention.

When verification reaches the cleanup menu, the test PV is already paused.
Choose to stop the IOC or resume PV archiving and keep the IOC running.
The default leaves the PV paused and stops its IOC. Keeping the IOC resumes
archiving. The script checks the owned IOC's PID and start time immediately
before resume and again after the response. If the IOC exits during the menu
wait, verification fails with the PV paused. If it exits during resume,
verification fails and cleanup attempts to pause the PV again.
A successful keep result confirms IOC presence at that observation;
it does not monitor the IOC after the script exits.
On failure or interruption, the script stops
its IOC and attempts to pause its unique PV. An unconfirmed pause produces a
warning; the registration might remain active. The PV registration remains in
the appliance configuration database, and original samples remain in its configured
archive stores. The printed `/tmp/archiver-local-pv.*` directory retains the IOC
log, CA observations, API request/response files, and any CSV files produced before
the test ended. Copy this evidence directory before the host removes temporary
files. It is not a backup of the appliance database or archive stores.

`--yes` and non-interactive installation skip the optional test.
Optional test failure leaves the completed installation intact and reports a
separate failure. To inspect the standalone verifier options, run:

```bash
bash scripts/verify-local-pv.bash --help
```

To retry without installation, supply `MGMT_BPL`, `RETRIEVAL`, and
`SOURCE_CHECKOUT` as its three arguments. The API URLs must use `localhost` or
`127.0.0.1`, explicit ports, and the `/mgmt/bpl` and `/retrieval` paths.
`--check-epics` validates Base prerequisites without starting an IOC or contacting
the appliance. `--epics-bin` explicitly selects the Base binary directory instead
of using `EPICS_BASE`; `--cleanup stop` or
`--cleanup keep` permits unattended execution. `--timeout` selects 10..3600
seconds, with 180 seconds as default. Cleanup has a separate HTTP timeout of
10 seconds.

### Stop a retained test IOC

Run these commands on the installed host as the user who ran the verification.
Replace the evidence path with the directory printed by that run, and use the
management port selected for the installation:

```bash
evidence='/tmp/archiver-local-pv.REPLACE_ME'
mgmt='http://localhost:17665/mgmt/bpl'
pv=$(cat -- "$evidence/pvs.txt")
ioc_pid=$(cat -- "$evidence/ioc.pid")
pause_url="$mgmt/pauseArchivingPV"
status_url="$mgmt/getPVStatus"
curl -q --noproxy '*' -fsS --max-time 10 -G --data-urlencode "pv=$pv" "$pause_url"
curl -q --noproxy '*' -fsS --max-time 10 -G --data-urlencode "pv=$pv" "$status_url" > "$evidence/manual-status.json"
filter='length == 1 and .[0].pvName == $pv and .[0].status == "Paused"'
jq -e --arg pv "$pv" "$filter" "$evidence/manual-status.json"
```

Require the status check to print `true` and exit 0 before continuing. A newly
paused PV returns `status: "ok"` from the pause API; an already paused PV can
return a validation message instead. In either case, the matching `getPVStatus`
entry must report `Paused`. If an HTTP request or the status check fails, stop
here and inspect the response.

Next, inspect the process and expected IOC prefix:

```bash
printf 'Expected IOC macro: P=%s\n' "${pv%Value}"
ps -ww -p "$ioc_pid" -o pid=,user=,comm=,args=
readlink -- "/proc/$ioc_pid/exe"
```

Require the PID to belong to your user, the executable to be the selected Base
`softIoc`, and its arguments to contain the printed `P=` macro and this test's
counter database. The PID file alone does not prove identity after a reboot or
PID reuse. If the process is absent or any detail differs, do not send a signal.
After confirming the identity, stop it and check again:

```bash
kill -TERM -- "$ioc_pid"
sleep 2
ps -ww -p "$ioc_pid" -o pid=,user=,comm=,args=
```

The last command should show no process row. If a row remains, inspect it before
taking further action. Pausing and stopping retain the PV registration, original
stored samples, and the evidence directory.

For broader acceptance, perform the separate
[functional verification](../docs/README.install.md#functional-verification).
