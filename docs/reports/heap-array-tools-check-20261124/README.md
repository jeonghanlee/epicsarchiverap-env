# Checks of the array case tools

Checks of the frame feeder `tests/heap/feed-frames.py` and the array request client `tests/heap/request-array.pl`, which serve the large-array cases of the heap measurement. All times are UTC. The tools are described in `tests/heap/README.md`.

## Bytes checked

| File | SHA-256 |
| :--- | :--- |
| `tests/heap/feed-frames.py` | `4f723315b5b15741d5517407479e637fc227b8332f8bf21798d4776989ce15c0` |
| `tests/heap-feed-frames.pl` | `3fa082d32f75d8a87c7f5b96e1823446ff4fe7261de18dd10fc8d2e75bd4c430` |
| `tests/heap/request-array.pl` | `b485ad50cbb784f557a6f5a33867e2ec5a7b9972805ff36f9bbd850f53ae2356` |
| `tests/heap-request-array.pl` | `055603230639f4e49554e98086f4007405443eb96bdfad9a795369012ba14dc7` |

## Local checks

The client has 21 checks, all passing on the analysis host: the usage errors and statuses, the plan errors (a missing file, a missing column, a time of the wrong form), one client against `python3 -m http.server` serving a real file (status, bytes and SHA-256 compared with `wc` and `sha256sum`), four clients in two groups (16 rows, the first requests of the clients overlap in time, a group starts after the previous one has ended), a missing file recorded as status 404 with the text of the server, a server that never answers recorded as status 0 with its reason near the time limit, a refused second run into the same directory, and the plan hash of `run.json`.

The feeder has 20 checks. Each of them ran at least once: 15 on the analysis host (ImageMagick and Java are installed there, softioc is not), 12 on the guest of the rehearsals (softioc, numpy and the EPICS tools are installed there, ImageMagick and Java are not), 7 on both. They cover the usage and input errors (among them `serve` on a host without softioc or numpy, which reports the missing modules with status 77 and no traceback), the decoding of `laser.png` and `airy.png` against the 8-bit gray stream that ImageMagick writes, the first six normal values of the port of `java.util.Random` and the SHA-256 of the `bound` frame against the `imageFrame` method of `AnalyzerFixtureData.java` (copied text for text, diff checked) run under the real Java 21, and, with a real soft IOC on a private Channel Access port, the read-back of the 1,405,025 elements of `laser` with `caget` against a frame file that was checked against ImageMagick on the host, the field type USHORT, the IOC timestamps of the publications about the period apart, and the log of the feeder.

Pins of the frames (the SHA-256 of the little-endian 16-bit elements): `laser` 1,405,025 elements `d05934e30059117bdc1afa6dcf63f2b431c808cb33672e56e84289a00d215723`, `airy` 4,915,200 elements `7a06547103de3ca762ac66bfcf8a7ebeb7bb43bfa63d626522c472a6d90361e6`, `bound` 5,529,600 elements `b3d85b7834d78afefb875e8a6ef636aa7799ec07035674c4fbc9b58265aa0199`. The port reproduces the real Java exactly: the normal values equal to the last digit and the whole `bound` frame has the SHA-256 that Java writes. Over Channel Access the 16-bit elements travel as `DBF_LONG`, four bytes per element (22,118,400 bytes for `bound`).

## Mutants

Eight changes of scratch copies were run once each on the final bytes, after the unchanged tools passed all checks. The failing checks were written down before the series.

| Mutant | Change | Where | Failing checks (predicted and observed) |
| :--- | :--- | :--- | :--- |
| FA | the addend of the generator 0xB instead of 0xC | host | the `bound` SHA-256 and the normal values (2) |
| FB | the byte order test reversed | host | `laser` and `airy` pixels and the `bound` SHA-256 (3) |
| FB | the same | guest | the elements read back with `caget` and the log (2) |
| FD | one added to the element count of the log | guest | the log (1) |
| FE | the missing module case ends with status 1 instead of 77 | host | the check of `serve` without softioc or numpy (1) |
| CB | the first byte of each chunk left out of the response hash | host | the SHA-256 of the response (1) |
| CC | the status of a request without answer starts at 599 | host | the request without answer (1) |
| CD | one group instead of the requested number | host | the 16 rows and the start of group 2 (2) |
| CF | each client starts 0.3 seconds after the previous one | host | the overlap of the first requests (1) |

FB first survived on the guest: the read-back check compared the IOC with the output of the feeder itself, so a byte order that is wrong in the same way on both sides passed. The prediction for the guest was wrong in that it assumed an independent oracle. The check now compares with a frame file that was written elsewhere and checked against ImageMagick (`--laser-frame`), and the log check takes its pin from that file; with it FB fails the two checks above. The series was run again on the final bytes of the checks.

Not proven by a mutant: the check of the timestamp spacing of the publications, which runs on the guest only. The check of the missing modules runs on the host only, because softioc and numpy are installed on the guest.

## Real run of the client

One run of the client against the real retrieval service of the first guest, through the port forward: four clients, two groups, a plan of two requests (a one hour window of a waveform PV and of a scalar PV, both ended ten minutes earlier). All 16 requests returned HTTP 200 (`real-run-plan.csv`, `real-run-requests.csv`); the 8 responses of the waveform PV had 32,697,154 bytes and the SHA-256 `1a8a796a49a722b9713854f84123e0a102e4cfceba13572c4e6dbdbfe3d4517b`, the 8 responses of the scalar PV 305,049 bytes and `fff90dba2b0a0d124d86c587bb0968def580d7970c444fc4e0c3ca69168165c5`, and `curl` returned the same two hashes for the same requests.

## Defects that running the tools showed

The decoder built its array from the bytes as if they were 16-bit words (half the elements); the feeder called `SetDeviceName` with an empty name and stopped at the start of the IOC; the check read `NELM` as a floating point number; the check waited on `camonitor` without a time limit after the feeder had ended; softioc, which lives in the user site of the guest, was hidden by the isolated mode of Python, and `serve` on a host without softioc or numpy ended with a Python traceback and status 1, the status that means a failed write, until a review run found it. All were corrected before the series.

## What these checks do not cover

The feeder was not run with `airy` or `bound` in a soft IOC (only `laser`, 1.4 million elements); no feeder frame went through the real engine, the stored archive and the real retrieval service, and the real run of the client used a scalar and a one hour waveform PV, not large arrays; the independent observation of the frames over Channel Access, the IOC database with the three records and the classification of delivery and refusal of the cases remain open items of the run inputs. The checks are 41 against the accepted size of about 38, and the mutants 8 against about 6.
