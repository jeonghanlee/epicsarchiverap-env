---
title: EPICS Archiver Appliance Storage & Policy Configuration Guide
author: Sangil Lee & Jeong Han Lee
date: 2026-10-18
version: 1.1
---
# EPICS Archiver Appliance Storage & Policy Configuration Guide

**Author:** Sangil Lee & Jeong Han Lee

This document serves as a comprehensive technical guide for configuring the storage architecture and archiving policies of the EPICS Archiver Appliance. It details the mechanisms for managing data lifecycles across storage tiers and defining sampling logic.

## Executive Summary

The Archiver Appliance manages data through a sophisticated tiered storage model (STS, MTS, LTS), governed by precise URL-based configuration parameters (`partitionGranularity`, `hold`, `gather`). This guide explains how to configure these parameters to optimize data flow and storage efficiency.

Beyond storage, this document explores the system's data processing capabilities, distinguishing between real-time retrieval operations and permanent ETL-based data reduction (`reducedata`, `pp`). Finally, it provides a deep dive into the `policies.py` script, clarifying how sampling methods (Monitor vs. Scan) and field archiving rules are defined, applied, and managed throughout the service lifecycle.

## 1. Storage Tier Architecture
The Archiver Appliance utilizes a tiered storage strategy to balance high-speed data acquisition with long-term capacity management. Data moves between these tiers via the ETL service.

* **STS (Short Term Storage)**: Designed for high-frequency writes; typically resides on a RAMDisk or fast SSD to maximize I/O performance.
* **MTS (Middle Term Storage)**: An intermediate staging area where data is consolidated before being moved to long-term storage.
* **LTS (Long Term Storage)**: The final destination for permanent historical data.

## 2. Data Store Parameters
Storage tiers are configured using URL-style strings that define how files are partitioned, moved, and maintained across the STS, MTS, and LTS areas.

### 2.1 Core Settings
The following settings are used to define URL-style strings.

#### 2.1.1 Storage Volume Identification (`name`)
* `STS`: Short Term Storage. Used for temporary files before ETL processing.
* `MTS`: Middle Term Storage. Used for temporary files staged between STS and permanent storage.
* `LTS`: Long Term Storage. The final destination for permanent files.
* **Note on "Temporary"**: This indicates that the `.pb` file will be moved to the next destination by the ETL service in the first pass after its partition is over and the `hold` setting is satisfied by the oldest file that holds a sample (section 2.3 and [The Data Journey](./README.DataJourney.md)).

#### 2.1.2 Storage Location (`rootFolder`)
* Specifies the location of the top-level folder where each storage area is saved.
* Supports the use of different mounted file system areas for each tier to optimize hardware usage and performance.

#### 2.1.3 Time Indexing (`partitionGranularity`)
* An essential parameter for the ETL service that sets the time index of the `.pb` file created in each storage area.
* Predefined Intervals:

| Interval Name | Calculation Formula | Duration (Seconds) |
| :--- | :--- | :--- |
| `PARTITION_5MIN` | 5 * 60 | 300 |
| `PARTITION_15MIN` | 15 * 60 | 900 |
| `PARTITION_30MIN` | 30 * 60 | 1,800 |
| `PARTITION_HOUR` | 60 * 60 | 3,600 |
| `PARTITION_DAY` | 24 * 60 * 60 | 86,400 |
| `PARTITION_MONTH` | 31 * 24 * 60 * 60 | 2,678,400 |
| `PARTITION_YEAR` | 366 * 24 * 60 * 60 | 31,622,400 |

* **PB File Naming Logic**: The `.pb` file name is created based on **UTC time** with a directory path prefix.
    * Example (PV: `ApplTest:AN:F:Analog10`):
        * `STS` (`PARTITION_15MIN`): `ApplTest/AN/F/Analog10:2025_10_25_06_15.pb`
        * `MTS` (`PARTITION_HOUR`): `ApplTest/AN/F/Analog10:2025_10_25_06.pb`
        * `LTS` (`PARTITION_MONTH`): `ApplTest/AN/F/Analog10:2025_10.pb`

### 2.2 Data File States (.pb)
In the Archiver Appliance, data is stored in `.pb` (Protocol Buffer) files. Before understanding how data moves (ETL), it is crucial to understand that these files exist in two states based on the `partitionGranularity`: Active and Completed. In MTS a file can also be partial, which section 2.2.2 describes.

