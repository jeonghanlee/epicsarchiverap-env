# Work Register

Release line: master (`maven` branch)
Milestone index: 265f580
Canonical path: `docs/milestone-265f580.md`
Canonical branch or ref: modernize
Git upstream: origin/modernize
Remote tracker: jeonghanlee/epicsarchiverap-env, GitHub milestone none yet
Peer register: aa-maven (jeonghanlee/epicsarchiverap-maven) `docs/milestone-daff1b7.md` on branch modernize, observed at `3c96141d394ebc4b6f81bb12f6db29858a1fb6bd` on 2026-09-20 by reading that path in a fetched clone (prior observation: `3528249462d54b295e9a9277882f7f3c0fc1cc62` on 2026-09-15 through the GitHub contents API)

Next session entry point: M33 (the journald logging model, D24) is In progress,
plan accepted and implementation authorized 2026-09-24; M34 waits on M33 (G14 Complete at `a1155ef0`);
M35 (Tomcat and java.util.logging through log4j2, D25) waits on M33 (G15 Complete at `9bbd69bf`).
M28, M29 and M30 are Complete at `1fc20a8`, `9f22eac` and `18356d1`. Then
select a systemd VM and an interruption window for M23's remaining real-process/runtime checks using the
implementation at `9ee6ac0`; local implementation review passed. The heap default at `0df950d` also awaits
deployment verification without an override under M22 / T2.
M26 remains Ready for a test-host archive filesystem separate from the root
volume, with the requirement documented in `docs/README.install.md`. Its
ETL-timing half moved to M31 (D23), Complete at `9eed006`: Make variables for
the store granularity and hold, so test hosts shorten the chain without
editing the shipped template. M32, the run that observes the chain with the
test values, is Blocked on G13, the ansible-provision soak requested on
2026-09-24. M24 is Complete at `4b4cb41`; issue #45 was
updated and closed on 2026-09-22. M25 is Complete
at `84b38e5`, and M15 is Complete at `d748d4f`; their repository landing evidence
was verified on 2026-09-22.
M23 is In progress: local implementation, checks and independent implementation
review passed; implementation landed at `9ee6ac0` on origin/modernize on
2026-09-23, and real-VM verification remains. Two rows are
Ready: M9 and M26. The five unfinished Backlog items
M10, M13, M18, M19 and M27 are assigned to Milestone on 2026-09-22; their
unresolved scope or operating conditions keep them Open and not Ready. M22 is In progress: the `256M` heap is
selected for VM testing, with four heaps totaling 1 GiB and metaspace caps adding
another 1 GiB. The operator report supplies approximately 21 hours of light
sampling-load evidence with the 256M override; it reports no OOM or restart.
The heap default landed at `0df950d` on origin/modernize on 2026-09-23;
default-install runtime verification remains outstanding. The
report does not provide a quantified disk growth rate for M26. M8's Release Verification 2 and 3 passed on three provisioned hosts;
Release Verification 1 and 4 remain, and M8 still waits on M9. M2
(`b6a80af`), M17 (`a159b79`), M21 (`a12516d`) and M20 (`e513267`) have landed.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Deploy | M1 | aa-env baseline tag and reproducible source pin | Milestone | Complete | No | D3 | Both `NewHope` tags verified and pin recipe reproduced 2026-09-11; [detail](#m1---aa-env-baseline-tag-and-reproducible-source-pin) |
| Register | M3 | Land register on maven and retire legacy roadmap | Milestone | Not started | No | M8 | Legacy roadmap retired (G2); the register lands on maven with M8's merge; [detail](#m3---land-register-on-maven-and-retire-legacy-roadmap) |
| aa-env | M4 | Residual configure and script defects | Milestone | Complete | No | D10 | Three defects fixed with phase 1 guards (`0e02ede`); the Maven item superseded by D10; [detail](#m4---residual-configure-and-script-defects) |
| Tomcat | M5 | Tomcat 9.0.121, the fixed Phase 2 version | Milestone | Complete | No | D8, D11 | Config bumped (`aea623b`); Tomcat 9.0.121 fixed for Phase 2; [detail](#m5---tomcat-90121-the-fixed-phase-2-version) |
| Build | M6 | Single-source pom: remove aa-env pom overwrite | Milestone | Complete | No | G3 | Verified 2026-09-12: full build with no aa-env pom, clean source tree (`0e9cee6`); [detail](#m6---single-source-pom-remove-aa-env-pom-overwrite) |
| Tomcat | M7 | Tomcat 11 migration (aa-env side) | Milestone | Complete | No | D11 | Retired 2026-09-12 by D11; Tomcat 9 is fixed for Phase 2; [detail](#m7---tomcat-11-migration-aa-env-side) |
| Tomcat | M12 | Tomcat 9.1.x fallback | Milestone | Complete | No | D11 | Retired 2026-09-12 by D11; [detail](#m12---tomcat-91x-fallback) |
| DB | M9 | Selectable persistence backend: MariaDB and SQLite | Milestone | Not started | Yes | G9, M11, D15 | One PV archives and retrieves under each backend selected in `context.xml`; [detail](#m9---selectable-persistence-backend-mariadb-and-sqlite) |
| Runtime | M16 | Run the Tomcat 9 instances under systemd template units | Milestone | Complete | No | D12 | Retired 2026-09-12 by D12; the script under the existing service stays the launcher; [detail](#m16---run-the-tomcat-9-instances-under-systemd-template-units) |
| Toolchain | M11 | Single distro toolchain: JDK, Maven Wrapper, package lists | Milestone | Complete | No | G8, D10 | Implemented and verified 2026-09-12 (`f24ec5c`); [detail](#m11---single-distro-toolchain-jdk-maven-wrapper-package-lists) |
| Release | M8 | Modernized baseline release to maven | Milestone | Not started | No | M1, M4, M6, M9, M11, M15, M16, M17, G10, D17 | Install-verified against aa-maven Phase 1, then PR to maven; M3 completes with this merge; [detail](#m8---modernized-baseline-release-to-maven) |
| Build seam | M14 | Remove Ant leftovers from aa-env | Milestone | Deferred | No | G6, D9, D17 | No `ANT_*` in `configure/`, no `site-template/siteid/build.xml`, no `ant` package, build still passes; deferred 2026-09-20 (D17) with Ant removal out of Phase 1 on both sides, returning to Not started only by a new dated decision; [detail](#m14---remove-ant-leftovers-from-aa-env) |
| Tests | M15 | Reduce phase 2 to a build-wrapper check | Milestone | Complete | No | G7, D9 | Implemented and locally verified; landed at `d748d4f` on origin/modernize, verified 2026-09-22; [detail](#m15---reduce-phase-2-to-a-build-wrapper-check) |
| Verification | M17 | Correct build verification and align documentation with code | Milestone | Complete | No | D14 | Implemented and locally verified 2026-09-15; landed at `a159b79` on origin/modernize 2026-09-19; T6 follow-up carried as M20; [detail](#m17---correct-build-verification-and-align-documentation-with-code) |
| Cleanup | M21 | Remove the retired Sphinx docs build from aa-env | Milestone | Complete | No | G11 | Sphinx/Python/docs-build assumptions removed; phase 2 asserts the mgmt WAR `ui/api/index.html` (T1/T2 pass); landed at `a12516d`; [detail](#m21---remove-the-retired-sphinx-docs-build-from-aa-env) |
| Deploy | M2 | Non-interactive install sequence for the ansible role | Milestone | Complete | No | M1, D7 | `docs/README.install.md` adopted by ansible-provision (T1 Pass 2026-09-19); landed at `b6a80af`, refined at `a12516d`; [detail](#m2---non-interactive-install-sequence-for-the-ansible-role) |
| Runtime | M22 | Size the JVM heap default to the host | Milestone | In progress | No | D18 | Default landed at `0df950d`; 256M override passed the reported approximately 21-hour light-load run; changed-default deployment/runtime verification remains; [detail](#m22---size-the-jvm-heap-default-to-the-host) |
| Runtime | M23 | Make a dead instance visible to systemd | Milestone | In progress | No | D12, D18, D19 | Implementation landed at `9ee6ac0`; VM checks remain for the 45-second failure-reporting target, no monitor-initiated stop/restart and preserved dependency behavior; [detail](#m23---make-a-dead-instance-visible-to-systemd) |
| Cleanup | M24 | Remove the dead jsvc shutdown path | Milestone | Complete | No | D12, D18 | Implemented and locally verified; landed at `4b4cb41`; issue #45 closed 2026-09-22; [detail](#m24---remove-the-dead-jsvc-shutdown-path) |
| Build seam | M25 | Correct the MAVEN_OPTS name and proxy guidance | Milestone | Complete | No | D10, D18 | Implemented and locally verified; landed at `84b38e5` on origin/modernize, verified 2026-09-22; [detail](#m25---correct-the-maven_opts-name-and-proxy-guidance) |
| Storage | M26 | Test-environment archive store | Milestone | Not started | Yes | D18, D21, D23 | The archive store sits off the root filesystem with a threshold that reports first, and the host prerequisites say so; [detail](#m26---test-environment-archive-store) |
| Tests | M10 | Phase 3 and 4 install tests (container, VM) | Milestone | Open | No | | Define a host and the container/VM implementation plan; [detail](#m10---phase-3-and-4-install-tests-container-vm) |
| UI | M13 | Site skin aligned with the rewritten mgmt UI | Milestone | Open | No | | Define the target interface and required aa-env skin changes; [detail](#m13---site-skin-aligned-with-the-rewritten-mgmt-ui) |
| Runtime | M18 | Investigate retrieval metadata HTTP 404 | Carry-forward | Open | No | | Define a reproduction environment and scope for issue #24; [detail](#m18---investigate-retrieval-metadata-http-404) |
| Storage | M19 | Investigate ETL for PV names containing underscores | Carry-forward | Open | No | | Define a reproduction environment and scope for issue #25; [detail](#m19---investigate-etl-for-pv-names-containing-underscores) |
| Storage | M27 | LTS retrieval pre-processing (`pp`) | Milestone | Open | No | D21 | Decide from operating experience whether `pp` on LTS earns its disk cost; [detail](#m27---lts-retrieval-pre-processing-pp) |
| DB | M28 | Load the schema without an admin account and fail loudly | Milestone | Complete | No | D22 | Implemented and verified (T1-T4); landed at `1fc20a8` on origin/modernize; issue #47 closed 2026-09-23; [detail](#m28---load-the-schema-without-an-admin-account-and-fail-loudly) |
| DB | M29 | Fail the backup listing and restore on error | Milestone | Complete | No | | Implemented and verified (T1-T2); landed at `9f22eac` on origin/modernize; issue #48 closed 2026-09-23; [detail](#m29---fail-the-backup-listing-and-restore-on-error) |
| DB | M30 | Fail the backup when the dump fails | Milestone | Complete | No | | Implemented and verified (T1-T2); landed at `18356d1` on origin/modernize; issue #49 closed 2026-09-23; [detail](#m30---fail-the-backup-when-the-dump-fails) |
| Storage | M31 | Selectable store granularity and hold for test hosts | Milestone | Complete | No | D21, D23 | Implemented and verified (T1); landed at `9eed006` on origin/modernize; issue #50 records it and stays open for M32; [detail](#m31---selectable-store-granularity-and-hold-for-test-hosts) |
| Storage | M32 | Observe the store chain with the test values | Milestone | Blocked | No | M31, G13, D23 | A run of a few hours with the M31 test values shows samples in STS, then MTS, then LTS, then issue #50 closes; [detail](#m32---observe-the-store-chain-with-the-test-values) |
| Runtime | M33 | Run the four Tomcats in the foreground under one journald-collected service | Milestone | In progress | No | D12, D19, D24 | The service is Type=exec with KillMode=mixed and Restart=no; the launcher starts and stops the four Tomcats in the D12 order in the foreground, each through `systemd-cat` with `archappl-<component>`; JULI keeps only the ConsoleHandler; the access log has `maxDays`; `log4j.properties.in` is gone; the install guide says so; [detail](#m33---run-the-four-tomcats-in-the-foreground-under-one-journald-collected-service) |
| Runtime | M34 | Take the log4j2 configuration from the WAR with journal priorities | Milestone | Not started | No | M33, G14, D24 | aa-env ships no `log4j2.xml` and exports `ARCHAPPL_ROOT_LOGGER_LEVEL`, so `journalctl -p err` selects application errors; [detail](#m34---take-the-log4j2-configuration-from-the-war-with-journal-priorities) |
| Runtime | M35 | Route Tomcat and java.util.logging output through log4j2 | Milestone | Not started | No | M33, G15, D25 | Each instance runs with `log4j-appserver` and `log4j-jul` on the Tomcat classpath and `log4j2-tomcat.xml`, so Tomcat's own lines and the CA client's `java.util.logging` lines reach the journal at their own priority; [detail](#m35---route-tomcat-and-javautillogging-output-through-log4j2) |
| Gate | G1 | aa-maven baseline tag reported by the aa-maven session | External gate | Complete | No | | Tag `NewHope` -> `abf6545` verified on the aa-maven origin 2026-09-11; [detail](#g1---aa-maven-baseline-tag-reported-by-the-aa-maven-session) |
| Gate | G2 | Legacy GitHub milestones and issues closed | External gate | Complete | No | | Milestones M0–M5 and issues #35–#42 closed, verified 2026-09-13; [detail](#g2---legacy-github-milestones-and-issues-closed) |
| Gate | G3 | aa-maven lands canonical pom | External gate | Complete | No | | Canonical pom at `9be652c`, verified on origin 2026-09-12; [detail](#g3---aa-maven-lands-canonical-pom) |
| Gate | G4 | aa-maven lands jakarta servlet migration | External gate | Complete | No | | Retired 2026-09-12: Tomcat 9 fixed, no jakarta migration (aa-maven D13); [detail](#g4---aa-maven-lands-jakarta-servlet-migration) |
| Gate | G6 | aa-maven lands Ant removal with the per-site build contract | External gate | Open | No | | Closes when aa-maven removes Ant and reports the commit with the post-Ant per-site contract; their M10 is deferred to backlog (2026-09-19) and Ant still drives the per-site build at `3c96141d`, so this blocks no row under D17; [detail](#g6---aa-maven-lands-ant-removal-with-the-per-site-build-contract) |
| Gate | G7 | aa-maven CI builds on Maven | External gate | Complete | No | | `maven.yml` runs `./mvnw -B -ntp clean verify` on JDK 21; passing run 35423900164 / `b0fcbb61`, re-derived at `3c96141d` 2026-09-20; [detail](#g7---aa-maven-ci-builds-on-maven) |
| Gate | G8 | aa-maven Maven Wrapper build verified | External gate | Complete | No | | Fresh-clone `./mvnw` build passed at `c1dd0b1`, reported 2026-09-12; [detail](#g8---aa-maven-maven-wrapper-build-verified) |
| Gate | G9 | aa-maven ships both DB drivers with dialect auto-detection | External gate | Complete | No | | Both `mariadb-java-client` and `sqlite-jdbc` ship; the source auto-detects the dialect from DataSource metadata (aa-maven `ab324afb`); [detail](#g9---aa-maven-ships-both-db-drivers-with-dialect-auto-detection) |
| Gate | G10 | aa-maven Phase 1 complete (servlet-api 9.0.122, CI on Maven) | External gate | Complete | No | | Phase 1 closed on the D17 basis: servlet-api 9.0.122 and Maven CI verified at `3c96141d` 2026-09-20; Ant removal deferred; [detail](#g10---aa-maven-phase-1-complete-servlet-api-90122-ci-on-maven) |
| Gate | G11 | aa-maven retires the Sphinx docs pipeline (mdBook on Pages) | External gate | Complete | No | | Sphinx/RTD removed on aa-maven modernize `263805a1`; mdBook live on GitHub Pages; [detail](#g11---aa-maven-retires-the-sphinx-docs-pipeline-mdbook-on-pages) |
| Gate | G12 | JNA on the WAR classpath for MariaDB Unix-socket support | External gate | Complete | No | | `jna` and `jna-platform` 5.13.0 present in all four WARs built from `3c96141d`, verified 2026-09-21; transitive, so an explicit declaration was requested of aa-maven as hardening; [detail](#g12---jna-on-the-war-classpath-for-mariadb-unix-socket-support) |
| Gate | G13 | ansible-provision runs a soak with the M31 test values | External gate | Open | No | | The ansible-provision operator reports a run of a few hours with the M31 test values, showing samples in STS, then MTS, then LTS; [detail](#g13---ansible-provision-runs-a-soak-with-the-m31-test-values) |
| Gate | G14 | aa-maven ships the log4j2 layout with the journal priority prefix | External gate | Complete | No | | `a1155ef0` on the aa-maven origin/modernize, read 2026-09-24: Console PatternLayout with `<2>` to `<7>` per level and root `${env:ARCHAPPL_ROOT_LOGGER_LEVEL:-INFO}`; [detail](#g14---aa-maven-ships-the-log4j2-layout-with-the-journal-priority-prefix) |
| Gate | G15 | aa-maven emits the Tomcat log4j jar set from its build | External gate | Complete | No | | `9bbd69bf` on the aa-maven origin/modernize, built here on 2026-09-24 through `make build.mvn`: `target/tomcat-log4j` holds the four jars at 2.26.1, the three shared with the engine WAR byte-identical; [detail](#g15---aa-maven-emits-the-tomcat-log4j-jar-set-from-its-build) |
### Decisions

| ID | Decision | Decision Date |
| --- | --- | --- |
| D1 | aa-maven is maintained independently. No further upstream merges; upstream changes are cherry-picked individually. Legacy roadmap phases M3 and M4 (upstream sync) are retired. | 2026-09-11 |
| D2 | Two registers, one per repository. The aa-env session is the single writer of this document; the aa-maven session is the single writer of the aa-maven register. Cross-references use canonical path plus local ID. (The per-M-row GitHub issue clause is superseded by D13.) | 2026-09-11 |
| D3 | The deployment baseline is aa-env `4d85e7f` (`maven` HEAD) with aa-maven `abf6545`, as-is. Modernization work does not gate the deployment. | 2026-09-11 |
| D4 | Both repositories use a `modernize` branch. The aa-env branch starts at cleanup `265f580`. | 2026-09-11 |
| D5 | Tomcat target is 11; 9.0.121 is the interim step on the 9.0.x line. | 2026-09-11 |
| D6 | SQLite as the configuration database stays in the Backlog until assigned. | 2026-09-11 |
| D7 | The ansible/cloud deployment work (install sequence document and deployment gate) moves to the Backlog and is built together with the EPICS-env provisioning, not on its own; the NewHope baseline stays frozen for it. | 2026-09-11 |
| D8 | The M5 Tomcat 9.0.121 live-install checks (T1, T2) are deferred; the version bump is committed, and the running-service verification is done at the M10 install-test phase or at deployment, not against this host now. | 2026-09-11 |
| D10 | Toolchain: the distro JDK package only (`openjdk-21-jdk-headless`, `JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64`) and the Apache Maven Wrapper committed in aa-maven (`./mvnw`, pinned 3.9.9); aa-env installs no Maven and drops java-env. Declarative per-OS package lists and one installer replace `scripts/required_pkgs.sh`. Supersedes the M4 Maven question. | 2026-09-12 |
| D11 | Runtime through Phase 2: the four WARs run on Tomcat 9 (fixed at 9.0.121), with SQLite as the only configuration store. Supersedes D5 (no Tomcat 11) and D6 (SQLite is active, not backlog); aa-env rows M7 and M12 and gate G4 are retired. The post-Phase-2 runtime (no Tomcat) is built in the EPICS-Arche repository, not here. Launcher: see D12. | 2026-09-12 |
| D12 | The launcher stays `scripts/archappl.bash` called by the existing single systemd service. The asymmetric start order (mgmt, engine, etl, retrieval) and stop order (engine, retrieval, etl, mgmt) live in the script, which `After=` ordering cannot express; the template-unit and conductor-unit designs are dropped and M16 retires. The script's restart-order defect was already fixed on cleanup (`e504e5c`). The SQLite-only clause is superseded by D15. | 2026-09-12 |
| D13 | Issues and milestones are per-repository and independent: aa-env and aa-maven each run their own, with no per-M-row issue and no mirrored peer issue URL (supersedes the D2 per-row clause). The two sides coordinate by ongoing cross-session conversation; a cross-reference is recorded in the register only where one side actually affects the other -- a prerequisite or a shared change -- as an external-gate (G) row citing the peer register path and local ID. Each detail's GitHub Projection fields stay unused unless that row is given its own issue. | 2026-09-13 |
| D14 | Correct the code-to-documentation review findings in M17. M3 completes as an outcome of M8 and is not its prerequisite. Preserve historical verification observations, qualify the defective Phase 2 verdict, and retain unresolved issues #24 and #25 as Open Backlog work rather than asserting a fix. | 2026-09-15 |
| D9 | Boundary between the two repositories: aa-env owns provisioning, deployment layout, service configuration, source baseline pinning, and the site skin; aa-maven owns source, the Maven build (Ant and Gradle leftovers consolidated onto Maven), dependency management, upstream cherry-pick policy, and independent bug fixes. Build-flavored leftovers inside aa-env are aa-env cleanup rows gated on aa-maven rows; compile verification moves to aa-maven CI and aa-env keeps install tests. No aa-env row migrates; the legacy build items already exist on the aa-maven register. | 2026-09-11 |
| D15 | MariaDB and SQLite run in parallel as selectable persistence backends, not SQLite-only. The backend is chosen at install in `context.xml` (a `DB_BACKEND` selector renders the driver class, URL, and initialization); the aa-maven source auto-detects the dialect from the DataSource metadata, so both `mariadb-java-client` and `sqlite-jdbc` stay shipped in the WARs. Supersedes the SQLite-only clause of D11; aa-maven records the same model as its D28/D29 (`ab324afb`, `263805a1`). | 2026-09-18 |
| D16 | DB-backend rollout order: MariaDB over TCP first, then MariaDB over Unix domain socket, then SQLite3 as the end state. The ansible/cloud provisioning starts on TCP MariaDB, agreed with LAB-ansible-provision and LAB-cloud-provision. Refines D15. | 2026-09-19 |
| D17 | Align aa-env with aa-maven on Ant removal: it is deferred out of Phase 1 on both sides. aa-maven moved its Ant-removal row (their M10) to the backlog on 2026-09-19 (their D7). aa-env confirmed this first-hand at aa-maven modernize `3c96141d`, whose commit subject is `Move M7 and M10 to the backlog and close out Phase 1`: their register `docs/milestone-daff1b7.md` carries M10 as `Deferred` with an assignment-history row recording the 2026-09-19 move, and the `maven-antrun-plugin` execution `sitespecificantscript` there still drives `build.xml` target `sitespecificbuild`. G10's completion criterion therefore covers the tomcat-servlet-api pin (observed 9.0.122, not the 9.0.121 the gate first named) and the Maven CI only, and G10 closes on that basis. aa-env M14 (Ant leftovers) becomes Deferred and leaves M8's dependency list; G6 stays Open and blocks no row; M14 returns to Not started only by a new dated decision. | 2026-09-20 |
| D18 | The four install-to-running findings from the ansible-provision archiver-dev run are taken as aa-env milestone work (M22-M25), not raised as issues on the reporting side: the JVM heap default, instance supervision under the single systemd unit, the dead jsvc shutdown path, and the `MAVEN_OPTS` name and proxy semantics. Each was re-derived in this repository before assignment. The same run supplies M8's Release Verification 2 and 3 observations, taken at aa-env `fb43522` with aa-maven `3c96141d`; the install and runtime paths (`site-template/`, `scripts/`, `configure/CONFIG_SITE`, `configure/CONFIG_SRC`) are unchanged between `fb43522` and `e06c554`, so those observations carry to the current tree. | 2026-09-21 |
| D19 | M23 reports a dead instance and does not recover it: no automatic restart, and the report comes from a health unit separate from the appliance service. A watcher running as the service's own main process was rejected because `systemd.service` states the stop operation is always performed once a service started successfully, "even if the processes in the service terminated on their own or were killed", so `ExecStop` would run `archappl.bash shutdown` and take the surviving instances down with it -- not the report-only behaviour wanted. Per-instance units stay excluded by D12 and are independently unsound here: the asymmetric start and stop order exists because the four components depend on one another, so restarting one alone bypasses that dependency. Consolidating the four webapps into a single Tomcat would dissolve both this and the M22 heap arithmetic, but it trades away per-component isolation and changes the install layout, so it stays a separate question outside M23. | 2026-09-21 |
| D20 | aa-env follows the aa-maven `modernize` branch through `SRC_TAG` instead of pinning a verified commit. Source-side improvements then arrive on the next checkout with no re-pin, at the cost of the build basis moving whenever aa-maven moves; verification therefore records the source commit it actually observed rather than assuming a fixed one, and the release step re-checks the source commit in force at that time. Confirmed 2026-09-21, after aa-maven moved `3c96141d` to `85f0f179`. | 2026-09-21 |
| D21 | The archive store's filesystem and the ETL timing become aa-env work (M26), scoped to the test environment first rather than to production storage architecture. Two facts drive it. On the provisioned hosts the archive store resolves to the root volume, nothing in the install path mounts a dedicated one, and `ARCHAPPL_STORAGE_TOP` only names a directory, so an archiver that fills its store fills `/` and takes the whole host; no quota or threshold exists anywhere in the chain. Separately, the shipped store configuration puts MTS at `PARTITION_MONTH` with `hold=2`, so samples do not leave MTS for roughly two months and the second ETL hop cannot be observed in any realistic test run. Production storage sizing, per-tier media selection and retention for real data stay outside this row. | 2026-09-21 |
| D22 | The empty configuration database reported by ansible-provision on three externally provisioned archiver-dev hosts becomes aa-env work (M28), tracked as issue #47, and is not raised on the reporting side. Re-derived in this repository: `sql.fill` checks database existence through the admin account, which the externally provisioned mode documented in `docs/README.install.md` never creates, and the not-found branch prints a message but exits 0, so the build continues. Paths that act as the application account check existence through that account; a not-found result or failed check reports and exits non-zero; paths that act as the admin account keep the admin check. The externally provisioned mode therefore needs no admin account. | 2026-09-23 |
| D23 | The ETL-timing half of M26 moves to its own work item, M31, so it can proceed without the archive-store filesystem work; M26 keeps the filesystem half. The store granularity and hold become Make variables substituted into the existing `site-template/policies.py.in` instead of a second, test-only policy file, so the shipped defaults and a test host's values come from one template and differ only in `../CONFIG_SITE.local`, which `make <os>.conf` does not rewrite. aa-env rejects a granularity name outside aa-maven's `PartitionGranularity` and a hold that is not a positive integer; the cross-tier ordering check (STS no coarser than MTS, MTS no coarser than LTS) is requested from the ansible-provision operator, which writes the test values. | 2026-09-23 |
| D24 | Logging model for the four-Tomcat appliance, agreed with aa-maven on 2026-09-23 after a request from ansible-provision. journald collects and rotates: each JVM's logging writes only stdout and stderr, the access log is the one file stream that remains, and `catalina.out`, logrotate and the JULI dated file handlers go away. The single service stays (D12, D19): the launcher is the main process (`Type=exec`, `KillMode=mixed` so only the launcher gets SIGTERM and stops engine, retrieval, etl, mgmt in order, `Restart=no`, `TimeoutStopSec` from a measured ETL stop with `consolidateOnShutdown=true`), starts the four Tomcats in the foreground in the D12 order, waits on the Tomcat processes and exits non-zero after an ordered stop when one dies. Component identity is per stream: each child runs through `systemd-cat --identifier=archappl-<component> --level-prefix=true`, so `journalctl -t archappl-<component>` filters one component and the `<N>` prefix maps to journal priority; a multi-line stack trace becomes several entries and is documented as such. One `log4j2.xml`, aa-maven's in the WAR, with a Console PatternLayout without timestamp and with the `<N>` prefix, root level `${env:ARCHAPPL_ROOT_LOGGER_LEVEL:-INFO}`; aa-env stops shipping its own and keeps `LOG4J_CONFIGURATION_FILE` as a site override, unset by default; `systemd-cat` parses the prefix by default, so the layout and the launcher land in either order, and application lines carry the default priority until the layout arrives. Shipped root level INFO. The access log stays as a file stream with `maxDays="90"`. Retention 8 weeks, matching the EPICS IOC runner's procServ logrotate policy (weekly, rotate 8), as journald `MaxRetentionSec` with `SystemMaxUse` winning; the ansible-provision operator sets the journald values from the soak's per-stream counts. Ownership: aa-maven owns the layout, levels, docs and the RollingFile fallback; aa-env owns the unit, launcher, JULI configuration, the access valve, dropping its `log4j2.xml`, and the install guide; ansible-provision owns the host journald settings. | 2026-09-23 |
| D25 | Tomcat's internal logging and `java.util.logging` go through log4j2 instead of JULI. `org.apache.juli.SystemdFormatter`, named by `site-template/skel/conf/logging.properties` since `c83256e`, does not exist in any Tomcat release (the JULI formatters are `JdkLoggerFormatter`, `JsonFormatter`, `OneLineFormatter`, `VerbatimFormatter`), so `java.util.logging` falls back to `SimpleFormatter` and JULI cannot emit a priority prefix; the CA client's beacon messages also arrive through `java.util.logging`. Each instance therefore gets `log4j-api`, `log4j-core`, `log4j-appserver` and `log4j-jul` at the WAR's log4j version in `$CATALINA_BASE/log4j`, put on the Tomcat classpath by `bin/setenv.sh`, which also sets `LOGGING_MANAGER` to `org.apache.logging.log4j.jul.LogManager`; `log4j-appserver` replaces `org.apache.juli.logging.Log` through its service file and reads `log4j2-tomcat.xml`, which aa-env ships with a Console layout carrying the same `<N>` prefix as the WAR layout and root level INFO. The WAR keeps its own `log4j2.xml` (D24). aa-maven's build emits the jar set next to the WARs so both come from one build and one version. Amends D24 in two places: the JULI configuration gives way to `log4j2-tomcat.xml`, and the appliance runs two log4j2 configurations, the WAR's for application lines and the Tomcat-level one for Tomcat and `java.util.logging` lines; the rest of D24 stands. | 2026-09-24 |

### Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| M2, G5 (`docs/milestone-265f580.md`) | Milestone section, branch modernize | Backlog section, branch modernize | `621312f` | `621312f` |
| M9, M11 (`docs/milestone-265f580.md`) | Backlog section, branch modernize | Milestone section, branch modernize (retitled per D10/D11) | this synchronization commit | this synchronization commit |
| M12 (`docs/milestone-265f580.md`) | Backlog section, branch modernize | Milestone section, branch modernize (retired per D11) | this synchronization commit | this synchronization commit |
| M2 (`docs/milestone-265f580.md`) | Backlog section, branch modernize | Milestone section, branch modernize | this synchronization commit | this synchronization commit |
| M10, M13, M18, M19, M27 (`docs/milestone-265f580.md`) | Backlog section, branch modernize | Milestone section, branch modernize (assigned 2026-09-22) | this synchronization commit | this synchronization commit |

### Milestone Details

Verification note (2026-09-15): the historical Phase 2 results below are retained
as observations of their original runs. The pre-M17 `run_logged` helper can
report a failed build as successful when earlier artifacts remain, so a Phase 2
PASS alone does not establish build success. M17 records fresh real-build and
failure-path checks; M8 still requires its own final-tree and live-install checks.

#### M1 - aa-env baseline tag and reproducible source pin

Origin: 265f580 / M1
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

Freeze the state that the cloud/ansible deployment installs: aa-env `4d85e7f`
and aa-maven `abf6545`. Provide a recipe that reproduces that source checkout
without editing tracked files.

##### Scope

- Annotated tag `NewHope` on aa-env `4d85e7f` (name decided 2026-09-11,
  paired with the aa-maven tag of the same name; owner runs the tag and push).
- A `configure/RELEASE.local` recipe that sets `SRC_TAG` to the aa-maven baseline
  tag, so `make init` on the tagged aa-env state clones the pinned aa-maven state.
- Tag names: aa-env `NewHope` -> `4d85e7f` (tag object `9d092f0`); aa-maven
  `NewHope` -> `abf6545` (tag object `ffbea94`).

Out of scope: any change to `configure/RELEASE`; the aa-maven tag itself (G1);
the deployment (M2, G5).

##### Completion Criteria

- The aa-env tag `NewHope` exists on `origin` and points at `4d85e7f`.
- A fresh clone of the aa-env tag plus the `RELEASE.local` recipe yields
  `epicsarchiverap-maven-src` at `abf6545`.

##### Dependencies And Decisions

- D3
- 2026-09-11: step 1 executed by owner direction (tag created by the owner,
  push delegated); step 2 verified by T2 after G1 completed.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-11, owner approved the `NewHope` tag name and the `RELEASE.local` pin in session
Implementation Authorization: 2026-09-11 (owner created the tag; tag push and T2 delegated)
Superseded Plan Artifacts: none

1. Present the one-line `git tag -a NewHope 4d85e7f` and
   `git push origin refs/tags/NewHope` commands for the owner.
2. Write the `RELEASE.local` recipe in the M2 sequence document
   (`SRC_TAG:=NewHope`), verified by T2.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Repository | `git ls-remote --tags origin` | aa-env checkout | `refs/tags/NewHope` present; `git rev-parse NewHope^{commit}` prints `4d85e7f` |
| T2 | Build system | Fresh clone at aa-env `NewHope`, add `configure/RELEASE.local` with `SRC_TAG:=NewHope`, run `make init` | Debian 13 host | `git -C epicsarchiverap-maven-src rev-parse --short HEAD` prints `abf6545` |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-11 | aa-env checkout | Pass | `git ls-remote --tags origin refs/tags/NewHope` returned tag object `9d092f0`; `rev-parse NewHope^{commit}` = `4d85e7f` |
| T2 | 2026-09-11 | Debian 13 host, fresh clone in a scratch directory | Pass | `git clone --branch NewHope` of aa-env gave `4d85e7f`; `configure/RELEASE.local` with `SRC_TAG:=NewHope`; `make init` checked out `epicsarchiverap-maven-src` at `abf6545`, `git describe --tags --exact-match` = `NewHope` |

##### Closure Evidence

- T1 and T2 observed 2026-09-11; aa-maven push notice of the same day.

##### GitHub Projection

Title: Freeze deployment baseline: aa-env tag and aa-maven source pin
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M3 - Land register on maven and retire legacy roadmap

Origin: 265f580 / M3
Identity History: none
GitHub Issue: none
Status: Not started

##### Summary

Confirm that the register and legacy-roadmap removal land on `maven` with M8.
The legacy GitHub issues and milestones are already retired through G2.

##### Scope

- Confirm that M8's merge carries this register and the already committed
  removal of `docs/MILESTONES.md` onto `maven`.
- Keep the legacy GitHub retirement evidence from G2. No new per-row issues
  are created (D13).

Out of scope: a separate PR or merge, new feature work, and reopening the retired
GitHub roadmap. M8 owns the integrated checks and release execution.

##### Completion Criteria

- `origin/maven` contains this document and not `docs/MILESTONES.md`.
- Issues #35–#42 and milestones M0–M5 are closed on GitHub. Done 2026-09-13 (G2).
- No per-row GitHub issues are created (D13); this register is the sole tracker.

##### Dependencies And Decisions

- M8: the register-on-maven half is performed by M8's fast-forward merge;
  this row completes when that lands (not a gate, so this row is Not started
  with Ready No until M8, not Blocked).
- G2 Complete 2026-09-13: the legacy roadmap is retired.
- D1, D2, D13, D14

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Wait for M8's verified merge to `maven`; this row does not gate that merge.
2. Verify the final branch contents and confirm that G2 remains complete.
3. Record the landing commit and close this row together with the M8 result.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Repository | Read `origin/maven:docs/milestone-265f580.md` and inspect its tracked paths after fetching | aa-env checkout | This register is present; `docs/MILESTONES.md` is absent |
| T2 | Repository | `git merge-base --is-ancestor <register commit> origin/maven` | aa-env checkout | Exit 0 |
| T3 | Tracker | Read issue and milestone states through the GitHub REST API | GitHub | Issues #35-#42 and milestones M0-M5 remain closed |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | aa-env checkout | Pending | none |
| T2 | Not run | aa-env checkout | Pending | none |
| T3 | Not run | GitHub | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Land the canonical work register and retire the legacy roadmap
Labels: documentation
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M4 - Residual configure and script defects

Origin: 265f580 / M4
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

Fix the defects found in the 2026-09-11 review that the cleanup commits did
not cover, and guard each with a phase 1 assertion.

##### Scope

- `configure/RULES_FUNC` `checkfile`: the `$(if $(wildcard ...))` branches
  are inverted, and the only caller (`db.conf` in `RULES_SQL`) passes a
  quoted path that `$(wildcard)` never matches; the two defects masked each
  other so the stale file was always removed. Fixed 2026-09-11.
- `configure/RULES_INSTALL` `serverxml.install`: engine and etl receive each
  other's `ARCHAPPL_SHUTDOWN_*_PORT` value. Fixed 2026-09-11.
- `configure/RULES_REQ` `get.jdbc` / `install.jdbc`: an unused manual
  alternative that copies the driver into `TOMCAT_HOME/lib`; Maven already
  packages `mariadb-java-client` into each WAR (runtime scope); the built
  WARs in `target/` and the installed tree carry the driver only inside the
  four WARs, and the Tomcat lib holds none. Not wired into `install` or
  `build`, not documented. Removed 2026-09-11 (owner choice), together with
  the `jdbc` download case in `scripts/install_java_pkgs_local.bash`.
- `scripts/required_pkgs.sh` Debian 13: no Maven; README relies on
  java-env for it. Superseded 2026-09-12 by D10: the script is replaced under
  M11 and aa-env installs no Maven at all.
- `tests/phase1-logic.bash` `EXPECTED_BRANCH` defaulted to `cleanup`, so
  P1.1 only warned on `modernize`. Default changed to `modernize` (owner
  choice a, 2026-09-11); the variable stays overridable.

Examined on `modernize` and found already fixed by the cleanup commits, so
not part of this row: the README "Debian 12" wording (Debian 13 throughout
since `6d294f3`) and the `.gitignore` `test*` pattern (followed by
`!/tests/` and `!/tests/**` since `dc8628d`; `tests/` is tracked).

Out of scope: defects already fixed on the cleanup commits; anything in the
aa-maven.

##### Completion Criteria

- Each defect item above has a phase 1 assertion in `tests/phase1-logic.bash`
  that fails on the old behavior and passes on the fix. The `EXPECTED_BRANCH`
  default is a test-harness setting, not a defect: its evidence is P1.1
  passing on `modernize` instead of warning.

##### Dependencies And Decisions

- Owner choice 2026-09-11: remove the jdbc rules rather than annotate them.
- Owner choice 2026-09-11: phase 1 expects `modernize` by default.
- D10 (2026-09-12) retires the Maven item to M11; nothing remains open here.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-11, owner accepted the assertion-first plan in session
Implementation Authorization: 2026-09-11, for the checkfile, serverxml, jdbc, and branch-default items
Superseded Plan Artifacts: none

1. Add the failing assertions first, run phase 1, observe the failures.
   Done 2026-09-11: P1.9 (checkfile, three checks), P1.10 (two checks),
   P1.11 (one check) added; each observed failing on the old code.
2. Apply each fix; re-run phase 1. Done 2026-09-11 for items 1 to 3 and
   the branch default.
3. Third-person review 2026-09-11: five findings accepted and applied — the
   `jdbc` download case removed from `scripts/install_java_pkgs_local.bash`,
   `CHANGELOG.md` and `tests/README.md` entries added, the completion
   criterion and the jdbc wording above corrected.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `tests/run-all-tests.bash --phase=1` | This host | New assertions pass; total count increases by the number added |
| T2 | Build system | `make -n install` | This host | Parses without error |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-11 | This host | Pass | `tests/run-all-tests.bash --phase=1`: passed=27 failed=0 (20 before; six new checks plus P1.1 now passing on `modernize`); the six new checks fail against the HEAD copies of the files |
| T2 | 2026-09-11 | This host | Pass | `make -n install` exit 0 after the RULES edits |

##### Closure Evidence

- Commit `0e02ede` (fixes, guards, CHANGELOG, tests README); T1 and T2
  observed 2026-09-11; third-person and second-person passes the same day;
  the Maven item retired by D10 on 2026-09-12.

##### GitHub Projection

Title: Fix residual configure and script defects with phase 1 guards
Labels: bug
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M5 - Tomcat 9.0.121, the fixed Phase 2 version

Origin: 265f580 / M5
Identity History: retitled from "Tomcat 9.0.121 interim bump" 2026-09-12 (D11)
GitHub Issue: none
Status: Complete

##### Summary

Set the aa-env Tomcat to 9.0.121, the latest 9.0.x. Under D11 this is the
fixed runtime version through Phase 2; there is no later Tomcat 11 step.

##### Scope

- `configure/CONFIG_TOMCAT`: `TOMCAT_MINOR_VER` 0.113 to 0.121.
- `docs/technicaldocs/README.tomcat.md`: example output shows 9.0.87;
  refresh.
- Inform the aa-maven session so `tomcat-servlet-api` in the pom moves in
  lockstep (informational; not a gate).

Out of scope: Tomcat 10 or 11 (retired by D11); the aa-maven pom.

##### Completion Criteria

- `configure/CONFIG_TOMCAT` and the Tomcat README name 9.0.121 and the change
  is committed. The live install and start are verified by M8 Release
  Verification 2 and 3 (re-homed there when M16 retired, D12).

##### Dependencies And Decisions

- D8: the live-install checks were deferred; they are carried by M8 Release
  Verification 2 and 3 (start the service, probe, archive a PV), and this
  row's own checks became the committed configuration values (D12 re-homed
  them from the retired M16).
- D11: 9.0.121 is the fixed Phase 2 version; the interim framing is retired.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-11, owner accepted the 9.0.121 bump in session
Implementation Authorization: 2026-09-11, config bump only; live install not run on this host per D8
Superseded Plan Artifacts: none

1. Edit `CONFIG_TOMCAT` and the tomcat README. Done 2026-09-11 (`aea623b`).
2. Live install and start are verified under M8 Release Verification 2 and 3
   using the existing service and launcher script.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Config | `make -s print-TOMCAT_VER` | This host | `9.0.121` |
| T2 | Config | `grep -c 9.0.121 docs/technicaldocs/README.tomcat.md` | This host | 3 (lines; the URL line holds two occurrences) |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-12 | This host | Pass | `make -s print-TOMCAT_VER` printed `9.0.121` (config from commit `aea623b`) |
| T2 | 2026-09-12 | This host | Pass | `grep -c 9.0.121 docs/technicaldocs/README.tomcat.md` printed `3` (commit `aea623b`) |

##### Closure Evidence

- Config bump committed `aea623b`; T1 and T2 observed 2026-09-12; the version
  is fixed by D11. The live install and start are M8 Release Verification 2
  and 3.

##### GitHub Projection

Title: Bump Tomcat to 9.0.121
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M6 - Single-source pom: remove aa-env pom overwrite

Origin: 265f580 / M6
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

Today `make init` and `build.mvn` copy aa-env's `pom.xml` over the source
clone on every build (`configure/RULES_SRC` target `pom`). Once aa-maven
carries the canonical pom (G3), aa-env stops shipping one.

##### Scope

- Remove the `pom` target and its use from `init`, `build.mvn`,
  `build.mvn2`, `build.mvn3`, `build.war`, `build.mvndeps`.
- Delete `pom.xml` from aa-env; remove the untracked `pom.xml.aa`.
- Update README and the phase 2 test that assumes the copy.

Out of scope: pom content; the aa-maven build.

##### Completion Criteria

- `make init build.mvn` produces the four WARs with no `pom.xml` in aa-env.
- The source clone shows a clean `git status` after a build.

##### Dependencies And Decisions

- G3 Complete 2026-09-12: the canonical pom is `9be652c` (about 96 diff lines
  from the aa-env copy); the removal must land together with any `SRC_TAG`
  at or past that commit
- D2

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-12, owner chose `SRC_TAG:=modernize` (track the source development branch; deployments stay pinned by NewHope)
Implementation Authorization: 2026-09-12, in session with the `SRC_TAG` choice
Superseded Plan Artifacts: none

1. Set `SRC_TAG:=modernize` in `configure/RELEASE`. Done 2026-09-12.
2. Remove the `pom` target and aa-env `pom.xml` in the same change (the
   canonical pom drops the system-scope jars, so the stale copy would break
   the build); `pom.xml.aa` removed with a scratch copy kept for the
   session. Done 2026-09-12 (`0e9cee6`).
3. Run phase 2. Done 2026-09-12; see Verification Results.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Compile | `tests/run-all-tests.bash --phase=2` | This host | Four WARs produced; no `pom.xml` in aa-env |
| T2 | Repository | `git -C epicsarchiverap-maven-src status --porcelain` after build | This host | Empty |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-12 | This host | Pass | `tests/run-all-tests.bash --phase=2`: phase 1 passed=27, phase 2 passed=14; four WARs, release tarball, and Sphinx docs built from source `6957bfc` with no `pom.xml` in aa-env |
| T2 | 2026-09-12 | This host | Pass | `git -C epicsarchiverap-maven-src status --porcelain` empty after the build |

##### Closure Evidence

- Commit `0e9cee6`; T1 and T2 observed 2026-09-12 against source `6957bfc`.

##### GitHub Projection

Title: Stop overwriting the aa-maven pom.xml from aa-env
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M7 - Tomcat 11 migration (aa-env side)

Origin: 265f580 / M7
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

Move the aa-env runtime to Tomcat 11 once the aa-maven has migrated to the
jakarta servlet namespace (G4). Tomcat 9.0.x support ends no earlier than
2027-03-31 per the Apache Tomcat project.

##### Scope

- `configure/CONFIG_TOMCAT`: major 11, URL, install location name.
- `site-template/skel/{conf,bin}` and `startup.sh.in` / `shutdown.sh.in`
  aligned with Tomcat 11 layout.
- `configure/RULES_TOMCAT` and `RULES_INSTALL` sed patterns for
  `server.xml`.
- Documentation.

Out of scope: source changes (aa-maven); Tomcat 10.1.

##### Completion Criteria

- Four WARs from the jakarta aa-maven build start on Tomcat 11 on this host.
- One test PV is archived and retrieved.

##### Dependencies And Decisions

- D11 retires this row.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Not executed. Retired by D11 before any work.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime | `make sd_start` then `curl http://localhost:17665/mgmt/bpl/getApplianceInfo` | This host, Tomcat 11 | HTTP 200 |
| T2 | Function | Archive one PV, then `curl http://localhost:17668/retrieval/data/getData.json?pv=<pv>` | This host | Non-empty samples |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Pending | none |
| T2 | Not run | This host | Pending | none |

##### Closure Evidence

- Retired 2026-09-12 by D11: Tomcat 9 is fixed for Phase 2, so there is no
  Tomcat 11 migration on the aa-env side. T1 and T2 waived.

##### GitHub Projection

Title: Migrate the aa-env runtime to Tomcat 11
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M12 - Tomcat 9.1.x fallback

Origin: 265f580 / M12
Identity History: Backlog (Conditional) to Milestone as a retired row, 2026-09-12 (D11)
GitHub Issue: none
Status: Complete

##### Summary

If Tomcat 9.0.x had reached end of support before a Tomcat 11 move, the
runtime would have moved to the 9.1.x extended-support branch. D11 fixes
9.0.121 for Phase 2 and places the post-Phase-2 runtime (no Tomcat) in
EPICS-Arche, so the condition can no longer arise here.

##### Scope

- `configure/CONFIG_TOMCAT` major/minor and URL for 9.1.x (not executed).

Out of scope: any source change.

##### Completion Criteria

- Retired; no deliverable.

##### Dependencies And Decisions

- D11 retires this row (2026-09-12).

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Not executed. Retired by D11.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime | `make tomcat install`; mgmt probe on 9.1.x | This host | HTTP 200 (waived) |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Waived | Retired by D11 |

##### Closure Evidence

- Retired 2026-09-12 by D11: Tomcat 9.0.121 is fixed through Phase 2 and no
  host Tomcat remains after it. T1 waived.

##### GitHub Projection

Title: Tomcat 9.1.x fallback for the aa-env runtime
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M8 - Modernized baseline release to maven

Origin: 265f580 / M8
Identity History: none
GitHub Issue: none
Status: Not started

##### Summary

Merge the completed `modernize` work into `maven` only after the install
verification passes on this host against the finished aa-maven Phase 1
source. Order: G10 (aa-maven Phase 1 done) -> install and run on this host
(Release Verification 2 and 3) -> PR `modernize` to `maven`. No PR is opened
before the install verification passes. The merge is a fast-forward (owner
choice 2026-09-12); `modernize` is ahead of `maven` with nothing behind.

##### Scope

- Final pull request from `modernize` to `maven`.
- Release tag on the merge commit.
- `CHANGELOG.md` `[Unreleased]` becomes a dated section.

Out of scope: any new feature.

##### Completion Criteria

- Release Verification 1–4 recorded with evidence.

##### Dependencies And Decisions

- M1, M4, M6, M9, M11, M15, M16, M17
- G10 (aa-maven Phase 1 complete); Complete 2026-09-20 on the D17 basis, so this
  row resumes at the recorded Not started
- D17. 2026-09-20: M14 (Ant leftovers) is Deferred and leaves this list; Ant
  removal is out of the release scope on both sides.
- The install verification (Release Verification 2 and 3) runs against the
  aa-maven Phase 1 source before any PR; fast-forward merge per owner choice
  2026-09-12.
- D11 and D12 retired the Tomcat migration and template-unit work. The existing
  service and script carry the runtime; this row owns its live verification.
- D14: M3 is completed by this row's merge and is not a prerequisite.
- D7: the ansible deployment (M2, G5) is Backlog and does not gate this row.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Re-run the integrated checks below on the final tree.
2. Prepare the pull request, tag, and changelog edit for the owner.

##### Integrated Verification

| Source Check | Re-run Trigger | Shared Surface | Release Verification Label | Expected Result | Result Evidence |
| --- | --- | --- | --- | --- | --- |
| M17 / T1 and T3 | Final tree | `tests/` | Release Verification 1 | Phase 1 and 2 pass with correct failure handling | pending |
| M5 (deferred live checks, D8/D12) | Final tree | Runtime | Release Verification 2 | HTTP 200 from the mgmt probe | pending |
| M8 first observation (PV archive on the install) | Final tree | Function | Release Verification 3 | one PV archived and retrieved | pending |

##### Production Environment Tests

| Release Verification Label | Timing | System | Version | Architecture | Deployment Path | Method | Expected Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Release Verification 3 | pre-PR | This host | Debian 13 | x86_64 | `make install` then start the service on the aa-maven Phase 1 source | README procedure | mgmt URL 200, one PV archived | pending |

##### Version Changes

| Field | File | Before | Planned After | Pre-check | Pre-check Label | Post-check | Post-check Label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Unreleased heading | `CHANGELOG.md` | `[Unreleased]` | dated section | `grep -n Unreleased CHANGELOG.md` | Release Verification 4 | same | Release Verification 4 |

##### Release Execution

| Step | Action | Authorization | Expected Result | Evidence |
| --- | --- | --- | --- | --- |
| 0 | Install-verify on this host against the aa-maven Phase 1 source (Release Verification 2 and 3 pass) | owner | mgmt probe 200, one PV archived | pending |
| 1 | Open the PR `modernize` to `maven` with the verification result | owner | PR opened | pending |
| 2 | Fast-forward `maven` to `modernize` (`git push origin origin/modernize:maven`) | owner | `origin/maven` equals `origin/modernize` | pending |
| 3 | Annotated tag on the merged commit | owner | tag on origin | pending |

##### Release Verification Plan

| Label | Layer | Timing | Method | Environment | Expected Result | Evidence Target |
| --- | --- | --- | --- | --- | --- | --- |
| Release Verification 1 | Logic and compile | pre-change | `tests/run-all-tests.bash --local` | This host | all pass | run log |
| Release Verification 2 | Runtime | pre-PR, on the aa-maven Phase 1 source | `make install` then start the service; mgmt probe | This host | HTTP 200 | curl output |
| Release Verification 3 | Function | pre-PR, on the aa-maven Phase 1 source | archive one PV, then retrieve it | This host | non-empty samples | curl output and retrieval sample |
| Release Verification 4 | Version | post-change | `grep -n Unreleased CHANGELOG.md` | aa-env checkout | dated heading present | file content |

##### Release Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| Release Verification 1 | Not run | This host | Pending | none |
| Release Verification 2 | 2026-09-21 | Three provisioned hosts (Rocky 8.10 x2, one built from bare for this check; Debian 13), aa-env `fb43522`, aa-maven `3c96141d`, Tomcat 9.0.121, OpenJDK 21, MariaDB over loopback TCP | Pass | LAB-ansible-provision drove the documented make sequence as root through its operator: `init`, `db.conf`, `conf.archapplproperties`, `build.mvn` and `sql.fill` completed under `set -e`; the als `classpathfiles` (`appliances.xml`, `archappl.properties`, `policies.py`) are packed in `WEB-INF/classes` of all four deployed webapps; four instances sit under the install root with the unit enabled and active and the storage root owned by the service account (0755); mgmt `/bpl/getApplianceInfo` returned 200 with identity `appliance0` and version 2025-6 on all three hosts. The privilege split was measured rather than derived: built as root, the four JVMs run as the service account. Observed on the reporting side, not on this host. Re-observed 2026-09-21 directly at `e06c554` on a freshly provisioned Rocky 8.10 host: a forced reinstall completed with failed=0 and left four instances, the unit active, the als `classpathfiles` in the deployed webapp, and mgmt returning 200 with identity `appliance0` and version 2025-6 on the first probe. The result therefore no longer rests on the D18 path-equivalence argument, which the reporting side also re-derived (`fb43522` is an ancestor of `e06c554`, and their diff touches nothing under `site-template/`, `scripts/`, `configure/CONFIG_SITE` or `configure/CONFIG_SRC`). |
| Release Verification 3 | 2026-09-21 | The same three hosts as Release Verification 2 | Pass | A 1 Hz calc record submitted through mgmt `/bpl/archivePV` moved Initial sampling to Appliance assigned to Being archived in about two minutes; `retrieval/data/getData.json` then returned 68 points carrying the record EGU at one-second spacing with incrementing values, and the short-term store held the expected `.pb` file. The fixture was removed afterwards. Re-applying the role reported no change, with the install tree, the four instance PIDs and the unit start time identical before and after. |
| Release Verification 4 | Not run | aa-env checkout | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Modernized baseline release to maven
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M14 - Remove Ant leftovers from aa-env

Origin: 265f580 / M14
Identity History: none
GitHub Issue: none
Status: Deferred

##### Summary

aa-env still carries Ant pieces from the pre-Maven build: an Ant build file
in the site overlay and `ANT_HOME` / `ANT_PATH` / `ANT_OPTS` in the site
configuration. M11 already removed Ant from the package lists. Once
aa-maven removes Ant from the build (its M10) and states how the per-site
build step is replaced, aa-env removes its half.

##### Scope

- `site-template/siteid/build.xml` (33 lines): remove, or replace per the
  post-Ant sitespecific contract aa-maven reports.
- `configure/CONFIG_SITE`: `ANT_HOME`, `ANT_PATH`, `ANT_OPTS` (lines 4, 9,
  43–49) and any `.local` preset that sets them.
- `configure/os/*.pkgs`: verify that no `ant` package remains. M11 already
  removed the legacy package scripts and omitted Ant from the new lists.
- `configure/RULES_SRC` `copy.sitespecific`: unchanged unless the contract
  changes the overlay path.

Out of scope: the aa-maven build itself; the overlay path
`src/sitespecific/<ARCHAPPL_SITEID>` and the `classpathfiles` packaging,
which aa-maven confirmed survive Ant removal.

##### Completion Criteria

- Phase 1 asserts: no `ANT_` variable in `configure/`, no
  `site-template/siteid/build.xml`, no `ant` package in `configure/os/*.pkgs`.
- `make build` against the post-Ant aa-maven source produces the four WARs
  with the site overlay applied.

##### Dependencies And Decisions

- G6 (aa-maven M10 and the post-Ant sitespecific contract); still Open, and it
  no longer blocks this row
- D9
- D17. 2026-09-20: Ant removal is deferred out of Phase 1 on both sides, so this
  row moves to Deferred and leaves M8's dependency list. aa-maven moved its M10
  to the backlog 2026-09-19; this row returns to Not started only by a new dated
  decision.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Read the contract aa-maven reports with G6; decide remove-or-replace for
   `site-template/siteid/build.xml`.
2. Add the failing phase 1 assertions, then remove the Ant pieces.
3. Run `make build` against the aa-maven commit named in G6.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `tests/run-all-tests.bash --phase=1` | This host | New assertions pass |
| T2 | Build | `make build` with `SRC_TAG` at the G6 commit | This host | Four WARs; `archappl.properties`, `log4j2.xml`, `policies.py` from the overlay present in each WAR (`unzip -l`) |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Pending | none |
| T2 | Not run | This host | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Remove Ant leftovers from the environment configuration
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M15 - Reduce phase 2 to a build-wrapper check

Origin: 265f580 / M15
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

Phase 2 checks the commands generated by the real `make -n build`: configuration
generation, site-overlay copying, and the source Maven Wrapper package command.
Under D9, aa-maven CI owns compilation and build artifacts; this local check
requires neither a source checkout nor a JDK and performs no build.

##### Scope

- `tests/phase2-compile.bash`: replace the full `make build.mvn` run with a
  wrapper check through the real `make -n build`: configuration commands,
  site-overlay copy, and the Maven Wrapper package command in the source tree.
- `tests/README.md`: phase 2 description and the phase table.
- `tests/run-all-tests.bash`: update the Phase 2 description; keep `--local`
  dispatching Phase 1 and Phase 2.
- This canonical detail: accepted plan and observed verification results.

Out of scope: phases 1, 3, 4; production build recipes; the aa-maven CI workflow.
The Phase 2 filename remains stable for existing direct callers.

##### Completion Criteria

- Phase 2 completes in seconds without a network fetch and passes on this
  host.
- `tests/README.md` states that compile verification runs in aa-maven CI.

##### Dependencies And Decisions

- G7 (aa-maven M5, CI on Maven); Complete 2026-09-20, so this row resumes at the
  recorded Not started
- D9. 2026-09-20: `build.mvn` now skips tests (`-DskipTests`); the test suite
  runs in aa-maven CI (D9), so aa-env no longer duplicates it. That was a
  partial step toward M15; with G7 Complete, the full reduction of phase 2 to a
  wrapper check is unblocked.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-22; command-generation checks and local verification
Implementation Authorization: 2026-09-22; implement the accepted plan
Superseded Plan Artifacts: none

1. Replace Phase 2 toolchain, clone, configuration execution, build and
   artifact checks with the real Makefile dry run. Verify the configuration
   commands precede the site-overlay copy and that the copy precedes the
   Maven Wrapper `clean package -DskipTests` command in the source directory.
2. Update `tests/README.md` and the runner description to call Phase 2 a
   build-wrapper check. State that it verifies command generation only;
   compilation and build artifacts belong to aa-maven CI.
3. Run `tests/run-all-tests.bash --local` in this checkout and a copy of the
   real tracked files without a source checkout or build artifacts. Verify
   that no source checkout or generated build files appear.
4. In the copied checkout, break build dependencies, overlay copying and the
   package goal individually. Also reject a command such as `echo` before
   the wrapper while accepting simple unquoted environment assignments.
   Run the shipped tests and require the expected result; restore each real
   file before the next case.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `tests/run-all-tests.bash --local`; Bash syntax and ShellCheck | This host | Phase 1 and the reduced Phase 2 pass; no new ShellCheck warnings |
| T2 | Build wrapper | Run the real `--local` entrypoint in a copy of tracked files without source or build artifacts; compare files before and after | Local isolated checkout | Passes without cloning, building or generating configuration files |
| T3 | Regression | Mutate build connections, overlay copy and package goal individually in the isolated checkout; run the shipped Phase 2 | Local isolated checkout | Each broken command path fails; restored checkout passes |
| T4 | Regression | Insert commands or simple environment assignments before the wrapper in the real build recipe; run the shipped `--local` entrypoint | Local isolated checkout | Commands are rejected; environment assignments pass |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-22T18:17:48Z | Working tree based on `84b38e5` | Pass | `TMPDIR=/tmp tests/run-all-tests.bash --local`: Phase 1 59 passed, Phase 2 14 passed, no failures. Bash syntax checks and `git diff --check` pass. Phase 2 passes both warning-level and full ShellCheck; runner diagnostics are unchanged against HEAD under the same command and version. |
| T2 | 2026-09-22T08:25:09Z | Copy of real tracked working-tree files, no source checkout or build artifacts | Pass | Both `--local` and `--phase=2` exit 0 in under one second: Phase 1 58 passed (branch sanity is warn-only without Git metadata), Phase 2 14 passed. Checkout file hashes and paths are unchanged, and no source checkout appears. A real `CONFIG_SITE.local` with a nonexistent JDK path and nonempty Maven flags also passes. |
| T3 | 2026-09-22T08:25:09Z | Real Makefile and shipped Phase 2 in the isolated checkout | Pass | Removing configuration or Maven dependencies, reversing build order, removing the overlay prerequisite, changing the goal, source directory, wrapper or copy destination, and omitting each of six configuration targets all exit 1 (14 mutations). A broken goal also fails with a prior successful dry run in LOGFILE. Each original file is restored between cases; the final `--local` run passes. |
| T4 | 2026-09-22T18:17:48Z | Real Makefile and shipped `--local` in a source-free copy | Pass | Before the correction, an `echo` prefix incorrectly passed. After the correction, `echo`, `false &&` and `:` prefixes exit 1 at the Phase 2 invocation check; populated and empty environment assignments pass. All 14 earlier mutations also fail through `--local` (the wrong-wrapper case is caught in Phase 1). An `echo` prefix still fails with an earlier successful dry run in LOGFILE. Restoring the real recipes yields Phase 1 58 passed and Phase 2 14 passed; checkout files are unchanged. |


##### Closure Evidence

- The wrapper check and documentation are implemented and locally verified.
  The accepted scope is command generation only, not compilation or runtime
  installation. Code and reader-facing documentation were checked against
  the accepted plan and the real execution results with no blocking finding.
- Complete 2026-09-22. Landed at `d748d4f2bcbde9440e44d2cdc293f9245494b3e0` on `origin/modernize`; no GitHub issue is assigned to this row.
- Observed 2026-09-22T19:05:49Z after `git fetch origin`: `git merge-base --is-ancestor d748d4f origin/modernize` exited 0. Comparing HEAD with `origin/modernize` at `d748d4f` using `git diff --exit-code` for every path listed by `git diff-tree --no-commit-id --name-only -r d748d4f` found no differences. Together with T1-T4 and the completed G7 dependency, this satisfies the completion criteria.

##### GitHub Projection

Title: Reduce phase 2 to a build-wrapper check; compile verification in aa-maven CI
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M9 - Selectable persistence backend: MariaDB and SQLite

Origin: 265f580 / M9
Identity History: Backlog "SQLite as the configuration database" to Milestone, retitled 2026-09-12 (D11), reframed to the selectable model 2026-09-18 (D15)
GitHub Issue: #43
Status: Not started

##### Summary

Under D15 MariaDB and SQLite are selectable backends; D16 sets the rollout
order: MariaDB over TCP first, then MariaDB over Unix domain socket, then
SQLite3 as the end state. The aa-maven source ships both `mariadb-java-client`
and `sqlite-jdbc` and auto-detects the dialect from the DataSource metadata
(gate G9), so no source change is needed to run MariaDB or SQLite. The
ansible/cloud provisioning starts on TCP MariaDB (agreed 2026-09-19). aa-env
renders the per-instance DataSource for the chosen backend and wires its
initialization.

##### Scope

- `site-template/context.xml.in`: a `DB_BACKEND` selector (`mariadb` | `sqlite`)
  that renders the driver class, URL, and pool settings for the chosen backend.
  MariaDB over TCP uses `jdbc:mariadb://<DB_HOST_NAME>:<DB_HOST_PORT>/<DB_NAME>`
  (host `127.0.0.1`, port `3306`; IPv4 loopback, standardized 2026-09-19 to
  avoid `::1` ambiguity).
- `configure/CONFIG_SQL`, `configure/RULES_SQL`: the initialization for the
  selected backend (the MariaDB targets as today; SQLite from
  `archappl_sqlite.sql`). Where the operator creates the database and account
  (the ansible/cloud path), aa-env skips db.secure/db.addAdmin/db.create and
  runs only `make sql.fill`.
- `site-template/systemd/epicsarchiverap-maven.service.in`: the `mariadb.service`
  dependency applies only when the MariaDB backend is selected.
- MariaDB over UDS (step 2): the driver's `localSocket` needs JNA on the
  classpath, and the WARs built from aa-maven `3c96141d` carry `jna` and
  `jna-platform` 5.13.0 (G12 Complete 2026-09-21), so this step is not gated.
- Package list: MariaDB packages for the MariaDB backend, `sqlite3` for SQLite.
- Documentation.

Out of scope: the driver dependencies and dialect detection in the source
(aa-maven, gate G9); replacing the existing launcher or service design.

##### Completion Criteria

- One PV archives and retrieves under each backend in the D16 order —
  MariaDB/TCP, then MariaDB/UDS, then SQLite3 — with the selector the only
  change between them.

##### Dependencies And Decisions

- G9 Complete 2026-09-18 (both drivers ship, dialect auto-detected)
- M11 (ordering): the package change lands in the per-OS lists, not in
  `required_pkgs.sh`
- D15 (selectable backend), D16 (rollout order TCP -> UDS -> SQLite3)
- MariaDB/TCP account and connection model: aa-env is authoritative on the user
  name, `DB_USER_PASS`, database name, and that it connects over TCP loopback to
  `:3306`; the account grant host-spec is server-side. The provisioning contract
  (cloud-provision `290f459`) pins MariaDB `skip-name-resolve` ON with the
  account `@'127.0.0.1'`, and aa-env connects to `127.0.0.1` (IPv4 loopback, no
  `::1`; `DB_HOST_NAME=127.0.0.1` in `configure/CONFIG_SITE`). `DB_USER_PASS` is
  aa-env's value and the account is created to match it. `DB_ADMIN_HOST` stays
  `localhost`: it belongs to the local-only admin path
  (`make db.secure`/`db.addAdmin`/`db.create`), which the provisioning operator
  replaces, so it is outside the 127.0.0.1 application standardization.
  `make db.secure` keeps only `root@'localhost'` (unix_socket) and drops every
  other root account and all anonymous users with `DROP USER` (portable across
  MariaDB 10.3's `mysql.user` table and 10.4+'s view; on 10.4+ a direct `DELETE`
  on that view reports success but does not remove the account -- a silent
  no-op).
- The ansible and cloud provisioning sessions provide TCP MariaDB
  (`skip_networking=false`, `127.0.0.1:3306`) and create the database and
  account, so aa-env runs only `make sql.fill`. First TCP test agreed 2026-09-19;
  the TCP loopback login re-verified green on Rocky 8 and Debian 13 (reported
  2026-09-19): `skip_name_resolve=1`, TCP to `127.0.0.1` authenticates as
  `archappl@127.0.0.1`, listener `127.0.0.1:3306` only, no `::1`. This is the
  DB-login check only. The bring-up has since been reported: G5 closed
  2026-09-21 on the mgmt probe returning 200 on three provisioned hosts, and the
  same run archived and retrieved a PV over MariaDB/TCP. That does not close
  this row, because the PV ran against the current MariaDB-only wiring rather
  than a selected backend; T1 still needs the selector in place.
- G12 Complete 2026-09-21: the WARs already carry `jna` and `jna-platform`, so
  the MariaDB/UDS step needs nothing from aa-maven. An explicit declaration of
  those jars was requested there the same day as hardening, since they arrive
  transitively; it is not a precondition for this step.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. MariaDB/TCP: add the `DB_BACKEND` selector, render `context.xml` for
   MariaDB/TCP, run `make sql.fill`, start the units, and verify one PV.
2. MariaDB/UDS: render the `localSocket` URL form and verify over the socket;
   the JNA jars the driver needs are already in the WARs.
3. SQLite3: render the SQLite DataSource and initialization and verify with no
   DB service present.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Function | Select MariaDB/TCP; run `make sql.fill`; start the units; archive one PV; retrieve | This host or a provisioned host (Rocky 8 / Debian 13) | Non-empty samples |
| T2 | Function | Select MariaDB/UDS; start the units; archive one PV; retrieve | provisioned host (Rocky 8 / Debian 13) | Non-empty samples over the socket |
| T3 | Function | Select SQLite3; start the units; archive one PV; retrieve | This host | Non-empty samples; no MariaDB required |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Pending | none |
| T2 | Not run | provisioned host (Rocky 8 / Debian 13) | Pending | none |
| T3 | Not run | This host | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Selectable persistence backend
Labels: enhancement
GitHub Milestone: none
Observed State: open
Observed Labels: enhancement
Observed Milestone: none
Last Compared: 2026-09-21

#### M16 - Run the Tomcat 9 instances under systemd template units

Origin: 265f580 / M16
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

Proposed replacing `scripts/archappl.bash` with `archappl@.service` template
units. Retired by D12: the appliance's stop order (engine, retrieval, etl,
mgmt) is not the reverse of its start order, `After=` ordering can only
mirror, and the owner chose the script over a conductor unit. The existing
`epicsarchiverap-maven.service` calling `archappl.bash` stays the launcher;
the script's restart-order defect was fixed on cleanup (`e504e5c`).

##### Scope

- No deliverable. The template-unit and conductor designs are not built.

Out of scope: everything; see D12.

##### Completion Criteria

- Retired; no deliverable. The live runtime checks this row briefly carried
  moved to M8 (Release Verification 2 and 3).

##### Dependencies And Decisions

- D12 retires this row (2026-09-12).

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Not executed. Retired by D12.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime | `make sd_start`; mgmt probe (waived here) | This host | Carried by M8 Release Verification 2 |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Waived | Moved to M8 Release Verification 2 and 3 |

##### Closure Evidence

- Retired 2026-09-12 by D12; the live checks live on as M8 Release
  Verification 2 and 3.

##### GitHub Projection

Title: Run the Tomcat 9 instances under systemd template units (retired)
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M11 - Single distro toolchain: JDK, Maven Wrapper, package lists

Origin: 265f580 / M11
Identity History: Backlog "Single JDK source on the host" to Milestone, retitled, 2026-09-12 (D10)
GitHub Issue: none
Status: Complete

##### Summary

The host carries two JDK 21 installs (java-env's `/opt/java-env/JDK` and
Debian's `openjdk-21`) and two Mavens; `configure/CONFIG_SITE` points at
java-env while Maven resolves the Debian JDK. D10 replaces this with the distro
JDK package, the Maven Wrapper committed in aa-maven (`./mvnw`), and declarative
per-OS package lists instead of `scripts/required_pkgs.sh`.

##### Scope

- `configure/CONFIG_SITE` and `configure/os/*.mk`: `JAVA_HOME` from the distro
  path; remove `MAVEN_HOME`, `MAVEN_PATH`, `JAVA_LOCAL*`, the
  `CONFIG_SITE_{JDK,ANT,MAVEN}.local` hooks; `MAVEN_CMD := $(SRC_PATH)/mvnw`.
- `configure/RULES_REQ`: remove the local JDK/Ant/Maven install rules and
  `scripts/install_java_pkgs_local.bash`.
- `configure/os/<os>.pkgs` (one package per line) and one installer that reads
  the list for the detected OS; remove `scripts/required_pkgs.sh`.
- `README.md`: prerequisites and the package step; no java-env reference.
- Phase 1: assert no `java-env`, `MAVEN_HOME`, or `install_java_pkgs_local`
  reference in `configure/`, `scripts/`, or `README.md`; assert the Debian 13
  list exists and names `openjdk-21-jdk-headless`.

Out of scope: Ant pieces (M14); the wrapper itself (G8); Rocky and macOS lists
beyond a first-pass port.

##### Completion Criteria

- `make info.mvn` reports the distro JDK for both Maven and `JAVA_CMD`, and
  `MAVEN_CMD` ends in `/mvnw`.
- `make build` succeeds through the wrapper with no Maven installed outside
  `~/.m2`.
- `scripts/required_pkgs.sh` and `scripts/install_java_pkgs_local.bash` are gone
  and the phase 1 assertions pass.

##### Dependencies And Decisions

- G8 Complete 2026-09-12 (wrapper verified from a fresh clone)
- D10

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-12, owner directed the start with the plan as registered
Implementation Authorization: 2026-09-12, same direction (G8 already Complete)
Superseded Plan Artifacts: none

1. Package lists (`debian13`, `rocky8`, `macos`) and
   `scripts/install_os_packages.bash` written per the bash-coding root-script
   rules (fixed PATH, os-release parsed not sourced, non-interactive stdin
   guard, `--force`, `--list-only`, `--os`); shellcheck clean. Done 2026-09-12.
2. Distro `JAVA_HOME`, `MAVEN_CMD` to the source `mvnw`, java-env and
   local-install rules removed, README and phase 1/2 updated, P1.12
   assertions added (observed failing against the HEAD copies). Done
   2026-09-12.
3. Build through the wrapper; T1-T3 recorded. Done 2026-09-12 (T3 ran
   `make build.mvn`, the compile path; `make build` additionally runs the
   sudo-gated storage provisioning, which is host state outside this row).
4. Third-person review 2026-09-12: four findings applied; the OS presets
   (`configure/os/{rocky8,macbrew,macos,githubmac}.mk`) now name JDK 21
   paths, the macOS technical doc points at the new installer, the
   installer rejects a valueless `--os`, and the stale JAVA ignore entry
   is gone.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `tests/run-all-tests.bash --phase=1` | This host | New assertions pass; removed scripts absent |
| T2 | Build system | `make info.mvn` | This host | One JDK path; `MAVEN_CMD` ends in `/mvnw` |
| T3 | Build | `make build` with `SRC_TAG` at the G8 commit | This host | Four WARs; `~/.m2/wrapper` holds the pinned Maven |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-12 | This host | Pass | `tests/run-all-tests.bash --phase=1`: passed=35 failed=0 (27 before; eight P1.12 checks added); on a HEAD copy the first P1.12 check fails |
| T2 | 2026-09-12 | This host | Pass | `make info.mvn`: Maven 3.9.9 from `~/.m2/wrapper` (wrapper-downloaded), Java 21.0.12.1 at `/usr/lib/jvm/java-21-openjdk-amd64`; `MAVEN_CMD` ends in `/mvnw` |
| T3 | 2026-09-12 | This host | Pass | `tests/run-all-tests.bash --phase=2` (runs `make build.mvn` through the wrapper): passed=14 failed=0; four WARs, release tarball, Sphinx docs |

##### Closure Evidence

- Commit `f24ec5c`; implementation and T1-T3 observed 2026-09-12; the four
  review passes (two third-person, one second-person, plus the convergence
  pass) applied their findings before this commit. The host still carries
  the now-unused `/opt/java-env` tree and distro `maven` package; removing
  them is host operations outside the repository.

##### GitHub Projection

Title: Single distro toolchain: distro JDK, Maven Wrapper, declarative package lists
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M17 - Correct build verification and align documentation with code

Origin: 265f580 / M17
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

Make the compile test reject a failed build even when previous artifacts exist,
accept the source repository's artifact naming, and correct the documentation
and work records against the implementation.

##### Scope

- `tests/lib/common.bash`, Phase 1 regression coverage, and Phase 2 artifact checks.
- README, installation guides, policy and ETL guides, changelog, and this register.
- ETL figure source `docs/figures/datajourney.svg` and its six T1-T6 PNG exports.
- Record issues #24 and #25 as unresolved Backlog work with their live metadata.

Out of scope: fixing those runtime issues, installing or restarting services,
changing storage policy values, completing M15's CI-dependent scope, and changing
the aa-maven source or its register.

##### Completion Criteria

- The real command wrapper preserves a failing process's exit status.
- The shipped Phase 2 rejects a failed build with existing real build artifacts.
- A real clean build passes without hard-coded WAR or tarball version names.
- Changed documentation agrees with code, all local links resolve, and work-table
  details and dependencies agree.
- Repository changes have commit and remote landing evidence.

##### Dependencies And Decisions

- D14; no aa-maven gate is needed for these corrections.
- The source's `aa-<date>-<hash>` finalName is present at aa-maven `35282494`;
  the local source used by prior verification is `6957bfc4`.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-15, accepted the reported code-to-documentation findings
Implementation Authorization: 2026-09-15, directed all reported corrections
Superseded Plan Artifacts: none

1. Add a command-exit regression test; observe its failure on the old helper.
2. Preserve the child exit status; generate the site configuration with the
   shipped `conf.archapplproperties` target; check unique service WARs and the
   assembly produced by the successful clean build without fixing their names.
3. Correct the runtime, install, policy, ETL, changelog, and milestone text.
   Apply the accepted second-person findings to the configuration table and
   shared SVG labels, then regenerate all six timeline figures.
4. Run T1-T4, review the changed procedures from the reader's perspective, and
   record the actual results. Commit and push remain separate operations.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `tests/run-all-tests.bash --phase=1`, including real child exit-status checks | Debian 13 | New check fails on the old helper and passes after the fix |
| T2 | Build failure | Run the shipped Phase 2 with an invalid make-level JAVA_HOME and existing real artifacts | Local source `6957bfc4` | Nonzero exit at the build failure; no Phase 2 PASS |
| T3 | Build | Run the shipped Phase 2 on real source checkouts, including the new artifact naming | Isolated checkouts | Successful clean build; four coherent WARs and one release tarball |
| T4 | Documentation | Compare changed procedures with code and dry runs; validate table values with the built Java enum, inspect all six rendered figures, and check local links, row/detail parity, and dependency cycles | aa-env working tree | No reported contradiction remains; runtime observations are not inferred |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-15 | Debian 13, JDK 21 | Pass | The new real-child regression failed on the old helper (expected exit 23, received 0); after the fix, `tests/run-all-tests.bash --phase=1` passed 37 assertions. |
| T2 | 2026-09-15 | Isolated aa-env checkout, source `6957bfc4`, existing real WARs and tarball | Pass | The shipped Phase 2 with make-level `JAVA_HOME=/nonexistent/archiver-review-jdk` exited 1 at `make build.mvn`; no artifact check or Phase 2 PASS followed. The pre-fix path had returned PASS with the same failure and stale artifacts. |
| T3 | 2026-09-15 | Debian 13, JDK 21, isolated source checkouts `6957bfc4` and `35282494` | Pass | Real clean builds passed all 23 Phase 2 assertions for both naming schemes. Source `35282494` also passed its default 734 Java tests (zero failures/errors/skips within that selection; the POM excludes integration, localEpics, slow, flaky, and PvaTest). After the final shell quoting change, its clean package and all 23 artifact assertions passed again with make-level `MAVEN_OPTS=-DskipTests`; the prior full default-test result was preserved separately. |
| T4 | 2026-09-15 | aa-env working tree; source `35282494` for policy and ETL code | Pass with follow-up | Changed procedures reviewed against code; the systemd directives match the template and a real `conf.systemd0` output. Rocky package listing and start/stop dry runs agree with the docs. All 17 tracked Markdown files have valid local file targets; all 29 work rows have matching details, resolved dependencies, derived Ready values, and no cycles. `bash -n` and `git diff --check` passed; no new ShellCheck findings under the same command and version (existing SC2155 warnings remain). T6's file placement does not yet match the derived ETL cutoff; M20 records the correction. No live install result is inferred. |

T4 follow-up (2026-09-15): the owner accepted two second-person findings:
invalid abbreviated partition names in the configuration examples and the
file-count trigger still printed in the figures. All nine table values now
resolve through the built `PartitionGranularity.valueOf` at source `35282494`.
The shared SVG uses first-sample time cutoffs for both ETL flows; all six PNGs
were regenerated with Inkscape and visually checked for readable labels and
preserved transfer arrows. The configuration-reader second-person pass found
no remaining issue within these two corrections.

Third-person review (2026-09-16): the actual `TimeUtils` cutoff calculation
shows that File_B and File_C in T6 should already be in LTS at the stated
12:30 evaluation. The owner chose to record this as M20 for a later correction;
the T6 artwork and prose remain unchanged in this session.

##### Closure Evidence

- Implementation and T1-T4 locally verified 2026-09-15; landed on
  origin/modernize at `a159b79` (2026-09-19). Live service installation and
  runtime issue reproduction were not part of these checks; the T6 timeline
  correction is carried as M20.

#### M2 - Non-interactive install sequence for the ansible role

Origin: 265f580 / M2
Identity History: Backlog to Milestone (assigned) 2026-09-19
GitHub Issue: none
Status: Complete

##### Summary

Turn the install procedure into a linear, non-interactive sequence with every
input named, so the ansible/cloud role drives the make targets without reading
the Makefiles. Delivered as `docs/README.install.md`.

##### Scope

- `docs/README.install.md`: the ordered targets (init, db.conf,
  conf.archapplproperties, build.mvn, sql.fill, conf.storage, install, sd_start),
  the per-step privilege (build-user vs root), the inputs each consumes, the
  paths each writes, and the check that proves it ran.
- Host prerequisites, variable placement (`configure/RELEASE.local` SRC_TAG;
  `../CONFIG_SITE.local` for AA_USERID/AA_GROUPID, DB_*, DB_HOST_NAME, toolchain),
  the aa-env/host ownership boundary, the skipped targets (db.secure/addAdmin/
  create, install_os_packages.bash, tomcat.get/install), and the health check.
- Handoff of the sequence to the ansible/cloud session.

Out of scope: writing the role; changing any Makefile behavior; MariaDB
account/database creation and hardening (the provisioning operator owns these,
per M9).

##### Completion Criteria

- `docs/README.install.md` is committed on `modernize`.
- The sequence has been handed off to and confirmed by the ansible/cloud session.
- The deployment result is recorded in Backlog gate G5; it does not gate M8
  under D7.

##### Dependencies And Decisions

- M1 (tags and pin recipe); D7 (deployment is Backlog); D10 (distro toolchain);
  D16 (DB rollout); M9 (selectable backend).
- 2026-09-19 coordination with LAB-ansible-provision and LAB-cloud-provision: the
  archiver-dev increment starts on TCP MariaDB; the operator creates the DB and
  account, so the sequence skips db.secure/db.addAdmin/db.create and runs only
  `make sql.fill`; `/opt/tomcat9` is provided read-only by P_tomcat; the document
  reflects the distro-JDK toolchain and the selectable backend.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-19, owner directed writing the sequence document in session
Implementation Authorization: 2026-09-19
Superseded Plan Artifacts: none

1. Record each target's inputs, outputs, privilege, and check from the Makefiles.
   Done 2026-09-19.
2. Write `docs/README.install.md`. Done 2026-09-19.
3. Hand the sequence to the ansible/cloud session. Done 2026-09-19; adopted by
   LAB-ansible-provision (archiver_build operator, archiver-dev species).

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Review | The ansible/cloud session confirms by message that every step names its command, inputs, outputs, and check | Peer session | Confirmation received, or a list of gaps to close |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-19 | Peer session | Pass | LAB-ansible-provision adopted the sequence, confirmed the privilege and ownership boundaries, and is building the archiver_build operator from it; no gaps flagged |

##### Closure Evidence

- `docs/README.install.md` written and the sequence handed off and adopted
  (2026-09-19); T1 Pass. Landed at `b6a80af` on origin/modernize and refined at
  `a12516d` (source references spelled as the full aa-maven URL); both observed
  on origin 2026-09-20. The live deployment result is Backlog gate G5 (does not
  gate M8, D7).

##### GitHub Projection

Title: Document the non-interactive install sequence for the ansible role
Labels: documentation
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M21 - Remove the retired Sphinx docs build from aa-env

Origin: 265f580 / M21
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

aa-maven retired the Sphinx / Read the Docs pipeline and its package build no
longer produces `docs/docs/build` (gate G11). aa-env still carries the matching
assumptions; remove them so the build and its tests match the current source.

##### Scope

- `configure/RULES_SRC`: drop the now-inert `-Dsphinx.skip=true` from
  `build.mvn2`, `build.mvn3`, and `build.war`.
- `tests/phase2-compile.bash`: replace the `docs/docs/build/index.html`
  assertion with the mgmt WAR `ui/api/index.html` and `ui/api/api.json` references.
- `README.md` and `tests/README.md`: remove the Sphinx build-step description.
- `configure/os/debian13.pkgs`: drop `python3`, `python3-pip`,
  `python-is-python3`, and `python3-venv` (the WAR build needs no system Python;
  the narrative docs are on Pages).

Out of scope: the mdBook build (aa-maven); the phase 2 reduction to a wrapper
check (M15); narrative-docs hosting.

##### Completion Criteria

- No `sphinx`, `docs/docs/build`, or Python-for-docs assumption remains in
  `configure/`, `scripts/`, `tests/`, or `README.md`.
- Phase 2 asserts the in-WAR mgmt `ui/api/index.html` and `ui/api/api.json`, and
  passes against the current aa-maven source.

##### Dependencies And Decisions

- G11 Complete 2026-09-18 (aa-maven Sphinx retired, mdBook on Pages)
- D10 (distro toolchain; the docs build needed no system Python). The earlier
  M17 working-tree overlap is resolved: M17 landed at `a159b79`.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-20, owner directed the cleanup in session
Implementation Authorization: 2026-09-20
Superseded Plan Artifacts: none

1. Removed the inert `-Dsphinx.skip=true` (RULES_SRC build.mvn2/3/war) and the
   Python docs packages (debian13.pkgs). Done 2026-09-20.
2. Repointed the phase 2 check to assert `ui/api/index.html` and `ui/api/api.json`
   in the mgmt WAR and removed the `docs/docs/build` and `python3` assertions.
   Done 2026-09-20.
3. Removed the Sphinx step from README.md and tests/README.md. Done 2026-09-20.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `tests/run-all-tests.bash --phase=1` | This host | Pass |
| T2 | Compile | `tests/run-all-tests.bash --phase=2` against the current aa-maven source | This host | Pass; asserts `ui/api/index.html`, no `docs/docs/build` |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-20 | This host | Pass | `tests/run-all-tests.bash --phase=1`: passed=37 failed=0 |
| T2 | 2026-09-20 | This host, source `3c96141d` | Pass | `tests/run-all-tests.bash --phase=2` ran end-to-end: `make build.mvn` (clean package, tests skipped) built the four WARs and the release assembly, and the redone P2.7 (`assert_file` on `ui/api/index.html` and `ui/api/api.json` extracted from the mgmt WAR) passed. Phase 2 passed=23 failed=0; no `docs/docs/build` reference remains. |

##### Closure Evidence

- Code changes applied and verified 2026-09-20 (T1, T2); landed at `a12516d` on
  origin/modernize 2026-09-20. G11 Complete; no linked issue.

##### GitHub Projection

Title: Remove the retired Sphinx docs build from aa-env
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M22 - Size the JVM heap default to the host

Origin: 265f580 / M22
Identity History: none
GitHub Issue: #46
Status: In progress

##### Summary

The VM test default for `AA_JAVA_HEAPSIZE` is `256M` in `configure/CONFIG_SITE`.
`configure/CONFIG_SRC` applies it to both `-Xms` and `-Xmx` through
`CATALINA_OPTS`. Four heaps total `4 * 256 MiB = 1 GiB`; four unchanged 256 MiB
metaspace limits add another 1 GiB. The combined 2 GiB is not a cap on total
process memory, so native JVM allocations, MariaDB and the OS require additional
RAM. The installation guide includes the calculation and a 4 GiB VM example.

The previous 1G heap default meant 4 GiB of heap across the four instances.
On a 4 GB host running MariaDB beside them, the kernel OOM killer removed an
instance roughly 2h50m and 4h after install. The lower value is selected for VM
testing. An operator report dated 2026-09-22 supplies a passing light-load
observation with the 256M override: 10 scalar PVs at 1 Hz each for 20 h 59 min
39 s, without reported OOM or JVM restart. This is evidence for that workload,
not verification of the changed repository default or larger workloads.

##### Scope

- `configure/CONFIG_SITE`: the `AA_JAVA_HEAPSIZE` default and the comment that
  says how to size it.
- `configure/CONFIG_SRC`: retain the shared value for `-Xms` and `-Xmx` and
  verify that the generated configuration receives both options.
- `docs/README.install.md`: state the memory the four instances need among the
  host prerequisites.

Out of scope: per-instance heap values; container or cgroup memory limits; the
MariaDB side of the same host budget.

##### Completion Criteria

- A default install on a 4 GB host runs the four instances beside MariaDB with
  no kernel OOM kill across the interval that previously failed.
- The documented host prerequisite states the memory requirement implied by the
  chosen default.

##### Dependencies And Decisions

- D18. Re-derived here 2026-09-21: `AA_JAVA_HEAPSIZE="1G"` at
  `configure/CONFIG_SITE`, expanded into `-Xms` and `-Xmx` at
  `configure/CONFIG_SRC`. The reporting side overrides to `256M` and has since
  run past both failure intervals with no kernel OOM.
- The `256M` figure is not yet a validated default. Reported 2026-09-21: with
  that override a host ran 15 h 32 min continuously, zero kernel OOM on both
  surviving hosts, `NRestarts` 0, all four instances live. The appliance was
  idle for the whole window, so the run exercised steady-state memory and never
  load. Retain this as historical idle evidence. The later loaded observation
  is recorded separately under T3 and does not establish default-install T2.
- Decision Date: 2026-09-22. Use 256M for both heap options as the VM test
  default, retain the 256M metaspace limit, and document the four-instance
  memory calculation. This accepts a test default, not a claim of runtime
  validation under PV load.
- Evidence received: the operator's 2026-09-22 report, supplied by the owner,
  states a light-load PASS with the 256M override on aa-env `6a026d4` and
  aa-maven `3c96141d`. This session checked the report and its arithmetic, not
  the VM, collector or original logs. T3 records that provenance explicitly.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-22; 256M VM test default with matching heap options and documented memory arithmetic
Implementation Authorization: 2026-09-22; change the default, add configuration comments, update documentation and verify locally
Superseded Plan Artifacts: none

1. Set `AA_JAVA_HEAPSIZE="256M"` in `configure/CONFIG_SITE`; retain the
   metaspace limit and the existing `CONFIG_SRC` expansion for both heap options.
2. Replace the old server-sizing comment with the four-instance calculation.
   Document heap and metaspace separately, additional memory consumers and
   the supported local override in `docs/README.install.md`.
3. Run the real `conf.archappl` target in a copy of tracked working-tree files
   with no local overrides. Check the generated options, repeat with a 512M
   local override, and run the existing local tests.
4. Record the received override-based light-load result as supplemental T3
   evidence. Keep T2 pending until an identified commit containing the default
   change is deployed without a heap override and its runtime is verified beyond
   both earlier failure intervals. VM deployment is not part of the current
   local configuration change. The accepted default-install criterion remains
   unchanged; supplemental evidence does not replace it.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Config | Resolve heap and metaspace with the real Makefile; render `conf.archappl` with the default and a 512M local override; run existing local tests | This host and an isolated copy of tracked files | Default renders Xms/Xmx256M, override renders Xms/Xmx512M, metaspace remains 256M, and local tests pass |
| T2 | Runtime | Install with the default and sample PVs beyond both earlier OOM intervals (more than four hours) | 4 GB host with MariaDB | Four instances stay up; no kernel OOM kill |
| T3 | Supplemental runtime evidence | Review the supplied operator report of the real 256M override run; identify retained measurements and limits | Reported Rocky Linux 8.10 VM, 3.58 GiB guest RAM, MariaDB co-located | Record survival, OOM and sampling/retrieval outcome for the measured light workload separately from default-install T2 |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-22T20:49:32Z | Working tree based on `9a64fb6`; isolated copy of real tracked files | Pass | The real `make conf.archappl` output passes `bash -n` and, when sourced by Bash, supplies exactly one Xms/Xmx256M pair. A real parent `CONFIG_SITE.local` override produces exactly one Xms/Xmx512M pair; both retain MaxMetaspaceSize=256M. Four-instance arithmetic confirms 1024 MiB heap plus 1024 MiB metaspace caps, leaving 2048 MiB from a 4 GiB VM for other consumers. `TMPDIR=/tmp tests/run-all-tests.bash --local` passes 59 logic and 14 build-wrapper assertions; `git diff --check` passes. No JVM or VM runtime was exercised. |
| T2 | Not run | 4 GB host with MariaDB | Pending | none |
| T3 | 2026-09-22T01:00:19Z to 2026-09-22T21:59:58Z (reported) | aa-env `6a026d4`, aa-maven `3c96141d`; 256M override; Rocky Linux 8.10, 3.58 GiB RAM, no swap | Pass (operator report; light workload only) | Owner-supplied VM heap verification report, dated 2026-09-22; 10 scalar PVs at 1 Hz each for 20 h 59 min 39 s. Reports four JVMs with the effective 256M options, zero OOM/restarts, and successful sampling/retrieval. Original VM records were not inspected by this session; details and limits below. |

##### Loaded Runtime Evidence And Limits

Source: the owner-supplied report headed "In reply to: VM heap verification for
the four-instance 256M configuration", dated 2026-09-22. The measurements below
are operator-reported observations, not a local rerun. Retained records are the
operator's `/usr/local/sbin/aasoak-sampler.sh`, `/var/tmp/aasoak-metrics.csv`,
instance `catalina.out` logs and local journal. No GitHub comment is asserted as
the source of this heap report.

| Area | Reported observation |
| --- | --- |
| Environment | Rocky Linux 8.10; 2 vCPU; actual guest RAM 3.58 GiB; no swap; MariaDB on the same VM |
| Deployment | aa-env `6a026d4`, aa-maven source `3c96141d`; OpenJDK 21.0.12.1 LTS; Tomcat 9.0.121; operator heap override, not a shipped-default test |
| Effective configuration | All four JVM command lines show `-Xms256M -Xmx256M -XX:MaxMetaspaceSize=256M`; four Java processes reported |
| Workload | 10 continuously updating scalar calc PVs at 1 Hz each; retrieval limited to periodic checks; no array or high-volume workload |
| Interval | Loaded from 2026-09-22T01:00:19Z through 2026-09-22T21:59:58Z; four JVMs started at 00:29:00Z and reportedly did not restart |
| Aggregate RSS | 85 samples at 15-minute cadence; start/minimum 1614, maximum/final 1697, with the report labeling this series MB |
| Final memory snapshot | JVM RSS: mgmt 487, engine 416, etl 398 and retrieval 396 MiB; MariaDB about 80 MiB; MemAvailable 1.28 GiB |
| Sampling/retrieval | STS/MTS bytes grew at each observation; retrieval returned 67 samples in the 01:00-01:03Z window and 182 in the 21:57-22:00Z window |
| Failure evidence | Report states zero kernel OOM, zero Java OutOfMemoryError and zero JVM restarts over the interval; four instances and mgmt HTTP 200 at all 85 observations |
| Unavailable interval metrics | No per-JVM RSS series, MariaDB RSS series or minimum MemAvailable series; only aggregate RSS and final snapshots were supplied |

Arithmetic and interpretation:

- The supplied timestamps span 75,579 seconds = 20 h 59 min 39 s, approximately
  21 hours. This corrects the report's approximate 20.8-hour wording without
  changing the reported timestamps or its observation scope.
- The final per-JVM RSS values sum to 1697 MiB. The aggregate series is labeled
  MB in the report; confirm the collector's conversion before equating those
  units. Its reported change is `(1697 - 1614) / 1614 * 100 = 5.14%`.
  Fifteen-minute samples do not establish the peak between samples or rule out
  a memory leak; preserve the measured range rather than claim either.
- Configured heap plus metaspace caps total 2 GiB. Against the reported actual
  guest RAM, `3.58 GiB - 2 GiB = 1.58 GiB` is the approximate remaining budget
  for native JVM memory, MariaDB, the OS and caching. This is not measured free
  RAM; the separately reported final MemAvailable is 1.28 GiB.
- The retrieved sample counts are evidence of data at both ends, not by
  themselves proof of complete 1 Hz coverage for all ten PVs. The operator's
  continuity assessment also uses the ongoing sampling and store observations.
- The report states interval-complete kernel and JVM log coverage for OOM and
  no intervening restarts. Those retained records have not been independently
  inspected here. The recorded PASS is limited to the reported survival,
  no-OOM and sampling/retrieval criteria for this light workload.
- T2 remains Pending: deploy `0df950d` or a descendant containing the heap default,
  verify effective options without a heap override, and record its loaded run.
  A capacity claim for larger PV populations, arrays or sustained retrieval
  would require a separate representative workload; it is not implied by T3.

##### Closure Evidence

- The 256M VM test default, comments and memory budget are implemented and
  locally verified (T1). Supplemental T3 records the operator-reported PASS
  for the 256M override under light sampling load for approximately 21 hours.
  Default-install runtime verification (T2) remains outstanding; status stays
  In progress.
- The heap default and memory-budget documentation landed at `0df950d` on
  origin/modernize on 2026-09-23. The commit is an ancestor of the pushed tip
  `75d3460`; recheck with `git merge-base --is-ancestor 0df950d origin/modernize`.
  Repository landing does not establish deployment or satisfy T2.

##### GitHub Projection

Title: Size the JVM heap default to the host
Labels: enhancement
GitHub Milestone: none
Observed State: open
Observed Labels: enhancement
Observed Milestone: none
Observed Updated At: 2026-09-23T20:53:26Z
Last Compared: 2026-09-23T20:53:27Z; `gh api repos/jeonghanlee/epicsarchiverap-env/issues/46` read after the body was synchronized with the 256M default at `0df950d` and the title set to Title; title, labels and milestone match

#### M23 - Make a dead instance visible to systemd

Origin: 265f580 / M23
Identity History: none
GitHub Issue: #44
Status: In progress

##### Summary

One `epicsarchiverap-maven.service` starts four Tomcat instances through
`scripts/archappl.bash`. The unit is `Type=forking` with no `PIDFile=` and no
`Restart=`, so main-process identification depends on a heuristic across four
independently daemonized JVMs. A selected surviving main process does not
establish that the other three JVMs are alive; the heuristic may also fail to
identify a main process. During the ansible-provision archiver-dev
run a host reported the unit active while mgmt served nothing, and the operator
had to check the four processes itself. Under D19 this row makes that failure
visible and deliberately does not recover it.

##### Scope

- `scripts/archappl.bash`: a `health` subcommand that checks every entry of
  `startup_services` against its PID file and actual process, and exits nonzero
  naming every missing or invalid instance. `get_pid` only prints
  the PID-file content and cannot serve as a liveness check.
  `status_archappl` stays what it is today, a human-readable dump that prints
  and exits zero.
- `site-template/systemd/epicsarchiverap-maven-health.service.in`: a
  `Type=oneshot` unit running that subcommand as the service account, with no
  `Restart=`.
- `site-template/systemd/epicsarchiverap-maven-health.timer.in`: the interval
  at which it runs.
- The install and systemd rules that render, install and enable the pair beside
  the existing unit.
- `tests/`: real launcher behavior checks, Make generation/install checks and
  an explicit runtime procedure for the installed health pair.
- `docs/technicaldocs/README.systemd.md`, `docs/README.install.md` and
  `tests/README.md`: command behavior, unit ownership, lifecycle and test scope.

Out of scope: automatic restart of anything (D19); per-instance systemd units
(D12, and unsound here per D19); any change to the appliance unit's `Type=`,
`ExecStart=`, `ExecStop=` or its ordering; consolidating the four webapps into
a single Tomcat, which D19 keeps as its own question.

##### Completion Criteria

- After the startup allowance, a stable instance failure while the appliance
  remains active makes the separate health unit report `failed`, naming the
  affected instances and reasons. The runtime acceptance target is detection
  within 45 seconds on an awake, responsive test VM, including timer accuracy,
  check execution and dispatch delay. This target requires measured verification;
  it is not a hard real-time guarantee or a claim of current behavior.
- The monitor issues no appliance/JVM start, stop, restart or terminating signal,
  directly or through unit dependencies. Existing appliance supervision and D12
  startup/shutdown order are preserved. JVM survival and continued operation of
  dependent components after another instance fails are not guaranteed by M23.
- Each successful process check means only that all four expected JVM processes
  were verified at that observation. A skipped check, unreadable configuration
  or failed observation must not be reported as healthy. HTTP readiness,
  archiving and retrieval correctness are outside this process check.
- Repeated checks, boot/restart allowance, intentional stop, operator recovery
  and health-pair installation/removal behave as specified below and are
  exercised through the actual shipped paths.
- MainPID-related appliance shutdown is observed and reported as existing
  appliance behavior, not prevented or presented as a monitor recovery action.
  Test evidence distinguishes the monitor's actions from dependency effects.

##### Dependencies And Decisions

- D12 (single service, `scripts/archappl.bash` launcher, asymmetric start and
  stop order). This row leaves that design untouched.
- D18. Re-derived here 2026-09-21: the unit is `Type=forking` with
  `ExecStart=/bin/bash -c "... startup"`, no `PIDFile=` and no `Restart=`.
- D19 (detect and report, no recovery; the report lives in a separate unit).
  Decision Date: 2026-09-22. The selected scope preserves existing appliance
  supervision. The monitor must not cause stop/restart actions; preserving other
  JVMs or their dependent functionality after failure is not a completion
  condition. This clarifies the earlier survivor wording without changing D12.
- HTTP readiness observation, reported 2026-09-21: mgmt returned 500 during
  initialization for about 20 to 30 seconds after restart and until about 48
  seconds after reboot. Preserve that observation, but do not use it as a
  measured process-start delay: M23 checks JVM presence, not HTTP responses.
  Measure PID creation and instance identity readiness separately. Use the
  initial 60-second startup allowance below and verify it against those
  measurements; the HTTP observation does not establish its adequacy.
- The same host returned unaided after a reboot: the unit was active 5 seconds
  in and the first journal line for it that boot is systemd starting it, so
  nothing here needs to add boot-time recovery.
- Do not build the check on scanning the journal for error words. On hosts
  provisioned this way `sudo` records the full text of the scripts it runs, so
  such a scan matches script text and reports events that did not happen; the
  reporting side counted phantom OOM entries that way. Checking the processes
  is the reliable path, which is what this design already does.

##### Planning Findings

Confirmed against the planning baseline at `9a64fb6`:

- `scripts/archappl.bash:get_pid` reads and prints a PID file without checking
  process existence. Its successful output cannot prove a live JVM.
  `site-template/startup.sh.in` supplies per-instance `CATALINA_PID` and
  `CATALINA_BASE`; use that installed identity rather than a name-only search.
- The launcher sources `archappl.conf` before dispatching commands without
  explicitly rejecting a source failure. The new health path must report an
  unreadable or invalid configuration as an inspection error, not healthy.
- The baseline `configure/RULES_SYSTEMD` installs the appliance unit and Tomcat
  override, but its enable, disable and clean targets cover only the appliance
  unit. Health lifecycle extends those targets while leaving the override separate.
- Baseline `sd_install` lists generation and installation as siblings, and
  baseline `install` similarly lists `sd_install` and `sd_enable`.
  `configure/RULES_VARS` globally declares `.NOTPARALLEL`, so these are not an
  observed concurrent race in the shipped graph. Preserve serialization and add
  explicit generation/install and reload/enable ordering, including direct
  target entry points. A real `make -j8` still runs the shipped serialized graph.
- `docs/README.install.md` describes one owned service and install-time enable;
  that document must change with the added health pair, not only the systemd
  technical note. `tests/phase4-vm.bash` currently skips runtime verification.

Manual-based constraints, not observations from a deployed VM:

- MainPID guessing can fail for a multi-process forking service. Once a
  successfully started service stops, its stop command can run even after
  process death [1]. With this repository's `ExecStop`, MainPID death and
  non-main death therefore cannot share an assumed survivor guarantee.
- Timer expiry includes `AccuracySec`, and a timer does not start another copy
  of an already active service [2]. Use a completing oneshot, explicit timing
  and timeout settings, and verify recurring checks after both success and
  failure. Do not infer a detection bound from the interval alone.
- Unit start limits also apply to timer activations [3]. Verify that persistent
  failures do not silently disable subsequent health observations.

Hypotheses requiring measurement:

- The target VM's actual MainPID and stop behavior, process-start duration,
  access to process identity under the service account, and detection latency
  are not yet observed. T4-T8 provide these observations.
- A PID can disappear or be reused during inspection. Re-read process identity
  and start time when needed; an inconsistent or inaccessible observation must
  not become a healthy verdict. This is a point-in-time check, not a guarantee
  that a process remains alive until the next timer run.

Accepted scope, Decision Date: 2026-09-22:

Detect and report only. Keep the appliance unit and its dependency behavior.
Do not introduce independent recovery, promise survivor availability, or reopen
supervision design as part of M23. A remaining JVM may itself fail or lose
functionality because another component died; process existence is not proof
of appliance correctness. Capture this distinction in diagnostics and tests.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-22, detect-and-report scope selected and strengthened plan confirmed
Implementation Authorization: 2026-09-22; implement the accepted plan
Superseded Plan Artifacts: earlier M23 plans in this canonical detail

1. Establish the test baseline under the accepted D12/D19 constraints. VM
   access is a runtime verification prerequisite, not a prerequisite for local
   implementation. Before deploying the health pair, record the aa-env/source
   commits, systemd version, effective unit including drop-ins, service account,
   MainPID and four JVM PID/start times. Obtain original-unit failure observations
   during the scheduled VM tests so later exits can be attributed correctly.
2. Add `archappl.bash health` with an explicit command contract. Inspect every
   configured instance even after one fails. Return 0 only for four verified
   live instances, 1 for an invalid or missing instance, and 2 when inspection
   cannot complete; inspection errors take precedence over instance failures.
   Print one result per instance with its name, observed PID when available,
   and process-check result or failure reason, followed by the aggregate result.
   Label success as verified process presence, not application readiness. Keep
   configuration contents and complete command lines out of diagnostic output.
   Check PID syntax before use, reject zero/negative/multiple values, inspect
   actual process state and exact Tomcat instance identity, and reject zombies,
   unrelated processes and mismatched instances. Use read-only observations;
   never delete PID files or signal a JVM. Preserve existing command behavior
   and startup/shutdown order. The systemd integration is Linux-specific;
   existing non-systemd commands must retain their current platform behavior.
3. Add the health service and timer plus the minimal systemd-aware dispatch
   needed to apply the state table below. Keep direct `health` independent of
   appliance unit state so it remains usable for diagnosis. The scheduled path
   reads appliance state and monotonic activation timestamps; it must not infer
   a new startup allowance from each timer run or from HTTP responses.
   Check for stop/restart transitions around the process observation to avoid
   reporting a mixed snapshot as a stable failure. Use no dependency or command
   that starts or restarts the appliance as a side effect of monitoring.
4. Make timing explicit in `configure/CONFIG_SYSTEMD` and the generated pair.
   Initial settings are startup allowance 60 seconds, repeat delay 30 seconds
   after a completed check, timer accuracy 1 second, randomized delay 0 and
   check timeout 5 seconds. Bound health-check termination as well so a timed-out
   check cannot indefinitely postpone the next observation. The scheduled
   command must finish without sleeping through the allowance. Verify the
   45-second acceptance target with the actual schedule, including a fault
   occurring just after its instance was inspected. An implementation that
   exceeds that target requires correction or an explicit plan revision; do not
   adjust the test limit after observing a failure. Confirm target-version
   support and repeated activation after both success and failure. Do not leave
   a successful oneshot active indefinitely.
5. Extend `configure/RULES_SYSTEMD`, `configure/CONFIG_SYSTEMD` and only the
   necessary dependencies in `configure/RULES_INSTALL`. Generation precedes
   file installation, daemon reload precedes enable, and the real `make install`
   path preserves those dependencies under parallel execution. Install/enable
   must not implicitly start the appliance or monitor an incomplete install.
   Specify how monitoring starts for both `make sd_start` and direct systemctl
   starts, including installation on an already-running appliance. Disable and
   clean must stop the timer and any running health check before removing the
   health pair or its enable links; they must not stop the appliance. Keep the
   existing appliance cleanup semantics and Tomcat override behavior separate.
6. Add local checks through the existing runner and document the runtime SOP in
   `tests/README.md`. Run the shipped launcher as a command, not extracted or
   overridden internal functions. Filesystem fixtures may exercise invalid PID
   inputs; real unrelated child processes may exercise identity rejection.
   Do not make a fake Tomcat process or mocked process query stand in for the
   healthy four-JVM integration path. That positive path belongs to T4.
   Execute real Make generation and file installation into an isolated writable
   destination. Dry-runs can inspect privileged command intent, but actual
   systemctl effects and timer behavior require T4-T8 on a real systemd VM.
7. Update both installation and systemd documentation: units owned by aa-env,
   install versus start, check semantics, timing, skipped versus healthy,
   failure output, operator recovery and monitoring removal. Verify Bash syntax,
   ShellCheck and existing local tests. Keep the appliance template and original
   launcher ordering unchanged. Document that dependent functionality and
   surviving JVMs are not protected by this monitor.
8. Run the VM tests outside M22's uninterrupted load observation. Capture the
   pre-test state, terminate only a revalidated test-instance PID, and record
   detection times, unit results and surviving process start times. Recovery
   uses the existing full-appliance procedure under operator control; monitoring
   never performs it. Retain failure evidence and restore the agreed test state
   after each interruption before proceeding to the next case.

##### Scheduled Check Contract

This table is the implemented contract, not verified runtime behavior. A skipped scheduled check is not evidence that all four JVMs are
healthy. Scheduled output must distinguish process-check success, detected
failure, inspection error and skip, including the appliance state and reason.

| Appliance state | Scheduled check result | Required behavior |
| --- | --- | --- |
| Inactive after a successful stop | Skip | Do not start the appliance or report missing JVMs as a new failure |
| Starting, within the allowance | Skip | Use the current start's monotonic timestamp; do not renew the allowance on every check |
| Active, within the allowance | Skip | Direct `health` remains available; scheduled checks begin after the allowance |
| Active, beyond the allowance | Inspect | All four verified processes succeed; any invalid instance or inspection error fails the health unit |
| Still starting beyond the allowance | Fail | Report exceeded startup allowance rather than skipping indefinitely |
| Stopping | Skip | Avoid treating intentional teardown as a new instance failure |
| Failed | Fail | Report appliance failure without attempting recovery; preserve the appliance's own evidence |
| Missing unit, unknown state, unreadable state or invalid timestamp | Inspection error | Fail visibly; never interpret inability to observe as healthy or intentionally stopped |
| State changes during inspection | Retry on the next tick | Identify the transition; do not publish an inconsistent healthy or failed instance snapshot |

While an instance failure persists, successive completed checks must continue
reporting it without a restart. A subsequent fully verified success clears the
current health failure; the journal preserves the earlier event. Verify and
document the temporary `activating` state during each check rather than promise
an uninterrupted `failed` display. Skips and appliance state transitions must
be identifiable in the output and must not be presented as recovery evidence.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local behavior | Run the shipped health command with absent/unreadable/empty/malformed/multiple PID values, absent process, wrong instance identity and simultaneous failures; use real unrelated processes for negative identity checks | Isolated workspace, non-root | All affected instances and reasons are reported; exit 1/2 follows the contract; no internal function replacement, PID deletion or JVM signal |
| T2 | Generation/install | Run real configuration and file-install targets with -j1 and -j8 (shipped .NOTPARALLEL retained), using default and alternate install paths/account; inspect full install dependencies with Make | Isolated writable destination | No unresolved placeholders; correct installed units, mode and paths; required ordering is represented and exercised for local file operations; dry-runs are not claimed as systemd execution |
| T3 | Regression | Run the existing local test entry point, Bash syntax checks and ShellCheck; inspect the appliance template and existing command paths | This host | Existing checks pass; no new warnings; original status/start/stop behavior and platform scope are preserved |
| T4 | Runtime baseline | Observe the original appliance first, then install the real health pair and run direct and scheduled checks under the service account | Selected systemd VM, four real Tomcat JVMs | Correct instance identity and exit 0; at least three successful scheduled observations; effective units, MainPID, timestamps and versions recorded |
| T5 | Runtime detection | Revalidate and terminate a non-main JVM, retain its PID file, observe repeated checks, then repeat with two non-main failures after restoring baseline; include a failure immediately after its instance check | Selected VM, outside M22 observation | Stable instance failures are named within 45 seconds while the appliance remains active; the monitor causes no restart/stop; record secondary exits and dependency effects without requiring continued JVM survival or mgmt availability |
| T6 | Lifecycle | Observe reboot, direct systemctl restart, Make start, intentional stop and a startup failure beyond the allowance | Selected VM | Fresh bounded allowance for each start, no stop/start false alarm, no indefinite skip, monitoring resumes on both supported start paths |
| T7 | Existing supervision | Compare original-unit and monitored-unit behavior on MainPID death where one is assigned; if MainPID is 0, record that fact and the observed process-group behavior rather than invent a representative PID | Selected VM, separately scheduled interruption | Existing appliance shutdown behavior is preserved; health diagnostics identify the observed appliance state, not a survivor guarantee; monitoring adds no stop/restart operation |
| T8 | Monitoring failure/recovery | Observe at least three repeated failures, a bounded check timeout or observation error, operator recovery, then disable/clean and reinstall the health pair while preserving the appliance | Selected VM | Checks continue after failures; no false healthy result on an error; real success restores current health status; timer/check stops before removal, no stale enable links remain, and reinstall restores monitoring |

For T5/T7, record the appliance and health-unit journal with precise timestamps,
unit results, four PID/start times and the exact fault. Process loss alone is
not proof that the monitor caused it. If attribution remains unclear, retain
Pending evidence and resolve it before closure; do not claim non-interference
from an unexamined exit. A changing appliance state is evaluated by the state
contract rather than a guarantee that it stays active after any instance dies.

T1/T2 validate only the paths actually executed locally. T4-T8 require the
installed scripts, generated units, real systemd and real Tomcat instances.
The existing phase 4 skip, a replacement shell service, or fabricated process
identity does not satisfy these tests. Record unavailable coverage as Pending,
not Pass. Before each runtime case, specify the exact fault method and expected
result; do not change the criterion to fit an observed outcome.

##### Implementation State

Implementation was authorized 2026-09-22 and landed at `9ee6ac0` on
origin/modernize on 2026-09-23.
Raw health uses read-only Linux process identity checks; scheduled dispatch uses
verified health invocation and appliance monotonic timestamps, buffering results
across state observations. Skip exit 3 is explicit and is not recovery evidence.
The generated oneshot/timer have finite execution/termination, recurring checks,
and one-way timer activation. Installation stops existing monitoring first and
never starts it implicitly. Monitor-only disable/clean targets preserve appliance
operation. Full runtime evidence remains outstanding.

Independent PID and systemd implementation reviews accepted the local result on
2026-09-22, including the operator-document pass. The PID correction pass verified
unrelated-Java rejection and inaccessible symlink error classification through
the shipped launcher. No remaining local implementation finding was reported.
This acceptance does not satisfy the real Tomcat cross-instance case in T1 or
runtime T4-T8.

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-22T23:35Z | Isolated workspace, non-root; real installed JDK, unrelated child processes and zombie | Pending | Local negative cases in `tests/health-local.py` passed: configuration/PID errors, nonexistent process, wrong executable, zombie, multi-instance output, symlink traversal denial and exit precedence. A real unrelated Java main class with Tomcat-like VM properties or application arguments was rejected; PID files/processes were preserved. Both added regressions failed against the preceding implementation and passed after correction. Cross-instance identity using a real Tomcat PID remains for the documented VM case. No healthy JVM fixture was fabricated. |
| T2 | 2026-09-22T23:22:58Z | Isolated real Make checkout and file destination; systemd-analyze 257 | Pass (local scope) | Real `install.systemd` under -j1 and -j8, default/alternate paths and accounts, plus site timing overrides passed. Unit modes/placeholders and generated-pair syntax verified. Global .NOTPARALLEL remained enabled. Full-install/cleanup ordering was checked by real Make dry-run only; live systemctl effects remain T4-T8. |
| T3 | 2026-09-22T23:35Z | Linux local checkout, Bash, ShellCheck 0.10.0 | Pass | `TMPDIR=/tmp bash tests/run-all-tests.bash --local` passed existing 59 logic/14 wrapper assertions plus 15 health/file-install test methods, with no skips. Changed Bash syntax and `shellcheck -x -P SCRIPTDIR scripts/archappl.bash tests/phase1-logic.bash` passed. The earlier full tracked Bash ShellCheck comparison exactly matched HEAD under the same command/version; existing unrelated warnings remain, and the subsequently corrected launcher still reports no diagnostics. Appliance unit bytes and existing status/storage/start/stop helper bodies equal HEAD. `git diff --check` passed. |
| T4 | Not run | Test VM not selected | Pending | none |
| T5 | Not run | Test VM not selected | Pending | none |
| T6 | Not run | Test VM not selected | Pending | none |
| T7 | Not run | Test VM not selected | Pending | none |
| T8 | Not run | Test VM not selected | Pending | none |

##### References

The cited versioned manuals establish design constraints only; compatibility
and actual behavior must be checked on the selected VM. Entries [1]-[3] use
the IEEE Reference Guide's I. Manuals, Manual (Online) format.

[1] systemd Project. *systemd.service: Service unit configuration*, version 252. (n.d.). Accessed: Sep. 22, 2026. [Online]. Available: https://raw.githubusercontent.com/systemd/systemd/v252/man/systemd.service.xml

[2] systemd Project. *systemd.timer: Timer unit configuration*, version 252. (n.d.). Accessed: Sep. 22, 2026. [Online]. Available: https://raw.githubusercontent.com/systemd/systemd/v252/man/systemd.timer.xml

[3] systemd Project. *systemd.unit: Unit configuration*, version 252. (n.d.). Accessed: Sep. 22, 2026. [Online]. Available: https://raw.githubusercontent.com/systemd/systemd/v252/man/systemd.unit.xml

##### Closure Evidence

- Implementation, tests and operator documentation landed at `9ee6ac0` on
  origin/modernize on 2026-09-23. The commit is an ancestor of the pushed tip
  `75d3460`; recheck with `git merge-base --is-ancestor 9ee6ac0 origin/modernize`.
- Repository landing completes no additional runtime check. T1's real Tomcat
  cross-instance case and T4-T8 remain Pending; status stays In progress.

##### GitHub Projection

Title: Service reports active after an instance dies
Labels: bug
GitHub Milestone: none
Observed State: open
Observed Labels: bug
Observed Milestone: none
Last Compared: 2026-09-21

#### M24 - Remove the dead jsvc shutdown path

Origin: 265f580 / M24
Identity History: none
GitHub Issue: #45
Status: Complete

##### Summary

At the pre-change commit `f0d2a979bb0283c956c055e4fce7fe1496b9bf23`,
`jsvc_shutdown_archappl` was defined at `scripts/archappl.bash:94` and never
called; start and stop both run each instance's `startup.sh` and `shutdown.sh`.
Its presence implied a `jsvc` dependency the launcher does not have, and `jsvc`
was listed only in `configure/os/debian13.pkgs`, not in `rocky8.pkgs`, so the
package lists disagreed about a tool nothing invokes. The function and Debian
package entry were removed in `4b4cb41` on `origin/modernize`.

##### Scope

- `scripts/archappl.bash`: remove `jsvc_shutdown_archappl` and its attached
  ShellCheck directive.
- `configure/os/debian13.pkgs`: remove the unused `jsvc` package entry.
- `tests/phase1-logic.bash`: add a structural guard against restoring the dead
  function or the unused package dependency.

Out of scope: the start and stop ordering D12 fixed; other differences between
the per-OS package lists.

##### Completion Criteria

- No function in `scripts/archappl.bash` is defined without a caller.
- `jsvc` appears in an OS package list only if something invokes it.

##### Dependencies And Decisions

- D12 (the launcher owns start and stop through the per-instance scripts).
- D18. Re-derived here 2026-09-21: the only `jsvc` references in
  `scripts/archappl.bash` are the function definition and its own body, and
  `configure/os/debian13.pkgs` is the only package list naming `jsvc`.
- Decision Date: 2026-09-21. Remove the unused function and package entry;
  do not introduce a jsvc launcher or shutdown path. Add the Phase 1 guard.
- No external test host is required for this cleanup. The removed function has
  no caller in the shipped scripts; the active dispatch and Tomcat script
  invocations are outside the change. D12 constrains those paths to remain
  unchanged. Package selection can be exercised locally through the real
  installer's `--list-only` mode, which returns before package installation.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-21; corrected plan accepted after the second-person review
Implementation Authorization: 2026-09-21; implement the accepted cleanup and local checks
Superseded Plan Artifacts: none

1. Remove the entire `jsvc_shutdown_archappl` definition and its attached
   ShellCheck directive from `scripts/archappl.bash`. Preserve the active
   startup, shutdown and restart dispatch, including both service-order arrays.
   Inspect the remaining function definitions and their callers against the
   completion criterion, and check the script with `bash -n`.
2. Remove only the `jsvc` entry from `configure/os/debian13.pkgs`. Check the
   launcher and all shipped OS package lists for remaining jsvc references;
   leave unrelated package differences unchanged.
3. Extend `tests/phase1-logic.bash` with assertions against the actual launcher
   and package installer: the dead function and jsvc invocation are absent,
   and `bash scripts/install_os_packages.bash --os <id> --list-only` succeeds with
   nonempty output and no `jsvc` entry for each shipped OS package list.
   Use the installer's real parser rather than reproducing it in the test.
4. Run T1 and T2 locally, inspect the diff to confirm that active service paths
   and unrelated package entries are unchanged, and record the actual results.
   These checks establish the cleanup and package selection; they do not claim
   service runtime verification. No service restart or package installation
   is part of this work.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | Run `bash -n scripts/archappl.bash`, inspect remaining function callers, and run `tests/run-all-tests.bash --phase=1` with the launcher and package-list guards | This host | Script parses, every remaining function has a caller, and the real Phase 1 runner passes with no dead jsvc function or package entry |
| T2 | Package selection | Run `bash scripts/install_os_packages.bash --os <id> --list-only` for each shipped `configure/os/<id>.pkgs` through the Phase 1 guard | This host; no root or network required | Every invocation exits 0 with a nonempty resolved package list containing no `jsvc` entry |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-22T03:27:40Z | Local working tree based on `f0d2a97` | Pass | `bash -n scripts/archappl.bash` and `TMPDIR=/tmp tests/run-all-tests.bash --phase=1` exit 0; Phase 1 reports 47 passed, 0 failed. All nine remaining launcher functions have callers. The new P1.14 launcher check was first run against the original function and exited 1 at the jsvc reference. The launcher diff removes only that function and its attached directive. |
| T2 | 2026-09-22T03:27:40Z | Local working tree; real package installer | Pass | P1.14 executes `bash scripts/install_os_packages.bash --os <id> --list-only` for debian13, macos and rocky8: each exits 0 with nonempty output and no jsvc entry. With the function removed but the original Debian list still present, the real Phase 1 runner exited 1 at the Debian jsvc assertion. No package installation or service operation ran. |

##### Closure Evidence

- Implementation and both local checks are finished. The
  accepted plan preserves the active launcher paths and service-order arrays;
  the diff contains no changes to those paths.
- Landed at `4b4cb4185584ccaed4200a9d0cf67db748c3e20d` on `origin/modernize`. Observed 2026-09-22T19:05:49Z after `git fetch origin`: `git merge-base --is-ancestor 4b4cb41 origin/modernize` exited 0. Comparing HEAD with `origin/modernize` at `d748d4f` using `git diff --exit-code` for every path listed by `git diff-tree --no-commit-id --name-only -r 4b4cb41` found no differences.
- Complete 2026-09-22. Issue #45's body was synchronized with the shipped implementation, accepted scope and verification results, then closed as completed at 2026-09-22T20:06:50Z. The remote body matched the prepared content before closure. Observed 2026-09-22T20:07:07Z through `gh api repos/jeonghanlee/epicsarchiverap-env/issues/45`: state `closed`, state_reason `completed`, label `enhancement`, no milestone. Together with T1-T2 and repository landing evidence, this satisfies the completion criteria. The local verification does not claim service runtime verification.

##### GitHub Projection

Title: Remove the uncalled jsvc shutdown function
Labels: enhancement
GitHub Milestone: none
Observed State: closed
Observed Labels: enhancement
Observed Milestone: none
Observed Updated At: 2026-09-22T20:06:50Z
Last Compared: 2026-09-22T20:07:07Z

#### M25 - Correct the MAVEN_OPTS name and proxy guidance

Origin: 265f580 / M25
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

Before this change, `MAVEN_OPTS` in `configure/CONFIG_SITE` was expanded onto
the mvn command line by the six `configure/RULES_SRC` targets, despite sharing
its name with Maven's JVM-options environment variable. The Make variable is
now `MAVEN_FLAGS`; the installation guide describes migration and proxy settings. The reporting side measured that JVM proxy properties passed that way
do not reach Maven's dependency resolution, and neither do the shell proxy
variables nor a real `MAVEN_OPTS` environment variable; only a settings file
works, which they select with `-gs` through this same hook.

##### Scope

- `configure/CONFIG_SITE`: the hook's name and the comment describing what it
  carries.
- `configure/RULES_SRC`: the build targets that expand it.
- `docs/README.install.md`: variable migration and Maven proxy guidance.
- `tests/phase1-logic.bash` and `tests/README.md`: command-generation checks
  for all six targets that consume the flags.

Out of scope: shipping a settings file; the Maven Wrapper pin (D10); proxy
configuration for anything other than the Maven build.

##### Completion Criteria

- The hook's name and comment describe mvn command-line flags, and any proxy
  guidance names the settings-file route rather than this hook alone.
- The build targets still parse and still pass the flags through.

##### Dependencies And Decisions

- D10 (the Maven Wrapper committed in aa-maven is the only Maven; aa-env
  installs none).
- D18. Re-derived here 2026-09-21: `configure/CONFIG_SITE` defines
  `MAVEN_OPTS:=` and the `RULES_SRC` targets expand it as
  `$(MAVEN_CMD) $(MAVEN_OPTS) <goal>`, which is a command-line position.

- Decision Date: 2026-09-22. Rename the Make variable directly to
  `MAVEN_FLAGS` without a compatibility alias. Existing local Make settings
  must migrate their command-line flags to the new name; the standard Maven
  `MAVEN_OPTS` environment variable retains its JVM-option meaning.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-22; direct rename, migration guidance and local checks
Implementation Authorization: 2026-09-22; implement the accepted plan
Superseded Plan Artifacts: none

1. Rename the empty Make variable in `configure/CONFIG_SITE` to `MAVEN_FLAGS`
   and describe its command-line role separately from JVM options.
2. Replace its expansion in the six Maven targets in `configure/RULES_SRC`;
   preserve their goals, existing fixed flags and prerequisites.
3. Document migration of local Make settings and command-line overrides in
   `docs/README.install.md`. Describe proxy configuration through a supplied
   settings file and the `-gs` flag; do not ship or generate that file.
4. Extend Phase 1 to run the real Makefile with `make -n` and nonempty flags
   for `clean.mvn`, `build.mvn`, `build.mvn2`, `build.mvn3`, `build.war` and
   `build.mvndeps`. Require successful expansion and the flags immediately
   after the Maven Wrapper command. Record this as command generation, not
   Maven execution or a network proxy test, and update `tests/README.md`.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `tests/run-all-tests.bash --phase=1` | This host | Passes after the rename |
| T2 | Build system | Through Phase 1, run `make -n` for all six Maven targets with `MAVEN_FLAGS` containing batch and settings-file options | This host; no Maven or network execution | Every target parses and places the flags immediately after the Maven Wrapper command, retaining its existing goals |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-22T07:13:00Z | Local working tree based on `4b4cb41` | Pass | `TMPDIR=/tmp tests/run-all-tests.bash --phase=1` exits 0 with 59 passed, 0 failed; `bash -n tests/phase1-logic.bash` and `git diff --check` also exit 0. Before renaming the real Makefile variable, the new check exited 1 because `clean.mvn` omitted MAVEN_FLAGS from the generated command. |
| T2 | 2026-09-22T07:13:00Z | Real Makefile through Phase 1 P1.15 | Pass | All six targets expand successfully with batch and global-settings flags immediately after the Maven Wrapper command. Source diff inspection confirms their existing goals, fixed flags and prerequisites are retained. This verifies command generation only; Maven and proxy connectivity were not exercised. |

##### Closure Evidence

- The direct rename, migration and proxy guidance, and local checks are
  implemented and verified. Existing local Make settings
  and command-line overrides must use `MAVEN_FLAGS` for CLI flags.
- Complete 2026-09-22. Landed at `84b38e579800fd76e34f164a67ba5100b6ad76fc` on `origin/modernize`; no GitHub issue is assigned to this row.
- Observed 2026-09-22T19:05:49Z after `git fetch origin`: `git merge-base --is-ancestor 84b38e5 origin/modernize` exited 0. Comparing HEAD with `origin/modernize` at `d748d4f` using `git diff --exit-code` for every path listed by `git diff-tree --no-commit-id --name-only -r 84b38e5` found no differences. Together with T1-T2, this satisfies the completion criteria.

##### GitHub Projection

Title: Correct the MAVEN_OPTS name and proxy guidance
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M26 - Test-environment archive store

Origin: 265f580 / M26
Identity History: Retitled 2026-09-23 from "Test-environment archive store and
ETL timing" when the ETL-timing half moved to M31 (D23).
GitHub Issue: none
Status: Not started

##### Summary

A finding from the provisioned deployment runs: the archive store resolves to the root volume: nothing in the install path mounts a
dedicated filesystem for it and `ARCHAPPL_STORAGE_TOP` only names a directory,
so an archiver that fills its store fills `/` and takes the whole host instead
of just archiving. No quota or threshold exists anywhere in the chain, and the
fill rate is unknown because no run has yet had a PV sampling.

The ETL-timing finding that shared this row, a store configuration whose
second hop could not be observed in a test run, moved to M31 on 2026-09-23
(D23).

##### Scope

- A dedicated filesystem for the archive store on test hosts, or at minimum a
  store that is not on the root filesystem, with a threshold that reports before
  the root filesystem is endangered.
- `docs/README.install.md`: name the storage volume among the host
  prerequisites, which today it does not.

Out of scope: production storage sizing and per-tier media selection; retention
policy for real data; the reduction operators (`reducedata`, `pp`); and any
change to the shipped default for real deployments. D21 scopes this row to the
test environment.

##### Completion Criteria

- On a test host the archive store is not on the root filesystem, and a
  threshold reports before the root filesystem is affected.
- The host prerequisites state what the test environment requires.

##### Dependencies And Decisions

- D18 (the findings come from the provisioned deployment runs).
- D21 (scoped to the test environment first).
- D23 (the ETL-timing half moved to M31, and its runtime test to M32).
- The fill rate is unknown until the pending load test reports disk growth with
  a PV sampling. That figure sets the threshold value; it does not change the
  shape of this work, so this row does not wait on it.
- 2026-09-21: the shipped MTS granularity moved from `PARTITION_MONTH` to
  `PARTITION_DAY`, matching the recommended default the storage guide already
  carried in its "Final Recommended Default Policy" section. The guide and the
  template had disagreed since both were first committed; the owner settled it
  by changing the template rather than annotating the guide. The second ETL hop
  now becomes eligible after roughly two days instead of roughly two months, so
  a soak can observe the whole chain; whether two days is short enough for
  quick iteration is now M31's question (D23).
- The LTS `pp=mean_3600` half of that same recommendation is deliberately not
  applied: `pp` adds auxiliary files and therefore disk, which is the opposite
  of what this row is protecting against while the fill rate is unknown, and it
  cannot coexist with the `reducedata` the Fast, VeryFast, Medium and Slow
  policies already set on LTS. M27 carries that question.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime | Grow the store toward the threshold | provisioned host | The threshold reports before the root filesystem is affected |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | provisioned host | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Test-environment archive store
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### G1 - aa-maven baseline tag reported by the aa-maven session

Origin: 265f580 / G1
GitHub Issue: none
Status: Complete

##### Summary

The aa-maven session (single writer of jeonghanlee/epicsarchiverap-maven) tags
the aa-maven state `abf6545` and reports the tag name. Affects M2.

Announced 2026-09-11: tag name `NewHope` (annotated, no `v` prefix) on
`abf6545`. Pushed the same day; see Verification Results.
aa-maven records the tag as decision D5 in `docs/milestone-daff1b7.md`
(no work row; complete).

##### Completion Criteria

- A cross-session response names the tag and confirms it points at
  `abf6545` on aa-maven's origin.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-11 | Pass | `git ls-remote --tags https://github.com/jeonghanlee/epicsarchiverap-maven refs/tags/NewHope 'refs/tags/NewHope^{}'` returned tag object `ffbea94` peeling to `abf6545` |

##### Closure Evidence

- aa-maven push notice of 2026-09-11 and the ls-remote observation above.

#### G2 - Legacy GitHub milestones and issues closed

Origin: 265f580 / G2
GitHub Issue: none
Status: Complete

##### Summary

GitHub milestones M0–M5 and the legacy roadmap issues #35–#42 on
jeonghanlee/epicsarchiverap-env are closed: the issues under issue
delegation, the milestones by the owner. Affects M3.

##### Completion Criteria

- `gh issue list --state open` shows none of #35–#42.
- `gh api repos/:owner/:repo/milestones?state=all` shows M0–M5 closed.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-13 | Pass | `gh issue list --state open` shows only #24 and #25 (real bugs, not retired); `gh api .../milestones?state=all` shows M0–M5 (id 1–6) all closed |
| 2026-09-15 | Pass | GitHub REST issue and milestone reads confirm #35-#42 and M0-M5 closed; every issue has a retirement comment pointing to this register. Their closed state is retirement evidence, not implementation evidence. #24 and #25 remain open and are recorded in M18 and M19. |

##### Closure Evidence

- Issues #35–#42 closed under issue delegation 2026-09-12; milestones M0–M5 closed by the owner; both verified on GitHub 2026-09-13.

#### G3 - aa-maven lands canonical pom

Origin: 265f580 / G3
GitHub Issue: none
Status: Complete

##### Summary

The aa-maven session commits a pom.xml that builds without aa-env's copy and
reports the commit hash. Affects M6.
aa-maven register row: `docs/milestone-daff1b7.md` M3; its base is aa-env's
tracked `pom.xml` (aa-maven decision D6).

##### Completion Criteria

- A cross-session response names the aa-maven commit and its register row.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-12 | Pass | Origin `modernize` at `6957bfc`; pom `9be652c` re-derived: zero `systemPath`/system-scope entries, `tomcat-servlet-api` 9.0.113, `lib/repo` local repository present; aa-maven register records M3 Complete |

##### Closure Evidence

- aa-maven push notice of 2026-09-12 (commits `9be652c`, `6957bfc`) and the
  origin re-derivation above.

#### G4 - aa-maven lands jakarta servlet migration

Origin: 265f580 / G4
GitHub Issue: none
Status: Complete

##### Summary

Retired 2026-09-12: aa-maven fixed Tomcat 9 and dropped the jakarta / Tomcat 11
migration (aa-maven decision D13); there is no migration to wait for. This gate
had served M7, which D11 also retired.

##### Completion Criteria

- A cross-session response names the aa-maven commit and its register row.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | none |

##### Closure Evidence

- aa-maven reset register `docs/milestone-daff1b7.md` (D13) retires the
  migration; no aa-maven target remains.

#### G6 - aa-maven lands Ant removal with the per-site build contract

Origin: 265f580 / G6
GitHub Issue: none
Status: Open

##### Summary

aa-maven removes Ant from its build (its register row M10) and reports the
commit together with the post-Ant contract for the per-site build step that
`build.xml` target `sitespecificbuild` used to run inside
`src/sitespecific/<site>`. Affected M14, which D17 deferred; this gate now
blocks no row and stays Open until aa-maven takes the work up again.

aa-maven register row: `docs/milestone-daff1b7.md` M10 (Ant removal, Deferred
and moved to the aa-maven backlog 2026-09-19, their D7).

##### Completion Criteria

- A cross-session response names the aa-maven commit and states how (or
  whether) the per-site `build.xml` step is executed after Ant removal.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-20 | Pending | aa-maven reports M10 (Ant removal) Deferred and moved to its backlog 2026-09-19 (their D7), with no landing commit. aa-env re-derived it at aa-maven modernize `3c96141d`: their register `docs/milestone-daff1b7.md` carries M10 as `Deferred` with an assignment-history row for the 2026-09-19 move, and the `maven-antrun-plugin` execution `sitespecificantscript` still runs `<ant antfile="${project.basedir}/build.xml" target="sitespecificbuild"/>`, so the per-site contract is still Ant-based. Recheck by reading that path and the pom at the then-current aa-maven `modernize` head. |

##### Closure Evidence

- none

#### G7 - aa-maven CI builds on Maven

Origin: 265f580 / G7
GitHub Issue: none
Status: Complete

##### Summary

aa-maven rebuilds CI on Maven and reports a passing workflow run. It removed
the Gradle workflows (aa-maven M1); the retired readthedocs build is covered by
G11. Affects M15.

aa-maven register row: `docs/milestone-daff1b7.md` M5 (Maven-centric CI and docs
build), reported Complete at `9a3855cd` on 2026-09-20.

##### Completion Criteria

- A cross-session response names the aa-maven commit and a passing
  workflow run.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-20 | Pass | aa-maven reports `.github/workflows/maven.yml` running `./mvnw -B -ntp clean verify` on JDK 21, passing run 35423900164 at commit `b0fcbb61` (CI added `a4952f3d`, verify build restored `54683b6c`, their M5 Complete at `9a3855cd`). aa-env re-derived at aa-maven modernize `3c96141d`: the workflow runs on JDK 21 with `./mvnw -B -ntp clean verify`; all four cited commits exist (`git cat-file -e <sha>^{commit}`) and `b0fcbb61` is an ancestor of `origin/modernize` (`git merge-base --is-ancestor`). The Actions run status itself stays peer-reported; recheck with `gh run view 35423900164 -R jeonghanlee/epicsarchiverap-maven`. |

##### Closure Evidence

- aa-maven cross-session response of 2026-09-20 (their M5 Complete, run
  35423900164 / `b0fcbb61`) and the aa-env workflow read above.

#### G8 - aa-maven Maven Wrapper build verified

Origin: 265f580 / G8
GitHub Issue: none
Status: Complete

##### Summary

aa-maven committed the Apache Maven Wrapper (`mvnw`, `mvnw.cmd`,
`.mvn/wrapper/maven-wrapper.properties`, pinned Maven 3.9.9) in commit
`ff67460`. This gate closes when a fresh clone builds through `./mvnw` so
aa-env can rely on it as the only Maven. Affects M11.

aa-maven register row: `docs/milestone-daff1b7.md` M2 (Complete).

##### Completion Criteria

- A cross-session response confirms the wrapper commit and a passing
  `./mvnw -B clean package -DskipTests` from a fresh clone.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-12 | Pass | aa-maven response: fresh clone at `c1dd0b1`, `./mvnw -B -q clean package -DskipTests` (JDK 21.0.12.1, wrapper-downloaded Maven 3.9.9) exit 0, four WARs; recorded as their M2 / T2 |

##### Closure Evidence

- aa-maven cross-session response of 2026-09-12 (their M2 Complete); the
  wrapper files and pin were re-derived from their origin on 2026-09-11.

#### G9 - aa-maven ships both DB drivers with dialect auto-detection

Origin: 265f580 / G9
GitHub Issue: none
Status: Complete

##### Summary

aa-maven ships both `mariadb-java-client` and `sqlite-jdbc` (runtime scope) in
all four WARs and the source auto-detects the SQLite vs MySQL dialect from the
DataSource's `DatabaseMetaData` product name, so either backend runs with no
source change. This replaces the earlier "removes MariaDB" framing under D15
(parallel, selectable). Affects M9.

aa-maven register rows: `docs/milestone-daff1b7.md` M11 (sqlite-jdbc) and M13
(reframed to selectable persistence, deferred and coordinated).

##### Completion Criteria

- A cross-session response names the aa-maven commit and confirms both drivers
  ship with dialect auto-detection.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-18 | Pass | aa-maven reports both drivers ship (runtime) with dialect auto-detection from DataSource metadata, adopted as its D28 at `ab324afb`; aa-env read the modernize-tip pom and found both `org.mariadb.jdbc:mariadb-java-client` and `org.xerial:sqlite-jdbc` present. WAR-level packing was not independently built here. |

##### Closure Evidence

- aa-maven cross-session response of 2026-09-18 (parallel/selectable model, `ab324afb`) and the aa-env pom read above.

#### G10 - aa-maven Phase 1 complete (servlet-api 9.0.122, CI on Maven)

Origin: 265f580 / G10
GitHub Issue: none
Status: Complete

##### Summary

aa-maven finishes its Phase 1 and reports the commit: the dependency refresh
(tomcat-servlet-api and the other current-stable pins) and CI rebuilt on Maven.
Under D17 Ant removal is deferred out of Phase 1 on both sides, so this gate no
longer carries the Ant clause; G6 keeps that item as its own Open row. With
Phase 1 closed on that basis, the source `modernize` branch is release-ready for
the aa-env install verification that gates M8. G7 (CI) stays its own row.

aa-maven register rows: `docs/milestone-daff1b7.md` M4 (dependency refresh),
M5 (CI on Maven); M10 (Ant removal) moved to their backlog 2026-09-19.

##### Completion Criteria

- A cross-session response names the aa-maven commit and confirms Phase 1 is
  complete on the D17 basis: the tomcat-servlet-api pin present in the pom and
  CI green on Maven, with Ant removal deferred.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-20 | Pass | aa-maven reports Phase 1 closed with Ant removal deferred to its backlog: servlet-api pinned at 9.0.122 and Maven CI green (run 35423900164 / `b0fcbb61`). aa-env re-derived both at aa-maven modernize `3c96141d`: `org.apache.tomcat:tomcat-servlet-api` version `9.0.122` in the pom, and `.github/workflows/maven.yml` running `./mvnw -B -ntp clean verify` on JDK 21. The Actions run status itself stays peer-reported (see G7 for its recheck command). The Ant clause is out of scope per D17; `build.xml` is still driven by antrun there (see G6). |

##### Closure Evidence

- aa-maven cross-session response of 2026-09-20 and the aa-env pom and workflow
  reads above; closed on the D17 basis (Ant removal deferred, not done).

#### G11 - aa-maven retires the Sphinx docs pipeline (mdBook on Pages)

Origin: 265f580 / G11
GitHub Issue: none
Status: Complete

##### Summary

aa-maven removed the Sphinx / Read the Docs pipeline and moved the narrative
docs to mdBook on GitHub Pages, so the aa-env build carries no docs-build
assumption. The mgmt API reference stays generated inside the mgmt WAR at
`ui/api/index.html`. Affects M21.

aa-maven register rows: `docs/milestone-daff1b7.md` M9 (mdBook docs) and M16
(in-WAR mgmt API reference).

##### Completion Criteria

- A cross-session response names the aa-maven commit and the Sphinx removal is
  observed on the modernize tip.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-18 | Pass | aa-env fetched aa-maven modernize `263805a1` and observed `.readthedocs.yaml`, `docs/docs`, `docs/build_docs.sh`, `conf.py`, and `requirements.txt` all absent, zero `sphinx` references in the pom, and `docs/book/` (mdBook) present; live remote head confirmed `263805a1` by `git ls-remote`. |

##### Closure Evidence

- aa-maven cross-session response of 2026-09-18 (mdBook live on Pages, `263805a1`) and the aa-env fetch and ls-remote observations above.

#### G12 - JNA on the WAR classpath for MariaDB Unix-socket support

Origin: 265f580 / G12
GitHub Issue: none
Status: Complete

##### Summary

MariaDB Connector/J connects over a Unix domain socket only when JNA
(`net.java.dev.jna:jna`, `jna-platform`) is on the classpath. This gate asks
whether the aa-maven WARs carry it, and they do, so aa-env can render a working
`localSocket` DataSource against the current source with no change on the
aa-maven side. Affects M9 step 2 (MariaDB/UDS).

At `3c96141d` the jars arrived transitively through `mariadb-java-client` and
`waffle-jna` rather than by declaration, so a later dependency bump could have
dropped them with no build failure and the symptom would have appeared only at
runtime. aa-env asked aa-maven to close that hole on 2026-09-21 and it landed
the same day at `85f0f179`: `jna` and `jna-platform` 5.13.0 are declared
directly at runtime scope and allowlisted for the analyze-only gate, so a bump
that drops either now fails the build instead of the socket.

aa-maven register row: none carries the closure; the declaration is theirs
(dependency management is their domain, D9).

##### Completion Criteria

- The built WARs carry `jna` and `jna-platform` on the deployed classpath, so
  `mariadb-java-client` can honour `localSocket`.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-21 | Pass | aa-env inspected the four WARs it had built itself from aa-maven `3c96141d`: `aa-20260920-3c96141d-{mgmt,engine,etl,retrieval}.war` each carry `WEB-INF/lib/jna-5.13.0.jar` and `WEB-INF/lib/jna-platform-5.13.0.jar` beside `mariadb-java-client-3.3.3.jar`. aa-maven reports the resolution path as `mariadb-java-client` to `waffle-jna` to `jna`, both runtime-scoped; that path is their observation, the jar presence is ours. Recheck with `unzip -l <war> | grep WEB-INF/lib/jna`. |

##### Closure Evidence

- Closed 2026-09-21 on the built artifact above; the MariaDB/UDS step is not
  blocked. An earlier reading of this gate recorded JNA as absent. That reading
  inspected the declared pom dependencies and the source tree instead of the
  resolved WAR, and was wrong; it is recorded here so the same check is not
  repeated the same way.
- Hardened the same day at aa-maven `85f0f179`, which aa-env verified by
  reading that commit's `pom.xml`: `net.java.dev.jna:jna` and `jna-platform`
  5.13.0 declared at runtime scope and both named in the analyze-only
  allowlist. `origin/modernize` moved `3c96141d` to `85f0f179`; aa-env tracks
  the branch through `SRC_TAG`, so the declared state arrives on the next
  checkout with no re-pin.

#### G13 - ansible-provision runs a soak with the M31 test values

Origin: 265f580 / G13
GitHub Issue: none
Status: Open

##### Summary

The ansible-provision operator writes the M31 test values (STS
`PARTITION_5MIN`/`hold=2`, MTS `PARTITION_HOUR`/`hold=2`, LTS
`PARTITION_DAY`, as listed in M31 Scope) into
`../CONFIG_SITE.local` (one directory above the checkout top) on a
provisioned test host, runs the appliance with at
least one PV archiving for a few hours, and reports where the samples are.
D23 also asks that operator to check the cross-tier ordering of the values it
writes. Affects M32.

##### Completion Criteria

- A cross-session response names the aa-env commit, the values used, the
  interval, and observed samples in STS, then MTS, then LTS.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | none |

##### Closure Evidence

- none

#### G14 - aa-maven ships the log4j2 layout with the journal priority prefix

Origin: 265f580 / G14
GitHub Issue: none
Status: Complete

##### Summary

aa-maven lands the WAR `log4j2.xml` agreed under D24: a Console PatternLayout
without timestamp, with level, logger, thread and intact stack traces, whose
level maps to the `<N>` journal priority prefix, and whose root level reads
`${env:ARCHAPPL_ROOT_LOGGER_LEVEL:-INFO}`. aa-maven reports the commit. Until
it lands, application lines written through `systemd-cat --level-prefix=true`
carry the default priority only, which is why M34 waits on this gate. Affects M34.

##### Completion Criteria

- A cross-session response names the aa-maven commit, and aa-env re-derives
  the prefix and the root-level lookup by reading that commit's `log4j2.xml`.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-24 | Pass | `git show a1155ef0:src/sitespecific/default/classpathfiles/log4j2.xml` in a fetched aa-maven clone, commit present on origin/modernize: `%level{FATAL=<2>, ERROR=<3>, WARN=<4>, INFO=<6>, DEBUG=<7>, TRACE=<7>}` on the Console layout, `<Root level="${env:ARCHAPPL_ROOT_LOGGER_LEVEL:-INFO}">` |

##### Closure Evidence

- aa-maven reported `a1155ef0` on 2026-09-24; verified as above the same day.

#### G15 - aa-maven emits the Tomcat log4j jar set from its build

Origin: 265f580 / G15
GitHub Issue: none
Status: Complete

##### Summary

Under D25 each Tomcat instance carries `log4j-api`, `log4j-core`,
`log4j-appserver` and `log4j-jul` on its classpath, at the same log4j version
as the WARs. aa-maven's build writes the four jars into one output directory
next to the WARs, so aa-env installs them from the same build that produced
the WARs and the two never drift apart. The request went to aa-maven on
2026-09-24; aa-maven reports the output directory and the commit. Affects M35.

##### Completion Criteria

- A cross-session response names the aa-maven commit and the output directory
  relative to the build target, and aa-env re-derives the four jar names and
  their version from a build of that commit through `make build.mvn`.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-24 | Pass | `make build.mvn` with the build source at `9bbd69bf` (present on origin/modernize): `target/tomcat-log4j` lists `log4j-api-2.26.1.jar`, `log4j-core-2.26.1.jar`, `log4j-appserver-2.26.1.jar`, `log4j-jul-2.26.1.jar`; sha256 of `log4j-api`, `log4j-core` and `log4j-jul` equal to the copies in `WEB-INF/lib` of the engine WAR from the same build; `log4j-appserver` carries `META-INF/services/org.apache.juli.logging.Log` |

##### Closure Evidence

- aa-maven reported `9bbd69bf` and the directory `target/tomcat-log4j` on 2026-09-24; verified as above the same day.

#### M10 - Phase 3 and 4 install tests (container, VM)

Origin: 265f580 / M10
Identity History: none
GitHub Issue: none
Status: Open

##### Summary

Implement the `tests/phase3-docker.bash` and `tests/phase4-vm.bash` stubs
described in `tests/README.md`.

##### Scope

- Container entrypoint under `tests/docker/` running `make install`.
- VM entrypoint under `tests/vm/` running the systemd stack and HTTP probes.

Out of scope: CI wiring.

##### Completion Criteria

- `tests/run-all-tests.bash --system` passes on a host with Docker and
  libvirt.

##### Dependencies And Decisions

- Decision Date: 2026-09-22. Assigned from Backlog to Milestone. The test host and implementation plan remain to be defined. Status stays Open; assignment alone does not accept or authorize implementation.
- none

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the implementation plan for the assigned work.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | System | `tests/run-all-tests.bash --system` | Host with Docker and libvirt | All assertions pass |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Host with Docker and libvirt | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Implement phase 3 and 4 install tests
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M13 - Site skin aligned with the rewritten mgmt UI

Origin: 265f580 / M13
Identity History: none
GitHub Issue: none
Status: Open

##### Summary

The management web interface rewrite moved to the EPICS-Arche repository
(the post-Phase-2 runtime, per D11). The aa-env repository carries only the
site-specific skin (`site-template/siteid`: css, img, `template_changes.html`)
copied into the WAR. While the appliance stays on WARs (Phase 2) the skin is
unchanged; it is revisited only if EPICS-Arche replaces the mgmt UI.

##### Scope

- `site-template/siteid/{css,img,template_changes.html}` and the
  `copy.sitespecific` step in `configure/RULES_SRC`.

Out of scope: the interface itself (EPICS-Arche).

##### Completion Criteria

- After planning defines the EPICS-Arche interface and aa-env's role, the
  resulting skin renders correctly on that interface. The current WAR skin
  remains unchanged until that scope is defined.

##### Dependencies And Decisions

- Decision Date: 2026-09-22. Assigned from Backlog to Milestone. The target interface and the role of the aa-env skin remain to be defined. Status stays Open; assignment alone does not accept or authorize implementation.
- EPICS-Arche repository (mgmt UI rewrite), post-Phase-2

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the implementation plan for the assigned work.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | UI | Define the actual interface and browser procedure during planning | Agreed target interface | Page renders with the site skin; no console errors |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Align the site skin with the rewritten mgmt UI
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M18 - Investigate retrieval metadata HTTP 404

Origin: 265f580 / M18
Identity History: none
GitHub Issue: [#24](https://github.com/jeonghanlee/epicsarchiverap-env/issues/24)
Status: Open

##### Summary

The reported quick-chart and live retrieval requests receive HTTP 404 from the
engine metadata endpoint. The issue has no resolution comment or current
reproduction result.

##### Scope

- Reproduce the metadata request on an explicitly identified appliance source
  and environment configuration; distinguish endpoint behavior from routing
  or PV state.
- Determine whether the fix belongs in aa-env or aa-maven before implementation.

Out of scope: assuming that a passing compile test fixes the issue, changing
the source repository without its own authorization, and closing the issue
without runtime evidence.

##### Completion Criteria

- The original request is reproduced or an evidenced non-reproduction is
  recorded with the source, environment, and PV setup.
- Any required fix has a real request-path regression check and the issue has
  an observed, authorized resolution.

##### Dependencies And Decisions

- Decision Date: 2026-09-22. Assigned from Backlog to Milestone. The reproduction environment and investigation plan remain to be defined. Status stays Open; assignment alone does not accept or authorize implementation.
- D14; recorded 2026-09-15 as unresolved work. Reproduction still needs a defined
  environment and investigation plan after assignment.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the reproduction environment and request sequence during planning.
2. Reproduce the issue and select the owning repository from observed behavior.
3. Plan the fix and regression check before changing runtime code.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime | Reproduce the issue's quick-chart/live request through retrieval and the engine metadata endpoint | To be agreed during planning | Observed HTTP result with the corresponding PV state and source revision |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Runtime environment not assigned | Pending | none |

##### Closure Evidence

- None; issue remains open.

##### GitHub Projection

Title: Investigate retrieval metadata HTTP 404
Labels: none
GitHub Milestone: none
Observed State: open
Observed Labels: none
Observed Milestone: none
Last Compared: 2026-09-15; GitHub REST issue #24 read, remote updated_at 2024-03-25T07:09:20Z

#### M19 - Investigate ETL for PV names containing underscores

Origin: 265f580 / M19
Identity History: none
GitHub Issue: [#25](https://github.com/jeonghanlee/epicsarchiverap-env/issues/25)
Status: Open

##### Summary

The issue reports PVs remaining in STS when an underscore occurs before the
final colon-separated name component. The reported namespace-separator setting
is still present in `site-template/archappl.properties.in`; this does not by
itself establish that the runtime defect persists or is fixed.

##### Scope

- Reproduce the reported PV-name cases with the generated separator settings
  and inspect transfer from STS to MTS and LTS.
- Identify whether the mismatch belongs to configuration or aa-maven's name
  mapping and storage implementation.

Out of scope: changing namespace separators on an existing data store without
an approved compatibility plan, inventing a cause from the issue description,
and closing the issue without runtime evidence.

##### Completion Criteria

- A real ETL run covers underscores in both namespace and final-name positions,
  with a colon-only control case.
- Stored samples remain retrievable after the verified transfer; any fix and
  required compatibility handling are recorded before issue resolution.

##### Dependencies And Decisions

- Decision Date: 2026-09-22. Assigned from Backlog to Milestone. The reproduction environment and investigation plan remain to be defined. Status stays Open; assignment alone does not accept or authorize implementation.
- D14; recorded 2026-09-15 as unresolved work. Reproduction still needs a defined
  environment and investigation plan after assignment.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define source revision, PV fixture, storage configuration, and ETL schedule
   during planning.
2. Reproduce the issue through the real archiving and retrieval path.
3. Plan the fix in its owning repository and address compatibility before
   changing how existing PV names map to stored paths.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime | Archive the reported underscore cases and a control PV; run ETL and retrieve their samples | To be agreed during planning | Observed tier paths and retrieval results tied to the source and configuration |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Runtime environment not assigned | Pending | none |

##### Closure Evidence

- None; issue remains open.

##### GitHub Projection

Title: Investigate ETL for PV names containing underscores
Labels: none
GitHub Milestone: none
Observed State: open
Observed Labels: none
Observed Milestone: none
Last Compared: 2026-09-15; GitHub REST issue #25 read, remote updated_at 2024-05-02T08:05:00Z

#### M27 - LTS retrieval pre-processing (`pp`)

Origin: 265f580 / M27
Identity History: none
GitHub Issue: none
Status: Open

##### Summary

`docs/README.policies.md` recommends `pp=mean_3600` on LTS, and the shipped
`site-template/policies.py.in` sets no `pp` on any tier. The gap is real but the
answer is not obvious from the documents, so it waits for operating experience
rather than being settled now.

Two facts shape the question. `pp` preserves the raw data and writes auxiliary
pre-calculated files beside it, so it *increases* disk use, which runs against
the open concern that the archive store sits on the root filesystem with an
unknown fill rate. And `pp` is mutually exclusive with `reducedata`, which the
shipped Fast, VeryFast, Medium and Slow policies already set on LTS; the
recommendation can therefore only apply to the Default and VerySlow policies.

##### Scope

- Whether the Default and VerySlow policies gain `pp` on LTS, and with which
  operator and interval.
- `site-template/policies.py.in` and the policy guide, if the answer is yes.

Out of scope: `reducedata` on the other policies; the retrieval API; the
storage filesystem work, which M26 carries.

##### Completion Criteria

- After the appliance has run with real queries and a known disk growth rate,
  a dated decision either adds `pp` to the named policies or records that the
  retrieval gain does not justify the additional storage.

##### Dependencies And Decisions

- Decision Date: 2026-09-22. Assigned from Backlog to Milestone. The operating measurements and pp selection remain unresolved. Status stays Open; assignment alone does not accept or authorize implementation.
- Condition for taking this up: an operating installation with a measured disk
  growth rate and real retrieval patterns to judge against. Owner decided
  2026-09-21 to look at it during operation over the long term rather than now.
- D21 (the storage work is scoped to the test environment first).
- The disk growth figure comes from the load test requested of the
  ansible-provision session.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Function | Compare retrieval time and disk use for a long span with and without `pp` on LTS | operating installation | The difference is large enough, or not, to settle the decision |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | operating installation | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: LTS retrieval pre-processing
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M28 - Load the schema without an admin account and fail loudly

Origin: 265f580 / M28
Identity History: none
GitHub Issue: #47
Status: Complete

##### Summary

In the externally provisioned mode of `docs/README.install.md`, `db.secure`,
`db.addAdmin` and `db.create` are skipped and only `sql.fill` runs, needing
only `DB_USER`/`DB_USER_PASS`. At `044cb62`, `sql.fill` reaches
`query_from_sql_file` in `scripts/mariadb_generic_function.bash`, whose `isDb`
check runs `SQL_ADMIN_CMD` (`DB_ADMIN`, default `admin`). That account does not
exist in this mode, so the check reports the database absent. `noDbMessage`
prints its message to stdout (the same script sets `VERBOSE=YES`
unconditionally) beside the client's `Access denied` error on stderr, and a
bare `exit` then returns 0, so the build continues. The schema load
through `SQL_DBUSER_CMD` is never reached. Observed on the reporting side, not
on this host, at 2026-09-23T09:05:24Z on three externally provisioned hosts
built from `6a026d4`: the `archappl` database had zero tables and mgmt logged
`Table 'archappl.PVTypeInfo' doesn't exist` on every PV registration. Recheck
on a host by counting rows in `information_schema.tables` where
`table_schema='archappl'` through the application account.

##### Scope

- `scripts/mariadb_generic_function.bash` and `scripts/mariadb_setup.bash`:
  functions that act as the application account check database existence
  through `SQL_DBUSER_CMD`; functions that act as the admin account keep the
  admin check. Among the `isDb` callers, only `get_admin_crypt_password` acts
  as the admin account; `backup_db` uses `SQL_BACKUP_CMD` (`DB_USER`) and
  `generate_admin_local_password` queries through `query_from_sql_file`.
- Every caller of `isDb` (`query_from_sql_file`, `show_tables`,
  `show_procedures`, `drop_tables`, `execute_query`, `drop_procedures`,
  `generate_admin_local_password`, `get_admin_crypt_password`, `backup_db`,
  `show_archappl`): a not-found result or failed existence check prints its
  message to stderr and exits non-zero, and callers that run these functions
  inside command substitution propagate that status: in
  `scripts/mariadb_setup.bash`, `generate_admin_local_password` captures
  `query_from_sql_file` at line 146 and `get_admin_crypt_password` at line 153.
- `tests/phase1-logic.bash`: a guard against restoring a zero exit on the
  not-found path.
- Exit-status change: no caller in this repository depends on the zero exit;
  the DB targets are invoked only from `configure/RULES_SQL` and as manual
  examples in `docs/technicaldocs/README.macos.md`. An external operator
  running `sql.fill` now stops at that step instead of at a later table check.

Out of scope: creating an admin account in the externally provisioned mode;
the SQLite backend (M9); the schema content shipped by aa-maven;
`docs/README.install.md`, whose lines 131 and 148 already describe the
intended behavior (`sql.fill` needs only `DB_USER`/`DB_USER_PASS` and is the
only DB step in the externally provisioned mode).

##### Completion Criteria

- With only the application account provisioned, `make sql.fill` loads the
  schema and `make sql.show` lists `PVTypeInfo`, `PVAliases`,
  `ArchivePVRequests` and `ExternalDataServers`.
- When the database is absent or the existence check cannot connect,
  `make sql.fill` exits non-zero with a message on stderr.
- The full local mode (`db.secure`, `db.addAdmin`, `db.create`, `sql.fill`)
  still loads the schema.

##### Dependencies And Decisions

- D22 (finding taken as aa-env work; the shape of the fix).
- Decision Date: 2026-09-23. Implement the application-account existence check
  and the non-zero exit; do not require an admin account in the externally
  provisioned mode.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-23; plan at `51b8846` accepted after third- and second-person review
Implementation Authorization: 2026-09-23; implement the accepted plan and run T1-T4
Superseded Plan Artifacts: none

1. Give `isDb` the account to check with, so application-account callers use
   `SQL_DBUSER_CMD` and admin-account callers keep `SQL_ADMIN_CMD`. Treat a
   failed client invocation as a failed check, not as an absent database.
2. Replace the zero-exit not-found branch in every `isDb` caller with a message
   on stderr and a non-zero exit. Propagate the status at the two
   command-substitution call sites in `generate_admin_local_password`
   (`scripts/mariadb_setup.bash:146` and `:153`).
3. Extend `tests/phase1-logic.bash` with a structural guard on the not-found
   path of the real scripts.
4. Run T1 locally, then T2-T4 on a disposable MariaDB server, and record the
   observed results.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `bash -n` on both scripts and `tests/run-all-tests.bash --phase=1` with the new guard | This host | Scripts parse; Phase 1 passes; the guard fails against the pre-change not-found branch |
| T2 | Runtime | Run `make init` so the source clone provides the schema file `sql.fill` reads. As root (`sudo mysql`), create an empty `DB_NAME` database and the application account with privileges on it only, for both `localhost` and `127.0.0.1`, matching the accounts on the externally provisioned hosts; create no `DB_ADMIN` account. Set `DB_NAME`, `DB_USER`, `DB_USER_PASS` and a `DB_ADMIN` absent from the server in `configure/CONFIG_SITE.local`, run `make db.conf` to regenerate `site-template/mariadb.conf`, then `make sql.fill` and `make sql.show` | A disposable MariaDB server (VM or container), never a shared one | `sql.fill` exits 0; the four tables are listed |
| T3 | Runtime | With the T2 settings, run `make sql.fill` after dropping the database as root, and again with a wrong `DB_USER_PASS` after `make db.conf` | A disposable MariaDB server (VM or container), never a shared one | Both exit non-zero with a message on stderr; no table is created |
| T4 | Runtime | On a fresh server, set in `configure/CONFIG_SITE.local` the `DB_ADMIN` and `DB_ADMIN_PASS` values that `db.addAdmin` creates, without creating that account by hand, run `make db.conf`, then the full local sequence `db.secure`, `db.addAdmin`, `db.create`, `sql.fill`, then `sql.show`. `db.secure` drops anonymous and remote root accounts and the `test` database as root | A disposable MariaDB server (VM or container), never a shared one | The four tables are listed |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-23T16:23:05Z | Local working tree based on `51b8846` | Pass | `bash -n` on both scripts exits 0; `shellcheck -x` reports nothing for both scripts before and after the change and nothing for `tests/phase1-logic.bash`; `TMPDIR=/tmp tests/run-all-tests.bash --phase=1` exits 0 with 65 passed, 0 failed. P1.16 runs the real `query_from_sql_file` against a closed loopback port: rc=1 with `Cannot check the database >> archappl <<` on stderr. With only `scripts/` reverted to `51b8846`, the same runner exits 1 at P1.16 with rc=0 from `query_from_sql_file`. |
| T2 | 2026-09-23T19:53:33Z | Disposable Rocky Linux 8 VM from cloud-provision, MariaDB 10.3.39, `skip_name_resolve` 0; aa-env working tree based on `51b8846`, source `b7d4b1e4` | Pass | Accounts `archappl`@`localhost` and `archappl`@`127.0.0.1` on an empty `archappl` database, no admin account (`DB_ADMIN=m28_absent`). `make sql.fill` exits 0 with empty stderr; `make sql.show` lists `ArchivePVRequests`, `ExternalDataServers`, `PVAliases`, `PVTypeInfo`, matching `information_schema.tables`. With only `scripts/` reverted to `51b8846` under the same setup, `make sql.fill` exits 0, prints the not-found message and `Access denied for user 'm28_absent'@'localhost'`, and leaves 0 tables. Repeated 2026-09-23T20:04:26Z on a recreated VM with `skip-name-resolve` and `bind-address=127.0.0.1` set as the archiver-dev MariaDB role sets them (`@@skip_name_resolve` 1): `make sql.fill` exits 0 with empty stderr and `make sql.show` lists the four tables; with `scripts/` reverted to `51b8846`, `make sql.fill` exits 0 with `Access denied for user 'm28_absent'@'127.0.0.1'` and leaves 0 tables. |
| T3 | 2026-09-23T19:53:43Z | Disposable Rocky Linux 8 VM from cloud-provision, MariaDB 10.3.39, `skip_name_resolve` 0; aa-env working tree based on `51b8846`, source `b7d4b1e4` | Pass | Database dropped as root: `make sql.fill` exits 2 (`sql.table.fill` Error 1) with the not-found message on stderr; no `archappl` schema. Database recreated and `DB_USER_PASS` wrong after `make db.conf`: exits 2 with `Access denied for user 'archappl'@'localhost'`, `Cannot check the database >> archappl <<` and the not-found message on stderr; 0 tables. |
| T4 | 2026-09-23T19:56:53Z | Recreated disposable Rocky Linux 8 VM with only MariaDB's default accounts; same aa-env tree and source | Pass | With `DB_ADMIN=admin` set in `configure/CONFIG_SITE.local` and `make db.conf`, `db.secure`, `db.addAdmin`, `db.create` and `sql.fill` each exit 0 with empty stderr; `make sql.show` lists the four tables. Remaining accounts: `root`@`localhost`, `admin`@`localhost`, `archappl`@`127.0.0.1`. |

##### Closure Evidence

- Implementation, T1-T4 and the accepted plan's checks are finished; the
  changed functions match Scope, and only `get_admin_crypt_password` keeps the
  admin-account check.
- Landed at `1fc20a8c49f4a11b611700bd1a38e67b06be4d30` on `origin/modernize`.
  Observed 2026-09-23T20:14:08Z after `git fetch origin`:
  `git merge-base --is-ancestor 1fc20a8 origin/modernize` exited 0 and
  `origin/modernize` resolved to `1fc20a8`.
- Complete 2026-09-23. Issue #47's body was synchronized with the shipped
  implementation and verification results, then closed as completed.
  Observed 2026-09-23T20:27:01Z through
  `gh api repos/jeonghanlee/epicsarchiverap-env/issues/47`: state `closed`,
  state_reason `completed`, label `bug`, no milestone; the remote body matched
  the prepared content. The commit's `Closes #47` takes effect only on the
  default branch.
- Confirmed on the real deploy path 2026-09-24, reported by the
  LAB-epicsarchiverap-maven session: the ansible-provision role deployed
  aa-env `1fc20a8` with aa-maven `b7d4b1e4` on a disposable Rocky 8.10 VM,
  and `make sql.fill` loaded the four tables as the application account over
  TCP during the deploy, with no admin account and no manual load (MariaDB
  10.3.39, driver only in each WAR's `WEB-INF/lib`); a PV archived and
  retrieved, and archiving resumed within 90 s of a unit restart.

##### GitHub Projection

Title: sql.fill exits 0 with no schema loaded
Labels: bug
GitHub Milestone: none
Observed State: closed
Observed Labels: bug
Observed Milestone: none
Observed Updated At: 2026-09-23T20:27:01Z
Last Compared: 2026-09-23T20:27:01Z; `gh api repos/jeonghanlee/epicsarchiverap-env/issues/47` read

#### M29 - Fail the backup listing and restore on error

Origin: 265f580 / M29
Identity History: none
GitHub Issue: #48
Status: Complete

##### Summary

At `1fc20a8`, `backup_db_list` (`dbBackupList`) and `restore_db`
(`dbRestore`) in `scripts/mariadb_setup.bash` print a message to stdout and end
with a bare `exit`, which returns 0, when the backup directory is missing or
the restore date is not given. `restore_db` then runs
`gunzip < <backup file> | ${SQL_ADMIN_CMD} ${DB_NAME}` without `pipefail`, so
a missing backup file restores nothing without making the function fail. A
caller cannot tell a failed restore from a completed one. Found while checking
M28's code paths for the same zero-status pattern; neither function calls
`isDb`.

##### Scope

- `scripts/mariadb_setup.bash` `backup_db_list` and `restore_db`: each failure
  message goes to stderr and the function exits non-zero.
- `restore_db`: a missing or unreadable backup file fails before the client
  runs, and a failure in the restore pipeline is returned.
- `tests/phase1-logic.bash`: a guard for the non-zero exits.

Out of scope: the account `restore_db` uses; backup creation (`backup_db`).

##### Completion Criteria

- `bash scripts/mariadb_setup.bash dbBackupList <missing directory>` exits
  non-zero with a message on stderr.
- `bash scripts/mariadb_setup.bash dbRestore` without a date, with a missing
  directory, and with a date whose backup file does not exist each exit
  non-zero with a message on stderr and restore nothing.
- A restore from an existing backup file still exits 0.

##### Dependencies And Decisions

- None. Assigned to Milestone on 2026-09-23 with issue #48.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-23; plan at `9a1a0cd` accepted
Implementation Authorization: 2026-09-23; implement the accepted plan and run T1-T2
Superseded Plan Artifacts: none

1. In `backup_db_list` and `restore_db`, send each failure message to stderr
   and replace each bare `exit` with a non-zero exit.
2. In `restore_db`, check that the backup file is readable before the restore,
   and return the pipeline's failure status.
3. Extend `tests/phase1-logic.bash` with a guard that runs the real script's
   failure paths.
4. Run T1 locally and T2 on a disposable MariaDB server, and record the
   observed results.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `bash -n` and `tests/run-all-tests.bash --phase=1` with the new guard | This host | Script parses; Phase 1 passes; the guard fails against the pre-change script |
| T2 | Runtime | Run `dbBackupList` with a missing directory, and `dbRestore` without a date, with a missing directory and with an absent backup file; then back up and restore an existing database with `dbBackup` and `dbRestore` | A disposable MariaDB server (VM or container), never a shared one | Each failure exits non-zero with a message on stderr and restores nothing; the real restore exits 0 |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-23T21:39:51Z | Local working tree based on `8abd039` | Pass | `bash -n` and `shellcheck -x` report nothing for `scripts/mariadb_setup.bash` and `tests/phase1-logic.bash`; `TMPDIR=/tmp tests/run-all-tests.bash --phase=1` exits 0 with 74 passed, 0 failed. P1.17 runs the real `mariadb_setup.bash` from an isolated copy of the Make system with `mariadb.conf` rendered by the real `db.conf` rule: `dbBackupList` with a missing directory and `dbRestore` without a date, with a missing directory and with an absent backup file each exit 1 with the expected stderr message. With only `scripts/` reverted to `8abd039`, the same runner exits 1 at P1.17 with rc=0 from `dbBackupList` (observed 2026-09-23T21:13:14Z). |
| T2 | 2026-09-23T21:57:44Z | Disposable Rocky Linux 8 VM from cloud-provision, MariaDB 10.3.39; aa-env working tree based on `8abd039` with the restore pipeline in a `pipefail` subshell; local mode through `db.secure`, `db.addAdmin`, `db.create`, plus a sample table `m29` with one row | Pass | `dbBackup` exits 0 and writes `archappl_<date>.sql.gz`; `dbBackupList` on it exits 0. Exit 1 with the stderr message for: `dbBackupList` with a missing directory; `dbRestore` without a date, with a missing directory, and with an absent backup file; a corrupt `.sql.gz` (`not in gzip format` plus the restore-failed message); a wrong `DB_ADMIN_PASS` (`Access denied` plus the restore-failed message). The table held its one row after both the corrupt-file and wrong-password cases. After dropping the table, `dbRestore <date> <dir>` exits 0 and the row returns. An earlier run at 2026-09-23T21:21:53Z against the superseded `local -` form passed the same cases; with only `scripts/` reverted to `8abd039` (2026-09-23T21:22:01Z), the missing-directory, missing-date, absent-file and corrupt-file cases all exit 0, and the absent file reports only the shell's redirection error, so the client ran on empty input and still exited 0. |

##### Closure Evidence

- Implementation, T1 and T2 are finished against the accepted plan; the
  restore pipeline confines `pipefail` in a subshell.
- Landed at `9f22eac` on `origin/modernize`. Observed 2026-09-23T22:02:56Z
  after `git fetch origin`: `git merge-base --is-ancestor 9f22eac
  origin/modernize` exited 0 and `origin/modernize` resolved to `93c6baa`.
- Complete 2026-09-23. Issue #48's body was synchronized with the shipped
  implementation and verification results, then closed as completed.
  Observed 2026-09-23T22:08:34Z through
  `gh api repos/jeonghanlee/epicsarchiverap-env/issues/48`: state `closed`,
  state_reason `completed`, label `bug`, no milestone; the remote body matched
  the prepared content. The commit's `Closes #48` takes effect only on the
  default branch.

##### GitHub Projection

Title: dbRestore and dbBackupList exit 0 on failure
Labels: bug
GitHub Milestone: none
Observed State: closed
Observed Labels: bug
Observed Milestone: none
Observed Updated At: 2026-09-23T22:08:34Z
Last Compared: 2026-09-23T22:08:34Z; `gh api repos/jeonghanlee/epicsarchiverap-env/issues/48` read

#### M30 - Fail the backup when the dump fails

Origin: 265f580 / M30
Identity History: none
GitHub Issue: #49
Status: Complete

##### Summary

At `8abd039`, `backup_db` (`dbBackup`) in `scripts/mariadb_setup.bash` runs
`${SQL_BACKUP_CMD} "${db_name}" | gzip -9 > <backup file>` without
`pipefail`, so the pipeline returns `gzip`'s status. When `mysqldump` fails,
`gzip` still writes a valid empty archive and exits 0, so `dbBackup` exits 0
and leaves a file that looks like a backup. Reproduced on 2026-09-23 on this
host with the same pipeline shape and a real `mysqldump` using an account that
cannot log in: `Access denied`, pipeline status 0, and a 20-byte `.sql.gz`
that passes `gunzip -t` and expands to 0 bytes. Found by the M29 third-person
review as an out-of-scope observation.

##### Scope

- `scripts/mariadb_setup.bash` `backup_db`: return the dump's failure from the
  backup pipeline, remove the partial backup file, print a message to stderr
  and exit non-zero.

Out of scope: `backup_db_list` and `restore_db` (M29); the backup file naming
and the account the dump uses.

##### Completion Criteria

- When the dump fails after the database existence check passes,
  `bash scripts/mariadb_setup.bash dbBackup <directory>` exits non-zero with a
  message on stderr and leaves no backup file.
- A backup of an existing database still exits 0, and the file restores
  through `dbRestore`.

##### Dependencies And Decisions

- None. Assigned to Milestone on 2026-09-23 with issue #49.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-23; plan at `93c6baa` accepted
Implementation Authorization: 2026-09-23; implement the accepted plan and run T1-T2
Superseded Plan Artifacts: none

1. In `backup_db`, run the dump pipeline with `pipefail` confined to a
   subshell, and on failure remove the backup file, print a stderr message and
   exit non-zero.
2. Run T1 locally and T2 on a disposable MariaDB server, and record the
   observed results.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `bash -n`, `shellcheck -x` and `tests/run-all-tests.bash --phase=1` | This host | Script parses and lints; Phase 1 passes |
| T2 | Runtime | Make the dump fail after the existence check passes, run `dbBackup`, then run a normal `dbBackup` and restore it with `dbRestore` | A disposable MariaDB server (VM or container), never a shared one | The failing backup exits non-zero with a stderr message and leaves no file; the normal backup exits 0 and restores |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-23T22:31:57Z | Local working tree based on `6557e75` | Pass | `bash -n` and `shellcheck -x` report nothing for `scripts/mariadb_setup.bash`; `TMPDIR=/tmp tests/run-all-tests.bash --phase=1` exits 0 with 74 passed, 0 failed. Phase 1 does not reach the dump, which needs a database that passes the existence check; T2 covers it. |
| T2 | 2026-09-23T22:38:28Z | Disposable Rocky Linux 8 VM from cloud-provision, MariaDB 10.3.39; aa-env working tree based on `6557e75`; local mode through `db.secure`, `db.addAdmin`, `db.create`, plus a sample table `m30` with one row | Pass | `dbBackup` exits 0 with empty stderr and writes a 673-byte `archappl_<date>.sql.gz`; after dropping the table, `dbRestore` from it exits 0 and the row returns. With `DB_USER` switched to an account holding only `SELECT` on `archappl` (so the existence check passes) and `make db.conf`, `dbBackup` exits 1 with `mysqldump` error 1044 on `LOCK TABLES` and the backup-failed message on stderr, and the backup directory is empty. With only `scripts/` reverted to `6557e75` under the same account (2026-09-23T22:40:28Z), `dbBackup` exits 0 with the same `mysqldump` error and leaves a 355-byte `.sql.gz`. |

##### Closure Evidence

- Implementation, T1 and T2 are finished against the accepted plan; no other
  dump or gzip pipeline remains in `scripts/` or `configure/RULES*`.
- Landed at `18356d1` on `origin/modernize`. Observed 2026-09-23T23:03:35Z
  after `git fetch origin`: `git merge-base --is-ancestor 18356d1
  origin/modernize` exited 0 and `origin/modernize` resolved to `18356d1`.
- Complete 2026-09-23. Issue #49's body was synchronized with the shipped
  implementation and verification results, then closed as completed.
  Observed 2026-09-23T23:04:57Z through
  `gh api repos/jeonghanlee/epicsarchiverap-env/issues/49`: state `closed`,
  state_reason `completed`, label `bug`, no milestone; the remote body matched
  the prepared content. The commit's `Closes #49` takes effect only on the
  default branch.

##### GitHub Projection

Title: dbBackup exits 0 when the dump fails
Labels: bug
GitHub Milestone: none
Observed State: closed
Observed Labels: bug
Observed Milestone: none
Observed Updated At: 2026-09-23T23:04:56Z
Last Compared: 2026-09-23T23:04:57Z; `gh api repos/jeonghanlee/epicsarchiverap-env/issues/49` read

#### M31 - Selectable store granularity and hold for test hosts

Origin: 265f580 / M31
Identity History: Split from M26 on 2026-09-23 (D23); M26 keeps the
archive-store filesystem half.
GitHub Issue: #50
Status: Complete

##### Summary

`site-template/policies.py.in` writes the store granularity and hold as
literals: STS `PARTITION_HOUR` with `hold=2`, MTS `PARTITION_DAY` with
`hold=2`, LTS `PARTITION_YEAR`. A test host cannot shorten the STS to MTS to
LTS chain without editing the shipped template. The ansible-provision
operator reported on 2026-09-23 that on its soak host the first STS to MTS
movement took about four hours, so MTS to LTS at `PARTITION_DAY` takes two
days or more, and asked for a test policy selectable through
`ARCHAPPL_POLICIES`. `ARCHAPPL_POLICIES` already selects the policy file end
to end (`configure/CONFIG_SITE`, `conf.policies` in
`configure/RULES_PROPERTIES`, `policies.install` in `configure/RULES_INSTALL`,
`site-template/archappl.conf.in`). D23 takes Make variables in the existing
template instead of a second file.

##### Scope

- `configure/CONFIG_SITE`: `ARCHAPPL_STS_GRANULARITY`, `ARCHAPPL_STS_HOLD`,
  `ARCHAPPL_MTS_GRANULARITY`, `ARCHAPPL_MTS_HOLD` and
  `ARCHAPPL_LTS_GRANULARITY`, defaulting to the current values.
- `site-template/policies.py.in`: the three store URLs take those values
  through `@...@` placeholders.
- `configure/RULES_PROPERTIES` `conf.policies`: substitute the values, and
  stop before writing `policies.py` when a granularity is not one of the seven
  `PartitionGranularity` names in aa-maven (`PARTITION_5MIN`,
  `PARTITION_15MIN`, `PARTITION_30MIN`, `PARTITION_HOUR`, `PARTITION_DAY`,
  `PARTITION_MONTH`, `PARTITION_YEAR`, read at aa-maven `b7d4b1e4` on
  2026-09-23; recheck when the followed source changes, D20) or a hold is not
  a positive integer. A hold of at least 1 keeps `hold - gather` non-negative
  with the fixed `gather=1`, which `PlainPBStoragePlugin` reports as an error
  otherwise.
- `docs/README.policies.md`: the variables, their defaults and the test-host
  example values, which are the M31 test values: STS `PARTITION_5MIN` with
  `hold=2`, MTS `PARTITION_HOUR` with `hold=2`, LTS `PARTITION_DAY`. Each is
  an accepted name, each hold satisfies `hold >= gather`, and the tiers run
  from finer to coarser.
- `tests/phase1-logic.bash`: a guard on the rendered policy.

Out of scope: `gather`, `consolidateOnShutdown` and `reducedata`; `pp` (M27);
the cross-tier ordering check, requested from the ansible-provision operator
(D23); the run that observes the chain with the test values (M32); a separate
policy file; production values.

##### Completion Criteria

- With no override, the generated `policies.py` is identical to the one the
  template at the pre-change commit renders.
- With test values in `../CONFIG_SITE.local`, the three store URLs carry them.
- An unknown granularity name or a hold that is not a positive integer makes
  `conf.policies` fail before `policies.py` is written.
- `docs/README.policies.md` documents the variables.

##### Dependencies And Decisions

- D21 (test environment first) and D23 (variables in the existing template;
  ordering check requested from ansible-provision).
- The runtime observation of the chain is M32, which depends on this row and
  on G13, so this row does not wait on the ansible-provision soak.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-23; plan at `b92f47a` accepted after third- and second-person review
Implementation Authorization: 2026-09-23; implement the accepted plan and run T1
Superseded Plan Artifacts: none

1. Add the five variables to `configure/CONFIG_SITE` with the current values
   as defaults.
2. Replace the literals in the three store URLs of
   `site-template/policies.py.in` with placeholders.
3. In `conf.policies`, validate each value and add the substitutions.
4. Document the variables and a test-host example in
   `docs/README.policies.md`.
5. `conf.policies` writes `site-template/policies.py` and a copy under
   `ARCHAPPL_SITEID_CLASSPATHFILES_PATH`, so render only in isolated copies
   of the Make system, as the Phase 1 backup and restore check does. Render
   the pre-change commit and the changed tree once each with no override,
   diff the two `policies.py` files and record the result. Extend
   `tests/phase1-logic.bash` so, in an isolated copy, the default values
   reach the three URLs, test values reach them, and invalid values fail.
6. After the change lands, send the ansible-provision operator the variable
   names, the accepted values and the request for the ordering check, and ask
   it for the G13 soak.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | In isolated copies of the Make system, diff the default render against the pre-change commit's render once; `bash -n` and `tests/run-all-tests.bash --phase=1` with the new guard | This host | No difference from the pre-change render; default and test values reach the URLs; invalid values stop `conf.policies`; the guard fails against the pre-change template |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-24T01:06:24Z | Local working tree based on `b92f47a`; isolated copies of the Make system | Pass | Rendered `conf.policies` with no override in an isolated copy of `b92f47a` and of the changed tree: the two `policies.py` files are byte-identical (9471 bytes). `bash -n` and `shellcheck -x` report nothing for `tests/phase1-logic.bash`; `TMPDIR=/tmp tests/run-all-tests.bash --phase=1` exits 0 with 90 passed, 0 failed. P1.18 runs the real `conf.policies` rule in an isolated copy: the default values and the test values (`PARTITION_5MIN`/3, `PARTITION_HOUR`/2, `PARTITION_DAY`) reach the three store URLs, and `PARTITION_WEEK`, a two-word `PARTITION_HOUR PARTITION_DAY`, `hold=0` and `hold=two` each stop make (rc=2) with no `policies.py` written. With `configure/` and `site-template/` reverted to `b92f47a` (2026-09-24T00:39:29Z), the runner exits 1 at P1.18 because the test values do not reach the STS URL. |

##### Closure Evidence

- Implementation and T1 are finished against the accepted plan; the default
  render is byte-identical to the pre-change template's.
- Landed at `9eed006` on `origin/modernize`. Observed 2026-09-24T01:23:42Z
  after `git fetch origin`: `git merge-base --is-ancestor 9eed006
  origin/modernize` exited 0 and `origin/modernize` resolved to `9eed006`.
- The ansible-provision operator was sent the variable names, accepted
  values, the test values, the ordering-check request and the G13 soak
  request on 2026-09-24 (plan step 6).
- Complete 2026-09-24: every completion criterion is met by T1 and the landing
  above. Issue #50, filed the same day, records this change; it stays open for
  the soak criterion, which M32 carries.

##### GitHub Projection

Title: Selectable store granularity and hold
Labels: enhancement
GitHub Milestone: none
Observed State: open
Observed Labels: enhancement
Observed Milestone: none
Observed Updated At: 2026-09-24T01:40:37Z
Last Compared: 2026-09-24T01:40:37Z; `gh api repos/jeonghanlee/epicsarchiverap-env/issues/50` read after creation; the issue stays open until the soak criterion, which M32 carries, is observed

#### M32 - Observe the store chain with the test values

Origin: 265f580 / M32
Identity History: Split from M31 on 2026-09-23 so M31 does not wait on the
external soak.
GitHub Issue: #50
Status: Blocked

##### Summary

With the M31 test values (listed in M31 Scope) on a provisioned test host, a
run of a few hours should show samples moving from STS to MTS to LTS, which the shipped values
make impossible to observe in a short run. The run is the ansible-provision
operator's (G13).

##### Scope

- Record the soak G13 reports: aa-env commit, values, interval and the tiers
  that hold samples.

Out of scope: the variables and their checks (M31); production values.

##### Completion Criteria

- With the M31 test values on a test host, a run of a few hours shows samples
  in STS, then MTS, then LTS.

##### Dependencies And Decisions

- M31 (the variables must land first) and G13 (the soak is run by the
  ansible-provision operator); D23. Blocked from creation on G13; resume as
  Not started.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. When G13 reports, re-derive what can be checked from aa-env (the commit and
   the rendered values) and record the reported tier observations with their
   source.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime | Archive at least one PV with the M31 test values for a few hours (G13) | Provisioned test host (ansible-provision) | Samples appear in STS, then MTS, then LTS |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Provisioned test host | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Selectable store granularity and hold
Labels: enhancement
GitHub Milestone: none
Observed State: open
Observed Labels: enhancement
Observed Milestone: none
Observed Updated At: 2026-09-24T01:40:37Z
Last Compared: 2026-09-24T01:40:37Z; `gh api repos/jeonghanlee/epicsarchiverap-env/issues/50` read after creation; #50 is shared with M31 and closes on this row's soak criterion

#### M33 - Run the four Tomcats in the foreground under one journald-collected service

Origin: 265f580 / M33
Identity History: none
GitHub Issue: none
Status: In progress

##### Summary

At `f9433a3` each instance produces four streams: application log4j2 output
(Console, into `catalina.out`), Tomcat JULI dated files (`catalina.<date>.log`,
`localhost.<date>.log`, `maxDays = 90`), the access log
(`site-template/skel/conf/server.xml:164`, daily files, no `maxDays`), and
process stdout in an unrotated `catalina.out`, because
`site-template/systemd/epicsarchiverap-maven.service.in` is `Type=forking` and
`scripts/archappl.bash` starts each instance with `bin/startup.sh` in the
background (`:71`). No Tomcat output reaches journald. D24 moves the appliance to the
journald model while keeping the single service of D12 and the no-restart rule
of D19. The launcher also tells users to tail `logs/archappl_service.log`
(`archappl.bash:120`), which nothing writes.

##### Scope

- `site-template/systemd/epicsarchiverap-maven.service.in`: `Type=simple`
  (`Type=exec` arrived with systemd 240 and Rocky 8 runs 239, which would
  ignore the value with a parse warning; for a launcher that stays up the two
  behave the same), `KillMode=mixed`, `Restart=no`, `TimeoutStopSec` from
  `SYSTEMD_TIMEOUT_STOP_SECONDS` (default 300) sized from T2's measured ETL
  stop, and no `ExecStop`: `systemctl stop` reaches the launcher as SIGTERM,
  so a Tomcat exit during a stop is never read as a child death.
- A foreground wrapper per instance, rendered like `site-template/startup.sh.in`
  by `configure/RULES_FUNC` step 4 (source `archappl.conf` and the instance
  conf, export `CATALINA_BASE` and `CATALINA_PID`, then `exec catalina.sh run`
  so the process the launcher holds is the JVM), or the launcher exporting
  that same environment itself. `catalina.sh run` writes no pid file, so the
  launcher writes each JVM's PID to `temp/<service>.pid` after the start and
  removes it after the exit; `get_pid` (`scripts/archappl.bash:53`) and M23's
  `health_instance` (`:280`) read that file.
- `scripts/archappl.bash`: as the service's main process, start mgmt, engine,
  etl and retrieval in the foreground (`catalina.sh run`) in that order, each
  with stdout and stderr through
  `systemd-cat --identifier=archappl-<component> --level-prefix=true` (no line
  carries a `<N>` prefix yet, so all lines take the default priority: JULI
  and `java.util.logging` lines until M35, application lines until M34). Each
  instance's `systemd-cat` reads a FIFO under `temp/` as an ordinary
  background job, and the wrapper writes to that FIFO as a second background
  job, so `$!` of the wrapper is, through `exec catalina.sh run` and
  catalina.sh's own `exec java`, the JVM, and `$!` of the `systemd-cat` job
  is its own PID. Neither a pipeline nor a process substitution serves: in a
  pipeline `$!` is the `systemd-cat` process, and on Rocky 8's bash 4.4
  `wait -n` does not return when a process substitution ends (measured
  2026-09-24 in a Rocky 8 container with bash 4.4.20: a finished
  `>(sleep 1)` left `wait -n` blocked until an unrelated child ended 30 s
  later, a plain child's end returned it at once, and `wait -n <pid>` was
  refused with 127). So the launcher runs a plain `wait -n` and, each time it
  returns, checks the four JVM PIDs and the four `systemd-cat` PIDs with
  `kill -0`. A dead `systemd-cat` is treated like a dead Tomcat, because the
  JVM keeps running while `System.out` swallows the write errors and that
  component's log would vanish silently. On SIGTERM stop engine,
  retrieval, etl, mgmt in that order by sending SIGTERM to each JVM PID and
  waiting for that PID to leave (the shutdown ports are `-1` by default,
  `configure/CONFIG_SRC:41-44` applied at install by `RULES_INSTALL`, so
  today's `bin/shutdown.sh` already ends in a SIGTERM through the pid file;
  with or without a port, `catalina.sh stop` follows after five seconds with
  a `kill -3` thread dump, which the launcher must not reproduce); when a
  Tomcat dies, stop the survivors the same way in that order and exit
  non-zero. `bin/shutdown.sh` stays for shell users only. The interactive `startup` and `shutdown`
  commands keep working for a shell user outside the service; a shell
  `shutdown` while the service runs is a child death to the launcher and ends
  the unit failed. Remove the stale `archappl_service.log` hint.
- `site-template/skel/conf/logging.properties`: only the ConsoleHandler, with
  `org.apache.juli.OneLineFormatter` in place of the non-existent
  `SystemdFormatter` (D25) so each record is one journal entry; the `1catalina`
  and `2localhost` AsyncFileHandlers go. M35 retires this file's role.
- `site-template/skel/conf/server.xml`: `maxDays="90"` on the AccessLogValve.
- `site-template/log4j.properties.in` and everything that renders it: the
  `conf.log4j` and `conf.log4j.show` rules and the `log4j` entry in
  `properties_RULES_NAMES` (`configure/RULES_PROPERTIES`),
  `ARCHAPPL_LOG4JPROPERTIES` and its comment (`configure/CONFIG_SITE`), and
  the `log4j.properties` line in `.gitignore`. Nothing under log4j2 reads the
  file; `ARCHAPPL_ROOT_LOGGER_LEVEL` reaches the appliance through M34 instead.
- `docs/README.install.md` and `docs/technicaldocs/README.systemd.md`: the
  service shape, where each stream goes, `journalctl` usage by identifier,
  the multi-line stack trace limit, that a shell `shutdown` while the
  service runs ends the unit failed, and that a `systemd-cat` process dying
  under a running Tomcat is handled the same way rather than losing that
  component's log silently.
- `tests/phase1-logic.bash`: guards on the rendered unit and the launcher.

Out of scope: the log4j2 configuration (M34); Tomcat and `java.util.logging` output through log4j2 (M35); automatic restart (D19); the M23 health timer, which stays until a separate decision;
journald settings on the hosts (ansible-provision); the layout, levels and
docs on the aa-maven side.

##### Completion Criteria

- On a test host, `make install` and `make sd_start` bring up four Tomcats as
  children of the launcher under one active service; `journalctl -u <unit>
  -t archappl-<component>` shows each component's lines and no `catalina.out`
  or JULI dated file is written.
- `systemctl stop <unit>` stops the components in the order engine, retrieval,
  etl, mgmt and the unit reaches inactive within `TimeoutStopSec`, with the
  measured ETL stop recorded.
- Killing one Tomcat, or one `systemd-cat` process, leaves the unit failed
  after the survivors stopped in order, with no automatic restart.
- The access valve removes an access log file whose modification time is
  older than 90 days: a `localhost_access_log.*.txt` file dated 91 days back
  before start is gone after the first background pass of the running Tomcat;
  the install guide and the systemd guide describe the model.

##### Dependencies And Decisions

- D12 (single service, launcher owns the order), D19 (no automatic restart),
  D24 (the model).
- The `systemd-cat` binary is part of systemd on Rocky Linux 8 and Debian 13;
  macOS keeps the interactive `startup` and `shutdown` path only.
- M23 (In progress) reads `temp/<service>.pid` through `health_instance`;
  the launcher keeps writing that file in the foreground mode, so M23's
  checks stay valid without a change on its side.
- `systemd-cat` parses `<N>` priority prefixes by default; the v239 and v257
  man pages both state "enabled (the default)", and a probe on systemd 257
  recorded `PRIORITY=3` with the prefix stripped. `--level-prefix=true` stays
  explicit to record the intent, and T2 repeats the probe on systemd 239.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-24, owner acceptance of the plan as recorded at c154a64 after aa-maven's review
Implementation Authorization: 2026-09-24, owner authorization for the plan accepted the same day
Superseded Plan Artifacts: none

1. Change the unit template to `Type=exec`, `KillMode=mixed`, `Restart=no`
   and a provisional `TimeoutStopSec`; keep `ExecStart` on the launcher and
   remove `ExecStop`.
2. In `scripts/archappl.bash`, add the service mode: foreground start of the
   four Tomcats in order through the per-instance wrapper and `systemd-cat`,
   each started as a background job writing to a FIFO that a background
   `systemd-cat` reads, so `$!` gives the JVM and the `systemd-cat` PID in
   turn, the JVM PID written
   to `temp/<service>.pid`, a SIGTERM trap that stops them in order with
   SIGTERM to each JVM PID and a wait on that PID, a plain `wait -n` loop
   with a `kill -0` check of the JVM and `systemd-cat` PIDs (bash 4.4 on
   Rocky 8 has no `wait -n <pid>`), ordered stop of survivors the same way, removal
   of the pid files and a non-zero exit on a child death. Keep `startup` and
   `shutdown` for shells.
3. Reduce `logging.properties` to the ConsoleHandler with `OneLineFormatter`;
   add `maxDays="90"` to the access valve; remove `log4j.properties.in` and
   everything the scope lists for it; remove the stale log hint.
4. Extend `tests/phase1-logic.bash`: the rendered unit carries the three
   directives and no `ExecStop`; the launcher parses and lints; no JULI file handler remains;
   the valve carries `maxDays`.
5. On a disposable VM, install, start, observe the four identifiers in the
   journal, archive a few PVs from a `softIoc` on the VM for some minutes,
   measure an ETL stop with that data in STS, stop in order, kill one
   Tomcat and observe the ordered stop and the failed unit; set
   `TimeoutStopSec` from the measurement and record it.
6. Update the two guides.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `bash -n`, `shellcheck -x` on the launcher; `tests/run-all-tests.bash --phase=1` with the new guards | This host | Unit renders with `Type=exec`, `KillMode=mixed`, `Restart=no` and no `ExecStop`; no JULI file handler; valve has `maxDays`; the guards fail against the pre-change tree |
| T2 | Runtime | Full install and `make sd_start`; `journalctl -u <unit> -t archappl-<component>` per component; `systemctl stop` timed with samples in STS from a few `softIoc` PVs on the VM archived for some minutes; `kill` of one Tomcat; priority probe `printf '<3>probe\n' \| systemd-cat -t archappl-probe` read back with `journalctl -t archappl-probe -o json`; a `localhost_access_log.old.txt` created with `touch -d '91 days ago'` in one instance's `logs` before start; `archappl.bash status` and `archappl.bash health` (M23) while running; `kill` of one `systemd-cat` process; `bash --version` and the launcher's `wait -n` loop observed on the VM's bash 4.4 | Disposable VM built from the aa-env tree with a `softIoc` (never a shared host) | Four identifiers present; `status` and `health` find every JVM through `temp/<service>.pid` (the JVM, not `systemd-cat`); a killed `systemd-cat` ends the unit failed after an ordered stop, like a killed Tomcat; the `wait -n` loop returns and re-checks on bash 4.4; no `catalina.out` or dated JULI file; ordered stop within the recorded time; failed unit after an ordered stop, no restart; the probe lands with `PRIORITY` 3 and `<3>` stripped from `MESSAGE` on systemd 239; the old access log file is gone within a minute of start |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-24T21:38:17Z | Local working tree based on `c154a64`; an isolated copy of the Make system for the unit render; the real `systemd-cat` of this host (systemd 257) with fake instances for a logic smoke test | Pass | `bash -n` and `shellcheck -x` report nothing for `scripts/archappl.bash`; `tests/run-all-tests.bash --phase=1` exits 0 with P1.19 passing: the rendered unit carries `Type=simple`, `KillMode=mixed`, `Restart=no`, `TimeoutStopSec=300s`, an `ExecStart` in service mode and no `ExecStop`; the launcher carries the identifier, the `wait -n` loop and `bin/run.sh`, and no `archappl_service.log`; `run.sh.in` execs `catalina.sh run`; `make -n install.mgmt` renders `bin/run.sh`; JULI keeps only the ConsoleHandler with `OneLineFormatter`; the valve carries `maxDays="90"`; `log4j.properties.in` and `conf.log4j` are gone; `tests/run-all-tests.bash --phase=2` also exits 0 after `log4j.properties` left the Phase 2 rendered-file list. Smoke test with four fake instances (a shell loop each) and the real `systemd-cat`: pid files hold the instance PIDs; killing one `systemd-cat` ends the launcher with rc 1 after the ordered stop engine, retrieval, etl, mgmt; SIGTERM ends it with rc 0 in the same order; no pid file remains; a `<6>` line landed at `PRIORITY` 6 with the prefix stripped |
| T2 | 2026-09-24T21:55:21Z (last start; observations 21:44Z to 21:55Z) | Disposable Rocky Linux 8.10 VM from cloud-provision (bash 4.4.20, systemd 239, Tomcat 9.0.121 from `make tomcat`, MariaDB 10.3.39, WARs from aa-maven `9bbd69bf`), aa-env working tree based on `c154a64` with the M33 change, `java-21-openjdk-devel` added by hand for the `JAVA_HOME` link; a `softIoc` with three records on the host's bridge address, `EPICS_CA_ADDR_LIST` set to it | Pass | Full `make install` and `make sd_start`: unit active with `Type=simple`, `KillMode=mixed`, `Restart=no`, `TimeoutStopSec=300s`, no `ExecStop`; `journalctl -u <unit> -t archappl-<component>` shows 92 to 143 entries per identifier after start; `logs/` holds only `localhost_access_log.<date>.txt` per instance, no `catalina.out`, no dated JULI file; the four pid files name the JVMs (`/proc/<pid>/exe` is java) and `status` and `health` verify all four; a JULI line is one entry at `PRIORITY` 6 (all 202 mgmt entries at 6); `printf '<3>probe' | systemd-cat -t archappl-probe` lands at `PRIORITY` 3 with `MESSAGE=probe` on systemd 239; three PVs archived (`Being archived`, 234 samples each over ten minutes, one STS file per PV); a `localhost_access_log.old.txt` dated 91 days back is gone after a restart; `systemctl stop` with samples in STS stops engine, retrieval, etl, mgmt in that order in 10.3 s (engine 10.1 s, the others under 0.1 s, each through Tomcat's ProtocolHandler pause, stop and destroy), unit inactive, no pid file left; `kill -KILL` of the retrieval JVM: `process <pid> is gone`, survivors stopped in order, unit failed with status 1, no restart; `kill -TERM` of the etl `systemd-cat`: same outcome; after each restart exactly four java processes and four ports; the `wait -n` loop woke on both deaths on bash 4.4. `TimeoutStopSec` stays at the 300 s default: the measured stop is 10.3 s with three PVs and the bound leaves room for a loaded ETL |

##### Closure Evidence

- none

##### GitHub Projection

Title: Run the four Tomcats in the foreground under one journald-collected service
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M34 - Take the log4j2 configuration from the WAR with journal priorities

Origin: 265f580 / M34
Identity History: none
GitHub Issue: none
Status: Not started

##### Summary

Under D24 one `log4j2.xml` ships, aa-maven's in the WAR, with the `<N>`
priority prefix and a root level read from `ARCHAPPL_ROOT_LOGGER_LEVEL`. aa-env
today installs its own Console-only `site-template/log4j2.xml` and points
`LOG4J_CONFIGURATION_FILE` at it (`site-template/archappl.conf.in:12`); its
`ARCHAPPL_ROOT_LOGGER_LEVEL` (`configure/CONFIG_SRC:71`) reaches nothing under
log4j2. This row switches to the WAR configuration once G14 lands, so
application lines enter the journal with a priority through the
`--level-prefix` path M33 already runs.

##### Scope

- `site-template/log4j2.xml`, its `log4j2.install` rule and the `log4j2`
  entry in `conf_RULES_NAMES` (`configure/RULES_INSTALL`), and
  `ARCHAPPL_LOG4J_XML` (`configure/CONFIG_SITE`): removed; there is no
  rendering rule for this file. `LOG4J_CONFIGURATION_FILE` stays in
  `archappl.conf.in` as a site override, unset by default.
- `site-template/archappl.conf.in` and `configure/CONFIG_SRC`: export
  `ARCHAPPL_ROOT_LOGGER_LEVEL` to the JVMs and change its default from the
  current `WARN` (`configure/CONFIG_SRC:71`) to `INFO` per D24.
- `docs/README.install.md`: the override hook and the level variable.

Out of scope: the layout itself (aa-maven, G14); the runtime level control
under discussion with aa-maven.

##### Completion Criteria

- With no site override, the running JVMs load the WAR's `log4j2.xml`, and
  per component identifier `journalctl -u <unit> -p err..err` returns the
  application ERROR lines and `-p info..info` the INFO lines, so each level
  maps to its own journal priority.
- Setting `ARCHAPPL_ROOT_LOGGER_LEVEL=WARN` in `../CONFIG_SITE.local` and
  reinstalling silences INFO lines.
- `LOG4J_CONFIGURATION_FILE` set to a site file takes precedence.

##### Dependencies And Decisions

- M33 (the launcher and `systemd-cat` path), G14 (the layout), D24. Blocked
  from creation on G14; G14 Complete 2026-09-24 at `a1155ef0`, restored to Not started; not Ready until M33 is Complete.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Remove the site `log4j2.xml`, its install rule and its variable; keep the
   `LOG4J_CONFIGURATION_FILE` line in `archappl.conf.in` commented as the
   override hook.
2. Export `ARCHAPPL_ROOT_LOGGER_LEVEL` from `archappl.conf.in` and set the
   `CONFIG_SRC` default to `INFO`.
3. Extend `tests/phase1-logic.bash` and the install guide; run T1, then T2 on
   a disposable VM with a WAR built at or after the G14 commit.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `tests/run-all-tests.bash --phase=1` with the new guards | This host | No site `log4j2.xml` installed; `archappl.conf` exports the level |
| T2 | Runtime | Install with a WAR at or after the G14 commit; `journalctl -p err..err` and `-p info..info` per identifier; WARN override; site override | Disposable VM | Each level lands at its own priority; the override silences INFO; the site file wins when set |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Pending | none |
| T2 | Not run | Disposable VM | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Take the log4j2 configuration from the WAR with journal priorities
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M35 - Route Tomcat and java.util.logging output through log4j2

Origin: 265f580 / M35
Identity History: none
GitHub Issue: none
Status: Not started

##### Summary

After M33 every Tomcat record still passes through JULI's ConsoleHandler with
no priority prefix, because no JULI formatter emits one (D25). The same path
carries the CA client's `java.util.logging` messages, which the
ansible-provision soak measured as about half of the engine's stdout lines.
Under D25 each instance runs Tomcat's internal logging and `java.util.logging`
through log4j2: `log4j-appserver` replaces `org.apache.juli.logging.Log`,
`log4j-jul` becomes the `java.util.logging` LogManager, and a
`log4j2-tomcat.xml` shipped by aa-env gives every such line the `<N>` prefix
that M33's `systemd-cat --level-prefix=true` already turns into a journal
priority. The WAR's own `log4j2.xml` (M34) is untouched.

##### Scope

- `configure/RULES_FUNC` instance install: copy the four jars from the G15
  output directory into `$CATALINA_BASE/log4j/`, and a `CONFIG_SITE` variable
  naming that directory relative to the build target.
- `site-template/setenv.sh.in`, rendered into each instance's `bin/setenv.sh`
  by the same install step as `startup.sh.in`: `CLASSPATH` extended with
  `$CATALINA_BASE/log4j/*` and `$CATALINA_BASE/log4j/`, and `LOGGING_MANAGER`
  set to `-Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager`.
- `site-template/skel/log4j/log4j2-tomcat.xml`: one Console appender to
  `SYSTEM_OUT` with the pattern
  `%level{FATAL=<2>, ERROR=<3>, WARN=<4>, INFO=<6>, DEBUG=<7>, TRACE=<7>}%-5level [%t] %c - %m%n`
  (the M18 pattern of aa-maven, without timestamp) and root level INFO.
- `site-template/skel/conf/logging.properties`: removed from the skel;
  `catalina.sh` passes `-Dnop` when the file is absent, and the `log4j-jul`
  LogManager does not read it.
- `docs/technicaldocs/README.systemd.md` and `docs/technicaldocs/README.tomcat.md`:
  the two log4j2 contexts (Tomcat level and WAR level) and which lines each one
  carries.
- `tests/phase1-logic.bash`: guards on the rendered `setenv.sh`, the jar
  install rule and the shipped `log4j2-tomcat.xml`.

Out of scope: the WAR layout and its root level (M34, G14); the jar set
itself (G15); a RollingFile fallback at the Tomcat level.

##### Completion Criteria

- On a test host after M33, `journalctl -u <unit> -t archappl-<component>
  -o json` shows Tomcat's startup lines with `PRIORITY` 6 and no two-line
  `SimpleFormatter` record.
- `java.util.logging` lines raised inside a WAR take the Tomcat-level
  configuration, since `log4j-jul` is the JVM-wide LogManager: with
  `EPICS_CA_CONN_TMO=abc` added to the engine's `conf/engine.conf` for one
  run, the CA client's "Cannot parse EPICS_CA_CONN_TMO" line (`Level.WARNING`
  in `CAJContext.java`) appears under `archappl-engine` at `PRIORITY` 4, and
  with two `softIoc` processes on the VM loading the same record name its
  "More than one PVs with name" lines (`logger.info`) appear at `PRIORITY` 6.
- `journalctl -u <unit> -p err..err` contains a Tomcat-level ERROR when one is
  provoked: a directory `webapps/broken/WEB-INF/` in one instance with a
  `web.xml` that is not well-formed XML, present at start.
- No `catalina.out`, no dated JULI file, and no `SimpleFormatter` record in
  the journal.

##### Dependencies And Decisions

- M33 (the foreground service and `systemd-cat` path), G15 (the jar set),
  D25. Blocked from creation on G15; G15 Complete 2026-09-24 at `9bbd69bf`, restored to Not started; not Ready until M33 is Complete.
- Verified on 2026-09-24: `log4j-appserver` 2.26.1 ships
  `META-INF/services/org.apache.juli.logging.Log` and its `TomcatLogger`
  looks for `log4j2-tomcat.xml`, `.json`, `.yaml`, `.yml` or `.properties` on
  the classpath; all four jars exist at 2.26.1 on Maven Central.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Add the jar directory variable and the copy step to the instance install.
2. Add `setenv.sh.in` and its rendering next to `startup.sh.in`.
3. Add `skel/log4j/log4j2-tomcat.xml`; remove `skel/conf/logging.properties`.
4. Extend the Phase 1 guards; update the two guides.
5. On a disposable VM with a `softIoc`, run T2.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `tests/run-all-tests.bash --phase=1` with the new guards | This host | Rendered `setenv.sh` carries the classpath and the LogManager; the install rule names the four jars; `log4j2-tomcat.xml` is shipped |
| T2 | Runtime | Full install with a build at or after the G15 commit; `journalctl -o json` per identifier; one run with `EPICS_CA_CONN_TMO=abc` in the engine's `conf/engine.conf`; two `softIoc` processes with the same record name; a `webapps/broken/WEB-INF/web.xml` that is not well-formed XML | Disposable VM with a `softIoc` | Startup lines at `PRIORITY` 6, the CA client's parse warning at 4 and its duplicate-PV lines at 6, the provoked error at 3; no `SimpleFormatter` record, no `catalina.out`, no dated JULI file |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Pending | none |
| T2 | Not run | Disposable VM | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Route Tomcat and java.util.logging output through log4j2
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Gate | G5 | Baseline deployment reported by the ansible/cloud session | External gate | Complete | No | D7 | mgmt probe returned 200 on three provisioned hosts, reported 2026-09-21; [detail](#g5---baseline-deployment-reported-by-the-ansiblecloud-session) |
| Documentation | M20 | Align T6 ETL timeline placement with the time cutoff | Carry-forward | Complete | No | M17, D14 | Artwork and exports landed at `9fb3b29`, T6 prose at `e513267`, T1 Pass 2026-09-21; [detail](#m20---align-t6-etl-timeline-placement-with-the-time-cutoff) |

### Backlog Details

#### G5 - Baseline deployment reported by the ansible/cloud session

Origin: 265f580 / G5
GitHub Issue: none
Status: Complete

##### Summary

The ansible/cloud session deploys the M1 baseline following the M2
sequence and reports the result. This is Backlog deployment work under D7,
moved to the Backlog on 2026-09-11 (see Assignment History); M8 Release
Verification 3 is its own pre-PR installation check.

##### Completion Criteria

- A cross-session response reports HTTP 200 from the mgmt probe on the
  deployment host, with the aa-env and aa-maven tags it used.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-21 | Pass | LAB-ansible-provision reported mgmt `/bpl/getApplianceInfo` returning 200 with identity `appliance0` and version 2025-6 on three provisioned hosts (two Rocky 8.10, one of them built from bare for the check, and one Debian 13), driven from aa-env `fb43522` with aa-maven `3c96141d`; re-observed at aa-env `e06c554` on a freshly provisioned Rocky 8.10 host, 200 on the first probe. Observed on the reporting side, not on this host. The same run is recorded under M8 Release Verification 2 and 3. |

##### Closure Evidence

- Closed 2026-09-21 on the cross-session report above, which names both tags
  the deployment used, as the completion criterion requires. Closing this row
  releases nothing: M8 carries its own pre-PR installation check.

#### M20 - Align T6 ETL timeline placement with the time cutoff

Origin: 265f580 / M20
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

The T6 timeline still shows File_B and File_C in MTS at 12:30, although the
implemented MTS hold and gather calculation makes both files eligible for LTS.
Re-checked 2026-09-21 against the restored artwork: with the figure's MTS at
30 minutes and `hold=2`, the boundary at 12:30 falls at 11:29:59, and both
files start before it, so the defect is present as described.

The same artwork also labels each ETL Flow box "Trigger when completed files
exceed hold (2)". That is the file-count reading of `hold`, which the source
does not implement, and `docs/README.policies.md` was corrected on 2026-09-21
to describe an age boundary instead. The figures now contradict the prose, so
the trigger wording is part of this correction, not a separate one.

##### Scope

- `docs/README.DataJourney.md` T6 explanation.
- `docs/figures/datajourney.svg` T6 layer and all six PNG exports.
- M17 verification evidence after the correction is applied.

Out of scope: changing ETL code or storage policy values, and running live
installation tests.

##### Completion Criteria

- T6 prose and artwork show File_B and File_C in LTS at the stated 12:30
  evaluation, consistent with the real cutoff calculation.
- All six PNG exports are regenerated from the corrected SVG and the
  documentation and link checks pass.

##### Dependencies And Decisions

- M17; correction recorded as a carry-forward on 2026-09-16.
- D14.
- The committed PNGs were not reproducible from the committed SVG. Exporting
  the untouched SVG reproduced the text, layout and colours exactly but drew
  the File_8 arrow as a diagonal where the committed PNG shows an elbow: the
  arrows are Inkscape auto-routed connectors (`inkscape:connector-type`), so
  their path depends on the rendering version. The figures published before
  this correction therefore came from an SVG state that is not the one in the
  repository. Regenerating them settles that; the connector shape changes in
  all six, which is appearance rather than information.
- Export recipe, previously undocumented: make exactly one `T` layer visible
  (BG stays visible) and run
  `inkscape --export-type=png --export-width=640 --export-filename=docs/figures/T<n>.png <svg>`.
  All six now render at 640x808; before this the set was inconsistent, T6
  alone being 640x807.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-21, owner directed the figure correction in session
Implementation Authorization: 2026-09-21
Superseded Plan Artifacts: none

1. `docs/figures/datajourney.svg`, BG layer: replaced the ETL Flow trigger text
   "when completed files / exceed hold (2)" with "when the oldest sample / is
   older than hold (2)", matching the corrected `docs/README.policies.md`. BG
   is shared, so this reaches all six figures. Done 2026-09-21.
2. Same file, T6 layer: moved File_C and File_B from the MTS column to the LTS
   column by shifting x by the column offset 61.4869, which lands them on the
   same x as File_A, and recoloured both to the LTS pink `#dc8add`. The colour
   convention was read off the layers first: bright green marks the active
   file, light blue a completed one, dark blue one in transit. Done 2026-09-21.
3. Regenerated all six PNGs with the recipe above. Done 2026-09-21.
4. `docs/README.DataJourney.md`, T6: wrote the prose half the criterion asks
   for, in the STS/MTS/LTS bullet form the other sections use, naming File_C,
   File_B and File_A in LTS and giving the 11:29:59 boundary that puts them
   there. The section's opening sentence had said both buffers were full,
   which the corrected figure contradicts, so it now says data ages past the
   MTS `hold` boundary and moves on. Done 2026-09-21.

1. Update the T6 prose and SVG layer to match the 12:30 MTS cutoff.
2. Regenerate all six PNG exports with Inkscape.
3. Re-run the documentation and figure checks, then update M17 evidence.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Documentation | Re-derive the MTS cutoff with the built `TimeUtils`, inspect T6 SVG/PNG, and run local link and register checks | aa-env working tree; source `35282494` | File_B and File_C are shown in LTS at 12:30 and all checks pass |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-21 | aa-env working tree; built classes from source `3c96141d` | Pass | The cutoff was re-derived with the built `TimeUtils`, not by hand: `TimeUtils.getPreviousPartitionLastSecond(now - hold * PARTITION_30MIN.getApproxSecondsPerChunk(), PARTITION_30MIN)` with `hold=2` and an evaluation time of 12:30 returned a hold boundary of 11:29:59, making File_B (first sample 10:30) and File_C (11:00) both eligible to leave MTS while a file starting at 11:30 stays. The regenerated T6 was inspected and shows both in the LTS column beside File_A. Local link check over the tracked Markdown: 21 links, 0 missing. Register check: row-to-detail status parity and detail anchors both clean. The plan named source `35282494`; the classes on hand are the newer `3c96141d`, and the derivation is recorded against what actually ran. |

##### Closure Evidence

- Artwork and export corrected 2026-09-21 (T1 Pass); the 2026-09-16 deferral is
  lifted. The artwork and the regenerated exports landed at `9fb3b29` on
  origin/modernize.
- The owner answered the prose question on 2026-09-21: match the text to the
  figure. The T6 prose was written the same day, states the placement and the
  boundary that produces it, and landed at `e513267`. Both halves of the
  completion criterion are met and both carry landing evidence, so this row
  closes.
