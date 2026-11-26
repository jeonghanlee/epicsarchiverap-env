# Results of the 48-hour heap baseline

The baseline observation of the per-component Java heap of the four appliance JVMs under the 100 scalar PV load, run by `tests/heap/run-baseline.pl` (commit `eb90b49`) on one fresh guest with the settings of `docs/reports/heap-baseline-settings-draft-20261123.md`. All times are UTC. The raw files (GC logs, sampler CSV, CA output, query responses, the copied blocks) are in a private evidence folder and are not kept after the analysis; this folder holds the results. The path of the evidence folder in `stages.csv` is replaced by `<evidence-dir>`.

## The run

| Item | Value |
| :--- | :--- |
| Guest | Rocky Linux 8.10, 2 vCPU, 4 GiB memory, 30 GiB disk, no swap, nothing installed before the appliance |
| Appliance | installed from the accepted refs with the GC log option; four JVMs of 256 MiB heap, G1, started 2026-11-23T08:22:24Z (`jvm-start-utc.txt`) |
| Collectors | sampler and CA observer from 2026-11-23T20:17:51Z to 2026-11-25T20:47:51Z |
| `R` (all 100 PVs report `Being archived`) | 2026-11-23T20:19:34Z, which is 43,030 seconds of JVM uptime |
| No-query interval | `R` + 6 h to `R` + 42 h (2026-11-24T02:19:34Z to 2026-11-25T14:19:34Z) |
| Query phase | four clients, two seconds between requests, from 2026-11-25T14:19:35Z to 20:19:34Z; the first hour is the warm-up and is excluded |
| Cutoff | 2026-11-25T20:19:34Z (`R` + 48 h) |
| Evidence blocks | 9, copied 6 hours apart from `R` + 6 h, the last at 2026-11-25T20:50:32Z (`blocks-summary.txt`) |
| Watchdog | 872 checks from 2026-11-23T20:18Z to 2026-11-25T21:04Z, no `ALERT`, `WATCH-END` at 21:04:51Z (`watch.log`) |

Every event of the schedule ran at its planned time (12 events 0 s late, one 1 s late; `stages.csv`).

## Results of the GC analysis

Settings of the analysis: Young collections required for all four JVMs, at least 5 events per bin, heap-change tolerance 2 MiB and growth-rate tolerance 0.5 MiB per hour, continuing growth only when both are exceeded. The analysis ran on two separate copies of the logs for each interval and the two outputs are identical (`analysis-*.json` is the output of one copy).

### No-query interval, R + 6 h to R + 42 h (36 hours)

Bins of equal duration: event count, median heap after collection in MiB.

| JVM | Class | Events | Bin 1 / bin 2 / bin 3 / bin 4 | Trend |
| :--- | :--- | :--- | :--- | :--- |
| mgmt | Mixed | 7 | 2, 63 / 0, None / 2, 64 / 3, 64 | inconclusive: Bin 1 has 2 events, the minimum is 5 |
| mgmt | Young | 266 | 67, 64 / 68, 64 / 66, 64 / 65, 64 | computed: change 0 MiB, slope 0 MiB/h, no growth |
| engine | Young | 1263 | 316, 40 / 316, 40 / 316, 41 / 315, 42 | computed: change 2 MiB, slope 0.077778 MiB/h, no growth |
| etl | Young | 144 | 36, 34 / 36, 34 / 36, 34 / 36, 34 | computed: change 0 MiB, slope 0 MiB/h, no growth |
| retrieval | Young | 167 | 42, 33 / 42, 33 / 42, 33 / 41, 33 | computed: change 0 MiB, slope 0 MiB/h, no growth |

### Query interval, R + 43 h to R + 48 h (5 hours)

Bins of equal duration: event count, median heap after collection in MiB.

| JVM | Class | Events | Bin 1 / bin 2 / bin 3 / bin 4 | Trend |
| :--- | :--- | :--- | :--- | :--- |
| mgmt | Mixed | 3 | 0, None / 3, 64 / 0, None / 0, None | inconclusive: Bin 1 has 0 events, the minimum is 5 |
| mgmt | Young | 36 | 10, 64 / 7, 64 / 9, 64 / 10, 64 | computed: change 0 MiB, slope 0 MiB/h, no growth |
| engine | Young | 181 | 45, 43 / 46, 43 / 45, 43 / 45, 44 | computed: change 1 MiB, slope 0.24 MiB/h, no growth |
| etl | Young | 20 | 5, 34 / 4, 34 / 5, 34 / 6, 34 | inconclusive: Bin 2 has 4 events, the minimum is 5 |
| retrieval | Mixed | 38 | 8, 29 / 11, 29 / 14, 30.5 / 5, 29 | computed: change 0 MiB, slope 0.12 MiB/h, no growth |
| retrieval | Young | 12723 | 3081, 29 / 3184, 30 / 3266, 33 / 3192, 30 | computed: change 1 MiB, slope 0.48 MiB/h, no growth |

