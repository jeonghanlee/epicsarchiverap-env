# EPICS Archiver Appliance Environment — Automated Tests

Phased install test suite that validates the Makefile system and build-wrapper
command generation and explicit VM installation/runtime acceptance.

## Phased SOP

Tests execute in strict order, from least to most privilege:

| Phase | Validates | Setup cost |
| :--- | :--- | :--- |
| 1. Logic | configure/ structure, Makefile parsing, doc integrity, real health negatives and unit file installation | Python 3; installed Java for PID cases; JDK compiler for unrelated-JVM negative |
| 2. Build wrapper | Real `make -n build`: configuration, site-overlay copy, Maven package command and ordering | none; no source checkout, JDK or network required |
| 3. Installation | Fresh VM, actual Ansible/Make/Maven install and payload checks | Pinned cloud-provision and ansible-provision checkouts; KVM, libvirt, cloud-init, SSH |
| 4. Runtime acceptance | Same VM: genuine JVMs, scheduled health, HTTP identity, CA acquisition/retrieval and persistence | Completed Phase 3 context; real systemd, EPICS IOC and selected database |

Phase 3 and Phase 4 call the driver in `tests/vm/driver.py`. The compatibility
filename `phase3-docker.bash` now selects VM installation; Docker is not a
prerequisite. Phase 4 consumes the recorded installation context. Local modes
never create or contact a VM. A system request without explicit inputs returns
77 before provisioning.

## System Workflow

