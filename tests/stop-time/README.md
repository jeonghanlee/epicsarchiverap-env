# Stop Time Measurement — Automated Tests

The scripts of this folder measure how long the appliance unit takes to stop
as a function of the number of archived PVs, on a dedicated guest. The plan,
the claims and the result belong to item M55 of `docs/milestone-2.0.1.md`.
`tests/run-all-tests.bash --local` does not run this folder; the measurement
runs on the guest, and the self-test runs on the local host.

| Script | Role |
| --- | --- |
| `gen-pvs.bash <output folder>` | Writes `extra.db` and `extra.csv`: the 2097 PVs `STOPTIME:E0001` to `STOPTIME:E2097` that, with the 903 PVs of ansible-provision, form the stage of 3000 PVs |
| `run-stop.bash` | Measures one stop: the checks before the stop, the phase window, the stop, the cuts, the listings, the status file and the record of the stop |
| `rebuild-table.bash` | Rebuilds the record of each stop from the raw files of its stop folder |
| `fit-line.bash` | Fits the stop time over the PV count: `rehearsal`, `expect`, `line`, `predict` and `check` |
| `selftest.bash` | Tests the scripts on the committed fixtures, without a guest |
| `stops-contract.json` | The contract of `compare-evidence.py` for the records of `stops.jsonl` |

## Recommended Test Sequence

1. Local host: run `selftest.bash`, `bash -n` and `shellcheck -x` on every script.
2. Guest: create the guard file `/etc/stop-time-guest`, install the appliance
   with `ARCHAPPL_STORAGE_TOP` `/arch`, and run `run-stop.bash --dry-run` with
   the options of the first stop.
3. Guest: run the rehearsal stops with `--cell rehearsal-25` and `--cell rehearsal-100`,
   then `fit-line.bash rehearsal` and `fit-line.bash expect`.
4. Guest: run the stops of the cells `main-903` and `main-3000`.
5. Local host: copy the evidence, run `rebuild-table.bash` on a copy, compare it
   with the recorded `stops.jsonl` through `compare-evidence.py`, run
   `fit-line.bash line` and `fit-line.bash predict`, and copy the prediction
   with its hash file to the guest.
6. Guest: run the stop of the cell `validation-903` with `--prediction`.

## Debugging and Workspace Retention

`selftest.bash` works in a fresh `mktemp -d` folder under `TMPDIR`. It removes
the folder after a Passed run and keeps it after a Failed or Incomplete run;
`KEEP_WORKSPACE=1` keeps it after a Passed run too. The folder `out/` holds the
standard output and standard error of every command the self-test ran, and
`stops/` holds the damaged copies of the fixture stop folders.

`run-stop.bash` never removes evidence. Each stop folder keeps the output,
the standard error and the exit status of every command under `cmd/`, and
`SHA256SUMS` over its files after the stop.

## Test Execution

The following command runs the self-test on the local host:

```bash
tests/stop-time/selftest.bash
```

The self-test finds `compare-evidence.py` of the test framework skill under
`~/.claude/skills/test-framework/scripts/`; `COMPARE_EVIDENCE=<path>` names
another copy. Without it the self-test ends Incomplete.

The following command measures the first stop of the cell `main-903` on the
guest; the PV lists are the copied lists of ansible-provision:

```bash
tests/stop-time/run-stop.bash --run <run-id> --cell main-903 --stop 1 --stage 903 --partition PARTITION_5MIN --hold 2 --evidence ~/stop-time-evidence --pv-list <pvs.csv> --pv-list <pvs-load1.csv> --pv-list <pvs-load2.csv> --expectation ~/stop-time-evidence/<run-id>/expectation.jsonl
```

The stage of 3000 PVs adds `--pv-list <extra.csv>`. A repeated stop takes the
number of the original with the suffix `r` (`--stop 2r`). The validation stop
adds `--prediction <prediction.json>`, with the file `<prediction.json>.sha256`
beside it.

The following command judges a recorded stop folder without a stop:

```bash
tests/stop-time/run-stop.bash --judge <stop folder>
```

### Guard

`run-stop.bash` refuses with status 3, before it reads the appliance or its
storage, unless the file `/etc/stop-time-guest` exists and
`make -s print-ARCHAPPL_STORAGE_TOP` of the checkout gives `/arch`. The
evidence directory must lie outside `ARCHAPPL_STORAGE_TOP`, `/tmp` and
`/dev/shm`. The script never runs `make conf.storage.rm`. Two environment
variables exist for the self-test: `STOP_TIME_GUARD_FILE` names another guard
file, and `STOP_TIME_CHECKOUT` names another checkout.

### Stop folder

`run-stop.bash` writes `<evidence>/<run-id>/stop-<cell>-<stop>/` with these
files, and `rebuild-table.bash` reads them:

| File | Content |
| --- | --- |
| `meta.env` | `run`, `cell`, `stop`, `n_pvs`, `partition`, `hold`, `timeout_s`, `e_used_utc`, and for the validation stop `prediction_lower_s` and `prediction_upper_s` |
| `unit.txt` | `systemctl show --timestamp=us+utc` of the unit: both timestamps, both monotonic values, `Result`, `InvocationID` |
| `stop-exit.txt` | The exit status of `sudo systemctl stop` |
| `keys.txt` | The store keys of the stage, from the column `store_key` of the PV lists |
| `journal.txt` | The journal cut, `TZ=UTC journalctl -o short-iso-precise` |
| `journal.bounds` | `first_cursor`, `first_utc`, `last_cursor`, `last_utc`, and `mode` (`cursor`, or `time` for a cut by the unit timestamps) |
| `etl-pass.size` | The size of `etl-pass.log` in bytes `before` and `after` the stop |
| `etl-pass.cut` | The bytes of `etl-pass.log` between the two sizes |
| `listing-before.txt`, `listing-after.txt` | One line per file of the three stores: `<store> <bytes> <mtime UTC> <path>` |
| `frozen/` | The frozen configuration with its `SHA256SUMS` |
| `status.<cell>.<stop>` | The status file as it was before the stop |