#### 2.2.1 Active State
* This state refers to the `.pb` file that is currently being written to.
* Data is actively being collected and appended to this file.
* The time duration defined by `partitionGranularity` for this file has not yet elapsed.

#### 2.2.2 Completed State
* In STS, this state refers to a `.pb` file whose partition defined by `partitionGranularity` is over. In MTS, it refers to a file that is full: it has received all STS files of its partition.
* An STS file is closed and considered a complete archive unit once its time elapses. An MTS file can become full after its partition is over, when the last STS file of the partition arrives.
* **Important**: Only files whose partition is over are subject to the `hold` parameter and subsequent ETL migration. The `hold` boundary is applied to these archived data files waiting to be moved.
* **Exception in MTS**: a partial file, which has received only some of the STS files of its partition, is not Completed, yet it is a candidate too (a candidate is a file that a pass considers for a move). ETL compares times only and does not check that a file is full ([The Data Journey](./README.DataJourney.md), Fullness).

### 2.3 ETL Flow Control
These parameters manage the movement of data between storage tiers. This process primarily interacts with files in the **Completed State**. When a pass runs and which files it moves is described in [The Data Journey](./README.DataJourney.md); this section defines the parameters.

#### 2.3.1 Definition of ETL Cycle
* The ETL Cycle, also called an ETL pass, is one run of the ETL jobs of the PVs that share a transition (e.g., `STS` → `MTS`) and a cadence (the interval between scheduled passes, defined under Pass schedule below). It moves a batch of data files (`.pb`) from one storage tier to the next.
* It is dynamically defined by the interaction of three key parameters:
    1.  **Unit**: The size of a single file, defined by `partitionGranularity`.
    2.  **Trigger**: A file moves in the first ETL pass whose processing time is at least `hold + 1` partition lengths after the start of the partition of the file (with `gather=1`). The processing time is the start of the pass minus 60 seconds, and the passes start at fixed times, not when a partition ends. The rule is exact for `PARTITION_5MIN` to `PARTITION_DAY`; `PARTITION_MONTH` and `PARTITION_YEAR` are calendar months and years, and the rule counts them as 31 and 366 days. The oldest file of the tier must also satisfy the rule ([The Data Journey](./README.DataJourney.md), What one pass moves).
    3.  **Batch Size**: The transfer boundary is set by `gather`; a pass that runs on schedule moves the files of `gather` partitions, and a late pass can move more.
* **Pass schedule**: The cadence of a transition is the partition length of its source tier, at most 8 hours. A pass starts at a multiple of the cadence counted from the Unix epoch plus 5 minutes times (transition number + 1); `STS` → `MTS` is transition 0 and `MTS` → `LTS` is transition 1. The first pass after the ETL starts, a scheduled time that falls inside a running pass, and a pass that waits for another pass are the exceptions described in The Data Journey. With the shipped partitions the passes from STS to MTS start at 5 minutes past each hour, and the passes from MTS to LTS start at 00:10, 08:10 and 16:10 UTC. A pass of the second transition waits for a running pass of the first, so when two start together the second starts at the first check after the first pass ends, 5 seconds later when that pass takes less than one check; the check is a timer that runs every 5 seconds ([The Data Journey](./README.DataJourney.md), When the ETL runs).

#### 2.3.2 Retention Period (`hold`)
* This parameter is directly related to the `partitionGranularity` setting.
* Specifies an **age**, not a file count: the implementation subtracts `hold` times the approximate partition duration from the processing time and takes the last second of the preceding partition as the boundary. A file becomes eligible when its first sample is at or before that boundary.
* Example: with `partitionGranularity=PARTITION_HOUR` and `hold=6`, the file of the partition that starts at 10:00 becomes eligible when the processing time reaches 17:00, seven partition lengths after the start of its partition. With `PARTITION_HOUR` on STS the passes from STS to MTS start at 5 minutes past each hour, so it moves in the pass at 17:05 (with `gather=1`; run on the ETL classes with `hold=6`, STS `PARTITION_HOUR` and MTS `PARTITION_DAY`: the 10:00 file left STS at 17:05, the 11:00 file at 18:05). A gap in the data does not postpone this; eligibility follows the oldest available sample's age, not how many files have accumulated.

