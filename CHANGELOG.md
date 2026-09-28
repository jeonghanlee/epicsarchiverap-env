# Changelog

All notable changes to this project are documented here. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
The source repository's POM defines build artifact names; this changelog records
changes to the environment repository.

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
- The work register `docs/milestone-265f580.md`, which tracks every work item, decision and verification.

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
