# Test groups of the local suite

The test entry point `tests/run-all-tests.bash` separates the checks that run on the checkout from the operations that need a virtual machine. This page names what each group proves and what it leaves to the next level.

## Checks that run on the checkout

| Group | Script | What it checks |
| :--- | :--- | :--- |
| Phase 1: Logic | `tests/phase1-logic.bash` | Structure of the Make system and the configure tree. The OS presets exist, the targets parse, and the generated policy and properties carry the settings. The control script reports failed instances, prints the addresses and checks the arguments of `loglevel`. The checks also cover the storage placement warning and the database backend and socket settings. This group calls the groups below |
| Health | `tests/health-local.py`, `tests/health-starting.bash` | The health check of `archappl.bash` for instances that have not executed Java yet: the shipped launcher runs under the real health command, and a stand-in holds each stage of the start chain |
| No Ant | `tests/no-ant.bash` | The tracked tree holds no Ant settings and no site build file, and the site id reaches every Maven call of the build and clean targets |
| Interface files | `tests/ui-static.bash` | The management interface files of the selected source clone, listed in `tests/ui-files.list`, checked without a browser. The checks cover marker blocks, content security policy, inline code, jQuery and outside hosts (a navigation link may name one; a script, a style or a data call may not), element ids and files, text contrast, and the checksum of the vendored chart library. Each rule has a broken copy that must be refused |
| Database and installer entry points | `tests/database-config.py`, `tests/local-install-output.bash`, `tests/local-install-epics.py` | The rendered database configuration for each backend, the readiness output of the installers, and the Experimental Physics and Industrial Control System (EPICS) preflight of the process variable (PV) verification, none of which installs anything |
| Installer configuration | `tests/local-install-config.bash` | The three installers refuse an invalid `configure/CONFIG_SITE.local` before any `make` step, `sudo` or package step, accept an absent file and each generated include, and the direct OS targets still write the generated include. The check reads the exec trace of every installer call, runs each call with `--plan` or `--help`, and installs nothing |
| Phase 2: Build wrapper | `tests/phase2-compile.bash` | The command generation of the real Makefile: the configuration resolves its paths, the build target orders the copy of the site folder before the Maven call, and the rendered build has no interface copy step |

## What the local checks do not prove

The local checks do not build the web application archive (WAR) files, start Tomcat or install anything. The compilation and the unit tests belong to the continuous integration (CI) of the source repository. The behavior of an installed appliance is the subject of the virtual machine operations.

## Virtual machine operations

The modes `--init`, `--case`, `--verify-cleanup` and `--verdict` of `run-all-tests.bash` hand over to `tests/vm/driver.py`. A case runs the installation and the runtime checks on its own fresh guest; the cases are named for the operating system and the database transport: `debian13-socket`, `debian13-tcp`, `debian13-sqlite`, `rocky8-socket`, `rocky8-tcp`, `rocky8-sqlite`, and a build-failure case for each operating system. The page [virtual machine (VM) verification operations](vm.md) explains the sequence.

The entry points `tests/phase3-docker.bash` and `tests/phase4-vm.bash` are compatibility names for one handed-off VM case.
