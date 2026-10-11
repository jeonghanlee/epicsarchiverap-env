# EPICS Archiver Appliance Documentation

Detailed guides covering installation, storage architecture, policy configuration, and the lifecycle of archived data.

## Documents

| Document | Purpose | Best for |
| :--- | :--- | :--- |
| [Installation guide](./README.install.md) | Local SQLite, MariaDB UDS, and MariaDB TCP installers, configuration inputs, and the ordered Make sequence. | Installing a systemd appliance or preparing an automated deployment. |
| [Management interface](./README.interface.md) | The pages of the management interface, what the System pages judge and its starting values, the limits, browser support, the build step and the site skin tokens. | Operating the appliance through its pages, or skinning them for a site. |
| [Storage & Policy Configuration Guide](./README.policies.md) | Reference for storage tiers (STS/MTS/LTS), URL-style parameters (`partitionGranularity`, `hold`, `gather`), data processing operators, and `policies.py`. | Setting up policies, choosing math operators, tuning sampling rates. |
| [The Data Journey](./README.DataJourney.md) | Conceptual ETL timeline (T1–T6) showing how data physically moves through the system over time. | Understanding why data is or is not yet in MTS, visualizing how `hold` and `gather` interact. |

## Quick Lookup

| Goal | Recommended Document |
| :--- | :--- |
| Install a local appliance with SQLite or MariaDB. | [Local systemd installation](./README.install.md#local-systemd-installation) |
| Learn what a status on the System pages means and when it turns to Attention or Problem. | [Management interface](./README.interface.md) |
| Set up `policies.py` or change the sampling rate. | [Storage & Policy Configuration Guide](./README.policies.md) |
| Find which mathematical functions are available. | [Storage & Policy Configuration Guide](./README.policies.md) |
| Diagnose why data is not moving to MTS yet. | [The Data Journey](./README.DataJourney.md) |
| Visualize how the `hold` buffer works over time. | [The Data Journey](./README.DataJourney.md) |
