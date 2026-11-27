# Results of the large-array cases of the heap measurement

The large-array cases run on the first guest from 2026-11-26 to 2026-11-27 (UTC) with the inputs of `docs/reports/heap-array-run-inputs-draft-20261123.md`. The fixtures are not the operator's frames; they are the pinned frames `laser` (1,405,025 elements), `airy` (4,915,200) and `bound` (5,529,600), served by `tests/heap/feed-frames.py` (commit `861dea6`) and requested by `tests/heap/request-array.pl`. The records in `records/` are the run logs, the request records and the kernel log lines the tables are computed from; the guest path in them is replaced by `<guest-home>`.

## Set-up

| Item | Value |
| :--- | :--- |
| Guest | Rocky Linux 8.10, 2 vCPU, 3.6 GiB memory (3,665 MiB), no swap, the appliance of `epicsarchiverap-maven` commit `105b1b10` as installed; mgmt and etl run at 256 MiB throughout; during the retrieval cells the engine runs at 512 MiB and during the engine cells of runs 1 and 2 the retrieval JVM runs at 512 MiB (it reads the stored frames; in the repeat without a reader it runs at 256 MiB), and a cell sets the heap of the component under test |
| Heap of a case | the target component's `conf/<component>.conf` gets one appended line `CATALINA_OPTS="$CATALINA_OPTS -Xms<N>M -Xmx<N>M"`; the later flags win; after each series the file is restored from a saved copy (SHA-256 `96faf859...`) |
| Channel Access limit | the installed `archappl.conf` sets `EPICS_CA_MAX_ARRAY_BYTES=16384` for every JVM; the engine cases add `EPICS_CA_MAX_ARRAY_BYTES=24000000` in `engine.conf`, read back from `/proc/<pid>/environ` (engine 24,000,000, mgmt, etl and retrieval 16,384) |
| Service restarts | the appliance runs under one supervising service that ends when one JVM ends; every heap change is a restart of the whole service, and the four JVM command lines and start times are recorded after it |
| Subscription | `MONITOR`, sampling period 30 s, one frame per 30 s from the feeder |
| Raw retrieval windows | one event of `laser`, one event of `airy`, three events of `airy`, one event of `bound`, each checked once at the preparation heap to hold exactly 1, 1, 3 and 1 events |
| Classification | frozen before the cases: a raw retrieval is Delivered when HTTP 200 carries the SHA-256 of the reference response at the preparation heap (512 MiB), Delivered-different for another 200, Refused for 400 or 503, Failed for anything else; an engine subscription is Archived when the PV reaches `Being archived`, the JVM keeps its lifetime and the stored frames equal the pin, Connected without storage, Not connected, or Failed when the JVM ends or logs an `OutOfMemoryError` |

## Preparation case

Engine at 512 MiB with the Channel Access limit 24,000,000: the three PVs reached `Being archived` about 102 seconds after the request, the engine kept its process, and every stored event of the three frames carried the pinned element count and SHA-256 (`d05934e3...`, `7a065471...`, `b3d85b78...`); the accepted preparation configuration of the plan holds. A first read of the stored frames with the retrieval JVM at 256 MiB ended with `OutOfMemoryError` for `airy` (HTTP 200 with an empty data array) and `bound` (HTTP 500); the same reads at 512 MiB delivered. That read was a preparation check and is not a counted cell.

## Results

Two runs of each series were made. Run 1 used scripts with the defects listed under Incidents; run 2 used the corrected scripts and new frames.

### Raw retrieval, one client

Each cell is 3 requests (3 groups). Entry: outcome counts of run 1 / run 2.

| Retrieval heap | laser, 1 event | airy, 1 event | airy, 3 events | bound, 1 event |
| :--- | :--- | :--- | :--- | :--- |
| 256 MiB | Delivered 3 / Delivered 3 | Failed-500 3 / Failed-500 3 | Failed-500 3 / Failed-500 3 | Failed-500 3 / Failed-500 3 |
| 384 MiB | Delivered 3 / Delivered 3 | Delivered 3 / Delivered 3 | Delivered 3 / Delivered 3 | Failed-500 3 / Failed-500 3 |
| 512 MiB | Delivered 3 / Delivered 3 | Delivered 3 / Delivered 3 | Delivered 3 / Delivered 3 | Delivered 3 / Delivered 3 |

### Raw retrieval, four clients

Each cell is 48 requests (4 clients, 4 requests, 3 groups).

| Run | Retrieval heap | Delivered | Delivered, different | Refused (503) | Failed (500) | OutOfMemoryError lines |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | 256 MiB | 1 | 0 | 34 | 13 | 19 |
| 1 | 384 MiB | 12 | 1 | 27 | 8 | 25 |
| 1 | 512 MiB | 16 | 0 | 28 | 4 | 9 |
| 2 | 256 MiB | 3 | 0 | 30 | 15 | 16 |
| 2 | 384 MiB | 10 | 0 | 30 | 8 | 18 |
| 2 | 512 MiB | 13 | 1 | 31 | 3 | 5 |

