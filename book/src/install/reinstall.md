# Reinstall or upgrade an appliance

A reinstall replaces the installed payload of an appliance with the payload built from the current checkout. The same installer that performs the first installation performs the reinstall, and an upgrade is a reinstall after the selected source or the site inputs change. The installer fetches the source repository and builds the commit that `SRC_TAG` names; the default, `origin/modernize`, is the tip of the source branch on the day of the reinstall. To install the same source again, set `SRC_TAG` to its commit hash first, as in [Select the source commit to build](../build/select-commit.md).

## Prerequisites

- An installed appliance managed by `epicsarchiverap-maven.service`.
- A checkout in which the source commit (`SRC_TAG`) and the site inputs are the ones to install, and in which the source inputs have no local changes.
- A decision about the database: the installer replaces the appliance payloads and keeps the database contents and the stores, that is the SQLite file or the MariaDB database and the three store folders under `ARCHAPPL_STORAGE_TOP`.

## Steps

1. Print the steps that the installer will perform, with the installer that matches the database backend of the appliance.

   ```bash
   bash scripts/install-local-sqlite.bash --plan --skip-packages
   ```

   The plan states, before it changes any installed file, that the installer stops `epicsarchiverap-maven.service` and requires it to be inactive.

2. Run the installer without `--plan`. The installer builds the web application archive (WAR) files, stops the health monitor and the service, replaces the payload under `AA_INSTALL_LOCATION`, installs the generated configuration and the systemd files, and starts the service again.

3. When the existing Tomcat cannot be executed by the checkout owner, choose its handling with `--tomcat existing` or `--tomcat replace`. The second choice backs up the existing Tomcat and installs the configured version, which stops the appliance.

## Verification

After the installer finishes, it prints the health result and the appliance information. The check in [Check the health of the appliance](../operate/health.md) repeats the health result later.
