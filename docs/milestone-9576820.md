# Work Register

Release line: master (unversioned development on the default branch maven)
Milestone index: 9576820
Canonical path: `docs/milestone-9576820.md`
Canonical branch or ref: maven
Git upstream: origin/maven
Remote tracker: jeonghanlee/epicsarchiverap-env; no open release milestone (observed 2026-10-29 via `gh api repos/jeonghanlee/epicsarchiverap-env/milestones`)

Next session entry point: Review the draft plan of M4 (Fix the findings of the review of the VM driver) in `docs/milestone-9576820.md` with the owner and record its acceptance before any implementation; M4 is Ready because M3 is Complete, but a Ready row does not accept a draft plan or authorize implementation. M1 landed at c4b27bcc65fa70ee7c80ccee7d40136bab64d995, M2 at de8301cb05d3d026708a0270878e110bee497ee7, M3 at 6efd7db7044b2a77f3a763eb04435aa606836e63, M11 at 134857b0a4f7e910b707b00993a2f9f027c75823, M14 at 23e98e8980a6a73742b99f8d4985fa1d646ecab8 and M15 at 79f21776b77d622702e7a45292ecf317586c8b69. The Backlog items M9, M10, M12 and M13 hold the remaining defects and improvements that the conversion showed (D24, D26, D27). Commit, push, issue creation and guest provisioning need their own authority. M5, M6 and M7 remain Deferred and M8, M9, M10, M12 and M13 Open; their later order is not authorization to resume.

## Scope

This generation owns fifteen work items on the default development branch. The assigned work is M1, M2, M3, M4, M11, M14 and M15; M11, M14 and M15 were assigned on 2026-11-02 by D26, D27 and D28, and their order against M4 is not set. Deferred work is ordered M5, M6 and M7 for later reconsideration; M8, M9, M10, M12 and M13 are unassigned and Open. Assignment authorizes preparation of the existing scope; implementation-plan acceptance and implementation authorization remain separate. Historical results remain evidence for their recorded inputs.

