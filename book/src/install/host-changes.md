# Changes that the installer makes on the host

The installers `install-local-sqlite.bash`, `install-local-mariadb-uds.bash` and `install-local-mariadb-tcp.bash` change the host in the places that this page lists. A reinstall repeats the same changes. It replaces the installed payload and keeps the database contents and the stores. The [glossary](../appendix/glossary.md) explains the terms of this page.

The page covers the installation itself. The optional soft IOC test that the installer offers is separate. It registers one PV in the configuration database of the appliance and writes a workspace under `/tmp`. When you choose to keep the test, a soft IOC process keeps running. [Archive a test PV and check the stored samples](verify-pv.md) describes the test.

Paths and names on this page are the defaults. `make -s print-<variable>` prints the value that your checkout uses.

## Operating system packages

- The installer installs packages unless it runs with `--skip-packages`.
- It reads the list that `scripts/install_os_packages.bash --list-only --os <os>` prints.
- On Debian 13, Ubuntu 24.04 and Ubuntu 26.04 it runs `sudo apt-get update` and `sudo apt-get install -y`. On Rocky Linux it runs `sudo dnf install -y`.
- The SQLite installer leaves out the packages `mariadb`, `mariadb-*` and `libmariadb-*`. The MariaDB installers install them.
- The list includes `chrony`. On Debian 13, `chrony` provides and conflicts with `time-daemon`, so installing it can replace another time daemon.

## The service account

- The installer creates the group and the system user that `AA_GROUPID` and `AA_USERID` name (`tomcat` by default) when they are missing.
- It creates them in one of two places: when it installs or replaces Tomcat, or in the database step. For SQLite, `sql.table.fill` runs that step; for MariaDB, `src_preinst` runs it.
- With an existing Tomcat, the check of the Tomcat access runs first. The service user must already exist, or the installer stops with `Service user <name> cannot execute <Tomcat>/bin/catalina.sh`.
- The user gets the shell `/usr/sbin/nologin` and the home field `/`. The installer creates no home directory.
- An existing group or user stays as it is.

## Changes in the checkout

- The first `make` step, `make <os>.conf`, deletes and rewrites `configure/CONFIG_SITE.local`.
- The installer renders the generated files and creates the lock file `work/.local-install.lock`.
- On the first run it clones the source repository `epicsarchiverap-maven-src`. On every run it fetches and builds the source.
- The build replaces `epicsarchiverap-maven-src/src/sitespecific/<site_id>` with a copy of `site-template/siteid`. The placeholder `<site_id>` is `ARCHAPPL_SITEID`; the installers pass `als` to every make step.
- `make conf.install` writes `site-template/.versions`.
- The installer does not rewrite `../CONFIG_SITE.local`. Put your site values there.

## The installed payload

The payload lives in `AA_INSTALL_LOCATION` (`/opt/epicsarchiverap-maven`).

- The installer replaces the payload in the four instance folders.
- It also replaces `archappl.conf`, `appliances.xml`, `archappl.properties`, `policies.py`, `archappl.bash`, and `archappl-config.bash`, and gives the files to the service account. It creates `config.d` and preserves existing [local environment files](../configure/runtime-environment.md).
- In each instance it edits `conf/server.xml` to the ports 17665 to 17668 and keeps the original as `server.xml.bak`.
- For the MariaDB installers, `conf/context.xml` of each instance holds `DB_USER_PASS` and has the mode 644.

## The Tomcat installation

Tomcat lives in `TOMCAT_INSTALL_LOCATION` (`/opt/tomcat9`).

- The installer installs the configured Tomcat when the folder is missing. It also installs it when `--tomcat replace`, or the answer `2` at the Tomcat question, selects the replacement.
- It downloads the archive into the checkout with `wget -c` and extracts it.
- It edits `conf/server.xml`. The connector port 8080 becomes `TOMCAT_DEFAULT_PORT`, and the original stays as `server.xml.bak`.
- It gives the folder to the service account with `chown -R` and sets the modes of `lib` and `bin`.
- For a replacement, it stops the appliance after the download and the checksum check. It then moves the existing folder to `/opt/tomcat9.backup.<random>/tomcat`. The backup stays on the host.
- With `--tomcat existing`, the installer uses the existing Tomcat as it is. When the Tomcat folder is missing, it stops with `Existing Tomcat is missing`.

