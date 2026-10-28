# Clean install of release 2.0.1 on six configurations

Report date: 2026-10-28

## Scope

This report records the method and the results of six installations of the candidate for release 2.0.1 on fresh guests, and of two further installations on fresh guests that hold EPICS Base, each followed by the optional soft input/output controller (IOC) test. Each of the first six guests starts from a cloud image with no Java, no SQLite client and no MariaDB. The installation follows the install pages of the book step by step, and the verification of the pages closes each check. The raw logs are not retained; the report keeps the statistics and the method.

A configuration is one operating system with one configuration database. The six configurations are Debian 13 and Rocky Linux 8.10, each with SQLite, with MariaDB over a Unix socket and with MariaDB over TCP. The Java Development Kit (JDK) is version 21. The web application archive (WAR) files are built from the source tag `2026-10` by the installer.

Times are UTC. Sizes of memory are in MiB (1,048,576 bytes).

**Out of scope:** an upgrade over an existing appliance and the installer options `--tomcat existing`, `--tomcat replace` and `--existing-db`, because they act on a host that holds an appliance, a Tomcat or a database, which a fresh install does not have; the data path under load, which the report of the 903-PV day run covers; and the verdict on the release, which belongs to the owner and is entered in the work register.

## Subject

| Item | Value |
| :--- | :--- |
| Repository, branch and commit | this repository, branch `release-2.0.1`, commit `3185bb05b7131540ec8887f9462eb3124406f6a0` |
| Source tag and commit | `2026-10`, commit `e0a8e66e` |
| Version string of every installed appliance | `Archiver Appliance Version e0a8e66e, built 2026-10-28` |
| Guests | one fresh guest per configuration, 2 virtual CPUs, 4,096 MiB assigned (3,903 MiB visible on Debian, 3,665 MiB on Rocky Linux), 20 GiB root disk, key-only SSH for the user `vmadmin` with `sudo` |
| Operating systems | Debian GNU/Linux 13 (trixie), Rocky Linux 8.10 (Green Obsidian); Rocky Linux runs with SELinux in Enforcing mode; `firewalld` is inactive on the three clean Rocky Linux guests and active on the Rocky Linux guest of the soft IOC check |
| Installers | `scripts/install-local-sqlite.bash`, `scripts/install-local-mariadb-uds.bash`, `scripts/install-local-mariadb-tcp.bash` |
| Guests of the soft IOC check | two fresh guests built from golden images that hold EPICS Base 7.0.10 (EPICS-env 1.2.2) and no Java, SQLite or MariaDB; one Debian 13, one Rocky Linux 8.10; the images were built on 2026-08-31 from the same Debian 13 and Rocky Linux 8 base images as the other guests |
| MariaDB server | 11.8.6 on Debian 13, 10.3.39 on Rocky Linux 8.10 |
| JDK | 21.0.13 on Debian 13, 21.0.12 on Rocky Linux 8.10 |

## Method

Each configuration runs on its own guest. A person follows the install pages and enters every command over SSH; no driver script and no configuration management tool installs anything. The steps are the same for each guest.

1. Record the time, `/etc/os-release`, the root disk, the memory, the files under `/opt` and `/arch`, and whether `git`, `make`, `java`, `sqlite3`, `mysql`, `python3` and `tree` exist.
2. Clone this repository from GitHub, check out the commit of the Subject table, and require `git status` to show no change.
3. Prepare the host. The SQLite installer runs without `--skip-packages` and installs its packages itself. For MariaDB, run `scripts/install_os_packages.bash -f`, then check the JDK package (`dpkg-query -W openjdk-21-jdk-headless` on Debian, `rpm -q java-21-openjdk-devel` on Rocky Linux) and the state of `mariadb.service`.
4. For MariaDB, write `DB_ADMIN_PASS` and `DB_USER_PASS` as random values into `../CONFIG_SITE.local` with the mode 600. The values are not recorded. For TCP, print `DB_HOST_NAME` and `DB_HOST_PORT` with `make -s`; they are `127.0.0.1` and `3306`.
5. Print the plan of the installer with `--plan`, with `--skip-packages` for MariaDB, and compare it with the sample plan of the page.
6. Run the installer with `-y` in a detached session on the guest and log to a file. A poll reads the log every 20 seconds until the line `exit=` appears. The run time is the span from the start of the command to the poll that sees the line, so it has a resolution of 20 seconds.
7. Verify with the checks that the pages document: the readiness block of the installer; `archappl.bash health` run as `tomcat` (exit status 0); the `startupState` of the four components; `getApplianceInfo` identity and version; the unit states and the restart counter; the store folders and their owner. For MariaDB, also the tables of the database `archappl`, the accounts with their hosts, the URL in `mgmt/conf/context.xml`, and the socket or the TCP listener. For Rocky Linux, also `getenforce`, `ausearch -m avc -ts boot` and the count of the lines `which: no tree` in the installer log.

