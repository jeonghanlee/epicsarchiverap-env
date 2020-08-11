# CentOS 8

## Step 0

```bash
dnf config-manager --enable PowerTools
dnf update

git clone https://github.com/jeonghanlee/epicsarchiverap-env

make init
make install.pkgs
```

## Step 1

We may not need the default java version change due to local configuration `make centos8.conf`

```bash
echo 2 | sudo update-alternatives --config java
```

* MariaDb

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
make centos8.conf
make tomcat.get
make tomcat.install
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