The canonical [VM installation and runtime plan](../docs/milestone-2.0.1.md#m10---automate-vm-installation-and-runtime-tests)
owns acceptance criteria and observed results. The driver composes the real
provisioners; `guest.py` checks the installed application and its CA/HTTP paths.
Implementation is authorized. Full-matrix VM acceptance is pending; local
checks cannot establish installation or runtime acceptance.

| Owner | Required Responsibility |
| --- | --- |
| cloud-provision | Create a fresh VM, confirm SSH/cloud-init readiness, generate its runtime inventory, and perform explicit owned-resource cleanup |
| ansible-provision | Provision EPICS/JDK/Tomcat/the selected DB and call this repository's real ordered Make targets with explicit appliance commits |
| epicsarchiverap-env | Coordinate the pinned tools and independently verify installed payloads, database persistence, process identity, scheduled health, HTTP identity and real CA-to-retrieval data |

The acceptance matrix is Debian 13 and Rocky 8.10, each with MariaDB socket,
MariaDB TCP and SQLite: six fresh installations. Run cases sequentially.
External checkout paths, full published candidate/tool commits, fixture
identity, case selection and private evidence location are explicit inputs.
Installed guest HEADs must equal the requested commits; role defaults and
build sentinels cannot establish identity.

Phase 4 consumes the exact Phase 3 VM context. An Ansible recap, active
systemd unit, health startup skip, HTTP 200 or stored old sample alone is
insufficient. Acceptance requires matching WAR/JAR/configuration bytes, four
genuine JVM identities, three eligible scheduled health successes, and at
least ten distinct retrieved timestamps inside the requested window with
changing values matching actual CA observations. The candidate's raw API
boundary behavior must be observed: a permitted value preceding `from` is
recorded separately and never counts as fresh acquisition. Restart and
explicit repeat-install checks verify persistent PV configuration and
historical data, followed by fresh acquisition.

The complete original `UnitTestPVs.db` at fixture commit
5e6c12668c9c55f71ae1ba1c3a4384d86049b806 contains 10,018 records,
including 9,997 with `.1 second` SCAN. Loading it runs the whole IOC even
when only `test_0` is archived. Keep the fixture unchanged and verify its
loaded record inventory before starting IOC processing. The per-run
prefix uses twelve SHA256 hexadecimal characters from the creation ID;
every original record must appear in the real IOC's `dbl` output, and any
database loading error fails startup.
Record its actual counts/identity, IOC CPU/RSS, appliance JVM RSS, guest CPU/memory/swap
and elapsed startup/acquisition/restart times on the accepted two-vCPU,
4-GiB VM. The fixed deadlines require confirmation through these real
measurements; exceeding a bound fails the check. Resource or deadline
changes require a revised accepted plan and a new run. Measurements are
pending and do not yet establish capacity or a resource failure.

The runtime negatives use real wrong PID identity, IOC loss and a failed
source checkout. Normal preflight first validates all candidate/tool refs.
Only the named build-negative case passes a separate, confirmed absent source
ref through Ansible's actual build input; invalid normal inputs remain refused.
Internal Make, Maven, systemd and application paths must run unchanged.
Record expected/actual results, timestamps, exit codes and sanitized
diagnostics. Missing prerequisites or an unimplemented required check return
77 and leave the run INCOMPLETE; observed failures return nonzero. Local
checks cannot provision or contact a VM. Failed/interrupted guests and evidence
are retained; explicit cleanup must prove exact resource ownership.

The full `--system` execution retains its run context and returns
INCOMPLETE/77 while required cleanup is pending. A separately requested driver
`--cleanup=<run-context>` operation records removal of owned resources. Its
success alone does not establish acceptance. The read-only
`--verdict=<run-context>` operation returns 0 only when the same context has
complete matrix, assertion and cleanup evidence; existing failures remain
failures after cleanup. These operations are available through the runner and the driver. A diagnostic
installation/runtime success never satisfies the full-matrix verdict.

Before the first guest creation, record one immutable run-start baseline of
existing domain identities and live/persistent DHCP reservations. Keep a
separate cumulative list of exact owned domain, disk, seed ISO,
`.creation-record` and DHCP identities for all cases. Later observations check
for collisions; retained resources from earlier cases remain owned cleanup
targets and never enter the preservation baseline. T15 runs at least two real
cases sequentially with the first case's resources retained before the second.
After the real cloud-provision cleanup, independently confirm removal of all
owned resources, including each reservation in both live and persistent
libvirt network configuration, and preservation of the run-start baseline.
Resources outside the ownership list remain untouched. The tool's exit 0
alone is insufficient; failed inspection or a remaining owned resource
prevents cleanup acceptance. Retain the baseline, ownership and inspection
evidence with the original test results.

The domain UUID/name and its single interface on the selected network identify
the owned VM. DHCP ownership uses that actual interface MAC and reserved IPv4
address in both live and persistent configuration. New reservations may omit
`name`; a legacy name must match the owned domain. Duplicate MAC/IP entries or
changed ownership refuse further operations. Guest readiness additionally checks
the actual interface IP against that reservation and the actual hostname against
`sudo -n cloud-init query ds.meta_data.local-hostname`, with a 63-character limit.
Cleanup requires both the owned MAC and IP to be absent from DHCP configuration.

## Execution Inputs

Copy `tests/vm/config.example.json` into an ignored private working location
and replace every placeholder. Zero candidate/tool refs, image digests, free-space thresholds and `/replace/` paths are
examples only. Do not put credentials in clone URLs or commit private input
files. The driver requires HTTPS origins, full 40-character commits, SHA256
image/fixture identities, and a new evidence directory whose parent exists.
It creates that directory with mode 0700 and refuses reuse or symlink contexts.
Guest source/install/store roots must be literal absolute shell-safe paths.
Select the cold-build free-space threshold explicitly for each image; zero is
invalid. The driver records actual capacity/free space and refuses installation
below that selected threshold. Full matrix execution must confirm sizing.

| Section | Required inputs |
| --- | --- |
| `cloud` | Clean initialized checkout and published commit; existing `qemu:///system` connection and `lab` network; unique VM prefix |
| `ansible` | Clean initialized checkout and published commit; its maintained inventory path |
| `candidate` | Published environment/source commits and credential-free HTTPS clone URLs |
| `fixture` | Original committed `UnitTestPVs.db`: local repository and tracked path; preserve the fixed original commit and SHA256 in the example |
| `images` | Both cached base image directories, exact filenames, SHA256 values, disk sizes and positive `minimum_build_free_bytes` thresholds for the cold build |
| `guest` | Explicit source/install/store roots and service user/group; OS-specific colon-separated EPICS binary directories containing `softIocPVX`, `camonitor` and `caget` |
| `ssh` | `vmadmin` and the private key corresponding to cloud-provision's first default public key (`id_ed25519.pub`, then `id_rsa.pub`) |

Preflight clones both appliance candidates and confirms both tool commits are
published before VM creation. The published environment candidate must contain
exactly the executing driver, guest verifier, local regression and phase
entrypoint bytes. An old remote commit cannot verify unpublished local code.
The Ansible command uses its own configuration and maintained inventory plus
the generated single-VM inventory, with `--limit` fixed to the created VM.
All installation/system modes run the published environment candidate's full
`--local` suite once during preflight, before any VM is created. Its actual
command, exit status, output digest and candidate commit are retained in
`local_suite`; the final verdict checks that evidence. The CLI-only regression
result cannot replace this full-suite evidence.

## Test Execution

Run these commands from the repository root after preparing inputs. System
commands create disposable VMs and retain them for an explicit cleanup request.
The evidence directory must not already exist.

```bash
# Local phases only; no virtualization or network provisioning.
tests/run-all-tests.bash --local

# Complete sequential matrix; expected exit 77 until explicit cleanup.
tests/run-all-tests.bash --system --config work/vm-config.json --evidence work/vm-run

# Cumulative local checks followed by the same complete matrix.
tests/run-all-tests.bash --phase=4 --config work/vm-config.json --evidence work/vm-run

# Diagnostic installation of one selected positive case.
tests/phase3-docker.bash --config work/vm-config.json --evidence work/vm-case --case debian13-sqlite

# Diagnostic runtime on that same live installation context.
tests/phase4-vm.bash work/vm-case --case debian13-sqlite

# Explicit cleanup, then read-only full-matrix verdict.
tests/run-all-tests.bash --cleanup work/vm-run
tests/run-all-tests.bash --verdict work/vm-run
```

`--phase=3` runs local phases before the selected installation diagnosis.
`--phase=4` and `all` run local phases once before the complete matrix.
`--system` executes installation and runtime sequentially for each case,
shuts down each successful guest, then advances. Two additional fresh guests
exercise the real absent-source-ref checkout failure. Unexpected failures stop
the matrix and preserve ownership/evidence. No implicit deletion occurs.

Exit 0 means the selected operation passed; only `--verdict` can establish
full-matrix acceptance. Exit 1 is an observed failure, 2 is invalid input or
unsafe context, and 77 is missing prerequisites or incomplete acceptance.
A failed run remains failed after successful cleanup. Changed verifier bytes
invalidate an old context. Missing or mismatched ownership refuses cleanup;
cleanup inspection errors and remaining resources prevent acceptance.
Lifecycle selectors (OS, node, creation ID and prefix) must derive exactly the
recorded VM and file names before an external command can run. Cleanup checks
the creation record's ID and image name as well as actual domain/disk/DHCP
ownership.

Cleanup saves each VM's confirmed removal before proceeding to the next VM.
A retry independently rechecks completed cases and processes the remaining
owned cases, preserving the original failure. If an interrupted cleanup left
all of a recorded case's resources absent, the retry confirms that absence.
Incomplete ownership or a partially removed case with unverifiable remaining
resources still refuses deletion. The first cleanup's preservation snapshot
is retained across retries; an inspection error never establishes absence.

## VM Evidence

`run.json` binds inputs, the immutable run-start preservation baseline,
cumulative resource ownership, per-case results, build invocation identities,
guest artifact hashes and the candidate-bound full local-suite proof. Command files retain actual subprocess output and
exit codes. The candidate environment's source path links to the verified
candidate source checkout for the local schema checks. Any shell `[SKIP]` or
nonzero unittest `skipped=N` count in the local-suite output prevents preflight
and final acceptance; both operations use the same completeness check.
Guest result files retain WAR hashes, CA timestamps/values, raw API
responses, eligible health invocation results, and resource/timing observations.
`cleanup.json` retains independent pre/post-cleanup observations. `report.json`
contains a reduced summary with candidate commits, case results and verdict.
Raw context, inventory, variables and diagnostics remain private; review and
sanitize any excerpt before publishing it.

The interruption check signals an actual driver child while it waits on an
owned guest's diagnostic systemd helper, stops that helper, and checks that the
VM/DHCP identities remain. It records an expected negative independently of an
unexpected run failure. Cleanup refusal checks invoke the actual driver with
missing and mismatched ownership contexts and verify preservation. Those
assertions require live guests; local CLI tests cover refusal and read-only
verdict behavior only. Neither class simulates internal installation paths.

## Workspace and Logs

Each implemented shell phase creates an `archappl-test.*` workspace under
`${TMPDIR:-/dev/shm}`. Its `run.log` contains commands captured by that phase;
it does not contain every test result and may be empty.

`health-local.py` creates separate `archappl-health-*` and `archappl-units-*`
workspaces in Python's temporary directory (normally `/tmp`, or the configured
`TMPDIR`). Their `run.log` files contain health diagnostics and Make output,
respectively. Test verdicts and retained workspace paths are printed to the
console. Preserve both console streams and all printed workspace paths when
collecting evidence; the shell phase log alone is insufficient.

