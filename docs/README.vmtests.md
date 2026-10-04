# VM installation and runtime tests

The VM tests install the Archiver Appliance on fresh virtual machines through
the real provisioning tools and verify the installed system independently.
This document describes the test architecture, the run and case model, the data
each step consumes and produces, and the rules that decide a verdict.

## Scope

This document covers the design of the system test driver in `tests/vm/`: its
inputs, the guest handoff contract, the case sequence, the run context, cleanup
verification, and the verdict.

**Out of scope:** VM image and cloud-init internals, which cloud-provision owns;
Ansible roles and operators, which ansible-provision owns; Make targets, which
`configure/` and `Makefile` define. Commands for running the tests are in
`tests/README.md`. Acceptance criteria, the T1-T15 labels, and observed results
are in `docs/milestone-2.0.1.md`, M10.

## Component responsibilities

Three repositories cooperate. Each one keeps its own implementation; the driver
calls only their public entry points.

| Repository | Responsibility in a run |
| --- | --- |
| cloud-provision | Creates each fresh guest, reports its identity in a handoff, shuts guests down, and removes owned resources on request |
| ansible-provision | Provisions EPICS, JDK, Tomcat, and the selected database, then runs this repository's ordered Make targets with explicit commits |
| epicsarchiverap-env | Verifies guest ownership and freshness, runs the installation, checks the installed system, and decides the verdict |

The driver never creates, stops, or deletes a guest. It reads libvirt state and
the guest over SSH, and it runs Ansible against exactly one guest at a time.

## Acceptance matrix

A complete run holds eight cases. Each case uses its own fresh guest with two
vCPUs, 4 GiB of memory, and a 20 GiB disk.

| Case | OS | Backend and transport | Ansible species | Required checks |
| --- | --- | --- | --- | --- |
| `debian13-socket` | Debian 13 | MariaDB, local socket | `archiver_dev` | T3-T12 |
| `debian13-tcp` | Debian 13 | MariaDB, local TCP | `archiver_dev` | T3-T12 |
| `debian13-sqlite` | Debian 13 | SQLite | `archiver_dev_sqlite` | T3-T13 |
| `rocky8-socket` | Rocky 8.10 | MariaDB, local socket | `archiver_dev` | T3-T12 |
| `rocky8-tcp` | Rocky 8.10 | MariaDB, local TCP | `archiver_dev` | T3-T12 |
| `rocky8-sqlite` | Rocky 8.10 | SQLite | `archiver_dev_sqlite` | T3-T13 |
| `debian13-build-failure` | Debian 13 | SQLite | `archiver_dev_sqlite` | T3, T14 |
| `rocky8-build-failure` | Rocky 8.10 | SQLite | `archiver_dev_sqlite` | T3, T14 |

T1 and T15 apply to the run as a whole.

## Run model

A run is one private directory that accumulates the results of all eight cases.
The driver opens it once, adds one case per invocation, and evaluates it at the
end. Each invocation that changes the run holds an exclusive lock on the
directory; `--verdict` reads the run without the lock.

```
  --init        preflight, baseline, local-suite proof   -> run.json created
  --case X      one handed-off guest, one case           -> case X appended
  ...           repeated for the remaining cases
  (cleanup)     cloud-provision removes owned resources  -> outside the driver
  --verify-cleanup  independent removal and preservation -> cleanup.json
  --verdict     read-only evaluation                     -> exit 0, 1, or 77
```

A case invocation covers one guest, so an interruption loses at most that case.
A case that fails stays failed in the run; a later invocation cannot replace it,
and the run refuses further cases. Full acceptance then requires a separate
run.

### Run initialization

`--init` validates the configuration and refuses an existing evidence path. It
clones both appliance candidates and both tool repositories over HTTPS, and it
requires every pinned commit to exist in its published repository. The executing
`tests/vm/driver.py`, `tests/vm/guest.py`, `tests/vm/local.py`,
`tests/phase3-docker.bash`, `tests/phase4-vm.bash`, and
`tests/run-all-tests.bash` must equal their bytes in the published environment
candidate. The driver then runs that candidate's full `--local` suite once and
retains its command, exit status, and output digest.