The soft IOC check uses a guest with EPICS Base and the SQLite installer. Steps 1 and 2 are the same, followed by `bash scripts/verify-local-pv.bash --check-epics --epics-bin <epics_bin_dir>`. The installer runs without `-y` on a terminal, with `EPICS_BASE` exported. The answers are `y` to the offer of the PV test, `y` to the installation, and `1` to the choice after the test, which stops the soft IOC. On the Debian 13 guest the answer `1` was not sent; the client closed the connection while the installer waited for it. The installer then installs its packages, builds, installs and starts the appliance, starts the soft IOC on the loopback interface, registers one unique PV, reads the stored samples back as comma-separated values (CSV) and compares them with the values that Channel Access (CA) reports.

On the first guest, a failure-path check follows: the file `../CONFIG_SITE.local` sets `SRC_TAG` to a commit that does not exist, and the installer runs with `-y --skip-packages` on the installed appliance.

## Result per configuration

Each installer of the six clean installations ends with exit status 0, and every installer of this report prints the message `Installation completed. All required installation checks passed.` Every configuration reports `archappl.bash health` with exit status 0, the four `startupState` values `STARTUP_COMPLETE`, the identity `appliance0`, the version string of the Subject table, active units for the appliance and the health timer, and a restart counter of 0.

| Configuration | Installer start | Installer end observed | Run time | Packages installed by |
| :--- | :--- | :--- | :--- | :--- |
| Debian 13, SQLite | 00:44:42 | 00:49:20 | at most 4 min 38 s | installer |
| Debian 13, MariaDB socket | 00:55:32 | 00:59:37 | 4 min 5 s | `install_os_packages.bash -f`, then installer |
| Debian 13, MariaDB TCP | 01:04:50 | 01:10:11 | 5 min 21 s | `install_os_packages.bash -f`, then installer |
| Rocky 8.10, SQLite | 01:14:35 | 01:20:56 | 6 min 21 s | installer |
| Rocky 8.10, MariaDB socket | 01:26:42 | 01:30:22 | 3 min 40 s | `install_os_packages.bash -f`, then installer |
| Rocky 8.10, MariaDB TCP | 01:34:57 | 01:39:18 | 4 min 21 s | `install_os_packages.bash -f`, then installer |

All times are on 2026-10-28. For Debian 13 with SQLite, the end time is the limit of the watch and the installer finished at or before it. The host step for MariaDB takes 30 to 40 seconds on Rocky Linux and installs 17 packages from the list of the operating system.

| Configuration | Database observed | Connection observed |
| :--- | :--- | :--- |
| SQLite | the file `archappl.sqlite` under `/arch/config` (listed on Debian 13); no database account exists | none |
| Debian 13, MariaDB socket | tables `ArchivePVRequests`, `ExternalDataServers`, `PVAliases`, `PVTypeInfo`; accounts `admin` and `archappl` at `localhost` | URL `jdbc:mariadb://localhost/archappl?localSocket=/run/mysqld/mysqld.sock`; `tomcat` reaches the socket |
| Debian 13, MariaDB TCP | the same four tables; accounts at `127.0.0.1` | URL `jdbc:mariadb://127.0.0.1:3306/archappl`; MariaDB listens on `127.0.0.1:3306` |
| Rocky 8.10, MariaDB socket | the same four tables; accounts at `localhost` | URL `jdbc:mariadb://localhost/archappl?localSocket=/var/lib/mysql/mysql.sock`; `tomcat` reaches the socket |
| Rocky 8.10, MariaDB TCP | the same four tables; accounts at `127.0.0.1` | URL `jdbc:mariadb://127.0.0.1:3306/archappl`; MariaDB listens on all addresses, port 3306 |

