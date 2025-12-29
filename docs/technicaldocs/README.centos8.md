# Archiver Appliance for ONLY CentOS 8 

**CentOS Linux 8 will reach End of Life (EOL) on December 31st, 2021. Please decide which OS you should use wisely.**

This is the CentOS 8 specific installation guide.

## Prerequirements

```bash
dnf install -y sudo which git make wget
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
