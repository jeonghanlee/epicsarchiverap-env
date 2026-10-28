# Prepare the host for the appliance

The installers expect the packages of the host operating system. The script `scripts/install_os_packages.bash` resolves a package list for the host from `configure/os/<os>.pkgs` and installs it with the package manager. When the host already provides the prerequisites, skip this page: the installers accept `--skip-packages` and use the host as it is. The SQLite installer also installs the packages itself when you run it without `--skip-packages`, so an SQLite reader can skip this page. The script of this page installs the MariaDB packages as well. The [glossary](../appendix/glossary.md) explains the terms of this page.

## Prerequisites

- A host that runs Debian 13, Rocky Linux 8, Rocky Linux 10.2, Ubuntu 24.04 or Ubuntu 26.04. The script names them `debian13`, `rocky8`, `rocky10`, `ubuntu24` and `ubuntu26`. The package script selects the list by the major version for Debian and Rocky Linux, and by the exact version 24.04 or 26.04 for Ubuntu. The installers accept Rocky Linux 10.2 and no other Rocky Linux 10 release.
- `sudo` rights, for the step that installs the packages.

## Steps

1. Print the packages that the script resolves for this host. The command needs no root privilege.

   ```bash
   bash scripts/install_os_packages.bash --list-only
   ```

   On Debian 13 the output is:

   ```text
   wget
   curl
   jq
   git
   sed
   gawk
   unzip
   make
   gcc
   tree
   mariadb-server
   mariadb-client
   libmariadb-dev
   libmariadb-dev-compat
   sqlite3
   openjdk-21-jdk-headless
   chrony
   ```

2. Optional: compare with the list of another operating system. The option `--os <os_id>` selects the list.

   ```bash
   bash scripts/install_os_packages.bash --list-only --os rocky8
   ```

   The output is one line per package. On Rocky Linux 8 it contains `java-21-openjdk`, `java-21-openjdk-devel`, `mariadb-server`, `sqlite` and `chrony`, among others.

3. Install the packages with root privilege. The script asks for a confirmation first.

   ```bash
   sudo bash scripts/install_os_packages.bash
   ```

   The option `-f` (`--force`) skips the confirmation prompt, for unattended runs. The script runs `apt-get update -y` and `apt-get install -y` on Debian and Ubuntu, and `dnf install -y` on Rocky Linux, so the host needs network access. The list holds the MariaDB packages for every database backend. For SQLite, run the SQLite installer without `--skip-packages` instead of this script, because the installer leaves those packages out. The list includes `mariadb-server` and `chrony`; installing `chrony` can replace another time daemon, as [Changes that the installer makes on the host](host-changes.md) describes.

## Verification

Check that the Java Development Kit (JDK) package of the host is installed. On Debian 13, Ubuntu 24.04 and Ubuntu 26.04, run:

```bash
dpkg-query -W openjdk-21-jdk-headless
```

The command prints the package name and its version. The version starts with 21:

```text
openjdk-21-jdk-headless:<arch>	<version>
```

On Rocky Linux 8 and Rocky Linux 10.2, run:

```bash
rpm -q java-21-openjdk-devel
```

The command prints the package with its version, in the form `java-21-openjdk-devel-21.<update>-<release>.<arch>`.

The installers select the `JAVA_HOME` of the operating system in their first `make` step, `make <os>.conf`. Before that step, `make -s print-JAVA_HOME` prints the path of Debian 13.
