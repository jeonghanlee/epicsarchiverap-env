# CentOS 8

Please don't use CentOS 8, which is going to end its role. I will update this if I see the Rocky Linux Distribution officially <https://rockylinux.org/>.

## Step 0

```bash
dnf config-manager --enable PowerTools
dnf update

git clone https://github.com/jeonghanlee/epicsarchiverap-env

make init
make install.pkgs
```

## Step 1

This step only be necessary if one would like to use the CentOS packages java environment. The default java version change due to local configuration `make centos8.conf`.

```bash
echo 2 | sudo update-alternatives --config java
```

* MariaDb

Note that one should check the MariaDB status via `sudo systemctl start mariadb`.

```bash
make db.secure
make db.addAdmin
make db.show
make db.create
make db.show
make sql.fill
make sql.show
```

* CentOS8 Specific Configuration

```bash
make centos8.conf         : Only and if Only one would like to use the CentOS 8 java envrionment.
make tomcat.get           : Download the selected Tomcat 9 version. Please check `configure/CONFIG_TOMCAT` for other version.  
make tomcat.install       : This also changes the Tomcat default server port to 8083.
make tomcat.sd_start
make tomcat.sd_status
```

## Step 2

```bash
make build
make install
make sd_start
make sd_status
```

## Error Messages

Local Ant and JAVA configuration returns the following error message:

```bash
>>> Ant  information
Ant : /opt/java-env/ANT1108/bin/ant
/usr/bin/build-classpath: Could not find jaxp_parser_impl Java extension for this JVM
/usr/bin/build-classpath: Could not find xml-commons-apis Java extension for this JVM
/usr/bin/build-classpath: error: Some specified jars were not found
Apache Ant(TM) version 1.10.5 compiled on June 24 2019
```

This error may be ignored when we are running the archiver appliance.
