# Reinstall or upgrade an appliance

A reinstall replaces the installed payload of an appliance with the payload built from the current checkout. The same installer that performs the first installation performs the reinstall, and an upgrade is a reinstall after the selected source or the site inputs change. The installer fetches the source repository and builds the commit that `SRC_TAG` names; the default is the tag `2026-10`, so a reinstall builds the same source again. A checkout that follows a branch such as `origin/master` builds the tip of the day; to install the same source again, set `SRC_TAG` to a commit hash or tag first, as in [Select the source commit to build](../build/select-commit.md). The [glossary](../appendix/glossary.md) explains the terms of this page.

## Prerequisites

- An installed appliance managed by `epicsarchiverap-maven.service`.
- A way back. After a successful run the installer keeps no copy of the old payload, and it overwrites `archappl.conf` and the other installed files, so local edits to them are lost. Before the reinstall, record the line of `site-template/.versions` that starts with `- SRC GIT`, which the reinstall rewrites. The first word after its colon is the commit hash to use as `SRC_TAG`. Also back up `AA_INSTALL_LOCATION`, `../CONFIG_SITE.local` and the database. A return to the old version is a reinstall with `SRC_TAG` set to the recorded commit and the old site inputs.
- The database backend of the appliance and, for MariaDB, its transport. The `url` attribute of `<install_location>/mgmt/conf/context.xml` shows them, where `<install_location>` is `AA_INSTALL_LOCATION` (`/opt/epicsarchiverap-maven` by default): `jdbc:sqlite:` for SQLite, `jdbc:mariadb://localhost/...?localSocket=...` for MariaDB over a socket, and `jdbc:mariadb://<host>:<port>/...` for MariaDB over TCP.
- An ordinary user that owns the checkout and can use `sudo`; the installer refuses to run as root.
- A host that runs systemd, with the JDK under `JAVA_HOME` and these commands: `make`, `git`, `realpath`, `bash`, `sudo`, `flock`, `curl`, `jq`, `unzip`, `sha512sum`, `systemctl` and `timeout`, plus `sqlite3` for the SQLite installer or `mysql` for the MariaDB installers. The installer stops with a message when one of these is missing. A host without Tomcat also needs `wget`, which the installer does not check; the package list of [Prepare the host for the appliance](prepare-host.md) includes it.
- Optional: an exported `EPICS_BASE` with `softIoc` and `caget`, for the soft IOC test that the installer offers. Without it, the answer `y` to the test question stops the installer before it changes anything.
- What the installer changes on the host and the network access that it needs, as [Changes that the installer makes on the host](host-changes.md) lists them.
- A checkout in which the source commit (`SRC_TAG`) and the site inputs are the ones to install, and in which the source inputs have no local changes.
- A decision about the database: the installer replaces the appliance payloads and keeps the database contents and the stores, that is the SQLite file or the MariaDB database and the three store folders under `ARCHAPPL_STORAGE_TOP`. For a MariaDB appliance, the installer also gives the existing administrative and application accounts the configured passwords and grants, unless you add `--existing-db`. Each run gives `ARCHAPPL_STORAGE_TOP` and the three store folders to the service account with `chown -R`, so the run time grows with the size of the archive.

## Steps

1. Print the steps that the installer will perform, with the installer that matches the database backend of the appliance. The option `--plan` installs and starts nothing, and `--skip-packages` uses the packages of the host. For an SQLite appliance, run:

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

   For a MariaDB appliance, add `--existing-db` to the plan command to keep the existing accounts. `DB_USER_PASS` must match the password of the existing application account. Add the flag again in step 3, so that the run does what the plan shows.

   The plan states, before it changes any installed file, that the installer stops `epicsarchiverap-maven.service` and requires it to be inactive.

2. Optional: decide how the installer handles Tomcat and its questions.

   Read the Tomcat lines of the plan in step 1. When the checkout owner cannot execute an existing Tomcat, the plan prints a choice. Add `--tomcat existing` to the command to use the existing Tomcat after checking access as the service user. Add `--tomcat replace` to back it up and install the configured version. The option `--tomcat replace` stops the appliance and moves the existing folder to `/opt/tomcat9.backup.<random>/tomcat`.

   Add `-y` to skip the two questions of the installer. In the Tomcat case, a run with `-y` and without `--tomcat` stops with `Select --tomcat existing or --tomcat replace for unattended installation`.

   The command of step 1 has `--skip-packages`, which uses the packages of the host. Remove it when the installer is to install the packages.

3. Run the installer without `--plan`, with the same options as in steps 1 and 2. Answer the questions that it asks.

   The installer builds the web application archive (WAR) files, stops the service and the health monitor, replaces the payload under `AA_INSTALL_LOCATION`, installs the generated configuration and the systemd files, and starts the service again.

   The installer asks two questions before it changes anything. The first offers the optional soft IOC test: `Run the PV acquisition/storage/retrieval test after installation? [y/N]`. The default is `N`. The second asks for a confirmation: `Install packages, build, prepare the database, replace the appliance and start it? [y/N]`. The option `-y` skips both questions. A run without a terminal and without `-y` stops with `Non-interactive stdin; use --yes`. Answer `y` to the confirmation.

   Later, when the checkout owner cannot execute the existing Tomcat and you gave no `--tomcat`, the installer asks `Tomcat choice [1/2; anything else cancels]:`. Answer `1` to use the existing Tomcat, or `2` to back it up and install the configured version, which stops the appliance.

   The appliance keeps running during the build. It is stopped from `appliance stop` until the end of `startup verification`. The stop takes up to 300 seconds (`SYSTEMD_TIMEOUT_STOP_SECONDS`), the `chown -R` of the storage folders counts as downtime, and the start waits up to 180 seconds.

   The installer runs these stages in order: `prerequisites`, `source selection`, `Tomcat preparation`, `configuration and build`, `appliance stop`, `database and installation` and `startup verification`. A failure message names the stage, except in `startup verification`, where the installer prints `Appliance files are installed. Verification failed (exit <status>)`. When the startup check fails, it also prints the readiness block that [The readiness block of the installer](../operate/health-results.md#the-readiness-block-of-the-installer) explains.

   A failure before `appliance stop` leaves the old appliance running. `--tomcat replace` stops the appliance earlier, in `Tomcat preparation`. A failure in `database and installation` leaves the service stopped. A failure in `startup verification`, which includes the start, leaves the installed files and the service as they are.

   The installer does not roll back the run and does not restart the appliance. Correct the cause and run the installer again.

## Verification

After the installer finishes, it prints `Installation completed. All required installation checks passed.` before the health result and the appliance information. The line `PV acquisition, storage and retrieval: NOT CHECKED` is expected; the test of [Archive a test PV and check the stored samples](verify-pv.md) checks the data path. The check in [Check the health of the appliance](../operate/health.md) repeats the health result later.
