# Check the health of the appliance

The control script verifies that the four Java virtual machine (JVM) processes belong to the installed appliance and that the stores have free space. A systemd timer runs the same check on a schedule.

## Prerequisites

- An installed appliance.
- A shell on the appliance host, as the service account (`tomcat` by default) or as root. A user that cannot read the instance directories gets `ERROR inaccessible-instance-directory` lines. The scheduled check runs as the service account.

## Steps

1. Run the `health` action of the control script from the installation directory `AA_INSTALL_LOCATION`. The script prints one line for each component, one line for the archive root and each configured store, and a verdict. The exit status is `0` for a healthy appliance, `1` when an instance has failed, is starting, or a store is at or above the threshold, and `2` when the inspection could not complete.

   A checkout has no `archappl.conf` next to the script, so the check cannot inspect anything there. In a checkout, the action prints the lines below and exits with `2`:

   ```bash
   bash scripts/archappl.bash health
   ```

   The action prints one error line for each component and the storage path, and the verdict:

   ```text
   mgmt pid=- ERROR unreadable-or-invalid-configuration
   engine pid=- ERROR unreadable-or-invalid-configuration
   etl pid=- ERROR unreadable-or-invalid-configuration
   retrieval pid=- ERROR unreadable-or-invalid-configuration
   storage path=- ERROR unreadable-or-invalid-configuration
   health ERROR inspection-incomplete
   ```

2. Read the verdict line. The page [Health check results](health-results.md) lists every line and its reason.

3. Optional: show the state of the scheduled check with the target `make sd_health_status`. The timer starts the check one second after it becomes active and again `SYSTEMD_HEALTH_INTERVAL_SECONDS` (30 seconds by default) after each run ends. The check runs as the service account, skips an appliance that started less than `SYSTEMD_HEALTH_STARTUP_SECONDS` (60 seconds) ago, and is stopped after `SYSTEMD_HEALTH_TIMEOUT_SECONDS` (5 seconds). The exit status `3` of a skipped check counts as success for systemd.

4. Optional: change the limits in `../CONFIG_SITE.local`, as in [Override a setting for one host](../configure/override-setting.md).

   | Variable | Default | Effect |
   | :--- | ---: | :--- |
   | `ARCHAPPL_STORAGE_ALARM_PERCENT` | 85 | A store at or above this usage makes the check print `FAIL storage-threshold` |
   | `ARCHAPPL_HEALTH_STARTING_SECONDS` | 10 | An instance that starts within this many seconds prints `STARTING`; the valid range is 1 to 59 |

## Verification

On an installed and started appliance the last line is `health PRESENT all-four-processes-verified; application-readiness-not-checked` and the exit status is `0`. The line states that the processes are verified and that the readiness of the applications is not part of this check; the installers check the `getApplianceInfo` call separately.
