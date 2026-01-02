# EPICS Archiver Appliance Documentation

This directory contains detailed guides regarding storage architecture, policy configuration, and the internal lifecycle of archived data.

Select a document below to view detailed information.


## Core Documentation

### 1. [Storage & Policy Configuration Guide](./README.policies.md)

This document is the primary reference for configuring the Archiver Appliance. It covers the technical details of storage tiers, mathematical post-processing, and the python-based policy logic.

* Storage Architecture: Detailed definitions of STS, MTS, and LTS tiers.
* Configuration Parameters: Explanation of URL-style parameters like `partitionGranularity`, `hold`, and `gather`.
* Data Processing: Full list of mathematical operators (e.g., `mean`, `optimized`) for retrieval and ETL reduction.
* Policy Script: How to configure `policies.py` for sampling rates (Monitor vs. Scan) and field archiving.

### 2. [The Data Journey](./README.DataJourney.md)

This document provides a conceptual overview of how data physically moves through the system over time. It uses a concrete timeline scenario to visualize the ETL process.

* Visualizing ETL: Step-by-step illustrations of data movement from T1 to T6.
* File States: Understanding "Active" vs. "Completed" `.pb` files.
* Logic Explanation: A deep dive into how `hold` and `gather` parameters interact to trigger data migration.
* Best for: Users who want to understand the *logic* behind data movement before configuring it.

## Quick Summary: Which guide do I need?

| Goal | Recommended Document |
| :--- | :--- |
| "I need to set up `policies.py` or change the sampling rate." | [**Configuration Guide**](./README.policies.md) |
| "I want to know which mathematical functions are available." | [**Configuration Guide**](./README.policies.md) |
| "I don't understand why my data isn't moving to MTS yet." | [**The Data Journey**](./README.DataJourney.md) |
| "I want to visualize how the `hold` buffer works." | [**The Data Journey**](./README.DataJourney.md) |
