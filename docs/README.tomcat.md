# Tomcat on CentOS8

CentOS has no tomcat packages which we can install through the package management.
So we have to setup the Tomcat9 by ourselves.

It may works with Debian 10, but we prefer the Debian package instead of this.

## Predefine variables

```bash
$ make vars FILTER=TOMCAT_

------------------------------------------------------------
>>>>          Current Envrionment Variables             <<<<
------------------------------------------------------------

TOMCAT_HOME = /usr/share/tomcat9
TOMCAT_INSTALL_LOCATION = /opt/tomcat9
TOMCAT_MAJOR_VER = 9
TOMCAT_MINOR_VER = 0.37
TOMCAT_SRC = apache-tomcat-9.0.37.tar.gz
TOMCAT_URL = "https://downloads.apache.org/tomcat/tomcat-9/v9.0.37/bin/apache-tomcat-9.0.37.tar.gz"
TOMCAT_VER = 9.0.37
```

## Setup

```bash
make tomcat.get
make tomcat.install
make tomcat.sd_start
make tomcat.sd_status
```
