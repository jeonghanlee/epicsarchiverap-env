# EPICS Archiver Appliance: Storage & Policy Configuration Guide

## 1. Storage Tier Architecture
The Archiver Appliance utilizes a tiered storage strategy to balance high-speed data acquisition with long-term capacity management. Data moves between these tiers via the ETL service.

* **STS (Short Term Storage)**: Designed for high-frequency writes; typically resides on a RAMDisk or fast SSD.
* **MTS (Middle Term Storage)**: An intermediate staging area for data before it is moved to long-term storage.
* **LTS (Long Term Storage)**: The final destination for permanent historical data.

## 2. Data Store Parameters
Storage tiers are configured using URL-style strings that define how files are partitioned, moved, and maintained across the STS, MTS, and LTS areas.

### 2.1 Core Settings
The following settings are used to define URL-style strings.

#### 2.1.1 Storage Volume Identification
* `STS`: Short Term Storage. Used for temporary files before ETL processing.
* `MTS`: Middle Term Storage. Used for temporary files staged between STS and permanent storage.
* `LTS`: Long Term Storage. The final destination for permanent files.
* Note on "Temporary": This indicates that the `.pb` file will be moved to the next destination by the ETL service after the time elapses, according to the `partitionGranularity` setting.

#### 2.1.2 Storage Location
* Defined by the `rootFolder` parameter.
* Specifies the location of the top-level folder where each storage area is saved.
* Supports the use of different mounted file system areas for each tier to optimize hardware usage and performance.

#### 2.1.3 Time Indexing
* Defined by the `partitionGranularity` parameter.
* An essential parameter for the ETL service that sets the time index of the `.pb` file created in each storage area.
* **Predefined Intervals**:

| Interval Name | Calculation Formula | Duration (Seconds) |
| :--- | :--- | :--- |
| `PARTITION_5MIN` | 5 * 60 | 300 |
| `PARTITION_15MIN` | 15 * 60 | 900 |
| `PARTITION_30MIN` | 30 * 60 | 1,800 |
| `PARTITION_HOUR` | 60 * 60 | 3,600 |
| `PARTITION_DAY` | 24 * 60 * 60 | 86,400 |
| `PARTITION_MONTH` | 31 * 24 * 60 * 60 | 2,678,400 |
| `PARTITION_YEAR` | 366 * 24 * 60 * 60 | 31,622,400 |

* **PB File Naming Logic**: The `.pb` file name is created based on UTC time with a directory path prefix.
    * Example (PV: `ApplTest:AN:F:Analog10`):
        * `STS` (`PARTITION_15MIN`): `ApplTest/AN/F/Analog10:2025_10_25_06_15.pb`
        * `MTS` (`PARTITION_HOUR`): `ApplTest/AN/F/Analog10:2025_10_25_06.pb`
        * `LTS` (`PARTITION_MONTH`): `ApplTest/AN/F/Analog10:2025_10.pb`


### 2.2 ETL Flow Control
These parameters manage the movement of data between storage tiers.

#### 2.2.1 Definition of ETL Cycle
* The **ETL Cycle** is the specific operation where the ETL service moves a batch of data files (`.pb`) from one storage tier to the next (e.g., STS → MTS).
* It is dynamically defined by the interaction of three key parameters:
    1.  **Unit**: The size of a single file, defined by `partitionGranularity`.
    2.  **Trigger**: The cycle starts when the file count exceeds `hold`.
    3.  **Batch Size**: The number of files moved is defined by `gather`.

#### 2.2.2 Retention Period
* Defined by the `hold` parameter.
* **Relation**: This parameter is directly related to the `partitionGranularity` setting.
* Specifies the number of granularity files maintained in a storage area before they are moved to the next tier.
* Example: `hold=6` maintains 5 `.pb` files in the current area before the ETL service initiates a move.

#### 2.2.3 Batch Move Size
* Defined by the `gather` parameter.
* **Relation**: This parameter is related to both the `partitionGranularity` and `hold` settings.
* Specifies the number of granularity file units to be moved simultaneously during an ETL cycle.
* Example: `gather=4` moves 4 `.pb` files at once when their time expires in the current tier.

#### 2.2.4 Flow Constraints
* **gather vs. hold**: The `hold` number must always be greater than the `gather` number.
* **Error Handling**: If `gather > hold`, it will result in an `IOException`.

#### 2.2.5 Configuration Strategies & Impact
The behavior of the Archiver Appliance varies significantly based on how `hold` and `gather` are configured.

