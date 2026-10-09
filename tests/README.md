# EPICS Archiver Appliance Environment — Automated Tests

Phased install test suite that validates the Makefile system and build-wrapper
command generation and explicit VM installation/runtime acceptance.

## Phased SOP

Tests execute in strict order, from least to most privilege:

| Phase | Validates | Setup cost |
| :--- | :--- | :--- |
| 1. Logic | configure/ structure, Makefile parsing, doc integrity, real health negatives and unit file installation | Python 3; installed Java for PID cases; JDK compiler for unrelated-JVM negative |
| 2. Build wrapper | Real `make -n build`: configuration, site-overlay copy, Maven package command and ordering | none; no source checkout, JDK or network required |
| 3. Installation | Handed-off fresh VM, actual Ansible/Make/Maven install and payload checks | Initialized run; cloud-provision guest and handoff; pinned ansible-provision checkout; libvirt, SSH |
| 4. Runtime acceptance | Same VM: genuine JVMs, scheduled health, HTTP identity, CA acquisition/retrieval and persistence | The same case invocation; real systemd, EPICS IOC and selected database |

Phases 3 and 4 run together as one case of the driver in `tests/vm/driver.py`.
The design is in [VM installation and runtime tests](../docs/README.vmtests.md).
Local modes never create or contact a VM. The runner modes `--system`,
`--phase=3`, `--phase=4`, and `all` run no checks, name the VM operations, and
exit 77; run local checks with `--local`. The compatibility entry points `phase3-docker.bash` and
`phase4-vm.bash` exit 77 without arguments and pass arguments to `--case`;
Docker is not a prerequisite.

## System Workflow

