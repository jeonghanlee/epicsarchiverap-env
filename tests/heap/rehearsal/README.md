# Rehearsals of the heap measurement

The rehearsals run the whole path of the heap measurement on a guest before the long observation: the appliance with GC logs from JVM start, a soft IOC with the 100 PVs of the first stage, the collectors, the query clients, the block copy and the GC analysis. They check that every tool works together on real data and that the limits and stop rules hold. The results are in `docs/reports/heap-rehearsal-20261122`; the plan is in `docs/milestone-9576820.md` (M7).

## Contents

| File | Content |
| :--- | :--- |
| `watch-2h.bash` | Read-only watchdog of the 2-hour rehearsal (the form after D74; the 2-hour run used its first form, which alerted on the count of limit events and did not log `memory.peak`) |
| `run-8h.bash` | Driver of the 8-hour rehearsal: starts the collectors, stops and restarts the sampler, starts the query clients, copies the blocks; writes every step to `stages.csv` |
| `watch-8h.bash` | Read-only watchdog of the 8-hour rehearsal (expects the sampler stop window) |
| `summarize-queries.py` | Condenses the request files of the query clients |
| `summarize-samples.py` | Condenses the CSV of the resource sampler |
| `SHA256SUMS` | SHA-256 of every file of this folder except this README; check with `sha256sum -c SHA256SUMS` |

The scripts use placeholders in place of the machine-specific names of the runs: `<user>` and `<home>` (the user of the guest and its home folder), `<guest-address>`, `<service-account>` (the account of the appliance), `<uid>` (the user id of the analysis host user), `<evidence-dir>` (the private evidence folder), `<repo>` (this checkout) and `<jvm-pids>` (the process ids of the four appliance JVMs, one per run). Replace them before use.

## Requirements

A guest with the appliance installed from the accepted refs (Rocky Linux 8.10, 2 vCPU, 4 GiB, MariaDB over a Unix domain socket, `AA_JAVA_OPTS` set to `-Xlog:gc*,safepoint:file=/arch/gc/gc-%p.log:uptime,level,tags`, `/arch/gc` created before the first start); the EPICS tree of Rocky 8.10 on the guest (`softIocPVX`, `camonitor`, `caget`); the tools `tests/heap/sample-resources.pl`, `observe-ca.pl`, `query-archive.pl`, `copy-block.pl`, `analyze-gc.pl`; `register.py` and `poll_status.py` of `tests/soak-903pv/tools`; the 100 PVs `pvs.csv` and the database `aasoak.db` of `tests/archiver-soak/fixtures` in `ansible-provision`.

## Limits and stop rules (D72, D74)

Guest (cgroup v1, `MemoryLimit`): sampler 64 MiB, CA observer 128 MiB. Analysis host (cgroup v2, `MemoryMax`): each query client 512 MiB, the port forward 64 MiB. Stop when the guest `MemAvailable` is below 200 MiB, the guest root filesystem is at 80 percent or more, the free inodes are below 10 percent, a collector cgroup has an out-of-memory kill, or its anonymous memory is at 90 percent of its limit. The page cache of the files a collector writes counts toward its cgroup limit and is no stop condition; the count of limit events (`memory.failcnt`, `memory.events`) is recorded only.

## 2-hour rehearsal

Times are UTC. Let `T0` be the registration time.