Initialization records the run-start baseline: every libvirt domain and every
live and persistent DHCP reservation on the configured network. A guest present
in the baseline can never become a case guest, and cleanup verification must
find every baseline domain and reservation unchanged.

The tool origin check reads the stored `remote.origin.url` of each tool
checkout. It does not use `git remote get-url`, because a user's `insteadOf`
rule rewrites that output. Publication is proven by the clones, not by the URL
text. They run without global or system git configuration, so a rewrite rule
cannot turn them into authenticated SSH clones.

### Case execution

`--case <case> --handoff <file> <run>` adopts the guest that the handoff
describes and runs one case on it. Steps 1-6 read libvirt and guest state
without changing it. A failure in those steps, or in the absent source commit
check of a build-failure case, refuses the handoff with status 2 and leaves
`run.json` unchanged. The command logs, generated inventory, and host key file
of the refused attempt remain as evidence. After step 7 records the case, any
error, including a changed ownership, is a recorded failure of the run.

1. Validate the handoff fields and derive the VM, disk, seed, and creation
   record names from the prefix, OS selector, node, and creation ID.
2. Require that the domain UUID is absent from the baseline and from every
   earlier case of the run.
3. Read the domain, its single interface on the configured network, its
   attached disk and seed, the creation record, both reservations, and the
   lease. Every value must match the handoff, and the domain must have two
   vCPUs, 4 GiB of memory, and a disk of the configured `disk_size`.
4. Generate a single-host inventory with the cloud-provision generator and
   require that it names only that guest.
5. Copy the host key that cloud-provision stored for the guest address in
   `~/.ssh/known_hosts` into the guest's own known-hosts file, and refuse the
   handoff when no key is stored. Every SSH and Ansible connection to the
   guest accepts only that key; Ansible runs with host key checking enabled
   even when the ansible-provision configuration disables it.
   Collect guest facts with the shell-only facts command and require the case
   OS release, two CPUs, the hostname from cloud-init metadata, the reserved
   address on the owned interface, and the configured free disk space.
6. Require a fresh guest through one `sudo -n sh -c` probe: cloud-init done
   without errors; none of `guest.source_parent`,
   `<guest.install_parent>/epicsarchiverap-maven`, `guest.store_top`,
   `/usr/local/sbin/archiver-build.sh`, and `/var/tmp/archiver-build.done`
   present; a successful service unit-file listing; and no unit whose name
   starts with `epicsarchiverap`, `archiver-build`, `mariadb`, or `mysql`.
7. Record the case with T3 passed and the earlier guests that remain owned and
   present. Run the case's species with explicit environment and source
   commits, limited to the guest. For a build-failure case, pass a source
   commit that the published source repository does not contain.
8. For a positive case, prove the detached build, transfer the verifier and
   fixture, and run the guest verifier actions. For a build-failure case,
   observe the real checkout failure and the missing success sentinel.
9. Stop the owned test IOC and mark the case verified. After any failure, the
   driver records it and stops every helper unit it owns on unfinished cases.

The driver performs the interruption and cleanup-refusal checks once per run,
on the first positive case, while its guest is live.

### Cleanup verification

Cleanup happens in cloud-provision on an explicit request after all cases have
run. `--verify-cleanup <run>` then reads libvirt and the image directory
independently. It requires each owned domain, disk, seed, and creation record
to be absent, and each owned MAC address and IPv4 address to be absent from both
live and persistent reservations. Every baseline domain and reservation must
keep its identity.

Verification refuses with status 2 when ownership is incomplete, overlaps the
baseline, or a domain carries an owned name with another UUID. A changed
baseline entry is a failure. While an owned resource remains, verification
returns 77 and can run again after cloud-provision completes the cleanup. An
inspection error never counts as absence: verification returns 77, records
nothing, and can run again.

### Verdict

`--verdict <run>` reads the run without changing it. It returns 0 only when all
of these hold:

- Each of the eight cases is present exactly once, in any order, and every
  required check passed.
- At least one case started while an earlier case's guest remained owned and
  present.
- The lifecycle checks and cleanup verification passed.
- The local-suite proof matches the candidate.
- Every recorded evidence file matches its recorded digest.

A recorded failure returns 1. Anything missing returns 77.

## Guest handoff

