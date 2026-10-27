# Install an appliance with MariaDB over TCP

This page installs a systemd-managed appliance whose configuration database is MariaDB, reached over Transmission Control Protocol (TCP) on the loopback address. The installer `scripts/install-local-mariadb-tcp.bash` builds the web application archive (WAR) files, prepares the database and its accounts, installs the appliance and starts it. The [glossary](../appendix/glossary.md) explains the terms of this page.

## Prerequisites

- A host prepared as in [Prepare the host for the appliance](prepare-host.md).
- An ordinary user that owns the checkout and can use `sudo`. The installer authenticates `sudo` once at the start (`sudo -v`) and does not refresh it, so a later `sudo` asks for the password again once the timestamp has expired. An unattended run (`-y`, no terminal) needs `sudo` without a password prompt; otherwise it stops at the start, before any change.
- A host that runs systemd, with the JDK under `JAVA_HOME` and these commands: `make`, `git`, `realpath`, `bash`, `sudo`, `flock`, `curl`, `jq`, `unzip`, `sha512sum`, `systemctl` and `timeout`, plus `sqlite3` for the SQLite installer or `mysql` for the MariaDB installers. The installer stops with a message when one of these is missing. A host without Tomcat, or a run with `--tomcat replace`, also needs `wget`, which the installer does not check; the package list of [Prepare the host for the appliance](prepare-host.md) includes it.
- Optional: an exported `EPICS_BASE` with `softIoc` and `caget`, for the soft IOC test that the installer offers. Without it, the answer `y` to the test question stops the installer before it changes anything.
- What the installer changes on the host and the network access that it needs, as [Changes that the installer makes on the host](host-changes.md) lists them.
- The passwords of the database accounts, set in `../CONFIG_SITE.local`: `DB_ADMIN_PASS` for the administrative account and `DB_USER_PASS` for the application account. The defaults in `configure/CONFIG_SITE` are the fixed values `admin` and `archappl`, the same for every installation. A host that keeps them has a server-wide administrative account with a public password, so set your own. [Changes that the installer makes on the host](host-changes.md) says where the installer writes the passwords and who can read them.
- `DB_HOST_NAME` set to `127.0.0.1`, which is its default in `configure/CONFIG_SITE`. Write it without quotes when you set it in `../CONFIG_SITE.local`. The installer clears `DB_SOCKET` and uses `DB_HOST_PORT`, which is `3306` by default, and it prepares the administrative account at `127.0.0.1`.
- Local root socket authentication for MariaDB, unless `--existing-db` is used. The installer requires the port of the local server to match the TCP port before it prepares accounts.

## Steps

1. Print the steps of the installer. The option `--plan` installs and starts nothing, and `--skip-packages` uses the packages of the host.

   ```bash
   bash scripts/install-local-mariadb-tcp.bash --plan --skip-packages
   ```

   The plan has the stages of the SQLite plan, except for the database step: the SQLite plan runs `sql.update`, `sql.table.fill` and `sql.show` there, and this plan runs the lines below. These lines differ, with the repository path replaced by `<checkout>`:

   ```text
   Backend: mariadb
   MariaDB TCP: 127.0.0.1:3306
   Prepare DB/accounts: 1
   + sudo -- systemctl start mariadb.service
   Require the local root socket server port to match TCP port 3306 before preparing accounts.
   + env DB_BACKEND=mariadb bash <checkout>/scripts/mariadb_setup.bash hostnameAdminAdd
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=mariadb DB_SOCKET= db.create
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=mariadb DB_SOCKET= sql.fill
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=mariadb DB_SOCKET= sql.show
   + sudo -- make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=mariadb DB_SOCKET= src_preinst
   ```

