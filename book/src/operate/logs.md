# Journal identifiers of the components

When systemd runs the appliance, each instance writes its application and Tomcat log lines to the systemd journal under its own identifier. The Tomcat access log stays a file, `logs/localhost_access_log.<date>.txt` in the instance folder. Instances that `make start` or the `startup` action launches do not log through `systemd-cat`. This page lists the identifiers, the commands that read them, and how the log level of a line is set. The [glossary](../appendix/glossary.md) explains the terms of this page.

## The identifiers

The `status` action of the control script prints the journal commands together with the addresses of the management page.

| Component | Identifier | Command |
| :--- | :--- | :--- |
| `mgmt` | `archappl-mgmt` | `journalctl -t archappl-mgmt` |
| `engine` | `archappl-engine` | `journalctl -t archappl-engine` |
| `etl` | `archappl-etl` | `journalctl -t archappl-etl` |
| `retrieval` | `archappl-retrieval` | `journalctl -t archappl-retrieval` |

Add `-f` to a command to follow the journal, or `-n <lines>` to limit the lines. The log of the service unit holds the lines of all four instances, each under its own identifier, and is read with `journalctl -u epicsarchiverap-maven.service`. Reading the journal needs root or membership of the `adm` or `systemd-journal` group. An ordinary user outside both groups gets a hint that other users' messages are hidden and the line `-- No entries --`, and the exit status is `0`, so an empty result does not mean that the instances wrote nothing.

The following command limits the output to the last two lines:

```bash
sudo journalctl -u epicsarchiverap-maven.service -n 2 --no-pager
```

A line holds the time, the host name, the identifier with the process id of the logging helper `systemd-cat`, and the message of the instance. The process id belongs to the helper and not to the Java process. The lines below come from the engine, with `<hostname>` for the host, `<pid>` for the process id and `<port>` for the ports:

```text
Oct 12 01:54:36 <hostname> archappl-engine[<pid>]: WARN  [UDP4-receiver /0.0.0.0:<port>] org.epics.pva - Received UDP packet with invalid magic startbyte from /127.0.0.1:<port>
Oct 12 01:54:37 <hostname> archappl-engine[<pid>]: WARN  [UDP4-receiver /0.0.0.0:<port>] org.epics.pva - Received UDP packet with invalid magic startbyte from /127.0.0.1:<port>
```

## How the level is set

Every log event starts with a syslog priority that `systemd-cat` turns into the journal priority. Continuation lines of a multi-line message or stack trace carry none and appear at the default priority. The command `journalctl -p warning -t archappl-mgmt` therefore shows the first line of each warning event and worse, and omits those continuation lines. The root level of the logging configuration is `ARCHAPPL_ROOT_LOGGER_LEVEL` (default `INFO`) in `archappl.conf`. `ARCHAPPL_LOG4J_SITE_FILE` names a site log4j2 configuration outside the web application archive; when it is empty the archive's own file applies. The page [Change a log level at run time](loglevel.md) changes the level of a running component.
