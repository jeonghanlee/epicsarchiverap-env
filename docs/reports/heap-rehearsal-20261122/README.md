# Rehearsals of the heap measurement: results

Two rehearsals of the measurement path on one guest (Rocky Linux 8.10, 2 vCPU, 4 GiB, the four appliance JVMs with GC logs from JVM start, a soft IOC with 100 PVs, MariaDB over a Unix domain socket). The procedure and the scripts are in `tests/heap/rehearsal`. All times are UTC. The full records (GC logs, sampler CSV, CA output, query responses) are in a private evidence folder; this folder holds the results only.

## Result in short

| Item | 2-hour rehearsal | 8-hour rehearsal |
| :--- | :--- | :--- |
| Collectors | sampler and CA observer for about 2 h | sampler and CA observer for 8 h; the sampler was stopped by `systemctl stop` at 21:35:00 and started again at 21:45:06 (606 s gap, same output file) |
| Query load | 4 clients, 40 min, 4,732 requests, all HTTP 200, 7.56 GiB | 4 clients, 60 min, 7,060 requests, all HTTP 200, 21.23 GiB, largest response 27.7 MiB |
| Query time (min / median / p99 / max) | 4 / 13 / 309 / 632 ms | 3 / 20 / 325 / 428 ms |
| Sampler | 1,484 samples, spacing 4.989 to 5.011 s | 5,640 samples, spacing 4.988 s to 604.905 s (the largest spacing is the deliberate stop) |
| Process identities | one `start_ticks` per process | one `start_ticks` per process; the four JVMs did not restart |
| Resident set (MiB, minimum to maximum) | engine 384-438, etl 391-404, mgmt 426-499, retrieval 393-447 | engine 431-434, etl 428-445, mgmt 479-487, retrieval 423-438 |
| Guest `MemAvailable` (MiB) | 1,284 to 1,479 | 1,166 to 1,296 |
| Guest disk | below 80 % | 25 to 35 % |
| Out-of-memory kills | none | none |
| Watchdog | one stop at 09:56:09Z, after the collectors had ended (the cgroup files are gone then); the first form also alerted on the count of limit events (see below) | no alert from start to end |
| Block copy | block 1, exit 0 | block 1 at 23:35:38Z and block 2 at 01:37:10Z, both exit 0 (`ok`, nothing skipped) |
| GC analysis | each interval run on two copies of the logs; the outputs are byte for byte identical | each interval run on two copies of the logs; the outputs are byte for byte identical |

The CA observer wrote 1,189,203,956 bytes in 8 h (about 2.5 MB per minute). The page cache of that file counts toward the cgroup limit of the observer (128 MiB), so its `memory.failcnt` rose to 188,274 while its anonymous memory stayed at about 10 MB and its out-of-memory count stayed 0. The count of limit events is recorded and is no stop condition (D74).

## GC results of the 8-hour rehearsal

JVM start was 06:50:13Z for all four JVMs; the collectors started at 17:35:00Z, which is 38,687 s of JVM uptime. The intervals in uptime seconds are: first quiet part 38,687 to 56,687 (collectors only), query hour 56,687 to 60,287, second quiet part 60,287 to 67,487, whole 38,687 to 67,487. The copy at 01:37:10Z is 67,617 s of JVM uptime; the last event of each GC log lies 14 s (etl) to 740 s (retrieval) before it, the span between two collections of a mostly idle JVM. The table gives the number of Young collections, the median heap after collection in MiB and the 99th percentile pause in ms.

| JVM | First quiet part | Query hour | Second quiet part | Whole |
| :--- | :--- | :--- | :--- | :--- |
| engine | 176, 40, 16.3 | 36, 40, 18.8 | 70, 40, 15.2 | 282, 40, 16.3 |
| etl | 20, 32, 6.2 | 4, 32, 1.0 | 8, 32, 4.6 | 32, 32, 6.2 |
| mgmt | 37, 64, 12.2 | 8, 63, 3.1 | 15, 63, 2.7 | 60, 63.5, 12.2 |
| retrieval | 23, 38, 5.8 | 2,241, 29, 9.3 | 10, 28, 7.5 | 2,274, 29, 9.3 |

mgmt had 30 Cleanup and 30 Remark events and one Mixed event in the whole interval; retrieval had 330 Cleanup, 330 Remark and 22 Mixed events, all in the query hour. No Full collection and no evacuation failure occurred in any interval. The least-squares trend of the Young collections is computed only for intervals with at least five events in the first bin; the 8-hour whole interval gives 0 MiB per hour for engine and etl, -0.2 for mgmt and -1.95 for retrieval. The files `analysis-*.json` hold every number.

The 2-hour rehearsal ran 1,159 retrieval Young collections in the whole interval (median 40 MiB after collection) against 2,274 (median 29 MiB) in the 8-hour rehearsal. The intervals of the two runs differ in length, load and JVM age, so the figures are not a tolerance for the later observation.

## What the rehearsals show

- Every tool of the path ran together on real data: appliance with GC logs from JVM start, soft IOC, sampler, CA observer, four query clients, rsync into staging, cumulative block copy, GC analysis, summaries.
- The resume rule held: a sampler restarted after 10 minutes appended to the same file, the process identities were unchanged, and the analysis can use the continuous intervals around the gap.
- The limits held: no out-of-memory kill, anonymous memory of the collectors at about 10 MB against 64 MiB and 128 MiB, the query clients within 512 MiB each, `MemAvailable` above 1,100 MiB.
- Evidence volume: query responses 11.3 GiB per query hour in the 2-hour rehearsal (7.56 GiB in 40 minutes) and 21.2 GiB in the query hour of the 8-hour rehearsal (four clients, 100 PVs), CA output about 2.5 MB per minute; the 8-hour evidence folder is 67 GB.

## Not decided here

The GC tolerances (`--tolerance-mib`, `--tolerance-mib-per-hour`) are not set from these runs. The array cases, the 48-hour baseline and the candidate-heap repeat are separate runs with their own authorization.

## Files

| Path | Content |
| :--- | :--- |
| `2h/` | stages, watchdog log, registration poll, JVM start times, effective stores of one PV per kind, three GC analyses, query and sampler summaries, block manifest hash |
| `8h/` | stages, watchdog log, JVM start times, four GC analyses, query and sampler summaries, block 2 manifest hash |
| `SHA256SUMS` | SHA-256 of every file of this folder except this README |