The live status file `<evidence>/<run-id>/status` and the table
`<evidence>/<run-id>/stops.jsonl` lie in the run folder. A stop that carries a
qualifier or is Incomplete for C1 sets `pending=<cell>/<stop>r` in the status
file; the repeat removes the key.

### Exit status

| Status | `run-stop.bash`, `rebuild-table.bash --stop`, `selftest.bash` | `fit-line.bash` |
| --- | --- | --- |
| 0 | Passed | Done; `check`: equal text |
| 1 | Failed | `check`: different text |
| 2 | Incomplete | Too few usable stops (Incomplete) |
| 3 | Refusal, usage or tool error | Usage |
| 130, 143 | Interrupted by INT or TERM | — |

Status 2 means Incomplete here, while `tests/run-all-tests.bash` uses 2 for an
invalid usage and 77 for an incomplete system test.

The scripts do not use `tests/lib/common.bash`: its workspace under `/dev/shm`,
its own EXIT trap and its exit at the first failure do not fit the counters,
the single EXIT handler and the retained evidence of these scripts.

## Verified Behaviors

The fixtures in `fixtures/` are synthetic files in the form of the records
that the scripts read; sanitized excerpts of the rehearsal replace them.
`fixtures/run-synthetic/` holds four stop folders and their recorded
`stops.jsonl`; `fixtures/fit/` holds a known table of stops and the recorded
fit, rehearsal fit, expectation and prediction.

### Record of a stop

- The duration is `InactiveEnterTimestampMonotonic` minus
  `ActiveExitTimestampMonotonic`; the gaps of the instances come from the four
  launcher lines and `InactiveEnterTimestamp`.
- The time after the boundary, the files of each PV against hold + 2, the
  bytes of the short term store, the consolidated and the left PVs come from
  `meta.env` and the two listings.
- The jobs of the loop at the stop come from the lines "Need to consolidate";
  K lines give K - 1 times, summarized by number, sum, mean, median and the
  longest with its PV; a stop with result `timeout` names the PV of its last line.
- A pass running at `ActiveExitTimestamp`, or planned between it and the line
  "Shutting down ETL threads." plus 5 seconds, gives the qualifier `overlap`; a
  time after the boundary outside the window or a PV without hold + 2 files
  gives `off-rule`.
- Time stamps of the unit (`Mon 2026-10-19 20:05:40.000000 UTC`), the journal
  (`+00:00`) and the log (`Z`) convert to one UTC epoch across a month and a
  year; the record carries the unit timestamps as ISO 8601 text with `Z`.

### Verdicts

- C1 is Passed when every file of the stop folder and every required field is
  present: the four launcher lines (except after `timeout`), the unit fields,
  the journal bounds, the pass record fields `plannedAt`, `startedAt`,
  `endedAt`, `pvCount`, `jobsRun`, `jobsFailed`, `partitionsMoved`,
  `bytesMoved`, `slowestPv`, `slowestMillis` and `aborted`, the line "Shutting
  down ETL threads.", well-formed listing rows and `frozen/SHA256SUMS`.
- A removed launcher line, a cut without its cursor, a truncated log, a missing
  pass record field, a missing `InvocationID`, an empty cut, a listing row
  without its time and a missing frozen configuration each give Incomplete; a
  stack trace line is ignored; an unreadable file is a tool error with status 3.
- C2 is Failed for a result other than `success`, a duration above the timeout
  or a PV left in the short term store, and Incomplete without the result, the
  duration or the listing after the stop.
- C3 is Passed inside and on the ends of the prediction interval, Failed
  outside it, and Incomplete without it.

### Fit

- `fit-line.bash line` on the known table gives the slope 0.0033381 s per PV,
  the intercept 10.1857 s and the standard error 0.00031512 with 4 degrees of
  freedom, values computed independently of the script.
- `predict` gives the interval 9.13296 s to 17.267 s from the three stops of
  903 PVs; the Student quantiles for df 1 to 30 equal the published table.
- `check` exits 0 on the recorded text and 1 on a changed digit; a cell with
  fewer than two usable stops and a prediction from one stop exit 2; a slope
  that is not positive gives no PV count at the timeout.

### Generator, guard and replay

- `gen-pvs.bash` writes 2097 records of the form of `load1.db` and 2097 rows
  with LF line ends; two runs give the same SHA-256.
- `run-stop.bash` refuses with status 3, and writes no evidence, without
  options, with an unknown cell, a bad stop number, a prediction for a main
  cell, a validation stop without a prediction, without the guard file and
  with `ARCHAPPL_STORAGE_TOP` other than `/arch`; `--judge` exits 0, 1 and 2
  on the three fixture stop folders.
- `rebuild-table.bash` on a copy of the fixtures leaves the originals
  byte-identical, and `compare-evidence.py` with `stops-contract.json` finds
  the rebuilt table equal to the recorded `stops.jsonl` and a changed duration
  different. The recorded table and the rebuilt table come from the same raw
  files, so their agreement shows that the rebuild reproduces the recording.
- The checks of `run-stop.bash --dry-run` that read the appliance, the journal
  and the storage run only on the guest.
