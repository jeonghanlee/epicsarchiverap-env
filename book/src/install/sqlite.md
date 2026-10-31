# Install an appliance with SQLite

This page installs a systemd-managed appliance whose configuration database is a SQLite file. The installer `scripts/install-local-sqlite.bash` builds the web application archive (WAR) files from the source that `SRC_TAG` selects, installs them and starts the appliance. The [glossary](../appendix/glossary.md) explains the terms of this page.

## Prerequisites

- A host that runs a supported operating system, with the packages that the installer needs. Run the installer without `--skip-packages` to install them, or prepare the host as in [Prepare the host for the appliance](prepare-host.md), which also installs the MariaDB packages.
- An ordinary user that owns the checkout and that can use `sudo`; the installer runs privileged steps with `sudo` itself. It authenticates `sudo` once at the start (`sudo -v`) and does not refresh it, so a later `sudo` asks for the password again once the timestamp has expired. An unattended run (`-y`, no terminal) needs `sudo` without a password prompt; otherwise it stops at the start, before any change.
- `configure/CONFIG_SITE.local` absent, or holding only the generated line `include $(TOP)/configure/os/<preset>.mk` of a shipped preset. Before any `make` step, `sudo` or package change, also with `--plan`, the installer checks the file and stops with status 1 when it holds anything else, such as an extra assignment, a comment, a blank line, a second include, a Make expression, altered whitespace or CRLF line ends, when it is empty or a symbolic link, or when it is not a readable regular file. The message names the file, the reason and the offending line numbers, never the contents. Keep site settings in `../CONFIG_SITE.local`. To recover, move the settings there first, then delete `configure/CONFIG_SITE.local`; the installer writes the generated line again. Running `make <os>.conf` before the move overwrites the settings.
- A host that runs systemd, with the JDK under `JAVA_HOME` and these commands: `make`, `git`, `realpath`, `bash`, `sudo`, `flock`, `curl`, `jq`, `unzip`, `sha512sum`, `systemctl` and `timeout`, plus `sqlite3`, `lsof`, and `runuser` for the SQLite installer or `mysql` for the MariaDB installers. The installer stops with a message when one of these is missing. A host without Tomcat, or a run with `--tomcat replace`, also needs `wget`, which the installer does not check; the package list of [Prepare the host for the appliance](prepare-host.md) includes it.
- What the installer changes on the host and the network access that it needs, as [Changes that the installer makes on the host](host-changes.md) lists them.
- Source inputs without local changes. The generated site folder (`ARCHAPPL_SITEID`; the installers pass `als` to every make step) and ignored build outputs are allowed.
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
   Source pin: 2026-10
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
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite conf.install
   If installed, stop epicsarchiverap-maven.service and require it to be inactive before changing installed files.
   + sudo -- make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite sd_health_stop
   + make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite sql.update
   + sudo -- make --no-print-directory -C <checkout> ARCHAPPL_SITEID=als DB_BACKEND=sqlite sql.table.fill
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

2. Optional: set the storage, Tomcat and service-account values for this host in `../CONFIG_SITE.local`, as in [Override a setting for one host](../configure/override-setting.md). Do this before the installation, because the installer reads the values then. Run the command of step 1 again after the edit, so that the plan shows these values.

3. Optional: decide how the installer handles Tomcat and its questions.

   Read the Tomcat lines of the plan in step 1. When the checkout owner cannot execute an existing Tomcat, the plan prints a choice. Add `--tomcat existing` to the command to use the existing Tomcat after checking access as the service user. Add `--tomcat replace` to back it up and install the configured version. The option `--tomcat replace` downloads and checks the configured version first, then stops the appliance and its health monitor and moves the existing folder to `/opt/tomcat9.backup.<random>/tomcat`; the installer prints that path as `Tomcat backup: <directory>/tomcat`.

   Add `-y` to skip the two questions of the installer. In the Tomcat case, a run with `-y` and without `--tomcat` stops with `Select --tomcat existing or --tomcat replace for unattended installation`.

   The command of step 1 has `--skip-packages`, which uses the packages of the host. Remove it when the installer is to install the packages.

4. Install the appliance. Run the command of step 1 without `--plan`, with the options that you chose in step 3.

   The installer asks two questions before it changes anything. The first offers the optional soft IOC test: `Run the PV acquisition/storage/retrieval test after installation? [y/N]`. The default is `N`. The second asks for a confirmation: `Install packages, build, prepare the database, replace the appliance and start it? [y/N]`. The option `-y` skips both questions. A run without a terminal and without `-y` stops with `Non-interactive stdin; use --yes`.

   When you answer `y` to the first question, the installer runs the soft IOC test after the installation and asks one more question when the test passes: `Select [1/2]:`. The answer `1`, an empty answer or the end of the input stops the soft IOC and leaves the test PV paused. The answer `2` resumes the test PV and keeps the soft IOC running. The installer waits for this answer.

5. Wait for the installer to finish. It waits up to 180 seconds for the process health, the four startup states and the `getApplianceInfo` call of `mgmt`, and then shows the management page address, the four component addresses, the health result and the appliance information.

   When a step fails, the installer prints `Installation stopped during <stage> (exit <status>)` with the failed stage. A check that fails before the installer has locked the checkout (an unsupported host, changes in the source checkout, a missing answer or another running installer) prints only `ERROR: <message>`, and a failing `sudo -v` prints only the message of `sudo`; both leave the host unchanged. On a host that already has an appliance, a failure in `database and installation` leaves the service stopped and, unless `sd_health_stop` itself failed, the health monitor stopped; [Reinstall or upgrade an appliance](reinstall.md) lists the state that each stage leaves and what an interrupt with Ctrl-C leaves. When the start or the startup check fails, it prints `Appliance files are installed. Verification failed (exit <status>)` instead. When the startup check fails, it also prints the readiness block with the last results, which [The readiness block of the installer](../operate/health-results.md#the-readiness-block-of-the-installer) explains. In both cases the installer keeps the data and the build files. It does not roll back the run and does not restart the appliance. Correct the cause and run the installer again.

## Verification

The installer ends with the health result and the appliance information, as [Check the health of the appliance](../operate/health.md) describes. Before the health result it prints `Installation completed. All required installation checks passed.` The readiness block ends with `PV acquisition, storage and retrieval: NOT CHECKED`, which is expected until you run the test of [Archive a test PV and check the stored samples](verify-pv.md). When you did not choose the soft IOC test, one more line says so: `Optional PV verification was not selected before installation; PV acquisition, storage and retrieval remain NOT CHECKED.` A successful installation leaves the appliance running under systemd as `epicsarchiverap-maven.service`.