* **Scenario A: Without `hold` & `gather` (Unconfigured)**
    * **Irregular Generation**: The Protocol Buffer (`.pb`) files corresponding to the EPICS Process Variable are created at irregular intervals.
    * **Inconsistent Display**: This irregularity causes the ETL service to move data files unpredictably, which may result in inconsistent data visualization on the viewer.

* **Scenario B: With `hold` & `gather` (Custom Configuration)**
    * **Consistency**: Both data movement and data visualization become consistent and predictable.
    * **Performance Tuning**: Using a **large `hold` count** is beneficial when data extraction requires optimized reading performance from the storage media (by buffering larger chunks of data before moving).
    * **Critical Warning**: As noted in flow constraints, setting `gather > hold` will immediately cause an `IOException`.

* **Scenario C: Optimized Configuration (Recommended)**
    * **Best Practice**: The setting `hold=2&gather=1` is recommended as the smoothest configuration for ETL data movement and data display.
    * **Use Case**: This setting is particularly effective and recommended when the `STS` and `MTS` storage media are identical (e.g., both utilize the same high-speed storage volume).

## 3. Data Reduction & Post-Processing
The ETL service provides powerful post-processing capabilities to optimize storage footprints and improve data retrieval performance.

Conceptually, this system consists of two parts:
1.  **Algorithms (`PostProcessors`)**: The library of mathematical functions available to process data.
2.  **Implementation Methods (`reducedata` vs `pp`)**: The two distinct approaches for applying these algorithms—either replacing the data or creating auxiliary processed files.

### 3.1 Post-Processing Algorithms (`PostProcessors`)
`PostProcessors` are the underlying operators that implement specific algorithm functions. These algorithms are the building blocks used by both `reducedata` and `pp` settings.


### 3.2 Implementation Method 1: Storage Optimization (`reducedata`)
The `reducedata` parameter applies post-processing algorithms to **permanently replace** the raw data during the ETL process.

#### 3.2.1 Core Purpose
* **Goal**: To significantly reduce storage consumption.
* **Mechanism**: Raw data is processed into a summary (e.g., one average value every 10 seconds), and only this summary is stored in the target tier (MTS/LTS).
* **Trade-off**: The original raw data is lost. High-frequency details cannot be recovered once this reduction is applied.

#### 3.2.2 Control Modes
When configuring `reducedata`, the reduction granularity is determined by two primary control mechanisms:

1.  **Interval Time** (e.g., `mean_300`, `firstFill_300`)
    * Meaning: Divides data into fixed time blocks (e.g., 300 seconds).
    * Calculation:
        * 1-hour query: $3600 \div 300 = 12$ data points.
        * 24-hour query: $86400 \div 300 = 288$ data points.
    * Applicability: Used for standard algorithms like `mean`, `firstFill`, `median` (excludes optimized variants).

2.  **Data Count** (e.g., `optimized_500`, `optimizedWithLastSample_500`)
    * Meaning: Forces the final result to have a fixed number of points (e.g., 500), regardless of the query duration.
    * Dynamic Binning: The number of data points is fixed, but the time size of the bins changes dynamically depending on the total query time.
        * 1-hour query: $3600 \div 500 = 7.2$ seconds per bin.
        * 24-hour query: $86400 \div 500 = 172.8$ seconds per bin.

#### 3.2.3 Categorization by Purpose
Algorithms should be selected based on the specific analytical goal ("What to see?"):

* **Simple Sampling (Representative Point Extraction)**
    * Goal: To pick a specific point to represent the bin without mathematical alteration.
    * Operators:
        * `FirstSample` / `FirstFill`: Takes the first value.
        * `LastSample` / `LastFill`: Takes the last value.
        * `Nth`: Extracts every N-th sample regardless of time.

* **Statistical Summary (Interval Compression)**
    * Central Tendency:
        * `Mean`: The arithmetic average.
        * `Median`: The middle value; robust against outliers compared to Mean.
    * Volatility & Stability:
        * `Variance` & `Jitter`: Measures data variability or noise.
        * `ErrorBars`: Visualizes the range (Min/Max) along with the Mean.
    * Distribution Shape (Advanced Analysis):
        * `Kurtosis`: Measures "peakiness" or the frequency of outliers.
        * `Skewness`: Measures the asymmetry of the data distribution.