Workspaces are normally removed after successful tests and retained on failure.
Set `KEEP_WORKSPACE=1` to retain successful cases too. From the repository root,
the following keeps console output and all local-test workspaces together:

```bash
logdir=$(mktemp -d /tmp/archappl-evidence.XXXXXX)
test_rc=0
KEEP_WORKSPACE=1 TMPDIR="$logdir" tests/run-all-tests.bash --local > "$logdir/console.log" 2>&1 || test_rc=$?
printf 'Exit: %s\nEvidence: %s\n' "$test_rc" "$logdir"
cat "$logdir/console.log"
```

Keep the printed exit status and the entire evidence directory, including
`console.log` and its retained subdirectories. Inspect failures and skips in
the console summary; a skipped check is not verification.

## Verified Behaviors

### Phase 1 — Logic
- `configure/CONFIG_COMMON` is fully removed; no surviving file in `configure/` references that name.
- The three OS preset fragments (`debian12`, `debian13`, `rocky8`) are present under `configure/os/`.
- `make -n build` parses without error.
- The three `XXX.conf` Tomcat targets each generate a `CONFIG_SITE.local` line that includes the matching preset.
- `SRC_PATH` derives to `epicsarchiverap-maven-src` and downstream `ARCHAPPL_SITEID_TARGET_PATH` resolves under that subtree (regression guard for the CONFIG include reorder).
- Both `../CONFIG_SITE.local` and `configure/CONFIG_SITE.local` can change the install, template and storage roots. The shipped Make rules render matching configuration, policy and service paths, copy the site classpath files into the relocated template tree, and create the storage directories there. Wrapper paths are checked in the real installation dry-run; no WAR or Tomcat substitute is installed. Explicit overrides of the six derived paths retain their values.
- Both local configuration locations preserve Tomcat path and service-port overrides with all three OS presets. Real configuration generation and `serverxml.install`, using the shipped server template, agree on the service and shutdown ports. Tomcat installation paths are checked by dry-run; command-line overrides still win.
- The real `conf.storage` applies ownership to tier directories and existing files outside the archive root. The shipped launcher reads the rendered configuration and reports every storage path, including an unreadable tier and `/dev/shm`. These checks do not start an appliance JVM or install Tomcat.
- `sql.drop` and `sql.table.drop` reject SQLite and invalid backend values before invoking a database client, even when files with those target names exist. The real Make targets run for rejection cases; the MariaDB deletion command is checked only with a dry-run.
- The five removed obsolete documents (`README.ant.md`, `README.centos7.md`, `README.centos8.md`, `README.javapkgs.md`, `README.macos.md`) are not referenced from any tracked Markdown file other than `CHANGELOG.md`, the milestone register and `tests/`; the check fails when the search itself cannot run, such as outside a Git work tree.
- `CHANGELOG.md` is present; the misspelled `CHANGLOG.md` is gone.
- `checkfile` (expanded from the real `configure/RULES_FUNC` with `make -n`) selects the removal command for an existing file and no removal command for an absent one; its caller in `RULES_SQL` passes an unquoted path. This is a command-generation check, not an executed deletion test.
- `serverxml.install` pairs engine and etl with their own `ARCHAPPL_SHUTDOWN_*_PORT` variables.
- `RULES_REQ` carries no `get.jdbc` / `install.jdbc` rules.
- The legacy package scripts are gone; `scripts/install_os_packages.bash` parses and `configure/os/debian13.pkgs` names the distro JDK.
- No `java-env`, `MAVEN_HOME`, or local-install reference survives in `configure/`, `scripts/`, or `README.md`; `MAVEN_CMD` is the source tree's `mvnw`.
- `run_logged` preserves both success and a nonzero exit status from real child commands.
- All six Maven targets parse with `MAVEN_FLAGS` and render those flags immediately after the Maven Wrapper command. The check uses the real Makefile with `make -n`; it does not run Maven, read the example settings file, or verify proxy connectivity.
- `health-local.py` invokes an unchanged copy of the shipped launcher in a
  filesystem fixture. It checks absent/invalid/unreadable configuration, absent
  and malformed PID files, a nonexistent PID, a real unrelated process and a
  real zombie, multi-instance output, inspection-error precedence and preserved
  PID files/processes. Symlink-target traversal denial remains an inspection
  error. An unrelated Java main class with misleading Tomcat arguments must
  be rejected. It never constructs a healthy Tomcat substitute. Its
  `archappl.conf` names the store and a 100 percent threshold, as an installed
  file names the store, so these instance cases do not depend on disk usage.
