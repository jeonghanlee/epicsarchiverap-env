# Test groups of the local suite

The test entry point `tests/run-all-tests.bash` separates the checks that run on the checkout from the operations that need a virtual machine. This page names what each group proves and what it leaves to the next level.

## Checks that run on the checkout

| Group | Script | What it checks |
| :--- | :--- | :--- |
| Phase 1: Logic | `tests/phase1-logic.bash` | Structure of the Make system and the configure tree. The OS presets exist, the targets parse, and the generated policy and properties carry the settings. The control script reports failed instances, prints the addresses and checks the arguments of `loglevel`. The checks also cover the storage placement warning and the database backend and socket settings. This group calls the groups below |
| Shared Perl helpers | `tests/perl-helpers.pl` | File access, process execution, argument handling, and cleanup through the shared test module |
| Health | `tests/health-local.pl`, `tests/health-starting.bash` | Launcher health, process identity, diagnostics, isolated unit installation, and bounded allowance for instances that have not executed Java |
| Local runtime settings | `tests/config-d.pl` | Configuration selection, ordered overrides, invalid or unreadable inputs, and preservation through temporary installation targets |
| No Ant | `tests/no-ant.bash` | The tracked tree holds no Ant settings and no site build file, and the site id reaches every Maven call of the build and clean targets |
| Interface files | `tests/ui-static.bash` | The management interface files of the selected source clone, listed in `tests/ui-files.list`, checked without a browser. The checks cover marker blocks, content security policy, inline code, jQuery and outside hosts (a navigation link may name one; a script, a style or a data call may not), element ids and files, text contrast, and the checksum of the vendored chart library. Each rule has a broken copy that must be refused |
| Database and installer entry points | `tests/database-config.pl`, `tests/database-settings.bash`, `tests/local-install-output.bash`, `tests/local-install-epics.pl` | Database rendering and identity, installer readiness output, and Experimental Physics and Industrial Control System (EPICS) prerequisites for process variable (PV) verification. The settings check requires the real database client |
| Installer configuration | `tests/local-install-config.bash` | The three installers refuse an invalid `configure/CONFIG_SITE.local` before any `make` step, `sudo` or package step, accept an absent file and each generated include, and the direct OS targets still write the generated include. The check reads the exec trace of every installer call, runs each call with `--plan` or `--help`, and installs nothing |
| Phase 2: Build wrapper | `tests/phase2-compile.bash` | The command generation of the real Makefile: the configuration resolves its paths, the build target orders the copy of the site folder before the Maven call, and the rendered build has no interface copy step |

## What the local checks do not prove

The local checks use isolated files, generated commands, and controlled process or transport boundaries. Some checks start Java processes or invoke installation targets under temporary directories. These results do not establish a host installation through its packages, database, and systemd services.

Phase 2 checks the commands from `make -n build`; it does not compile web application archive (WAR) files. Source compilation and unit tests belong to the source repository's continuous integration (CI). Real guest installation verifies the configured site build and the installed appliance separately.

The `--local` mode runs Phase 1 followed by Phase 2. The `--phase=2` mode runs that same pair of phases, so it is not an additional compilation check after a complete local result. Optional prerequisites and skipped checks remain explicit in the result.

## Virtual machine operations

The `--case` mode of `tests/run-all-tests.bash` forwards explicit guest inputs to `tests/vm/install.pl`. One invocation verifies installation, stored samples, service restart, and unchanged installer re-application on one fresh guest. The selected matrix combines Debian 13 and Rocky Linux 8.10 with SQLite, MariaDB over a Unix socket, and MariaDB over Transmission Control Protocol (TCP).

The entry points `tests/phase3-docker.bash` and `tests/phase4-vm.bash` are compatibility names for that complete sequence. They do not split installation from runtime verification. Guest lifecycle belongs to cloud-provision; the [virtual machine (VM) verification reference](vm.md) defines the inputs and results.
