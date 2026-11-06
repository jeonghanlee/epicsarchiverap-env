# Work Register

Release line: master (unversioned development on the default branch maven)
Milestone index: 9576820
Canonical path: `docs/milestone-9576820.md`
Canonical branch or ref: maven
Git upstream: origin/maven
Remote tracker: jeonghanlee/epicsarchiverap-env; no open release milestone (observed 2026-10-29 via `gh api repos/jeonghanlee/epicsarchiverap-env/milestones`)

Next session entry point: Review the M16 server.xml permission correction and its completed regression evidence before commit preparation. The Debian 13 SQLite direct baseline passed T1-T5; D43 corrected the separate restrictive-checkout failure, with original failure evidence retained. Replacement Perl automation, the remaining five cases and T6 are Pending and need separate authorization. M5, M6 and M7 remain Deferred. Production upgrades follow [Upgrade an appliance during a maintenance window](../book/src/install/upgrade-maintenance.md).

## Scope

This generation owns seventeen work items on the default development branch. The assigned work is M1, M2, M3, M4, M8, M9, M10, M11, M12, M13, M14, M15, M16 and M17; M11, M13, M14 and M15 were assigned on 2026-11-02 by D26, D29, D27 and D28, M9 on 2026-11-03 by D30, M8 on 2026-11-03 by D32, which closes M8 by its decision and retires M4, M17 on 2026-11-03 by D34, M10 on 2026-11-05 by D37, M12 on 2026-11-05 by D39, and M16 on 2026-11-06 by D42. Deferred work is ordered M5, M6 and M7 for later reconsideration. Assignment authorizes preparation of the existing scope; implementation-plan acceptance and implementation authorization remain separate. Historical results remain evidence for their recorded inputs.

