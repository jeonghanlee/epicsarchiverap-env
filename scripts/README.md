# Local Installation Scripts

These scripts install a systemd-managed EPICS Archiver Appliance on Debian 13
or Rocky Linux 8. Choose one entry script for the required database connection.
All three use [install-local-common.bash](install-local-common.bash), the
configured source pin, and the `als` site configuration.

| Entry script | Database connection |
| --- | --- |
| [install-local-sqlite.bash](install-local-sqlite.bash) | SQLite file selected by `ARCHAPPL_SQLITE_FILE` |
| [install-local-mariadb-uds.bash](install-local-mariadb-uds.bash) | MariaDB Unix domain socket selected by `--socket`, `DB_SOCKET`, or the OS default |
| [install-local-mariadb-tcp.bash](install-local-mariadb-tcp.bash) | MariaDB at `127.0.0.1`, using `DB_HOST_PORT` |

Run an entry script as the ordinary checkout owner with `sudo` access.
Keep storage, Tomcat, service-account, and database settings in
`../CONFIG_SITE.local`, relative to the repository root.
Read the [installation procedure](../docs/README.install.md#local-systemd-installation)
for prerequisites, configuration placement, and database preparation before
confirming installation.

## Preview and Run

From the repository root, print the plan for your selected mode. The following
commands are alternatives; run only the line matching your choice:

```bash
bash scripts/install-local-sqlite.bash --plan
bash scripts/install-local-mariadb-uds.bash --plan
bash scripts/install-local-mariadb-tcp.bash --plan
```

The plan reads configuration and checks existing source inputs without changing
files, building, or starting services. To install, run the same entry script
without `--plan` and review the confirmation before answering `y`:

```bash
bash scripts/install-local-sqlite.bash
bash scripts/install-local-mariadb-uds.bash
bash scripts/install-local-mariadb-tcp.bash
```

The installer prepares packages, selects the source pin, prepares Tomcat 9, and
builds the appliance. When reusing Tomcat, it then stops an installed appliance, prepares the
database, replaces the payload, starts the service and health timer, and checks
startup readiness. PV acquisition and retrieval require the separate
[functional verification](../docs/README.install.md#functional-verification).

MariaDB installation creates or updates the configured database and accounts,
including existing account passwords and grants. `--existing-db` skips that
provisioning; schema loading still runs, and `DB_USER_PASS` must match the
existing application account. Failures after the appliance stop can leave it
stopped or partly replaced; there is no automatic rollback.

If the checkout owner cannot execute existing Tomcat, installation offers two
choices: check and use it as the service account, or back it up and install the
configured version. Use `--tomcat existing` or `--tomcat replace` to select
explicitly for unattended installation. Replacement stops an installed appliance
and retains the original default Tomcat directory in a unique sibling backup.
The menu marks replacement unavailable for custom, symlink, or overlapping paths.
Replacement refuses a Tomcat directory containing the checkout, or overlapping
the source checkout, appliance install directory, archive root, any archive tier,
or SQLite file. These checks run before download or service shutdown and resolve
symlink aliases in the protected paths. Existing
Tomcat checks require both read and execute access to `catalina.sh` as the
service account.

Each entry script accepts `--help`. See the
[installation options](../docs/README.install.md#local-systemd-installation)
for `--tomcat`, `--skip-packages`, `--socket`, `--existing-db`, `--timeout`, and `--yes`.
