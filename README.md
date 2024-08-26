# EPICS Archiver Appliance Configuration Environment

Configuration Environment for [Customized or Legacy EPICS Archiver Appliance](https://github.com/jeonghanlee/epicsarchiverap) for [the Advanced Light Source Upgrade (ALS-U) Project](https://als.lbl.gov/als-u/overview/) at [Lawrence Berkeley National Laboratory](https://lbl.gov). Please check [the latest discussions for your own customizations.](https://github.com/jeonghanlee/epicsarchiverap-env/discussions/14)


## Debian 12
will use a manually downloaded version of tomcat9, installed to /opt/tomcat9

### Pre-requirement packages

```bash
make init
scripts/required_pkgs.sh
```

### MariaDB

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

### Tomcat 9

```
make vars FILTER=TOMCAT
make tomcat.get
make tomcat.install
make tomcat.installmdb # will install mariadb jdbc connector to tomcat's libs
make tomcat.exist
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

### Switch between different source commits

First, update `SRC_TAG` in `configure/RELEASE`, then `make srcupdate`

