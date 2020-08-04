# JAVA Local Configuration

```bash
Usage    : scripts/install_java_pkgs_local.bash <pkg> <dest>

          <pkg>

          ant     : ant     1.10.8
          maven   : maven   3.6.3
          jdk11   : openjdk 11
          jdk12   : openjdk 12

          <dest>

                : /home/jhlee/gitsrc/epicsarchiverap-env/scripts/JAVA
```

## Ant

```bash
bash scripts/install_java_pkgs_local.bash ant
```

## OpenJDK

* OpenJDK11

```bash
bash scripts/install_java_pkgs_local.bash jdk11
```

* OpenJDK12

```bash
bash scripts/install_java_pkgs_local.bash jdk12
```

## Maven

```bash
bash scripts/install_java_pkgs_local.bash maven
```

## Vars

```bash
bash $ bash scripts/install_java_pkgs_local.bash vars

MAVEN_HOME:=$(TOP)/JAVA/maven
ANT_HOME:=$(TOP)/JAVA/ant
JAVA_HOME:=$(TOP)/JAVA/openjdk_your_install_version
```

## Installation Location

```bash
$ tree -L 1 JAVA/
JAVA/
├── [jhlee      61]  ant -> /home/jhlee/gitsrc/epicsarchiverap-env/JAVA/apache-ant-1.10.8
├── [jhlee    4.0K]  apache-ant-1.10.8
├── [jhlee    4.0K]  apache-maven-3.6.3
├── [jhlee    4.0K]  jdk-11
├── [jhlee    4.0K]  jdk-12
├── [jhlee      62]  maven -> /home/jhlee/gitsrc/epicsarchiverap-env/JAVA/apache-maven-3.6.3
├── [jhlee      50]  openjdk11 -> /home/jhlee/gitsrc/epicsarchiverap-env/JAVA/jdk-11
└── [jhlee      50]  openjdk12 -> /home/jhlee/gitsrc/epicsarchiverap-env/JAVA/jdk-12
```

## Makefile Rule

There are two versions of OpenJDK, 11 and 12. That version `JAVA_LOCAL_VER` can be selected within `configure/CONFIG_COMMON`. The default one is `11`.

```bash
$ make install.jdk
OpenJDK will be in /home/jhlee/gitsrc/epicsarchiverap-env/JAVA/openjdk11
/home/jhlee/gitsrc/epicsarchiverap-env/JAVA
├── ant -> /home/jhlee/gitsrc/epicsarchiverap-env/JAVA/apache-ant-1.10.8
├── apache-ant-1.10.8
├── apache-maven-3.6.3
├── jdk-11
├── jdk-12
├── maven -> /home/jhlee/gitsrc/epicsarchiverap-env/JAVA/apache-maven-3.6.3
├── openjdk11 -> /home/jhlee/gitsrc/epicsarchiverap-env/JAVA/jdk-11
└── openjdk12 -> /home/jhlee/gitsrc/epicsarchiverap-env/JAVA/jdk-12

$ make conf.jdk
>>> Generating /home/jhlee/gitsrc/epicsarchiverap-env/configure/CONFIG_COMMON_JDK.local
     1  JAVA_HOME:=/home/jhlee/gitsrc/epicsarchiverap-env/JAVA/openjdk11
     2  JAVA_PATH:=/home/jhlee/gitsrc/epicsarchiverap-env/JAVA/openjdk11/bin

```
