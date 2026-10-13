# Changelog

All notable changes to this project are documented here. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
The source repository's POM defines build artifact names; this changelog records
changes to the environment repository.

## [2.0.1] - unreleased

### Added
- Local systemd installers for SQLite, MariaDB over UDS, and MariaDB over TCP, sharing one driver with plan output, configurable startup verification, and an option to retain provisioned MariaDB accounts. See the local installation procedure in `docs/README.install.md`.
- VM acceptance driver `tests/vm/` behind `tests/run-all-tests.bash` (`--init`, `--case`, `--verify-cleanup`, `--verdict`): it composes cloud-provision (fresh guests) and ansible-provision (prerequisites and the ordered installation) and checks Debian 13 and Rocky Linux 8.10 with MariaDB over a socket, MariaDB over TCP and SQLite, plus two real build-failure cases, each on its own guest. It verifies the installed payload against the WARs, the four JVM identities, three scheduled health runs, archiving and retrieval of a changing PV, and survival of a restart, a repeat apply and a forced reinstall. The design is in `docs/README.vmtests.md`.
- Failure evidence in the VM verifier: a failed health check keeps the health unit entries and a copy of the journal files; a failed channel access data check keeps the engine JVM's UDP sockets and the management view of the test PV and the disconnected PVs.
- `ARCHAPPL_HEALTH_STARTING_SECONDS` (default 10, valid 1 to 59) bounds how long `archappl.bash health` reports an instance as starting.
- `tests/health-starting.bash` runs the shipped launcher chain under the real health check, and `tests/no-ant.bash` keeps Ant out of the tracked tree and checks the site id of every Maven call.
- `docs/README.install.md` documents the site folder inputs (`img/`, `css/main.css`, `template_changes.html`, `classpathfiles/`) and the variables `ARCHAPPL_SITEID` and `ARCHAPPL_SITEID_TEMPATE_PATH`.

- The management interface rework (developed here and now part of the source repository, jeonghanlee/epicsarchiverap-maven): a Work page that finds PVs (search words, glob, regular expression, the server reports as selections), scans up to 100 selected PVs as sparkline rows, charts up to 5 of one unit with D3, zooms and pans a window, shows the state of a PV with its explanation and the actions that apply, and keeps the name list as a browser snapshot that follows the appliance every 15 s.
- System pages for everyone and for the operator: Overview with three verdict lines and a meaning for every measure, Operations with the questions, thresholds and remedies of samples, dropped samples, write path, stores, ETL and processes, and Retrieval performance with a request measured in the browser; disconnected PVs are grouped by host and time of loss.
- Links from the Work page to the data viewer for the selected PVs and the focused PV over the window of the chart, and the state of the rows in view of the PV list, read in one call.
- Maintenance of a PV from the page: change of sampling, rename, change of type and consolidation, each pausing the PV first and saying what it changes; pause, resume and stop for several selected PVs; pause of a disconnected host group.
- `tests/ui-static.bash`, run by `tests/phase1-logic.bash` against the interface files of the selected source (`tests/ui-files.list`): marker blocks, content security policy, no inline code, outside host, jQuery or text turned into markup, referenced files, element ids and text contrast, each with a broken copy that must be refused.
- `docs/README.interface.md` points to the description of the management interface in the source repository and names what this repository keeps: the site skin and the static checks.
- An mdBook of the appliance in `book/`, written from the code and from commands run: concepts, install and operate procedures, reference pages that `book/scripts/gen-*.bash` print from the code, and a glossary. `mdbook build book` renders it to `book/site/`.

