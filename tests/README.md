# EPICS Archiver Appliance Environment — Automated Tests

Phased install test suite that validates the Makefile system and build-wrapper
command generation, with container deployment and VM integration planned.

## Phased SOP

Tests execute in strict order, from least to most privilege:

| Phase | Validates | Setup cost |
| :--- | :--- | :--- |
| 1. Logic | configure/ structure, Makefile parsing, doc set integrity | none |
| 2. Build wrapper | Real `make -n build`: configuration, site-overlay copy, Maven package command and ordering | none; no source checkout, JDK or network required |
| 3. Infrastructure | `make install` end-to-end inside a Debian 13 container | Docker daemon |
| 4. System | full systemd stack inside a libvirt VM; HTTP probes | KVM, libvirt, cloud-init |

Phase 3 and Phase 4 are stubs until their entrypoints are committed
under `tests/docker/` and `tests/vm/`.

## Test Execution

```bash
# Run all phases that are implemented.
tests/run-all-tests.bash

# Local command-generation checks (no build, network or privilege required).
tests/run-all-tests.bash --local

# Targeted phase (cumulative: --phase=N runs phases 1..N).
tests/run-all-tests.bash --phase=2
```

## Workspace and Logs

Each run creates a workspace under `${TMPDIR:-/dev/shm}` and writes
phase command output to `${WORKSPACE}/run.log`. The workspace
is removed on success and retained on failure for post-mortem
inspection. Force retention with `KEEP_WORKSPACE=1`.

## Verified Behaviors

### Phase 1 — Logic
- `configure/CONFIG_COMMON` is fully removed; no surviving file in `configure/` references that name.
- The five OS preset fragments (`debian12`, `rocky8`, `macos`, `macbrew`, `githubmac`) are present under `configure/os/`.
- `make -n build` parses without error.
- The five `XXX.conf` Tomcat targets each generate a `CONFIG_SITE.local` line that includes the matching preset.
- `SRC_PATH` derives to `epicsarchiverap-maven-src` and downstream `ARCHAPPL_SITEID_TARGET_PATH` resolves under that subtree (regression guard for the CONFIG include reorder).
- The four removed obsolete documents (`README.ant.md`, `README.centos7.md`, `README.centos8.md`, `README.javapkgs.md`) are not referenced from any surviving Markdown file.
- `CHANGELOG.md` is present; the misspelled `CHANGLOG.md` is gone.
- `checkfile` (expanded from the real `configure/RULES_FUNC` with `make -n`) selects the removal command for an existing file and no removal command for an absent one; its caller in `RULES_SQL` passes an unquoted path. This is a command-generation check, not an executed deletion test.
- `serverxml.install` pairs engine and etl with their own `ARCHAPPL_SHUTDOWN_*_PORT` variables.
- `RULES_REQ` carries no `get.jdbc` / `install.jdbc` rules.
- The legacy package scripts are gone; `scripts/install_os_packages.bash` parses and `configure/os/debian13.pkgs` names the distro JDK.
- No `java-env`, `MAVEN_HOME`, or local-install reference survives in `configure/`, `scripts/`, or `README.md`; `MAVEN_CMD` is the source tree's `mvnw`.
- `run_logged` preserves both success and a nonzero exit status from real child commands.
- All six Maven targets parse with `MAVEN_FLAGS` and render those flags immediately after the Maven Wrapper command. The check uses the real Makefile with `make -n`; it does not run Maven, read the example settings file, or verify proxy connectivity.

### Phase 2 — Build wrapper
- The real `make -n build` target parses and generates commands successfully.
- The package command runs from the configured source directory and invokes its Maven Wrapper with `clean package -DskipTests`.
- Only simple unquoted environment assignments may precede the wrapper; another command such as `echo` does not pass the invocation check.
- The six configuration-generation commands precede the site-overlay copy, which precedes the Maven package command.
- `MAVEN_FLAGS` is empty for this check; Phase 1 separately verifies nonempty flags across all six Maven targets.
- The check does not clone sources, execute Java or Maven, generate configuration, provision storage, or inspect WARs and release artifacts. Compilation and artifact verification belong to [aa-maven CI](https://github.com/jeonghanlee/epicsarchiverap-maven/actions).
- The script remains `tests/phase2-compile.bash` for direct callers. Both `--local` and `--phase=2` still run Phase 1 followed by Phase 2.

### Phase 3 — Infrastructure (planned)
- `make install` populates `${AA_INSTALL_LOCATION}/{mgmt,engine,etl,retrieval}/webapps` with the four exploded WAR trees.
- `make tomcat.exist` reports the install location populated.

### Phase 4 — System Integration (planned)
- `systemctl is-active archappl.service` returns active.
- `curl http://localhost:17665/mgmt/bpl/getApplianceInfo` returns 200.
- The `archappl` MariaDB database contains `ArchivePVRequests`, `ExternalDataServers`, `PVAliases`, and `PVTypeInfo`.

The source repository owns the documentation build. Planned changes to that
build are tracked in its own work register rather than as aa-env test work.