## The systemd unit files

The files live in `/etc/systemd/system/`.

- The installer stops the running appliance and the health timer before it replaces installed files.
- It installs `epicsarchiverap-maven.service`, `epicsarchiverap-maven-health.service` and `epicsarchiverap-maven-health.timer`. A file that it replaces stays as a backup with the suffix `~`.
- For the MariaDB installers, the service unit lists `mariadb.service` in `After=` and `Requires=`.
- It reloads systemd, enables the service and the health timer, and starts both. Both start at boot.
- Enabling also creates the alias `archappl.service`.

## The Tomcat drop-in file

The file is `/etc/systemd/system/tomcat9.service.d/override.conf`.

- The installer writes `ReadWritePaths=<install_location>/`, where `<install_location>` is `AA_INSTALL_LOCATION`. A file that it replaces stays as `override.conf~`.
- The drop-in applies to a `tomcat9.service` that the host provides.

## The storage folders

The folders are `ARCHAPPL_STORAGE_TOP` (`/arch`) and the three store folders `sts/ArchiverStore`, `mts/ArchiverStore` and `lts/ArchiverStore` below it, for the short, medium and long term store.

- The installer creates the folders when they are missing.
- It gives them to the service account with `chown -R`, recursively over the existing content.
- The run time grows with the size of the archive. Other data below those folders changes its owner too.

## The SQLite database file

The file is `ARCHAPPL_SQLITE_FILE` (`/arch/config/archappl.sqlite`).

- The installer creates the folder of the file and gives it to the service account.
- It loads the schema with `IF NOT EXISTS`. The existing contents stay.

## The MariaDB server and database

- The installer starts `mariadb.service`.
- Unless `--existing-db` is set, it creates or updates the two accounts and creates the database.
- The administrative account `DB_ADMIN` (`admin`) receives `GRANT ALL ON *.* ... WITH GRANT OPTION`. The grant holds for the whole server.
- The application account `DB_USER` (`archappl`) receives `GRANT ALL PRIVILEGES` on the database `DB_NAME` (`archappl`). The installer creates that database with `CREATE DATABASE IF NOT EXISTS`.
- The socket installer sets the accounts at `localhost`. The TCP installer sets them at `DB_HOST_NAME`.
- An existing account receives the configured password and grants.
- In every case, including `--existing-db`, the installer loads the schema with `CREATE TABLE IF NOT EXISTS`.

## Passwords and who can read them

- The SQLite installer creates no database account and reads no database password. The rest of this section applies to the MariaDB installers.
- The installers do not generate passwords. `DB_ADMIN_PASS` and `DB_USER_PASS` default to the fixed repository values `admin` and `archappl`. They are temporary values for a first trial: set the passwords of the host in `../CONFIG_SITE.local` before the installer prepares the accounts.
- A host that keeps the defaults has an administrative account with a server-wide grant and a password that every installation shares.
- The installer renders the passwords in clear text into `site-template/mariadb.conf` and `site-template/context.xml` in the checkout. It renders `mariadb.conf` with `umask 077`, so only the checkout owner can read it. The installer runs with `umask 022`, so a newly rendered `context.xml` is readable by every user of the host. An existing file keeps its earlier mode.
- `conf/context.xml` of each instance holds `DB_USER_PASS` and has the mode 644, so every user of the host can read it.
- `../CONFIG_SITE.local` holds the passwords that you set, with the permissions that you give the file.
- Restrict who can read the checkout and `../CONFIG_SITE.local` when other users share the host.

## Network ports of the installation

| Instance | Port |
| :--- | ---: |
| `mgmt` | 17665 |
| `engine` | 17666 |
| `etl` | 17667 |
| `retrieval` | 17668 |

