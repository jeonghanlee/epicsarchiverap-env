# EPICS Archiver Appliance Configuration Environment

## Configuration

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

### Stroage

```bash
$ make stroage.build
$ make stroage.show
/home/jhlee/ArchiverAppliance
├── [drwxr-xr-x tomcat   tomcat  ]  lts
├── [drwxr-xr-x tomcat   tomcat  ]  mts
└── [drwxr-xr-x tomcat   tomcat  ]  sts
```

## Build
