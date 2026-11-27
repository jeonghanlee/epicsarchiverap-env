# Check of the array case tools

The tools in `tests/heap/array-cases/` (`prepare-frames.bash`, `run-retrieval-cells.bash`, `run-engine-cells.bash`, `array-common.bash`, `hash-events.pl`, `classify-cells.pl`) and the test `tests/heap-array-cases.pl` were checked on 2026-11-27 (UTC) with the Perl test on the analysis host and on the first guest (Rocky Linux 8.10, Perl 5.26.3), the shellcheck gate, real runs of the drivers on the first guest, and mutants. The records are in `records/`; the guest path in them is replaced by `<guest-home>`.

## Contract

| Item | Size |
| :--- | :--- |
| Perl test `tests/heap-array-cases.pl` | 50 checks of the two Perl tools and of the outcome function; expected hashes from `sha256sum` of bytes written by arithmetic |
| Shellcheck | gate `shellcheck -x -s bash -S warning` on the four bash files; inventory `shellcheck -x -s bash` |
| Real runs of the drivers on the first guest | preparation, retrieval cells, engine cells, with the guest at the baseline configuration before and after |
| Mutants of the Perl tools and the outcome function | 7, each run once on the final bytes with the prediction written first |
| Mutants of the drivers on the guest | 3 defects of the earlier scripts (stored-file name, time zone, request window), run in a reduced scope |

## Results

| Check | Result |
| :--- | :--- |
| Perl test, analysis host and guest Perl 5.26.3, final bytes | 50 of 50 pass |
| Shellcheck gate | exit 0; the inventory lists two info findings (`ps | grep` with the bracket form that keeps the pattern from matching its own command, and a `sudo ... <` whose input file is read by the calling user) |
| `hash-events.pl` on the real saved responses (19 MB, 75 MB, 113 MB), address space capped at 120 MB | the element counts and SHA-256 equal the pins of the three frames; the output is identical to the python reader used earlier |
| `prepare-frames.bash` (`records/real1/prepare`, `real4/prepare`) | stored files after 111 s, frames paused, `first_event=` printed, configuration restored and the service restarted at the end |
| `run-retrieval-cells.bash`, six cells (`records/real1/retrieval`) | one client: 256 MiB Delivered 3 of 12, 384 MiB 9 of 12, 512 MiB 12 of 12, as in the earlier runs; four clients: Delivered 1, 11 and 10 with Refused-503 37, 28 and 28 and Failed-500 10, 9 and 10 for 256, 384 and 512 MiB |
| `run-retrieval-cells.bash` on the final bytes, 256 MiB with one client (`records/real4/control`) | exit 0, `reference ok rows=4`, `Delivered=3 Failed-500=9`, 9 `OutOfMemoryError` lines |
| `run-engine-cells.bash` on the final bytes, 256 MiB, `airy`, one attempt (`records/real4/engine-control`) | `Archived`, `archived_s=101`, `stored_s=111`, 3 events with the pinned hash, the engine process unchanged, configuration restored at the end |
| Engine run with the three cells at 256 MiB, one attempt each (`records/real2/engine`, bytes before the outcome function) | `airy` and `bound` Archived, `airy+bound` Failed with 3 `OutOfMemoryError` lines |
| Refusal of a start with array PVs present (`records/real2/refuse`) | exit 4 with the message, no configuration change |
| End by a termination signal (`records/real1/engine`) | the log shows the restore of both configuration files and the restart of the service, and the four JVMs at 256 MiB; the hash of the two files was read on the guest and is not kept in the records |

## Defects found by the runs and the mutants

