# Archiver Appliance for ONLY Rocky 8 

This guide describes the Rocky Linux 8 configuration. The package list is a first-pass port using JDK 21; a complete Rocky installation is not covered by the recorded Debian verification.

## Init

```bash
$ make init
```

## Packages, and MariaDB, and Tomcat

I assumed that Rocky 8 is the fresh installation version.

```bash
$ sudo bash scripts/install_os_packages.bash --os rocky8
$ sudo systemctl start mariadb
$ sudo systemctl status mariadb
# 
$ make db.secure
$ make db.addAdmin
$ make db.show
$ make db.create
$ make db.show
$ make sql.fill
$ make sql.show
#
$ make rocky8.conf
$ make tomcat
```

## Build, Install, and Systemd services 

```bash
$ make build
$ make install
$ make exist
#
$ make sd_start
$ make sd_status
```

## Warning

Please change the default user account and its password for MariaDB, and so on.
