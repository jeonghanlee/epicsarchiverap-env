# Changelog

All notable changes to this project are documented here. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
The source repository's POM defines build artifact names; this changelog records
changes to the environment repository.

## [2.0.1] - unreleased

Upgrading from 2.0.0: the order of the steps (move the source, build, render the units, stop, install, start, check) is in "Reinstall and upgrade" in `docs/README.install.md#reinstall-and-upgrade`. The installer scripts of "Local systemd installation" in the same file, `scripts/install-local-sqlite.bash`, `install-local-mariadb-uds.bash` and `install-local-mariadb-tcp.bash`, do the same steps for your database backend. For a site that already has its database and accounts, add `--existing-db` to a MariaDB script: without it the script creates a missing `DB_ADMIN` account with `GRANT ALL ON *.* ... WITH GRANT OPTION` and gives an existing account of the same user and host the configured password, which defaults to the public values `admin` and `archappl` unless `../CONFIG_SITE.local` sets `DB_ADMIN_PASS` and `DB_USER_PASS`; with the flag the application account must exist and accept `DB_USER_PASS` over the transport, or the schema step fails after the appliance was stopped. For an unattended run (`--yes`) configure `sudo` without a password prompt. The scripts always use `ARCHAPPL_SITEID=als` and do not remember `--socket`; the guide gives the details. What changes for a 2.0.0 site:
- Update this repository to the 2.0.1 release first (`git fetch`, then check out the tag `2.0.1`): the installer scripts, `make conf.install` and the default `SRC_TAG` belong to it. A site that edited `SRC_TAG` in the tracked file `configure/RELEASE`, as the README of 2.0.0 said, moves that value to `configure/RELEASE.local` or `../RELEASE.local` and restores the tracked file (`git restore configure/RELEASE`) before the checkout, which stops on the local change otherwise.
- Configuration: leave `SRC_TAG` at the default tag `2026-10`, or set another tag or a commit hash, and remove a `SRC_TAG` that names the branch `modernize` (`origin/modernize` or `modernize`) from `configure/RELEASE.local` and `../RELEASE.local`, because that branch no longer exists. Remove `ARCHAPPL_SAMPLE_BUFFER_CAPACITY_ADJUSTMENT`, `DB_BACKUP_PATH` and the `ANT_*` variables from `../CONFIG_SITE.local`: they have no effect.
- A site folder of your own: delete `css/main.css` or start it again from the file of the source, replace the sections of `template_changes.html` by one `site_logo` block that holds the logo link and the favicon of the old `site_header`, and remove `css/mgmt.css` and `build.xml`.
- Installation: build first (`make db.conf`, `make conf.archapplproperties` and `make build.mvn` after `git -C epicsarchiverap-maven-src fetch origin` and `make srcupdate`; without `make conf.archapplproperties` the installed `appliances.xml`, `archappl.properties`, `policies.py`, `context.xml` and `archappl.conf` keep their old content, and without the build `make install` installs the old WARs from `target` without an error), then run `make conf.install` as the checkout owner after the last edit of the configuration and before `sudo make install`. Without it `sudo make install` stops with exit status 2 before it changes anything and names `make conf.install`.
- Scripts: replace `tests/run-all-tests.bash --phase=3`, `--phase=4`, `--system`, `all` and a call without an argument with `--local` (which, like `--phase=1`, now also runs `tests/ui-static.bash` on the site folder and on the interface files of the source clone, so an old `template_changes.html` or `css/main.css` fails it); re-check scripts that read the exit status of `archappl.bash status`, `archappl.bash storage` or `make sd_health_status`, and allow `du` in the sudoers rule for `archappl.bash storage`.

