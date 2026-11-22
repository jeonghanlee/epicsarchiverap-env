# Results of the 903-PV day run of 2026-11-20

This folder keeps the results behind `docs/reports/soak-903pv-20261120.md`, which holds the method and the report. The tools and the procedure to repeat the run are in `tests/soak-903pv`. Only the results are kept; the detail files of the run (the 141 cycle files, the installer output, the registration, the status poll, the watchdog log and the journal extract of the health service) are not.

| File | Content |
| :--- | :--- |
| `soak-log.csv` | One row per cycle of the collector: 141 rows from 2026-11-21T00:23:24Z to 2026-11-21T23:43:24Z |
| `summarize.out` | The statistics of the checks C1 to C7 condensed from `soak-log.csv` |
| `final-measure.out` | The measurements after the window: versions, 16 whole-day retrievals, store folders, storage metrics, last closed hour of all PVs |
| `instance-metrics.json` | The ETL counters of the management interface at 2026-11-22T00:16:20Z |
| `war-comparison.txt` | Every differing entry of the four built WARs against the WARs of the bundle |
| `SHA256SUMS` | SHA-256 of every file of this folder except this README; check with `sha256sum -c SHA256SUMS` |
