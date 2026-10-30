# Debian and Rocky full installation scenario for config.d

Status: Passed on 2026-10-30 UTC. The final snapshot passed V01-V16 in all six
fresh-VM cases, including shutdown and retention. See the
[final-snapshot report](reports/config-d-final-install-20261030.md).
The [earlier snapshot report](reports/config-d-install-20261029.md) is retained
separately.

## Scope and execution path

Validate the local installers from a fresh VM through package installation,
source build, database preparation, installed payloads, actual systemd startup,
and Channel Access acquisition/retrieval. Verify issue #63's local environment
contract on that installation, including restart and reinstall behavior.

The path under test is:

```text
Fresh cloud-provision guest
  -> ordinary checkout owner + sudo
  -> install-local-*.bash
  -> OS packages + JDK + Tomcat + Maven build
  -> database + Make installation + systemd units
  -> installed launcher + wrappers + four appliance JVMs
  -> real soft IOC + archived data retrieval
```

Do not replace the installer, package manager, Make, database, systemd, Tomcat,
JVMs, or application APIs with substitutes. Run commands from a session that
survives the installation; capture the command, full output, exit status, and
start/end times independently of the connection used to observe progress.

This is an operator-executed scenario, not an implemented `tests/vm/driver.py`
case. The existing [VM driver](README.vmtests.md) invokes Ansible species and
has its own eight-case acceptance matrix. It does not invoke the local
installers or perform the config.d checks below. Its `--verdict` cannot certify
this scenario, and two successful OS cases cannot certify its eight-case matrix.

The existing `tests/config-d-runtime.py` validates a temporary installation's
launcher paths without installing units. It is supporting evidence, not a
replacement for this systemd installation test.

**Out of scope:** Java live reload/API implementation, production deployment,
performance/soak testing, and guest deletion. Existing Ansible acceptance remains
a separate procedure; this document does not change its criteria.

## Case matrix and ordering

Use Debian 13 and Rocky Linux 8.10, matching the existing VM profiles. Use one
fresh guest per OS/backend combination; do not convert one installed database
backend into another and call that a fresh installation.

| Order | Case | Installer | Status |
| --- | --- | --- | --- |
| 1 | Debian 13 / SQLite | `scripts/install-local-sqlite.bash` | Passed V01-V16 |
| 2 | Rocky 8.10 / SQLite | `scripts/install-local-sqlite.bash` | Passed V01-V16 |
| 3 | Debian 13 / MariaDB socket | `scripts/install-local-mariadb-uds.bash` | Passed V01-V16 |
| 4 | Rocky 8.10 / MariaDB socket | `scripts/install-local-mariadb-uds.bash` | Passed V01-V16 |
| 5 | Debian 13 / MariaDB TCP | `scripts/install-local-mariadb-tcp.bash` | Passed V01-V16 |
| 6 | Rocky 8.10 / MariaDB TCP | `scripts/install-local-mariadb-tcp.bash` | Passed V01-V16 |

Complete the SQLite pair first to expose installation or OS compatibility
problems before the four MariaDB cases. All six cases are required for the
full matrix in this document. Start with one running guest at a time; retained
shut-off guests continue to consume disk space.

## Candidate and VM preparation

1. Select an immutable environment candidate and aa-maven commit for all cases.
   The environment candidate must include the config.d implementation,
   templates, installation rules, and tests. Use either an exact published
   commit or an owner-selected working-tree snapshot. For a snapshot, freeze
   the archive and a manifest of complete member paths, types, modes, and
   SHA-256 hashes; record the base commit and archive hash. Exclude private
   site inputs, credentials, generated files, and execution records. Verify
   complete membership, bytes, and modes inside every guest before installation.
   An older remote branch tip does not identify uncommitted changes. This run
   uses the selected working-tree snapshot; its archive remains unchanged
   across all six cases.
2. Run the candidate's complete local suite once and retain its actual result.
   Pin the cloud-provision tool revision and base image checksums. Record the
   versions of Bash, Java, Tomcat, Maven, systemd, and the database after setup.
3. Identify the owner of the VM provisioner and prepare a resource request for
   a fresh guest. Do not infer that an unrelated existing VM is available for
   this test. Creation/start requires a current capacity check on that host.
