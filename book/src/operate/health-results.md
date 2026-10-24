# Health check results

This page lists every line that `archappl.bash health` prints, the reason that follows a status word, and the exit status. The strings come from `scripts/archappl.bash`. The last section explains the readiness block that the installers print when the startup check fails. The [glossary](../appendix/glossary.md) explains the terms of this page.

## Instance lines of the check

A line has the form `<component> pid=<pid> <status> <reason>`, where `<status>` is one of the status words of the table. `<pid>` reads `-` when the check could not read a process id.

| Status | Exit | Reason | Meaning |
| :--- | ---: | :--- | :--- |
| `PRESENT` | 0 | `verified-process-presence` | The process identifier (PID) file names a live process that belongs to the instance |
| `STARTING` | 1 | `run-script`, `catalina-script` | The process is in the start chain and younger than the starting bound |
| `FAIL` | 1 | `missing-pid-file`, `invalid-pid-file` | The PID file is absent or does not hold a valid PID |
| `FAIL` | 1 | `missing-process`, `dead-process` | The PID names no process, or a zombie or dead one |
| `FAIL` | 1 | `startup-timeout` | The process did not leave the start chain in time |
| `FAIL` | 1 | `wrong-java-executable`, `wrong-instance-base`, `wrong-tomcat-home`, `wrong-tomcat-identity` | A process with that PID is not this instance's Tomcat |
| `ERROR` | 2 | `inaccessible-instance-directory`, `inaccessible-pid-directory`, `unreadable-pid-path`, `unreadable-pid-file`, `unreadable-instance-path` | The check cannot read the instance directory or its PID file |
| `ERROR` | 2 | `unreadable-process-state`, `invalid-process-state`, `unknown-process-state`, `unreadable-process-executable`, `unreadable-process-arguments` | The check cannot read the process |
| `ERROR` | 2 | `process-changed-during-inspection`, `pid-file-changed-during-inspection` | The process or its PID file changed while the check ran |

## Storage lines of the check

A line has the form `storage path=<path> mount=<mount> use=<percent>% threshold=<percent>% <status>`, with a `<status>` from the table. The check reports the archive root and each of the three store folders.

| Status | Exit | Reason | Meaning |
| :--- | ---: | :--- | :--- |
| `PRESENT` | 0 | none | Usage is below the threshold |
| `FAIL` | 1 | `storage-threshold` | Usage is at or above `ARCHAPPL_STORAGE_ALARM_PERCENT` |
| `ERROR` | 2 | `storage-unreadable` | `df` cannot read the path |
| `ERROR` | 2 | `storage-invalid-threshold` | The threshold is not a number from 1 to 100 |

On the two `ERROR` rows, `mount` and `use` read `-`. The line of `storage-unreadable` keeps `threshold=<percent>%`; the line of `storage-invalid-threshold` prints the threshold as written, without `%`.

## Configuration errors of the check

When the check cannot load its configuration, each instance line reads `<component> pid=- ERROR <reason>`. For the reasons `unreadable-or-invalid-configuration` and `configuration-load-failed`, the storage line reads `storage path=- ERROR <reason>`, because the store path is unknown.

| Reason | Meaning |
| :--- | :--- |
| `linux-process-inspection-required` | The host is not Linux |
| `unreadable-or-invalid-configuration` | `archappl.conf` next to the script is missing, unreadable or has a syntax error |
| `configuration-load-failed` | Sourcing `archappl.conf` returned a non-zero status, for example because its last command failed |
| `invalid-runtime-paths` | `JAVA_HOME` or `CATALINA_HOME` is not an absolute path to an existing runtime |
| `starting-invalid-bound` | `ARCHAPPL_HEALTH_STARTING_SECONDS` is not a number from 1 to 59 |

## The verdict line of the check

| Line | Exit |
| :--- | ---: |
| `health PRESENT all-four-processes-verified; application-readiness-not-checked` | 0 |
| `health STARTING instances-starting; application-readiness-not-checked` | 1 |
| `health FAIL one-or-more-invalid-instances` | 1 |
| `health FAIL storage-threshold` | 1 |
| `health FAIL one-or-more-invalid-instances; storage-threshold` | 1 |
| `health ERROR inspection-incomplete` | 2 |
| `health ERROR invalid-arguments` | 2 |

