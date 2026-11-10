# VM verification operations

The virtual machine (VM) test runs the shipped installer and verifies the installed appliance on a fresh guest. `tests/vm/install.pl` follows one changing process variable (PV) through acquisition, storage, retrieval, service restart, and unchanged installer re-application.

The shipped verifier starts a soft input/output controller (IOC) and compares stored samples with independent Channel Access (CA) observations. Installer success and responding management endpoints alone do not establish successful data storage.

## Guest prerequisites and ownership

cloud-provision supplies the guest and owns its lifecycle. The runner executes inside the guest as the ordinary checkout owner with non-interactive sudo. It does not create VMs, invoke Ansible, or reproduce the installer's Make sequence.

Each case requires a prepared checkout, the Perl prerequisites, and real Experimental Physics and Industrial Control System (EPICS) Base executables, including `softIoc` and `caget`. The guest must have neither an appliance installation nor a source `target/` directory. The installer prepares its packages and selected database; supplied web application archive (WAR) files do not replace its source build.

The [guest-test instructions](https://github.com/jeonghanlee/epicsarchiverap-env/blob/maven/tests/README.md#execution-inputs) define package prerequisites, private site settings, and the complete execution command. Each guest and its execution need separate authorization.

## Case inputs and entry points

The input shape is `tests/vm/install.example.json`. Replace its example paths and revisions with actual guest values. The configuration uses JavaScript Object Notation (JSON); it contains expected values, not commands or provisioning instructions.

| Input | Required value |
| :--- | :--- |
| `--config` | A private JSON file naming the repository, full environment and appliance revisions, source directory, operating system, backend, EPICS binaries, installation paths, service identities, database, endpoints, storage paths, and expected configuration |
| `--work` | A new absolute evidence directory; an existing directory is refused |
| `environment_patch` | Optional absolute file containing the exact tracked candidate diff; staged changes are refused, and additional candidate files require separate retention |
| MariaDB settings | A database name and application account, with the selected socket or TCP endpoint; credentials belong in private installer site settings |

`tests/run-all-tests.bash` selects the guest runner through `--case`. The compatibility entry points `tests/phase3-docker.bash` and `tests/phase4-vm.bash` forward the same configuration and work options to the complete Perl sequence. Each invocation covers one case.

From the repository root, inspect the runner's options without contacting a guest:

```bash
bash tests/run-all-tests.bash --case --help
```

The selected matrix has six cases:

| Operating system input | Backend input | Shipped installer |
| :--- | :--- | :--- |
| `debian13` or `rocky8` | `sqlite` | `scripts/install-local-sqlite.bash` |
| `debian13` or `rocky8` | `mariadb-uds` | `scripts/install-local-mariadb-uds.bash` |
| `debian13` or `rocky8` | `mariadb-tcp` | `scripts/install-local-mariadb-tcp.bash` |

`debian13` requires Debian 13; `rocky8` requires Rocky Linux 8.10. The socket and Transmission Control Protocol (TCP) inputs select different MariaDB connection paths. The selected guests have two virtual processors, 4 GiB of memory, and a 30 GiB disk.

## Installation and data observations

| Stage | Required observation |
| :--- | :--- |
| T1 | The selected installer completes with package/database preparation and source build enabled |
| T2 | Installed versions, settings, units, database, storage, four Java virtual machines (JVMs), startup responses, and service-account health match the inputs |
| T3 | Changing CA values match persisted samples; the same PV has a database registration and a fixed historical query containing its initial samples |
| T4 | A service restart replaces the four JVM lifetimes; the same registration and historical rows remain, and new samples match observations from the same IOC/PV |
| T5 | Identical installer re-application performs no build or JVM replacement; configuration, registration, history, and continuing acquisition remain valid |

The independent verifier supplies the initial CA-to-CSV comparison, where CSV means comma-separated values. Later comparisons retain timestamps, values, status, severity, and row occurrence counts. A fresh PV cannot substitute for the same-PV continuation checks.

## Evidence, cleanup, and verdicts

The work directory retains inputs, command arguments and outputs, native statuses, durations, installed-state snapshots, CA observations, retrieval responses, CSV files, IOC identity, and `result.json`. Keep exact guest identifiers and private configuration out of public summaries.

Normal completion pauses the test PV and stops its identified IOC. Failure and interruption attempt the same cleanup and retain available evidence. Registrations and stored samples remain; cleanup errors remain visible and prevent a successful verdict.

| Native status | Meaning |
| :--- | :--- |
| `0` | All required outcomes of this case and final cleanup passed |
| `1` | An installation, runtime, data, or comparison assertion failed |
| `2` | Inputs, prerequisites, evidence, interruption, or cleanup left the execution incomplete |
| `77` | A no-input system mode or compatibility entry point reports Incomplete without running an installation |

`result.json` retains `Passed`, `Failed`, or `Incomplete` and the last stage when its path remains writable. A confirmed assertion failure remains Failed when cleanup also fails. Help and input-refusal checks establish command behavior, not installation acceptance.

After copying and verifying the evidence, the operator checks final PV/IOC state and asks cloud-provision to retain and shut down the guest. The runner does not shut down the guest or erase its evidence.

Separate procedures cover controlled database/storage faults and interruption boundaries. A normal case does not establish host reboot recovery, source/schema upgrade, sustained load, or transfer through all storage tiers. The [recorded installation results](https://github.com/jeonghanlee/epicsarchiverap-env/blob/8d0494e3c47d553f29aa7b6bb62bb86533252677/docs/milestone-9576820.md#m16---build-the-vm-installation-test-on-the-local-installer-scripts) state the executed versions and limits.
