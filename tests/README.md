# EPICS Archiver Appliance Environment — Automated Tests

Phased install test suite that validates the Makefile system, Maven
build, container deployment, and full VM-based integration.

## Phased SOP

Tests execute in strict order, from least to most privilege:

| Phase | Validates | Setup cost |
| :--- | :--- | :--- |
| 1. Logic | configure/ structure, Makefile parsing, doc set integrity | none |
| 2. Compile | full Maven build with sphinx; four service WARs produced | Java 21, Maven, Python (host), network |
| 3. Infrastructure | `make install` end-to-end inside a Debian 13 container | Docker daemon |
| 4. System | full systemd stack inside a libvirt VM; HTTP probes | KVM, libvirt, cloud-init |

Phase 3 and Phase 4 are stubs until their entrypoints are committed
under `tests/docker/` and `tests/vm/`.

## Test Execution

```bash
# Run all phases that are implemented.
tests/run-all-tests.bash

# Local-only phases (no privilege required).
tests/run-all-tests.bash --local

# Targeted phase (cumulative: --phase=N runs phases 1..N).
tests/run-all-tests.bash --phase=2
```

## Workspace and Logs

Each run creates a workspace under `${TMPDIR:-/dev/shm}` and writes
detailed Maven and shell logs to `${WORKSPACE}/run.log`. The workspace
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
- `checkfile` (run through the real `configure/RULES_FUNC` in an ad-hoc makefile) removes an existing file and leaves an absent one alone; its caller in `RULES_SQL` passes an unquoted path.
- `serverxml.install` pairs engine and etl with their own `ARCHAPPL_SHUTDOWN_*_PORT` variables.
- `RULES_REQ` carries no `get.jdbc` / `install.jdbc` rules.

### Phase 2 — Compile
- `python3` is on PATH for `docs/build_docs.sh` to bootstrap its sphinx venv.
- `make init` clones `epicsarchiverap-maven-src` (skipped if the directory already exists).
- `make build.mvn` (full clean + package) returns success.
- The four service WARs (`mgmt`, `engine`, `etl`, `retrieval`) are produced under `target/`, each at least 1 MB.
- The release tarball `archappl_<version>.tar.gz` and `target/stage/RELEASE_NOTES` are produced.
- `docs/docs/build/index.html` confirms the sphinx documentation step ran end-to-end.

### Phase 3 — Infrastructure (planned)
- `make install` populates `${AA_INSTALL_LOCATION}/{mgmt,engine,etl,retrieval}/webapps` with the four exploded WAR trees.
- `make tomcat.exist` reports the install location populated.

### Phase 4 — System Integration (planned)
- `systemctl is-active archappl.service` returns active.
- `curl http://localhost:17665/mgmt/bpl/getApplianceInfo` returns 200.
- The `archappl` MariaDB database contains `ArchivePVRequests`, `ExternalDataServers`, `PVAliases`, and `PVTypeInfo`.

## Long-term TODO

The Maven + sphinx integration relies on `docs/build_docs.sh`
auto-bootstrapping a Python venv inside the source tree. This is the
known fragile boundary inherited from the Gradle-to-Maven port and
should be replaced with a tracked Maven plugin invocation.
