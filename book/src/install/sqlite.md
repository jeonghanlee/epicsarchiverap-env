# Install an appliance with SQLite

This page installs a systemd-managed appliance whose configuration database is a SQLite file. The installer `scripts/install-local-sqlite.bash` builds the web application archive (WAR) files from the source that `SRC_TAG` selects, installs them and starts the appliance.

## Prerequisites

- A host that runs a supported operating system, prepared as in [Prepare the host for the appliance](prepare-host.md).
- An ordinary user that owns the checkout and that can use `sudo`; the installer runs privileged steps with `sudo` itself.
- Source inputs without local changes. The generated `als` site and ignored build outputs are allowed.
- Optional: an exported `EPICS_BASE` with `softIoc` and `caget`, for the soft input/output controller (IOC) test that the installer offers before the installation.

## Steps

1. Print the steps that the installer would perform. The option `--plan` installs and starts nothing, and `--skip-packages` uses the packages of the host.

   ```bash
   bash scripts/install-local-sqlite.bash --plan --skip-packages
   ```

   On Debian 13 the output is the following, with the path of the repository replaced by `<checkout>`:

   ```text
   Before installation, offer the optional soft IOC test and validate exported EPICS_BASE, softIoc and caget.
   Repository: <checkout>
   OS: debian13
   Source pin: origin/modernize
   Install: /opt/epicsarchiverap-maven
   Backend: sqlite
   SQLite: /arch/config/archappl.sqlite
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite debian13.conf
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite init
   + git -C <checkout>/epicsarchiverap-maven-src fetch origin
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite srcupdate
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite db.conf
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite conf.archapplproperties
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite build.mvn
   If installed, stop epicsarchiverap-maven.service and require it to be inactive before changing installed files.
   + sudo -- make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite sd_health_stop
   + sudo -- make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite sql.fill
   + sudo -- make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite sql.show
   + sudo -- make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite conf.storage
   + sudo -- make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite install
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite sd_start
   Wait up to 180 seconds for process health, four startup states and http://localhost:17665/mgmt/bpl/getApplianceInfo
   Show the management UI, four component URLs, health result and appliance information.
   Run the soft IOC PV registration/storage/CSV test if selected before installation; unattended mode skips it.
   ```

   The repository path and the operating system in your output are those of your host, and the source pin is the value of `SRC_TAG`. If a Tomcat that the checkout owner cannot execute is installed, the plan also prints the two choices described in step 3.

   On a host without Tomcat, the plan lists the download and the installation of Tomcat after the `srcupdate` line:

   ```text
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite tomcat.get
   Verify the downloaded Tomcat archive against its Apache SHA-512 before extraction.
   + sudo -- make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite tomcat.install
   ```

2. Optional: set the storage, Tomcat and service-account values for this host in `CONFIG_SITE.local`, as in [Override a setting for one host](../configure/override-setting.md). Do this before the installation, because the installer reads the values then.

3. Install the appliance. Run the command of step 1 without `--plan`. When an existing Tomcat is found, `--tomcat existing` uses it as the service user and `--tomcat replace` backs it up and installs the configured version. The option `-y` skips the confirmation.

4. Wait for the installer to finish. It waits up to 180 seconds for the process health, the four startup states and the `getApplianceInfo` call of `mgmt`, and then shows the management page address, the four component addresses, the health result and the appliance information.

   When a step fails, the installer prints `Installation stopped during <stage> (exit <status>)`, with the failed stage and its exit status, keeps the data and the build files, and neither rolls back nor starts the service again. Correct the cause and run the installer again.

## Verification

The installer ends with the health result and the appliance information, as [Check the health of the appliance](../operate/health.md) describes. A successful installation leaves the appliance running under systemd as `epicsarchiverap-maven.service`.