## Scheduled check lines

The timer runs `archappl.bash health --systemd <unit> <own_unit> <allowance>`. The placeholder `<unit>` is the appliance unit, `<own_unit>` is the unit of the health check itself, and `<allowance>` is the startup allowance in seconds. When the unit state is the same before and after the check, it prints `scheduled appliance=<unit> state=<state>` and then one of the lines of the first table. The lines of the second table are printed alone, without that header line.

| Line | Exit | Meaning |
| :--- | ---: | :--- |
| `SKIP appliance-inactive`, `SKIP appliance-stopping` | 3 | The appliance is stopped or stopping, which is not a failure |
| `SKIP startup-allowance`, `SKIP appliance-started-during-check` | 3 | The appliance started within the startup allowance |
| `FAIL appliance-failed` | 1 | The unit is in the failed state |
| `FAIL appliance-stop-failed` | 1 | The unit is inactive after a result other than success |
| `FAIL startup-allowance-exceeded` | 1 | The unit is activating after the allowance |
| the output of the plain check | 0, 1 or 2 | The unit is active and the check above ran |
| `ERROR invalid-start-timestamp`, `ERROR unknown-appliance-state` | 2 | The check cannot interpret the start time or the state of the unit |

The lines of the second table end the check at once:

| Line | Exit | Meaning |
| :--- | ---: | :--- |
| `scheduled SKIP appliance-transition; retry-next-tick` | 3 | The unit changed state while the check ran |
| `scheduled ERROR invalid-arguments` | 2 | A unit name or the allowance is not valid |
| `scheduled ERROR unreadable-unit-state` | 2 | The check cannot read the state of the unit or of the timer's own service |
| `scheduled ERROR invalid-unit-or-invocation-state` | 2 | The check read the state, but the appliance unit is not loaded, a state field is empty, or the check does not run as the activated health service |
| `scheduled ERROR unreadable-final-unit-state` | 2 | The check cannot read the unit again after the inspection |

The status word `STARTING` and the reasons of the instance and storage tables are not set by the scheduled check; it forwards them.

## The readiness block of the installer

When the installer does not pass its startup checks within the wait (180 seconds by default), it prints `Verification could not pass within <N> seconds. Last observed results:` and the readiness block. It then prints the command that reads the service journal and ends with `ERROR: Installation verification did not pass; use the results above to identify the failed check.`

The block has one line each for the appliance service, the health timer, the four process identities, the storage usage and the health check. It then lists the four components, each with a status line and, indented below it, its startup address. The appliance information follows with its address and, below it, its status. Each status carries one of these words:

| Status | Meaning |
| :--- | :--- |
| `PASS` | The check passed |
| `NOT ACTIVE` | `systemctl is-active` reports the service or the health timer as inactive, failed, activating, deactivating or in maintenance; the line below names the state |
| `NOT READY` | A component does not answer `STARTUP_COMPLETE` at its startup address, or the appliance information address does not answer with an identity and a version |
| `NOT VERIFIED` | Not all four process identity checks pass |
| `NOT CHECKED` | The check did not run or its result is not known |
| `FAIL` | The health check ended with an error status, or a store is at or above the threshold |
| `ERROR` | The storage check printed an error line |
| `TIMED OUT` | A query did not finish before the deadline |
| `INSPECTION ERROR` | The health inspection or the unit state query ended abnormally |

The block also holds the address of the management page, the last health output and the command that repeats the health check. A line that gives the detail of a status, such as `systemctl reports: <state>`, is indented below its status line.

Read the block from the top. `NOT ACTIVE` on the service or the health timer names the state that systemd reports in the line below. `<component>: NOT READY` means that the component has not answered `STARTUP_COMPLETE`. Read the service journal with the printed command and the identifiers of [Journal identifiers](logs.md).

When `Storage usage` is `FAIL`, the installer adds that a store has reached the threshold. It keeps the threshold and deletes no data. When the four components, the process identities, the information API and the service have passed, it also says that the failed storage check does not mean that the appliance failed to start.
