# Run the local test suite

The local suite checks the Make system, the configuration files, the control script, the interface files and the installer entry points without installing anything. It needs no network and no root privilege.

## Prerequisites

- A checkout of the repository with `make`, `bash` and `python3`.
- `strace` and an ordinary user: the installer configuration check traces every command that an installer starts. Without a working `strace` it prints `INCOMPLETE:` and ends with status 77, and Phase 1 then fails.
- Optional: the source clone of the repository (`make init` creates it). The interface files group reads the management interface from it and is skipped with a message when no clone exists.
- Optional: the `bin/<host_arch>` folder of an Experimental Physics and Industrial Control System (EPICS) Base, for the check that resolves the real `softIoc` and `caget`. Step 2 shows how to find it. Without it the check prints `SKIP: real Base binary resolution; AA_TEST_EPICS_BIN is unset.`

## Steps

1. Run the suite from the root of the checkout.

   ```bash
   bash tests/run-all-tests.bash --local
   ```

   The command prints one `[OK]` line for each check and ends with one `[PASS]` line for each group.

2. Optional: find the folder of a real EPICS Base. Look in these places, in this order:

   1. `/opt/epics`
   2. a clone of the [EPICS-env-distribution](https://github.com/jeonghanlee/EPICS-env-distribution) repository
   3. a clone of the internal distribution repository of a site
   4. an EPICS Base build below your source directory
   5. `~/epics`

   The following command lists the trees of one place. Replace `<place>` and `<host_arch>`, which is `linux-x86_64` on an x86-64 Linux host:

   ```bash
   find -L <place> -maxdepth 9 -type f -name softIoc -path '*/bin/<host_arch>/*'
   ```

   A tree of a distribution ends as `<release>/<os>/<base_version>/base/bin/<host_arch>/softIoc`, where `<os>` is the `ID` and the `VERSION_ID` of `/etc/os-release` joined by a hyphen, such as `debian-13`. Any other build ends as `<base>/bin/<host_arch>/softIoc` and has no release number. Keep the distribution trees of your operating system and take the one with the highest release number. Compare the numbers field by field, so that `1.10.0` is higher than `1.9.0`. The earlier place wins a tie, and a tree without a release number ranks after the others. The folder to use is the one that holds `softIoc`, without the file name. It is called `<epics_bin_dir>` below. When nothing is found, leave the variable unset in the next step.

3. Optional: set environment variables for the run.

   | Variable | Effect |
   | :--- | :--- |
   | `EXPECTED_BRANCH` | The branch the first check expects, `modernize` by default. A different branch prints a warning, not a failure |
   | `AA_TEST_EPICS_BIN` | The `bin/<host_arch>` folder of an EPICS Base, as an absolute path, holding executable `softIoc` and `caget`. The real binary check uses it |
   | `KEEP_WORKSPACE` | `1` keeps the temporary workspace after the run, for inspection |

   To set the variables for one run, put them before the command:

   ```bash
   EXPECTED_BRANCH=<branch> AA_TEST_EPICS_BIN=<epics_bin_dir> bash tests/run-all-tests.bash --local
   ```

4. Run one phase when you only need it. `--phase=1` runs the logic checks and `--phase=2` runs the build-wrapper checks after them.

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

The number of checks changes when a check is added; the status of each group and `failed=0` are what matter. On a host without the source clone, the interface files group prints a skip message and ends with `[SKIP] Interface files: markers, content security, inline code and element ids (nothing was checked)` in place of its `[PASS]` line; a skipped group is not verification.

Whether the real binary check ran shows in one line. The following command runs the suite again and filters the output for that line:

```bash
AA_TEST_EPICS_BIN=<epics_bin_dir> bash tests/run-all-tests.bash --local 2>&1 | grep -E 'EPICS preflight|SKIP: real Base'
```

The line `PASS: EPICS preflight resolves the supplied real Base binaries.` shows that the real binaries were used. The line `SKIP: real Base binary resolution; AA_TEST_EPICS_BIN is unset.` shows that they were not.