### Changed
- `ARCHAPPL_SAMPLE_BUFFER_MARGIN_SECONDS` (default 1.0, at least 1.0) is written to `archappl.properties` as `org.epics.archiverappliance.config.PVTypeInfo.sampleBufferMarginSeconds`, the seconds of write delay a sample buffer absorbs, and the remedy texts of the Operations page name it. It replaces the earlier multiplier of the buffer capacity; the source commit `6c6b973a` of jeonghanlee/epicsarchiverap-maven that reads the key is contained in every `modernize` commit that `SRC_TAG` follows.
- The management pages are rebuilt without jQuery and with a content security policy on every full page; `metrics.html`, `storage.html`, `appliance.html`, `reports.html`, `pvdetails.html` and `cacompare.html` forward to the page that replaced them.
- The site folder keeps only the files that carry the site's own values: `template_changes.html` fills the `site_logo` block of the header, and `img/` holds `LBNLLogo.png` and `als.ico`. The stylesheet, the header logo, its narrow-screen wordmark and the menu come from the source, so the site's `css/main.css` copy is removed.
- `SRC_TAG` is `origin/modernize` of jeonghanlee/epicsarchiverap-maven: the source update step fetches and builds the branch tip, whose Maven build applies the site template and copies the site assets; a site folder that still holds a `build.xml` stops the build; remove that file (see "Site inputs" in `docs/README.install.md`).
- The source of `modernize` packages the MariaDB JDBC driver 3.5.10 instead of 3.3.3, which closes the four published advisories of the older driver; the four WARs carry 43 runtime jars instead of 46 (`waffle-jna`, `caffeine` and `checker-qual` are gone), and `jna` stays for the Unix domain socket path.
- Every Maven call of `configure/RULES_SRC` passes `ARCHAPPL_SITEID` (default `als`) instead of a fixed `als`, so the copied site folder and the built site agree.
- The VM verifier waits on `STARTING` and `wrong-java-executable` within its readiness deadline, fails when either persists, and keeps every retried health output with its elapsed time.
- The site folder follows the contract of the source: only `img/`, `css/main.css`, `template_changes.html` and `classpathfiles/` are applied, and a `css/mgmt.css` of a site is reported as not applied. The `engine` and `etl` WARs carry only `ui/comm/version.txt` of the shared static content, so the VM verifier compares the site images and `css/main.css` in the `mgmt` and `retrieval` WARs.
- The VM driver names the species of the current provisioners: the inventory generator of cloud-provision receives `archiver-dev-uds`, `archiver-dev-tcp` or `archiver-dev-sqlite`, and the species playbooks of ansible-provision are `archiver_dev_uds`, `archiver_dev_tcp` and `archiver_dev_sqlite`. The generator no longer accepts `archiver-dev`.

### Fixed
- MariaDB client configuration is created and replaced with mode 0600, and account creation output excludes password hashes.
- `archappl.bash health` run right after a start or restart no longer reports a correct, starting appliance as `FAIL wrong-java-executable`: a PID that the launcher started and that has not yet executed Java is reported as `STARTING run-script` or `STARTING catalina-script` (exit status 1), and `FAIL startup-timeout` once the bound passes. Any other executable still fails with `wrong-java-executable`.
- With `DB_BACKEND=sqlite`, all `db.*` targets skip with a message and return success without reading or writing MariaDB configuration; unsupported SQLite delete and query operations and standalone MariaDB helper actions are rejected, and an invalid backend selector fails before any configuration write or database contact.
- The build-failure check recognizes the absent-commit message of git 2.47 (`unable to read tree`).
- `archappl.bash startup`, `shutdown` and `restart` exit non-zero when an instance script fails and name the instance on stderr; `restart` starts nothing when its shutdown failed. Every action that runs instances (`startup`, `shutdown`, `restart`, `service`) refuses to run when `archappl.conf` is missing or is not valid shell.
- `archappl.bash shutdown` keeps `temp/<component>.pid` when the instance's `bin/shutdown.sh` failed; `status` takes its address from the `src` field of the route and falls back to the host name, and no longer prints `Verified` before the health check; the usage names `health --systemd`, `storage all` and `help`, spells `possible`, and no longer lists the `h` argument, which is now an unknown argument like any other.
- `make sd_health_status` ends with exit status `0` when the health service is inactive between two runs; an absent unit still fails the target.

### Removed
- The files of the old homepage that no management page uses: `site-template/siteid/css/mgmt.css` and the jQuery UI dialog rules of `css/main.css`, 45 unused images of `site-template/siteid/img` (toolbar icons, favicons, logos, `dome.png`) with their notes and license, and the screenshots of the old pages under `docs/technicaldocs`. The site folder keeps `css/main.css`, `template_changes.html`, `img/LBNLLogo.png` and `img/als.ico`; a site can still supply `css/mgmt.css`, and the VM verifier no longer compares it.
- The interface copy step: `site-template/ui`, the `copy.ui` rule (and its prerequisite in every `build.*` target), `scripts/prepare-ui.bash`, `ARCHAPPL_UI_TEMPLATE_PATH`, `ARCHAPPL_UI_TARGET_PATH` and the copy checks of the logic and build tests. The management interface is part of the source that `SRC_TAG` selects, from jeonghanlee/epicsarchiverap-maven commit `d0932d1b`; the installers restore the files of an earlier copy in the source clone and stop when the selected source does not carry the interface.
- Ant: `site-template/siteid/build.xml`, `ANT_HOME`, `ANT_PATH`, `ANT_CMD`, `ANT_OPTS`, the Ant entry in `PATH` and the Ant comments and README sentence. At the same source commit, the four WARs differ from the Ant-backed build only by the new site overlay class and the embedded POM copy.
- The sections `main_includes` and `site_contact_text` of `site-template/siteid/template_changes.html`: no management page of the source carries their markers, so the overlay never merged them. The VM verifier requires every section of the file in the `mgmt` WAR.

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
