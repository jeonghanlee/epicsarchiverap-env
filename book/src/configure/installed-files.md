# Files of an installation

This page lists what `make install` puts on the host, and where each file comes from. Paths below `AA_INSTALL_LOCATION` (default `/opt/epicsarchiverap-maven`) are relative to it.

## Below the installation directory

| Path | Content | Source in the repository |
| :--- | :--- | :--- |
| `archappl.conf` | Shared environment of the four instances | `site-template/archappl.conf.in` |
| `appliances.xml` | Identity and addresses of the components | `site-template/appliances.xml.in` |
| `archappl.properties` | Engine and retrieval properties | `site-template/archappl.properties.in` |
| `policies.py` | Storage policies and store uniform resource locators (URLs) | `site-template/policies.py.in` |
| `archappl.bash` | The control script: `startup`, `shutdown`, `restart`, `service`, `status`, `storage`, `health`, `loglevel`, `help` | `scripts/archappl.bash` |
| `<component>/` | One Tomcat instance for each of `mgmt`, `engine`, `etl` and `retrieval` | `site-template/skel` and the rules below |

The files `archappl.properties` and `policies.py` belong to the service account (`AA_USERID`, default `tomcat`).

## Inside one instance

For each component the installer creates the folder with `conf`, `logs`, `webapps`, `work` and `temp`, copies `site-template/skel` into it, installs the payload, and then sets the owner to `AA_USERID:AA_GROUPID`.

| Path | Content |
| :--- | :--- |
| `conf/server.xml` | Tomcat configuration of the instance; `serverxml.install` writes the port of the component into it |
| `conf/context.xml` | Database resource definition, generated from `site-template/context.xml.in` (or `context-sqlite.xml.in`) |
| `conf/<component>.conf` | Per-component Java options, from `site-template/<component>.conf` |
| `bin/startup.sh`, `bin/shutdown.sh`, `bin/run.sh`, `bin/setenv.sh` | Start and stop scripts of the instance, generated from the `.in` files of `site-template` |
| `log4j/` | `log4j2-tomcat.xml`, the logging configuration of the instance, and the log4j JAR files that `scripts/install-payload.bash` copies there |
| `policy/catalina.policy` | Tomcat security policy file |
| `webapps/<component>/` | The web application: the exploded web application archive (WAR) of the component, which `scripts/install-payload.bash` replaces from the WAR in `target/` of the source |

## The systemd service files

| Path | Content | Source |
| :--- | :--- | :--- |
| `/etc/systemd/system/epicsarchiverap-maven.service` | The appliance service | `site-template/systemd/epicsarchiverap-maven.service.in` |
| `/etc/systemd/system/epicsarchiverap-maven-health.service` | The health check that the timer runs | `site-template/systemd/epicsarchiverap-maven-health.service.in` |
| `/etc/systemd/system/epicsarchiverap-maven-health.timer` | The timer of the health check | `site-template/systemd/epicsarchiverap-maven-health.timer.in` |
| `/etc/systemd/system/tomcat9.service.d/override.conf` | Drop-in for the `tomcat9` service | `site-template/systemd/override.conf.in` |

`make install` enables `epicsarchiverap-maven.service` and the health timer. It does not start the service; the installers start it afterwards with `make sd_start`.

## Outside the installation directory

| Path | Content | Set by |
| :--- | :--- | :--- |
| `/arch/sts/ArchiverStore`, `/arch/mts/ArchiverStore`, `/arch/lts/ArchiverStore` | The three stores | `ARCHAPPL_STORAGE_TOP` and the three folder variables |
| `/arch/config/archappl.sqlite` | The configuration database of the SQLite backend | the SQLite installer |
| the MariaDB database `archappl` | The configuration database of the MariaDB backend | `DB_NAME` |

An uninstall (`make uninstall`) stops and disables the service and the health timer, removes the service file and the two health unit files, and deletes `AA_INSTALL_LOCATION`. It does not remove the stores or the database; [Changes that the installer makes on the host](../install/host-changes.md) lists what else stays.
