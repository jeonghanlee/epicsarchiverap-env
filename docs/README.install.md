# Non-Interactive Install Sequence

Linear, non-interactive procedure to build and run the Archiver Appliance from
this environment on a pre-provisioned host, so an automation role drives the
`make` targets without reading the Makefiles. It covers the ordered targets, the
privilege boundary of each, the inputs each consumes, the paths each writes, and
the check that proves it ran.

## Architecture

- aa-env clones the source repository (https://github.com/jeonghanlee/epicsarchiverap-maven) and drives its Maven Wrapper build, then
  installs four Tomcat instances under a single systemd service: `mgmt` (17665),
  `engine` (17666), `etl` (17667), `retrieval` (17668).
- The source WARs are site-built: the default `als` site overlay is copied into
  the source tree before the build (built in; no operator action — override
  `ARCHAPPL_SITEID` only for a different site), so each WAR carries the site
  `classpathfiles`.
- The runtime uses the shared Tomcat as a read-only `CATALINA_HOME`; each
  instance is a writable `CATALINA_BASE` under the install location.

## Host prerequisites (provided by the host, not by aa-env)

- JDK 21 with `JAVA_HOME` at the distribution path.
- Tomcat 9.0.121 as a shared `CATALINA_HOME` at `/opt/tomcat9`, readable and
  executable by the service user (dirs `r-x`, `bin/*.sh` executable, `lib/*.jar`
  readable). No Tomcat service runs; aa-env uses the binaries only.
- MariaDB reachable over the IPv4 loopback (`127.0.0.1:3306`, `skip-name-resolve`
  on), with the configuration database and the application account already
  created (account host-spec `@'127.0.0.1'`; password equal to `DB_USER_PASS`,
  set in Configuration below).
- Build tools: `git`, `make`, `unzip`, `sed`, `tree`, and `curl` or `wget`.
  The launcher's `loglevel` command needs `curl` on the appliance host.
  `scripts/install_os_packages.bash` is skipped when the host supplies these.
- Linux process monitoring requires Bash 4.4 or newer, coreutils and readable
  `/proc` process state, executable links and arguments for the service account.
- Outbound network for the build: the `git` clone of the source, and the Maven
  Wrapper (3.9.16) plus dependency downloads into a cold `~/.m2`.
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

An operator-reported test with a 256 MiB heap override ran 10 scalar PVs at
1 Hz each for approximately 21 hours on a 3.58 GiB Rocky Linux VM with MariaDB
and no swap, with no reported OOM or JVM restart. That result covers the tested
light workload; it does not validate the changed default through deployment or
establish capacity for arrays, larger PV populations or sustained retrieval.
See [the heap verification record](milestone-265f580.md#m22---size-the-jvm-heap-default-to-the-host)
for the deployment basis, measurement limits and pending default-install test.
Validate the intended workload before using this value as an operating default.

Set `AA_JAVA_HEAPSIZE` in `../CONFIG_SITE.local` when the measured workload
needs a different heap. Both heap options follow this value; for example,
`512M` means 2 GiB of heap across four instances, plus up to 1 GiB of metaspace.

## Configuration (variable placement)

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
- Toolchain (`JAVA_HOME`, `TOMCAT_HOME`): set through the OS preset
  (`make <os>.conf` writes `configure/CONFIG_SITE.local` to include
  `configure/os/<os>.mk`), or set them in `../CONFIG_SITE.local`. Do not place
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

## Ordered sequence

`U` runs as an ordinary build user; `R` requires root (an automation role that
runs every step as root is also valid — the internal `sudo` is a no-op when
already root). Do not run `make build` wholesale; it bundles `conf.storage`.

| # | Target | Priv | Inputs | Writes | Check |
| --- | --- | --- | --- | --- | --- |
| 1 | `make init` | U | `SRC_TAG`, `SRC_URL` | source clone `epicsarchiverap-maven-src` | source `HEAD` at `SRC_TAG` |
| 2 | `make db.conf` | U | `DB_*` | `site-template/mariadb.conf` | file exists (`make db.conf.show`) |
| 3 | `make conf.archapplproperties` | U | `ARCHAPPL_*` (incl. `ARCHAPPL_*_PORT`, default 17665-17668) | `site-template/*` and source `classpathfiles` | files exist (`make conf.archapplproperties.show`) |
| 4 | `make build.mvn` | U | source clone, `JAVA_HOME` | four WARs and the Tomcat log4j jar set in `epicsarchiverap-maven-src/target` | four `*-{mgmt,engine,etl,retrieval}.war`; `target/tomcat-log4j` holds `log4j-api`, `log4j-core`, `log4j-appserver` and `log4j-jul` |
| 5 | `make sql.fill` | U | `DB_USER`/`DB_USER_PASS`, source SQL | schema loaded over TCP | `make sql.show` lists the tables |
| 6 | `make conf.storage` | R | `ARCHAPPL_STORAGE_TOP` | `/arch/{sts,mts,lts}/ArchiverStore` | directories exist, owned by the service user |
| 7 | `make install` | R | WARs, `AA_USERID`/`AA_GROUPID` | four instances, appliance service, health service and timer | units installed; appliance and timer enabled, not started |
| 8 | `make sd_start` | R | installed units and complete instance configuration | appliance and health timer started | timer active; process checks after startup allowance; separate mgmt probe returns HTTP 200 |

Notes:
- `make install` creates the service account (idempotent), stops any existing
  health timer/check before changing files, then installs the appliance and
  health pair. It reloads systemd before enabling the appliance and timer, with
  no implicit start. Run `make sd_start` after every install, including an
  install on an already-running appliance, to start the timer explicitly.
- The enabled timer is also wanted by the appliance service, so a direct
  `systemctl start epicsarchiverap-maven.service` starts monitoring. Enabling a
  timer does not retroactively activate it for an already-running appliance.
- The unit declares `Requires=mariadb.service`, so that unit must resolve on the
  host.
- The database and account are created by the host; the sequence therefore skips
  `db.secure`, `db.addAdmin`, and `db.create` and runs only `sql.fill`.

## Ownership boundary

- aa-env owns: `/opt/epicsarchiverap-maven` (the four instances,
  `CATALINA_BASE`), `/arch` (storage), `epicsarchiverap-maven.service`, and the
  `epicsarchiverap-maven-health.service` / `.timer` pair. Instance and storage
  files are owned by `AA_USERID:AA_GROUPID`; unit files are installed mode 0644
  through the privileged systemd install targets.
- The host owns: `/opt/tomcat9` (`CATALINA_HOME`, read-only to aa-env), the
  MariaDB service and the application account, the base packages, and the service
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
  `make conf.archapplproperties` and `make install` again, then restart. A
  site that needs another layout, or level changes without a restart, keeps a
  copy of the WAR's `log4j2.xml` on the host, taken from an installed
  instance such as
  `/opt/epicsarchiverap-maven/mgmt/webapps/mgmt/WEB-INF/classes/log4j2.xml`
  (the copy keeps the file's `monitorInterval="30"`), names it in `ARCHAPPL_LOG4J_SITE_FILE`, and
  reinstalls once; `archappl.conf` then
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
  exit 1 names invalid/missing instances; exit 2 reports incomplete inspection.
  The recurring health service reports failures independently of the appliance
  service. A successful or skipped oneshot becomes inactive, so inactive alone
  is not proof of four healthy processes. Inspect its journal and exit status.
- HTTP readiness: `curl http://<host>:17665/mgmt/bpl/getApplianceInfo` returns HTTP 200.
- Functional verification (archive a PV, then retrieve its samples through the
  mgmt and retrieval endpoints) is the M8/G5 runtime check, which owns the full
  procedure, the time-range parameters, and the archiving-delay wait; it is out
  of scope for this install sequence.

Monitoring neither restarts nor protects surviving JVMs after a failure. Existing
MainPID handling and component dependencies still apply. See the
[systemd operating contract](technicaldocs/README.systemd.md#process-monitoring)
for timing, skip results, operator recovery and monitor-only removal, and the
[VM test procedure](../tests/README.md#process-monitoring-vm-verification)
for runtime acceptance. Current verification evidence is maintained in
[M23](milestone-265f580.md#m23---make-a-dead-instance-visible-to-systemd).
