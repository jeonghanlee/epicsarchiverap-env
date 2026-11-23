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

Six more tools in this directory support the measurement. Each prints
its synopsis and options with `--help`, and its POD ends with an EXIT STATUS
section (`pod2text tests/heap/<tool>.pl` shows it); all need Perl 5.26 or newer and core modules
only.

| Tool | Purpose | Exit statuses |
| --- | --- | --- |
| `analyze-gc.pl` | Reads one G1 unified log per JVM and reports pause statistics per collection class, the after-GC heap of four equal bins of a comparison interval and its least-squares trend | 0, 2, 77 |
| `sample-resources.pl` | Appends host memory, process and filesystem figures to one CSV file at a fixed interval until a count, a duration or a signal ends it | 0, 1, 2, 77 |
| `observe-ca.pl` | Runs `camonitor` for a PV list, keeps its output unmodified and writes a run record (command line, working directory, UTC and monotonic start and end, exit status or signal, file sizes) | 0, 1, 2, 77 |
| `query-archive.pl` | One client of the retrieval load: reads random PVs through the retrieval service, stores each full response with its SHA256 and writes one CSV row per request | 0, 1, 2, 77 |
| `copy-block.pl` | Copies the evidence files of one block into a cumulative tree, appends only the new bytes after proving that the earlier bytes are unchanged, and writes a manifest with each file's length, SHA256 and last newline | 0, 1, 2, 3, 77 |
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

The driver does not restart a stopped collector: the resume rule (restart within 30 minutes, record both times) is applied by hand. The sampler is started again under the same unit name and appends to `samples/samples.csv`; `observe-ca.pl` refuses an output folder that already holds a `run.json`, so the CA observer is started again with a new folder (`ca/run2`, `ca/run3`, ...) under the same unit name, and the block copies take every folder below `ca`. A
failed block copy is recorded and the run goes on; a failed step before it ends the run with status 1 and leaves the collectors running until their duration ends. The result of the check runs of the driver is in
`docs/reports/heap-baseline-driver-check-20261123`.