Out of scope for this assignment update: product implementation, VM provisioning, a new numbered release, and changes to GitHub issues or milestones.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DB | M1 | Apply backend selection to all database operations | Carry-forward | Complete | No | D4, D11, D13, D14 | T1-T5 and correction checks passed; landed at c4b27bc; [detail](#m1---apply-backend-selection-to-all-database-operations) |
| Install | M2 | The operating system target rewrites `configure/CONFIG_SITE.local` and the installers run it first | Milestone | Complete | No | M1, D7, D11, D15 | T1-T5 passed on Debian 13 and Rocky 8.10; landed at de8301c; [detail](#m2---the-operating-system-target-rewrites-configureconfig_sitelocal-and-the-installers-run-it-first) |
| Tests | M3 | Replace the Python tests with Perl tests | Carry-forward | Complete | No | M2, D6, D11, D16, D17, D18, D19, D20, D21, D22, D23, D24, D25 | T1-T4 passed, T2 and T4 with the waivers of D25; landed at 6efd7db; [detail](#m3---replace-the-python-tests-with-perl-tests) |
| Tests | M4 | Fix the findings of the review of the VM driver | Carry-forward | Not started | Yes | M3, D8, D11 | Driver findings are fixed or decided, with defect-sensitive tests and a real guest verdict; [detail](#m4---fix-the-findings-of-the-review-of-the-vm-driver) |
| Tests | M11 | Remove the false failures of the converted tests | Carry-forward | Complete | No | M3, D24, D26 | A run directly after another run passes the port probe of the runtime test, a pid file with text fails clearly, and the signal test passes from a background job; T1-T2 passed; landed at 134857b; [detail](#m11---remove-the-false-failures-of-the-converted-tests) |
| Tests | M14 | Declare scalar prototypes on the check helper of the Perl tests | Carry-forward | Complete | No | M3, D24, D27 | The six tests that define `check` declare scalar prototypes and pass unchanged, and a list-context match in a call of `check` fails the check; T1-T2 passed; landed at 23e98e8; [detail](#m14---declare-scalar-prototypes-on-the-check-helper-of-the-perl-tests) |
| Tests | M15 | Stop the instances that an aborted runtime test did not record | Carry-forward | Complete | No | M3, D24, D28 | A run of the runtime test that ends early, including the pid file mutation, leaves no JVM of its instances, and the recorded mutations keep their verdicts; T1-T2 passed; landed at 79f2177; [detail](#m15---stop-the-instances-that-an-aborted-runtime-test-did-not-record) |

Ready indicates work-order eligibility; it does not accept a draft plan or authorize implementation. Assigned work: 6 Complete and 1 Not started. M4 is Ready; its plan is a draft.

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
Status: Not started

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

Out of scope: the conversion of the tests (M3); the rule for the evidence of passing runs (M13); the exchange of the time-range test (M9); changes to the shipped code.

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

## Backlog

M5, M6 and M7 remain unassigned and Deferred, with the reconsideration order M5, M6 and M7. M8, M9, M10, M12 and M13 are unassigned and Open. All rows are excluded from the release tally.

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Storage | M5 | LTS retrieval pre-processing (`pp`) | Milestone | Deferred | No | D5, D12 | Measured retrieval benefit and disk cost support a dated decision on LTS pre-processing; [detail](#m5---lts-retrieval-pre-processing-pp) |
| Tests | M6 | Reduce the repeated checks of the release verification plan | Carry-forward | Deferred | No | D9, D12 | The next release plan maps each check to one claim, its inputs and a re-run trigger; [detail](#m6---reduce-the-repeated-checks-of-the-release-verification-plan) |
| Runtime | M7 | Measure per-component heap needs by archiving load | Carry-forward | Deferred | No | D2, D3, D12 | Measured GC events and validated candidate heaps support load-specific guidance; dedicated storage and a new resumption decision required; [detail](#m7---measure-per-component-heap-needs-by-archiving-load) |
| Tests | M8 | Decide the replacement of the VM driver and guest verifier | Carry-forward | Open | No | D6, D16, D17 | The owner decides whether and in which language the driver, verifier and driver test are replaced, and any chosen work passes defect-sensitive tests and a real guest verdict; [detail](#m8---decide-the-replacement-of-the-vm-driver-and-guest-verifier) |
| Tests | M9 | Keep one consistent exchange in the PV time-range test | Carry-forward | Open | No | M3, D23 | The unmutated time-range test passes in every run of a series whose length the plan fixes, and its mutation verdicts stay as sensitive as before; [detail](#m9---keep-one-consistent-exchange-in-the-pv-time-range-test) |
| Tests | M10 | Close the gaps that the Python tests left in the Perl tests | Carry-forward | Open | No | M3, D24 | Every one of the 48 mutations that the converted tests leave alive is killed by its test or recorded as equivalent with the reason, and the killed ones stay killed; [detail](#m10---close-the-gaps-that-the-python-tests-left-in-the-perl-tests) |
| Tests | M12 | Share the helper code of the Perl tests | Carry-forward | Open | No | M3, D24, D27 | The nine Perl tests load one shared module instead of their own copies, with unchanged output and mutation verdicts; [detail](#m12---share-the-helper-code-of-the-perl-tests) |
| Tests | M13 | Decide the evidence that passing runs of the converted tests keep | Carry-forward | Open | No | M3, D26 | The owner decides one rule for the evidence of a passing run of the three evidence-keeping tests, and the tests follow it; [detail](#m13---decide-the-evidence-that-passing-runs-of-the-converted-tests-keep) |

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

#### M8 - Decide the replacement of the VM driver and guest verifier

Origin: 9576820 / M8
Identity History: created as M8 on 2026-10-30 by D17
GitHub Issue: none
Status: Open

##### Summary

D17 leaves `tests/vm/driver.py` (1,247 lines), `tests/vm/guest.py` (894 lines) and `tests/vm/local.py` (918 lines) out of M3. The driver orchestrates fresh guests, the verifier checks the installed appliance on guests with different Python versions, and the driver test checks the driver and its documents. D6 keeps Python only where testing Python code requires it; D16 names Perl for the replacement tests. Whether and how this trio is replaced is not decided.

##### Scope

- Decide whether the driver, the guest verifier and the driver test are replaced, and in which language, with the consequence for each of them.
- Carry out the replacement the decision selects, keeping each assertion and its real-path method.

Out of scope: the tests that M3 converts; fixing the review findings of the current driver (M4); replacing Ansible, which the control host still needs.

##### Completion Criteria

- The decision and its date are recorded, naming which of the three files change language and which stay.
- If a file is replaced, its replacement fails on the defect each assertion covers, shown by a mutation of the shipped code, and a real guest verdict passes under the current conditions.

##### Dependencies And Decisions

- D17 creates this item on 2026-10-30 and leaves it Open until the owner decides priority and scope.
- D6 and D16 apply to any replacement.
- The order against M4 is not set. M4 fixes findings in the current Python driver; a replacement could make part of that work unnecessary, so the owner decides the order.

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
| T1 | Pending | The register | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Decide the replacement of the VM driver and guest verifier
Labels: enhancement
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M9 - Keep one consistent exchange in the PV time-range test

Origin: 9576820 / M9
Identity History: created as M9 on 2026-10-31 by D23
GitHub Issue: none
Status: Open

##### Summary

The time-range test (`tests/local-install-pv-range.pl`, converted from `tests/local-install-pv-range.py` by M3) replaces the HTTP transport of the shipped PV verifier with a fixture that answers from the real soft IOC. For every data request the fixture writes `query.json` and then `response.json` in the evidence folder, and the test reads both after the run. The verifier ends an attempt that passes its deadline, but the fixture process of that attempt can finish later and overwrite one of the files after the next attempt has written the other. The pair then does not come from one attempt and the count of valid samples differs. Six consecutive unmutated runs of each implementation failed 2 times each (33 percent); the failing case differed from run to run. The conversion keeps this behavior (D23).

##### Scope

- Make the test read one consistent query and response, for example by recording both in one file that is replaced as a whole, and bind a late fixture process to the attempt that started it.
- Measure the failure rate of the unmutated test before and after, in a series of the same length, and repeat the mutations whose verdicts depended on timing.

Out of scope: the conversion of the test (M3); changing the shipped verifier; the menu test, which does not read the two files.

##### Completion Criteria

- The unmutated test passes in every run of a series whose length is fixed in the accepted plan, with the series listed.
- The recorded mutations keep their stable verdicts, and the timing-dependent ones are repeated and recorded with their counts.

##### Dependencies And Decisions

- D23 creates this item on 2026-10-31.
- M3 converts the test first; M9 changes the converted file.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Reproduce the failure on the converted test with the unmutated series, and record the failing runs.
2. Change the exchange so that the pair comes from one attempt, then run the series again.
3. Repeat the recorded mutations, with repeats for the timing-dependent ones.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Run the unmutated test in a series and count the failures | A host with a real EPICS Base | No failure in the series |
| T2 | Local | Run the recorded mutations of the test and compare their verdicts with the recorded ones | The same host | The stable verdicts are unchanged |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Pending | A host with a real EPICS Base | Pending | none |
| T2 | Pending | The same host | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Keep one consistent exchange in the PV time-range test
Labels: bug
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M10 - Close the gaps that the Python tests left in the Perl tests

Origin: 9576820 / M10
Identity History: created as M10 on 2026-11-02 by D24
GitHub Issue: none
Status: Open

##### Summary

The Perl tests that M3 converted leave 48 of their scratch mutations alive, and the Python tests left the same ones alive (conversion record of M3). Each survivor is a line of the shipped code on which no check of the test depends: either a check is missing, or the line has no observable effect. The survivors per file are: `tests/install-payload.pl` 4, `tests/health-local.pl` 5, `tests/database-config.pl` 11 (nine configuration cases and two integration cases), `tests/config-d.pl` 6, `tests/local-install-epics.pl` 5, `tests/local-install-pv-menu.pl` 6, `tests/local-install-pv-range.pl` 4, `tests/local-install-pv-signals.pl` 3 and `tests/config-d-runtime.pl` 4. The signal test also has no check of how it ends when the evidence file of the verifier is missing.

##### Scope

- For each survivor, add an observation to the Perl test that fails on the mutation, or record with its reason that the line has no observable effect and keep the mutation as known to be equivalent.
- Run every mutation of the changed file again, with repeats for the timing-dependent ones of `tests/local-install-pv-menu.pl` and `tests/local-install-pv-range.pl`.

Out of scope: the conversion of the tests (M3); the exchange of the time-range test (M9); changes to the shipped code.

##### Completion Criteria

- Every survivor listed in the conversion record of M3 is killed by its Perl test or recorded as equivalent with the reason.
- The mutations that the tests kill after M3 stay killed.

##### Dependencies And Decisions

- D24 creates this item on 2026-11-02.
- M3 converts the tests first; M10 changes the converted files.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. List the survivors per file from the conversion record and, for each, decide by reading the shipped line whether an observation can see it.
2. Add the observations file by file and run the file against its mutations, one file at a time.
3. Record the survivors that stay, with their reasons.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Run the recorded mutations of each changed test and compare their verdicts with the recorded ones | A host with a real EPICS Base, Java and Tomcat | Each former survivor is killed or recorded as equivalent; the former kills stay |
| T2 | Local and guest | Run each changed test unmutated | The same host and the Rocky Linux guest | Every run passes, as before the change |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Pending | A host with a real EPICS Base, Java and Tomcat | Pending | none |
| T2 | Pending | The same host and the Rocky Linux guest | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Close the gaps that the Python tests left in the Perl tests
Labels: none
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M12 - Share the helper code of the Perl tests

Origin: 9576820 / M12
Identity History: created as M12 on 2026-11-02 by D24
GitHub Issue: none
Status: Open

##### Summary

Each of the nine Perl tests carries its own copy of its helpers: `slurp`, `spew` and `usage_error` in all nine files, `which` in seven, `shell_quote` and the pair `fail` and `check` in six, and `pause_for` in three. A fix in one copy has to be repeated by hand in the others, and the copies already differ in small details. The copies of `check` and `fail` have no prototype in six tests, which M14 repairs by declaring scalar prototypes (D27).

##### Scope

- Put the common helpers in one module below `tests/` that each test loads from its own location, using only the modules of the Perl core and keeping Perl 5.26 working.
- Keep every test runnable alone, from a copy of the tree, as the scratch trees of the mutation runs use it.
- Keep the scalar prototypes of `check` and `fail` that M14 adds, in the shared module.

Out of scope: changing what a test checks (M3, M10, M11); the shell helpers in `tests/lib/`.

##### Completion Criteria

- Every Perl test loads the shared module instead of its own copy, and the copies are gone.
- The output of each test on the shipped code and the verdicts of its recorded mutations are unchanged.
- The module has a check of its own that runs in the local suite, and it shows that a check with a failed pattern match fails.

##### Dependencies And Decisions

- D24 creates this item on 2026-11-02.
- D27 moves the scalar prototypes of `check` and `fail` to M14 on 2026-11-02.
- M3 converts the tests first; M12 changes the converted files.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Compare the copies of each helper and fix one behavior for each, noting where the copies differ.
2. Write the module and its check, then move the tests to it one at a time.
3. Run each moved test on the shipped code and against its recorded mutations.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Run each moved test on the shipped code and compare its output with the output before the move | A host with a real EPICS Base | The output is identical apart from paths and times |
| T2 | Guest | Run the moved tests that run on a guest | The Rocky Linux guest, Perl 5.26 | Every run passes |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Pending | A host with a real EPICS Base | Pending | none |
| T2 | Pending | The Rocky Linux guest | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Share the helper code of the Perl tests
Labels: none
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M13 - Decide the evidence that passing runs of the converted tests keep

Origin: 9576820 / M13
Identity History: created as M13 on 2026-11-02 by D26
GitHub Issue: none
Status: Open

##### Summary

`tests/config-d-runtime.pl`, `tests/local-install-pv-signals.pl` and `tests/local-install-pv-range.pl` keep the evidence of every run, about 476 MB for one run of the first, while `tests/config-d.pl`, `tests/health-local.pl` and `tests/database-config.pl` remove the workspace of a passing case and keep that of a failed case (D22). The Python tests kept every workspace. Which rule the three tests follow is the owner's decision: keep as before, follow D22, or keep only on request.

##### Scope

- The owner decides one rule for the evidence of a passing run of these three tests, keeping the evidence of a failed run and the `KEEP_WORKSPACE` switch of D22 where it applies.
- Apply the rule to the three tests and to `tests/README.md`.

Out of scope: the conversion of the tests (M3); the false failures of the same tests (M11).

##### Completion Criteria

- The decision is recorded with its date.
- A passing run of the three tests behaves as the decision says, and a failed run keeps its evidence.

##### Dependencies And Decisions

- D26 creates this item on 2026-11-02.
- M3 converts the tests first; M13 changes the converted files.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Record the decision of the owner.
2. Apply the rule to the three tests, one at a time, and update the guide.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Run each of the three tests once on the shipped code and once failing | A host with a real EPICS Base, Java and Tomcat 9 | The evidence of the passing run is kept or removed as decided, and the failed run keeps its evidence |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Pending | A host with a real EPICS Base, Java and Tomcat 9 | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Decide the evidence that passing runs of the converted tests keep
Labels: none
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

## History

| Reset Date | Prior State Commit |
| --- | --- |
| 2026-10-29 | 95768200a49e965ef2dd1949919e955af982aff6 |
