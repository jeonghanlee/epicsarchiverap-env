# Non-Interactive Install Sequence

Linear, non-interactive procedure to build and run the Archiver Appliance from
this environment on a pre-provisioned host, so an automation role drives the
`make` targets without reading the Makefiles. It covers the ordered targets, the
privilege boundary of each, the inputs each consumes, the paths each writes, and
the check that proves it ran.

For a local host whose prerequisites and database are not provisioned, use the
entry scripts below. The manual ordered sequence assumes host-provided
prerequisites and accounts.

## Local systemd installation

The three entry scripts share `scripts/install-local-common.bash` and install
a systemd-managed appliance with the `als` site configuration. They use the
source that `SRC_TAG` selects and the installation paths resolved from Make settings. A plain run of a script installs the OS packages and selects the OS preset, fetches the source, prepares Tomcat, builds the source, renders the units, stops an installed appliance and its health monitor, prepares the database (for MariaDB it starts `mariadb.service` and, unless `--existing-db` is given, creates the database if it is absent and prepares the accounts), loads the schema, prepares the storage folders (`make conf.storage`), installs the appliance and starts it; `--skip-packages` omits only the installation of the OS packages, not the selection of the OS preset, and `--plan` runs none of them. With `--tomcat replace` the appliance and its health monitor are stopped before the build. A failure between the stop and the start leaves the appliance stopped, and a failure of the startup verification, which includes the start, leaves the installed files and the service as they are; the script neither rolls back nor stops nor restarts it.

Prerequisites:

