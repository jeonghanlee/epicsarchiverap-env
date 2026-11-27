# Array Case Drivers

These tools run the large-array cases of the heap measurement on the guest that runs the appliance
(`docs/reports/heap-array-run-inputs-draft-20261123.md`). `feed-frames.py` (one directory up) publishes the pinned frames and
`request-array.pl` sends the requests; the tools of this directory register the frames, run the retrieval and engine cells and
read and classify the results. The drivers find `request-array.pl` one directory above them, so copy the whole `tests/heap` tree to
the guest and keep its layout; a copy of `array-cases/` alone cannot send the requests.

## Tools

| Tool | Purpose | Exit statuses |
| --- | --- | --- |
| `array-common.bash` | Sourced by the three drivers: configuration read from the environment, stop rules, JVM state record, heap override with saved originals, the outcome function of an engine attempt | not run alone |
| `prepare-frames.bash` | Registers `LASER`, `AIRY` and `BOUND` with the engine at the preparation heap, waits for their stored files, pauses them and logs `first_event=UTC` | 0, 1, 2, 3 |
| `run-retrieval-cells.bash` | A reference group at the preparation heap, then one-client and four-client cells for each retrieval heap; every cell restarts the whole service | 0, 1, 2, 3, 5 |
| `run-engine-cells.bash` | For each engine heap, fresh subscription attempts of `airy`, `bound` and `airy+bound`, read back and compared with the pins | 0, 2, 3, 4 |
| `hash-events.pl` | Prints seconds, element count and SHA-256 of the elements of each event of a `getData.json` response, in blocks of 256 KiB | 0, 2, 77 |
| `classify-cells.pl` | Counts the outcome classes of the requests of the retrieval cells of one run; `--check-reference MIN_BYTES` checks the reference group | 0, 2, 77 |

Exit status 1 is no stored file within the bound (`prepare-frames.bash`) or a failed classification (`run-retrieval-cells.bash`), 3 is the stop rule (host `MemAvailable` below 200 MiB, root filesystem at 80 percent or inode use at 90 percent), 4 an
array PV or its data that exists when an engine run starts without `--delete-existing`, 5 a reference group that is not usable, 77 an
input that cannot be read. Each tool states its options with `--help` or in its header.

## Configuration

The environment variables of `array-common.bash` and their defaults: `ARRAY_HOME` (`$HOME/array`, the folder of the saved
configuration files and the default output folders), `APPLIANCE_DIR` (`/opt/epicsarchiverap-maven`), `SERVICE_ACCOUNT` (`mid-srv`, the owner of
the component configuration files, reached with `sudo -n -u`), `SERVICE_UNIT`, `MGMT_URL`, `RETRIEVAL_URL`, `STORE_ROOT`, `PV_PREFIX`
(`AASOAK:ARR:`), `PV_STORE_GLOB`, `PREP_HEAP_MIB` (512), `ENGINE_CA_BYTES` (24000000) and `RESTART_WAIT_S` (60). The drivers need
`sudo` without a password for the service account, `systemctl restart`, `journalctl` and reading `/proc/<pid>/environ`.

## Behaviour

- A heap override appends `CATALINA_OPTS="$CATALINA_OPTS -Xms<N>M -Xmx<N>M"` (and `EPICS_CA_MAX_ARRAY_BYTES` for the engine) to the
  component configuration file, which the launcher reads after the common configuration; the first copy of the file is kept in
  `$ARRAY_HOME/saved` and never replaced.
- Every driver puts the saved files back and restarts the whole service when it ends, also after a stop rule or a termination signal.
  The appliance runs under one supervising service that ends when one JVM ends, so a heap change is always a restart of the whole service.
- The engine run reads the stored frames through the retrieval service, which runs at the preparation heap; its attempts end when
  every PV is archived and has a stored file or at the bound, and the PVs are paused and deleted with their data after each attempt.
  An attempt is Archived only when every PV reached `Being archived` and every stored event equals the pin; it is Failed when the engine JVM
  ended, the kernel killed a process or the engine logged an `OutOfMemoryError`.

## Procedure

1. Start the frame feeder: `python3 tests/heap/feed-frames.py serve --names laser,airy,bound --period 30 --log FILE --images DIR
   --prefix AASOAK:ARR:` with `EPICS_CA_MAX_ARRAY_BYTES=24000000` in its environment, under a user unit that survives the terminal.
2. `prepare-frames.bash`; read `first_event=` in its `run.log` (default `$ARRAY_HOME/logs/prepare/run.log`; the other drivers write
   `$ARRAY_HOME/logs/retrieval-cells/` and `$ARRAY_HOME/logs/engine-cells/` unless `--output` is given).
3. `run-retrieval-cells.bash --first-event <that time>`; then `classify-cells.pl <output folder>` for the counts.
4. Delete the three PVs with their data (`run-engine-cells.bash --delete-existing` does it at the start), then `run-engine-cells.bash`.

Run the drivers as a user unit (`systemd-run --user`) and read their `run.log`. The memory of `hash-events.pl` does not depend on the
size of an event: check a new copy with a real response under a cap of the address space, for example `( ulimit -v 120000; perl
hash-events.pl response.json )` on a response of more than 100 MiB; the test below does not measure memory.

## Test

`perl tests/heap-array-cases.pl` checks `hash-events.pl` and `classify-cells.pl` through their command lines, with the expected hash taken
from `sha256sum` of bytes written by arithmetic, and the outcome function of `array-common.bash` over every combination that matters. The
drivers themselves are checked by real runs on the guest: `docs/reports/heap-array-tools-check-20261127` records the runs and the mutants.