### Engine subscriptions, run 1

| Engine heap | PV set | Attempt 1 | Attempt 2 | Attempt 3 |
| :--- | :--- | :--- | :--- | :--- |
| 256 MiB | airy | Archived | Archived | Archived |
| 256 MiB | bound | Archived | Archived | Archived |
| 256 MiB | airy+bound | Failed | Failed | Not-connected |
| 512 MiB | airy | Archived | Archived | Archived |
| 512 MiB | bound | Archived | Archived | Archived |
| 512 MiB | airy+bound | Archived | Archived | Failed (kernel kill) |

### Engine subscriptions, run 2

| Engine heap | PV set | Attempt 1 | Attempt 2 | Attempt 3 |
| :--- | :--- | :--- | :--- | :--- |
| 256 MiB | airy | Archived | Archived | Archived |
| 256 MiB | bound | Archived | Failed | Archived |
| 256 MiB | airy+bound | Failed | Failed | Failed |
| 512 MiB | airy | Archived | Archived | Archived |
| 512 MiB | bound | Archived | Archived | Archived |
| 512 MiB | airy+bound | Archived | Archived | not run |

### Engine subscriptions, repeat without a reader process

Engine 512 MiB, `airy` and `bound` together, 3 attempts without any reading process during the attempt: the engine kept its process in all three, no kernel kill was added, and the lowest `MemAvailable` was 767, 647 and 614 MiB (`records/engine-repeat/run.log`). The repeat did not check the stored files, because its stored-file check had the wrong file name pattern (below); it shows the engine alive, not stored frames. The repeat is not a like-for-like control of the killed attempt: its retrieval JVM ran at 256 MiB (`records/engine-repeat/jvm-heaps.txt`, from the GC logs of the four JVMs it started), so the four heaps added up to 1,280 MiB against 1,536 MiB in the attempt that was killed.

### Profiles

| Profile | Engine subscription | Raw retrieval, one client | Raw retrieval, four clients |
| :--- | :--- | :--- | :--- |
| laser (1.4 million elements) | Archived in the preparation case at 512 MiB; not a counted cell | Delivered at 256, 384 and 512 MiB (6 of 6 groups per heap) | mixed at every heap, see the four-client table |
| airy (4.9 million) | alone: Archived 6 of 6 at 256 MiB and 6 of 6 at 512 MiB | Failed at 256 MiB, Delivered at 384 and 512 MiB | mixed at every heap |
| bound (5.5 million) | alone: Archived 5 of 6 at 256 MiB (one Failed) and 6 of 6 at 512 MiB | Failed at 256 and 384 MiB, Delivered at 512 MiB | mixed at every heap |
| airy and bound together | 256 MiB: Archived 0 of 6 (5 Failed, 1 Not connected); 512 MiB: Archived 4 of 6, 1 Failed by a kernel kill, 1 not run | not a case | not a case |

## Reading

- One client: delivery depends on the size of the frame and the retrieval heap in the same way in both runs. At 256 MiB only the 1.4 million element frame is delivered, at 384 MiB the 4.9 million element frame is also delivered, at 512 MiB the 5.5 million element frame is delivered too. Each failed request is an HTTP 500 caused by an `OutOfMemoryError` in the retrieval JVM; the process survived every case.
- Four clients: at every retrieval heap, including 512 MiB, more than half of the 48 requests per cell are refused (503) by the retrieval memory protection (`Retrieval memory admission refused: collection usage ... exceeds threshold 268435456`) or fail with HTTP 500. The counts differ between the two runs, so a four-client cell supports a tendency, not a number.
- Two requests were answered with HTTP 200 and an empty data array of 77 bytes instead of the frames (run 1: 384 MiB, `airy` one event; run 2: 512 MiB, `airy` three events): after a heap shortage the service can answer without an error status and without data.
- Engine: one PV alone is archived at 256 MiB in 11 of 12 attempts (one Failed with an `OutOfMemoryError` line); two array PVs together are not archived at 256 MiB in any of 6 attempts; at 512 MiB they are archived in 4 of the 5 attempts that ran.
- No retrieval case and no engine case at 256 MiB ended a JVM process. In the engine cases the engine JVM stayed alive after `OutOfMemoryError` lines in its log.

## Incidents and deviations

