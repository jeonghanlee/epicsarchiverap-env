# Work Register

Release line: 2.0.1
Milestone index: 2.0.1
Canonical path: `docs/milestone-2.0.1.md`
Canonical branch or ref: release-2.0.1
Git upstream: origin/release-2.0.1
Remote tracker: [GitHub milestone 2.0.1 / #7](https://github.com/jeonghanlee/epicsarchiverap-env/milestone/7), observed OPEN on 2026-09-30 at 04:34 UTC via `gh api repos/jeonghanlee/epicsarchiverap-env/milestones/7`

Next session entry point: the full accepted matrix passed on 2026-10-05 in the M10 run on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770` (all eight cases, independent cleanup PASS, `--verdict` PASS); commit and publish this record, then project the results to #56 and handle its closure under separate issue authority, which is the last open M10 completion criterion. M46 / T3 stays Partial: the verifier does not retain the `STARTING` window of a passing restart, and the deadline failure for a persistent wrong executable is covered only locally. cloud-provision plans to rename the `archiver-dev` species to `archiver-dev-uds` and its inventory group to `archiver_dev_uds`; the next run after that needs a matching ansible-provision pin and driver configuration. M45 (#58) is Not started and Ready under D38; G7 and G8 are Complete; its plan is draft. M41 remains Backlog under D37; M14 remains Blocked on G6.

## Scope

The 2.0.1 patch cycle covers backend isolation safeguards, removal of obsolete Ant integration after the source contract is confirmed, real installation test automation. Heap measurement and guidance are excluded under D37 and retained in Backlog. The owner assigned these four candidates on 2026-09-29. D38 adds M45 on 2026-10-04, and the owner added M46 on 2026-10-04. The current proposed order is M43, M14, M10, then M44. G6 may be investigated while M43 is planned; its completion gates M14 and release readiness. The release sequence and remaining detailed plans await acceptance; M43 is accepted under D32.

Out of scope: adding SQLite deletion, table-query, backup or restore support; changing the shipped heap default; UI skin changes; LTS pre-processing; data migration. Existing 2.0.0 release objects remain immutable. No next release after 2.0.1 is assigned.

Baseline: epicsarchiverap-env `d68f66848e1edc174e76fe77326e941baf58f850`, published 2.0.0 tag commit `386c91d74086313efe04e0b64eb5dacfd91f8389`, epicsarchiverap-maven pin `d8a7813f40083c1bf7148e6c3b7bffd368d70ee0`. Prior release results are historical evidence and do not satisfy 2.0.1 checks. Backend isolation work is Complete; VM test implementation is In progress and real runtime acceptance remains Pending.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DB | M43 | Reject operations on an unselected database backend | Milestone | Complete | No | D31, D32 | SQLite db.* skips; unsupported and invalid selections stop before configuration writes or DB contact; [detail](#m43---reject-operations-on-an-unselected-database-backend) |
| Gate | G6 | epicsarchiverap-maven lands Ant removal with the per-site build contract | External gate | Open | No | | Exact usable source commit and overlay contract confirmed; [detail](#g6---epicsarchiverap-maven-lands-ant-removal-with-the-per-site-build-contract) |
| Build | M14 | Remove Ant leftovers from epicsarchiverap-env | Milestone | Blocked | No | G6, D31, D33 | After Maven stabilization, four real WARs retain generated site content through the Maven-only build; [detail](#m14---remove-ant-leftovers-from-epicsarchiverap-env) |
| Tests | M10 | Automate VM installation and runtime tests | Milestone | In progress | No | M46, D31, D34, D39 | Composed provisioning/install and independent acceptance pass for all accepted OS/backend cases; [detail](#m10---automate-vm-installation-and-runtime-tests) |
| Health | M46 | Report a starting instance distinctly in the launcher health check | Milestone | In progress | No | D40, D41, D42 | A launcher-started PID that has not yet executed Java reports a starting state, not `wrong-java-executable`, and the VM verifier waits on it; [detail](#m46---report-a-starting-instance-distinctly-in-the-launcher-health-check) |
| D41 | Write new tests in Bash and keep Python tests to the minimum that testing Python code requires, because Python versions differ across the supported systems and Python test code needs rewriting as the language changes. Converting the existing Python tests to Bash is the long-term direction and is not scheduled. | 2026-10-04 |
| D42 | Specify the launcher health starting verdict: `STARTING` exits 1, the status that FAIL uses, and is told apart by its output token; the time bound is `ARCHAPPL_HEALTH_STARTING_SECONDS` with a default of 10 seconds, which must stay below the scheduled health startup allowance of 60 seconds. The owner accepted the recommended values. The default is provisional until the VM run records the real window. | 2026-10-04 |
| Gate | G7 | ansible-provision reports the exact cause of the Rocky 8.10 journald gap | External gate | Complete | No | D38 | Cause established as a systemd 239 reader defect; the reproducer and scanner are shared for M45 / T1; [detail](#g7---ansible-provision-reports-the-exact-cause-of-the-rocky-810-journald-gap) |
| Gate | G8 | epicsarchiverap-maven reports the exact cause of the CAJ search-port defect | External gate | Complete | No | D38 | Socket reproducer and engine-start counts confirm or refute the shared-port mechanism; [detail](#g8---epicsarchiverap-maven-reports-the-exact-cause-of-the-caj-search-port-defect) |
| Tests | M45 | Contain the journalctl reader and CAJ search-port defects in VM acceptance | Milestone | Not started | Yes | G7, G8, D38, D39 | T8 exposure to hidden journal entries is measured, failures carry classifying evidence, and T8 is revised only if exposure is found; [detail](#m45---contain-the-journalctl-reader-and-caj-search-port-defects-in-vm-acceptance) |
| Release | M44 | Verify and publish release 2.0.1 | Milestone | Not started | No | M43, M14, M10, D31, D37 | Released objects and required post-release checks pass; [detail](#m44---verify-and-publish-release-201) |

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
| D35 | Limit heap measurement to the existing 100, 500 and 903 PV workloads, adding event-based post-GC heap and individual pause measurements. Preserve the reported workload and query conditions for comparison. At scope selection, the revised detailed plan remained draft and implementation was not authorized; subsequent plan acceptance is recorded in the detail. | 2026-10-01 |
| D36 | Defer M41 implementation and measurement. Preserve the accepted plan, recovered source evidence and local input-inspection tool. Resumption requires a new dated decision; release assignment and M44 dependencies remain pending a separate scope decision. | 2026-10-01 |
| D37 | Move M41 to Backlog, excluding heap measurement and new heap guidance from 2.0.1 completion requirements. Preserve its accepted plan and evidence. Reassignment requires an environment with sufficient dedicated disk capacity for the complete archive, response and measurement evidence plus shutdown reserves; existing resource stop rules remain applicable. | 2026-10-01 |
| D38 | Split the two independent Rocky 8.10 defects by owner. epicsarchiverap-maven owns the CAJ search-port defect (its #26), ansible-provision owns the systemd 239 journald unlinked-entry gap, and epicsarchiverap-env owns how both reach its VM acceptance checks (M45). Each owner proves the exact cause first, then fixes its own side. Patches stay local; publication and upstream reports are decided after the problem is resolved. A session that needs a VM requests it from cloud-provision directly. | 2026-10-04 |
| D39 | Run M10 acceptance on the latest epicsarchiverap-maven `modernize` commit that carries the current fixes and passes its CI, and keep following newly fixed commits instead of holding an older source. The next run uses `aa953a44bd2e6fb2a299224b97d365e7753a2fd8`, which carries the CAJ correction `7adc7d5a` and passed run 37249019863. The repository source pin `SRC_TAG` in `configure/RELEASE` follows the same commit, so the tested and released source stay equal. | 2026-10-04 |
| D40 | Fix the false `wrong-java-executable` at start in both places: the launcher health reports a starting state for a PID that has not yet executed Java, and the VM verifier waits on that state and on `wrong-java-executable` within its bounded readiness deadline, failing when it persists. The owner chose this for system stability and reliability over the smaller verifier-only change, accepting the larger plan and later M10 run. | 2026-10-04 |

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
| 265f580 / M41 | docs/milestone-2.0.1.md, Milestone | docs/milestone-2.0.1.md, Backlog | this synchronization commit | this synchronization commit; D37, 2026-10-01 |

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

The Phase 3 and Phase 4 entrypoints call the VM driver; the full accepted matrix passed on 2026-10-05 (subsection "VM Acceptance Run On e441d59"). The earlier systemd-free container premise is incompatible with the shipped `make install`: `sd_health_stop`, `sd_install` and `sd_enable` invoke real `systemctl`. Both installation and runtime verification therefore use the same disposable systemd VM. No second VM provisioner or installation implementation is needed here. The test design is in [`docs/README.vmtests.md`](README.vmtests.md).

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
Plan Acceptance: 2026-10-04; owner accepted the VM supply and run structure revision carried by fdbf1eccc6aa0c68553ecb17b9f68d3ece8a3d29, with its design draft in the ignored `work/m10-design/README.vmtests.md`, after four third-person and five second-person passes with all findings applied; the prior plan is re-accepted with the replacements the revision names
Implementation Authorization: 2026-10-04; owner authorized implementation of the accepted revision and its local verification; commit, push, publication, the VM run and every cleanup request require separate authority
Superseded Plan Artifacts: original draft at epicsarchiverap-env d68f66848e1edc174e76fe77326e941baf58f850, docs/milestone-265f580.md, M10; container-install draft carried by dcfa39b3f1a6a457ffd6803cb6c618d601768c30, docs/milestone-2.0.1.md, M10; prior accepted plan state, including the still-current service-inventory revision, accepted and authorized on 2026-10-01 and carried by e799b094b0c20a89664a2fae4901e07954a74a9c, docs/milestone-2.0.1.md, M10; prior accepted plan state, including the still-current Rocky 8.10 compatibility revision, accepted and authorized on 2026-10-02 and carried by f58c3da517d45cd580c8aab82471439ff65b40ab, docs/milestone-2.0.1.md, M10; address selection draft, not accepted, carried by 4a97ae408403ba8c76d6fbc84a6e4794c977a146, docs/milestone-2.0.1.md, M10

###### VM Supply And Run Structure Revision For Review

Dates in this revision are Pacific local dates. The diagnostics and runs recorded below expose five design defects. Apart from the first case of the interrupted full run, every passing VM case at `65cf077b1230f61efdba817aa697483a79a3a5d5` came from guests that cloud-provision created, checked through a private harness that binds the driver's methods to an external guest; the shipped driver can only verify guests it creates itself. Driver-created guests collide with occupied addresses (31 of 95 hashed addresses held by a reservation or lease on 2026-10-03 at 21:30 PDT, recorded in the address selection draft carried by `4a97ae408403ba8c76d6fbc84a6e4794c977a146`) and with stale stored host keys. One driver process runs all eight cases for hours, so an interruption fails the whole run and its completed cases cannot count toward acceptance; the first full run at that candidate failed this way. The tool origin check reads `git remote get-url`, which a common `insteadOf` rule rewrites to SSH form. The design is split between this growing register and `tests/README.md`. Owner direction, Decision Date: 2026-10-03: cloud-provision creates every guest and the driver adopts it from a handoff; each case runs as a separate invocation that appends to one run context; the origin check reads the stored URL; and the design is consolidated into one document. This revision supersedes the unaccepted address selection draft. T5-T14 checks, the fixture, the deadlines and the guest verifier are unchanged. Accepting this revision re-accepts the prior plan with these items and the replacement rows below. It also replaces Implementation Plan items 2, 3 and 9 where they create, shut down or clean up guests through the driver, and the `--system` and `--cleanup` statements of the Phase And Result Contract. In the T15 Assertion Details, "leaving the first case's shut-down VM and DHCP reservation present when the second begins" becomes "leaving the first case's VM and DHCP reservation owned and present, running or shut off, when the second begins". The rest of the plan is unchanged.

1. In `tests/vm/driver.py`, replace `--system`, `--installation`, `--runtime` and `--cleanup` with four operations: `--init --config <file> --evidence <new-dir>`, `--case <case> --handoff <file> <run>`, `--verify-cleanup <run>` and the unchanged read-only `--verdict <run>`. Remove every `create_vm.bash` call (`-F`, `-s`, `-S`, `-c`) from the driver and keep the cloud-provision inventory generator. `--init` keeps the existing preflight, candidate local-suite proof and baseline of domains and live and persistent reservations.
2. Define the guest handoff as a JSON file with `schema`, `os_selector`, `prefix`, `node`, `creation_id`, `uuid`, `vm_name`, `mac`, `address`, `disk`, `seed`, `record` and `tool_ref`. The operator writes it from cloud-provision's private markdown handoff, whose lines carry every field; a JSON handoff emitted by cloud-provision itself is a separate peer request. `--case` derives the VM, disk, seed and record names from the selectors and requires equality with the handoff; requires the UUID to be absent from the baseline and from earlier cases; matches the live domain, single interface, attached disk and seed, creation record, both reservations and the lease; collects shell-only facts; and requires a fresh guest through one `sudo -n sh -c` probe: cloud-init done without errors, none of the configured source, install and store roots or `/usr/local/sbin/archiver-build.sh` and `/var/tmp/archiver-build.done` present, a successful service unit-file listing and no unit name starting with `epicsarchiverap`, `archiver-build`, `mariadb` or `mysql`. It then runs the existing installation, build proof, transfer and guest verifier sequence, or the build-failure path, and stops its own helpers. It records whether earlier cases' guests remain owned and present when it starts. Each invocation locks the run; a recorded case failure is permanent and a case name cannot be run twice. Case order does not matter; the verdict requires each `MATRIX` case exactly once instead of the current exact-order comparison. By owner direction, Decision Date: 2026-10-04, `--case` copies the host key that cloud-provision stored for the guest address in `~/.ssh/known_hosts` into a per-guest known-hosts file before the first guest connection, refuses the handoff when no key is stored, and runs SSH and Ansible with strict host key checking against that file, as ansible-provision does for its guests.
3. Keep the interruption and cleanup-refusal checks on the first positive case. The refusal checks invoke `--verify-cleanup` on missing and mismatched ownership contexts and require refusal with unchanged state. `--verify-cleanup` keeps the existing removal and baseline-preservation inspection; the cleanup itself is a separate request to cloud-provision. By owner direction, Decision Date: 2026-10-04, an inspection error during `--verify-cleanup` returns 77 without recording a failure, so the verification can run again.
4. Read each tool checkout's stored `remote.origin.url` and require HTTPS without credentials; keep the published-commit proof through the HTTPS clone.
5. In `tests/run-all-tests.bash`, forward `--init`, `--case`, `--verify-cleanup` and `--verdict` to the driver. `--system`, `--phase=3`, `--phase=4` and `all` perform no VM operation and no local phase, name the four operations and exit 77; by owner direction, Decision Date: 2026-10-04, they do not run the local phases, because the local suite's `database-config.py` contract test invokes `--system` and must observe an immediate 77 without a pass. `tests/phase3-docker.bash` and `tests/phase4-vm.bash` keep exit 77 without arguments and forward arguments to `--case`. Local modes stay unchanged and contact no VM; update the existing entry point regressions to this behavior. Add `tests/vm/local.py` regressions for each operation's input refusals, handoff validation with real files, the origin check with real `git` under an isolated global configuration that contains an `insteadOf` rule, refusal to rerun or replace a case, and read-only verdict rules.
6. Add the design document `docs/README.vmtests.md`; its draft, kept in the ignored `work/m10-design/README.vmtests.md`, is reviewed with this revision and moved and committed with the implementation so that it matches the code. Reduce `tests/README.md` to execution and evidence procedures that link to it, and link this detail to it.
7. Run the full `tests/run-all-tests.bash --local` without skips. After separately authorized publication, run `--init`, the eight cases on cloud-provision guests one at a time, cloud-provision cleanup on request, `--verify-cleanup` and `--verdict` on one run context. Existing run contexts stay bound to their driver digests and are not resumed. Their owned resources and the diagnostic guests are removed by cloud-provision on a separate request and inspected with the driver commit that created each context, or by a recorded manual inspection for guests outside any context; none of them enters a run of the revised driver.

###### VM Supply And Run Structure Test Plan

These rows replace the T1, T3 and T15 methods of the Test Plan, and the Fresh VM and Explicit cleanup rows of Repository Responsibilities, once accepted.

| Check | Real Path And Environment | Expected Result |
| --- | --- | --- |
| T1 | `--init`, eight `--case` invocations, cloud-provision cleanup on request, `--verify-cleanup` and `--verdict` on one run context | Before verified cleanup: 77; after it: 0 only with every required check, lifecycle check and cleanup postcondition; recorded failures remain failures |
| T2 / operations | Shipped CLI with missing, invalid and conflicting inputs; real files in isolated directories; no VM | Refusal with 2 or 77 before any external action; no context created or changed |
| T2 / handoff | Shipped validation with real handoff files | Missing fields, derived-name mismatches and baseline UUIDs are refused |
| T2 / origin | Real `git` with an isolated global `insteadOf` rule and stored HTTPS origins | Stored HTTPS origins pass; SSH or credential-bearing stored origins are refused |
| T2 / run rules | Shipped context handling and verdict on constructed contexts | A second invocation of a recorded case is refused; verdict stays read-only |
| T3 | Handed-off fresh guest from cloud-provision | Handoff, live identity, baseline exclusion, facts and freshness match; Ansible limited to that guest |
| T15 | Guests retained across cases; cleanup by cloud-provision on request; `--verify-cleanup` | Earlier guests stay owned when later cases start; every owned resource absent and every baseline entry preserved; refusal checks leave state unchanged |

| Step | Owner | Input | Required Output And Next Condition |
| --- | --- | --- | --- |
| 2. Fresh VM | cloud-provision | Request with OS selector and resources | Fresh guest and its handoff; no address collision or stale host key |
| 8. Explicit cleanup | cloud-provision on request; verified by epicsarchiverap-env | Owned resource list from the run context | Removal by cloud-provision; independent removal and preservation proof by `--verify-cleanup` |

###### Rocky 8.10 Compatibility Revision For Review

Dates in this revision and its diagnostics are Pacific local dates; clock times are PDT (UTC-7). Two shipped harness defects stop every fresh Rocky 8.10 case at published environment `607092b962afd9cbac31ce9f62efba0e7c62b471`, including the build-failure case, because the facts command runs before installation; evidence is in the Rocky 8.10 socket diagnostic below. The fresh base image provides no `python3`, so the driver's pre-installation facts command exits 127; the interpreter available before installation, `/usr/libexec/platform-python`, is Python 3.6.8 and rejects the command's `text=` argument. The verifier passes `journalctl --since` an ISO 8601 timestamp with an offset, which systemd 239 rejects. On 2026-10-02 at 18:17 PDT, read-only queries accepted `@<epoch seconds>` and `YYYY-MM-DD HH:MM:SS UTC` on both the Rocky 8.10 guest (systemd 239) and a Debian 13 guest (systemd 257). Owner direction, Decision Date: 2026-10-02: replace the Python facts command with shell-only collection, and convert the journal bound to whole epoch seconds with the IEEE 754 `roundToIntegralTowardPositive` operation. T10-T13 have not yet run on Rocky 8.10; a further incompatibility found there requires its own revision. Accepting this revision re-accepts the unchanged prior plan with these four items added; nothing else in the plan changes.

1. In `tests/vm/driver.py`, replace the pre-installation Python facts command with one shell command that prints delimited sections from `/etc/os-release`, `getconf _NPROCESSORS_ONLN`, `hostname`, `ip -j address`, `/proc/meminfo` and `stat -f -c '%S %b %a' /` (fundamental block size, total data blocks, free blocks available to non-superuser). `getconf _NPROCESSORS_ONLN` reports the same online-processor count as the current `os.cpu_count()`, whereas `nproc` follows CPU affinity and `OMP_NUM_THREADS`. Parse the sections on the host into the existing `guest_resources` fields, with root bytes as `%S × %b` and free bytes as `%S × %a`. Keep the hostname, interface, OS release, CPU and free-space checks unchanged, and reject a missing or malformed section. Factor the command and parser into module functions so the local regression executes the shipped text.
2. In `tests/vm/guest.py`, derive the scheduled-health journal bound as `@` followed by the current epoch time in whole seconds, converted with the IEEE 754 `roundToIntegralTowardPositive` operation (ceiling). Compute it from integer nanoseconds from `time.time_ns()` rather than the binary64 `time.time()` value, so the conversion is exact. The bound is therefore at or after the original instant, and no earlier journal entry can count; the eligibility rules and the timer interval are unchanged. Factor the conversion into a module function.
3. In `tests/vm/local.py`, run the shipped facts command through the real local shell with a `PATH` containing only the real tools it names and no Python interpreter; parse the real output and compare CPU count, hostname and root size with the local system. The earlier command, which resolves `python3` through `PATH`, fails this test; before replacing the command, run the new test against the earlier command and record its failure. Remove one section from the real output and confirm that the shipped parser rejects it. Run the shipped journal-bound function against the real local `journalctl` and check the conversion at whole and fractional seconds. Local systemd accepts the earlier ISO form, so this test cannot reproduce the systemd 239 rejection; only a real Rocky 8.10 run verifies the journal-bound correction.
4. Run the full `tests/run-all-tests.bash --local` without skips. Review this revision before code changes; commit, push and publication require separate authority. The published correction is a new candidate: no earlier diagnostic verifies it, and the re-verification scope across Debian, Rocky and the full driver remains an owner decision before execution.

###### Rocky 8.10 Compatibility Test Plan

| Check | Real Path And Environment | Expected Result |
| --- | --- | --- |
| T2 / shell facts | Shipped facts command and parser; real local shell and tools; `PATH` without any Python interpreter | Exit 0; parsed CPU count, hostname and root size equal the local observations; a missing section is rejected |
| T2 / journal bound | Shipped conversion; real local `journalctl --since` | Whole seconds stay unchanged, any fractional second converts toward positive and the real command exits 0; systemd 239 behavior is not claimed |
| T3 / Rocky 8.10 | New published candidate; fresh Rocky 8.10 base guest before Ansible | Shipped facts collection passes without `python3` and the existing identity, OS and resource checks pass |
| T8 / Rocky 8.10 | Same candidate; shipped `guest.py runtime` on systemd 239 | Journal query exits 0 and three distinct eligible health invocations are observed |
| T3-T12 / regression | Same candidate on Debian 13 and the remaining Rocky 8.10 cases, scope selected by the owner | Previously passing assertions still pass with unchanged bounds and fixture |

###### Service Inventory Revision For Review

The SQLite absence check must distinguish an absent database service from an unavailable or unreadable service inventory. The selected-unit query can exit 1 when no unit matches; that result alone cannot establish either a provisioning failure or successful absence verification.

1. In `tests/vm/guest.py`, enumerate all installed service unit files with real `systemctl list-unit-files --type=service --full --no-legend --no-pager`. Require command exit 0, structurally valid rows and the installed appliance unit in the inventory. An empty or incomplete inventory cannot prove absence.
2. Reject any installed `mariadb.service`, `mysql.service` or `mysqld.service`, including disabled, static, masked and alias entries. Keep the independent effective dependency check and service-account SQLite schema query. Retain the exact command, status, stdout, stderr and parsed inventory.
3. In `tests/vm/local.py`, exercise the shipped inventory helper using the real systemctl binary against isolated unit-file roots. Cover normal absence, each forbidden name/state, missing appliance inventory and a real invalid-root command failure. These are filesystem-level regressions; they do not verify guest provisioning, SQL or runtime integration.
4. Review the revised plan and draft code. Do not start a new VM matrix or alter retained run contexts before the review and revised execution authorization. Commit/push remain separate operations.
5. After approval and candidate publication, use a new evidence directory and the published revised environment commit with the exact corrected source commit. Run the full six positive cases and both real build-failure cases through the existing driver, preserving accepted resources, deadlines, original IOC fixture and raw inclusive retrieval bounds. Prior partial passes cannot complete this new combined candidate.
6. Request cleanup separately only after evidence review. Confirm real owned-resource removal and preservation of the run-start baseline before the read-only final verdict. Preserve earlier failures permanently.

###### Revised Inventory Test Plan

| Check | Real Path And Environment | Expected Result |
| --- | --- | --- |
| T2 / database service absent | Shipped `sqlite_service_units`; real `systemctl --root`; isolated root containing the appliance unit | Exit 0 inventory, appliance present, forbidden names absent; helper passes |
| T2 / database service present | Same helper and binary; each forbidden name as static, disabled, masked and alias unit-file fixtures | Helper rejects every name/state; presence cannot pass because the service is inactive |
| T2 / incomplete inventory | Same path; root containing a different valid service but no appliance; also a completely empty service root | Both rejected; command failure and missing appliance remain distinguishable |
| T2 / query failure | Same path; a nonexistent root passed to the real systemctl binary | Nonzero command status rejected; actual stderr and exit status retained |
| T6 / real guest backend | New published-candidate Debian 13 and Rocky 8.10 SQLite installs through the unchanged driver/species | Actual service-account SQL and effective dependencies pass; real complete service inventory confirms appliance presence and MariaDB-family absence |
| T1, T3-T15 / combined candidate | All six positive and two negative real VM cases, original fixture, fixed bounds, new context, separately requested cleanup | Complete retained matrix and independent cleanup evidence; no previous partial result or filesystem regression substitutes for VM acceptance |

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

T1 retains the cumulative system-run identity; T2-T15 make its required observations explicit. The six positive installation cases require T3-T12. The two SQLite positive cases additionally require T13 runtime-negative checks. The two dedicated build-failure cases require T3 and T14; they do not require successful installation or T4-T12. T15 covers resource preservation and cleanup for every case. No acceptance row can be marked Pass from code inspection alone.

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | System | Run shipped `tests/run-all-tests.bash --system`; retain its context; separately request driver cleanup, then evaluate the final verdict | All six accepted positive cases and both OS negative cases | Before cleanup: INCOMPLETE/77 with retained results; after actual cleanup: T2-T15 evidence complete, no required skip/failure and final verdict exit 0 |
| T2 | Local preflight | Execute real entrypoints with missing tool paths, invalid normal candidate refs, invalid case/context and unsupported arguments; check distinct normal/fault-ref inputs; run `--local` | Isolated local checkout; no VM credentials/resources | Invalid/missing normal inputs exit 2 or 77 before external action; a fault ref cannot bypass normal preflight or enter a positive case; valid local suite preserves its verdict without guest contact/provisioning |
| T3 | VM lifecycle | Call actual cloud creation/readiness and inventory generator; inspect guest OS, cloud-init and identity | Fresh per-case VM | New recorded domain/disks; SSH and cloud-init ready; exact target limit; existing resources unchanged |
| T4 | Real installation | Apply pinned species with explicit appliance refs; observe build unit, source HEADs, Maven log and actual installation | Six positive installation cases only | Eight real Make steps succeed; both HEADs equal requested commits; no stale sentinel/ref/default can pass; dedicated build-failure cases use T14 instead |
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
- For SQLite cases only, T6 service inventory requires exit 0 from the full real service listing, the installed appliance unit and no `mariadb.service`, `mysql.service` or `mysqld.service` entries in any install state. MariaDB socket and TCP cases use their selected database service and are not subject to this absence check. Missing-unit filtered-query exit 1 is not used as an absence verdict. Command failure or incomplete inventory fails the check; retain raw evidence.
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

- `tests/vm/driver.py` opens a run with `--init`, adopts one cloud-provision guest per `--case` invocation from a JSON handoff after read-only identity, ownership, disk capacity, stored host key and freshness checks, runs the pinned Ansible species and the guest verifier, and evaluates the run with `--verify-cleanup` and the read-only `--verdict`. It creates, stops and deletes no guest. Implemented in `9dcf72996d10a6fd3c1d3712088900c0ac6fce1d`; the design is `docs/README.vmtests.md`. `tests/vm/guest.py` checks the real artifacts, database, JVMs, scheduled health, HTTP and original IOC/retrieval/persistence paths.
- `tests/run-all-tests.bash` forwards the four operations, and the compatibility entry points `tests/phase3-docker.bash` and `tests/phase4-vm.bash` forward to `--case`; `tests/vm/config.example.json` and `tests/README.md` define explicit inputs and operator commands. `tests/vm/local.py` runs in Phase 1 without virtualization.
- Local verification does not satisfy the accepted real VM matrix. Full candidate publication and explicit checkout/image/key/fixture/binary inputs are required before VM execution; the driver refuses a published candidate whose harness bytes differ from the executing implementation.
- Handoff selectors must derive exactly the recorded VM and file names, and a case is recorded only after every read-only check passes; a refused handoff leaves the run record unchanged. Cleanup is a cloud-provision action on request. `--verify-cleanup` independently confirms that every owned domain, disk, seed, creation record and reservation is absent and that the run-start baseline is preserved; it returns 77 and records nothing while a resource remains or an inspection fails. Original failures remain failures.
- The original fixture commit and SHA256 are enforced, including SHA256 `85778e0ed007ef196ab963a582c9ba7ddbff96bf68e91edab118d1e9ff497e32`, re-derived from the actual committed file. System/installation preflight executes the published candidate's full local suite once; final evaluation requires the matching candidate, exact command, exit 0 and retained output digest rather than a CLI-only result.
- The IOC prefix derives twelve SHA256 hexadecimal characters from the creation ID. Before processing starts, the real IOC must load every original fixture record and report no database loading error. Candidate local checks use the verified candidate source checkout at the expected source path; shell `[SKIP]` and nonzero unittest `skipped=N` counts prevent both preflight and final acceptance through the same completeness check.

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `work/m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: `--init` passed, all eight `--case` invocations passed, cloud-provision removed the eight guests, `--verify-cleanup` returned PASS and `--verdict` returned PASS (exit 0). Evidence: `work/m10-validation/e441d59-run-verify-cleanup-20261005T145533Z.log`, SHA256 `ba6c1ca0135a73539dcaff27a3a9d5e36ec198413b776db9dda765c1bf33aa03`; `work/m10-validation/e441d59-run-verdict-20261005T145533Z.log`, SHA256 `c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431` Earlier, `work/m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: `--init` passed, three Debian 13 positive cases passed, and `rocky8-socket` failed at T11, so the run holds a failure and four cases did not run (subsection "VM Acceptance Run On f8c457e"). Earlier: Executed the previous shipped `tests/run-all-tests.bash --system`; both unchanged system-phase stubs reported unimplemented checks and the runner exited 77. No installation/runtime acceptance ran. This is the pre-implementation observation, not a result of the new workflow. |
| T2 | 2026-10-04 03:09 PDT | Local Debian 13; real CLI entrypoints | Pass | Latest: the full `--local` suite on the implemented bytes exited 0 without skips (Phase 1 223/0, health 20, database 10, VM local 26, Phase 2 13/0), and the published candidate's own suite passed inside `--init` at 15:42 PDT (subsection "VM Supply And Run Structure Local Verification"). Earlier: Full `tests/run-all-tests.bash --local` exited 0 outside the socket-restricted sandbox: Phase 1 223/0, Phase 2 13/0, health 20, database 10 and VM CLI 10 tests passed without skips. The two added CLI regressions reject noncanonical fixture identities and changed lifecycle selectors before external commands. Bash/Python syntax and `git diff --check` passed; ShellCheck warning gate passed, with only the existing SC1091 info finding in its inventory. Console evidence: `work/m10-validation/review-fixes-local.log`. A separate actual environment checkout with its candidate source linked at the expected path ran the current full local suite on 2026-10-01 03:53 UTC with exit 0 and no skips (Phase 1 223/0, Phase 2 13/0; health 20, database 10 and VM CLI 10 tests); evidence: `work/m10-validation/candidate-source-local.log`. On 2026-10-01 05:11 UTC, the corrected full local suite exited 0 without skips (Phase 1 223/0, Phase 2 13/0; health 20, database 10 and VM CLI 11 tests). The new regression runs the shipped health test with a real Java executable and libraries but no adjacent compiler, then rejects its actual unittest skip output. A separate full-suite run with that compiler-free Java also exited 0 with `OK (skipped=1)`; the shared production completeness function accepted the normal output and rejected the skipped output. Evidence: `work/m10-validation/unittest-skip-normal.log`, `unittest-skip-jre.log` and `unittest-skip-verdict.json`. The published-driver preflight executed before the first real VM attempt; live cleanup progress/retry and the remaining real matrix assertions are unexecuted. Earlier local evidence remains in `work/m10-validation/local.log` and `work/m10-validation/vm-local.log`. Local contract checks on 2026-10-01 09:14 UTC exited 0 without skips: Phase 1 223/0, Phase 2 13/0, health 20, database 10 and VM local 14 tests; evidence: `work/m10-validation/cloud-contract-local.log`. The three new unit checks execute shipped ownership predicates for unnamed/legacy reservations, UUID/interface identity and remaining MAC/IP detection; they do not exercise real VM creation or cleanup. Read-only SSH on the retained Debian guest confirmed `sudo -n cloud-init query ds.meta_data.local-hostname` returns the actual datasource hostname; this is a metadata-query observation only, retained in private `work/m10-validation/cloud-metadata-query.json`. The actual guest confirmed that `ip -j address` includes MAC and IPv4 data, whereas `ip -j -4 address` omits MAC data; the driver uses the former and selects IPv4 entries. |
| T3 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `work/m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in all eight cases. Earlier, `work/m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`; the four remaining cases did not run. Earlier: Real cloud creation exited 1 at SSH readiness; the reserved IP differed from the actual lease and the 90-character guest hostname was rejected. Ansible installation did not run. VM and original failure are preserved in `work/m10-vm-run-e43b973-2`; diagnostic SSH through the observed lease does not satisfy the original run. The cloud-provision correction and current driver require a new matching published-candidate run. A second real run on 2026-10-01 16:19 UTC used published environment `4280f203f87fe2c20de1543ab589cbed9f97e7d0` and cloud-provision `da2ffd56c57cd1814472e85afe3b794339e09464`: cloud creation/readiness and inventory generation exited 0; guest hostname was 63 characters and actual MAC/IP matched the reservation. The driver then failed JSON decoding because its SSH stderr first-connect warning was merged into stdout. Ansible did not run; `work/m10-vm-run-4280f20` preserves the failed run and VM. On 2026-10-01 17:19 UTC, the corrected shipped SSH function repeated the actual guest facts command with a fresh known_hosts file: stdout decoded as JSON, the first-connect warning was retained separately in stderr, and actual hostname matched cloud-init datasource metadata. Private evidence: `work/m10-validation/ssh-stream-fix/command-00001.json` and `command-00002.json`. The final local suite on 2026-10-01 17:19 UTC exited 0 without skips: Phase 1 223/0, Phase 2 13/0, health 20, database 10 and VM local 15 tests. The stream regression executes real subprocesses and checks JSON stdout, retained stderr, nonzero exit propagation and the unchanged combined-output default. Evidence: `work/m10-validation/ssh-stream-fix-local.log`. This read-only diagnostic does not replace a complete matrix run. A third run at 2026-10-01 18:09 UTC with published environment `bdb36baeddeb153ea75a903aafd5cbce0c7effa6` passed this case's lifecycle and identity checks; original run evidence is retained in `work/m10-vm-run-bdb36ba/run.json`. Its overall runtime verdict remains Fail; other matrix cases are unexecuted. |
| T4 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `work/m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). Earlier, `work/m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`; the four remaining cases did not run. Earlier: First-case actual Ansible/Make cold build and installation passed. Evidence: `work/m10-vm-run-bdb36ba/run.json`. Other accepted matrix cases remain unexecuted. |
| T5 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `work/m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). Earlier, `work/m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`; the four remaining cases did not run. Earlier: First-case installed payload comparison passed. Evidence: `work/m10-vm-run-bdb36ba/run.json`. Other accepted matrix cases remain unexecuted. |
| T6 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `work/m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). Earlier, `work/m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`; the four remaining cases did not run. Earlier: First-case database schema and socket passed. Evidence: `work/m10-vm-run-bdb36ba/run.json`. Other accepted matrix cases remain unexecuted. |
| T7 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `work/m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). Earlier, `work/m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`, the last read from its runtime evidence `command-01027.json` because the case failed before recording; the four remaining cases did not run. Earlier: First-case JVM readiness passed. Evidence: `work/m10-vm-run-bdb36ba/command-00298.json`. Other accepted matrix cases remain unexecuted. |
| T8 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `work/m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). The three scheduled health successes were observed on every Rocky 8.10 case. Earlier, `work/m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`, the last read from its runtime evidence `command-01027.json` because the case failed before recording; the four remaining cases did not run. Earlier: First-case three eligible scheduled health invocations passed. Evidence: `work/m10-vm-run-bdb36ba/command-00298.json`. Other accepted matrix cases remain unexecuted. |
| T9 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `work/m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). Earlier, `work/m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`, the last read from its runtime evidence `command-01027.json` because the case failed before recording; the four remaining cases did not run. Earlier: First-case HTTP identity passed. Evidence: `work/m10-vm-run-bdb36ba/command-00298.json`. Other accepted matrix cases remain unexecuted. |
| T10 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `work/m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). Earlier, `work/m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`, the last read from its runtime evidence `command-01027.json` because the case failed before recording; the four remaining cases did not run. Earlier: The published `bdb36ba` runtime failed timestamp/value comparison with zero parsed CA observations: `camonitor -t i` produces incremental timestamps while the parser requires absolute dates. The correction selects CA server timestamps with `-t s`. A focused execution of the shipped `Guest.start_ioc`, `Observer` and `Guest.acquire` loaded all 10,018 original records, recorded 107 CA events without observer errors, and matched all 10 distinct retrieved samples to real CA timestamp/value observations. IOC startup took 1.273 s and acquisition took 106.657 s, within the unchanged 180 s bounds. Private evidence: `work/m10-validation/ca-timestamp-fix-acquisition-2.json`; full local suite exited 0 without skips (Phase 1 223/0, Phase 2 13/0, health 20, database 10 and VM local 15 tests), evidence `work/m10-validation/ca-timestamp-fix-local-external.log`. This focused run does not replace the failed full run or satisfy the full matrix and remaining boundary assertions. On 2026-10-01 20:28 UTC, the fresh `52d90166f5995acc332dbeb14945ed26ae32d408` Debian socket run passed T3-T10: real VM creation, installation, payload, database, JVM/HTTP readiness, scheduled health and CA-to-retrieval checks. The original fixture loaded 10,018 records; first acquisition completed in 101.860 s and its raw preceding-value boundary check passed. Runtime evidence: `work/m10-vm-run-52d9016/command-00304.json`; installation results: `work/m10-vm-run-52d9016/run.json`. Other accepted matrix cases remain unexecuted. |
| T11 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `work/m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases, including `rocky8-socket`, `rocky8-tcp` and `rocky8-sqlite` with health polled immediately after `sd_restart`; the case that failed in the run on f8c457e passed. Earlier, `work/m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the three Debian 13 positive cases; Fail in `rocky8-socket`, where launcher health reported `wrong-java-executable` about 0.4 s after `sd_restart` (M46). Earlier: Shipped `sd_restart` replaced the four JVM identities; readiness returned within 60.074 s and earlier retrieved samples remained unchanged. The following real fresh-acquisition request ended at `2026-10-01T20:29:52.813821124Z`; raw retrieval returned a sample at `2026-10-01T20:29:52.823097908Z`, 9.276784 ms later. The unchanged window check refused this response with `Unexpected out-of-window API data`. The observer recorded 163 CA events and 162 resource samples without errors. Original failure and response: `work/m10-vm-run-52d9016/command-00304.json`; console `work/m10-validation/system-52d9016.log`, exit 1. No source correction or window-check relaxation has been applied. T12-T15 and remaining matrix cases did not run; owned IOC/verifier helpers stopped and the VM remains preserved. Diagnosis on 2026-10-01 20:41 UTC reproduced the source bug using the real original IOC and live HTTP retrieval: `to = sample timestamp - 1 ns` still returned that sample; `to = sample timestamp` returned it without upper-bound overflow. Stored-history controls excluded the target at minus 1 ns and included it at its exact timestamp. At pinned source `d8a7813f40083c1bf7148e6c3b7bffd368d70ee0`, `GetEngineDataAction` uses `StreamPBIntoOutput.streamPBIntoOutputStream`, whose lines 50-65 discard fractional seconds and compare epoch seconds; `MergeDedupConsumer` forwards events without a final upper-bound filter. Actual evidence: `work/m10-validation/retrieval-live-upper-bound-3.json` and `work/m10-validation/retrieval-upper-bound.json`. The successful live probe recorded 168 CA events with no observer errors; its owned IOC stopped successfully. No production source or acceptance criteria changed. |
| T12 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `work/m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). Earlier, `work/m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the three Debian 13 positive cases; the other cases did not reach it. |
| T13 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `work/m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-sqlite` and `rocky8-sqlite`. Earlier, `work/m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-sqlite`; `rocky8-sqlite` did not run. |
| T14 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `work/m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-build-failure` and `rocky8-build-failure`: the build failed at the real checkout of an absent commit, with git 2.47.3 printing `unable to read tree` on Debian 13 and `reference is not a tree` on Rocky 8.10, both recognized by the corrected check. |
| T15 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `work/m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Eight guests were retained across the cases, cloud-provision removed them on request, and `--verify-cleanup` returned PASS: every owned domain, disk, seed, creation record and reservation is absent and the baseline is preserved. Earlier, `work/m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: `debian13-tcp` started while the first guest remained owned and present, and the interruption and cleanup-refusal checks passed in `debian13-socket`; `--verify-cleanup` on this failed run returned PASS at 19:04 PDT after cloud-provision removed its four guests; the run holds a failure, so it yields no verdict. |

###### Published-Candidate Run Before Inventory Revision

Observed on 2026-10-02 at 06:04 UTC, using published environment `8f3bbfe96b7d1ee60cfd11ee0c72b2c422e8d12c`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee`, pinned cloud/Ansible tools, unchanged images and original IOC fixture. The preceding table preserves earlier candidate observations; this run supersedes their current execution status without clearing their failures.

