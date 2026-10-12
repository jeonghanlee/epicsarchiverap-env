# VM verification operations

The virtual machine (VM) operations prove the installation and the runtime behavior on fresh guests. The driver `tests/vm/driver.py` coordinates the provisioning tools that the configuration names and keeps independent evidence for each case. This page lists the inputs, the operations and the cases.

## Inputs of a run

| Input | Where it is set |
| :--- | :--- |
| The cloud provisioning tool and the Ansible provisioning tool, at the references that the configuration pins | `cloud` and `ansible` in the configuration file |
| The candidate references of this repository and of the source repository | `candidate.env_ref` and `candidate.source_ref` |
| Disk images for the operating systems, with their SHA-256 values | `images` |
| The test PV database file `src/resources/test/UnitTestPVs.db` of the source repository, with its repository, its reference and its SHA-256 value | `fixture` |
| The paths, the account and the EPICS binary directories of each operating system inside the guest | `guest` (`source_parent`, `install_parent`, `store_top`, `user`, `group`, `epics_bin`) |
| The account and the private key that log in to the guest | `ssh` (`user`, `key`) |

A run uses a copy of `tests/vm/config.example.json` with real values. The example uses placeholders such as `/replace/images`.

## Operations of the VM driver

| Operation | Command form | What the driver does |
| :--- | :--- | :--- |
| Initialize a run | `bash tests/run-all-tests.bash --init --config <config_file> --evidence <new_directory>` | Validates the configuration, refuses an evidence directory that exists, writes `run.json` with the configuration and the checksums of `driver.py` and `guest.py`, and prints `PASS: run initialized; no guest was contacted` |
| Run one case | `bash tests/run-all-tests.bash --case <case> --handoff <handoff_file> <run>` | Adopts the guest named in the handoff file, runs the runtime checks and the lifecycle checks for the case, and prints `PASS: case <case> recorded; only --verdict establishes acceptance` |
| Verify cleanup | `bash tests/run-all-tests.bash --verify-cleanup <run>` | Checks the owned resources and prints `PASS: owned resources are absent and the baseline is preserved` |
| Verdict | `bash tests/run-all-tests.bash --verdict <run>` | Prints `PASS`, `FAIL` or `INCOMPLETE` with exit status `0`, `1` or another value |

Only the verdict establishes acceptance of a run. A case that ends with `PASS` is recorded, not accepted. The driver holds a lock on the run directory, so another operation on the same run is refused.

## Cases and exit statuses

The cases are `debian13-socket`, `debian13-tcp`, `debian13-sqlite`, `rocky8-socket`, `rocky8-tcp`, `rocky8-sqlite`, `debian13-build-failure` and `rocky8-build-failure`. A mode without VM inputs, such as `--phase=3` or `all`, prints that VM verification runs as explicit operations and exits with `77`; no system action runs.

Any exit status other than `0` and `1` of the verdict operation prints `INCOMPLETE`, and the plain modes exit with `77` without a verdict. The command forms come from `tests/run-all-tests.bash` and the help of `tests/vm/driver.py` (`python3 tests/vm/driver.py --help`).
