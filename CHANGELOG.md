# Changelog

All notable changes to this project are documented here. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Version markers use the calendar-versioning scheme adopted in `pom.xml`.

## [Unreleased]

### Added
- `configure/os/<os>.pkgs` declarative per-OS package lists (`debian13`, `rocky8`, `macos`) and `scripts/install_os_packages.bash`, the installer that consumes them.
- `configure/os/*.mk` tracked OS preset files (`debian12`, `rocky8`, `macos`, `macbrew`, `githubmac`).
- Scope and Out-of-scope blocks in `README.md`, `docs/README.policies.md`, and `docs/README.DataJourney.md`.
- `## help` annotations on user-facing Tomcat targets and `.PHONY` wiring for `$(all_tomcat_RULES)`.

### Changed
- Restructure CONFIG layout per the epics-makefile pattern: merge `configure/CONFIG_COMMON` into `configure/CONFIG_SITE`; reorder `configure/CONFIG` includes so RELEASE comes first and CONFIG_VARS last.
- `XXX.conf` Tomcat targets now generate a single-line `CONFIG_SITE.local` that includes the matching tracked preset under `configure/os/`.
- Top-level documentation reformatted: convert multi-attribute bullet lists to tables in the policies guide (sections 4.1, 4.3, 6); compress `docs/README.md` to a true index; convert single-cell figure tables to plain images with captions across all docs.
- `tests/phase1-logic.bash` expects branch `modernize` by default (`EXPECTED_BRANCH` still overrides).
- Toolchain: `JAVA_HOME` is the distro JDK (`/usr/lib/jvm/java-21-openjdk-amd64`) and the build runs the source repository's Maven Wrapper (`./mvnw`, pinned 3.9.9); the environment installs no Maven and no longer references java-env.
- The build consumes the source repository's own `pom.xml`; the environment no longer ships or copies one, and `SRC_TAG` tracks the source `modernize` branch during development.

### Fixed
- `a_service_BUIDER` -> `a_service_BUILDER` macro typo across `RULES_FUNC` and `RULES_VARS`.
- Drop dead `CATALINA_OPTS` block in `CONFIG_VARS` that referenced undefined `JAVA_HEAPSIZE` and `JAVA_MAXMETASPACE`.
- `help` awk character class now includes `.` so dotted targets surface in `make help`.
- `make macport.conf` reference in macOS docs corrected to `make macos.conf`.
- `checkfile` macro in `RULES_FUNC` had its `$(if $(wildcard))` branches inverted while its only caller (`db.conf` in `RULES_SQL`) passed a quoted path that never matched; both corrected, with phase 1 guards P1.9.
- `serverxml.install` in `RULES_INSTALL` paired engine and etl with each other's `ARCHAPPL_SHUTDOWN_*_PORT` variable; each now reads its own, with phase 1 guard P1.10.

### Removed
- Obsolete documentation: `README.ant.md` (pre-Maven build guide), `README.centos7.md` (EOL 2024-06-30), `README.centos8.md` (EOL 2021-12-31), `README.javapkgs.md` (Java 11/12 superseded by Java 21).
- `configure/CONFIG_COMMON` (folded into `CONFIG_SITE`).
- `get.jdbc`, `clean.jdbc`, `install.jdbc` rules in `RULES_REQ` and the `jdbc` download case in `scripts/install_java_pkgs_local.bash`: Maven packages `mariadb-java-client` into each WAR, so a copy in the Tomcat lib is not used (phase 1 guard P1.11).
- `scripts/required_pkgs.sh` and `scripts/install_java_pkgs_local.bash`: replaced by the package lists, the installer, and the Maven Wrapper (phase 1 guard P1.12); the `install.{jdk,ant,maven}` and `conf.{jdk,ant,maven}` local-toolchain rules in `RULES_REQ` go with them.

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
