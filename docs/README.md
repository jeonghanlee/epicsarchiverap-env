# EPICS Archiver Appliance Documentation

Detailed guides covering installation, storage architecture, policy configuration, and the lifecycle of archived data.

## Documents

| Document | Purpose | Best for |
| :--- | :--- | :--- |
| [Installation guide](./README.install.md) | Local SQLite, MariaDB UDS, and MariaDB TCP installers, configuration inputs, and the ordered Make sequence. | Installing a systemd appliance or preparing an automated deployment. |
| [Management interface](./README.interface.md) | Where the pages of the management interface are described, and what this repository keeps: the site skin and the static checks. | Operating the appliance through its pages, or skinning them for a site. |
| [Storage & Policy Configuration Guide](./README.policies.md) | Reference for storage tiers (STS/MTS/LTS), URL-style parameters (`partitionGranularity`, `hold`, `gather`), data processing operators, and `policies.py`. | Setting up policies, choosing math operators, tuning sampling rates. |
| [VM installation and runtime tests](./README.vmtests.md) | Design of the VM test driver: components, run and case model, guest handoff, cleanup verification and verdict. | Running or reviewing the VM acceptance tests. |
| [Automated tests](../tests/README.md) | Test phases, how to run them, real EPICS Base binaries, and what each check verifies. | Running the local suite or interpreting its results. |
| [Technical references](./technicaldocs/README.systemd.md) | Systemd unit and health monitoring ([systemd](./technicaldocs/README.systemd.md)), MariaDB connection and accounts ([MariaDB](./technicaldocs/README.mariadb.md)), Tomcat 9 ([Tomcat](./technicaldocs/README.tomcat.md)), Rocky Linux 8 values and verified scope ([Rocky 8](./technicaldocs/README.rocky8.md)). | Looking up how the service, the database or Tomcat is wired, or what is specific to Rocky Linux 8. |
| [The Data Journey](./README.DataJourney.md) | Conceptual ETL timeline (T1–T6) showing how data physically moves through the system over time. | Understanding why data is or is not yet in MTS, visualizing how `hold` and `gather` interact. |
| [Appliance book](../book/src/index.md) | mdBook written from the code: components, install and operate procedures, reference tables and a glossary. Render it with `mdbook build book`. | Learning the appliance end to end and looking up variables, targets and options. |

## Quick Lookup

| Goal | Recommended Document |
| :--- | :--- |
| Install a local appliance with SQLite or MariaDB. | [Local systemd installation](./README.install.md#local-systemd-installation) |
| Learn what a status on the System pages means and when it turns to Attention or Problem. | [Management interface](https://github.com/jeonghanlee/epicsarchiverap-maven/blob/modernize/docs/book/src/interface.md) |
| Set up `policies.py` or change the sampling rate. | [Storage & Policy Configuration Guide](./README.policies.md) |
| Find which mathematical functions are available. | [Storage & Policy Configuration Guide](./README.policies.md) |
| Diagnose why data is not moving to MTS yet. | [The Data Journey](./README.DataJourney.md) |
| Visualize how the `hold` buffer works over time. | [The Data Journey](./README.DataJourney.md) |
