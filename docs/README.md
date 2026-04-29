# EPICS Archiver Appliance Documentation

Detailed guides covering storage architecture, policy configuration, and the lifecycle of archived data.

## Documents

| Document | Purpose | Best for |
| :--- | :--- | :--- |
| [Storage & Policy Configuration Guide](./README.policies.md) | Reference for storage tiers (STS/MTS/LTS), URL-style parameters (`partitionGranularity`, `hold`, `gather`), data processing operators, and `policies.py`. | Setting up policies, choosing math operators, tuning sampling rates. |
| [The Data Journey](./README.DataJourney.md) | Conceptual ETL timeline (T1–T6) showing how data physically moves through the system over time. | Understanding why data is or is not yet in MTS, visualizing how `hold` and `gather` interact. |

## Quick Lookup

| Goal | Recommended Document |
| :--- | :--- |
| Set up `policies.py` or change the sampling rate. | [Storage & Policy Configuration Guide](./README.policies.md) |
| Find which mathematical functions are available. | [Storage & Policy Configuration Guide](./README.policies.md) |
| Diagnose why data is not moving to MTS yet. | [The Data Journey](./README.DataJourney.md) |
| Visualize how the `hold` buffer works over time. | [The Data Journey](./README.DataJourney.md) |