Current M16 execution follows D42 and the installed-file permission correction authorized by D43. Replacement automation, the remaining installation cases, a new numbered release, and GitHub mutations require separate authorization.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DB | M1 | Apply backend selection to all database operations | Carry-forward | Complete | No | D4, D11, D13, D14 | T1-T5 and correction checks passed; landed at c4b27bc; [detail](#m1---apply-backend-selection-to-all-database-operations) |
| Install | M2 | The operating system target rewrites `configure/CONFIG_SITE.local` and the installers run it first | Milestone | Complete | No | M1, D7, D11, D15 | T1-T5 passed on Debian 13 and Rocky 8.10; landed at de8301c; [detail](#m2---the-operating-system-target-rewrites-configureconfig_sitelocal-and-the-installers-run-it-first) |
| Tests | M3 | Replace the Python tests with Perl tests | Carry-forward | Complete | No | M2, D6, D11, D16, D17, D18, D19, D20, D21, D22, D23, D24, D25 | T1-T4 passed, T2 and T4 with the waivers of D25; landed at 6efd7db; [detail](#m3---replace-the-python-tests-with-perl-tests) |
| Tests | M4 | Fix the findings of the review of the VM driver | Carry-forward | Complete | No | M3, D8, D11, D32 | Retired by D32 on 2026-11-03: the driver is not repaired, because the VM test is rebuilt on the local installer scripts (M16); [detail](#m4---fix-the-findings-of-the-review-of-the-vm-driver) |
| Tests | M11 | Remove the false failures of the converted tests | Carry-forward | Complete | No | M3, D24, D26 | A run directly after another run passes the port probe of the runtime test, a pid file with text fails clearly, and the signal test passes from a background job; T1-T2 passed; landed at 134857b; [detail](#m11---remove-the-false-failures-of-the-converted-tests) |
| Tests | M14 | Declare scalar prototypes on the check helper of the Perl tests | Carry-forward | Complete | No | M3, D24, D27 | The six tests that define `check` declare scalar prototypes and pass unchanged, and a list-context match in a call of `check` fails the check; T1-T2 passed; landed at 23e98e8; [detail](#m14---declare-scalar-prototypes-on-the-check-helper-of-the-perl-tests) |
| Tests | M15 | Stop the instances that an aborted runtime test did not record | Carry-forward | Complete | No | M3, D24, D28 | A run of the runtime test that ends early, including the pid file mutation, leaves no JVM of its instances, and the recorded mutations keep their verdicts; T1-T2 passed; landed at 79f2177; [detail](#m15---stop-the-instances-that-an-aborted-runtime-test-did-not-record) |
| Tests | M13 | Leave only the pass record of the tests and use a local temporary folder | Carry-forward | Complete | No | M3, D26, D29 | A passing run of the nine Perl tests and of `tests/local-install-pv.bash` leaves no file of the run, a failed run or `KEEP_WORKSPACE=1` keeps them, and the tools use `TMPDIR` or `work/scratch/tmp`; T1-T3 passed; landed at 6049646; [detail](#m13---leave-only-the-pass-record-of-the-tests-and-use-a-local-temporary-folder) |
| Tests | M9 | Keep the last sample of the PV time-range test inside the query range | Carry-forward | Complete | No | M3, D23, D30, D31 | The unmutated time-range test passes in all 30 runs of a series, and its stable mutation verdicts stay as before; T1-T2 passed; landed at e39252e; [detail](#m9---keep-the-last-sample-of-the-pv-time-range-test-inside-the-query-range) |
| Tests | M8 | Decide the replacement of the VM driver and guest verifier | Carry-forward | Complete | No | D6, D16, D17, D32 | Decided by D32 on 2026-11-03: none of the three Python files is kept, and a new Perl test on the local installer scripts replaces them (M16); [detail](#m8---decide-the-replacement-of-the-vm-driver-and-guest-verifier) |
| Install | M17 | Upgrade an installed appliance by comparing its state with the checkout | Milestone | Complete | No | D33, D34 | T1-T9 satisfy the completion criteria within their recorded input and environment limits; read-failure correction and verification record landed at 5da67a8; [detail](#m17---upgrade-an-installed-appliance-by-comparing-its-state-with-the-checkout) |
| Tests | M10 | Close the gaps that the Python tests left in the Perl tests | Carry-forward | Complete | No | M3, D24, D37, D38 | T1-T2 passed: 156 mutations killed and five equivalent for the recorded entry paths; all 113 former kills retained; landed at 37ba14f; [detail](#m10---close-the-gaps-that-the-python-tests-left-in-the-perl-tests) |
| Tests | M12 | Share the helper code of the Perl tests | Carry-forward | Complete | No | M3, M10, M14, D24, D27, D39, D40 | T1-T4 extraction evidence and the R1 import-correction checks are retained with their recorded limits; landed at cb7a041; [detail](#m12---share-the-helper-code-of-the-perl-tests) |
| Tests | M16 | Build the VM installation test on the local installer scripts | Milestone | In progress | No | D16, D32, D41, D42, D43 | Direct Debian 13 SQLite baseline: T1-T5 passed. The restrictive-checkout permission correction passed local and affected-guest checks; its original failure remains recorded. Five other cases, fault controls and replacement automation remain Pending; [detail](#m16---build-the-vm-installation-test-on-the-local-installer-scripts) |

Ready indicates work-order eligibility; it does not accept a draft plan or authorize implementation. Assigned work: 13 Complete, 1 In progress. No row is Ready.

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
| D13 | Extend the existing database commands for M1 instead of adding a parallel common command set. Keep db.create, db.drop and db.show as the public entrypoints and select their behavior through DB_BACKEND. Preserve MariaDB database-and-account creation and deletion; replace SQLite skipping for these entrypoints with file lifecycle and inspection operations. This selects the command interface for the draft plan, not full plan acceptance or implementation authorization. | 2026-10-29 |
| D14 | Preserve the existing table-deletion scope for M1: sql.drop and sql.table.drop remove every user table in the selected database on both backends, including tables beyond the four shipped appliance tables. Do not target database-engine internal tables. Keep the database or SQLite file itself; db.drop remains the separate database-removal operation. This selects deletion scope for the draft plan, not full plan acceptance or implementation authorization. | 2026-10-30 |
| D15 | For M2 refusal diagnostics, report the configuration file and offending line numbers without printing line contents or values. Name ../CONFIG_SITE.local as the destination for site settings. This supersedes the raw-line output requirement in D7; refusal before changes remains required. | 2026-10-30 |
| D16 | Write the tests that replace the Python tests in Perl, one language for all of them, at the language level of the oldest supported interpreter (Perl 5.26.3 on Rocky Linux 8.10) and with the modules that every supported system has after its package preparation; tests that already run in Bash stay. This amends the language of D6, which named Bash; D6 still keeps Python only where testing Python code requires it. Conversion scope, order and acceptance remain open. | 2026-10-30 |
| D17 | Leave the VM driver (`tests/vm/driver.py`), the guest verifier (`tests/vm/guest.py`) and the driver test (`tests/vm/local.py`) out of M3. Their replacement, and the language of any replacement, is decided in M8. M3 converts the tests of shell code, Make rules and the installed appliance outside that trio, and updates only the places in the trio that call a converted test. | 2026-10-30 |
| D18 | Read the completion criterion without skips as no new skip: the skips that the local suite prints today (the SQLite lifecycle check and the database maintenance client check, which need a disposable guest, and the real Base binary resolution, which needs `AA_TEST_EPICS_BIN`) may remain, and no converted test adds one. | 2026-10-30 |
| D19 | Allow the replacement tests new prerequisites where the Perl core has no equivalent, and document them as prerequisites of the local suite: `xmllint`, `script` and `sqlite3`, and on Rocky Linux the packages that provide the Perl modules missing after its package preparation. The final list follows from the modules the converted tests use. | 2026-10-30 |
| D20 | Treat `tests/heap/inspect-inputs.py` as a preparation tool, not a test: it reads the preserved soak inputs and emits their hashes and populations. It stays outside M3 and remains Python, the one Python file beside the VM driver trio of M8 that D6 and D16 do not convert. | 2026-10-30 |
| D21 | Read "without skips" as the rule of the VM driver's completeness check (`local_suite_complete`): the output of the local suite, run with a real EPICS Base supplied through `AA_TEST_EPICS_BIN` on a host that meets its other optional prerequisites (the source clone, a real Java, the `mysql` client and a `/dev/shm` on its own filesystem), has no `[SKIP]` line, no line that starts with `SKIP:` and no unittest skip. The two announcements in `tests/phase1-logic.bash` of checks that run in `tests/database-operations.bash` on a disposable guest stop using the skip marker and read as plain statements; this change was made on 2026-10-30. This supersedes D18. | 2026-10-30 |
| D22 | `tests/config-d.pl` removes the workspace of a passing case and keeps the workspace of a failed case, or of every case when `KEEP_WORKSPACE=1`, and prints the kept path, as `tests/health-local.pl` and `tests/database-config.pl` do; the Python `tests/config-d.py` kept every workspace. | 2026-10-31 |
| D23 | Convert `tests/local-install-pv-range.py` with its behavior, including the way it keeps the query and the response of the replaced HTTP transport in two files that can come from different attempts, and handle that defect afterwards as the separate item M9. | 2026-10-31 |
| D24 | Read the first check (T1) of M3 as parity with the Python tests: a mutation that a Python test kills is killed by its Perl test, and the survivors are the same set. The Perl tests keep the defects of the Python tests for now, and every defect or improvement that the conversion shows in the Perl tests becomes a Backlog item instead of a change inside M3: M10 closes the gaps that the mutations left, M11 removes false failures and leftover evidence, M12 shares the helper code, and M9 stays as it is. | 2026-11-02 |
| D25 | Close the checks T2 and T4 of M3 without the eight-case VM run and without the mutations on the guests. The VM matrix keeps its pass conditions because `tests/vm/driver.py` and `tests/vm/guest.py` are identical to the prior state commit of this generation and call no converted test; the part of T2 that the conversion touches is the local suite, which ran with a real EPICS Base and passed the completeness check of the driver. The mutations were run on the local host for all nine tests, and the guests ran the shipped code of the guest tests on Debian 13 and Rocky Linux 8.10. | 2026-11-02 |
| D26 | Assign M11 on 2026-11-02 in the reduced form the owner chose: it covers the free-port probe and the pid file of `tests/config-d-runtime.pl` and the SIGINT disposition of the verifier that `tests/local-install-pv-signals.pl` starts, and its status changes from Open to Not started. The rule for the evidence that passing runs keep becomes the separate Backlog item M13, which the owner decides. | 2026-11-02 |
| D27 | Split M12 in two on 2026-11-02. The scalar prototypes of the helpers `check` and `fail` become M14, which is assigned and In progress; the shared module for the helper code stays M12, Open, and keeps these prototypes. | 2026-11-02 |
| D28 | Assign M15 on 2026-11-02 after the owner accepted its revised plan and authorized the implementation: the abnormal stop of the runtime test finds the JVMs of the run by their command line. Its status changes from Open to In progress. | 2026-11-02 |
| D29 | Settle one rule on 2026-11-02 for the nine Perl tests and for `tests/local-install-pv.bash`. A passing run leaves only its output and exit status and removes the files it generated, that is its workspace and the evidence folder of the verifier it started, only those of this run. A failed run or `KEEP_WORKSPACE=1` keeps them and prints the path. Temporary files go below the folder that `TMPDIR` names, or else below `work/scratch/tmp` of the checkout, which the tool creates when it is missing; the verifier script follows `TMPDIR` and keeps `/tmp` as its default. This sets M13 and changes it from Open to In progress. | 2026-11-02 |
| D30 | Assign M9 on 2026-11-03 after the owner accepted its plan and authorized the implementation: the query and the response of a data request are recorded in one file that is replaced as a whole. Its status changes from Open to In progress. | 2026-11-03 |
| D31 | Replace the plan of M9 after its measurement rejected the premise: the test with one exchange file failed in 3 of 12 runs and the committed test in 1 of 12, and all four failures show the last sample one second past the upper bound of the query of the same attempt. The fixture holds the time of the last sample at the upper bound, the one-file change is removed uncommitted, and M9 is renamed. | 2026-11-03 |
| D32 | Rebuild the VM installation test on the existing tools. For each case the test requests a fresh guest from cloud-provision, runs this repository's local installer script on the guest, checks that the installed appliance stores and retrieves PVs, asks cloud-provision to remove the guest and reports; cloud-provision alone answers for the creation, freshness and removal of the guest, the test does not run Ansible, and it is written in Perl (D16), not Python. The current `tests/vm/driver.py`, `guest.py` and `local.py` are not repaired and stay until the new test replaces them: M4 is retired, M8 is closed by this decision, and M16 holds the new test. | 2026-11-03 |
| D33 | Upgrade an installed appliance through the local installer scripts themselves: they compare the installed state with the state the checkout renders, print a plan per layer with the reason, and run only the layers that differ, with the existing Make rules and a stop of the appliance only when an installed layer changes. `site-template/.versions` is installed with the appliance so the host records what was installed and when. The schema layer compares the source SQL file at the installed commit with the file at the target commit by `git diff`, because the installed appliance was installed from this checkout and its commit is recorded in the installed `version.txt`: a difference that only adds whole tables runs the schema load, which is safe to repeat, and any other difference stops with the diff, because the source carries no migration. The classpath files are settled by the finding in M17. The tool stays Bash. The work is M17. | 2026-11-03 |
| D34 | Assign M17 on 2026-11-03 after the owner accepted its plan and authorized the implementation: the installer scripts inspect the installed appliance and run only the layers that differ. Its status changes from Open to In progress. | 2026-11-03 |
| D35 | Revise the plan of M17 before its step 3: the comparison of the installed appliance with the checkout is a helper script `scripts/inspect-local-install.bash`, so that a test can run it alone against a temporary tree; the checkout update and the printed comparison are the new option `--inspect` of the installer scripts; `--plan` keeps its meaning, prints the commands and executes nothing, because the tests and the install pages treat it as free of side effects; a normal run inspects first and asks its confirmation after the inspection, naming the layers that will change. The owner accepted the revision and, after the review of the revised text ended, renewed the implementation authorization for its steps 3 to 6. | 2026-11-03 |
| D36 | Keep the optional soft IOC question of the installer scripts first, before the lock and the checkout update, and narrow the rule of D35 that a run which changes nothing asks nothing to "asks no confirmation": the test of the EPICS preflight requires that an unprepared EPICS environment stops the installer before any `make` or `sudo` step, and moving the question behind the inspection made that test fetch the source and render the working checkout, so that it needed the network and left the checkout rendered for the last backend. The owner chose this over rewriting the test (2026-11-03). | 2026-11-03 |
| D37 | Assign M10 and authorize its first implementation batch: correct the four reproduced gaps in `tests/install-payload.pl`, verify the real installation path and rerun its fourteen recorded mutations. The remaining forty-four survivors are outside this batch; M10 remains In progress until its full completion criteria are met. | 2026-11-05 |
| D38 | Extend the accepted M10 implementation plan and authorization to the remaining eight tests, all forty-four original survivors, and outstanding verification. Add checks through the shipped paths or record demonstrated equivalent mutations with their reasons; shipped product code remains outside the scope. | 2026-11-05 |
| D39 | Assign M12 as the next work item and prepare its shared-helper plan against the completed M10 and M14 tests. Preserve existing test behavior and mutation verdicts. Plan acceptance and implementation authorization remain separate. | 2026-11-05 |
| D40 | Accept the reviewed shared-helper plan at c30be1d and authorize M12 implementation and verification. Reuse the retained Rocky test guest, preserve earlier evidence, run in a new directory and shut it down after testing. | 2026-11-05 |
| D41 | Revise M16 around observable installation results: installation from documented prerequisites, intended runtime configuration, real PV acquisition and retrieval, preservation across restart and unchanged re-application, and detection of actual database or storage faults. Use the existing installer and PV verifier before automating repeated operations. Replace the skipped-Make-step criterion with the relevant failed outcome. Keep the six selected OS/backend cases and separate M17 upgrade evidence. This authorizes plan revision and review, not assignment, implementation or VM operations. | 2026-11-06 |
| D42 | Assign M16, accept the reviewed plan at 02a79f5 and authorize its first direct Debian 13 SQLite T1-T5 execution, including a fresh test VM request and shutdown with disk and evidence retained. Replacement automation, the remaining matrix, T6 faults and product corrections are not authorized by this first-case execution decision. | 2026-11-06 |
| D43 | Authorize correction of the installed server.xml readability failure observed during M16, with regression verification through the shipped installation rules and the affected guest. Establish mode 0644 during server.xml installation independently of checkout permissions; keep genuine inspection read failures as refusals. Preserve the original failed evidence and record corrective results separately. | 2026-11-06 |

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
| 9576820 / M11 | `docs/milestone-9576820.md`, Backlog, maven | `docs/milestone-9576820.md`, Milestone, maven; assigned 2026-11-02 by D26 | this synchronization commit | this synchronization commit |
| 9576820 / M15 | `docs/milestone-9576820.md`, Backlog, maven | `docs/milestone-9576820.md`, Milestone, maven; assigned 2026-11-02 by D28 | this synchronization commit | this synchronization commit |
| 9576820 / M13 | `docs/milestone-9576820.md`, Backlog, maven | `docs/milestone-9576820.md`, Milestone, maven; assigned 2026-11-02 by D29 | this synchronization commit | this synchronization commit |
| 9576820 / M9 | `docs/milestone-9576820.md`, Backlog, maven | `docs/milestone-9576820.md`, Milestone, maven; assigned 2026-11-03 by D30 | this synchronization commit | this synchronization commit |
| 9576820 / M8 | `docs/milestone-9576820.md`, Backlog, maven | `docs/milestone-9576820.md`, Milestone, maven; assigned and closed 2026-11-03 by D32 | this synchronization commit | this synchronization commit |
| 9576820 / M17 | `docs/milestone-9576820.md`, Backlog, maven | `docs/milestone-9576820.md`, Milestone, maven; assigned 2026-11-03 by D34 | this synchronization commit | this synchronization commit |
| 9576820 / M10 | `docs/milestone-9576820.md`, Backlog, maven | `docs/milestone-9576820.md`, Milestone, maven; assigned 2026-11-05 by D37 | this synchronization commit | this synchronization commit |
| 9576820 / M12 | `docs/milestone-9576820.md`, Backlog, maven | `docs/milestone-9576820.md`, Milestone, maven; assigned 2026-11-05 by D39 | this synchronization commit | this synchronization commit |
| 9576820 / M16 | `docs/milestone-9576820.md`, Backlog, maven | `docs/milestone-9576820.md`, Milestone, maven; assigned 2026-11-06 by D42 | this synchronization commit | this synchronization commit |

### Milestone Details

#### M1 - Apply backend selection to all database operations

Origin: 9576820 / M2
Identity History: M2 -> M1 on 2026-10-29; renumbered to match the selected work order
GitHub Issue: none
Status: Complete

##### Summary

Commit c4b27bcc65fa70ee7c80ccee7d40136bab64d995 implements the accepted backend operation contract through the existing Make targets and database dispatcher. SQLite supports file lifecycle, schema loading, queries, all-user-table deletion, backup and restore; only its client-configuration targets skip. Shared settings validation rejects stale MariaDB configuration, and offline operations check the appliance and health units before database access. T1-T5 passed on 2026-10-30, including six fresh installations; the follow-up results below identify the narrower correction verification. Repository landing is verified and M1 is Complete.

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
- Preserve the all-user-table scope of `sql.drop` and `sql.table.drop` under
  D14 on both backends, including additional user tables. Exclude engine
  internal tables and retain the database or SQLite file itself.
- Define backend-specific behavior for database creation, removal, inspection,
  backup and restore. MariaDB account and server administration have no SQLite
  equivalent: make the command boundary explicit and return a clear error for
  unsupported operations without contacting MariaDB under SQLite selection.
- Extend the existing `db.create`, `db.drop` and `db.show` entrypoints under
  D13. Retain MariaDB database-and-account creation and deletion, and define
  SQLite file creation, removal and inspection through those same targets.
  Do not introduce a parallel common command set for these operations.
- Keep database identity consistent across Make, generated configuration,
  helper scripts and JDBC. Honor `DB_NAME` on MariaDB and the configured file
  on SQLite; define how stale generated configuration is detected or refreshed.
- Align the install procedure, command documentation and tests with that
  behavior, including when MariaDB configuration generation is unnecessary.

Out of scope: automatic data migration or replication between engines,
application schema redesign, PV archive-file deletion, and DB performance
tuning. The current deletion guard is a partial safeguard, not completion of
this work. Raw SQL translation and sandboxing are also outside scope:
`query` and file-query actions execute operator-supplied native SQL, which can
explicitly name other databases. Isolation guarantees apply to helper-selected
connections and generated operations, not arbitrary SQL supplied by an operator.

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
- Table deletion removes both the shipped appliance tables and an additional
  user table from the selected database while retaining the database or file;
  subsequent schema loading restores the shipped appliance schema.
- The install and operator documentation describes the same behavior as the
  commands, with no unconditional MariaDB step in the SQLite procedure.

##### Dependencies And Decisions

- D11 assigns this work to the current development cycle and changes Deferred to Not started on 2026-10-29, superseding the scheduling restrictions of D4 and D10. The full operation plan was accepted and implementation authorized on 2026-10-30.
- D13 selects extension of the existing command interface on 2026-10-29. SQLite `db.create`, `db.drop` and `db.show` will perform operations instead of returning the current successful skip. The detailed lifecycle and interface contracts below were accepted on 2026-10-30.
- D14 selects all user tables in the selected database as the scope of `sql.drop` and `sql.table.drop` on 2026-10-30. The existing MariaDB implementation in `scripts/mariadb_generic_function.bash`, `drop_tables`, enumerates base tables rather than restricting deletion to the four shipped tables. SQLite will follow that scope while retaining its database file; database removal remains `db.drop`.
- The prerequisite isolation safeguards are complete at 3560216c5315088a05bb2e9dea263eac075c52bf; they are evidence, not a remaining work dependency.
- The operation inventory identifies the current command surface. The accepted contract specifies the behavior for every entrypoint. The acceptance and implementation authorization are recorded separately below.

###### Operation Inventory And Intended Behavior

The inventory covers 20 Make targets from `configure/RULES_SQL` and 26 active
dispatch actions from `scripts/mariadb_setup.bash`. MariaDB database clients
use the configured TCP endpoint or Unix domain socket; root account
administration retains its separate local socket authentication path.
Every entrypoint must reject an invalid backend before configuration writes
or database access. The behavior below is governed by the accepted contract, D13, D14 and the Scope.

| Make targets | MariaDB behavior | SQLite behavior |
| --- | --- | --- |
| `db.create`, `db.drop` | Create database and application account; remove database and application account, with the offline precondition below | Create an empty valid database or remove the selected file under D13; retain a valid existing file on create |
| `db.show` | List databases through the configured administrator | Print the existing selected database's absolute path; fail if missing, unreadable or invalid |
| `db.conf`, `db.conf.show` | Generate private client configuration; display it only on explicit request | Keep the successful skip and do not read or write MariaDB configuration |
| `db.secure`, `db.addAdmin`, `db.rmAdmin` | Existing server and administrator-account operations | No equivalent; return an unsupported-operation error without accessing MariaDB as required by Scope |
| `sql.update`, `sql.update.show` | Generate and display the modified shipped MariaDB schema | Generate and display the modified shipped SQLite schema |
| `sql.fill`, `sql.table.fill` | Generate/load or load the selected schema through the application account | Generate/load or load the selected schema as the service account; preserve repeatable loading |
| `sql.show`, `sql.table.show` | List selected database tables | List selected file tables without creating a missing file; absence is an error |
| `sql.drop`, `sql.table.drop` | Drop every base table in the selected database | Drop every user table under D14, excluding engine internal tables; retain the file |
| `PVRequests.show` | Query `ArchivePVRequests` | Query the same shipped table in the selected file |
| `DataServers.show` | Query `ExternalDataServers` | Query the same shipped table in the selected file |
| `PVAliases.show` | Query `PVAliases` | Query the same shipped table in the selected file |
| `PVTypeInfo.show` | Query `PVTypeInfo` | Query the same shipped table in the selected file |

| Direct helper actions | Current behavior and plan boundary |
| --- | --- |
| `secureSetup`, `localAdminAdd`, `hostnameAdminAdd`, `localAdminRemove`, `hostnameAdminRemove`, `adminAdd`, `adminRemove`, `userDrop` | MariaDB-only administration; retain valid MariaDB behavior and reject SQLite before configuration access |
| `dbCreate`, `dbShow`, `dbDrop`, `isDb` | Support both backends with the selected database/file; `dbCreate` and `dbDrop` remain database-only on MariaDB |
| `dbUserCreate`, `dbUserDrop` | Retain MariaDB database-and-account behavior; reject SQLite because it has no database accounts. SQLite Make lifecycle targets call `dbCreate` and `dbDrop` |
| `tableShow`, `tableDrop`, `aaShow` | Generic table operations; standalone routing must agree with the corresponding Make targets |
| `query`, `queryFile`, `querySFile` | Support both backends using native SQL under the argument and output rules below; `querySFile` is an alias of `queryFile` |
| `dbBackup`, `dbBackupList`, `dbRestore` | Keep the existing action names and argument positions; use the backend-specific backup formats below |
| `addProject`, `updateCDBAdminPassword`, `showAdminCryptPassword` | Return an explicit unsupported-action error before configuration access for both backends; do not execute the nonfunctional ComponentDB paths |

###### Accepted Operation Contract

The following concrete policies replace the earlier unresolved alternatives.
The complete contract was accepted and implementation authorized on 2026-10-30,
with D13 and D14 unchanged.

**Interface and configuration.** Extend `scripts/mariadb_setup.bash` as the
existing public dispatcher for both backends. Internal functions may be split
into sourced files, but no second public command set is introduced. Keep
SQLite `db.conf` and `db.conf.show` as successful skips so the shared installer
can retain its `db.conf` step. All other unsupported actions return status 2
with a diagnostic before reading a backend's generated settings.

Make keeps its normal settings precedence and forwards the resolved database
settings explicitly to the helper. Direct invocation resolves the same Make
settings, with explicitly supplied database environment variables treated as
overrides. The resolver must distinguish an unset value from an explicitly
empty value. Do not let sourcing an old generated file replace that selection.
Under MariaDB, compare generated connection/account settings with the current
resolved values and reject missing or mismatched configuration before database
access, naming `db.conf` as the required preparation. Existing Make targets
with an explicit `db.conf` prerequisite may retain that preparation step;
other operations do not silently regenerate configuration. SQLite never
sources MariaDB configuration. Do not expose passwords during comparison.

Include backend, database/file, host, port, socket, account and credential
values in the comparison; timestamps alone cannot validate command-line
overrides. Rendering and installation must keep `context.xml` and
`archappl.conf` consistent with the same selection. An installed appliance
uses its installed settings until configuration is installed and the service
restarted. Queries and deletion do not rewrite those files or restart services.

**SQLite files and output.** Require an absolute, nonempty database path on a
local filesystem; reject a symlink or non-regular database file. Run database
clients as `AA_USERID` with `AA_GROUPID`; create new database files with mode
0600 and new private database/backup directories with mode 0700. Existing
directories are checked for access, not recursively changed. Existing files
must have the expected owner and be writable by the service account for a
write operation; otherwise fail without changing ownership or content.

`db.create`/`dbCreate` initializes a missing or zero-length file as a valid
empty SQLite database, without appliance tables. A valid existing database is
retained; a corrupt file is rejected without truncation. `sql.fill` remains
the schema-loading operation and may initialize a missing database as part
of installation. Database-content reads require an existing valid file and
must not create one. `isDb` may report absence, and `dbBackupList` only inspects
the backup directory; neither requires an existing database. `db.show`/`dbShow`
prints its absolute path followed by
a newline. SQLite `tableShow` uses the existing SQLite table-list format.
For both backends, `isDb` returns 0 for present, 1 for absent and 2 for an
inspection/configuration error; it must not turn a failed client call into a
successful absence result. Its diagnostic names the selected database/file.

The four application-table queries and `aaShow [table]` retain the numbered
first-column display: `pvName` for `PVTypeInfo`, `PVAliases` and
`ArchivePVRequests`, and `serverid` for `ExternalDataServers`. No full-JSON
output is promised. Read
complete first-column values without splitting identifiers on whitespace;
row order is unspecified. An empty table succeeds; a missing table fails.
`aaShow` defaults to `PVTypeInfo` and treats its argument as one quoted table
identifier, not a SQL fragment.

`query [sql]` preserves native client output. Without SQL, MariaDB retains
`SHOW DATABASES`; SQLite lists user-table names in the selected file.
`queryFile [file] [options] [verbose]` and its `querySFile` alias read SQL from
the named file. For MariaDB, retain the option/verbose argument positions and
resolve the default to the shipped `site-template/sql/default_query.sql`.
The option string may contain only these exact, whitespace-separated output
flags: `-N`, `--skip-column-names`, `-B`, `--batch`, `-r`, `--raw`, `-t` and
`--table`. An empty string is valid. Do not evaluate shell text, expand
variables, accept abbreviated options, or accept combined short flags.
Reject every other token before any database connection, including the
existence check performed by `isDb`. This excludes connection/account options
such as `--host`, `--port`, `--socket`, `--protocol`, `--user`, `--password`
and `--database`, option-file selectors, additional SQL execution options,
error-suppression options and positional database names. Diagnostics must not
echo credential values. Connection identity comes only from the validated
configuration; extra client options cannot override it.
SQLite requires an explicit SQL file, accepts no client-option string, and
accepts empty/NO or YES for verbose output. Unsupported options fail before
opening the database. There is no SQL-dialect conversion. SQLite uses batch
error handling so an earlier failed statement cannot be hidden by a later
successful statement. Raw SQL remains an explicit operator action, including
its transaction and cross-database effects.

**Offline operations.** Database creation, schema loading, table/database
deletion, backup and restore require the appliance and its health timer/service
to be inactive on both backends. Read-only inspection and application-table
queries may run while the appliance is active. Raw SQL actions require the
offline precondition because their contents are not classified as read-only.
The helper verifies actual unit states; a query error or unknown state fails.
Absent units permit initial provisioning on a functioning systemd host. The
operator stops units explicitly using the existing health-stop and appliance
stop operations; the helper never stops, starts or kills a service itself.
Verify inactivity rather than relying on `sd_stop`'s exit status, because
that Make target currently ignores stop errors.

Before an offline SQLite operation, inspect open references to the database,
WAL and shared-memory files with sufficient privilege; an observed user or an
inspection failure rejects the operation. Serialize this helper's operations
for the same canonical file with an advisory lock. This is a maintenance
contract: the operator must prevent independent clients or an external
service start during maintenance. The checks do not claim to prevent arbitrary
processes from opening a file after inspection. MariaDB maintenance likewise
requires other writers to be stopped; the database server itself remains up.

SQLite client lock waits are bounded to 5 seconds and each client operation
to 30 seconds. Timeout, interruption and client errors return nonzero. Table
deletion enumerates user tables inside a transaction, quotes each name and
rolls back on error. Engine internal tables are never targeted. SQLite
`db.drop`/`dbDrop` opens the valid database, completes WAL checkpoint/cleanup
through SQLite and closes it before unlinking the exact database path. If
side files remain or cleanup cannot complete, fail without unlinking the
database; do not delete WAL files independently. A missing database with no
side files is an idempotent success; orphan side files or a corrupt database
require separate recovery. MariaDB retains its native DDL behavior; do not
promise rollback of a partially completed multi-step database/account action.

**Backup and restore.** Keep `dbBackup [directory]`, `dbBackupList [directory]`
and `dbRestore stamp [directory]`. All backup/restore operations use the offline
precondition. Backup listing does not require a stopped appliance. MariaDB
retains its configured-name `.sql.gz` format, existing timestamp syntax,
default directory and no-overwrite publication. Restore requires an existing
selected MariaDB database and validates gzip input before import. A database
import error can leave partial changes; return failure and leave the appliance
stopped. No automatic rollback or service restart is promised.

SQLite defaults to the directory `<ARCHAPPL_SQLITE_FILE>.backups` and names
each backup `<database-basename>_<YYYYmmddTHHMMSSZ>.sqlite3`. Use the SQLite
CLI `.backup` operation into a private temporary file, not a raw copy of the
main database. Convert the completed backup to DELETE journal mode, require
`PRAGMA quick_check` to return `ok`, and publish without replacing an existing
path. The result is one self-contained database file with mode 0600. A failed
backup publishes no completed backup and removes only its own temporary file
when cleanup is possible; an uncatchable interruption may leave that private
temporary file, which listing must ignore.

SQLite backup listing prints sorted matching backup filenames, one per line;
an existing empty directory succeeds, a missing/unreadable directory fails.
SQLite restore requires an absent destination database and absent WAL/shared-
memory side files. An existing destination, including a zero-length file or
symlink, is rejected before alteration. To replace a database, the operator
explicitly backs it up and invokes `db.drop` before restore. Validate the
selected backup read-only, stage its database content in a private file in the
destination directory, validate again, then publish without overwriting a
competing destination. Before publication, this operation creates no final
database path; if another actor creates that path, reject publication and
preserve the competing object unchanged. After successful publication the
destination must be a complete valid database with the service account
ownership. The source backup is never changed. Re-enabling WAL is the
appliance's normal JDBC open behavior. Cross-backend restore is unsupported.

SQLite mechanism references: [CLI backup commands](https://www.sqlite.org/cli.html),
[Backup API](https://www.sqlite.org/backup.html), and
[WAL file lifecycle](https://www.sqlite.org/wal.html#the_wal_file).
These describe database mechanisms, not verification of the planned helper.
The Debian/Rocky tests must establish the behavior of their installed clients.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-30; complete M1 operation contract accepted.
Implementation Authorization: 2026-10-30; explicit authorization to implement the accepted M1 plan.
Superseded Plan Artifacts: none

1. Record acceptance and implementation authorization for this operation
   contract, keeping D13 and D14 unchanged. Both were granted on 2026-10-30.
   The accepted contract supplies the operation test expectations.
2. Update `configure/CONFIG_SQL`, `configure/RULES_SQL` and the setup/helper
   path to validate the effective backend and database identity before side
   effects. Reuse the existing public targets and implement the accepted
   standalone interface. Verify all inventoried entrypoints through T1 and
   stale-configuration cases through T5. Propagate `isDb` inspection failures
   through every caller; do not interpret them as database absence. Reject the
   three nonfunctional legacy actions explicitly and document `querySFile`.
3. Implement SQLite queries and table deletion through the real client under
   the service account. Use schemas selected through `configure/RELEASE` and
   `SQL_TOP_PATH`, preserve associated triggers on reload, quote discovered
   table identifiers, and follow the accepted locking policy. T2 verifies
   exact query results, both deletion targets and the unselected databases.
4. Implement the accepted lifecycle, backup and restore contract in the helper
   path while retaining MariaDB account behavior and backup compatibility.
   Add the shared offline-state check and file-level operation lock. T3
   verifies file ownership, WAL data, failures and interruption behavior;
   it must not claim atomic restore unless the real path proves it.
5. Align `configure/RULES_PROPERTIES`, `scripts/render-db-config.bash` and
   `scripts/install-local-common.bash` where the accepted policy requires it.
   T5 checks generated and installed JDBC identity; T4 exercises the actual
   local installation entry scripts and service startup on both operating
   systems. Do not substitute the deferred M4 VM-driver work for these paths.
6. Update `docs/README.install.md`, `docs/technicaldocs/README.mariadb.md`,
   `scripts/README.md` and `tests/README.md` with the same operation contract.
   Write new checks in Bash under D6 and adjust existing assertions that
   require SQLite lifecycle commands to skip or supported queries to reject.
   Do not perform the separate M3 Python-to-Bash conversion here. Record real
   T1-T5 results, source/environment revisions and any incomplete cases before
   considering closure.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Command routing | Run every entrypoint with both backends, both local configuration locations, command-line overrides and invalid values | Isolated checkout and disposable databases on systemd test guests for offline operations | Selected client and identity agree; invalid or unsupported operations fail before side effects |
| T2 | Database integration | Load the shipped schemas, insert distinguishable rows, query all four tables, create an additional user table, exercise sql.drop and sql.table.drop with fresh data between cases | SQLite and MariaDB over TCP and Unix domain socket on systemd test guests | Each query returns the expected identifiers/content under the accepted output contract; both deletion targets remove all user tables and retain the database/file; reload restores shipped schema and triggers; unselected database unchanged |
| T3 | Database lifecycle | Exercise db.create, db.drop, db.show and direct lifecycle actions, backup/list/restore, non-default identity, WAL mode, active connections and real failure cases | Disposable databases under the service account on systemd test guests | Offline actions reject active/unknown states; restored rows match the backup; existing SQLite restore destinations and backup collisions remain unchanged; failures preserve the documented state |
| T4 | Deployment | Run the actual local SQLite, MariaDB TCP and MariaDB UDS installation entry scripts, then exercise configuration persistence through the running appliance | Debian 13 and Rocky Linux 8 disposable VMs; six OS/backend-transport cases | Installed JDBC, helpers and service dependencies agree; real configuration survives restart; SQLite installation needs no MariaDB configuration or service |
| T5 | Configuration identity | Generate settings for identity A, select B without regeneration, invoke real Make/helper paths, then render/install B settings and restart the appliance | Isolated checkout, disposable A/B databases or files and the T4 guests | Direct/stale consumers reject before access; explicit preparation targets may generate B settings; A remains unchanged; Make, helpers and installed JDBC select B after deployment/restart |

T1 covers all 20 Make targets and 26 dispatched helper actions above, including
explicit unsupported results. Exercise both local settings files, command-line
overrides and direct helper environment/inherited settings. Invalid selections
must fail before generating files or connecting to either backend.
Include empty values, unsupported legacy/account actions, argument errors and
the `querySFile` alias. Check the `isDb` present/absent/error distinction with
real connection refusal or denied access, not a mocked client. Confirm that
SQLite configuration skips still allow the shared installer sequence.
For both file-query aliases, test each allowed MariaDB output flag and the
empty option string against a real database, checking the requested format
and unchanged connection identity. Reject connection/account overrides in
long, short and attached-value forms, option-file selectors, SQL execution
options, unknown/abbreviated/combined flags and positional database names.
Include an allowed flag followed by a forbidden token. Observe real disposable
server connection logs to verify rejection before even the `isDb` connection;
schema equality alone is not evidence of no connection. Check that credential
values do not appear in rejection output. SQLite rejects every nonempty
client-option string under the accepted contract.

T2 uses the actual source checkout's `archappl_mysql.sql` and
`archappl_sqlite.sql`, not a replacement schema. Record their revision and
hashes. Insert valid, distinct fixture rows into `PVTypeInfo`, `PVAliases`,
`ArchivePVRequests` and `ExternalDataServers`; assert expected identifiers and
any fields promised by the accepted output contract, not just exit status.
Compare complete first-column values, including identifiers containing spaces;
do not assert undocumented row order or full JSON output. An empty existing
table must succeed; a missing table must fail. Verify the
SQLite update triggers by changing rows and observing `last_modified` after a
clock interval sufficient to distinguish timestamps. Include a valid quoted
user-table name and foreign-key relationships in deletion coverage. Recreate
the additional table before testing the second deletion alias. Compare schema
and rows in both a second database/file on the same backend and the unselected
backend before and after each destructive case.

T3 includes existing/missing/corrupt SQLite files, parent-directory permissions,
service-user ownership, retained WAL data, refusal with a live writer, locked
databases and the 5-second lock/30-second operation bounds. Use real systemd
units and client processes to check active, inactive, absent and inaccessible
states; inability to observe a state is failure, not proof of inactivity.
Verify that commands never stop/restart the appliance automatically. Create
failures through real client permissions,
real locks, unreadable or corrupt backup input, existing backup destinations
and process interruption. Confirm the documented target state after each
failure and restored rows after a successful backup/restore. Verify SQLite
restore refusal before changing an existing target, successful restore into an
absent target, and preservation of a competing target created during staging.
After `db.drop`, verify that `isDb` reports absence, `dbBackupList` still lists
the retained backups, and restore can use one of those backups. Verify WAL
cleanup before file removal. New tests must
exercise the shipped entrypoints; do not mock internal dispatch or clients.

T4 records the exact installation command, environment/source revisions and
guest identity for each of the six cases. Verify service startup and a real
appliance configuration write/read across restart. Local rendering, schema
load and an installer `--plan` run cannot pass this check. PV sample storage
is not inferred from configuration database persistence.

T5 varies `DB_NAME`, `ARCHAPPL_SQLITE_FILE`, backend, TCP endpoint and socket,
including command-line changes without a newer configuration-file timestamp.
Exercise both stale files and missing files. Include the installed
`context.xml` and `archappl.conf` in identity checks; generating a correct new
file alone does not prove the running service selected the intended database.

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-30 UTC | Local checkout; Debian 13 and Rocky 8.10 systemd guests | Pass | Local suite passed, including 17 configuration tests and 23 settings assertions. The real Bash database suite passed on each OS for SQLite (103 assertions), MariaDB UDS (143) and TCP (143). All 20 Make targets and 26 dispatched actions are covered across valid, invalid and unsupported cases; real connection-log positive controls precede no-connection rejection checks. |
| T2 | 2026-10-30 UTC | Debian 13 and Rocky 8.10; real SQLite and MariaDB UDS/TCP | Pass | Shipped schemas, four complete first-column queries, both deletion aliases, quoted additional tables, foreign keys, SQLite FTS5 tables, reload and update triggers passed. Same-backend and other-backend database fingerprints remained unchanged. |
| T3 | 2026-10-30 UTC | Debian 13 and Rocky 8.10 disposable systemd guests | Pass | Real lifecycle, service ownership, WAL retention, live-writer refusal, health timer, unavailable systemd bus, 5-second lock waits, 30-second operation timeout, backup interruption and restore publication collision passed. Existing Python integration tests passed 2/2 on each OS with real clients and privileges. Direct executable invocation, startup-file isolation, quoted paths/table identifiers and backup/restore also passed on Debian. |
| T4 | 2026-10-30 UTC | Six fresh guests: Debian 13 and Rocky 8.10, each with SQLite, MariaDB UDS and MariaDB TCP | Pass | Each actual local installer built the pinned source, installed Tomcat/appliance/systemd units and started all four components. A real configuration API write survived service restart. Installed JDBC identity, helper output and service dependencies agreed. Fresh SQLite installations had no MariaDB configuration or service. PV acquisition and stored samples were not tested. |
| T5 | 2026-10-30 UTC | Local settings suite, disposable databases and all six installed guests | Pass | Empty/CLI/environment/local settings, host/port/socket changes, credentials and unchanged timestamps passed 23 local assertions. On each installed guest, stale or missing MariaDB settings rejected before access; SQLite selection of an absent B file did not create it. Explicit preparation and reinstallation selected B in context.xml, archappl.conf, helpers and the running API. B persisted after restart and A remained unchanged. Backend overrides also preserved the unselected database. |

Follow-up verification on 2026-10-30 UTC covers locale-independent MariaDB
configuration comparison and complete table-name listing. The local settings
suite passed 31 assertions and the configuration suite passed 17 tests. On a
retained Debian 13 systemd guest, `tests/database-operations.bash` passed for
SQLite (109 assertions), MariaDB UDS (157) and MariaDB TCP (157). Both helper
and Make table listings preserved spaces and backticks; the helper also
handled empty lists. All four generation/execution combinations of `C` and `C.UTF-8`
accepted identical non-ASCII settings and rejected changed values. These
checks extend T1, T2 and T5; the six fresh installations above remain evidence
for their original snapshots and were not repeated for this correction.
The locale regression failed on the original product code, and the real
MariaDB UDS suite rejected an isolated copy with the original table-listing
implementation. Original outputs and corrected results are retained separately.

The test environment basis was `de8b53a27377b4fd097e904dfbbeca981822fe71`
with the then-uncommitted M1 changes. Snapshot archives contain the exact file list
and per-file SHA256 checks used on the guests:

| Input | SHA256 | Verified use |
| --- | --- | --- |
| Environment snapshot04 | `3de02a73802d044c805fccc123f16c87110cdb50256bd1233a21e0342da91de5` | Fresh SQLite installations and installed A/B tests on both OSes |
| Environment snapshot05 | `3d883b49593189696886ce21baea0649da8b5dbb428a6936bfc9535746b4cb8b` | Final Bash database matrix on both OSes and all four fresh MariaDB installations |
| Final Python integration test | `0fd83d79a85f3d648125a53ce868237aecb46a80555528e379043fe5e932eef4` | Real 2/2 integration cases on Debian Python 3 and Rocky Python 3.9 |
| Database correction inputs | `94179e7a3fdb4657ae313d2773bd1de5ecfd03291b62c918f36c48601fa33b61` | Three product scripts and two regression scripts applied over snapshot05; all three database modes on retained Debian 13 |

The only product-code difference between snapshot04 and snapshot05 is SQLite
all-table deletion ordering for virtual tables and their shadow tables. The
fresh SQLite installation path does not use table deletion; both OSes passed
the final snapshot05 deletion tests. The current product differs from snapshot05
in `scripts/database_common.bash`, `scripts/render-db-config.bash` and
`scripts/mariadb_generic_function.bash`: shell configuration generation and
comparison use `C` locale, and MariaDB table listing preserves the complete
first field of each batch-output row. The correction input archive and its
per-file SHA256 list identify the exact scripts used for follow-up verification.

All six installations use source commit
`e0a8e66ed09e840ab8ed67dae81b25474605db08` and its original schema files:

| Source schema | SHA256 |
| --- | --- |
| `archappl_mysql.sql` | `09672f169e26be29555392211207a085eb36a36f464b962aa6284998df8b9112` |
| `archappl_sqlite.sql` | `bc0bd2bff0e2ee1d8bc7a53a71aee612032a0d7cf2fe040f2a9abcadcbf6af54` |

For each OS, the exact initial commands were
`bash scripts/install-local-sqlite.bash --yes --timeout 300`,
`bash scripts/install-local-mariadb-uds.bash --yes --timeout 300` and
`bash scripts/install-local-mariadb-tcp.bash --yes --timeout 300`.
The source pin was set through the parent `RELEASE.local`; database identity
was set through the parent `CONFIG_SITE.local`. B reinstallation used the same
entry script with `--yes --skip-packages --tomcat existing --timeout 300`.
The private `work/m1-database/` evidence retains guest identity, snapshots,
commands, schema hashes, initial package/unit inventory, API responses,
installed settings and database fingerprints. Internal guest identifiers and
credential-bearing logs are not published.

Local verification also passed `bash -n`, the warning/error ShellCheck gate,
mdBook generated-page checks and `mdbook build`. The full local suite skips
real EPICS Base binary resolution when `AA_TEST_EPICS_BIN` is unset; no PV
sample result is inferred from that suite. `configure/CONFIG_SQL` and
`configure/RULES_PROPERTIES` retain their existing selection behavior.
`scripts/render-db-config.bash` uses deterministic shell quoting under `C`
locale; XML rendering is unchanged and covered by the configuration suite.

##### Closure Evidence

- Implementation and required verification: finished on 2026-10-30.
- Repository landing: commit c4b27bcc65fa70ee7c80ccee7d40136bab64d995 on origin/maven. Observed at 2026-10-30T16:48:51Z after fetching origin; HEAD and origin/maven both resolved to that commit and the complete tree comparison had no differences. Recheck with fetch, rev-parse and diff against this commit.
- Commit preparation removed one trailing space in tests/database-operations.bash after the retained test runs. Bash syntax and staged whitespace checks passed; the three corrected product scripts were unchanged. Historical input archives remain unchanged.
- Linked GitHub issue: none.

#### M2 - The operating system target rewrites `configure/CONFIG_SITE.local` and the installers run it first

Origin: 9576820 / M5
Identity History: M5 -> M2 on 2026-10-29; renumbered to match the selected work order
GitHub Issue: none
Status: Complete

##### Summary

The targets `<os>.conf` (`debian13.conf`, `rocky8.conf` and the others in `configure/RULES_TOMCAT`) delete `configure/CONFIG_SITE.local` and write one line into it, the include of `configure/os/<os>.mk`. Every installer runs its operating system target during prerequisites, after reading Make settings and optionally installing packages, so a value that an operator wrote into `configure/CONFIG_SITE.local` is lost when execution reaches that target. `../CONFIG_SITE.local`, next to the checkout, is not touched and is the place for site values.

Source inspection at c4b27bcc65fa70ee7c80ccee7d40136bab64d995 on 2026-10-30 confirms that configure/RULES_TOMCAT rewrites the file. In scripts/install-local-common.bash, main calls select_backend and read_settings before the preset target; both can invoke make_value. configure/CONFIG_SITE includes the file while Make parses settings. Later, sudo authentication, work-directory/lock creation and optional package installation precede run_make "$os.conf". A check only at that target would therefore occur too late.

D7 (2026-10-11) chose refusal before changes. D11 (2026-10-29) assigns preparation after M1 in the current development cycle without waiting for a numbered release.

##### Scope

- The three installers stop before their first Make invocation or installation side effect when `configure/CONFIG_SITE.local` does not match the generated OS-file contract. Report its path and offending line numbers without line contents, and name `../CONFIG_SITE.local` (D7, D15). The target keeps writing the one line.
- Keep the documented place for site values, `../CONFIG_SITE.local`.

Out of scope: changing configure/os/*.mk, changing the behavior of direct make <os>.conf calls, automatically migrating site settings, rewriting Make configuration precedence, guarding arbitrary Makefiles, changing installed config.d, database behavior, the VM driver, or converting existing Python tests. Concurrent external edits during installation are outside this preflight contract; the check is not a security boundary for untrusted checkouts.

##### Completion Criteria

- For SQLite, MariaDB UDS and MariaDB TCP, an extra assignment or unsupported file form causes the real installer to return nonzero before Make, sudo authentication, lock creation, package installation, source operations or service changes. The original configuration and parent site file remain byte-for-byte unchanged.
- The diagnostic identifies the file and offending line numbers and names ../CONFIG_SITE.local, without printing configuration contents or values. An unreadable file or unsupported file type reports the path and reason when no line can be inspected.
- Valid generated input and an absent file permit the normal installer plan. --yes and --skip-packages do not bypass protection; --plan applies the same check and --help remains available.
- Actual OS targets still generate their documented one-line include in isolated copies, and preserve ../CONFIG_SITE.local. Direct-target compatibility is a separate check, not evidence that the installer refused invalid input.
- New Bash regressions run the complete shipped entry scripts and common driver. The early-refusal regression fails against the original driver or a copy with only the guard call removed. The original driver is scripts/install-local-common.bash as committed at the latest commit before the M2 change, copied with git show; at planning that is c4b27bcc65fa70ee7c80ccee7d40136bab64d995, and the hash actually used is recorded with the results. No internal function, Make, sudo or package-manager substitute establishes acceptance.

##### Dependencies And Decisions

- D11 assigns this work and changes Deferred to Not started on 2026-10-29. It supersedes the next-numbered-release scheduling condition of D7 and the unassigned condition of D10; D7's refusal behavior and site-settings location remain the accepted direction.
- M1 is a work-order dependency selected by D11, not a technical prerequisite.
- Preparation must locate the first side effect in each installer and show how the refusal check precedes it. The direct-target test was reviewed against the installer refusal requirement before plan acceptance.
- Installed `config.d` support does not protect the separate checkout file `configure/CONFIG_SITE.local`.
- M1 implementation, verification and repository landing are complete at c4b27bcc65fa70ee7c80ccee7d40136bab64d995. This satisfies the work-order dependency; no database API is needed by the new guard.
- D15 selects file/line-only diagnostics on 2026-10-30. It changes diagnostic content, not the refusal policy. The input contract and plan below were accepted on 2026-10-30.

###### Planning Findings

| Class | Finding | Evidence |
| --- | --- | --- |
| Confirmed finding | The OS recipe removes and replaces the checkout-local configuration without inspecting extra settings. | configure/RULES_TOMCAT, six preset recipes and the two CentOS aliases |
| Confirmed finding | Installer Make reads occur before the OS recipe; Make syntax in an extra line can execute during parsing. | scripts/install-local-common.bash: main, select_backend, read_settings, make_value; configure/CONFIG_SITE local includes |
| Confirmed finding | sudo authentication, work/lock creation and optional packages precede the OS recipe. | scripts/install-local-common.bash: main, install_packages |
| Confirmed finding | The former T1 ran a direct Make target but allowed an installer refusal as its expected result; that path cannot prove the requirement. | M2's earlier Test Plan at c4b27bc |
| Owner decision resolved | Suppress configuration contents in diagnostics; retain file and line numbers. | D15 |

These are source-inspection findings. No M2 runtime verification has run.

###### Input And Refusal Contract

Treat configure/CONFIG_SITE.local as generated input. An absent path is allowed for a first installation. An existing path must be a readable regular file, not a symlink, and contain exactly one literal include line naming a shipped preset: debian12, debian13, rocky8, rocky10, ubuntu24 or ubuntu26. The line is `include $(TOP)/configure/os/<preset>.mk`; accept its final newline being present or absent. A valid prior preset may differ from the detected host because the normal OS target replaces it.

Reject empty files, extra blank or comment lines, duplicate includes, assignments, other include paths, Make expressions, altered whitespace and CRLF input. Do not evaluate, source, repair, delete or migrate the file. This deliberately recognizes generated output rather than attempting to interpret general Make syntax. The strict input rule was accepted with the plan on 2026-10-30; D7 and D15 alone did not accept every parser detail.

Use one Bash validation function in scripts/install-local-common.bash, called after argument parsing and the existing non-root check, before detect_os, select_backend, read_settings or any Make call. Keep --help's early exit. Report all offending line numbers for readable text and exit through the existing installer error path with status 1. Under D15, do not echo file contents, assignment names, values, Make diagnostics from the rejected file, or a command that embeds them. Give manual recovery instructions to inspect the named lines, move site settings to ../CONFIG_SITE.local first, then delete configure/CONFIG_SITE.local so that the installer writes the generated include again, and retry. State that running make <os>.conf before the move would overwrite the settings. Missing tools, unreadable input and unsupported file types must not be treated as valid input.

The refusal guarantee covers this installer processing an already-invalid file, including --plan. It does not cover Make expressions in the trusted parent site file or other checkout files, shell startup customization, direct manual OS-target execution, or an external process modifying configuration after validation. No new locking or global Make parser is proposed.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-30; owner accepted the input and refusal contract, test coverage and evidence boundaries of this plan text (SHA256 7e37da04d74510e0 before this record).
Implementation Authorization: 2026-10-30; explicit owner authorization to implement the accepted M2 plan. It does not authorize commit, push, issue creation or provisioning of guests.
Superseded Plan Artifacts: none

1. Plan acceptance and implementation authorization were recorded separately on 2026-10-30, as the fields above state, before product code changed.
2. Add the shared read-only validator and its early call to scripts/install-local-common.bash. Leave the three public wrapper scripts and configure/RULES_TOMCAT behavior intact. T1 and T2 prove refused inputs are preserved and never reach Make or installation effects; T3 proves valid inputs and help still work.
3. Add tests/local-install-config.bash with separate --local and --disposable-host modes; default to --local. Both use isolated copies of the real Makefiles and installer scripts without extracting functions, fake clients or a mocked common driver. In --local, every installer invocation except --help must carry --plan, including original-code and guard-removal checks. Invoke only --local from tests/phase1-logic.bash; neither the full local runner nor inherited environment flags may select --disposable-host. That explicit mode requires an ordinary user and AA_TEST_DISPOSABLE_HOST=YES on an authorized disposable VM before any test side effect. It alone runs installer --yes cases without --plan. Missing mode prerequisites or tracing capability produce Incomplete rather than silently omitting checks: a missing mode prerequisite or tracing capability ends the test with one INCOMPLETE line and status 77, and phase1 does not catch that status, so the phase fails. T1-T4 cover the input and entrypoint matrix; T5 runs the existing local suite.
4. Run actual OS targets in separate isolated copies for all six presets and the CentOS aliases. Assert the exact expected include and unchanged parent site configuration. Do not change the targets or claim that their direct execution protects extra assignments. T4 proves compatibility with the accepted generated-output design.
5. Update installer help, scripts/README.md, docs/README.install.md and the installation prerequisites in book/src/install/{sqlite,mariadb-uds,mariadb-tcp,reinstall}.md. Also update book/src/configure/override-setting.md, book/src/understand/site-changes.md and book/src/install/host-changes.md, which describe the rewrite as the first installer step, so they state the refusal that now precedes it. Explain the two configuration locations, refusal timing, strict generated-file form, manual recovery and unchanged direct-target behavior. Update tests/README.md with the new real-path suite and its prerequisites, stating that its disposable mode runs as an ordinary user with AA_TEST_DISPOSABLE_HOST=YES and --disposable-host, unlike tests/database-operations.bash, which requires root with the same variable, because the installers refuse root. Add the new script to the group table in book/src/test/phases.md and strace to the prerequisites in book/src/test/run-local.md. Regenerate book/src/appendix/script-options.md with book/scripts/gen-script-options.bash rather than editing generated help text. T5 checks syntax, lint, local regressions and generated pages.
6. Record actual results and input identities for T1-T5, including original-code failures, before closure. Run local --plan cases on Debian 13 and Rocky 8.10 as ordinary users. Run every --yes case without --plan only in separately authorized disposable Debian 13 and Rocky 8.10 guests; a normal Debian development host cannot supply that evidence. The owner supplies each guest when authorizing the run; the VM driver and its handoff files are not used. Before entering --disposable-host mode, confirm on the guest and record in the evidence directory: /etc/os-release names Debian 13 or Rocky 8.10; id -u is not 0; systemd-detect-virt --vm reports a virtual machine, not a container; the owner's authorization names this guest; and the installation path that make print-AA_INSTALL_LOCATION resolves and the appliance service unit do not exist. The environment acknowledgment alone does not prove isolation, and any failed item stops the run as Incomplete before a test side effect. Retain evidence and inspect/stop any surviving installer processes before releasing a guest after a failed test. Do not provision guests during planning. This milestone verifies early refusal and valid preflight, not another complete appliance installation; M1's installation results remain tied to their original snapshots.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Installer refusal | Local mode runs all three entry scripts on invalid fixtures with --plan, with/without --skip-packages. Disposable-host mode additionally runs --yes without --plan, with/without --skip-packages. Capture native status, stdout/stderr, file hashes and exec traces | --plan: isolated copies on supported ordinary-user hosts. --yes without --plan: authorized disposable Debian 13 and Rocky 8.10 VMs only. Real Bash and working strace required | Status 1 with the intended file/line diagnostic; parent and local configuration unchanged; no Make, sudo, package manager or service command starts and no installer work/lock file is created |
| T2 | Defect sensitivity | Put a harmless Make parse-time file marker inside the rejected configuration, then run the real --plan entrypoints against corrected code and a separate copy of the original driver defined in Completion Criteria | Isolated copies, no host-level mutation; real Make | Corrected code refuses before the marker exists; original code demonstrably parses the fixture and fails the same regression; matching nonzero exit codes alone cannot pass |
| T3 | Accepted input and CLI | Run all three --plan entrypoints with an absent file and each valid shipped include, with final newline present/absent; test --help against invalid input; capture resolved plan and before/after state | Debian 13 and Rocky 8.10 ordinary users; isolated real Make tree, no source checkout required | Valid plans exit 0, retain configuration bytes and print the host OS target and selected backend; help exits 0 without reading settings; invalid-input refusal cannot be bypassed by normal flags |
| T4 | Direct-target compatibility | Execute all six actual OS targets and both CentOS aliases in separate copies, including changing an existing generated preset; retain expected and actual file bytes | Local host; real shipped Makefiles and presets | Exact expected one-line include is written; parent CONFIG_SITE.local remains unchanged; no direct-target preservation guarantee is inferred |
| T5 | Regression and documentation | Verify test-mode selection, then run the new --local suite via phase1, the full local suite, changed-script bash -n and ShellCheck warning/error gate, generated-book comparison and mdbook build | Local host with declared suite prerequisites; non-plan installer cases remain VM-only | Default/--local mode cannot launch an installer without --plan even when AA_TEST_DISPOSABLE_HOST=YES is inherited; incomplete VM opt-in rejects before test side effects; a missing strace ends the --local run with status 77 and fails phase1; existing assertions remain intact and documentation/generated help agree |

T1's invalid-input matrix includes an ordinary assignment after the valid include, a password-like test value, an assignment on the first line, an extra comment or blank line, repeated includes, an unknown include, a line holding a Make expression such as a function call or variable reference, altered whitespace (a leading space, a trailing space, a tab in place of the space, and no space after include), empty/CRLF input, a symlink (including dangling), a directory and an unreadable regular file. For readable inputs compare exact diagnostic line numbers and assert the sentinel value never occurs in stdout or stderr. Preserve path types, symlink targets and parent/local bytes; exclude test-owned evidence files from the installer side-effect comparison. File-access metadata such as atime is not an installation mutation.

The checkout copy confines fixture changes, not system changes: a defective early guard can let a non-plan installer reach real sudo, package managers and installation paths. Keep that failure inside a disposable VM. The local suite must retain --plan when exposing the missing-guard defect; an inherited disposable-host acknowledgment never removes it. Test default and explicit --local dispatch with that acknowledgment both absent and present, and test --disposable-host without it; capture actual installer arguments and native outcomes. Verify the new test driver's routing without replacing the installer. A local pass cannot satisfy the VM-only portion of T1. On any observed forbidden command or state change, record Failed, stop further cases on that guest and preserve evidence for inspection; do not wait for an unintended installation to finish.

T2 uses configuration data that creates a marker only if real Make parses it; it does not replace any product function. Restrict original-code runs to --plan and an isolated checkout, so exposing the defect cannot install packages or change services. Capture the actual marker and original status before judging the regression. For extra confidence that the call location matters, repeat against a separate copy with only the early guard invocation removed, without replacing the validator. Keep original and corrected outputs separate.

T3 uses the real preset files and wrapper scripts. All six preset contents can be checked on each supported test host without changing /etc/os-release; actual host detection remains real. It tests --plan completion, not JVM startup, data persistence or package installation. T4 covers legacy aliases without claiming the installers support CentOS or Debian 12 hosts.

Evidence goes under ignored work/m2-install-config/ with case inputs, source hashes, arguments, host/tool versions, UTC start/end, native statuses, complete stdout/stderr, trace output and before/after hashes. Each short case has a 30-second harness timeout; timeout or missing traces is Incomplete unless an independent violation is already observed. No long-duration, throughput or archive-size claim applies. Test expectations come from the contract above, trace evidence proves actual command exposure, and corrected/original source membership is recorded separately. Preserve failed and interrupted cases without reporting completion; do not normalize diagnostic or file differences away. No installation or VM is started by writing this plan.

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-30 UTC | Debian 13 development host, and two disposable KVM guests (Debian 13 and Rocky 8.10), ordinary user, isolated copies | Pass | Local `--plan` part: 22 invalid inputs, three installers, with and without `--skip-packages`, 132 runs, all refused. On each guest the same suite ran 264 refusals: 132 with `--plan` and 132 with `--yes` or `--yes --skip-packages` and no `--plan`. Every run ended with status 1, the exact offending line numbers or reason, `../CONFIG_SITE.local` named, no content in the output and an unchanged file, parent file and checkout tree. The traces of all 264 runs on each guest show no `make`, `sudo`, package, `systemctl` or `flock` start, and every non-plan trace carries `--yes` and no `--plan`. Evidence: `work/m2-install-config/20261031T001952Z/`, `work/m2-install-config/guest-<Debian 13 guest>-20261031T003014Z/` and `work/m2-install-config/guest-<Rocky 8.10 guest>-20261031T003018Z/` (`results.tsv`, `cases/t1/`, `environment.txt`, `guest-identity.txt`, `run.log`) |
| T2 | 2026-10-30 UTC | Isolated corrected, original and guard-removed copies; real Make | Pass | The corrected driver refused and no parse marker existed, for all three installers. The driver of `c4b27bcc65fa70ee7c80ccee7d40136bab64d995` and a copy with only the guard call removed each created the marker (3 of 3). The refusal regression failed on both: 22 of 22 groups, 642 of 1453 assertions, exit 1. Evidence: `work/m2-install-config/20261031T001952Z/drivers/sha256.txt` and `work/m2-install-config/mutants-statefix-20261030/` (earlier runs on previous versions of the test or driver are in `mutants-20261030/`, `mutants-current-test-20261030/` and `mutants-final-driver-20261030/`) Both guests repeated it with the same result (9 of 9 runs). |
| T3 | 2026-10-30 UTC | Debian 13 development host and both guests | Pass | On each of the three hosts: 39 `--plan` runs (absent file and six generated includes, final newline present and absent, three installers) exited 0 and printed `OS:` of the host and the backend line with unchanged bytes; three `--help` runs on an invalid file exited 0 and parsed nothing. The Rocky 8.10 guest ran the installers with Bash 4.4.20. Evidence: `work/m2-install-config/20261031T001952Z/cases/t3/` and the `cases/t3/` folders of the two guest evidence folders |
| T4 | 2026-10-30 UTC | Local host; real shipped Makefiles | Pass | The six `<os>.conf` targets and the two legacy aliases replaced an existing different preset with exactly the expected line and left `../CONFIG_SITE.local` unchanged (8 runs). Evidence: `work/m2-install-config/20261031T001952Z/cases/t4/` Both guests repeated it with the same result (8 of 8 runs). |
| T5 | 2026-10-30 UTC | Local host | Pass | `bash tests/run-all-tests.bash --local` ended with status 0, including the new suite (1886 assertions) through the Phase 1 call. The first run ended with status 1: `tests/database-config.py` test `test_tomcat_choices_and_backup_preserve_existing_files` wrote `TOMCAT_INSTALL_LOCATION:=...` into `configure/CONFIG_SITE.local` and then ran the three entry scripts with `--plan`, which the guard refuses. The owner directed that its setup move the value to the parent site file before the entry-script loop; its assertions are unchanged and all 17 tests of the file pass. Also passed: mode dispatch (default and `--local`, with and without the inherited acknowledgment, launched only installers with `--plan`; `--disposable-host` without the full guest confirmation ended with status 77 and launched none); a denied `ptrace` (a stand-in `strace` that fails like the sandbox) ended the new suite with one `INCOMPLETE:` line, status 77 and no case, and ended Phase 1 with status 77; `bash -n` and `shellcheck -S warning` on the changed scripts; `book/scripts/check-generated.bash`; `mdbook build`. Evidence: `work/m2-install-config/suite-and-denied-tracing-20261030/` (the `statefix` logs belong to the final driver and test file; the other logs belong to earlier versions) |

Guest runs: the owner named a Debian GNU/Linux 13 guest (kernel 6.12.85, Bash 5.2.37, `strace` 6.13) and a Rocky Linux 8.10 guest (kernel 4.18.0-553, Bash 4.4.20, `strace` 5.18) on 2026-10-30; the guest names are kept in the private handoff and evidence only. The provisioner session created them on request. Each is a KVM guest; `guest-identity.txt` records the checks before the run: the operating system, the ordinary user, the virtual machine type, the owner's name for the guest, and no installation path or service unit. Each run used `bash tests/local-install-config.bash --disposable-host` with the same driver and test hashes as the table below and 3049 assertions, all passed. The guests ran the suite twice: the first run, in `guest-*-20261030T230404Z` and `guest-*-20261030T230407Z`, used the test file before the stop-rule change below; the repeat, whose folders the results table cites, used the final file. No forbidden command or state change occurred, so no installer process needed inspection. The requesting session sent a finished notice to the provisioner session after each run, once the evidence was copied, and said that the disks are not needed.

Implementation review on 2026-10-30: a third-person pass found two minor findings. The mode dispatch check lacked the explicit `--local` run without the inherited acknowledgment, and a sentence of `tests/README.md` claimed an input that the suite does not run. A second-person pass, from the seat of an operator who follows the recovery text, found one minor finding: six short sentences said that the installer stops when the file "holds more than" the generated include, although it also refuses an empty file, a symbolic link, a directory, an unreadable file and a file with a NUL byte. A further second-person pass, from the seat of the person who runs the test, found one minor finding: `tests/README.md` gave no command for the guest mode and did not say that the guest name must come from the owner's authorization. A second third-person pass found one minor finding: the stop rule of the guest mode raised its flag only for a forbidden command or a changed checkout tree, not for a changed configuration file or parent file, although the plan stops on any state change. It was applied: any change of the configuration file, the parent file or the tree now stops the guest run, and a driver that changes only the parent file stops the new test after the refusal checks (1453 assertions) while the previous test ran on (1874) (evidence: `work/m2-install-config/statechange-ab-20261030/`). A third second-person pass, from the seat of the person who prepares the commit, found one minor finding: the handoff's list of changed files omitted `tests/database-config.py` and counted six book pages instead of nine. All six were applied. The dispatch, help-text and stop-rule findings changed the test or the installer help, so the code runs above were repeated on the final files, including the two guests; the other three findings changed only `tests/README.md` or the handoff and needed no new run. No further pass has read the corrected text.

Input identities of the runs above:

| Input | SHA256 | Verified use |
| --- | --- | --- |
| `scripts/install-local-common.bash` | `40dcb6cc5dce124c69e1cec1444e6b2e7305b6f2b836bfd52dec03797291c9a4` | Corrected driver of T1 to T5 |
| `tests/local-install-config.bash` | `324cc799fe753a6fa4fbb65afde26122d46f9b943b8b79b686e0e8f78488586b` | New suite |
| `tests/phase1-logic.bash` | `3e379d5b3cc187a3a902568f176ba7780a2225fb05c02e6027277d864faa2d47` | Phase 1 call of the new suite |
| `tests/database-config.py` | `26d034cd7f61e753811d43a30aeeb5e024f35c4b0b37337c5eb03cc9c940c936` | Existing suite after the setup change |

##### Closure Evidence

- Implementation and required verification: finished on 2026-10-31. T1 to T5 are Pass in Verification Results, on the Debian 13 development host and on two disposable guests (Debian 13 and Rocky 8.10).
- Completion criteria against the evidence: refusal before any `make`, `sudo`, lock, package or service step, with the files unchanged (T1, 264 runs on each guest including 132 without `--plan`); diagnostic with file, line numbers and `../CONFIG_SITE.local`, never contents (T1); valid input, absent file and `--help` still work, and `--yes` and `--skip-packages` do not bypass the check (T1, T3); the actual OS targets still write the generated include (T4); the new regression runs the shipped entry scripts and fails on the original driver and on a copy without the guard call (T2).
- Repository landing: commit de8301cb05d3d026708a0270878e110bee497ee7 on origin/maven. Observed at 2026-10-31T03:57:40Z after fetching origin; HEAD, origin/maven and the remote branch tip all resolved to that commit and the tree comparison had no differences. Recheck with fetch, rev-parse and diff against this commit. The committed driver, test, Phase 1 file and `tests/database-config.py` carry the hashes of the table above.
- Remaining external conditions: none. No G gate applies and the item has no linked GitHub issue.
- Linked GitHub issue: none.

##### GitHub Projection

Title: The operating system target rewrites `configure/CONFIG_SITE.local` and the installers run it first
Labels: bug
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M3 - Replace the Python tests with Perl tests

Origin: 9576820 / M4
Identity History: M4 -> M3 on 2026-10-29; renumbered to match the selected work order
GitHub Issue: none
Status: Complete

##### Summary

The shell, Make and installed-appliance tests include Python programs that run across different host and guest Python versions. At 95768200a49e965ef2dd1949919e955af982aff6, `git ls-files tests` lists 13 Python files, including the config.d and local-install checks. This inventory supersedes the earlier seven-file count; it does not change the accepted direction or authorize conversion.

D6 sets the direction away from Python for tests of shell code, and D16 names Perl as the language where D6 named Bash. D11 assigns the existing scope after M2; D17 leaves the VM driver, the guest verifier and the driver test to M8. The detailed conversion plan and acceptance remain pending.

##### Scope

- Inventory every Python file and the consumers that call it, from `tests/phase1-logic.bash` and `tests/run-all-tests.bash`.
- Convert the tests of shell code first (`tests/health-local.py`, `tests/database-config.py`, `tests/install-payload.py`) to Perl, keeping each assertion and its real-path method.
- Leave the VM driver, the guest verifier and the driver test (`tests/vm/driver.py`, `guest.py`, `local.py`) to M8 (D17); update only the places in them that call a converted test.

Out of scope: any change to what the tests assert; replacing the VM driver, guest verifier and driver test (M8); the preparation tool `tests/heap/inspect-inputs.py`, which is not a test (D20); replacing Ansible, which the control host still needs.

##### Completion Criteria

- No test of shell code, Make rules or the installed appliance remains Python, except the VM driver, the guest verifier and the driver test, which M8 owns (D17), and the preparation tool `tests/heap/inspect-inputs.py`, which D20 keeps in Python.
- Each converted test fails on the defect it covers, shown by a mutation of the shipped code.
- The full local suite, run with a real EPICS Base on a host that meets its other optional prerequisites (D21), prints no skip, so the completeness check of the VM driver accepts its output, and the VM matrix keeps its current pass conditions.

##### Dependencies And Decisions

- D11 assigns this work and changes Open to Not started on 2026-10-29 under the existing conversion scope. It settles work order and supersedes D10's unassigned condition.
- D17, D18, D19 and D20 settle on 2026-10-30 the owner decisions recorded below: the VM driver and verifier go to M8, no new skip is allowed, new prerequisites are allowed, and the preparation tool stays Python. D21 supersedes D18 after the review found the completeness check of the VM driver.
- D16 selects Perl as the replacement language on 2026-10-30. It amends the language of D6 only; the interpreter baseline and the modules that each supported system has after its package preparation were measured on a Debian 13 and a Rocky Linux 8.10 system (Planning Findings).
- M2 is a work-order dependency selected by D11, not a technical prerequisite.
- D25 settles on 2026-11-02 that T2 and T4 close without the eight-case VM run and without the mutations on the guests; the waived parts are named in the two Verification Results rows.
- D24 settles on 2026-11-02 how T1 counts the mutations that both implementations leave alive, and sends the defects and improvements found during the conversion to the Backlog items M10, M11 and M12.
- Preparation refreshed the Python-file and caller inventory after M1 and M2 (Planning Findings). The mapping of every assertion to a real-path Perl check is step 2 of the plan, and plan acceptance remains pending.


###### Planning Findings

| Class | Finding | Evidence |
| --- | --- | --- |
| Confirmed finding | As first drafted, completion criterion 3 asked for no skips, but the passing local suite prints three: the SQLite lifecycle check and the database maintenance client check need a disposable guest, and the real Base binary resolution needs `AA_TEST_EPICS_BIN`. | `bash tests/run-all-tests.bash --local` on the tree of de8301c |
| Confirmed finding | As first drafted, scope and criterion 1 disagreed about the VM driver and verifier: criterion 1 forbade a Python test of the installed appliance, while the scope left their replacement to a separate decision. `tests/vm/guest.py` verifies the installed appliance; `tests/vm/local.py` tests Python code (`tests/vm/driver.py`). | tests/vm/guest.py, tests/vm/local.py, Scope |
| Confirmed finding | The inventory after M1 and M2 is unchanged: 13 Python files under tests (2,357 lines of shell-code and appliance tests, 3,059 lines of VM driver, verifier and driver test, 142 lines of one preparation tool); only `tests/database-config.py` was edited. The first draft lacked the per-assertion mapping that Dependencies requires; step 2 of the plan now owns it. | `git ls-files tests` at de8301c |
| Confirmed finding | Three files have no caller in the code and run by hand: `tests/install-payload.py` (two real Maven target directories), `tests/config-d-runtime.py` (Java, Tomcat and WAR files) and `tests/heap/inspect-inputs.py` (a preparation tool for the heap soak, not a test). The first draft did not classify them; the plan converts the first two and D20 keeps the third in Python. | tests/README.md, tests/heap/README.md |
| Confirmed finding | No record shows which defects the Python tests catch, so "the same defect detection" cannot be shown for a converted test; step 2 of the plan records them. | Completion Criteria, Test Plan T1 |
| Owner decision resolved | Perl as the one replacement language, amending D6. | D16 |
| Owner decision resolved | The VM driver, guest verifier and driver test go to the separate item M8; M3 converts the other tests. | D17 |
| Owner decision resolved | Without skips first meant no new skip beyond the three above. | D18, superseded by D21 |
| Confirmed finding | The VM driver rejects a local suite whose output has a `[SKIP]` line, a line that starts with `SKIP:` or unittest skips. Since the commit that added two unconditional `[SKIP]` announcements to `tests/phase1-logic.bash`, that check returned False for every run of the tree, so the acceptance run of the VM matrix could not pass at its local suite step; D18 and criterion 3 rested on a wrong reading. | `local_suite_complete` applied to the output of the suite at de8301c; the introducing commit c4b27bc |
| Owner decision resolved | The two announcements lose the skip marker, and the local suite prints no skip when a real Base is supplied. | D21 |
| Confirmed finding | After that change the suite run with a real Base ends with status 0 and no skip, and `local_suite_complete` is True; without the Base one skip remains, from the unset `AA_TEST_EPICS_BIN`. | suite output with and without `AA_TEST_EPICS_BIN` on 2026-10-30 |
| Confirmed finding | The completeness check also fails on six other environment skips of the suite (no source clone, no directory creatable under the storage base, a `/dev/shm` on the root filesystem, no real Java, a threshold outside 1 to 100, no `mysql` client), and the driver does not pass `AA_TEST_EPICS_BIN` on: it hands its own environment to the suite. The documents list only the source clone and the Base as optional prerequisites. D21 and step 1 of the plan now name them. | the skip conditions in `tests/phase1-logic.bash`; `tests/vm/driver.py` |
| Confirmed finding | Found while converting `tests/install-payload.py`: its root-alias case appends `/../..` to the workspace and expects `/`, which holds only when the workspace sits two levels below the filesystem root. With a deeper `TMPDIR` the path named a real directory and the shipped installer acted on it, and the case failed. The Perl test derives the alias from the depth of the workspace and stops before it runs the installer if the alias does not resolve to `/`. | the Python test before its removal; `work/m3-perl/install-payload/` |
| Confirmed finding | Found while converting `tests/health-local.py`: the driver's `local_suite_complete` recognizes a skip only as `[SKIP]`, a line that starts with `SKIP:`, or `skipped=N` of the Python unittest summary, and `tests/vm/local.py` asserted the unittest form `OK (skipped=1)`. TAP skip text (`# skip`) would pass the completeness check. The Perl test prints a `SKIP:` line before each skip, selects a case with `--case NAME` as the VM test needs, and the assertion in `tests/vm/local.py` now expects that line; the driver stays unchanged (D17). Every later converted test follows this form. | tests/vm/driver.py, tests/vm/local.py, `work/m3-perl/health-local/` |
| Confirmed finding | As first drafted, no check covered criterion 1, and no check ran the converted guest-side tests: `tests/config-d-runtime.py` needs Java, Tomcat and WAR files, and the `tests/local-install-pv-*.py` checks need real WAR files and a soft IOC on a disposable guest, while T1 named the local host and the VM matrix runs none of them. T3 and T4 now cover both. | tests/README.md, Test Plan |
| Owner decision resolved | New prerequisites of the replacement tests are allowed and documented. | D19 |
| Owner decision resolved | `tests/heap/inspect-inputs.py`, a preparation tool that reads the soak inputs and is not a test, stays outside M3 and remains Python. | D20 |
| Owner decision resolved | The workspace of a passing case is removed and that of a failed case or a case with `KEEP_WORKSPACE=1` is kept, as in `tests/health-local.pl` and `tests/database-config.pl`; the Python `tests/config-d.py` kept every workspace. | D22 |
| Confirmed finding | Found while converting `tests/local-install-pv-range.py`: the unmutated Python test and the unmutated Perl test, run alternately six times each on this host, both failed in runs 1 and 4 (Python at wrong-pv both times, Perl at time-skew and at boundary); the unmutated Perl test also failed once in a mutation series (at outside, with a `query.json` and a `response.json` from different attempts) and once in a run without a controlling terminal (at inside). The fixture writes `query.json` and then `response.json` for every request, and when the verifier ends an attempt at its deadline, the fixture process of that attempt can finish after the next attempt has written its own files, so the pair does not come from one attempt and the count of valid samples is wrong. The same cause makes single mutation verdicts of time-dependent checks unreliable (`fraction-borrow` was killed once in six runs of each implementation, and the zombie check of the menu test once in seven Python runs). | `work/m3-perl/pv-range/controls/`, `work/m3-perl/pv-range/fraction-*.tsv` |
| Owner decision resolved | The time-range test is converted with its behavior, and the defect above is handled afterwards as the separate item M9. | D23 |
| Confirmed finding | Measured with the probe of the Perl standards on a Debian 13 guest and a Rocky Linux 8.10 guest, each a base image plus `git`, `make` and `strace`. Debian 13 has Perl 5.40.1 with `JSON::PP`, `Digest::SHA`, `Test::More`, `IO::Socket::INET`, `IO::Uncompress::Unzip` and `Time::HiRes`. Rocky Linux 8.10 has only the interpreter 5.26.3, without `JSON::PP`, `Digest::SHA`, `Test::More`, `Time::HiRes`, `IO::Uncompress::Unzip` and `prove`; the packages are perl-JSON-PP, perl-Digest-SHA, perl-Test-Simple, perl-Time-HiRes, perl-IO-Compress and perl-Test-Harness. `xmllint` is present on Rocky Linux and missing on Debian (package libxml2-utils); `script` is present on both; `sqlite3`, `jq` and `unzip` are missing on both. The XML, pseudo-terminal and SQLite modules are absent everywhere, so those checks keep using a command. | probe and package queries on the two guests, 2026-10-31 UTC |

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-31; owner accepted this plan text, as committed in 78b0d4f683f1b9b5c3c5e8ff142b3e86b1fad7ef.
Implementation Authorization: 2026-10-31; explicit owner authorization to implement the accepted M3 plan. It does not authorize commit, push, issue creation or provisioning of guests; the owner names each guest for the guest checks.
Superseded Plan Artifacts: none

1. The Perl baseline is measured (Planning Findings). Fix the prerequisite list from the modules the converted tests use, document it in `tests/README.md` and `book/src/test/run-local.md`, and keep `python3` listed while any Python file remains. Also document the optional prerequisites whose absence prints a skip (the source clone, a real Java, the `mysql` client, a `/dev/shm` on its own filesystem and `AA_TEST_EPICS_BIN`), and that the VM acceptance run needs them and the variable exported before the driver starts, because the driver passes its own environment to the suite.
2. For each Python file, write its contract (the assertions, the real-path method, the inputs and the consumer that calls it) and record which defects it catches. Run the Python test from a copy of the repository tree that includes the tests, because each test finds the shipped code from its own location; mutate the copy and supply the inputs the test needs. `tests/database-config.py` and `tests/install-payload.py` read the tree with `git ls-files`, so make the copy a Git work tree; `tests/database-config.py` also needs the source clone, and the `tests/local-install-pv-*.py` checks need the EPICS Base path and an evidence folder in their environment.
3. Convert one file at a time: first the three tests of shell code that the scope names (`tests/health-local.py`, `tests/database-config.py`, `tests/install-payload.py`), then `tests/config-d.py`, `tests/local-install-epics.py`, the three `tests/local-install-pv-*.py` checks and `tests/config-d-runtime.py`. Run the Perl test and the Python test on the same inputs and compare their outcomes, then run the Perl test against each recorded mutation. Remove the Python file only after both hold.
4. Update the consumers and prerequisites (`tests/phase1-logic.bash`, `tests/run-all-tests.bash`, `tests/README.md`, `book/src/test/`) and run the full local suite.
5. Update the two calls in `tests/vm/local.py` that start a converted test (`tests/health-local.py` and `tests/local-install-epics.py`); the driver and the verifier call no converted test, and the three files stay otherwise unchanged (D17).

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Each converted test against the shipped code, then against a scratch mutation that reintroduces the defect it covers | Local host | Passes on the shipped code and fails on its mutation |
| T2 | System | Full `tests/run-all-tests.bash --local` with a real EPICS Base supplied, and the VM matrix | Local host; fresh guests | Same pass conditions as before, no skip, and the output passes `local_suite_complete` |
| T3 | Inventory | Compare `git ls-files '*.py' '*.py.in'` with the exceptions of criterion 1 | Local host | Only `tests/vm/driver.py`, `tests/vm/guest.py`, `tests/vm/local.py`, `tests/heap/inspect-inputs.py` and the shipped `site-template/policies.py.in` remain |
| T4 | Guest | The converted `config-d-runtime` and `local-install-pv-*` checks on a Debian 13 and a Rocky Linux 8.10 guest with their prerequisites, against the shipped code and each recorded mutation | Disposable guests with Java, Tomcat 9, built WAR files and EPICS Base | Same pass conditions as their Python versions, with no new skip |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-11-02 UTC | Local host; the Rocky Linux guest for the tests that ran there | Pass by D24 | The conversion record lists for each of the nine files the run on the shipped code and the mutation outcome: every mutation that the Python test kills is killed by the Perl test, and the survivors are the same set, 48 in all (M10). The time-range test failed in 2 of 6 runs of each implementation on the shipped code (D23, M9) |
| T2 | 2026-11-02 UTC | Local host; fresh guests | Pass by D25 | `bash tests/run-all-tests.bash --local` with a real Debian 13 EPICS Base ended with status 0 in 146 seconds: 756 `[OK]` lines, the five groups passed (279, 40, 22, 401 and 14 checks), no `[SKIP]` line, no line that starts with `SKIP:`, no unittest skip, and `local_suite_complete` returned True; evidence under `work/m3-perl/suite-final/`. Waived by D25: the eight-case VM run; `tests/vm/driver.py` and `tests/vm/guest.py` are identical to the prior state commit 95768200a49e965ef2dd1949919e955af982aff6 (`git diff --quiet` ended with status 0) and contain no call of a converted test |
| T3 | 2026-11-02 UTC | Local host | Pass | `git ls-files '*.py' '*.py.in'` at ff2fa4fa884337a75b0fdac3f0483b5cc154aec5 lists exactly `site-template/policies.py.in`, `tests/heap/inspect-inputs.py`, `tests/vm/driver.py`, `tests/vm/guest.py` and `tests/vm/local.py` |
| T4 | 2026-11-02 UTC | Disposable Debian 13 (Perl 5.40.1, Java 21.0.13) and Rocky Linux 8.10 (Perl 5.26.3, Java 21.0.12.1) guests | Pass by D25 | As a non-root account with Tomcat 9.0.121, the four built WAR files and a real EPICS Base of the system: `tests/config-d-runtime.pl` ended with status 0 in 245 seconds on Debian 13 and 259 seconds on Rocky Linux 8.10; the full `tests/local-install-pv.bash` ended with status 0 in 562 and 530 seconds, with its 16 `PASS:` lines and no Java or soft IOC process left. Beyond the base images, Debian 13 needed `openjdk-21-jdk-headless`, `unzip` and `jq`, and Rocky Linux 8.10 needed `java-21-openjdk-devel`, `perl-IO-Compress` and `unzip`. A start of the test from a background job that ignores SIGINT made `int-then-int` fail on both guests, see M11; the logs are under `work/m3-perl/t4/`. Waived by D25: the recorded mutations on the guests |

Conversion record, one file at a time; the evidence is under `work/m3-perl/<file>/`, which Git ignores:

| File | Perl file | Same output as the Python run | Mutations killed (Python, Perl) | Oldest-interpreter run |
| --- | --- | --- | --- | --- |
| `tests/install-payload.py` | `tests/install-payload.pl` | Identical standard output apart from the workspace path, on a real 2025 and a real 2026-10-26 build output with an older log4j JAR set; also identical with a workspace of another depth | 10 and 10, the same ten; the same four survive (`jars-required`, `webxml-check`, `restore-webapp-on-failure`, `unzip-failure-tolerated`) | Run on Rocky Linux 8.10 (Perl 5.26.3) after its package preparation (perl-Test-Simple, perl-Digest-SHA, perl-IO-Compress, perl-Test-Harness, git, make, unzip, a JDK; `xmllint` present): exit 0, same standard output as the Python baseline apart from the workspace path and one capture line, empty standard error, non-root account, 2026-10-31 |
| `tests/health-local.py` | `tests/health-local.pl` | All 23 cases pass in both with no skip, on this host (Debian 13, non-root, real Java 21 and JDK compiler); 1253 TAP assertions in Perl | 22 and 22 of 27, the same 22; the same five survive (`pid-regex-unbounded`, `wrong-java-guard`, `bootstrap-position`, `storage-threshold-boundary`, `systemd-argument-form`) | Run on Rocky Linux 8.10 (Perl 5.26.3) on a fresh guest after the same package preparation and `java-17-openjdk-devel`: exit 0, 23 cases, 1253 assertions, no skip, empty standard error, non-root account, 2026-10-31. Root and `/dev/shm` absent were not run; JDK compiler absent was run through `tests/vm/local.py` |
| `tests/database-config.py` | `tests/database-config.pl` | Configuration cases: all 17 pass in both with no skip, on this host (Debian 13, non-root). Integration cases (root, private MariaDB, SQLite): both pass in both on a fresh Debian 13 guest and a fresh Rocky Linux 8.10 guest (Python 3.9 for the Python run) | Configuration cases: 20 and 20 of 29, the same 20; the same nine survive (`replacement-symlink-guard`, `replacement-checkout-guard`, `service-read-check`, `deadline-before`, `deadline-after`, `make-backend-guard`, `helper-sqlite-account-refusal`, `helper-backend-guard`, `helper-settings-failure`). Integration cases, on the Debian guest: 5 and 5 of 7, the same five; `backup-overwrite-check` and `backup-pipefail` survive in both | Run on Rocky Linux 8.10 (Perl 5.26.3) after its package preparation (perl-Test-Simple, perl-Time-HiRes, git, make, curl, libxml2, sqlite, mariadb-server, lsof, tree): the 17 configuration cases pass as a non-root account and the two integration cases pass as root, 2026-10-31. The source checkout for these runs was a shallow clone of the pinned source commit |
| `tests/config-d.py` | `tests/config-d.pl` | All 11 cases pass in both with no skip, on this host (Debian 13, non-root, real Java 21) | 15 and 15 of 21, the same 15; the same six survive (`nullglob`, `dotglob`, `globignore-reset`, `locale-order`, `file-readable-check`, `health-quiet`) | Run on Rocky Linux 8.10 (Perl 5.26.3) after its package preparation (perl-Test-Simple, make, curl, `java-17-openjdk-devel`): all 11 cases pass as a non-root account, no skip, empty standard error, 2026-10-31; repeated with the final file: no workspace is left after a passing run, one is kept with `KEEP_WORKSPACE=1`, and a failing case keeps its own (a copy of the loader without its `set +f` fails only the noglob case) |
| `tests/local-install-epics.py` | `tests/local-install-epics.pl` | Identical standard output on this host (Debian 13, non-root) without `AA_TEST_EPICS_BIN` and with the real Debian 13 Base binary folder of the distribution tree | 7 and 7 of 12, the same 7, with the real Base supplied; the same five survive (`base-absolute-check`, `host-arch-validation`, `unique-candidate`, `binaries-executable`, `installer-unattended`) | Run on Rocky Linux 8.10 (Perl 5.26.3, `script` 2.32.1) as a non-root account without the variable and with the real Rocky Linux 8.10 Base binary folder: exit 0 and the same output as on Debian, empty standard error, 2026-10-31; repeated with the final file: the same result, and exit status 2 with a message when `script` is not on the search path |
| `tests/local-install-pv-menu.py` | `tests/local-install-pv-menu.pl` | Identical standard output apart from the evidence folder path, on this host (Debian 13, non-root) with the real Debian 13 Base binary folder of the distribution tree and a real soft IOC; 28 seconds in both | Clean runs with the leaked IOCs of earlier runs stopped between runs: 8 and 8 of 14 in the stable verdict; the same six survive (`owner-start-time`, `owner-zombie-check`, `resume-status`, `pause-message`, `finish-term`, `evidence-line`). `owner-zombie-check` depends on the moment at which the verifier collects the stopped IOC: Python killed it once in seven runs, and five repeats of each implementation all survived | Run on Rocky Linux 8.10 (Perl 5.26.3, `script` 2.32.1, `jq` 1.6, Python 3.9 for the unconverted fixture) as a non-root account with the real Rocky Linux 8.10 Base and a shallow clone of the pinned source commit: the three cases pass in 29 seconds, empty standard error, no IOC left, 2026-10-31 |
| `tests/local-install-pv-range.py` | `tests/local-install-pv-range.pl` | Identical standard output apart from the evidence folder path, on this host (Debian 13, non-root) with the real Debian 13 Base and a real soft IOC (five cases, 82 and 85 seconds); the `query.json` and `response.json` of the fixture have the same structure, and only the seconds between two real observations differ | Series of 10 mutations with the leaked IOCs of earlier runs stopped between runs: 6 and 6 of 10 in the stable verdict; the same four survive (`lower-bound`, `severity-filter`, `code-propagation`, `fraction-borrow`). `fraction-borrow` depends on the observed fraction of a second: five repeats of each implementation gave Python 0 and Perl 1 kills, and the earlier clean series gave Python 1 kill. The unmutated test itself failed in 2 of 6 runs of each implementation, in the same runs (see the finding and M9); the test is converted with that behavior (D23) | Run on Rocky Linux 8.10 (Perl 5.26.3, `perl-JSON-PP` 2.97) as a non-root account with the real Rocky Linux 8.10 Base: without `perl-JSON-PP` the test stops with `Can't locate JSON/PP.pm` and status 2; with it the five cases pass on the first run, and the keep-menu test passes its three cases with no python on the search path, 2026-10-31. On this host the whole `tests/local-install-pv.bash` passed with the real Debian 13 Base and a readable Tomcat 9.0.121 (four real WARs, a real soft IOC; the signal check still Python, the time-range and keep-menu checks Perl): exit 0 in 559 seconds, ending with `PASS: real PV round trip, interactive keep/resume and failed-retrieval cleanup`, no test process left |
| `tests/local-install-pv-signals.py` | `tests/local-install-pv-signals.pl` | Identical standard output apart from the evidence folder path, on this host (Debian 13, non-root) with the real Debian 13 Base and a real soft IOC; seven cases, 54 seconds in both; the `pause.json` check parses the file with `JSON::PP` and requires a top-level `status` of `ok`, as the Python test does | 8 and 8 of 11, the same eight; the same three survive (`ioc-term`, `ioc-kill-escalation`, `ioc-reap`): the soft IOC ends with its parent, so the three lines that stop and reap it are not needed for the test to pass. No timing-dependent verdict appeared; the series was run again with the final file and gave the same table | Run on Rocky Linux 8.10 (Perl 5.26.3, `script` 2.32.1) as a non-root account with the real Rocky Linux 8.10 Base: the seven cases pass in 56 seconds with the final file, status 0, no IOC left, `JSON::PP` 2.97001 present, 2026-11-01. A run without a controlling terminal passed on this host; a missing Base variable gives status 2 and a message, where the Python test stops with a `KeyError` |
| `tests/config-d-runtime.py` | `tests/config-d-runtime.pl` | Identical standard output apart from the evidence folder path, on this host (Debian 13, non-root) with Java 21, Tomcat 9.0.121 and the four built WAR files; six rounds and the invalid-syntax checks, 199 seconds for Python and 200 for Perl (202 with the file of the series). The evidence folders hold the same files (Perl adds `command.out`, `command.err` and `schema.sql`); the `config.d` files and the JVM observations are equal apart from the process IDs; the installed tree holds the same 3492 files in both, and its 257 configuration, script and library files are equal once the folder name is replaced | 11 and 11 of 15, the same eleven; the same four survive (`option-leak`, `require-config`, `pid-kept`, `startup-no-allexport`): no observation of the test depends on those lines. The Perl series ran on a copy of the file with SHA256 `1462090f88ade986c53e824981c7a7c0be2bd536f9c12dd0f2571914d3593a40`, which differs from the final file in the POD text only | Run on Rocky Linux 8.10 (Perl 5.26.3) as a non-root account with Java 21.0.12.1, the same Tomcat tree and WAR files (equal hashes): passes in 233 seconds with the first file and in 250 seconds with the file of the series, no JVM left, 2026-11-02; the packages java-21-openjdk-headless, perl-IO-Compress and unzip were installed beyond the base image. The error paths are equal: usage errors give 2 in both, an unusable Tomcat script, a busy port and a port base out of range give 1; a missing Tomcat folder gives 2 with a message where Python gives a traceback and 1. SIGINT ends both with 130 and no JVM left; SIGTERM ends both with 143, and Python leaves its JVMs running where the Perl test stops them |

For `tests/install-payload.py` the mutations number 14, for `tests/health-local.py` 27, for `tests/database-config.py` 29 on the configuration cases and 7 on the integration cases, for `tests/config-d.py` 21, for `tests/local-install-epics.py` 12, for `tests/local-install-pv-menu.py` 14, for `tests/local-install-pv-range.py` 10, for `tests/local-install-pv-signals.py` 11, for `tests/config-d-runtime.py` 15.

The control run, without a mutation, passed for both implementations before their kill tables were accepted. Standard error of the Perl run is empty and `perl -wc` and `podchecker` are clean. T1 to T4 stay Pending until the prerequisite documents, the consumers and the full local suite of the plan are done. The modules of `tests/install-payload.pl` are `Cwd`, `Digest::SHA`, `File::Basename`, `File::Copy`, `File::Find`, `File::Glob`, `File::Path`, `File::Temp`, `Getopt::Long`, `IO::Uncompress::Unzip`, `Pod::Usage` and `POSIX`; on Rocky Linux the packages perl-Digest-SHA and perl-IO-Compress are needed beyond the interpreter. The modules of `tests/health-local.pl` are `Cwd`, `File::Basename`, `File::Copy`, `File::Path`, `File::Temp`, `Getopt::Long`, `IO::Select`, `Pod::Usage`, `POSIX` and `Test::More`; on Rocky Linux the package perl-Test-Simple is needed, and the test needs the program `xmllint` beside `bash`, `make`, `git`, `df` and `sleep`. The modules of `tests/database-config.pl` are `Cwd`, `Fcntl`, `File::Basename`, `File::Copy`, `File::Glob`, `File::Path`, `File::Temp`, `Getopt::Long`, `IO::Socket::INET`, `Pod::Usage`, `POSIX`, `Test::More` and `Time::HiRes`; on Rocky Linux the packages perl-Test-Simple and perl-Time-HiRes are needed, and the test needs `xmllint`, `curl` and `git`; the integration cases also need `sqlite3`, `gzip`, `mysql`, the MariaDB server, `lsof` and `tree`. The modules of `tests/config-d.pl` are `Cwd`, `File::Basename`, `File::Copy`, `File::Path`, `File::Temp`, `Getopt::Long`, `IO::Socket::INET`, `Pod::Usage`, `POSIX` and `Test::More`; on Rocky Linux the package perl-Test-Simple is needed beside `bash`, `make` and `curl`. The modules of `tests/local-install-epics.pl` are `Cwd`, `File::Basename`, `File::Temp`, `Getopt::Long`, `Pod::Usage` and `POSIX`, all in the Perl core; the test needs `bash` and `script` of util-linux, which it uses for the pseudo-terminal of the installers and whose absence it reports as an environment error with exit status 2, and no Perl package beyond the interpreter on Rocky Linux. The modules of `tests/local-install-pv-range.pl` are `Cwd`, `File::Basename`, `File::Glob`, `File::Path`, `File::Temp`, `Getopt::Long`, `JSON::PP`, `Pod::Usage`, `POSIX` and `Time::Local`; on Rocky Linux the package perl-JSON-PP is needed, and the test needs a real EPICS Base (`AA_TEST_EPICS_BIN`), the source checkout (`AA_TEST_SOURCE_PATH`), `bash`, `jq` and `curl`. The modules of `tests/local-install-pv-signals.pl` are `Cwd`, `File::Basename`, `File::Path`, `File::Temp`, `Getopt::Long`, `JSON::PP`, `Pod::Usage` and `POSIX`; on Rocky Linux the package perl-JSON-PP is needed, and the test needs `bash`, `script` of util-linux, a real EPICS Base (`AA_TEST_EPICS_BIN`), the source checkout (`AA_TEST_SOURCE_PATH`), `jq` and `curl`. The modules of `tests/local-install-pv-menu.pl` are `Cwd`, `File::Basename`, `File::Path`, `File::Temp`, `Getopt::Long`, `IO::Select`, `Pod::Usage` and `POSIX`, all in the Perl core; it needs `bash`, `script` of util-linux, a real EPICS Base (`AA_TEST_EPICS_BIN`), the source checkout (`AA_TEST_SOURCE_PATH`) and, for the verifier, `jq` and `curl`, and, through `tests/local-install-pv-range.pl`, no Python. The modules of `tests/config-d-runtime.pl` are `Cwd`, `Digest::SHA`, `File::Basename`, `File::Glob`, `File::Path`, `File::Temp`, `Getopt::Long`, `IO::Select`, `IO::Socket::INET`, `IO::Uncompress::Unzip`, `JSON::PP`, `Pod::Usage`, `POSIX` and `Socket`; on Rocky Linux the packages perl-Digest-SHA, perl-IO-Compress and perl-JSON-PP are needed, and the test needs a Java of the version that compiled the WAR files (21), Tomcat 9, the built WAR files with `tomcat-log4j`, `bash`, `make`, `sqlite3` and `unzip`. Its probe of the free ports binds without address reuse, as the Python test does, so a port that a closed connection still holds fails the probe for about a minute after a run; the Perl test kept that behavior until M11 set address reuse on 2026-11-02. The runs leave the soft IOC of a mutated verifier behind when its clean-up is mutated, and that IOC takes the CA port of the next run, so a mutation run stops the IOCs of its tree before and after each run. The Python test kept every workspace; `tests/config-d.pl` removes the workspace of a passing case and keeps that of a failed case or any case with `KEEP_WORKSPACE=1`, like `tests/health-local.pl` and `tests/database-config.pl` (D22).

Input identities of the conversion record:

| Input | SHA256 | Use |
| --- | --- | --- |
| `tests/install-payload.pl` | `95a0153d476d75913900b024744e40567307777c165e7fb1e19cb75ca814f420` | The converted test |
| `scripts/install-payload.bash` | `d7eab599ca430f65c9facffcf67346cd848a4a68fc98b72f0e569c2137020578` | The shipped code under test, unmutated |
| `tests/health-local.pl` | `d5bf115d2be6ec9cb3cfeff99de287326345a82e5f99f65df30ed9b8dc7252c9` | The converted test; the mutation runs and the Rocky Linux run used the file with SHA256 `72816eb747f950683bfb0c8ab9a01261bbc59d494e3de7a28156aa3ef8ef7aeb`, which differs only in the POD text (prerequisite and case names) |
| `scripts/archappl.bash` | `3a1cb0ea5539cd18538621a79394058b7674df727fef166c35c11c3ab247cc4e` | The shipped code under test, unmutated |
| `tests/database-config.pl` | `68378f53f3ca82267dab61a9e00e81dc5b09f194db6731ad9225c5aa684c8feb` | The converted test; the mutation runs and the guest runs used the file with SHA256 `d3ba741c6d518f24a6f1c1a2de16f63bf90df43ca0ce20e62c5671682bfb6f77`, which differs only in the POD text (integration prerequisites) |
| `tests/config-d.pl` | `911f428c6d13fe7fced182d41bd31b503f6f20feb3902a2fab8f199fb002c5e9` | The converted test; the first mutation runs and the first Rocky Linux run used the file with SHA256 `54a1be7f48c805b1b1d96d20e034f302de2d3792873f0e2d0ffe1875620a19b6`, which differs only in the handling of the workspace after a passing case; the mutation runs and the Rocky Linux run were repeated with this file and gave the same verdicts |
| `tests/local-install-epics.pl` | `a77cafdeb49a0b0b1221c82a588f1be1643ea240c944626b53182602958b85b7` | The converted test; the first mutation runs and the first Rocky Linux run used the file with SHA256 `c8f7cc62486247520627b4721f74d2ee6f93bc26c2a9101c38decaa6cbe2fdb6`, which differs only in the upfront check for `script`; the mutation runs and the Rocky Linux run were repeated with this file and gave the same verdicts |
| `tests/local-install-pv-menu.pl` | `9a747fc971e54af2b86efd4d6ec3266531a4f609bca66ca3cc3fc8454050f42e` | The converted test; the mutation runs and the first Rocky Linux run used the file with SHA256 `a4094789c450f3480f8226c2dad8455a118ef7950e3945f2fcabe7ef7828093f`, which differs only in the link to the Python time-range fixture and the text that names it; the run on this host and the Rocky Linux run with the Perl fixture used this file |
| `tests/local-install-pv-range.pl` | `e7757e823adee6742f2b281acae3841e114eb4ff29e288764c2a8a5f31adc8c5` | The converted test; the mutation runs, the controls and the Rocky Linux run used this file |
| `tests/local-install-pv-signals.pl` | `2dbed3dd1836549b0b63d283ab517becf14f0c0312adaa75c1d6eae3c43613b7` | The converted test; the mutation runs and the Rocky Linux run used this file |
| `tests/config-d-runtime.pl` | `0b2565c3b29899902ff704578c517ab3b100533824dbccc6ec0eacf59a96287a` | The converted test; the Perl mutation runs, the final host run and the final Rocky Linux run used the file with SHA256 `1462090f88ade986c53e824981c7a7c0be2bd536f9c12dd0f2571914d3593a40`, which differs from this file in the POD text only. The first host and Rocky Linux runs used the file with SHA256 `596a54f026bdb5754551fafb4c7f178256da46ff5dc04453ae95669a9398aa96`, which checked the arguments of the JVMs for exactly one occurrence where the Python test accepts one or more, and had other POD text |

##### Closure Evidence

- Implementation and required verification: finished on 2026-11-02. T1 to T4 are Pass in Verification Results: T1 by D24 and T2 and T4 by D25, on the Debian 13 development host and on a Debian 13 and a Rocky Linux 8.10 guest.
- Completion criteria against the evidence: the `.py` files that remain are exactly `site-template/policies.py.in`, `tests/heap/inspect-inputs.py`, `tests/vm/driver.py`, `tests/vm/guest.py` and `tests/vm/local.py`, which existed at the prior state commit 95768200a49e965ef2dd1949919e955af982aff6 (T3); every mutation that a Python test killed is killed by its Perl test and the survivors are the same set of 48, which M10 follows (T1, D24); the full local suite with a real EPICS Base printed no skip and passed the completeness check of the VM driver, and the VM driver and guest verifier are identical to that prior state commit, so the VM matrix keeps its pass conditions (T2, D25).
- Repository landing: the last commit of the work is 6efd7db7044b2a77f3a763eb04435aa606836e63 on origin/maven. Observed at 2026-11-02T07:50:12Z after fetching origin; HEAD, origin/maven and the remote branch tip all resolved to that commit and the tree comparison had no differences. Recheck with fetch, rev-parse and diff against this commit. The commits of the conversions, each followed by its record: ce6142f069251fbd2a032ac739429dfee8b2a572 and 13887af973832a1d954a1343ed49356681109a0d, 84e9b44ee61291898ace5c817c7e1d9086358e71 and aa12b6265623a48d4a2b6bf644a71a5fc00b304c, cb810ca603ddfcfbd35b4d18dd7d44e8b13b8d80 and ff195c1d21ba4b20754d72cf5480f313c0f70376, 588c7d318638364a1ad41e2ee688c479b82e3ee8 and debe17fe9f806706b65f1c1057eba1c6680e6ba5, e592604cf76c9a78dcec7ee512afac504d8a8ee9 and e8cf9c42907e82956db6a8de87897a236a57b24f, 3b68f225e61b186f8883ee41bf575803a6d83789 and 22e7994a97b8ff005cb3f14a1e3f3776ea6e308a, 2164d899ea1e458bae18f917586b6e27f3770e06 and 35e2b198cee0e1b7b5da8a87381875f683b0103a, 7814888872a6f87db65b0f05252ec3c1bfa42033 and ff2fa4fa884337a75b0fdac3f0483b5cc154aec5; the prerequisite documents are 0c9b041282dca53b829b4ef4c033ecbdd60ab22b and f4d5bca4cff0da822aaaad1ccc7e4aa727845fac, and the decisions D24 and D25 are 6efd7db7044b2a77f3a763eb04435aa606836e63.
- Waived checks: the eight-case VM run of T2 and the mutations on the guests of T4, by D25 on 2026-11-02.
- Remaining external conditions: none. No G gate applies and the item has no linked GitHub issue. The defects and improvements that the conversion showed are the items M9 to M12.
- Linked GitHub issue: none.

##### GitHub Projection

Title: Replace the Python tests with Perl tests
Labels: enhancement
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M4 - Fix the findings of the review of the VM driver

Origin: 9576820 / M6
Identity History: M6 -> M4 on 2026-10-29; renumbered to match the selected work order
GitHub Issue: none
Status: Complete

##### Summary

The delegated third-person review of `tests/vm/driver.py`, `guest.py`, `local.py` and their documents on 2026-10-27 found one Must-Fix and further findings. The driver run of the same day stopped at its check `build_proof` (`driver.py`, near line 958), whose required Make list lacks `conf.install`, which the installer runs. D8 replaced the driver run for release 2.0.1 with a check that followed the install pages. D11 now assigns this work after M3, whose changes must be considered when checking the historical findings.

##### Scope

- Must-Fix: the driver loads its state (`driver.py` near lines 1153, 1160 and 1166) before it takes the exclusive lock (near line 1188); take the lock first.
- Make the required Make list of `build_proof` agree with the Make steps that the installers run, including `conf.install`.
- Minor findings: the tool reference is not verified; the tool checkouts are checked only at initialization; the SSH host pin is weaker than the stated global known-hosts handling; an interruption before the first record fails the whole run; the refusal check accepts any exit status 2; the snapshot comparison covers the whole libvirt host; a malformed context returns inconsistent exit codes.
- Strengthen the tests: in the mutation sample of the review, 101 of 125 mutations survive; the verdict gates, the cleanup verification, `build_proof`, the adoption path, the species mapping and the guest actions have no test that fails on a mutation.
- Correct the three places where the documents and the code disagree.

Out of scope: choosing a driver replacement (M8 owns that decision); changing the accepted historical local-installer verification method.

##### Completion Criteria

- Each finding of Scope is fixed or carries an owner decision that leaves it.
- Each fixed finding has a test that fails on a mutation that reintroduces it.
- The driver files do not change while a run that started with them is open.

##### Dependencies And Decisions

- D11 assigns this work and changes Deferred to Not started on 2026-10-29, superseding the scheduling restrictions of D8 and D10. The prohibition on changing driver files during an open run remains in force.
- M3 is a work-order dependency selected by D11. Because M3 converts the tests that the driver test calls and M8 may replace the driver or its tests, recheck each historical finding against the resulting implementation before drafting fixes; do not assume the old Python files or line numbers still apply.
- Preparation must account for every finding as still present, already resolved with evidence, or requiring a decision. Preserve the completion criteria and real-guest verification; obtain plan acceptance before implementation.
- The current record does not identify the three documentation discrepancies or provide a locator for the original review. Before plan acceptance, recover the 2026-10-27 review and record its durable source plus all three document paths, passages and corresponding code behavior in this detail. If that evidence cannot be recovered, obtain a scope decision before accepting the plan; do not infer the missing items or treat them as resolved.
- D32 retires this item on 2026-11-03: the driver is not repaired, because the VM test is rebuilt on the local installer scripts (M16) and the findings concern code that the rebuilt test does not keep.

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
| T1 | 2026-11-03 | Local host | Waived | D32; no fix was made |
| T2 | 2026-11-03 | Local libvirt host; fresh guest | Waived | D32; no fix was made |

##### Closure Evidence

- Retirement: D32 on 2026-11-03. The driver is not repaired, because the VM test is rebuilt on the local installer scripts (M16) and the findings of this item concern code that the rebuilt test does not keep. No plan was accepted and no file changed.
- Waived checks: T1 and T2.
- The review of 2026-10-27 that this item cites was not found in the repository or in the work folder, so its three findings on the documents were never recovered; D32 makes their recovery unnecessary.
- Remaining external conditions: none. No G gate applies and the item has no linked GitHub issue.
- Linked GitHub issue: none.

##### GitHub Projection

Title: Fix the findings of the review of the VM driver
Labels: enhancement
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M11 - Remove the false failures of the converted tests

Origin: 9576820 / M11
Identity History: created as M11 on 2026-11-02 by D24; narrowed and assigned on 2026-11-02 by D26, which moved the rule for the evidence of passing runs to M13
GitHub Issue: none
Status: Complete

##### Summary

Three behaviors of the converted tests report a failure, or can, although the code under test is fine. First, `tests/config-d-runtime.pl` probes its ports with a bind without address reuse, so for about a minute after a run the closed connections that still hold the ports make the probe fail with `Port N is not free`; the first series of mutations of M3 failed that way in all 15 runs, and the Python test behaves the same. Second, `tests/config-d-runtime.pl` reads the pid file of an instance with a numeric conversion, which gives 0 for text, where the Python test stops with an error. Third, `tests/local-install-pv-signals.pl` starts the verifier as its own child, and a verifier that inherits an ignored SIGINT cannot trap it: started from a background job of a non-interactive shell, `int-then-int` failed with status 1 instead of 130 on a Debian 13 and a Rocky Linux 8.10 guest, and the Python test starts its child the same way.

##### Scope

- Probe the ports of `tests/config-d-runtime.pl` so that only a listening socket counts as busy.
- Check the pid file of `tests/config-d-runtime.pl` as a number and stop with a clear message otherwise.
- Start the verifier of `tests/local-install-pv-signals.pl` with SIGINT at its default.

Out of scope: the conversion of the tests (M3); the rule for the evidence of passing runs (M13); the last sample of the time-range test (M9); changes to the shipped code.

##### Completion Criteria

- A run of `tests/config-d-runtime.pl` directly after another run passes the port probe, and a port that a process listens on still fails it with the port named.
- A pid file with text ends the run with a clear message that names the file.
- The signal test passes when it is started from a background job that ignores SIGINT.
- The mutations that the two tests killed before stay killed.

##### Dependencies And Decisions

- D24 creates this item on 2026-11-02.
- D26 narrows it to the three behaviors, assigns it and changes Open to Not started on 2026-11-02; the evidence rule is M13.
- M3 converts the tests first; M11 changes the converted files.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-11-02; the owner accepted this plan text.
Implementation Authorization: 2026-11-02; explicit owner authorization to implement this plan. It does not authorize commit, push, issue creation or provisioning of guests.
Superseded Plan Artifacts: none

1. In `tests/config-d-runtime.pl`, set address reuse on the socket of the port probe. Show it with a second run directly after a first run, and with a process that listens on a port of the test.
2. In the same file, accept only digits in the pid file and fail with a message that names the file otherwise. Show it with a scratch mutation of the shipped `site-template/startup.sh.in` that writes text into the pid file.
3. In `tests/local-install-pv-signals.pl`, reset SIGINT to its default in the child before it starts the verifier. Show it by starting the test from a background job of a non-interactive shell.
4. Run the recorded mutations of both files again and compare their verdicts with the recorded ones.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Run `tests/config-d-runtime.pl` twice in a row, then with a listening process on a port of the test, then with the scratch mutation that writes text into the pid file | A host with Java, Tomcat 9 and the built WAR files | The second run passes, the busy port fails with the port named, the text fails with a message that names the file |
| T2 | Local | Start `tests/local-install-pv-signals.pl` from a background job that ignores SIGINT, then run the recorded mutations of both changed tests | A host with a real EPICS Base, Java and Tomcat 9 | The background start passes and the verdicts equal the recorded ones |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-11-02 UTC | The Debian 13 development host with Java 21, Tomcat 9.0.121 and the four built WAR files | Pass | `tests/config-d-runtime.pl` run twice in a row at port base 30665 ended with status 0 both times, in 208 and 211 seconds, with empty standard error; with a process listening on a port of the test it ended with status 1 and `Port 31902 is not free: Address already in use`; with the scratch mutation `pid-text`, which writes text into the pid file after the start of each instance, it ended with status 1 and `The pid file of mgmt does not hold a number` followed by the file name, without a numeric warning. The test file of these runs has SHA256 `cbe8f6fb1252b63a98ac29fd79f64f754507c211cf5a599488c631005b4df1dc`; logs under `work/m3-perl/config-d-runtime/` |
| T2 | 2026-11-02 UTC | The Debian 13 development host with a real EPICS Base, Java 21 and Tomcat 9.0.121 | Pass | `tests/local-install-pv-signals.pl` started from a background job with `SigIgn` 7 (HUP, INT and QUIT ignored) passed its seven cases, `int-then-int` with status 130; its file has SHA256 `a7b206839c65b159e28e1fe3f9b1862cd79150981a1bb4d5fad29f4e0414d0eb`. The 15 recorded mutations of `tests/config-d-runtime.pl` gave the recorded verdicts (11 killed, 4 survive: `option-leak`, `require-config`, `pid-kept`, `startup-no-allexport`) and `pid-text` was killed; the 11 recorded mutations of `tests/local-install-pv-signals.pl` gave the recorded verdicts (8 killed, 3 survive). The series ran on the copy of the runtime test with the SHA256 above, which differs from the file now committed (SHA256 `0ebb6b0513fc90d5e0abd57fdb8a6d2ddecd51441be2a2390e300eb21f03bf4b`) in the POD text only; no run had a port probe failure or left a JVM |

##### Closure Evidence

- Implementation and required verification: finished on 2026-11-02. T1 and T2 are Pass in Verification Results, on the Debian 13 development host.
- Completion criteria against the evidence: a run of `tests/config-d-runtime.pl` directly after another run passes the port probe, and a port that a process listens on still fails it with the port named (T1); a pid file with text ends the run with a message that names the file, shown with a mutation of the shipped `site-template/startup.sh.in` (T1); the signal test passes when it is started from a background job that ignores SIGINT, `int-then-int` with status 130 (T2); the recorded mutations of both tests give the recorded verdicts, and `pid-text` is killed (T2).
- Repository landing: the code is commit 134857b0a4f7e910b707b00993a2f9f027c75823 and the last commit of the work is 497406850249b97d983fe80a1d5319f9b54c0a79 on origin/maven. Observed at 2026-11-02T16:01:54Z after fetching origin; HEAD, origin/maven and the remote branch tip all resolved to that last commit and the tree comparison had no differences. Recheck with fetch, rev-parse and diff against this commit.
- Remaining external conditions: none. No G gate applies and the item has no linked GitHub issue. The rule for the evidence of passing runs is M13, and the scalar prototype of `check` is M14 (D27).
- Linked GitHub issue: none.

##### GitHub Projection

Title: Remove the false failures of the converted tests
Labels: bug
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M14 - Declare scalar prototypes on the check helper of the Perl tests

Origin: 9576820 / M14
Identity History: created as M14 on 2026-11-02 by D27, which split it from M12
GitHub Issue: none
Status: Complete

##### Summary

Six Perl tests define the helpers `check` and `fail` without a prototype: `tests/config-d-runtime.pl`, `tests/install-payload.pl`, `tests/local-install-epics.pl`, `tests/local-install-pv-menu.pl`, `tests/local-install-pv-range.pl` and `tests/local-install-pv-signals.pl`. A pattern match that fails inside the argument list of `check` gives an empty list, so the message takes the place of the condition and the check passes whatever the text is. A line of that form was written on 2026-11-02 while M11 was implemented, and the scratch mutation that writes text into the pid file showed it; a search of every call in the nine tests found no such line left.

##### Scope

- Declare `check` with the prototype `($$)` and `fail` with `($)` in the six tests, so that the arguments are read in scalar context.
- Show that a list-context pattern match in a call of `check` now fails the check, by running the real runtime test against the mutation that writes text into the pid file.

Out of scope: the shared module for the helpers (M12); changes to what any check tests; the Test::More based tests, whose `ok` already reads its condition in scalar context.

##### Completion Criteria

- The six tests compile with the prototypes and pass unmutated on the local host.
- The runtime test with the earlier, list-context form of the pid check is killed by the mutation that writes text into the pid file, with the message of the check.

##### Dependencies And Decisions

- D24 sends the improvements found during the conversion to the Backlog; D27 splits this part from M12, assigns it and changes it to In progress on 2026-11-02.
- M3 converts the tests first; M14 changes the converted files. M12 keeps these prototypes in the shared module.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-11-02; the owner accepted this plan text.
Implementation Authorization: 2026-11-02; explicit owner authorization to implement this plan. It does not authorize commit, push, issue creation or provisioning of guests.
Superseded Plan Artifacts: none

1. Add the prototypes to `check` and `fail` in the six tests.
2. Run `perl -wc` on each, then each test unmutated on the local host with a real EPICS Base, Java and Tomcat where it needs them.
3. In a scratch copy of the runtime test, restore the list-context form of the pid check and run it against the mutation that writes text into the pid file.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Run each of the six tests unmutated on the shipped code | The Debian 13 development host with a real EPICS Base, Java 21, Tomcat 9 and the built WAR files | Every test passes as before |
| T2 | Local | Run the scratch copy of the runtime test with the list-context pid check against the mutation `pid-text` | The same host | The run fails with `The pid file of` followed by the instance name and the file |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-11-02 UTC | The Debian 13 development host with a real EPICS Base, Java 21, Tomcat 9.0.121 and the built WAR files | Pass | The six tests that define `check`, unmutated and with the prototypes, ended with status 0 and empty standard error and printed no `SKIP:` line: `tests/local-install-epics.pl` in 1 second, `tests/install-payload.pl` in 32 seconds on the two Maven target directories and the old log4j folder, `tests/local-install-pv-signals.pl` in 53 seconds, `tests/local-install-pv-range.pl` in 90 seconds at the first attempt, `tests/local-install-pv-menu.pl` in 45 seconds and `tests/config-d-runtime.pl` in 228 seconds; logs under `work/m3-perl/m14/` |
| T2 | 2026-11-02 UTC | The same host | Pass | A scratch copy of the runtime test with the list-context form of the pid check and the prototype `($$)` passed its control run and was killed by the mutation `pid-text` with status 1 and `The pid file of mgmt does not hold a number` followed by the file name, without a numeric warning; the same form without the prototype passed the check (M11). The four JVMs of the aborted instances stayed running and were stopped by hand, which M15 follows |

##### Closure Evidence

- Implementation and required verification: finished on 2026-11-02. T1 and T2 are Pass in Verification Results, on the Debian 13 development host.
- Completion criteria against the evidence: the six tests compile with the prototypes `check($$)` and `fail($)` and pass unmutated, with status 0, empty standard error and no `SKIP:` line (T1); the runtime test with the earlier, list-context form of the pid check is killed by the mutation that writes text into the pid file, with the message of the check (T2).
- Repository landing: the code is commit 23e98e8980a6a73742b99f8d4985fa1d646ecab8 and the last commit of the work is 515e7c7a6e1b00c18cc5b88cca946d3f8b0da47e on origin/maven. Observed at 2026-11-02T16:50:58Z after fetching origin; HEAD, origin/maven and the remote branch tip all resolved to that last commit and the tree comparison had no differences. Recheck with fetch, rev-parse and diff against this commit.
- Remaining external conditions: none. No G gate applies and the item has no linked GitHub issue. The shared module that keeps these prototypes is M12, and the instances that an aborted runtime test leaves running are M15.
- Linked GitHub issue: none.

##### GitHub Projection

Title: Declare scalar prototypes on the check helper of the Perl tests
Labels: bug
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M15 - Stop the instances that an aborted runtime test did not record

Origin: 9576820 / M15
Identity History: created as M15 on 2026-11-02 by D24; assigned and changed from Open to In progress on 2026-11-02 by D28
GitHub Issue: none
Status: Complete

##### Summary

When a run of `tests/config-d-runtime.pl` ends early, its stop routine stops only the instances whose pid it has recorded: it walks the list that the readiness wait fills while it reads the pid files. A run that fails before it has read a pid file leaves the instances that the launcher started running. Observed on 2026-11-02 with the scratch mutation that writes text into the pid file: the test failed with its message, and the four JVMs of the instances stayed up until they were stopped by hand; the cleaning script of the earlier mutation series had hidden it. The Python test walks the same kind of list. That mutation also leaves text in the pid files, so the pid files cannot name the instances; the command line of each JVM does, because it holds `-Dcatalina.base=` followed by the installed tree of the run, which the test creates anew for every run and the runtime test already checks.

##### Scope

- On an abnormal end, find every process whose command line holds `-Dcatalina.base=` and the installed tree of the run, stop it like the recorded ones and wait for it, whatever the pid files hold.
- Show it by running the mutation that writes text into the pid file directly, without a cleaning script, and checking that no JVM of the run remains.

Out of scope: the conversion of the tests (M3); the scalar prototypes (M14); changes to the shipped code.

##### Completion Criteria

- A run that ends early, including the one with the pid file mutation, leaves no JVM of its instances.
- The recorded mutations of the runtime test keep their verdicts.

##### Dependencies And Decisions

- D24 creates this item on 2026-11-02.
- D28 assigns it and changes Open to In progress on 2026-11-02, after the owner accepted the plan.
- M3 converts the tests first; M15 changes the converted file.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-11-02; the owner accepted this plan text.
Implementation Authorization: 2026-11-02; explicit owner authorization to implement this plan. It does not authorize commit, push, issue creation or provisioning of guests.
Superseded Plan Artifacts: none

1. Reproduce the leftover JVMs with the pid file mutation and no cleaning script, and record them.
2. Change the abnormal stop so that it also stops the processes found by the command line of the run in `/proc`, then run the reproduction again.
3. Run the recorded mutations of the runtime test again and compare their verdicts with the recorded ones.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Run the runtime test against the mutation that writes text into the pid file, without a cleaning script, and count the JVMs of the run afterwards | A host with Java, Tomcat 9 and the built WAR files | No JVM of the run remains |
| T2 | Local | Run the recorded mutations of the runtime test and compare their verdicts with the recorded ones | The same host | The verdicts are unchanged |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-11-02 UTC | The Debian 13 development host with Java 21, Tomcat 9.0.121 and the four built WAR files | Pass | The runtime test run directly against the mutation that writes text into the pid file, without a cleaning script: before the change it ended with status 1 and the message of the pid check, and four JVMs of the run stayed up until they were stopped by hand; after the change it ended with status 1 and the same message, printed `Stopped: direct-noglob`, and no JVM of the run remained, counted by the folder name of the run. Logs under `work/m3-perl/m15/` |
| T2 | 2026-11-02 UTC | The same host | Pass | The 15 recorded mutations of the runtime test gave the recorded verdicts (11 killed, 4 survive: `option-leak`, `require-config`, `pid-kept`, `startup-no-allexport`) and `pid-text` was killed with the message of the pid check, without a numeric warning; no run failed the port probe. The test file of the series has SHA256 `d2976f2a50b6e7cf264aa6a42eac0bbf19a4518ee707e238c05dbb7521fa798e`; logs under `work/m3-perl/config-d-runtime/` |

##### Closure Evidence

- Implementation and required verification: finished on 2026-11-02. T1 and T2 are Pass in Verification Results, on the Debian 13 development host.
- Completion criteria against the evidence: a run that ends early, shown with the mutation that writes text into the pid file and no cleaning script, leaves no JVM of its instances after the change, where four stayed up before it (T1); the 15 recorded mutations of the runtime test give the recorded verdicts and `pid-text` is killed with the message of the pid check (T2).
- Repository landing: the code is commit 79f21776b77d622702e7a45292ecf317586c8b69 and the last commit of the work is bd373daac4564f86e8f164fe1777537c27164196 on origin/maven. Observed at 2026-11-02T22:44:37Z after fetching origin; HEAD, origin/maven and the remote branch tip all resolved to that last commit and the tree comparison had no differences. Recheck with fetch, rev-parse and diff against this commit.
- Remaining external conditions: none. No G gate applies and the item has no linked GitHub issue.
- Linked GitHub issue: none.

##### GitHub Projection

Title: Stop the instances that an aborted runtime test did not record
Labels: bug
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M13 - Leave only the pass record of the tests and use a local temporary folder

Origin: 9576820 / M13
Identity History: created as M13 on 2026-11-02 by D26; retitled, assigned and changed from Open to In progress on 2026-11-02 by D29
GitHub Issue: none
Status: Complete

##### Summary

Six Perl tests keep the files of every run: `tests/config-d-runtime.pl` (about 476 MB for one run), `tests/local-install-pv-signals.pl`, `tests/local-install-pv-range.pl`, `tests/local-install-pv-menu.pl`, `tests/install-payload.pl` and `tests/local-install-epics.pl`, while `tests/config-d.pl`, `tests/health-local.pl` and `tests/database-config.pl` remove the workspace of a passing case (D22). The shell test `tests/local-install-pv.bash` keeps its workspace too. The verifier `scripts/verify-local-pv.bash` creates its evidence folder below `/tmp` with a fixed path, and the tests create their folders below `TMPDIR` or `/tmp`; the owner's temporary folder is the local one below the checkout. The Python tests kept everything. D29 settles one rule for all of them.

##### Scope

- A passing run of each Perl test and of `tests/local-install-pv.bash` leaves only its output and exit status. It removes the files it generated: its own workspace and the evidence folder of the verifier it started, and only the ones of this run. A failed run, or a run with `KEEP_WORKSPACE=1`, keeps them and prints their path.
- The tests create their temporary files below the folder that `TMPDIR` names, or else below `work/scratch/tmp` of the checkout, which they create when it is missing; when it cannot be created they stop with a message.
- `scripts/verify-local-pv.bash` creates its evidence folder below `TMPDIR` and keeps `/tmp` as the default when `TMPDIR` is unset.
- `tests/README.md` and the POD texts state the rule.

Out of scope: the conversion of the tests (M3); the Claude Code settings, which the owner keeps; the shell tests other than `tests/local-install-pv.bash`; a shared module for the helpers (M12).

##### Completion Criteria

- After a passing run of each of the nine Perl tests and of `tests/local-install-pv.bash`, no file of the run remains below the temporary folder or `/tmp`.
- A failed run and a run with `KEEP_WORKSPACE=1` keep their files and print the path.
- With `TMPDIR` unset, a test creates `work/scratch/tmp` when it is missing and works below it.
- The full local suite with a real EPICS Base passes without a skip.

##### Dependencies And Decisions

- D26 creates this item on 2026-11-02.
- D29 sets the rule, retitles the item, assigns it and changes Open to In progress on 2026-11-02, after the owner accepted the plan.
- M3 converts the tests first; M13 changes the converted files.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-11-02; the owner accepted this plan text.
Implementation Authorization: 2026-11-02; explicit owner authorization to implement this plan. It does not authorize commit, push, issue creation or provisioning of guests.
Superseded Plan Artifacts: none

1. Give each of the nine Perl tests the same two helpers: the temporary folder (`TMPDIR`, else `work/scratch/tmp` of the checkout, created when missing) and the end of a workspace (removed only when the run passed, `KEEP_WORKSPACE` is not 1, and the path is the one this run created, absolute, not a link and equal to its resolved path; otherwise `Workspace retained: <path>`).
2. Change the six tests that keep their files to create their workspace below the temporary folder and to end it with the helper; change the three tests of D22 to use the temporary folder.
3. In the tests that start the verifier, pass the temporary folder as `TMPDIR` and, on a pass, remove the evidence folder that the verifier printed when it lies below the temporary folder.
4. In `scripts/verify-local-pv.bash`, create the evidence folder below `${TMPDIR:-/tmp}`.
5. In `tests/local-install-pv.bash`, create the workspace below the temporary folder and remove it on success.
6. Update `tests/README.md` and the POD texts.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Run each of the nine Perl tests and `tests/local-install-pv.bash` unmutated, and list the temporary folder and `/tmp` before and after | The Debian 13 development host with a real EPICS Base, Java 21, Tomcat 9 and the built WAR files | Every run passes and no new entry of the run remains |
| T2 | Local | Run representative failing runs (the recorded mutations) and runs with `KEEP_WORKSPACE=1`, and run a test with `TMPDIR` unset in a copy of the checkout that has no `work/scratch/tmp` | The same host | The files stay and the path is printed; the folder is created and used |
| T3 | System | Full `tests/run-all-tests.bash --local` with a real EPICS Base | The same host | Passes without a skip and `local_suite_complete` returns True |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-11-02 UTC | The Debian 13 development host with a real EPICS Base, Java 21, Tomcat 9.0.121 and the built WAR files | Pass | Listing the temporary folder and `/tmp` before and after: `tests/local-install-epics.pl` (1 second), `tests/install-payload.pl` (14), `tests/local-install-pv-signals.pl` (51), `tests/local-install-pv-range.pl` (83), `tests/local-install-pv-menu.pl` (27), `tests/config-d-runtime.pl` (202) and `tests/local-install-pv.bash` (557) ended with status 0 and left no new entry; `tests/config-d.pl`, `tests/health-local.pl` and `tests/database-config.pl` passed inside the full local suite (T3) with no new entry. A first run of the range and menu tests failed in 4 seconds because an edit of the files had removed their executable mode, which the `curl` fixture needs; the mode was restored and both passed. Logs under `work/m3-perl/m13/` |
| T2 | 2026-11-02 UTC | The same host | Pass | A failing run keeps its files and prints the path: the signal test against a verifier whose pause message is changed (status 1, `Workspace retained: …`) and the runtime test against the mutation that writes text into the pid file (status 1, folder kept, no JVM left). `KEEP_WORKSPACE=1` keeps the files of passing runs of the menu test (the workspace and three evidence folders of the verifier) and of the payload test. In a copy of the checkout without `work/`, the signal test run with `TMPDIR` unset created `work/scratch/tmp` and kept its workspace and the evidence folder of the verifier below it. The runs left folders that were moved to `work/trash/` |
| T3 | 2026-11-02 UTC | The same host | Pass | `bash tests/run-all-tests.bash --local` with a real Debian 13 EPICS Base ended with status 0 in 163 seconds: the five groups passed (279, 40, 22, 401 and 14 checks), no `[SKIP]` line, no line that starts with `SKIP:`, no unittest skip, `local_suite_complete` returned True, and no new entry appeared in the temporary folder |

##### Closure Evidence

- Implementation and required verification: finished on 2026-11-02. T1 to T3 are Pass in Verification Results, on the Debian 13 development host.
- Completion criteria against the evidence: after a passing run of `tests/local-install-epics.pl`, `tests/install-payload.pl`, `tests/local-install-pv-signals.pl`, `tests/local-install-pv-range.pl`, `tests/local-install-pv-menu.pl`, `tests/config-d-runtime.pl` and `tests/local-install-pv.bash` no entry of the run remained in the temporary folder, and the three tests of D22 passed in the full local suite with no new entry (T1, T3); a failed run and a run with `KEEP_WORKSPACE=1` kept their files and printed the path (T2); with `TMPDIR` unset a test created `work/scratch/tmp` in a copy of the checkout and worked below it (T2); the full local suite passed without a skip and `local_suite_complete` returned True (T3).
- Repository landing: the code is commit 6049646ca574234e4afe005db64fa368f26dcacb and the last commit of the work is 3de0e558e4c26f4dea444f79861159a3a06a561f on origin/maven. Observed at 2026-11-03T00:19:31Z after fetching origin; HEAD, origin/maven and the remote branch tip all resolved to that last commit and the tree comparison had no differences. Recheck with fetch, rev-parse and diff against this commit.
- Remaining external conditions: none. No G gate applies and the item has no linked GitHub issue. The Claude Code settings stay with the owner (D29).
- Linked GitHub issue: none.

##### GitHub Projection

Title: Leave only the pass record of the tests and use a local temporary folder
Labels: enhancement
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M9 - Keep the last sample of the PV time-range test inside the query range

Origin: 9576820 / M9
Identity History: created as M9 on 2026-10-31 by D23; assigned and changed from Open to In progress on 2026-11-03 by D30; renamed from "Keep one consistent exchange in the PV time-range test" on 2026-11-03 by D31
GitHub Issue: none
Status: Complete

##### Summary

The time-range test (`tests/local-install-pv-range.pl`, converted from `tests/local-install-pv-range.py` by M3) replaces the HTTP transport of the shipped PV verifier with a fixture that answers from the real soft IOC. For every data request the fixture reads the current value and time of the IOC with `caget` as the last sample of its answer. The verifier fixes the upper bound of the query before that read, so a read that sees a later time gives a sample past the bound, and the test, which counts the samples inside the bound, finds one valid sample instead of two. Earlier series showed the failure in 2 of 6 runs of each implementation; on 2026-11-03 the unmutated test failed in 1 of 12 runs, and in 3 of 12 with the query and the response kept in one file. In all four failures the last sample is one second past the bound of the query of the same attempt. The conversion keeps this behavior (D23).

##### Scope

- Hold the time of the last sample of a data answer at the upper bound of the query when the read of the IOC gives a later time; the value stays the one read from the IOC.
- Measure the unmutated test in a series of 30 runs and run the recorded mutations again.

Out of scope: the conversion of the test (M3); changing the shipped verifier; the menu test; the timing dependence of the `fraction-borrow` mutation.

##### Completion Criteria

- The unmutated test passes in all 30 runs of the series after the change.
- The recorded mutations keep their stable verdicts: the killed ones stay killed and the survivors `lower-bound`, `severity-filter` and `code-propagation` survive; `fraction-borrow` is outside this criterion.

##### Dependencies And Decisions

- D23 creates this item on 2026-10-31.
- D30 assigns it and changes Open to In progress on 2026-11-03, after the owner accepted the plan.
- D31 replaces the plan on 2026-11-03, after the owner accepted the revised plan.
- M3 converts the test first; M9 changes the converted file.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-11-03; the owner accepted this plan text.
Implementation Authorization: 2026-11-03; explicit owner authorization to implement this plan. It does not authorize commit, push, issue creation or provisioning of guests.
Superseded Plan Artifacts: the plan accepted on 2026-11-03 under D30, which recorded the query and the response in one file; its change was removed before any commit (D31).

1. In `tests/local-install-pv-range.pl`, restore the committed text and make `curl_fixture` use the upper bound of the query as the time of the last sample when the time read from the IOC is later.
2. Run the unmutated test 30 times with the changed file.
3. Run the recorded mutations of the test and compare their verdicts with the recorded ones.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Run the unmutated test 30 times with the changed file and count the failures | A host with a real EPICS Base | No failure in the 30 runs |
| T2 | Local | Run the recorded mutations of the test and compare their verdicts with the recorded ones | The same host | The stable verdicts are unchanged |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-11-03T02:22Z | Local host, Debian 13, non-root, the real Debian 13 Base 7.0.10 and a real soft IOC | Pass | 30 of 30 runs pass (79 to 84 seconds each) with `tests/local-install-pv-range.pl` SHA-256 `4e025026037d97f02858a572f7c4d55836c3855c04e884de656df091da0ce04c`; the committed file, SHA-256 `de977c0948185cf759398b1f26c1818b9d5269be90989013699294167fd0ebf4`, differs from it in one comment line only |
| T2 | 2026-11-03T02:33Z | The same host | Pass | The same file: `upper-bound-nanos`, `two-distinct-values`, `time-window`, `wrong-pv-name`, `status-200-branch` and `response-copy` are killed; `lower-bound`, `severity-filter` and `code-propagation` survive; `fraction-borrow` survived in this run |

##### Closure Evidence

- Implementation and required verification: finished on 2026-11-03. T1 and T2 are Pass in Verification Results, on the Debian 13 development host.
- Completion criteria against the evidence: the unmutated test passed all 30 runs of the series after the change (T1); the recorded mutations kept their stable verdicts, six killed and `lower-bound`, `severity-filter` and `code-propagation` surviving (T2).
- Repository landing: the code is commit e39252eeda4cff81f7c60654087d03f156426d75 and the last commit of the work is e44d7e0e727dd675a8b9b6423e6fc21ca752fc8b on origin/maven. Observed at 2026-11-03T04:27:13Z after fetching origin; HEAD and origin/maven resolved to that last commit and the tree comparison of the two changed files had no differences. Recheck with fetch, rev-parse and diff against this commit.
- Remaining external conditions: none. No G gate applies and the item has no linked GitHub issue.
- Linked GitHub issue: none.

##### GitHub Projection

Title: Keep the last sample of the PV time-range test inside the query range
Labels: bug
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M8 - Decide the replacement of the VM driver and guest verifier

Origin: 9576820 / M8
Identity History: created as M8 on 2026-10-30 by D17; assigned and changed from Open to Complete on 2026-11-03 by D32
GitHub Issue: none
Status: Complete

##### Summary

D17 leaves `tests/vm/driver.py` (1,247 lines), `tests/vm/guest.py` (894 lines) and `tests/vm/local.py` (918 lines) out of M3. The driver orchestrates fresh guests, the verifier checks the installed appliance on guests with different Python versions, and the driver test checks the driver and its documents. D6 keeps Python only where testing Python code requires it; D16 names Perl for the replacement tests. D32 decides on 2026-11-03 that none of the three files is kept or ported: the VM installation test is rebuilt in Perl on the local installer scripts, with cloud-provision alone answering for the guests, and that work is M16.

##### Scope

- Decide whether the driver, the guest verifier and the driver test are replaced, and in which language, with the consequence for each of them.
- The replacement that the decision selects is carried out by M16.

Out of scope: the tests that M3 converts; fixing the review findings of the current driver (M4); Ansible, which the rebuilt test does not run (D32).

##### Completion Criteria

- The decision and its date are recorded, naming which of the three files change language and which stay.
- If a file is replaced, its replacement fails on the defect each assertion covers, shown by a mutation of the shipped code, and a real guest verdict passes under the current conditions.

##### Dependencies And Decisions

- D17 creates this item on 2026-10-30 and leaves it Open until the owner decides priority and scope.
- D6 and D16 apply to any replacement.
- D32 decides it on 2026-11-03 and closes it: none of the three files is kept, M16 builds the replacement, and M4 is retired by the same decision.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. After the owner decision on priority and scope, map each historical finding of M4 to the replacement choice.
2. Plan the replacement of the chosen files.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Review | Compare the findings of M4 with each replacement choice | The register | The decision names which findings survive each choice |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-11-03 | The register | Pass | D32 against the findings of M4: none survives, because the current driver is not kept; the lock order, the required Make list of `build_proof`, the Minor findings and the surviving mutations of the driver leave with it, and the rebuilt test runs the local installer script instead of checking a Make list |

##### Closure Evidence

- Decision: D32 on 2026-11-03 records that none of `tests/vm/driver.py`, `guest.py` and `local.py` is kept or ported and that a new test in Perl on the local installer scripts replaces them (M16); the first completion criterion is met by that record.
- The second completion criterion, the defect sensitivity and the real guest verdict of the replacement, belongs to M16, since this item replaces no file itself; the three files stay in the repository until M16 replaces them (D32).
- Remaining external conditions: none. No G gate applies and the item has no linked GitHub issue.
- Linked GitHub issue: none.

##### GitHub Projection

Title: Decide the replacement of the VM driver and guest verifier
Labels: enhancement
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M17 - Upgrade an installed appliance by comparing its state with the checkout

Origin: 9576820 / M17
Identity History: created as M17 on 2026-11-03 by D33; assigned and changed from Open to In progress on 2026-11-03 by D34; completed on 2026-11-05 against the landed implementation and verification record at 5da67a8
GitHub Issue: none
Status: Complete

##### Summary

The local installer scripts compare the installed appliance with the selected source and rendered configuration. They apply only changed layers. An unchanged installation requires no build or restart, and a selected soft IOC test runs against the running appliance. Configuration changes reuse the target WARs when the program layer is unchanged and all four WARs exist.

Implementation and installation documentation landed through `2baf640`; `d1ca12a` carries the selected-PV correction and `54ee5ab` carries maintenance documentation. T1 to T6 have the bounded results below. T7 and T8 passed real changed-source and missing-WAR upgrades, startup readiness, and historical-sample preservation on an isolated SQLite appliance. T9 verifies the approved correction for unreadable inspection inputs. The read-failure correction and verification record landed at `5da67a8`; M17 completed on 2026-11-05 within the recorded verification limits.

##### Scope

- An inspection helper `scripts/inspect-local-install.bash` that the installer scripts call. It changes nothing on the system: it only reads the installed state, and its paths (installation folder, systemd folder, source clone, rendered folder) are arguments, so a test can point it at a temporary tree. The installer first updates the checkout as the checkout owner (`git fetch`, `make srcupdate`, then `make db.conf`, `make conf.archapplproperties` and `make conf.install`, which write only below the checkout and do not depend on the build), because the comparison needs the target commit and the rendered files. The new option `--inspect` of the three installer scripts takes the installer lock, runs this update, prints the comparison, and changes nothing on the system; `--plan` keeps its present meaning, prints the commands and executes nothing, so that the tests and documents that treat it as free of side effects stay true. The helper covers six layers: program (the commit in the installed `version.txt` against the commit of `SRC_TAG` after the fetch), configuration (the rendered `site-template` files against the installed copies in `AA_INSTALL_LOCATION` and the `conf/` files of each instance, with the port values of `server.xml`), systemd (the rendered units and `override.conf` against `/etc/systemd/system`), schema (the source SQL file at the installed commit against the file at the target commit, by `git diff`), storage (the tier folders and their owner) and runtime (unit states and HTTP readiness without `sudo`; `archappl.bash health`, which only the service account can run, through `sudo -n` when that works without a password, and otherwise reported as "not observed: needs sudo", which does not make the layer changed; observed, never changed).
- A normal run takes the installer lock before the checkout update, which moves the lock from after the confirmation to before the first change of the checkout, so that two installers never change the same `site-template` together; it then always inspects, prints per layer what differs and why, and asks the confirmation, which names the layers that will change and moves from before the source update to after the inspection; `-y` skips the question. The `sudo` password is asked after the confirmation, as now. The optional soft IOC question stays the first question, before the lock and the checkout update, as it is now, and is skipped by `-y` and without a terminal, because `tests/local-install-epics.pl` requires that an unprepared EPICS environment stops the installer before any `make` or `sudo` step and because a later question would make that test fetch and render the working checkout. When no layer changed, the run asks no confirmation and no `sudo` password: it reports the installation as up to date, and its verification observes the unit states and HTTP readiness, and `archappl.bash health` only through a `sudo -n` that works without a password, otherwise as "not observed: needs sudo". A run without an installation to compare with is a first installation and treats every layer as changed. Only the changed layers run: the build when the program changed or when an install will run and `epicsarchiverap-maven-src/target` does not hold the four WARs named for the target commit (a WAR file name carries the abbreviated commit, as in `aa-20261026-e0a8e66e-mgmt.war`), because `make install` installs the WARs it finds and stops when none is there; the stop of the appliance, `make install` and the start when the program, the configuration or the systemd layer changed, and the stop only after the build; `make install` installs everything from the existing WARs, so a configuration-only run builds nothing and replaces the payload with the same WARs; the schema and storage steps run when their layers changed. After a run, and after a run that changed nothing, the verification observes `health`, the version of `getApplianceInfo` equal to the installed commit, and HTTP 200.
- `site-template/.versions` installed into `AA_INSTALL_LOCATION` by `make install`.
- Schema rule: no difference runs nothing; a difference that only adds whole `CREATE TABLE` blocks runs `make sql.fill`; any other difference, including a changed or removed column and a changed comment, stops with the diff until the owner has read it and runs the installer again with `--accept-schema`, which loads the schema and goes on. The installed commit is not in the clone: the inspection fetches first and stops when the commit is still absent.
- Known limits, stated in the plan output and the documents: the schema layer assumes that the installed database was loaded from the schema file of the installed commit, so a table changed by hand or loaded from an older commit is not detected; a column change has no migration in the source, so the owner decides it; a value given only on a `make` command line is not seen by the file comparison; the installed JDK and Tomcat are checked against the configuration and reported, not changed.
- Refusals, reported and not changed: a retained `.payload.*` folder of a failed install; a JDK or Tomcat that differs from the configuration.
- The reinstall section of `docs/README.install.md` and the book page describe the inspection and the plan.

Out of scope: a migration of a changed column; the host prerequisites (OS packages, JDK, Tomcat); the VM test (M16); Python.

##### Completion Criteria

- On an installed host with nothing changed, the installer reports the installation as up to date, builds nothing and does not stop the appliance.
- With only `../CONFIG_SITE.local` changed and the four WARs of the target commit in `target`, it installs without a build, and without them it builds first; with a changed source commit, it builds and installs; each run ends with the verification passing and the installed `.versions` naming the installed commit.
- A source SQL file that differs between the installed and the target commit is detected by the diff: a new table is loaded, any other difference stops with the diff, and `--accept-schema` continues after it.
- `--inspect` on a host with nothing changed reports every layer unchanged and changes nothing on the system, and `--plan` still executes nothing.
- The helper reports a first installation when there is no installed `version.txt` and treats every layer as changed, and it reports that a build is needed when the program changed or when the four WARs named for the target commit are not in the folder it is given.
- A second installer, or a second `--inspect`, that starts while another holds the installer lock stops with `Another appliance installer is running in this checkout` before it changes the checkout.
- The tests that call the installer scripts still pass: `tests/local-install-epics.pl`, `tests/database-config.pl`, `tests/local-install-output.bash`, `tests/local-install-config.bash` and `tests/local-install-readiness.bash`.
- The generated book pages are current: `bash book/scripts/check-generated.bash` reports every page as current, which is the check of the workflow `Appliance book`.
- A scratch mutation of the comparison of each layer, which makes a changed layer look unchanged, fails the test of the inspection.
- An unreadable installed version or comparison input causes refusal before build, installation, or service stop; it is not a changed configuration or a first installation.

##### Dependencies And Decisions

- D33 creates this item on 2026-11-03 and settles the design: the inspection lives in the installer scripts, `.versions` is installed, the schema layer compares the source SQL files of the installed and the target commit, the tool is Bash.
- D34 assigns it on 2026-11-03 after the owner accepted the plan and authorized the implementation; its order against M16 is not set.
- D36 keeps the optional soft IOC question first and narrows the quiet run to "no confirmation question" (2026-11-03); the existing test of the EPICS preflight stays unchanged.
- D35 revises the plan on 2026-11-03 before step 3, after the reading of `scripts/install-local-common.bash` showed that `--plan` executes nothing and that `tests/phase1-logic.bash`, `tests/database-config.pl`, `tests/local-install-config.bash` and the install pages of the book treat it as free of side effects: the option `--inspect` carries the checkout update and the comparison, `--plan` stays unchanged, the inspection is a helper script, and the confirmation moves after the inspection.
- Finding of 2026-11-03 from the source at commit e0a8e66e: the services read `appliances.xml` (`AppliancesList.determineApplianceXMLFileAndReturnStream`), `archappl.properties` (`DefaultConfigService`, `ARCHAPPL_PROPERTIES_FILENAME`) and `policies.py` (`DefaultConfigService.getPolicyText`) from the path that `ARCHAPPL_APPLIANCES`, `ARCHAPPL_PROPERTIES_FILENAME` and `ARCHAPPL_POLICIES` name, and use the copy inside the WAR only when the variable is not set; a named file that does not exist stops the service. The installed `archappl.conf` of the development host sets all three to the installed copies. Rule of the layer: a change of one of the three files alone is installed and takes effect at the next start, with no rebuild, when the installed `archappl.conf` sets the variable; when it does not set it, the WAR copy is the one in use and the program layer is rebuilt. The rebuild that `docs/README.install.md` asks for in that case is the conservative form of this rule and is corrected by M17.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-11-03; the owner accepted this plan text, and accepted its revision by D35 on 2026-11-03 (steps 3 to 6 and T1).
Implementation Authorization: 2026-11-03; explicit owner authorization to implement this plan; it covered steps 1 and 2 and was renewed for steps 3 to 6 by the owner on 2026-11-03, after the review of the revised text ended. It does not authorize commit, push, issue creation or provisioning of guests; the runs of T1 and T2 need the owner at the terminal for the `sudo` password.
Plan Extension Acceptance And Authorization: 2026-11-04; the owner separately approved one isolated Debian 13 VM for the remaining live upgrade checks, followed by shutdown and retention. The owner also approved stopping installation on a read failure, covering step 7 and T9. Production deployment remains outside this authorization.
Superseded Plan Artifacts: the text of steps 3 to 6 and T1 that the plan had on 2026-11-03 before D35: the inspection as functions inside `scripts/install-local-common.bash` and `--plan` running the checkout update.

1. The rule for the three classpath files is settled and recorded under Dependencies And Decisions; the inspection checks that the installed `archappl.conf` sets the three variables, and the correction of `docs/README.install.md` is part of step 6.
2. Add the `.versions` install to `configure/RULES_INSTALL`.
3. Write `scripts/inspect-local-install.bash` with the six layers and its per-layer output (layer, state `changed`, `unchanged` or `refuse`, and the reason) and with one more line that says whether a build is needed (the program changed, or the four WARs of the target commit are not in the folder it is given), report a first installation when there is no installed `version.txt`, and add the option `--inspect` to the installer scripts: it runs the checkout update, calls the helper and prints the result.
4. In `scripts/install-local-common.bash`, move the installer lock before the checkout update, move the rendering before the build, call the helper in every normal run, move the confirmation after it, run the build, stop, database, storage and install stages only for the layers that changed, add `--accept-schema`, and add the read-only verification for a run that changed nothing.
5. Write a Perl test under `tests/` that runs the helper `scripts/inspect-local-install.bash` against an installed tree that the real file-writing install rules produced (`make conf.install` runs first, because the install rules stop with status 2 when a rendered file is older than `configure/CONFIG_SITE`; then `services.install`, `serveroption.install` (which installs the `<service>.conf` files that `services.install` does not) and `install.systemd` run with `AA_INSTALL_PATH` and `SYSTEMD_PATH` on the command line pointing to a temporary folder that exists and is writable, and with `AA_USERID` and `AA_GROUPID` set to the account of the test, because the default `tomcat` makes `chown` fail for an ordinary user and a folder that is not writable makes `make` use `sudo`; `systemctl daemon-reload` and `sd_enable` of `install.files` are not run), and checks the verdict of each layer, with a scratch mutation per layer; run the installer on the installed appliance of the development host for the unchanged and the configuration-only cases, with the owner at the terminal for the `sudo` password that the installer asks for.
6. Update the documents: in `docs/README.install.md` the reinstall section (the inspection, `--inspect`, `--accept-schema`, the rebuild rule for the three classpath files and the table of the ordered sequence); in the book the install pages `book/src/install/sqlite.md`, `mariadb-uds.md`, `mariadb-tcp.md` and `reinstall.md`, whose sentences on the two questions and on the checks that fail "before the installer has locked the checkout" change because the lock moves before the checkout update and the confirmation moves after the inspection, and whose stage list gains the stage `inspection`; and the generated pages `book/src/appendix/make-targets.md` and `book/src/appendix/script-options.md`, which are regenerated with `bash book/scripts/generate-all.bash` and not edited by hand, so that `bash book/scripts/check-generated.bash`, which the workflow `Appliance book` runs on every push, passes; a rule or an option that is added without regenerating them turns that workflow red, as the commits that added `versions.install` and `--inspect` did. The generated `book/site/` is not edited.

7. Refuse unreadable inspection inputs in `scripts/inspect-local-install.bash`, retaining the distinction between missing files, readable differences, and read errors. Cover all four port files, both comparison operands, systemd units, and the installed version with real filesystem permission failures in `tests/local-install-inspect.pl`. Verify the original defect, the corrected CLI, and both real installer modes; update the installation documents.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Run the installer `--inspect`, then the installer, on the development host with its running appliance and nothing changed | The development host with the installed appliance | `--inspect` reports every layer unchanged (the `health` observation shows "not observed: needs sudo" when no password-free `sudo` exists) and changes nothing on the system; `--plan` before and after leaves every file time of the checkout unchanged; the run builds nothing and does not stop the appliance |
| T2 | Local | Change one value of `../CONFIG_SITE.local`, run the installer, then restore the value and run it again; the running appliance of the host is stopped and started by each run | The same host | Each run names the configuration layer and the changed file, installs without a build, and ends with the verification passing |
| T3 | Local | Run the Perl test of the inspection against the prepared installed tree, with the cases of an unchanged tree, a tree without `version.txt` (first installation) and a target folder without the four WARs of the target commit, then against a scratch mutation of the comparison of each layer | A host with the build tools | The test passes on the shipped code, reports the first installation and the needed build in their cases, and fails on each mutation |
| T4 | Local | In a scratch clone of the source, change the SQL file between two commits once by adding a table and once by changing a column, and run the inspection for the installed commit against each | A host with the build tools | The added table runs `make sql.fill`; the changed column stops with the diff, and `--accept-schema` continues |
| T5 | Local | Run the tests that call the installer scripts, listed in the completion criteria, and `bash book/scripts/check-generated.bash` | A host with a real EPICS Base | Every run passes as before the change and every generated page is current |
| T6 | Local | Hold the installer lock from another process (`flock` on `work/.local-install.lock`), then run the installer `--inspect` | The checkout of the development host | The run stops with `Another appliance installer is running in this checkout` and the checkout is unchanged |
| T7 | Integration | Install source `9bbd4579`, archive a changing PV, then select `e0a8e66e` and run the shipped SQLite installer | Isolated Debian 13 VM, real systemd, JDK 21, Tomcat 9, EPICS Base 7.0.10 | Build before stop; installation exit 0; four startup APIs complete; installed versions match; historical CSV unchanged; a new PV stores real CA values |
| T8 | Integration | Retain all four target WARs outside the build folder, change the buffer from 10 to 11, install, then restore 10 and install again | The T7 appliance | Missing WARs cause a build before stop; restoration reuses WARs; both runs pass readiness and preserve historical samples |
| T9 | Local and integration | Apply real file-permission faults to Make-produced inputs; run original and corrected helpers, then the real installer with unreadable installed port files | Debian 13 / Perl 5.40.1, Rocky 8.10 / Perl 5.26.3, and the T7 VM | Original code fails the refusal assertions; corrected full suites pass; normal and inspect modes exit 1 before build/install/stop, preserving service start, four PIDs and history |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-11-04; plan comparison finished 21:58:48 UTC | Debian 13, running SQLite appliance at source `e0a8e66e` | Pass | `work/unchanged-pv-20261104/` records real unchanged runs, inspection, and identical service PID/start-time observations. The owner ran `work/check-plan-mtimes.bash`; `/tmp/archiver-plan.4zy4X93W/result.txt` records installer exit 0 and full-checkout path/type/mtime comparison exit 0, including privileged test directories. |
| T2 | 2026-11-04 22:08:07 UTC | The same installed appliance, environment commit `d1ca12a` | Pass | `work/config-upgrade.LF3TT6ai/`: `ARCHAPPL_HEALTH_STARTING_SECONDS` changed from 10 to 11 and back through the real installer. Both runs selected only `configuration`, reused WARs, and passed startup in 37 seconds. Three distinct service start timestamps establish both restarts. The installed configuration equals its baseline byte for byte; the temporary site override is absent and the source remains `e0a8e66e`. |
| T3 | 2026-11-04 17:12:44 and 17:14:02 UTC | Debian 13 / Perl 5.40.1 and Rocky 8.10 container / Perl 5.26.3, real installation outputs and WARs | Pass | `work/m17-inspection/fix-results.md`, `inspect-EBwxLXpk/result.json`, and `inspect-zNEuvOCS/result.json`: 649/649 assertions in each environment. Seven scratch mutations failed their designated assertions in `mutations-20261104T171300Z/results.json`. Runtime mutation coverage is the explicit skipped-observation contract, not live HTTP. |
| T4 | 2026-11-04 | Debian 13, MariaDB 11.8.6, JDK 21, real Maven builds and the complete MariaDB UDS installer | Pass for schema application | `work/m17-schema-20261104/results.md`: added table loaded, changed column refused, and explicit acceptance continued through real build, schema load, and four-WAR installation. Native installer exit 2 at the declared external startup fault is not installation success. `work/m17-t4-checker-20261104/results.md` records the corrected checker and 12 matching native outcomes. Acceptance does not migrate an existing column. |
| T5 | 2026-11-04 | Debian 13, real EPICS Base 7.0.10, real WARs and Tomcat 9.0.121 where required | Pass within each test's declared boundary | `work/m17-inspection/fix-results.md` records all five required regressions. The schema correction repeated configuration/output/generated checks; `work/unchanged-pv-20261104/` records EPICS/output checks, actual selected/declined/noninteractive/inspect runs, and the final book build/generated-page checks for the PV correction. All five generated pages were current. These results do not add a live changed-source upgrade. |
| T6 | 2026-11-04 17:48:24 UTC | Development checkout with an independently held installer lock | Pass | `work/m17-lock-20261104T174524Z/results.md` and `repeat.*`: actual `--inspect` exited 1 with the lock refusal; 11,219 content records and 12,584 metadata records matched. The capture includes the lock separately and excludes other `work/` artifacts. The holder remained locked during capture and released normally. |
| T7 | 2026-11-05 01:29:35 to 01:40:47 UTC | Debian 13 VM, environment `54ee5ab`, SQLite, JDK 21.0.13, Tomcat 9.0.121 | Pass within the selected source transition | `work/m17-live-upgrade-20261105T011641Z/results.md` and `guest-evidence/evidence/{baseline,upgrade}`: native installer exits 0, build before stop, all four APIs complete, installed versions match, and all nine baseline CSV rows remain byte-identical. Baseline and new-PV tests matched four and three stored CA samples. The source transition changes release metadata and documentation, not Java code or schema. |
| T8 | 2026-11-05 01:41:58 to 01:46:36 UTC | The T7 appliance at source `e0a8e66e` | Pass | The same evidence root, `guest-evidence/evidence/{missing-wars,restore}`: missing-WAR build and installation exited 0, four startup APIs completed, a new PV matched four stored CA samples, and restoration installed without a build. Both historical CSVs equal the nine-row baseline. Original WARs remain retained. |
| T9 | 2026-11-05; live refusal check 01:52:39 to 01:52:42 UTC | Debian 13 and Rocky 8.10, plus the real T7 appliance | Pass after correction | The same evidence root and `work/m17-inspection/{inspect-E0u9HM76,inspect-eC8jfLiU}`: 813/813 assertions in each corrected full run. `inspect-8xvTH_6e` exposes the original refusal defects with real permission failures. Both real installer modes exited 1; service start `1243488220`, all four verified PIDs and the historical CSV remained identical. The first Rocky launcher inherited root's Git configuration path; its two stderr assertion failures remain retained separately from the corrected-user run. |

The exact helper and test SHA-256 values were rechecked against the retained T3 inputs: `2370baac588b2e9ce255aa37aac55014c6f106909d4d547f25db8d12fcd5f9ea` for `scripts/inspect-local-install.bash` and `6e840118e607133fea692847ae3abdb2e72a28a4cd701cea45c5d9abf03d02f4` for `tests/local-install-inspect.pl`. Earlier failing runs remain diagnostic evidence and are superseded by the correction results named above.

T9 uses helper SHA-256 `076690bfe1f1e77e4724d6804e8141fb05a96dec05435d2a8b42da87b45bda42` and test SHA-256 `8feeea457207670d2a0052a1053e671aa966bc28578d6438a2930f267dafa6ac`. T7 and T8 used the original helper at `54ee5ab`; their inspection also falsely named missing ports because the installed `server.xml` files were unreadable to the checkout owner. T9 corrects that classification and verifies refusal on those same files. T7 and T8 do not establish successful upgrades with the corrected helper against unreadable inputs.

T9 directory-access follow-up, 2026-11-05: helper `68aaf72b163d51b8a966bb40146a7c303a6e612e8186b8396f3a0e5713b772cf` and test `a082f25b9638b89875674b99ddbccd1d98e814a18d9d824007c71782ee9b2aff` passed 991/991 assertions in 14 cases on Debian 13 and Rocky 8.10 (`work/m17-inspection/{inspect-3Zf422ia,inspect-RxiOw2og}`). Ten directory permission faults cover version ancestors, all four component configuration folders, rendered configuration, unit listing, installed units, and the override folder. The preceding helper fails 33 refusal assertions in `inspect-6IGNt0xW`; fault restoration, genuine absence and search-only access controls pass. `work/read-failure-review.UPUdEM5v/` retains native results and input hashes. The real SQLite installer in the Rocky container passed baseline/restored inspection and refused four file/directory faults in both normal and inspect modes (eight native exits 1), before build/install/stop. Relative paths and a symlink path containing a space also passed the real CLI checks. This final helper was not rerun on the stopped VM; the container checks establish installer refusal, not live readiness or PID preservation for these final bytes.

The current driver at `d1ca12a` has SHA-256 `58397fde0d925706f0770ca489b4d549eb0c56b4c98db2e54661da3edd4e49a4`. Its selected-PV run matched five persisted samples to real changing CA observations, retained CSV evidence, stopped the test IOC, and left the test PV paused. The unchanged run preserved the appliance start timestamp. These checks establish short-term acquisition and retrieval, not storage-tier migration.

Evidence under `work/` and `/tmp/` is retained locally and is not distributed with the repository. The observations above record the inputs, results, and limits; they do not assert that another host has been upgraded.

##### Closure Evidence

- Product code, inspection tests, and installation documentation are committed through `2baf6407250f093f8a3c821aa5c634ccc40122ab`. The selected-PV correction is `d1ca12a8bd422dcc1dbb7a8d09240895ad743809`; the final read-failure correction, its tests, documentation and verification record are `5da67a8af7e48dfc0413ba5344a680c238849463`.
- On 2026-11-05 at 18:16:58 UTC, after a successful `git fetch origin`, `git rev-parse HEAD origin/maven` returned `5da67a8af7e48dfc0413ba5344a680c238849463` for both refs. Comparing the five paths in that commit against the fetched upstream returned no differences (native exit 0); a subsequent whole-tree comparison also returned 0. Recheck from the checkout with `git fetch origin` and `git diff --exit-code origin/maven 5da67a8` before relying on this observation for a later deployment.
- Completion criteria map to the recorded results: T1 covers unchanged execution, inspection and `--plan`; T2, T7 and T8 cover configuration-only, changed-source and missing-WAR upgrades; T3 covers first installations, build selection and layer mutations; T4 covers schema application and refusal; T5 covers the dependent tests and generated pages; T6 covers locking; T9 covers read-error refusal. The version, environment and native-exit limits in Verification Results remain part of these conclusions.
- T7 and T8 establish live changed-source and missing-WAR upgrades ending in startup readiness for the recorded input versions, with historical samples preserved. T9 separately establishes refusal of unreadable inputs through the corrected helper and real installer. These checks do not verify a production upgrade, arbitrary Java/schema compatibility, or storage-tier migration.
- Complete on 2026-11-05: the accepted deliverable, all ten completion criteria and implementation landing are established by the evidence above. The correction and installation documentation completed review with no open findings before `5da67a8`. There is no linked issue or open external gate for M17. This closure does not assign Backlog work or authorize production deployment.

##### GitHub Projection

Title: Upgrade an installed appliance by comparing its state with the checkout
Labels: enhancement
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M10 - Close the gaps that the Python tests left in the Perl tests

Origin: 9576820 / M10
Identity History: created as M10 on 2026-11-02 by D24; assigned on 2026-11-05 by D37
GitHub Issue: none
Status: Complete

##### Summary

At the M3 conversion, the Perl and Python tests both left the same 48 scratch mutations alive (conversion record of M3). The corrected nine tests kill 43 of those mutations; five have matching native results and source-level equivalence reasons below. All 113 former kills remain killed. The complete set is 161 mutations: 156 killed and five equivalent for the recorded entry paths. The original survivors per file were: `tests/install-payload.pl` 4, `tests/health-local.pl` 5, `tests/database-config.pl` 11 (nine configuration cases and two integration cases), `tests/config-d.pl` 6, `tests/local-install-epics.pl` 5, `tests/local-install-pv-menu.pl` 6, `tests/local-install-pv-range.pl` 4, `tests/local-install-pv-signals.pl` 3 and `tests/config-d-runtime.pl` 4. The signal test also checks the unconfirmed-pause warning when the verifier's pause evidence is missing. Implementation, required verification and repository landing are complete.

##### Scope

- For each survivor, add an observation to the Perl test that fails on the mutation, or record with its reason that the line has no observable effect and keep the mutation as known to be equivalent.
- Run every mutation of the changed file again, with repeats for the timing-dependent ones of `tests/local-install-pv-menu.pl` and `tests/local-install-pv-range.pl`.

Out of scope: the conversion of the tests (M3); the last sample of the time-range test (M9); changes to the shipped code.

##### Completion Criteria

- Every survivor listed in the conversion record of M3 is killed by its Perl test or recorded as equivalent with the reason.
- The mutations that the tests kill after M3 stay killed.

##### Dependencies And Decisions

- D24 creates this item on 2026-11-02.
- M3 converts the tests first; M10 changes the converted files.
- D37 accepts and authorizes the installation-test batch on 2026-11-05.
- D38 extends acceptance and implementation authorization to all remaining M10 work on 2026-11-05.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-11-05, installation-test batch by D37 and remaining work by D38
Implementation Authorization: 2026-11-05, installation-test corrections by D37 and all remaining corrections and verification by D38
Superseded Plan Artifacts: none

The implementation covers all nine Perl tests named in Scope and their test documentation, without changing shipped product code. The tests retain Perl 5.10-compatible syntax; the oldest target interpreter is Perl 5.26.3 on Rocky Linux 8.10. Test prerequisites include a C compiler and libc headers for the menu filesystem boundary, Linux ptrace access and syscall.ph for the real IOC exit barrier, and the documented core Perl modules. These are test dependencies only. The `zip` command prepares a damaged copy of a real built WAR; no application payload is synthesized.

1. Require the specific missing-JAR diagnostic, so a later command failure cannot satisfy that case.
2. Remove `WEB-INF/web.xml` from a copy of a real WAR and verify rejection without changing the installed payload.
3. Prefix a real WAR with invalid bytes, first establish that real `unzip` reports a warning after extracting `web.xml`, then verify that the installer refuses that input without changing the installed payload.
4. Run the shipped Make target with its command prefix redirecting only the real payload installer's stdout to `/dev/full`. Require the final write error and exact restoration of the installed WAR and JAR contents after replacement.
5. Run the unchanged case and all fourteen recorded mutations on the corrected test, recording intended assertion failures rather than treating any nonzero status as a kill. Run the unmutated test on the local host and the oldest available Rocky Linux environment; keep any missing guest coverage explicit.

6. Address the configuration-loader and EPICS preflight gaps with actual filesystem inputs, inherited shell settings, exact diagnostics and an unattended installer stopped by its real checkout lock.
7. Address health and runtime gaps through the real launcher, process identities, storage observations and installed wrappers. Classify a redundant guard only after comparing the actual original and mutated paths.
8. Address database configuration and backup gaps using the shipped helpers and real disposable databases; retain native errors separately from assertion failures.
9. Address PV menu, range and signal gaps using real soft IOC processes, real CA observations and the existing HTTP boundary fixtures. Include missing verifier evidence, actual cleanup exposure and the preserved time bounds. Repeat unmutated and mutated menu/range cases at least three times.
10. Run all recorded mutations for every changed file; retain source hashes, exact commands, native output and the intended failing assertion. Run each changed test unmutated locally and in the Rocky guest; complete M10 only after all original survivors and required checks are accounted for.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Run the recorded mutations of each changed test and compare their verdicts with the recorded ones | A host with a real EPICS Base, Java and Tomcat | Each former survivor is killed or recorded as equivalent; the former kills stay |
| T2 | Local and guest | Run each changed test unmutated | The same host and the Rocky Linux guest | Every run passes, as before the change |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-11-05 UTC | Debian 13, Perl 5.40.1; real WARs, Tomcat and soft IOC; private databases in Rocky | Pass: 43 of 48 former survivors are killed and five are equivalent; all 113 former kills remain. All 24 menu/range mutations fail at the intended assertions in each of three runs, and their unmutated controls pass | `work/m10-remaining/mutation-verdicts.json`; `work/m10-remaining/evidence-audit.json`; `work/m10-remaining/fault-exposure.json`; `work/m10-remaining/equivalent-native-comparison.json`; `work/m10-remaining/backup-equivalent-native-comparison-final.json`; `work/m10-payload-fix-kq1vfi8u/mutations/results.json` |
| T2 | 2026-11-05 UTC | Debian 13 host and Rocky Linux 8.10 guest, Perl 5.26.3 | Pass: all nine changed tests pass unmutated on both targets. The Rocky guest also passes the real SQLite and private MariaDB socket/TCP integration paths. Syntax, POD, help and required modules pass on both interpreters | Guest controls: `work/m10-remaining/rocky-48vkqhgt`, `rocky-2ile111j`, `rocky-36660q7v` (runtime), and `rocky-im0636ee` (PV and database integration); exact successful cases are recorded in each `results.json`. Static results: `work/m10-remaining/static-final/`; guest input recheck and terminal facts: `work/m10-remaining/rocky-final/` |

The guest required the test-only packages `zip` and `perl-Pod-Checker`; their actual installation logs are retained. Its source remained at `e0a8e66ed09e840ab8ed67dae81b25474605db08`, all transferred input checksums remained valid, and no M10 JVM, IOC or database process remained before shutdown. Shutdown completed on 2026-11-05 UTC; `work/m10-remaining/rocky-lifecycle.jsonl` retains the native result and shut-off observation. Earlier missing prerequisites, shared-CA-port collisions, blocked runtime ports and superseded fixture failures are excluded from mutation kills.

The source audit covers 208 selected local runs, each with the complete 299-member Git inventory and a native post-run checksum check. The payload's fourteen mutation copies also pass native checksum checks; guest manifests agree with the transferred source and the exact single mutation. The executed test files equal the final executable code; any later difference is limited to POD or the initial comment and is listed with both hashes. Forty-two retained PV fault observations independently confirm the CA samples, query edges, process-file faults, native signals and kernel exit events used by the failing assertions. Static syntax, POD, help and module checks all pass on both interpreters against the final test hashes.

The deliberately broken `run-no-exec` and `ioc-start-record` copies can leave their real JVMs or IOCs running. Those processes were recorded before external cleanup; the cleanup is not credited to the tested launcher. `work/m10-remaining/runtime-mutation-leftovers.json` and `work/m10-remaining/final-process-cleanup.json` retain their exact command lines, PID/start-time identities and observed termination. The final scan found seven owned processes before cleanup and none afterward.

| Test | Original Survivors | Newly Killed | Equivalent | Total Killed |
| --- | --- | --- | --- | --- |
| `install-payload.pl` | 4 | 4 | 0 | 14 |
| `health-local.pl` | 5 | 5 | 0 | 27 |
| `database-config.pl`, including integration | 11 | 8 | 3 | 33 |
| `config-d.pl` | 6 | 4 | 2 | 19 |
| `local-install-epics.pl` | 5 | 5 | 0 | 12 |
| `local-install-pv-menu.pl` | 6 | 6 | 0 | 14 |
| `local-install-pv-range.pl` | 4 | 4 | 0 | 10 |
| `local-install-pv-signals.pl` | 3 | 3 | 0 | 11 |
| `config-d-runtime.pl` | 4 | 4 | 0 | 16 |
| Total | 48 | 43 | 5 | 156 |

##### Equivalent Mutations

Equivalence is limited to the recorded entry paths and stable input files. Each normal and mutated run exits 0 with identical assertions and diagnostics after normalizing only generated workspace paths, backup minutes and the private database's assigned TCP port.

| Test | Mutation | Reason And Actual Comparison |
| --- | --- | --- |
| Configuration | `nullglob` | The following regular-file check discards an unmatched literal glob, the enumeration returns 0, and the subshell confines shell options. Both real runs agree |
| Configuration | `file-readable-check` | The next real `bash -n` reads the same file and returns the same refusal for an unreadable stable file. Both real runs agree |
| Database configuration | `helper-sqlite-account-refusal` | `database_error` returns 2 under the helper's top-level `set -e`, before the mutated explicit exit is reached. Both real CLI runs agree |
| Database configuration | `helper-backend-guard` | The preceding `database_error` similarly ends the real CLI with 2 before the mutated exit. Both real runs agree |
| Database backup | `backup-pipefail` | The helper already enables `pipefail` at entry. Removing the redundant inner assignment preserves failure propagation; actual denied dumps still fail and leave no archive in both socket and TCP cases |

##### Installation-Test Batch Evidence

The test SHA-256 is `4dffc710a1039aa6065596de68ee4c9f5013fb37f7773cb8eead312bea0a5f06`. The corrected test passes syntax and POD checks on both measured interpreters. The Rocky container image is `sha256:507b995d50e4fee989c55b3fcbbfd7da3d9dc57a469ec771739cd6f399f967c9`; its recorded probe finds every existing Perl dependency and the newly required `zip` command. The real build artifacts match the hashes in `work/m10-payload-fix-kq1vfi8u/mutations/inputs.json`.

| Former Survivor | Observed Failure Of The Corrected Test |
| --- | --- |
| `jars-required` | The later `install` failure does not supply the required missing-JAR diagnostic |
| `webxml-check` | The Make target returns 0 for a real WAR with `WEB-INF/web.xml` removed, instead of the required 2 |
| `restore-webapp-on-failure` | The installed payload differs after the final write fails; the expected restore is missing |
| `unzip-failure-tolerated` | The Make target returns 0 after the real extraction warning, instead of the required 2 |

On both normal runs, the prefixed real WAR causes native `unzip` status 1 after extracting the original `web.xml`, and `/dev/full` causes the payload installer's final `printf` to fail. The full Make path restores the previous WAR and JAR contents and removes its staging directory. Per-run `run.log` files, retained workspaces and the mutation source manifests preserve those observations. No shipped installer code changed. The later payload installation guest check passed.

##### Closure Evidence

- Implementation and required verification: finished on 2026-11-05. T1 and T2 are Pass; all 48 original survivors are resolved, all former kills are retained, and shipped product code is unchanged.
- The Rocky guest is shut off; its disks and earlier/new evidence are preserved. Owned local mutation processes were observed and stopped, with the original outcomes retained.
- Repository landing: observed at 2026-11-05T23:59:03Z after fetching `origin`. Both `HEAD` and `origin/maven` resolved to `37ba14f713f758c0aebfe7ec26340a5a830d2e6b`; comparing all eleven paths changed by that commit against `origin/maven` exited 0 with no differences.

##### GitHub Projection

Title: Close the gaps that the Python tests left in the Perl tests
Labels: none
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M12 - Share the helper code of the Perl tests

Origin: 9576820 / M12
Identity History: created as M12 on 2026-11-02 by D24; assigned on 2026-11-05 by D39
GitHub Issue: none
Status: Complete

##### Summary

The nine Perl tests repeat eight helper families: `slurp`, `spew` and `usage_error` in all nine files, `which` in seven, `shell_quote` and the pair `fail` and `check` in six, and `pause_for` in three. M14 already supplied the scalar prototypes of `fail` and `check`; M10 established 156 killed mutations and five equivalent mutations. This work shares the helpers while preserving those results and each caller's existing output and error handling.

##### Scope

- Provide these eight helper families in one module below `tests/lib/`, loaded explicitly by each of the nine tests. Preserve the existing two-argument `spew` calls and the runtime test's append mode, both shell-quoting formats, and each script's usage diagnostic prefix and POD.
- Keep every test runnable from a copied checkout and from a working directory outside it, including the `curl` and `date` symlink entry points used by the real PV fixtures.
- Preserve the scalar prototypes `fail($)` and `check($$)` at import time. Import only the requested helpers; the three tests using `Test::More` retain its assertions.
- Add a direct test of the shared module to `tests/phase1-logic.bash`, which the existing local-suite entry point runs, and describe the module and its test in `tests/README.md`.

Out of scope: changing test assertions, fixtures, process supervision or cleanup; sharing other repeated helpers; changing shipped product code or the shell helpers in `tests/lib/`; VM provisioning.

##### Completion Criteria

- All nine tests load the shared module and no longer define their own copies of the eight named helper families.
- Each test's output and exit status match the pre-change implementation for the same inputs under the comparison rules below. Database integration is compared before and after the refactor on the authorized disposable guest. The 161 M10 mutation verdicts remain 156 killed and five equivalent, with the same intended failing checks and equivalence limits.
- The shared-module check runs through the local suite and demonstrates that an imported `check` rejects a failed pattern match. File operations, both shell-quoting formats, usage output and import behavior have direct checks.
- The changed tests and shared module pass syntax, POD, help and module-availability checks, and all nine tests pass on the local host and Rocky Linux 8.10 with Perl 5.26.3.

##### Dependencies And Decisions

- D24 creates this item on 2026-11-02; D27 moves the scalar-prototype correction to M14.
- M3 supplied the Perl tests, M14 completed their scalar prototypes, and M10 supplies the current mutation baseline. These completed changes are the inputs whose behavior this work preserves.
- D39 assigns M12 on 2026-11-05 for plan preparation.
- D40 accepts the reviewed plan and authorizes implementation and verification on 2026-11-05. Reuse of the retained Rocky test guest is separately authorized for this work, with earlier evidence preserved, a new working directory and shutdown afterward.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-11-05, reviewed plan at c30be1d1f042758e2d792f93b49ccdf259cc1a4c, by D40
Implementation Authorization: 2026-11-05, shared-helper extraction and verification, including retained Rocky guest reuse, by D40
Superseded Plan Artifacts: the earlier three-step draft in this detail, retained at commit 743be01c69351ac614c328aeeea5cae036fbfc36

The proposed module is `tests/lib/ArchiverTest.pm`, with explicit exports and no default imports or process exit. Preserve the current language level (`use 5.010`) and test on the oldest supported interpreter, Perl 5.26.3. Use only modules available after the targets' test-package preparation; measure availability before relying on a new import. The source comparison at commit `743be01` finds identical `slurp`, `which`, `fail`, `check` and `pause_for` bodies. `spew` has the runtime-only append argument, `shell_quote` has always-quoted and shlex-compatible forms, and `usage_error` differs by script name. These differences are preserved explicitly rather than silently selecting one caller's behavior for all callers.

Comparison rules: retain the raw stdout, stderr and exit status, together with each run's normalization map. Only generated workspace paths, generated run or backup timestamps, and the actual OS-assigned TCP port of the private test database may differ. Replace that port only in the corresponding database connection argument, using the value recorded for that run; never replace arbitrary numbers. Preserve all assertions, diagnostics, test data and exit statuses. A skip, missing prerequisite or exit 77 is incomplete verification, not a passing comparison.

1. Capture the pre-change results of the real nine test entry points from commit `743be01`, including help and invalid arguments, in the environments specified by T2 and T4. Keep exact commands, input hashes, exit status, stdout and stderr; use the same real EPICS, Tomcat and WAR inputs, and equivalent fresh private databases for comparisons. Capture the database integration baseline on the authorized guest before running the refactored version there. Reuse recorded M10 mutations as inputs, not as proof that the refactored tests pass.
2. Add the shared module. Preserve raw byte reads and writes, optional append mode, PATH search behavior, assertion diagnostics and prototypes, and pause behavior. Expose both existing quote formats explicitly. Pass the caller's script identity and POD path to shared usage handling so the module returns 2 without exiting or rendering its own documentation.
3. Replace the local helper definitions one test at a time. Resolve the library directory from the actual script location at compile time, so imports preserve prototypes and work through the PV fixtures' symlinks. Include the module in copied checkouts used for mutation and guest runs; never load it from the author's original checkout as a fallback.
4. Add `tests/perl-helpers.pl` and wire it into `tests/phase1-logic.bash`. Exercise the real exported functions with raw bytes, empty files, append writes, missing paths, executable and non-executable PATH entries, both quote formats through a real shell, and usage rendering for the real test scripts. Check the scalar prototypes and an actual failed regex at the imported call site. Use the existing local-suite entry point to verify the wiring; keep Test::More imports separate.
5. Run the real test entry points before and after the move, including the complete copied-checkout and symlink fixture paths. Repeat all 161 recorded mutations on the refactored tests, requiring the intended assertion for each killed mutation and retained native evidence for the five equivalents. Repeat menu/range controls and mutations at least three times. Missing inputs, import errors or unrelated command failures do not count as kills.
6. Run the shared-module check and all nine tests on the local host and the separately authorized Rocky guest. On the local host, run `database-config.pl` in its configuration mode. On the guest, run both the pre-change and refactored `database-config.pl --integration` as root with `AA_TEST_DISPOSABLE_HOST=YES`, covering real SQLite and private MariaDB socket/TCP paths, then compare their outputs and statuses under the comparison rules. Record interpreter/module versions, static checks, exact test and module hashes, outputs, mutation verdicts and cleanup outcomes. Update the test guide and record completion only after every required result is observed.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Module and CLI | Run syntax, POD, help and module checks; execute `tests/perl-helpers.pl` through the real local-suite entry point; check the actual imported regex call, quote modes, usage output and file operations | Local host and Rocky Linux 8.10, Perl 5.26.3 | The module's public behavior is preserved, a failed regex fails its assertion, help exits 0 and invalid usage exits 2; no module or prototype warning |
| T2 | Local integration | Run all nine pre-change and refactored test entry points with the same real inputs, using configuration mode for `database-config.pl`; compare exit status, stdout and stderr; run from outside a copied checkout and exercise the real PV symlink fixtures | Local host with real EPICS Base, Java, Tomcat and WARs; database integration comparison belongs to T4 | Outputs and statuses agree under the comparison rules; every test uses the module from its own checkout |
| T3 | Mutation | Run all 161 recorded M10 mutations through the refactored tests; repeat menu/range controls and mutations at least three times; retain the native failure and input hashes | Local host with the baseline's real fixtures; authorized Rocky guest for database integration mutations | All 156 mutations fail at the intended checks; the five equivalents retain their documented behavior; unmutated controls pass |
| T4 | Guest integration | Run the shared-module check and all nine refactored tests; compare pre-change and refactored `database-config.pl --integration` for SQLite and private MariaDB socket/TCP, as root with `AA_TEST_DISPOSABLE_HOST=YES` | Separately authorized Rocky Linux 8.10 guest, Perl 5.26.3, real EPICS, Java, Tomcat and WARs; equivalent fresh databases for each version | Every test passes using its transferred module; database outputs and statuses agree under the comparison rules; raw evidence and cleanup outcomes are retained; exit 77 is not a pass |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-11-06 UTC | Debian 13, Perl 5.40.1; Rocky Linux 8.10, Perl 5.26.3 | Pass: syntax and POD checks for all eleven files; help and invalid usage; all 22 imported modules available. The 78 helper assertions pass on both systems and through the actual local Phase 1 entry point; Phase 1 exits 0 without skips. The Perl skill's 47 system-pattern checks pass on both interpreters | `work/m12-helpers/static-local/`, `final-runtime-static/`, `static-guest-final/`, `usage-and-modules/`, `phase1-local/`, `perl-patterns/`; exact commands, statuses, file hashes and raw output retained |
| T2 | 2026-11-06 UTC | Debian 13; real EPICS Base, Tomcat, WARs and database configuration mode | Pass: all nine baseline and final refactored entry points pass from outside copied checkouts. Control stdout, stderr and statuses match after mapping only generated workspace paths. Help, invalid options and invalid arguments match byte for byte. Source and input hashes remain unchanged | `work/m12-helpers/baseline-local/`, `final-runtime-local/`, `comparisons/`, `usage-and-modules/`; raw captures and each normalization map retained |
| T3 | 2026-11-06 UTC | Debian host; Rocky guest for root database integration | Pass: all 161 M10 verdicts remain, with 156 killed at the intended checks and five equivalent within the recorded input limits. Each menu/range control and mutation ran three times. All 15 selected controls pass; 42 retained PV fault observations verify the actual boundary inputs | `work/m12-helpers/verification-summary.json`, `mutation-audit.json`, `guest-mutation-audit.json`, `fault-exposure.json`, `equivalent-comparisons/`; actual commands, native failures, source hashes, comparisons and external cleanup records retained |
| T4 | 2026-11-06 UTC | Rocky Linux 8.10, Perl 5.26.3; real EPICS, Java, Tomcat, SQLite and private MariaDB | Pass: the helper, all nine refactored tests and root database integration pass. Baseline and refactored database outputs agree under the accepted workspace, backup-time and private-port rules. Input hashes remain unchanged; no test process remains; normal boot readiness and final shut-off state were observed | `work/m12-helpers/baseline-guest/`, `refactored-guest/`, `refactored-guest-retry/`, `comparisons/guest-database-integration/`, `rocky-final/`, `perl-patterns/`; the archived baseline verifies 17,076 file hashes and the volatile final DB workspace verifies 612 files on the host |

The mutation evidence selects 215 local runs, eight guest runs and one additional runtime retry control. Incomplete setup, occupied-port prerequisites and a capture without a saved exit status are excluded. The local recording label error is resolved by each actual command, case path and complete source hash inventory; raw records remain unchanged. `verification-summary.json` identifies every selected run and exclusion. Source comparison in `extraction-scope.json` confirms that all nine callers preserve their assertions, fixtures and cleanup bodies; the only runtime difference after the initial captures is removal of an orphan comment, checked through native Perl compiler output and final-file controls.

The three `menu-prompt` repeats reached the actual changed `Choose` prompt and failed the unchanged prompt check on its deadline; the M10 captures failed its output-ended branch. One `owner-zombie-check` repeat failed earlier at the same owned-IOC liveness check during `resume-exit`, with the actual SIGTERM and matching PID recorded. These branch differences are retained explicitly. The five equivalent mutations have matching native statuses, assertions and diagnostics under the accepted normalization rules; their limits remain those recorded under M10.

The R1 correction on 2026-11-06 UTC binds each import to the absolute module path beside the real script. The nine existing tests change only their import blocks; their assertions, fixtures and cleanup bodies are unchanged. The helper check includes all ten real entry points with a missing local module and a foreign `PERL5LIB`, plus complete copies reached through symlinks. The missing-module checks fail before the correction and all 128 assertions pass afterward on Debian 13 and Rocky Linux 8.10. Helper help renders without an external `perldoc`.

R1 verification: all nine local entry points pass, with stdout, stderr and status equal to the pre-extraction baseline after the accepted workspace-path normalization. The real local Phase 1 suite passes without skips. On Rocky, the helper, all nine entry points, root database integration and 65 syntax, POD, CLI and module checks pass. Source and input hashes remain unchanged during the runs. Commands, statuses, hashes, raw output and comparison maps are under `work/m12-r1-gda201qr/`. The 161 mutation outcomes above belong to the pre-R1 extraction snapshots; the import-only correction did not repeat the full mutation set.

##### Closure Evidence

- Implementation and verification: complete on 2026-11-06 within the source and environment limits of the extraction results and R1 follow-up recorded above; no shipped product code changed. The shared-module SHA-256 is `0f6565d9b120bb1cdaa1bab4fc95022555d68aeecdcf42fe70d6c157ae1c9e95`.
- The retained Rocky guest is shut off, with its disks and earlier evidence preserved. The authorized baseline deletion followed a complete host archive and hash check. Raw captures, final process observations, input hashes and VM lifecycle records remain under `work/m12-helpers/`.
- After the R1 checks, no owned test process remains and the same Rocky guest is shut off. Its volatile R1 workspace was archived on the host with all 3,891 regular-file hashes verified; `work/m12-r1-gda201qr/guest-archive/verified.json` and `vm-final.json` retain the archive and lifecycle observations.
- Repository landing: observed at 2026-11-06T08:40:53Z after fetching `origin`. Both `HEAD` and `origin/maven` resolved to `cb7a0413559e26daad1a1d2eb74213bc5baf2b89`; comparing all fourteen paths changed by that commit against `origin/maven` exited 0 with no differences. All eleven Perl source hashes match the R1 verification record.

##### GitHub Projection

Title: Share the helper code of the Perl tests
Labels: none
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M16 - Build the VM installation test on the local installer scripts

Origin: 9576820 / M16
Identity History: created as M16 on 2026-11-03 by D32
GitHub Issue: none
Status: In progress

##### Summary

The test establishes that an operator can install a usable Archiver Appliance through the existing local installer: the intended program and database configuration are active, changing CA observations are stored and retrieved, and the same PV registration and historical samples remain usable after a service restart and an unchanged installation request. Installer exit status and HTTP readiness alone do not establish this result.

The installation entry points are `scripts/install-local-sqlite.bash`, `scripts/install-local-mariadb-uds.bash` and `scripts/install-local-mariadb-tcp.bash`. `scripts/verify-local-pv.bash` already checks initial acquisition and retrieval against independently observed CA values and timestamps. The test invokes these shipped tools; it does not reproduce their installation, IOC creation or initial sample-matching logic. Automation follows a real execution of the acceptance sequence with these tools.

##### Scope

- Execute T1-T5 on fresh Debian 13 and Rocky Linux 8.10 guests, each with SQLite, MariaDB over a socket and MariaDB over TCP. These six cases are the selected coverage, not a claim about every OS supported by the installer.
- Use one Debian 13 MariaDB socket case and one Debian 13 SQLite case for the database and storage fault controls of T6, after their normal baselines pass. Fault controls are not multiplied across the whole OS/backend matrix.
- Add only the repeated command execution and missing result checks in Perl under `tests/vm/` (D16). Required inputs are the environment checkout and appliance source revisions, OS/backend selection, site settings, service account, endpoints and a real EPICS Base. Keep command output, native status and the observations required by T1-T6.
- cloud-provision supplies the guest and owns its lifecycle. After evidence is retained and the test IOC is stopped, send the completion notice through its request procedure. The test reports Passed, Failed or Incomplete per required outcome.
- Remove `tests/vm/driver.py`, `tests/vm/guest.py` and `tests/vm/local.py`, and update `docs/README.vmtests.md` and `tests/README.md`, only after the replacement establishes the declared results. File removal is delivery cleanup, not proof that installation works.

Out of scope: verifying guest creation, freshness, ownership or removal (D32); running Ansible; reimplementing Make sequencing; a general run-record framework with locks and digest proofs; Python implementation; changed-source or schema upgrades owned by M17; production deployment; host reboot, long-duration reliability and storage-tier migration. Service restart does not establish reboot recovery, and short-term stored samples do not establish STS-to-MTS-to-LTS transfer.

##### Completion Criteria

- T1-T5 pass through the shipped entry points for all six selected cases, with the exact commands, inputs and required observations retained. No required outcome is inferred from another outcome's PASS message.
- Initial PV verification succeeds independently of installer status. Restart and unchanged re-application preserve the same registered PV and a fixed historical query; new samples from that PV also match new CA observations.
- Both T6 controls fail their designated database or stored-sample check on the real installed path. An unrelated prerequisite failure does not count as detection. Restoration returns the relevant checks to their normal passing result.
- The replacement automation runs the same acceptance sequence. The three Python files are then removed and the two documents describe its actual inputs, assertions, evidence and limits.

##### Dependencies And Decisions

- D32 creates this item on 2026-11-03 and leaves it Open until the owner assigns it.
- D16 names Perl for replacement tests.
- D41 revises the draft around installation outcomes on 2026-11-06. This plan revision does not assign the item or authorize implementation.
- D42 accepts the reviewed plan and authorizes only the first direct Debian 13 SQLite T1-T5 case, including its guest request and retained shutdown.
- D43 authorizes the installed server.xml permission correction and its regression verification. The Perl test keeps its existing 5.26.3 baseline and adds no module dependencies.
- cloud-provision supplies the guests; each case needs a guest request under the procedure of that session, which this register does not authorize.
- M17 results are separate evidence for their recorded source transitions and environments. They neither replace a fresh-installation case nor require repeating the entire upgrade suite in M16.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-11-06, reviewed plan at 02a79f5, D42
Implementation Authorization: D42, first direct Debian 13 SQLite T1-T5 execution and its fresh VM request; D43, installed server.xml permission correction and verification; automation, remaining cases and T6 require separate authorization
Superseded Plan Artifacts: the M16 draft at 905b8cd, replaced under D41

1. Before implementation, complete review and acceptance of this contract. Before execution, obtain assignment, implementation authorization and the required guest approval. Record the exact inputs and finite installation/build deadline for each case; startup and each data observation use a 180-second limit. Missing test prerequisites stop the case as Incomplete.
2. On the first authorized Debian 13 SQLite guest, execute T1-T5 directly with the existing installer, verifier, service controls and pinned CSV client. Establish the actual commands and results before writing automation. Do not work around an installer defect with manual installation commands; retain the failure and resolve it through a separately authorized correction.
3. Add minimal Perl orchestration under `tests/vm/` for that same sequence, including same-PV history and continuing-acquisition checks absent from `verify-local-pv.bash`. Run the real automated sequence from a fresh starting state, then extend it to the remaining five selected cases. A direct run is baseline evidence, not proof that the later automation ran.
4. Run the two T6 controls against the actual checks, with the fault, expected failing assertion and restoration recorded before injection. Keep failure evidence and restore the isolated guest before evaluating recovery.
5. After the required results pass, remove the three obsolete Python files and update the two test documents. Preserve useful claims from `tests/vm/guest.py` through T1-T6, not a line-for-line port of its checks or another test of the retired VM driver.

##### Test Inputs And Evidence

- Start from the documented host prerequisites with no appliance installation or copied WAR/build outputs. Use the checkout owner with sudo, a pinned environment checkout and pinned appliance source, and the intended site settings. Run the matching installer with `--yes`, without `--skip-packages` or `--existing-db`, so package installation and database preparation remain inside the tested path. Record any prerequisites already supplied by the guest image; do not claim their installation was exercised. EPICS Base is a separately supplied test prerequisite, checked with the verifier's `--check-epics --epics-bin` entry point.
- Use the supplied configuration as the expected value and compare it with the installed configuration and runtime. Check SQLite's actual file or MariaDB's actual socket/TCP endpoint with the application credentials, including the required schema and the test PV registration. Database metadata and archive sample files are distinct; a table or registration row is not evidence of stored samples.
- Run `verify-local-pv.bash` separately with the installed local management/retrieval URLs, the selected source checkout, `--epics-bin`, `--cleanup keep` and `--timeout 180`. Require native exit 0 and its successful CA-to-CSV comparison. The installer's optional PV branch is not the acceptance result: `--yes` skips it, and an optional PV failure does not become an installer failure.
- Retain the verifier's PV name, IOC identity, CA observations, retrieval response and CSV. Before restart, use the pinned `getDataToCsv.bash` to capture a fixed, already completed interval containing at least two of the matched changing samples. Save its exact FROM/TO arguments and returned rows as the historical baseline. Later comparisons use this same PV and interval, preserving sample timestamps, values, severity, status and occurrence counts. Do not replace it with a newly generated PV or a moving time window.
- Keep the same IOC and PV active across restart and re-application. For each new-data check, record CA observations and query a new interval after the action; require at least two distinct matching values, timestamp agreement within the existing verifier's one-second allowance, and successful sample status. A new registration request is forbidden for these continuation checks. Stop only the recorded test IOC after checking its process identity, pause its PV and retain the registration, samples and evidence on every outcome before guest handoff.
- Preserve installer and verification stdout/stderr, native statuses, effective settings without credentials, version/API observations, service/process identities, query arguments and CSV results under a case-specific `work/` directory. Copy required guest evidence before the completion notice. Evidence size is bounded by one PV and short observation windows; load, long-duration and evidence-replay frameworks are not part of this contract.
- Passed requires every applicable result and its evidence. Failed requires an observed violation; missing prerequisites, interrupted execution or unavailable evidence are Incomplete, never PASS. Preserve any confirmed failure even if later observations are incomplete. An expected fault makes the tested appliance check fail; T6 passes only when that specific failure and subsequent restoration are observed. Do not retry an uncertain installation until its actual process/service state is known.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Installation | Run the selected shipped installer from the declared prerequisites, with package/database preparation enabled and no prebuilt WARs; retain its native result | All six selected fresh guests | Installation completes within the declared deadline with exit 0; intended program and configuration are installed without manual repair |
| T2 | Installed state | Compare installed component versions and appliance identity with the pinned inputs; inspect effective units, four JVM identities/owners, storage paths, actual database transport/schema, four startup APIs and the shipped health command as the service account | Each T1 installation | The selected configuration is actually in use; all four APIs report STARTUP_COMPLETE within 180 seconds; service and health timer are enabled and active; health exits 0 |
| T3 | Data path | Execute the existing PV verifier independently; check the PV row through the actual configured database; capture the fixed historical query with the pinned CSV client | Each ready installation, real loopback soft IOC and CA | Verifier exits 0 with at least two distinct stored values matching independently observed CA values/times; registration persists in the selected database; the fixed query contains the matched samples |
| T4 | Restart persistence | Record process identities, restart through the shipped service control, repeat T2, re-query the saved interval and observe new samples from the same running IOC/PV | Each T3 installation | All four JVM lifetimes change and readiness returns within 180 seconds; the same registration and historical rows remain; new data match new CA observations within 180 seconds without re-registration |
| T5 | Unchanged re-application | Record healthy service/JVM lifetimes and configuration; repeat the identical installer command with unchanged source/site inputs; compare those identities, repeat T2 and the old/new data checks | Each T4 installation | Installer exits 0 without a build or service/JVM replacement; installed configuration, PV registration and historical samples remain; continuing acquisition still passes |
| T6 | Fault detection | On passing disposable baselines, apply separately a wrong installed MariaDB socket endpoint and service-account write denial on the actual short-term store; run the real acceptance checks, retain the intended failed assertion and restore each fault | Debian 13 MariaDB socket and Debian 13 SQLite cases respectively | The database control fails the actual connection/configuration check; the storage control reaches real changing CA input and the write/retrieval path but fails the stored-sample assertion; neither is reported as overall installation acceptance; restoration passes the affected checks |

For T6, capture the original configuration/permissions, apply each fault only to the isolated installation and prove it is effective for the actual service account. Close any pre-existing database connections or writable store handles before relying on the fault. The storage control must reach its declared data-path check with the IOC producing changing CA observations; an earlier startup refusal is not proof that the stored-sample check detects lost data. If the intended exposure cannot be established, retain Incomplete for that control rather than counting an unrelated nonzero exit. Required new comparison assertions also need the smallest real-path fault that exposes their own mismatch; these checks remain limited to the declared installation outcomes.

D43 correction verification uses the real installation targets with a mode-0600 server.xml template and requires all four installed files to be mode 0644. The uncorrected rules must fail this permission assertion; the corrected rules must pass the complete inspection suite on the development host and Perl 5.26.3. On the retained affected guest, reproduce the original refusal, apply the corrected serverxml.install target and repeat the original installer command. Require successful re-application, unchanged service/JVM lifetimes and configuration contents, preserved PV registration and fixed historical samples, and a successful independent PV verifier run. This bounded correction check does not repeat the complete fresh-installation or same-PV continuation sequence.

##### Verification Results

The first direct case used environment commit `02a79f559a3213f6eaa0cae1170bfeceed8a9d87` and appliance commit `e0a8e66ed09e840ab8ed67dae81b25474605db08`, on Debian 13 with SQLite, 2 vCPU, 4 GiB RAM and a 30 GiB disk. The installation deadline was 3600 seconds; startup and each data window were limited to 180 seconds. Packages were enabled, no WAR or build output was supplied, and no manual product repair was applied. The five other cases, fault controls and replacement automation remain Pending.

Input qualification: the first retained setup command used `umask 077` for the clone as well as evidence. Its `site-template/skel/conf/server.xml` was mode 600. At `02a79f5`, the installation copied the template and changed its owner to the service account without establishing read permission for the checkout owner; all four installed `server.xml` files remained mode 600. T5 establishes failure under this restrictive checkout condition, not under the guest login's default umask. The separate fresh baseline below preserves the login's umask 0002 during checkout creation. No permission workaround or corrected-product run replaces the restrictive-case failure.

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-11-06T09:56:13Z | First direct Debian 13 SQLite case, restricted checkout permissions | Passed for this case | Installer exit 0 in 427.49 seconds, including package installation, source build and installation; startup passed in 43 seconds. `work/m16-first-install-20261106T094315Z/guest-final/t1/`; image packages and setup commands retained |
| T2 | 2026-11-06 UTC, after installation and after each action | Same case | Passed for this case | Intended source/component versions, identity, four service-account JVMs, effective units, storage, actual SQLite file/schema, all four STARTUP_COMPLETE APIs, enabled/active service and timer, and health exit 0. `guest-final/t2/`, `t4-after/`, `t5-after/` under the same evidence root; the database file stat was repeated as the service account after an ordinary-user permission error |
| T3 | 2026-11-06T09:58:48Z | Same case, real loopback IOC | Passed for this case | Independent shipped verifier exit 0 with three distinct stored values matching CA observations. The same PV row exists in SQLite. The fixed historical query retained six rows with values 100-105. `guest-final/t3/`, `history-baseline/`, and saved query arguments |
| T4 | 2026-11-06T10:01:53Z | Same case and same IOC/PV | Passed for this case | Shipped service restart returned 0; all four JVM lifetimes changed; readiness returned in 43.10 seconds. The six historical rows and registration persisted. New CA values 277-279 matched stored sample times within one microsecond, with severity/status zero; the new-data collection completed in 12.75 seconds. `guest-final/t4-*` and `evidence/t4-history-comparison.json` |
| T5 | 2026-11-06T10:05:25Z | Same case; unchanged source, site inputs and installer command | Failed | Installer exit 1 in 1.26 seconds: inspection refused unreadable mode-600 `server.xml` files. No build or service/JVM replacement occurred; installed configuration, six historical rows, PV registration and continued acquisition remained intact. New values 489-491 matched CA within one microsecond. `guest-final/t5/`, `t5-*`, `final/`, and `evidence/t5-history-comparison.json` |
| T6 | Pending | Selected Debian 13 fault controls | Pending | Not authorized or executed in the first direct case |

The normal baseline used the same source revisions, site inputs, resource sizes and deadlines on a separate fresh Debian 13 guest. The checkout template was mode 664 before installation, and all four installed `server.xml` files were mode 644. Both environment and appliance source trees remained clean. Commands, inputs and results are retained under `work/m16-baseline-20261106T101048Z/`; no product changes or manual installation repairs were applied.

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-11-06T10:25:28Z | Direct Debian 13 SQLite baseline, default checkout permissions | Passed | Identical shipped installer command with packages enabled; exit 0 in 425.37 seconds, including source build and installation. Startup passed in 45 seconds. `guest-final/t1/`, retained setup inputs and command hashes |
| T2 | 2026-11-06 UTC, after installation and after each action | Same baseline | Passed | Pinned versions and appliance identity, service-account ownership of four JVMs and storage, effective units, actual SQLite file/schema, all four STARTUP_COMPLETE APIs, enabled/active service and timer, and health exit 0. `guest-final/t2/`, `t4-after/`, `t5-after/` |
| T3 | 2026-11-06T10:27:43Z | Same baseline, real loopback IOC | Passed | Independent shipped verifier exit 0 with three distinct CA-to-CSV matches. SQLite retained the PV registration. The fixed query from 10:27:35Z to 10:27:43Z on this date contained seven rows, values 102-108, including the matched samples. `guest-final/t3/`, `history-baseline/` and saved FROM/TO arguments |
| T4 | 2026-11-06T10:29:24Z | Same baseline and same IOC/PV | Passed | Shipped restart exit 0; all four JVM lifetimes changed; readiness returned in 43.49 seconds. The seven historical rows matched in all fields and occurrence counts; PV identity, creation time and archiving settings persisted. Twelve new CA values matched stored samples within one microsecond, severity/status zero, in a 12.67-second observation. `guest-final/t4-*`, `evidence/t4-history-comparison.json` and `t4-new-data-measurements.json` |
| T5 | 2026-11-06T10:31:11Z | Same baseline; identical source, site inputs and installer command | Passed | Installer exit 0 in 1.55 seconds with no build. Service invocation, four JVM lifetimes, effective units and installed configuration remained unchanged. The seven historical rows and same PV registration persisted; twelve new CA values matched stored samples within one microsecond, severity/status zero, in 12.68 seconds. `guest-final/t5/`, `t5-*`, `evidence/t5-history-comparison.json` and `t5-new-data-measurements.json` |

Registration comparison retained the original PV identity and creation time. The pinned appliance's `DefaultConfigService.upgradeTypeInfo` initialized `chunkKey` during restart; raw metadata bytes were therefore not an invariant. The same IOC lifetime continued through both actions, and neither continuation check registered another PV. The optional `lsof` diagnostic found no open SQLite handle after T5; the required service-account database query, registration query and data-path observations succeeded.

D43 correction verification on 2026-11-06 used the same source revisions with only the server.xml installation rule changed. `serverxml.install` now establishes mode 0644 for the four port configuration files after rendering. Genuine read errors still cause inspection refusal. The tested RULES_INSTALL SHA-256 is `723bc5124d1bd43dbfb80e6cfdd5aa8d501acf77cd2b5ca2ae6f0bbefa47891a`; the inspection test SHA-256 is `42ee36df88a42451c894d143109cc07604fdd246d7003e145d93a695b520db30`. Evidence is retained under `work/m16-permissions-20261106/`.

- Regression: the real Make installation with the original rules failed all four expected permission assertions, native exit 1. The corrected rules passed all 15 inspection cases on the development host and Rocky Linux 8.10 with Perl 5.26.3, native exit 0, including real unreadable-file refusals. The Rocky test image explicitly includes Java 21 and diffutils; its package versions, image identity, source hashes and full output are retained. See `evidence/before-old.stdout`, `final-local.stdout`, `rocky-complete.stdout` and their native-status files.
- Affected guest: the original installer again refused the four mode-600 files at 18:00:02Z, native exit 1. The corrected shipped `serverxml.install` target returned 0 at 18:05:04Z and established mode 644 with service-account ownership. The original installer command then returned 0 at 18:05:16Z in 1.25 seconds, reporting every installed layer unchanged and no build needed. Service invocation, boot identity, all four JVM lifetimes, effective units and active configuration contents were unchanged. See `guest-final/before/`, `correction/`, `after/`, `healthy-before/`, `healthy-after/` and `evidence/state-comparison.json`.
- Data: the original Paused PV registration and all six fixed historical rows matched before and after correction, including full fields and occurrence counts. A separate real PV verifier returned 0 at 18:07:48Z in 105.48 seconds, with three changing stored samples matching CA observations. See `evidence/history-comparison.json` and `guest-final/pv/`. This new-PV result proves the corrected installation's data path; it does not replace T5's same-PV continuation requirement or the original failed result.
- Recovery boundary: an existing installation with unreadable server.xml files still requires the explicit corrected `serverxml.install` target before re-running the installer. The installer does not bypass a read refusal or silently repair permissions during inspection. A corrected fresh full T1-T5 VM sequence was not repeated; the permission regression executes real Make installation in a private prefix.

##### Closure Evidence

- The default-permission direct baseline passed T1-T5. The original restrictive-checkout case remains recorded as Failed; its permission defect is corrected and the separate D43 checks passed. The correction is not yet committed. These results do not complete the six-case matrix, T6 or replacement automation.
- D43 final observation at 2026-11-06T18:08:51Z confirmed health exit 0, the new test IOC absent and both retained PVs Paused. The original 1,942 evidence files remained hash-identical. All 675 regular correction-evidence files were copied to `work/m16-permissions-20261106/guest-final/` and verified against the independent guest hash list; the materialized curl-adapter symlink also matches its recorded shipped source hash. cloud-provision confirmed normal shutdown with disk, definition, reservation and evidence retained; an independent read-only hypervisor query confirmed shut off. The exact lifecycle response is in the private `provider-closure.txt` under the correction evidence root.
- The restrictive-case IOC was absent and its retained PV was Paused at 2026-11-06T10:06:32Z. Registration and samples remain. All 1,942 regular guest evidence files were copied to `work/m16-first-install-20261106T094315Z/guest-final/` and verified against the guest hash list. cloud-provision confirmed normal shutdown with disk, definition, reservation and evidence retained.
- The normal-baseline IOC identity was checked before stopping it; the IOC was absent and the retained PV was Paused at 2026-11-06T10:31:27Z. All 1,941 regular guest evidence files were copied to `work/m16-baseline-20261106T101048Z/guest-final/` and verified against the independent guest hash list. The copied curl-adapter symlink became one additional regular file, whose hash matches the recorded shipped source. cloud-provision confirmed normal shutdown, retained VM state and unchanged evidence; a read-only hypervisor query also confirmed the guest was shut off. The private provider record retains the exact identity and lifecycle response.

##### GitHub Projection

Title: Build the VM installation test on the local installer scripts
Labels: enhancement
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

## Backlog

M5, M6 and M7 remain unassigned and Deferred, with the reconsideration order M5, M6 and M7. All rows are excluded from the release tally.

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

Out of scope: removing a check that proves a different claim; changing what a test asserts; the VM driver (M4 and M8).

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