### Added
- Local systemd installers for SQLite, MariaDB over UDS (Unix domain socket), and MariaDB over TCP, sharing one driver with `--plan`, which lists the steps without running them, configurable startup verification, and `--existing-db` (MariaDB installers only), which skips the provisioning of the database and the MariaDB accounts; the script still starts `mariadb.service` and loads the schema. See the local installation procedure in `docs/README.install.md#local-systemd-installation`.
- An optional soft IOC test in the installers (`scripts/verify-local-pv.bash`, `scripts/verify-local-pv-curl.bash`): an interactive run asks, before the confirmation question, whether to start one changing soft IOC PV after the installation, register it and compare the stored samples with the values observed over Channel Access. The test needs an exported `EPICS_BASE` with `softIoc` and `caget`, is skipped with `--yes` or without a terminal, and its failure leaves the exit status of a completed installation at 0. `scripts/README.md` describes the test and the other scripts.
- Installation targets Rocky Linux 10.2, Ubuntu 24.04 and Ubuntu 26.04 besides Debian 13 and Rocky Linux 8: the presets and package lists `configure/os/rocky10`, `ubuntu24` and `ubuntu26` with the targets `make rocky10.conf`, `make ubuntu24.conf` and `make ubuntu26.conf`, and `jq` in every package list.
- `ARCHAPPL_HEALTH_STARTING_SECONDS` (default 10, valid 1 to 59) bounds how long `archappl.bash health` reports an instance as starting; a value outside that range makes `health` print `ERROR starting-invalid-bound` and end with the error status 2, so the scheduled check fails until the value is corrected. A site sets it in `../CONFIG_SITE.local`, and the installer writes it into `archappl.conf`.
- `ARCHAPPL_SAMPLE_BUFFER_MARGIN_SECONDS` (default 1.0; the engine raises a lower value to 1.0) is written to `archappl.properties` as `org.epics.archiverappliance.config.PVTypeInfo.sampleBufferMarginSeconds`, the seconds of write delay a sample buffer absorbs, and the remedy texts of the Operations page name it.
- The management interface rework (developed in this repository and now part of the source repository jeonghanlee/epicsarchiverap-maven): a Browse PVs page that finds PVs (search words, glob, regular expression, the server reports as selections) and keeps the name list as a browser snapshot that follows the appliance every 15 s.
- On the Browse PVs page, up to 100 selected PVs are scanned as sparkline rows, up to 5 PVs of one unit are charted with D3, a window can be zoomed and panned, and the state of a PV is shown with its explanation and the actions that apply.
- Links from the Browse PVs page to the data viewer for the selected PVs and the focused PV over the window of the chart. The page reads the state of the rows in view of the name list in one call.
- Maintenance of a PV from the page: change of sampling, rename, change of type and consolidation, each pausing the PV first and saying what it changes; pause, resume and stop for several selected PVs; pause of a disconnected host group.
- System pages for everyone and for the operator: Overview with three verdict lines and a meaning for every measure, Operations with the questions, thresholds and remedies of samples, dropped samples, write path, stores, ETL and processes, Retrieval performance with a request measured in the browser, and External servers, which replaces the Integration page (`integration.html` forwards to `external.html`); disconnected PVs are grouped by host and time of loss.
- `docs/README.install.md` documents the site folder inputs (`img/`, `css/main.css`, `template_changes.html`, `classpathfiles/`) and the variables `ARCHAPPL_SITEID` and `ARCHAPPL_SITEID_TEMPATE_PATH` (spelled as in the configuration).
- An mdBook of the appliance in `book/`, written from the code and from commands run: concepts, install and operate procedures, reference pages that `book/scripts/gen-*.bash` print from the code, and a glossary. `mdbook build book` renders it to `book/site/`.
- `docs/README.interface.md` points to the description of the management interface in the source repository and names what this repository keeps: the site skin and the static checks.
- VM acceptance driver `tests/vm/` behind `tests/run-all-tests.bash` (`--init`, `--case`, `--verify-cleanup`, `--verdict`): it composes the companion projects jeonghanlee/cloud-provision (fresh guests) and jeonghanlee/ansible-provision (prerequisites and the ordered installation) and checks Debian 13 and Rocky Linux 8.10 with MariaDB over a socket, MariaDB over TCP and SQLite, plus two real build-failure cases, each on its own guest. The driver passes cloud-provision the species (the kind of guest, one for each database transport) `archiver-dev-uds`, `archiver-dev-tcp` or `archiver-dev-sqlite` and ansible-provision the playbooks `archiver_dev_uds`, `archiver_dev_tcp` or `archiver_dev_sqlite`. The driver is a maintainer test aid; an installation does not need it. The design is in `docs/README.vmtests.md`.
- The verifier that the driver runs on each guest (`tests/vm/guest.py`) checks the installed payload against the WARs, the four JVM identities, three scheduled health runs, archiving and retrieval of a changing PV, and survival of a restart, a repeat apply and a forced reinstall. It compares the files of the site folder `img/` with the copies in the `mgmt` and `retrieval` WARs, which are the only WARs that carry the site images (the `engine` and `etl` WARs carry only `ui/comm/version.txt` of the shared static content), and the sections of `template_changes.html` with the pages of the `mgmt` WAR. Right after a start it retries the health check while the output shows an unfinished start (`STARTING`, `wrong-java-executable`, a missing pid file, a missing or dead process), fails when that persists beyond its readiness deadline, and keeps the retried outputs (at most 100, each cut to 600 characters) with their elapsed time. The build-failure cases recognize the messages that git prints for an absent commit, among them `unable to read tree` of git 2.47 on Debian 13 and `reference is not a tree`.
- Failure evidence of the verifier: a failed health check keeps the health unit entries and a copy of the journal files; a failed channel access data check keeps the engine JVM's UDP sockets and the management view of the test PV and the disconnected PVs.
- `tests/health-starting.bash` runs the shipped `run.sh` and `archappl.bash` under the real health check with a stand-in `catalina.sh` that holds and then runs a live JVM named like the Tomcat start class, because the test host has no Tomcat. `tests/no-ant.bash` checks that the site folder holds no `build.xml`, that `configure/` sets none of `ANT_HOME`, `ANT_PATH`, `ANT_CMD` and `ANT_OPTS`, that the README does not say that Ant is used, and, as the Changed list says, that the targets `build.mvn`, `build.mvn2`, `build.mvn3`, `build.war`, `build.mvndeps` and `clean.mvn` pass the site id.
- `tests/ui-static.bash`, run by `tests/phase1-logic.bash` against the interface files of the selected source (`tests/ui-files.list`): marker blocks, content security policy, no inline code, outside host, jQuery or text turned into markup, referenced files, element ids and text contrast, each with a broken copy that must be refused.

