# MariaDB configuration reference

This page describes the appliance's MariaDB connection, account preparation,
schema targets, and configuration database backup. Archived PV samples reside
in the STS, MTS, and LTS stores; MariaDB stores appliance configuration.

**Out of scope:** MariaDB server installation, listener configuration, and archive
store backups. Use the [installation procedure](../README.install.md#local-systemd-installation)
for the local entry scripts and the ordered installation sequence.

## Connection and account settings

Set site values in `../CONFIG_SITE.local`, relative to the environment checkout.
Generate client settings with `make db.conf` after changing them.

| Setting | Effect |
| --- | --- |
| `DB_BACKEND=mariadb` | Selects MariaDB configuration and schema targets |
| `DB_SOCKET` | Selects an absolute Unix domain socket for application and helper clients |
| Empty `DB_SOCKET` | Selects TCP using `DB_HOST_NAME` and `DB_HOST_PORT` |
| `DB_HOST_NAME` | Defaults to IPv4 loopback, `127.0.0.1` |
| `DB_HOST_PORT` | Defaults to `3306` |
| `DB_NAME` | Selects the appliance configuration database |
| `DB_USER`, `DB_USER_PASS` | Select the application's database identity and password |
| `DB_ADMIN`, `DB_ADMIN_PASS` | Select the database administrator used by helper commands |

The environment does not configure MariaDB's bind address or enable
`skip-networking` or `skip-name-resolve`. Those are host settings.
Socket clients use account host `localhost`; the TCP installation entry script
creates accounts at `127.0.0.1` and works with `skip-name-resolve`.
A socket-only server can use `skip-networking` when all appliance clients use
the configured socket.

The UDS installer starts MariaDB and prepares the administrator and application
accounts at `localhost`. The TCP installer prepares both at `127.0.0.1`.
Both create or update the configured database, passwords, and grants.
`--existing-db` skips account provisioning but still starts MariaDB and loads
the schema. Neither installer invokes `db.secure`.

## Account and configuration targets

Run these targets from the environment checkout. Account preparation requires
a reachable local MariaDB server and suitable root socket authentication.
Database operations require the configured administrator or application account.
Root account operations explicitly select `localhost` and the socket protocol.
With `DB_SOCKET`, they use that path; otherwise they use the client socket setting.
Application TCP settings do not select the root account preparation transport.

| Make target | Behavior |
| --- | --- |
| `db.conf` | Generates `site-template/mariadb.conf` with mode 0600 |
| `db.conf.show` | Prints the generated client settings, including passwords |
| `db.secure` | Removes anonymous accounts, root accounts whose host is not `localhost`, and the `test` database |
| `db.addAdmin` | Creates or updates the configured administrator at `localhost` |
| `db.create` | Creates or updates the configured database and application account for the selected transport |
| `db.show` | Lists databases using the configured administrator |
| `db.drop` | Drops the configured database and its application account |

`db.secure` preserves the authentication method of `root@localhost`.
It does not convert that account to `unix_socket`, set its password, or
guarantee rejection of local TCP root connections. Root authentication and
TCP access must be configured independently on the host.

For manual local provisioning, select `DB_SOCKET` before `db.addAdmin`.
That target uses `localhost` for the account host even when application clients
use TCP. A TCP client at `127.0.0.1` cannot rely on the `localhost` account
when name resolution is disabled.

The generated client file contains secrets. Keep its mode 0600 and do not
publish `db.conf.show` output. Account creation and removal list account names,
hosts, and grant flags without password or authentication hashes.
Database client failures return nonzero, including errors during table listing,
row queries, and account listing after account changes.

## Schema and table targets

Schema generation reads `SQL_AA_ORIG_SQL` from the selected source checkout.
It writes `SQL_AA_UPDATE_SQL` and uses
`CREATE TABLE IF NOT EXISTS` for repeatable schema loading.

| Make target | Behavior |
| --- | --- |
| `sql.fill` | Loads the source schema using the application account |
| `sql.show` | Lists the configuration database tables |
| `sql.drop` | Drops every user table, retaining the database |
| `PVRequests.show` | Displays numbered `ArchivePVRequests.pvName` values |
| `DataServers.show` | Displays numbered `ExternalDataServers.serverid` values |
| `PVAliases.show` | Displays numbered `PVAliases.pvName` values |
| `PVTypeInfo.show` | Displays numbered `PVTypeInfo.pvName` values |

The schema contains `ArchivePVRequests`, `ExternalDataServers`, `PVAliases`,
and `PVTypeInfo`. Use `make sql.fill` for schema creation; the helper does
not expose the legacy `tableCreate`, view, or procedure creation commands.
An empty existing table is a successful query. A missing table produces a
nonzero result from the helper and its Make target.
Successful schema loading and table listing do not prove
PV acquisition or archived sample retrieval. Use the
[functional verification procedure](../README.install.md#functional-verification)
for the data path.

## Configuration database backup behavior

The `dbBackup` action of `scripts/mariadb_setup.bash` writes a compressed SQL
dump named `<database_name>_<yymmddhhmm>.sql.gz` in the requested directory.
It uses the application account and requires sufficient dump privileges,
including table locks.

The filename has one-minute resolution. If that path already exists, including
a directory or symlink, another backup is rejected and the path is preserved.
A backup writes to a private mode-0600 temporary file in the output directory.
Only a complete dump is published; a competing file created during the dump
also causes publication to fail without replacing it. Failed dumps and failed
publication remove the temporary file and return nonzero.
The restore action reads the selected compressed file and loads it with the
configured administrator. These operations cover the configuration database
only; retain separate backups of the archive stores.



## Backend operation contract

The existing `scripts/mariadb_setup.bash` dispatcher selects `DB_BACKEND`.
Invoke it directly or with `bash -p`, including under sudo. Make passes resolved
settings; direct invocations resolve the same Makefiles with explicit database
environment values overriding them, including empty values. MariaDB compares
current settings with `mariadb.conf` without executing that file. Missing or
changed settings require `make db.conf`; a timestamp match is insufficient.
Targets already depending on `db.conf` prepare it explicitly. Installing changed
`context.xml` and `archappl.conf` and restarting the appliance is required to
change its running database identity. Helpers never deploy or restart services.

| Operation | MariaDB | SQLite |
| --- | --- | --- |
| `db.conf`, `db.conf.show` | Generate/display client settings | Successful skip |
| `db.secure`, `db.addAdmin`, `db.rmAdmin` | Server/account administration | Unsupported, status 2 |
| `db.create`, `db.drop`, `db.show` | Database plus application account lifecycle; list databases | Create empty valid file, remove file, print existing absolute file path |
| `sql.update`, `sql.update.show` | Generate/display modified shipped schema | Same; guards tables and triggers with IF NOT EXISTS |
| `sql.fill`, `sql.table.fill` | Load schema | Load schema as service account; can initialize missing file |
| `sql.show`, `sql.table.show` | List tables | List existing file tables without creating a missing file |
| `sql.drop`, `sql.table.drop` | Drop all user tables | Drop all user tables in one transaction, excluding engine internals |
| Four application `.show` targets | Numbered first-column identifiers | Same, preserving spaces |

Direct `dbCreate`/`dbDrop` are database-only; `dbUserCreate`/`dbUserDrop`
include MariaDB accounts and reject SQLite. `dbShow`, `isDb`, `tableShow`,
`tableDrop`, `aaShow`, `query`, `queryFile`, `querySFile`, `dbBackup`,
`dbBackupList` and `dbRestore` support both backends. `isDb` exits 0 for
present, 1 for absent and 2 for inspection/configuration failure.
`aaShow [table]` defaults to `PVTypeInfo`; an empty table succeeds and a
missing table fails. Row ordering is unspecified. Account actions
`secureSetup`, `localAdminAdd`, `hostnameAdminAdd`, `localAdminRemove`,
`hostnameAdminRemove`, `adminAdd`, `adminRemove` and `userDrop` are MariaDB-only.
The legacy `addProject`, `updateCDBAdminPassword` and `showAdminCryptPassword`
actions reject before configuration access.

`query [sql]` returns native client output; its default lists MariaDB databases
or SQLite user tables. `queryFile [file] [options] [verbose]` reads native SQL;
`querySFile` is its alias. MariaDB defaults to the shipped `default_query.sql`.
Only the separate output flags `-N`, `--skip-column-names`, `-B`, `--batch`,
`-r`, `--raw`, `-t` and `--table` are accepted in its option string. Combined
or abbreviated flags, connection options, SQL-execution options and positional
arguments fail before any connection. SQLite requires an explicit file and
empty options. Verbose is empty/NO or YES. SQL errors return failure.
Native SQL may explicitly address other databases; these actions do not
translate or sandbox operator SQL.

### Maintenance and SQLite files

Creation, schema load, table/database deletion, raw SQL, backup and restore
require the appliance and its health service/timer to be inactive. Stop them
explicitly with `make sd_health_stop` and `make sd_stop`, then check actual
state. The helper independently verifies state, rejects unknown/error states,
and never stops services itself. Absent units permit initial provisioning.
Keep independent clients and service starts out of the maintenance window;
MariaDB itself stays running. Read-only inspection and backup listing may
run live.

SQLite requires an absolute path on a supported local filesystem, a regular
non-symlink file, and ownership matching `AA_USERID` and `AA_GROUPID`. Clients
run as that account. New files are 0600 and new private directories 0700;
existing directories are checked, not recursively changed. Non-root callers
need noninteractive sudo. Privileged `lsof` inspection rejects open database,
WAL or shared-memory references before maintenance. A per-file advisory lock
serializes helpers; SQLite busy waits are limited to 5 seconds and each client
operation to 30 seconds. These checks do not prevent arbitrary external opens
after inspection.

Create retains a valid existing database and initializes an empty file without
appliance tables. Corrupt files fail. Table deletion retains the file. Database
deletion uses SQLite checkpoint/journal cleanup, then removes only the main
file if side files are absent. An absent database with no side files succeeds;
orphan WAL/shared-memory files require recovery. Never remove WAL independently.

### Backup and restore arguments

Use `dbBackup [directory]`, `dbBackupList [directory]`, and
`dbRestore stamp [directory]`. MariaDB defaults to `<checkout>/<DB_NAME>_sql_backup`
and retains the compressed SQL naming above. Restore requires an existing
database and validates gzip input before import. An import error may leave
partial changes; there is no automatic rollback or service restart.

SQLite defaults to `<ARCHAPPL_SQLITE_FILE>.backups` and names backups
`<database-basename>_<YYYYmmddTHHMMSSZ>.sqlite3`. The SQLite backup API creates
a consistent temporary file; DELETE journal mode and `quick_check` validate
it before publication without overwriting an existing path. Listing prints
sorted matching names, ignores private temporary files and does not need the
main database. A missing/unreadable backup directory fails; an empty one succeeds.

SQLite restore requires the database and WAL/shared-memory paths to be absent,
including no zero-length file or symlink. To replace a database, back it up,
run `db.drop`, then restore. Restore validates the backup read-only, stages and
validates a private file, then publishes without replacing a competing path.
The source backup remains unchanged. The appliance enables WAL on its next JDBC
open. Failed publication leaves any competing destination unchanged. Uncatchable
interruption may leave private temporary files; no completed backup is reported.
Cross-backend restore and archive-store backup are outside this interface.
