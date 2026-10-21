# Build and install stages of the repository

The repository turns the source commit that `SRC_TAG` selects and a set of site inputs into four web application archive (WAR) files, and it installs them as a systemd-managed appliance. This page lists the stages, in order, and the target that runs each one.

## The stages of build and install

| Stage | Target | What it does |
| :--- | :--- | :--- |
| 1. Fetch the source | `make init` | Runs `clone`, which clones `SRC_GITURL` into `SRC_PATH` and checks out the reference `SRC_TAG`, and `update`, which runs `git submodule update --init`. |
| 2. Generate the configuration | `make conf` | Runs `conf.archapplproperties` and `conf.storage`, whose commands run with `sudo`. It writes `appliances.xml`, `archappl.properties` and `policies.py` from their `.in` templates and prepares the storage folders. |
| 3. Apply the site inputs | `copy.sitespecific` | Replaces `src/sitespecific/<site_id>` of the source tree with `site-template/siteid`, where `<site_id>` is the value of `ARCHAPPL_SITEID`. |
| 4. Build the WARs | `make build.mvn` | Runs `mvnw clean package -DskipTests` in the source tree with `ARCHAPPL_SITEID` set. |
| 5. Render the units | `make conf.install` | Runs as the checkout owner: renders the systemd override, service and health units from their `.in` templates and records the source commit in `site-template/.versions`. |
| 6. Install | `make install` | Runs as root: stops the health monitor, installs the four instances, the generated configuration files and the units of stage 5, and enables the service. It renders nothing into the checkout and stops, naming `make conf.install`, when a unit of stage 5 is missing or older than its template or the configuration. |

`make build` runs stage 2 and then stage 4, which runs stage 3 first, so one target covers everything up to the WAR files. `make install` does not build.

## What stage 2 writes

The three generated files are copied into `site-template/siteid/classpathfiles`. The source build packs that folder into the WAR files, so the files are part of every web application. A second copy of each file is installed into `AA_INSTALL_LOCATION`.

| File | Template | Carries |
| :--- | :--- | :--- |
| `appliances.xml` | `appliances.xml.in` | The identity and the addresses of the components |
| `archappl.properties` | `archappl.properties.in` | The engine and the retrieval properties, for example the minimum sampling period |
| `policies.py` | `policies.py.in` | The storage policies and the store uniform resource locators (URLs) |

`conf.storage` runs with `sudo`: it creates `ARCHAPPL_STORAGE_TOP` and the three store folders. The target `conf.archapplproperties` generates the files without `sudo`; `make conf.archapplproperties build.mvn` therefore builds the WAR files without touching the storage folders.

## What stage 6 installs

The dry run `make -n install` lists the steps, in order:

1. Install the instances `mgmt`, `engine`, `etl` and `retrieval` under `AA_INSTALL_LOCATION`.
2. Install `archappl.conf`, `appliances.xml`, `archappl.properties` and `policies.py` into `AA_INSTALL_LOCATION`.
3. Write the port numbers of `appliances.xml` into the `server.xml` of each instance.
4. Install `scripts/archappl.bash` into `AA_INSTALL_LOCATION`.
5. Install the systemd override, service and health units that stage 5 rendered, reload systemd, and enable the service.

The page [Files of an installation](../configure/installed-files.md) lists the result.