| Check | Observed Result | Evidence And Remaining Work |
| --- | --- | --- |
| T1 | Fail | Full system run exited 1 and stopped on SQLite installation verification; `work/m10-vm-run-8f3bbfe-dca485f-2/report.json` |
| T2 | Partial | Published candidate full local suite and preflight passed; this does not verify the revised draft code |
| T3-T12 | Partial | Debian 13 MariaDB socket and TCP cases passed all installation, runtime, exact-window, restart and repeat-install assertions; per-case results in `run.json` and guest JSON files. Both guests are shut down and retained |
| T5-T6 SQLite | Fail at T6 | Payload comparison and service-account schema query passed; effective appliance dependencies contain no MariaDB unit. The selected MariaDB unit query returned empty stdout and exit 1, which `execute` rejected before the absence assertion. Actual guest evidence in `command-01583.json`; database absence is not a failed SQLite schema result |
| T13-T14 | Not run | SQLite runtime negatives, Rocky cases and both real build-failure cases remain unexecuted |
| T15 | Partial | Real interruption and cleanup-refusal checks passed on the first owned guest; earlier ownership remained recorded when later cases began. Explicit resource cleanup has not run; no full acceptance |

The failed SQLite VM and all original contexts remain preserved. The revised draft verifier requires its own local checks, review and a new full published-candidate run. No revised VM result or successful cleanup is claimed.