### Changed
- `make install` installs what `make conf.install` rendered and no longer renders the systemd units itself; its first step, the target `install.rendered`, checks the four units. A site that ran only `sudo make install` on 2.0.0 runs `make conf.install` as the checkout owner first; without it `make install` stops with exit status 2 and names that target before it stops the health monitor or changes the payload, and it stops the same way when a unit is older than its template or than a file of the configuration (`configure/CONFIG*`, `configure/RELEASE*`, `../CONFIG_SITE.local`, `../RELEASE.local`). The targets `install.systemd`, `install.systemd0`, `install.override` and `install.health.service` and `.timer` no longer render a unit either and stop the same way. `make conf.install` also writes `site-template/.versions`, which `make install` no longer rewrites. `make sql.table.fill` likewise needs `make sql.update` first. The order is in `docs/README.install.md`.
- `archappl.bash startup` prints a warning on stderr when a pid file names a process that is still running, before it removes the file.
- `SUDOBASH` omits `sudo -E` when `sudo` is not installed, so the recipes that use it run as the current user.
- `ARCHAPPL_SAMPLE_BUFFER_MARGIN_SECONDS` replaces `ARCHAPPL_SAMPLE_BUFFER_CAPACITY_ADJUSTMENT`, a multiplier of the buffer capacity that nothing reads any more, so a value of that variable in `../CONFIG_SITE.local` has no effect; the source commit `6c6b973a` of jeonghanlee/epicsarchiverap-maven that reads the key is contained in the tag `2026-10` that `SRC_TAG` names.
- The management pages are rebuilt without jQuery and with a content security policy on every full page; `metrics.html`, `storage.html`, `appliance.html`, `reports.html`, `pvdetails.html` and `cacompare.html` forward to the page that replaced them.
- The site folder keeps only the files that carry the site's own values: `template_changes.html` fills the `site_logo` block of the header, and `img/` holds `LBNLLogo.png` and `als.ico`. The stylesheet, the header logo, its narrow-screen wordmark and the menu come from the source, so the shipped site folder holds no `css/main.css`.
- A `css/main.css` that a 2.0.0 site kept in its own site folder still overwrites the whole shared stylesheet of the source, the rules of the menu and of the logo sizes included: delete it, or start again from the file of the source.
- The site folder follows the contract of the source: only `img/`, `css/main.css`, `template_changes.html` and `classpathfiles/` are applied, and a `css/mgmt.css` of a site is reported as not applied.
- `ARCHAPPL_VERSION`, `SRC_VERSION` and `JAVA_CMD` are read by no file, so a site value has no effect.
- `configure/os/rocky8.mk` keeps a custom `JAVA_HOME` and no longer sets `JAVA_PATH`; `JAVA_PATH` follows `JAVA_HOME` in `configure/CONFIG_SITE`.
- `tests/run-all-tests.bash --phase=3`, `--phase=4`, `--system`, `all` and a call without an argument (the default mode `all`) no longer run the phase scripts of 2.0.0: they print `INCOMPLETE: VM verification runs as explicit operations; no system action ran.` and exit with status 77. VM verification runs through the operations of `tests/vm/driver.py`. A script that used these modes for the local checks runs `--local`, `--phase=1` or `--phase=2` instead, and a local mode that gets extra arguments exits with status 2.
- `SRC_TAG` is the tag `2026-10` of jeonghanlee/epicsarchiverap-maven: the installers `scripts/install-local-*.bash` fetch and build that tag, and the manual `make` flow updates the clone with `git -C epicsarchiverap-maven-src fetch origin` and `make srcupdate`. The Maven build of that source applies the site template and copies the site assets; a site folder that still holds a `build.xml` stops the build; remove that file (see "Site inputs" in `docs/README.install.md`). The management interface comes with that source from commit `d0932d1b`, and the installers stop when the selected source does not carry it.
- The branch `modernize` of jeonghanlee/epicsarchiverap-maven no longer exists. A site whose `configure/RELEASE.local` or `../RELEASE.local` sets `SRC_TAG:=origin/modernize` sets it to `2026-10`, another tag or a commit hash and removes the old value from both files. A site that pins a commit hash is not affected by the removal of the branch; a hash that precedes the management interface (commit `d0932d1b`), such as the 2.0.0 pin `d8a7813f`, is stopped by the installers for another reason. `configure/RELEASE` reads `../RELEASE.local` first and `configure/RELEASE.local` last, so a line left in either file can set the old value: an existing source clone keeps a stale `origin/modernize` and builds that old tip without an error, and a new clone stops at the checkout.
- The source at the tag `2026-10` packages the MariaDB JDBC driver 3.5.10 instead of 3.3.3, which closes the four published advisories of the older driver; the four WARs carry 43 runtime jars instead of 46 (`waffle-jna`, `caffeine` and `checker-qual` are gone), and `jna` stays for the Unix domain socket path.
- Every Maven call of `configure/RULES_SRC` except the version query of `info.mvn` passes `ARCHAPPL_SITEID` (default `als`) instead of a fixed `als`, so the copied site folder and the built site agree; `tests/no-ant.bash` checks it.

