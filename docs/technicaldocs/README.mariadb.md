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
It writes `SQL_AA_UPDATE_SQL` with the configured database name and uses
`CREATE TABLE IF NOT EXISTS` for repeatable schema loading.

| Make target | Behavior |
| --- | --- |
| `sql.fill` | Loads the source schema using the application account |
| `sql.show` | Lists the configuration database tables |
| `sql.drop` | Drops the configuration database tables |
| `PVRequests.show` | Displays `ArchivePVRequests` rows |
| `DataServers.show` | Displays `ExternalDataServers` rows |
| `PVAliases.show` | Displays `PVAliases` rows |
| `PVTypeInfo.show` | Displays `PVTypeInfo` rows |

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


