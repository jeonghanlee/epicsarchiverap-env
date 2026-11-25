# Heap Measurement Input Inspection

## Scope

`inspect-inputs.pl` reads the preserved original soak inputs from an explicitly
selected Ansible checkout. It verifies the requested full commit ID, source
cleanliness, recorded file hashes, ordered PV increments, unique PV/store
identities and the accepted 100/500/903 PV stage populations. Git output is
read as bytes, so a file name that is not valid UTF-8 cannot abort the
inspection. CSV files are read as strict UTF-8; a double quote in a CSV file is
refused.

It writes a JSON inventory to stdout and does not execute the preserved tools,
modify either checkout, contact an appliance or create a VM. The canonical
[heap measurement plan](../../docs/milestone-9576820.md#m7---measure-per-component-heap-needs-by-archiving-load)
owns runtime prerequisites, authorization and T1-T5 acceptance.

## Invocation

Run from this repository's root with Perl 5.26 or newer (`Digest::SHA` and
`JSON::PP` installed) and Git available. Select the Ansible checkout and pass the
commit ID that is currently checked out in it (its HEAD) as the source ref; any
other commit returns 77 because the tool never changes the checkout:

```bash
SOAK_REPO=/path/to/ansible-provision
SOAK_REF=full_40_character_commit_id
perl tests/heap/inspect-inputs.pl --ansible-repository "$SOAK_REPO" --source-ref "$SOAK_REF"
```

The selected source must contain the tracked `tests/archiver-soak/SHA256SUMS`
and the original preserved fixture. Only the source directory must be clean;
unrelated checkout changes do not alter this inspection's inputs.

## Results

Exit 0 means input inspection completed and JSON was written. Invalid or
incomplete source inputs, including a source ref that is not the checkout's
HEAD, return 77 without a success inventory; malformed CLI
arguments return 2. File hashes and stage summaries identify the inspected
inputs. The output always records `execution_ready: false` and
`runtime_verification: "Not run"`, with the remaining unverified inputs.

An inspection success does not establish the original installed policy,
effective per-PV stores, runtime readiness, accepted resource/analysis limits
or any VM test result. The supplied checkout is evidence for preserved source
inputs; it does not substitute for the original installed configuration.

## Test

`tests/heap-inspect-inputs.pl` runs the inspector as a subprocess against
temporary Git repositories. It checks the exit statuses and diagnostics for a
missing option, a malformed and a mismatched source ref, and a dirty source
directory with ASCII and non-UTF-8 file names. With
`AA_HEAP_SOAK_REPO` and `AA_HEAP_SOAK_REF` set to a real preserved soak
checkout, it exports the tracked source directory, requires the unchanged copy
to pass, and applies five single changes to real input (altered fixture,
missing required file, untracked checksum list, duplicate checksum entry,
combined fixture that differs with consistent checksums), each of which must
end with status 77 and its own diagnostic.

```bash
perl tests/heap-inspect-inputs.pl
```

## Measurement Tools

Eight more tools in this directory support the measurement. The Perl tools print
their synopsis and options with `--help`, end their POD with an EXIT STATUS
section (`pod2text tests/heap/<tool>.pl` shows it) and need Perl 5.26 or newer and core modules
only. `feed-frames.py` is Python: its usage, its fixtures and its exit statuses are in the docstring at the head of the file, and `--help` prints the first line of that text and the options.

| Tool | Purpose | Exit statuses |
| --- | --- | --- |
| `analyze-gc.pl` | Reads one G1 unified log per JVM and reports pause statistics per collection class, the after-GC heap of four equal bins of a comparison interval and its least-squares trend | 0, 2, 77 |
| `sample-resources.pl` | Appends host memory, process and filesystem figures to one CSV file at a fixed interval until a count, a duration or a signal ends it | 0, 1, 2, 77 |
| `observe-ca.pl` | Runs `camonitor` for a PV list, keeps its output unmodified and writes a run record (command line, working directory, UTC and monotonic start and end, exit status or signal, file sizes) | 0, 1, 2, 77 |
| `query-archive.pl` | One client of the retrieval load: reads random PVs through the retrieval service, stores each full response with its SHA256 and writes one CSV row per request | 0, 1, 2, 77 |
| `copy-block.pl` | Copies the evidence files of one block into a cumulative tree, appends only the new bytes after proving that the earlier bytes are unchanged, and writes a manifest with each file's length, SHA256 and last newline | 0, 1, 2, 3, 77 |
| `request-array.pl` | Sends the requests of a plan (PV and time window) to the retrieval service with one to four overlapping clients, in groups, and records the time, status, bytes and SHA-256 of every request with a time limit | 0, 1, 2, 77 |
| `feed-frames.py` | Python. Makes the pinned fixture frames of the array cases (two PNG pictures and the seeded `bound` frame) and publishes them as waveform PVs of a soft IOC every period, with a log of every publication | 0, 1, 2, 77 |
| `run-baseline.pl` | Drives and watches the 48-hour baseline observation of one guest: schedule, collectors, registration, query clients, evidence blocks with hard-linked staging, and a read-only watchdog (commands `plan`, `link-queries`, `prepare`, `run`, `watch`) | 0, 1, 2 |

