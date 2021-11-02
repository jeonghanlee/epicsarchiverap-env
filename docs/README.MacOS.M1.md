# Archiver Appliance for ONLY macOS 11.6.1

This is the macOS 11.6.1 specific installation guide (WIP).  

## Init

```bash
$ make init
```

## Packages, and MariaDB, and Tomcat

The default **port** package management shall be used. 

```bash
$ make install.pkgs
```

### Configure MariaDB

```bash
$ sudo port unload mariadb-10.5-server
$ sudo vi /opt/local/etc/mariadb-10.5/my.cnf
# Use default MacPorts settings
!include /opt/local/etc/mariadb-10.5/macports-default.cnf

[mysqld]
skip-networking=0
bind-address=localhost
```

```bash
$ sudo port load mariadb-10.5-server 
$ make db.secure
$ make db.addAdmin
$ make db.show
$ make db.create
$ make db.show
$ make sql.fill
$ make sql.show


#
$ make macos.conf
$ make tomcat.action
$ make tomcat.exit
```

## Build and Install 

```bash
$ make build
$ make src_install
$ make services.install
$ make exist
```

## Run

```bash
sudo bash /opt/epicsarchiverap/archappl.bash startup
sudo bash /opt/epicsarchiverap/archappl.bash status
```

## Warning

Please change the default user account and its password for MariaDB, and so on.
