# EPICS Archiver Appliance Configuration Environment

## Configuration

```bash
make init
```

## Requirements

* Debian 10

```bash
make install.pkgs
```

### MariaDB

See [docs/README.mariadb.md](docs/README.mariadb.md)

* Setup the MariaDB JDBC connector

```bash
$ make get.jdbc
Downloading JDBC connector ...
$ make install.jdbc
Copying mariadb-java-client-2.3.0.jar to /usr/share/tomcat9/lib/

```

### JAVA, and Ant

See [docs/README.javapkgs.md](docs/README.javapkgs.md)

## Build

* Generate all configuration files, and prepare the storage space, and build the archiver appliance

```bash
make build
```

which contains three rules such as `conf.archapplproperties`, `conf.storage`, and `build.ant`

## Install

```bash
make install
```