1. **Tooling on the guest.** The guest firewall rejects the appliance ports from the analysis host, so only the guest side is prepared here: `sudo dnf install procServ` (EPEL), link it to `/usr/local/bin/procServ`, copy `ioc-runner` to `/usr/local/bin`, `sudo loginctl enable-linger <user>`.
2. **Soft IOC.** Put `aasoak.db`, an executable `st.cmd` whose shebang is `modules/pvxs/bin/linux-x86_64/softIocPVX` of the EPICS tree and which loads the database and runs `iocInit`, the names of the 100 PVs and a conf (`IOC_USER`, `IOC_GROUP`, `IOC_CHDIR`, `IOC_PORT=""`, `IOC_CMD="./st.cmd"`, the four loopback `EPICS_*` variables and `EPICS_CA_MAX_ARRAY_BYTES=16384`) in a folder on the guest. Install and start it with `ioc-runner --local -f install <conf>` and `ioc-runner --local start <name>` (with `XDG_RUNTIME_DIR=/run/user/<uid>`) and read all 100 names with `caget` on the loopback address.
3. **Collectors on the guest.** Read the process ids of the four JVMs from `ps -u <service-account>` (the instance name is in `-Dcatalina.base`), the soft IOC and `mysqld`. Start the sampler as a transient system service: `sudo systemd-run --unit=reh-sampler -p User=<user> -p WorkingDirectory=<home>/rehearsal -p MemoryLimit=64M -p Type=simple perl tools/sample-resources.pl --output samples/samples.csv --interval 5 --duration <s> --process mgmt=<pid> --process engine=<pid> --process etl=<pid> --process retrieval=<pid> --process ioc=<pid> --process mariadb=<pid> --filesystem root=/`; the CA observer the same way with `-p MemoryLimit=128M`, `-p Environment="EPICS_CA_ADDR_LIST=127.0.0.1 EPICS_CA_AUTO_ADDR_LIST=NO EPICS_CA_MAX_ARRAY_BYTES=16384"` and `perl tools/observe-ca.pl --pv-list <pvnames> --output-dir ca/run --camonitor <camonitor> --duration <s>`. The `systemd-run` of systemd 239 has no `--working-directory` or `-E`; use the properties.
4. **Port forward and stages.** Start `ssh -N -o ControlMaster=no -o ControlPath=none -o ExitOnForwardFailure=yes -L 127.0.0.1:18665:127.0.0.1:17665 -L 127.0.0.1:18668:127.0.0.1:17668 <user>@<guest-address>` with `systemd-run --user -p MemoryMax=64M` (a forward requested on a multiplexed connection is served by the master process, outside the limit). Keep `stages.csv` (`time_utc,uptime_s,event,detail`) with one row per event.
5. **Registration.** `register.py pvs.csv <out-dir> registered.csv http://127.0.0.1:18665/mgmt/bpl` (note `T0`), then `poll_status.py 600` on the guest until all 100 report `Being archived`. Read `getPVTypeInfo?pv=<pv>` of one PV of each kind (basic, fast, slow, waveform, deadband) for the effective stores.
6. **Query clients.** Start four clients at a fixed time on the analysis host, each under `systemd-run --user -p MemoryMax=512M`: `perl tests/heap/query-archive.pl --pv-csv pvs.csv --output-dir <queries> --url http://127.0.0.1:18668/retrieval/data/getData.json --client <n> --pause 2 --duration <s>`. A transient timer (`--on-calendar`) needs `--timer-property=AccuracySec=1s`; without it the clients started about 50 seconds late.
7. **Watchdog.** Run `watch-2h.bash` (or `watch-8h.bash`) in the background on the analysis host.
8. **Block copy.** `rsync -a --rsync-path="sudo rsync"` the folder `/arch/gc` of the guest (the logs belong to the service account and are readable by its group only), the sampler folder and the observer folder into a staging folder, link the query files into it, and run `perl tests/heap/copy-block.pl --source <staging> --dest <blocks> --block <n>`.
9. **Analysis.** Read each JVM start with `TZ=UTC ps -o lstart= -p <pid>` (one second resolution) and convert the bounds of an interval to seconds since JVM start; the last event of each GC log must agree with the wall time of the copy within the collection gap. Copy the GC logs of the block twice and run `perl tests/heap/analyze-gc.pl --log mgmt=<file> --log engine=<file> --log etl=<file> --log retrieval=<file> --from <s> --to <s>` on each copy; the two outputs must be identical. Run the two summary scripts on the query folder and the sampler CSV.

## 8-hour rehearsal

`run-8h.bash <S> <pvs.csv>` does steps 3, 6 and 8 on a schedule from the start time `S`: collectors at `S`; the sampler stopped at `S`+4:00 and started again at `S`+4:10 under the same unit name and output file (the resume rule: restart within 30 minutes, record both times and the new process); four query clients at `S`+5:00 for one hour; block 1 at `S`+6:00; block 2 two minutes after the collectors end at `S`+8:00. It needs the appliance, the soft IOC, the port forward and `watch-8h.bash <S>` running, and on the guest, in `<home>/rehearsal`: `tools/` with `sample-resources.pl` and `observe-ca.pl` (the other tools of the requirements run on the analysis host) and `sampler.args` (the `--process` and `--filesystem` arguments of step 3 on one line), `ioc/iocBoot/iocAasoak/pvnames.txt` (the 100 PV names, one per line) and the output folders `samples8h` and `ca8h` (the script creates them). `watch-8h.bash` reads `samples8h` and `ca8h/run`.

Set before use, besides the placeholders: `CAMONITOR` in `run-8h.bash` (the path of `camonitor` in the EPICS tree of the guest) and the example start time in the usage lines. `watch-2h.bash` holds the times of the one 2-hour run as literals (`QUERY_START`, `QUERY_END`, `WATCH_END` and the sampler end `09:54:00Z`); change them to the new run. `poll_status.py` of step 5 reads `pvnames.txt` from its current folder, so run it from the folder that holds the file. The analysis (step 9) follows by hand.

## Points that cost time

- The page cache of written files counts toward a cgroup; a limit event count is not a failure of a collector.
- A systemd transient timer fires up to a minute late unless `AccuracySec=1s` is set.
- A transient user service does not report `MemoryPeak` on this host; read `memory.peak` of its cgroup while it runs, because the cgroup is removed when the service ends.
- The retrieval of a waveform PV over one hour is about 24 MiB per request; four clients write several GiB in 40 minutes.