- PID cases require an installed Java executable so the configuration identity
  is real; they skip explicitly when none exists. Permission-denial cases skip
  under root. The unrelated-JVM negative compiles `fixtures/UnrelatedJava.java`
  with the installed JDK and launches it with both JVM-property and application
  argument variants; it skips if that JDK has no compiler. A skipped case is
  not a pass. No appliance JVM is launched.
- Real Make configuration and unit file installation run in an isolated
  checkout/destination using default and alternate paths/accounts. Both `-j1`
  and `-j8` retain the shipped `.NOTPARALLEL`. Full-install and removal command
  ordering is checked by dry-run only; no live systemctl mutation is executed.
  If available, `systemd-analyze verify` checks the generated pair's unit syntax.
- The appliance unit rendered by the real `conf.systemd0` rule from an isolated
  copy carries `Type=simple`, `KillMode=mixed`, `Restart=no`, the
  `TimeoutStopSec` default and an `ExecStart` in service mode, with no
  `ExecStop`. The launcher parses (and passes `shellcheck -x` when installed),
  carries the per-instance `systemd-cat` identifier, the `wait -n` loop and the
  `bin/run.sh` wrapper, and no longer names `archappl_service.log`. The run
  wrapper template execs `catalina.sh run`; the instance install renders it.
  No JULI `logging.properties` is shipped, the access
  valve carries `maxDays="90"`, and the `log4j.properties` template and its
  `conf.log4j` target are gone. No JVM or systemd-cat is started.