### Whole run, R to R + 48 h (for context, not a comparison of the settings)

Bins of equal duration: event count, median heap after collection in MiB.

| JVM | Class | Events | Bin 1 / bin 2 / bin 3 / bin 4 | Trend |
| :--- | :--- | :--- | :--- | :--- |
| mgmt | Mixed | 18 | 9, 64 / 1, 63 / 2, 64 / 6, 64 | inconclusive: Bin 2 has 1 events, the minimum is 5 |
| mgmt | Young | 349 | 82, 64 / 91, 64 / 88, 64 / 88, 64 | computed: change 0 MiB, slope 0 MiB/h, no growth |
| engine | Young | 1692 | 421, 39 / 422, 40 / 421, 41 / 428, 43 | computed: change 4 MiB, slope 0.108333 MiB/h, no growth |
| etl | Young | 189 | 45, 34 / 48, 34 / 48, 34 / 48, 34 | computed: change 0 MiB, slope 0 MiB/h, no growth |
| retrieval | Mixed | 54 | 0, None / 0, None / 0, None / 54, 29.5 | inconclusive: Bin 1 has 0 events, the minimum is 5 |
| retrieval | Young | 15308 | 56, 32 / 56, 33 / 56, 33 / 15140, 30 | computed: change -2 MiB, slope -0.05 MiB/h, no growth |

No Full collection and no evacuation failure occurred in any JVM in any interval. The 99th percentile of the Young pauses was 7.0 to 15.7 ms in the no-query interval and 7.5 to 20.2 ms in the query interval; the longest Young pause in the whole-run interval was 43.7 ms (engine); the longest pause of any kind was a Remark pause of 184.18 ms in the retrieval JVM at JVM uptime 197,048 s.

## Result by the accepted rules

- **No-query interval:** the four required Young comparisons are computed and none shows continuing growth. The engine median rises from 40 to 42 MiB over the interval, a change of 2 MiB, which equals the tolerance and does not exceed it; its slope is 0.078 MiB per hour.
- **Query interval:** the Young comparisons of mgmt, engine and retrieval are computed and show no continuing growth (the retrieval slope is 0.48 MiB per hour, below 0.5, with a change of 1 MiB). The Young comparison of the etl JVM (its garbage collection statistics, not the move of the data files) is **inconclusive**: its bin 2 holds 4 events and the minimum is 5. Under the accepted rule an inconclusive comparison withholds a recommendation, events of another interval are not borrowed, and a run or the settings are changed only on the owner's separate direction.
- **Observation outside the rule:** the median heap after Young collection of the engine rises over the whole run, 39, 40, 41 and 43 MiB in the four bins of the whole run (change 4 MiB, slope 0.11 MiB per hour). It is below the growth-rate tolerance and is reported as a fact, not as a finding of growth.

## Other facts of the run

| Item | Value |
| :--- | :--- |
| Samples | 34,920 samples, 1,606,320 rows, spacing 4.984 to 5.016 s, one `start_ticks` per process (no restart of any monitored process) (`sample-summary.txt`) |
| Resident set (MiB, minimum to maximum) | mgmt 418 to 490, engine 384 to 432, etl 382 to 432, retrieval 365 to 424 |
| Host `MemAvailable` | 1,119 to 1,533 MiB (sampler), at least 1,160 MiB at the watchdog checks |
| Guest root filesystem | at most 75 percent (stop rule 80 percent) |
| Queries | 42,191 requests, all HTTP 200, no error; 171.97 GiB of responses, the largest 31.2 MiB; elapsed 2 / 19 / 333 / 2,284 ms (minimum, median, 99th percentile, maximum) (`query-summary.txt`) |
| CA observer output | 7,548,025,543 bytes (about 7.0 GiB) |
| Block copy | blocks 1 to 7 exit status 0; blocks 8 and 9 took 17.7 and 19.2 minutes |

