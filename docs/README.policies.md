---
title: EPICS Archiver Appliance: Storage and Policy Configuration Guide
author: Sangil Lee & Jeong Han Lee
date: 2026-01-02
version: 1.0
---
# EPICS Archiver Appliance: Storage & Policy Configuration Guide

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
* **Note on "Temporary"**: This indicates that the `.pb` file will be moved to the next destination by the ETL service after the time elapses, according to the `partitionGranularity` setting.

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
In the Archiver Appliance, data is stored in `.pb` (Protocol Buffer) files. Before understanding how data moves (ETL), it is crucial to understand that these files exist in two distinct states based on the `partitionGranularity`.

#### 2.2.1 Active State
* This state refers to the `.pb` file that is currently being written to.
* Data is actively being collected and appended to this file.
* The time duration defined by `partitionGranularity` for this file has not yet elapsed.

#### 2.2.2 Completed State
* This state refers to a `.pb` file that has completely stored data for the entire duration defined by `partitionGranularity`.
* Once the time elapses, the file is closed and considered a complete archive unit.
* **Important**: Only files in this completed state are subject to the `hold` parameter and subsequent ETL migration. The `hold` count applies specifically to these fully formed, archived data files waiting to be moved.

### 2.3 ETL Flow Control
These parameters manage the movement of data between storage tiers. This process primarily interacts with files in the **Completed State**.

#### 2.3.1 Definition of ETL Cycle
* The ETL Cycle is the specific operation where the ETL service moves a batch of data files (`.pb`) from one storage tier to the next (e.g., `STS` → `MTS`).
* It is dynamically defined by the interaction of three key parameters:
    1.  **Unit**: The size of a single file, defined by `partitionGranularity`.
    2.  **Trigger**: The cycle starts when the file count (of Completed files) exceeds `hold`.
    3.  **Batch Size**: The number of files moved is defined by `gather`.

#### 2.3.2 Retention Period (`hold`)
* This parameter is directly related to the `partitionGranularity` setting.
* Specifies the number of **completed** granularity files maintained in a storage area before they are moved to the next tier.
* Example: `hold=6` maintains 5 completed `.pb` files in the current area before the ETL service initiates a move.

#### 2.3.3 Batch Move Size (`gather`)
* This parameter is related to both the `partitionGranularity` and `hold` settings.
* Specifies the number of granularity file units to be moved simultaneously during an ETL cycle.
* Example: `gather=4` moves 4 `.pb` files at once when their time expires in the current tier.

#### 2.3.4 Flow Constraints (`hold` vs. `gather`)
* The `hold` number must always be greater than the `gather` number.
* If `gather > hold`, it will result in an `IOException`.

#### 2.3.5 Configuration Strategies and Impact
The behavior of the Archiver Appliance varies significantly based on how `hold` and `gather` are configured.

* **Scenario A: Without `hold` and `gather` (Unconfigured)**
    * Irregular Generation: The Protocol Buffer (`.pb`) files corresponding to the EPICS Process Variable are created at irregular intervals.
    * Inconsistent Display: This irregularity causes the ETL service to move data files unpredictably, which may result in inconsistent data visualization on the viewer.

* **Scenario B: With `hold` & `gather` (Custom Configuration)**
    * Consistency: Both data movement and data visualization become consistent and predictable.
    * Performance Tuning: Using a large `hold` count is beneficial when data extraction requires optimized reading performance from the storage media (by buffering larger chunks of data before moving).
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
These operators are based on the **Apache Commons Math** library. For detailed mathematical definitions and usage examples, please refer to the following documentation:

