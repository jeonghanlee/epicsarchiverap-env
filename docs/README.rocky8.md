# Archiver Appliance for ONLY Rocky 8 

This is the Rocky 8.4 (Green Obsidian) specific installation guide. Technically, CentOS8 is the same one, but some make rules do not support. Please use Debian 11 or Rocky 8 instead. 


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
$ make tomcat.sd_start
$ make tomcat.sd_status
```

## Build, Install, and Systemd services 

```bash
$ make build
$ make install
$ make sd_start
$ make sd_status
```

## Warning

Please change the default user account and its passowrd  for MariaDB, and so on.


/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el8_4.x86_64/