#### 2.3.3 Batch Move Size (`gather`)
* This parameter is related to both the `partitionGranularity` and `hold` settings.
* The implementation computes a second boundary at `hold - (gather - 1)` partition durations and selects the files whose first samples are at or before it.
* Example: with `hold=6` and `gather=4`, continuous data and passes on schedule move 4 partitions in each move. A late pass can select more; missing partitions can yield fewer.

#### 2.3.4 Flow Constraints (`hold` vs. `gather`)
* Use nonnegative values with `hold >= gather`. Equality is allowed: the implementation rejects only `gather > hold`.
* `setHoldETLForPartions` and `setGatherETLinPartitions` throw an `IOException` when `hold - gather` would be negative.
* Both default to zero. With `hold=0` and `gather=0` the implementation skips these boundaries and takes the available candidates before the current partition. A file that has a header but no sample stops the job of its PV in this case ([The Data Journey](./README.DataJourney.md), Files without samples).

#### 2.3.5 Configuration Strategies and Impact
The behavior of the Archiver Appliance varies significantly based on how `hold` and `gather` are configured.

* **Scenario A: Without `hold` and `gather` (Unconfigured)**
    * No retention delay: both parameters default to zero, so the implementation skips the hold and gather boundaries and moves every available candidate in the first pass whose processing time is at or after the end of its partition (for example the 10:00 file of a 15-minute STS partition at 10:20).
    * File generation is unaffected: partitioning follows `partitionGranularity`. Leaving these settings out does not by itself make file creation irregular; it removes the delay before ETL takes the completed files.

* **Scenario B: With `hold` & `gather` (Custom Configuration)**
    * Consistency: Both data movement and data visualization become consistent and predictable.
    * Performance Tuning: A larger `hold` is beneficial when data extraction requires optimized reading performance from the storage media (by keeping more recent data in the faster tier before moving it).
    * As noted in flow constraints, setting `gather > hold` will immediately cause an `IOException`.

* **Scenario C: Optimized Configuration (Recommended)**
    * Best Practice: The setting `hold=2&gather=1` is recommended as the smoothest configuration for ETL data movement and data display.
    * This setting is particularly effective and recommended when the `STS` and `MTS` storage media are identical (e.g., both utilize the same high-speed storage volume).

## 3. Data Processing & Reduction
The Archiver Appliance utilizes the **Apache Commons Math** library to perform statistical analysis and data reduction. This processing capability is applied in two distinct stages:

1.  **Retrieval-Time**: Processing data "on-the-fly" when a user or client requests it (Temporary).
2.  **ETL-Time**: Pre-calculating or reducing data during the archiving process via `policies.py` (Permanent/Cached).

**Note**: While the mathematical operators described in Section 3.1 serve as shared building blocks, **not all operators may be applicable** to both stages. Users should verify compatibility when applying complex operators to ETL policies.

### 3.1 Processing during Data Retrieval (On-the-fly)
Users can request processed data directly through the retrieval URL without modifying the stored data.

#### 3.1.1 Usage & Binning Logic
* **Usage**: Specify the operator in the PV name request.
    * URL Example: `getData.json?pv=mean_3600(test:pv:123)`
    * Viewer Example: Plotting `mean_3600(test:pv:123)` applies the operator before rendering.
* **Binning Mechanism**: Algorithms group raw samples into "bins" based on a time interval (default 900s).
    * Logic: Uses integer division of the sample's epoch seconds.
    * Formula: Two samples ($S1, S2$) belong to the same bin if:
        $$S1.epoch / Interval == S2.epoch / Interval$$
    * Example: For `mean_3600`, all samples within 0-3599s form one bin, 3600-7199s form the next.

