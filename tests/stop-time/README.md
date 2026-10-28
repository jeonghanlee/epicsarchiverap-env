# Stop Time Measurement — Automated Tests

The scripts of this folder measure how long the appliance unit takes to stop
as a function of the number of archived PVs, on a dedicated guest. The plan,
the claims and the result belong to item M55 of `docs/milestone-2.0.1.md`.
`tests/run-all-tests.bash --local` does not run this folder; the measurement
runs on the guest, and the self-test runs on the local host.

| Script | Role |
| --- | --- |
| `gen-pvs.bash <output folder>` | Writes `extra.db` and `extra.csv`: the 2097 PVs `STOPTIME:E0001` to `STOPTIME:E2097` that, with the 903 PVs of ansible-provision, form the stage of 3000 PVs |
| `archive-stage.bash` | Archives the PVs of one stage after a reset with one archivePV POST and waits until every PV is archived and connected |
| `run-stop.bash` | Measures one stop: the checks before the stop, the phase window, the stop, the cuts, the listings, the status file and the record of the stop |
| `run-cell.bash` | Runs the stops of one cell in order, starts the appliance between them, and stops the cell at a refusal or a repeat that is due |
| `rebuild-table.bash` | Rebuilds the record of each stop from the raw files of its stop folder |
| `fit-line.bash` | Fits the stop time over the PV count: `rehearsal`, `expect`, `line`, `predict` and `check` |
| `selftest.bash` | Tests the scripts on the committed fixtures, without a guest |
| `stops-contract.json` | The contract of `compare-evidence.py` for the records of `stops.jsonl` |

## Recommended Test Sequence

1. Local host: run `selftest.bash`, `bash -n` and `shellcheck -x` on every script.
2. Guest: create the guard file `/etc/stop-time-guest`, install the appliance
   with `ARCHAPPL_STORAGE_TOP` `/arch` and `DB_BACKEND=sqlite` in
   `../CONFIG_SITE.local`, start the IOC unit, archive the PVs of the stage
   with `archive-stage.bash`, and run `run-stop.bash --dry-run` with the
   options of the first stop once the first pass after the archiving has
   created `etl-pass.log`.
3. Guest: run the rehearsal stops with `--cell rehearsal-25` and
   `--cell rehearsal-100`, then `fit-line.bash rehearsal` and
   `fit-line.bash expect`.
4. Guest: run the stops of the cells `main-903` and `main-3000` with
   `run-cell.bash`. A stop leaves the appliance stopped; `run-cell.bash` runs
   `make sd_start` before each further stop. Between the two cells run the
   reset of item M55 in `docs/milestone-2.0.1.md` and archive the PVs of the
   next stage with `archive-stage.bash`.
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

The rehearsal cells `rehearsal-25` and `rehearsal-100` do not need
`--expectation`, because the expectation comes from them. The stage of 3000
PVs adds `--pv-list <extra.csv>`. A repeated stop takes the number of the
original with the suffix `r` (`--stop 2r`). The validation stop
adds `--prediction <prediction.json>`, with the file `<prediction.json>.sha256`
beside it.

### Archive the PVs of a stage

`archive-stage.bash` turns the PV lists into the body of one archivePV POST
(`pv`, `samplingperiod` from the column `period`, `samplingmethod` from the
column `method`, and `policy` when the column is not empty), sends it to
`MGMT_URL` (default `http://localhost:17665/mgmt/bpl`), and reads
`getPVStatus` every 10 seconds until every PV shows `Being archived` with
`connectionState` true, at most `READY_LIMIT_S` seconds (default 1200). It
keeps the body, the reply, its HTTP status, the last status read and the
times in the output folder. `--dry-run` writes the body only. The following
command archives the stage of 903 PVs after a reset:

```bash
tests/stop-time/archive-stage.bash ~/stop-time-evidence/<run-id>/<cell>/archive <pvs.csv> <pvs-load1.csv> <pvs-load2.csv>
```

The stage of 3000 PVs adds `<extra.csv>`. Exit status: 0 every PV ready, 1
the POST failed, 2 not every PV ready in time, 3 usage.

### Run the stops of a cell

