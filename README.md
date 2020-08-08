# EPICS Archiver Appliance Configuration Environment

Configuration Environment for EPICS Archiver Appliance at <https://github.com/slacmshankar/epicsarchiverap>

## Requirements

* Debian 10

```bash
make install.pkgs
```

### MariaDB

* JDBC connector

It is inside the site specific building procedure, so don't need to do anything.

* Create the DB and itsuser : `archappl`

If the MariDB has already `admin` account, please use it with the modification in `configure/CONFIG_COMMOM`.
With the admin account, create `db` and `user` for the archiver appliance.

```bash
make db.create
```

* Create and fill the tables

```bash
make sql.fill
```

Please see [docs/README.mariadb.md](docs/README.mariadb.md) for the further information.

### JAVA and Ant

We can use the local JAVA and Ant environments. The java 11/12 and Ant.

See [docs/README.javapkgs.md](docs/README.javapkgs.md)

## TL;DR

```bash
$ make init
$ make build
$ make install
$ make exist LEVEL=2
tree -pugaL 2 /opt/epicsarchiverap
/opt/epicsarchiverap
├── [-rwxr-xr-x tomcat   tomcat  ]  appliances.xml
├── [-rwxr-xr-x tomcat   tomcat  ]  archappl.conf
├── [-rwxr-xr-x tomcat   tomcat  ]  archappl.properties
├── [drwxr-xr-x tomcat   tomcat  ]  engine
│   ├── [drwxr-xr-x tomcat   tomcat  ]  bin
│   ├── [drwxr-xr-x tomcat   tomcat  ]  conf
│   ├── [drwxr-xr-x tomcat   tomcat  ]  logs
│   ├── [drwxr-xr-x tomcat   tomcat  ]  policy
│   ├── [drwxr-xr-x tomcat   tomcat  ]  temp
│   ├── [drwxr-xr-x tomcat   tomcat  ]  webapps
│   └── [drwxr-xr-x tomcat   tomcat  ]  work
├── [drwxr-xr-x tomcat   tomcat  ]  etl
│   ├── [drwxr-xr-x tomcat   tomcat  ]  bin
│   ├── [drwxr-xr-x tomcat   tomcat  ]  conf
│   ├── [drwxr-xr-x tomcat   tomcat  ]  logs
│   ├── [drwxr-xr-x tomcat   tomcat  ]  policy
│   ├── [drwxr-xr-x tomcat   tomcat  ]  temp
│   ├── [drwxr-xr-x tomcat   tomcat  ]  webapps
│   └── [drwxr-xr-x tomcat   tomcat  ]  work
├── [drwxr-xr-x tomcat   tomcat  ]  mgmt
│   ├── [drwxr-xr-x tomcat   tomcat  ]  bin
│   ├── [drwxr-xr-x tomcat   tomcat  ]  conf
│   ├── [drwxr-xr-x tomcat   tomcat  ]  logs
│   ├── [drwxr-xr-x tomcat   tomcat  ]  policy
│   ├── [drwxr-xr-x tomcat   tomcat  ]  temp
│   ├── [drwxr-xr-x tomcat   tomcat  ]  webapps
│   └── [drwxr-xr-x tomcat   tomcat  ]  work
├── [-rwxr-xr-x tomcat   tomcat  ]  policies.py
├── [drwxr-xr-x tomcat   tomcat  ]  retrieval
│   ├── [drwxr-xr-x tomcat   tomcat  ]  bin
│   ├── [drwxr-xr-x tomcat   tomcat  ]  conf
│   ├── [drwxr-xr-x tomcat   tomcat  ]  logs
│   ├── [drwxr-xr-x tomcat   tomcat  ]  policy
│   ├── [drwxr-xr-x tomcat   tomcat  ]  temp
│   ├── [drwxr-xr-x tomcat   tomcat  ]  webapps
│   └── [drwxr-xr-x tomcat   tomcat  ]  work
└── [-rw-r--r-- tomcat   tomcat  ]  .versions
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

### Rules