- No site `log4j2.xml` is shipped and the install rules carry no log4j2 step;
  the real `conf.archappl` rule, run from the isolated copy, renders
  `ARCHAPPL_ROOT_LOGGER_LEVEL=INFO` by default, `WARN` under a command-line
  override and `ERROR` from a `../CONFIG_SITE.local` beside the copy (the
  site file must win over the shipped default),
  with `LOG4J_CONFIGURATION_FILE` a commented hook when `ARCHAPPL_LOG4J_SITE_FILE`
  is empty and an active assignment when it names a file.
- Tomcat's own logging goes through log4j2: `setenv.sh.in` sets the
  `$CATALINA_BASE/log4j` class path and the `log4j-jul` LogManager;
  `log4j2-tomcat.xml` carries the priority prefix, the root level from
  `ARCHAPPL_ROOT_LOGGER_LEVEL` and `monitorInterval`; the instance install,
  expanded with `make -n` from the isolated copy, renders `bin/setenv.sh`,
  removes a `conf/logging.properties` left by an earlier install, stops
  when `target/tomcat-log4j` is absent, and copies its jars into `log4j/`.

- The shipped launcher, run from a copy whose `archappl.conf` points
  `ARCHAPPL_MGMT_PORT` at a port with no listener, rejects an unknown
  component or level with exit 2 before any request, sends a lower-case level
  upper case and reports the refused request with exit 1, and stops with
  exit 2 naming `curl` when `curl` is not in `PATH`, exits 1 naming the status
  when a local HTTP server standing in for the transport answers 404, and
  exits 2 when `archappl.conf` has no mgmt port; the real `conf.archappl`
  render carries `ARCHAPPL_MGMT_PORT`.
- The same launcher copy's `status` prints the three mgmt URLs with the
  port from its `archappl.conf`, and with 17665 when the file lacks it; only
  the URL lines are judged. Both launcher checks drop an `ARCHAPPL_MGMT_PORT`
  exported by the caller, so the copy's `archappl.conf` alone decides.
