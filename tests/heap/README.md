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

Four more tools in this directory support the measurement. Each prints
its synopsis and options with `--help`, and its POD ends with an EXIT STATUS
section (`pod2text tests/heap/<tool>.pl` shows it); all need Perl 5.26 or newer and core modules
only.

| Tool | Purpose | Exit statuses |
| --- | --- | --- |
| `analyze-gc.pl` | Reads one G1 unified log per JVM and reports pause statistics per collection class, the after-GC heap of four equal bins of a comparison interval and its least-squares trend | 0, 2, 77 |
| `sample-resources.pl` | Appends host memory, process and filesystem figures to one CSV file at a fixed interval until a count, a duration or a signal ends it | 0, 1, 2, 77 |
| `observe-ca.pl` | Runs `camonitor` for a PV list, keeps its output unmodified and writes a run record (command line, working directory, UTC and monotonic start and end, exit status or signal, file sizes) | 0, 1, 2, 77 |
| `query-archive.pl` | One client of the retrieval load: reads random PVs through the retrieval service, stores each full response with its SHA256 and writes one CSV row per request | 0, 1, 2, 77 |

Exit status 2 is invalid usage, 77 a missing or unusable input, and 1 a failure
to write the collected data.

```bash
perl tests/heap/analyze-gc.pl --help
perl tests/heap/sample-resources.pl --help
perl tests/heap/observe-ca.pl --help
perl tests/heap/query-archive.pl --help
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

Without `AA_TEST_EPICS_BIN` the observer test runs its usage and missing-input
cases and reports that the soft IOC cases were skipped.
