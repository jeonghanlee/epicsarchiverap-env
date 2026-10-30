# EPICS Archiver Appliance Configuration Environment with MAVEN

This repository provides the configuration environment for the [EPICS Archiver Appliance with MAVEN](https://github.com/jeonghanlee/epicsarchiverap-maven). Makefiles and scripts fetch the source, build the four web applications, prepare the configuration database and install the appliance as a systemd service on Debian 13, Rocky Linux 8, Rocky Linux 10.2, Ubuntu 24.04 LTS and Ubuntu 26.04 LTS.

The source repository builds with Maven and stays close to the community version of the Archiver Appliance. See that repository for the build system and its differences.

**Release**: [2.0.1](https://github.com/jeonghanlee/epicsarchiverap-env/releases/tag/2.0.1); the changes are in [CHANGELOG.md](CHANGELOG.md). Implementation status and observed verification results are recorded in the [work register](docs/milestone-9576820.md).

## Install and look at an appliance on this host

The fastest way to see an appliance run is the SQLite installer. It needs no database server. Clone the repository at the release tag:

```bash
git clone --branch 2.0.1 https://github.com/jeonghanlee/epicsarchiverap-env.git
cd epicsarchiverap-env
```

Then follow the page [Install an appliance with SQLite](https://jeonghanlee.github.io/epicsarchiverap-env/install/sqlite.html), or start with the plan, which lists every step without running it:

```bash
bash scripts/install-local-sqlite.bash --plan
```

Run an installer as the ordinary checkout owner with `sudo` rights; it uses `sudo` for the privileged steps and installs the packages it needs, JDK 21 among them. Each installer supports `--plan`.

| Configuration database | Installer script | Page |
| :--- | :--- | :--- |
| SQLite | `scripts/install-local-sqlite.bash` | [Install an appliance with SQLite](https://jeonghanlee.github.io/epicsarchiverap-env/install/sqlite.html) |
| MariaDB over a Unix socket | `scripts/install-local-mariadb-uds.bash` | [Install an appliance with MariaDB over a Unix socket](https://jeonghanlee.github.io/epicsarchiverap-env/install/mariadb-uds.html) |
| MariaDB over TCP | `scripts/install-local-mariadb-tcp.bash` | [Install an appliance with MariaDB over TCP](https://jeonghanlee.github.io/epicsarchiverap-env/install/mariadb-tcp.html) |

A MariaDB installer reads the passwords of the database accounts, `DB_ADMIN_PASS` and `DB_USER_PASS`, from `../CONFIG_SITE.local`. The defaults are fixed values for a first trial, so set both before the first run, as the page of the installer describes.

After the installation, the management interface is at `http://localhost:17665/mgmt/ui/index.html`. The installer checks the four JVMs, the storage use, the component startup states and the appliance information. An optional test archives a PV and reads the stored samples back; it needs EPICS Base with `softIoc` and `caget`.

To update a host that runs an appliance, read [Reinstall or upgrade an appliance](https://jeonghanlee.github.io/epicsarchiverap-env/install/reinstall.html) first.

## Follow the procedure with make

The page [Build and install stages of the repository](https://jeonghanlee.github.io/epicsarchiverap-env/understand/build-and-install.html) lists the stages in order with the `make` target of each stage. The [ordered sequence](docs/README.install.md#ordered-sequence) gives the privilege, the inputs and the check of every step. To build another source commit, read [Select the source commit to build](https://jeonghanlee.github.io/epicsarchiverap-env/build/select-commit.html).

## Where to read more

* The [book of the appliance](https://jeonghanlee.github.io/epicsarchiverap-env/): concepts, install and operate procedures, reference tables and a glossary.
* The [install guide](docs/README.install.md): configuration variables, site inputs, reinstall and upgrade, health checks.
* The [script reference](scripts/README.md): the Bash scripts, the supported operating systems and the optional soft IOC test.
* The [policies guide](docs/README.policies.md) and the [data journey](docs/README.DataJourney.md): storage tiers and the movement of data.
* The [management interface](docs/README.interface.md): the site skin and the checks of the interface files; it points to the description of the pages.

## Scope

This repository covers the local installation of the appliance with SQLite or MariaDB, the build of its web applications and the systemd service and health timer.

**Out of scope:**
* Archiving policy configuration and storage tier tuning; see [docs/README.policies.md](docs/README.policies.md).
* Data lifecycle and ETL behavior over time; see [docs/README.DataJourney.md](docs/README.DataJourney.md).
* The upstream community build process; see [archiver-appliance/epicsarchiverap](https://github.com/archiver-appliance/epicsarchiverap).