Exit status 2 is invalid usage, 77 a missing or unusable input, and 1 a failure
to write the collected data. `run-baseline.pl` uses 0 (finished), 1 (a step of `run` failed or `watch` found a deviation) and 2 (invalid usage or an environment error). `copy-block.pl` also returns 3 when its manifest is
written but a file failed the check of earlier content.

```bash
perl tests/heap/analyze-gc.pl --help
perl tests/heap/sample-resources.pl --help
perl tests/heap/observe-ca.pl --help
perl tests/heap/query-archive.pl --help
perl tests/heap/copy-block.pl --help
perl tests/heap/run-baseline.pl --help
```

### Tool Tests

Each tool has a test that runs it as a subprocess through its command line.
The expected figures come from other tools (grep, awk, sort, wc, sha256sum, ps,
df, date, caget), and the processes and logs are real.

| Test | Real inputs | Run |
| --- | --- | --- |
| `tests/heap-analyze-gc.pl` | G1 logs written by real JVMs running `fixtures/Alloc.java` | `perl tests/heap-analyze-gc.pl` |
| `tests/heap-sample-resources.pl` | A real process, a real zombie, real signals | `perl tests/heap-sample-resources.pl` |
| `tests/heap-observe-ca.pl` | A real soft IOC (`fixtures/observe.db`) and the real `camonitor` | `AA_TEST_EPICS_BIN=<bin/host_arch folder of a real EPICS Base> perl tests/heap-observe-ca.pl` |
| `tests/heap-query-archive.pl` | `python3 -m http.server` serving real files; only the HTTP server stands in for the retrieval service | `perl tests/heap-query-archive.pl` |
| `tests/heap-request-array.pl` | The real client as a subprocess against `python3 -m http.server` serving a real file, a missing file and a server that never answers | `perl tests/heap-request-array.pl` |
| `tests/heap-feed-frames.pl` | The real feeder as a subprocess: PNG decoding against ImageMagick, the `bound` frame and `java.util.Random` against the real Java, and a real soft IOC read back with `caget` and `camonitor` (the IOC cases need `AA_TEST_EPICS_BIN`, softioc and numpy, and run on the guest; pass `--laser-frame` with a frame file written elsewhere) | `perl tests/heap-feed-frames.pl --maven <epicsarchiverap-maven checkout> [--laser-frame FILE]` |
| `tests/heap-run-baseline.pl` | The real driver as a subprocess: usage errors, the schedule against dates computed by `date -u -d`, and hard-linked staging checked by inode number | `perl tests/heap-run-baseline.pl` |
| `tests/heap-copy-block.pl` | Real files, a real process that appends to a log while it is copied, and real changes to the source and destination files | `perl tests/heap-copy-block.pl` |

Without `AA_TEST_EPICS_BIN` the observer test runs its usage and missing-input
cases and reports that the soft IOC cases were skipped.

## 48-Hour Baseline Driver

`run-baseline.pl` runs the observation of the accepted settings in `docs/reports/heap-baseline-settings-draft-20261123.md` on one guest that has the
appliance installed and nothing else running. `R` is the time at which all 100 PVs report `Being archived`. In hours after `R`: warm-up until 6, one evidence block every 6 hours
(8 blocks, the last at the cutoff, 48), four query clients from 42 to 48, and one more block 120 seconds after the collectors end. The collectors start before `R` and end 48.5 hours after their start.

1. Prepare the guest as in steps 1 and 2 of `tests/heap/rehearsal/README.md` (procServ, `ioc-runner`, lingering, the soft IOC of the 100 PVs and its PV name file, `camonitor` of the EPICS tree).
2. `perl tests/heap/run-baseline.pl prepare --guest <user>@<guest-address> --guest-dir <home>/baseline --service-account <service-account>` copies the sampler and the CA observer to the guest and writes `tools/sampler.args`
   from the process ids it finds (four JVMs, the soft IOC, the database); it prints the arguments.
