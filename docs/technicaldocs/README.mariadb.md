# MariaDB Configuration

We bind MariaDB to the loopback interface only (`localhost`, i.e. `127.0.0.1`), so all connections are limited to the local host.

The Archiver Appliance connects to the database over `127.0.0.1` (IPv4 loopback), set by `DB_HOST_NAME=127.0.0.1` in `configure/CONFIG_SITE`. When MariaDB is exposed over TCP, the application account is `archappl@'127.0.0.1'` with `skip-name-resolve` ON, so the grant matches the IPv4 connection deterministically. The `admin` account below belongs to the local-only setup path.

## Generic Configuration

* Secure Setup and add administor : only need to do at the beginning of the MariaDB configuration. One has

```bash
make db.secure
```

`make db.secure` keeps `root@'localhost'` (unix_socket) and removes every other root account and all anonymous users with `DROP USER`, which works on both MariaDB 10.3 and 10.4+ (on 10.4+ a direct `DELETE` on the `mysql.user` view reports success but does not remove the account -- a silent no-op). It then drops the `test` database, so no root login is reachable over TCP afterward.

* Add the admin user account for SQL Database. We use the default `root` through `unix_socket` to connect the SQL server, so we would like to create `admin` account to let users allow to connect the database without `unix_socket`.

```bash
make db.addAdmin
```

It is better to check the result via the sql query `select user, host, password from mysql.user;`. For example,

```bash
MariaDB [(none)]> select user, host, password from mysql.user WHERE user = 'admin';
+-------+-----------+-------------------------------------------+
| user  | host      | password                                  |
+-------+-----------+-------------------------------------------+
| admin | localhost | *4ACFE3202A5FF5CF467898FC58AAB1D615029441 |
+-------+-----------+-------------------------------------------+
```

If one would like to check its grant and others, the following query is useful:

```sql
SELECT user, host, Password, Grant_priv, Show_db_priv, authentication_string, default_role, is_role FROM mysql.user;
```

One can remove it via `make db.rmAdmin`.

## Archiver Appliance Configuration

* Generate MariaDB configuration file based on `configure/CONFIG_SITE`

```bash
make db.conf
```

* Show the generated MariaDB configuration file

```bash
$ make db.conf.show
     1  ## MariaDB configuration example
     2  DB_ADMIN_HOST="localhost"
     3  DB_HOST_IPADDR=127.0.0.1
     4  DB_HOST_PORT=3306
     5  DB_HOST_NAME=127.0.0.1
     6  ## SQL server ADMIN user, because we don't use root
     7  DB_ADMIN=admin
     8  DB_ADMIN_PASS=admin
     9  ## User for the Database DB_NAME
    10  DB_NAME=archappl
    11  DB_USER=archappl
    12  DB_USER_PASS=archappl
```

* Create DB `DB_NAME` with an associated user `DB_USER`.

```bash
make db.create
```

* Show exist DBs

```bash
make db.show
```

* Drop DB and remove the associated user `DB_USER`.

```bash
make db.drop
```

## Fill the Tables

* Fill Tables from `SQL_AA_SQL`

```bash
make sql.fill
```

* Show Tables

```bash
$ make sql.show

>>    1/   1/   4<<                        ArchivePVRequests
>>    2/   2/   4<<                      ExternalDataServers
>>    3/   3/   4<<                                PVAliases
>>    4/   4/   4<<                               PVTypeInfo
```

* Drop Tables

```bash
make sql.drop
```


## Archiver Appliance Table Entries

The archiver SQL has four tables, which we can see with `make sql.show`. Here we can see its entries in each table in a short format.

* `ArchivePVRequests` Table

```bash
make PVRequests.show
```

* `ExternalDataServers` Table

```bash
make DataServers.show
```

* `PVAliases` Table

```bash
make PVAliases.show
```

* `PVTypeInfo` Table

```bash
make PVTypeInfo.show
```


