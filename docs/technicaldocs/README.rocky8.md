# Archiver Appliance for ONLY Rocky 8 

This is the Rocky 8.4 (Green Obsidian) specific installation guide. Technically, CentOS8 is the same one, but some make rules are not supported. Please use Debian 11 or Rocky 8. 

## Init

```bash
$ make init
```

## Packages, and MariaDB, and Tomcat

I assumed that Rocky 8 is the fresh installation version.

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