* **Data Cleaning (Filtering)**
    * Goal: To handle statistical outliers.
    * Operators:
        * `IgnoreFliers`: Removes statistical outliers to archive only "clean" data.
        * `Fliers`: Extracts *only* the statistical outliers to analyze errors or abnormal events.

* **Interpolation & Smoothing**
    * Goal: To generate smooth trends or fill missing data.
    * Operators:
        * `LinearInterpolation`: Resamples irregular data into regular intervals using straight lines.
        * `LoessInterpolation`: Specialized for drawing smooth trend lines that remove noise.

#### 3.2.4 Performance Trade-offs
There is a distinct trade-off between the complexity of the statistical feature and system performance:

* **High Performance / Low Memory** (uses `SummaryStatistics`)
    * These algorithms process data streams efficiently with minimal memory footprint.
    * Operators: `Min`, `Mean`, `Variance`, `Jitter`, `Statistics`, `ErrorBars`.

* **High Cost / High Memory** (uses `DescriptiveStatistics` or List)
    * These algorithms require storing the full list of values in memory to calculate, consuming significant CPU and RAM.
    * Operators: `Median`, `Kurtosis`, `Skewness`, `LinearInterpolation`, `LoessInterpolation`.

#### 3.2.5 The Importance of Handling Data Gaps
Deciding how to handle intervals with no data is critical for data continuity:

* **No Fill (Gap Preservation)**
    * Operators: `FirstSample`, `LastSample`.
    * Behavior: If a bin has no data, it remains empty. This is useful for identifying system downtimes or signal losses.

* **Fill (LOCF - Last Observation Carried Forward)**
    * Operators: `FirstFill`, `LastFill`, `OptimizedWithLastSample`.
    * Behavior: Fills empty intervals with the previous known value to ensure a continuous line in visualizations.
    
### 3.3 Implementation Method 2: Pre-Calculation & Separate Storage (`pp`)
The `pp` (Post-Processor) parameter performs **real-time data processing** during the ETL cycle and stores the results in **independent files**.

#### 3.3.1 Core Purpose & Mechanism
* **Real-Time Processing**: As data flows through the ETL service, the system calculates the specified algorithms (e.g., Mean, RMS) on the fly.
* **Independent File Creation**: Instead of overwriting the raw data, the system creates a separate, independent `.pb` file for the processed data.
    * Example: For a PV named `Analog15`, the system stores the raw file `Analog15:2025.pb` AND a separate processed file `Analog15:2025.mean_30.pb`.
* **Retrieval Efficiency**: When a user requests data with a matching post-processor (e.g., asking for `mean_30`), the system serves the data directly from this pre-calculated file. This bypasses the need for heavy CPU calculation at query time.
* **Default Behavior**: If `pp` is not configured, the default behavior is to save only the raw data.

#### 3.3.2 Configuration Rules
* **Exclusivity**: The `pp` property and `reducedata` property cannot be set simultaneously for the same storage tier.
* **Storage Location**: `pp` settings can be applied to `MTS` and `LTS` areas. The processed files reside in the same storage root folder as the raw data but exist as distinct entities.

#### 3.3.3 Advanced Configuration
The `pp` parameter supports complex processing logic through chained settings and specialized statistical modes.

* **Chained Processing (Continuous Setting)**
    * Logic: Multiple post-processor algorithms can be applied in sequence using the `&` character.
    * Example: `pp=ignoreflyers_30_3&mean_60`
    * Explanation:
        1.  First, the `ignoreflyers` algorithm filters out data exceeding 3 sigma (standard deviations) over a 30-second interval.
        2.  Second, the `mean` algorithm calculates the average of the remaining "clean" data over a 60-second interval.

* **Statistical Optimization (`stats`)**
    * Logic: The `stats` post-processor is a specialized setting that pre-calculates the five most essential statistical metrics at once.
    * Example: `pp=stats_60`
    * Data Structure: A single `stats` file contains values in a specific extraction order: `{mean, standard deviation, minimum, maximum, count}`.
    * Benefit: This is critical for visualization tools (e.g., ErrorBars) that need multiple metrics simultaneously. It avoids the need to read the file multiple times to get min, max, and mean separately.

#### 3.3.4 Data Lifecycle & ETL Policy
* **ETL Movement**: While `pp` files are created during the ETL process, the standard ETL data moving policy (defined by `hold` and `gather`) applies primarily to the raw data partition.
* **File Management**: The `pp` files are auxiliary files that accompany the raw data in the `MTS` and `LTS` tiers. They do not trigger independent move cycles but are managed alongside the primary data stream.