- Debian 13, Rocky Linux 8, Rocky Linux 10.2, Ubuntu 24.04 LTS or Ubuntu 26.04 LTS with systemd running.
  See the [OS defaults](../scripts/README.md#supported-os-defaults) for exact
  detected versions, package managers, JDK paths, and socket paths.
- An ordinary checkout owner with `sudo` access; do not run an entry script as root. The script authenticates `sudo` once at the start (`sudo -v`) and does not refresh the timestamp, but uses `sudo` throughout, also after a build that can take several minutes. Once the timestamp has expired, a later `sudo` asks for the password again, as the first `sudo` after a long build does, and the Tomcat access checks, which run `sudo -n` before the build, stop with an error instead of asking, for example after a slow download. For an unattended run (`--yes`, no terminal) configure `sudo` without a password prompt for the checkout owner; without it `sudo -v` fails at the start, before any change.
- `bash`, `make`, `git`, and `realpath` for preflight; `sudo` and `flock` for installation.
- Network access for OS packages, source Git fetches, Tomcat downloads, and Maven dependencies.
- Storage, Tomcat, service-account, and database settings in
  `../CONFIG_SITE.local`, as described in [configuration variable placement](#configuration-variable-placement).
  Select a different source through the supported RELEASE overrides.
- A clean source checkout, if one exists. Tracked or staged changes and
  untracked files stop preflight. Generated `src/sitespecific/als` files and
  ignored build outputs are allowed; ignored inputs under `src` or `.mvn` are rejected.

1. Choose one database mode and review its inputs.

   | Entry script | Connection and preparation |
   | --- | --- |
   | `install-local-sqlite.bash` | Uses `ARCHAPPL_SQLITE_FILE`, loads the SQLite schema as the service account, and excludes MariaDB packages from installation |
   | `install-local-mariadb-uds.bash` | Uses `--socket`, then `DB_SOCKET`, then the OS default socket; starts MariaDB and prepares accounts at `localhost` |
   | `install-local-mariadb-tcp.bash` | Clears `DB_SOCKET`, requires `DB_HOST_NAME=127.0.0.1`, uses `DB_HOST_PORT`, and prepares accounts at `127.0.0.1` |

   The default UDS path is `/run/mysqld/mysqld.sock` on Debian 13 or Ubuntu 24.04/26.04 and
   `/var/lib/mysql/mysql.sock` on Rocky Linux 8 or 10.2. The service account must be able
   to reach and write the socket. The script does not configure MariaDB's listener.

   MariaDB starts `mariadb.service` and, unless `--existing-db` is given, creates
   `DB_NAME` if it is absent and prepares `DB_ADMIN` and `DB_USER` with
   `GRANT ... IDENTIFIED BY` and the configured passwords. An account that does not
   exist is created (`DB_ADMIN` receives `GRANT ALL ON *.* ... WITH GRANT OPTION`,
   server-wide), and an existing account of the same user and host receives the
   configured password. `DB_ADMIN_PASS` and `DB_USER_PASS` default to the public
   values `admin` and `archappl`, so set both in `../CONFIG_SITE.local` before
   confirming; otherwise a production account with another password loses it. The
   accounts are at `localhost` for the UDS script and at `DB_HOST_NAME` for the TCP
   script: an account at the other host is not touched, and a new one is created.
   Default account preparation requires local root socket authentication, for UDS as
   well as for TCP. For TCP, the root socket server's port must match `DB_HOST_PORT`.
   The schema is loaded with `CREATE TABLE IF NOT EXISTS` and drops nothing.

2. In the environment checkout, print the plan for the selected mode. These are
   alternatives; run only the line matching your choice:

   ```bash
   bash scripts/install-local-sqlite.bash --plan
   bash scripts/install-local-mariadb-uds.bash --plan
   bash scripts/install-local-mariadb-tcp.bash --plan
   ```

   `--plan` reads configuration and checks an existing source checkout. It prints
   the steps without installing packages, changing files, building, or starting
   services. It does not establish that the host is ready for installation.

3. In the same checkout, start the selected installer and review its confirmation
   before answering `y`. Run only one of these alternatives:

   ```bash
   bash scripts/install-local-sqlite.bash
   bash scripts/install-local-mariadb-uds.bash
   bash scripts/install-local-mariadb-tcp.bash
   ```

   Packages and the OS preset are prepared first. The script selects the source
   that `SRC_TAG` names, prepares Tomcat 9, generates configuration, and builds before stopping an
   installed appliance when reusing Tomcat. Tomcat replacement stops the appliance
   earlier, before moving the shared Tomcat directory. The installer requires the appliance to be stopped before database
   preparation and payload replacement, then starts the appliance and health timer.
   The OS preset rewrites `configure/CONFIG_SITE.local`; keep site overrides in
   `../CONFIG_SITE.local`.

   | Option | Behavior |
   | --- | --- |
   | `--plan` | Prints steps without executing installation |
   | `-y`, `--yes` | Skips the installation confirmation, which for MariaDB also carries the warning about the existing accounts, and the optional PV test; required with non-interactive stdin |
   | `--skip-packages` | Uses host-provided prerequisites: JDK 21, the commands `curl`, `jq`, `unzip`, `sha512sum`, `systemctl` and `timeout`, and `sqlite3`, `lsof`, `runuser` for SQLite or `mysql` for MariaDB; the script stops when one command is missing |
   | `--tomcat existing` | Uses existing Tomcat after checking access and version as the service account |
   | `--tomcat replace` | Backs up the default Tomcat directory and installs the configured version; stops an installed appliance before the backup |
   | `--socket <socket_path>` | UDS only: selects an absolute socket path without whitespace |
   | `--existing-db` | MariaDB only: skips account/database provisioning; still starts `mariadb.service` and loads the schema |
   | `--timeout <seconds>` | Sets the startup verification deadline from 1 to 86400 seconds; default 180 |
   | `-h`, `--help` | Prints usage and option descriptions |

   With `--existing-db`, the database and the application account must already exist,
   the account must accept `DB_USER_PASS` over the transport (the installer creates it
   at `localhost` for UDS and at `DB_HOST_NAME` for TCP); if the connection fails, the
   schema step fails after the appliance has been stopped. The unit must be called
   `mariadb.service`. The flag preserves account
   configuration, not database contents: schema loading runs in both modes.
   Existing archive stores and database files remain during payload replacement.
   An unavailable default Tomcat installation is downloaded and checked against
   Apache's SHA-512 before extraction; a custom `TOMCAT_HOME` must already contain Tomcat 9.

   If the checkout owner cannot execute an existing `bin/catalina.sh`, the
   installer offers two choices: use Tomcat after checking service-account
   access, or back it up and install the configured version. Select explicitly
   with `--tomcat existing` or `--tomcat replace` when using `--yes`.
   Existing Tomcat is checked as `AA_USERID`, including access to
   execute and read `catalina.sh`, read `setclasspath.sh`, and inspect the
   Tomcat 9 version in `catalina.jar`.
   Replacement supports only the default `TOMCAT_HOME`, without symlink paths.
   It rejects a Tomcat directory containing the environment checkout, or
   overlapping the source checkout, appliance install directory, archive root,
   STS/MTS/LTS directories, or SQLite file. Protected paths are resolved through
   symlinks before comparison. Rejection occurs before download or service shutdown.
   The choice menu marks replacement unavailable for other paths before asking
   for a selection; existing Tomcat can still be checked with choice 1.
   The download and checksum check precede appliance shutdown. The original
   directory is moved to `<TOMCAT_HOME>.backup.<unique-id>/tomcat`; its path is
   printed and retained on failure. Replacement stops the appliance and health
   monitor before moving Tomcat, so a later build failure can leave the appliance
   stopped. Backup restoration is manual.

Verification: a successful run prints `Installation completed.` and displays the
management UI, four component startup API URLs, process/storage health, the
repeat health command, and the information API URL, appliance identity, and version.
The default UI URL is `http://localhost:17665/mgmt/ui/index.html`; `/mgmt/ui`
is a directory, not the page URL. The information API is
`http://localhost:17665/mgmt/bpl/getApplianceInfo` with the default port.
It checks process health as the service account, all four JSON `startupState`
responses for `STARTUP_COMPLETE`, valid appliance information, and active
appliance and health timer units within the startup deadline.
Waiting messages report outstanding checks when they change, without repeating
the full health output or raw information JSON.

If verification fails, the installer displays the last observed results for
each component, process identities, storage, service, timer, and information API.
It also displays the management UI and a journal command with `sudo`.
Service and timer checks distinguish observed inactivity (`NOT ACTIVE`),
query failure (`INSPECTION ERROR` with the diagnostic), and deadline expiry
(`TIMED OUT`). A failed query does not establish that the unit is inactive.
Early signal termination reports `INSPECTION ERROR` with its exit status.
Health inspection also distinguishes early signal termination from deadline expiry.
Successful component startup does not imply that the storage check passes.
For example, 93% filesystem usage fails the default 85% storage limit even
when all four components have started and the information API responds.
The installer identifies this as a storage failure and exits nonzero.
Installed files and data remain; it does not stop or restart the appliance
after verification fails, delete data, or raise the storage limit.
Make space available on the affected filesystem or relocate the archive stores
before repeating verification.

Interactive installation offers an optional test of one changing soft IOC PV.
The choice is made before installation. Selecting the test requires an exported
`EPICS_BASE` with executable `softIoc` and `caget`; otherwise the installer stops
before installing packages and asks the user to source their EPICS environment
setup file in the same terminal, then rerun. The installer never sources that
file itself. The selected test runs after appliance startup succeeds.
The test registers the PV using Bash and `curl`, then uses the selected source's
`getDataToCsv.bash` to check stored samples against actual CA observations.
See [soft IOC verification](../scripts/README.md#verify-one-changing-pv) for
EPICS prerequisites, retained evidence, the keep/stop choice, and unattended use.
Skipping the test leaves acquisition, storage, and retrieval marked `NOT CHECKED`.
Its failure is separate from installation completion. The installer exits 0 after
successful installation even when the optional test fails.
Interrupting post-install verification reports the interruption separately and
preserves the installation completion message.
Perform the separate [functional verification](#functional-verification) for
broader acceptance.

On installation failure, the script exits nonzero and reports the error. Once installation
begins, it also names the failed step. It retains data and build files and
performs no automatic rollback or restart. A failure
after the appliance stop can leave it stopped or partly replaced; resolve the
reported failure before repeating installation or starting the service.

## Architecture

- This repository, `epicsarchiverap-env` (aa-env in this guide), clones the source repository (https://github.com/jeonghanlee/epicsarchiverap-maven) and drives its Maven Wrapper build, then
  installs four Tomcat instances under a single systemd service: `mgmt` (17665),
  `engine` (17666), `etl` (17667), `retrieval` (17668).
- The source WARs are built for the `als` site by default (`ARCHAPPL_SITEID=als`). The local installers fix `ARCHAPPL_SITEID=als` on every Make command line, so
  they install only that site; for another site, run the [ordered sequence](#ordered-sequence) with the settings of
  [Site inputs](#site-inputs). The site overlay is copied into the source tree automatically before the
  build, so each WAR carries the `classpathfiles` of the selected site.
- The runtime uses the shared Tomcat as a read-only `CATALINA_HOME`; each
  instance is a writable `CATALINA_BASE` under the install location.

## Host prerequisites (provided by the host, not by aa-env)

- JDK 21 with `JAVA_HOME` at the distribution path.
- Tomcat 9.0.121 as a shared `CATALINA_HOME` at `/opt/tomcat9`, readable and
  executable by the service user (dirs `r-x`, `bin/*.sh` executable, `lib/*.jar`
  readable). No Tomcat service runs; aa-env uses the binaries only.
- For the MariaDB backend (`DB_BACKEND=mariadb`, the default): MariaDB reachable
  over the IPv4 loopback (`127.0.0.1:3306`, `skip-name-resolve` on), with the
  configuration database and the application account already created (account
  host-spec `@'127.0.0.1'`; password equal to `DB_USER_PASS`, set in
  Configuration below). With `DB_SOCKET` set, MariaDB is reached over that
  Unix domain socket instead, and the account host-spec is `@'localhost'`.
- For the SQLite backend (`DB_BACKEND=sqlite`): the `sqlite3` command-line tool
  and `lsof` for open-file inspection (package `sqlite` on Rocky Linux 8 or 10.2, `sqlite3` on Debian 13 or Ubuntu 24.04/26.04) and no MariaDB.
  A host that also carries `mariadb-server` from the per-OS package list need
  not enable it.
- Build tools: `git`, `make`, `unzip`, `sed`, `tree`, and `curl` or `wget`.
  The launcher's `loglevel` command needs `curl` on the appliance host.
  `scripts/install_os_packages.bash` is skipped when the host supplies these.
- Linux process monitoring requires Bash 4.4 or newer, coreutils and readable
  `/proc` process state, executable links and arguments for the service account.
- Outbound network for the build: the `git` clone of the source, and the Maven
  Wrapper (3.9.16) plus dependency downloads into a cold `~/.m2`.
- A filesystem for the archive store (`ARCHAPPL_STORAGE_TOP`, `/arch` by
  default) other than the root filesystem and outside any user home, sized by
  the site. `make conf.storage` warns, and still succeeds, when the store shares
  the root filesystem or lies under `/home`, `/root` or the home of the user
  running it. These checks and service-account ownership apply to the archive
  root and each configured STS, MTS and LTS directory, including paths outside
  the root. The health timer reports `FAIL storage-threshold` once any checked
  filesystem reaches `ARCHAPPL_STORAGE_ALARM_PERCENT` (default 85, set
  in `../CONFIG_SITE.local`). To change it on an installed host, edit
  `../CONFIG_SITE.local`, then run `make conf.archapplproperties`. Apply it
  using the [reinstall procedure](#reinstall-and-upgrade): stop the appliance,
  install, then start it after installation succeeds. Each health check reads
  the installed `archappl.conf` anew; this installation procedure also replaces
  the WARs and logging JARs and therefore requires an appliance stop.
- The service group and user (`AA_GROUPID`, `AA_USERID`) may be pre-created; the
  install leaves an existing group/user unchanged.

### Memory budget for a test VM

The VM test default is `AA_JAVA_HEAPSIZE="256M"` per instance. Each of the four
JVMs receives `-Xms256M -Xmx256M` and `-XX:MaxMetaspaceSize=256M`.

| Memory setting | Per JVM | Four JVMs |
| --- | --- | --- |
| Initial heap (`-Xms`) | 256 MiB | 1 GiB |
| Maximum heap (`-Xmx`) | 256 MiB | 1 GiB |
| Maximum metaspace | 256 MiB | 1 GiB |
| Maximum heap plus maximum metaspace | 512 MiB | 2 GiB |

`-Xms` and `-Xmx` describe the same heap and must not be added together. The
heap calculation is `4 * 256 MiB = 1024 MiB = 1 GiB`; adding the four metaspace
limits gives `4 * (256 + 256) MiB = 2048 MiB = 2 GiB`. These are configured
limits, not measured memory usage or a cap on total process memory.

For a VM with 4 GiB of RAM, subtracting those two regions leaves
`4 GiB - 2 GiB = 2 GiB` for JVM native allocations, thread stacks, code caches,
MariaDB, the OS and filesystem caching. That remainder is a budget to verify,
not a guarantee that the workload fits. On a VM reporting 3.58 GiB of actual
guest RAM, the same calculation leaves approximately 1.58 GiB, so use measured
guest RAM rather than the VM's nominal allocation.

The [loaded heap report](reports/heap-soak-20260928.md) records operator-reported
100, 500 and 903 PV runs with 256 MiB heap overrides, including six hours of
concurrent retrieval. A separate default-install check confirmed that all four
JVMs receive the shipped 256 MiB setting. Together these satisfy the amended
[heap verification criterion](milestone-2.0.0.md#m22---size-the-jvm-heap-default-to-the-host).
The measurements do not establish production capacity or an optimal heap size:
post-GC retained heap and individual GC pauses were not measured. Validate the
intended workload before using this value as an operating default.

Set `AA_JAVA_HEAPSIZE` in `../CONFIG_SITE.local` when the measured workload
needs a different heap. Both heap options follow this value; for example,
`512M` means 2 GiB of heap across four instances, plus up to 1 GiB of metaspace.

## Configuration (variable placement)

`DB_NAME` selects the MariaDB database and defaults the JDBC resource name.
`JDBC_DB_NAME`, if explicitly overridden, names both the resource in
`context.xml` and the runtime `ARCHAPPL_DB_NAME` lookup. Keep it aligned with
the intended database. Database passwords are rendered as XML attribute data
and quoted shell values; shell metacharacters remain literal. In Make override
files, use `$$` for a literal dollar and `\#` for a literal hash.

- `configure/RELEASE.local`: `SRC_TAG` — the source reference for
  https://github.com/jeonghanlee/epicsarchiverap-maven (a commit, tag, or branch). The default is
  the tag `2026-10`: the installer fetches origin and checks out that tag. A site that
  follows the branch tip sets `origin/master`, and a build of one fixed commit sets its hash. `SRC_URL` has a default (`https://github.com/jeonghanlee`) and
  is overridden here only when the source is hosted elsewhere. This file is not
  rewritten by the per-OS config targets. The selected source must carry the management interface,
  which it does from `d0932d1b`; the installers stop with `The selected source does not carry the
  management interface` otherwise. It must also be at or after
  `67be91d7`: from `9bbd69bf` the build writes `target/tomcat-log4j`, which
  `make install` requires and stops without, and from `67be91d7` every WAR
  carries the `log4j2.xml` that formats application lines. An older source
  installs without that file, and application lines then run unconfigured.
- `../CONFIG_SITE.local` (one directory above the checkout top): `AA_USERID`,
  `AA_GROUPID`, `DB_NAME`, `DB_USER`, `DB_USER_PASS`, `DB_HOST_NAME` (`127.0.0.1`),
  `DB_HOST_PORT`, and any `ARCHAPPL_*` overrides. This file is included first and
  survives the per-OS config target that rewrites `configure/CONFIG_SITE.local`.
  Write each value in the form that `configure/CONFIG_SITE` uses for it: `make` keeps quote characters
  as part of a value, so `DB_HOST_NAME="127.0.0.1"` makes `db.create` fail with `ERROR 2005` and
  `DB_HOST_NAME=127.0.0.1` works.
- Configuration database: `DB_BACKEND` is `mariadb` (default) or `sqlite`, set
  in `../CONFIG_SITE.local`; any other value stops step 3
  (`make conf.archapplproperties`), so the sequence goes no further, and
  `make conf.install` also stops before it renders the unit. With `sqlite`, the
  database is the file `ARCHAPPL_SQLITE_FILE`, by default
  `$(ARCHAPPL_STORAGE_TOP)/config/archappl.sqlite`
  (`/arch/config/archappl.sqlite`), owned by the service account. It sits under
  the store, so `make conf.storage.rm`, which removes `ARCHAPPL_STORAGE_TOP`,
  removes the configuration database too. SQLite supports schema loading,
  table queries, all-user-table deletion, database-file lifecycle, backup and
  restore through the existing Make targets and database helper. Only
  `db.conf` and `db.conf.show` skip SQLite; account/server actions reject it.
  Offline operations require the appliance and its health units to be stopped.
  Read the [database operation reference](technicaldocs/README.mariadb.md#backend-operation-contract)
  before database maintenance. Invalid backends fail before configuration
  writes or database contact.
- MariaDB transport: `DB_SOCKET` is empty by default, which connects over TCP to
  `DB_HOST_NAME:DB_HOST_PORT`. Set it in `../CONFIG_SITE.local` to the server's
  Unix domain socket (`/var/lib/mysql/mysql.sock` on Rocky Linux 8 or 10.2,
  `/run/mysqld/mysqld.sock` on Debian 13 or Ubuntu 24.04/26.04, or the path the provisioning sets)
  and every MariaDB connection uses it: the appliance through a `localSocket`
  URL in `context.xml`, and `db.secure`, `db.addAdmin`, `db.create`,
  `sql.fill`, `sql.show` and the backup commands of
  `scripts/mariadb_setup.bash`. MariaDB names a socket client's host
  `localhost`, so `make db.create` then grants `DB_USER` at `localhost`, and a
  provisioned account must be `@'localhost'`. The appliance connects as the
  service account (`AA_USERID`), so the socket and its directory must be
  reachable by that account; the distribution defaults are. The server may
  then run with `skip-networking`. After changing `DB_SOCKET`, run step 2 (`make db.conf`)
  and step 3 again, then follow the [reinstall procedure](#reinstall-and-upgrade)
  on an installed host. Stop the appliance before step 8 (`make install`, which
  also replaces the WARs), then start it after installation succeeds.
  `DB_SOCKET` is ignored for `sqlite`.
- Toolchain: `JAVA_HOME` is set through the OS preset
  (`make <os>.conf`, with `<os>` one of `debian13`, `rocky8`, `rocky10`, `ubuntu24` and `ubuntu26`, the five
  local-install systems, or `debian12`, which has a preset but no package list,
  writes `configure/CONFIG_SITE.local` to include `configure/os/<os>.mk`), or
  set in `../CONFIG_SITE.local`. The five local-install presets
  preserve a custom `JAVA_HOME`; `JAVA_PATH` follows it unless overridden.
  `--skip-packages` does not skip the preset. `TOMCAT_HOME` defaults to
  `TOMCAT_INSTALL_LOCATION`, which follows `AA_INSTALL_PATH` unless explicitly
  overridden. OS presets preserve both Tomcat path overrides. Do not place
  overrides in `configure/CONFIG_SITE.local` when `make <os>.conf` is used, since
  that target overwrites the file.

### Maven flags and proxy settings

`MAVEN_FLAGS` supplies Maven command-line arguments to `clean.mvn`, `build.mvn`,
`build.mvn2`, `build.mvn3`, `build.war`, and `build.mvndeps`. Its default is empty.
Set it in `../CONFIG_SITE.local`, or pass it as a Make command-line override.

Migrate existing `MAVEN_OPTS` assignments used for command-line flags in local
Make settings or `make` invocations to `MAVEN_FLAGS`. There is no compatibility
alias. The standard `MAVEN_OPTS` environment variable remains for Maven's JVM
options, such as `-Xmx512m`; do not put Maven command-line flags in it.

For Maven dependency downloads through a proxy, configure the `<proxies>`
section in an existing Maven settings file. Select an alternate global settings
file with `-gs`, for example in `../CONFIG_SITE.local`:

```makefile
MAVEN_FLAGS := -B -ntp -gs /absolute/path/maven-settings.xml
```

Use an absolute settings-file path because these targets run Maven from the
source checkout. The environment does not generate or supply that file.
`MAVEN_FLAGS` selects the file; the proxy configuration belongs inside it.
Do not rely on shell proxy variables or JVM proxy properties as a portable
replacement for Maven settings. These settings cover Maven dependency
resolution, not Git or Maven Wrapper distribution downloads.

### Site inputs

The folder `site-template/siteid` holds the inputs of the selected site. Every
build target first replaces `src/sitespecific/<ARCHAPPL_SITEID>` in the source
checkout with this folder (`make copy.sitespecific`); the source Maven build then
applies the folder before it packages the WARs. No Ant is involved.

| Path in the site folder | Content | Effect in the WARs |
| --- | --- | --- |
| `img/` | Image files, with their subfolders | Overwrite the shared images |
| `css/main.css` | Shared stylesheet of a site that sets its own tokens; optional | Overwrites the shared stylesheet |
| `template_changes.html` | Template sections | Merged into the management pages before the copies |
| `classpathfiles/` | `appliances.xml`, `archappl.properties` and `policies.py`, generated by `make conf.archapplproperties` | Packaged on the classpath of every WAR; the folder must exist |

The shared images and stylesheet go into the `mgmt` and `retrieval` WARs; the
`engine` and `etl` WARs carry only `ui/comm/version.txt` of the shared files.
A file of the site folder outside this table is not packaged. The build warns about
any other file under `css/`, a `css/mgmt.css` among them, and any other folder,
because it applies none of them.
The shipped site folder holds `template_changes.html`, `img/LBNLLogo.png` and `img/als.ico`, and the generated
`classpathfiles/`. It carries no stylesheet, so the shared stylesheet of the source applies. `template_changes.html`
fills the block `site_logo` of the header with the site logo and the favicon link. Keep the logo inside
`<span id="siteimages">`: the stylesheet sizes `#siteimages img` to 44 px, to 30 px at 720 px and below and to
24 px at 380 px and below, and the shipped `template_changes.html` has that form. The source supplies the header
frame, the header logo, its narrow-screen wordmark and the menu; a `site_header` block would put a second header
inside the frame and a `site_navbar` block would replace the menu, so the site folder carries neither.

A `css/main.css` in the site folder replaces the whole shared stylesheet, the rules of the menu and of the logo
sizes included. Start from the file of the source, change only the values of the site, and compare it with the
file of the source again whenever the source changes.

`ARCHAPPL_SITEID` (default `als`) names the folder under `src/sitespecific` and
reaches Maven through every build and clean target. `ARCHAPPL_SITEID_TEMPATE_PATH`
(spelled as in the configuration) names the folder that is copied. To build another
site, set both in `../CONFIG_SITE.local`, or pass them as Make command-line
overrides, with the site folder laid out as in the table. Run the [ordered sequence](#ordered-sequence) for it:
the three local entry scripts fix `ARCHAPPL_SITEID=als` on their Make command lines, which wins over the
setting in `../CONFIG_SITE.local`.

A site folder that contains a `build.xml` fails the build with the message
`A site build.xml is no longer run. Remove <site folder>/build.xml and use img/, css/
and template_changes.html as described in the Building chapter.`, where `<site folder>`
is the folder path. Remove the file from the site folder, including an
operator-supplied one named by `ARCHAPPL_SITEID_TEMPATE_PATH`.

### Interface files

The management pages and the data viewer are part of the source that `SRC_TAG` selects, and a build packages them
with the site skin of the site folder. This repository copies no interface files. When the git directory of the
source clone holds a list `aa-ui-prepared.list`, the installers restore each file that it names from the source (or
remove the file when the source does not track it), delete the list, and only then select the source commit; the
preflight does not count the listed files as local changes before that. The
pages, their judgements and their limits are described in [the interface guide](./README.interface.md).

## Reinstall and upgrade

This section reinstalls or upgrades an installation that you built with `make`. The scripts `scripts/install-local-*.bash` of [Local systemd installation](#local-systemd-installation), called the installer scripts here, do most of this work in one command; they also prepare the packages and Tomcat, and the options of that section decide what they change on the host.

The installer scripts pass `DB_BACKEND`, `ARCHAPPL_SITEID=als` and the `DB_SOCKET` of a MariaDB transport (empty for TCP) only on their `make` command lines, and they do not remember `--socket`. The manual steps use the `ARCHAPPL_SITEID` of `../CONFIG_SITE.local` (default `als`) and the installer scripts always `als`, so keep `als` when an installer script installed the appliance. Before the manual steps below, write the same values into `../CONFIG_SITE.local` and remove a `DB_SOCKET` that a TCP site no longer uses (the manual flow has no empty `DB_SOCKET=`): `DB_BACKEND=sqlite` for SQLite, and for MariaDB over a socket the `DB_SOCKET` that the installer used (its default is `/var/lib/mysql/mysql.sock` on Rocky Linux 8 and 10 and `/run/mysqld/mysqld.sock` on Debian 13 and Ubuntu 24.04 and 26.04). With the default `mariadb` backend, `make conf.install` renders a unit that requires `mariadb.service`, which a SQLite host does not have, and without `DB_SOCKET` `context.xml` and `mariadb.conf` are rendered for TCP; `make install` installs both without an error.

On a first installation steps 6 (the schema) and 7 (`make conf.storage`) of the ordered sequence are required. On an upgrade they are needed only when the schema or the storage folders change, and then the parts that the table marks U (MariaDB `make sql.fill`, SQLite `make sql.update`) run as the checkout owner; schema loading requires the maintenance window, while SQLite `make sql.table.fill` and `make conf.storage` run as root in the maintenance window after the stop and before `sudo make install`; the schema of the source is the same in the 2.0.0 pin `d8a7813f` and in the tag `2026-10`, and repeating the steps is safe.

Before the maintenance window, as the checkout owner (the owner of this repository checkout, not root), build and generate the configuration:

1. Move the source clone when `SRC_TAG` changed or the source repository has new commits: run `git -C epicsarchiverap-maven-src fetch origin` and `make srcupdate` in place of step 1 of the [ordered sequence](#ordered-sequence), because in an existing clone `make init` does not move the source. Then confirm the source: compare `git -C epicsarchiverap-maven-src rev-parse HEAD` with `git -C epicsarchiverap-maven-src rev-parse "$(make -s print-SRC_TAG)^{commit}"`; the two commits must be equal.
2. Run steps 2 to 4 of the sequence: `make db.conf`, `make conf.archapplproperties` and `make build.mvn`. Without sequence step 4, `make install` replaces the payload with the WARs that already sit in `target`, and without the move of item 1 the build uses the old checkout.
3. Run step 5 of the sequence, `make conf.install`, after the last edit of the configuration. `make <os>.conf` rewrites `configure/CONFIG_SITE.local`, which is such an edit: run it before item 2, so that the build and the rendered files use the same configuration as the units, and in any case before `make conf.install`, never after. `make install` installs the units that step 5 rendered and renders nothing into the checkout itself; when a unit is missing or older than its template or the configuration, it stops before it stops the health monitor or changes the payload and names `make conf.install`.

In the maintenance window, stop the appliance, install as root and start the appliance only after the installation succeeds. Tomcat must not load classes while the WAR and logging libraries are replaced. `make sd_stop` ignores errors, so check that the unit is inactive before the installation; `make -s print-SYSTEMD_FILENAME` prints the unit name, `epicsarchiverap-maven.service`, and the first code block takes it from there because `systemctl is-active` also prints `inactive` for a mistyped name. `make sd_stop`, `make sd_start` and `sudo make install` call `sudo`; an unattended run needs `sudo` without a password prompt. The `sudo make install` command runs Make itself as root so its shell can access existing service-owned instance directories. Stop the appliance and read the state of its unit:

```bash
make sd_health_stop
make sd_stop
systemctl is-active "$(make -s print-SYSTEMD_FILENAME)"
systemctl is-active "$(make -s print-SYSTEMD_HEALTH_TIMER)"
systemctl is-active "$(make -s print-SYSTEMD_HEALTH_SERVICE)"
```

Proceed only when all three state checks print `inactive` or `failed` (a crashed appliance leaves the unit `failed`, and the installer scripts accept both states). Any other output or inspection error means that the stop is not established: inspect the unit with `systemctl status` and do not load a schema or install. If schema loading is required, run sequence step 6 now with its documented ownership. Then install as root:

```bash
sudo make install
```

Start the appliance only after `make install` succeeds:

```bash
make sd_start
```

`make sd_stop` alone leaves the health timer running; this procedure stops it first with `make sd_health_stop` so database maintenance is permitted. `make sd_start` starts the appliance and its health timer after installation. Installation itself does not stop or restart the appliance. Do not run concurrent installations into the same prefix.

After the start, check the result in this order; the [Health check](#health-check) and [Functional verification](#functional-verification) sections below give the details.

1. Run this command in the checkout. It runs the health check as the service user (`AA_USERID`, default `tomcat`) and must exit 0:

   ```bash
   sudo -u "$(make -s print-AA_USERID)" bash "$(make -s print-AA_INSTALL_LOCATION)/archappl.bash" health
   ```

   Exit status 1 with `STARTING` means that an instance has not executed Java yet, so repeat the command; `STARTING` lasts at most `ARCHAPPL_HEALTH_STARTING_SECONDS` (default 10), and after that bound the command reports `FAIL startup-timeout`. Exit status 2 means that the inspection was incomplete. Exit status 0 verifies the processes and the storage usage, not HTTP readiness.
2. Check the HTTP readiness. `getApplianceInfo` on the `mgmt` port, `http://<host>:17665/mgmt/bpl/getApplianceInfo` with the default port, must return HTTP 200 and a `version` that contains the first 8 characters of the source commit. Each of the four components must answer `{"status":"STARTUP_COMPLETE"}` on `http://<host>:<port>/<component>/bpl/startupState`, with the ports 17665 to 17668 for `mgmt`, `engine`, `etl` and `retrieval` by default. Repeat the checks for up to 180 seconds, the time that the installer scripts wait by default (`--timeout` accepts 1 to 86400).

For each of `mgmt`, `engine`, `etl` and `retrieval`, installation prepares the
WAR and logging JARs in a temporary directory before replacing the managed
payload. Exactly one matching WAR and a nonempty logging JAR set are required.
A missing, ambiguous or unreadable input, or a failed WAR extraction, stops
that instance's payload replacement while retaining its previous payload.

| Location | Reinstall behavior |
| --- | --- |
| `<instance>/webapps/<component>/` | Replaced completely by the selected WAR; removed upstream files and local edits inside this tree disappear |
| `<instance>/log4j/*.jar` | Replaced by the selected `target/tomcat-log4j` set; older or manually added JARs disappear |
| Other files under `<instance>/log4j/` | Retained; shipped logging configuration is refreshed by the normal template install |
| Logs, work/temp files, other webapps, archive stores and SQLite data | Not removed by payload replacement |
| Generated aa-env configuration and wrappers | Refreshed from the configured templates as in a normal install; keep site settings in the supported override files |

The installer attempts to restore the prior payload if a replacement move
fails. If restoration fails, it reports the retained `.payload.*` backup path
on stderr. Keep the appliance stopped and resolve the reported failure before
starting it. Replacement is per instance, not a transaction across all four
components; an interrupted or failed installation requires a successful rerun.
This procedure does not promise rollback after power loss or a forced kill.

## Ordered sequence

The sequence starts after the host preparation: the OS packages and `make <os>.conf`, and Tomcat (`make tomcat.get`, `make tomcat.install`, `make tomcat.exist`; see [Make targets of the repository](../book/src/appendix/make-targets.md)). An upgrade of a running host needs none of them when Tomcat is already installed; do not run `make tomcat.install` over a live Tomcat.

`U` runs as an ordinary build user; `R` requires root (an automation role that
runs every step as root is also valid — the internal `sudo` is a no-op when
already root). Do not run `make build` wholesale; it bundles `conf.storage`.

| # | Target | Priv | Inputs | Writes | Check |
| --- | --- | --- | --- | --- | --- |
| 1 | `make init` | U | `SRC_TAG`, `SRC_URL` | source clone `epicsarchiverap-maven-src`, only when the folder is absent | a new clone: source `HEAD` at `SRC_TAG`; an existing clone stays at its commit, so run `git -C epicsarchiverap-maven-src fetch origin` and `make srcupdate`, then check `HEAD` |
| 2 | `make db.conf` | U | `DB_BACKEND`, `DB_*` | MariaDB: `site-template/mariadb.conf`; SQLite: none | MariaDB: file exists (`make db.conf.show`); SQLite: `[SKIP]` |
| 3 | `make conf.archapplproperties` | U | `ARCHAPPL_*` (incl. `ARCHAPPL_*_PORT`, default 17665-17668) | `site-template/*` and source `classpathfiles` | files exist (`make conf.archapplproperties.show`) |
| 4 | `make build.mvn` | U | source clone, `JAVA_HOME` | four WARs and the Tomcat log4j jar set in `epicsarchiverap-maven-src/target` | four `*-{mgmt,engine,etl,retrieval}.war`; `target/tomcat-log4j` holds `log4j-api`, `log4j-core`, `log4j-appserver` and `log4j-jul` |
| 5 | `make conf.install` | U | `AA_*`, `DB_BACKEND`, `SYSTEMD_*`, source clone | `site-template/systemd/` units and `site-template/.versions` | files exist |
| 6 | MariaDB: `make sql.fill`; SQLite: `make sql.update`, then `make sql.table.fill` | MariaDB: U; SQLite: U, then R | `DB_BACKEND`; `DB_USER`/`DB_USER_PASS` or `ARCHAPPL_SQLITE_FILE`; source SQL | `site-template/sql/` schema copy; schema loaded over TCP or `DB_SOCKET`, or into the SQLite file | `make sql.show` lists the tables |
| 7 | `make conf.storage` | R | `ARCHAPPL_STORAGE_TOP` | `$(ARCHAPPL_STORAGE_TOP)/{sts,mts,lts}/ArchiverStore`, with the default `/arch/{sts,mts,lts}/ArchiverStore` | directories exist, owned by the service user |
| 8 | `make install` | R | WARs, the files of step 5, `AA_USERID`/`AA_GROUPID` | four instances, appliance service, health service and timer | units installed; appliance and timer enabled, not started |
| 9 | `make sd_start` | R | installed units and complete instance configuration | appliance and health timer started | timer active; process checks after startup allowance; separate mgmt probe returns HTTP 200 |

Notes:
- The steps that need root render nothing into the checkout, so the checkout
  stays writable for its owner. `make install` installs the units that step 5
  rendered (step 5 also records the source commit in `site-template/.versions`),
  and `make sql.table.fill` loads the schema
  copy that `make sql.update` rendered; each stops with exit status 2 and names
  the rendering target when its file is missing or older than its template or,
  for the units, than the configuration (`configure/CONFIG*`,
  `configure/RELEASE*`, `../CONFIG_SITE.local`, `../RELEASE.local`). After a
  change of the configuration run step 5 again; the check compares only the
  modification times of these files, so a value given on the `make` command
  line or a change of `configure/os/*.mk` needs step 5 again by hand. The files that step 3 renders
  (`archappl.conf`, `appliances.xml`, `archappl.properties`, `policies.py` and
  `context.xml`) are installed without that check, and the WARs of step 4 carry
  `appliances.xml`, `archappl.properties` and `policies.py`, so run steps 2 to 4
  again as well, before step 8.
- `make install` creates the service account (idempotent), stops any existing
  health timer/check before changing files, then installs the appliance and
  health pair. It reloads systemd before enabling the appliance and timer, with
  no implicit appliance stop or start. For an upgrade or reinstall, run
  `make sd_stop` before changing installed files, then `make sd_start` after
  installation to start the appliance and timer explicitly.
- The enabled timer is also wanted by the appliance service, so a direct
  `systemctl start epicsarchiverap-maven.service` starts monitoring. Enabling a
  timer does not retroactively activate it for an already-running appliance.
- With the MariaDB backend the unit declares `Requires=mariadb.service`, so that
  unit must resolve on the host; with SQLite the unit names no database service.
- MariaDB: the manual sequence assumes host-provided accounts and runs
  `sql.fill` without account provisioning. For manual local provisioning,
  use `DB_SOCKET` with `db.addAdmin` and `db.create`: `db.addAdmin` creates
  the administrator at `localhost`. TCP clients at `127.0.0.1` cannot rely
  on that account with `skip-name-resolve`. The TCP installation entry script
  instead prepares both accounts explicitly at `127.0.0.1`; the UDS entry
  script prepares them at `localhost`. Neither entry script invokes
  `db.secure`. That optional target removes anonymous and non-localhost root
  accounts and the test database; it preserves the remaining root account's
  authentication method. See the [MariaDB reference](technicaldocs/README.mariadb.md).
  The database targets, including `db.rmAdmin` and `db.drop`, stop with a non-zero status
  and name the failed step when the database client fails.
- SQLite: step 6 loads the schema as root (R) after `make sql.update` rendered
  it as the checkout owner. `sql.table.fill` first creates the service account
  when it does not exist yet, as `make install` does later, then creates the
  directory of `ARCHAPPL_SQLITE_FILE` for that account and loads the schema
  with `sqlite3` run as the account (`runuser`, after non-root helper calls obtain root through `sudo -n`), so the database and its WAL files stay writable by the
  appliance. Loading again is harmless and restores a missing table. Check the
  tables with `make sql.show`, which runs `sqlite3` the same way; another user
  cannot read the file once the appliance has opened it. Step 2
  (`make db.conf`) prints `[SKIP]` and succeeds without generating MariaDB
  client settings. `db.conf.show` also skips; `db.create`, `db.drop` and `db.show` operate on the SQLite file.

## Ownership boundary

- aa-env owns: `/opt/epicsarchiverap-maven` (the four instances,
  `CATALINA_BASE`), `/arch` (storage), `epicsarchiverap-maven.service`, and the
  `epicsarchiverap-maven-health.service` / `.timer` pair. Instance and storage
  files are owned by `AA_USERID:AA_GROUPID`; unit files are installed mode 0644
  through the privileged systemd install targets.
- The host owns: `/opt/tomcat9` (`CATALINA_HOME`, read-only to aa-env), the
  MariaDB service and the application account for the MariaDB backend, the
  base packages, and the service
  group and user when pre-created.

The local entry scripts can install host packages and the shared Tomcat runtime,
start MariaDB, and prepare database accounts. The appliance unit does not own
MariaDB's listener configuration. `--existing-db` preserves account provisioning,
and `--tomcat replace` explicitly permits replacing the default shared Tomcat.

## Logs

- The appliance service runs the launcher as its main process and the four
  Tomcats in the foreground. Each instance's stdout and stderr go to the
  journal under `archappl-<instance>` (`archappl-mgmt`, `archappl-engine`,
  `archappl-etl`, `archappl-retrieval`):
  `journalctl -u epicsarchiverap-maven.service -t archappl-engine`.
- No `catalina.out` and no dated JULI file is written; the only file per
  instance is the access log `logs/localhost_access_log.<date>.txt`, which
  Tomcat rotates daily and prunes after 90 days.
- Application lines come from the log4j2 configuration inside each WAR. Its
  root level is `ARCHAPPL_ROOT_LOGGER_LEVEL` (default `INFO`), exported to the
  JVMs through `archappl.conf`; set it in `../CONFIG_SITE.local`, then run
  `make conf.archapplproperties` and follow the
  [reinstall procedure](#reinstall-and-upgrade). A
  site that needs another layout, or level changes without a restart, keeps a
  copy of the WAR's `log4j2.xml` on the host, taken from an installed
  instance such as
  `/opt/epicsarchiverap-maven/mgmt/webapps/mgmt/WEB-INF/classes/log4j2.xml`
  (the copy keeps the file's `monitorInterval="30"`), names it in `ARCHAPPL_LOG4J_SITE_FILE`, and
  follows the same stop/install/start procedure once; `archappl.conf` then
  carries `LOG4J_CONFIGURATION_FILE`, the copy replaces the WAR's file, and a
  logger level edited in the copy takes effect within the interval.
- Journal retention (`MaxRetentionSec`, `SystemMaxUse`) is a host setting.
- `systemctl stop` stops the instances in order within
  `SYSTEMD_TIMEOUT_STOP_SECONDS` (default 300); a dead instance leaves the unit
  failed with no automatic restart. The systemd guide in
  `docs/technicaldocs/README.systemd.md` describes the lifecycle.

## Health check

- Process and storage health: run the installed `archappl.bash health` as the service
  account. Exit 0 verifies the four expected JVM processes and filesystem usage
  below the storage alarm threshold at that observation. Exit 1 reports a
  reached or exceeded storage threshold, names invalid/missing instances, or
  reports `STARTING` for an instance
  that has not executed Java yet, so repeat the command a few seconds after a
  start or restart; exit 2 reports incomplete inspection.
  `archappl.bash status` displays UI and journal information, then runs the
  same process/storage check and returns its exit status. Run it as the service
  account too. Neither command verifies HTTP readiness or sample acquisition.
  The recurring health service reports failures independently of the appliance
  service. A successful or skipped oneshot becomes inactive, so inactive alone
  is not proof of four healthy processes. Inspect its journal and exit status.
- HTTP readiness: `curl http://<host>:17665/mgmt/bpl/getApplianceInfo` returns HTTP 200.
- Functional verification: complete the [PV acquisition and retrieval check](#functional-verification)
  below after process presence and HTTP readiness succeed.

Monitoring neither restarts nor protects surviving JVMs after a failure. Existing
MainPID handling and component dependencies still apply. See the
[systemd operating contract](technicaldocs/README.systemd.md#process-monitoring)
for timing, skip results, operator recovery and monitor-only removal, and the
[VM test procedure](../tests/README.md#process-monitoring-vm-verification)
for runtime acceptance. Current verification evidence is maintained in
[M23](milestone-2.0.0.md#m23---make-a-dead-instance-visible-to-systemd).

## Functional verification

Use this procedure on the appliance host after installation. It checks actual
IOC acquisition and retrieval through the running appliance. It does not
measure ETL, sustained load, or production capacity.

### Required inputs

Record these inputs with the test evidence before starting:

| Input | Requirement |
| --- | --- |
| Environment and source | Exact aa-env release commit or tag and the source commit that `SRC_TAG` resolved to |
| IOC address | A reachable real IOC endpoint selected for the test; retain internal addresses only in private evidence |
| Test PVs | Three scalar numeric PVs that change at least once per second; record their names and expected changes; the IOC operator supplies and keeps them running |
| Appliance endpoints | Management and retrieval base URLs using the configured host and ports; defaults are 17665 and 17668 |
| Runtime identity | Configured appliance identity, service user, install path and systemd unit names |
| Clock | IOC and appliance clocks synchronized so sample timestamps can be compared with the request interval |
| Evidence location | A private run directory for input values, UTC times, HTTP responses and process observations |

### Acquisition and retrieval procedure

1. In `../CONFIG_EPICSENV.local` relative to the aa-env checkout, set
   `EPICS_CA_ADDR_LIST` to the selected IOC address and
   `EPICS_CA_AUTO_ADDR_LIST` to `NO`. Follow the configuration/build steps
   and the root [reinstall procedure](#reinstall-and-upgrade). Record UTC
   time immediately before starting the appliance as the retrieval lower
   bound. Preserve that timestamp for every request in this run.
2. On the appliance host, wait up to 180 seconds for the management
   `GET /mgmt/bpl/getApplianceInfo` endpoint to return HTTP 200 with the
   configured appliance identity. Retry every two seconds; limit each HTTP
   request to ten seconds. An exhausted deadline is a failed check.
3. Confirm the appliance service and health timer are enabled and active.
   Run the installed health command as the service user and require exit 0.
   Inspect all four actual JVM environments through `/proc/<pid>/environ`
   with sufficient read permission. Require the selected CA address and
   auto-address `NO` in each component. Record the PIDs and observations.
4. For each test PV, submit `GET /mgmt/bpl/archivePV` to the management
   endpoint with the URL-encoded `pv` parameter. Save the response. Poll
   `GET /mgmt/bpl/getPVStatus` with the same parameter every two seconds,
   for up to 180 seconds. Require exactly one matching PV entry with
   `status` equal to `Being archived` and `connectionState` equal to `true`.
   A submitted archive request alone is not success.
5. For each PV, request `GET /retrieval/data/getData.json` from the retrieval
   endpoint. URL-encode the query parameters below. Retry every two seconds
   for up to 120 seconds until every PV meets the pass criteria. Refresh
   the upper bound on each retry, and save the complete responses and the
   bounds used. Do not count a response returned after its deadline as a pass.

   | Parameter | Value |
   | --- | --- |
   | `pv` | One recorded test PV name |
   | `from` | The recorded pre-start UTC lower bound, formatted as `YYYY-MM-DDTHH:MM:SSZ` |
   | `to` | Current appliance-host UTC time, in the same format |

6. Require one returned series whose `meta.name` matches the requested PV.
   Compute each sample timestamp as `secs + nanos / 1000000000` (zero nanos
   when absent). Count only samples within the requested inclusive bounds;
   retain but exclude any earlier boundary sample. For each PV, require at
   least two counted samples, at least two distinct values, and a newest
   timestamp no more than 15 seconds before the request's upper bound.
7. Repeat the process health check and save its exit status. After a scheduled
   health check has run, record that service's actual execution time,
   `Result=success` and `ExecMainStatus=0`, read with `systemctl show
   epicsarchiverap-maven-health.service -p Result -p ExecMainStatus -p ExecMainStartTimestamp`; an inactive oneshot alone does not
   establish success. Record completion time and Pass only when all checks
   above succeed. Otherwise record Fail with the responses and failed step.

Keep the test PVs, database and installed tree available until their owner
approves cleanup. For release verification, place the durable result, exact
release/source commits and private evidence digests in the canonical release
record; do not publish internal endpoints or credentials.