[VM installation and runtime tests](../docs/README.vmtests.md) describes the
components, the run and case model, the guest handoff, cleanup verification,
and the verdict. The canonical
[VM installation and runtime plan](../docs/milestone-2.0.1.md#m10---automate-vm-installation-and-runtime-tests)
owns acceptance criteria and observed results. Local checks cannot establish
installation or runtime acceptance.

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
| `cloud` | Clean initialized checkout and published commit that provides the inventory generator; existing `qemu:///system` connection and `lab` network; the VM prefix cloud-provision uses |
| `ansible` | Clean initialized checkout and published commit; its maintained inventory path |
| `candidate` | Published environment/source commits and credential-free HTTPS clone URLs |
| `fixture` | Original committed `UnitTestPVs.db`: local repository and tracked path; preserve the fixed original commit and SHA256 in the example |
| `images` | Both cached base image directories, exact filenames, SHA256 values, disk sizes and positive `minimum_build_free_bytes` thresholds for the cold build |
| `guest` | Explicit source/install/store roots and service user/group; OS-specific colon-separated EPICS binary directories containing `softIocPVX`, `camonitor` and `caget` |
| `ssh` | `vmadmin` and the private key corresponding to cloud-provision's first default public key (`id_ed25519.pub`, then `id_rsa.pub`) |

`--init` clones both appliance candidates and confirms both tool commits are
published before any case runs. The published environment candidate must contain
exactly the executing driver, guest verifier, local regression and phase
entrypoint bytes. An old remote commit cannot verify unpublished local code.
The Ansible command uses its own configuration and maintained inventory plus
the generated single-VM inventory, with `--limit` fixed to the handed-off VM.
`--init` runs the published environment candidate's full `--local` suite once,
before any case runs. Its actual
command, exit status, output digest and candidate commit are retained in
`local_suite`; the final verdict checks that evidence. The CLI-only regression
result cannot replace this full-suite evidence.

### SQLite Service Inventory

The guest verifier reads the complete real service unit-file inventory and
requires a successful command plus the installed appliance unit. It rejects
MariaDB, MySQL and mysqld service names, including masked units and aliases.
An empty inventory or failed query cannot establish database-service absence.
The raw command result and parsed inventory are retained independently of the
service-account schema and effective dependency checks.

Local regressions use the shipped helper, real `systemctl --root` and isolated
unit-file fixtures. They verify filesystem inventory behavior only; full SQLite
installation and runtime acceptance require the published-candidate VM matrix.

## Test Execution

Run these commands from the repository root after preparing inputs. The
evidence directory must not already exist. The driver never creates, stops, or
deletes a guest; cloud-provision does that on request.

The following command runs the local phases only, without virtualization or
network provisioning:

```bash
tests/run-all-tests.bash --local
```

The following command opens a run. It runs the published candidate's local
suite and records the baseline; it contacts no guest:

```bash
tests/run-all-tests.bash --init --config work/vm-config.json --evidence work/vm-run
```

Request from cloud-provision a fresh base guest that meets the
[Acceptance matrix](../docs/README.vmtests.md#acceptance-matrix) for one case,
and write its handoff file as
[Guest handoff](../docs/README.vmtests.md#guest-handoff) describes.
The following command runs that case; repeat it for all eight cases in any
order, one guest per case:

```bash
tests/run-all-tests.bash --case debian13-sqlite --handoff work/debian13-sqlite-handoff.json work/vm-run
```

Keep each finished guest defined until cleanup; a shut-off guest stays owned.
After all cases, request cleanup of the run's guests from cloud-provision. The
`<case>-handoff.json` files in the run directory name exactly those guests. A
guest whose handoff was refused is not part of the run, and
`--verify-cleanup` does not inspect it; request its cleanup separately. The
following commands verify the removal and evaluate the run:

```bash
tests/run-all-tests.bash --verify-cleanup work/vm-run
tests/run-all-tests.bash --verdict work/vm-run
```

Start each `--case` invocation from a shell that outlives the case, such as an
operator terminal or a user unit. A tool session that stops its background
tasks at a time limit also stops the driver. The following command starts the
case as a user unit; `--same-dir` keeps the repository root as its working
directory, so the relative paths resolve:

```bash
systemd-run --user --same-dir --unit=vmtest-debian13-sqlite tests/run-all-tests.bash --case debian13-sqlite --handoff work/debian13-sqlite-handoff.json work/vm-run
```

The unit's output is in the user journal. A failed unit keeps its exit status,
and its name must be reset before reuse. A successful unit is removed when it
ends; the driver's `PASS` line in the journal records its success:

```bash
journalctl --user -u vmtest-debian13-sqlite --no-pager -o cat
systemctl --user show vmtest-debian13-sqlite -p ActiveState -p ExecMainStatus
systemctl --user reset-failed vmtest-debian13-sqlite
```

The user manager stops its units when the user's last session ends unless
lingering is enabled with `loginctl enable-linger`.

Exit 0 means the selected operation passed; only `--verdict` can establish
full-matrix acceptance. Exit 1 is an observed failure, 2 is invalid input,
refused ownership, or an unsafe context, and 77 is a missing prerequisite or
an incomplete run. A refused handoff leaves the run record unchanged. A recorded
failure remains a failure after cleanup, and the run then accepts no further
case. Changed verifier bytes invalidate an existing run.

## VM Evidence

[Run context and evidence](../docs/README.vmtests.md#run-context-and-evidence)
lists the files in a run directory. Raw context, handoffs, inventory,
variables, and diagnostics remain private; review and sanitize any excerpt
before publishing it.

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
- The six OS preset fragments (`debian12`, `debian13`, `rocky8`, `rocky10`, `ubuntu24`, `ubuntu26`) are present under `configure/os/`.
- `make -n build` parses without error.
- The six `XXX.conf` Tomcat targets each generate a `CONFIG_SITE.local` line that includes the matching preset.
- `SRC_PATH` derives to `epicsarchiverap-maven-src` and downstream `ARCHAPPL_SITEID_TARGET_PATH` resolves under that subtree (regression guard for the CONFIG include reorder).
- Both `../CONFIG_SITE.local` and `configure/CONFIG_SITE.local` can change the install, template and storage roots. The shipped Make rules render matching configuration, policy and service paths, copy the site classpath files into the relocated template tree, and create the storage directories there. Wrapper paths are checked in the real installation dry-run; no WAR or Tomcat substitute is installed. Explicit overrides of the six derived paths retain their values.
- Both local configuration locations preserve Tomcat path and service-port overrides with the `debian12`, `debian13` and `rocky8` presets. Real configuration generation and `serverxml.install`, using the shipped server template, agree on the service and shutdown ports. Tomcat installation paths are checked by dry-run; command-line overrides still win.
- All five supported local-install OS presets preserve a custom `JAVA_HOME`
  from `../CONFIG_SITE.local`, and the real Make configuration derives its
  matching `JAVA_PATH`.
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
- The shipped `status` path rejects missing PID files and unrelated live
  processes through the real health check. Storage tests run real `du` with
  only the privilege transport replaced; literal shell characters remain path
  data, and a missing directory returns nonzero.

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
  `scripts/mariadb_generic_function.bash` expands the admin, user, and backup
  commands: TCP host and port and the `DB_HOST_NAME` account host by default,
  `--socket=<path>` with no host or port and the `localhost` account host with
  the path. Root commands explicitly use `localhost` and the socket protocol,
  with `--socket=<path>` when configured. The SQLite render is the same with and without
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

### Native database and PV checks

`database-config.py --integration` uses a private real MariaDB server and the
selected source schema. Socket and TCP cases check account identities, schema
loading, backup/restore, private backup permissions, rejection of an existing
backup or symlink, failed dump cleanup, and a file appearing during publication.
Account deletion output must omit password hashes. The root cleanup target
preserves the existing authentication method. SQLite uses its real source schema.
Conflicting root client defaults select TCP and a closed port; account preparation
must reach the private server through its socket for both appliance transports.
An empty table query succeeds, while missing-table queries fail through the
helper and the real Make target.
Denied account metadata queries return nonzero after successful primary account
changes; the private server's account inventory confirms those changes.
These checks do not contact the host's database service.

`local-install-readiness.bash` starts four real WARs with Tomcat 9 and runs the
shipped installer readiness functions and launcher health inspection.
It checks successful output, inactive and failed units, denied and missing-unit
queries, early signal termination versus deadlines for unit and health inspection,
a storage limit equal to actual filesystem usage,
and a missing PID file. Its health configuration uses the executable of the
running management JVM, including a JDK selected through `JAVA_HOME`.
Health recovery clears interruption diagnostics; an interrupted later check
preserves the last completed process and storage observations.
Failure output must preserve successful startup results,
UI and API URLs, and the nonzero exit status without claiming installation success.
Only privilege and systemd command boundaries are replaced; HTTP, JVM identity,
and filesystem inspection run against the real appliance.
This check does not establish host systemd installation or scheduled timer behavior.
Set `AA_TEST_TOMCAT_HOME` to a readable Tomcat 9 installation and prepare the
selected source's four WARs before running the check from the repository root:

```bash
bash tests/local-install-readiness.bash
```

`local-install-pv.bash` starts four real WARs and a real soft IOC in an isolated
workspace. It checks acquisition/retrieval, interactive keep/resume, and failed
retrieval cleanup. Its signal, range, and menu checks use the shipped verifier,
IOC database, and CSV client, replacing only HTTP transport.
`local-install-pv-menu.py` checks a live keep result, IOC exit during the cleanup
menu, and IOC exit during resume. Menu fixtures verify lifecycle handling;
the real appliance round trip establishes sample storage and retrieval.

### Phase 2 — Build wrapper

- The real `make -n build` target parses and generates commands successfully.
- The package command runs from the configured source directory and invokes its Maven Wrapper with `clean package -DskipTests`.
- Only simple unquoted environment assignments may precede the wrapper; another command such as `echo` does not pass the invocation check.
- The six configuration-generation commands precede the site-overlay copy, which precedes the Maven package command.
- `MAVEN_FLAGS` is empty for this check; Phase 1 separately verifies nonempty flags across all six Maven targets.
- The check does not clone sources, execute Java or Maven, generate configuration, provision storage, or inspect WARs and release artifacts. Source compilation tests belong to [epicsarchiverap-maven CI](https://github.com/jeonghanlee/epicsarchiverap-maven/actions); VM acceptance verifies the actual installed candidate independently.
- The script remains `tests/phase2-compile.bash` for direct callers. Both `--local` and `--phase=2` still run Phase 1 followed by Phase 2.

### Phase 3 - Installation assertions

- cloud-provision prepares and ansible-provision installs only the handed-off fresh VM at the requested appliance commits.
- All four exploded WAR trees, Tomcat logging JARs, generated inputs, effective units and ownership match the real guest build and selected backend/site.
- The selected configuration database has the four application tables and is usable through the same account and transport as the appliance.

### Phase 4 - Runtime assertions

- The real installed appliance service and health pair operate with four verified JVM identities; three eligible scheduled health executions succeed.
- `getApplianceInfo` returns valid matching JSON, independently of process-presence checks.
- Original tracked IOC fixture values pass through real CA, engine, archive stores and raw `getData.json`; in-window timestamps and values match CA observations. A permitted preceding value cannot pass acquisition or IOC-loss checks.
- PV configuration/history survive restart and explicit same-candidate reinstall; new data is collected afterwards.
- Actual runtime/build faults produce non-success; stale data and skips cannot pass. The build fault uses a separate absent source ref after normal candidate preflight. Full acceptance also requires verified cleanup and final evaluation of retained evidence. Observed VM results are in the milestone register.

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

The runner VM modes and the compatibility entry points return 77 without
contacting a VM when their explicit inputs are missing. Local CLI regressions
cover malformed normal refs, unknown and conflicting operations, missing and
symlink contexts, handoff validation, case refusals that leave the run
unchanged, the stored-origin check, the fresh-guest probe, order-independent
and read-only verdicts, and retained failures. These checks invoke the shipped
entry points; they do not establish VM installation, runtime, or cleanup
acceptance.

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

The same local checks verify mode 0600 when the real `db.conf` target creates
or replaces MariaDB client configuration under a permissive umask. All three
local installer entry scripts run their plan path against both a source clone
and a Git worktree. Generated `als` inputs are allowed; tracked changes,
untracked source files, and ignored inputs under `src` and `.mvn` are rejected.

The readiness unit check invokes the shipped `wait_ready` and
`run_before_deadline` functions with a slow real HTTP server and `curl`.
Only the outer `sudo` boundary is replaced to deny access or delay its response.
The check requires the startup deadline to hold in both cases. It does not run
package installation, a Maven build, or systemd appliance installation/startup.

The Tomcat unit check runs the shipped choice and backup functions, the real
monitor-stop Make target, and real temporary directory moves. Only the outer
`sudo` and `systemctl` boundaries are replaced. It checks cancellation and
explicit choices, preserves the original files in a unique backup, rejects
symlink replacement, and requires an inactive appliance before any backup.
It also rejects an executable but unreadable launcher and marks replacement
unavailable before selection for a custom Tomcat path.
The path checks reject checkout containment and source, appliance, archive-root,
archive-tier, or SQLite-file overlap, including symlink aliases, before any
download, service command, or backup. Separate sibling paths remain eligible.
It does not verify a host Tomcat reinstall or service-account permissions.

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
Account creation output must contain neither a `Password` column nor a MariaDB
password hash over either connection.
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
