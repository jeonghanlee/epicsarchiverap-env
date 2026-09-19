# Work Register

Release line: master (`maven` branch)
Milestone index: 265f580
Canonical path: `docs/milestone-265f580.md`
Canonical branch or ref: modernize
Git upstream: origin/modernize
Remote tracker: jeonghanlee/epicsarchiverap-env, GitHub milestone none yet
Peer register: aa-maven (jeonghanlee/epicsarchiverap-maven) `docs/milestone-daff1b7.md` on branch modernize, observed at `3528249462d54b295e9a9277882f7f3c0fc1cc62` on 2026-09-15 through the GitHub contents API

Next session entry point: two rows are Ready now — M9 (selectable MariaDB/SQLite
backend, G9 Complete) and M21 (remove the retired Sphinx docs build, G11
Complete). M17 landed at `a159b79` on origin/modernize (2026-09-19); its T6
follow-up is carried as M20. M8 still waits for the remaining aa-maven gates and
install verification.

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
| Release | M8 | Modernized baseline release to maven | Milestone | Blocked | No | M1, M4, M6, M9, M11, M14, M15, M16, M17, G10 | Install-verified against aa-maven Phase 1, then PR to maven; M3 completes with this merge; [detail](#m8---modernized-baseline-release-to-maven) |
| Build seam | M14 | Remove Ant leftovers from aa-env | Milestone | Blocked | No | G6, D9 | No `ANT_*` in `configure/`, no `site-template/siteid/build.xml`, no `ant` package; build still passes; [detail](#m14---remove-ant-leftovers-from-aa-env) |
| Tests | M15 | Reduce phase 2 to a build-wrapper check | Milestone | Blocked | No | G7, D9 | Phase 2 no longer compiles; aa-maven CI owns compile verification; [detail](#m15---reduce-phase-2-to-a-build-wrapper-check) |
| Verification | M17 | Correct build verification and align documentation with code | Milestone | Complete | No | D14 | Implemented and locally verified 2026-09-15; landed at `a159b79` on origin/modernize 2026-09-19; T6 follow-up carried as M20; [detail](#m17---correct-build-verification-and-align-documentation-with-code) |
| Cleanup | M21 | Remove the retired Sphinx docs build from aa-env | Milestone | Not started | Yes | G11 | No Sphinx/Python/docs-build assumption remains and phase 2 asserts the mgmt WAR `ui/api` reference; [detail](#m21---remove-the-retired-sphinx-docs-build-from-aa-env) |
| Gate | G1 | aa-maven baseline tag reported by the aa-maven session | External gate | Complete | No | | Tag `NewHope` -> `abf6545` verified on the aa-maven origin 2026-09-11; [detail](#g1---aa-maven-baseline-tag-reported-by-the-aa-maven-session) |
| Gate | G2 | Legacy GitHub milestones and issues closed | External gate | Complete | No | | Milestones M0–M5 and issues #35–#42 closed, verified 2026-09-13; [detail](#g2---legacy-github-milestones-and-issues-closed) |
| Gate | G3 | aa-maven lands canonical pom | External gate | Complete | No | | Canonical pom at `9be652c`, verified on origin 2026-09-12; [detail](#g3---aa-maven-lands-canonical-pom) |
| Gate | G4 | aa-maven lands jakarta servlet migration | External gate | Complete | No | | Retired 2026-09-12: Tomcat 9 fixed, no jakarta migration (aa-maven D13); [detail](#g4---aa-maven-lands-jakarta-servlet-migration) |
| Gate | G6 | aa-maven lands Ant removal with the per-site build contract | External gate | Open | No | | aa-maven M10 complete, commit and post-Ant sitespecific contract reported; [detail](#g6---aa-maven-lands-ant-removal-with-the-per-site-build-contract) |
| Gate | G7 | aa-maven CI builds on Maven | External gate | Open | No | | aa-maven rebuilds CI on Maven and reports a passing run; [detail](#g7---aa-maven-ci-builds-on-maven) |
| Gate | G8 | aa-maven Maven Wrapper build verified | External gate | Complete | No | | Fresh-clone `./mvnw` build passed at `c1dd0b1`, reported 2026-09-12; [detail](#g8---aa-maven-maven-wrapper-build-verified) |
| Gate | G9 | aa-maven ships both DB drivers with dialect auto-detection | External gate | Complete | No | | Both `mariadb-java-client` and `sqlite-jdbc` ship; the source auto-detects the dialect from DataSource metadata (aa-maven `ab324afb`); [detail](#g9---aa-maven-ships-both-db-drivers-with-dialect-auto-detection) |
| Gate | G10 | aa-maven Phase 1 complete (servlet-api 9.0.121, Ant removed, CI on Maven) | External gate | Open | No | | aa-maven reports Phase 1 done with the commit; the source modernize branch is release-ready; [detail](#g10---aa-maven-phase-1-complete-servlet-api-90121-ant-removed-ci-on-maven) |
| Gate | G11 | aa-maven retires the Sphinx docs pipeline (mdBook on Pages) | External gate | Complete | No | | Sphinx/RTD removed on aa-maven modernize `263805a1`; mdBook live on GitHub Pages; [detail](#g11---aa-maven-retires-the-sphinx-docs-pipeline-mdbook-on-pages) |
| Gate | G12 | aa-maven adds JNA for MariaDB Unix-socket support | External gate | Open | No | | aa-maven ships `net.java.dev.jna:jna` (+ jna-platform) so `mariadb-java-client` `localSocket` works; needed for M9 step 2 (UDS); [detail](#g12---aa-maven-adds-jna-for-mariadb-unix-socket-support) |
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

### Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| M2, G5 (`docs/milestone-265f580.md`) | Milestone section, branch modernize | Backlog section, branch modernize | `621312f` | `621312f` |
| M9, M11 (`docs/milestone-265f580.md`) | Backlog section, branch modernize | Milestone section, branch modernize (retitled per D10/D11) | this synchronization commit | this synchronization commit |
| M12 (`docs/milestone-265f580.md`) | Backlog section, branch modernize | Milestone section, branch modernize (retired per D11) | this synchronization commit | this synchronization commit |

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
Status: Blocked (resume as Not started)

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

- M1, M4, M6, M9, M11, M14, M15, M16, M17
- G10 (aa-maven Phase 1 complete); resume as Not started
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
| Release Verification 2 | Not run | This host | Pending | none |
| Release Verification 3 | Not run | This host | Pending | none |
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
Status: Blocked (resume as Not started)

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

- G6 (aa-maven M10 and the post-Ant sitespecific contract); resume as Not
  started
- D9

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
Status: Blocked (resume as Not started)

##### Summary

`tests/phase2-compile.bash` runs the full Maven build with Sphinx as an
aa-env test. Under D9 compile verification belongs to aa-maven CI (its M5);
aa-env keeps the install tests and reduces phase 2 to checking that the
`make build` wrapper still drives the aa-maven build.

##### Scope

- `tests/phase2-compile.bash`: replace the full `make build.mvn` run with a
  wrapper check (the target resolves and invokes `mvn ... package` in
  `epicsarchiverap-maven-src`, captured with `make -n`).
- `tests/README.md`: phase 2 description and the phase table.
- `tests/run-all-tests.bash`: `--local` semantics unchanged.

Out of scope: phases 1, 3, 4; the aa-maven CI workflow. M17 independently fixes
the current compile test's failure handling and artifact discovery while G7
remains open.

##### Completion Criteria

- Phase 2 completes in seconds without a network fetch and passes on this
  host.
- `tests/README.md` states that compile verification runs in aa-maven CI.

##### Dependencies And Decisions

- G7 (aa-maven M5, CI on Maven); resume as Not started
- D9

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. After G7 reports a passing aa-maven workflow run, rewrite phase 2 as the
   wrapper check.
2. Update `tests/README.md`; run `tests/run-all-tests.bash --local`.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `tests/run-all-tests.bash --local` | This host | Phase 1 and the reduced phase 2 pass; no Maven download |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Pending | none |

##### Closure Evidence

- none

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
GitHub Issue: none
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
  classpath, which the aa-maven WARs do not ship; this step is gated on G12
  (aa-maven adds JNA), verified absent at aa-maven `3c96141d`.
- Package list: MariaDB packages for the MariaDB backend, `sqlite3` for SQLite.
- Documentation.

Out of scope: the driver dependencies and dialect detection in the source
(aa-maven, gate G9); replacing the existing launcher or service design.

##### Completion Criteria

- One PV archives and retrieves under each backend in the D16 order —
  MariaDB/TCP, then MariaDB/UDS, then SQLite3 — with the selector (and, for UDS,
  the G12 JNA dependency) the only change between them.

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
- The ansible and cloud provisioning sessions provide TCP MariaDB
  (`skip_networking=false`, `127.0.0.1:3306`) and create the database and
  account, so aa-env runs only `make sql.fill`. First TCP test agreed 2026-09-19;
  the TCP loopback login re-verified green on Rocky 8 and Debian 13 (reported
  2026-09-19): `skip_name_resolve=1`, TCP to `127.0.0.1` authenticates as
  `archappl@127.0.0.1`, listener `127.0.0.1:3306` only, no `::1`. This is the
  DB-login check only; the full bring-up is not yet done — G5's mgmt-probe
  deployment report and M9's own PV archive-and-retrieve are separate checks, and
  G5 stays Open.
- The MariaDB/UDS step is gated on G12 (aa-maven adds JNA); route the request to
  aa-maven when the step is reached.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. MariaDB/TCP: add the `DB_BACKEND` selector, render `context.xml` for
   MariaDB/TCP, run `make sql.fill`, start the units, and verify one PV.
2. MariaDB/UDS: once aa-maven ships JNA, render the `localSocket` URL form and
   verify over the socket.
3. SQLite3: render the SQLite DataSource and initialization and verify with no
   DB service present.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Function | Select MariaDB/TCP; run `make sql.fill`; start the units; archive one PV; retrieve | This host or a provisioned host (Rocky 8 / Debian 13) | Non-empty samples |
| T2 | Function | Select MariaDB/UDS (after G12, the aa-maven JNA dependency, lands); start the units; archive one PV; retrieve | provisioned host (Rocky 8 / Debian 13) | Non-empty samples over the socket |
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

Title: Selectable persistence backend: MariaDB and SQLite
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

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

#### M21 - Remove the retired Sphinx docs build from aa-env

Origin: 265f580 / M21
Identity History: none
GitHub Issue: none
Status: Not started

##### Summary

aa-maven retired the Sphinx / Read the Docs pipeline and its package build no
longer produces `docs/docs/build` (gate G11). aa-env still carries the matching
assumptions; remove them so the build and its tests match the current source.

##### Scope

- `configure/RULES_SRC`: drop the now-inert `-Dsphinx.skip=true` from
  `build.mvn2`, `build.mvn3`, and `build.war`.
- `tests/phase2-compile.bash`: replace the `docs/docs/build/index.html`
  assertion with the mgmt WAR `ui/api/index.html` reference.
- `README.md` and `tests/README.md`: remove the Sphinx build-step description.
- `configure/os/debian13.pkgs`: drop `python3`, `python3-pip`,
  `python-is-python3`, and `python3-venv` (the WAR build needs no system Python;
  the narrative docs are on Pages).

Out of scope: the mdBook build (aa-maven); the phase 2 reduction to a wrapper
check (M15); narrative-docs hosting.

##### Completion Criteria

- No `sphinx`, `docs/docs/build`, or Python-for-docs assumption remains in
  `configure/`, `scripts/`, `tests/`, or `README.md`.
- Phase 2 asserts the in-WAR mgmt `ui/api/index.html` and passes against the
  current aa-maven source.

##### Dependencies And Decisions

- G11 Complete 2026-09-18 (aa-maven Sphinx retired, mdBook on Pages)
- The `tests/phase2-compile.bash`, `README.md`, and `tests/README.md` edits
  overlap the uncommitted M17 working tree; sequence them with M17.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Remove the inert `-Dsphinx.skip=true` and the Python docs packages.
2. Repoint the phase 2 docs assertion to the mgmt WAR `ui/api/index.html`.
3. Remove the Sphinx step from the READMEs; run phase 1 and 2.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `tests/run-all-tests.bash --phase=1` | This host | Pass |
| T2 | Compile | `tests/run-all-tests.bash --phase=2` against the current aa-maven source | This host | Pass; asserts `ui/api/index.html`, no `docs/docs/build` |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Pending | none |
| T2 | Not run | This host | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Remove the retired Sphinx docs build from aa-env
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
`src/sitespecific/<site>`. Affects M14.

aa-maven register row: `docs/milestone-daff1b7.md` M10 (Ant removal,
Deferred to the end of aa-maven Phase 1, their D7).

##### Completion Criteria

- A cross-session response names the aa-maven commit and states how (or
  whether) the per-site `build.xml` step is executed after Ant removal.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | none |

##### Closure Evidence

- none

#### G7 - aa-maven CI builds on Maven

Origin: 265f580 / G7
GitHub Issue: none
Status: Open

##### Summary

aa-maven rebuilds CI on Maven and reports a passing workflow run. It removed
the Gradle workflows (aa-maven M1); the readthedocs build already runs
`./mvnw javadoc:javadoc`. Affects M15.

aa-maven register row: `docs/milestone-daff1b7.md` M5 (Maven-centric CI and docs
build), observed Not started at `35282494` on 2026-09-15.

##### Completion Criteria

- A cross-session response names the aa-maven commit and a passing
  workflow run.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | none |

##### Closure Evidence

- none

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

#### G10 - aa-maven Phase 1 complete (servlet-api 9.0.121, Ant removed, CI on Maven)

Origin: 265f580 / G10
GitHub Issue: none
Status: Open

##### Summary

aa-maven finishes its Phase 1 and reports the commit: the dependency refresh
(tomcat-servlet-api 9.0.121 and the other current-stable pins), Ant removal
with the per-site build contract, and CI rebuilt on Maven. Only then is the
source `modernize` branch release-ready for the aa-env install verification
that gates M8. This gate subsumes the earlier per-item gates G6 (Ant) and G7
(CI) for release purposes; those stay as their own rows until each is
reported.

aa-maven register rows: `docs/milestone-daff1b7.md` M4 (dependency refresh
including servlet-api 9.0.121), M5 (CI on Maven), M10 (Ant removal).

##### Completion Criteria

- A cross-session response names the aa-maven commit and confirms Phase 1 is
  complete (servlet-api 9.0.121 in the pom, no Ant, CI green on Maven).

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | none |

##### Closure Evidence

- none

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

#### G12 - aa-maven adds JNA for MariaDB Unix-socket support

Origin: 265f580 / G12
GitHub Issue: none
Status: Open

##### Summary

MariaDB Connector/J connects over a Unix domain socket only when JNA
(`net.java.dev.jna:jna`, `jna-platform`) is on the classpath. The aa-maven WARs
ship no JNA, so aa-env cannot render a working `localSocket` DataSource until
aa-maven adds the dependency. Affects M9 step 2 (MariaDB/UDS).

aa-maven register row: to be assigned by the aa-maven session when the request
is routed (dependency management is aa-maven's domain, D9).

##### Completion Criteria

- A cross-session response names the aa-maven commit that adds JNA and confirms
  `mariadb-java-client` `localSocket` connects over the socket.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | none |

##### Closure Evidence

- none. JNA verified absent at aa-maven `3c96141d`: no `jna`/`jnr` in the pom or source tree, and the runtime-dependency allowlist names only `mariadb-java-client` and `sqlite-jdbc`.

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Deploy | M2 | Non-interactive install sequence for the ansible role | Milestone | Open | No | M1, D7 | Assign when the EPICS-env provisioning work that carries the archiver is scheduled; [detail](#m2---non-interactive-install-sequence-for-the-ansible-role) |
| Gate | G5 | Baseline deployment reported by the ansible/cloud session | External gate | Open | No | D7 | Follows M2 when assigned; [detail](#g5---baseline-deployment-reported-by-the-ansiblecloud-session) |
| Tests | M10 | Phase 3 and 4 install tests (container, VM) | Milestone | Open | No | | Assign when a CI or VM host is available; [detail](#m10---phase-3-and-4-install-tests-container-vm) |
| UI | M13 | Site skin aligned with the rewritten mgmt UI | Milestone | Open | No | | Assign if the EPICS-Arche UI change requires an aa-env skin update; [detail](#m13---site-skin-aligned-with-the-rewritten-mgmt-ui) |
| Runtime | M18 | Investigate retrieval metadata HTTP 404 | Carry-forward | Open | No | | Assign a reproduction environment and scope for issue #24; [detail](#m18---investigate-retrieval-metadata-http-404) |
| Storage | M19 | Investigate ETL for PV names containing underscores | Carry-forward | Open | No | | Assign a reproduction environment and scope for issue #25; [detail](#m19---investigate-etl-for-pv-names-containing-underscores) |
| Documentation | M20 | Align T6 ETL timeline placement with the time cutoff | Carry-forward | Open | No | M17, D14 | Update the T6 prose and source SVG so files whose first samples pass the 12:30 MTS cutoff are shown in LTS, regenerate T1-T6 PNGs, and rerun documentation verification; [detail](#m20---align-t6-etl-timeline-placement-with-the-time-cutoff) |

### Backlog Details

#### M2 - Non-interactive install sequence for the ansible role

Origin: 265f580 / M2
Identity History: none
GitHub Issue: none
Status: Open (2026-09-11, D7)

##### Summary

Turn the README procedure into a linear, non-interactive sequence with every
input named, so the ansible/cloud session can write a role from it without
reading this repository's Makefiles.

##### Scope

- One document under `docs/` listing, in order: packages (distro-JDK toolchain,
  no java-env, per D10), the DB step for the selected backend (per M9/D16 — where
  the provisioning operator creates the database and account, aa-env runs only
  `make sql.fill`), Tomcat get/install, `make init build install`, systemd
  enable/start, and the health probe.
- For each step: the command, the variables it consumes, the files it writes,
  and the check that proves it ran.
- The `RELEASE.local` pin from M1.
- Handoff message to the ansible/cloud session.

Out of scope: writing the role; changing any Makefile behavior; MariaDB
account/database creation and hardening (the provisioning operator owns these in
the ansible/cloud path, per M9).

##### Completion Criteria

- The document is committed on `modernize`.
- The handoff message has been sent with the document path and both tags.
- The deployment result is recorded in Backlog gate G5; it does not gate M8
  under D7.

##### Dependencies And Decisions

- M1 (tags and pin recipe)
- G1 (aa-maven tag name)
- D7 (moved to Backlog 2026-09-11)
- 2026-09-11: G5 moved from this row to M8; the deployment cannot precede the
  document it follows.
- 2026-09-19 coordination with LAB-ansible-provision and LAB-cloud-provision
  (see D16 and M9): the archiver-dev increment starts on TCP MariaDB
  (`skip_networking=false`, `127.0.0.1:3306`). The provisioning operator creates
  the database and account, so the aa-env sequence skips db.secure/db.addAdmin/
  db.create and runs only `make sql.fill`; `DB_USER_PASS` is aa-env's value in
  `CONFIG_SITE.local` and the account is created to match it. The account grant
  host-spec must match MariaDB `skip-name-resolve` (`@'localhost'` vs
  `@'127.0.0.1'`); IPv4 loopback, no `::1`. The sequence document reflects the
  distro-JDK toolchain (D10, no java-env) and the selectable backend (M9), not
  the original java-env/MariaDB-only steps.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Walk the README procedure on this host and record each step's inputs and
   observable outputs.
2. Write the sequence document.
3. Send the handoff request to the ansible/cloud session.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Review | The ansible/cloud session confirms by message that every step in the document names its command, inputs, outputs, and check | Peer session | Confirmation received, or a list of gaps to close |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Peer session | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Document the non-interactive install sequence for the ansible role
Labels: documentation
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### G5 - Baseline deployment reported by the ansible/cloud session

Origin: 265f580 / G5
GitHub Issue: none
Status: Open (Backlog since 2026-09-11, D7)

##### Summary

The ansible/cloud session deploys the M1 baseline following the M2
sequence and reports the result. This is Backlog deployment work under D7;
M8 Release Verification 3 is its own pre-PR installation check.

##### Completion Criteria

- A cross-session response reports HTTP 200 from the mgmt probe on the
  deployment host, with the aa-env and aa-maven tags it used.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | none |

##### Closure Evidence

- none

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

- none

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Not planned until assigned.

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

- After assignment defines the EPICS-Arche interface and aa-env's role, the
  resulting skin renders correctly on that interface. The current WAR skin
  remains unchanged until that scope is defined.

##### Dependencies And Decisions

- EPICS-Arche repository (mgmt UI rewrite), post-Phase-2

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Not planned until assigned.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | UI | Define the actual interface and browser procedure when assigned | Agreed target interface | Page renders with the site skin; no console errors |

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

- D14; recorded 2026-09-15 as unresolved work. Assignment waits for a defined
  reproduction environment and investigation priority.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the reproduction environment and request sequence when assigned.
2. Reproduce the issue and select the owning repository from observed behavior.
3. Plan the fix and regression check before changing runtime code.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime | Reproduce the issue's quick-chart/live request through retrieval and the engine metadata endpoint | To be agreed on assignment | Observed HTTP result with the corresponding PV state and source revision |

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

- D14; recorded 2026-09-15 as unresolved work. Assignment waits for a defined
  reproduction environment and investigation priority.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define source revision, PV fixture, storage configuration, and ETL schedule
   when assigned.
2. Reproduce the issue through the real archiving and retrieval path.
3. Plan the fix in its owning repository and address compatibility before
   changing how existing PV names map to stored paths.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime | Archive the reported underscore cases and a control PV; run ETL and retrieve their samples | To be agreed on assignment | Observed tier paths and retrieval results tied to the source and configuration |

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

#### M20 - Align T6 ETL timeline placement with the time cutoff

Origin: 265f580 / M20
Identity History: none
GitHub Issue: none
Status: Open

##### Summary

The T6 timeline still shows File_B and File_C in MTS at 12:30, although the
implemented MTS hold and gather calculation makes both files eligible for LTS.

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

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

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
| T1 | Not run | aa-env working tree | Pending | none |

##### Closure Evidence

- none; owner deferred the correction during the 2026-09-16 session wrap-up.