4. Request the following guest contract for each case. Keep actual addresses,
   UUIDs, keys, and resource names in private execution records.

   | Field | Requested value |
   | --- | --- |
   | Purpose | Fresh local-installer acceptance and config.d verification for issue #63 |
   | Platform | Debian 13 or Rocky Linux 8.10, exact base-image checksum recorded |
   | Resources | 2 vCPUs, 4 GiB RAM, 20 GiB disk as the initial profile |
   | Capacity | Confirm host headroom and a positive guest free-space threshold adequate for a cold build before creation/execution |
   | State | Cloud-init complete; no existing appliance, archive, database service, or application build |
   | Access | SSH key authentication; ordinary checkout owner with noninteractive sudo |
   | Network | Package, source, and Maven download access; application/IOC test traffic limited to the guest |
   | Window | Reserve up to 2 hours per case; exceeding it requires a status report and a revised bound |
   | Return information | Private handoff with identity, image/tool provenance, access route, and creation record |
   | Finish | Report completion to the provisioner; shut down and retain the VM and evidence |

5. Verify the returned identity against the live guest and creation record.
   Record OS release, CPU, RAM, disk/free space, cloud-init result, SSH host key,
   and initial unit inventory. Stop before installation on a mismatch or an
   existing appliance. Record the hypervisor baseline so unrelated resources
   remain identifiable throughout the run.
6. Bootstrap only what is required to invoke the installer: an ordinary owner,
   sudo, Git, Make, Bash, and the candidate checkout. Do not preinstall the
   appliance with an Ansible archiver species. The first installation must
   exercise the installer's package stage without `--skip-packages`.
7. Prepare `../CONFIG_SITE.local` and `../RELEASE.local` for the guest. Pin
   `SRC_TAG` to the selected aa-maven commit. Use guest-local storage and
   loopback CA discovery; use private test DB credentials for MariaDB.
   Keep those inputs identical across reinstall. Do not edit generated files
   to make the first installation pass.
8. For the manual shutdown check, set four distinct, available
   `ARCHAPPL_SHUTDOWN_<COMPONENT>_PORT` values in the site inputs before the
   first installation. Their default `-1` disables Tomcat's shutdown listener.
   Record the chosen values and verify the rendered `server.xml` files. Keep
   guest access restricted to the test network.
9. Before the PV checks, provide real EPICS Base `softIoc` and `caget` binaries
   for the selected OS through the site's EPICS preparation procedure. Record
   the source/version and binary paths. This preparation must not install or
   replace the appliance. Missing EPICS tools leave PV checks incomplete.

The VM provider supplies the guest; the requester runs this scenario and owns
its observations. The provider is not asked to execute test scripts. Confirm
the provider and reply route at execution time; this plan sends no VM request.

## Installer entry points

These are planned guest commands, not execution receipts. Run only the row
matching the guest's backend, from the candidate checkout as its ordinary owner.
Capture the plan first, then the actual installation. Do not use `sudo bash`.

| Backend | Plan command | First installation |
| --- | --- | --- |
| SQLite | `bash scripts/install-local-sqlite.bash --plan` | `bash scripts/install-local-sqlite.bash -y` |
| MariaDB socket | `bash scripts/install-local-mariadb-uds.bash --plan` | `bash scripts/install-local-mariadb-uds.bash -y` |
| MariaDB TCP | `bash scripts/install-local-mariadb-tcp.bash --plan` | `bash scripts/install-local-mariadb-tcp.bash -y` |

The first guest must have no Tomcat installation, so no reuse/replacement
decision is hidden in the first run. On reinstall, run the same installer with
`-y --tomcat existing`. Keep the same source pin, backend, credentials, and
storage paths. TCP requires `DB_HOST_NAME=127.0.0.1`; record the actual socket
path for the socket case. `-y` skips the optional PV prompt, so run the shipped
PV verifier explicitly in the steps below.

## Required checks on every guest

