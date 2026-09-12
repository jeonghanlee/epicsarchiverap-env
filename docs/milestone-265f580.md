# Work Register

Release line: master (`maven` branch)
Milestone index: 265f580
Canonical path: `docs/milestone-265f580.md`
Canonical branch or ref: modernize
Git upstream: origin/maven
Remote tracker: jeonghanlee/epicsarchiverap-env, GitHub milestone none yet
Peer register: aa-maven (jeonghanlee/epicsarchiverap-maven) `docs/milestone-abf6545.md` on branch modernize, commit `4f8a261` (2026-09-11)

Next session entry point: `docs/milestone-265f580.md` M4 — obtain the owner's
decision on Maven in `scripts/required_pkgs.sh` (add the package, or document
the java-env dependency), apply it, then close M4.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Deploy | M1 | aa-env baseline tag and reproducible source pin | Milestone | Complete | No | D3 | Both `NewHope` tags verified and pin recipe reproduced 2026-09-11; [detail](#m1---aa-env-baseline-tag-and-reproducible-source-pin) |
| Register | M3 | Land register on maven and retire legacy roadmap | Milestone | Blocked | No | G2 | Register merged to `maven`; `docs/MILESTONES.md` gone; legacy issues closed; [detail](#m3---land-register-on-maven-and-retire-legacy-roadmap) |
| aa-env | M4 | Residual configure and script defects | Milestone | In progress | No | | Three defects fixed with phase 1 guards and the branch check retargeted; one item awaits an owner decision; [detail](#m4---residual-configure-and-script-defects) |
| Tomcat | M5 | Tomcat 9.0.121 interim bump | Milestone | In progress | No | D5, D8 | Config bumped; live install check deferred (D8); [detail](#m5---tomcat-90121-interim-bump) |
| Build | M6 | Single-source pom: remove aa-env pom overwrite | Milestone | Blocked | No | G3 | Build succeeds with no `pom.xml` in aa-env; [detail](#m6---single-source-pom-remove-aa-env-pom-overwrite) |
| Tomcat | M7 | Tomcat 11 migration (aa-env side) | Milestone | Blocked | No | M5, G4, D5 | Four WARs start on Tomcat 11 and one PV archives; [detail](#m7---tomcat-11-migration-aa-env-side) |
| Release | M8 | Modernized baseline release to maven | Milestone | Blocked | No | M1, M3, M4, M5, M6, M7, M14, M15 | Release Verification complete; [detail](#m8---modernized-baseline-release-to-maven) |
| Build seam | M14 | Remove Ant leftovers from aa-env | Milestone | Blocked | No | G6, D9 | No `ANT_*` in `configure/`, no `site-template/siteid/build.xml`, no `ant` package; build still passes; [detail](#m14---remove-ant-leftovers-from-aa-env) |
| Tests | M15 | Reduce phase 2 to a build-wrapper check | Milestone | Blocked | No | G7, D9 | Phase 2 no longer compiles; aa-maven CI owns compile verification; [detail](#m15---reduce-phase-2-to-a-build-wrapper-check) |
| Gate | G1 | aa-maven baseline tag reported by the aa-maven session | External gate | Complete | No | | Tag `NewHope` -> `abf6545` verified on the aa-maven origin 2026-09-11; [detail](#g1---aa-maven-baseline-tag-reported-by-the-aa-maven-session) |
| Gate | G2 | Legacy GitHub milestones and issues closed by owner | External gate | Open | No | | Milestones M0–M5 and issues #35–#42 closed; [detail](#g2---legacy-github-milestones-and-issues-closed-by-owner) |
| Gate | G3 | aa-maven lands canonical pom | External gate | Open | No | | aa-maven commit hash received; [detail](#g3---aa-maven-lands-canonical-pom) |
| Gate | G4 | aa-maven lands jakarta servlet migration | External gate | Open | No | | aa-maven commit hash received; [detail](#g4---aa-maven-lands-jakarta-servlet-migration) |
| Gate | G6 | aa-maven lands Ant removal with the per-site build contract | External gate | Open | No | | aa-maven M4 complete, commit and post-Ant sitespecific contract reported; [detail](#g6---aa-maven-lands-ant-removal-with-the-per-site-build-contract) |
| Gate | G7 | aa-maven CI builds on Maven | External gate | Open | No | | aa-maven M5 complete, workflow run reported; [detail](#g7---aa-maven-ci-builds-on-maven) |

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
| D9 | Boundary between the two repositories: aa-env owns provisioning, deployment layout, service configuration, source baseline pinning, and the site skin; aa-maven owns source, the Maven build (Ant and Gradle leftovers consolidated onto Maven), dependency management, upstream cherry-pick policy, and independent bug fixes. Build-flavored leftovers inside aa-env are aa-env cleanup rows gated on aa-maven rows; compile verification moves to aa-maven CI and aa-env keeps install tests. No aa-env row migrates; the legacy build items already exist on the aa-maven register. | 2026-09-11 |

### Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| M2, G5 (`docs/milestone-265f580.md`) | Milestone section, branch modernize | Backlog section, branch modernize | this synchronization commit | this synchronization commit |

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
Status: In progress

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
  java-env for it. Document or install. Owner decision pending (2026-09-11).
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
- One item above (Maven in `required_pkgs.sh`) awaits an owner decision
  before this row can close.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-11, owner accepted the assertion-first plan in session
Implementation Authorization: 2026-09-11, for the checkfile, serverxml, jdbc, and branch-default items; the Maven item awaits its decision
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

- none

##### GitHub Projection

Title: Fix residual configure and script defects with phase 1 guards
Labels: bug
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M5 - Tomcat 9.0.121 interim bump

Origin: 265f580 / M5
Identity History: none
GitHub Issue: none
Status: In progress

##### Summary

Move the aa-env Tomcat from 9.0.113 to 9.0.121, the latest 9.0.x at the time
of D5, as the safe step before the Tomcat 11 migration.

##### Scope

- `configure/CONFIG_TOMCAT`: `TOMCAT_MINOR_VER` 0.113 to 0.121.
- `docs/technicaldocs/README.tomcat.md`: example output shows 9.0.87;
  refresh.
- Inform the aa-maven session so `tomcat-servlet-api` in the pom moves in
  lockstep (informational; not a gate).

Out of scope: Tomcat 10 or 11; the aa-maven pom.

##### Completion Criteria

- `make tomcat` on this host installs 9.0.121 and the four services start
  against it.

##### Dependencies And Decisions

- D5
- D8: the live-install checks (T1, T2) are deferred to M10 or deployment.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-11, owner accepted the 9.0.121 bump in session
Implementation Authorization: 2026-09-11, config bump only; live install not run on this host per D8
Superseded Plan Artifacts: none

1. Edit `CONFIG_TOMCAT` and the tomcat README. Done 2026-09-11.
2. `make tomcat.get tomcat.install`; then `make install sd_start`. Deferred (D8).

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Install | `unzip -p /opt/tomcat9/lib/catalina.jar org/apache/catalina/util/ServerInfo.properties` | This host | `server.number=9.0.121.0` |
| T2 | Runtime | `make sd_start` then `curl http://localhost:17665/mgmt/bpl/getApplianceInfo` | This host | HTTP 200 |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Deferred (D8) | This host | Pending | Requires `make tomcat.install`, which replaces `/opt/tomcat9`; not run |
| T2 | Deferred (D8) | This host | Pending | Requires restarting the running appliance; not run |

##### Closure Evidence

- none

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
Status: Blocked (resume as Not started)

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

- G3; resume as Not started
- D2

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. After G3 reports the aa-maven commit, set `SRC_TAG` for the build to that
   commit or later.
2. Remove the `pom` target and aa-env `pom.xml`.
3. Run phase 2.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Compile | `tests/run-all-tests.bash --phase=2` | This host | Four WARs produced; no `pom.xml` in aa-env |
| T2 | Repository | `git -C epicsarchiverap-maven-src status --porcelain` after build | This host | Empty |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Pending | none |
| T2 | Not run | This host | Pending | none |

##### Closure Evidence

- none

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
Status: Blocked (resume as Not started)

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

- M5
- G4; resume as Not started
- D5

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Diff Tomcat 11 `conf/` and `bin/` against the skel; update templates.
2. Update CONFIG_TOMCAT and rules; `make tomcat install sd_start`.
3. Archive one PV from a local IOC; retrieve it.

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

- none

##### GitHub Projection

Title: Migrate the aa-env runtime to Tomcat 11
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

- M1, M3, M4, M5, M6, M7, M14, M15
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
| M7 / T1 | Final tree | Runtime | Release Verification 2 | HTTP 200 on Tomcat 11 | pending |

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
| Release Verification 3 | Install | post-change | README procedure at the release tag | This host | HTTP 200, PV archived | curl output and retrieval sample |
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

#### G1 - aa-maven baseline tag reported by the aa-maven session

Origin: 265f580 / G1
GitHub Issue: none
Status: Complete

##### Summary

The aa-maven session (single writer of jeonghanlee/epicsarchiverap-maven) tags
the aa-maven state `abf6545` and reports the tag name. Affects M2.

Announced 2026-09-11: tag name `NewHope` (annotated, no `v` prefix) on
`abf6545`. Pushed the same day; see Verification Results.
aa-maven register row: `docs/milestone-abf6545.md` M1 (Complete).

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
Status: Open

##### Summary

The aa-maven session commits a pom.xml that builds without aa-env's copy and
reports the commit hash. Affects M6.
aa-maven register row: `docs/milestone-abf6545.md` M2 (Not started, Ready);
its base is aa-env's tracked `pom.xml` (aa-maven decision D8, 2026-09-11).

##### Completion Criteria

- A cross-session response names the aa-maven commit and its register row.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | none |

##### Closure Evidence

- none

#### G4 - aa-maven lands jakarta servlet migration

Origin: 265f580 / G4
GitHub Issue: none
Status: Open

##### Summary

The aa-maven session migrates `javax.servlet` to `jakarta.servlet` and the
related dependencies, and reports the commit hash. Affects M7.
aa-maven register row: `docs/milestone-abf6545.md` M6 (depends on its M3).

##### Completion Criteria

- A cross-session response names the aa-maven commit and its register row.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | none |

##### Closure Evidence

- none

#### G6 - aa-maven lands Ant removal with the per-site build contract

Origin: 265f580 / G6
GitHub Issue: none
Status: Open

##### Summary

aa-maven removes Ant from its build (its register row M4) and reports the
commit together with the post-Ant contract for the per-site build step that
`build.xml` target `sitespecificbuild` used to run inside
`src/sitespecific/<site>`. Affects M14.

aa-maven register row: `docs/milestone-abf6545.md` M4.

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

aa-maven moves its GitHub Actions and readthedocs build from Gradle to
Maven (its register row M5) and reports a passing workflow run. Affects
M15.

aa-maven register row: `docs/milestone-abf6545.md` M5.

##### Completion Criteria

- A cross-session response names the aa-maven commit and a passing
  workflow run.

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
| DB | M9 | SQLite as the configuration database | Milestone | Open | No | D6 | Assign when MariaDB removal is scheduled; [detail](#m9---sqlite-as-the-configuration-database) |
| Tests | M10 | Phase 3 and 4 install tests (container, VM) | Milestone | Open | No | | Assign when a CI or VM host is available; [detail](#m10---phase-3-and-4-install-tests-container-vm) |
| aa-env | M11 | Single JDK source on the host | Milestone | Open | No | | Assign after M7; [detail](#m11---single-jdk-source-on-the-host) |
| Tomcat | M12 | Tomcat 9.1.x fallback | Milestone | Conditional | No | | Condition: Tomcat 9.0.x end of support is announced before M7 completes; [detail](#m12---tomcat-91x-fallback) |
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

#### M9 - SQLite as the configuration database

Origin: 265f580 / M9
Identity History: none
GitHub Issue: none
Status: Open

##### Summary

Replace MariaDB with SQLite for the appliance configuration database. The
aa-maven source already selects the SQLite dialect from the JDBC driver name and
ships `archappl_sqlite.sql`; upstream documents a single-connection pool
limit.

##### Scope

- `site-template/context.xml.in`: driver `org.sqlite.JDBC`, file URL,
  pool size 1.
- `configure/CONFIG_SQL`, `configure/RULES_SQL`: SQLite initialization
  instead of MariaDB targets.
- `site-template/systemd/*.service.in`: drop `Requires=mariadb.service`.
- `scripts/required_pkgs.sh`: `sqlite3` instead of MariaDB packages.
- Documentation.

Out of scope: the `sqlite-jdbc` dependency (aa-maven register).

##### Completion Criteria

- One PV archives and retrieves with no MariaDB service on the host.

##### Dependencies And Decisions

- D6
- aa-maven `docs/milestone-abf6545.md` M8 (`sqlite-jdbc`, Backlog)

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Not planned until assigned.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Function | `systemctl stop mariadb`; `make sd_restart`; archive one PV; retrieve | This host | Non-empty samples |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Use SQLite as the configuration database
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

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

#### M11 - Single JDK source on the host

Origin: 265f580 / M11
Identity History: none
GitHub Issue: none
Status: Open

##### Summary

The host carries two JDK 21 installs: java-env's `/opt/java-env/JDK`
(21+35) and Debian's `openjdk-21` (21.0.12.1). Maven resolves the Debian
one while `CONFIG_SITE` points at java-env. Pick one and make
`required_pkgs.sh` and the configuration agree.

##### Scope

- Decide the JDK source; update `scripts/required_pkgs.sh` and the
  `configure/os/debian13.mk` preset accordingly.

Out of scope: aa-maven's `maven.compiler` settings.

##### Completion Criteria

- `make info.mvn` reports the same JDK path for Maven and for `JAVA_CMD`.

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
| T1 | Build system | `make info.mvn` | This host | One JDK path in both outputs |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Use a single JDK source on the host
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M12 - Tomcat 9.1.x fallback

Origin: 265f580 / M12
Identity History: none
GitHub Issue: none
Status: Conditional

##### Summary

If Tomcat 9.0.x reaches end of support before M7 completes, move the aa-env
runtime to the 9.1.x extended-support branch, which keeps the javax
namespace.

##### Scope

- `configure/CONFIG_TOMCAT` major/minor and URL for 9.1.x.

Out of scope: any source change.

##### Completion Criteria

- Four services start on Tomcat 9.1.x on this host.

##### Dependencies And Decisions

- Condition: Apache announces the 9.0.x end-of-support date and it precedes
  the expected M7 completion.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Not planned until the condition is observed.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime | `make tomcat install sd_start`; mgmt probe | This host | HTTP 200 |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This host | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Tomcat 9.1.x fallback for the aa-env runtime
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

aa-maven will rewrite the management web interface. The aa-env repository
carries only the site-specific skin (`site-template/siteid`: css, img,
`template_changes.html`) that the build copies into the WAR. Once the new
interface lands, the skin must be rebuilt against it or dropped.

##### Scope

- `site-template/siteid/{css,img,template_changes.html}` and the
  `copy.sitespecific` step in `configure/RULES_SRC`.

Out of scope: the interface itself (aa-maven register).

##### Completion Criteria

- `make build` with the new aa-maven UI produces a mgmt WAR whose home page
  renders the site skin without errors in the browser console.

##### Dependencies And Decisions

- aa-maven `docs/milestone-abf6545.md` M12 (mgmt UI rewrite, Backlog)

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
