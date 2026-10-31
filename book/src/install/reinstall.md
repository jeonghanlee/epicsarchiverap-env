# Reinstall or upgrade an appliance

A reinstall replaces the installed payload of an appliance with the payload built from the current checkout. The same installer that performs the first installation performs the reinstall, and an upgrade is a reinstall after the selected source or the site inputs change. The installer fetches the source repository and builds the commit that `SRC_TAG` names; the default is the tag `2026-10`, so a reinstall builds the same source again. A checkout that follows a branch such as `origin/master` builds the tip of the day; to install the same source again, set `SRC_TAG` to a commit hash or tag first, as in [Select the source commit to build](../build/select-commit.md). The [glossary](../appendix/glossary.md) explains the terms of this page.

## Prerequisites

- An installed appliance managed by `epicsarchiverap-maven.service`.
- `configure/CONFIG_SITE.local` absent, or holding only the generated line `include $(TOP)/configure/os/<preset>.mk` of a shipped preset. Before any `make` step, `sudo` or package change, also with `--plan`, the installer checks the file and stops with status 1 when it holds anything else, such as an extra assignment, a comment, a blank line, a second include, a Make expression, altered whitespace or CRLF line ends, when it is empty or a symbolic link, or when it is not a readable regular file. The message names the file, the reason and the offending line numbers, never the contents. Keep site settings in `../CONFIG_SITE.local`. To recover, move the settings there first, then delete `configure/CONFIG_SITE.local`; the installer writes the generated line again. Running `make <os>.conf` before the move overwrites the settings.
- A way back. After a successful run the installer keeps no copy of the old payload, and it overwrites `archappl.conf` and the other installed files, so local edits to them are lost. Files in the installed `config.d` directory retain their contents; see [Local runtime environment](../configure/runtime-environment.md). Before the reinstall, record the line of `site-template/.versions` that starts with `- SRC GIT`, which the reinstall rewrites. The first word after its colon is the commit hash to use as `SRC_TAG`. Also back up `AA_INSTALL_LOCATION`, `../CONFIG_SITE.local` and the database. A return to an older version is a reinstall with `SRC_TAG` set to the recorded commit and the old site inputs, but only when that source carries the management interface. The installer stops in `source selection` with `The selected source does not carry the management interface: missing <page>` for a source without it, such as the commit `d8a7813f` of release 2.0.0. A site that returns to such a version restores its backups of `AA_INSTALL_LOCATION` and the database.
- The database backend of the appliance and, for MariaDB, its transport. The `url` attribute of `<install_location>/mgmt/conf/context.xml` shows them, where `<install_location>` is `AA_INSTALL_LOCATION` (`/opt/epicsarchiverap-maven` by default): `jdbc:sqlite:` for SQLite, `jdbc:mariadb://localhost/...?localSocket=...` for MariaDB over a socket, and `jdbc:mariadb://<host>:<port>/...` for MariaDB over TCP.
- An ordinary user that owns the checkout and can use `sudo`; the installer refuses to run as root. It authenticates `sudo` once at the start (`sudo -v`) and does not refresh it, so a later `sudo` asks for the password again once the timestamp has expired. An unattended run (`-y`, no terminal) needs `sudo` without a password prompt; otherwise it stops at the start, before any change.
- A host that runs systemd, with the JDK under `JAVA_HOME` and these commands: `make`, `git`, `realpath`, `bash`, `sudo`, `flock`, `curl`, `jq`, `unzip`, `sha512sum`, `systemctl` and `timeout`, plus `sqlite3`, `lsof`, and `runuser` for the SQLite installer or `mysql` for the MariaDB installers. The installer stops with a message when one of these is missing. A host without Tomcat, or a run with `--tomcat replace`, also needs `wget`, which the installer does not check; the package list of [Prepare the host for the appliance](prepare-host.md) includes it.
- Optional: an exported `EPICS_BASE` with `softIoc` and `caget`, for the soft IOC test that the installer offers. Without it, the answer `y` to the test question stops the installer before it changes anything.
- What the installer changes on the host and the network access that it needs, as [Changes that the installer makes on the host](host-changes.md) lists them.
- A checkout in which the source commit (`SRC_TAG`) and the site inputs are the ones to install, and in which the source inputs have no local changes.
- A decision about the database: the installer replaces the appliance payloads and keeps the database contents and the stores, that is the SQLite file or the MariaDB database and the three store folders under `ARCHAPPL_STORAGE_TOP`. For a MariaDB appliance, the installer also gives the existing administrative and application accounts the passwords `DB_ADMIN_PASS` and `DB_USER_PASS` and the grants, unless you add `--existing-db`. A password that `../CONFIG_SITE.local` does not set takes the public default of `configure/CONFIG_SITE`: `admin` for `DB_ADMIN_PASS` and `archappl` for `DB_USER_PASS`. Each run gives `ARCHAPPL_STORAGE_TOP` and the three store folders to the service account with `chown -R`, so the run time grows with the size of the archive.

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

   The TCP installer serves a database on this host only. It stops, already at the plan command, with `Local TCP installation requires DB_HOST_NAME=127.0.0.1` when `DB_HOST_NAME` is another address. For an appliance whose `url` names another host, follow the manual steps of "Reinstall and upgrade" in `docs/README.install.md`.

   For a MariaDB appliance that uses the local socket, the installer does not remember the socket of the first installation. Add `--socket <path>` with the path that the `url` shows to the plan command and to the run in step 3, or keep `DB_SOCKET` in `../CONFIG_SITE.local`; without it the installer takes the default socket of the operating system, and when that socket is missing the run stops after it has stopped the appliance. Only `install-local-mariadb-uds.bash` accepts `--socket`; the SQLite and TCP installers stop with `--socket requires MariaDB UDS`.

   For a MariaDB appliance, add `--existing-db` to the plan command to keep the existing accounts. `DB_USER_PASS` must match the password of the existing application account. Add the flag again in step 3, so that the run does what the plan shows.

   The plan states, before it changes any installed file, that the installer stops `epicsarchiverap-maven.service` and requires it to be inactive.

