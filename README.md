# EPICS Archiver Appliance Configuration Environment
[![Linux Build](https://github.com/jeonghanlee/epicsarchiverap-env/actions/workflows/build.yml/badge.svg)](https://github.com/jeonghanlee/epicsarchiverap-env/actions/workflows/build.yml)
[![macOS Build](https://github.com/jeonghanlee/epicsarchiverap-env/actions/workflows/macOS.yml/badge.svg)](https://github.com/jeonghanlee/epicsarchiverap-env/actions/workflows/macOS.yml)
[![Linter Run](https://github.com/jeonghanlee/epicsarchiverap-env/actions/workflows/linter.yml/badge.svg)](https://github.com/jeonghanlee/epicsarchiverap-env/actions/workflows/linter.yml)

Configuration Environment for [EPICS Archiver Appliance](https://github.com/slacmshankar/epicsarchiverap) for [the Advanced Light Source Upgrade (ALS-U) Project](https://als.lbl.gov/als-u/overview/) at [Lawrence Berkeley National Laboratory](https://lbl.gov). Please check [the latest discussions for your own customizations.](https://github.com/jeonghanlee/epicsarchiverap-env/discussions/14)

## Please

One should understand that 
- This reposiotry is a **simple tool** to help users to setup, maintain, and upgrade EPICS archiver appliance easily.
- This repository does **NOT** support multiple archiver instances.
- Archiving data is a very unique asset, which one has to handle seriously. 
- I do not understant them all, but I want, and I am learning it continously still today.

## Pre-requirement packages

```bash
git make sudo which
```

## Debian 10/11 (EOL: 2024-06-01/2026-08-15)

### Preparation

```bash
make init
scripts/required_pkgs.sh
```

### MariaDB

I assume that Debian 10/11 are the fresh installation version.

```bash
sudo systemctl start mariadb
sudo systemctl status mariadb
#
make db.secure
make db.addAdmin
make db.show
make db.create
make db.show
make sql.fill
make sql.show
```

### Build, install, and Service

```
make build
make install
make exist
#
make sd_start
make sd_status
```

## CentOS7 (EOL: 2024-06-30)

See [docs/README.centos7.md](docs/README.centos7.md).

## ~~CentOS8 (EOL: 2021-12-31)~~

~~See [docs/README.centos8.md](docs/README.centos8.md).~~

## Rocky8 (EOL: 2029-05-31)

See [docs/README.rocky8.md](docs/README.rocky8.md).

## macOS (BigSur 11.6.1, 20G224)

See [docs/README.macos.md](docs/README.macos.md).

## Descriptions

### Install required packages

```bash
scripts/required_pkgs.sh
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

### EPICS Environment Variables

The default EPICS Environment Variables are defined as

```bash
% make vars FILTER=EPICS_

EPICS_CA_ADDR_LIST = localhost
EPICS_CA_AUTO_ADDR_LIST = YES
EPICS_CA_MAX_ARRAY_BYTES = 16384
```

Please see `configure/CONFIG_EPICSENV`. After deployment, one changes `archappl.conf` file in `INSTALL_LOCATION`, and restart it through systemd service or its master script. Note all 4 services should be restarted.


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

[1] [Jave Environment](https://github.com/jeonghanlee/java-env)

[2] [End Of Life Date](https://endoflife.date)