###### Revised Draft Local Verification

Observed on 2026-10-02 at 06:31 UTC. `PYTHONDONTWRITEBYTECODE=1 python3 tests/vm/local.py` exited 0: 16 tests, including real systemctl filesystem inventory regressions. The initial regression draft failed because an empty service root returned command exit 1; the final test distinguishes that command failure from a nonempty inventory missing the appliance. No VM result is inferred from either local execution.

The real `tests/run-all-tests.bash --local` run outside the sandbox exited 0 without skips: Phase 1 logic 223 passed, health 20 tests, database 10 tests, VM local 16 tests, Phase 2 build wrapper 13 passed. Evidence: `work/m10-validation/sqlite-inventory-revision-local.log`, SHA256 `d6ddaba233302bf305e0c2fc6482b41062b22c288c7d8c56a9b6bc9936d5fd16`. Verified draft `tests/vm/guest.py` SHA256: `c152e9342505cbee9fa3b541b2360358efdf61439f5ad88c1c70dbd4d823a680`; `tests/vm/local.py` SHA256: `1ab7c5ccabdb978b7a3d4642ca787b12da9668bd4c5f1f9ab0798b913faaa8c5`.

Revised plan acceptance and execution authorization are recorded above. The revised verifier was published as `607092b962afd9cbac31ce9f62efba0e7c62b471`; subsequent observations are recorded below. Full matrix acceptance and explicit cleanup remain pending. Retained failed contexts have not been changed.

###### Published Revision And Single-VM Verification

Observed on 2026-10-02, with environment `607092b962afd9cbac31ce9f62efba0e7c62b471` and source `dca485fd28d14cf91e988fae9ade13729a55c7ee`. The full driver preflight passed the published candidate's actual complete local suite without skips at 07:30 UTC. Its first VM creation then exited 1 because the selected address already belonged to another MAC in an unnamed DHCP reservation. Disk and seed creation preceded that refusal; no domain was found afterward. Installation did not start. Preserve `work/m10-vm-run-607092b-dca485f`, including `command-00116.json`, and the original failure; do not treat a retry or later diagnostic success as clearing it.