### Fixed
- MariaDB client configuration is created and replaced with mode 0600, and account creation output excludes password hashes.
- `mariadb_setup.bash dbBackup` refuses to overwrite a backup file of the same name and returns 1, and it publishes the finished dump through a temporary file, so a failed dump leaves no file.
- `archappl.bash health` run right after a start or restart no longer reports a correct, starting appliance as `FAIL wrong-java-executable`: a PID that the launcher started and that has not yet executed Java is reported as `STARTING run-script` or `STARTING catalina-script` (exit status 1), and `FAIL startup-timeout` once the bound `ARCHAPPL_HEALTH_STARTING_SECONDS` passes. Any other executable still fails with `wrong-java-executable`.
- With `DB_BACKEND=sqlite`, all `db.*` targets skip with a message and return success without reading or writing MariaDB configuration; unsupported SQLite delete and query operations and standalone MariaDB helper actions are rejected, and an invalid backend selector fails before any configuration write or database contact.
- `archappl.bash startup`, `shutdown` and `restart` exit non-zero when an instance script fails and name the instance on stderr; `restart` starts nothing when its shutdown failed. Every action that runs instances (`startup`, `shutdown`, `restart`, `service`) refuses to run when `archappl.conf` is missing or is not valid shell.
- `archappl.bash shutdown` keeps `temp/<component>.pid` when the instance's `bin/shutdown.sh` failed.
- `archappl.bash status` prints the process and storage health instead of the lists of Tomcat and appliance PIDs, so that its exit status is the health status (0 present, 1 failed or starting, 2 error). It takes its address from the source address that `ip -4 route get 8.8.8.8` reports and falls back to the host name.
- The usage of `archappl.bash` names `health --systemd`, `storage all` and `help` and spells `possible`. It no longer lists the `h` argument: `archappl.bash h` printed nothing and exited 0, and now prints the usage and exits 1, like any unknown argument.
- `make sd_health_status` ends with exit status `0` when the health timer or the health service is inactive (exit status 3 of `systemctl status`), for example the service between two runs; an absent unit still fails the target. A check that detected a stopped timer through this target reads the state of the unit instead.
- `archappl.bash storage` and `storage all` return the exit status of `sudo -- du` instead of always 0, and call `du` directly instead of through `bash -c`: a sudoers rule of the calling account must allow `du`.

