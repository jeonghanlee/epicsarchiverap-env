# Reinstall or upgrade an appliance

A reinstall replaces the installed payload of an appliance with the payload built from the current checkout. The same installer that performs the first installation performs the reinstall, and an upgrade is a reinstall after the source pin or the site inputs change.

## Prerequisites

- An installed appliance managed by `epicsarchiverap-maven.service`.
- A checkout in which the source commit (`SRC_TAG`) and the site inputs are the ones to install, and in which the source inputs have no local changes.
- A decision about the database: the installer keeps the database contents and the stores.

## Steps

1. Print the steps that the installer will perform, with the installer that matches the database backend of the appliance.

   ```bash
   bash scripts/install-local-sqlite.bash --plan --skip-packages
   ```

   The plan states, before it changes any installed file, that the installer stops `epicsarchiverap-maven.service` and requires it to be inactive.

2. Run the installer without `--plan`. The installer builds the WAR files, stops the health monitor and the service, replaces the payload under `AA_INSTALL_LOCATION`, installs the generated configuration and the systemd files, and starts the service again.

3. When the existing Tomcat cannot be executed by the checkout owner, choose its handling with `--tomcat existing` or `--tomcat replace`. The second choice backs up the existing Tomcat and installs the configured version, which stops the appliance.

## What the reinstall keeps

The installer replaces the appliance payloads. Database contents and stores remain: the SQLite file or the MariaDB database, and the three store folders under `ARCHAPPL_STORAGE_TOP`.

## Verification

After the installer finishes, it prints the health result and the appliance information. The check in [Check the health of the appliance](../operate/health.md) repeats the health result later.

Step 2 changes the host and was not run for this page; step 1 was run as shown.