`run-cell.bash` runs `run-stop.bash` for the stops `--first` to
`--first + --stops - 1` and passes every other option to it unchanged. Before
each stop after the first it runs `make sd_start`, because a stop leaves the
appliance stopped. It stops the cell when `run-stop.bash` refuses (status 3),
when `make sd_start` fails, or when the status file names a repeat in
`pending`, so that a later stop does not remove that key. Each stop keeps its
output in `<evidence>/<run-id>/console/<cell>-<stop>.log`, and
`<cell>.rcs` lists the exit status and `pending` after each stop. The
appliance must be active before the first stop. The following command runs
the three stops of the cell `main-903`:

```bash
tests/stop-time/run-cell.bash --stops 3 --run <run-id> --cell main-903 --stage 903 --partition PARTITION_5MIN --hold 2 --evidence ~/stop-time-evidence --pv-list <pvs.csv> --pv-list <pvs-load1.csv> --pv-list <pvs-load2.csv> --expectation ~/stop-time-evidence/<run-id>/expectation.jsonl
```

Exit status: 0 every stop ran (each stop keeps its own verdict), 2 the cell
stopped at a repeat that is due, 3 usage, a refusal or a failed
`make sd_start`. A repeat runs with `run-stop.bash --stop <n>r`.

### Judge a recorded stop

The following command judges a recorded stop folder without a stop:

```bash
tests/stop-time/run-stop.bash --judge <stop folder>
```

### Guard

`run-stop.bash` refuses with status 3, before it reads the appliance or its
storage, unless the file `/etc/stop-time-guest` exists and
`make -s print-ARCHAPPL_STORAGE_TOP` of the checkout gives `/arch`. The
evidence directory must lie outside `ARCHAPPL_STORAGE_TOP`, `/tmp` and
`/dev/shm`. The script never runs `make conf.storage.rm`.

After the guard, `run-stop.bash` also refuses with status 3 when a tool it
runs is missing, when the appliance unit or `stop-time-ioc.service` is not
active, when `ARCHAPPL_LOG4J_SITE_FILE` is empty, when
`<AA_INSTALL_LOCATION>/etl/logs/etl-pass.log` does not exist (the file appears
with the first pass after PVs are archived), when the root file system is at
85 percent or more, when `journalctl` gives no cursor for the unit (the
engineer is a member of `systemd-journal`), when the journal is not
persistent, when a PV list has no column `store_key`, or, for the validation
stop, when the prediction file does not match its hash file.

Two environment variables exist for the self-test:
`STOP_TIME_GUARD_FILE` names another guard file, and `STOP_TIME_CHECKOUT`
names another checkout. A third, `STOP_TIME_CURSOR`, replaces the journal
cursor taken before the stop, so that the rehearsal exercises the cut by time
stamps after a lost cursor; the stop folder keeps both cursors in
`journal.cursor`.

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
| `journal.cursor` | `cursor_taken`, the cursor read before the stop, and `cursor_used` when `STOP_TIME_CURSOR` replaced it |
| `journal.bounds` | `first_cursor`, `first_utc`, `last_cursor`, `last_utc`, and `mode` (`cursor`, or `time` for a cut by the unit timestamps) |
| `etl-pass.size` | The size of `etl-pass.log` in bytes `before` and `after` the stop |
| `etl-pass.cut` | The bytes of `etl-pass.log` between the two sizes |
| `etl-pass.records` | Every pass record of the whole `etl-pass.log` after the stop; a record is written at the end of its pass, so the passes around a stop are not all in the cut |
| `listing-before.txt`, `listing-after.txt` | One line per file of the three stores: `<store> <bytes> <mtime UTC> <path>` |
| `frozen/` | The frozen configuration with its `SHA256SUMS` |
| `status.<cell>.<stop>` | The status file as it was before the stop |

The live status file `<evidence>/<run-id>/status` and the table
`<evidence>/<run-id>/stops.jsonl` lie in the run folder. The key `pending` of
the status file names the stop that is due next:

- A recorded stop that carries a qualifier or is Incomplete for C1 sets
  `pending=<cell>/<stop>r`; any other recorded stop, and every recorded repeat,
  removes the key.
- A stop that ends before its record writes `ended.txt` (`native_status`,
  `stop_command_issued`, `ended_utc`) and `SHA256SUMS` into its folder. Before
  the stop command it sets `pending=<cell>/<stop>`: the same stop runs again,
  and `run-stop.bash` moves the old folder aside as
  `stop-<cell>-<stop>.interrupted-<UTC>`. After the stop command it sets
  `pending=<cell>/<stop>r`, or removes the key for a repeat.
