# Reinstall or upgrade an appliance

The installer compares an installed appliance with the selected source and rendered configuration, then applies the changes. It fetches the source repository and selects the commit that `SRC_TAG` names; the default is the tag `2026-10`. An unchanged installation needs no build, confirmation, or restart. A checkout that follows a branch such as `origin/master` selects its fetched tip; to install the same source again, set `SRC_TAG` to a commit hash or tag first, as in [Select the source commit to build](../build/select-commit.md). The [glossary](../appendix/glossary.md) explains the terms of this page.

## Prerequisites

- An installed appliance managed by `epicsarchiverap-maven.service`.
- `configure/CONFIG_SITE.local` absent, or holding only the generated line `include $(TOP)/configure/os/<preset>.mk` of a shipped preset. Before any `make` step, `sudo` or package change, also with `--plan`, the installer checks the file and stops with status 1 when it holds anything else, such as an extra assignment, a comment, a blank line, a second include, a Make expression, altered whitespace or CRLF line ends, when it is empty or a symbolic link, or when it is not a readable regular file. The message names the file, the reason and the offending line numbers, never the contents. Keep site settings in `../CONFIG_SITE.local`. To recover, move the settings there first, then delete `configure/CONFIG_SITE.local`; the installer writes the generated line again. Running `make <os>.conf` before the move overwrites the settings.
- A way back. After a successful run the installer keeps no copy of the old payload, and it overwrites `archappl.conf` and the other installed files, so local edits to them are lost. Files in the installed `config.d` directory retain their contents; see [Local runtime environment](../configure/runtime-environment.md). Before inspection, record the installed commit from `mgmt/webapps/mgmt/ui/comm/version.txt` under `AA_INSTALL_LOCATION`. The installed `.versions` also records the source commit when present; `make install` copies it from `site-template/.versions`. Inspection rewrites the checkout copy, so it is not a record of the installed version. Also back up `AA_INSTALL_LOCATION`, `../CONFIG_SITE.local` and the database. A return to an older version is a reinstall with `SRC_TAG` set to the recorded commit and the old site inputs, but only when that source carries the management interface. The installer stops in `source selection` with `The selected source does not carry the management interface: missing <page>` for a source without it, such as the commit `d8a7813f` of release 2.0.0. A site that returns to such a version restores its backups of `AA_INSTALL_LOCATION` and the database.
- The database backend of the appliance and, for MariaDB, its transport. The `url` attribute of `<install_location>/mgmt/conf/context.xml` shows them, where `<install_location>` is `AA_INSTALL_LOCATION` (`/opt/epicsarchiverap-maven` by default): `jdbc:sqlite:` for SQLite, `jdbc:mariadb://localhost/...?localSocket=...` for MariaDB over a socket, and `jdbc:mariadb://<host>:<port>/...` for MariaDB over TCP.
- An ordinary user that owns the checkout and can use `sudo`; the installer refuses to run as root. It authenticates `sudo` after confirmation when changes need to be applied (`sudo -v`). It does not refresh the timestamp, so a later privileged step can ask for the password again. An unattended run that applies changes needs `sudo` without a password prompt. Authentication failure leaves the installation unchanged, but source selection and rendering in the checkout have already run.
- A host that runs systemd, with the JDK under `JAVA_HOME` and these commands: `make`, `git`, `realpath`, `bash`, `sudo`, `flock`, `curl`, `jq`, `unzip`, `sha512sum`, `systemctl` and `timeout`, plus `sqlite3`, `lsof`, and `runuser` for the SQLite installer or `mysql` for the MariaDB installers. The installer stops with a message when one of these is missing. A host without Tomcat, or a run with `--tomcat replace`, also needs `wget`, which the installer does not check; the package list of [Prepare the host for the appliance](prepare-host.md) includes it.
- Optional: an exported `EPICS_BASE` with `softIoc` and `caget`, for the soft IOC test that the installer offers. Without it, the answer `y` to the test question stops the installer before it changes anything.
- What the installer changes on the host and the network access that it needs, as [Changes that the installer makes on the host](host-changes.md) lists them.
- A checkout in which the source commit (`SRC_TAG`) and the site inputs are the ones to install, and in which the source inputs have no local changes.
- A decision about the database: the installer replaces the appliance payloads and keeps the database contents and the stores, that is the SQLite file or the MariaDB database and the three store folders under `ARCHAPPL_STORAGE_TOP`. When the schema layer changes, the MariaDB installer prepares accounts with `DB_ADMIN_PASS`, `DB_USER_PASS`, and the configured grants unless you add `--existing-db`. A password that `../CONFIG_SITE.local` does not set takes the public default of `configure/CONFIG_SITE`: `admin` for `DB_ADMIN_PASS` and `archappl` for `DB_USER_PASS`. The storage step runs only for a first installation or a storage difference. Its recursive ownership change can take time on a large archive.

