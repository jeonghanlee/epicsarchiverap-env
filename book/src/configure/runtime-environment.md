# Local runtime environment

The installed `config.d` directory holds local environment additions and overrides for the appliance. It sits beside `archappl.conf` under `AA_INSTALL_LOCATION`, which defaults to `/opt/epicsarchiverap-maven`. Installation creates the directory and preserves existing local files during configuration regeneration and reinstall.

These files configure processes at startup. Periodic reload, live configuration APIs, and regeneration of installation files are outside this mechanism.

## File selection and syntax

The loader selects regular, non-hidden files matching `config.d/*.conf`, including symbolic links to regular files. It does not recurse into directories or read backup names such as `50-site.conf~` or `50-site.conf.bak`. A missing or empty directory leaves the common configuration in effect.

Files use Bash assignments, not Java properties syntax. Assignments are exported to child processes without an explicit `export`. Later assignments replace earlier values, including an explicitly empty value. Quote spaces and shell characters as Bash requires.

For example, `config.d/50-epics.conf` can restrict Channel Access discovery to the local host:

```bash
EPICS_CA_ADDR_LIST=127.0.0.1
EPICS_CA_AUTO_ADDR_LIST=NO
```

The files are sourced shell code and execute as the account running the launcher or wrapper. Keep write access limited to trusted operators and use assignment statements for settings. Keep the files readable by the service account.

## Configuration loading order

| Order | Source | Effect |
| :--- | :--- | :--- |
| 1 | Installed `archappl.conf` | Generated common defaults |
| 2 | Installed `config.d/*.conf` | Local additions and overrides in bytewise filename order (`LC_ALL=C`) |
| 3 | `<component>/conf/<component>.conf` | Component settings read by `startup.sh` and `run.sh` |
| 4 | Wrapper and Tomcat settings | Instance `CATALINA_BASE` and `CATALINA_PID`, then Tomcat's `setenv.sh` and startup processing |

The launcher and generated `startup.sh`, `shutdown.sh`, and `run.sh` share the same common loader. The directory is relative to the installed configuration, independent of the caller's working directory. `shutdown.sh` reads the common configuration without the component file.

Local values do not take precedence over later component or Tomcat assignments. A component can append its JVM options to the common `CATALINA_OPTS`. The launcher checks the readability and Bash syntax of every selected file before evaluating any configuration or starting a component.

An invalid or unreadable file produces a diagnostic naming the file, without printing its contents. Startup stops before touching an instance. The [health check](../operate/health.md) reports a configuration error. Finish configuration edits before starting or restarting the appliance.

## Applying changes to processes

Changes to environment variables used by a running Java virtual machine (JVM) require an [appliance restart](../operate/start-stop.md). Editing a file changes neither the environment nor the initialized Java objects of an existing JVM.

Each health invocation reads the current configuration files. A local change to `ARCHAPPL_STORAGE_ALARM_PERCENT` or `ARCHAPPL_HEALTH_STARTING_SECONDS` therefore affects the next check without restarting the appliance. The health result does not establish that running JVMs received the edited environment.

An environment override does not rewrite `server.xml`, `appliances.xml`, database configuration, or storage policies. For example, changing `ARCHAPPL_MGMT_PORT` here changes the launcher's destination but does not change Tomcat's listening port. Use [repository configuration](override-setting.md) and the existing installation procedure for settings represented in generated files.

Reinstall preserves `config.d` file contents, so an existing local value continues to override a changed generated default. Uninstall removes the installation directory, including `config.d`; retain a separate backup when uninstalling.
