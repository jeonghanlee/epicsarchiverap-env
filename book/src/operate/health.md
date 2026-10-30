# Check the health of the appliance

The control script verifies that the four Java virtual machine (JVM) processes belong to the installed appliance and that the stores have free space. A systemd timer runs the same check on a schedule. The [glossary](../appendix/glossary.md) explains the terms of this page.

## Prerequisites

- An installed appliance.
- A shell on the appliance host, as the service account (`tomcat` by default) or as root. A user that cannot read the instance directories gets `ERROR inaccessible-instance-directory` lines. An ordinary user that is neither the service account nor root gets `ERROR unreadable-process-executable` for each running instance, then `health ERROR inspection-incomplete` and exit status `2`, because the check cannot read `/proc/<pid>/exe` of the process. The scheduled check runs as the service account.

## Steps

1. Run the `health` action of the control script from the installation directory `AA_INSTALL_LOCATION`. The script prints one line for each component, one line for the archive root and each configured store, and a verdict. The exit status is `0` for a healthy appliance, `1` when an instance has failed, is starting, or a store is at or above the threshold, and `2` when the inspection could not complete.

   On an installed and started appliance, run the action as the service account, shown as `<service_account>` below (`tomcat` by default, set by `AA_USERID`). The folder `<install_location>` is `AA_INSTALL_LOCATION` (`/opt/epicsarchiverap-maven` by default; `make -s print-AA_INSTALL_LOCATION` prints it), which holds `archappl.bash` and `archappl.conf`. The command below exits with `0`:

   ```bash
   sudo -u <service_account> bash <install_location>/archappl.bash health
   ```

   The action prints one line for each component and one line for the archive root and each store, with `<pid>` standing for the process id and `<storage_top>` for `ARCHAPPL_STORAGE_TOP`:

   ```text
   mgmt pid=<pid> PRESENT verified-process-presence
   engine pid=<pid> PRESENT verified-process-presence
   etl pid=<pid> PRESENT verified-process-presence
   retrieval pid=<pid> PRESENT verified-process-presence
   storage path=<storage_top> mount=/ use=33% threshold=85% PRESENT
   storage path=<storage_top>/sts/ArchiverStore mount=/ use=33% threshold=85% PRESENT
   storage path=<storage_top>/mts/ArchiverStore mount=/ use=33% threshold=85% PRESENT
   storage path=<storage_top>/lts/ArchiverStore mount=/ use=33% threshold=85% PRESENT
   health PRESENT all-four-processes-verified; application-readiness-not-checked
   ```

   A checkout has no `archappl.conf` next to the script, so the check cannot inspect anything there. In a checkout, the action prints `ERROR unreadable-or-invalid-configuration` for each component and for the storage path, then `health ERROR inspection-incomplete`, and exits with `2`.

2. Read the verdict line. The page [Health check results](health-results.md) lists every line and its reason.

3. Optional: show the state of the scheduled check. Run the target from the repository checkout that installed the appliance.

   ```bash
   make sd_health_status
   ```

   The timer starts the check one second after it becomes active and again `SYSTEMD_HEALTH_INTERVAL_SECONDS` (30 seconds by default) after each run ends. The check runs as the service account, skips an appliance that started less than `SYSTEMD_HEALTH_STARTUP_SECONDS` (60 seconds) ago, and is stopped after `SYSTEMD_HEALTH_TIMEOUT_SECONDS` (5 seconds). The exit status `3` of a skipped check counts as success for systemd.

4. Optional: change the limits in `../CONFIG_SITE.local`, as in [Override a setting for one host](../configure/override-setting.md).

   | Variable | Default | Effect |
   | :--- | ---: | :--- |
   | `ARCHAPPL_STORAGE_ALARM_PERCENT` | 85 | A store at or above this usage makes the check print `FAIL storage-threshold` |
   | `ARCHAPPL_HEALTH_STARTING_SECONDS` | 10 | An instance that starts within this many seconds prints `STARTING`; the valid range is 1 to 59 |

   Changes in `../CONFIG_SITE.local` require a [reinstall](../install/reinstall.md) to reach the installed `archappl.conf`. Alternatively, set these variables in the installed [local runtime environment](../configure/runtime-environment.md); the next health invocation reads them. This does not show that an existing JVM has received changed environment variables.

## Verification

On an installed and started appliance the last line is `health PRESENT all-four-processes-verified; application-readiness-not-checked` and the exit status is `0`. The line states that the processes are verified and that the readiness of the applications is not part of this check; the installers check the `getApplianceInfo` call separately.