### Removed
- `DB_BACKUP_PATH` in `configure/CONFIG_SITE`: no file read it, so a site value had no effect.
- The files of the old homepage that no management page uses: `site-template/siteid/css/main.css` and `css/mgmt.css`, 45 unused files of `site-template/siteid/img` (44 images, among them toolbar icons, favicons, logos and `dome.png`, and a conversion script) with `site-template/siteid/README.md` and `LICENSE.FeatherIcons`, and the screenshots of the old pages under `docs/technicaldocs`.
- Ant: `site-template/siteid/build.xml`, `ANT_HOME`, `ANT_PATH`, `ANT_CMD`, `ANT_OPTS`, the Ant entry in `PATH` and the Ant comments and README sentence.
- The sections `main_includes`, `site_contact_text`, `site_header`, `site_navbar` and `site_footer` of `site-template/siteid/template_changes.html`. No management page of the source carries the markers of the first two, so the overlay never merged them; the source supplies the header frame and the menu, so a `site_header` block would put a second header inside the frame and a `site_navbar` block would replace the menu.
- A site that kept any of these five sections in its own `template_changes.html` drops them and moves the logo link and the favicon, which sat in `site_header`, into a `site_logo` block as in the shipped file.

## [2.0.0] - 2026-09-28

### Added
- `configure/os/<os>.pkgs` declarative per-OS package lists (`debian13`, `rocky8`) and `scripts/install_os_packages.bash`, the installer that consumes them.
- `configure/os/*.mk` tracked OS preset files (`debian12`, `debian13`, `rocky8`) and their `make <os>.conf` targets.
- Scope and Out-of-scope blocks in `README.md`, `docs/README.policies.md`, and `docs/README.DataJourney.md`.
- `## help` annotations on user-facing Tomcat targets and `.PHONY` wiring for `$(all_tomcat_RULES)`.
- Phased test framework under `tests/`: `tests/run-all-tests.bash` runs the Phase 1 logic checks and the Phase 2 build-wrapper check (`--local`).
- `DB_BACKEND` selects the configuration database, `mariadb` (default) or `sqlite`; SQLite keeps its file at `ARCHAPPL_SQLITE_FILE` (default `$(ARCHAPPL_STORAGE_TOP)/config/archappl.sqlite`), loads its schema with `sqlite3` as the service account, and the appliance unit requires `mariadb.service` only for MariaDB.
- `DB_SOCKET` moves every MariaDB connection, the appliance's `localSocket` URL and the environment's own clients, onto the server's Unix domain socket; the application account is then granted at `localhost`.
- `archappl.bash health` and a health service and timer beside the appliance: every 30 s after a 60 s startup allowance it verifies the four Tomcat processes and the appliance state, and it never starts, stops or signals anything; `make sd_health_stop`, `sd_health_disable`, `sd_health_clean` and `sd_health_status` manage the pair.
- `ARCHAPPL_STORAGE_ALARM_PERCENT` (default 85): the health check fails once the archive store's filesystem reaches it; `make conf.storage` warns when the store shares the root filesystem or lies under a user home.
- `ARCHAPPL_STS_GRANULARITY`, `ARCHAPPL_STS_HOLD`, `ARCHAPPL_MTS_GRANULARITY`, `ARCHAPPL_MTS_HOLD` and `ARCHAPPL_LTS_GRANULARITY` render the store chain, so a test host can shorten it without editing the template.
- `archappl.bash loglevel <component> [logger] [level]` reads or sets an application log level at runtime through the mgmt BPL; `ARCHAPPL_ROOT_LOGGER_LEVEL` and `ARCHAPPL_LOG4J_SITE_FILE` set the start-up level and an optional site log4j2 file.
- `archappl.bash status` prints the mgmt URLs with the configured port.
- [The original work register](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md), which tracks every work item, decision and verification.

