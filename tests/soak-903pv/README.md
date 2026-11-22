# 903-PV day run of the Archiver Appliance

This folder holds everything that the 24-hour run of 903 PVs needs again: the procedure, the tools, the PV and IOC files and the files of the earlier run. The run proves that an appliance built and installed from a source commit archives 903 PVs for 24 hours with the checks C1 to C9 of the record `docs/reports/soak-903pv-20261026.md`. Its second record, `docs/reports/soak-903pv-20261120.md`, shows how the method and the result are written; its results are in `docs/reports/soak-903pv-20261120-evidence`.

The tools are Python 3 (standard library only) and Bash. All but `compare-wars.py` and `cpu-stats.py` are kept as they were run, except for the placeholders named below; those two scripts hold the code that was first typed on the command line for the WAR comparison and the CPU figures; `cpu-stats.py` reproduces its figures on the kept collector log, and `compare-wars.py` gave the same entries as the kept `war-comparison.txt` when it was run afterwards on the WARs, which are not kept. They are a verification kit, not part of the Perl tests of `tests/`.

## Contents

| Path | Content |
| :--- | :--- |
| `tools/collect.py` | The collector: every cycle it reads the checks C1 to C7 (and the CPU columns) and writes `evidence/soak-log.csv` and one `evidence/cycle-<time>.json` |
| `tools/register.py` | One `archivePV` request for all PVs of `pvs-all.csv` (from `ansible-provision`, run unchanged) |
| `tools/poll_status.py` | Waits until every PV reports `Being archived` |
| `tools/final-measure.py` | The measurements after the window: whole-day retrievals of 16 PVs, retrieval of the last closed hour for all PVs, versions, store folders, storage metrics |
| `tools/summarize.py` | Condenses `evidence/soak-log.csv` into the statistics of the checks C1 to C6 and C7 |
| `tools/cpu-stats.py` | Condenses the CPU columns of the collector log |
| `tools/compare-wars.py` | Compares the WARs of two builds entry by entry |
| `tools/watch.bash` | Read-only watchdog that checks the run every 10 minutes and ends with an `ALERT` line at the first deviation |
| `tools/stores.bash` | Lists the store folders of the six sample PVs (run it with sudo; `final-measure.py` run as root lists them too) |
| `fixtures/` | `pvs-all.csv` and `pvnames.txt` (903 PVs), `ioc/aasoak.db`, `ioc/load1.db`, `ioc/load2.db`, and the IOC start-up `ioc/st.cmd.guest` and conf `ioc/aasoak-soak.conf.guest` (placeholders for the user and the paths of the guest) |
| `original-2026-10/` | The three files of the earlier run that differ from the files above: `collect.py` without the CPU columns, `st.cmd` and `aasoak-soak.conf` for the development host |
| `SHA256SUMS` | SHA-256 of every file of this folder except this README; check with `sha256sum -c SHA256SUMS` |

## Placeholders

The kept copies of `collect.py`, `st.cmd`, `aasoak-soak.conf` and `watch.bash` replace the machine-specific names of the runs by placeholders; the code is otherwise the code that ran (the collector reads the user name from `USER` and has an empty default). Replace `<user>` with the user of the guest, `<home>` with its home folder, `<guest-address>` with the address or name of the guest and `<work-dir>` with a folder on the analysis host before use. The SHA-256 values in the records are those of the files as run; `SHA256SUMS` lists the files as kept.

The SHA-256 values of the PV files are in the record of 2026-10 (`pvs-all.csv` `037a92691bc23a6dcac37ec3613ad19c9f80b93b689209ec8dc403b519eaf594`, `aasoak.db` `c0a70bbd…`, `load1.db` `c7cfa5d2…`, `load2.db` `229f7f67…`); the copies in `fixtures/` match them.

## Pass condition

903 PVs registered and archived for 24 hours; every cycle of the collector without an error cycle; in every cycle the checks C1 (units and four JVMs), C2 (903 archived), C3 (903 connected), C4 (six sample PVs at 99 percent or more of the expected count), C5 (no dropped events) and C6 (no stale changing PV) pass; after the window, the whole-day retrieval of 16 PVs is complete (HTTP 200, at least 99 percent of the expected count), the last closed hour of all 903 PVs is at least 99 percent (the 10 `deadband` PVs are reported without a period rule), the folders show the earlier data in the MTS and only the latest hours in the STS, and the scheduled health service reports no `FAIL`, `ERROR`, `SKIP`, `STARTING` or `Failed` line (C9). Memory, disk and CPU are recorded as observed values only. The verdict on the run belongs to the owner of the source repository.

## Procedure

Times are UTC. Let `T0` be the registration time of step 5.