On the four MariaDB configurations, the file `mgmt/conf/context.xml` has the mode 644. On the two TCP configurations, the management port listens on all addresses. Both points are documented in the page on host changes.

### Soft IOC check on two guests with EPICS Base

| Guest | Installer and PV test | Stored samples | Latest matched sample |
| :--- | :--- | :--- | :--- |
| Debian 13, SQLite | installer completed; `PV acquisition, storage and retrieval: PASS` | 3, matching changing CA values | 2026-10-28T01:58:11Z |
| Rocky 8.10, SQLite | installer completed; `PV acquisition, storage and retrieval: PASS` | 3, matching changing CA values | 2026-10-28T03:26:11Z |

Both guests report `archappl.bash health` with exit status 0, four `startupState` values `STARTUP_COMPLETE`, the version string of the Subject table and a restart counter of 0. On Rocky Linux, no soft IOC process remains after the choice `1`; on Debian 13, none remains after the client closed the connection, and the exit status of that installer is not recorded. The Rocky Linux guest runs SELinux in Enforcing mode with `firewalld` active, and `ausearch -m avc -ts boot` returns no match. The first installer run on the Rocky Linux guest stops during `prerequisites` with exit status 1, as Observation 4 describes; the run reported here is the second.

### Failure path on Debian 13 with SQLite

The installer stops with `Installation stopped during source selection (exit 2). Data and build files are retained.` and the message `No rollback or automatic restart is attempted.` The appliance unit stays active and `health` reports all four processes after the failed run. The page on the SQLite installation describes this stop.

### Rocky Linux

SELinux is in Enforcing mode on all four Rocky Linux guests. `ausearch -m avc -ts boot` returns no match after each installation, so no access denial occurs during the installation or the start of the services.

## Differences between the operating systems

The installers behave the same on both operating systems. The install pages describe the first three differences below.

| Point | Debian 13 | Rocky Linux 8.10 |
| :--- | :--- | :--- |
| `mariadb.service` after the package step | active | inactive; the installer starts it |
| Default socket | `/run/mysqld/mysqld.sock` | `/var/lib/mysql/mysql.sock` |
| Listener of the MariaDB package | `127.0.0.1:3306` | all addresses, port 3306 |
| `python3` on the blank guest | not recorded | absent; no step needs it |
| Lines `which: no tree` in the installer log | 0 | 28 on SQLite, where `tree` is not installed before the Make steps; 0 on the MariaDB configurations, where the host step installs `tree` first |

## Observations

1. The lines `which: no tree` appear on a blank Rocky Linux guest when the installer runs before `tree` exists. They come from a Make rule that calls `which tree`, and they do not change an exit status. The installer log of the SQLite configuration holds 28 such lines.
2. The distribution package of MariaDB on Rocky Linux 8 listens on all addresses, because `bind-address` is a comment in `/etc/my.cnf.d/mariadb-server.cnf`. The application accounts exist for `127.0.0.1` only, and `firewalld` is inactive on the guest. The page on host changes lists the listener under the points that a site hardens itself.
3. After the PV test the installer asks `Select [1/2]`: `1` stops the soft IOC and leaves the test PV paused (the default), `2` resumes the PV and keeps the IOC. The pages on the three installers and on the reinstall describe this choice.
4. The first run of the installer on the Rocky Linux guest with EPICS Base stops with `Installation stopped during prerequisites (exit 1)`. The command `dnf install -y 1 gcc ...` receives an extra first argument `1` and answers `No match for argument: 1`. The run sent the third answer `1` to the terminal together with the first two. The second run sent that answer after the PV test and passes. The command that prints the package list returns a correct list when it runs alone with the same pending input, so the cause is not found.

## Limits

- Each configuration ran once, on one guest; the soft IOC check on Rocky Linux ran twice (Observation 4).
- The six clean installations cover installation, start and the documented verification. PV acquisition, storage and retrieval are checked only by the soft IOC check on two guests with the SQLite installer, one per operating system, with three stored samples each.
- The versions of MariaDB and JDK are those that the repositories of each distribution held on 2026-10-28.
- Rocky Linux 10.2, Ubuntu 24.04 and Ubuntu 26.04 are not part of this run.
- The installer option `--socket` with a path other than the default of the operating system is not part of this run.
