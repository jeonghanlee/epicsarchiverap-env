# Work Register

Release line: 2.0.1
Milestone index: 2.0.1
Canonical path: `docs/milestone-2.0.1.md`
Canonical branch or ref: release-2.0.1
Git upstream: none (local branch; no push authorized)
Remote tracker: jeonghanlee/epicsarchiverap-env, GitHub milestone 2.0.1 planned, not created

Next session entry point: review and accept the draft plans in this document, resolve G6 against the pinned aa-maven source, then prepare the planning commit. GitHub projection follows that commit. Implementation, source-pin changes, release actions and publication require separate authority.

## Scope

The 2.0.1 patch cycle covers backend isolation safeguards, removal of obsolete Ant integration after the source contract is confirmed, real installation test automation and measured heap guidance. The owner assigned these four candidates on 2026-09-29. The proposed order is M43, M14, M10, M41, then M44. G6 may be investigated while M43 is planned; its completion gates M14 and release readiness. The sequence and detailed plans await acceptance.

Out of scope: adding SQLite deletion, table-query, backup or restore support; changing the shipped heap default; UI skin changes; LTS pre-processing; data migration. Existing 2.0.0 release objects remain immutable. No next release after 2.0.1 is assigned.

Baseline: aa-env `d68f66848e1edc174e76fe77326e941baf58f850`, published 2.0.0 tag commit `386c91d74086313efe04e0b64eb5dacfd91f8389`, aa-maven pin `d8a7813f40083c1bf7148e6c3b7bffd368d70ee0`. Prior release results are historical evidence and do not satisfy 2.0.1 checks. No implementation or runtime verification has started.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DB | M43 | Reject operations on an unselected database backend | Milestone | Not started | Yes | D31 | Unsupported and invalid selections stop before configuration writes or DB contact; [detail](#m43---reject-operations-on-an-unselected-database-backend) |
| Gate | G6 | aa-maven lands Ant removal with the per-site build contract | External gate | Open | No | | Exact usable source commit and overlay contract confirmed; [detail](#g6---aa-maven-lands-ant-removal-with-the-per-site-build-contract) |
| Build | M14 | Remove Ant leftovers from aa-env | Milestone | Blocked | No | G6, D31 | No Ant integration remains; four real WARs retain the site overlay; [detail](#m14---remove-ant-leftovers-from-aa-env) |
| Tests | M10 | Phase 3 and 4 install tests (container, VM) | Milestone | Not started | Yes | D31 | Real container install and VM runtime checks pass; [detail](#m10---phase-3-and-4-install-tests-container-vm) |
| Runtime | M41 | Measure per-component heap needs by archiving load | Carry-forward | Not started | Yes | D31 | Event-based GC observations justify the documented heap guidance; [detail](#m41---measure-per-component-heap-needs-by-archiving-load) |
| Release | M44 | Verify and publish release 2.0.1 | Milestone | Not started | No | M43, M14, M10, M41, D31 | Released objects and required post-release checks pass; [detail](#m44---verify-and-publish-release-201) |

### Decisions

D9, D17, D21 and D29 retain historical decisions from the closed 2.0.0 generation; references within those rows use that historical scope. D31 owns current release assignment and supersedes the earlier deferral of M14 for this cycle.

| ID | Decision | Decision Date |
| --- | --- | --- |
| D9 | Boundary between the two repositories: aa-env owns provisioning, deployment layout, service configuration, source baseline pinning, and the site skin; aa-maven owns source, the Maven build (Ant and Gradle leftovers consolidated onto Maven), dependency management, upstream cherry-pick policy, and independent bug fixes. Build-flavored leftovers inside aa-env are aa-env cleanup rows gated on aa-maven rows; compile verification moves to aa-maven CI and aa-env keeps install tests. No aa-env row migrates; the legacy build items already exist on the aa-maven register. | 2026-09-11 |
| D17 | Align aa-env with aa-maven on Ant removal: it is deferred out of Phase 1 on both sides. aa-maven moved its Ant-removal row (their M10) to the backlog on 2026-09-19 (their D7). aa-env confirmed this first-hand at aa-maven modernize `3c96141d`, whose commit subject is `Move M7 and M10 to the backlog and close out Phase 1`: their register `docs/milestone-daff1b7.md` (historical peer observation; current contract must be rechecked) carries M10 as `Deferred` with an assignment-history row recording the 2026-09-19 move, and the `maven-antrun-plugin` execution `sitespecificantscript` there still drives `build.xml` target `sitespecificbuild`. G10's completion criterion therefore covers the tomcat-servlet-api pin (observed 9.0.122, not the 9.0.121 the gate first named) and the Maven CI only, and G10 closes on that basis. aa-env M14 (Ant leftovers) becomes Deferred and leaves M8's dependency list; G6 stays Open and blocks no row; M14 returns to Not started only by a new dated decision. | 2026-09-20 |
| D21 | The archive store's filesystem and the ETL timing become aa-env work (M26), scoped to the test environment first rather than to production storage architecture. Two facts drive it. On the provisioned hosts the archive store resolves to the root volume, nothing in the install path mounts a dedicated one, and `ARCHAPPL_STORAGE_TOP` only names a directory, so an archiver that fills its store fills `/` and takes the whole host; no quota or threshold exists anywhere in the chain. Separately, the shipped store configuration puts MTS at `PARTITION_MONTH` with `hold=2`, so samples do not leave MTS for roughly two months and the second ETL hop cannot be observed in any realistic test run. Production storage sizing, per-tier media selection and retention for real data stay outside this row. | 2026-09-21 |
| D29 | Limit current DB changes to rejecting `sql.drop` and `sql.table.drop` for SQLite or an invalid backend before invoking any database client. Record full backend consistency as Backlog M42, deferred from current execution; SQLite deletion support and the remaining DB command behavior require a later accepted plan. | 2026-09-28 |
| D31 | Assign the four 2.0.1 candidates: M41, M10, M14 and the backend isolation safeguard split from M42 as M43. Preserve M42 expansion, M13 and M27 as Backlog. M14 resumes as Not started after G6 completes and is Blocked until then. Plans and the proposed order remain draft; assignment authorizes documentation and issue preparation only. | 2026-09-29 |

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
GitHub Issue: none
Status: Not started

##### Summary

At the cycle baseline, `configure/RULES_SQL` guards `sql.drop` and `sql.table.drop`, but `db.*` and the four application-table query targets remain MariaDB-specific and invalid selections fall into the MariaDB schema branch. These are code observations; no new reproduction has run.

##### Scope

- Inventory the Make DB entrypoints, configuration generation and standalone helper dispatch. Validate backend values before side effects.
- Preserve existing MariaDB behavior over TCP and Unix sockets and existing SQLite schema load/list behavior. Reject unsupported SQLite operations clearly before MariaDB is contacted.
- Update operator documentation and real-path regression checks.

Out of scope: implementing new SQLite table deletion, application-table queries, lifecycle, backup or restore; schema changes; data migration. Those remain M42.

##### Completion Criteria

- All inventoried generic entrypoints validate the selector before writes or DB contact.
- SQLite and invalid values cannot invoke a MariaDB-only operation, including prerequisites and standalone helpers; rejection returns nonzero.
- Supported MariaDB and SQLite behavior remains verified with the shipped rules, scripts and schemas.

##### Dependencies And Decisions

- D31 splits the safeguard from M42; M42 remains Deferred. Existing selection and schema support is historical 2.0.0 work, not an unfinished dependency.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the supported/rejected matrix for every entrypoint in `configure/RULES_SQL` and the DB helpers; distinguish explicit MariaDB administration from generic operations.
2. Add backend validation before prerequisites can generate configuration or contact another backend; extend the existing deletion guard without adding SQLite functionality.
3. Document rejected operations and execute routing negatives plus supported operations on disposable databases.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Integration | Execute every unsupported/invalid operation through shipped Make targets and standalone helpers; inspect exit status and pre/post configuration and database state | Isolated checkout and disposable DBs | Nonzero rejection before writes or MariaDB contact |
| T2 | Database | Execute supported schema load/list and MariaDB operations through real commands with shipped source schemas | SQLite; MariaDB TCP and Unix socket | Selected database has expected results; other database remains unchanged |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Isolated checkout and disposable DBs | Pending | none |
| T2 | Not run | SQLite; MariaDB TCP and Unix socket | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Reject operations on an unselected database backend
Labels: bug
GitHub Milestone: 2.0.1 (planned)
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### G6 - aa-maven lands Ant removal with the per-site build contract

Origin: 265f580 / G6
GitHub Issue: none
Status: Open

##### Summary

aa-maven removes Ant from its build (its register row M10) and reports the
commit together with the post-Ant contract for the per-site build step that
`build.xml` target `sitespecificbuild` used to run inside
`src/sitespecific/<site>`. Affected M14, which D17 deferred; this gate is reactivated for 2.0.1 and blocks M14 until the pinned-source contract is confirmed. No current completion has been observed.

aa-maven register row: `docs/milestone-daff1b7.md` (historical peer observation; current contract must be rechecked) M10 (Ant removal, Deferred
and moved to the aa-maven backlog 2026-09-19, their D7).

##### Completion Criteria

- A cross-session response names the aa-maven commit and states how (or
  whether) the per-site `build.xml` step is executed after Ant removal.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-20 | Pending | aa-maven reports M10 (Ant removal) Deferred and moved to its backlog 2026-09-19 (their D7), with no landing commit. aa-env re-derived it at aa-maven modernize `3c96141d`: their register `docs/milestone-daff1b7.md` (historical peer observation; current contract must be rechecked) carries M10 as `Deferred` with an assignment-history row for the 2026-09-19 move, and the `maven-antrun-plugin` execution `sitespecificantscript` still runs `<ant antfile="${project.basedir}/build.xml" target="sitespecificbuild"/>`, so the per-site contract is still Ant-based. Recheck by reading that path and the pom at the then-current aa-maven `modernize` head. |

##### Closure Evidence

- none

#### M14 - Remove Ant leftovers from aa-env

Origin: 265f580 / M14
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved
GitHub Issue: none
Status: Blocked

##### Summary

aa-env still carries Ant pieces from the pre-Maven build: an Ant build file
in the site overlay and `ANT_HOME` / `ANT_PATH` / `ANT_OPTS` in the site
configuration. [M11 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md) already removed Ant from the package lists. Once
aa-maven removes Ant from the build (its M10) and states how the per-site
build step is replaced, aa-env removes its half.

##### Scope

- `site-template/siteid/build.xml` (33 lines): remove, or replace per the
  post-Ant sitespecific contract aa-maven reports.
- `configure/CONFIG_SITE`: `ANT_HOME`, `ANT_PATH`, `ANT_OPTS` (lines 4, 9,
  43–49) and any `.local` preset that sets them.
- `configure/os/*.pkgs`: verify that no `ant` package remains. [M11 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md) already
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

- D31, Decision Date: 2026-09-29. Assigned to 2.0.1; detailed plan remains draft and implementation is not authorized. Earlier assignment decisions below retain their original dates.

- Decision Date: 2026-09-29. Transferred from Milestone to Backlog for the 2.0.0 cycle close. Existing status, scope, dependencies, plan and verification evidence are preserved; no next release is assigned.
- G6 (aa-maven M10 and the post-Ant sitespecific contract); still Open, and it blocks this 2.0.1 work; resume as Not started
- D9
- D17. 2026-09-20: Ant removal is deferred out of Phase 1 on both sides, so this
  row previously moved to Deferred and left [M8 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md)'s dependency list. aa-maven moved its M10
  to the backlog 2026-09-19; this row returns to Not started only by a new dated
  decision.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: original draft at aa-env d68f66848e1edc174e76fe77326e941baf58f850, docs/milestone-265f580.md, M14

1. Read the contract aa-maven reports with G6; decide remove-or-replace for
   `site-template/siteid/build.xml`.
2. Add the failing phase 1 assertions, then remove the Ant pieces.
3. Run `make build` against the aa-maven commit named in G6.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Logic | `tests/run-all-tests.bash --phase=1` | This host | New assertions pass |
| T2 | Build | `make build` with `SRC_TAG` at the G6 commit | This host | Four real WARs retain `archappl.properties` and `policies.py`; the mgmt WAR retains the site CSS, images and template changes. Compare entries and bytes with the generated overlay; use the source-owned log4j2 configuration |

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
GitHub Milestone: 2.0.1 (planned)
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M10 - Phase 3 and 4 install tests (container, VM)

Origin: 265f580 / M10
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved
GitHub Issue: none
Status: Not started

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

- D31, Decision Date: 2026-09-29. Assigned to 2.0.1; detailed plan remains draft and implementation is not authorized. Earlier assignment decisions below retain their original dates.

- Decision Date: 2026-09-29. Transferred from Milestone to Backlog for the 2.0.0 cycle close. Existing status, scope, dependencies, plan and verification evidence are preserved; no next release is assigned.
- Decision Date: 2026-09-22. Assigned from Backlog to Milestone. The test host and implementation plan remain to be defined. Status stays Open; assignment alone does not accept or authorize implementation.
- none

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: original draft at aa-env d68f66848e1edc174e76fe77326e941baf58f850, docs/milestone-265f580.md, M10

1. Define reproducible container and libvirt VM entrypoints under `tests/docker/` and `tests/vm/`, with isolated installation roots and explicit prerequisites.
2. Run the documented prerequisites and all ordered installation targets through the shipped Make system; build real WARs with Maven Wrapper.
3. Verify installed payloads, configuration and failure propagation in Phase 3; verify the real systemd stack, HTTP identity, acquisition and retrieval in Phase 4.
4. Make missing infrastructure or unimplemented checks return an explicit non-success result; document evidence retention and run the shipped cumulative runner.

Ordering proposal: perform the final installation run after M43 and M14 so the installed candidate includes the DB guards and final source pin; development of the automation can proceed independently. The host, backend matrix and infrastructure ownership must be fixed during plan acceptance.

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

Title: Automate real container installation and VM runtime tests
Labels: enhancement
GitHub Milestone: 2.0.1 (planned)
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M41 - Measure per-component heap needs by archiving load

Origin: 265f580 / M41
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved
GitHub Issue: #53
Status: Not started

##### Summary

The 256M heap default ([M22 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md)) is a test default; the available measurements
do not establish a heap recommendation by load. The ansible-provision soak
on aa-env `9eed006`, aa-maven `3c96141d` and Ansible `dca2255` covers 100,
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
  instance for each load in the matrix, with the aa-env and aa-maven refs and
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
Superseded Plan Artifacts: original draft at aa-env d68f66848e1edc174e76fe77326e941baf58f850, docs/milestone-265f580.md, M41

1. Fix the load matrix, stage durations and concurrent queries during plan acceptance. Capture identified GC events using G1 unified GC logging on every component; periodic `jstat` may supplement RSS and counters but cannot replace event measurements.
2. Run the matrix on a disposable VM and record the measurements.
3. Derive and document the recommendation.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime | Run each load of the matrix with the G1 event logs with optional `jstat` supplements on all four instances; read the stable after-GC heap, the GC counts and pause times, and the RSS | Disposable VM | A complete table per instance and load, tied to the aa-env and aa-maven refs |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Disposable VM | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Measure per-component heap needs by archiving load
Labels: enhancement
GitHub Milestone: 2.0.1 (planned)
Observed State: OPEN
Observed Labels: enhancement
Observed Milestone: none
Last Compared: 2026-09-29, `gh issue view 53 --repo jeonghanlee/epicsarchiverap-env`; OPEN, enhancement, milestone none, assignee jeonghanlee, updatedAt 2026-09-29T18:33:45Z

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
- No source pin is changed during planning. A new aa-maven commit is selected only after G6 is satisfied and the source change is accepted.

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

The source POM belongs to aa-maven. This cycle does not independently bump it. APPNAME, SRC_VERSION and install-path derivation remain checked for consistency; no environment numeric version field has been identified beyond the changelog and release objects.

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
| Release Verification 1 | Baseline | pre-change | Record current aa-env commit, effective source pin, changelog and existing released refs before candidate version changes | Checkout and origin | Reproducible pre-change baseline | Private evidence with public hashes |
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
| UI | M13 | Site skin aligned with the rewritten mgmt UI | Milestone | Open | No | | Define the target interface and required aa-env skin changes; [detail](#m13---site-skin-aligned-with-the-rewritten-mgmt-ui) |
| Storage | M27 | LTS retrieval pre-processing (`pp`) | Milestone | Open | No | D21 | Decide from operating experience whether `pp` on LTS earns its disk cost; [detail](#m27---lts-retrieval-pre-processing-pp) |

### Backlog Details

#### M42 - Apply backend selection to all database operations

Origin: 265f580 / M42
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved
GitHub Issue: none
Status: Deferred

##### Summary

`DB_BACKEND` selects the appliance JDBC resource and MariaDB service dependency,
but does not consistently select aa-env's database commands. At `46faeb9`,
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

The current narrow correction rejects SQLite and invalid backend values at
`sql.drop` and `sql.table.drop`. It does not implement SQLite deletion or
complete backend isolation for the other commands.

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
| T1 | Command routing | Run every entrypoint with both backends, both local configuration locations, command-line overrides and invalid values | Isolated aa-env checkout and disposable databases | Selected client and identity agree; invalid or unsupported operations fail before side effects |
| T2 | Database integration | Load the shipped schemas, insert records, query all four tables, drop tables and reload through real targets | SQLite and MariaDB over TCP and Unix domain socket | Expected schema and rows in the selected database; unselected database unchanged |
| T3 | Database lifecycle | Exercise creation, removal, backup and restore, including a non-default name or file, WAL mode and defined active-connection handling | Disposable databases under the service account | Documented lifecycle and ownership; backup restores the expected rows; failures propagate |
| T4 | Deployment | Follow the documented sequence for each backend and exercise the appliance configuration database | Debian 13 and Rocky Linux 8 disposable VMs | JDBC, helpers and service dependencies use the selected backend consistently |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Isolated aa-env checkout and disposable databases | Pending | none |
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

- Decision Date: 2026-09-29. Transferred from Milestone to Backlog for the 2.0.0 cycle close. Existing status, scope, dependencies, plan and verification evidence are preserved; no next release is assigned.
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