### Changed
- Restructure CONFIG layout per the epics-makefile pattern: merge `configure/CONFIG_COMMON` into `configure/CONFIG_SITE`; load RELEASE first and CONFIG_VARS before the derived SQL, Tomcat, and source configuration.
- `XXX.conf` Tomcat targets generate `CONFIG_SITE.local` with an include of the matching tracked preset under `configure/os/`.
- Top-level documentation reformatted: convert multi-attribute bullet lists to tables in the policies guide (sections 4.1, 4.3, 6); compress `docs/README.md` to a true index; convert single-cell figure tables to plain images with captions across all docs.
- `tests/phase1-logic.bash` expects branch `modernize` by default (`EXPECTED_BRANCH` still overrides).
- Toolchain: `JAVA_HOME` is the distribution JDK 21 (on Rocky Linux 8 the `java-21-openjdk-devel` package provides the link) and the build runs the source repository's Maven Wrapper (`./mvnw`, Maven 3.9.16 at the pinned source); the environment installs no Maven and no longer references java-env.
- The build consumes the source repository's own `pom.xml`; the environment no longer ships or copies one. `SRC_TAG` pins the source to jeonghanlee/epicsarchiverap-maven commit `d8a7813f40083c1bf7148e6c3b7bffd368d70ee0`.
- Apache Tomcat 9.0.121 for the four runtime instances.
- The appliance unit is `Type=simple` with the launcher as its main process: the four Tomcats run in the foreground, each through `systemd-cat` into the journal under `archappl-<component>`, and when one exits the launcher stops the others in order and the unit ends `failed`, with no `ExecStop` and no restart.
- Logging goes to the journal with syslog priorities: Tomcat and `java.util.logging` output through log4j2 (`log4j2-tomcat.xml` and the log4j jar set the source build provides), application logging through the WAR's own `log4j2.xml`; no `catalina.out` or dated JULI files are written.
- The per-instance JVM heap default is 256M for both `-Xms` and `-Xmx` (was 1G), with a 256M metaspace limit; the install guide states the four-instance memory budget.
- The shipped medium-term store uses a one-day partition.
- The Maven CLI flag hook is `MAVEN_FLAGS` (was `MAVEN_OPTS`).
- The application connects to MariaDB at `127.0.0.1` (IPv4 loopback).
- Phase 2 is a Make dry-run check of the build wrapper; compilation and artifact checks run in the source repository's CI.

