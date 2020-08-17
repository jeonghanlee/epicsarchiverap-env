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

## Tomcat Generic Service

The Archiver Appliance uses the following port numbers

```bash
16670 : cluster inet port
17665 : mgmt url
17666 : engine url
17667 : etl url
```

However, the genric tomcat stil uses 8080, which has the conflict with our another services, Payara and ChannelFinder services, so we would like to change it 8083.

Debian 10, the generic `server.xml` is located in `/etc/tomcat9`, and replace `8080` with `8083`.

```xml
    <Connector port="8083" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
```
