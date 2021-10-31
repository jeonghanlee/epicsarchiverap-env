# EPICS Archiver Appliance Configuration Environment
[![Build](https://github.com/jeonghanlee/epicsarchiverap-env/actions/workflows/build.yml/badge.svg)](https://github.com/jeonghanlee/epicsarchiverap-env/actions/workflows/build.yml)
[![Linter Run](https://github.com/jeonghanlee/epicsarchiverap-env/actions/workflows/linter.yml/badge.svg)](https://github.com/jeonghanlee/epicsarchiverap-env/actions/workflows/linter.yml)

Configuration Environment for EPICS Archiver Appliance at <https://github.com/slacmshankar/epicsarchiverap>

## Requirements

### Download source code first

```bash
make init
```

### Install required packages

* Debian 10/11

```bash
make install.pkgs
```

Note that MariaDb should be started before further steps.

```bash
sudo systemctl start mariadb
```

### Tomcat 9

* Debian 10/11 : tomcat9 will be installed through `make install.pkgs`

* Others : See  [docs/README.tomcat.md](docs/README.tomcat.md)

### MariaDB

* JDBC connector

It is inside the site specific building procedure, so don't need to do anything.

* Create the DB and itsuser : `archappl`

If the MariDB has already `admin` account, please use it with the modification in `configure/CONFIG_COMMOM`.
With the admin account, create `db` and `user` for the archiver appliance.

```bash
make db.create
```

If one cannot get results properly by `make db.show`, please run `make addAdmin`. Thus, from scratch, one should do

```bash
make db.secure
make db.addAdmin
make db.show
make db.create
make db.show
```

* Create and fill the tables

```bash
make sql.fill
make sql.show
```

Please see [docs/README.mariadb.md](docs/README.mariadb.md) for the further information.

### JAVA and Ant

For JAVA and Ant configuration, please look at the generic Java Environment [1].

For the testing purpose, one can use the local JAVA and Ant environments. The java 11/12 and Ant.

See [docs/README.javapkgs.md](docs/README.javapkgs.md)

* Debina 10 System

```bash
JAVA_HOME:=/usr/lib/jvm/java-11-openjdk-amd64
ANT_HOME:=/usr/share/ant
TOMCAT_HOME:=/usr/share/tomcat9
```

## EPICS Environment Variables

The default EPICS Environment Variables are defined as

```bash
% make vars FILTER=EPICS_

EPICS_CA_ADDR_LIST = localhost
EPICS_CA_AUTO_ADDR_LIST = YES
EPICS_CA_MAX_ARRAY_BYTES = 16384
```

Please see `configure/CONFIG_EPICSENV`. After deployment, one changes `archappl.conf` file in `INSTALL_LOCATION`, and restart it through systemd service or its master script. Note all 4 services should be restarted.

## TL;DR for Debian 11

```bash
make build
make install
make sd_start
make sd_status
```

|![AAH](docs/images/home.png)|
| :---: |
|**Figure 1** Firefox Archiver Appliance Home Page Screenshot.|

* Startup services

```bash
systemctl start epicsarchiverap.service
```

* Stop Services

```bash
systemctl stop epicsarchiverap.service
```

## CentOS7

See [docs/README.centos7.md](docs/README.centos7.md)

## Rocky8.4

See [docs/README.rocky8.md](docs/README.rocky8.md). This instruction may work with CentOS8.

### Build

* Generate all configuration files, and prepare the storage space, and build the archiver appliance

```bash
make build
```

which contains three rules such as `conf.archapplproperties`, `conf.storage`, and `build.ant`

### Install

```bash
make install
```

### Systemd

```bash
make sd_start
make sd_status
```

## References

[1] <https://github.com/jeonghanlee/java-env>