#### 3.1.2 Available Operators
The operators are the post-processors that the source registers; they are based on the **Apache Commons Math** library. The page [Retrieving data](https://jeonghanlee.github.io/epicsarchiverap-maven/retrieval.html#post-processing) of the source documentation lists each operator with its arguments and its result per bin, and is the reference. In summary:

* **Sampling**: `firstSample`, `lastSample`, `firstFill`, `lastFill`, `nth`.
* **Statistics**: `mean`, `min`, `max`, `count`, `ncount`, `std`, `variance`, `popvariance`, `rms`, `jitter`, `median`, `kurtosis`, `skewness`, `stats` (mean, standard deviation, minimum, maximum and count together) and `errorbar`. `median`, `kurtosis`, `skewness`, `linear` and `loess` keep all values of a bin in memory and use more resources.
* **Filtering**: `ignoreflyers` and `flyers` (second argument: number of standard deviations, default 3), `deadBand`.
* **Reduction to a number of points**: `optimized` and `optimLastSample` (default 1000 points). If the range holds no more events than that number, the raw events are returned.
* **Other**: `caplotbinning`, and the interpolations `linear` and `loess`, which evaluate at the centre of each bin.
* **Empty bins**: the statistics operators, `linear`, `loess` and `optimized` fill an empty bin with the previous value, except that `count` gives 0; `optimLastSample` fills it with the last recorded sample (mean, minimum and maximum equal to it, standard deviation and count 0). The variant with `Sample` appended (for example `meanSample`) leaves the bin empty.
* **References**:
    * [Apache Commons Math: StatisticalSummary](https://commons.apache.org/proper/commons-math/javadocs/api-3.6.1/org/apache/commons/math3/stat/descriptive/StatisticalSummary.html)
    * [Apache Commons Math: DescriptiveStatistics](https://commons.apache.org/proper/commons-math/javadocs/api-3.6.1/org/apache/commons/math3/stat/descriptive/DescriptiveStatistics.html)

### 3.2 Policy-Based Processing (ETL Configuration)
This section explains how to apply the operators from Section 3.1 permanently or for caching via `policies.py`.

**Constraint**: Do not set `reducedata` and `pp` on the same storage tier. The source accepts both without an error: the reduced data is stored first, and the `pp` files are then computed from the reduced files instead of the raw data, which the class comment of `PlainPBStoragePlugin` calls unpredictable ([epicsarchiverap-maven#50](https://github.com/jeonghanlee/epicsarchiverap-maven/issues/50)).

#### 3.2.1 Storage Optimization (`reducedata`)
The `reducedata` parameter applies operators to **permanently replace** raw data during the ETL process.

* **Core Purpose**: Significantly reduces storage consumption. The original raw data is lost.
* **Control Modes**:
    1.  Interval Time (e.g., `mean_300`): Divides data into fixed time blocks.
        * Calculation (1-hour query): $3600 \div 300 = 12$ data points.
    2.  Data Count (e.g., `optimized_500`): fixes the number of points of a retrieval. It is accepted without an error but does not apply in `reducedata`: one hour of 1 Hz data stored with `reducedata=optimized_500` gives 4 samples (bins of 900 seconds), not 500 ([epicsarchiverap-maven#49](https://github.com/jeonghanlee/epicsarchiverap-maven/issues/49)). Use an interval operator such as `mean_300` in `reducedata`.
* **Performance Trade-offs**:
    * Low Cost: `Min`, `Mean`, `Variance`, `Jitter`, `Count` (uses incremental `SummaryStatistics`).
    * High Cost: `Median`, `Kurtosis`, `Skewness`, `Linear`, `Loess` (requires storing full lists in memory).

#### 3.2.2 Retrieval Optimization (`pp`)
The `pp` (Post-Processor) parameter uses operators to **pre-calculate** results and save them in **separate files**.

* **Core Purpose**: Accelerates retrieval speed for heavy queries while preserving raw data.
* **Mechanism**: Creates an auxiliary file per partition, named like the `.pb` file of the partition with the operator in place of `pb` (for example `ApplTest/AN/F/Analog10:2025_10_25_06.mean_60`). An operator with a decimal argument carries it as written by the source: `pp=ignoreflyers_30_3` creates `…:2025_10_25_06.ignoreflyers_30_3.0`. The system serves this file when a request names exactly that operator: with the raw file deleted, a request for `mean_60` is answered from the pp file and a request for `mean_30` finds no data.
* **Advanced Configuration**:
    * Several operators: `pp=ignoreflyers_30_3&pp=mean_60` creates one file for each operator. Only parameters named `pp` are read, so a bare `&mean_60` is ignored without an error, and each file is computed from the `.pb` file of the partition (the raw file when `reducedata` is not set), not chained from the other.
    * Statistical Optimization (`stats`): `pp=stats_60` pre-calculates `{mean, std, min, max, count}` in one file.
* **Lifecycle**: `pp` files are created in the store that carries the `pp` parameter, next to the raw files. ETL moves only the `.pb` files: when the `.pb` file of a partition moves to the next store, the pp file of the source store stays in it ([epicsarchiverap-maven#51](https://github.com/jeonghanlee/epicsarchiverap-maven/issues/51)), and the next store computes its own pp file if it carries a `pp` parameter.

#### 3.2.3 Summary Comparison

| Feature | `reducedata` | `pp` (Post-Processor) |
| :--- | :--- | :--- |
| **Primary Goal** | Storage Capacity Optimization | Retrieval Performance Optimization |
| **Operational Mechanism** | Permanently replaces raw data | Creates auxiliary pre-calculated files |
| **Raw Data Status** | **Lost** (Overwritten) | **Preserved** (Kept Intact) |
| **Storage Consumption** | Significantly Decreased | Increased (Raw + Processed) |
| **File Architecture** | Single reduced file | Multiple files (Raw + Processed) |
| **Exclusivity** | Not meant to be combined with `pp` | Not meant to be combined with `reducedata` |

## 4. Archiving Policies
The `policies.py` script defines the logic for how different Process Variables (PVs) are sampled, structured in storage tiers, and how their data is reduced for long-term storage.

### 4.1 Standard Policy Configurations
The system provides a set of predefined policies mapped to specific sampling rates and storage strategies. The policy is determined by the `determinePolicy` function.

#### 4.1.1 Monitor-Based Policies
These policies use the `MONITOR` sampling method, meaning every value change that the IOC sends is archived; a value with a time stamp that is not newer than the last one or lies outside the accepted time window is dropped, and when the sample buffer is full the oldest buffered sample is dropped. The accepted time window starts at 1991-01-01 and ends 1800 seconds after the engine clock; a time stamp more than 1800 seconds before the engine clock is dropped too, except for the first sample after a start, a reconnect or a write error; the installation property `org.epics.archiverappliance.engine.epics.server_ioc_drift_seconds`, which is set in `archappl.properties`, sets the 1800 seconds. A sample whose data type differs from the buffered ones is dropped too. The sampling period only sizes the sample buffer; it does not limit the rate.

* **Default**
    * Sampling: 1.0 second (1 Hz)
    * LTS Reduction: None (Standard retention)
* **VeryFast**
    * Sampling: 0.1 second (10 Hz)
    * LTS Reduction: Reduced to 10 seconds (`lastSample_10`)
* **Fast**
    * Sampling: 1.0 second (1 Hz)
    * LTS Reduction: Reduced to 30 seconds (`lastSample_30`)
* **Medium**
    * Sampling: 10.0 seconds
    * LTS Reduction: Reduced to 60 seconds (`lastSample_60`)

#### 4.1.2 Scan-Based Policies
These policies use the `SCAN` sampling method to sample monitor events. The engine buffers the latest monitor value and limits
accepted events using the configured period and `scanJitterFactor`; its scheduled
check can accept a buffered event after the interval has elapsed. It does not
issue a forced IOC read at each interval. Once an event has been archived,
the engine does not repeat it to fill later intervals. The period therefore does not guarantee a fixed number
of archived samples.

* **Slow**
    * Sampling: 60.0 seconds
    * LTS Reduction: Reduced to 180 seconds (`lastSample_180`)
* **VerySlow**
    * Sampling: 900.0 seconds (15 minutes)
    * LTS Reduction: None

### 4.2 Controlled Archiving
Policies with the "Controlled" suffix allow archiving to be paused or resumed dynamically based on an external signal.

* **Mechanism**: If the policy name contains "Controlled" (e.g., `FastControlled`), a control PV is assigned.
* **Control PV**: `EPICS:ArchiverAppliance:Enable`.
* **Behavior**: Archiving is active only when the control PV is in the enabled state.

### 4.3 Field Archiving Logic
In addition to the main value (`.VAL`), the archiver captures auxiliary fields to provide operational context (limits, drive values, etc.). The list of archived fields is determined dynamically based on the EPICS Record Type (`RTYP`).

#### 4.3.1 Group A: Standard Limits
Records in this group archive the standard alarm limits and operating ranges.
* **Fields**: `HIHI`, `HIGH`, `LOW`, `LOLO`, `LOPR`, `HOPR`
* **Applicable RTYPs**:
    * `ai` (Analog Input)
    * `calc`, `calcout` (Calculation)
    * `longin` (Long Input)
    * `dfanout` (Data Fanout)
    * `sub` (Subroutine)

#### 4.3.2 Group B: Limits with Drive Values
Output records often include drive limits in addition to the standard operating limits.
* **Fields**: Group A Fields + `DRVH` (Drive High), `DRVL` (Drive Low)
* **Applicable RTYPs**:
    * `ao` (Analog Output)
    * `longout` (Long Output)

#### 4.3.3 Group C: Motor Specific
Motor records require velocity and readback information in addition to standard limits.
* **Fields**: Group A Fields + `VELO` (Velocity), `RBV` (Readback Value)
* **Applicable RTYPs**:
    * `motor`

#### 4.3.4 Global Stream Fields
The system defines a default set of fields considered part of every PV stream structure.
* **Default List**: `HIHI`, `HIGH`, `LOW`, `LOLO`, `LOPR`, `HOPR`, `DRVH`, `DRVL`.
* The groups above list the fields that a record type adds in `policies.py`. A record type that none of the groups names, for example `bi`, `mbbi` or `waveform`, gets no field list from the shipped template.

## 5. Policy Application & Lifecycle
The archiving logic defined in `policies.py` is applied when a PV is archived.

### 5.1 Loading Mechanism
The policy script is run by an embedded Jython interpreter in the services that need it. `mgmt` reads it to compute the policy of an archive request, to list the policies and to return the policy text; `retrieval` reads it when a request names a PV that has no type information, names no `retiredPVTemplate` parameter, and the installation property `org.epics.archiverappliance.retrieval.SearchStoreForRetiredPvs`, which is set in `archappl.properties`, is enabled (it is disabled by default); the type information is the record of a PV in the configuration database. `engine` and `etl` do not read it: they use the stores that the type information of each PV holds.
The loading process is managed by `ConfigService.java` and `DefaultConfigService.java` within the `archiverappliance` source code; `ExecutePolicy.java` runs the script, and `retrieval` runs it in its own interpreter.

### 5.2 Runtime vs. Build Time
It is important to distinguish between the software build and the configuration application.
* **Build Time**: One web application archive (WAR file) for each of `mgmt`, `engine`, `etl` and `retrieval` is created during the build process. Each WAR carries a copy of `policies.py` on its classpath as a default.
* **Runtime**: A service that reads the policy reads the file that `ARCHAPPL_POLICIES` names (the Java system property of that name first, then the environment variable); only when neither is set does it use the copy inside the WAR. The installed appliance sets the variable to the installed `policies.py`. `mgmt` keeps the executed policy for one minute, so it reads a replaced file again at the first request that needs the policy after that minute; the list of policies is read from the file at every request.
* **Conclusion**: A change of the installed `policies.py` applies without rebuilding the software and without a restart; it applies to the PVs that are archived afterwards (section 5.4) and, in `retrieval`, to the next request for a PV that has no type information.

### 5.3 Configuration Path
The system locates the policy script using a specific environment variable.
* **Variable Name**: `ARCHAPPL_POLICIES`
* **Function**: Defines the absolute file system path to the active `policies.py` file.
* **Example**: `ARCHAPPL_POLICIES="/opt/epicsarchiverap-maven/policies.py"`

### 5.4 Update Workflow
A change of `policies.py` reaches only the PVs that are archived after the change. When a PV is archived, its store URLs, with their `partitionGranularity`, `hold` and `gather`, are stored with its type information (in the SQLite or MariaDB database), and ETL builds the sources and destinations of the PV from them. A PV that was archived before the change keeps its stored URLs. This guide does not describe how the stores of an archived PV are changed.
1.  **Modification**: Edit or replace the `policies.py` file at the path defined by `ARCHAPPL_POLICIES`. `mgmt` reads the file again at the first request after about a minute; a restart of the services (`make sd_stop`, `make sd_start`) applies it at once.
2.  **Durability**: `make install` copies the file that `make conf.archapplproperties` rendered from `site-template/policies.py.in` over the installed `policies.py`, so an edit of the installed file is lost at the next `make install`. `make install` does not render the template: after a change in the template or in the variables of section 5.5, run `make conf.archapplproperties` first, otherwise the copy rendered at the last run is installed.

### 5.5 Store Settings as Build Variables
`site-template/policies.py.in` takes the partition granularity and ETL hold of each tier from Make variables, so a host changes them in `../CONFIG_SITE.local` (one directory above the checkout top) without editing the shipped template. `make conf.policies` renders them into `policies.py`.

On a new host, set the values before step 3 of the install sequence in `README.install.md`: `make conf.archapplproperties` includes `conf.policies`, and `make install` installs the rendered `policies.py`. On an installed host, stop the services with `make sd_stop`, change the values and run `make conf.archapplproperties` and `sudo make install` again (the install replaces the web applications and the configuration files), then start the services with `make sd_start`.

| Variable | Default | Tier setting |
| --- | --- | --- |
| `ARCHAPPL_STS_GRANULARITY` | `PARTITION_HOUR` | STS `partitionGranularity` |
| `ARCHAPPL_STS_HOLD` | `2` | STS `hold` |
| `ARCHAPPL_MTS_GRANULARITY` | `PARTITION_DAY` | MTS `partitionGranularity` |
| `ARCHAPPL_MTS_HOLD` | `2` | MTS `hold` |
| `ARCHAPPL_LTS_GRANULARITY` | `PARTITION_YEAR` | LTS `partitionGranularity` |

`gather=1` on STS and on MTS, `consolidateOnShutdown=true` on STS (ETL pushes the data of the store to the next store when the appliance stops), and the `reducedata` operators on LTS stay in the template. `conf.policies` stops before writing `policies.py` when a granularity is not one of the seven `PartitionGranularity` names in section 2.1 or a hold is not a positive integer; a hold of at least 1 keeps `hold - gather` non-negative with the fixed `gather=1`. It does not check that the tiers run from finer to coarser; the operator writing the values keeps that order.

A test host that wants to watch samples move through all three tiers within hours sets, in `../CONFIG_SITE.local`:

```make
ARCHAPPL_STS_GRANULARITY:=PARTITION_5MIN
ARCHAPPL_STS_HOLD:=2
ARCHAPPL_MTS_GRANULARITY:=PARTITION_HOUR
ARCHAPPL_MTS_HOLD:=2
ARCHAPPL_LTS_GRANULARITY:=PARTITION_DAY
```

With these values a partition becomes eligible for ETL out of STS about ten minutes after it closes and out of MTS about two hours after it closes (run on the ETL classes: the STS file of 10:00 left at 10:20, the MTS file of 10:00 at 13:10); the actual move waits for the next ETL pass, so it lands later than that. The shipped defaults stay for real deployments.

## 6. Storage Media & Hardware Recommendations
The selection of `partitionGranularity`, `hold`, and `gather` should be optimized based on the physical storage media being used.

### 6.1 SATA Disk (Local Storage)
* **STS Configuration**:
    * Recommended for RAM file systems or high-RAM environments (64GB+).
    * `partitionGranularity`: `PARTITION_HOUR`
    * `hold`: 5
    * `gather`: 1
* **MTS Configuration**:
    * `partitionGranularity`: `PARTITION_DAY`
    * `hold`: 2
    * `gather`: 1
* **LTS Configuration**:
    * `partitionGranularity`: `PARTITION_MONTH`

### 6.2 NVMe (M.2) Storage
* **STS Configuration**:
    * `partitionGranularity`: `PARTITION_DAY`
    * `hold`: 2
    * `gather`: 1
* **MTS Configuration**:
    * `partitionGranularity`: `PARTITION_MONTH`
    * `hold`: 2
    * `gather`: 1
* **LTS Configuration**:
    * `partitionGranularity`: `PARTITION_YEAR` (Live data)
    * Recommendation: Move to recovery storage after 1, 3, or 5 years depending on the experiment requirements.

### 6.3 Recommended Default Policy
For a standard robust deployment, the following parameters are recommended to ensure reliability and performance. They are a recommendation; the shipped `policies.py` differs on LTS, as the last item states:

* **STS**: `PARTITION_HOUR`, `hold=2`, `gather=1`, `consolidateOnShutdown=true`
* **MTS**: `PARTITION_DAY`, `hold=2`, `gather=1`
* **LTS**: `PARTITION_YEAR`, `pp=mean_3600`. The shipped `policies.py` sets no `pp` on LTS: the Default and VerySlow policies keep the raw data there, and the VeryFast, Fast, Medium and Slow policies reduce it with `reducedata`. A tier takes `pp` or `reducedata`, not both (section 3.2); add `pp` to a tier only where it holds no `reducedata`.
