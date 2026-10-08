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
source pin and installation paths resolved from Make settings.

Prerequisites:

- Debian 13 or Rocky Linux 8 with systemd running.
- An ordinary checkout owner with `sudo` access; do not run an entry script as root.
- `bash`, `make`, `git`, and `realpath` for preflight; `sudo` and `flock` for installation.
- Network access for OS packages, source Git fetches, Tomcat downloads, and Maven dependencies.
- Storage, Tomcat, service-account, and database settings in
  `../CONFIG_SITE.local`, as described in [configuration variable placement](#configuration-variable-placement).
  Select a different source pin through the supported RELEASE overrides.
- A clean source checkout, if one exists. Tracked or staged changes and
  untracked files stop preflight. Generated `src/sitespecific/als` files and
  ignored build outputs are allowed; ignored inputs under `src` or `.mvn` are rejected.

1. Choose one database mode and review its inputs.

   | Entry script | Connection and preparation |
   | --- | --- |
   | `install-local-sqlite.bash` | Uses `ARCHAPPL_SQLITE_FILE`, loads the SQLite schema as the service account, and excludes MariaDB packages from installation |
   | `install-local-mariadb-uds.bash` | Uses `--socket`, then `DB_SOCKET`, then the OS default socket; starts MariaDB and prepares accounts at `localhost` |
   | `install-local-mariadb-tcp.bash` | Clears `DB_SOCKET`, requires `DB_HOST_NAME=127.0.0.1`, uses `DB_HOST_PORT`, and prepares accounts at `127.0.0.1` |

   The default UDS path is `/run/mysqld/mysqld.sock` on Debian 13 and
   `/var/lib/mysql/mysql.sock` on Rocky Linux 8. The service account must be able
   to reach and write the socket. The script does not configure MariaDB's listener.

   MariaDB starts `mariadb.service` and creates or updates `DB_NAME`, `DB_ADMIN`,
   and `DB_USER` using the configured passwords and grants. Set `DB_ADMIN_PASS`
   and `DB_USER_PASS` before confirming; existing accounts receive those values.
   Default account preparation requires local root socket authentication. For TCP,
   the root socket server's port must match `DB_HOST_PORT`.

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
   pin, prepares Tomcat 9, generates configuration, and builds before stopping an
   installed appliance. It requires the appliance to be stopped before database
   preparation and payload replacement, then starts the appliance and health timer.
   The OS preset rewrites `configure/CONFIG_SITE.local`; keep site overrides in
   `../CONFIG_SITE.local`.

   | Option | Behavior |
   | --- | --- |
   | `--plan` | Prints steps without executing installation |
   | `-y`, `--yes` | Skips the installation confirmation; required with non-interactive stdin |
   | `--skip-packages` | Uses host-provided prerequisites, including JDK 21 |
   | `--socket <socket_path>` | UDS only: selects an absolute socket path without whitespace |
   | `--existing-db` | MariaDB only: skips account/database provisioning; starts MariaDB and loads the schema |
   | `--timeout <seconds>` | Sets the startup verification deadline from 1 to 86400 seconds; default 180 |
   | `-h`, `--help` | Prints usage and option descriptions |

   With `--existing-db`, the database and application account must already exist,
   and `DB_USER_PASS` must match that account. The flag preserves account
   configuration, not database contents: schema loading runs in both modes.
   Existing archive stores and database files remain during payload replacement.
   An unavailable default Tomcat installation is downloaded and checked against
   Apache's SHA-512 before extraction; a custom `TOMCAT_HOME` must already contain Tomcat 9.

Verification: a successful run prints `Installation ready:` with the management
URL and exits 0. It checks process health as the service account, all four
`startupState` responses for `STARTUP_COMPLETE`, a successful management HTTP
response, and active appliance and health timer units within the startup deadline.
Perform the separate [functional verification](#functional-verification) to
confirm PV acquisition and retrieval.

On failure, the script exits nonzero and reports the error. Once installation
begins, it also names the failed step. It retains data and build files and
performs no automatic rollback or restart. A failure
after the appliance stop can leave it stopped or partly replaced; resolve the
reported failure before repeating installation or starting the service.

## Architecture

- aa-env clones the source repository (https://github.com/jeonghanlee/epicsarchiverap-maven) and drives its Maven Wrapper build, then
  installs four Tomcat instances under a single systemd service: `mgmt` (17665),
  `engine` (17666), `etl` (17667), `retrieval` (17668).
- The source WARs are built for the `als` site. Keep `ARCHAPPL_SITEID=als`.
  The site overlay is copied into the source tree automatically before the
  build, so each WAR carries the `als` site `classpathfiles`.
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
  (package `sqlite` on Rocky Linux 8, `sqlite3` on Debian 13) and no MariaDB.
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

- `configure/RELEASE.local`: `SRC_TAG` — the source pin for
  https://github.com/jeonghanlee/epicsarchiverap-maven (a commit, tag, or branch). `SRC_URL` has a default (`https://github.com/jeonghanlee`) and
  is overridden here only when the source is hosted elsewhere. This file is not
  rewritten by the per-OS config targets. A pinned `SRC_TAG` must be at or after
  `67be91d7`: from `9bbd69bf` the build writes `target/tomcat-log4j`, which
  `make install` requires and stops without, and from `67be91d7` every WAR
  carries the `log4j2.xml` that formats application lines. An older source
  installs without that file, and application lines then run unconfigured.
- `../CONFIG_SITE.local` (one directory above the checkout top): `AA_USERID`,
  `AA_GROUPID`, `DB_NAME`, `DB_USER`, `DB_USER_PASS`, `DB_HOST_NAME` (`127.0.0.1`),
  `DB_HOST_PORT`, and any `ARCHAPPL_*` overrides. This file is included first and
  survives the per-OS config target that rewrites `configure/CONFIG_SITE.local`.
- Configuration database: `DB_BACKEND` is `mariadb` (default) or `sqlite`, set
  in `../CONFIG_SITE.local`; any other value stops step 3
  (`make conf.archapplproperties`), so the sequence goes no further, and
  `make install` also stops before it writes the unit. With `sqlite`, the
  database is the file `ARCHAPPL_SQLITE_FILE`, by default
  `$(ARCHAPPL_STORAGE_TOP)/config/archappl.sqlite`
  (`/arch/config/archappl.sqlite`), owned by the service account. It sits under
  the store, so `make conf.storage.rm`, which removes `ARCHAPPL_STORAGE_TOP`,
  removes the configuration database too. SQLite currently supports
  `sql.update`, `sql.update.show`, `sql.fill` and `sql.show`, including their
  `sql.table.fill` and `sql.table.show` targets. `sql.drop` and
  `sql.table.drop` reject SQLite without changing either database.
  Every `db.*` target prints `[SKIP]` and succeeds without reading or writing
  MariaDB configuration or running prerequisites. This keeps the common install
  sequence usable with SQLite. The four application-table query targets
  (`PVRequests.show`, `DataServers.show`, `PVAliases.show`, `PVTypeInfo.show`)
  and direct `scripts/mariadb_setup.bash` operations reject SQLite before any
  MariaDB access. Every DB/SQL/query target rejects an invalid backend before
  configuration writes or database contact.
- MariaDB transport: `DB_SOCKET` is empty by default, which connects over TCP to
  `DB_HOST_NAME:DB_HOST_PORT`. Set it in `../CONFIG_SITE.local` to the server's
  Unix domain socket (`/var/lib/mysql/mysql.sock` on Rocky Linux 8,
  `/run/mysqld/mysqld.sock` on Debian 13, or the path the provisioning sets)
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
  on an installed host. Stop the appliance before step 7 (`make install`, which
  also replaces the WARs), then start it after installation succeeds.
  `DB_SOCKET` is ignored for `sqlite`.
- Toolchain: `JAVA_HOME` is set through the OS preset
  (`make <os>.conf`, with `<os>` one of `debian13`, `debian12` and `rocky8`,
  writes `configure/CONFIG_SITE.local` to include `configure/os/<os>.mk`), or
  set in `../CONFIG_SITE.local`. `TOMCAT_HOME` defaults to
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
| `img/` | Image files, without subfolders | Overwrite the shared images |
| `css/main.css` | Shared stylesheet | Overwrites the shared stylesheet |
| `css/mgmt.css` | Management stylesheet | Overwrites the management stylesheet |
| `template_changes.html` | Template sections | Merged into the management pages before the copies |
| `classpathfiles/` | `appliances.xml`, `archappl.properties` and `policies.py`, generated by `make conf.archapplproperties` | Packaged on the classpath of every WAR; the folder must exist |

The other entries of the site folder (`README.md`, `LICENSE.FeatherIcons`) are not
packaged. The build warns about any other file under `css/` and any other folder,
because it applies none of them.

`ARCHAPPL_SITEID` (default `als`) names the folder under `src/sitespecific` and
reaches Maven through every build and clean target. `ARCHAPPL_SITEID_TEMPATE_PATH`
(spelled as in the configuration) names the folder that is copied. To build another
site, set both in `../CONFIG_SITE.local`, or pass them as Make command-line
overrides, with the site folder laid out as in the table.

A site folder that contains a `build.xml` fails the build with the message
`A site build.xml is no longer run. Remove <site folder>/build.xml and use img/, css/
and template_changes.html as described in the Building chapter.`, where `<site folder>`
is the folder path. Remove the file from the site folder, including an
operator-supplied one named by `ARCHAPPL_SITEID_TEMPATE_PATH`.

## Reinstall and upgrade

Build and generate the configuration before the maintenance window. Stop the
appliance before replacing its files; Tomcat must not load classes while the
WAR and logging libraries are being replaced. From the aa-env checkout,
stop the appliance, install as root, and start only after installation succeeds.
The `sudo make install` command runs Make itself as root so its shell can
access existing service-owned instance directories:

```bash
make sd_stop
sudo make install
make sd_start
```

Run `make sd_start` only after `make install` succeeds, then perform the
process and application checks below. Installation itself does not stop or
restart the appliance. Do not run concurrent installations into the same prefix.

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

`U` runs as an ordinary build user; `R` requires root (an automation role that
runs every step as root is also valid — the internal `sudo` is a no-op when
already root). Do not run `make build` wholesale; it bundles `conf.storage`.

| # | Target | Priv | Inputs | Writes | Check |
| --- | --- | --- | --- | --- | --- |
| 1 | `make init` | U | `SRC_TAG`, `SRC_URL` | source clone `epicsarchiverap-maven-src` | source `HEAD` at `SRC_TAG` |
| 2 | `make db.conf` | U | `DB_BACKEND`, `DB_*` | MariaDB: `site-template/mariadb.conf`; SQLite: none | MariaDB: file exists (`make db.conf.show`); SQLite: `[SKIP]` |
| 3 | `make conf.archapplproperties` | U | `ARCHAPPL_*` (incl. `ARCHAPPL_*_PORT`, default 17665-17668) | `site-template/*` and source `classpathfiles` | files exist (`make conf.archapplproperties.show`) |
| 4 | `make build.mvn` | U | source clone, `JAVA_HOME` | four WARs and the Tomcat log4j jar set in `epicsarchiverap-maven-src/target` | four `*-{mgmt,engine,etl,retrieval}.war`; `target/tomcat-log4j` holds `log4j-api`, `log4j-core`, `log4j-appserver` and `log4j-jul` |
| 5 | `make sql.fill` | U (R for SQLite) | `DB_BACKEND`; `DB_USER`/`DB_USER_PASS` or `ARCHAPPL_SQLITE_FILE`; source SQL | schema loaded over TCP or `DB_SOCKET`, or into the SQLite file | `make sql.show` lists the tables |
| 6 | `make conf.storage` | R | `ARCHAPPL_STORAGE_TOP` | `/arch/{sts,mts,lts}/ArchiverStore` | directories exist, owned by the service user |
| 7 | `make install` | R | WARs, `AA_USERID`/`AA_GROUPID` | four instances, appliance service, health service and timer | units installed; appliance and timer enabled, not started |
| 8 | `make sd_start` | R | installed units and complete instance configuration | appliance and health timer started | timer active; process checks after startup allowance; separate mgmt probe returns HTTP 200 |

Notes:
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
- MariaDB: the database and account are created by the host; the sequence
  therefore skips `db.secure`, `db.addAdmin`, and `db.create` and runs only
  `sql.fill`. A host installed by aa-env alone runs those three targets
  first; over TCP they need a server without `skip-name-resolve`, because
  `db.addAdmin` creates the admin account at `localhost` while the TCP client
  arrives as `127.0.0.1`. A server with `skip-name-resolve` uses `DB_SOCKET`,
  whose clients arrive as `localhost`, or the host-provided path. Each of
  these targets, and `db.rmAdmin` and `db.drop`, stops with a non-zero status
  and names the failed step when the database client fails.
- SQLite: step 5 needs root (R). `sql.fill` first creates the service account
  when it does not exist yet, as `make install` does later, then creates the
  directory of `ARCHAPPL_SQLITE_FILE` for that account and loads the schema
  with `sqlite3` run as the account (`runuser` for a root-run build, `sudo -u`
  otherwise), so the database and its WAL files stay writable by the
  appliance. Loading again is harmless and restores a missing table. Check the
  tables with `make sql.show`, which runs `sqlite3` the same way; another user
  cannot read the file once the appliance has opened it. Step 2
  (`make db.conf`) prints `[SKIP]` and succeeds without generating MariaDB
  client settings. The same behavior applies to every other `db.*` target.

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

- Process presence: run the installed `archappl.bash health` as the service
  account. Exit 0 verifies the four expected JVM processes at that observation;
  exit 1 names invalid/missing instances or reports `STARTING` for an instance
  that has not executed Java yet, so repeat the command a few seconds after a
  start or restart; exit 2 reports incomplete inspection.
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
| Environment and source | Exact aa-env release commit or tag and pinned aa-maven commit |
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
   `Result=success` and `ExecMainStatus=0`; an inactive oneshot alone does not
   establish success. Record completion time and Pass only when all checks
   above succeed. Otherwise record Fail with the responses and failed step.

Keep the test PVs, database and installed tree available until their owner
approves cleanup. For release verification, place the durable result, exact
release/source commits and private evidence digests in the canonical release
record; do not publish internal endpoints or credentials.