## Steps

1. Print the full installation sequence, with the installer that matches the database backend of the appliance. The option `--plan` prints a static sequence without changing files or starting services. It does not compare the installed appliance. The option `--skip-packages` uses the packages of the host. For an SQLite appliance, run:

   ```bash
   bash scripts/install-local-sqlite.bash --plan --skip-packages
   ```

   For a MariaDB appliance that uses the local socket, run:

   ```bash
   bash scripts/install-local-mariadb-uds.bash --plan --skip-packages
   ```

   For a MariaDB appliance that uses TCP, run:

   ```bash
   bash scripts/install-local-mariadb-tcp.bash --plan --skip-packages
   ```

   The TCP installer serves a database on this host only. It stops, already at the plan command, with `Local TCP installation requires DB_HOST_NAME=127.0.0.1` when `DB_HOST_NAME` is another address. For an appliance whose `url` names another host, follow the manual steps of "Reinstall and upgrade" in `docs/README.install.md`.

   For a MariaDB appliance that uses the local socket, the installer does not remember the socket of the first installation. Add `--socket <path>` with the path that the `url` shows to the plan command and to the run in step 4, or keep `DB_SOCKET` in `../CONFIG_SITE.local`; without it the installer takes the default socket of the operating system. A missing socket stops the schema step after the appliance has stopped. Only `install-local-mariadb-uds.bash` accepts `--socket`; the SQLite and TCP installers stop with `--socket requires MariaDB UDS`.

   For a MariaDB appliance, add `--existing-db` to the plan command to keep the existing accounts. `DB_USER_PASS` must match the password of the existing application account. Add the flag again in step 4 to preserve those accounts when the schema step runs.

   The printed sequence includes stopping `epicsarchiverap-maven.service`. A normal run stops it only when changes need to be applied.

