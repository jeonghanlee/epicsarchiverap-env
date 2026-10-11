# Start, stop and restart the appliance

The appliance is one systemd service, `epicsarchiverap-maven.service`, that owns the four Tomcat instances. This page starts, stops and restarts it, and shows how the control script `archappl.bash` orders the instances.

## Prerequisites

- An installed appliance, as in [Install an appliance with SQLite](../install/sqlite.md).
- `sudo` rights; the targets below run `systemctl` with `sudo`.
- A shell in the repository checkout that installed the appliance.

## Steps

1. Start the service and its health timer.

   ```bash
   make sd_start
   ```

2. Stop the service.

   ```bash
   make sd_stop
   ```

   The unit waits up to `SYSTEMD_TIMEOUT_STOP_SECONDS` (300 seconds by default) for the ordered stop of the four instances, which includes the consolidation of data that ETL performs on shutdown.

3. Restart the service and start the health timer again.

   ```bash
   make sd_restart
   ```

4. Show the state of the service.

   ```bash
   make sd_status
   ```

## How the instances are ordered

The unit runs `archappl.bash service` as its main process. The script starts the instances in the first order below and stops them in the second:

| Action | Order |
| :--- | :--- |
| Start | `mgmt`, `engine`, `etl`, `retrieval` |
| Stop | `engine`, `retrieval`, `etl`, `mgmt` |

Each instance writes to the journal through its own `systemd-cat` with the identifier `archappl-<component>`, as [Read the logs of the four components](logs.md) shows.

The control script can also start and stop the instances without systemd, with `archappl.bash startup`, `archappl.bash shutdown` and `archappl.bash restart`. The targets `make start` and `make stop` call `startup` and `shutdown` of the installed script. Do not use them while the systemd unit manages the appliance.

## Verification

Run the health check of the script after the start. A started appliance prints `health PRESENT all-four-processes-verified; application-readiness-not-checked`, as [Check the health of the appliance](health.md) explains.

The commands of this page were not run for the book: the appliance of the host that wrote it serves a live archive. The orders and the timeout come from `scripts/archappl.bash`, `configure/RULES_SYSTEMD` and `configure/CONFIG_SYSTEMD`.
