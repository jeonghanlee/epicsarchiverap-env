# Work Register

Release line: 2.0.1
Milestone index: 2.0.1
Canonical path: `docs/milestone-2.0.1.md`
Canonical branch or ref: release-2.0.1
Git upstream: origin/release-2.0.1
Remote tracker: [GitHub milestone 2.0.1 / #7](https://github.com/jeonghanlee/epicsarchiverap-env/milestone/7), observed OPEN on 2026-09-30 at 04:34 UTC via `gh api repos/jeonghanlee/epicsarchiverap-env/milestones/7`

Next session entry point: coordinate a source correction for the reproduced live-engine retrieval upper-bound bug before rerunning M10 / #56 with a corrected published source. Preserve the exact `[from, to]` acquisition checks. The fresh `52d90166f5995acc332dbeb14945ed26ae32d408` Debian socket run passed T3-T10 and failed post-restart acquisition; real live retrieval subsequently returned a sample even when `to` was 1 ns before its exact timestamp, while independent stored-history controls honored the 1 ns boundary rule. Evidence is retained in `work/m10-vm-run-52d9016` and `work/m10-validation/retrieval-live-upper-bound-3.json`. The full matrix remains unverified; failed VMs remain preserved. M14 / #57 waits for Maven stabilization under D33; G6 remains Open and M14 Blocked.

## Scope

The 2.0.1 patch cycle covers backend isolation safeguards, removal of obsolete Ant integration after the source contract is confirmed, real installation test automation and measured heap guidance. The owner assigned these four candidates on 2026-09-29. The proposed order is M43, M14, M10, M41, then M44. G6 may be investigated while M43 is planned; its completion gates M14 and release readiness. The release sequence and remaining detailed plans await acceptance; M43 is accepted under D32.

Out of scope: adding SQLite deletion, table-query, backup or restore support; changing the shipped heap default; UI skin changes; LTS pre-processing; data migration. Existing 2.0.0 release objects remain immutable. No next release after 2.0.1 is assigned.

Baseline: epicsarchiverap-env `d68f66848e1edc174e76fe77326e941baf58f850`, published 2.0.0 tag commit `386c91d74086313efe04e0b64eb5dacfd91f8389`, epicsarchiverap-maven pin `d8a7813f40083c1bf7148e6c3b7bffd368d70ee0`. Prior release results are historical evidence and do not satisfy 2.0.1 checks. Backend isolation work is Complete; VM test implementation is In progress and real runtime acceptance remains Pending.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DB | M43 | Reject operations on an unselected database backend | Milestone | Complete | No | D31, D32 | SQLite db.* skips; unsupported and invalid selections stop before configuration writes or DB contact; [detail](#m43---reject-operations-on-an-unselected-database-backend) |
| Gate | G6 | epicsarchiverap-maven lands Ant removal with the per-site build contract | External gate | Open | No | | Exact usable source commit and overlay contract confirmed; [detail](#g6---epicsarchiverap-maven-lands-ant-removal-with-the-per-site-build-contract) |
| Build | M14 | Remove Ant leftovers from epicsarchiverap-env | Milestone | Blocked | No | G6, D31, D33 | After Maven stabilization, four real WARs retain generated site content through the Maven-only build; [detail](#m14---remove-ant-leftovers-from-epicsarchiverap-env) |
| Tests | M10 | Automate VM installation and runtime tests | Milestone | In progress | No | D31, D34 | Composed provisioning/install and independent acceptance pass for all accepted OS/backend cases; [detail](#m10---automate-vm-installation-and-runtime-tests) |
| Runtime | M41 | Measure per-component heap needs by archiving load | Carry-forward | Not started | Yes | D31 | Event-based GC observations justify the documented heap guidance; [detail](#m41---measure-per-component-heap-needs-by-archiving-load) |
| Release | M44 | Verify and publish release 2.0.1 | Milestone | Not started | No | M43, M14, M10, M41, D31 | Released objects and required post-release checks pass; [detail](#m44---verify-and-publish-release-201) |

### Decisions

D9, D17, D21 and D29 retain historical decisions from the closed 2.0.0 generation; references within those rows use that historical scope. D31 owns current release assignment and supersedes the earlier deferral of M14 for this cycle.

| ID | Decision | Decision Date |
| --- | --- | --- |
| D9 | Boundary between the two repositories: epicsarchiverap-env owns provisioning, deployment layout, service configuration, source baseline pinning, and the site skin; epicsarchiverap-maven owns source, the Maven build (Ant and Gradle leftovers consolidated onto Maven), dependency management, upstream cherry-pick policy, and independent bug fixes. Build-flavored leftovers inside epicsarchiverap-env are epicsarchiverap-env cleanup rows gated on epicsarchiverap-maven rows; compile verification moves to epicsarchiverap-maven CI and epicsarchiverap-env keeps install tests. No epicsarchiverap-env row migrates; the legacy build items already exist on the epicsarchiverap-maven register. | 2026-09-11 |
| D17 | Align epicsarchiverap-env with epicsarchiverap-maven on Ant removal: it is deferred out of Phase 1 on both sides. epicsarchiverap-maven moved its Ant-removal row (their M10) to the backlog on 2026-09-19 (their D7). epicsarchiverap-env confirmed this first-hand at epicsarchiverap-maven modernize `3c96141d`, whose commit subject is `Move M7 and M10 to the backlog and close out Phase 1`: their register `docs/milestone-daff1b7.md` (historical peer observation; current contract must be rechecked) carries M10 as `Deferred` with an assignment-history row recording the 2026-09-19 move, and the `maven-antrun-plugin` execution `sitespecificantscript` there still drives `build.xml` target `sitespecificbuild`. G10's completion criterion therefore covers the tomcat-servlet-api pin (observed 9.0.122, not the 9.0.121 the gate first named) and the Maven CI only, and G10 closes on that basis. epicsarchiverap-env M14 (Ant leftovers) becomes Deferred and leaves M8's dependency list; G6 stays Open and blocks no row; M14 returns to Not started only by a new dated decision. | 2026-09-20 |
| D21 | The archive store's filesystem and the ETL timing become epicsarchiverap-env work (M26), scoped to the test environment first rather than to production storage architecture. Two facts drive it. On the provisioned hosts the archive store resolves to the root volume, nothing in the install path mounts a dedicated one, and `ARCHAPPL_STORAGE_TOP` only names a directory, so an archiver that fills its store fills `/` and takes the whole host; no quota or threshold exists anywhere in the chain. Separately, the shipped store configuration puts MTS at `PARTITION_MONTH` with `hold=2`, so samples do not leave MTS for roughly two months and the second ETL hop cannot be observed in any realistic test run. Production storage sizing, per-tier media selection and retention for real data stay outside this row. | 2026-09-21 |
| D29 | Limit current DB changes to rejecting `sql.drop` and `sql.table.drop` for SQLite or an invalid backend before invoking any database client. Record full backend consistency as Backlog M42, deferred from current execution; SQLite deletion support and the remaining DB command behavior require a later accepted plan. | 2026-09-28 |
| D31 | Assign the four 2.0.1 candidates: M41, M10, M14 and the backend isolation safeguard split from M42 as M43. Preserve M42 expansion, M13 and M27 as Backlog. M14 resumes as Not started after G6 completes and is Blocked until then. Plans and the proposed order remain draft; assignment authorizes documentation and issue preparation only. | 2026-09-29 |
| D32 | For SQLite, all db.* targets print a skip message and return success without prerequisites or MariaDB configuration reads/writes. Invalid backend values and unsupported SQL/query/helper operations fail before side effects. | 2026-09-29 |
| D33 | Record the site-build migration plan, procedure and real-path tests in the canonical detail and #57. Wait for Maven stabilization before implementation. epicsarchiverap-env generates and copies its site inputs before Maven runs; epicsarchiverap-maven owns template application and WAR packaging. | 2026-09-29 |
| D34 | Plan a combined cloud-provision VM lifecycle, ansible-provision installation and epicsarchiverap-env final acceptance workflow. Preserve the tool ownership boundaries and use disposable systemd VMs for installation/runtime tests. Detailed plan, test matrix and implementation authority remain separate. | 2026-09-30 |

### Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| 265f580 / M10 | docs/milestone-2.0.0.md, release-2.0.1 | docs/milestone-2.0.1.md, release-2.0.1 | this synchronization commit | this synchronization commit |
| 265f580 / M14 | docs/milestone-2.0.0.md, release-2.0.1 | docs/milestone-2.0.1.md, release-2.0.1 | this synchronization commit | this synchronization commit |
| 265f580 / M41 | docs/milestone-2.0.0.md, release-2.0.1 | docs/milestone-2.0.1.md, release-2.0.1 | this synchronization commit | this synchronization commit |
| 265f580 / M13 | docs/milestone-2.0.0.md, release-2.0.1 | docs/milestone-2.0.1.md, release-2.0.1 | this synchronization commit | this synchronization commit |
| 265f580 / M27 | docs/milestone-2.0.0.md, release-2.0.1 | docs/milestone-2.0.1.md, release-2.0.1 | this synchronization commit | this synchronization commit |
| 265f580 / M42 | docs/milestone-2.0.0.md, release-2.0.1 | docs/milestone-2.0.1.md, release-2.0.1 | this synchronization commit | this synchronization commit |
| 265f580 / G6 | docs/milestone-2.0.0.md, release-2.0.1 | docs/milestone-2.0.1.md, release-2.0.1 | this synchronization commit | this synchronization commit |

### Milestone Details

#### M43 - Reject operations on an unselected database backend

Origin: 2.0.1 / M43
Identity History: none
GitHub Issue: [#55](https://github.com/jeonghanlee/epicsarchiverap-env/issues/55)
Status: Complete

##### Summary

At the cycle baseline, `configure/RULES_SQL` guards `sql.drop` and `sql.table.drop`, but `db.*` and the four application-table query targets remain MariaDB-specific and invalid selections fall into the MariaDB schema branch. Commit `3560216c5315088a05bb2e9dea263eac075c52bf` branches before prerequisites, skips SQLite db.* targets, and rejects unsupported or invalid operations. Regression execution against the actual f5037ab rules/helper fails; the committed real paths pass the checks below.

##### Scope

- Inventory the Make DB entrypoints, configuration generation and standalone helper dispatch. Validate backend values before side effects.
- Preserve existing MariaDB behavior over TCP and Unix sockets and existing SQLite schema load/list behavior. Skip every `db.*` target for SQLite with an explanatory success result and no prerequisites; reject unsupported SQL/query/helper operations before MariaDB is contacted.
- Update operator documentation and real-path regression checks.

Out of scope: implementing new SQLite table deletion, application-table queries, lifecycle, backup or restore; schema changes; data migration. Those remain M42.

##### Completion Criteria

- All inventoried generic entrypoints validate the selector before writes or DB contact.
- SQLite `db.*` targets return zero with a skip message without reading or writing MariaDB configuration or running prerequisites.
- Unsupported SQLite SQL/query/helper operations and invalid backend values return nonzero before configuration writes or database contact.
- Supported MariaDB and SQLite behavior remains verified with the shipped rules, scripts and schemas.

##### Dependencies And Decisions

- D32 sets SQLite db.* to an explanatory skip; standalone MariaDB helpers and unsupported SQL/query operations still reject.
- D31 splits the safeguard from M42; M42 remains Deferred. Existing selection and schema support is historical 2.0.0 work, not an unfinished dependency.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-29; SQLite db.* skip, invalid selections and unsupported SQL/query/helper rejection accepted
Implementation Authorization: 2026-09-29; implement and verify the accepted backend isolation plan
Superseded Plan Artifacts: none

1. Branch `configure/RULES_SQL` before prerequisites: all eight `db.*` targets skip for SQLite; MariaDB retains its current operations. Invalid values fail for every DB/SQL/query target.
2. Validate standalone `scripts/mariadb_setup.bash` dispatch before reading configuration; reject SQLite and invalid values. Keep supported SQLite schema load/list paths and reject SQLite deletion and application-table queries.
3. Update install and test documentation and `tests/database-config.py`. Run actual Make targets and helper dispatch for skip/rejection and supported MariaDB TCP/socket and SQLite paths using the source schemas and disposable databases.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Integration | Execute every unsupported/invalid operation through shipped Make targets and standalone helpers; inspect exit status and pre/post configuration and database state | Isolated checkout and disposable DBs | SQLite db.* skips with zero; unsupported/invalid operations reject before writes or MariaDB contact |
| T2 | Database | Execute supported schema load/list and MariaDB operations through real commands with shipped source schemas | SQLite; MariaDB TCP and Unix socket | Selected database has expected results; other database remains unchanged |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-30 05:09 UTC | Isolated copies; private MariaDB 11.8.6 over TCP/socket | Pass | `tests/database-config.py`: all 8 SQLite db.* skip, 20 DB/SQL/query targets reject invalid selectors, 22 helper actions reject SQLite/invalid values before reading config. Config and MariaDB general log remain unchanged; application marker persists. Actual f5037ab comparison fails 16 skip, 80 invalid-selector and 89 helper assertions. |
| T2 | 2026-09-30 05:09 UTC | Private MariaDB 11.8.6 TCP/socket; SQLite 3.46.1 as current OS user | Pass | `python3 tests/database-config.py --integration`: 2 tests pass against epicsarchiverap-maven d8a7813f40083c1bf7148e6c3b7bffd368d70ee0 original schemas selected through `AA_TEST_SOURCE_PATH`. MariaDB account/schema/query/backup/restore and SQLite repeated load/list/missing-table restoration pass; unrelated admin accounts and MariaDB configuration are preserved. |

##### Closure Evidence

- Local verification: `EXPECTED_BRANCH=release-2.0.1 bash tests/run-all-tests.bash --local` passes Logic 224, payload 20, database configuration 10 and build wrapper 13 checks. `bash -n scripts/mariadb_setup.bash`, `shellcheck scripts/mariadb_setup.bash` and `git diff --check` pass. The build wrapper checks command generation; no appliance build or VM runtime check is claimed here.
- Pinned source schema Git blobs: MariaDB `948a38d87765b0e8e6076c76c597996c7765945d`; SQLite `bfe76e0bf87ee2faad942208886828553ad015b0`. Retrieved from the source commit above and validated against their Git blob hashes before execution.
- Implementation commit: `3560216c5315088a05bb2e9dea263eac075c52bf`, carrying the rules, helper, regression tests and operator documentation.
- Landing observed 2026-09-30 at 05:48 UTC: after `git fetch origin`, local HEAD and origin/release-2.0.1 both resolve to the implementation commit. `git diff 3560216c5315088a05bb2e9dea263eac075c52bf origin/release-2.0.1 -- configure/RULES_SQL scripts/mariadb_setup.bash tests/database-config.py docs/README.install.md tests/README.md docs/milestone-2.0.1.md` is empty.
- Issue closure observed 2026-09-30 at 05:54 UTC: #55 is CLOSED, closedAt and updatedAt `2026-09-30T05:54:00Z`. Readback confirms the implemented body, all five completed acceptance criteria and [closure comment](https://github.com/jeonghanlee/epicsarchiverap-env/issues/55#issuecomment-5905030281). No external build gate applies to this work.

##### GitHub Projection

Title: Reject operations on an unselected database backend
Labels: bug
GitHub Milestone: 2.0.1
Observed State: CLOSED
Observed Labels: bug
Observed Milestone: 2.0.1 / #7
Last Compared: 2026-09-30 at 05:54 UTC, `gh issue view 55 --repo jeonghanlee/epicsarchiverap-env`; CLOSED, bug, milestone 2.0.1, assignee jeonghanlee, updatedAt 2026-09-30T05:54:00Z

#### G6 - epicsarchiverap-maven lands Ant removal with the per-site build contract

Origin: 265f580 / G6
GitHub Issue: none
Status: Open

##### Summary

epicsarchiverap-maven removes Ant from its build (its register row M10) and reports the
commit together with the post-Ant contract for the per-site build step that
`build.xml` target `sitespecificbuild` used to run inside
`src/sitespecific/<site>`. That step applies the site's HTML template and copies
CSS and images before WAR packaging. D33 requires Maven stabilization before
starting this conversion. This gate blocks M14 until the published source
replacement and its site-input contract are verified. No completion has been observed.

epicsarchiverap-maven register row: `docs/milestone-daff1b7.md` (historical peer observation; current contract must be rechecked) M10 (Ant removal, Deferred
and moved to the epicsarchiverap-maven backlog 2026-09-19, their D7).

##### Completion Criteria

- Record the stable epicsarchiverap-maven baseline and its build/test evidence before implementation, with confirmation that it is the baseline to use. No stabilization date or commit has been assigned.
- Identify a published epicsarchiverap-maven commit that replaces its Ant executions with Maven executions and documents the site-input contract.
- Verify template application, shared and mgmt assets, classpath configuration and four real WARs against that exact source commit. Retain supported default/test-site behavior.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-20 | Pending | epicsarchiverap-maven reports M10 (Ant removal) Deferred and moved to its backlog 2026-09-19 (their D7), with no landing commit. epicsarchiverap-env re-derived it at epicsarchiverap-maven modernize `3c96141d`: their register `docs/milestone-daff1b7.md` (historical peer observation; current contract must be rechecked) carries M10 as `Deferred` with an assignment-history row for the 2026-09-19 move, and the `maven-antrun-plugin` execution `sitespecificantscript` still runs `<ant antfile="${project.basedir}/build.xml" target="sitespecificbuild"/>`, so the per-site contract is still Ant-based. Recheck by reading that path and the pom at the then-current epicsarchiverap-maven `modernize` head. |
| 2026-09-30 06:20 UTC | Pending | Code inspection of local epicsarchiverap-maven `5e6c12668c9c55f71ae1ba1c3a4384d86049b806`: `pom.xml` still has `sitespecificantscript` and `create-version-txt` in `maven-antrun-plugin`. epicsarchiverap-env `site-template/siteid/build.xml` invokes the real `SyncStaticContentHeadersFooters` class with `template_changes.html` and the mgmt stage, then copies images, shared CSS and mgmt CSS. This checkout differs from the configured d8a7813f source pin; no migration build or stabilization result is claimed. |

##### Closure Evidence

- none

#### M14 - Remove Ant leftovers from epicsarchiverap-env

Origin: 265f580 / M14
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved
GitHub Issue: [#57](https://github.com/jeonghanlee/epicsarchiverap-env/issues/57)
Status: Blocked

##### Summary

epicsarchiverap-env owns the site inputs under `site-template/siteid`: `template_changes.html`, CSS, images and generated classpath configuration. `configure/RULES_SRC` copies that directory into `src/sitespecific/<ARCHAPPL_SITEID>` before Maven runs. The source POM then invokes Ant, which uses `SyncStaticContentHeadersFooters` to apply the template to mgmt pages and copies site assets into the stage used by WAR packaging. Removing only the Ant file would lose those generated pages and assets. The replacement must preserve the complete input-to-WAR path. Implementation waits for Maven stabilization; only the plan is being recorded.

##### Scope

- Preserve epicsarchiverap-env's template, CSS, images and configuration generation. Preserve the copy into `src/sitespecific/<ARCHAPPL_SITEID>` before each site build.
- Remove `site-template/siteid/build.xml` after the source-owned replacement lands. Remove `ANT_HOME`, `ANT_PATH`, `ANT_CMD`, `ANT_OPTS` and the Ant entry in `PATH` from `configure/CONFIG_SITE` and `configure/CONFIG_SRC`; update Ant-specific comments and tests, including the existing `ANT_OPTS` assertion in `tests/health-local.py`. Document obsolete local overrides without modifying operator-owned `.local` files.
- Keep the configured site selection consistent between the copied directory and the Maven invocation in `configure/RULES_SRC`; preserve the current default ALS site. Inventory all build variants before editing.
- Verify `configure/os/*.pkgs` remains free of an Ant requirement. Update operator and test documentation for the Maven site-input contract.
- Update `configure/RELEASE` to the published, verified source commit after the replacement passes. Coordinate the epicsarchiverap-maven prerequisite through G6.

Out of scope for this repository: implementing epicsarchiverap-maven's POM or Java changes; those are the producing repository's prerequisite described below. Also excluded: UI redesign, changing the template text or branding, appliance runtime changes, installation/VM automation and unrelated dependency upgrades.

##### Completion Criteria

- No Ant configuration, command dependency or site build file remains in epicsarchiverap-env. The exact source replacement and its contract have landing evidence.
- The real path is configuration generation, copy into the selected source site directory, Maven template/asset processing, then WAR packaging.
- Four real WARs preserve the generated classpath files and shared site assets; mgmt pages contain the expected template sections and mgmt CSS. WAR paths and bytes are checked against actual generated inputs and the Ant baseline.
- A clean rebuild and supported site changes preserve this result without stale ALS content leaking into another site. A valid site without optional customization retains its default pages.
- Invalid inputs and actual generator failures return nonzero through the real build. Required regression checks fail on the original Ant-dependent path or when the real replacement execution is disabled.

##### Dependencies And Decisions

- D33, Decision Date: 2026-09-29. Plan and issue update only. Implementation waits for Maven stabilization and subsequent plan acceptance and authorization; no source pin or build file is changed now.
- D31, Decision Date: 2026-09-29. Assigned to 2.0.1; detailed plan remains draft. Earlier assignment decisions below retain their original dates.

- Decision Date: 2026-09-29. Transferred from Milestone to Backlog for the 2.0.0 cycle close. Existing status, scope, dependencies, plan and verification evidence are preserved; no next release is assigned.
- G6 covers Maven stabilization, the published Ant replacement and its verified site-input contract; still Open, and it blocks this work; resume as Not started only after that gate and the implementation authority are satisfied.
- D9
- D17. 2026-09-20: Ant removal is deferred out of Phase 1 on both sides, so this
  row previously moved to Deferred and left [M8 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md)'s dependency list. epicsarchiverap-maven moved its M10
  to the backlog 2026-09-19; this row returns to Not started only by a new dated
  decision.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: original draft at epicsarchiverap-env d68f66848e1edc174e76fe77326e941baf58f850, docs/milestone-265f580.md, M14; remove-or-replace draft carried by dcfa39b3f1a6a457ffd6803cb6c618d601768c30, docs/milestone-2.0.1.md, M14

1. Wait for the stable epicsarchiverap-maven baseline to be identified and confirmed. Read its POM, supported site fixtures and existing generator. Accept the current migration plan and authorize its implementation separately before code changes.
2. In isolated work directories, preserve the actual Ant baseline with the real epicsarchiverap-env overlay. Generate configuration, copy the site directory and build the four WARs. Record the source/env commits, site selection, tool versions, input hashes, template sections, asset paths and WAR contents. Keep operator configuration and existing worktrees untouched.
3. Producing repository prerequisite: replace `sitespecificantscript` in epicsarchiverap-maven's `pom.xml`. Use `maven-resources-plugin` for shared images and `css/main.css` and for mgmt `css/mgmt.css`; use `exec-maven-plugin` to invoke the existing `SyncStaticContentHeadersFooters` on `template_changes.html` and the mgmt stage. Order base staging before site assets/template processing and all of these before `maven-war-plugin`. Keep `classpathfiles` packaging and supported site selection. Handle absent optional customization for valid default sites, while surfacing real input/generator errors. Rehome `create-version-txt` to a Maven execution as well so no Ant execution remains. Publish the verified source commit and contract before epicsarchiverap-env consumes them.
4. Dependent repository: preserve `conf.archapplproperties` and `copy.sitespecific` ordering in epicsarchiverap-env, then remove its Ant file/configuration and update the source pin to the published replacement. Check all build variants and `.local` site/path overrides. Update the tests and documentation without changing site content.
5. Run the real local suite and clean Maven builds through shipped Make targets in isolated paths. Compare WAR entries, template sections and exact asset/configuration bytes; run clean rebuild, site-switch and negative-input checks below. No internal function or build-stage substitute is allowed.
6. Record each actual result and both published commits. Only after all required checks pass, synchronize the issue body with evidence, close #57 under issue authority, observe closure and mark this work Complete.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local regression | Run the real local suite and assertions for removed Ant variables/files/packages and consistent site selection | Isolated epicsarchiverap-env checkout | Current checks pass; Ant-removal assertions fail against the original tracked files. Existing path/configuration tests remain valid after replacing the obsolete ANT_OPTS assertion. |
| T2 | Baseline build | Generate configuration, copy the actual overlay and run the original Ant-backed Maven package | Stable pre-conversion source and isolated install/storage paths | Four real WARs provide recorded template sections and asset/configuration bytes for comparison; exact source/env commits and inputs are recorded. |
| T3 | Full build | Run shipped init/configuration/copy/build targets with the published source replacement; inspect the effective POM and build log | JDK 21, source Maven Wrapper, isolated epicsarchiverap-env/source trees and install/storage paths | Copy precedes Maven; base stage precedes site processing; four real WARs are built without Ant executions. Record the actual checkout commit, not only SRC_TAG. |
| T4 | WAR content | Open the actual WAR ZIPs and compare generated inputs and T2 output | T3 artifacts | Shared images and main CSS match in all four WARs; mgmt CSS and each applicable template section match in mgmt pages including index.html. Classpath configuration/policies match generated files in all WARs; version.txt retains the source build contract. |
| T5 | Rebuild and site isolation | Repeat clean package and switch between ALS and source-supported default/test sites through the real configuration/copy/build path | Disposable source trees with actual tracked fixtures | Clean rebuild preserves site output; no ALS content leaks after a site switch. A valid site with no optional template/assets keeps its default content. Remove or disable only the real template/asset execution in a disposable copy to confirm the content check detects its loss. |
| T6 | Failure propagation | Use an invalid selected site/input path and trigger a real template-generator error; invoke shipped build targets | Disposable trees and actual generator | Build returns nonzero before a successful final package is reported. Valid absence of optional customization remains distinct from an invalid path or unreadable required input. No mocks replace the generator or Maven stages. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Isolated epicsarchiverap-env checkout | Pending | none |
| T2 | Not run | Stable pre-conversion source | Pending | none |
| T3 | Not run | Published replacement and isolated build paths | Pending | none |
| T4 | Not run | Actual baseline and replacement WARs | Pending | none |
| T5 | Not run | Actual supported site fixtures | Pending | none |
| T6 | Not run | Actual Maven and generator with invalid inputs | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Remove Ant leftovers from the environment configuration
Labels: enhancement
GitHub Milestone: 2.0.1
Observed State: OPEN
Observed Labels: enhancement
Observed Milestone: 2.0.1 / #7
Last Compared: 2026-09-30 at 06:40 UTC, `gh issue view 57 --repo jeonghanlee/epicsarchiverap-env`; prepared body matched the published body; OPEN, enhancement, milestone 2.0.1, assignee jeonghanlee, updatedAt 2026-09-30T06:40:26Z

#### M10 - Automate VM installation and runtime tests

Origin: 265f580 / M10
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved
GitHub Issue: [#56](https://github.com/jeonghanlee/epicsarchiverap-env/issues/56)
Status: In progress

##### Summary

Compose the existing cloud-provision VM lifecycle and ansible-provision installation with independent acceptance checks owned by epicsarchiverap-env. The actual path is fresh VM -> SSH/cloud-init readiness -> generated Ansible inventory -> prerequisite provisioning -> real Make/Maven build and installation -> installed payload and runtime verification -> retained evidence -> explicit VM cleanup.

The Phase 3 and Phase 4 entrypoints call the VM driver; real matrix acceptance remains pending. The earlier systemd-free container premise is incompatible with the shipped `make install`: `sd_health_stop`, `sd_install` and `sd_enable` invoke real `systemctl`. Both installation and runtime verification therefore use the same disposable systemd VM. No second VM provisioner or installation implementation is needed here.

##### Scope

- Implement a driver under `tests/vm/` that calls pinned, separately maintained cloud-provision and ansible-provision checkouts. Each tool retains ownership of its own implementation.
- Use Phase 3 for fresh VM readiness, prerequisite provisioning, actual installation and installed-payload verification. Use Phase 4 for process identity, scheduled health, HTTP identity, real CA acquisition/retrieval, persistence and repeat-install verification on that same VM.
- Add independent VM acceptance checks and structured results in this repository. Ansible success, a build sentinel, an active unit or HTTP 200 alone cannot satisfy acceptance.
- Adapt `tests/run-all-tests.bash`, phase dispatch, `tests/database-config.py` and `tests/README.md` to the VM-based phase contract. Preserve the existing `tests/phase3-docker.bash` path as a compatibility entrypoint for Phase 3; document its VM prerequisites. No Docker daemon or systemd substitute is required.
- Keep local checks independent of virtualization. System execution requires explicit external-checkout paths and published candidate refs; the local default must never provision a VM.

Out of scope: implementing VM images or cloud-init internals, duplicating Ansible roles, independently maintaining guest install commands, a Docker test environment, CI wiring, production deployment, load/heap soak, ETL retention-capacity validation, UI or Ant migration, and new database features.

##### Completion Criteria

- The full accepted matrix runs through the real three-repository path, with exact refs and the OS/backend/transport recorded. Every required assertion and case passes; a missing prerequisite, skipped assertion or unimplemented phase cannot yield overall success. A single-case run cannot establish full-matrix completion.
- Installed payload/configuration matches the actual WARs, logging JARs and generated inputs. Actual guest checkout commits match the requested epicsarchiverap-env and epicsarchiverap-maven commits.
- Four genuine appliance JVM identities, installed units and three eligible scheduled health successes are observed. Application readiness and identity are checked separately from process presence.
- The real IOC fixture archives and retrieves changing, timestamped values; PV configuration and historical samples survive an appliance restart. A repeat Ansible apply and explicit same-candidate reinstall preserve the configuration database and archive data.
- Wrong PID identity, loss of IOC updates and a real failed source checkout are detected without replacing any install/build/systemd/application span with mocks.
- Results, timing, relevant payload hashes and sanitized diagnostic excerpts are retained. Full-matrix acceptance remains INCOMPLETE until explicit cleanup independently confirms removal of this run's domains, disks, seed ISOs, `.creation-record` files and DHCP reservations, and the final verdict validates the retained test and cleanup evidence. Every resource present before the run, including DHCP reservations, is preserved; retained resources created by an earlier case in this same run remain owned cleanup targets.
- The public issue reflects the implemented scope and observed evidence and its authorized closure is observed. No closure or migration verification is claimed by this plan.

##### Dependencies And Decisions

- D34, Decision Date: 2026-09-30. Accept the combined cloud-provision -> ansible-provision -> epicsarchiverap-env workflow, six-case matrix and T1-T15 plan. VM lifecycle stays in cloud-provision; prerequisite provisioning and Make installation stay in ansible-provision; this repository owns orchestration and final verification. This direction replaces the container-install premise; implementation authorization remains separate.
- D31, Decision Date: 2026-09-29. Assigned to 2.0.1. Assignment authorizes planning, not implementation.
- The six-case matrix and proposed deadlines are accepted with this plan. Exact external tool revisions, published candidate commits and images remain execution inputs to be selected and verified through the planned preflight before guest creation. A dirty local checkout or branch name is not a candidate identity for an Ansible clone.
- M14 is not a behavioral prerequisite for this automation: the existing build can be tested at its verified source pin. A later Ant replacement or source-pin change requires a new integrated run on the combined candidate; existing release-wide verification retains ownership of that final run.
- Decision Date: 2026-09-29. Transferred from Milestone to Backlog for the 2.0.0 cycle close; reassigned under D31.
- Decision Date: 2026-09-22. Earlier assignment left the test host and implementation plan undefined; that historical assignment did not authorize implementation.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-30; owner accepted the current VM workflow, six-case matrix, deadlines, ownership/cleanup contract and T1-T15 after review
Implementation Authorization: 2026-09-30; owner authorized implementation of the accepted plan
Superseded Plan Artifacts: original draft at epicsarchiverap-env d68f66848e1edc174e76fe77326e941baf58f850, docs/milestone-265f580.md, M10; container-install draft carried by dcfa39b3f1a6a457ffd6803cb6c618d601768c30, docs/milestone-2.0.1.md, M10

###### Repository Responsibilities And Handoffs

| Step | Owner | Input | Required Output And Next Condition |
| --- | --- | --- | --- |
| 1. Preflight | epicsarchiverap-env | External checkout paths, exact published candidate/tool refs, selected case, deadlines, private evidence location | Valid prerequisites and resource ownership plan; no guest mutation on invalid input; T14 fault ref kept separate from valid candidates |
| 2. Fresh VM | cloud-provision | OS selector, distinct instance label, image directory and resource limits | New domain/disks only, resolved identity, SSH and completed cloud-init |
| 3. Inventory | cloud-provision | Readiness result and matching species | Runtime inventory naming exactly the new VM; stable OS/species groups |
| 4. Prerequisites | ansible-provision | Its tracked inventory plus generated runtime inventory; limit to the new VM | Real EPICS tools, JDK, shared Tomcat and selected DB available |
| 5. Build/install/start | ansible-provision calling epicsarchiverap-env | Exact `archiver_env_ref`, `archiver_maven_src_tag` and case-specific overrides | Actual Make/Maven steps succeed; installed tree and services ready for independent checks |
| 6. Acceptance | epicsarchiverap-env | VM identity, actual build/configuration outputs and original IOC fixture | Per-assertion payload, database, process, health, HTTP, CA and persistence results |
| 7. Evidence before cleanup | epicsarchiverap-env | Case/assertion results, ownership context and bounded logs | Retained report; full run returns INCOMPLETE/77 while cleanup evidence is pending |
| 8. Explicit cleanup | cloud-provision, called by the driver | Recorded ownership and an explicit cleanup request | Driver independently confirms owned domain/disk/seed/creation-record and live/persistent DHCP removal; pre-existing resources preserved; evidence retained and cleanup errors reported |
| 9. Final verdict | epicsarchiverap-env | Retained results and cleanup evidence bound to the same run/candidate | Read-only evaluation; exit 0 only for complete T2-T15 evidence across the accepted matrix; original failures remain failures |

1. Define and validate the cross-repository input contract. Use explicit paths to initialized tool checkouts, full commit IDs for both tools and both appliance repositories, case selection, timeouts and an evidence directory. Record tool versions and effective `SRC_TAG`; verify every normal candidate/tool commit can be cloned before creating guests. T14 is a separately selected negative case: after normal preflight succeeds, the driver prepares a distinct 40-hex fault ref and confirms its absence in the real source clone. Record the valid source candidate and the absent fault ref separately; absence is required only for this named negative case. Invalid normal refs still stop before guest creation. Publish candidate code under separately authorized commit/push actions before installation tests; never label a run of the old remote commit as verification of local changes.
2. Add the orchestration and result support under `tests/vm/`. Keep lifecycle logic in a single driver; installation and runtime checks are separate commands/functions of that driver. Wire it into the existing phase entrypoints and cumulative runner. For `--system`, the positive matrix loop surrounds both phases: create one case's context, run its Phase 3 then Phase 4, collect results, shut down that owned successful guest through cloud-provision, then begin the next case. Negative cases follow their specified paths; T14 records its expected Phase 3 checkout failure and never enters Phase 4. Never provision all six guests first. A Phase 3-only run selects one positive case, stops after installation checks and records a live VM context; Phase 4 first verifies that context and its candidate identity. Cumulative `--phase=4`/all modes run local phases once before this same matrix loop; `--phase=3` runs local phases and one selected installation case.
3. Before the first guest creation, record one immutable run-start baseline of existing domain identities and DHCP reservations in the selected libvirt network's live and persistent configuration. Keep a separate cumulative ownership list for resources created by every case in this run. Refresh observations before each case to detect collisions, but never add this run's earlier owned resources to the preservation baseline. Call the real `cloud-provision/bin/create_vm.bash` with `-F` and a unique instance label; inspect readiness through its `-s` path. Refuse existing domains/disks and unrecorded targets. Record the created domain UUID, exact disk/seed/`.creation-record` paths, creation identity, network and DHCP MAC/IP attributes (plus a legacy name when present) in the private ownership context. Require the actual domain UUID/name and single network-interface MAC to match; live and persistent reservations must agree without MAC/IP collisions. New unnamed reservations are valid; any legacy name must equal the domain name. Compare the actual guest interface IPv4 address to the reservation and the actual hostname to its cloud-init datasource metadata, with a 63-character limit. Only recorded owned resources are eligible for cleanup; resources outside that list remain untouched. Generate inventory with `bin/generate_ansible_inventory.bash`; combine it with ansible-provision's maintained inventory and always limit the play to the exact created VM. Do not default to a running development or soak VM.
4. Apply the real `archiver_dev` or `archiver_dev_sqlite` species. Pass all candidate refs explicitly instead of inheriting role defaults. Keep `archiver_site_id=als`; select DB backend/transport, service account, install/store roots and heap. The Ansible role executes `init`, `db.conf`, `conf.archapplproperties`, `build.mvn`, `sql.fill`, `conf.storage`, `install` and `sd_start` in the shipped Make system. Observe both the detached build result and actual guest state. Do not insert alternative install commands in this repository.
5. Add installed-payload checks that compare all four exploded WAR trees and Tomcat logging JAR sets against that guest's real build outputs. Check the selected site's classpath files, ALS template/assets, generated service ports, effective unit files, ownership and backend configuration. Separate expected Tomcat/runtime state from immutable WAR/JAR payloads.
6. Add independent runtime assertions: real process identities under the service account, direct shipped launcher health, three non-skipped scheduled health executions, appliance JSON identity, database schema/transport and live IOC archival/retrieval. Confirm the candidate's raw retrieval boundary behavior using the actual API and recorded IOC events. Retrieve at least ten samples within the requested window, with distinct timestamps and changing values matching real CA observations; a value preceding the window cannot count as new acquisition.
7. Add restart, unchanged Ansible re-apply and explicit same-candidate reinstall checks. Retain pre-action identities and data; after the action, verify fresh/live identities as appropriate, health/readiness, persistent PV registration, identical historical samples and additional new samples. Verify state preservation from real data, not only an on-disk marker.
8. Add real failure cases on disposable guests: another real instance's PID in a PID file, stopped IOC, and T14's absent fault ref during a fresh installation. Only T14 supplies that recorded fault ref as `archiver_maven_src_tag` to the real Ansible species; the environment/tool refs remain valid. Positive cases always use the validated source candidate. Assert non-success at the relevant boundary and preserve evidence; restore baseline between runtime cases. Update local runner regressions to check both invalid normal inputs before external action and the separate T14 input contract, rather than asserting that implemented phases always return the old stub result.
9. Implement evidence retention, explicit cleanup and final verdict operations in the same driver. Preserve guests on unexpected failures and interruptions; stop only helper processes owned by the run, and do not advance the matrix after an unexpected failed case. After successful assertions, including an expected T14 build failure, shut down the owned guest through cloud-provision's `-S` path and retain its domain/disks until explicit cleanup. Store all case results and ownership records in one run context. The planned `--cleanup=<run-context>` operation rechecks domain UUID, exact disk/seed/`.creation-record` paths, creation identity and DHCP ownership, then calls the existing cloud-provision cleanup path. Independently inspect every resource afterward, even when the tool exits 0: the owned domain and files must be absent, the recorded DHCP MAC and IP must both be absent from both live and persistent network configuration, and every pre-existing reservation must remain. A failed inspection cannot establish absence or preservation. It requires a separate explicit cleanup request and can operate on retained failed runs without erasing their failure results. Pre-existing guests, directories and operator `.local` files remain untouched. Missing ownership evidence refuses cleanup; shutdown, removal or inspection failures are reported lifecycle failures. The planned `--verdict=<run-context>` operation reads the retained evidence without guest mutation: pending cleanup returns 77, observed failures return nonzero, and only the complete accepted matrix with successful T15 cleanup can return 0.
10. Update operator/test documentation, run local checks and the complete accepted matrix, record each result, and project the revised scope and evidence to #56 under separate issue authority. Keep the milestone In progress until implementation, the accepted real matrix and required external evidence are complete.

###### Proposed Environment Matrix

The proposed acceptance matrix has six fresh successful installations, run sequentially with one active guest per case. Runtime-negative checks use the dedicated SQLite matrix guest for each OS after its healthy assertions; build-failure checks require two additional fresh guests, one per OS. Each guest uses the real OS init/systemd, JDK 21, the existing shared Tomcat provisioner, two vCPUs, 4 GiB nominal RAM, a disk sized for the cold build, and the current 256M per-instance test heap. Record actual guest RAM and disk capacity; require enough free space before build. These are test conditions, not production capacity recommendations. Confirm exact image/tool versions and resource limits before execution.

| OS | Backend / Transport | Species And Required Overrides |
| --- | --- | --- |
| Debian 13 | MariaDB / socket | `archiver_dev`; `archiver_db_backend=mariadb`, `archiver_db_socket=auto`, `mariadb_skip_networking=true` |
| Debian 13 | MariaDB / TCP | `archiver_dev`; empty `archiver_db_socket`, `mariadb_skip_networking=false`; validate the provisioned application account for the effective transport |
| Debian 13 | SQLite | `archiver_dev_sqlite`; `archiver_db_backend=sqlite`; no MariaDB server/service required |
| Rocky 8.10 | MariaDB / socket | Same socket contract through the Rocky species target |
| Rocky 8.10 | MariaDB / TCP | Same TCP contract through the Rocky species target |
| Rocky 8.10 | SQLite | Same SQLite contract through the Rocky species target |

For every case, bind the environment/source refs, tool refs, image digest, site, effective ports, user/group, heap and store policy into the private run context. Both guest Git HEADs in positive installations must equal the requested full commits. T14 additionally binds its separate fault ref and records the actual failed source checkout; it cannot claim a successful installation or require a HEAD at a nonexistent commit. The install stamp and configuration are supporting evidence, never substitutes for reading HEAD and checking payload hashes. Bind an original tracked IOC fixture and its immutable repository commit/path/digest as a separate input; do not reconstruct the fixture from a previous report.

The inspected source at 5e6c12668c9c55f71ae1ba1c3a4384d86049b806 tracks `src/resources/test/UnitTestPVs.db` and its real `SIOCSetup` consumer. Use that original fixture unchanged, with a per-run prefix and its incrementing `test_0` PV, after confirming compatibility with the candidate. The configured source pin d8a7813f40083c1bf7148e6c3b7bffd368d70ee0 is not available as a local tree object for fixture comparison; no same-pin fixture equivalence is claimed. Acquire and verify the exact fixture before running. Start the real `softIocPVX` inside the guest with loopback CA discovery; use real CA tools and the appliance APIs. A fixed fixture ref does not change `SRC_TAG`.

At the inspected fixture commit, the original file contains 10,018 records, including 9,997 with `SCAN` set to `.1 second`. The real consumer loads the entire file; archiving only `test_0` does not limit IOC processing to that PV. Preserve the complete fixture and record its actual record/SCAN counts with its identity. Measure IOC CPU/RSS and guest CPU/memory availability on the proposed two-vCPU, 4-GiB VM, alongside the four appliance JVMs, to verify that the functional checks meet their fixed deadlines. These measurements remain pending; the record counts alone establish neither sufficient resources nor a resource failure.

###### Phase And Result Contract

- Phase 3 checks the fresh installation and its payloads on a VM running real systemd. Phase 4 consumes that same validated installation; it never accepts an arbitrary SSH address or stale context as a verified candidate.
- `--local` runs only the existing local checks and new preflight/verdict negatives. It cannot contact a guest or create resources. Explicit system selection and inputs are required before the VM driver can mutate guest state. The cumulative all-phase mode keeps its documented behavior, but missing explicit system inputs stop before provisioning.
- Diagnostic phase/single-case runs may return 0 for their selected assertions and must identify their limited coverage; they cannot close the acceptance matrix. A full `--system` run retains its context and returns INCOMPLETE/77 when all checks before cleanup succeed but T15 cleanup remains pending. After separately requested `--cleanup=<run-context>`, run `--verdict=<run-context>` to establish full acceptance from the same retained evidence. Cleanup exit 0 describes that operation only; final verdict exit 0 requires the complete accepted matrix and every T2-T15 assertion, including cleanup. Expected negative-test child failures count as successful assertions only when the actual failure and required containment are observed; unexpected failures remain failures after cleanup. Exit 1 denotes observed build/runtime/assertion/cleanup failure; exit 2 denotes invalid invocation or context; exit 77 denotes unavailable prerequisites, unimplemented required checks or pending required cleanup. Any 77 remains overall INCOMPLETE. Preserve the original cause when diagnostic collection also fails.
- The proposed positive deadlines are VM readiness 30 minutes, detached build 45 minutes, application readiness 5 minutes, first ten archived samples 3 minutes and post-restart readiness 5 minutes. Record retries and actual elapsed times. Confirm the runtime bounds with measurements while the complete IOC fixture is running on the accepted VM resources; an exceeded bound is a failed check, not permission to extend it silently. Changing resources or deadlines requires a revised accepted plan and a new run. Healthy startup messages and a transient initial HTTP error may be retried until the bound; permanent malformed responses and identity mismatch fail. Confirm the build bound against the existing role's 80 x 30-second poll limit.
- Scheduled health verification begins only after the effective startup allowance. Record three distinct eligible timer invocations with successful process/storage observations and actual timestamps. Startup/intentional-stop skips do not count. Derive the overall bound from effective startup/interval/timeout values plus a stated scheduling allowance; retain measured times rather than claiming a detection latency from arithmetic.
- Local evidence retains exact target identities, runtime inventory and private diagnostics with restrictive permissions. The public report includes case IDs, immutable code/image refs, tool versions, expected/actual assertions, measured durations, relevant hashes, failure categories and bounded sanitized logs. Exclude credentials, internal VM/host/IP/endpoint identifiers and full secret-bearing configuration.

##### Test Plan

T1 retains the cumulative system-run identity; T2-T15 make its required observations explicit. T3-T12 run for every matrix case. T13 and T14 cover the actual negative paths on dedicated disposable guests for each OS; T15 covers every resource lifecycle. No acceptance row can be marked Pass from code inspection alone.

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | System | Run shipped `tests/run-all-tests.bash --system`; retain its context; separately request driver cleanup, then evaluate the final verdict | All six accepted positive cases and both OS negative cases | Before cleanup: INCOMPLETE/77 with retained results; after actual cleanup: T2-T15 evidence complete, no required skip/failure and final verdict exit 0 |
| T2 | Local preflight | Execute real entrypoints with missing tool paths, invalid normal candidate refs, invalid case/context and unsupported arguments; check distinct normal/fault-ref inputs; run `--local` | Isolated local checkout; no VM credentials/resources | Invalid/missing normal inputs exit 2 or 77 before external action; a fault ref cannot bypass normal preflight or enter a positive case; valid local suite preserves its verdict without guest contact/provisioning |
| T3 | VM lifecycle | Call actual cloud creation/readiness and inventory generator; inspect guest OS, cloud-init and identity | Fresh per-case VM | New recorded domain/disks; SSH and cloud-init ready; exact target limit; existing resources unchanged |
| T4 | Real installation | Apply pinned species with explicit appliance refs; observe build unit, source HEADs, Maven log and actual installation | Every matrix case | Eight real Make steps succeed; both HEADs equal requested commits; no stale sentinel/ref/default can pass |
| T5 | Installed payload | Compare real WAR/JAR/configuration bytes, site assets, ports, effective units and ownership | Actual guest build/installed trees | Four intended payloads and required logging JARs match; site/configuration and permissions match the case |
| T6 | Backend contract | Use actual clients as the service account; inspect schema, JNDI and unit dependencies; confirm effective connection transport | Socket, TCP and SQLite cases | Four named application tables; matching resource/runtime DB; selected transport usable; SQLite has no MariaDB dependency/contact |
| T7 | Process identity | Inspect installed launcher health and PID/executable/start-time/CATALINA_BASE under service account | Real four-JVM appliance | Four distinct genuine appliance identities; direct health exit 0; no PID file or `pgrep` match alone accepted |
| T8 | Scheduled health | Inspect effective pair/timer, journal and systemd invocation timestamps after startup allowance | Running guest systemd | Enabled/active timer; three distinct eligible successful checks; no skip counted as success |
| T9 | HTTP identity | Poll real `getApplianceInfo` with a bound and parse its JSON | Selected mgmt port | HTTP 200 plus matching appliance identity/URLs and version contract; independent payload/source checks establish the commit |
| T10 | CA-to-retrieval | Start complete original IOC fixture; measure IOC/guest resource use and elapsed times; record CA updates, register actual PV, confirm raw API boundary behavior and poll status/`getData.json` | Real IOC, engine, store and retrieval on accepted VM resources | Resource/timing evidence retained; `Being archived`; >=10 distinct timestamps and >=2 values inside the requested window matching real CA observations within the deadline; any permitted preceding value excluded from acquisition counts |
| T11 | Restart persistence | Record PV row and retrieved samples; restart through shipped `sd_restart`; repeat identity/health/HTTP/status/retrieval | Same VM and real DB/store | PV row survives; earlier samples unchanged; new samples after restart; fresh process identities and bounded readiness |
| T12 | Repeat installation | Re-apply unchanged pinned species, then explicitly force same-candidate reinstall; repeat payload and runtime checks | Same VM after healthy baseline | Unchanged apply does not rebuild; forced install is real; PV configuration/history retained; new acquisition resumes |
| T13 | Runtime negatives | Use another genuine instance's PID in one PID file; restore; stop real IOC and run fresh-window retrieval checks; restore | Dedicated disposable guest per OS | Health/verifier detects wrong identity despite HTTP readiness; stale history never passes fresh acquisition; real pipeline reports non-success and recovery is reverified |
| T14 | Real build failure | Pass normal preflight with valid candidate/tool refs; on a fresh guest supply only the separately recorded absent fault ref as `archiver_maven_src_tag` to the real species/build path | Dedicated failure guest per OS | Actual source checkout/build fails within bound; preflight rejection alone cannot pass; no new success sentinel/acceptance; Phase 4 is not run; original failure retained |
| T15 | Evidence/cleanup | Run at least two real cases sequentially, retaining the first case's resources; exercise interrupt/failure retention, separately requested cleanup and ownership refusals; independently inspect domain/disks/seed/`.creation-record` and live/persistent DHCP configuration; evaluate retained results | Disposable owned resources, immutable run-start domain/DHCP baseline and cumulative case ownership list | Earlier cases remain owned cleanup targets; all owned resources removed and run-start baseline preserved regardless of tool exit 0; pending cleanup never yields full success; results/logs retained; actual failures cannot be cleared by successful cleanup; final exit 0 requires all other assertions too |

###### Assertion Details

- T5 reads WAR entries and logging JAR digests from the actual Maven target directory and compares installed counterparts. Generated classpath files are checked inside each WAR as well as the installed application; site images/shared CSS and mgmt template sections are checked independently. Timestamped artifact names alone are not identity evidence.
- T6 requires `ArchivePVRequests`, `ExternalDataServers`, `PVAliases` and `PVTypeInfo`. MariaDB clients use the same socket/TCP transport and application account as Tomcat. SQLite clients run as the actual service account; inspect that there is no MariaDB unit dependency and no accidental MariaDB installation/contact in the SQLite-only species. Confirm the newly registered test PV is persisted in `PVTypeInfo`.
- T8 records health invocation identity, exit status and output. A unit's most recent successful result cannot represent three executions. An enabled timer or a startup skip cannot replace a completed health check.
- T10 records the full fixture's identity and record/SCAN counts, IOC startup duration and timestamped resource observations before IOC startup and throughout acquisition. Record the sampling interval, IOC PID/CPU/RSS, four appliance JVM identities/RSS, and guest CPU, available memory and swap use. Retain elapsed acquisition and post-restart readiness times through T11/T12 with the IOC running. Missing measurements leave the resource/deadline confirmation incomplete; exceeding a fixed readiness/acquisition bound or observing a process loss fails its check. This is functional-test environment verification, not a capacity or long-duration soak result.
- T10 starts CA observation before registration. Capture real IOC event timestamps and values, then compare retrieved `secs`/`nanos` and values to those observations at the CA client's recorded timestamp precision; do not claim nanosecond equality from lower-precision output or invent a time offset. Keep IOC and client in the same guest and record timestamp resolution before judging a match. Use raw `getData.json` without a postprocessor. Query across known recorded events with `from` between two event timestamps and record whether the candidate includes the latest value before `from`. Repeat the observation during T13's stopped-IOC window with `from` after the last observed update. These are actual candidate API checks, not inferred results from the inspected source.
- T10 counts only sample timestamps inside the inclusive `[from, to]` window. If the candidate's observed raw API contract includes a preceding value, permit at most one such first value; record it separately and exclude it from new-sample counts, changing-value counts and the in-window CA comparison. Compare it with the recorded preceding CA event when available. Reject other out-of-window timestamps, malformed/empty data, stale-only history, fewer than ten distinct in-window timestamps or unchanged in-window values. Retry only while the deadline remains. Record requested and observed ranges; do not infer collection from a successful registration response. T11's post-restart acquisition and T13's IOC-loss check use the same rule, so a returned preceding value never proves new acquisition.
- The retrieval boundary check remains unverified until the selected candidate's real API runs. The inspected 5e6c12668c9c55f71ae1ba1c3a4384d86049b806 source has preceding-event handling in `MergeDedupConsumer`; this is a reason to require the check, not proof of the selected candidate's runtime response.
- T11 keeps the original retrieved window and checks it again after restart, then asks for a window after that restart. A persistent PV row without new data, or new data without preserved historical samples, fails.
- T12 records the Ansible outcome, build invocation identity and appliance PID/start times. Re-apply success without actual application checks is insufficient. A forced same-candidate install is explicit and performed only on this run's VM; it must not erase the configuration DB or archive history.
- T13 wrong-PID testing preserves/restores the original PID file and uses a currently verified real other-instance PID; health must fail without signaling/removing either genuine process. IOC loss is judged with a new query window after the last observed update, so old stored data cannot satisfy the test. Restoration is followed by new CA/archival observations.
- T14 prepares a source ref whose absence has been confirmed in the real clone after all normal candidate/tool refs pass preflight. This ref is an intentional fault input, never a candidate identity. The driver passes it only to the named negative case through the actual Ansible variable; the role renders and runs its real detached build script unchanged. Preserve the successful normal preflight, fault-ref absence evidence, Ansible override, build invocation and actual checkout error. A host-side preflight failure cannot satisfy T14. Do not substitute `git`, Maven, Make or `systemctl`; a verifier-only fabricated failure is insufficient.
- T15 compares the immutable run-start baseline and cumulative case ownership list against real post-cleanup state. Execute at least two real cases sequentially through the driver, leaving the first case's shut-down VM and DHCP reservation present when the second begins. Confirm that these earlier-case resources remain in the owned cleanup list and do not become preservation targets through a later observation. After explicit cleanup, independently confirm that every case's owned domain, disk, seed ISO and `.creation-record` are absent, and each owned DHCP MAC and IP are both absent from both live and persistent configuration of the recorded network. Every domain and reservation in the run-start baseline must retain its identity; resources outside the ownership list remain untouched. Capture inspection exit codes and actual results; a query/permission error cannot count as an absent resource. The inspected cloud-provision cleanup at 794eb6b17679a5d48ba61fea3eee110b4b62a97a reports individual failures through messages and its main cleanup branch exits 0, so neither that exit nor an `[OK]` message proves all postconditions. No cleanup failure reproduction is claimed by this inspection. Missing/mismatched context is a refusal, not permission to delete by prefix. Failure/interrupt evidence is preserved before any explicit cleanup. Verify full-run exit 77 while cleanup is pending, cleanup refusal/error or a remaining owned resource without full PASS, and final verdict exit 0 only after all required evidence and resource postconditions are present. A retained unexpected failure must still yield final exit 1 after successful cleanup. A partial context, candidate mismatch or incomplete matrix cannot yield full acceptance.

##### Implementation Evidence

- `tests/vm/driver.py` orchestrates pinned cloud/Ansible entrypoints, sequential cases, retained ownership/evidence, diagnostic operations, interruption/refusal checks, explicit cleanup and read-only final evaluation. `tests/vm/guest.py` checks the real artifacts, database, JVMs, scheduled health, HTTP and original IOC/retrieval/persistence paths.
- The existing phase entrypoints and cumulative runner call the driver; `tests/vm/config.example.json` and `tests/README.md` define explicit inputs and operator commands. `tests/vm/local.py` runs in Phase 1 without virtualization.
- Local verification does not satisfy the accepted real VM matrix. Full candidate publication and explicit checkout/image/key/fixture/binary inputs are required before VM execution; the driver refuses a published candidate whose harness bytes differ from the executing implementation.
- Lifecycle selectors are checked against recorded VM/file identities before external operations. Cleanup independently confirms and persists each completed case before advancing, retains its initial preservation snapshot across retries, and rechecks completed removal. An interrupted case can be completed by observing that all its resources are absent; unverifiable partial ownership still refuses deletion. Original failures remain failures.
- The original fixture commit and SHA256 are enforced, including SHA256 `85778e0ed007ef196ab963a582c9ba7ddbff96bf68e91edab118d1e9ff497e32`, re-derived from the actual committed file. System/installation preflight executes the published candidate's full local suite once; final evaluation requires the matching candidate, exact command, exit 0 and retained output digest rather than a CLI-only result.
- The IOC prefix derives twelve SHA256 hexadecimal characters from the creation ID. Before processing starts, the real IOC must load every original fixture record and report no database loading error. Candidate local checks use the verified candidate source checkout at the expected source path; shell `[SKIP]` and nonzero unittest `skipped=N` counts prevent both preflight and final acceptance through the same completeness check.

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-30 06:44 UTC | Docker daemon 29.8.1 and system libvirt accessible | Pending | Executed the previous shipped `tests/run-all-tests.bash --system`; both unchanged system-phase stubs reported unimplemented checks and the runner exited 77. No installation/runtime acceptance ran. This is the pre-implementation observation, not a result of the new workflow. |
| T2 | 2026-09-30 15:47 UTC | Local Debian 13; Python 3.13; real CLI entrypoints | Pending | Full `tests/run-all-tests.bash --local` exited 0 outside the socket-restricted sandbox: Phase 1 223/0, Phase 2 13/0, health 20, database 10 and VM CLI 10 tests passed without skips. The two added CLI regressions reject noncanonical fixture identities and changed lifecycle selectors before external commands. Bash/Python syntax and `git diff --check` passed; ShellCheck warning gate passed, with only the existing SC1091 info finding in its inventory. Console evidence: `work/m10-validation/review-fixes-local.log`. A separate actual environment checkout with its candidate source linked at the expected path ran the current full local suite on 2026-10-01 03:53 UTC with exit 0 and no skips (Phase 1 223/0, Phase 2 13/0; health 20, database 10 and VM CLI 10 tests); evidence: `work/m10-validation/candidate-source-local.log`. On 2026-10-01 05:11 UTC, the corrected full local suite exited 0 without skips (Phase 1 223/0, Phase 2 13/0; health 20, database 10 and VM CLI 11 tests). The new regression runs the shipped health test with a real Java executable and libraries but no adjacent compiler, then rejects its actual unittest skip output. A separate full-suite run with that compiler-free Java also exited 0 with `OK (skipped=1)`; the shared production completeness function accepted the normal output and rejected the skipped output. Evidence: `work/m10-validation/unittest-skip-normal.log`, `unittest-skip-jre.log` and `unittest-skip-verdict.json`. The published-driver preflight executed before the first real VM attempt; live cleanup progress/retry and the remaining real matrix assertions are unexecuted. Earlier local evidence remains in `work/m10-validation/local.log` and `work/m10-validation/vm-local.log`. Local contract checks on 2026-10-01 09:14 UTC exited 0 without skips: Phase 1 223/0, Phase 2 13/0, health 20, database 10 and VM local 14 tests; evidence: `work/m10-validation/cloud-contract-local.log`. The three new unit checks execute shipped ownership predicates for unnamed/legacy reservations, UUID/interface identity and remaining MAC/IP detection; they do not exercise real VM creation or cleanup. Read-only SSH on the retained Debian guest confirmed `sudo -n cloud-init query ds.meta_data.local-hostname` returns the actual datasource hostname; this is a metadata-query observation only, retained in private `work/m10-validation/cloud-metadata-query.json`. The actual guest confirmed that `ip -j address` includes MAC and IPv4 data, whereas `ip -j -4 address` omits MAC data; the driver uses the former and selects IPv4 entries. |
| T3 | 2026-10-01 05:39 UTC | Published environment `e43b973fe534786cf5606c8ab46b9ba5a948d072`; cloud-provision `794eb6b17679a5d48ba61fea3eee110b4b62a97a`; first Debian 13 socket case | Fail | Real cloud creation exited 1 at SSH readiness; the reserved IP differed from the actual lease and the 90-character guest hostname was rejected. Ansible installation did not run. VM and original failure are preserved in `work/m10-vm-run-e43b973-2`; diagnostic SSH through the observed lease does not satisfy the original run. The cloud-provision correction and current driver require a new matching published-candidate run. A second real run on 2026-10-01 16:19 UTC used published environment `4280f203f87fe2c20de1543ab589cbed9f97e7d0` and cloud-provision `da2ffd56c57cd1814472e85afe3b794339e09464`: cloud creation/readiness and inventory generation exited 0; guest hostname was 63 characters and actual MAC/IP matched the reservation. The driver then failed JSON decoding because its SSH stderr first-connect warning was merged into stdout. Ansible did not run; `work/m10-vm-run-4280f20` preserves the failed run and VM. On 2026-10-01 17:19 UTC, the corrected shipped SSH function repeated the actual guest facts command with a fresh known_hosts file: stdout decoded as JSON, the first-connect warning was retained separately in stderr, and actual hostname matched cloud-init datasource metadata. Private evidence: `work/m10-validation/ssh-stream-fix/command-00001.json` and `command-00002.json`. The final local suite on 2026-10-01 17:19 UTC exited 0 without skips: Phase 1 223/0, Phase 2 13/0, health 20, database 10 and VM local 15 tests. The stream regression executes real subprocesses and checks JSON stdout, retained stderr, nonzero exit propagation and the unchanged combined-output default. Evidence: `work/m10-validation/ssh-stream-fix-local.log`. This read-only diagnostic does not replace a complete matrix run. A third run at 2026-10-01 18:09 UTC with published environment `bdb36baeddeb153ea75a903aafd5cbce0c7effa6` passed this case's lifecycle and identity checks; original run evidence is retained in `work/m10-vm-run-bdb36ba/run.json`. Its overall runtime verdict remains Fail; other matrix cases are unexecuted. |
| T4 | 2026-10-01 18:25 UTC | Published environment `bdb36baeddeb153ea75a903aafd5cbce0c7effa6`; Debian 13 MariaDB socket case | Pending | First-case actual Ansible/Make cold build and installation passed. Evidence: `work/m10-vm-run-bdb36ba/run.json`. Other accepted matrix cases remain unexecuted. |
| T5 | 2026-10-01 18:25 UTC | Published environment `bdb36baeddeb153ea75a903aafd5cbce0c7effa6`; Debian 13 MariaDB socket case | Pending | First-case installed payload comparison passed. Evidence: `work/m10-vm-run-bdb36ba/run.json`. Other accepted matrix cases remain unexecuted. |
| T6 | 2026-10-01 18:25 UTC | Published environment `bdb36baeddeb153ea75a903aafd5cbce0c7effa6`; Debian 13 MariaDB socket case | Pending | First-case database schema and socket passed. Evidence: `work/m10-vm-run-bdb36ba/run.json`. Other accepted matrix cases remain unexecuted. |
| T7 | 2026-10-01 18:25 UTC | Published environment `bdb36baeddeb153ea75a903aafd5cbce0c7effa6`; Debian 13 MariaDB socket case | Pending | First-case JVM readiness passed. Evidence: `work/m10-vm-run-bdb36ba/command-00298.json`. Other accepted matrix cases remain unexecuted. |
| T8 | 2026-10-01 18:26 UTC | Published environment `bdb36baeddeb153ea75a903aafd5cbce0c7effa6`; Debian 13 MariaDB socket case | Pending | First-case three eligible scheduled health invocations passed. Evidence: `work/m10-vm-run-bdb36ba/command-00298.json`. Other accepted matrix cases remain unexecuted. |
| T9 | 2026-10-01 18:25 UTC | Published environment `bdb36baeddeb153ea75a903aafd5cbce0c7effa6`; Debian 13 MariaDB socket case | Pending | First-case HTTP identity passed. Evidence: `work/m10-vm-run-bdb36ba/command-00298.json`. Other accepted matrix cases remain unexecuted. |
| T10 | 2026-10-01 19:27 UTC | Retained Debian 13 MariaDB socket VM; source `d8a7813f40083c1bf7148e6c3b7bffd368d70ee0`; EPICS 7.0.10; original committed fixture; corrected guest code SHA256 `0fa83378f71549079a6fb5f7a0a73d368f3696fb1a68db1c345952565b6105b0` | Pending | The published `bdb36ba` runtime failed timestamp/value comparison with zero parsed CA observations: `camonitor -t i` produces incremental timestamps while the parser requires absolute dates. The correction selects CA server timestamps with `-t s`. A focused execution of the shipped `Guest.start_ioc`, `Observer` and `Guest.acquire` loaded all 10,018 original records, recorded 107 CA events without observer errors, and matched all 10 distinct retrieved samples to real CA timestamp/value observations. IOC startup took 1.273 s and acquisition took 106.657 s, within the unchanged 180 s bounds. Private evidence: `work/m10-validation/ca-timestamp-fix-acquisition-2.json`; full local suite exited 0 without skips (Phase 1 223/0, Phase 2 13/0, health 20, database 10 and VM local 15 tests), evidence `work/m10-validation/ca-timestamp-fix-local-external.log`. This focused run does not replace the failed full run or satisfy the full matrix and remaining boundary assertions. On 2026-10-01 20:28 UTC, the fresh `52d90166f5995acc332dbeb14945ed26ae32d408` Debian socket run passed T3-T10: real VM creation, installation, payload, database, JVM/HTTP readiness, scheduled health and CA-to-retrieval checks. The original fixture loaded 10,018 records; first acquisition completed in 101.860 s and its raw preceding-value boundary check passed. Runtime evidence: `work/m10-vm-run-52d9016/command-00304.json`; installation results: `work/m10-vm-run-52d9016/run.json`. Other accepted matrix cases remain unexecuted. |
| T11 | 2026-10-01 20:29 UTC | Published environment `52d90166f5995acc332dbeb14945ed26ae32d408`; Debian 13 MariaDB socket VM; pinned source and fixture | Fail | Shipped `sd_restart` replaced the four JVM identities; readiness returned within 60.074 s and earlier retrieved samples remained unchanged. The following real fresh-acquisition request ended at `2026-10-01T20:29:52.813821124Z`; raw retrieval returned a sample at `2026-10-01T20:29:52.823097908Z`, 9.276784 ms later. The unchanged window check refused this response with `Unexpected out-of-window API data`. The observer recorded 163 CA events and 162 resource samples without errors. Original failure and response: `work/m10-vm-run-52d9016/command-00304.json`; console `work/m10-validation/system-52d9016.log`, exit 1. No source correction or window-check relaxation has been applied. T12-T15 and remaining matrix cases did not run; owned IOC/verifier helpers stopped and the VM remains preserved. Diagnosis on 2026-10-01 20:41 UTC reproduced the source bug using the real original IOC and live HTTP retrieval: `to = sample timestamp - 1 ns` still returned that sample; `to = sample timestamp` returned it without upper-bound overflow. Stored-history controls excluded the target at minus 1 ns and included it at its exact timestamp. At pinned source `d8a7813f40083c1bf7148e6c3b7bffd368d70ee0`, `GetEngineDataAction` uses `StreamPBIntoOutput.streamPBIntoOutputStream`, whose lines 50-65 discard fractional seconds and compare epoch seconds; `MergeDedupConsumer` forwards events without a final upper-bound filter. Actual evidence: `work/m10-validation/retrieval-live-upper-bound-3.json` and `work/m10-validation/retrieval-upper-bound.json`. The successful live probe recorded 168 CA events with no observer errors; its owned IOC stopped successfully. No production source or acceptance criteria changed. |
| T12 | Not run | Planned environment above | Pending | none |
| T13 | Not run | Planned environment above | Pending | none |
| T14 | Not run | Planned environment above | Pending | none |
| T15 | Not run | Planned environment above | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Automate real VM installation and runtime tests
Labels: enhancement
GitHub Milestone: 2.0.1
Observed State: OPEN
Observed Labels: enhancement
Observed Milestone: 2.0.1 / #7
Last Compared: 2026-09-30, `gh issue view 56 --repo jeonghanlee/epicsarchiverap-env`; OPEN, enhancement, milestone 2.0.1, assignee jeonghanlee. The live title/body still describe container installation; the revised VM plan is local and has not been projected.


#### M41 - Measure per-component heap needs by archiving load

Origin: 265f580 / M41
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved
GitHub Issue: [#53](https://github.com/jeonghanlee/epicsarchiverap-env/issues/53)
Status: Not started

##### Summary

The 256M heap default ([M22 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md)) is a test default; the available measurements
do not establish a heap recommendation by load. The ansible-provision soak
on epicsarchiverap-env `9eed006`, epicsarchiverap-maven `3c96141d` and Ansible `dca2255` covers 100,
500 and 903 PV stages. The 903 PV stage includes 110 PVs at 10 Hz and eight
waveforms. With `-Xms256M -Xmx256M` on every JVM, the largest sampled ETL
heap was 250.9 MiB. Its ten Full GCs cover the combined interval from the
500 PV stage through the run's end, including fault tests; one occurred
in the 500 PV stage. The other three components had no Full GC in that
interval.

The [heap observation report](reports/heap-soak-20260928.md), committed at
`decff38`, records the supplied figures and their limits. Five-minute
samples do not provide immediate post-GC heap or individual GC pauses,
so this evidence does not meet this work item's completion criteria.
The heap needed may depend on different workloads per component (PV count
and rate for engine, partition size for etl, query span for retrieval);
that relationship remains a hypothesis until measured.

##### Scope

- Measure, per instance, the live set (heap in use right after a GC, not the
  peak), the GC counts and pause times, and the RSS on a disposable VM over a
  load matrix: PV counts (for example 100, 500, 1000 and 2000) at 1 Hz and
  10 Hz from a `softIoc` on the test host, archived in bulk through the mgmt
  BPL, plus one step with a retrieval client. Each step runs long enough to
  cover several ETL passes, with the [M31 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md) test store values
  (`PARTITION_5MIN`) so STS, MTS and LTS are all reached within hours.
- Capture identified GC events using G1 unified GC logging on all four JVMs, including post-GC heap and individual pause durations. Check the shipped JVM-option path before running. Periodic `jstat` may supplement counters but cannot establish immediate post-GC heap or individual pauses.
- From the measurements, write a heap recommendation per load into
  `docs/README.install.md` beside the four-instance memory calculation, as
  the live set times a headroom factor; the factor (2 to 3 is the usual rule
  of thumb) is chosen from the measured GC counts and pause times.

Out of scope: changing the shipped default ([M22 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md)); per-instance heap
variables, unless the measurements show one shared value cannot fit; GC
tuning beyond sizing; production storage sizing.

##### Completion Criteria

- A recorded table of the after-GC heap, GC counts and pause times per
  instance for each load in the matrix, with the epicsarchiverap-env and epicsarchiverap-maven refs and
  the measurement method used.
- The install guide gives a heap per load derived from that table.

##### Dependencies And Decisions

- D31, Decision Date: 2026-09-29. Assigned to 2.0.1; detailed plan remains draft and implementation is not authorized. Earlier assignment decisions below retain their original dates.

- Recorded 2026-09-28 from the owner's direction after the [M22 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md) review of the
  `9eed006` soak figures; not assigned to current work.
- Additional post-GC heap and individual GC pause measurements were requested
  from the Ansible operator on 2026-09-28. Results have not been received;
  no new measurement run is verified here. This historical request remained separate
  from [M8 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md)'s release criteria.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: original draft at epicsarchiverap-env d68f66848e1edc174e76fe77326e941baf58f850, docs/milestone-265f580.md, M41

1. Fix the load matrix, stage durations and concurrent queries during plan acceptance. Capture identified GC events using G1 unified GC logging on every component; periodic `jstat` may supplement RSS and counters but cannot replace event measurements.
2. Run the matrix on a disposable VM and record the measurements.
3. Derive and document the recommendation.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime | Run each load of the matrix with the G1 event logs with optional `jstat` supplements on all four instances; read the stable after-GC heap, the GC counts and pause times, and the RSS | Disposable VM | A complete table per instance and load, tied to the epicsarchiverap-env and epicsarchiverap-maven refs |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Disposable VM | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Measure per-component heap needs by archiving load
Labels: enhancement
GitHub Milestone: 2.0.1
Observed State: OPEN
Observed Labels: enhancement
Observed Milestone: 2.0.1 / #7
Last Compared: 2026-09-30 at 04:34 UTC, `gh issue view 53 --repo jeonghanlee/epicsarchiverap-env`; OPEN, enhancement, milestone 2.0.1, assignee jeonghanlee, updatedAt 2026-09-30T04:33:58Z

#### M44 - Verify and publish release 2.0.1

Origin: 2.0.1 / M44
Identity History: none
GitHub Issue: none
Status: Not started

##### Summary

Produce immutable 2.0.1 release objects from the combined verified patch candidate and verify the actual released installation path.

##### Scope

- Integrated re-runs, production-equivalent installation, version checks, authorized merge/publication, and post-release verification.

Out of scope: another release line, automatic security fixes, changing or deleting 2.0.0 release objects.

##### Completion Criteria

- M43, M14, M10 and M41 complete, G6 resolved, and all required final checks Pass.
- The annotated 2.0.1 tag and GitHub release resolve to the authorized candidate.
- Required issue states and canonical closure agree after publication.

##### Dependencies And Decisions

- M43, M14, M10, M41 and D31. Ant work is release-blocking under the current proposed scope; any deferral or source-contract change requires an explicit decision.
- No source pin is changed during planning. A new epicsarchiverap-maven commit is selected only after G6 is satisfied and the source change is accepted.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Accept this release plan and the work plans, commit the canonical plan, then project issues to GitHub.
2. Complete the ordered work; record actual refs, configuration and evidence for each check.
3. Preserve pre-change checks, write the changelog and prove the combined 2.0.1 candidate.
4. Prepare the exact authorized merge, branch push, annotated tag, tag push and release commands through `git-workflow`.
5. Execute separately authorized actions, verify the released object on clean hosts, reconcile issues and close this cycle.

##### Test Plan

Final checks are owned by Release Verification Plan below; no local T labels apply.

##### Verification Results

Final observations are owned by Release Verification Results below.

##### Closure Evidence

- none

##### Integrated Verification

| Source Check | Re-run Trigger | Shared Surface | Release Verification Label | Expected Result | Result Evidence |
| --- | --- | --- | --- | --- | --- |
| M43 / T1, M43 / T2 | Later Make, install, source schema or DB-helper changes | Backend command routing | Release Verification 2 | Rejections and supported behavior hold on final tree | Pending |
| M14 / T1, M14 / T2 | Later source-pin or overlay changes | Build and installed WARs | Release Verification 2 | Real build retains overlay with no Ant integration | Pending |
| M10 / T1 | Later install, build or configuration changes | Documented installation | Release Verification 3 | Real container/VM installation checks pass | Pending |
| M41 / T1 | Later source pin, JVM options, workload or store changes | Heap recommendation applicability | Release Verification 4 | Repeat affected loads or narrow recommendation to its measured configuration | Pending |

##### Production Environment Tests

| Release Verification Label | Timing | System | Version | Architecture | Deployment Path | Method | Expected Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Release Verification 3 | post-change | Debian; Rocky Linux | 13; 8.10 | x86_64 | Documented prerequisites and eight ordered install targets | Real WAR build, four JVMs, systemd, health timer, HTTP identity, CA acquisition and timestamped retrieval; MariaDB TCP/socket and SQLite cases fixed at acceptance | Installed candidate works on accepted backend matrix | Pending |
| Release Verification 6 | post-release | Debian; Rocky Linux | 13; 8.10 | x86_64 | Clean host using immutable 2.0.1 tag and install guide | Cold real build and installed payload comparison; four JVMs, health timer, HTTP identity, changing PV acquisition and retrieval | Released object runs; evidence records refs, options and backend | Pending |

##### Version Changes

| Field | File | Before | Planned After | Pre-check | Pre-check Label | Post-check | Post-check Label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Changelog release heading | CHANGELOG.md | Newest dated release 2.0.0 | One dated 2.0.1 heading above preserved 2.0.0 | Read committed heading and working-tree diff | Release Verification 1 | Check date, uniqueness and actual shipped scope | Release Verification 4 |
| SRC_TAG | configure/RELEASE | d8a7813f40083c1bf7148e6c3b7bffd368d70ee0 | Exact commit accepted after G6; unresolved | Resolve committed Make value and source identity | Release Verification 1 | Resolve effective pin, build refs and source changes | Release Verification 4 |

The source POM belongs to epicsarchiverap-maven. This cycle does not independently bump it. APPNAME, SRC_VERSION and install-path derivation remain checked for consistency; no environment numeric version field has been identified beyond the changelog and release objects.

##### Release Execution

| Step | Action | Authorization | Expected Result | Evidence |
| --- | --- | --- | --- | --- |
| 1 | Planning and candidate commits on release-2.0.1 | Separate Commit/add scope | Only reviewed files committed | Pending |
| 2 | Publish release-2.0.1 branch | Separate Push scope | Same-named branch and upstream verified | Pending |
| 3 | Merge verified release-2.0.1 into maven | Exact preview and separate Release authority | Reviewed merge commit becomes release candidate | Pending |
| 4 | Publish maven candidate | Separate Push scope or exact authorized release sequence | Remote candidate equals local | Pending |
| 5 | Create annotated tag 2.0.1 on merge candidate | Exact preview and separate Release authority | Immutable tag object recorded | Pending |
| 6 | Publish refs/tags/2.0.1 | Separate Tag push scope | Remote tag object and peeled candidate match | Pending |
| 7 | Create GitHub release 2.0.1 with reviewed notes | Exact preview and separate Release authority | Published non-prerelease object references tag | Pending |
| 8 | Reconcile issues and close GitHub milestone 2.0.1 | Issue scope for issues; milestone close requires separately authorized exact release sequence or user execution | Required issues closed and milestone closed | Pending |
| 9 | Record canonical closure and next entry point | Separate documentation and commit/push authority | Checked closure published; next release unassigned | Pending |

##### Release Verification Plan

| Label | Layer | Timing | Method | Environment | Expected Result | Evidence Target |
| --- | --- | --- | --- | --- | --- | --- |
| Release Verification 1 | Baseline | pre-change | Record current epicsarchiverap-env commit, effective source pin, changelog and existing released refs before candidate version changes | Checkout and origin | Reproducible pre-change baseline | Private evidence with public hashes |
| Release Verification 2 | Integrated | post-change | Execute shipped local suite, M43 routing/DB checks and real M14 build on combined candidate | Supported local toolchain and disposable DBs | No failed or required skipped check | Suite/build logs and payload hashes |
| Release Verification 3 | Deployment | post-change | Run real M10 installation and runtime entrypoints on accepted matrix | Debian 13 and Rocky 8.10 | Actual installed system, acquisition and retrieval succeed | Install/runtime evidence |
| Release Verification 4 | Candidate | post-change | Resolve changelog/source versions and verify M41 measurements apply to final refs; rerun invalidated measurements | Candidate and measured workload | Consistent 2.0.1 candidate and bounded heap guidance | Version and measurement evidence |
| Release Verification 5 | Published objects | post-release | Read origin tag object/peeled commit and GitHub release flags/notes | origin and GitHub | Objects match recorded authorized candidate | Remote observations with time |
| Release Verification 6 | Released installation | post-release | Execute documented clean installation and runtime checks from immutable tag | Clean Debian 13 and Rocky 8.10 hosts | Actual released system succeeds on accepted matrix | Private install/runtime evidence and hashes |
| Release Verification 7 | Closure | post-release | Compare canonical rows/details, GitHub issues/milestone, published closure and next entry | Canonical document, origin and GitHub | Scope complete, evidence coherent, 2.0.0 unchanged, next release unassigned | Dated closure observations |

##### Release Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| Release Verification 1 | Not run | Planned environment above | Pending | none |
| Release Verification 2 | Not run | Planned environment above | Pending | none |
| Release Verification 3 | Not run | Planned environment above | Pending | none |
| Release Verification 4 | Not run | Planned environment above | Pending | none |
| Release Verification 5 | Not run | Planned environment above | Pending | none |
| Release Verification 6 | Not run | Planned environment above | Pending | none |
| Release Verification 7 | Not run | Planned environment above | Pending | none |

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DB | M42 | Apply backend selection to all database operations | Carry-forward | Deferred | No | M43, D29, D31 | Every generic DB operation uses the selected backend; unsupported operations fail before contacting another backend; deferred 2026-09-28; [detail](#m42---apply-backend-selection-to-all-database-operations) |
| UI | M13 | Site skin aligned with the rewritten mgmt UI | Milestone | Open | No | | Define the target interface and required epicsarchiverap-env skin changes; [detail](#m13---site-skin-aligned-with-the-rewritten-mgmt-ui) |
| Storage | M27 | LTS retrieval pre-processing (`pp`) | Milestone | Open | No | D21 | Decide from operating experience whether `pp` on LTS earns its disk cost; [detail](#m27---lts-retrieval-pre-processing-pp) |

### Backlog Details

#### M42 - Apply backend selection to all database operations

Origin: 265f580 / M42
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved
GitHub Issue: none
Status: Deferred

##### Summary

`DB_BACKEND` selects the appliance JDBC resource and MariaDB service dependency,
but does not consistently select epicsarchiverap-env's database commands. At `46faeb9`,
`configure/RULES_SQL` switches schema generation, loading and table listing;
table deletion and the four application-table queries still invoke
`scripts/mariadb_setup.bash`. All `db.*` commands remain MariaDB-specific.
An unrecognized backend falls through to MariaDB in the SQL rules, while
`conf.context` and `conf.systemd0` reject it. At that earlier commit, the
MariaDB application-table query also hardcoded
`archappl` in `show_archappl`. The 2026-09-28 correction authorized after the
whole-repository review makes it honor `DB_NAME`, exports `JDBC_DB_NAME` as
`ARCHAPPL_DB_NAME` for the JNDI lookup, and makes admin removal honor
`DB_ADMIN`. These identity corrections do not implement backend isolation.

The 2.0.0 correction rejects SQLite and invalid backend values at
`sql.drop` and `sql.table.drop`. M43 now verifies the broader isolation guards
in commit 3560216: SQLite db.* skips, while unsupported SQL/query/helper
operations and invalid selectors reject before side effects. SQLite deletion,
application-table queries, lifecycle, backup and restore remain this row's
deferred scope.

##### Scope

- Inventory every public database operation, including `sql.*`, `db.*`,
  `PVRequests.show`, `DataServers.show`, `PVAliases.show`, `PVTypeInfo.show`,
  and the setup script's query, backup and restore entrypoints.
- Make generic operations consistently select MariaDB over TCP or a Unix
  domain socket, or the SQLite file at `ARCHAPPL_SQLITE_FILE`. Validate the
  backend before any configuration write, database connection or deletion;
  an unknown value must never fall through to MariaDB.
- Implement SQLite table deletion and application-table queries against the
  source repository's shipped schema. Specify handling of associated triggers,
  missing databases, file ownership, WAL files and active appliance connections.
- Define backend-specific behavior for database creation, removal, inspection,
  backup and restore. MariaDB account and server administration have no SQLite
  equivalent: make the command boundary explicit and return a clear error for
  unsupported operations without contacting MariaDB under SQLite selection.
- Keep database identity consistent across Make, generated configuration,
  helper scripts and JDBC. Honor `DB_NAME` on MariaDB and the configured file
  on SQLite; define how stale generated configuration is detected or refreshed.
- Align the install procedure, command documentation and tests with that
  behavior, including when MariaDB configuration generation is unnecessary.

Out of scope: automatic data migration or replication between engines,
application schema redesign, PV archive-file deletion, and DB performance
tuning. The current deletion guard is a partial safeguard, not completion of
this work.

##### Completion Criteria

- Every inventoried entrypoint has documented behavior for both supported
  backends and for invalid selection; no generic command contacts the
  unselected backend.
- SQLite supports schema load, table listing, all four application-table
  queries, table deletion and reload using the shipped schema. MariaDB retains
  those operations over both TCP and its Unix domain socket.
- Database lifecycle, backup and restore follow the documented backend policy;
  unsupported operations and client failures return nonzero status.
- Disposable-database tests verify the selected database's result and that the
  other database's schema and rows remain unchanged, including deletion tests.
- The install and operator documentation describes the same behavior as the
  commands, with no unconditional MariaDB step in the SQLite procedure.

##### Dependencies And Decisions

- D31. Backend isolation guards move to M43 for 2.0.1. This row retains the full SQLite operation, lifecycle, backup and restore expansion; M43 does not close it.

- [M9 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md) supplies the installed backend selection and source schemas.
- D29, Decision Date: 2026-09-28. Full work remains deferred. The initial
  authorization covered the `sql.drop` / `sql.table.drop` safeguard.
- Decision Date: 2026-09-28. The subsequent whole-repository review correction
  additionally covers password preservation, runtime DB-name propagation,
  application-table DB selection and configured admin removal. It does not
  authorize the full backend matrix; M42 remains Deferred. A new dated
  decision is required to return it to Not started.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the operation matrix and database lifecycle policy, including the
   MariaDB-only administration boundary and standalone script invocation.
2. Apply shared backend validation and route generic operations to the matching
   client and database identity. Implement missing SQLite operations.
3. Align documentation and exercise the complete matrix on disposable databases
   using the shipped rules, scripts and source schemas.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Command routing | Run every entrypoint with both backends, both local configuration locations, command-line overrides and invalid values | Isolated epicsarchiverap-env checkout and disposable databases | Selected client and identity agree; invalid or unsupported operations fail before side effects |
| T2 | Database integration | Load the shipped schemas, insert records, query all four tables, drop tables and reload through real targets | SQLite and MariaDB over TCP and Unix domain socket | Expected schema and rows in the selected database; unselected database unchanged |
| T3 | Database lifecycle | Exercise creation, removal, backup and restore, including a non-default name or file, WAL mode and defined active-connection handling | Disposable databases under the service account | Documented lifecycle and ownership; backup restores the expected rows; failures propagate |
| T4 | Deployment | Follow the documented sequence for each backend and exercise the appliance configuration database | Debian 13 and Rocky Linux 8 disposable VMs | JDBC, helpers and service dependencies use the selected backend consistently |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Isolated epicsarchiverap-env checkout and disposable databases | Pending | none |
| T2 | Not run | SQLite and MariaDB over TCP and Unix domain socket | Pending | none |
| T3 | Not run | Disposable databases under the service account | Pending | none |
| T4 | Not run | Debian 13 and Rocky Linux 8 disposable VMs | Pending | none |

##### Closure Evidence

- none
#### M13 - Site skin aligned with the rewritten mgmt UI

Origin: 265f580 / M13
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved
GitHub Issue: none
Status: Open

##### Summary

The management web interface rewrite moved to the EPICS-Arche repository
(the post-Phase-2 runtime, per D11). The epicsarchiverap-env repository carries only the
site-specific skin (`site-template/siteid`: css, img, `template_changes.html`)
copied into the WAR. While the appliance stays on WARs (Phase 2) the skin is
unchanged; it is revisited only if EPICS-Arche replaces the mgmt UI.

##### Scope

- `site-template/siteid/{css,img,template_changes.html}` and the
  `copy.sitespecific` step in `configure/RULES_SRC`.

Out of scope: the interface itself (EPICS-Arche).

##### Completion Criteria

- After planning defines the EPICS-Arche interface and epicsarchiverap-env's role, the
  resulting skin renders correctly on that interface. The current WAR skin
  remains unchanged until that scope is defined.

##### Dependencies And Decisions

- Decision Date: 2026-09-29. Transferred from Milestone to Backlog for the 2.0.0 cycle close. Existing status, scope, dependencies, plan and verification evidence are preserved; no next release is assigned.
- Decision Date: 2026-09-22. Assigned from Backlog to Milestone. The target interface and the role of the epicsarchiverap-env skin remain to be defined. Status stays Open; assignment alone does not accept or authorize implementation.
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

#### M27 - LTS retrieval pre-processing (`pp`)

Origin: 265f580 / M27
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved
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

- Decision Date: 2026-09-29. Transferred from Milestone to Backlog for the 2.0.0 cycle close. Existing status, scope, dependencies, plan and verification evidence are preserved; no next release is assigned.
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
