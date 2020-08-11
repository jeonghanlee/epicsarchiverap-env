# EPICS Archiver Appliance Configuration Environment

![Build](https://github.com/jeonghanlee/epicsarchiverap-env/workflows/Build/badge.svg)
![Linter Run](https://github.com/jeonghanlee/epicsarchiverap-env/workflows/Linter%20Run/badge.svg)

Configuration Environment for EPICS Archiver Appliance at <https://github.com/slacmshankar/epicsarchiverap>

## Requirements

### Download source code first

```bash
make init
```

### Install required packages

* Debian 10

```bash
make install.pkgs
```

### Tomcat 9

* Debian 10 : tomcat9 will be installed through `make install.pkgs`

* CentOS 8 : See  [docs/README.tomcat.md](docs/README.tomcat.md)

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
make addAdmin
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

We can use the local JAVA and Ant environments. The java 11/12 and Ant.

See [docs/README.javapkgs.md](docs/README.javapkgs.md)

## TL;DR

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

* Stop Services

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
