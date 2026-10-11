# Install an appliance with MariaDB over TCP

This page installs a systemd-managed appliance whose configuration database is MariaDB, reached over TCP on the loopback address. The installer `scripts/install-local-mariadb-tcp.bash` builds the WAR files, prepares the database and its accounts, installs the appliance and starts it.

## Prerequisites

- A host prepared as in [Prepare the host for the appliance](prepare-host.md).
- An ordinary user that owns the checkout and may use `sudo`.
- The passwords of the database accounts, set in `CONFIG_SITE.local`: `DB_ADMIN_PASS` and `DB_USER_PASS`.
- `DB_HOST_NAME` set to `127.0.0.1`. The installer clears `DB_SOCKET` and uses `DB_HOST_PORT`, which is `3306` by default, and it prepares the administrative account at `127.0.0.1`.
- Local root socket authentication for MariaDB, unless `--existing-db` is used. The installer requires the port of the local server to match the TCP port before it prepares accounts.

## Steps

1. Print the steps of the installer. The command installs and starts nothing.

   ```bash
   bash scripts/install-local-mariadb-tcp.bash --plan --skip-packages
   ```

   The plan has the stages of the SQLite plan. These lines differ, with the repository path replaced by `<checkout>`:

   ```text
   Backend: mariadb
   MariaDB TCP: 127.0.0.1:3306
   Prepare DB/accounts: 1
   + sudo -- systemctl start mariadb.service
   Require the local root socket server port to match TCP port 3306 before preparing accounts.
   + env DB_BACKEND=mariadb bash <checkout>/scripts/mariadb_setup.bash hostnameAdminAdd
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=mariadb DB_SOCKET= db.create
   ```

2. Set the passwords and the TCP values in `CONFIG_SITE.local`, as in [Override a setting for one host](../configure/override-setting.md).

3. Install the appliance. Run the command of step 1 without `--plan`. The installer starts `mariadb.service`, prepares the accounts with `scripts/mariadb_setup.bash`, creates the database, loads the schema and installs the appliance.

4. Optional: add `--existing-db` when the accounts exist. The installer then skips the account preparation and only loads the schema.

## Verification

The installer waits up to 180 seconds for the process health, the four startup states and the `getApplianceInfo` call of `mgmt`, and then prints the health result and the appliance information.

Step 3 changes the host and was not run for this page; step 1 was run as shown.