## Incidents and deviations

1. The first start of the run (2026-11-23T20:16:47Z) failed at the port forward because a failed unit of a test mutant was still in the user manager; nothing had started on the guest. After `systemctl --user reset-failed` the run started at 20:17:51Z (rows 2 and 3 of `stages.csv`).
2. The GC log of the retrieval JVM rotated once, at 2026-11-25T19:52:07Z (JVM uptime 214,183 s), because the JVM writes at most 20 MiB to a log file by default and keeps five files, and the query load wrote about 40,000 lines per hour. The rotated file `gc-59930.log.0` (20,971,546 bytes, SHA-256 `ab4f1414cd9dae395c584f6bbfdb883c10da2c850728fc0760790f52776c90d4`) is the log from the JVM start; the active file starts at 214,182.944 s, exactly where the rotated one ends. The block copier therefore refused the file `gc-59930.log` in blocks 8 and 9 (`prefix_mismatch`, exit status 3) and left its earlier copy unchanged; that copy is the first 430,529 bytes of the rotated file. The analysis used the rotated file followed by the active file as pulled at the last block (1,606,006 bytes, SHA-256 `e43bfe03954a7050c8c8cf51cc5095b500db39c0e0407519df867445bbf0d5d4`, equal to the first 1,606,006 bytes of the file on the guest); the joined file has 22,577,552 bytes and the SHA-256 `2556fdd6bc607fa611168501d9fc8ae0ddda959356b7432d34a38906e0946829`. A second rotation did not occur, so no part of the log was lost. The three other logs did not rotate.

## The move of the data by the ETL

Read on 2026-11-26T03:08Z, 55 hours after `R`, on the guest, read-only.

| Item | Value |
| :--- | :--- |
| ETL runs of the management interface (`getInstanceMetrics`) | 56 runs of the first stage (short-term to medium-term store) and 8 of the second (medium-term to long-term store); the longest run took 10 seconds; at most 0.01 percent of the time |
| Errors about the ETL in the appliance journal since 2026-11-23T20:00Z | none (the one line found is the answer to a request for an action that does not exist, made by the check) |
| Files of the stores | short-term 300 files (3 per PV), medium-term 300 files (3 per PV), long-term 100 files (1 per PV): every one of the 100 PVs has its files in each store; the long-term store holds 525 MB at this read |
| Events of one PV of each of the 12 groups in one hour of three days (2026-11-23T21:00Z, 2026-11-24T21:00Z, 2026-11-25T08:00Z) | PVs read every second: 3,601 events in each hour (an hour of one-second events and the end of the window), also the string, enum and waveform PVs; `fast` (0.1 s) 361, 36,001, 36,001; `slow` (10 s) 61, 361, 361; `deadband` 60, 70, 73 |

The counts of `fast` (one event per 10 seconds) and `slow` (one per 60 seconds) in the oldest hour are lower than in the two later hours; the reduction setting that explains this was not read in this check. The check read one PV per group, not all 100 PVs.

## Verdict and reading

The observation ran as planned and every collected signal is normal: no watchdog alert, no restart of any JVM, no Full collection, no evacuation failure, all queries answered, and the ETL moved the data between the stores without error. The owner's verdict for the 48-hour observation (T3) is **Passed**.

Reading of the measured values at the heap of 256 MiB for each JVM (post-collection heap is observed occupancy, not the complete live set):

| JVM | Post-collection heap after Young collections, median / maximum (MiB) | Heap before a collection, maximum (MiB) | Humongous regions at once, maximum (1 MiB each) |
| :--- | :--- | :--- | :--- |
| mgmt | 64 / 65 | 219 | 6 |
| engine | 41 / 45 | 195 | 1 |
| etl | 34 / 41 | 239 (93 percent of 256) | 83 |
| retrieval, no query | 33 / 33 | 185 | 1 |
| retrieval, four clients | 30 / 37 | 189 | 5 |