- `DB_BACKEND` selects the configuration database: from an isolated copy, the
  real `conf.context` and `conf.systemd0` render the MariaDB resource and a unit
  requiring `mariadb.service` by default; `DB_BACKEND:=sqlite` in
  `../CONFIG_SITE.local` renders `org.sqlite.JDBC` with
  `journal_mode=WAL`, a one-connection pool, no user or password, and a unit
  without `mariadb.service`; `DB_BACKEND=postgres` stops both. `SQLITE_RUN_AS`
  expands to `sudo -u <account>` for a user-run build and to
  `runuser -u <account> --` when `id -u` reports 0 (an `id` in `PATH` that
  prints 0). With the real `sqlite3` and the source tree's
  `archappl_sqlite.sql`, run as the current user (`SUDO=`, `SQLITE_RUN_AS=`),
  `sql.fill` creates the file, succeeds again, restores a dropped table and
  succeeds on a WAL-mode file, every `CREATE` in the modified copy carries
  `IF NOT EXISTS`, the MariaDB copy is untouched, and `sql.show` lists the four
  tables; without `sqlite3` or the source tree this part prints `[SKIP]`.
- From an isolated copy run as the current user (`SUDO=`, `SUDOBASH="bash -c"`),
  the real `conf.storage` succeeds for a store under `/var/tmp`, under
  `/dev/shm` and under the user's home, prints the root-filesystem warning
  exactly when `df -P` puts the store on the root mount and the user-home
  warning only for the home store; each directory comes from `mktemp -d` and is
  removed, and a case whose directory cannot be made, or `/dev/shm` on the root
  mount, prints `[SKIP]`. The real `conf.archappl` render carries
  `ARCHAPPL_STORAGE_ALARM_PERCENT=85`, and `70` when `../CONFIG_SITE.local`
  sets it. The shipped launcher's `health`, with a real JDK, no running
  instance and the checkout as the store, prints
  `storage ... FAIL storage-threshold` and the verdict
  `health FAIL one-or-more-invalid-instances; storage-threshold` at a threshold
  equal to the measured usage, and `PRESENT` with only the instance cause one
  percent above it; `storage path=- ERROR configuration-load-failed` with exit 2
  when `archappl.conf` does not load; and the storage line with exit 2 when only
  the runtime paths are invalid.
- `DB_SOCKET` selects the MariaDB transport: from an isolated copy, the real
  `conf.context` and `db.conf` render the TCP URL and `DB_SOCKET=''` by
  default, and with a socket path in `../CONFIG_SITE.local` the
  `jdbc:mariadb://localhost/<db>?localSocket=<path>` URL and that path in
  `mariadb.conf`. Sourcing the rendered `mariadb.conf` and the shipped
  `scripts/mariadb_generic_function.bash` expands the root, admin, user and
  backup commands: TCP host and port and the `DB_HOST_NAME` account host by
  default, `--socket=<path>` with no host or port and the `localhost` account
  host with the path. The SQLite render is the same with and without
  `DB_SOCKET`. No database client runs.
- The account and database targets stop when the database client fails: from
  an isolated copy, with the real `mysql` client unable to connect, `make
  db.create`, `db.drop`, `db.show`, `db.addAdmin` and `db.rmAdmin` and the
  `mariadb_setup.bash` commands `dbCreate`, `dbDrop`, `dbShow`, `userDrop`,
  `hostnameAdminAdd` and `hostnameAdminRemove` each exit non-zero with
  `ERROR 2002` and a message naming the failed step on stderr. The admin
  command meets a closed loopback port; the root command meets a missing
  socket through `DB_SOCKET`, with a pass-through `sudo` first in `PATH`.
  Without a `mysql` client this part prints `[SKIP]`.