3. `perl tests/heap/run-baseline.pl plan --r-time <UTC>` prints the schedule for a given `R`; it changes nothing.
4. `perl tests/heap/run-baseline.pl run --evidence-dir <evidence-dir>/baseline --guest <user>@<guest-address> --guest-dir <home>/baseline --service-account <service-account> --camonitor <camonitor> --pvs-csv <pvs.csv> --pv-names <pv-name-file>`
   starts the port forward, the collectors, registers the 100 PVs and waits for `R`, then performs the schedule. `--r-time` skips the registration; `--scale 30` or `--scale 60` runs the same schedule with one hour standing for 30 or 60 seconds.
5. `perl tests/heap/run-baseline.pl watch --evidence-dir <evidence-dir>/baseline --guest <user>@<guest-address> --guest-dir <home>/baseline` in a second process, started a few seconds after `run`, when `plan.json` exists in the evidence folder. It reads `plan.json` of the run, only reads the guest and ends with `ALERT` at the first deviation or `WATCH-END` after the end of the run. If `run` failed before it wrote `plan.json`, `watch` keeps waiting for the file without a message: end it by hand.
   An `ALERT` does not stop the run or the collectors; the operator decides, under the stop rules of the resource set (`Limits and stop rules` in `tests/heap/rehearsal/README.md`). The deviations are: the sampler, the CA observer or the appliance not active; the process ids of the four JVMs changed; guest `MemAvailable` below 200 MiB; the guest root filesystem at 80 percent or more; free inodes below 10 percent; an out-of-memory kill or anonymous memory at 90 percent of the limit of a collector or a query client; a query client not active during the query phase; the sampler file not growing for 30 seconds while the collectors run; less than 200 GiB free in the evidence folder.
6. Each step is a row of `stages.csv` (time, uptime, event, detail); `plan.json` holds `R`, the schedule and the process ids; the blocks are in `blocks/` and the staging folder in `staging/`, where the query files are hard links of `queries/`.

A failed unit of an earlier attempt blocks the next `run` with the same prefix (`Unit base-tunnel.service was already loaded`); clear it with `systemctl --user reset-failed <prefix>-tunnel.service`. The driver does not restart a stopped collector: the resume rule (restart within 30 minutes, record both times) is applied by hand. The sampler is started again under the same unit name and appends to `samples/samples.csv`; `observe-ca.pl` refuses an output folder that already holds a `run.json`, so the CA observer is started again with a new folder (`ca/run2`, `ca/run3`, ...) under the same unit name, and the block copies take every folder below `ca`. A
failed block copy is recorded and the run goes on; a failed step before it ends the run with status 1 and leaves the collectors running until their duration ends. The result of the check runs of the driver is in
`docs/reports/heap-baseline-driver-check-20261123`.

## Array Case Tools

The two tools serve the large-array cases of the heap measurement (`docs/reports/heap-array-run-inputs-draft-20261123.md`).