cloud-provision reports each guest it creates in a private markdown handoff.
The operator writes the driver's handoff JSON file from that report; the driver
rechecks each value against live state. `schema` is the JSON integer `1`; every
other value is a JSON string. `tool_ref` is the full commit that the `Tool tree`
line names.

| Field | Content | cloud-provision handoff line |
| --- | --- | --- |
| `schema` | `1` | none |
| `os_selector` | `debian13-archiver-dev` or `rocky8-archiver-dev` | `OS selector` |
| `prefix` | VM name prefix | `Prefix selector` |
| `node` | Node selector | `Node selector` |
| `creation_id` | Run ID used at creation | `IMAGE_WORKFLOW_RUN_ID` |
| `uuid` | Domain UUID | `Actual domain UUID` |
| `vm_name` | Domain name | `Domain name` |
| `mac` | Interface MAC address on the configured network | `Actual interface MAC` |
| `address` | Reserved and leased IPv4 address | `Reservation and lease IP` |
| `disk` | Absolute path of the independent disk | `Independent disk` |
| `seed` | Absolute path of the seed ISO | `Seed` |
| `record` | Absolute path of the creation record | `Creation record` |
| `tool_ref` | cloud-provision commit that created the guest | `Tool tree` |

## Guest verifier actions

The driver runs `tests/vm/guest.py` on the guest as root inside a transient
systemd unit. Each action returns structured evidence for the case.

| Action | Checks | Labels |
| --- | --- | --- |
| `installation` | Guest commits, WAR, JAR, and configuration bytes, site assets, ports, units, ownership, database schema and transport | T5, T6 |
| `runtime` | JVM identities, launcher health, three scheduled health runs, HTTP identity, IOC load, CA-to-retrieval data, restart persistence | T7-T11 |
| `snapshot` | Stored history and current JVM identities before reapply | T12 |
| `unchanged` | Unchanged JVM identities and history after an unchanged Ansible apply | T12 |
| `reinstalled` | Payload, schema, health, history, and fresh data after a forced reinstall | T5-T9, T12 |
| `negative` | Wrong-instance PID detection and IOC-loss detection with recovery | T13 |
| `stop` | Stops the owned test IOC | none |

## Run context and evidence

The run directory has mode 0700 and contains only private evidence.

| File | Content |
| --- | --- |
| `run.json` | Configuration, baseline, local-suite proof, cases with ownership and results, lifecycle and cleanup state, failures |
| `report.json` | Candidate commits, per-case results, and the current verdict |
| `command-<n>.json` | Each external command with its arguments, exit status, output, and duration |
| `<case>-handoff.json` | The handoff as received |
| `<case>-<action>.json` | Guest verifier evidence for each action |
| `lifecycle.json`, `interruption.json` | Interruption and cleanup-refusal evidence |
| `cleanup.json` | Observations before and after cleanup |
| `<case>.ini` | Generated single-host inventory |
| `<case>-variables.json` | Ansible variables of the latest apply |
| `<case>-guest.json` | Verifier input transferred to the guest as `case.json` |
| `<creation_id>.known_hosts` | The guest's stored host key, used by SSH and Ansible |
| `UnitTestPVs.db` | Original fixture extracted from its recorded commit |
| `candidate-env/`, `candidate-source/` | Published candidate clones |
| `tool-cloud/`, `tool-ansible/` | Publication proof clones of the pinned tools |
| `refusal-missing/`, `refusal-mismatched/` | Contexts used by the cleanup-refusal checks |
| `interruption-child.json`, `interruption-command-<n>.json` | Interruption check child output and commands |

## Exit status

| Status | Meaning |
| --- | --- |
| 0 | The selected operation passed; only `--verdict` 0 establishes acceptance |
| 1 | An observed build, runtime, assertion, ownership, or cleanup failure |
| 2 | Invalid input, invalid context, or refused ownership |
| 77 | A missing prerequisite or an incomplete run |

## Execution environment

The driver reads but does not edit `~/.ssh/known_hosts`; it keeps each guest's
host key in the run directory. A guest recreated at an address that already has
a stored key needs cloud-provision to refresh that key at creation. The driver needs no exclusive use of the network, because it
creates nothing; cloud-provision avoids address collisions when it creates a
guest. Each step of a case invocation has its own deadline in
`DEFAULT_BOUNDS`; the shell that starts an invocation must outlive all of them.