| ID | Action | Required observation |
| --- | --- | --- |
| V01 | Run the first installer through completion | Every stage executes; installer exits 0; candidate commit or complete snapshot and aa-maven commit match; installed payload matches the built WARs |
| V02 | Inspect the installed units and runtime | Appliance unit and health timer exist and are enabled/active; service account and database dependency match the backend; all four applications report `STARTUP_COMPLETE`; information API and launcher health succeed |
| V03 | Inspect the initial configuration | `archappl-config.bash` is installed; `config.d` exists and is empty; all generated wrappers use the shared loader; empty-directory startup succeeds |
| V04 | Test absent-directory compatibility | Stop the appliance and timer, temporarily rename the empty config.d directory, start the appliance, and verify health/readiness; stop it, restore the directory, and restart the appliance and timer |
| V05 | Add the local files below and a component JVM option, then restart through systemd | All four real JVMs receive the expected environment; quoted and empty values are preserved; engine receives both common and component JVM options |
| V06 | Edit settings while the service runs | JVM process identities and selected environments remain unchanged; immediate health and the next scheduled health run read the edited threshold |
| V07 | Restart through systemd | Old JVMs exit; new JVM identities appear; all four receive the edited values and recover application readiness |
| V08 | Add conflicting ignored files, restart through systemd, and vary the caller directory | All four new JVMs retain the expected values despite hidden files, backup suffixes, and nested files; health from `/` agrees with health from the installation directory |
| V09 | Introduce a syntax error in the final selected file, then attempt startup from a stopped state | No component JVM starts; service reaches a failed state; diagnostic names the file without its contents; health as the service account exits 2 |
| V10 | Restore syntax, then make one selected file unreadable to the service account | Startup is blocked with the file named; health as that account exits 2; restore the file mode and verify normal recovery |
| V11 | Run the installed manual startup/shutdown paths with systemd stopped | Generated wrappers start all four actual JVMs with the expected environment and stop them; no duplicate JVMs; return control to systemd afterwards |
| V12 | Archive a real test PV | Run `scripts/verify-local-pv.bash` with real EPICS Base `softIoc` and `caget`, actual API URLs, selected source checkout, and `--cleanup stop`; changing CA samples match archived CSV samples |
| V13 | Reinstall using the same installer and source pin | All config.d filenames and bytes are preserved; installed loader/wrappers match the candidate; service restarts with local overrides; DB records and the recorded PV history remain retrievable |
| V14 | Run the real PV verifier again after reinstall | New data is acquired and retrieved; distinguish this new-PV result from preservation of V12's existing registration/history |
| V15 | Reboot the guest normally | Boot ID changes; enabled appliance and timer recover; four JVMs receive local values; readiness, health, DB access, and recorded history recover |
| V16 | Finish and retain evidence | Owned IOC is stopped, PV pause is confirmed, all required evidence is copied off the guest, and the provider confirms guest shutdown with disk/identity retained |

For V02, observe at least three completed scheduled health invocations rather
than relying only on the timer's active state. SQLite must not introduce a
MariaDB/MySQL service or dependency; inspect the successful full unit inventory.
For MariaDB, prove the requested JDBC transport and schema using the real
service account's access. Match actual connections to all four JVM PIDs at
initial installation, after the first PV, after reinstall, and after reboot.
Query the original PV registration after acquisition, reinstall, and reboot;
schema access alone does not establish preservation of that registration.

For V09, systemd `Type=simple` can acknowledge a start before the launcher exits.
Do not require the initial `systemctl start` status alone to prove failure.
Observe `ActiveState`, `SubState`, `Result`, the journal, the unit cgroup, and
the absence of component JVMs. Stop the timer during intentional faults so its
separate attempts do not obscure the captured manual health result, then restore it.
Unreadability must be checked as the unit's service account; root's access is
not evidence that the service account can read the file.

### Startup and command regression checks

In V05, prepend `/opt/configd-path-probe` to PATH as shown below. Read the actual
JVM environment and require exactly one occurrence in every component at V05,
V06 after editing, V07, V08, each V11 startup path, V13, and V15. This checks
that launcher validation does not apply sourced settings before a wrapper
applies them again. Record observations by checkpoint and component rather
than counting them as distinct JVM lifetimes.

Run manual launcher startup/shutdown and direct component-wrapper
startup/shutdown with `bash -f` in V11. Both must select the same drop-ins and
preserve the expected environment without duplicate JVMs. Invoke health with
`bash -f` as well; require the edited threshold and the expected status 2 under
each configuration fault.

During V09 and V10, invoke `loglevel mgmt ROOT INFO` through the installed
launcher with `bash -f` and an inherited `ARCHAPPL_MGMT_PORT`. Require exit 1
and a configuration preflight diagnostic naming the affected file, before
the HTTP request path. Restore the configuration and service state afterwards.

## Configuration inputs and expected values

Keep `archappl.conf` generated. In V05, create `config.d/10-common.conf` with:

```bash
SITE_TEST_LABEL='first value'
SITE_TEST_EMPTY=before
SITE_TEST_REV=one
EPICS_CA_ADDR_LIST=127.0.0.1
EPICS_CA_AUTO_ADDR_LIST=NO
PATH="/opt/configd-path-probe:$PATH"
CATALINA_OPTS="$CATALINA_OPTS -Dconfigd.common=present"
```