* **References**:
    * [Apache Commons Math: StatisticalSummary](https://commons.apache.org/proper/commons-math/javadocs/api-3.6.1/org/apache/commons/math3/stat/descriptive/StatisticalSummary.html)
    * [Apache Commons Math: DescriptiveStatistics](https://commons.apache.org/proper/commons-math/javadocs/api-3.6.1/org/apache/commons/math3/stat/descriptive/DescriptiveStatistics.html)
    * [EPICS Archiver User Guide: Retrieving Data](https://epicsarchiver.readthedocs.io/en/latest/user/userguide.html#retrieving-data-using-cs-studio-archive-viewer-and-matlab)

* **Sampling & Gap Handling**
    * `firstSample`: Returns the first sample in a bin (Default sparsification).
    * `lastSample`: Returns the last sample in a bin.
    * `firstFill`: Similar to `firstSample` but alters timestamp to middle of bin. Copies previous bin's value if current bin is empty (LOCF).
    * `lastFill`: Similar to `firstFill` but uses the last sample for filling.
    * `nth`: Returns every N-th value.

* **Statistical Summary (Interval Compression)**
    * `mean`: Arithmetic average.
    * `min` / `max`: Minimum / Maximum value in the bin.
    * `count`: Number of samples in the bin.
    * `ncount`: Total number of samples in the selected time span.
    * `std`: Standard deviation.
    * `variance` / `popvariance`: Variance / Population variance.
    * `jitter`: Measures noise. Calculated as the standard deviation divided by the mean of a bin (`std / mean`).
    * `errorbar`: Returns `mean`, but adds `std` (standard deviation) as an extra column for visualization.

* **Advanced Statistics (Distribution Analysis)**
    * `median`: Returns the 50th percentile. Robust against outliers.
    * `kurtosis`: Returns the kurtosis (measure of peakedness) of a bin.
    * `skewness`: Returns the skewness (measure of asymmetry) of a bin.
    * *Note: These operators utilize `DescriptiveStatistics`, which requires storing all values in memory, resulting in higher resource usage.*

* **Filtering & Cleaning**
    * `ignoreflyers`: Removes outliers defined as `N` standard deviations from the mean (Default 3.0).
        * Formula: `Math.abs(val - mean) <= numDeviations * std`.
    * `flyers`: Opposite of `ignoreflyers`. Returns *only* the outliers that exceed the deviation threshold.

* **Optimization & Visualization**
    * `optimized`: Returns a summary (`mean`, `std`, `min`, `max`, `count`) as a single sample.
        * Gap Behavior (Stepwise): When encountering a data gap, it copies all the statistical information from the previous interval. This creates a staircase-like appearance in the graph.
    * `optimLastSample`: Variation of optimized for better gap handling.
        * Gap Behavior (Horizontal): When encountering a data gap, it retrieves the last recorded actual sample value. It sets the `mean`, `min`, and `max` to this value, while `std` and `count` are set to zero. This creates a horizontal line in the graph (LOCF), clearly indicating that the last state is maintained without new data.
    * `caplotbinning`: Approximates ChannelArchiver plot binning algorithm.

* **Interpolation**
    * `linear`: Linear arithmetic mean interpolation.
    * `loess`: LOcally Estimated Scatterplot Smoothing (LOESS).

### 3.2 Policy-Based Processing (ETL Configuration)
This section explains how to apply the operators from Section 3.1 permanently or for caching via `policies.py`.

**Constraint**: The `reducedata` and `pp` properties are **mutually exclusive**. They cannot be configured simultaneously for the same storage tier (e.g., you cannot set both for MTS).

#### 3.2.1 Storage Optimization (`reducedata`)
The `reducedata` parameter applies operators to **permanently replace** raw data during the ETL process.

* **Core Purpose**: Significantly reduces storage consumption. The original raw data is lost.
* **Control Modes**:
    1.  Interval Time (e.g., `mean_300`): Divides data into fixed time blocks.
        * Calculation (1-hour query): $3600 \div 300 = 12$ data points.
    2.  Data Count (e.g., `optimized_500`): Forces result to a fixed number of points (e.g., 500).
        * Dynamic Binning: Bin size changes based on query duration ($3600 \div 500 = 7.2s$).
* **Performance Trade-offs**:
    * Low Cost: `Min`, `Mean`, `Variance`, `Jitter`, `Count` (uses incremental `SummaryStatistics`).
    * High Cost: `Median`, `Kurtosis`, `Skewness`, `Loess` (requires storing full lists in memory).

#### 3.2.2 Retrieval Optimization (`pp`)
The `pp` (Post-Processor) parameter uses operators to **pre-calculate** results and save them in **separate files**.

* **Core Purpose**: Accelerates retrieval speed for heavy queries while preserving raw data.
* **Mechanism**: Creates an auxiliary file (e.g., `.mean_60.pb`). The system serves this file directly when requested.
* **Advanced Configuration**:
    * Chained Processing: `pp=ignoreflyers_30_3&mean_60`
        * Logic: Filter outliers (3-sigma, 30s interval) → Calculate mean (60s interval).
    * Statistical Optimization (`stats`): `pp=stats_60`
        * Logic: Pre-calculates `{mean, std, min, max, count}` in one pass. Essential for efficient `errorbar` or `optimized` plotting.
* **Lifecycle**: `pp` files are managed alongside raw data in `MTS`/`LTS` but do not trigger independent ETL moves.

#### 3.2.3 Summary Comparison

| Feature | `reducedata` | `pp` (Post-Processor) |
| :--- | :--- | :--- |
| **Primary Goal** | Storage Capacity Optimization | Retrieval Performance Optimization |
| **Operational Mechanism** | Permanently replaces raw data | Creates auxiliary pre-calculated files |
| **Raw Data Status** | **Lost** (Overwritten) | **Preserved** (Kept Intact) |
| **Storage Consumption** | Significantly Decreased | Increased (Raw + Processed) |
| **File Architecture** | Single reduced file | Multiple files (Raw + Processed) |
| **Exclusivity** | Cannot coexist with `pp` | Cannot coexist with `reducedata` |

## 4. Archiving Policies
The `policies.py` script defines the logic for how different Process Variables (PVs) are sampled, structured in storage tiers, and how their data is reduced for long-term storage.

### 4.1 Standard Policy Configurations
The system provides a set of predefined policies mapped to specific sampling rates and storage strategies. The policy is determined by the `determinePolicy` function.

#### 4.1.1 Monitor-Based Policies
These policies use the `MONITOR` sampling method, meaning data is archived whenever the PV value changes (within the sampling period limit).

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
These policies use the `SCAN` sampling method, forcing a data read at fixed intervals regardless of value changes.

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

## 5. Policy Application & Lifecycle
The archiving logic defined in `policies.py` is integrated into the system during the service initialization phase.

### 5.1 Loading Mechanism
The policy script is loaded into the Java environment when each specific service (Management, Engine, ETL, Retrieval) starts up.
The loading process is managed by `ConfigService.java` and `DefaultConfigService.java` within the `archiverappliance` source code.

### 5.2 Runtime vs. Build Time
It is important to distinguish between the software build and the configuration application.
* **Build Time**: The web application archives (WAR files: `mgmt.war`, `engine.war`, `etl.war`, `retrieval.war`) are created during the build process.
* **Startup Time**: The services run with the WAR files unzipped. The `policies.py` file is read from the external file system when the service starts, not baked into the build.
* **Conclusion**: Policies are applied at service startup, allowing for configuration changes without rebuilding the software.

### 5.3 Configuration Path
The system locates the policy script using a specific environment variable.
* **Variable Name**: `ARCHAPPL_POLICIES`
* **Function**: Defines the absolute file system path to the active `policies.py` file.
* **Example**: `ARCHAPPL_POLICIES="/opt/epicsarchiverap-maven/policies.py"`

### 5.4 Update Workflow
Since the policy file is loaded only at initialization, changes to `policies.py` are not applied dynamically.
1.  **Shutdown**: Stop the Archiver Appliance services.
2.  **Modification**: Edit or replace the `policies.py` file at the path defined by `ARCHAPPL_POLICIES`.
3.  **Startup**: Start the services to load and apply the new logic.

## 6. Storage Media & Hardware Recommendations
The selection of `partitionGranularity`, `hold`, and `gather` should be optimized based on the physical storage media being used.

### 6.1 SATA Disk (Local Storage)
* **STS Configuration**:
    * Recommended for RAM file systems or high-RAM environments (64GB+).
    * `partitionGranularity`: `HOUR`
    * `hold`: 5
    * `gather`: 1
* **MTS Configuration**:
    * `partitionGranularity`: `DAY`
    * `hold`: 2
    * `gather`: 1
* **LTS Configuration**:
    * `partitionGranularity`: `MONTH`

### 6.2 NVMe (M.2) Storage
* **STS Configuration**:
    * `partitionGranularity`: `DAY`
    * `hold`: 2
    * `gather`: 1
* **MTS Configuration**:
    * `partitionGranularity`: `MONTH`
    * `hold`: 2
    * `gather`: 1
* **LTS Configuration**:
    * `partitionGranularity`: `YEAR` (Live data)
    * Recommendation: Move to recovery storage after 1, 3, or 5 years depending on the experiment requirements.

### 6.3 Final Recommended Default Policy
For a standard robust deployment, the following parameters are recommended to ensure reliability and performance:

* **STS**: `PARTITION_HOUR`, `hold=2`, `gather=1`, `consolidateOnShutdown=true`
* **MTS**: `PARTITION_DAY`, `hold=2`, `gather=1`
* **LTS**: `PARTITION_YEAR`, `pp=mean_3600`
