# Health check results

This page lists every line that `archappl.bash health` prints, the reason that follows a status word, and the exit status. The strings come from `scripts/archappl.bash`.

## Instance lines of the check

A line has the form `<component> pid=<pid> <status> <reason>`, where `<status>` is one of the status words of the table.

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

## Configuration errors of the check

When the check cannot load its configuration, each instance line reads `<component> pid=- ERROR <reason>`.

| Reason | Meaning |
| :--- | :--- |
| `linux-process-inspection-required` | The host is not Linux |
| `unreadable-or-invalid-configuration` | `archappl.conf` next to the script is missing, unreadable or has a syntax error |
| `configuration-load-failed` | `archappl.conf` did not load |
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

## Scheduled check lines

The timer runs `archappl.bash health --systemd <unit> <own_unit> <allowance>`. It prints `scheduled appliance=<unit> state=<state>` and then one of these lines.

| Line | Exit | Meaning |
| :--- | ---: | :--- |
| `SKIP appliance-inactive`, `SKIP appliance-stopping` | 3 | The appliance is stopped or stopping, which is not a failure |
| `SKIP startup-allowance`, `SKIP appliance-started-during-check` | 3 | The appliance started within the startup allowance |
| `scheduled SKIP appliance-transition; retry-next-tick` | 3 | The unit changed state while the check ran |
| `FAIL appliance-failed`, `FAIL appliance-stop-failed` | 1 | The unit is in a failed state |
| `FAIL startup-allowance-exceeded` | 1 | The unit is activating after the allowance |
| the output of the plain check | 0, 1 or 2 | The unit is active and the check above ran |
| `ERROR ...` (for example `invalid-unit-or-invocation-state`, `unreadable-unit-state`) | 2 | The check cannot read the unit |

The status word `STARTING` and the reasons that follow `FAIL` are not set by the scheduled check; it forwards them.