### Fixed
- Preserve database credentials through Make, XML, shell configuration and MariaDB client arguments; use the configured database name for JDBC lookup and application queries, and the configured admin account for removal.
- Replace the deployed WAR contents and logging JAR set on reinstall, removing stale payload files while preserving external logs, work/temp files and data; attempt per-instance payload restoration on replacement failure.
- Return SKIP (exit 77) from unimplemented system test phases and report the requested run as incomplete.
- Local configuration preserves Tomcat installation and runtime paths, service and shutdown ports, and the cluster address across all OS presets; Ant uses the final Tomcat path.
- Storage preparation sets ownership on the archive root and every configured tier, including existing files outside the root; health checks inspect each tier's filesystem.
- `make db.show` and `mariadb_setup.bash dbShow` return a non-zero status when the database client fails.
- Preserve failed command exit statuses in the test runner so stale build artifacts cannot turn a build failure into a passing Phase 2 result, and do not mask a failure to resolve the test root.
- Align runtime, installation, policy, ETL, and test documentation with the implementation; correct the README screenshot path.
- `a_service_BUIDER` -> `a_service_BUILDER` macro typo across `RULES_FUNC` and `RULES_VARS`.
- Drop dead `CATALINA_OPTS` block in `CONFIG_VARS` that referenced undefined `JAVA_HEAPSIZE` and `JAVA_MAXMETASPACE`.
- `help` awk character class now includes `.` so dotted targets surface in `make help`.
- `checkfile` macro in `RULES_FUNC` had its `$(if $(wildcard))` branches inverted while its only caller (`db.conf` in `RULES_SQL`) passed a quoted path that never matched; both corrected, with phase 1 guards P1.9.
- `serverxml.install` in `RULES_INSTALL` paired engine and etl with each other's `ARCHAPPL_SHUTDOWN_*_PORT` variable; each now reads its own, with phase 1 guard P1.10.
- `make db.secure` removes the other root accounts and anonymous users with `DROP USER`, which works on MariaDB 10.3 and 10.4+ alike.
- `make sql.fill` checks the schema database as the application account, so it works where no admin account exists and stops when it cannot confirm the database.
- The backup listing and restore stop with a non-zero status on error, and a failed dump leaves no partial backup.
- `make db.addAdmin`, `db.rmAdmin`, `db.create` and `db.drop` and the matching `mariadb_setup.bash` commands stop with a non-zero status and name the failed step when the database client fails; account drops use `DROP USER IF EXISTS`.

### Removed
- Obsolete `install.docker`, `build.docker` and `prune.docker` targets.
- Obsolete documentation: `README.ant.md` (pre-Maven build guide), `README.centos7.md` (EOL 2024-06-30), `README.centos8.md` (EOL 2021-12-31), `README.javapkgs.md` (Java 11/12 superseded by Java 21).
- `configure/CONFIG_COMMON` (folded into `CONFIG_SITE`).
- `get.jdbc`, `clean.jdbc`, `install.jdbc` rules in `RULES_REQ` and the `jdbc` download case in `scripts/install_java_pkgs_local.bash`: Maven packages `mariadb-java-client` into each WAR, so a copy in the Tomcat lib is not used (phase 1 guard P1.11).
- `scripts/required_pkgs.sh` and `scripts/install_java_pkgs_local.bash`: replaced by the package lists, the installer, and the Maven Wrapper (phase 1 guard P1.12); the `install.{jdk,ant,maven}` and `conf.{jdk,ant,maven}` local-toolchain rules in `RULES_REQ` go with them.
- macOS support: the macOS presets and package list, the launchd rules and the `darwin` branches of the scripts, and `README.macos.md`.
- The jsvc shutdown path and its package dependency.
- The Sphinx documentation build; the source repository publishes its own documentation.

## [2025-12-23]

### Changed
- Apache Tomcat 9.0.113.
- Debian 13 support; storage permission fixes.

### Removed
- Deprecated property in `archappl.properties`.

## [2025-07-12]

### Changed
- `commons-fileupload` 1.5 -> 1.6.0 (security).
- `commons-lang3` bumped via dependabot.

## [2025-06-17]

### Changed
- JCA 2.4.10.

## [2025-06-06]

### Added
- Maven baseline. First stable Maven-based build of the Archiver Appliance with MAVEN environment.

## [2025-06-04]

### Added
- Hazelcast support.

## [2025-06-03]

### Added
- First working version of build, deploy, and run sequence.

### Fixed
- Apache Commons IO security update.
- Security patches for `pom.xml` and `template_changes.html`.

## [2021-11-01]

### Changed
- Apache Tomcat 9: 9.0.46 -> 9.0.54.
