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
$ 
#$ make db.secure
#$ make db.addAdmin
#$ make db.show
#$ make db.create
#$ make db.show
#$ make sql.fill
#$ make sql.show
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

## Warning

Please change the default user account and its password for MariaDB, and so on.
