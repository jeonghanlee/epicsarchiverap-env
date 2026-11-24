# Run inputs of the large-array cases of the heap measurement

Status: accepted by the owner on 2026-11-24 (D82); the engine side of the CA limit is still checked in the first engine case. The plan requires the fixtures, the number of attempts and requests, the bounds and the heap cells to be declared and accepted before the first array case runs. Nothing runs before the 48-hour observation has ended.

## Fixtures

The owner decided on 2026-11-23 that the operator's frames cannot be obtained (the operator is unknown) and that the cases use fixtures with pinned content that have the reported geometries. The results state that they come from these fixtures and do not reproduce the operator's frames.

| Fixture | Elements | Content | Pinned by |
| :--- | :--- | :--- | :--- |
| laser | 1,405,025 (1307 by 1075) | green channel of a public laser-beam photograph, CC0, as `laser.png` | SHA-256 of the file `efdfcbb8a0e423aa43d9b91eea62f81b893257f8dd0610f0f62d0438b0a4145b` |
| airy | 4,915,200 (2560 by 1920) | red channel of a public diffraction photograph, CC0, as `airy.png` | SHA-256 of the file `95040559b825097a041b39cb4c0db25df411d537b804d834f3e2d9ca9abce7a4` |
| bound | 5,529,600 (2560 by 2160) | synthetic Gaussian blob with noise, seed 20261113, made by `tests/heap/feed-frames.py` as a port of `AnalyzerFixtureData.imageFrame` and `java.util.Random` (the real Java gives the same frame; `AnalyzerFixtureData` itself writes archive files and is not used) | the SHA-256 of the generated frame `b3d85b7834d78afefb875e8a6ef636aa7799ec07035674c4fbc9b58265aa0199` |

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
| Retrieval clients | one or four array request clients (`tests/heap/request-array.pl`, item 7 below) under the 512 MiB limit of the resource set, each recording request time, status, bytes and SHA-256 of the response; `tests/heap/query-archive.pl` is not used for these cases because it picks random scalar PVs with one-hour or one-day windows and cannot ask for the one-event window or the three-event window of a given PV |
| Stops | the stop rules of the resource set: guest `MemAvailable` below 200 MiB, root filesystem at 80 percent, free inodes below 10 percent, a collector with an out-of-memory kill |

For each engine case the sampling period of the PV and the sample buffer margin are recorded, because the engine sizes its buffer from them.

## Classification of outcomes (frozen before the matrices)

The installed source (the appliance of both guests, `epicsarchiverap-maven` commit `105b1b10795f1826318d6c0834ab55a8e09225b7`) has three memory checks (declared size 400, admission 503, pressure 503). `RetrievalMemoryProtection.Request.admit` declares a size only for the optimized and summarizing operators, and `DefaultRawPostProcessor` declares none, so a raw request of a few events that are arrays of millions of elements passes all three checks and can exhaust the heap (the book page of `epicsarchiverap-maven` says so, and the engine is not bounded either). No cell is therefore classified as an expected refusal; each outcome is recorded as observed. The criteria do not depend on the answer that is wanted.

| Family | Outcome | Criterion |
| :--- | :--- | :--- |
| Raw retrieval | Delivered | HTTP 200 and a response whose SHA-256 equals that of the reference retrieval at the preparation heap for the same window |
| Raw retrieval | Delivered, different | HTTP 200 and another SHA-256 or length: kept with both responses |
| Raw retrieval | Refused by a memory check | HTTP 400 or 503 with the text of the check |
| Raw retrieval | Failed | any other status, a broken connection or no answer within 300 seconds, with the retrieval JVM lifetime and the `OutOfMemoryError` lines of its log read before and after |
| Engine subscription | Archived | the PV reaches `Being archived`, the JVM keeps its lifetime, and a read of its stored samples at the preparation configuration returns the pinned frame |
| Engine subscription | Connected without storage | the PV is connected and no frame is stored within the bound |
| Engine subscription | Not connected | the connection state stays false within 300 seconds |
| Engine subscription | Failed | the engine JVM ends or logs an `OutOfMemoryError`, with its lifetime read before and after |