Create `config.d/90-site.conf` with:

```bash
SITE_TEST_LABEL='last value * $literal'
SITE_TEST_EMPTY=''
ARCHAPPL_STORAGE_ALARM_PERCENT=100
```

Append `-Dconfigd.component=engine` to `CATALINA_OPTS` in the installed
`engine/conf/engine.conf` without replacing its other content. Expect both
`configd.common` and `configd.component` in the engine's real JVM arguments.
Expect the common option in the other three JVMs. Component files are generated
installation inputs, not preserved config.d files; V13 does not require this
temporary component edit to survive reinstall.

For V06, add `SITE_TEST_REV=two` and change the threshold to `99` in
`90-site.conf`. Before restart, all four JVM environments retain `one` and
`100`; health reports threshold `99`. After V07, all four environments contain
`two` and `99`. Choose a filesystem with measured usage below both thresholds
so this check measures configuration selection rather than a storage alarm.

For V08, use conflicting `SITE_TEST_LABEL` assignments in `.hidden.conf`,
`90-site.conf~`, `90-site.conf.bak`, and `nested/20-test.conf`. The effective
label must remain `last value * $literal`. Restore the normal file set before
the preservation snapshot. For V09, use an unmatched quote in a final
`99-invalid.conf`; record its hash and the named-path diagnostic, then remove
only that explicitly identified fault file during recovery. For V10, change
one selected file to mode `000`, verify the actual service-account read denial,
then restore its recorded mode.

Read `/proc/<pid>/environ` as NUL-separated entries. Save only the test variables
and selected EPICS variables; do not export complete environments or credentials.
Bind each observation to component, boot ID, PID, process start ticks, resolved
Java executable, `catalina.base`, and systemd invocation ID. A PID alone is not
a process-lifetime identity. A sourced shell's output is not JVM evidence.

## Evidence, bounds, and verdict

Use a private per-run directory with separate subdirectories for each case and
check. Retain the VM handoff, image and source identities, installer command
receipts, installed file hashes, unit definitions/state, relevant journal
intervals, selected JVM observations, HTTP responses, and PV/CSV artifacts.
Before V13, freeze the config.d member list, bytes, hashes, and modes; compare
membership and bytes afterwards. Retain the original DB/PV evidence and compare
the same historical time interval after reinstall and reboot.

Use the installer's startup deadline of 180 seconds. Allow up to 45 minutes
for a cold build/install, 300 seconds for service stop/restart, 180 seconds for
each PV verification, and 10 minutes for reboot/SSH/application recovery.
Record monotonic elapsed times and UTC timestamps. A connection timeout does
not prove that a remote build stopped: inspect its actual state before retrying.
Do not silently extend a timeout or overwrite the failed attempt.

Each check records expected result, observed result, native exit status,
evidence paths, and `Passed`, `Failed`, or `Incomplete`. Expected syntax and
permission failures pass only when the specified blocking behavior and recovery
are observed. Missing tools, missing observations, interrupted execution, and
unrun cases are not passes. Preserve confirmed failures even if later evidence
is incomplete. Save evidence before reporting success or releasing the guest.

The full scenario passes only after V01-V16 pass in all six cases. Shutdown
and retention satisfy V16; they do not establish the existing VM driver's
deletion/cleanup criteria. Guest deletion requires a separate explicit request.

| Execution safeguard | Required evidence or limit |
| --- | --- |
| Evidence size | One bounded installation and real PV checks per case; no sustained-volume claim; evidence copy failures leave the case incomplete |
| Expected values | Inputs and expected environment transitions above, established before reading runtime output |
| Time boundaries | UTC plus monotonic durations; preserve the original PV interval and actual restart/boot boundaries |
| Fault exposure | On-disk syntax fault and actual service-account read denial; named diagnostics, no JVM startup, and successful recovery |
| Measurement identity | Boot/process start identity, systemd invocation, selected environment, and exact config.d member hashes |
| Real installation | Installer receipts, package/build evidence, installed bytes, real systemd units/JVMs/APIs, and actual PV samples |
| Coverage | Six separate case records; every V01-V16 observation required; no inference across OS/backend combinations |

No replay/evidence-transfer tool or performance comparison is under test here.
No long observation is required. Diagnose a checker-only problem from preserved
evidence when possible; repeat live steps only where an observation is missing
or the candidate behavior changed. Final status remains Incomplete until
actual execution receipts establish V01-V16 for every required case.