- The load on the heap is unequal. The etl JVM has the least free heap before a collection (up to 239 MiB) and holds up to 83 humongous regions (83 MiB, a third of its heap) at once; the log gives the region count, not the size of single objects. 92 of the 94 concurrent cycles of its whole log (from JVM start) were started by such large allocations. The retrieval JVM under four clients raised its allocation from 0.20 to 107 MiB per second and its Young collections from about 4.6 to 2,552 per hour (12,761 in five hours); its pressure shows as collection rate, while its retained heap after a Young collection stays at 37 MiB or less. The mgmt and engine JVMs keep at most 65 and 45 MiB after a Young collection. The etl and retrieval JVMs therefore carry the memory load (etl by occupancy, retrieval by allocation rate), and the four JVMs need not receive the same heap.
- This is an observation of one run at one heap size. It is not a numeric recommendation: the etl comparison of the query interval is inconclusive, and a run in which nothing goes wrong does not show how much heap is needed. Per-instance heap variables are outside the work item unless the owner decides otherwise.
- Possible later experiment, not started and needing the owner's separate approval: load the etl and retrieval JVMs until the signal worsens (more or faster PVs, more clients, longer query windows) or reduce their heap, to locate the point where the post-collection heap, the collection count or the pause time starts to rise. The array cases are separate and already accepted.

## Limits of the experiment

1. **It observes a healthy state.** All four JVMs ran at 256 MiB with free heap, and every signal stayed normal. A run in which nothing worsens shows that 256 MiB suffices for this workload; it does not show how much heap is needed, and it cannot tell apart a heap that is just enough from one that is far larger. The point where the post-collection heap, the collection count or the pause time starts to rise was not reached, so no threshold, no minimum and no recommended size follow.
2. **One heap size.** Only 256 MiB was run, for all four JVMs at once. There is no candidate size and no comparison; the repeat at a candidate heap is a separate run that has not started.
3. **One run.** One guest, one 48-hour run, no repeat, so the run-to-run variation is unknown. The values are observations, not ranges.
4. **One workload.** Only the preserved 100 scalar PV stage (D59) ran: its rates, deadbands, reduction policies and the single waveform group. The 500 and 903 PV stages, higher rates and large arrays (millions of elements per event) are outside this run; the array cases are separate and have not run.
5. **The query load is narrow.** Four clients with two seconds between requests sent scalar-PV requests with windows of one hour or one day for the last six hours; the first hour is excluded, so five hours were analysed. Raw array requests, other client counts and longer windows were not tried. The allocation rate of the retrieval JVM (107 MiB per second) and its retained heap (37 MiB at most) belong to this load only.
6. **The etl JVM is observed too rarely for a verdict in the query interval.** It collects about four times an hour, so five hours gave 20 events and one bin held 4 of the required 5; the comparison is inconclusive. The no-query interval (144 events) is computed. The volume of its humongous allocations follows the data it handles (partition and file sizes were not varied, and the objects were not traced to their source in this run), so the 83 MiB is the value of this workload, not a bound.
7. **Short time scale for slow growth.** 48 hours cannot exclude a growth slower than the tolerance of 0.5 MiB per hour. The engine median rose from 39 to 43 MiB over the run; it stays under the tolerance, and a longer run would be needed to tell a plateau from a slow rise.
8. **What the logs measure.** The post-collection heap after Young collections is an observed occupancy, not the complete live set; Mixed and Full collections are kept apart, and none of the latter occurred. A high heap before a collection is normal for G1 and is not a measure of need.
9. **One environment.** Rocky Linux 8.10 on a guest with 2 vCPU, 4 GiB memory and no swap, the appliance of `epicsarchiverap-maven` commit `105b1b10` as installed, and a soft IOC on the same host. RSS, pauses and the available memory belong to this environment.
10. **The ETL data move was read, not exhaustively verified.** The runs and files were counted for all 100 PVs, but the stored events were compared for one PV per group in one hour of three days, not for every PV.
11. **The collection method had one defect.** The GC log option of the installed policy rotates at 20 MiB, and the retrieval log rotated once. Nothing was lost and the analysis joined the pieces (incident 2), but a run with more query load would need a larger file size or no rotation.

## Files

| File | Content |
| :--- | :--- |
| `analysis-noquery.json`, `analysis-query.json`, `analysis-whole.json` | output of `analyze-gc.pl` for the three intervals |
| `sample-summary.txt`, `query-summary.txt` | summaries of the sampler file and the query clients |
| `stages.csv`, `watch.log`, `blocks-summary.txt`, `jvm-start-utc.txt`, `frozen.sha256` | stage record, watchdog log, status of the nine blocks, JVM start times, hashes of the records at the start of the analysis |
| `SHA256SUMS` | SHA-256 of every file of this folder except this README |
