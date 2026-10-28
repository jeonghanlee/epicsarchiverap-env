# Storage tiers and the movement of data

The appliance keeps every process variable (PV) in up to three stores. Samples go to the first store, and the `etl` component moves them to the next store as they age. This page explains the stores, the parameters that describe them and the policies that choose them.

## The three stores

| Store | Role | Default folder | Default partition |
| :--- | :--- | :--- | :--- |
| STS (short term store) | Receives the samples written by `engine` | `/arch/sts/ArchiverStore` | `PARTITION_HOUR` |
| MTS (medium term store) | Receives data moved out of STS | `/arch/mts/ArchiverStore` | `PARTITION_DAY` |
| LTS (long term store) | Receives data moved out of MTS | `/arch/lts/ArchiverStore` | `PARTITION_YEAR` |

The folders come from `ARCHAPPL_STORAGE_TOP` (`/arch`) and the variables `ARCHAPPL_SHORT_TERM_FOLDER`, `ARCHAPPL_MEDIUM_TERM_FOLDER` and `ARCHAPPL_LONG_TERM_FOLDER`. The partitions come from `ARCHAPPL_STS_GRANULARITY`, `ARCHAPPL_MTS_GRANULARITY` and `ARCHAPPL_LTS_GRANULARITY`. All of them live in `configure/CONFIG_SITE`.

A store is described by a uniform resource locator (URL) of the `pb://` form. The template `site-template/policies.py.in` builds the three URLs and the generated `policies.py` carries them:

| Part of the URL | Meaning (from the storage plugin of the source) |
| :--- | :--- |
| `name` | Identifies the plugin: `STS`, `MTS` or `LTS`. |
| `rootFolder` | The folder that holds the files of the store. |
| `partitionGranularity` | The time span of one file. With `PARTITION_HOUR` a file covers one hour of data. |
| `hold` | How many further partitions of the store must elapse after the partition of a file before the file can move out (this repository sets `2` for STS and MTS). |
| `gather` | Sets the boundary for the files that move after the oldest candidate that holds a sample has satisfied `hold`; every candidate at or before that boundary moves (this repository sets `1` for STS and MTS). |
| `consolidateOnShutdown` | Whether ETL pushes data to the next store when the application stops. STS sets it to `true`. |
| `reducedata` | Reduces the data as it moves into the store; only the reduced data is kept. |

With the defaults, a file of STS leaves STS in the first pass that starts at least three partitions and one minute after the start of its partition. The passes of STS start at 5 minutes past each hour, so the file of 10:00 leaves at 13:05 UTC.

## The policies of the template

The function `determinePolicy` in `policies.py` returns the sampling and the stores for a PV from the policy name in its request. The template defines eleven policies: `Default`, the five names `VeryFast`, `Fast`, `Medium`, `Slow` and `VerySlow`, and the same five names with the suffix `Controlled`. The five names without `Controlled` set the following values.

| Policy | Sampling | Method | Reduction into LTS |
| :--- | ---: | :--- | :--- |
| `VeryFast` | 0.1 s | `MONITOR` | `lastSample_10` |
| `Fast` | 1 s | `MONITOR` | `lastSample_30` |
| `Medium` | 10 s | `MONITOR` | `lastSample_60` |
| `Slow` | 60 s | `SCAN` | `lastSample_180` |
| `VerySlow` | 900 s | `SCAN` | none |

A name that contains `Controlled` sets the control PV `EPICS:ArchiverAppliance:Enable`, so that the PV is archived only while that PV allows it. A request without a policy name, or with `Default`, gets 1 s `MONITOR` and the three unreduced stores.

For a record type, `policies.py` also lists the fields archived with the PV. For `ai` and `calc`, for example, they are `HIHI`, `HIGH`, `LOW`, `LOLO`, `LOPR` and `HOPR`.

The page [Storage policy parameters](../configure/policy-parameters.md) lists every parameter that a store URL accepts. The page [The data journey of a file from STS to LTS](data-journey.md) explains when ETL moves a file and what `hold` and `gather` select.