Reading a stored frame: a response of `getData.json` has the form `[{"meta":…,"data":[{"secs":…,"val":[…]}]}]`, and `perl -MJSON::PP -MDigest::SHA=sha256_hex -e 'local $/; my $d = decode_json(<STDIN>); for my $ev (@{ $d->[0]{data} }) { my @v = @{ $ev->{val} }; print "secs=$ev->{secs} elements=", scalar(@v), " sha256=", sha256_hex(pack("v*", @v)), "\n" }' < RESPONSE.json` prints the element count and the SHA-256 of the elements of each event, packed as unsigned 16-bit little-endian values like the pin. A frame counts as stored (and a retrieval as complete) only when an event prints the element count and the SHA-256 of the pin. The command was run on a real response of a waveform PV of the first guest (events of 1,000 elements); its output for an integer array PV is confirmed in the first engine case.

## Decisions taken

The owner decided on 2026-11-24, as recommended:

1. Before the array cases, the soft IOC of the rehearsals (`aasoak-rehearsal`) on the first guest is stopped, because it holds the Channel Access port the engine uses, and its 100 PVs are paused in the appliance (reversible, their data stays), so that every case starts from the same registered PVs.
2. The preparation configuration of the retrieval cases is an engine heap of 512 MiB with `EPICS_CA_MAX_ARRAY_BYTES=24000000`, accepted once the first engine case shows the frames stored (read as described above).
3. The classification of outcomes above is accepted.

With these decisions the run inputs of the array cases are accepted as written. The array cases start after the 48-hour observation has ended.

## Items that were open before the first case, and their state

1. The frame feeder: written (`tests/heap/feed-frames.py`, D81) and checked (`docs/reports/heap-array-tools-check-20261124`); it publishes the fixture frames as waveform PVs at the declared cadence and logs the frame hashes. It served `laser`, `airy` and `bound` together in a soft IOC on the first guest and the frames were read back over Channel Access (item 3).
2. The IOC records: closed by the feeder, which hosts them. `tests/heap/feed-frames.py serve` publishes `AASOAK:ARR:LASER`, `AASOAK:ARR:AIRY` and `AASOAK:ARR:BOUND` (the default prefix), field type USHORT, with 1,405,025, 4,915,200 and 5,529,600 elements; the IOC limit is `EPICS_CA_MAX_ARRAY_BYTES=24000000` in the environment of the feeder (at least 22,118,400 is needed). The engine finds PVs through `EPICS_CA_ADDR_LIST=localhost` on port 5064, which the soft IOC of the rehearsals holds, so that IOC must stop before the feeder serves on that port (decision 1).
3. The independent observation of the frames over Channel Access: closed by a command, not a tool. `caget -t PV | perl -MDigest::SHA=sha256_hex -e 'my $l = <STDIN>; my ($c, @v) = split " ", $l; print "elements=$c values=", scalar(@v), " sha256=", sha256_hex(pack("v*", @v)), "\n"'` with `EPICS_CA_MAX_ARRAY_BYTES=24000000` read the three PVs of a running feeder on the first guest in 1, 1 and 2 seconds, with the element counts 1,405,025, 4,915,200 and 5,529,600 and the SHA-256 equal to the pins (`d05934e3…`, `7a065471…`, `b3d85b78…`); the native type is `DBF_LONG`. The case runs it before and after each case.
4. The generated `bound` frame and the files in use: closed. The `bound` frame has the SHA-256 `b3d85b7834d78afefb875e8a6ef636aa7799ec07035674c4fbc9b58265aa0199` (the real Java agrees); the PNG files used on the analysis host and on the first guest have the SHA-256 declared in the table of the fixtures.
5. The classification of delivery and refusal: frozen by the section above, from the installed source.
6. The CA limit and the actual transfer: the IOC side is verified (item 3). The engine side is open: the environment of the engine JVM has no `EPICS_CA_MAX_ARRAY_BYTES` and `JCAConfigGen` then writes `max_array_bytes` as `30.0`; the array engine cells set 24,000,000 in `engine/conf/engine.conf`, which the launcher reads after the common configuration, and the first engine case reads the engine JVM environment (`/proc/<pid>/environ`) and the delivered element count of its stored samples before any cell is counted.
7. The array request client: written (`tests/heap/request-array.pl`, D81) and checked (`docs/reports/heap-array-tools-check-20261124`); it sends the requests of a plan (PV and time window) with one to four overlapping clients and records time, status, bytes and SHA-256 per request. It has run against the real retrieval service only for a scalar and a waveform PV of one hour.
