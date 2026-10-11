# What the repository builds and installs

The repository turns the source commit that `SRC_TAG` selects and a set of site inputs into four WAR files, and it installs them as a systemd-managed appliance. This page lists the stages, in order, and the target that runs each one.

## The stages of build and install

| Stage | Target | What it does |
| :--- | :--- | :--- |
| 1. Fetch the source | `make init` | Runs `clone`, which clones `SRC_GITURL` into `SRC_PATH` at the commit `SRC_TAG`, and `update`, which runs `git submodule update --init`. |
| 2. Generate the configuration | `make conf` | Runs `conf.archapplproperties` and `conf.storage`. It writes `appliances.xml`, `archappl.properties` and `policies.py` from their `.in` templates and prepares the storage folders. |
| 3. Apply the site inputs | `copy.sitespecific` | Replaces `src/sitespecific/<ARCHAPPL_SITEID>` of the source tree with `site-template/siteid`. |
| 4. Apply the interface files | `copy.ui` | Copies `site-template/ui` over `src/main/org/epics/archiverappliance` of the source tree. |
| 5. Build the WARs | `make build.mvn` | Runs `mvnw clean package -DskipTests` in the source tree with `ARCHAPPL_SITEID` set. |
| 6. Install | `make install` | Stops the health monitor, installs the four instances, the generated configuration files and the systemd units, and enables the service. |

`make build` runs stage 2 and then stage 5, which runs stages 3 and 4 first, so one target covers everything up to the WAR files. `make install` does not build.

## What stage 2 writes

The three generated files are copied into `site-template/siteid/classpathfiles`. The source build packs that folder into the WAR files, so the files are part of every web application. A second copy of each file is installed into `AA_INSTALL_LOCATION`.

| File | Template | Carries |
| :--- | :--- | :--- |
| `appliances.xml` | `appliances.xml.in` | The identity and the addresses of the components |
| `archappl.properties` | `archappl.properties.in` | The engine and the retrieval properties, for example the minimum sampling period |
| `policies.py` | `policies.py.in` | The storage policies and the store URLs |

`conf.storage` runs with `sudo`: it creates `ARCHAPPL_STORAGE_TOP` and the three store folders. The target `conf.archapplproperties` generates the files without `sudo`; `make conf.archapplproperties build.mvn` therefore builds the WAR files without touching the storage folders.

## What stage 6 installs

The dry run `make -n install` lists the steps, in order:

1. Record the source commit in `site-template/.versions`.
2. Install the instances `mgmt`, `engine`, `etl` and `retrieval` under `AA_INSTALL_LOCATION`.
3. Install `archappl.conf`, `appliances.xml`, `archappl.properties` and `policies.py` into `AA_INSTALL_LOCATION`.
4. Write the port numbers of `appliances.xml` into the `server.xml` of each instance.
5. Install `scripts/archappl.bash` into `AA_INSTALL_LOCATION`.
6. Generate and install the systemd override and service files, then enable the service.

The page [Files of an installation](../configure/installed-files.md) lists the result.
