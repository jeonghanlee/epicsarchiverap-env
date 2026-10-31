# Work Register

Release line: master (unversioned development on the default branch maven)
Milestone index: 9576820
Canonical path: `docs/milestone-9576820.md`
Canonical branch or ref: maven
Git upstream: origin/maven
Remote tracker: jeonghanlee/epicsarchiverap-env; no open release milestone (observed 2026-10-29 via `gh api repos/jeonghanlee/epicsarchiverap-env/milestones`)

Next session entry point: T1 to T5 are recorded as Pass on Debian 13 and Rocky 8.10, so M2 closes only with its commit, push and landing evidence under separate `git-workflow` authority; the plan was accepted and implementation authorized on 2026-10-30, and the Verification Results record what has run. D15 requires file and line numbers without configuration contents in diagnostics. M1 landed at c4b27bcc65fa70ee7c80ccee7d40136bab64d995. Commit, push and issue creation need their own authority. Then follow M3 and M4 in that order. M5, M6 and M7 remain Deferred; their later order is not authorization to resume.

## Scope

This generation owns the seven unfinished items on the default development branch. The assigned work order is M1, M2, M3 and M4. Deferred work is ordered M5, M6 and M7 for later reconsideration. Assignment authorizes preparation of the existing scope; implementation-plan acceptance and implementation authorization remain separate. Historical results remain evidence for their recorded inputs.

Out of scope for this assignment update: product implementation, VM provisioning, a new numbered release, and changes to GitHub issues or milestones.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DB | M1 | Apply backend selection to all database operations | Carry-forward | Complete | No | D4, D11, D13, D14 | T1-T5 and correction checks passed; landed at c4b27bc; [detail](#m1---apply-backend-selection-to-all-database-operations) |
| Install | M2 | The operating system target rewrites `configure/CONFIG_SITE.local` and the installers run it first | Milestone | In progress | No | M1, D7, D11, D15 | Installers refuse extra assignments before overwriting generated OS configuration; [detail](#m2---the-operating-system-target-rewrites-configureconfig_sitelocal-and-the-installers-run-it-first) |
| Tests | M3 | Replace the Python tests with Bash tests | Carry-forward | Not started | No | M2, D6, D11 | Shell and Make tests run in Bash with the same assertions and defect detection; [detail](#m3---replace-the-python-tests-with-bash-tests) |
| Tests | M4 | Fix the findings of the review of the VM driver | Carry-forward | Not started | No | M3, D8, D11 | Driver findings are fixed or decided, with defect-sensitive tests and a real guest verdict; [detail](#m4---fix-the-findings-of-the-review-of-the-vm-driver) |

Ready indicates work-order eligibility; it does not accept a draft plan or authorize implementation. Assigned work: 1 Complete, 1 In progress and 2 Not started. No assigned row is Ready until M2 completes; M3 follows M2.

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
Status: In progress

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