Cloud-provision subsequently created a separate basic Debian 13 VM using tool `e468393242000f627f626fffbb2f5b7277f344e3`. Actual domain UUID and MAC/IP ownership matched the private handoff and both live/persistent reservations before guest verification. SSH, two vCPUs, 4 GiB RAM and cloud-init done with no errors were independently observed; a password-unspecified warning remains. Installation used the unchanged pinned Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`, its maintained inventory plus a generated single-host inventory, and an exact host limit. The real `archiver_dev.yml` run exited 0 with failed=0 and unreachable=0. This is a direct Ansible installation, outside a full driver run context.

| Check | Observed Time UTC | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T5-T6 | 2026-10-02 08:29 | Debian 13 MariaDB socket; shipped `guest.py installation` through a real systemd helper | Pass for this VM: exact candidate HEADs, installed payload/configuration and service-account schema/transport verified; `work/m10-ansible-handoff-607092b/installation.json` |
| T7-T9 | 2026-10-02 08:29-08:31 | Same VM; shipped `guest.py runtime`, actual launcher, timer and HTTP APIs | Pass for this VM: four genuine JVM identities, three distinct eligible health invocations and HTTP appliance identity |
| T10 | 2026-10-02 08:32 | Same runtime path; unchanged original fixture, real IOC/CA and retrieval | Pass for this VM: all 10,018 records loaded; ten distinct retrieved timestamps/values matched CA observations and raw window checks passed; IOC startup 1.306 s, first acquisition 109.625 s, each within its unchanged 180 s bound |
| T11 | 2026-10-02 08:34 | Same runtime path; real `sd_restart` with IOC running | Pass for this VM: all JVM identities replaced, earlier history preserved and fresh acquisition passed; restart/readiness 53.689 s within 300 s, fresh acquisition 10.332 s within 180 s |
| T12 / unchanged reapply | 2026-10-02 08:47 | Same VM and pinned Ansible inputs; actual playbook followed by shipped `guest.py unchanged` | Pass for this VM: Ansible exit 0, changed=0 and failed=0; actual build invocation remained identical, all four JVM PID/start identities and stored history/readiness preserved; `work/m10-ansible-handoff-607092b/reapply-result.json` |
| T12 / forced reinstall | 2026-10-02 08:58 | Same VM; explicit force variable through actual Ansible, real build journal and shipped `guest.py reinstalled` | Pass for this VM: new build invocation, expected eight Make targets, actual completion sentinel, replaced JVM identities, matching payload/schema, three eligible health successes, stored history and fresh acquisition; acquisition 10.296 s within 180 s; `work/m10-ansible-handoff-607092b/reinstall-result.json` |
| T13-T15 | Not run in this diagnostic | Planned SQLite negative, build-failure and lifecycle methods | Pending for this candidate; no full matrix or cleanup result inferred |

Installation verifier and runtime verifier both exited 0. Runtime evidence: `work/m10-ansible-handoff-607092b/runtime.json`, SHA256 `d46370b880c451102bebf500b290376e8fdc7afafe70f3f7661106802c2d6db1`. Installation evidence SHA256: `a5b2d4f93c3b779895bbeeb31a8e0aaf37495b7fbedcb3c858e1c19b13bc2604`. Private inputs, ownership observations and Ansible output remain in the same evidence directory. The published guest verifier ran without internal substitutions and used the original fixture and unchanged deadlines. The current driver has no external-VM adoption operation; these results remain independent diagnostic evidence. No synthetic full-run context, full acceptance, VM shutdown or cleanup is claimed. M10 remains In progress.

Repeat-install evidence was observed through the actual pinned playbook and shipped verifier, without substituting internal build or application paths. Unchanged-reapply evidence SHA256: `0f711ce4748792017f7ad98363022c2e01eaf51ad36fc2be9ef796de16ada00d`; forced-reinstall evidence SHA256: `0edba2c04c578b67b0794562a0c32611f02e04d27b80bce97ef75a1d867210d9`. The full build journals, Ansible command results and raw guest output are retained beside these files. Separate SQLite observations follow below.

###### Published Revision And Debian SQLite Verification

Observed on 2026-10-02 with the same published environment/source commits and pinned Ansible. A separate fresh Debian 13 VM was prepared by cloud-provision `a52bb79687f0ba260123de362f5ade77d136ceb9`. Actual UUID, interface MAC, attached disk/seed and live/persistent DHCP ownership matched the private handoff; the initial guest had no appliance or MariaDB installation. The real single-host `archiver_dev_sqlite.yml` install exited 0 with ok=27, changed=9, failed=0 and unreachable=0. The unchanged published `guest.py` and original IOC fixture digests were confirmed on the guest before runtime verification. These are independent diagnostics outside the failed full driver context.

| Check | Observed Time UTC | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T5-T6 | 2026-10-02 15:54 | Debian 13 SQLite; shipped `guest.py installation`, service-account SQL and complete real service inventory | Pass for this VM: requested source HEADs and installed payload/configuration match; application schema and WAL connection verified; appliance unit present, MariaDB-family units and dependencies absent; `work/m10-ansible-sqlite-607092b/installation.json` |
| T7-T9 | 2026-10-02 16:26-16:27 | Shipped `guest.py runtime`; genuine processes, launcher health, scheduled timer and HTTP APIs | Pass for this VM: four appliance JVM identities, three distinct eligible health successes and matching HTTP appliance identity |
| T10 | 2026-10-02 16:29 | Same runtime path; complete original IOC, real CA and raw retrieval | Pass for this VM: all 10,018 records loaded; eleven distinct in-window timestamps with eleven different values match CA observations; the between-events boundary query records one preceding value separately. IOC startup 1.300 s and acquisition 101.561 s are within unchanged 180 s bounds |
| T11 | 2026-10-02 16:30 | Real `sd_restart` with IOC running | Pass for this VM: all JVM identities replaced, stored PV/history preserved and new acquisition observed. Restart/readiness 52.706 s within 300 s; fresh acquisition 10.230 s within 180 s |
| T12 / unchanged reapply | 2026-10-02 16:31 | Same pinned Ansible inputs followed by shipped `guest.py unchanged` | Pass for this VM: Ansible exit 0, changed=0 and failed=0; build invocation and four JVM PID/start identities unchanged; stored history and readiness preserved; `work/m10-ansible-sqlite-607092b/reapply-result.json` |
| T12 / forced reinstall | 2026-10-02 16:38 | Explicit force variable through real Ansible, actual build journal/script/sentinel and shipped `guest.py reinstalled` | Pass for this VM: Ansible exit 0, changed=1 and failed=0; new build invocation and expected eight Make targets; payload/schema and MariaDB absence rechecked; replaced JVMs, three eligible health successes, preserved history and fresh acquisition in 10.304 s; `work/m10-ansible-sqlite-607092b/reinstall-result.json` |
| T13 | 2026-10-02 16:39 | Shipped `guest.py negative`; genuine other-instance PID, real IOC stop and restoration | Pass for this VM: wrong PID gives health exit 1 with `wrong-instance-base`, despite HTTP readiness; genuine process identities and PID-file ownership restored. Stopped-IOC query has zero fresh samples and one preceding value. Restored IOC resumes acquisition in 12.342 s and stored history remains unchanged; `work/m10-ansible-sqlite-607092b/negative.json` |
| T1, T3-T4, T14-T15 / full context | Not established by these diagnostics | Accepted full driver, dedicated build-failure and lifecycle/cleanup paths | Pending; the original full-run failure and all retained resources remain preserved |

The runtime verifier exited 0 and retained 165 CA events and 164 one-second resource observations without observer errors. Its original IOC, raw window checks, restart and recovery ran through the published code without internal substitutes or relaxed deadlines. Runtime evidence is `work/m10-ansible-sqlite-607092b/runtime.json`.

| Retained Artifact | SHA256 |
| --- | --- |
| `installation.json` | `b4dc4d509e0ec21a74a45af3c8a7c1ea5ebe5d9d90e7c464bb2bcd21981145c3` |
| `runtime.json` | `6b2716a6461c3f30eee503a1dd70c172c6986021c3b33a1be272879097557f02` |
| `reapply-result.json` | `d99ed56cec4dfa3b3970e533845038ebbe7de330d86932ca19fd1833cdc384bf` |
| `reinstall-result.json` | `d73d487cad39eb190b2033b31c62632e35222e95abb97c86429fd316cbc21352` |
| `negative.json` | `c7895fa7770763fd815c5d755d1e66f4665bebc0785f1851d90a14b62b08d4bb` |

Private command results, full build journals, Ansible output, actual guest `history.json` and pre-action PID/start records are retained in `work/m10-ansible-sqlite-607092b`. Its `evidence-manifest.json` records 43 retained files and their digests; manifest SHA256: `404d2d2fee79b5bcba5c228bf1b902f604649dca19c47768344ee12c6f17ccd8`. Final observed appliance/IOC services and health timer are active. No shutdown, cleanup, full matrix acceptance or issue closure has been performed. M10 remains In progress.

###### Published Revision And Debian TCP Verification

Observed on 2026-10-02 with the same published environment/source commits, pinned Ansible and original fixture. A separate fresh Debian 13 VM was prepared by cloud-provision `9da0436bf6fbd780015156ea04c2b535fe5507ec`; actual UUID, interface MAC, attached disk/seed, lease and live/persistent DHCP ownership matched the private handoff, and the guest had no install paths or appliance/database units. The shipped `Driver` methods `capture_ownership`, `verify_live_case`, `install`, `build_proof`, `transfer`, `guest` and `runtime` ran unchanged against that guest through a private harness that binds them to the external VM and writes no `run.json`. The real `archiver_dev.yml` play used an empty `archiver_db_socket` and `mariadb_skip_networking=false`. These are independent diagnostics outside a full driver context.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T3 | 2026-10-02 13:29 | Debian 13; ownership, generated single-host inventory and the driver's guest facts, hostname, interface, OS and resource checks | Pass for this VM: 2 vCPUs, 18652266496 free root bytes, cloud-init done with no errors (extended status degraded by the template's password-unspecified warning) |
| T4 | 2026-10-02 13:40 | Real Ansible installation, build journal, build script and sentinel | Pass for this VM: Ansible exit 0, ok=31, changed=11, failed=0 in 630.0 s; the eight accepted Make targets ran in order |
| T5-T6 | 2026-10-02 13:40 | Shipped `guest.py installation` | Pass for this VM: guest HEADs equal the requested environment/source commits; payload/configuration match; the service account reads the four application tables over TCP to the local MariaDB port |
| T7-T9 | 2026-10-02 13:40-13:42 | Shipped `guest.py runtime` | Pass for this VM: four genuine JVM identities, three distinct eligible health successes and matching HTTP appliance identity; readiness 4.363 s |
| T10 | 2026-10-02 13:43 | Same runtime path; complete original IOC, real CA and raw retrieval | Pass for this VM: all 10,018 records loaded; ten distinct in-window timestamps with ten values match CA observations; the between-events boundary query records one preceding value separately. IOC startup 1.306 s and acquisition 103.432 s within unchanged 180 s bounds |
| T11 | 2026-10-02 13:45 | Real `sd_restart` with IOC running | Pass for this VM: all JVM identities replaced, stored PV/history preserved and new acquisition observed. Restart/readiness 60.312 s within 300 s; fresh acquisition 10.349 s within 180 s |
| T12 / unchanged reapply | 2026-10-02 13:45 | Same pinned Ansible inputs followed by shipped `guest.py unchanged` | Pass for this VM: Ansible exit 0, changed=0 and failed=0; build invocation and four JVM PID/start identities unchanged; stored history and readiness preserved |
| T12 / forced reinstall | 2026-10-02 13:48-13:50 | Explicit force variable through real Ansible, actual build journal/script/sentinel and shipped `guest.py reinstalled` | Pass for this VM: Ansible exit 0, changed=1 and failed=0 in 168.0 s; new build invocation and expected eight Make targets; payload/schema rechecked; replaced JVMs, three eligible health successes, preserved history and fresh acquisition in 10.338 s |
| T1, T13-T15 / full context | Not established by these diagnostics | Accepted full driver, SQLite negative, build-failure and lifecycle/cleanup paths | Pending; T13 is not required for a MariaDB case |

The runtime observer retained 175 CA events and 173 one-second resource observations without errors. At 13:50 PDT, `systemctl is-active` over SSH reported the appliance, health timer, test IOC and MariaDB units active. The pinned Ansible checkout reported an SSH-form origin URL at 13:29 PDT; the driver's full preflight requires an HTTPS origin, so that input must be rechecked before a full driver run.

| Retained Artifact | SHA256 |
| --- | --- |
| `debian13-tcp-installation.json` | `8f92dd30bef2694e88285c314fcce592e2f6eb04b7282972782a38683ae67a73` |
| `debian13-tcp-runtime.json` | `e13d7ec58888c428d9a86eed1b96fb980cbf0bec3631b8d18bea671b12b27a33` |
| `debian13-tcp-unchanged.json` | `28c13147ead2aa6d790870254f1030c2c73b0a737a6853b990719c2f1391e8af` |
| `debian13-tcp-reinstalled.json` | `e397be8c571319a34d75c37c9339c14b8f34b4c106dba6f7cb66540700417e6b` |

Private inputs, ownership observations, the harness, 547 command results and the diagnostic state are retained in `work/m10-ansible-tcp-607092b`. No shutdown, cleanup, full matrix acceptance or issue closure has been performed.

###### Published Revision And Rocky 8.10 Socket Diagnostic

Observed on 2026-10-02 with the same published environment/source commits, pinned Ansible, original fixture and harness method. A separate fresh Rocky 8.10 VM was prepared by cloud-provision `6ae1dbf3dd0d115185f7eee29f657ab318f94393`, whose uncommitted paths were documentation and tests only; actual ownership matched the private handoff and the guest was fresh. By owner direction, Decision Date: 2026-10-02, the diagnostic continued after the recorded T3 failure using the adjusted observation only. The case stopped at its first unexpected runtime failure; deadlines, window checks and verifier code were not relaxed.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T3 / shipped facts command | 2026-10-02 18:00 | Rocky 8.10 base guest; the driver's pre-installation facts command over SSH | Fail: `python3` is absent before Ansible installs its Python packages, so the command exits 127 with `python3: command not found`. The shipped `Driver.create` sequence would stop at this point on every fresh Rocky case. Evidence: `command-00117.json` |
| T3 / diagnostic continuation | 2026-10-02 18:00 | Same checks with `/usr/libexec/platform-python` and `text=True` replaced by `universal_newlines=True` for Python 3.6 | Pass for this VM only: 2 vCPUs, 18407264256 free root bytes, cloud-init done with no errors or warnings. This adjusted observation does not verify the shipped command |
| T4 | 2026-10-02 18:08 | Real Ansible installation, build journal, build script and sentinel | Pass for this VM: Ansible exit 0, ok=33, changed=14, failed=0; the eight accepted Make targets ran in order |
| T5-T6 | 2026-10-02 18:08 | Shipped `guest.py installation` | Pass for this VM: guest HEADs equal the requested commits; payload/configuration match; JDK 21; the service account reads the four application tables through the MariaDB socket. SHA256 `dee5556c3459b4305bb6f0b5d5984fd41132f2750503f4a028d48b23c595c515` |
| T7, T9 | 2026-10-02 18:08 | Shipped `guest.py runtime` | Pass within the failed runtime attempt: readiness and appliance identity completed in 17.176 s |
| T8 | 2026-10-02 18:08 | Same runtime path; scheduled health journal query | Fail: `guest.py` passes an ISO 8601 timestamp with fractional seconds and a `+00:00` offset to `journalctl --since`; systemd 239 rejects it with `Failed to parse timestamp`. A read-only repeat on the guest also rejected the form without fractional seconds and accepted `YYYY-MM-DD HH:MM:SS UTC`. The verifier exited 1. Evidence: `command-00404.json` |
| T10-T12 | Not run | Same VM | Not run after the T8 failure; the test IOC was not started |

The Debian 13 cases accepted the same timestamp form, so both failures are specific to the Rocky 8.10 base environment. Correcting them changes the shipped driver and verifier and therefore requires a revised plan, publication and a new candidate run; earlier diagnostics do not verify that candidate. The original failures, private inputs, harness, command results and diagnostic state are retained in `work/m10-ansible-rocky8-socket-607092b`. At 22:50 PDT, `systemctl is-active` over SSH reported the appliance, health timer and MariaDB active and the never-started test IOC inactive; no shutdown or cleanup has been performed.

###### Rocky 8.10 Compatibility Local Verification

Observed on 2026-10-02 on the local Debian 13 host (systemd 257, Python 3.13) with the accepted revision implemented on top of 6751c098eddcca75188418b84de366ed179c5b94. The source SHA256 values below identify the verified bytes: `tests/vm/driver.py` `ddf92f98a71fd292e83c6ff82e4a50e1e9d1483128a3dc0947663390e940c24f`, `tests/vm/guest.py` `755745bf1b5ab19ebbf6b7fcd4ae16d8130afa07e59cda720965bf0d287f2116`, `tests/vm/local.py` `921ac8dcd6a906b14a69057d8b696651f8832b7d5edaad303274ad37bf58da21`.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T2 / earlier facts command | 2026-10-02 23:09 | New shell-facts regression against the earlier Python command, factored into a module function without other change (driver SHA256 `b077eaa730650fa3d01b2b7a0ca479ffc7a3ec1a20e51bf7458bb38546700776`); real `bash -c` with a `PATH` of real `sh`, `cat`, `getconf`, `hostname`, `ip` and `stat` only | Fail as required: exit 127 with `python3: command not found`, the same failure as the Rocky 8.10 guest. Evidence: `work/m10-validation/rocky-compat-earlier-facts.log` |
| T2 / shell facts | 2026-10-02 23:10 | Same regression against the shipped shell command and parser | Pass: parsed CPU count, hostname, root size and `/etc/os-release` content equal the local observations; removing each of the six sections in turn is rejected |
| T2 / journal bound | 2026-10-02 23:10 | Shipped `journal_since`; real local `journalctl --since` | Pass: a whole second is unchanged and 1 ns, 0.5 s and 0.999999999 s past it convert to the next second; the real command exits 0. systemd 239 behavior is not reproduced locally |
| T2 / full local suite | 2026-10-02 23:10 | `tests/run-all-tests.bash --local` | Pass: exit 0 without skips; Phase 1 223/0, health 20, database 10 and VM local 18 tests, Phase 2 13/0. Evidence: `work/m10-validation/rocky-compat-local.log`, SHA256 `8a6ace3da4459fe3d376e5fd813f2b325b20e32b72203b65e04427ff305fedb8` |
| Guest facts preview | 2026-10-02 23:10 | Shipped facts command over SSH on the retained Rocky 8.10 socket and Debian 13 TCP guests | Exit 0 on both; parsed OS release, two CPUs, 63-character hostnames and root/free bytes. Both guests were already installed, so this is not T3 evidence. Evidence: `work/m10-validation/rocky-compat-guest-facts.log` |

The VM verification of this revision follows below.

###### Published Revision And Six-Case Verification

Observed on 2026-10-03 (Pacific local date; times PDT) with published environment `65cf077b1230f61efdba817aa697483a79a3a5d5`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee`, pinned Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`, the original fixture and unchanged bounds. By owner direction, Decision Date: 2026-10-02, all six positive cases were re-run one fresh guest at a time, each shut down after its case. Cloud-provision `a29f4773c14274b447cb66f4b9ab11f4cc1f8583` prepared every guest, with one uncommitted documentation path; actual UUID, interface MAC, attached disk/seed, lease and live/persistent DHCP ownership matched each private handoff. A private harness bound the unchanged shipped `Driver` methods to each external guest, collected facts through the shipped `guest_facts_command` and `parse_guest_facts`, checked freshness with a shell-only probe, required the executing `tests/` tree to equal the candidate commit and wrote no `run.json`. These are independent diagnostics outside a full driver context.

| Case | Observed Time PDT | Results | Ansible Install / Reapply / Reinstall | IOC Startup / Acquisition / Restart / Post-Restart / Post-Reinstall |
| --- | --- | --- | --- | --- |
| Debian 13 socket | 2026-10-03 00:18-00:37 | T3-T12 Pass | changed=11 in 464 s / changed=0 / changed=1 in 228 s; failed=0 | 1.327 / 105.532 / 55.982 / 10.255 / 10.294 s |
| Debian 13 TCP | 2026-10-03 00:39-00:57 | T3-T12 Pass | changed=11 in 518 s / changed=0 / changed=1 in 168 s; failed=0 | 1.298 / 103.584 / 58.734 / 10.301 / 10.326 s |
| Debian 13 SQLite | 2026-10-03 01:00-01:19 | T3-T13 Pass | changed=9 in 504 s / changed=0 / changed=1 in 197 s; failed=0 | 1.299 / 109.515 / 61.032 / 10.302 / 10.284 s; T13 recovery 10.261 s |
| Rocky 8.10 socket | 2026-10-03 01:23-01:37 | T3-T12 Pass | changed=14 in 312 s / changed=0 / changed=1 in 146 s; failed=0 | 1.300 / 103.416 / 52.985 / 10.252 / 10.225 s |
| Rocky 8.10 TCP | 2026-10-03 01:41-01:58 | T3-T12 Pass | changed=14 in 426 s / changed=0 / changed=1 in 202 s; failed=0 | 1.328 / 105.950 / 54.347 / 10.188 / 10.220 s |
| Rocky 8.10 SQLite | 2026-10-03 02:05-02:20 | T3-T13 Pass | changed=11 in 316 s / changed=0 / changed=1 in 172 s; failed=0 | 1.352 / 105.574 / 51.776 / 10.201 / 10.230 s; T13 recovery 12.234 s |

Each acquisition stays within its 180 s bound and each restart within 300 s. Every runtime loaded all 10,018 fixture records, matched at least ten distinct in-window timestamps with their values to CA observations and retained 167-181 CA events without observer errors. The between-events boundary query recorded one preceding value separately in five cases and none in the Debian 13 SQLite case, within the permitted maximum of one. Socket and TCP cases used the service account through the MariaDB socket and `127.0.0.1` TCP respectively; both SQLite cases confirmed WAL, the appliance unit and the absence of MariaDB-family units. Both T13 runs detected the wrong-instance PID despite HTTP readiness, returned no fresh sample with the IOC stopped and resumed acquisition after restoration.

The Rocky 8.10 failures recorded at `607092b962afd9cbac31ce9f62efba0e7c62b471` are corrected on real guests. Cloud-provision reported no `python3` and no Ansible on each fresh Rocky guest, and a separate SSH check immediately before the socket-case observation confirmed `python3` absent; the shipped facts collection passed T3 on all three. On systemd 239, the journal bound `@<epoch seconds>` was accepted and three distinct eligible health invocations passed T8; T10-T13 then ran on Rocky 8.10 for the first time and passed.

| Case | Installation | Runtime | Unchanged | Reinstalled | Negative |
| --- | --- | --- | --- | --- | --- |
| Debian 13 socket | `f44ae7e6191097ef3a5ff2c4a2fa74964f36a57ac35ca8f01240bb3e42883f8f` | `50d1e4b70ab2c9aeae709fc9779bcaeda0645d5f67bb2d700e913e7fbe8bad8e` | `1c0f295cdcff3643c9af0e24def6cb132853162c0300f7f13417ce4f56c5d6e0` | `47ffccf9175f62ffe1221100409d55b18c943834df28873482232fe89ca608e7` | Not required |
| Debian 13 TCP | `6700679b24f29bc95d825a6c79729e4a53219c63cd2c82444703efdb356268db` | `34dfbe492089205e4bf42cf2853c2ea3e573d34133670eda14f011264ea592b3` | `821d01f6cf4d5a83d715f478dc98d6aa78ff440f39fb2686c0195fc10f575ac4` | `407b108e13df50b2201a0ec6d0ef31ff93b55338a8678ae06534e7fade977f8a` | Not required |
| Debian 13 SQLite | `075d82581328465daca2234d4952e0a6ed6e2b60c191567461604f3b341884a2` | `6ded2b97bb192c62ae3db3f38e521e7136478b96e5498dfed08b07735282d932` | `04882fcf17a8070157a067d7848453f4ca0d94ce44912cdf05df12dcf99d683f` | `a52a21cf346f380f24ac352c1abd321089da222c26ed14c9932a1e5d990ddb17` | `50f37b22ea50578d43ffb9d4be5e83203e14eec9f96c682e9f7f5333bc9cb652` |
| Rocky 8.10 socket | `538a0c3b99c640509862aebdd0439fc0798fccb04fe77a6f7153276829223384` | `4c2135d55e2faac57be2550282e47ed77177a7a2a521ddb9f57fd9aa71c903b2` | `06430804afa97fda1190b2be8a2b0c657543a4e082cd40f755d8bf20836a89a3` | `bdf3e73cae083bd9f5593f1ec14df1f671fc4edea4956eae8834596030ef7cf3` | Not required |
| Rocky 8.10 TCP | `e1f8589189578b671cd9fe74d97eb2a921a5dfd22f69f1ca3488d5aff10623ba` | `4ecddf72365fe3c25bf1cc18ba544b9d95976dd4726c417e4e5823e9e50490ae` | `54577d0f434804c42e2e1e4d1c969fde8304dbf66fc0bea5915390192877f35d` | `6c2735ab81219838610641017f8d4a6402548c5bc52649a556c7bb152b67d12a` | Not required |
| Rocky 8.10 SQLite | `6cbffef8635f0a3ab563339f2ff20764fd83575ea4235028b8f76761c6dd871f` | `704f96069434533805e4fdee0ad3bbf9c889768c25af1356668e07c6a3241652` | `e7885eb152becd814a4b0300ecfa9f7e6a7030a0829da656baa6dc885c7d7865` | `ddcb826df42899aa93bf79839806f4b55fd93f0544359042dd2e920592214cfd` | `67cb53a7d28e9f7393981b0453695767c1a6006afb4e9fa35b81ed3cf93fcc3d` |

Private inputs, ownership observations, command results and diagnostic state are retained in `work/m10-<case>-65cf077` for each case, and the harness in `work/m10-harness`. All six guests were shut down through cloud-provision after their cases and retained; at 2026-10-03 10:41 PDT `virsh domstate` reported each of them shut off. No cleanup, full driver context, T1, T14, T15 or issue closure has been performed.

###### Interrupted Full Driver Run At 65cf077

Observed on 2026-10-03 (times PDT) with the shipped `tests/run-all-tests.bash --system` on environment `65cf077b1230f61efdba817aa697483a79a3a5d5`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee`, pinned Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5` and cloud-provision `a29f4773c14274b447cb66f4b9ab11f4cc1f8583`. The run was started at 19:30 from a background task of the operator tooling with `GIT_CONFIG_GLOBAL=/dev/null`, because a global `url.<ssh>.insteadOf` rule makes `git remote get-url` report SSH form for the stored HTTPS origins. Before the run, stale `~/.ssh/known_hosts` keys of ten unreserved addresses in the hashed window were removed by owner direction, with a full backup retained in `work/`.

| Check | Observed Time PDT | Result |
| --- | --- | --- |
| Preflight and candidate local suite | 2026-10-03 19:32 | Pass |
| Debian 13 socket | 2026-10-03 19:33-19:54 | T3-T12 Pass; interruption and invalid-ownership cleanup refusal checks passed; guest shut down and retained |
| Debian 13 TCP | 2026-10-03 19:56-20:01 | T3 Pass; terminated during Ansible installation |

At 20:01, coinciding with the tooling stopping the launching background task at its 30-minute limit, the driver's child processes were terminated and the driver recorded `ProcessLookupError` as its failure. This is an execution-environment termination, not an appliance or harness assertion failure; it remains a failure of this run. The context `work/m10-vm-run-65cf077-dca485f` and console log are retained unchanged. The driver shut down the Debian 13 socket guest after its case; the interrupted TCP guest was shut down through cloud-provision; both are retained. The remaining cases did not run.

###### VM Supply And Run Structure Local Verification

Observed on 2026-10-04 (times PDT) on the local Debian 13 host with the accepted revision implemented on top of fdbf1eccc6aa0c68553ecb17b9f68d3ece8a3d29. The driver offers `--init`, `--case`, `--verify-cleanup` and `--verdict`, calls no `create_vm.bash` action, adopts a guest from a JSON handoff, records a case only after its read-only identity, ownership and freshness checks pass, records any later error of that case as a run failure, checks the handed-off disk capacity against the configured `disk_size`, pins each guest's host key from the key cloud-provision stored at creation and connects through SSH and Ansible with strict host key checking, returns 77 without recording a failure when cleanup inspection fails, checks the digest of every guest verifier evidence file in the verdict, reads the stored tool origin URL, and clones for the publication proof without global or system git configuration. The later-error path and the refusal of an absent-source-commit, `OSError` or `TypeError` error before recording are verified by code reading only; reproducing them needs a live ownership change or a fault inside libvirt or the guest. The design document is `docs/README.vmtests.md`; `tests/README.md` keeps the execution and evidence procedures. Verified source SHA256: `tests/vm/driver.py` `454345b16a3cb873398f50447c0451ab1e79b9ea684632dbd4a29c91cf86fa11`, `tests/vm/guest.py` `755745bf1b5ab19ebbf6b7fcd4ae16d8130afa07e59cda720965bf0d287f2116`, `tests/vm/local.py` `db18b6bdf22926f986e2f0fb845e97209556037e960fa46e99ad454386a2f9f1`, `tests/run-all-tests.bash` `5c9e21a0b77afe7e9287da958763548273ac44a12e1f68af525746cf0598b9fb`.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T2 / full local suite, first run | 2026-10-04 00:47 | `tests/run-all-tests.bash --local` with the runner modes running the local phases as planned | Fail: `database-config.py` `test_system_entrypoints_cannot_report_success` timed out, because its `--system` call reran the local suite. Evidence: `work/m10-validation/vm-supply-local-20261004T074748Z.log`. The runner change recorded in item 5 followed |
| T2 / full local suite | 2026-10-04 03:09 | Same command after the runner modes stop without running checks | Pass: exit 0 without skips; Phase 1 223/0, health 20, database 10 and VM local 26 tests, Phase 2 13/0. Evidence: `work/m10-validation/vm-supply-local-20261004T100904Z.log`, SHA256 `bf8929aa43102b3e0d6b1f077433ea255f737cb7f21ca53022b936271f323007` |
| T2 / operations, handoff, origin, run rules | 2026-10-04 03:09 | The VM local tests within that suite: shipped CLI refusals, handoff validation with real files, case refusals, real `git` under an isolated `insteadOf` rule for the stored origin and the publication clone environment, the real fresh-guest probe script with real `systemctl`, real `ssh-keygen` lookup of a hashed stored host key, cleanup verification against a failing `virsh` executable, and order-independent read-only verdicts that refuse changed guest evidence | Pass |
| T2 / regression strength | 2026-10-04 03:09 | Scratch copies of the verified driver with the earlier exact-order verdict, the earlier `remote get-url` origin read, no case-rerun refusal, the inherited git configuration for publication clones, the earlier three-action evidence check, `accept-new` host key checking, a recorded cleanup inspection failure, no Ansible host key checking variable, or a schema check that accepts `true` | Each targeted regression fails on its mutant and the original passes. Evidence: `work/m10-validation/vm-supply-mutation-20261004T100920Z.log`, SHA256 `65170f5c488d3e7bd08335b91b713d228647c77eb89e631e31f46f9fdcdbaf09` |
| T2 / real `--init` path | 2026-10-04 02:20 | Shipped `--init` of driver `db57f754853f63d82a1752e3b854995e3f1d8c200a59a3b2bcbfef7a6be1fce8`, before the disk capacity check, under the user's real git configuration with a global `insteadOf` rule, the pinned tool clones and published candidate `fdbf1eccc6aa0c68553ecb17b9f68d3ece8a3d29` in a scratch evidence path; git tracing to a file | Stored HTTPS origins pass; all four publication clones use `git-remote-https` with no SSH URL; the run is refused with status 2 because the published candidate lacks these driver bytes, and no failure is recorded. No guest is contacted. Evidence: `work/m10-validation/vm-supply-init-trace-20261004T092207Z.log` |
| T3 / disk capacity | 2026-10-04 02:32 | Shipped `capture_ownership` of driver `58858f74c0c78f87ce393c94a0b035a8a523041530c14358abc1ef112f7bdec0`, whose method is unchanged in the verified bytes, with read-only `virsh` on the retained shut-off Rocky 8.10 SQLite diagnostic guest, configured `disk_size` 20G and a wrong 30G | 20G passes the capacity check and stops at the absent lease of the shut-off guest; 30G is refused at the capacity check. Evidence: `work/m10-validation/vm-supply-capacity-20261004T093238Z.log` |
| T3 / stored host key | 2026-10-04 02:56 | Shipped `pin_host_key` of driver `69452348cb2b7b798da61e414bf40900f9037de289159b132f98effe1a8d547a`, whose method is unchanged in the verified bytes, in a scratch run context against the user's real `~/.ssh/known_hosts`, for the retained Rocky 8.10 SQLite diagnostic guest's address and for an unused documentation address | The guest's three stored keys are copied into a mode 0600 file; the unused address is refused with no file written. No guest is contacted. Evidence: `work/m10-validation/vm-supply-hostkey-20261004T095641Z.log` |
| T3 / Ansible host key checking | 2026-10-04 03:08 | Real `ansible -m ping -vvvv` of ansible-core 2.19.11 under the pinned ansible-provision `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5` configuration, which sets `host_key_checking = False`, toward an unused documentation address, with the shipped `ansible_connection_variables` and with its host key checking variable removed | With the shipped variables, Ansible's SSH command carries only `StrictHostKeyChecking=yes`; without the variable it carries `StrictHostKeyChecking=no` before `yes`, so SSH would use `no`. No guest is contacted. Evidence: `work/m10-validation/vm-supply-ansible-hostkey-20261004T100839Z.log`, SHA256 `5888d59c54f2c8cb67e1b6dcc840698e152150b1c17366b4cf9d0feb05e8dac5` |

No guest was created or changed for these checks; only the disk capacity check read a retained guest's libvirt state, and the host key check read its stored key. The VM run on a published candidate remains pending under separate authority.

###### Earlier Guest Cleanup Inspection

By owner decision on 2026-10-04, cloud-provision removed all 19 shut-off `archiver-vm-test` guests of earlier M10 runs and diagnostics with `create_vm.bash -c` and each guest's own selectors, and reported every removal with exit 0. Their run contexts in `work/` stay as private evidence and are not resumed. epicsarchiverap-env then inspected the result independently and read-only, as revision item 7 requires.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| Removal of the 19 guests | 2026-10-04 15:08 | `virsh list --all`, the image directory, live and persistent `lab` network XML and `net-dhcp-leases`, matched against the 19 node selectors and the interface MACs recovered from retained run contexts and cloud-provision handoffs | Pass: no domain or image file names any of the nodes, and no reservation or lease carries any of the 17 recovered MACs or reuses their addresses. The two guests without a recorded MAC (the first two `607092b` diagnostics) rest on the absence of any `archiver-vm-test` reservation and on the cloud-provision report. Evidence: `work/m10-validation/earlier-guests-cleanup-inspection-20261004T220829Z.log`, SHA256 `85ae6a8f367e2a4c1be7e8f97fe35dc7686c98a10bb9dfc4d63b3757a74c28b6` |
| Removal of the leftover file set | 2026-10-04 15:13 | The same inspection found a disk, seed and creation record without a domain for one Debian 13 node of the failed `607092b` context, whose creation stopped at an address collision. By owner decision on 2026-10-04, cloud-provision removed them with `create_vm.bash -c` and its selectors, exit 0; no reservation existed. Re-inspected with `virsh list --all`, the image directory and both `lab` network XML forms | Pass: no domain, image file or `archiver-vm-test` reservation remains. Evidence: `work/m10-validation/leftover-cleanup-inspection-20261004T221307Z.log`, SHA256 `62d2b5e665b9a0a891fb3907ff9f6e160baf8cc57542ab89eb9266233022d2a1` |

###### VM Acceptance Run On f8c457e

Run context `work/m10-vm-run-f8c457e-dca485f`, opened on 2026-10-04 with `--init` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0` (implementation `9dcf72996d10a6fd3c1d3712088900c0ac6fce1d`), source `dca485fd28d14cf91e988fae9ade13729a55c7ee`, pinned Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5` and cloud-provision inventory generator `a29f4773c14274b447cb66f4b9ab11f4cc1f8583`. cloud-provision created each guest at its commit `8308105fc59c4e356ac2b51a924a627d6e51159c`. Each case ran as a user unit. The run holds a failure and accepts no further case; a new run is required after M46.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T1 / run initialization | 2026-10-04 15:42 | `--init`: publication clones, candidate full `--local` suite, baseline of 15 domains and 15 live and persistent reservations | Pass |
| `debian13-socket` | 2026-10-04 16:06 | First positive case, including the interruption and cleanup-refusal checks | Pass: T3-T12; interruption and refusal verified |
| `debian13-tcp` | 2026-10-04 16:30 | Started while the first guest remained owned and present | Pass: T3-T12; the T15 precondition is recorded |
| `debian13-sqlite` | 2026-10-04 16:52 | Debian 13 SQLite | Pass: T3-T13 |
| `rocky8-socket` | 2026-10-04 17:06 | Rocky 8.10 MariaDB socket | Fail at T11 after T3-T10 passed. About 0.4 s after `make sd_restart`, the shipped health reported mgmt and engine `FAIL wrong-java-executable`. The same PIDs ran Java afterwards and health then reported PRESENT. The launcher writes the PID of the backgrounded `run.sh` before the shell chain executes Java, and the verifier does not treat that window as startup (M46). Evidence: `command-01027.json` in the run context; `work/m10-validation/rocky8-socket-restart-race-20261005T004541Z.log`, SHA256 `35688cefd4f5d87afa3a78f0c0e14dfdebeb0170e8e170787c62c790b10a6da8` |

The remaining four cases did not run. By owner decision on 2026-10-04, cloud-provision removed the four guests of this run with `create_vm.bash -c` and reported four removals, each confirmed against the recorded UUID first. The driver's `--verify-cleanup` on this context then returned PASS at 19:04 PDT: every owned domain, disk, seed, creation record and reservation is absent, and the 15 baseline domains and reservations are preserved; the two domains added to the host since the baseline belong to another session. The run keeps its recorded failure. Evidence: `work/m10-validation/f8c457e-run-verify-cleanup-20261005T020411Z.log`, SHA256 `bb632ef45c2f360b0c408af5542e246b1d34de2e5e288e03c3f86976e4bb447a`; `cleanup.json` in the run context, SHA256 `982738a7bb74fb698e1252d84b808dff34b38564da414054a55437e7571a722e`.

###### VM Acceptance Run On 933b2d8

Run context `work/m10-vm-run-933b2d8-aa953a4`, opened on 2026-10-04 with `--init` on published environment `933b2d875b7cc3733485644a9315d6643ef00333`, which carries the M46 implementation, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` under D39, pinned Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5` and cloud-provision inventory generator `a29f4773c14274b447cb66f4b9ab11f4cc1f8583`. cloud-provision created each guest at its commit `8308105fc59c4e356ac2b51a924a627d6e51159c`, one guest per request after the previous case ended. Each case ran as a user unit. The run holds a failure and accepts no further case; a new run is required.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T1 / run initialization | 2026-10-04 20:10 | `--init`: publication clones, candidate full `--local` suite, baseline of the host's domains and reservations | Pass; local suite proof in `command-00017.json` of the run context |
| `debian13-socket` | 2026-10-04 20:14-20:33 | Fresh Debian 13 guest, MariaDB socket | Pass: T3-T12 |
| `debian13-tcp` | 2026-10-04 20:36-20:54 | Fresh Debian 13 guest, MariaDB TCP | Pass: T3-T12 |
| `debian13-sqlite` | 2026-10-04 20:57-21:15 | Fresh Debian 13 guest, SQLite | Pass: T3-T13 |
| `rocky8-socket` | 2026-10-04 21:18-21:34 | Fresh Rocky 8.10 guest, MariaDB socket; the case that failed at T11 on f8c457e | Pass: T3-T12 |
| `rocky8-tcp` | 2026-10-04 21:36-21:52 | Fresh Rocky 8.10 guest, MariaDB TCP; cloud-provision substituted the node label `test-933b2d800000000a` because the requested label mapped to an address reserved by another session's shut-off guest, and the handoff carries the substituted label | Pass: T3-T12 |
| `rocky8-sqlite` | 2026-10-04 21:54-22:10 | Fresh Rocky 8.10 guest, SQLite; node label substituted by `test-933b2d8000000011` for the same reason | Pass: T3-T13 |
| `debian13-build-failure` | 2026-10-04 22:12-22:18 | Fresh Debian 13 guest; installation with an absent source commit | Fail at T14 after T3 passed. The build failed at the real checkout (`make clone` error 128, one failed Ansible task), but the guest's git 2.47.3 printed `fatal: unable to read tree (<commit>)`, which the check's message list did not contain. Evidence: `command-01984.json` and `command-01985.json` in the run context |

The six positive cases passed T11 with health polled immediately after `sd_restart`, including all three Rocky 8.10 cases, and T8 passed on each Rocky 8.10 case. The verifier keeps the retried health output only when readiness expires, so no `STARTING` or `wrong-java-executable` output was retained; the passes do not record how long health reported `STARTING`.

The T14 message list was corrected in `054f1e2bb8a7fadb03618d4ed1519f0e76d82003`: the recognized messages are one constant, and a regression runs the real host git (2.47.3) checking out an absent commit in a path clone and in a `file://` clone. With the old list the regression fails on the real output and with the corrected list it passes; the full `--local` suite exited 0 without skips (Phase 1 223/0, new health 32/0, VM local 31 tests, Phase 2 13/0). Evidence: `work/m10-validation/t14-absent-ref-local-20261005T065622Z.log`, SHA256 `9fdea6eecea871e8476b869053fc731851046c09aeae272c41b02e560b96335d`. The Rocky 8.10 message for an absent commit has not been observed.

