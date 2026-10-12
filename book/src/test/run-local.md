# Run the local test suite

The local suite checks the Make system, the configuration files, the control script, the interface files and the installer entry points without installing anything. It needs no network and no root privilege.

## Prerequisites

- A checkout of the repository with `make`, `bash` and `python3`.
- Optional: the source clone of the repository (`make init` creates it). The interface files group reads the management interface from it and is skipped with a message when no clone exists.
- Optional: the directory of Experimental Physics and Industrial Control System (EPICS) Base binaries, for the check that resolves the real `softIoc` and `caget`. Without it the check prints `SKIP: real Base binary resolution; AA_TEST_EPICS_BIN is unset.`

## Steps

1. Run the suite from the root of the checkout.

   ```bash
   bash tests/run-all-tests.bash --local
   ```

   The command prints one `[OK]` line for each check and ends with one `[PASS]` line for each group.

2. Optional: set environment variables for the run.

   | Variable | Effect |
   | :--- | :--- |
   | `EXPECTED_BRANCH` | The branch the first check expects, `modernize` by default. A different branch prints a warning, not a failure |
   | `AA_TEST_EPICS_BIN` | The EPICS Base binary directory for the real binary check |
   | `KEEP_WORKSPACE` | `1` keeps the temporary workspace after the run, for inspection |

   To set the variables for one run, put them before the command:

   ```bash
   EXPECTED_BRANCH=<branch> AA_TEST_EPICS_BIN=<epics_bin_dir> bash tests/run-all-tests.bash --local
   ```

3. Run one phase when you only need it. `--phase=1` runs the logic checks and `--phase=2` runs the build-wrapper checks after them.

   ```bash
   bash tests/run-all-tests.bash --phase=1
   ```

## Verification

The exit status is `0` and the last lines show a `[PASS]` for each group, in this form, where `<n>` is the number of checks of the group:

```text
[PASS] Phase 1: Logic (passed=<n> failed=0)
[PASS] Health: instances that have not executed Java yet (passed=<n> failed=0)
[PASS] No Ant: configuration, site build file and Maven site id (passed=<n> failed=0)
[PASS] Interface files: markers, content security, inline code and element ids (passed=<n> failed=0)
[PASS] Phase 2: Build wrapper (passed=<n> failed=0)
```

The number of checks changes when a check is added; the status of each group and `failed=0` are what matter. On a host without the source clone, the interface files group prints a skip message and reports `passed=0`.