2. Optional: when the database and its accounts exist, add `--existing-db` to the command of step 1, and add it again to the run in step 5.

   Without the flag, the installer gives the existing administrative and application accounts the configured passwords. It also gives the administrative account `GRANT ALL ON *.* ... WITH GRANT OPTION`, which holds for the whole MariaDB server.

   With the flag, the plan shows `Prepare DB/accounts: 0` and no account lines. The installer skips the database and account preparation; it still starts `mariadb.service` and loads the schema. `DB_USER_PASS` must match the password of the existing application account.

3. Set the passwords and the TCP values in `../CONFIG_SITE.local`, as in [Override a setting for one host](../configure/override-setting.md). Run the command of step 1 again after the edit, so that the plan shows these values.

4. Optional: decide how the installer handles Tomcat and its questions.

   Read the Tomcat lines of the plan in step 1. When the checkout owner cannot execute an existing Tomcat, the plan prints a choice. Add `--tomcat existing` to the command to use the existing Tomcat after checking access as the service user. Add `--tomcat replace` to back it up and install the configured version. The option `--tomcat replace` downloads and checks the configured version first, then stops the appliance and its health monitor and moves the existing folder to `/opt/tomcat9.backup.<random>/tomcat`; the installer prints that path as `Tomcat backup: <directory>/tomcat`.

   Add `-y` to skip the two questions of the installer. In the Tomcat case, a run with `-y` and without `--tomcat` stops with `Select --tomcat existing or --tomcat replace for unattended installation`.

   The command of step 1 has `--skip-packages`, which uses the packages of the host. Remove it when the installer is to install the packages.

5. Install the appliance. Run the command of step 1 without `--plan`, with the options that you chose in steps 2 and 4.

   The installer asks two questions before it changes anything. The first offers the optional soft IOC test: `Run the PV acquisition/storage/retrieval test after installation? [y/N]`. The default is `N`. The second asks for a confirmation: `Install packages, build, prepare the database, replace the appliance and start it? [y/N]`. The option `-y` skips both questions. A run without a terminal and without `-y` stops with `Non-interactive stdin; use --yes`.

   The installer starts `mariadb.service`. Without `--existing-db`, it prepares the accounts with `scripts/mariadb_setup.bash` and creates the database. The administrative account `DB_ADMIN` receives `GRANT ALL ON *.* ... WITH GRANT OPTION` at `DB_HOST_NAME`, which holds for the whole MariaDB server. The application account is `DB_USER`. In every case the installer loads the schema and installs the appliance.

   When a step fails, the installer prints `Installation stopped during <stage> (exit <status>)` with the failed stage. A check that fails before the installer has locked the checkout (an unsupported host, changes in the source checkout, a missing answer or another running installer) prints only `ERROR: <message>`, and a failing `sudo -v` prints only the message of `sudo`; both leave the host unchanged. On a host that already has an appliance, a failure in `database and installation` (for example a failed start of `mariadb.service` or a schema load with a password that the existing application account refuses) leaves the service stopped and, unless `sd_health_stop` itself failed, the health monitor stopped; [Reinstall or upgrade an appliance](reinstall.md) lists the state that each stage leaves and what an interrupt with Ctrl-C leaves. When the start or the startup check fails, it prints `Appliance files are installed. Verification failed (exit <status>)` instead. When the startup check fails, it also prints the readiness block with the last results, which [The readiness block of the installer](../operate/health-results.md#the-readiness-block-of-the-installer) explains. In both cases the installer keeps the data and the build files. It does not roll back the run and does not restart the appliance. Correct the cause and run the installer again.

## Verification

The installer ends with the health result and the appliance information, as [Check the health of the appliance](../operate/health.md) describes. Before the health result it prints `Installation completed. All required installation checks passed.` The readiness block ends with `PV acquisition, storage and retrieval: NOT CHECKED`, which is expected until you run the test of [Archive a test PV and check the stored samples](verify-pv.md). When you did not choose the soft IOC test, one more line says so: `Optional PV verification was not selected before installation; PV acquisition, storage and retrieval remain NOT CHECKED.` The database objects exist when the `sql.show` step before the installation lists the tables of the configured database (`DB_NAME`).