By owner decision on 2026-10-05, cloud-provision removed the seven guests of this run with `create_vm.bash -c`, each confirmed against the recorded UUID first, and cleared their stored host keys. The driver's `--verify-cleanup` returned PASS at 00:01 PDT: every owned domain, disk, seed, creation record and reservation is absent and the baseline is preserved. The current tree's driver refused the context (`Context belongs to another driver version`, exit 2, SHA256 `0b3780b2b5564734601bf469e0ec965b4de10199fe16b55f40b4b9ce90d1df8b`) because the T14 correction changed `tests/vm/driver.py`, so the check ran from the `933b2d8` tree that opened the run, exported with `git archive`. `--verdict` on the same context exited 1 (FAIL). Evidence: `work/m10-validation/933b2d8-run-verify-cleanup-20261005T070152Z.log`, SHA256 `ba6c1ca0135a73539dcaff27a3a9d5e36ec198413b776db9dda765c1bf33aa03`; `work/m10-validation/933b2d8-run-verdict-20261005T070157Z.log`, SHA256 `4f8e9e45f8a9e1843b81eaf3bdf52a6b778d415d23bf985774a9d34a43f69bd5`.

###### VM Acceptance Run On e441d59

Run context `work/m10-vm-run-e441d59-aa953a4`, opened on 2026-10-05 with `--init` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770` (implementation of `054f1e2bb8a7fadb03618d4ed1519f0e76d82003`, which carries M46 and the T14 message correction), source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` under D39, pinned Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5` and cloud-provision inventory generator `a29f4773c14274b447cb66f4b9ab11f4cc1f8583`. cloud-provision created each guest at its commit `8308105fc59c4e356ac2b51a924a627d6e51159c`, one guest per request after the previous case ended, with uncommitted work only in its register and definition files while `bin/create_vm.bash` and the scripts it sources matched that commit. Each case ran as a user unit.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T1 / run initialization | 2026-10-05 00:06-00:08 | `--init`: publication clones, candidate full `--local` suite, baseline | Pass |
| `debian13-socket` | 2026-10-05 00:09-00:30 | Fresh Debian 13 guest, MariaDB socket | Pass: T3-T12 |
| `debian13-tcp` | 2026-10-05 00:31-00:53 | Fresh Debian 13 guest, MariaDB TCP | Pass: T3-T12 |
| `debian13-sqlite` | 2026-10-05 00:55-01:20 | Fresh Debian 13 guest, SQLite | Pass: T3-T13 |
| `rocky8-socket` | 2026-10-05 01:28-01:58 | Fresh Rocky 8.10 guest, MariaDB socket; cloud-provision substituted the node label `test-e441d59000000014` because the requested label's address was held by a running guest of another session | Pass: T3-T12 |
| `rocky8-tcp` | 2026-10-05 02:00-02:25 | Fresh Rocky 8.10 guest, MariaDB TCP | Pass: T3-T12 |
| `rocky8-sqlite` | 2026-10-05 02:33-02:54 | Fresh Rocky 8.10 guest, SQLite | Pass: T3-T13 |
| `debian13-build-failure` | 2026-10-05 02:56-03:10 | Fresh Debian 13 guest; installation with an absent source commit | Pass: T3, T14; git 2.47.3 printed `unable to read tree` |
| `rocky8-build-failure` | 2026-10-05 03:24-03:42 | Fresh Rocky 8.10 guest; the same fault; cloud-init on this guest was slower than usual and its readiness wait retried 26 of 61 attempts | Pass: T3, T14; git printed `reference is not a tree` |

cloud-provision removed the eight guests with `create_vm.bash -c` and reported eight removals, each confirmed against the recorded UUID first. The driver's `--verify-cleanup` then returned PASS: every owned domain, disk, seed, creation record and reservation is absent, and the baseline is preserved. `--verdict` returned PASS (exit 0). The verifier keeps retried health output only when readiness expires, so this run recorded no `STARTING` window. Evidence: `work/m10-validation/e441d59-run-verify-cleanup-20261005T145533Z.log`, SHA256 `ba6c1ca0135a73539dcaff27a3a9d5e36ec198413b776db9dda765c1bf33aa03`; `work/m10-validation/e441d59-run-verdict-20261005T145533Z.log`, SHA256 `c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431`.

##### Closure Evidence

- Not a closure record: the implementation `9dcf72996d10a6fd3c1d3712088900c0ac6fce1d` and its register record landed on `origin/release-2.0.1`; on 2026-10-05 at 01:12 UTC, `git fetch` and `git rev-parse origin/release-2.0.1` returned `f8c457eec76184d5d12366923cd7b3c511d5bce0`.
- Not a closure record: the Rocky 8.10 compatibility revision commit `65cf077b1230f61efdba817aa697483a79a3a5d5` landed on `origin/release-2.0.1`; on 2026-10-02 at 23:52 PDT, `git fetch` followed by `git rev-parse HEAD origin/release-2.0.1` returned that commit for both.

##### GitHub Projection

Title: Automate real VM installation and runtime tests
Labels: enhancement
GitHub Milestone: 2.0.1
Observed State: OPEN
Observed Labels: enhancement
Observed Milestone: 2.0.1 / #7
Last Compared: 2026-10-05 at 01:12 UTC, `gh issue view 56 --repo jeonghanlee/epicsarchiverap-env`; OPEN, enhancement, milestone 2.0.1, assignee jeonghanlee, updatedAt 2026-09-30T04:32:58Z. The live title "Automate real container installation and VM runtime tests" and body still describe container installation; the handed-off VM design, its implementation and the run results have not been projected.


#### G7 - ansible-provision reports the exact cause of the Rocky 8.10 journald gap

Origin: 2.0.1 / G7
GitHub Issue: none
Status: Complete

##### Summary

ansible-provision observed journal entries missing from `journalctl` output on Rocky 8.10 in its M22 soak and owns the cause under D38. Two measures exist: sequence numbers with no readable entry across all journal files of a boot, and lines missing in a concurrent burst test. Debian 13 with systemd 257 showed neither. The stage-1 report below establishes the cause as a reader defect, not lost writes. This gate blocks M45 until the reproducer and scanner reach epicsarchiverap-env for M45 / T1.

##### Completion Criteria

- A minimal reproducer without the appliance runs concurrent `systemd-cat` writers on fresh Rocky 8.10 and Debian 13 guests and compares emitted with read-back lines.
- The report gives, per guest, the systemd and kernel versions, writer count and rate, emitted and read-back counts, `__SEQNUM` holes, the `journalctl --verify` result and the rate-limit exclusion.
- The report states the loss threshold, or that loss occurs without concurrency, and shares the reproducer and sequence scanner for M45 / T1.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-10-04 14:11 PDT | Pending | ansible-provision replies by session message received before this time: its M22 record row "Rocky 8 journald unlinked entries" (2026-10-04T08:26:26Z) holds 9 and 39 missing sequence numbers by passive scan, 16 on a third guest, and 65-137 lines lost per run in a 903-request two-worker burst test with one worker losing none; Debian 13 lost none in four runs. It proposes stage 1 alone first; its owner has not yet authorized execution. Recheck by asking ansible-provision for its stage-1 report. |
| 2026-10-04 15:35 PDT | Pending | Stage-1 report and follow-up by ansible-provision session message. On systemd 239-82.el8 (kernel 4.18.0-553.el8_10), `journalctl` hides an entry whose boot ID, realtime timestamp and content hash equal those of the entry it just returned, without comparing the sequence number (`sd-journal.c` `compare_with_location()` and `journal-file.c` `journal_file_compare_locations()` of v239). journald stamps the lines of one stdout read with one timestamp, so identical lines in a burst collapse to one visible entry per timestamp. The entries are stored: `journalctl --verify` passes and systemd 257 reading a copy returns all of them. One writer of 5,000 identical lines: 295 visible on Rocky 8.10, 5,000 when the same file is read with systemd 257, 5,000 on Debian 13 (257.9). Distinct lines, 1 to 16 writers, widths up to 2000, rate limiting disabled with no Suppressed record: none hidden in 18 runs. The earlier 65-137 burst figure and 9/39/16 sequence holes are this reader defect. Upstream fix: systemd commit b17f651a17cd6ec0ceac7835f2f8607fbd9ddb95, "journalctl: don't skip the entries that have the same seqnum" (2020-12-10, read back through the GitHub API), first released in v248; the latest Rocky 8.10 update `systemd-239-82.el8_10.19` still shows 295 of 5,000. The reproducer and scanner are private to ansible-provision and are sent when M45 / T1 starts. |
| 2026-10-04 18:04 PDT | Complete | Status reply by ansible-provision session message. Its owner chose header accounting for the soak: an unreturned sequence number is recorded, and every collection requires one stored entry per sequence number across fully retained journal files, read from the file headers (its local commits `28d433e` tools and `83b7744` record, not yet pushed). Header accounting found every unreturned number stored: 112,641 entries for sequence 1-112,641 on the appliance guest, and 944,713 for the retained range on the reproduction guest; 20 runs under continuous 903-request bursts passed. Tools shared for M45 / T1, present on this host: `journald-burst-repro.py` and `journal-gap-union.py` under `/data/gitsrc/ansible-provision/work/soak-etl-pass-3bdf378c/`, and the header functions in `tests/archiver-soak/etl-pass/journal_coverage.py` at `28d433e`. |

##### Closure Evidence

- The completion criteria hold: the reproducer ran on Rocky 8.10 and Debian 13 with the per-guest counts above, the cause is a systemd 239 reader defect rather than lost writes, and the reproducer and scanner are shared for M45 / T1.

#### G8 - epicsarchiverap-maven reports the exact cause of the CAJ search-port defect

Origin: 2.0.1 / G8
GitHub Issue: none; tracked in [epicsarchiverap-maven#26](https://github.com/jeonghanlee/epicsarchiverap-maven/issues/26)
Status: Complete

##### Summary

The engine creates one CAJ context per CA command thread, ten by default. On one fresh Rocky 8.10 engine, two contexts shared one UDP search port, and the 95 PVs of one context never connected. It was observed once in about ten deployments. The working hypothesis is that the kernel gives two `SO_REUSEADDR` sockets bound to port 0 the same port. epicsarchiverap-maven owns the cause under D38. The defect affects only CA channel connection, not logging. This gate blocks M45.

##### Completion Criteria

- A standalone reproducer opens ten datagram channels as CAJ does, repeats about 10,000 rounds with and without `SO_REUSEADDR`, and counts duplicate ports on a Rocky 8.10 guest and on Debian 13.
- Repeated engine starts on a Rocky 8.10 guest with the default ten command threads record `ss -uanp` of the engine JVM and connected PV counts per thread; at least 30 starts, or fewer once three occurrences are recorded.
- The report gives the reproducer source or commit, kernel and JDK versions, round and start counts, and the location of the raw `ss` outputs, as a #26 comment and register M43 of epicsarchiverap-maven.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-10-04 14:11 PDT | Pending | `gh issue view 26 -R jeonghanlee/epicsarchiverap-maven` returns OPEN, updatedAt 2026-10-04T20:32:40Z. epicsarchiverap-maven proposes stage 1 alone first and awaits its owner's authorization; the stage-1 method, stopping rule and record above were agreed by session message. |
| 2026-10-04 14:24 PDT | Pending | Interim report by epicsarchiverap-maven session message, Debian 13 half only (kernel 6.12.111, OpenJDK 21.0.12, jca 2.4.12; probe not yet committed). Ten real CAJ contexts per round shared a search port in 11 of 10,000 rounds. Raw channels bound as CAJ binds them shared a port in 16 of 10,000 rounds with `SO_REUSEADDR` and 0 of 10,000 without it. In 3 of 3 shared-port trials, all 100 unicast datagrams reached the later-bound socket and none the earlier one. The mechanism is therefore not specific to kernel 4.18. The Rocky 8.10 probe and the engine-start correlation await a guest. |
| 2026-10-04 15:19 PDT | Complete | Stage-1 report in the [#26 comment](https://github.com/jeonghanlee/epicsarchiverap-maven/issues/26#issuecomment-5985074826) (created 22:19:30 UTC, read back by `gh api`), probe at epicsarchiverap-maven `b6ff8704`, their register M43 T1 in `20e9a133`. Probe, 10,000 rounds of ten sockets each: on Rocky 8.10 (kernel 4.18.0-553.el8_10, OpenJDK 21.0.12.1), real CAJ contexts shared a port in 17 rounds, raw channels in 18 with `SO_REUSEADDR` and 0 without; Debian 13 gave 11, 16 and 0. On both, unicast to a shared port reached only the later-bound socket. Engine on the epicsarchiverap-env deploy path (903 PVs, default ten command threads) on the same Rocky guest: 30 restarts, all 903 PVs connected in each, no shared port. Zero in 30 bounds the per-start rate at about 10% (95%), so the field rate of about one in ten deployments is neither reproduced nor excluded. |

##### Closure Evidence

- The completion criteria hold: the mechanism is confirmed outside the appliance on Rocky 8.10 and Debian 13, the engine correlation ran 30 starts, and the report with counts and identifiers is the #26 comment above. Why the field rate exceeds the probe rate stays open in epicsarchiverap-maven #26.

#### M45 - Contain the journalctl reader and CAJ search-port defects in VM acceptance

Origin: 2.0.1 / M45
Identity History: none
GitHub Issue: [#58](https://github.com/jeonghanlee/epicsarchiverap-env/issues/58)
Status: Not started

##### Summary

Two independent defects can change an M10 acceptance result. The journalctl reader defect (G7) is observed on Rocky 8.10 only; the CAJ search-port defect (G8) occurs on both Rocky 8.10 and Debian 13 kernels. T8 counts three scheduled health runs from journal success lines in `tests/vm/guest.py`, and systemd 239 `journalctl` hides an entry whose realtime timestamp and content equal those of the entry it just returned. Whether a health success line meets that condition is not yet measured. T10 and T11 check CA data from the archived PV, so the CAJ defect can fail them on either OS. A CAJ failure is a real appliance defect, not a harness error. M45 measures this exposure, records evidence that tells the causes apart, and, if the measurement shows exposure, changes the epicsarchiverap-env side so a correct installation does not fail on a hidden journal entry.

##### Scope

- T1: before the failed M10 run's guests are cleaned up, measure T8 exposure read-only on its installed Rocky 8.10 `rocky8-socket` guest, whose health timer has run since installation. Count the health-unit success entries that systemd 239 `journalctl` returns, and compare them with the same journal files read by a newer reader and with G7 header accounting.
- T2: retain classifying evidence on failure. On a T8 failure, keep the health-unit entries as read and the journal files for a newer reader; a sequence hole alone does not prove a lost entry on systemd 239. On a T10 or T11 failure on either OS, keep `ss -uanp` of the engine JVM and the connection status of the archived PVs. This changes `tests/vm/guest.py` together with M46.
- T3, only if T1 shows exposure: change how the verifier establishes T8 so that a hidden identical entry cannot fail a correct installation, and verify it on Rocky 8.10.
- The CAJ defect is handled at its source: under D39 the next M10 run uses an epicsarchiverap-maven commit that carries the CAJ correction, and M45 only keeps the evidence that would classify a recurrence.

Out of scope: fixing journalctl, CAJ or jca, which their owners do under D38; publishing a patch or reporting upstream, which D38 defers until the problem is resolved; changing the M10 acceptance matrix.

##### Completion Criteria

- M45 / T1 records the T8 exposure on Rocky 8.10 over a stated window with both readers and header accounting.
- M45 / T2 shows the shipped verifier retaining the classifying evidence through its real failure path, and the next M10 run carries it.
- M45 / T3 is required only when T1 shows exposure; it then shows T8 passing a correct installation on Rocky 8.10 while identical entries are hidden, and still failing when health runs fail.

##### Dependencies And Decisions

- D38 assigns this work and keeps every fix local; D39 sets the source that the next M10 run uses.
- G7 and G8 blocked M45 when it was created; resume as Not started. Both are Complete since 2026-10-04, so M45 resumed as Not started.
- M10's Rocky 8.10 cases are exposed to the journalctl reader defect, and every case was exposed to the CAJ defect before its correction. The owner has not set an order between M10, M44 and M45; M44's dependencies are unchanged.
- T1 reads the retained `rocky8-socket` guest of the failed run `work/m10-vm-run-f8c457e-dca485f` without changing it; that run's cleanup request waits until T1 is recorded. Any other guest comes from cloud-provision on a request under separate owner authorization.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: 2026-10-04; owner authorized only the read-only T1 measurement on the retained `rocky8-socket` guest, with no change to the guest or the repository. T2, T3, any code change and any guest request need plan acceptance and separate authorization
Superseded Plan Artifacts: draft of 2026-10-04 with a fresh-guest T1 and an unconditional T3, carried by 36b17908531bc06863f47c20fa96842581a9b782, docs/milestone-2.0.1.md, M45

1. On the retained `rocky8-socket` guest, copy the journal files read-only to private evidence, count health-unit success entries with the guest's systemd 239 `journalctl` and with a newer `journalctl` over the copy, and run G7 header accounting over the same files.
2. Add evidence retention for T8 and for T10 and T11 failures to `tests/vm/guest.py` in the M46 change, with a local regression that executes the shipped retention path.
3. If T1 shows exposure, select the T8 revision from the G7 mechanism, implement it, and verify it on Rocky 8.10.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | System | Read-only count of health-unit success entries by systemd 239 and by a newer reader over copies of the same journal files, plus G7 header accounting | Retained installed Rocky 8.10 guest of the failed M10 run | Hidden health-unit entries counted over a stated window; zero means T8 is not exposed |
| T2 | Local and system | Local regression through the shipped retention path; the next M10 run carries it | Local host; next M10 run | Retention runs on the real failure path and names journal holes or the search ports and unconnected PVs |
| T3 | System | Only if T1 shows exposure: T8 with identical entries hidden under the G7 reproducer, and with a failing health run | Fresh Rocky 8.10 guest | Correct installation passes; a failing health run still fails T8 |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-04 18:59 PDT | Retained installed Rocky 8.10 `rocky8-socket` guest of the failed M10 run, systemd 239-82.el8_10.19, kernel 4.18.0-553.el8_10; its journal files copied read-only and read by host systemd 257.13 | Pass | Health unit entries until 2026-10-05 01:57:00 UTC: the guest's 239 `journalctl` and 257 over the copy both return 2,880 entries, 220 of them health success lines with 220 distinct invocations, over a 114-minute window with gaps of 30.2 s minimum, 31.0 s median and 91.9 s maximum; no health entry is hidden. Whole journal: 239 returns 12,122 entries and 257 returns 12,123; the one entry only 257 returns is an `[INFO]` line of `archiver-build.sh`, a repeated short line of the build unit, and 239 returns no entry that 257 does not. The reader defect is therefore present on the real appliance guest but did not touch the health unit. The 5 non-success invocations are four startup-allowance SKIPs and one oneshot start without an invocation id. G7 header accounting was not run, because comparing the two readers by journal cursor counts the hidden entries directly. Evidence: `work/m10-validation/m45-t1-journal-reader-exposure-20261005T015917Z.log`, SHA256 `4169db729a89fdb93b1eb5c137cf48aba09c9f8ae8b716cdd8abfc5aaf91ace2`; journal copy `work/m10-validation/rocky8-socket-journal-20261005T015749Z` |
| T2 | Pending | Local host; next M10 run | Pending | none |
| T3 | 2026-10-04 18:59 PDT | Conditional on T1 | Not required | T1 found no hidden health entry, so the T8 revision is not needed on this evidence. One guest and 114 minutes is a measurement, not proof for every run; T2 keeps the evidence that would show a hidden health line if one ever fails T8. |

##### Closure Evidence

- none

##### GitHub Projection

Title: Contain the journalctl reader and CAJ search-port defects in VM acceptance
Labels: bug
GitHub Milestone: 2.0.1
Observed State: OPEN
Observed Labels: bug
Observed Milestone: 2.0.1 / #7
Last Compared: 2026-10-04 at 22:32 UTC, `gh issue view 58 --repo jeonghanlee/epicsarchiverap-env`; OPEN, bug, milestone 2.0.1, assignee jeonghanlee, updatedAt 2026-10-04T22:32:46Z; title and body equal to the revised draft

#### M46 - Report a starting instance distinctly in the launcher health check

Origin: 2.0.1 / M46
Identity History: none
GitHub Issue: [#59](https://github.com/jeonghanlee/epicsarchiverap-env/issues/59)
Status: In progress

##### Summary

`service_start_instance` in `scripts/archappl.bash` starts `bin/run.sh` in the background and writes its `$!` to the instance PID file at once. That PID is still the shell until `run.sh` executes `catalina.sh run` and `catalina.sh` executes Java. A health check in that window finds the PID file and a live process whose executable is not Java, and `health_process_identity` reports `wrong-java-executable` as FAIL. A direct `archappl.bash health` call right after a start or restart therefore fails on a correct installation for a fraction of a second. The scheduled `--systemd` mode is not exposed: it skips for the first `SYSTEMD_HEALTH_STARTUP_SECONDS` (60) seconds after the appliance unit starts, which covers the window, and the first scheduled runs of the failed guest show `SKIP startup-allowance`. The exposed callers are an operator running `health` by hand and the VM verifier. The M10 VM run on f8c457e hit it at T11 on Rocky 8.10 through the verifier's direct call. The verifier retries only `missing-pid-file`, `missing-process` and `dead-process` during startup, within its bounded readiness deadline.

##### Scope

- Under D40, change both places. The launcher health reports a starting state for a PID that has not yet executed Java. The VM verifier waits on that state and on `wrong-java-executable` within its existing bounded readiness deadline and fails when either persists to that deadline.
- Keep `wrong-java-executable` and every other identity failure for a process that stays outside startup.
- Verdict, fixed by D42: an instance line `<name> pid=<pid> STARTING run-script` or `STARTING catalina-script`; `FAIL startup-timeout` once the process is older than the bound; an aggregate line `health STARTING instances-starting; application-readiness-not-checked`. Precedence is ERROR, FAIL, STARTING, PRESENT. `STARTING` exits 1, so the aggregation by largest status stays valid and the health unit, whose `SuccessExitStatus=3` treats skips as success, cannot mask a stuck wrapper in `--systemd` mode.
- Bound, fixed by D42: `${ARCHAPPL_HEALTH_STARTING_SECONDS:-10}`, validated like the storage threshold, with an invalid value reported as `ERROR starting-invalid-bound` and a value of 60 or more refused because it must stay below the scheduled startup allowance. The process age comes from its `/proc` start time, which `exec` keeps.
- Instance signals, observed in a scratch chain of the same shape on a Linux 6.12 host and read by the same user: in the `run-script` stage the second command-line word resolves to `<base>/bin/run.sh` and the environment does not yet carry the instance, because the exports happen after `bash` starts; in the `catalina-script` stage the command line is `<CATALINA_HOME>/bin/catalina.sh run` with no instance, while `CATALINA_BASE` in `/proc/<pid>/environ` resolves to the instance base. Reading exe, command line and environment repeats up to three times when the executable changes between reads, and then reports `ERROR process-changed-during-inspection`. Not yet checked: a process of another user, where health already needs the same read access for `/proc/<pid>/exe`, and the Rocky 8.10 kernel and the shipped Tomcat chain. Evidence: `work/m10-validation/m46-instance-signal-check-20261005T021900Z.log`, SHA256 `df3433e8074529a8b80a49520aab51d75a7eaded75f8ed0326f47caae99458ca`.
- Update the operator documentation of the health verdicts.

Out of scope: changing when the launcher writes the PID file; changing Tomcat scripts; changing the health timer schedule.

##### Completion Criteria

- M46 / T1 shows the shipped launcher chain (`service_start_instance`, `run.sh`, `catalina.sh`) is polled by the real health while the PID is still a shell, reports the starting state, and then PRESENT. A hand-built shell standing in for the chain does not count.
- M46 / T2 shows `wrong-java-executable` still reported for a live process outside startup whose executable is not the configured Java, and a stuck wrapper is reported as a failure after the time bound.
- M46 / T3 shows the VM verifier passing restarts on Rocky 8.10 and Debian 13 guests with health polled immediately after `sd_restart`, and a persistent wrong executable still fails the check at the readiness deadline.

##### Dependencies And Decisions

- D40 sets the approach and D41 sets Bash for the new launcher tests and D42 fixes the verdict, exit status and bound. Plan review on 2026-10-04 found that scheduled health skips during the startup allowance, so only direct callers are exposed, and that a verifier-only retry with the existing bounded deadline would also fail a persistent wrong executable. The owner still chose both changes for stability and reliability.
- M10 depends on M46: its next run uses a candidate that carries this change.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-04; owner accepted the plan as revised by D40, D41 and D42 after plan review
Implementation Authorization: 2026-10-04; owner authorized implementation of this accepted plan and its local verification; commit, push, publication, the VM run and every guest request need separate authority
Superseded Plan Artifacts: draft with the approach left open between a verifier-only change, a launcher change and both, carried by 3a7bcc9105afbe9d30eb0fcce8c632531a794804, docs/milestone-2.0.1.md, M46

1. Implement the starting verdict exactly as the Scope specifies, implement it in `scripts/archappl.bash`, and add the launcher regressions as a new Bash test under Phase 1 that uses `tests/lib/common.bash`, per D41, leaving `tests/health-local.py` unchanged.
2. In `tests/vm/guest.py`, add the starting verdict and `wrong-java-executable` to the startup tokens of `ready()`, with a small regression in `tests/vm/local.py` that executes the shipped retry path and shows a persistent wrong executable failing at the deadline; it stays Python because the code under test is Python (D41).
3. Document the verdict, and prove the result on real guests with T3.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Integration | The shipped chain polled by the real health while the PID is still a shell, then after Java runs | Local host | Starting verdict, then PRESENT |
| T2 | Integration | Real health against a live process with another executable outside startup, and against a stuck wrapper past the time bound | Local host | `wrong-java-executable` FAIL; stuck wrapper FAIL |
| T3 | System | VM verifier restarts with health polled immediately after `sd_restart`, recording how long health reports `STARTING`, and a persistent wrong executable | Fresh Rocky 8.10 and Debian 13 guests | Restart checks pass; the recorded window is below the bound; the persistent wrong executable fails at the deadline |

##### Verification Results

Observed on 2026-10-04 (times PDT) on the local Debian 13 host, bash 5.2.37, with the accepted plan implemented in `scripts/archappl.bash`, `tests/vm/guest.py`, the new `tests/health-starting.bash` with its fixture `tests/fixtures/tomcat/org/apache/catalina/startup/Bootstrap.java`, `tests/vm/local.py`, `tests/phase1-logic.bash` and the two health guides. Verified source SHA256: `scripts/archappl.bash` `ca22bec9ef9a64b3848a71176e1f1c02f2b4afd1355d71f13b3f0f0282616c24`, `tests/health-starting.bash` `76b8da67f8fe2e376d1fffb8c8b9449504a1a46e28639fa47be60dd74f4bffc6`, `tests/vm/guest.py` `419103264fdf2c01c89783188ab324d13ca8188efc2e6997d43bd5dc3947cd15`, `tests/vm/local.py` `99180ec08352004775683411fd8344ce9d5415ba3bed8f6a6df27a0d6daf9f7c`. The local chain is the shipped `run.sh` rendered with the Make `sed`, a stand-in `catalina.sh` that holds and then executes a live JVM named like Tomcat's Bootstrap; real Tomcat and the shipped launcher start function are not exercised here, so the real-chain proof is T3. The `env` start stage of `#!/usr/bin/env bash`, which lasts under a millisecond, is handled by the code but not exercised; the verifier's retry of `wrong-java-executable` covers it.

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-04 19:41 | Local host; shipped launcher copied as installed, real `health`, shipped `run.sh`, stand-in `catalina.sh`, live Bootstrap-named JVM | Pass | `tests/health-starting.bash`, 32 checks inside the full suite: four live JVMs PRESENT; one PID reported `STARTING run-script`, then `STARTING catalina-script`, then PRESENT with the same PID; each starting verdict exits 1 with the aggregate `health STARTING instances-starting; application-readiness-not-checked`. Evidence: `work/m10-validation/m46-local-20261005T024120Z.log`, SHA256 `52f27dfccf368f63725aa223524aa44f0247cba4b3cd653bba31b85d07e20bfa`: exit 0 without skips, Phase 1 223/0, health 20, new health 32/0, database 10, VM local 29 tests, Phase 2 13/0 |
| T2 | 2026-10-04 19:39 | Local host; the same test against the launcher before the change and eight scratch mutants | Pass | `wrong-java-executable` is still reported for an unrelated executable and for the run.sh and catalina.sh shells of another instance; `FAIL startup-timeout` in both stages; a failure outranks a start; bounds 0, 60, `abc` and 1.5 give `ERROR starting-invalid-bound` and 59 is accepted. The old launcher and each mutant (starting exits 0, no timeout, run.sh stage ignores the instance, catalina.sh stage ignores the instance, start outranks failure, bound accepts 60, any process counts as starting, no bound validation) fail the targeted check and the shipped launcher passes. Evidence: `work/m10-validation/m46-launcher-mutation-20261005T023902Z.log`, SHA256 `bbbcb78e6a994306027c2206ecb2539a8c3563bc9f60d4e20bf6ca6fa3dbd2ec`. Verifier: `StartupHealthTests` in `tests/vm/local.py` runs the shipped retry logic against the retained real verdict text and the specified starting verdict; four mutants (no `STARTING` token, no `wrong-java-executable` token, retry of every failure, deadline error without the last verdict) each fail a targeted test and the shipped code passes. Evidence: `work/m10-validation/m46-verifier-mutation-20261005T024045Z.log`, SHA256 `2d3977b46c8bf0619ca3085e81a45edd2c3017d64a25d951958ebf98155f9e7d` |
| T3 | 2026-10-04 21:18 | Fresh Rocky 8.10 and Debian 13 guests of the run on `933b2d8` | Partial | Restart checks passed in all six positive cases of both the run on `933b2d8` and the run on `e441d59` with health polled immediately after `sd_restart`, including `rocky8-socket`, `rocky8-tcp` and `rocky8-sqlite`; the failed f8c457e case passed. Not shown: the length of the `STARTING` window, which the verifier does not retain on success, and a persistent wrong executable failing at the deadline, which only the local regression covers. Evidence: the `VM Acceptance Run On 933b2d8` table in M10 |

