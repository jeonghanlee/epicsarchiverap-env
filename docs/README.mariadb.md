# MariaDB Configuration

## Generic Configuration

* Secure Setup and add administor : only need to do at the beginning of the MariaDB configuration. One has

```bash
make db.secure
```

* Add the admin user account for SQL Database. We use the default `root` through `unix_socket` to connect the SQL server, so we would like to create `admin` account to let users allow to connect the database without `unix_socket`.

```bash
make db.addAdmin
```

One can remove it via `make db.rmAdmin`.

## Archiver Appliance Configuration

* Generate MariaDB configuration file based on `configure/CONFIG_COMMOM`

```bash
make db.conf
```

* Show the generated MariaDB configuration file

```bash
$ make db.conf.show
     1  ## MariaDB configuration example
     2  ## Users in the HOSTS can access the SQL server with DB_ADMIN permission
     3  DB_ADMIN_HOSTS="localhost 127.0.0.1 10.0.0.200"
     4  ## SQL Server
     5  DB_HOST_IPADDR=127.0.0.1
     6  DB_HOST_PORT=3306
     7  DB_HOST_NAME=localhost
     8  ## SQL server ADMIN user, because we don't use root
     9  DB_ADMIN=admin
    10  DB_ADMIN_PASS=admin
    11  ## User for the Database DB_NAME
    12  DB_NAME=archappl
    13  DB_USER=archappl
    14  DB_USER_PASS=archappl
```

* Create DB with DB user

```bash
make db.create
```

* Show exist DBs

```bash
make db.show
```

* Drop DB and remove the DB user

```bash
make db.drop
```

## Fill the Tables

* Fill Tables from `SQL_AA_SQL`

```bash
make sql.table.fill
```

* Show Tables

```bash
$ make sql.table.show

>>    1/   1/   4<<                        ArchivePVRequests
>>    2/   2/   4<<                      ExternalDataServers
>>    3/   3/   4<<                                PVAliases
>>    4/   4/   4<<                               PVTypeInfo
```

* Drop Tables

```bash
make sql.tables.drop
```
