# Archiver Appliance for ONLY macOS 11.6.1

This is the macOS 11.6.1 specific installation guide.  

## Init

```bash
$ make init
```

## Packages, and MariaDB, and Tomcat

The **port** and **brew** package management shall be used. 

```bash
$ bash scripts/required_pkgs.sh
```

### Configure MariaDB

* port

```bash
#
$ sudo port unload mariadb-10.5-server
$ sudo vi /opt/local/etc/mariadb-10.5/my.cnf
# Use default MacPorts settings
!include /opt/local/etc/mariadb-10.5/macports-default.cnf
[mariadb]
skip-networking = 0
bind-address = 127.0.0.1
port = 3306
$ sudo port load mariadb-10.5-server
```

* brew

```bash
$ sudo vi /opt/homebrew/etc/my.cnf
[mariadb]
skip-networking = 0
bind-address = 127.0.0.1
port = 3306
$ brew services restart mariadb
```
* Check its status

```bash
$ netstat -an |grep LISTEN
$ nmap -sT -sV localhost -p 3306
```

### Update DB for Archiver Appliance

```bash
$ make db.secure
$ make db.addAdmin
$ make db.show
$ make db.create
$ make db.show
$ make sql.fill
$ make sql.show
#
# Select one of port or brew
# port
$ make macport.conf
# brew
$ make macbrew.conf
#
$ make tomcat.action
$ make tomcat.exist
```

## Build and Install 

```bash
$ make build
$ make src_install
$ make services.install
$ make exist
```

## Run, status, and stop

```bash
bash /opt/epicsarchiverap/archappl.bash startup
bash /opt/epicsarchiverap/archappl.bash status
bash /opt/epicaarchiverap/archappl.bash stop
```

|![AAZ](images/macos.png)|
| :---: |
|**Figure 1** Archiver Appliance Home Page Screenshot on macOS.|


## Launchctrl

Note that the following rules are developing and they do not work. Please don't use this.


```bash
make conf.launch
make conf.launch.show
make install.launch
make install.launch.show
make launchctl_load
make launchctl_unload
```

* Check the launch service 

```bash
make stop
make launchctl_unload
make launchctl_load
make status
```

Note that at this moment, start and stop are not intergrated fully. One can stop the service through `archappl.bash shutdown`.

## Warning

Please change the default user account and its password for MariaDB, and so on.
