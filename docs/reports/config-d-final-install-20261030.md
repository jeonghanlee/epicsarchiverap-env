# config.d final-snapshot installation verification

Status: **Passed**, completed 2026-10-30 UTC. All six fresh-VM cases passed
V01-V16, including shutdown and retention.

## Scope

This report verifies the final config.d implementation through the real local
installers on Debian 13 and Rocky Linux 8.10, with SQLite, MariaDB UDS, and
MariaDB TCP. Each case used a separate fresh guest with 2 vCPUs, 4 GiB RAM,
and a 20 GiB disk. The acceptance procedure is
[the full installation scenario](../PLAN.config-d-vm-tests.md).

**Out of scope:** Java live reload or API changes, Ansible's separate eight-case
acceptance matrix, PVAccess, production deployment, performance/soak testing,
and guest deletion.

## Frozen inputs

| Input | Identity |
| --- | --- |
| Environment candidate | Uncommitted working-tree snapshot, 289 members |
| Candidate SHA-256 | `ee77fa77750da154666d37f0b4f2524ea365638541f31b06f09e95774a20bf97` |
| Base environment commit | `45d207633ca0fe81c9563f67734efe18af2eef24` |
| aa-maven commit | `e0a8e66ed09e840ab8ed67dae81b25474605db08` |
| EPICS Base R7.0.10 commit | `bf11a0c31c919ba85ba2e23b72bcf0b5f9f62e77` |
| Provisioner revision | `aee7360d9f8c3658a361db240ba09511d0f859fd`, clean |
| Debian image SHA-256 | `383dbfed19d9c20618beb0068cebeebc36c253a48908265387a2a5c2c619e1d7` |
| Rocky image SHA-256 | `e56066c58606191e96184de9a9183a3af33c59bcbd8740d8b10ca054a7a89c14` |

The same candidate archive was verified in every guest. Complete Git source
membership, bytes, and modes matched the snapshot after all six runs and before
this report and the scenario status update. No product code changed during the
matrix. Symlink target bytes were included in the source verification.

The complete local suite, `bash tests/run-all-tests.bash --local`, exited 0 in
88.0 seconds from a Git checkout containing the candidate. Its real Base binary
resolution check was explicitly skipped because `AA_TEST_EPICS_BIN` was unset;
the VM cases separately built real EPICS Base and ran `softIoc` and `caget`.

## Installation and data results

All first installations ran the matching `install-local-*.bash -y`, including
OS package installation. Reinstallation used the same source and site inputs
with `-y --tomcat existing`. All first-install and reinstall commands exited 0.
Times are observed command durations in seconds, not a performance comparison.

| Case | First install (s) | Reinstall (s) | Matched PV samples, before / after | Preserved history samples | V01-V16 |
| --- | ---: | ---: | ---: | ---: | --- |
| Debian 13 / SQLite | 335.5 | 80.5 | 4 / 3 | 8 | Passed |
| Rocky 8.10 / SQLite | 284.6 | 83.1 | 4 / 4 | 7 | Passed |
| Debian 13 / MariaDB UDS | 331.3 | 82.8 | 4 / 4 | 8 | Passed |
| Rocky 8.10 / MariaDB UDS | 496.6 | 82.6 | 4 / 4 | 8 | Passed |
| Debian 13 / MariaDB TCP | 265.7 | 81.6 | 4 / 4 | 7 | Passed |
| Rocky 8.10 / MariaDB TCP | 341.0 | 80.2 | 4 / 4 | 8 | Passed |

Each PV verifier used the shipped `scripts/verify-local-pv.bash`, actual
Channel Access traffic, application APIs, and stored samples. The original PV's
fixed historical interval returned identical decoded JSON before reinstall,
after reinstall, and after reboot. New-PV checks after reinstall were separate
from preservation of that original registration and history.

For each MariaDB case, all four JVM PIDs had observed connections through the
requested transport at four checkpoints: initial installation, first PV,
reinstall, and reboot. Each checkpoint contained eight matching connection
rows and a successful query as `tomcat`. Original-PV registration was queried
after acquisition, reinstall, and reboot. SQLite cases had no MariaDB service
dependency.

