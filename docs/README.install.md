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
  `scripts/install_os_packages.bash` is skipped when the host supplies these.
- Outbound network for the build: the `git` clone of the source, and the Maven
  Wrapper (3.9.16) plus dependency downloads into a cold `~/.m2`.
- The service group and user (`AA_GROUPID`, `AA_USERID`) may be pre-created; the
  install leaves an existing group/user unchanged.

## Configuration (variable placement)

- `configure/RELEASE.local`: `SRC_TAG` — the source pin for
  https://github.com/jeonghanlee/epicsarchiverap-maven (a commit, tag, or branch). `SRC_URL` has a default (`https://github.com/jeonghanlee`) and
  is overridden here only when the source is hosted elsewhere. This file is not
  rewritten by the per-OS config targets.
- `../CONFIG_SITE.local` (one directory above the checkout top): `AA_USERID`,
  `AA_GROUPID`, `DB_NAME`, `DB_USER`, `DB_USER_PASS`, `DB_HOST_NAME` (`127.0.0.1`),
  `DB_HOST_PORT`, and any `ARCHAPPL_*` overrides. This file is included first and
  survives the per-OS config target that rewrites `configure/CONFIG_SITE.local`.
- Toolchain (`JAVA_HOME`, `TOMCAT_HOME`): set through the OS preset
  (`make <os>.conf` writes `configure/CONFIG_SITE.local` to include
  `configure/os/<os>.mk`), or set them in `../CONFIG_SITE.local`. Do not place
  overrides in `configure/CONFIG_SITE.local` when `make <os>.conf` is used, since
  that target overwrites the file.

## Ordered sequence

`U` runs as an ordinary build user; `R` requires root (an automation role that
runs every step as root is also valid — the internal `sudo` is a no-op when
already root). Do not run `make build` wholesale; it bundles `conf.storage`.

| # | Target | Priv | Inputs | Writes | Check |
| --- | --- | --- | --- | --- | --- |
| 1 | `make init` | U | `SRC_TAG`, `SRC_URL` | source clone `epicsarchiverap-maven-src` | source `HEAD` at `SRC_TAG` |
| 2 | `make db.conf` | U | `DB_*` | `site-template/mariadb.conf` | file exists (`make db.conf.show`) |
| 3 | `make conf.archapplproperties` | U | `ARCHAPPL_*` (incl. `ARCHAPPL_*_PORT`, default 17665-17668) | `site-template/*` and source `classpathfiles` | files exist (`make conf.archapplproperties.show`) |
| 4 | `make build.mvn` | U | source clone, `JAVA_HOME` | four WARs in `epicsarchiverap-maven-src/target` | four `*-{mgmt,engine,etl,retrieval}.war` |
| 5 | `make sql.fill` | U | `DB_USER`/`DB_USER_PASS`, source SQL | schema loaded over TCP | `make sql.show` lists the tables |
| 6 | `make conf.storage` | R | `ARCHAPPL_STORAGE_TOP` | `/arch/{sts,mts,lts}/ArchiverStore` | directories exist, owned by the service user |
| 7 | `make install` | R | WARs, `AA_USERID`/`AA_GROUPID` | `/opt/epicsarchiverap-maven/{mgmt,engine,etl,retrieval}`, the systemd unit | instances present; unit installed and enabled |
| 8 | `make sd_start` | R | the systemd unit | service started | mgmt probe returns HTTP 200 |

Notes:
- `make install` also creates the service account (idempotent) and installs and
  enables the systemd unit `epicsarchiverap-maven.service`; only `make sd_start`
  is a separate step.
- The unit declares `Requires=mariadb.service`, so that unit must resolve on the
  host.
- The database and account are created by the host; the sequence therefore skips
  `db.secure`, `db.addAdmin`, and `db.create` and runs only `sql.fill`.

## Ownership boundary

- aa-env owns: `/opt/epicsarchiverap-maven` (the four instances,
  `CATALINA_BASE`), `/arch` (storage), and `epicsarchiverap-maven.service` (the
  only service). `make install` and `conf.storage` chown these to
  `AA_USERID:AA_GROUPID`.
- The host owns: `/opt/tomcat9` (`CATALINA_HOME`, read-only to aa-env), the
  MariaDB service and the application account, the base packages, and the service
  group and user when pre-created.

## Health check

- Liveness: `curl http://<host>:17665/mgmt/bpl/getApplianceInfo` returns HTTP 200.
- Functional verification (archive a PV, then retrieve its samples through the
  mgmt and retrieval endpoints) is the M8/G5 runtime check, which owns the full
  procedure, the time-range parameters, and the archiving-delay wait; it is out
  of scope for this install sequence.