1. **Guest.** Ask the session that owns the provisioner for one fresh guest. The run used Debian 13 (x86_64), 2 vCPU (the provisioner fixes the vCPU count), 8 GiB of memory, 60 GiB of disk, no swap. State the vCPU count in the record. The guest needs a user with key login and password-less sudo and a network that reaches GitHub and Maven Central.
2. **Stage files on the guest.** Copy this folder, the EPICS tree `1.3.0/debian-13/7.0.10` (about 876 MB; the shebang of `st.cmd` names it), and `ioc-runner` and `procServ` (the `ioc-runner` 1.4.1 and `procServ` of the development host). Install the package `libevent-pthreads-2.1-7t64`, which `softIocPVX` needs, and install `ioc-runner` and `procServ` into `/usr/local/bin`.
3. **Install.** Send the installer with `git archive` of the chosen commit of this repository to `~/epicsarchiverap-env` on the guest. The installers build the source commit that `SRC_TAG` of `configure/RELEASE` names; they have no path for a prebuilt bundle. Set the pin in the guest copy (`SRC_TAG:=<source commit>`), keep the original line, run `bash scripts/install-local-sqlite.bash --plan`, then `bash scripts/install-local-sqlite.bash -y` (about 5 minutes). Record the installer commit, the pin and the line you changed.
4. **WARs.** When a bundle of the same commit exists, hash the four built WARs (`epicsarchiverap-maven-src/target/aa-*-<name>.war`) and the WARs in the bundle, and run `tools/compare-wars.py <bundle-dir> <built-dir>` with `mgmt.war`, `engine.war`, `etl.war` and `retrieval.war` in each directory. A difference in the configuration files and the UI files comes from the site id of the installer; a difference in classes or libraries must be reported.
5. **IOC and registration.** Enable lingering for the user (`sudo loginctl enable-linger <user>`). Put `fixtures/ioc` in `~/rv15/ioc/iocBoot/iocAasoak` (rename `st.cmd.guest` to `st.cmd` and make it executable, rename `aasoak-soak.conf.guest` to `aasoak-soak.conf`, put the three database files in `db/`, and replace `<user>` and `<home>` in both files, for example with `sed -i "s#<home>#$HOME#g; s#<user>#$(id -un)#g"`), install and start the IOC with `ioc-runner --local -f install <conf>` and `ioc-runner --local start aasoak-soak` (set `XDG_RUNTIME_DIR=/run/user/<uid>` in a non-login SSH shell), and read all 903 names of `pvnames.txt` with `caget` on the loopback address. Then run `register.py pvs-all.csv <out-dir> registered.csv http://localhost:17665/mgmt/bpl` in the folder with the PV files and note the time as `T0`, and run `poll_status.py 600` until all 903 report `Being archived`.
6. **Collector.** In a folder that holds `pvnames.txt` and `pvs-all.csv`, check one cycle without writing evidence: import `collect.py`, call `cycle()` and print the row. Then schedule the collector as a transient user unit that starts at `T0` + 30 minutes: `systemd-run --user --unit=rv15-collector --on-calendar="<T0+30min> UTC" --working-directory=<folder> --setenv=USER=<user> --property=Type=simple /usr/bin/python3 collect.py <until> 600`. Give `<until>` as `T0` + 24 hours + 10 minutes: the collector stops before the first cycle after `<until>`, and with `T0` + 24 hours the last cycle falls 10 minutes short of the 24 hours.
7. **Watchdog.** Edit the constants at the top of `tools/watch.bash` (guest, log file, end of the collector, end of the watch) and run it in the background on the analysis host. It checks the collector, IOC and appliance units, four JVMs, the age of the last row, the content of the last row and the free disk every 10 minutes.
8. **After the window.** Start these after the collector ended. Run `final-measure.py <S> <E>` as root in the folder with `pvs-all.csv`, about 20 minutes after the window ends. `S` is the first full minute after all PVs report `Being archived` and `E` is `S` + 86,340 s (the run of 2026-11-20: `S` 2026-11-20T23:56:00Z, `E` 2026-11-21T23:55:00Z). Read the ETL counters with `curl http://localhost:17665/mgmt/bpl/getInstanceMetrics`. Count the runs of the scheduled health service for `T0` to `T0` + 24 hours with `journalctl -u epicsarchiverap-maven-health.service --utc --since "<T0> UTC" --until "<T0+24h> UTC" --no-pager`: the number of `Finished` lines and the number of lines with `FAIL`, `ERROR`, `SKIP`, `STARTING` or `Failed`. Name the time zone in the bounds, as the journal reads bounds without it in the local zone of the guest. Run `summarize.py 903 0` and `cpu-stats.py` in the folder with `evidence/`.
9. **Record and results.** Copy the run folder of the guest to the analysis host. Write the report, with the method and the result of each check, after the model of `docs/reports/soak-903pv-20261120.md`. Keep the results next to it with a hash list: the collector log, the statistics of `summarize.py`, the output of `final-measure.py`, the ETL counters and the WAR comparison. The detail files of the run (the cycle files, the installer output, the registration, the status poll, the watchdog log, the journal extract) need not be kept. Then send the finished notice of the guest to the provisioning session.

## Points that cost time

- The installer builds the source commit; install a prebuilt bundle only by a step outside the installer, and record it as a deviation.
- The built WARs carry the site id of the installer, so their configuration and UI entries differ from those of a bundle built without a site; the classes and libraries are the same.
- `collect.py` reads the user unit `epics-@aasoak-soak.service`, the processes of the service account `tomcat` and the filesystem `/arch`; on another layout change these names and record the change.
- A `__pycache__` folder next to the tools breaks a plain `scp` of the folder; copy the files by name.
- The journal reads `--since` and `--until` in the local zone of the guest unless the zone is named; the guest used Pacific time.
- The first cycle must not come before the window of the first retrieval is covered; 30 minutes after `T0` was used.