`feed-frames.py` makes the fixture frames and publishes them. `python3 tests/heap/feed-frames.py frame --name laser --images <folder of laser.png and airy.png> --output FILE` writes one frame as unsigned 16-bit little-endian values and prints its element count and SHA-256
(the pin); `bound` needs no folder. The pins are `laser` 1,405,025 elements `d05934e30059117bdc1afa6dcf63f2b431c808cb33672e56e84289a00d215723`, `airy` 4,915,200 elements `7a06547103de3ca762ac66bfcf8a7ebeb7bb43bfa63d626522c472a6d90361e6` and `bound` 5,529,600 elements `b3d85b7834d78afefb875e8a6ef636aa7799ec07035674c4fbc9b58265aa0199`.
`serve --names laser,airy,bound --period 30 --log FILE --images <folder> --prefix <device>:` hosts the waveform PVs `<device>:LASER`, `<device>:AIRY` and `<device>:BOUND` (the field type is USHORT, which Channel Access transfers as four bytes per element) and
publishes each frame at once and then every period with a newly observed timestamp; `EPICS_CA_MAX_ARRAY_BYTES` must be at least four bytes per element of the largest frame (22,118,400 for `bound`; the plan's candidate value is 24,000,000), and the server port variables of the environment decide where it listens
(a private port keeps it apart from another IOC on the host). It needs the Python modules softioc and numpy, which the IOC guest has in the user site; run it without `-I`. SIGTERM ends it at once, without another publication, and the log keeps the rows written up to then.

`request-array.pl --plan FILE --output-dir DIR --url URL [--clients N] [--groups G]` sends the requests of a plan with the header `name,pv,from,to` (times as `2026-11-24T06:55:05.000Z`); a group is one pass over the plan by all clients at once.
A request that fails or times out is a row of `requests.csv`, not an error of the tool.

## Analysing The 48-Hour Baseline

The analysis starts after `run_complete` and `tunnel_stopped` are in `stages.csv`, `watch.log` ends with `WATCH-END` and holds no `ALERT` line, and the manifests `blocks/manifests/block-0001.json` to `block-0009.json` all say `"ok": true` (and `copy-block.err` does not exist). The intervals and the tolerances are the accepted settings of `docs/reports/heap-baseline-settings-draft-20261123.md`. Run it from the root of this repository; `<evidence>` is the evidence folder of the run.

1. **Freeze the records.** Create `<evidence>/analysis` (the files of steps 1, 4 and 5 go there) and write the SHA-256 of `<evidence>/plan.json`, `stages.csv`, `watch.log` and `blocks/manifests/block-0009.json` (the manifest holds the length and hash of every evidence file) into `<evidence>/analysis/frozen.sha256` before any analysis.
2. **JVM start times.** While the JVMs still run, read them in UTC with a resolution of one second: `ssh <user>@<guest-address> 'for p in <jvm-pids>; do echo "$p $(TZ=UTC ps -o lstart= -p $p)"; done'`; the process ids are in `plan.json` (`jvm_pids`: mgmt, engine, etl, retrieval).
3. **Interval bounds in seconds of JVM uptime.** With `R` of `plan.json` and the start `S` of the JVMs: `OFF=$(( $(date -u -d <R> +%s) - $(date -u -d "<lstart>" +%s) ))`. The no-query interval is `OFF + 6 h` to `OFF + 42 h` (`OFF + 21600` to `OFF + 151200`), the query interval `OFF + 43 h` to `OFF + 48 h` (`OFF + 154800` to `OFF + 172800`), and the whole run `OFF` to `OFF + 172800` for context. The warm-up after readiness (to `OFF + 6 h`) and the first hour of the queries are excluded.
4. **Two copies of the GC logs.** Copy `blocks/data/gc/gc-<pid>.log` of the four JVMs into `<evidence>/analysis/copy1` and `copy2`.
5. **GC analysis on each copy and each interval.** `perl tests/heap/analyze-gc.pl --log mgmt=<copy>/gc-<pid>.log --log engine=<copy>/gc-<pid>.log --log etl=<copy>/gc-<pid>.log --log retrieval=<copy>/gc-<pid>.log --from <s> --to <s> --tolerance-mib 2 --tolerance-mib-per-hour 0.5 > <evidence>/analysis/<interval>-<copy>.json`, once for each of the three intervals and each copy; the minimum of 5 events per bin is the default of the script. `cmp` the two outputs of an interval: they must be identical.
6. **Reading the result.** Compare each JVM and each collection class separately. Young collections are required for all four JVMs; Mixed, Remark and Cleanup are reported and not required. Continuing growth is present only when the `trend` of a class says `"growth": true` (the last-bin minus first-bin median above 2 MiB and a positive slope above 0.5 MiB per hour). A bin with fewer than 5 events gives a `status` other than `computed`, which makes that comparison inconclusive; events of another interval are not borrowed. Report the event counts and the median after collection of every bin.
7. **Plausibility records.** `python3 -I tests/heap/rehearsal/summarize-samples.py <evidence>/blocks/data/samples/samples.csv` (the spacing of the samples, one `start_ticks` per process, the resident sets); `python3 -I tests/heap/rehearsal/summarize-queries.py <evidence>/blocks/data/queries` (requests, statuses, errors); the last event of each GC log against the uptime of the copy of the last block (they agree within the gap between two collections); the late-by value of every row of `stages.csv`; the size of `blocks/data/ca/run/camonitor.out`. The times in that output are the local time of the guest, not UTC (UTC minus 8 hours in November).
8. **Results record.** Put the analysis files, the two summaries, `stages.csv`, `watch.log`, the JVM start times and a README with the intervals, the bin tables and the verdict of each comparison into `docs/reports/heap-baseline-48h-<date>/`, and the observed facts into the register. The raw files (query responses, CA output, the copied blocks and the staging folder) are not kept after the analysis; deleting paths outside the repository needs the owner's approval for each path, and the small records stay with a `SHA256SUMS`.

Rehearsal of this procedure: steps 2 to 5 were run on the blocks of the first 18 hours of the run for one interval (the no-query interval up to that time) and the two copies, and from step 7 the summary of the samples, the comparison of the last GC events with the copy time and the lateness of the stages were run; the two copies gave identical outputs. `summarize-queries.py`, the query interval and the whole-run interval have not run, because the queries start at `R` + 42 h and no query folder existed then.
