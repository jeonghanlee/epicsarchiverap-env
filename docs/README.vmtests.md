# VM installation and runtime tests

The VM test runs the shipped local installer on a fresh guest, verifies the
installed configuration and runtime, and follows one changing PV through
acquisition, storage, retrieval, service restart and unchanged re-application.
Installer exit status and HTTP readiness do not establish successful storage.

## Responsibilities

| Component | Responsibility |
| --- | --- |
| cloud-provision | Supplies each guest and owns creation, access and retained shutdown. |
| `tests/vm/install.pl` | Runs one guest-side installation case and records the required observations. |
| `scripts/install-local-*.bash` | Prepares packages and the selected database, builds and installs the appliance, and starts its services. |
| `scripts/verify-local-pv.bash` | Starts the real soft IOC, observes CA and compares initial stored samples with CA values and timestamps. |
| Pinned source CSV client and `scripts/verify-local-pv-curl.bash` | Retrieve persisted samples through the installed retrieval API. |
| `tests/vm/compare.pl` | Compares actual process state, registration, historical rows and new CA-to-CSV samples. |
| `tests/vm/database.pl` | Reads installed MariaDB resources and queries the selected database with the installed application credentials as the service account. |

The test does not create or delete VMs, inspect hypervisor ownership, run
Ansible or reproduce the installer's Make sequence. EPICS Base is a separate
test prerequisite. The guest image's existing packages are recorded; their
installation is not claimed as installer coverage.

## Selected cases

Each case requires a fresh guest with no appliance installation or source
`target/` directory, a checkout owned by an ordinary user with non-interactive
sudo, and real EPICS Base executables. The selected environments have 2 vCPU,
4 GiB RAM and a 30 GiB disk.

| OS input | Backend input | Shipped installer |
| --- | --- | --- |
| `debian13` or `rocky8` | `sqlite` | `scripts/install-local-sqlite.bash` |
| `debian13` or `rocky8` | `mariadb-uds` | `scripts/install-local-mariadb-uds.bash` |
| `debian13` or `rocky8` | `mariadb-tcp` | `scripts/install-local-mariadb-tcp.bash` |

`rocky8` requires Rocky Linux 8.10; `debian13` requires Debian 13. These six
cases are the selected coverage, not a claim about every supported platform.
Observed results and their exact source versions are in
[M16](milestone-9576820.md#m16---build-the-vm-installation-test-on-the-local-installer-scripts).

## Inputs and sequence

Run `install.pl --config FILE --work NEW_DIRECTORY` inside the guest as the
checkout owner. `tests/vm/install.example.json` defines the input shape;
[the test instructions](../tests/README.md) describe preparation and commands.
The JSON names absolute repository, installation, EPICS and evidence paths,
full environment/appliance revisions, expected service accounts, units,
storage paths and local API endpoints. SQLite names its database file.
MariaDB names its database and application user, plus an absolute socket path
or `127.0.0.1` and a TCP port. Passwords belong in the installer's private site
configuration, never the case JSON.

The checkout must match the supplied environment revision. An optional
`environment_patch` names the exact expected tracked diff. Candidate runs
must also retain separately any new files used by the test and their hashes.
The source revision selected by the installer's configuration must match
`appliance_revision`; the runner verifies the result rather than silently
overriding the operator's site configuration.

| Step | Required result |
| --- | --- |
| T1 | The selected installer runs with `--yes`, packages/database preparation enabled and no prebuilt WARs; native exit is 0 within `install_timeout`. |
| T2 | Pinned versions, identity, endpoints, installed configuration, units, four JVM lifetimes and owners, storage access, actual database/schema, all four startup APIs and service-account health match the inputs. |
| T3 | The standalone shipped verifier matches at least two distinct changing CA values to persisted samples. The configured database contains that PV, and a fixed closed historical query contains the initial rows. |
| T4 | A shipped service restart changes all four JVM lifetimes. The same registration and fixed historical rows remain, and new data from the same IOC/PV match new CA observations. |
| T5 | The identical installer request exits 0 without a build or service/JVM replacement. Configuration, registration and history remain, and continuing acquisition still matches CA. |

Startup and data checks have 180-second limits. The initial verifier uses
`--cleanup keep` so T4 and T5 retain the same IOC and PV. Each new-data check
records twelve actual CA observations before pausing to query persisted data.
Historical comparison preserves timestamps, values, status, severity and row
occurrence counts; it does not compare only a sample count.

## Evidence and cleanup

`--work` must be a new absolute directory. The runner records `inputs.json`,
per-command arguments, cwd, timeout, stdout, stderr, native status and timing,
installed-state snapshots, verifier evidence, `ioc.json`,
`history-window.json`, comparisons and `result.json`. Database resources are
read through the real installed path; MariaDB credentials use a private
temporary client file and are excluded from output. Database registration
metadata and archive sample files are checked separately.

Normal completion pauses the test PV and stops the identified IOC. Failure
or interruption attempts the same cleanup and retains available evidence.
When the verifier has released its IOC but the runner has not recorded it,
cleanup recovers ownership from the unique private verifier record and
checks the live command before signalling. A cleanup error remains visible
in `result.json`; it never turns an unsuccessful case into Passed.

The operator independently checks final PV/IOC state, copies and verifies
evidence, then sends a finished notice to cloud-provision. Definitions,
disks, registrations and stored samples remain retained. The runner does not
issue a shutdown or erase the evidence directory.

## Fault and interruption checks

T6 is a separate controlled check on passing disposable baselines. The
database control closes existing application connections, changes the
installed MariaDB socket and requires a new actual connection to fail at the
database assertion. The storage control requires no pre-existing writable STS
handles, denies the service account write access to the actual STS and runs
the shipped verifier. With changing real CA input and a same-PV storage error,
rejection during actual append/flush or stored-sample verification establishes
detection. An unrelated startup or input failure is Incomplete. A flush failure
does not establish execution of the later stored-sample comparison. Record any
manual PV recovery separately; the control does not certify automatic recovery. Original configuration or permissions are
restored, and the affected normal checks must pass again.

T7 separately exercises the seven interruption and evidence-write boundaries
defined in the M16 procedure. These controls use the shipped entry points;
they are not automatic branches of a normal `install.pl` run. Their results
apply only to the recorded versions and boundaries.

## Verdict and limits

| Native status | Meaning |
| --- | --- |
| 0 | All required outcomes of this case passed and cleanup succeeded. |
| 1 | An observed installation, runtime, data or comparison assertion failed. |
| 2 | Missing or invalid inputs, unavailable evidence, interruption or another incomplete execution. |

`result.json` records `Passed`, `Failed` or `Incomplete`, the last stage,
primary error and cleanup error when its path remains writable. A confirmed
assertion failure is retained even when cleanup also fails. Missing command
evidence cannot be inferred from another PASS message.

The Bash compatibility entry points keep their no-input status 77; a real
case forwards the Perl runner's native status. Each invocation covers one
case, not the whole six-case matrix. A complete M16 result also needs its
separate T6 and T7 evidence. Service restart does not establish host reboot
recovery. Short-term stored samples do not establish STS-to-MTS-to-LTS
transfer, sustained load or long-duration reliability. Source/schema upgrade
coverage belongs to M17.
