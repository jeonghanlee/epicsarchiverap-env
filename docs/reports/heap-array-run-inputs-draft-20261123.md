# Run inputs of the large-array cases of the heap measurement

Status: draft for acceptance. The plan requires the fixtures, the number of attempts and requests, the bounds and the heap cells to be declared and accepted before the first array case runs. Nothing below is accepted until the owner accepts it, and nothing runs before the open items at the end are closed.

## Fixtures

The owner decided on 2026-11-23 that the operator's frames cannot be obtained (the operator is unknown) and that the cases use fixtures with pinned content that have the reported geometries. The results state that they come from these fixtures and do not reproduce the operator's frames.

| Fixture | Elements | Content | Pinned by |
| :--- | :--- | :--- | :--- |
| laser | 1,405,025 (1307 by 1075) | green channel of a public laser-beam photograph, CC0, as `laser.png` | SHA-256 of the file `efdfcbb8a0e423aa43d9b91eea62f81b893257f8dd0610f0f62d0438b0a4145b` |
| airy | 4,915,200 (2560 by 1920) | red channel of a public diffraction photograph, CC0, as `airy.png` | SHA-256 of the file `95040559b825097a041b39cb4c0db25df411d537b804d834f3e2d9ca9abce7a4` |
| bound | 5,529,600 (2560 by 2160) | synthetic Gaussian blob with noise from `java.util.Random`, seed 20261113, written by `AnalyzerFixtureData` | the SHA-256 of the generated frame, to be recorded when the frame is generated and before any use |

The PNG files are tracked in the `epicsarchiverap-maven` checkout under `src/test/js/analyzer/reference/images/`, derived by `prepare-images.py` from published originals whose URLs and SHA-256 are in its `SOURCES.md`. The original files are not kept. The values of the 2026-11-12 observation that the cases follow are not recorded; the geometries are the same.

Each fixture is delivered as one frame, repeated at one frame per 30 seconds with newly observed IOC timestamps (the proposed cadence of the plan). Recorded separately per case: the record type, the actual CA transfer type, `NELM`, the transmitted element count, the value sequence and the cadence. The element type of the archive path is `DBR_WAVEFORM_INT` as in the reported case.

## Cases and bounds

| Family | Cells | Attempts or groups per cell | Bound per attempt or group | Cells times attempts |
| :--- | :--- | :--- | :--- | :--- |
| Engine subscriptions | airy alone, bound alone, airy and bound together; engine heap 256 and 512 MiB | 3 fresh subscription attempts | 300 s | 6 cells, 18 attempts |
| Raw retrieval, one client | laser one event; airy one event; airy three events; bound one event; retrieval heap 256, 384 and 512 MiB | 3 request groups | 300 s | 12 cells, 36 groups |
| Raw retrieval, four clients | the same 12 cells, after the one-client cells | 3 request groups, requests overlapping in time | 300 s | 12 cells, 36 groups |

The time bound of all array cases is 12 hours, including preparation and restarts. The plain sum of the case bounds is 450 minutes (90 for the engine, 180 for each retrieval family), which leaves 270 minutes for preparation, restarts and the checks between cells. A cell that has not reached its intended state at its bound is evaluated at that bound; the series is never stopped at the first success, and a mixed series is reported as mixed and not as a threshold.

## Configuration

| Item | Declared value |
| :--- | :--- |
| Heap override | the target component's installed `<component>/conf/<component>.conf`, which the launcher reads after the common configuration; the other `CATALINA_OPTS` flags stay; the shared `AA_JAVA_HEAPSIZE` is not changed |
| Frozen across cells | the other three JVMs' heap and non-heap settings, the CA limits, the cadence and the stores |
| After each restart | read the four actual JVM command lines and lifetimes before the case proceeds |
| Restore | the prior component configuration after the qualification, and a check of the four shared 256 MiB heaps before the new baseline |
| Preparation of the retrieval cases | frames acquired through IOC, CA, engine and archive at a preparation heap and CA configuration that is observed to work; the proposal is an engine heap of 512 MiB and `EPICS_CA_MAX_ARRAY_BYTES` of 24,000,000, accepted only after the observation of the actual transfer; acquisition is then paused and the stored frames are compared with independent IOC and CA observations before the first retrieval cell |
| Retrieval clients | one or four array request clients (`tests/heap/request-array.pl`, open item 7) under the 512 MiB limit of the resource set, each recording request time, status, bytes and SHA-256 of the response; `tests/heap/query-archive.pl` is not used for these cases because it picks random scalar PVs with one-hour or one-day windows and cannot ask for the one-event window or the three-event window of a given PV |
| Stops | the stop rules of the resource set: guest `MemAvailable` below 200 MiB, root filesystem at 80 percent, free inodes below 10 percent, a collector with an out-of-memory kill |

For each engine case the sampling period of the PV and the sample buffer margin are recorded, because the engine sizes its buffer from them.

## Open items before the first case

1. The frame feeder: written (`tests/heap/feed-frames.py`, D81) and checked (`docs/reports/heap-array-tools-check-20261124`); it publishes the fixture frames as waveform PVs at the declared cadence and logs the frame hashes. It was run in a soft IOC with `laser` only; `airy` and `bound` have not been served by it yet.
2. The IOC database with the three waveform records of the geometries above and the CA array limits of the IOC.
3. The independent CA observation of the frames: the CA observer of the rehearsals reads with a 16,384 byte array limit and cannot carry these frames, so the observation of the frames needs its own method.
4. The generated `bound` frame and its SHA-256, and the check that the PNG files of the declared hashes are the files in use.
5. The classification of delivery and refusal for each family, which the plan freezes before each matrix: it depends on the retrieval code of the installed source and is read from it before the matrix; none of the cells is classified in advance in this draft.
6. The check of the installed CA library's limit and actual transfer on the IOC and on the engine.
7. The array request client: written (`tests/heap/request-array.pl`, D81) and checked (`docs/reports/heap-array-tools-check-20261124`); it sends the requests of a plan (PV and time window) with one to four overlapping clients and records time, status, bytes and SHA-256 per request. It has run against the real retrieval service only for a scalar and a waveform PV of one hour.
