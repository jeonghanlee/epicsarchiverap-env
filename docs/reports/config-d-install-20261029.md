# config.d installation verification

Report date: 2026-10-29

Status: Passed. All six OS/backend combinations completed V01-V16, including
provider-confirmed shutdown and retention. No test guest remains running.

## Scope

This report records execution of the [six-case installation scenario](../PLAN.config-d-vm-tests.md)
for local runtime environment additions and overrides. Each combination starts
with a fresh cloud guest and runs its real local installer, package manager,
Maven build, database setup, systemd services, Tomcat applications, and EPICS
Channel Access acquisition and retrieval. Reinstall and normal reboot are
included on every tested combination.

**Out of scope:** Java live reload or configuration APIs, production deployment,
performance or soak claims, optional PVA modules, guest deletion, and the
separate Ansible VM driver's acceptance matrix.

## Candidate and environment

| Input | Identity |
| :--- | :--- |
| Environment candidate | Owner-selected working-tree snapshot, 288 members |
| Base commit | `45d207633ca0fe81c9563f67734efe18af2eef24` |
| Snapshot archive SHA-256 | `95cc7968688536f9b6022337a35ac5b1aed5f9361915b616fd8e349f74a1d178` |
| aa-maven commit | `e0a8e66ed09e840ab8ed67dae81b25474605db08` |
| EPICS Base commit | `bf11a0c31c919ba85ba2e23b72bcf0b5f9f62e77` (`R7.0.10`) |
| Guest resources | 2 vCPU, 4 GiB configured RAM, 20 GiB root disk |
| Debian image SHA-256 | `383dbfed19d9c20618beb0068cebeebc36c253a48908265387a2a5c2c619e1d7` |
| Rocky image SHA-256 | `e56066c58606191e96184de9a9183a3af33c59bcbd8740d8b10ca054a7a89c14` |
| Provisioner commit | `aee7360d9f8c3658a361db240ba09511d0f859fd`, clean tracked tree |

The snapshot includes the uncommitted config.d implementation. Its complete
member list, bytes, types, modes, and archive hash are checked in each guest.
Private site inputs and test credentials are supplied separately. Subsequent
changes to this report and the scenario's execution status do not change the
frozen snapshot.

The candidate's complete local suite (`tests/run-all-tests.bash --local`)
completed with native exit status 0 in 84.670 seconds. This supports the
candidate but does not replace the VM observations below. The updated operator
book also completed an mdBook HTML build with native exit status 0.

## Method and results

The first installation runs as the ordinary checkout owner with sudo and
without `--skip-packages`. Reinstall uses the same source pin, backend,
credentials, storage paths, and installer with `-y --tomcat existing`.
Actual native exit status, full output, UTC boundaries, and monotonic elapsed
time are retained independently of the SSH observer. Times below are rounded
to the nearest second and are observations, not performance comparisons.

| Configuration | V01-V16 | First install | Reinstall | PV matches before / after | Preserved history |
| :--- | :--- | ---: | ---: | ---: | ---: |
| Debian 13 / SQLite | Passed, fresh repeat | 292 s | 80 s | 3 / 2 | 5 |
| Rocky 8.10 / SQLite | Passed | 493 s | 85 s | 3 / 4 | 7 |
| Debian 13 / MariaDB socket | Passed | 248 s | 82 s | 4 / 4 | 8 |
| Rocky 8.10 / MariaDB socket | Passed | 319 s | 82 s | 3 / 3 | 8 |
| Debian 13 / MariaDB TCP | Passed | 287 s | 83 s | 3 / 4 | 6 |
| Rocky 8.10 / MariaDB TCP | Passed | 310 s | 85 s | 4 / 4 | 8 |

Every listed completed first installation and reinstall has native exit status
0. PV matches count the shipped verifier's stored samples matching changing
CA values. Preserved history is a separate count: the original PV's complete
JSON response for the same fixed interval is equal before reinstall, after
reinstall, and after reboot. A second PV exercises acquisition after reinstall.

The original Debian SQLite attempt remains Incomplete because its first
installer's native exit receipt was unavailable. The table uses a separate
fresh guest that completed every required check with retained receipts. The
original observation is preserved and is not counted as a pass.

For all six combinations:

- Installed WARs match the built files; all four applications reach
  `STARTUP_COMPLETE`, and the appliance and health timer recover after reboot.
  At least three scheduled health executions are observed initially.
- Empty or absent config.d works. Filename order, quoted and empty values,
  common and component JVM options, ignored files, and caller-directory
  independence are checked against the actual JVMs and installed wrappers.
- Editing a file leaves existing JVM identities and environments unchanged.
  Immediate and scheduled health calls read the new health threshold. Restart
  creates new JVM identities that receive the changed environment.
- Actual syntax faults and service-account read denial block startup before
  component JVMs appear. Health exits 2 and names the file. Restoring the file
  and its mode permits recovery.
- Installed manual startup and shutdown wrappers control the four actual
  JVMs with systemd stopped, then return control to systemd without duplicates.
- Reinstall preserves config.d membership, bytes, and modes. Recorded PV
  registration and history remain available after reinstall and reboot.
- SQLite introduces no MariaDB unit or dependency. MariaDB observations use
  the real service account and installed JDBC configuration; process socket
  observations establish the selected transport. Each completed MariaDB case
  records eight JDBC connections at its four database checkpoints.

## Evidence and limits

Each private case directory retains the source manifest, provider records,
native command receipts, unit and journal observations, selected JVM environment
and process identities, API responses, actual PV fixtures, and database checks.
Full environments and credentials are not included in this public report.

Final guest evidence is copied before shutdown. The copied archive hash,
complete unique member set, individual byte counts, and member hashes are
verified. V16 additionally requires paused PVs, no remaining test IOC, and
provider-confirmed shutdown with the VM definition, disk, seed, reservation,
creation record, and evidence retained. No guest deletion is requested.
Debian NVRAM retention is established only for its unchanged definition path;
file-level existence was not verified. Rocky definitions contain no NVRAM.

| Configuration | Verified evidence members | Archive SHA-256 |
| :--- | ---: | :--- |
| Debian 13 / SQLite, fresh repeat | 214 | `e30479d521dca07ad917ef162b60a2e02106597f039146ad4163561b820d3ec5` |
| Rocky 8.10 / SQLite | 257 | `b552337c8735fb65ee41325ac84a998265eafbc13162ffa5252f4ea4c6844713` |
| Debian 13 / MariaDB socket | 274 | `24d9981e323c375e3f4c4f11b3afe724ae0c25462e8623d131866990a136f571` |
| Rocky 8.10 / MariaDB socket | 227 | `d046127297d00969c369a8cd11c626ceb133cfd908c0cd5e67f8738742d77653` |
| Debian 13 / MariaDB TCP | 227 | `4d1932a43254eee9190dd2d3adfdc13274bd9f4e53532a6c2e461cd6ba168778` |
| Rocky 8.10 / MariaDB TCP | 227 | `cdd9254394b5ec204dc87aab1c3d0134720edfb0cab0a2cc8ac12127d3082621` |

Checker execution errors and their original records remain in the private
evidence. Corrected observations run against the real installed product;
they do not replace installation, database, systemd, JVM, or PV behavior with
substitutes. No product-source change was needed during these VM tests.

The [runtime environment guide](../../book/src/configure/runtime-environment.md)
describes manual configuration and when changes take effect. These results
establish startup-time JVM configuration and per-invocation health configuration;
they do not establish live Java configuration reload.