### Phase 2 — Build wrapper
- The real `make -n build` target parses and generates commands successfully.
- The package command runs from the configured source directory and invokes its Maven Wrapper with `clean package -DskipTests`.
- Only simple unquoted environment assignments may precede the wrapper; another command such as `echo` does not pass the invocation check.
- The six configuration-generation commands precede the site-overlay copy, which precedes the Maven package command.
- `MAVEN_FLAGS` is empty for this check; Phase 1 separately verifies nonempty flags across all six Maven targets.
- The check does not clone sources, execute Java or Maven, generate configuration, provision storage, or inspect WARs and release artifacts. Source compilation tests belong to [epicsarchiverap-maven CI](https://github.com/jeonghanlee/epicsarchiverap-maven/actions); VM acceptance verifies the actual installed candidate independently.
- The script remains `tests/phase2-compile.bash` for direct callers. Both `--local` and `--phase=2` still run Phase 1 followed by Phase 2.

### Phase 3 - Installation assertions (VM execution pending)

- The actual cloud-provision and ansible-provision paths prepare and install only the recorded fresh VM at the requested appliance commits.
- All four exploded WAR trees, Tomcat logging JARs, generated inputs, effective units and ownership match the real guest build and selected backend/site.
- The selected configuration database has the four application tables and is usable through the same account and transport as the appliance.

### Phase 4 - Runtime assertions (VM execution pending)

- The real installed appliance service and health pair operate with four verified JVM identities; three eligible scheduled health executions succeed.
- `getApplianceInfo` returns valid matching JSON, independently of process-presence checks.
- Original tracked IOC fixture values pass through real CA, engine, archive stores and raw `getData.json`; in-window timestamps and values match CA observations. A permitted preceding value cannot pass acquisition or IOC-loss checks.
- PV configuration/history survive restart and explicit same-candidate reinstall; new data is collected afterwards.
- Actual runtime/build faults produce non-success; stale data and skips cannot pass. The build fault uses a separate absent source ref after normal candidate preflight. Full acceptance also requires explicit cleanup and final evaluation of retained evidence. These are implemented assertions; their real VM results remain pending.

The source repository owns the documentation build. Planned changes to that
build are tracked in its own work register rather than as epicsarchiverap-env test work.

## Process-monitoring VM verification

This procedure is for a selected disposable systemd VM with four real Tomcat
instances. It provides a focused monitoring check separately from the full
Phase 4 driver. Obtain the VM owner and an
interruption window outside any uninterrupted heap-load observation before
running faults, reboots or lifecycle changes. The operator records each case's
exact action and expected outcome before execution. Default names below must
be replaced together when the installation is customized.

Retain the environment/source commit IDs, rendered configuration, systemd
version, effective units including drop-ins, service account, MainPID, and four
PID/start times. Do not publish configuration secrets or full command lines.
Before installing the health pair, obtain the original appliance's failure
behavior for comparison in the agreed interruption window. Use PID/start-time
identity immediately before any signal; never send a signal based only on an
old PID file or an unverified MainPID guess.

```bash
systemctl --version
systemctl cat epicsarchiverap-maven.service
systemctl show epicsarchiverap-maven.service -p MainPID -p ActiveState -p SubState -p Result
sudo -u tomcat /opt/epicsarchiverap-maven/archappl.bash health
systemctl cat epicsarchiverap-maven-health.service epicsarchiverap-maven-health.timer
systemctl list-timers --all epicsarchiverap-maven-health.timer
journalctl -u epicsarchiverap-maven-health.service -o short-precise
journalctl -u epicsarchiverap-maven.service -o short-precise
```

For each real process, record `/proc/<pid>/stat` field 22 and its executable
and Tomcat instance identity under the service account. Record relevant unit
monotonic timestamps, not only wall-clock text. Collect both journals over the
same interval so a monitor action can be distinguished from an existing
appliance stop or dependent component failure.

| Case | Action through the installed path | Required observation |
| --- | --- | --- |
| T4 baseline | Install and enable the real pair, start through `make sd_start`, run direct health under the service account and observe at least three eligible timer runs | Four real identities verified; direct exit 0 and three scheduled process successes; versions/effective units recorded |
| T1 identity completion | During the agreed interruption window, preserve one PID file and temporarily use another real instance's PID, then restore it | Wrong instance is named, exit 1; all instances still inspected; no signal or PID removal by health |
| T5 non-main loss | Revalidate a non-main test PID, terminate it while retaining its PID file, then observe at least three checks; restore baseline and repeat with two non-main faults | While appliance remains active, affected instances reported within 45 seconds; repeated failures remain observable; no health-initiated recovery |
| T5 boundary timing | Include a fault immediately after the affected instance's observation; bound that observation with precise monotonic tracing or another recorded observation method | Worst measured detection meets 45 seconds; retain timing uncertainty and do not substitute interval arithmetic for measurement |
| T6 lifecycle | Separately test reboot, direct systemctl restart, Make start, intentional stop and startup remaining activating beyond 60 seconds | Fresh bounded allowance; skipped checks identified; intentional stop not a missing-JVM alarm; overdue startup reports failure; both start paths resume monitoring |
| T7 MainPID | Compare original and monitored behavior after verified MainPID loss; if MainPID is 0, record it and observe process-group behavior without inventing a main PID | Existing appliance supervision preserved; secondary exits attributed using journals and start times; no survivor guarantee inferred |
| T8 error/recovery | Observe at least three repeated failures, a real observation-access error or bounded health timeout, then operator recovery | No false process success; recurrence continues; next eligible successful process check is distinct from a skip; timeout terminates only the health control group |
| T8 installation lifecycle | While preserving the appliance, disable/clean the monitor, reinstall/enable it, and start it explicitly; include reinstall while monitoring was already running | Timer and running check stop before payload/removal; no stale Wants links; no appliance stop caused by monitor cleanup; checks resume |

Restore the agreed full-appliance state after every fault, then revalidate PID
identities, direct health and application behavior before the next case. Record
secondary JVM failures even when expected from dependencies; their existence
alone neither proves monitor interference nor violates a survivor promise.
Unclear attribution or an unexecuted case remains Pending. Do not change the
45-second criterion after a failure. Record actual command, timestamp, target,
exit status and retained evidence in the canonical M23 verification rows.

## Incomplete system test result

The Phase 3 and Phase 4 entrypoints return 77 without provisioning when their
explicit inputs are missing. Local CLI regressions cover malformed normal
refs, unknown/conflicting operations, missing/symlink contexts, read-only
verdicts and retained failures. These checks invoke the shipped entrypoints;
they do not establish VM installation, runtime or cleanup acceptance.

## Configuration and database regression checks

`--local` also runs `database-config.py`: it renders the real templates,
parses their XML, sources their shell assignments, compares the runtime DB
name with both backend resources, and checks the system-phase exit contract.
It executes all eight SQLite `db.*` targets with missing prerequisites and
both present and absent MariaDB configuration, checking explanatory success
and unchanged configuration. Invalid backend values reject every DB/SQL/query
target; unsupported SQLite deletion/query operations reject even when files
matching target names exist. Standalone helper operations reject SQLite and
invalid selectors before reading configuration.
It also verifies that a failed `conf.archappl` substitution returns nonzero
without creating or replacing the output, and that inline comments on
`DB_SOCKET` leave JDBC and shell clients using the same transport and path.

For actual MariaDB account, schema, query, backup and restore operations, and
SQLite schema load/list operations:

```bash
python3 tests/database-config.py --integration
```

`AA_TEST_SOURCE_PATH` selects an alternate source checkout or a tree containing
the exact source schema files at their original paths; the default is
`epicsarchiverap-maven-src`.

This requires `mariadb-install-db`, `mariadbd`, `mysql`, `mysqldump`,
`sqlite3`, and the source checkout's `archappl_mysql.sql` and
`archappl_sqlite.sql`. It creates a private datadir, socket
and loopback listener and stops that server at exit. The only substitute is
a pass-through `sudo` at the privilege boundary; SQL runs through the shipped
setup script and the real client/server. The socket setting comes from a local
override with an inline comment. Both TCP and socket connections use
a password containing shell, XML and SQL special characters. The test also
checks that removing a configured admin preserves unrelated `admin` accounts.
The private server's general log must remain unchanged while SQLite `db.*`
skips and unsupported/invalid targets and helper actions reject; the generated
MariaDB configuration and application data remain unchanged. SQLite uses the
shipped schema and real Make targets, checks repeated loading and missing-table
restoration, and preserves MariaDB configuration. Account/privilege selection
uses the current OS user for SQLite; host account provisioning is outside this
check.
It does not verify host sudo policy or Tomcat runtime authentication.

`install-payload.py` accepts two real Maven `target` directories and an
`--old-log4j` directory containing real old log4j JARs. It runs the shipped
`install.mgmt`, `install.engine`, `install.etl` and `install.retrieval` targets
twice under a temporary prefix and compares every installed payload file with
the second WAR and JAR set. It checks preservation of logs, external config,
work/temp files, other webapps and a storage-file marker. It then verifies
that missing, ambiguous and truncated WAR inputs and missing JARs fail without
changing the installed mgmt payload. It exits nonzero on a mismatch and retains
its workspace and log. No systemd unit or running appliance is changed. This
checks installation contents, not runtime upgrade behavior or host privileges.

Run the payload comparison from the epicsarchiverap-env checkout, using actual build paths:

```bash
python3 tests/install-payload.py /path/old/target /path/new/target --old-log4j /path/old/log4j
```

Exit 0 means all four payload comparisons, state-preservation checks, invalid
artifact cases and destination-rejection cases passed. The printed workspace
contains the installation log.