##### Closure Evidence

- none

##### GitHub Projection

Title: Report a starting instance distinctly in the launcher health check
Labels: bug
GitHub Milestone: 2.0.1
Observed State: OPEN
Observed Labels: bug
Observed Milestone: 2.0.1 / #7
Last Compared: 2026-10-05 at 02:16 UTC, `gh issue view 59 --repo jeonghanlee/epicsarchiverap-env`; OPEN, bug, milestone 2.0.1, assignee jeonghanlee, updatedAt 2026-10-05T02:16:11Z; title unchanged and body equal to the revised draft that states the direct-call exposure and the D40 scope

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

- M43, M14 and M10 complete, G6 resolved, and all required final checks Pass. Heap measurement is Backlog work under D37 and is not required for 2.0.1.
- The annotated 2.0.1 tag and GitHub release resolve to the authorized candidate.
- Required issue states and canonical closure agree after publication.

##### Dependencies And Decisions

- M43, M14, M10, D31 and D37. Ant work is release-blocking under the current proposed scope; any deferral or source-contract change requires an explicit decision.
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
| Release Verification 4 | Candidate | post-change | Resolve changelog/source versions and confirm the shipped heap default is unchanged; no new heap recommendation is included | Combined candidate | Consistent 2.0.1 candidate within the assigned scope | Version and configuration evidence |
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
| Runtime | M41 | Measure per-component heap needs by archiving load | Carry-forward | Deferred | No | D31, D35, D36, D37 | Event-based GC observations justify the documented heap guidance; deferred 2026-10-01 until a sufficient dedicated test disk is available; [detail](#m41---measure-per-component-heap-needs-by-archiving-load) |
| DB | M42 | Apply backend selection to all database operations | Carry-forward | Deferred | No | M43, D29, D31 | Every generic DB operation uses the selected backend; unsupported operations fail before contacting another backend; deferred 2026-09-28; [detail](#m42---apply-backend-selection-to-all-database-operations) |
| UI | M13 | Site skin aligned with the rewritten mgmt UI | Milestone | Open | No | | Define the target interface and required epicsarchiverap-env skin changes; [detail](#m13---site-skin-aligned-with-the-rewritten-mgmt-ui) |
| Storage | M27 | LTS retrieval pre-processing (`pp`) | Milestone | Open | No | D21 | Decide from operating experience whether `pp` on LTS earns its disk cost; [detail](#m27---lts-retrieval-pre-processing-pp) |
| Tests | M47 | Replace the Python tests with Bash tests | Carry-forward | Open | No | D41 | Every test of shell code and every driver check runs as Bash under `tests/`; only a test of Python code stays Python; [detail](#m47---replace-the-python-tests-with-bash-tests) |

### Backlog Details

#### M41 - Measure per-component heap needs by archiving load

Origin: 265f580 / M41
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved; moved from Milestone to Backlog on 2026-10-01 under D37
GitHub Issue: [#53](https://github.com/jeonghanlee/epicsarchiverap-env/issues/53)
Status: Deferred

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

- Measure post-GC heap, event counts, individual pauses and RSS for mgmt, engine, etl and retrieval under the existing 100, 500 and 903 PV workloads. Recover the original IOC definitions, PV list and query selection before execution; the summary counts alone cannot reproduce MONITOR/SCAN settings, deadbands or waveform values.
- Capture G1 unified GC logs from JVM startup through every stage. Keep Young, Mixed and Full collections separate. Post-Young-GC heap is an observed occupancy, not proof of the complete live set; do not combine different collection types into one sizing value. Periodic `jstat` and process sampling supplement the event record.
- Derive a candidate heap and validate it against the same workloads before adding guidance beside the four-instance memory calculation in `docs/README.install.md`. State its measured configuration and limits. A multiplier alone does not establish a safe setting.

Out of scope: changing the shipped default ([M22 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md)); per-instance heap
variables, unless the measurements show one shared value cannot fit; GC
tuning beyond sizing; production storage sizing.

##### Completion Criteria

- A recorded table of the after-GC heap, GC counts and pause times per
  instance for each load in the matrix, with the epicsarchiverap-env and epicsarchiverap-maven refs and
  the measurement method used.
- Raw GC logs, workload definitions, stage boundaries, process samples, retrieval responses and ETL observations reproduce the table; missing measurements remain explicit.
- The install guide gives heap guidance supported by both the measurement table and a repeat of the relevant workloads at the proposed setting. Inconclusive data keeps this work unfinished and does not produce a numeric recommendation.

##### Dependencies And Decisions

- D31, Decision Date: 2026-09-29. Assigned to 2.0.1; assignment alone did not accept the detailed plan or authorize implementation. Earlier assignment decisions below retain their original dates.
- D35, Decision Date: 2026-10-01. The owner selected the existing three workloads rather than a larger PV/rate matrix. The accepted run schedule below preserves the reported observation durations; plan acceptance and separate implementation authorization are recorded below.
- D36, Decision Date: 2026-10-01. Implementation and measurement are deferred. The accepted plan, recovered source evidence and local preparation tool are preserved. No VM measurement started, and T1-T5 remain Pending. A new dated decision is required to resume; the earlier implementation authorization does not permit continued work during this deferral. Release assignment and M44 dependencies are unchanged.
- D37, Decision Date: 2026-10-01. Move this work to Backlog and exclude it from the 2.0.1 completion requirements. Resume only by a new dated assignment decision in an environment where the test can use sufficient dedicated disk capacity to retain archive data, complete retrieval responses and GC/collection evidence for the accepted schedule, including orderly-shutdown reserves. Confirm actual usable capacity and filesystem/inode limits before resource-limit acceptance. Existing stop thresholds remain applicable; this condition does not authorize filling a filesystem to exhaustion. The accepted full measurement plan is preserved; no reduced-load replacement experiment is assigned.

- Recorded 2026-09-28 from the owner's direction after the [M22 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md) review of the
  `9eed006` soak figures; not assigned to current work.
- Additional post-GC heap and individual GC pause measurements were requested
  from the Ansible operator on 2026-09-28. Results have not been received;
  no new measurement run is verified here. This historical request remained separate
  from [M8 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md)'s release criteria.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-01; Implementation Plan and Test Plan accepted. Run-specific resource limits and analysis settings retain their stated acceptance requirements.
Implementation Authorization: 2026-10-01; implement the accepted plan. Original-input verification and the stated run-specific acceptance requirements remain prerequisites for the corresponding measurement stages.
Superseded Plan Artifacts: original draft at epicsarchiverap-env d68f66848e1edc174e76fe77326e941baf58f850, docs/milestone-265f580.md, M41

1. Recover the operator's original PV CSV, IOC definitions, installed store policy/properties and retrieval request selection. Record their hashes and verify each stage's total, periods, waveform type/length, MONITOR/SCAN settings and deadbands. Recover the complete per-PV store URLs, partition granularities, STS/MTS hold values, ETL scheduling settings and any post-processing. Missing inputs stop workload acceptance; do not manufacture a replacement from the summary table.
2. Record immutable environment, Maven, Ansible and cloud-provision refs and the installed Java, database and EPICS versions. Use a disposable Rocky 8.10 VM with the reported topology: 2 vCPU, 4 GiB assigned RAM, no swap, MariaDB and IOC on the same VM. Record actual guest RAM and disk capacity. Preflight archive/log space and host memory; retain evidence and stop if either cannot support the run.
3. Install through the shipped Ansible/Make/service path. Start with all four JVMs at `-Xms256M -Xmx256M -XX:MaxMetaspaceSize=256M` and G1. Render `ARCHAPPL_STS_GRANULARITY`, `ARCHAPPL_STS_HOLD`, `ARCHAPPL_MTS_GRANULARITY`, `ARCHAPPL_MTS_HOLD` and `ARCHAPPL_LTS_GRANULARITY` from the recovered policy, preserving the corresponding ETL schedule and post-processing. The reported STS 5 minutes, MTS 1 hour and LTS 1 day alone do not determine exact handoff times. Do not inherit the default hold values of 2 without confirming the original values. Read back the installed policy and each archived PV's effective stores. Historical results are a comparison reference, not validation of the new source revisions.
4. Supply test-only logging through `AA_JAVA_OPTS` in `CONFIG_SITE.local`, rendered by `configure/RULES_PROPERTIES` into `archappl.conf` and exported by `scripts/archappl.bash`. Log `gc*` and `safepoint` events with UTC time, uptime, level and tags. Use a private run directory and distinct PID/startup-time filenames; disable rotation for this bounded run and monitor disk usage. Verify the effective options and writable log output of all four real JVMs. Do not change shipped defaults or enable asynchronous logging that could discard events.
5. Begin the baseline on a newly provisioned VM with an empty test database and archive. Verify that no earlier registered PVs or store files exist. Execute all three stages below in order on that appliance to preserve the defined accumulated history. Record UTC and monotonic stage boundaries and the point at which newly registered PVs actually archive. Each duration starts after stage readiness. Record preparation time separately; planned observation time totals 57 hours before any validation repeat.
6. Sample per-component RSS, CPU, process identity, host memory and filesystem usage every 5 seconds. Collect GC events continuously and retain actual HTTP requests/responses and durations using the bounded collection and stop rules below. Record actual CA/sample rates and individual ETL pass/store-transition observations. Archive the complete evidence before any VM cleanup; cleanup requires separate owner direction.
7. Produce tables by component, load, GC type and query interval. Report event count, post-GC heap distribution, maximum and p99 individual pause, Full GC count, RSS distribution and concurrent total RSS from matching timestamps. Separate GC pause durations from concurrent phases and safepoints; never use cumulative GCT or ETL metrics as individual-event durations. A zero-event class has count zero and no pause percentile; no observed old-generation reclamation is a sizing limitation, not a reason to force a GC.
8. From valid observations, derive a candidate shared heap and explain the margin, measured post-GC occupancy trend and host memory budget. Repeat the complete 100/500/903 PV sequence, 24/6/27-hour durations and final six-hour query interval on a separate newly provisioned VM with an empty test database and archive. Freeze identical source refs, workload hashes, database version, JVM non-heap options, store/ETL settings, VM resources, collector limits and client placement; change only the candidate heap. Record the initial empty-state checks for both runs and preserve the first VM and its evidence. A complete baseline plus one complete candidate repeat requires 114 observation hours, excluding provisioning and preflight. A reduced rerun requires a separate scope decision and cannot establish the original three-stage recommendation. An OOM, unexpected restart, incomplete logs, unvalidated query payload or continuing post-GC growth prevents a sizing conclusion. Record failed or inconclusive workloads rather than changing heap or resources silently. Per-component settings and further GC tuning require a separate decision.
9. Update `docs/README.install.md` only with the validated setting, applicability and limits. Keep the existing observation report unchanged; add the new run's evidence and actual results here. Project the accepted plan/results to #53 under separate issue authority.

###### Workload And Observation Schedule

| Stage | Registered PVs at 1 s / 0.1 s / 10 s | Waveforms included in total | Observation | Concurrent retrieval |
| --- | --- | --- | --- | --- |
| 100 PV | 80 / 10 / 10 | 5 x 1,000 doubles, 1 s | 24 hours | none |
| 500 PV | 480 / 10 / 10 | 5 x 1,000 doubles, 1 s | 6 hours | none |
| 903 PV | 783 / 110 / 10 | 8 x 1,000 doubles, 1 s | 27 hours | final 6 hours |

The 903 PV query interval uses four clients, a two-second wait between requests and one-hour or one-day ranges selected from the recovered original workload. Record the range mix and selected PVs. Keep client resource usage separate from appliance RSS and collect kernel OOM evidence. HTTP 200 alone is insufficient: verify decoded data, timestamps and values against actual IOC observations and retained history. The reproduced live upper-bound defect in jeonghanlee/epicsarchiverap-maven#21 must not be hidden by weakening query validation; any affected query interval remains invalid until verified with a corrected published source.

Registration periods are workload inputs. Record actual archived rates; do not equate configured periods with delivered rates. Require observed complete STS-to-MTS and MTS-to-LTS transitions for each stage's data. If the planned duration lacks the required evidence, report the stage as insufficient and obtain direction before extending it.

###### Bounded Collection And Stop Rules

After detailed plan acceptance and implementation authorization, name the sampler, CA observer, query clients and GC analysis tools. Before any preflight workload or history collection starts, record and obtain acceptance of a provisional resource-limit set: client placement, each collector/client's numeric `MemoryMax`, minimum host `MemAvailable`, minimum free space/inodes and a maximum preflight duration. Reserve memory for the OS, MariaDB, IOC and four JVMs before allocating collector budgets. Use actual guest capacity and conservative estimates of archive, response and GC-log growth plus an orderly-shutdown allowance to set the initial disk reserve; this first limit set does not depend on measurements from the preflight it protects. Missing values, an infeasible budget or a duration insufficient for the required history prevents preflight from starting. Enforce these provisional limits throughout history preparation and concurrent queries.

Conduct the separate preflight with the original IOC waveform definitions and longest original query selection. Measure simultaneous resource use and write rates within the provisional limits, then propose the final resource-limit set for the long observation runs, retaining the provisional values, measurements and reasons for each change. Obtain acceptance of the final numeric limits before the 57-hour baseline starts; missing values, failed or incomplete preflight evidence or a budget that exceeds available RAM prevents that run from starting. Identify both limit sets and their acceptance times in the run description. Use the final limits unchanged in the baseline and candidate repeat. The preflight has its own evidence and must not populate the baseline database/archive. Reaching a provisional limit invokes the same stop and evidence-preservation rules; do not relax it or continue under the same run identity. Any revised preflight limits require separate acceptance and a new preflight run identity.

Prepare the retrieval preflight on a separate disposable VM through the same real installation, IOC, CA acquisition, archive and ETL paths. Use the recovered 903 PV workload and store policy. Collect actual history covering the longest original query range for every PV selected by those requests, including any selected waveforms; a one-day range requires at least one day of real collection plus readiness and store-transition preparation. Do not substitute generated archive files, fabricated timestamps or empty responses. Retain CA observations and store evidence, then verify response timestamps, sample counts, values, waveform lengths and response bytes against that history and the recovered post-processing rules. Run all four clients concurrently with the original range mix and waits while the other collectors operate. An incomplete history, unexpectedly sparse response or invalid payload makes the resource preflight insufficient. Record collection time, complete request/response volumes, simultaneous memory peaks and disk write rates separately from the 57-hour baseline and 57-hour candidate observations; the 114-hour total excludes this additional preparation. Apply the bounded collection and stop rules during preflight as well.

Write process samples and CA events incrementally to append-only files. Stream each HTTP response to disk and decode it incrementally; retain only the current parsing state and bounded timestamp/value comparison buffers. Analyze long GC logs and compute statistics from disk. Do not accumulate all CA events or a full day of waveform responses in memory. Each collector/client must run in an identified cgroup with the applicable accepted `MemoryMax`: provisional during preflight, final during baseline and candidate observations. Monitor memory usage and cgroup limit/OOM events alongside appliance resources. A collector reaching its limit is a measurement failure, not evidence that the appliance heap is too small.

Stop owned IOC/query workload producers, end the observation interval, flush collection evidence and stop the appliance through its shipped service on the first resource or collection failure: memory at the applicable recorded collector limit, a new cgroup max/OOM event, host `MemAvailable` below the applicable accepted minimum, disk usage at or above the installed `ARCHAPPL_STORAGE_ALARM_PERCENT` (default 85), free space/inodes below the applicable recorded minimum, expiration of the provisional preflight duration, write failure, lost collector, missing observation interval, unexpected JVM restart or any JVM/client/kernel OOM. Monitor every filesystem holding archive, GC logs or collected responses. The provisional free-space reserve uses the accepted conservative estimates and shutdown allowance; the final reserve must cover the measured write rate through orderly shutdown. A 5-second check is not a hard disk cap. Preserve the VM and classify the affected interval as failed or incomplete. Do not delete archive files, extend capacity or continue with reduced collection under the same run identity.

###### Evidence And Analysis Contract

Retain one run description with source refs, workload hashes, actual JVM flags, installed policy, guest resources and start/end times. Preserve per-JVM GC logs with process identity, a process/host sample CSV, stage boundary CSV, retrieval request/response records and ETL observations. Identify every parsed GC event by JVM identity and GC ID; pair each completed pause with its own before/after heap values and event type. Calculate p99 with a documented method and report the contributing count and log-reported heap precision. Do not interpolate a periodic heap sample into a missing event measurement.

Warm-up and query intervals remain separately identifiable in the raw record. Analyze steady operation and transitions separately. Distinguish an observed JVM OOM from a client or host OOM, and report both. Hash the retained raw files and show which files and timestamps produce each result; keep private runtime identifiers out of public guidance.

Before the baseline begins, record and obtain acceptance of the analysis settings: warm-up duration after each stage's readiness and after concurrent retrieval begins, comparison interval boundaries, required GC types per component, minimum event counts, heap-change tolerance in MiB and growth-rate tolerance in MiB/hour. Derive the proposed tolerances from log precision and preflight variability, with their rationale; do not choose them from the completed baseline or candidate results. Use the same accepted settings for both runs. Missing settings prevent either long run from starting.

Evaluate each component and GC type separately within a constant workload and query condition. Exclude only the previously specified warm-up intervals from trend calculations and retain their raw events. Divide each remaining comparison interval into four equal-duration bins. Report event counts and median post-GC heap for every bin, the ordinary least-squares slope of those four medians at their bin midpoints, and the last-bin minus first-bin median. Continuing growth is present when both the positive slope and the median increase exceed their accepted tolerances. A bin below the accepted minimum count, an incomplete interval or an unavailable comparable GC type makes that comparison inconclusive; do not borrow events from another load, query condition or GC type. A zero-event class still reports count zero without a percentile; its absence blocks a recommendation only when that class is required by the accepted analysis settings. Report Young occupancy separately, and do not infer a complete live set when old-generation reclamation has not been observed. Absence of continuing growth is necessary but does not replace the candidate repeat, heap margin, host memory budget, payload checks or failure exclusions. If either run is inconclusive or any required comparison shows continuing growth, withhold the recommendation; retain evidence and obtain separate direction before extending a run or revising the analysis settings.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Installation | Render test overrides through the shipped Make configuration, install via Ansible and start through the real launcher/service; inspect all four JVM command lines, GC files, effective per-PV stores, hold values and ETL properties; verify initial empty database/archive | Disposable Rocky 8.10 VM | Recovered policy reproduced completely; correct refs, 256M heaps, G1 and logging; every component writes identifiable logs |
| T2 | Measurement | Verify accepted provisional limits before preflight history collection; prepare full-range real history on a separate VM; run all four original query clients with the collectors; validate sample coverage, values and response bytes; use measured resources to propose final limits and verify acceptance before baseline; parse complete GC logs and compare with original lines | Preflight with actual one-day history where requested, plus all four components over the three stages | Provisional limits enforced from preflight start; complete responses and simultaneous resource measurements retained; sparse, invalid or failed preflight blocks baseline; both limit sets and acceptance times recorded; final limits enforced unchanged in both long runs; actual boundary failure stops collection and preserves evidence; reproducible statistics with explicit unavailable fields |
| T3 | Runtime | Run the original 100/500/903 PV workloads through real CA acquisition, archive queries and ETL; measure process and host resources throughout | 24/6/27-hour schedule; final six hours with four query clients | Original workload/settings verified; actual archived rates and both ETL transitions observed; query data validated; all failures and resource constraints recorded |
| T4 | Sizing | Repeat the complete three-stage 57-hour sequence through the shipped path with the candidate heap; verify matching refs, workload/policy hashes, collector budgets and resources plus initial empty database/archive; apply the previously accepted warm-up intervals, event counts and four-bin trend method to both runs; compare GC, resources and payload validity | Separate newly provisioned VM; otherwise identical recorded conditions and analysis settings | Only heap differs; complete comparable evidence without JVM/client/host OOM or unexpected restart; every required trend comparison has sufficient events and does not trigger the fixed continuing-growth criterion; growth, insufficient evidence or analysis changes prevent recommendation |
| T5 | Documentation | Recalculate each public table from retained raw evidence and match guide settings and limits to the validated repeat | Canonical results and install guide | Recommended heap, source/configuration applicability, margin and measurement limits agree with real results |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Disposable VM | Pending | none |
| T2 | Not run | Disposable VM | Pending | none |
| T3 | Not run | Disposable VM | Pending | none |
| T4 | Not run | Disposable VM | Pending | none |
| T5 | Not run | Canonical results and install guide | Pending | none |

Input recovery observed on 2026-10-01: the clean ansible-provision checkout at `13608fea2b65758f9999c8d462e82a50570146bd` contains the preserved original tools and fixtures under `tests/archiver-soak/`, last changed at `1827046eaa216c1d27c0c22ca57ab729154b50e1`. The real `sha256sum --check SHA256SUMS` in that directory passed all 30 entries. Direct CSV inspection confirmed incremental populations of 100, 400 and 403 PVs; their ordered concatenation equals the 903-PV list, with 903 unique PV names and store keys, 880 MONITOR and 23 SCAN requests. Cumulative periods and waveform counts match all three planned stages. The combined fixture SHA256 is `037a92691bc23a6dcac37ec3613ad19c9f80b93b689209ec8dc403b519eaf594`.

The preserved `baseline/store-test.yml` specifies STS `PARTITION_5MIN`, hold 2; MTS `PARTITION_HOUR`, hold 2; and LTS `PARTITION_DAY`. `baseline/register.py` and `baseline/load_retrieval.py` preserve the registration and four-client query selection: one-hour windows for all selected PVs, with one-day windows allowed only for eligible one-second scalars, and a two-second wait. The original installed policy/properties and effective per-PV stores have not yet been recovered; the separate pilot policy is not evidence for that run. The retained query client counts streamed samples but does not validate or retain full response payloads, so it cannot satisfy the new measurement contract unchanged. These local input checks do not pass T1-T5.

Evidence storage placement remains undecided. The original operator record at ansible-provision `13608fea2b65758f9999c8d462e82a50570146bd`, `docs/milestone-38560eb.md`, M14 / T21, reports approximately 156 GB served in six hours. This is a reported response volume, not a new disk measurement. Retaining complete responses therefore requires a separately accepted evidence-storage budget and placement; the 20 GiB appliance disk alone cannot hold that reported volume. No provisional resource limits or VM measurement start have been accepted yet.

Local preparation tool: `tests/heap/inspect-inputs.py` reads the preserved source inputs without VM contact or mutation and emits their hashes, populations and outstanding execution prerequisites. On 2026-10-01, its real CLI returned 0 against the original files at Ansible `13608fea2b65758f9999c8d462e82a50570146bd`, with the expected three stages and `execution_ready: false`. Supplying a different requested commit returned 77. These are local input-inspection results; T1-T5 remain Pending.

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
#### M47 - Replace the Python tests with Bash tests

Origin: 2.0.1 / M47
Identity History: none
GitHub Issue: none
Status: Open

##### Summary

D41 sets Bash for new tests and names the conversion of the existing Python tests as the long-term direction, because Python versions differ across the supported systems and Python test code needs rewriting as the language changes. Seven tracked Python files total 3,755 lines: `tests/vm/driver.py` 1,233, `tests/vm/guest.py` 761, `tests/vm/local.py` 658, `tests/health-local.py` 472, `tests/database-config.py` 344, `tests/install-payload.py` 145 and `tests/heap/inspect-inputs.py` 142. The shell scripts and Make rules of the repository contain no Python; the tests are the only dependency. The guest verifier needs `python3` on the guest, which a fresh Rocky 8.10 guest lacks until Ansible installs it, and the guest then runs Python 3.6 while the host runs 3.13.

The row is Open because its scope and order are unsettled: the owner has set the direction, not a schedule or an acceptance rule.

##### Scope

- Inventory every Python file and the consumers that call it, from `tests/phase1-logic.bash` and `tests/run-all-tests.bash`.
- Convert the tests of shell code first (`tests/health-local.py`, `tests/database-config.py`, `tests/install-payload.py`), keeping each assertion and its real-path method.
- Decide separately how the VM driver and guest verifier are replaced, since they carry the largest logic and run on guests with different Python versions.

Out of scope: any change to what the tests assert; replacing Ansible, which the control host still needs.

##### Completion Criteria

- No test of shell code, Make rules or the installed appliance remains Python.
- Each converted test fails on the defect it covers, shown by a mutation of the shipped code.
- The full local suite and the VM matrix keep their current pass conditions without skips.

##### Dependencies And Decisions

- D41 sets the direction. A dated owner decision on scope and order is required before it can become Not started.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. After the owner decision, inventory each Python file with its callers and the behavior it asserts.
2. Convert the shell-code tests one file at a time, then plan the driver and verifier.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Each converted test against the shipped code, then against a scratch mutation that reintroduces the defect it covers | Local host | Passes on the shipped code and fails on its mutation |
| T2 | System | Full `tests/run-all-tests.bash --local` and the VM matrix | Local host; fresh guests | Same pass conditions as before, no skips |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Pending | Local host | Pending | none |
| T2 | Pending | Local host; fresh guests | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Replace the Python tests with Bash tests
Labels: enhancement
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

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
