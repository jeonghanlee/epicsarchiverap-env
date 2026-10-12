# Start and stop actions of the appliance

The appliance is one systemd service, `epicsarchiverap-maven.service`, that owns the four Tomcat instances. This page lists the actions that start, stop and restart it, the order of the instances, and what the control script `archappl.bash` reports.

## Actions through systemd

Each target runs from the repository checkout that installed the appliance. The targets `sd_start`, `sd_stop` and `sd_restart` run `systemctl` with `sudo`; `sd_status` runs `systemctl status` without it.

| Target | What it does |
| :--- | :--- |
| `make sd_start` | Starts the service and its health timer |
| `make sd_stop` | Stops the service; the unit waits up to `SYSTEMD_TIMEOUT_STOP_SECONDS` (300 seconds by default) for the ordered stop of the four instances, which includes the consolidation of data that the ETL component performs on shutdown. The health timer keeps running, and its scheduled check skips the stopped appliance with `SKIP appliance-inactive` |
| `make sd_restart` | Restarts the service and starts the health timer again |
| `make sd_status` | Shows the state of the service |

## Output of the status target

The following lines are an excerpt of `make sd_status` on a running appliance. The Java command lines of the four instances and the resource lines are left out:

```text
● epicsarchiverap-maven.service - EPICS Archiver Appliance for als
     Loaded: loaded (/opt/epicsarchiverap-maven/archappl.bash; enabled; preset: enabled)
     Active: active (running) since Sat 2026-09-12 21:34:29 PDT; 2 days ago
   Main PID: 34519 (bash)
     CGroup: /system.slice/epicsarchiverap-maven.service
             ├─34519 /bin/bash /opt/epicsarchiverap-maven/archappl.bash service
             ├─37602 /bin/cat
             ├─86316 /usr/lib/jvm/java-21-openjdk-amd64/bin/java ...
```

The service runs `archappl.bash service` as its main process. Each of the four instances is one `java` process in the same control group, started with its own `/bin/cat` helper process.

## The order of the instances

The unit runs `archappl.bash service` as its main process. The script starts the instances in the first order below and stops them in the second.

| Action | Order |
| :--- | :--- |
| Start | `mgmt`, `engine`, `etl`, `retrieval` |
| Stop | `engine`, `retrieval`, `etl`, `mgmt` |

Each instance writes to the journal through its own `systemd-cat` with the identifier `archappl-<component>`, as [Journal identifiers of the components](logs.md) lists.

## Actions of the control script without systemd

The actions `startup`, `shutdown` and `restart` of `archappl.bash` start and stop the instances without systemd. The targets `make start` and `make stop` call `startup` and `shutdown` of the installed script. Do not use these actions while the systemd unit manages the appliance.

## Exit statuses and messages

| Situation | Exit status | Message on standard error |
| :--- | :--- | :--- |
| An instance script of `startup` fails | non-zero; the other instances run as well | `startup ERROR <component> status=<n>` |
| An instance script of `shutdown` fails | non-zero; the other instances run as well, and the `temp/<component>.pid` file of the failed one stays | `shutdown ERROR <component> status=<n>` |
| The shutdown part of `restart` fails | non-zero; no instance is started | `restart ERROR shutdown failed; no instance was started` |
| `archappl.conf` next to the script is missing or is not valid shell (`startup`, `shutdown`, `restart`, `service`) | non-zero; no instance is touched | `ERROR: <path>/archappl.conf is missing or is not valid shell; no instance was touched` |

The orders and the timeout come from `scripts/archappl.bash`, `configure/RULES_SYSTEMD` and `configure/CONFIG_SYSTEMD`. The checks of `tests/phase1-logic.bash` assert the statuses and messages: they run the shipped script from a copy beside instance scripts that record their calls and exit with a chosen status.