- The installer sets these ports in `conf/server.xml` of each instance.
- The shipped connectors name no `address`, so Tomcat listens on all local addresses. This is the default that the Tomcat 9 documentation gives for the connector attribute `address`.
- The shutdown port of each instance is `-1`, which disables it.
- The shared Tomcat folder gets the connector port `TOMCAT_DEFAULT_PORT` (8083 by default) in its own `conf/server.xml`. The four instances use the ports above from their own `conf/server.xml`.
- The `mgmt` web application declares no security constraint, so every `/mgmt/bpl` action (archive, delete and the others) is open to any client that reaches the port. `archappl.bash loglevel` sends such plain HTTP requests without credentials.
- MariaDB over TCP uses `DB_HOST_NAME` and `DB_HOST_PORT` (`127.0.0.1` and `3306` by default).
- The installer configures no firewall. Decide who may reach these ports before you use a shared host.

## Network access of the installers

The installers need network access to these places:

| Place | When |
| :--- | :--- |
| The operating system package repositories | The installer installs packages |
| The source remote of `epicsarchiverap-maven-src` | The installer clones the source, fetches it with `git fetch origin` and updates its submodules |
| The Maven repositories | The build downloads dependencies that the local Maven cache does not hold |
| The Tomcat download site | The installer installs Tomcat |

The build time and the disk space depend on the host and on the Maven cache. This book gives no measured value.

## What a site hardens itself

The installers set values for a first trial. A site that shares the host with other users, or opens the ports to other hosts, hardens five points itself. The first two points and the fifth point apply to the MariaDB installers, because the SQLite installer reads no database password and starts no MariaDB server.

- **The passwords.** Set `DB_ADMIN_PASS` and `DB_USER_PASS` in `../CONFIG_SITE.local` before the installer prepares the accounts. With `--existing-db`, `DB_USER_PASS` must match the password of the existing application account.
- **The mode of `conf/context.xml`.** The file of each instance holds `DB_USER_PASS` and has the mode 644. Restrict who can read it, but keep it readable by the service account `AA_USERID`, and repeat the change after a [reinstall](reinstall.md), which overwrites the installed files. The copies `site-template/context.xml` and `site-template/mariadb.conf` in the checkout hold the same password and keep the mode they had when first rendered, so restrict them too.
- **The connector addresses.** The shipped connectors name no `address`, so Tomcat listens on all local addresses, and the installer configures no firewall. Decide with a firewall which hosts may reach the ports 17665 to 17668.
- **The management port.** The `mgmt` port accepts every `/mgmt/bpl` action (archive, delete, `archappl.bash loglevel` and the others) without credentials from any client that can reach it. The firewall decision of the previous point covers it.
- **The MariaDB listener.** The installers leave the network settings of the MariaDB server as the package sets them. On Rocky Linux 8 the server listens on all addresses on port 3306, because `bind-address` is a comment in `/etc/my.cnf.d/mariadb-server.cnf`; on Debian 13 it listens on `127.0.0.1`. Decide with a firewall which hosts may reach port 3306, or set the MariaDB option `bind-address` to `127.0.0.1` in the server configuration and restart `mariadb.service`.

## Undo an installation

The target `make uninstall` stops and disables the service and the health timer. It removes the service file and the two health unit files, and it deletes `AA_INSTALL_LOCATION`.

The target leaves these on the host:

- the stores and the database;
- Tomcat and its backup folder;
- the service account and the operating system packages;
- the MariaDB accounts `DB_ADMIN` and `DB_USER`, and the running `mariadb.service`;
- the Tomcat drop-in `override.conf` and the backup files with the suffix `~`;
- the files of the checkout.

Run both targets from the checkout. The target `make conf.storage.rm` deletes `ARCHAPPL_STORAGE_TOP` and everything below it, including the stores and, with the default paths, the SQLite file. It runs `rm -rf` without `sudo` and ignores its errors, so it cannot remove files that the service account owns unless you run it with root rights. The repository has no target for the MariaDB accounts, the service account, Tomcat or the operating system packages. Remove them with the tools of the host.