1. The first attempt to restart only the engine ended the supervising service, which stopped the other three JVMs; the whole service was started again about one minute later. Every later restart was a restart of the whole service. No data was touched.
2. Kernel out-of-memory kill: at 2026-11-26T22:37:51Z the kernel killed the engine JVM (`records/kernel-oom-kill.txt`: process 1930527, resident anonymous memory 955,072 kB, the guest at the end of its memory) during attempt 3 of the 512 MiB `airy` and `bound` cell of engine run 1; the supervising service ended and the appliance was down until it was started again. The script recorded the attempt as Archived because its check of the JVM lifetime ran before the kill; the table classifies it as Failed from the kernel log. The frames of that attempt had been stored and read back equal to the pins before the kill. A python process of the run was running at that moment (the kernel table lists it), and whether it was the reader of the stored frames is not established.
3. Engine run 2 stopped by its own rule before attempt 3 of the same cell (2026-11-27T00:43:00Z): `MemAvailable` was 194 MiB, below the stop rule of 200 MiB, at the check before the attempt, when no reader process was running (every attempt of the run reads its stored frames after it); the largest processes were the engine (932 MB resident), the retrieval JVM (672 MB) and the feeder (489 MB). The cause of the kill in item 2 is not established, and the repeat of the cell without a reader (retrieval heap 256 MiB, 1,280 MiB in total) does not isolate the reader from the difference in heap; on this 3.6 GiB guest the memory of the four JVMs, the feeder and the reader together leaves little free memory when the engine and retrieval heaps are 512 MiB.
4. The reader of the stored frames in the run inputs (a `perl` command) ran out of memory on frames of millions of elements; a reader based on `numpy` computed the same value (SHA-256 of the unsigned 16-bit little-endian elements) and was used for all stored-frame checks. Its replacement `tests/heap/array-cases/hash-events.pl` computes the same value and gave identical output on the saved responses (`docs/reports/heap-array-tools-check-20261127`).
5. Script defects found during the runs: the stored-file check of the engine script used a wrong file name pattern, so every attempt of engine run 1 ran to its 300 second bound and the repeat could not check storage (the classification of run 1 used the read-back hashes and is not affected); the out-of-memory count of retrieval run 1 was taken with a time in the wrong zone and read 0, so the counts in the table come from a recount of the journal (`records/retrieval-run1-oom-recount.txt`); the CSV of engine run 1 has shifted columns because a field held commas; the request windows of the retrieval script were fixed to the events of run 1 (run 2 takes the first event time as an argument). Run 2 used the corrected scripts. The runs above used earlier versions of the scripts; the corrected drivers are in `tests/heap/array-cases/` and their check is recorded in `docs/reports/heap-array-tools-check-20261127`.
6. Wall-clock: the first preparation step started at 2026-11-26T08:41Z and the last run ended at 2026-11-27T00:43Z, far above the 12 hours of the plan, because of waits between steps. The run time of the cells is about 12 minutes per retrieval run, 1 h 47 min for engine run 1 and 54 minutes for engine run 2.

## Limits

- One guest of 3.6 GiB, three fixtures and not the operator's frames, 3 attempts or groups per cell, two runs of each series.
- Each cell varied the heap of one component; the other component of the pair was at 512 MiB (the engine during the retrieval cells, the retrieval JVM during the engine cells, except in the repeat without a reader where it was at 256 MiB) and mgmt and etl at 256 MiB, so the four heaps added up to 1,280 to 1,536 MiB in every case; the engine was not run at 384 MiB. No threshold, no minimum heap and no recommended size follow, and nothing here applies to the scalar workload.
- The 512 MiB result of the engine with two array PVs is confounded by the memory of the guest.
- The four-client cells differ between runs; the outcomes of requests in one cell are not independent.
- The console output of the preparation case (the hashes of its stored frames and the first reads at 256 MiB) and of the check of the request windows was not kept as a file, so those statements have no record in `records/`; the `run.log` files of engine runs 1 and 2 record for each attempt whether the stored frames matched the pinned hashes (`pinned_ok`), without the hash values.
- The repeat without a reader process did not check the stored files (item 5); the frames of engine run 2 were checked by the read-back hashes with the corrected scripts.

## Files

| Path | Content |
| :--- | :--- |
| `records/retrieval-run1/`, `records/retrieval-run2/` | plan, `run.log`, and per cell the `requests.csv` (one row per request with time, status, bytes and SHA-256) and `run.json` |
| `records/engine-run1/`, `records/engine-run2/` | `run.log` of the attempts and `results.csv` (columns of run 1 shifted) |
| `records/engine-repeat/` | `run.log` of the repeat without a reader process and `jvm-heaps.txt`, the heap capacity of its four JVMs from their GC logs |
| `records/feeder-frames.log` | the frames published by the feeder with their SHA-256 |
| `records/kernel-oom-kill.txt` | the kernel lines of the kill |
| `records/retrieval-run1-oom-recount.txt` | the recount of out-of-memory lines of retrieval run 1 per cell |
| `SHA256SUMS` | SHA-256 of every file of this folder except this README |