### 3.4 Summary Comparison

| Feature | `reducedata` | `pp` (Post-Processor) |
| :--- | :--- | :--- |
| **Primary Goal** | Storage Capacity Optimization | Retrieval Performance Optimization |
| **Operational Mechanism** | Permanently replaces raw data with summarized data | Creates auxiliary pre-calculated files alongside raw data |
| **Raw Data Status** | **Lost** (Overwritten) | **Preserved** (Kept Intact) |
| **Storage Consumption** | Significantly Decreased | Increased (Raw file + Processed file) |
| **Control Logic** | Supports 'Interval Time' or 'Fixed Data Count' | Supports 'Chained Processing' (`&`) & 'Statistical Optimization' (`stats`) |
| **File Architecture** | Single reduced file in the target tier | Multiple files (Original Raw + Independent Processed) |
| **Ideal Scenario** | Long-term archiving (LTS) where high-frequency raw precision is not required | Active analysis scenarios requiring both raw data integrity and fast access to statistical summaries |
    
    
## 4. Archiving Policies
The `policies.py.in` script defines the logic for how different Process Variables (PVs) are sampled and how their data is reduced for long-term storage.

### 4.1 Policy Definitions
The system provides a set of predefined policies that can be selected via the management UI.

#### 4.1.1 Available Policy List
* **Default**: 1 Hz monitor.
* **VeryFast**: 10 Hz monitor, LTS reduced to 10 seconds (`reducedata=lastSample_10`).
* **Fast**: 1 Hz monitor, LTS reduced to 30 seconds (`reducedata=lastSample_30`).
* **Medium**: 10 second monitor, LTS reduced to 60 seconds (`reducedata=lastSample_60`).
* **Slow**: 60 second scan, LTS reduced to 180 seconds (`reducedata=lastSample_180`).
* **VerySlow**: 15 minute scan, No LTS reduction.

#### 4.1.2 Controlled Archiving
* Policies with the **"Controlled"** suffix (e.g., `FastControlled`) are archived based on the status of a specific control PV.
* The default control PV used is `ALS:Archiver:Enable`.

### 4.2 Automatic Field Archiving
Beyond the primary value, the archiver captures additional fields based on the record type (`RTYP`) to provide operational context.

#### 4.2.1 Standard Stream Fields
* Every PV archives the following fields as part of its data stream: `HIHI`, `HIGH`, `LOW`, `LOLO`, `LOPR`, `HOPR`, `DRVH`, and `DRVL`.

#### 4.2.2 Record-Specific Fields
* **Analog/Calc (`ai`, `ao`, `calc`, `calcout`)**: Archives alarm limits (`HIHI` to `LOLO`) and operating ranges (`LOPR`, `HOPR`).
* **Output Records (`ao`, `longout`)**: Includes drive limits `DRVH` and `DRVL`.
* **Motor Records**: Specifically archives `VELO` (Velocity) and `RBV` (Readback Value).

## 5. Storage Media & Hardware Recommendations
The selection of `partitionGranularity`, `hold`, and `gather` should be optimized based on the physical storage media being used.

### 5.1 SATA Disk (Local Storage)
* **STS Configuration**:
    * Recommended for RAM file systems or high-RAM environments (64GB+).
    * `partitionGranularity`: `HOUR`.
    * `hold`: 5.
    * `gather`: 1.
* **MTS Configuration**:
    * `partitionGranularity`: `DAY`.
    * `hold`: 2.
    * `gather`: 1.
* **LTS Configuration**:
    * `partitionGranularity`: `MONTH`.

### 5.2 NVMe (M.2) Storage
* **STS Configuration**:
    * `partitionGranularity`: `DAY`.
    * `hold`: 2.
    * `gather`: 1.
* **MTS Configuration**:
    * `partitionGranularity`: `MONTH`.
    * `hold`: 2.
    * `gather`: 1.
* **LTS Configuration**:
    * `partitionGranularity`: `YEAR` (Live data).
    * Recommended to move to recovery storage after 1, 3, or 5 years depending on the experiment.

### 5.3 Final Recommended Default Policy
For a standard robust deployment, the following parameters are recommended to ensure reliability and performance:

* `STS`: `PARTITION_HOUR`, `hold=2`, `gather=1`, `consolidateOnShutdown=true`.
* `MTS`: `PARTITION_DAY`, `hold=2`, `gather=1`.
* `LTS`: `PARTITION_YEAR`, `pp=mean_3600`.
