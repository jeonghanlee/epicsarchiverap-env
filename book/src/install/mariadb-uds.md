# Install an appliance with MariaDB over a Unix socket

This page installs a systemd-managed appliance whose configuration database is MariaDB, reached through a Unix domain socket. The installer `scripts/install-local-mariadb-uds.bash` builds the WAR files, prepares the database and its accounts, installs the appliance and starts it.

## Prerequisites

- A host prepared as in [Prepare the host for the appliance](prepare-host.md); the package list includes `mariadb-server`.
- An ordinary user that owns the checkout and may use `sudo`.
- The passwords of the database accounts, set in `CONFIG_SITE.local`: `DB_ADMIN_PASS` for the administrative account and `DB_USER_PASS` for the application account. The defaults in `configure/CONFIG_SITE` are fixed values of the repository; set your own.
- The service account (`tomcat` by default) must be able to read and write the socket. The installer checks this with `sudo -n -u tomcat test -S` and `test -w`.

## Steps

1. Print the steps of the installer. The command installs and starts nothing.

   ```bash
   bash scripts/install-local-mariadb-uds.bash --plan --skip-packages
   ```

   The plan has the same stages as the plan of the SQLite installer. These lines differ, shown here with the repository path replaced by `<checkout>`:

   ```text
   Backend: mariadb
   MariaDB socket: /run/mysqld/mysqld.sock
   Prepare DB/accounts: 1
   + sudo -- systemctl start mariadb.service
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=mariadb DB_SOCKET=/run/mysqld/mysqld.sock db.addAdmin
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=mariadb DB_SOCKET=/run/mysqld/mysqld.sock db.create
   + sudo -n -u tomcat -- test -S /run/mysqld/mysqld.sock
   + sudo -n -u tomcat -- test -w /run/mysqld/mysqld.sock
   ```

   The socket path is `--socket <path>`, or `DB_SOCKET`, or the default of the operating system; `/run/mysqld/mysqld.sock` on Debian 13.

2. Set the passwords and, when the socket is not at the default path, `DB_SOCKET` in `CONFIG_SITE.local`, as in [Override a setting for one host](../configure/override-setting.md).

3. Install the appliance. Run the command of step 1 without `--plan`. The installer starts `mariadb.service`, creates or updates the configured database and accounts, and loads the schema. Existing administrative and application accounts receive the configured passwords and grants.

4. Optional: when the database and its accounts exist, add `--existing-db`. The installer then skips the account preparation and only loads the schema. `DB_USER_PASS` must match the password of the existing application account.

## Verification

The installer waits up to 180 seconds for the process health, the four startup states and the `getApplianceInfo` call of `mgmt`, and then prints the health result and the appliance information. The database objects exist when `sql.show`, the step before the installation, lists the tables of the configured database (`DB_NAME`).

Step 3 changes the host and was not run for this page; step 1 was run as shown.
