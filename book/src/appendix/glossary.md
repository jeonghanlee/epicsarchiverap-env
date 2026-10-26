# Glossary of terms used in the book

The terms below are the names that the repository and the source use. Each definition is the meaning that the pages of this book give the term.

| Term | Definition |
| :--- | :--- |
| active | A file whose partition contains the current time and that receives samples |
| appliance | One installation of the four components on one host, named by its identity in `appliances.xml` (`appliance0` by default) |
| archive request | The request to archive a PV; the `mgmt` workflow handles it from `Initial sampling` to `Being archived` |
| archive root | The folder `ARCHAPPL_STORAGE_TOP`, default `/arch`, below which the three store folders lie by default |
| arrive | A file arrives in a store when its first sample, or its first part, is written to that store |
| BPL | The set of management actions that a component serves under `<component>/bpl`; `mgmt` registers them in its `BPLServlet` |
| cadence | The length of the source partition of a transition, at most 8 hours; the pass start times are multiples of it |
| caget | The EPICS command that reads the value of a PV once; the soft IOC test of the installers needs it |
| candidate | A file that a pass considers: its partition starts before the partition that contains the processing time |
| CI | Continuous integration: the automated build and unit tests that the source repository runs for every commit |
| completed | An STS file whose partition is over, or an MTS file that is full |
| component | One of the four web applications of the appliance: `mgmt`, `engine`, `etl`, `retrieval` |
| consolidate | Move the data of a store into the next store when the application stops (`consolidateOnShutdown`) or on request |
| driver | The unit of the ETL scheduler for one pair of transition and cadence; its passes run the jobs of all PVs of that pair |
| drop-in | A systemd file in a `<unit>.service.d/` folder that adds settings to a unit; the installer writes `override.conf` for `tomcat9.service` |
| eligible | A candidate that the pass moves: its first sample is at or before the gather boundary and the oldest candidate that holds a sample has passed the hold boundary |
| engine | The component that connects to PVs and writes their samples to the short term store |
| EPICS | Experimental Physics and Industrial Control System, the control system software whose process variables the appliance archives |
| EPICS Base | The EPICS software package that provides `softIoc` and `caget`; `EPICS_BASE` names its folder |
| ETL | Extract, transform, load: the component and the process that move data from one store to the next as it ages |
| full | A file that holds all samples of its partition: an STS file when its partition is over, an MTS file when its last part has arrived |
| gather | The setting of a store that sets the boundary for the files that move after the oldest candidate that holds a sample has satisfied `hold`; every candidate at or before that boundary moves |
| gather boundary | The time that a candidate is compared with to decide whether it moves, computed from the processing time and `hold - (gather - 1)` partitions |
| health check | The verification by `archappl.bash health` that the four processes belong to the installation and that the stores have free space |
| health timer | The systemd timer `epicsarchiverap-maven-health.timer` that runs the scheduled health check |
| hold | The setting of a store that tells how many further partitions of the store must elapse after the partition of a file before the file can move out |
| hold boundary | The time that the oldest candidate that holds a sample is compared with, computed from the processing time and `hold` partitions |
| identity | The name of an appliance in `appliances.xml` |
| installation directory | `AA_INSTALL_LOCATION`, default `/opt/epicsarchiverap-maven` |
| instance | One of the four Tomcat instances of the appliance, the same as a component: `mgmt`, `engine`, `etl` or `retrieval`; each has its own folder under `AA_INSTALL_LOCATION` |
| IOC | Input/output controller: a process that serves process variables to the control system; a soft IOC does so without hardware |
| JDK | Java Development Kit; the repository requires version 21, named by `JAVA_HOME` |
| JVM | Java virtual machine; each of the four instances runs in its own |
| LTS | The long term store, the last store of the chain |
| mgmt | The component that accepts management requests, runs the archive request workflow and serves the management pages |
| move | Append the samples of a source file to a file of the destination, then delete the source file |
| MTS | The medium term store, between the short and the long term store |
| offset | 5 minutes times (transition number + 1), added to the multiples of the cadence to give the pass start times |
| over | A partition is over when its time span has ended |
| overrun | A pass that ends after the next scheduled time of its transition; the scheduled times inside the pass are skipped |
| part | A source file that is appended to a destination file is one part of that file |
| partial | An MTS file that has received only some of its parts |
| partition | The time span that one file of a store covers, set by `partitionGranularity` |
| pass | One run of the ETL jobs of the PVs that share a transition and a cadence |
| payload | The files that the installer puts under `AA_INSTALL_LOCATION`: the four instance folders, the configuration files and `archappl.bash` |
| PID | Process identifier; the file `temp/<component>.pid` of an instance holds its PID |
| pin | A commit hash set in `SRC_TAG` so that every build uses the same source; the default `origin/modernize` follows the source branch instead |
| policy | A named set of sampling and store settings that `policies.py` selects for a PV |
| processing time | The time that a pass uses as its current time: the start of the pass minus 60 seconds; `T_PROCESS` on the page of the data journey |
| PV | A process variable of the control system that the appliance archives |
| reduction | Keeping a reduced form of the data when it moves into a store (`reducedata`), for example the last sample of each 30 seconds |
| retrieval | The component that serves stored data |
| sampling method | `MONITOR`, which stores each change, or `SCAN`, which stores at a fixed period |
| service account | The user and group, `tomcat` by default, that own the installed files and run the instances; `AA_USERID` and `AA_GROUPID` name them |
| site folder | The folder `site-template/siteid` that the build applies to the source tree for one site |
| soft IOC | A software input/output controller that serves PVs without hardware; `verify-local-pv.bash` starts one |
| softIoc | The EPICS program that runs a soft IOC; `verify-local-pv.bash` starts it for the test |
| source tree | The clone of the source repository under `SRC_PATH` |
| SRC_TAG | The source commit or branch that the installer fetches and builds; the default is `origin/modernize` |
| start-up pass | The pass that each driver with at least one PV runs when the ETL starts |
| store | A folder tree of data files that a `pb://` URL describes: STS, MTS or LTS |
| STS | The short term store, which receives the samples that `engine` writes |
| TCP | Transmission Control Protocol; one of the two ways the MariaDB installers reach the database, over the loopback address |
| transition | The move from one store to the next: STS to MTS, and MTS to LTS |
| URL | Uniform resource locator; the `pb://` form of a store is such a locator |
| VM | Virtual machine; the fresh guest on which the VM verification operations run |
| VM driver | The script `tests/vm/driver.py`; it runs the operations of a VM test run: initialize, case, cleanup verification and verdict |
| WAR | The web application archive that the source build produces for each component |
