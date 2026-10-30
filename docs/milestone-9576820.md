# Work Register

Release line: master (unversioned development on the default branch maven)
Milestone index: 9576820
Canonical path: `docs/milestone-9576820.md`
Canonical branch or ref: maven
Git upstream: origin/maven
Remote tracker: jeonghanlee/epicsarchiverap-env; no open release milestone (observed 2026-10-29 via `gh api repos/jeonghanlee/epicsarchiverap-env/milestones`)

Next session entry point: Open M1 in `docs/milestone-9576820.md`. Inventory the shipped database-operation entrypoints, compare their current behavior with M1 Scope and Test Plan, and prepare the detailed operation matrix and lifecycle choices for plan acceptance. Then follow M2, M3 and M4 in that order. M5, M6 and M7 remain Deferred; their later order is not authorization to resume.

## Scope

This generation owns the seven unfinished items on the default development branch. The assigned work order is M1, M2, M3 and M4. Deferred work is ordered M5, M6 and M7 for later reconsideration. Assignment authorizes preparation of the existing scope; implementation-plan acceptance and implementation authorization remain separate. Historical results remain evidence for their recorded inputs.

Out of scope for this assignment update: product implementation, VM provisioning, a new numbered release, and changes to GitHub issues or milestones.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DB | M1 | Apply backend selection to all database operations | Carry-forward | Not started | Yes | D4, D11 | Selected-backend queries, deletion, lifecycle, backup and restore pass real database tests; [detail](#m1---apply-backend-selection-to-all-database-operations) |
| Install | M2 | The operating system target rewrites `configure/CONFIG_SITE.local` and the installers run it first | Milestone | Not started | No | M1, D7, D11 | Installers refuse extra assignments before overwriting generated OS configuration; [detail](#m2---the-operating-system-target-rewrites-configureconfig_sitelocal-and-the-installers-run-it-first) |
| Tests | M3 | Replace the Python tests with Bash tests | Carry-forward | Not started | No | M2, D6, D11 | Shell and Make tests run in Bash with the same assertions and defect detection; [detail](#m3---replace-the-python-tests-with-bash-tests) |
| Tests | M4 | Fix the findings of the review of the VM driver | Carry-forward | Not started | No | M3, D8, D11 | Driver findings are fixed or decided, with defect-sensitive tests and a real guest verdict; [detail](#m4---fix-the-findings-of-the-review-of-the-vm-driver) |

Ready indicates work-order eligibility; it does not accept a draft plan or authorize implementation. M1 is the next plan-preparation entry point.

### Decisions

| ID | Decision | Decision Date |
| --- | --- | --- |
| D1 | Reset the current development register on maven without assigning a numbered release or authorizing implementation of Backlog work. Preserve the seven unfinished items and their existing execution conditions. | 2026-10-29 |
| D2 | Measure heap with the existing 100, 500 and 903 PV workloads, preserving workload and query conditions and the accepted detailed schedule. | 2026-10-01 |
| D3 | Keep heap measurement deferred. Preserve its accepted plan and recovered evidence. Resume only after a new dated assignment decision and sufficient dedicated storage for archive data, complete responses, measurement evidence and shutdown reserves. The resource and analysis acceptance requirements remain binding. | 2026-10-01 |
| D4 | Keep the expansion of database operations deferred. Backend isolation safeguards are already implemented; SQLite deletion, application-table queries, lifecycle, backup and restore require a later accepted plan and a new dated decision to resume. | 2026-09-28 |
| D5 | Leave LTS pre-processing undecided until an operating installation supplies measured disk growth and real retrieval patterns. Production storage architecture is outside the test-environment scope. | 2026-09-21 |
| D6 | Write new tests in Bash, retaining Python only where testing Python code requires it. Conversion of existing Python tests is a long-term direction; scope, order and acceptance still need a dated decision. | 2026-10-04 |
| D7 | Make installers stop before changing anything when configure/CONFIG_SITE.local contains more than its operating-system include, and name ../CONFIG_SITE.local as the place for site settings. The OS target remains generated. Assign this work to the release after 2.0.1 before execution. | 2026-10-11 |
| D8 | Defer VM-driver findings from the 2026-10-27 review; the accepted release verification used the real local installation procedure instead. A dated timing decision is required to resume. Driver files must not change during an open run started with them. | 2026-10-27 |
| D9 | Plan release verification so each check proves one claim from stated inputs and repeats only when those inputs change. Preserve assertions and checks that prove different claims; scope and order still need a dated decision. | 2026-10-28 |
| D10 | Keep surviving Backlog work unassigned; no next numbered release line is open. | 2026-10-28 |
| D11 | Assign M1, M2, M3 and M4 to the current development cycle in that order and prepare their existing scopes for execution. These are work-order dependencies, not asserted technical constraints. Supersede the earlier deferral or unassigned scheduling conditions for these four items, including the requirement to wait for a numbered release for M2. Keep draft plans unaccepted and implementation unauthorized until their separate approvals. | 2026-10-29 |
| D12 | Keep M7 deferred and defer M5 and M6. Their later reconsideration order is M5, M6, M7, after M4. Each requires a new dated resumption decision; the order does not waive measurement, resource or plan-acceptance requirements. | 2026-10-29 |

### ID Migration

All seven IDs changed together on 2026-10-29 to match the selected work order. The Old ID column refers to the state before this renumbering; Origin remains the immutable initial identity.

| Old ID | Current ID | Reason | Updated References |
| --- | --- | --- | --- |
| M2 | M1 | Selected work order, 2026-10-29 | Work table, detail, decisions, dependencies and next entry point |
| M5 | M2 | Selected work order, 2026-10-29 | Work table, detail, decisions, dependencies and next entry point |
| M4 | M3 | Selected work order, 2026-10-29 | Work table, detail, decisions, dependencies and next entry point |
| M6 | M4 | Selected work order, 2026-10-29 | Work table, detail, decisions, dependencies and next entry point |
| M3 | M5 | Selected work order, 2026-10-29 | Work table, detail, decisions, dependencies and next entry point |
| M7 | M6 | Selected work order, 2026-10-29 | Work table, detail, decisions, dependencies and next entry point |
| M1 | M7 | Selected work order, 2026-10-29 | Work table, detail, decisions, dependencies and next entry point, heap report and test guide links |

### Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| 9576820 / M2 | `docs/milestone-9576820.md`, Backlog, maven | `docs/milestone-9576820.md`, Milestone, maven; assigned 2026-10-29 by D11 | this synchronization commit | this synchronization commit |
| 9576820 / M5 | `docs/milestone-9576820.md`, Backlog, maven | `docs/milestone-9576820.md`, Milestone, maven; assigned 2026-10-29 by D11 | this synchronization commit | this synchronization commit |
| 9576820 / M4 | `docs/milestone-9576820.md`, Backlog, maven | `docs/milestone-9576820.md`, Milestone, maven; assigned 2026-10-29 by D11 | this synchronization commit | this synchronization commit |
| 9576820 / M6 | `docs/milestone-9576820.md`, Backlog, maven | `docs/milestone-9576820.md`, Milestone, maven; assigned 2026-10-29 by D11 | this synchronization commit | this synchronization commit |

### Milestone Details

#### M1 - Apply backend selection to all database operations

Origin: 9576820 / M2
Identity History: M2 -> M1 on 2026-10-29; renumbered to match the selected work order
GitHub Issue: none
Status: Not started

##### Summary

Backend isolation safeguards are implemented in commit 3560216c5315088a05bb2e9dea263eac075c52bf: SQLite `db.*` commands skip, and unsupported operations or invalid selections reject before side effects. SQLite deletion, application-table queries, lifecycle, backup and restore are assigned for plan preparation by D11; implementation has not started. Database identity corrections already honor `DB_NAME`, `DB_ADMIN` and the JDBC resource name; they do not implement this remaining scope.

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

- D11 assigns this work to the current development cycle and changes Deferred to Not started on 2026-10-29, superseding the scheduling restrictions of D4 and D10. The full operation plan still requires acceptance before implementation.
- The prerequisite isolation safeguards are complete at 3560216c5315088a05bb2e9dea263eac075c52bf; they are evidence, not a remaining work dependency.
- Preparation starts by inventorying the real Make targets and setup-script query, deletion, lifecycle, backup and restore entrypoints against the existing Scope and Test Plan. Record unresolved lifecycle choices before seeking plan acceptance.

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

#### M2 - The operating system target rewrites `configure/CONFIG_SITE.local` and the installers run it first

Origin: 9576820 / M5
Identity History: M5 -> M2 on 2026-10-29; renumbered to match the selected work order
GitHub Issue: none
Status: Not started

##### Summary

The targets `<os>.conf` (`debian13.conf`, `rocky8.conf` and the others in `configure/RULES_TOMCAT`) delete `configure/CONFIG_SITE.local` and write one line into it, the include of `configure/os/<os>.mk`. Every installer runs its operating system target as its first step, so a value that an operator wrote into `configure/CONFIG_SITE.local` is lost when the installer runs. `../CONFIG_SITE.local`, next to the checkout, is not touched and is the place for site values.

Observed 2026-10-11 on the author's host. `make -n debian13.conf` prints `rm -f <checkout>/configure/CONFIG_SITE.local` and `echo "include \$(TOP)/configure/os/debian13.mk" > <checkout>/configure/CONFIG_SITE.local`. The plan of `bash scripts/install-local-sqlite.bash --plan --skip-packages` lists `make ... debian13.conf` as its first make step. Recheck with those two commands.

D7 (2026-10-11) chose refusal before changes. D11 (2026-10-29) assigns preparation after M1 in the current development cycle without waiting for a numbered release.

##### Scope

- The installers stop, before they change anything, when `configure/CONFIG_SITE.local` holds a line other than the include of its operating system file, print those lines and name `../CONFIG_SITE.local` (D7). The target keeps writing the one line.
- Keep the documented place for site values, `../CONFIG_SITE.local`.

Out of scope: changing the content of the operating system files `configure/os/*.mk`.

##### Completion Criteria

- An assignment written into `configure/CONFIG_SITE.local` is either present after `make <os>.conf` or the installer stops before it changes anything and names `../CONFIG_SITE.local`.
- The check for this behavior runs the real `make <os>.conf` target in an isolated copy of the repository.

##### Dependencies And Decisions

- D11 assigns this work and changes Deferred to Not started on 2026-10-29. It supersedes the next-numbered-release scheduling condition of D7 and the unassigned condition of D10; D7's refusal behavior and site-settings location remain the accepted direction.
- M1 is a work-order dependency selected by D11, not a technical prerequisite.
- Preparation must locate the first side effect in each installer and show how the refusal check precedes it. Review the draft's direct-target test against the installer refusal requirement before plan acceptance.
- Installed `config.d` support does not protect the separate checkout file `configure/CONFIG_SITE.local`.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. After the owner decision, change the `<os>.conf` rules in `configure/RULES_TOMCAT`, or the first step of the installers.
2. Add the real-target check to `tests/phase1-logic.bash`.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | In an isolated copy of the repository, write an assignment into `configure/CONFIG_SITE.local`, run the real `make debian13.conf`, and read the file | Local host | The assignment is present, or the installer stops first with a message that names `../CONFIG_SITE.local` |
| T2 | Local | The full local suite `bash tests/run-all-tests.bash --local` | Local host | Passes with the same groups as before |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Pending | Local host | Pending | none |
| T2 | Pending | Local host | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: The operating system target rewrites `configure/CONFIG_SITE.local` and the installers run it first
Labels: bug
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M3 - Replace the Python tests with Bash tests

Origin: 9576820 / M4
Identity History: M4 -> M3 on 2026-10-29; renumbered to match the selected work order
GitHub Issue: none
Status: Not started

##### Summary

The shell, Make and installed-appliance tests include Python programs that run across different host and guest Python versions. At 95768200a49e965ef2dd1949919e955af982aff6, `git ls-files tests` lists 13 Python files, including the config.d and local-install checks. This inventory supersedes the earlier seven-file count; it does not change the accepted direction or authorize conversion.

D6 sets Bash as the direction for shell-code tests. D11 assigns the existing scope after M2; the detailed conversion plan and acceptance remain pending.

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

- D11 assigns this work and changes Open to Not started on 2026-10-29 under the existing conversion scope. It settles work order and supersedes D10's unassigned condition; D6's Bash direction remains in force.
- M2 is a work-order dependency selected by D11, not a technical prerequisite.
- Preparation must refresh the Python-file and caller inventory after M1 and M2, then map every assertion to its proposed real-path Bash check. Driver/verifier replacement details and plan acceptance remain unresolved; the assignment does not accept a replacement design.

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

#### M4 - Fix the findings of the review of the VM driver

Origin: 9576820 / M6
Identity History: M6 -> M4 on 2026-10-29; renumbered to match the selected work order
GitHub Issue: none
Status: Not started

##### Summary

The delegated third-person review of `tests/vm/driver.py`, `guest.py`, `local.py` and their documents on 2026-10-27 found one Must-Fix and further findings. The driver run of the same day stopped at its check `build_proof` (`driver.py`, near line 958), whose required Make list lacks `conf.install`, which the installer runs. D8 replaced the driver run for release 2.0.1 with a check that followed the install pages. D11 now assigns this work after M3, whose changes must be considered when checking the historical findings.

##### Scope

- Must-Fix: the driver loads its state (`driver.py` near lines 1153, 1160 and 1166) before it takes the exclusive lock (near line 1188); take the lock first.
- Make the required Make list of `build_proof` agree with the Make steps that the installers run, including `conf.install`.
- Minor findings: the tool reference is not verified; the tool checkouts are checked only at initialization; the SSH host pin is weaker than the stated global known-hosts handling; an interruption before the first record fails the whole run; the refusal check accepts any exit status 2; the snapshot comparison covers the whole libvirt host; a malformed context returns inconsistent exit codes.
- Strengthen the tests: in the mutation sample of the review, 101 of 125 mutations survive; the verdict gates, the cleanup verification, `build_proof`, the adoption path, the species mapping and the guest actions have no test that fails on a mutation.
- Correct the three places where the documents and the code disagree.

Out of scope: choosing a driver replacement (M3 owns that decision); changing the accepted historical local-installer verification method.

##### Completion Criteria

- Each finding of Scope is fixed or carries an owner decision that leaves it.
- Each fixed finding has a test that fails on a mutation that reintroduces it.
- The driver files do not change while a run that started with them is open.

##### Dependencies And Decisions

- D11 assigns this work and changes Deferred to Not started on 2026-10-29, superseding the scheduling restrictions of D8 and D10. The prohibition on changing driver files during an open run remains in force.
- M3 is a work-order dependency selected by D11. Because M3 may replace the driver or its tests, recheck each historical finding against the resulting implementation before drafting fixes; do not assume the old Python files or line numbers still apply.
- Preparation must account for every finding as still present, already resolved with evidence, or requiring a decision. Preserve the completion criteria and real-guest verification; obtain plan acceptance before implementation.
- The current record does not identify the three documentation discrepancies or provide a locator for the original review. Before plan acceptance, recover the 2026-10-27 review and record its durable source plus all three document paths, passages and corresponding code behavior in this detail. If that evidence cannot be recovered, obtain a scope decision before accepting the plan; do not infer the missing items or treat them as resolved.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. After the owner decision, list every finding with its location in the current files of `tests/vm`.
2. Fix the Must-Fix and `build_proof` first, each with a failing test before the fix.
3. Work through the Minor findings and the surviving mutations in the order the owner sets.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | The tests of `tests/vm` against the shipped code, then against a scratch mutation for each fixed finding | Local host | Passes on the shipped code and fails on each mutation |
| T2 | System | One real case of the driver on a fresh guest after the fixes | Local libvirt host; fresh guest | The case reaches its verdict without a driver error |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Pending | Local host | Pending | none |
| T2 | Pending | Local libvirt host; fresh guest | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Fix the findings of the review of the VM driver
Labels: enhancement
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

## Backlog

All rows remain unassigned and Deferred. Their reconsideration order is M5, M6 and M7; they are excluded from the release tally.

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Storage | M5 | LTS retrieval pre-processing (`pp`) | Milestone | Deferred | No | D5, D12 | Measured retrieval benefit and disk cost support a dated decision on LTS pre-processing; [detail](#m5---lts-retrieval-pre-processing-pp) |
| Tests | M6 | Reduce the repeated checks of the release verification plan | Carry-forward | Deferred | No | D9, D12 | The next release plan maps each check to one claim, its inputs and a re-run trigger; [detail](#m6---reduce-the-repeated-checks-of-the-release-verification-plan) |
| Runtime | M7 | Measure per-component heap needs by archiving load | Carry-forward | Deferred | No | D2, D3, D12 | Measured GC events and validated candidate heaps support load-specific guidance; dedicated storage and a new resumption decision required; [detail](#m7---measure-per-component-heap-needs-by-archiving-load) |

### Backlog Details

#### M5 - LTS retrieval pre-processing (`pp`)

Origin: 9576820 / M3
Identity History: M3 -> M5 on 2026-10-29; renumbered to match the selected work order
GitHub Issue: none
Status: Deferred

##### Summary

The unresolved question is whether retrieval pre-processing on LTS benefits the Default and VerySlow policies enough to justify additional disk usage. `pp` keeps raw data and writes auxiliary pre-calculated files. It is mutually exclusive with `reducedata`, which the other policies use. The decision requires real retrieval patterns and measured disk growth.

##### Scope

- Whether the Default and VerySlow policies gain `pp` on LTS, and with which
  operator and interval.
- `site-template/policies.py.in` and the policy guide, if the answer is yes.

Out of scope: `reducedata` on the other policies; the retrieval API; the
storage filesystem implementation and production storage architecture.

##### Completion Criteria

- After the appliance has run with real queries and a known disk growth rate,
  a dated decision either adds `pp` to the named policies or records that the
  retrieval gain does not justify the additional storage.

##### Dependencies And Decisions

- D12 changes Open to Deferred on 2026-10-29. Reconsider this work after M4 and before M6; the order does not automatically resume it. A new dated resumption decision is required.
- D5 still requires an operating installation with measured disk growth and real retrieval patterns before deciding whether to use `pp`.
- This work concerns policy selection in epicsarchiverap-env; the processing implementation belongs to epicsarchiverap-maven. No implementation plan has been accepted.

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

#### M6 - Reduce the repeated checks of the release verification plan

Origin: 9576820 / M7
Identity History: M7 -> M6 on 2026-10-29; renumbered to match the selected work order
GitHub Issue: none
Status: Deferred

##### Summary

D9 sets the direction. In the cycle of release 2.0.1 the sources were built and the local suite ran several times for one tree: the suite before each commit, the real build with the site overlay in Release Verification 2, and a build inside every installation of Release Verification 3 and 6.

D12 defers this work for reconsideration after M5 and before M7. The direction remains set; the detailed scope and plan acceptance remain pending.

##### Scope

- List each check of the release verification plan of release 2.0.1 with the claim it proves and the inputs it reads (files, sources, hosts).
- Find the checks that prove the same claim from the same inputs, and propose which one stays.
- State the rule for a re-run: a check runs again only when one of its inputs changed; a change to a file that no test reads does not run the suite.

Out of scope: removing a check that proves a different claim; changing what a test asserts; the VM driver (M4 and M3).

##### Completion Criteria

- The plan of the next release lists each check once with its claim, its inputs and its re-run trigger.
- No two checks of that plan prove the same claim from the same inputs.

##### Dependencies And Decisions

- D12 changes Open to Deferred on 2026-10-29. Reconsider this work after M5 and before M7; the order does not automatically resume it. A new dated resumption decision is required.
- D9's direction remains in force; detailed scope and plan acceptance remain unresolved.
- The [release 2.0.1 verification plan and results](https://github.com/jeonghanlee/epicsarchiverap-env/blob/95768200a49e965ef2dd1949919e955af982aff6/docs/milestone-2.0.1.md#m44---verify-and-publish-release-201) are the historical inputs for identifying repeated checks.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. After the owner decision, build the list of checks of release 2.0.1 from the Release Verification Plan and the Integrated Verification table.
2. Mark each overlap and propose the check that stays.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Review | Derive for each check of the drafted plan the claim it proves and the inputs it reads, then compare every pair | The register of the next release | No two checks prove the same claim from the same inputs |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Pending | The register of the next release | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Reduce the repeated checks of the release verification plan
Labels: enhancement
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M7 - Measure per-component heap needs by archiving load

Origin: 9576820 / M1
Identity History: M1 -> M7 on 2026-10-29; renumbered to match the selected work order
GitHub Issue: [#53](https://github.com/jeonghanlee/epicsarchiverap-env/issues/53)
Status: Deferred

##### Summary

The 256M heap default ([the recorded heap-default decision](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md)) is a test default; the available measurements
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

Out of scope: changing the shipped default ([the recorded heap-default decision](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md)); per-instance heap
variables, unless the measurements show one shared value cannot fit; GC
tuning beyond sizing; production storage sizing.

##### Completion Criteria

- A recorded table of the after-GC heap, GC counts and pause times per
  instance for each load in the matrix, with the epicsarchiverap-env and epicsarchiverap-maven refs and
  the measurement method used.
- Raw GC logs, workload definitions, stage boundaries, process samples, retrieval responses and ETL observations reproduce the table; missing measurements remain explicit.
- The install guide gives heap guidance supported by both the measurement table and a repeat of the relevant workloads at the proposed setting. Inconclusive data keeps this work unfinished and does not produce a numeric recommendation.

##### Dependencies And Decisions

- D2 preserves the accepted workload and measurement scope.
- D3 suspends execution despite the earlier implementation authorization. A new dated assignment decision, sufficient dedicated storage, accepted resource limits and accepted analysis settings are required before resuming.
- D12 retains Deferred on 2026-10-29 and places this work after M5 and M6 for later reconsideration. The order does not start a measurement or waive any existing prerequisite.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-01; Implementation Plan and Test Plan accepted. Run-specific resource limits and analysis settings retain their stated acceptance requirements.
Implementation Authorization: 2026-10-01; accepted execution is suspended by D3 pending a new dated resumption decision. Original-input verification and the stated run-specific acceptance requirements remain prerequisites for the corresponding measurement stages.
Superseded Plan Artifacts: original heap measurement draft at epicsarchiverap-env d68f66848e1edc174e76fe77326e941baf58f850, docs/milestone-265f580.md

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
GitHub Milestone: none
Observed State: OPEN
Observed Labels: enhancement
Observed Milestone: none
Last Compared: 2026-10-29 22:52 PDT via `gh issue view 53 --repo jeonghanlee/epicsarchiverap-env`; OPEN, enhancement, no milestone, assignee jeonghanlee, updatedAt 2026-10-05T17:33:17Z. The issue body still gives an illustrative 100/500/1000/2000 PV matrix; the accepted canonical plan uses 100/500/903 PVs. The remote body requires reconciliation before measurement execution.

## History

| Reset Date | Prior State Commit |
| --- | --- |
| 2026-10-29 | 95768200a49e965ef2dd1949919e955af982aff6 |
