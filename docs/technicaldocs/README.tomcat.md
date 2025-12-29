# Tomcat9

We need more time to migrate to Tomcat10, so here how configure the Tomcat 9

## Predefine variables

```bash
epicsarchiverap-env (master)$ make vars FILTER=TOMCAT

------------------------------------------------------------
>>>>          Current Envrionment Variables             <<<<
------------------------------------------------------------

TOMCAT_DEFAULT_PORT = 8083
TOMCAT_DEFAULT_SERVER_XML = server.xml
TOMCAT_HOME = /opt/tomcat9
TOMCAT_INSTALL_LOCATION = /opt/tomcat9
TOMCAT_MAJOR_VER = 9
TOMCAT_MINOR_VER = 0.87
TOMCAT_SRC = apache-tomcat-9.0.87.tar.gz
TOMCAT_URL = "https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.87/bin/apache-tomcat-9.0.87.tar.gz"
TOMCAT_VER = 9.0.87
```

## Setup

```bash
make tomcat.get
make tomcat.install
make tomcat.exist
```

### Tomcat service
Note that the Tomcat service itself isn't necessary for the Archiver Appliance.
However, one would like to use the native tomcat 9 service, please check `configure/RULES_TOMCAT` file.
There are several make rules may help to set up them correctly.


## Tomcat Generic Service

The Archiver Appliance uses the following port numbers

```bash
16670 : cluster inet port
17665 : mgmt url
17666 : engine url
17667 : etl url
```

However, the genric tomcat stil uses 8080, which has the conflict with our another services, Payara and ChannelFinder services, so we would like to change it 8083 in case one would like to use the tomcat native service for other purpose.

Debian 10, the generic `server.xml` is located in `/etc/tomcat9`, and replace `8080` with `8083`.

```xml
    <Connector port="8083" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
```
