# Work Register

Release line: master (`maven` branch)
Milestone index: 265f580
Canonical path: `docs/milestone-265f580.md`
Canonical branch or ref: modernize
Git upstream: origin/maven
Remote tracker: jeonghanlee/epicsarchiverap-env, GitHub milestone none yet
Peer register: aa-maven (jeonghanlee/epicsarchiverap-maven) `docs/milestone-daff1b7.md` on branch modernize, commit `c1dd0b1` (2026-09-12 reset; prior generation at `daff1b7`)

Next session entry point: `docs/milestone-265f580.md` M3 — prepare the
legacy issue and milestone close commands for the owner (gate G2), then the
pull request from `modernize` to `maven`; no other row is Ready.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Deploy | M1 | aa-env baseline tag and reproducible source pin | Milestone | Complete | No | D3 | Both `NewHope` tags verified and pin recipe reproduced 2026-09-11; [detail](#m1---aa-env-baseline-tag-and-reproducible-source-pin) |
| Register | M3 | Land register on maven and retire legacy roadmap | Milestone | Blocked | No | G2 | Register merged to `maven`; `docs/MILESTONES.md` gone; legacy issues closed; [detail](#m3---land-register-on-maven-and-retire-legacy-roadmap) |
| aa-env | M4 | Residual configure and script defects | Milestone | Complete | No | D10 | Three defects fixed with phase 1 guards (`0e02ede`); the Maven item superseded by D10; [detail](#m4---residual-configure-and-script-defects) |
| Tomcat | M5 | Tomcat 9.0.121, the fixed Phase 2 version | Milestone | Complete | No | D8, D11 | Config bumped (`aea623b`); Tomcat 9.0.121 fixed for Phase 2; [detail](#m5---tomcat-90121-the-fixed-phase-2-version) |
| Build | M6 | Single-source pom: remove aa-env pom overwrite | Milestone | Complete | No | G3 | Verified 2026-09-12: full build with no aa-env pom, clean source tree (`0e9cee6`); [detail](#m6---single-source-pom-remove-aa-env-pom-overwrite) |
| Tomcat | M7 | Tomcat 11 migration (aa-env side) | Milestone | Complete | No | D11 | Retired 2026-09-12 by D11; Tomcat 9 is fixed for Phase 2; [detail](#m7---tomcat-11-migration-aa-env-side) |
| Tomcat | M12 | Tomcat 9.1.x fallback | Milestone | Complete | No | D11 | Retired 2026-09-12 by D11; [detail](#m12---tomcat-91x-fallback) |
| DB | M9 | SQLite as the only configuration database | Milestone | Blocked | No | G9, M11, D11 | One PV archives and retrieves with no MariaDB on the host; [detail](#m9---sqlite-as-the-only-configuration-database) |
| Runtime | M16 | Run the Tomcat 9 instances under systemd template units | Milestone | Complete | No | D12 | Retired 2026-09-12 by D12; the script under the existing service stays the launcher; [detail](#m16---run-the-tomcat-9-instances-under-systemd-template-units) |
| Toolchain | M11 | Single distro toolchain: JDK, Maven Wrapper, package lists | Milestone | Complete | No | G8, D10 | Implemented and verified 2026-09-12 (`f24ec5c`); [detail](#m11---single-distro-toolchain-jdk-maven-wrapper-package-lists) |
| Release | M8 | Modernized baseline release to maven | Milestone | Not started | No | M1, M3, M4, M6, M9, M11, M14, M15, M16 | Release Verification complete; [detail](#m8---modernized-baseline-release-to-maven) |
| Build seam | M14 | Remove Ant leftovers from aa-env | Milestone | Blocked | No | G6, D9 | No `ANT_*` in `configure/`, no `site-template/siteid/build.xml`, no `ant` package; build still passes; [detail](#m14---remove-ant-leftovers-from-aa-env) |
| Tests | M15 | Reduce phase 2 to a build-wrapper check | Milestone | Blocked | No | G7, D9 | Phase 2 no longer compiles; aa-maven CI owns compile verification; [detail](#m15---reduce-phase-2-to-a-build-wrapper-check) |
| Gate | G1 | aa-maven baseline tag reported by the aa-maven session | External gate | Complete | No | | Tag `NewHope` -> `abf6545` verified on the aa-maven origin 2026-09-11; [detail](#g1---aa-maven-baseline-tag-reported-by-the-aa-maven-session) |
| Gate | G2 | Legacy GitHub milestones and issues closed by owner | External gate | Open | No | | Milestones M0–M5 and issues #35–#42 closed; [detail](#g2---legacy-github-milestones-and-issues-closed-by-owner) |
| Gate | G3 | aa-maven lands canonical pom | External gate | Complete | No | | Canonical pom at `9be652c`, verified on origin 2026-09-12; [detail](#g3---aa-maven-lands-canonical-pom) |
| Gate | G4 | aa-maven lands jakarta servlet migration | External gate | Complete | No | | Retired 2026-09-12: Tomcat 9 fixed, no jakarta migration (aa-maven D13); [detail](#g4---aa-maven-lands-jakarta-servlet-migration) |
| Gate | G6 | aa-maven lands Ant removal with the per-site build contract | External gate | Open | No | | aa-maven M4 complete, commit and post-Ant sitespecific contract reported; [detail](#g6---aa-maven-lands-ant-removal-with-the-per-site-build-contract) |
| Gate | G7 | aa-maven CI builds on Maven | External gate | Open | No | | aa-maven rebuilds CI on Maven and reports a passing run; [detail](#g7---aa-maven-ci-builds-on-maven) |
| Gate | G8 | aa-maven Maven Wrapper build verified | External gate | Complete | No | | Fresh-clone `./mvnw` build passed at `c1dd0b1`, reported 2026-09-12; [detail](#g8---aa-maven-maven-wrapper-build-verified) |
| Gate | G9 | aa-maven delivers SQLite persistence and removes MariaDB | External gate | Open | No | | aa-maven sqlite-jdbc and MariaDB-removal commits with the SQLite DataSource contract; [detail](#g9---aa-maven-delivers-sqlite-persistence-and-removes-mariadb) |

### Decisions

| ID | Decision | Decision Date |
| --- | --- | --- |
| D1 | aa-maven is maintained independently. No further upstream merges; upstream changes are cherry-picked individually. Legacy roadmap phases M3 and M4 (upstream sync) are retired. | 2026-09-11 |
| D2 | Two registers, one per repository. The aa-env session is the single writer of this document; the aa-maven session is the single writer of the aa-maven register. Cross-references use canonical path plus local ID. Every M row gets one GitHub issue in its own repository, carrying the peer issue URL in its body. | 2026-09-11 |
| D3 | The deployment baseline is aa-env `4d85e7f` (`maven` HEAD) with aa-maven `abf6545`, as-is. Modernization work does not gate the deployment. | 2026-09-11 |
| D4 | Both repositories use a `modernize` branch. The aa-env branch starts at cleanup `265f580`. | 2026-09-11 |
| D5 | Tomcat target is 11; 9.0.121 is the interim step on the 9.0.x line. | 2026-09-11 |
| D6 | SQLite as the configuration database stays in the Backlog until assigned. | 2026-09-11 |
| D7 | The ansible/cloud deployment work (install sequence document and deployment gate) moves to the Backlog and is built together with the EPICS-env provisioning, not on its own; the NewHope baseline stays frozen for it. | 2026-09-11 |
| D8 | The M5 Tomcat 9.0.121 live-install checks (T1, T2) are deferred; the version bump is committed, and the running-service verification is done at the M10 install-test phase or at deployment, not against this host now. | 2026-09-11 |
| D10 | Toolchain: the distro JDK package only (`openjdk-21-jdk-headless`, `JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64`) and the Apache Maven Wrapper committed in aa-maven (`./mvnw`, pinned 3.9.9); aa-env installs no Maven and drops java-env. Declarative per-OS package lists and one installer replace `scripts/required_pkgs.sh`. Supersedes the M4 Maven question. | 2026-09-12 |
| D11 | Runtime through Phase 2: the four WARs run on Tomcat 9 (fixed at 9.0.121), with SQLite as the only configuration store. Supersedes D5 (no Tomcat 11) and D6 (SQLite is active, not backlog); aa-env rows M7 and M12 and gate G4 are retired. The post-Phase-2 runtime (no Tomcat) is built in the EPICS-Arche repository, not here. Launcher: see D12. | 2026-09-12 |
| D12 | The launcher stays `scripts/archappl.bash` called by the existing single systemd service. The asymmetric start order (mgmt, engine, etl, retrieval) and stop order (engine, retrieval, etl, mgmt) live in the script, which `After=` ordering cannot express; the template-unit and conductor-unit designs are dropped and M16 retires. The script's restart-order defect was already fixed on cleanup (`e504e5c`). | 2026-09-12 |
| D9 | Boundary between the two repositories: aa-env owns provisioning, deployment layout, service configuration, source baseline pinning, and the site skin; aa-maven owns source, the Maven build (Ant and Gradle leftovers consolidated onto Maven), dependency management, upstream cherry-pick policy, and independent bug fixes. Build-flavored leftovers inside aa-env are aa-env cleanup rows gated on aa-maven rows; compile verification moves to aa-maven CI and aa-env keeps install tests. No aa-env row migrates; the legacy build items already exist on the aa-maven register. | 2026-09-11 |

### Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| M2, G5 (`docs/milestone-265f580.md`) | Milestone section, branch modernize | Backlog section, branch modernize | `621312f` | `621312f` |
| M9, M11 (`docs/milestone-265f580.md`) | Backlog section, branch modernize | Milestone section, branch modernize (retitled per D10/D11) | this synchronization commit | this synchronization commit |
| M12 (`docs/milestone-265f580.md`) | Backlog section, branch modernize | Milestone section, branch modernize (retired per D11) | this synchronization commit | this synchronization commit |

### Milestone Details

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
Status: Blocked (resume as Not started)

##### Summary

Validate the cleanup content carried on `modernize`, land this register on
`maven` through a pull request, and retire the legacy roadmap in the
repository and on GitHub.

##### Scope

- `tests/run-all-tests.bash --local` passes on `modernize` HEAD.
- `docs/MILESTONES.md` is removed in the same change that adds this
  document.
- Pull request from `modernize` to `maven` covering the cleanup commits and
  this register; owner reviews and merges.
- GitHub side: new issues for M1–M8 per D2, after the legacy issues and
  milestones are closed (G2).

Out of scope: any modernization content beyond the cleanup commits already
on the branch.

##### Completion Criteria

- `origin/maven` contains this document and not `docs/MILESTONES.md`.
- Issues #35–#42 and milestones M0–M5 are closed on GitHub.
- Issues for M1–M8 exist and their numbers are recorded in each detail.

##### Dependencies And Decisions

- G2; resume as Not started
- D1, D2

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Run phase 1 and phase 2 tests on `modernize`; fix anything that fails.
2. Prepare the commit that adds this document and removes
   `docs/MILESTONES.md`.
3. Prepare the `gh issue close` and milestone close commands for the owner.
4. Prepare the pull request description; owner opens and merges.
5. Prepare `gh issue create` drafts for M1–M8 and record the numbers.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic and compile | `tests/run-all-tests.bash --local` | This host | Phase 1 and phase 2 report all assertions passed |
| T2 | Repository | `git merge-base --is-ancestor <register commit> origin/maven` | aa-env checkout | Exit 0 |
| T3 | Tracker | `gh issue list --state open --json number` | GitHub | None of #35–#42 listed |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Pending | none |
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
2. Live install and start run under M16 with the systemd units.

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

Merge the completed `modernize` work into `maven`, tag it, and verify the
whole tree once on this host and once on the deployment host.

##### Scope

- Final pull request from `modernize` to `maven`.
- Release tag on the merge commit.
- `CHANGELOG.md` `[Unreleased]` becomes a dated section.

Out of scope: any new feature.

##### Completion Criteria

- Release Verification 1–4 recorded with evidence.

##### Dependencies And Decisions

- M1, M3, M4, M6, M9, M11, M14, M15, M16
- D11 retired M5's successor work (M7); M16 carries the runtime.
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
| M3 / T1 | Final tree | `tests/` | Release Verification 1 | Phase 1 and 2 pass | pending |
| M5 (deferred live checks, D8/D12) | Final tree | Runtime | Release Verification 2 | HTTP 200 from the mgmt probe | pending |

##### Production Environment Tests

| Release Verification Label | Timing | System | Version | Architecture | Deployment Path | Method | Expected Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Release Verification 3 | post-change | This host | Debian 13 | x86_64 | `make install sd_start` at the release tag | README procedure | mgmt URL 200, one PV archived | pending |

##### Version Changes

| Field | File | Before | Planned After | Pre-check | Pre-check Label | Post-check | Post-check Label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Unreleased heading | `CHANGELOG.md` | `[Unreleased]` | dated section | `grep -n Unreleased CHANGELOG.md` | Release Verification 4 | same | Release Verification 4 |

##### Release Execution

| Step | Action | Authorization | Expected Result | Evidence |
| --- | --- | --- | --- | --- |
| 1 | Merge `modernize` into `maven` via pull request | owner | merge commit on `origin/maven` | pending |
| 2 | Annotated tag on the merge commit | owner | tag on origin | pending |

##### Release Verification Plan

| Label | Layer | Timing | Method | Environment | Expected Result | Evidence Target |
| --- | --- | --- | --- | --- | --- | --- |
| Release Verification 1 | Logic and compile | pre-change | `tests/run-all-tests.bash --local` | This host | all pass | run log |
| Release Verification 2 | Runtime | pre-change | `make sd_start`; mgmt probe | This host | HTTP 200 | curl output |
| Release Verification 3 | Install | post-change | `make install sd_start` at the release tag | This host | HTTP 200, PV archived | curl output and retrieval sample |
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
in the site overlay, `ANT_HOME` / `ANT_PATH` / `ANT_OPTS` in the site
configuration, and the `ant` package in the Debian package list. Once
aa-maven removes Ant from the build (its M4) and states how the per-site
build step is replaced, aa-env removes its half.

##### Scope

- `site-template/siteid/build.xml` (33 lines): remove, or replace per the
  post-Ant sitespecific contract aa-maven reports.
- `configure/CONFIG_SITE`: `ANT_HOME`, `ANT_PATH`, `ANT_OPTS` (lines 4, 9,
  43–49) and any `.local` preset that sets them.
- `scripts/required_pkgs.sh`: the `ant` package in every OS function.
- `configure/RULES_SRC` `copy.sitespecific`: unchanged unless the contract
  changes the overlay path.

Out of scope: the aa-maven build itself; the overlay path
`src/sitespecific/<ARCHAPPL_SITEID>` and the `classpathfiles` packaging,
which aa-maven confirmed survive Ant removal.

##### Completion Criteria

- Phase 1 asserts: no `ANT_` variable in `configure/`, no
  `site-template/siteid/build.xml`, no `ant` package in
  `scripts/required_pkgs.sh`.
- `make build` against the post-Ant aa-maven source produces the four WARs
  with the site overlay applied.

##### Dependencies And Decisions

- G6 (aa-maven M4 and the post-Ant sitespecific contract); resume as Not
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

Out of scope: phases 1, 3, 4; the aa-maven CI workflow.

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

#### M9 - SQLite as the only configuration database

Origin: 265f580 / M9
Identity History: Backlog "SQLite as the configuration database" to Milestone, retitled, 2026-09-12 (D11)
GitHub Issue: none
Status: Blocked (resume as Not started)

##### Summary

Under D11 SQLite is the only configuration store; MariaDB is removed. The
aa-maven source selects the SQLite dialect from the JDBC driver name and ships
`archappl_sqlite.sql`; aa-maven adds `sqlite-jdbc` and removes the MariaDB
dependency (its M11 and M13) and sends the SQLite DataSource contract. aa-env
renders the per-instance DataSource and the initialization from that contract.

##### Scope

- `site-template/context.xml.in`: driver `org.sqlite.JDBC`, file URL, pool
  size 1, per the aa-maven contract (G9).
- `configure/CONFIG_SQL`, `configure/RULES_SQL`: SQLite initialization from
  `archappl_sqlite.sql` instead of the MariaDB targets.
- `site-template/systemd/epicsarchiverap-maven.service.in`: drop the
  `mariadb.service` dependency when MariaDB goes.
- Package list: `sqlite3`, no MariaDB packages (M11 list).
- Documentation.

Out of scope: the `sqlite-jdbc` dependency and MariaDB removal in the source
(aa-maven M11, M13); the systemd unit itself (M16).

##### Completion Criteria

- One PV archives and retrieves with no MariaDB service or package on the host.

##### Dependencies And Decisions

- G9 (aa-maven sqlite-jdbc + MariaDB removal + DataSource contract); resume as
  Not started
- M11 (ordering): the package change lands in the per-OS lists, not in
  `required_pkgs.sh`
- D11 (SQLite is the only store)

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. On the G9 contract: render `context.xml` for SQLite and wire the
   initialization from `archappl_sqlite.sql`.
2. Drop MariaDB from the package list and the unit dependency.
3. Archive and retrieve one PV with no MariaDB present.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Function | Stop and remove MariaDB; start the units; archive one PV; retrieve | This host | Non-empty samples; no MariaDB running |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Use SQLite as the only configuration database
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

#### G2 - Legacy GitHub milestones and issues closed by owner

Origin: 265f580 / G2
GitHub Issue: none
Status: Open

##### Summary

The owner closes GitHub milestones M0–M5 and issues #35–#42 on
jeonghanlee/epicsarchiverap-env; the commands are prepared under M3.
Affects M3.

##### Completion Criteria

- `gh issue list --state open` shows none of #35–#42.
- `gh api repos/:owner/:repo/milestones?state=open` shows none of M0–M5.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | none |

##### Closure Evidence

- none

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

aa-maven removes Ant from its build (its register row M4) and reports the
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

aa-maven register: CI rebuild on Maven. aa-maven removed the Gradle
workflows (their M1); the Maven CI is a planned aa-maven item, not yet a row.

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

aa-maven register row: `docs/milestone-daff1b7.md` M2 (In progress).

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

#### G9 - aa-maven delivers SQLite persistence and removes MariaDB

Origin: 265f580 / G9
GitHub Issue: none
Status: Open

##### Summary

aa-maven adds the `sqlite-jdbc` runtime dependency and removes the MariaDB
dependency (its M11 and M13), and reports the SQLite DataSource contract
aa-env renders into `context.xml`: driver class, file URL, pool size, and the
initialization SQL. Affects M9.

aa-maven register rows: `docs/milestone-daff1b7.md` M11 (sqlite-jdbc) and M13
(MariaDB removal, closes aa-maven Phase 2).

##### Completion Criteria

- A cross-session response names the aa-maven commits and the SQLite DataSource
  contract.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | none |

##### Closure Evidence

- none

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Deploy | M2 | Non-interactive install sequence for the ansible role | Milestone | Open | No | M1, D7 | Assign when the EPICS-env provisioning work that carries the archiver is scheduled; [detail](#m2---non-interactive-install-sequence-for-the-ansible-role) |
| Gate | G5 | Baseline deployment reported by the ansible/cloud session | External gate | Open | No | D7 | Follows M2 when assigned; [detail](#g5---baseline-deployment-reported-by-the-ansiblecloud-session) |
| Tests | M10 | Phase 3 and 4 install tests (container, VM) | Milestone | Open | No | | Assign when a CI or VM host is available; [detail](#m10---phase-3-and-4-install-tests-container-vm) |
| UI | M13 | Site skin aligned with the rewritten mgmt UI | Milestone | Open | No | | Assign when aa-maven lands the new mgmt interface; [detail](#m13---site-skin-aligned-with-the-rewritten-mgmt-ui) |

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

- One document under `docs/` listing, in order: packages, java-env, MariaDB
  secure/admin/create/fill, Tomcat get/install, `make init build install`,
  systemd enable/start, and the health probe.
- For each step: the command, the variables it consumes, the files it writes,
  and the check that proves it ran.
- The `RELEASE.local` pin from M1.
- Handoff message to the ansible/cloud session.

Out of scope: writing the role; changing any Makefile behavior; MariaDB
hardening beyond `make db.secure`.

##### Completion Criteria

- The document is committed on `modernize`.
- The handoff message has been sent with the document path and both tags.
- The deployment result itself is gate G5 on M8, not on this row.

##### Dependencies And Decisions

- M1 (tags and pin recipe)
- G1 (aa-maven tag name)
- D7 (moved to Backlog 2026-09-11)
- 2026-09-11: G5 moved from this row to M8; the deployment cannot precede the
  document it follows.

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
sequence and reports the result. Affects M8 (Release Verification 3).

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

- `make build` with the new aa-maven UI produces a mgmt WAR whose home page
  renders the site skin without errors in the browser console.

##### Dependencies And Decisions

- EPICS-Arche (mgmt UI rewrite; the session OFFICE-EPICS-Arche), post-Phase-2

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Not planned until assigned.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | UI | Open `http://localhost:17665/mgmt/ui/index.html` after `make build install sd_start` | This host | Page renders with the site skin; no console errors |

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
