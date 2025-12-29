# Archiver Appliance for ONLY CentOS 7

This is the CentOS 7 (AltArch) specific installation guide. 

## Init

```bash
$ make init
```

## Packages, and MariaDB, and Tomcat

I assumed that CentOS7 is the fresh installation version.

```bash
$ make install.pkgs
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
$ make centos7.conf
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