2. Inspect the installed appliance. In the matching command from step 1, replace `--plan` with `--inspect` and retain the backend options.

   Inspection takes the checkout lock, selects the OS preset, fetches and selects the source, and renders configuration. It changes files in the checkout, but no installed files, packages, database, storage, or service state. It does not ask for confirmation or a password.

   A second installer or inspection using the same checkout stops with `Another appliance installer is running in this checkout` while this lock is held.

   Each installable layer reports `changed`, `unchanged`, or `refuse`, with a reason; runtime reports `observed`. A refusal stops the run. The program consists of four web application archive (WAR) files.

   | Layer | Comparison | Work selected by a normal run |
   | --- | --- | --- |
   | `program` | Installed source commit and the three classpath bindings | Build and install when changed |
   | `configuration` | Rendered files, launch scripts, and component ports | Install from existing WARs when available |
   | `systemd` | Rendered units and the Tomcat override | Install files and units |
   | `schema` | SQL at the installed and target commits | Load added tables; require acceptance for other changes |
   | `storage` | Existence and owner of the configured folders | Create folders and set ownership |
   | `runtime` | Service, timer, HTTP, and available health observations | Observation only; never selects work |

   The `build` line reports whether a build is needed. Missing WARs trigger a build only when appliance files will be installed. A missing installed `version.txt` selects a first installation, with all five installable layers changed.

   When the installed `archappl.conf` sets all three bindings below, changes only to these files can reuse the four existing target WARs. If a target WAR is missing, installation builds first. The installer copies these files and restarts the appliance. If a binding is absent, it selects a rebuild.

   | File | Binding in installed `archappl.conf` |
   | --- | --- |
   | `appliances.xml` | `ARCHAPPL_APPLIANCES` |
   | `archappl.properties` | `ARCHAPPL_PROPERTIES_FILENAME` |
   | `policies.py` | `ARCHAPPL_POLICIES` |

   The schema comparison assumes the database matches the schema of the installed commit. It cannot detect manual database edits or a schema loaded from another commit. Only complete new tables are accepted automatically; other changes print a diff and stop. After reviewing that diff and arranging any required migration, add `--accept-schema` to accept schema loading. This option does not migrate existing columns: `CREATE TABLE IF NOT EXISTS` leaves existing tables unchanged.

   Resolve retained `.payload.*` folders before proceeding. An installed commit that remains unavailable after the fetch also causes refusal. Inspection also refuses an existing installation whose configured Java executable or Tomcat folder is missing. It does not upgrade the JDK or Tomcat. A value supplied only to a separate Make command is not part of this comparison.

   Runtime observations do not determine whether the installation is up to date. Without password-free `sudo`, health is reported as `health not observed: needs sudo`. An up-to-date result does not establish full runtime readiness.

3. Optional: decide how the installer handles Tomcat and its questions.

   Read the Tomcat lines of the static plan in step 1. When the checkout owner cannot execute an existing Tomcat, the plan prints a choice. Add `--tomcat existing` to the command to use the existing Tomcat after checking access as the service user. Add `--tomcat replace` to back it up and install the configured version. The option `--tomcat replace` downloads and checks the configured version first, then stops the appliance and its health monitor and moves the existing folder to `/opt/tomcat9.backup.<random>/tomcat`; the installer prints that path as `Tomcat backup: <directory>/tomcat`.

   Add `-y` to skip the two questions of the installer. In the Tomcat case, a run with `-y` and without `--tomcat` stops with `Select --tomcat existing or --tomcat replace for unattended installation`.

   The command of step 1 has `--skip-packages`, which uses the packages of the host. Remove it when the installer is to install the packages.