| Defect | Found by | Correction |
| :--- | :--- | :--- |
| `hash-events.pl` read blocks of 4 MiB and ran out of memory (and ended with a segmentation fault) under an address space cap of 250 MB | the real run on the responses of the guest | blocks of 256 KiB |
| `hash-events.pl` checked the elements with one regular expression, which exceeds the repetition limit of Perl 5.26 on long text and reported a valid element as not an integer | the real run on the guest Perl | the check is made per element |
| the engine run judged an attempt Archived from the stored frames alone, although its PV was paused and never reached `Being archived` | the real engine run (`records/real1/engine`) | the outcome function requires the archived state and the matching frames; all combinations are in the test |
| the engine run assumed that no array PV exists, but the preparation leaves three paused PVs | the same run | the run refuses to start (exit 4) unless `--delete-existing` is given |
| the check of the reference group of the retrieval run could not fail: its exit status was taken from `tee` in a pipeline | mutant G3 (the prediction of exit 5 was wrong; the run went on with empty references) | the output is captured and the exit status of the tool is read; mutant G3 rerun on the final bytes ends with exit 5 |
| the test did not cover a `secs` or `val` token cut by the end of a block, nor an answer of exactly the minimum size | the review of the mutant predictions (M2 and M5 would have survived) | two checks for the token cuts and one for the minimum size |

## Mutants of the Perl tools and the outcome function

Each mutant was run once against the final test; the prediction was written before the run.

| Mutant | Prediction | Result |
| :--- | :--- | :--- |
| M1 `pack('v*')` to `pack('n*')` in `hash-events.pl` | killed | killed (7 checks) |
| M2 `$TAIL_BYTES` 64 to 1 | killed by the two token cut checks | killed by those two checks only |
| M3 `$BLOCK_BYTES` 256 KiB to 4 MiB | survives, the test does not measure memory | survived; the memory use is checked by the capped real run above |
| M4 quoted CSV fields without a line break in `classify-cells.pl` | killed | killed (3 checks) |
| M5 minimum size `>=` to `>` | killed by the exact size check | killed by that check only |
| M6 status 500 classified as `Other` | killed | killed (1 check) |
| M7 outcome function without the archived condition | killed by the paused PV combination | killed by that check only |

## Mutants of the drivers on the guest

| Mutant | Prediction | Result |
| :--- | :--- | :--- |
| G1 stored-file name pattern of the engine run restored to the earlier defect (`records/real3/G1`) | `stored_s=-1` in the attempt record (the control gives 111) | `stored_s=-1`, outcome `Archived`, 5 events with the pinned hash |
| G2 restart time taken in UTC in the retrieval run (first series, `records/real3/G2`; final bytes, `records/real4/G2f`) | `oom_lines_since_restart=0` (the control gives 9) | 0 in both series |
| G3 request windows fixed to the time of the first run (first series, `records/real3/G3`) | exit 5, no cell run | exit 0 and a cell run: the reference check could not fail (defect above) |
| G3 on the final bytes (`records/real4/G3f`) | exit 5, no cell run | exit 5, no cell run, message `the reference of laser1 has status 200 and 6 bytes, below 1000000` |

## Limits

- One guest. The six-cell retrieval run and the engine run with three cells were made on earlier bytes of the drivers; the final bytes were run in the reduced scope of the controls (retrieval 256 MiB with one client, engine `airy` at 256 MiB, one attempt), and the mutants of the drivers were run in the same reduced scope.
- The `Failed` outcome of the engine run came from the `OutOfMemoryError` lines in the real run (`records/real2/engine`, earlier bytes) and from the table of the outcome function; the final bytes did not run into it. A kernel kill and a changed engine process, the other inputs of `Failed`, were not produced by a real run.
- Mutant M3 survives the test and is covered only by the capped real run, which is a step of the procedure, not an automatic check.
- The drivers are bash and the reader and the classifier are Perl; the python readers of the earlier runs are not part of the repository.

## Files

| Path | Content |
| :--- | :--- |
| `records/real1/` | preparation, the six-cell retrieval run and the first engine run of the tools (stopped by a termination signal) |
| `records/real2/` | the refusal of a start and the engine run with `--delete-existing` |
| `records/real3/` | the first series of driver mutants (G1, G2, G3) with its preparation |
| `records/real4/` | the final series: preparation, control run, mutants G3 and G2 on the final bytes, and the engine control |
| `SHA256SUMS` | SHA-256 of every file of this folder except this README |
