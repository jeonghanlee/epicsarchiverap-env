# Archiver Appliance on Rocky Linux 8

This page lists what is specific to Rocky Linux 8.x. The installation steps, the options and the checks are those of [the installation guide](../README.install.md); this page names the Rocky values and states what the recorded verification covers.

## Verified configuration

The VM acceptance tests install and run the appliance on fresh Rocky Linux 8.10 guests with three database configurations: SQLite, MariaDB over a Unix domain socket and MariaDB over TCP. Each case installs through the ordered Make sequence with explicit environment and source commits, and checks the installed WARs and configuration, the four JVMs, the scheduled health runs, HTTP identity, acquisition and retrieval of a test PV, persistence across a restart and a forced reinstall. A further Rocky 8.10 case with an absent source commit must fail the installation. The design of the tests is in [VM installation and runtime tests](../README.vmtests.md); the observed results are in the milestone register.

The three local entry scripts of the installation guide accept Rocky Linux 8.x and select the same preset. The recorded verification runs the ordered Make sequence on Rocky 8.10, not the entry scripts. Other Rocky 8 minor releases use the same preset without a recorded run.

## Values of the Rocky preset

| Item | Value |
| --- | --- |
| Preset | `rocky8`; `make rocky8.conf` writes `configure/CONFIG_SITE.local` to include `configure/os/rocky8.mk` |
| Package manager | `dnf` |
| Package list | `configure/os/rocky8.pkgs`, which names `java-21-openjdk`, `java-21-openjdk-devel`, `mariadb-server`, `sqlite`, `chrony` and the build tools |
| JDK 21 directory | `/usr/lib/jvm/java-21-openjdk` |
| Default MariaDB socket | `/var/lib/mysql/mysql.sock` |
| SQLite package | `sqlite` |

The following command prints the packages that the script resolves for Rocky Linux 8 without installing anything and without root privilege:

```bash
bash scripts/install_os_packages.bash --list-only --os rocky8
```

## Database credentials

The defaults in `configure/CONFIG_SITE` (`DB_ADMIN_PASS`, `DB_USER_PASS`) are fixed values of the repository. Set your own in `../CONFIG_SITE.local` before the MariaDB configurations, as the installation guide describes. The SQLite configuration needs no database account.
