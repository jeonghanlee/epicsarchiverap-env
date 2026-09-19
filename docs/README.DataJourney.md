---
title: The Data Journey in the EPICS Archiver Appliance
author: Sangil Lee & Jeong Han Lee
date: 2026-01-02
version: 1.0
---
# The Data Journey in the EPICS Archiver Appliance

**Author:** Sangil Lee & Jeong Han Lee

This document outlines the storage hierarchy and ETL logic of the Archiver Appliance, incorporating a timestamped scenario to illustrate how data moves over time.

## Executive Summary

The Archiver Appliance utilizes a three-tiered storage strategy to balance high-speed data acquisition with long-term capacity management. Data flows from high-speed Short Term Storage (STS), is consolidated into larger files in Middle Term Storage (MTS), and finally rests in permanent Long Term Storage (LTS).

The crucial logic determining **when and how much data to move** between these tiers is defined by the ETL rules: `hold` and `gather`.

## Scope

This document walks through a single concrete timeline (T1–T6) to show how the `hold` and `gather` parameters trigger data movement between STS, MTS, and LTS over time.

**Out of scope:**
* Numeric reference and parameter taxonomy — see [README.policies.md](README.policies.md).
* Operational deployment, system installation, and service management — see the project [README](../README.md).

## 1. Storage Tiers and File Units

Data moves through the following stages:

1.  **STS (Short Term Storage):**
    * Role: Designed for high-frequency writes, typically on fast media like RAMDisks or SSDs. Files here are temporary and meant for ETL migration.
    * File Unit: In this scenario, we use a `PARTITION_15MIN` granularity, meaning each `.pb` file holds 15 minutes of data.
2.  **MTS (Middle Term Storage):**
    * Role: An intermediate staging area that consolidates smaller files from STS into larger units. Data here is also temporary.
    * File Unit: Here, we use `PARTITION_30MIN`, consolidating two 15-minute files from STS into one 30-minute file.
3.  **LTS (Long Term Storage):**
    * Role: The final destination for the permanent archiving of historical data.

### Two Critical File States

Data files exist in one of two states based on time:

* **Active State:** The file is currently being written to, and its defined time duration has not yet elapsed.
* **Completed State:** The file belongs to a partition before the current partition. It can be an ETL candidate; its first sample timestamp is compared with the retention boundaries.


## 2. Data Movement Rules: ETL Flow Control

The rules for moving data between tiers are dictated by the `hold` and `gather` parameters. This example uses `hold=2` and `gather=1`.

The central logic guiding the movement is:

**Core rule: compare the first sample in each candidate file with time boundaries derived from the ETL evaluation time and the partition duration. File count is not the trigger.**

* The `hold` boundary is the last second of the partition preceding `evaluation time - hold * approximate partition duration`.
* The `gather` boundary uses `hold - (gather - 1)` partition durations in the same calculation. Once the oldest candidate satisfies `hold`, candidates whose first samples are at or before the gather boundary are selected.
* *Constraint:* Use nonnegative values with `hold >= gather`; equality is allowed. With both zero, the hold/gather boundary checks are skipped.
* Missing partitions and delayed ETL runs change the number of files selected. The figures show the continuous-data scenario below; their hold and gather cutoffs are timestamps, not file counts.

This description follows `PlainPBStoragePlugin.getETLStreams` and
`TimeUtils.getPreviousPartitionLastSecond` in aa-maven `35282494`.

## 3. Timeline Scenario: A Day in the Life of Data

Let's trace the journey of data with a concrete timeline to visualize the flow.

**Scenario Settings:**
* Start Time: 10:00:00 UTC, with a sample at each partition start and no missing partitions
* STS Partition: 15 minutes
* MTS Partition: 30 minutes
* ETL Rule: `hold=2`, `gather=1`
* Evaluation schedule: one ETL evaluation exactly at each 15-minute boundary; actual scheduling can delay a transfer

### [T1] 10:00:00 - 10:15:00 (The First 15 Minutes)
* **STS:** The first file, `File_1 (10:00-10:15)`, is created. Data is actively being written to it (Active State).

![T1: the first 15 minutes](./figures/T1.png)

*Figure 1 — T1, The First 15 Minutes*

### [T2] 10:15:00 - 10:30:00 (The Second 15 Minutes)
* **STS:** `File_1` completes its 15-minute span and moves to the Completed buffer.
    * Completed Buffer Count: 1 (`File_1`).
    * *Action at 10:15:* No move; the hold boundary is 09:44:59, earlier than `File_1`'s first sample at 10:00.
* **STS:** A new file, `File_2 (10:15-10:30)`, begins writing (Active State).

![T2: the second 15 minutes](./figures/T2.png)

*Figure 2 — T2, The Second 15 Minutes*

### [T3] 10:30:00 - 10:45:00 (The Third 15 Minutes)
* **STS:** `File_2` completes and enters the buffer.
    * Completed Buffer Count: 2 (`File_1`, `File_2`).
    * *Action at 10:30:* No move; the hold boundary is 09:59:59, still earlier than `File_1`'s first sample.
* **STS:** A new file, `File_3 (10:30-10:45)`, begins writing.

![T3: the third 15 minutes](./figures/T3.png)

*Figure 3 — T3, The Third 15 Minutes*

### [T4] Just After 10:45:00 (ETL Trigger Moment)
* **STS:** `File_3` completes and enters the buffer.
    * Completed Buffer Count: 3 (`File_1`, `File_2`, `File_3`).
    * *Trigger at 10:45:* The hold and gather boundaries are both 10:14:59. `File_1`'s first sample is before that boundary; the first samples in `File_2` and `File_3` are later.
    * *Action:* `File_1 (10:00-10:15)` is selected for transfer to MTS.
* **MTS:** `File_1` supplies the first half of the 30-minute partition covering `10:00-10:30`. That time partition has already ended; later STS transfers can still append data to it.

![T4: ETL trigger moment, just after 10:45:00](./figures/T4.png)

*Figure 4 — T4, Just After 10:45:00*


### [T5] Just After 11:00:00 (MTS Consolidation)
* **STS:** At 11:00 the boundaries advance to 10:29:59, so `File_2 (10:15-10:30)` becomes eligible for transfer to MTS.
* **MTS:** `File_2` arrives and is merged/appended with the waiting `File_1`.
* **Result:** The MTS file now contains both 15-minute contributions for `10:00-10:30`. Its onward eligibility uses the MTS partition duration, first sample timestamp, and ETL evaluation time; completion of the append is not a separate count-based trigger.

![T5: MTS consolidation, just after 11:00:00](./figures/T5.png)

*Figure 5 — T5, Just After 11:00:00*


### [T6] Long After T5 (Continuous Operation)

After a longer period, the system reaches a steady state where both STS and MTS buffers are full, and data is being continuously moved to LTS as new files are created. This final image illustrates the complete end-to-end data flow.

![T6: continuous operation, long after T5](./figures/T6.png)

*Figure 6 — T6, Long After T5*