2. Optional: decide how the installer handles Tomcat and its questions.

   Read the Tomcat lines of the plan in step 1. When the checkout owner cannot execute an existing Tomcat, the plan prints a choice. Add `--tomcat existing` to the command to use the existing Tomcat after checking access as the service user. Add `--tomcat replace` to back it up and install the configured version. The option `--tomcat replace` downloads and checks the configured version first, then stops the appliance and its health monitor and moves the existing folder to `/opt/tomcat9.backup.<random>/tomcat`; the installer prints that path as `Tomcat backup: <directory>/tomcat`.

   Add `-y` to skip the two questions of the installer. In the Tomcat case, a run with `-y` and without `--tomcat` stops with `Select --tomcat existing or --tomcat replace for unattended installation`.

   The command of step 1 has `--skip-packages`, which uses the packages of the host. Remove it when the installer is to install the packages.

3. Run the installer without `--plan`, with the same options as in steps 1 and 2. Answer the questions that it asks.

   The installer builds the web application archive (WAR) files, stops the service and the health monitor, replaces the payload under `AA_INSTALL_LOCATION`, installs the generated configuration and the systemd files, and starts the service again.

   The installer asks two questions before it changes anything. The first offers the optional soft IOC test: `Run the PV acquisition/storage/retrieval test after installation? [y/N]`. The default is `N`. The second asks for a confirmation: `Install packages, build, prepare the database, replace the appliance and start it? [y/N]`. The option `-y` skips both questions. A run without a terminal and without `-y` stops with `Non-interactive stdin; use --yes`. Answer `y` to the confirmation.

   When you answer `y` to the first question, the installer runs the soft IOC test after the installation and asks one more question when the test passes: `Select [1/2]:`. The answer `1`, an empty answer or the end of the input stops the soft IOC and leaves the test PV paused. The answer `2` resumes the test PV and keeps the soft IOC running. The installer waits for this answer.

   Later, when the checkout owner cannot execute the existing Tomcat and you gave no `--tomcat`, the installer asks `Tomcat choice [1/2; anything else cancels]:`. Answer `1` to use the existing Tomcat, or `2` to back it up and install the configured version, which stops the appliance.

   The appliance keeps running during the build. It is stopped from `appliance stop` until the end of `startup verification`. The stop takes up to 300 seconds (`SYSTEMD_TIMEOUT_STOP_SECONDS`), the `chown -R` of the storage folders counts as downtime, and the start waits up to 180 seconds.

   The installer runs these stages in order: `prerequisites`, `source selection`, `Tomcat preparation`, `configuration and build`, `appliance stop`, `database and installation` and `startup verification`. A failure message names the stage, except in `startup verification`, where the installer prints `Appliance files are installed. Verification failed (exit <status>)`, and except a check that fails before the installer has locked the checkout (an unsupported host, an invalid `configure/CONFIG_SITE.local`, changes in the source checkout, a missing answer or another running installer), which prints only `ERROR: <message>`, and except a failing `sudo -v`, which prints only the message of `sudo`; both leave the host unchanged. When the startup check fails, it also prints the readiness block that [The readiness block of the installer](../operate/health-results.md#the-readiness-block-of-the-installer) explains.

   A failure before `appliance stop` leaves the old appliance running. `--tomcat replace` stops the appliance and the health monitor earlier, in `Tomcat preparation`, after the download and the checksum check; a failure before that point leaves the appliance running. A failure in `appliance stop` leaves the health monitor running: `Appliance is not stopped: <state>` names the state of the service, and after a failing `systemctl stop` the command `systemctl is-active "$(make -s print-SYSTEMD_FILENAME)"` prints it. A failure in `database and installation` leaves the service stopped and, unless its first command `sd_health_stop` failed, the health monitor stopped, and the instances possibly partly replaced, so do not start the service before a run succeeds. A failure in `startup verification`, which includes the start, leaves the installed files and the service as they are.

   When `--tomcat replace` fails after it has moved the folder, `/opt/tomcat9` is absent, partial or not usable by the service user. The first run prints the path of the original Tomcat on the line `Tomcat backup: <directory>/tomcat`; a second run with `--tomcat replace` moves a partial folder into a further backup, so keep the path of the first run.

   The installer does not roll back the run and does not restart the appliance. Correct the cause and run the installer again.

   An interrupt with Ctrl-C can end the run without the line `Installation stopped during <stage>`. Take the stage from the last `+ <command>` line that the installer printed and treat the interrupt as a failure of that stage: the package commands and `<os>.conf` belong to `prerequisites`; `init`, `git fetch` and `srcupdate` to `source selection`; the Tomcat commands to `Tomcat preparation`; `db.conf`, `conf.archapplproperties`, `build.mvn` and `conf.install` to `configuration and build`; `systemctl stop` to `appliance stop`; `sd_health_stop` and every later command up to `install` to `database and installation`; with `--tomcat replace`, the `systemctl stop` and `sd_health_stop` lines that come before the move of the Tomcat folder belong to `Tomcat preparation`, where nothing is replaced yet; `sd_start` to `startup verification`. An interrupt at one of the two questions at the start leaves the host unchanged.

## Verification

After the installer finishes, it prints `Installation completed. All required installation checks passed.` before the health result and the appliance information. The line `PV acquisition, storage and retrieval: NOT CHECKED` is expected; the test of [Archive a test PV and check the stored samples](verify-pv.md) checks the data path. The check in [Check the health of the appliance](../operate/health.md) repeats the health result later.
