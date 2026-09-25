# EPICS Archiver Appliance Environment — Automated Tests

Phased install test suite that validates the Makefile system and build-wrapper
command generation, with container deployment and VM integration planned.

## Phased SOP

Tests execute in strict order, from least to most privilege:

| Phase | Validates | Setup cost |
| :--- | :--- | :--- |
| 1. Logic | configure/ structure, Makefile parsing, doc integrity, real health negatives and unit file installation | Python 3; installed Java for PID cases; JDK compiler for unrelated-JVM negative |
| 2. Build wrapper | Real `make -n build`: configuration, site-overlay copy, Maven package command and ordering | none; no source checkout, JDK or network required |
| 3. Infrastructure | `make install` end-to-end inside a Debian 13 container | Docker daemon |
| 4. System | full systemd stack inside a libvirt VM; HTTP probes | KVM, libvirt, cloud-init |

Phase 3 and Phase 4 are stubs until their entrypoints are committed
under `tests/docker/` and `tests/vm/`.

## Test Execution

```bash
# Run all phases that are implemented.
tests/run-all-tests.bash

# Local command-generation checks (no build, network or privilege required).
tests/run-all-tests.bash --local

# Targeted phase (cumulative: --phase=N runs phases 1..N).
tests/run-all-tests.bash --phase=2
```

## Workspace and Logs

Each shell phase creates an `archappl-test.*` workspace under
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
- The five OS preset fragments (`debian12`, `rocky8`, `macos`, `macbrew`, `githubmac`) are present under `configure/os/`.
- `make -n build` parses without error.
- The five `XXX.conf` Tomcat targets each generate a `CONFIG_SITE.local` line that includes the matching preset.
- `SRC_PATH` derives to `epicsarchiverap-maven-src` and downstream `ARCHAPPL_SITEID_TARGET_PATH` resolves under that subtree (regression guard for the CONFIG include reorder).
- The four removed obsolete documents (`README.ant.md`, `README.centos7.md`, `README.centos8.md`, `README.javapkgs.md`) are not referenced from any surviving Markdown file.
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
  be rejected. It never constructs a healthy Tomcat substitute.
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
- Tomcat's own logging goes through log4j2: `setenv.sh.in` sets the
  `$CATALINA_BASE/log4j` class path and the `log4j-jul` LogManager;
  `log4j2-tomcat.xml` carries the priority prefix, the root level from
  `ARCHAPPL_ROOT_LOGGER_LEVEL` and `monitorInterval`; the instance install,
  expanded with `make -n` from the isolated copy, renders `bin/setenv.sh`,
  removes a `conf/logging.properties` left by an earlier install, stops
  when `target/tomcat-log4j` is absent, and copies its jars into `log4j/`.

### Phase 2 — Build wrapper
- The real `make -n build` target parses and generates commands successfully.
- The package command runs from the configured source directory and invokes its Maven Wrapper with `clean package -DskipTests`.
- Only simple unquoted environment assignments may precede the wrapper; another command such as `echo` does not pass the invocation check.
- The six configuration-generation commands precede the site-overlay copy, which precedes the Maven package command.
- `MAVEN_FLAGS` is empty for this check; Phase 1 separately verifies nonempty flags across all six Maven targets.
- The check does not clone sources, execute Java or Maven, generate configuration, provision storage, or inspect WARs and release artifacts. Compilation and artifact verification belong to [aa-maven CI](https://github.com/jeonghanlee/epicsarchiverap-maven/actions).
- The script remains `tests/phase2-compile.bash` for direct callers. Both `--local` and `--phase=2` still run Phase 1 followed by Phase 2.

### Phase 3 — Infrastructure (planned)
- `make install` populates `${AA_INSTALL_LOCATION}/{mgmt,engine,etl,retrieval}/webapps` with the four exploded WAR trees.
- `make tomcat.exist` reports the install location populated.

### Phase 4 — System Integration (planned)
- `systemctl is-active archappl.service` returns active.
- `curl http://localhost:17665/mgmt/bpl/getApplianceInfo` returns 200.
- The `archappl` MariaDB database contains `ArchivePVRequests`, `ExternalDataServers`, `PVAliases`, and `PVTypeInfo`.

The source repository owns the documentation build. Planned changes to that
build are tracked in its own work register rather than as aa-env test work.

## Process-monitoring VM verification

This procedure is for a selected disposable systemd VM with four real Tomcat
instances. It is separate from the unimplemented general Phase 4 entry point;
running that stub does not verify monitoring. Obtain the VM owner and an
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