## Configuration and regression results

All cases verified empty and absent config.d compatibility, ordered overrides,
quoted and empty values, common/component JVM options, excluded files,
caller-directory independence, and service-account access. Syntax and
unreadability faults blocked startup, named the affected file, and produced
health status 2; restoring the file recovered normal operation.

| Final implementation requirement | Observed result in every case |
| --- | --- |
| Apply sourced settings once per JVM startup | PATH probe appeared exactly once in 36 component observations across nine runtime checkpoints, including systemd, manual launcher, direct wrappers, reinstall, and reboot |
| Validate configuration before loglevel requests | Two calls with an inherited management port exited 1 with a configuration preflight diagnostic under syntax and unreadability faults |
| Select drop-ins when the caller uses `bash -f` | Manual launcher and direct-wrapper startup/shutdown retained the expected environment; nine health calls exercised the same shell option, including the two expected status-2 fault results |

The 36 PATH observations per case are checkpoint/component observations, not
36 distinct JVM lifetimes. Across six cases, the recorded totals are 216 PATH
observations, 12 blocked loglevel calls, and 54 health calls under `bash -f`.

Editing a drop-in left running JVM identities and environments unchanged.
Immediate health and the next scheduled health invocation read the edited
threshold. Restart created new JVMs with the new values. Each case observed
at least three completed scheduled health invocations during initial checks.
Reinstall preserved config.d membership, bytes, and modes. Reboot changed the
boot ID and restored the enabled appliance and health timer with local values.

## Evidence and retention

Private evidence is retained under
`work/config-d-final-vm-20261029T234500Z/<case>/`. Each case contains native
command receipts, `guest-evidence.tar.gz`, the original evaluator result,
`result-final.json`, and provider shutdown/retention records. The matrix-wide
verification is `matrix-final-verification.json` in the run root.

Every transferred archive's complete membership, sizes, and SHA-256 values were
verified. Member counts below exclude `evidence-manifest.json` itself.

| Case | Evidence members | Archive SHA-256 |
| --- | ---: | --- |
| Debian 13 / SQLite | 227 | `cbfb057ea1fbd05db136a93816916e1edcaf294f437de06c0c79c843fbb561e6` |
| Rocky 8.10 / SQLite | 227 | `8a58b1da619e19d8e92e0b84bfa9c382bb804ce77363e5ad33d72504b02a869a` |
| Debian 13 / MariaDB UDS | 233 | `d52d314df60d051c23c418d61d6a02bfa04ed648dfe9e4abad5afc193ce1cc15` |
| Rocky 8.10 / MariaDB UDS | 233 | `b6a3f4a16c90d60329023e18289db7355a97572b48b470c6d285024ea4174cac` |
| Debian 13 / MariaDB TCP | 233 | `70d6e98358192f97a25fd8ec5eea0487b66eb9307e04b48fa6149c5114db6b94` |
| Rocky 8.10 / MariaDB TCP | 233 | `faae8a2f2d78501adc95e63931e420ff6de97b34af62421bd0987e52c0a81ae2` |

The Debian MariaDB UDS post-reboot original-PV query also has a separately
retained `V15-database-pv.json` addendum, SHA-256
`7abf1d7849ab4b27ee0d440b8e438df61df3870141246320edd7b13e35bc6e2c`,
with native query and transfer receipts. The original archive is unchanged;
`result-final.json` references both the archive evidence and this addendum.

All test IOCs were stopped and both test PVs in each case were confirmed Paused
before release. The provider confirmed all six guests shut off with definitions,
disks, seeds, reservations, creation records, and evidence retained. No guest
was deleted. Debian NVRAM references were unchanged in the definitions; protected
NVRAM files were not directly inspected. Rocky definitions had no NVRAM entry.

Private raw records contain site inputs and runtime identities and are not
public report attachments. Earlier incomplete preparation records and the
[earlier snapshot report](config-d-install-20261029.md) remain separate; their
results are not reused as evidence for this candidate.
