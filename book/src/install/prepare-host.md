# Prepare the host for the appliance

The installers expect the packages of the host operating system. The script `scripts/install_os_packages.bash` resolves a package list for the host from `configure/os/<os>.pkgs` and installs it with the package manager.

## Prerequisites

- A host that runs Debian 13, Rocky Linux 8, Rocky Linux 10, Ubuntu 24.04 or Ubuntu 26.04. The script names them `debian13`, `rocky8`, `rocky10`, `ubuntu24` and `ubuntu26`.
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

3. Install the packages with root privilege: run the script of step 1 with `sudo` and without `--list-only`. The option `-f` (`--force`) skips the confirmation prompt, for unattended runs.

4. Optional: when the host provides the prerequisites, skip this page. The installers accept `--skip-packages` and use the host as it is.

## Verification

Check that the Java installation that the repository uses is present and is version 21. The variable `JAVA_HOME` in `configure/CONFIG_SITE` names it.

```bash
$(make -s print-JAVA_HOME)/bin/java -version
```

The first line of the output names a Java 21 runtime, in this form:

```text
openjdk version "21.<update>" <release_date>
```
