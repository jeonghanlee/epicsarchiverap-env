# Glossary of terms used in the book

The terms below are the names that the repository and the source use. Each definition is the meaning that the pages of this book give the term.

| Term | Definition |
| :--- | :--- |
| appliance | One installation of the four components on one host, named by its identity in `appliances.xml` (`appliance0` by default) |
| archive request | The request to archive a PV; the `mgmt` workflow handles it from `Initial sampling` to `Being archived` |
| BPL | The set of management actions that a component serves under `<component>/bpl`; `mgmt` registers them in its `BPLServlet` |
| CI | Continuous integration: the automated build and unit tests that the source repository runs for every commit |
| component | One of the four web applications of the appliance: `mgmt`, `engine`, `etl`, `retrieval` |
| consolidate | Move the data of a store into the next store when the application stops (`consolidateOnShutdown`) or on request |
| engine | The component that connects to PVs and writes their samples to the short term store |
| EPICS | Experimental Physics and Industrial Control System, the control system software whose process variables the appliance archives |
| ETL | The component and the process that move data from one store to the next as it ages |
| gather | The number of partitions that ETL moves at one time out of a store |
| health check | The verification by `archappl.bash health` that the four processes belong to the installation and that the stores have free space |
| hold | The number of partitions that a store keeps before ETL starts moving data out of it |
| identity | The name of an appliance in `appliances.xml` |
| installation directory | `AA_INSTALL_LOCATION`, default `/opt/epicsarchiverap-maven` |
| IOC | Input/output controller: a process that serves process variables to the control system; a soft IOC does so without hardware |
| JDK | Java Development Kit; the repository requires version 21, named by `JAVA_HOME` |
| JVM | Java virtual machine; each of the four instances runs in its own |
| LTS | The long term store, the last store of the chain |
| mgmt | The component that accepts management requests, runs the archive request workflow and serves the management pages |
| MTS | The medium term store, between the short and the long term store |
| partition | The time span that one file of a store covers, set by `partitionGranularity` |
| PID | Process identifier; the file `temp/<component>.pid` of an instance holds its PID |
| pin | A commit hash set in `SRC_TAG` so that every build uses the same source; the default `origin/modernize` follows the source branch instead |
| policy | A named set of sampling and store settings that `policies.py` selects for a PV |
| PV | A process variable of the control system that the appliance archives |
| reduction | Keeping a reduced form of the data when it moves into a store (`reducedata`), for example the last sample of each 30 seconds |
| retrieval | The component that serves stored data |
| sampling method | `MONITOR`, which stores each change, or `SCAN`, which stores at a fixed period |
| site folder | The folder `site-template/siteid` that the build applies to the source tree for one site |
| soft IOC | A software input/output controller that serves PVs without hardware; `verify-local-pv.bash` starts one |
| source tree | The clone of the source repository under `SRC_PATH` |
| store | A folder tree of data files that a `pb://` URL describes: STS, MTS or LTS |
| STS | The short term store, which receives the samples that `engine` writes |
| TCP | Transmission Control Protocol; one of the two ways the MariaDB installers reach the database, over the loopback address |
| URL | Uniform resource locator; the `pb://` form of a store is such a locator |
| VM | Virtual machine; the fresh guest on which the VM verification operations run |
| WAR | The web application archive that the source build produces for each component |
