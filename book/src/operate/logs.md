# Read the logs of the four components

Each instance writes its log lines to the systemd journal. This page reads them by the identifier that the control script gives each instance.

## Prerequisites

- An appliance started by the systemd unit, as in [Start, stop and restart the appliance](start-stop.md).
- Permission to read the journal: root, or membership of the `systemd-journal` group.

## Steps

1. Print the commands for the four identifiers. The `status` action of the control script prints them with the addresses of the management page.

   ```bash
   bash /opt/epicsarchiverap-maven/archappl.bash status
   ```

   The lines that name the journal commands are:

   ```text
   >>> Consult Service Logs (journald, one identifier per instance)
     journalctl -t archappl-mgmt
     journalctl -t archappl-engine
     journalctl -t archappl-etl
     journalctl -t archappl-retrieval
   ```

2. Read one component. Add `-f` to follow it, or `-n <lines>` to limit the lines.

   ```bash
   journalctl -t archappl-mgmt -n 50
   ```

3. Read the log of the service unit itself, which holds the start and stop of the four instances.

   ```bash
   journalctl -u epicsarchiverap-maven.service
   ```

## How the level is set

Every line carries a syslog priority that `systemd-cat` turns into the journal priority, so `journalctl -p warning -t archappl-mgmt` shows only warnings and worse. The root level of the logging configuration is `ARCHAPPL_ROOT_LOGGER_LEVEL` (default `INFO`) in `archappl.conf`. `ARCHAPPL_LOG4J_SITE_FILE` names a site log4j2 configuration outside the WAR; when it is empty the WAR's own file applies. To change a logger level while the appliance runs, use [Change a log level at run time](loglevel.md).

## Verification

The command of step 2 prints lines whose identifier is `archappl-mgmt` and that carry the time of the host.

The commands of this page were not run for the book, because the host that wrote it serves a live archive; the identifiers and the settings come from `scripts/archappl.bash`, `site-template/skel/log4j/log4j2-tomcat.xml` and `configure/CONFIG_SITE`.