- A tool error of `rebuild-table.bash` at the end of a stop writes no record:
  its standard error stays in `cmd/judge.err`, and the stop ends as one that
  ended before its record.
- A folder of a stop that holds `stop-exit.txt` or a record is never reused;
  `run-stop.bash` refuses it with status 3.

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

`fixtures/run-rehearsal/` holds three real stop folders of the rehearsal on
the guest, with the host name replaced by `guest` and only the files that
`rebuild-table.bash` reads: a normal stop of 25 PVs, a stop that the unit
ended at a timeout of 1 second, and a stop interrupted before the stop
command. `recorded.jsonl` holds the records that `run-stop.bash` wrote at the
two completed stops. `fixtures/run-synthetic/` holds four synthetic stop
folders in the same form and their recorded `stops.jsonl`; the damaged copies
of the self-test start from them. `fixtures/fit/` holds a known table of stops
and the recorded fit, rehearsal fit, expectation and prediction.

### Record of a stop

- The duration is `InactiveEnterTimestampMonotonic` minus
  `ActiveExitTimestampMonotonic`; the gaps of the instances come from the four
  launcher lines and `InactiveEnterTimestamp`.
- The real rehearsal stops judge again to the values that `run-stop.bash`
  recorded at the stop for the unit duration, the result, the native status,
  the time after the boundary, the files and bytes, the consolidated and left
  PVs, the loop jobs, the engine gap and C2; the interrupted stop is Incomplete.
- The time after the boundary, the files of each PV against hold + 2, the
  bytes of the short term store, the consolidated and the left PVs come from
  `meta.env` and the two listings.
- The jobs of the loop at the stop come from the lines "Need to consolidate";
  K lines give K - 1 times, summarized by number, sum, mean, median and the
  longest with its PV; a stop with result `timeout` names the PV of its last
  line.
- `slowestMillis` and the pass duration count the passes of `etl-pass.records`
  planned from (hold + 2) partitions before E, and not before `start_utc` of
  the status copy `status.<cell>.<stop>` (the start of `run-stop.bash`), to
  the end of the unit; `etl-pass.log` runs on across resets, so the passes of
  an earlier stage stay out.
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
  the journal bounds, at least one pass record, the pass record fields
  `plannedAt`, `startedAt`, `endedAt`, `pvCount`, `jobsRun`, `jobsFailed`,
  `partitionsMoved`, `bytesMoved`, `slowestPv`, `slowestMillis` and `aborted`,
  the line "Shutting down ETL threads.", well-formed listing rows and
  `frozen/SHA256SUMS`.
- A removed launcher line, a cut without its cursor, a truncated log, a missing
  pass record field, a missing `InvocationID`, an empty cut, a listing row
  without its time and a missing frozen configuration each give Incomplete; a
  stack trace line is ignored; an unreadable file is a tool error with status 3.
  An empty cut is not missing evidence when the unit ended the stop before the
  launcher reached the ETL instance.
- Launcher lines count only from `ActiveExitTimestamp` on, and a journal cut
  whose first record lies more than 60 seconds before it is Incomplete
  (`journal.bounds:first-before-stop`): such a cut holds the lines of earlier
  stops.
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
- `archive-stage.bash --dry-run` builds the archivePV body from lists with CR
  LF line ends, with and without a policy, and sends nothing; it refuses a call
  without lists and a list without the column `method`. `run-cell.bash`
  refuses a call without options, without `--stops` and with `--stop`.
- `run-stop.bash` refuses with status 3, and writes no evidence, without
  options, with an unknown cell, a bad stop number, a prediction for a main
  cell, a validation stop without a prediction, without the guard file and
  with `ARCHAPPL_STORAGE_TOP` other than `/arch`; `--judge` exits 0, 1 and 2
  on the three fixture stop folders.
- `rebuild-table.bash <run folder>` leaves out a stop folder without
  `meta.env` or with `ended.txt` (a stop that ended before its record) and
  names it on standard error as `not recorded` with its `ended.txt`.
- `rebuild-table.bash` on a copy of the fixtures leaves the originals
  byte-identical, and `compare-evidence.py` with `stops-contract.json` finds
  the rebuilt table equal to the recorded `stops.jsonl` and a changed duration
  different. The recorded table and the rebuilt table come from the same raw
  files, so their agreement shows that the rebuild reproduces the recording.
- The checks of `run-stop.bash --dry-run` that read the appliance, the journal
  and the storage run only on the guest.