4. Run the installer without `--plan` or `--inspect`, with the backend and Tomcat options selected above. Answer the questions that it asks.

   The installer repeats the inspection while holding the lock. Program, configuration, or systemd differences select file installation; `--tomcat replace` also selects it. A selected installation rebuilds WAR files when the program changed or any target WAR is missing. Otherwise it reuses the existing WARs, including for configuration-only changes.

   The optional soft IOC question comes first, before the lock and checkout update. It defaults to `N`; `-y` and non-interactive input skip it. After inspection, the confirmation names the changed layers and adds `build first` when needed. Answer `y` to apply them, or use `-y` to skip confirmation.

   A changed run without a terminal or `-y` stops in `confirmation`, after updating the checkout. A run with no changes skips confirmation, password authentication and the service stop, then runs the soft IOC test if you selected it.

   When you answer `y` to the first question, the installer runs the soft IOC test after any selected installation changes and startup checks succeed, or directly after inspection when the installation is unchanged. When the test passes, it asks `Select [1/2]:`. The answer `1`, an empty answer or the end of the input stops the soft IOC and leaves the test PV paused. The answer `2` resumes the test PV and keeps the soft IOC running. The installer waits for this answer.

   If file installation is selected, and the checkout owner cannot execute the existing Tomcat and you gave no `--tomcat`, the installer asks `Tomcat choice [1/2; anything else cancels]:`. Answer `1` to use the existing Tomcat, or `2` to back it up and install the configured version, which stops the appliance.

   When Tomcat is reused, the appliance keeps running during the build. Every run that applies changes stops it, including schema-only and storage-only runs. Downtime spans `appliance stop` through startup readiness. The stop takes up to 300 seconds (`SYSTEMD_TIMEOUT_STOP_SECONDS`), and startup waits up to 180 seconds by default. Storage ownership work, when selected, also takes place during downtime.

   The stages follow this order; conditional stages are omitted when their work is unnecessary:

   | Stage | Work |
   | --- | --- |
   | `prerequisites` | Select the OS preset under the checkout lock |
   | `source selection` | Fetch and select `SRC_TAG` |
   | `configuration` | Render database, application, and installation inputs |
   | `inspection` | Compare layers; stop on refusal, or run only the selected PV test when unchanged |
   | `confirmation` | Confirm the selected changes, then authenticate `sudo` |
   | `prerequisites` | Install packages unless skipped, read settings, and check the host |
   | `Tomcat preparation` | Prepare Tomcat when appliance files will be installed |
   | `build` | Build when the selected installation needs WARs |
   | `appliance stop` | Stop the appliance and require it to be inactive |
   | `database and installation` | Stop monitoring, then apply selected schema, storage, and file work |
   | `startup verification` | Start the appliance and check readiness |

   After the lock, failures name the stage in `Installation stopped during <stage> (exit <status>)`. Preflight or lock failure prints only `ERROR: <message>`. A failed confirmation or `sudo -v` leaves the installation unchanged, but the checkout update has already run. Inspection-only failures use `Inspection stopped during <stage> (exit <status>)`.

   Startup or readiness failure prints `Appliance files are installed. Verification failed (exit <status>)`. This wording also applies when only schema or storage work ran. A failed readiness check includes [the readiness block](../operate/health-results.md#the-readiness-block-of-the-installer).

   A failure before `appliance stop` leaves the old appliance running. `--tomcat replace` stops the appliance and the health monitor earlier, in `Tomcat preparation`, after the download and the checksum check; a failure before that point leaves the appliance running. A failure in `appliance stop` leaves the health monitor running: `Appliance is not stopped: <state>` names the state of the service, and after a failing `systemctl stop` the command `systemctl is-active "$(make -s print-SYSTEMD_FILENAME)"` prints it. A failure in `database and installation` leaves the service stopped and, unless its first command `sd_health_stop` failed, the health monitor stopped, and the instances possibly partly replaced, so do not start the service before a run succeeds. A failure in `startup verification`, which includes the start, leaves the installed files and the service as they are.

   When `--tomcat replace` fails after it has moved the folder, `/opt/tomcat9` is absent, partial or not usable by the service user. The first run prints the path of the original Tomcat on the line `Tomcat backup: <directory>/tomcat`; a second run with `--tomcat replace` moves a partial folder into a further backup, so keep the path of the first run.

   The installer does not roll back the run and does not restart the appliance. Correct the cause and run the installer again.

   An interrupt with Ctrl-C can end the run without a stage summary. Use the stage table and the last printed command to determine what ran. The commands `db.conf`, `conf.archapplproperties`, and `conf.install` belong to `configuration`; `build.mvn` belongs to `build`.

   During `Tomcat preparation`, replacement can stop the appliance before moving Tomcat. An interrupt at the initial soft IOC question leaves the checkout and installation unchanged. An interrupt at confirmation leaves the installation unchanged, but source selection and rendering have already run.

## Verification

After a run applies changes and passes startup verification, it prints `Installation completed. All required installation checks passed.` before the health result and the appliance information. The line `PV acquisition, storage and retrieval: NOT CHECKED` is expected; the test of [Archive a test PV and check the stored samples](verify-pv.md) checks the data path. The check in [Check the health of the appliance](../operate/health.md) repeats the health result later.

An unchanged run prints `The installation is up to date: no layer differs from the checkout.` It reports runtime observations during inspection and skips the build, installation, service restart and startup verification. If you selected the soft IOC test at the initial question, it runs that test against the running appliance. Otherwise, PV acquisition, storage and retrieval remain `NOT CHECKED`. Use the linked health procedure when a full readiness check is required.
