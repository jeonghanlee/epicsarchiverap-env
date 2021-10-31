# Archiver Appliance for ONLY CentOS 8 

This is the CentOS 8 specific installation guide. One may need to check Rocky 8 instead of CentOS 8.

## Prerequirements

```bash
dnf install -y sudo which git make
```

## Init

```bash
$ make init
```

## Packages, and MariaDB, and Tomcat

I assumed that CentOS 8 is the fresh installation version.

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
$ make centos8.conf
$ make tomcat
$ make tomcat.sd_start
$ make tomcat.sd_status
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
