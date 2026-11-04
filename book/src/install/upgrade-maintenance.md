# Upgrade an appliance during a maintenance window

Use this procedure when an installed appliance needs an offline recovery backup before an upgrade. The [installer procedure](reinstall.md) describes layer selection and installation stages.

## Scope

Upgrade an existing Archiver Appliance through the local installer, preserving its database, archive stores, site configuration, and existing PV registrations. This procedure covers preparation, an offline backup, installation, verification, and recovery.

Confirm the installed host values before choosing commands. Keep host details, credentials, backup locations, and execution records in a private site record.

Process variables (PVs), input/output controllers (IOCs), Channel Access (CA), and PVAccess (PVA) use the terminology in the [glossary](../appendix/glossary.md). Short-, medium-, and long-term stores are abbreviated STS, MTS, and LTS.

Operating system (OS), Java Development Kit (JDK), Java virtual machine (JVM), and web application archive (WAR) retain their usual meanings.

**Out of scope:** changing database backend, moving archive stores, replacing the host OS, upgrading Java or Tomcat, and migrating existing database columns. Those changes require a separate procedure.

## Prerequisites

- A maintenance window that permits acquisition interruption. Samples emitted while acquisition is stopped might not be recoverable.
- An ordinary account that owns the checkout and can use `sudo`. Run the installer as that account, never with `sudo bash`.
- A supported host: Debian 13, Rocky 8, Rocky 10.2, Ubuntu 24.04, or Ubuntu 26.04; systemd and JDK 21. Reuse the existing compatible Tomcat.
- The current appliance uses the installation layout and service managed by this repository. If its service or layout differs, resolve that difference before using these commands.
- A backup destination with adequate space and a defined restore method for every filesystem holding archive data. A VM snapshot does not automatically cover separately mounted or network storage.
- The existing database credentials, socket or TCP endpoint, service account, and storage ownership. Record credentials privately; do not paste them into logs or the work register.
- Two or more representative production PVs, including a changing PV, with recorded pre-upgrade state and a historical retrieval interval.

Complete this inventory on the installed host before changing it:

| Item | Operator records before changing anything |
| --- | --- |
| OS and access | Distribution/version, checkout owner, sudo access |
| Repository | Absolute checkout path, current branch and commit, local changes |
| Installed application | Installation path, installed version, installed `.versions` if present |
| Runtime | Appliance unit, health timer/service if present, service user/group, Java and Tomcat paths |
| Database | SQLite file or MariaDB database, transport, endpoint/socket, private credentials |
| Storage | STS/MTS/LTS paths, mount sources, free space, snapshot or copy coverage |
| Site inputs | Parent and local `CONFIG_SITE.local` and `RELEASE.local`, local site templates, installed `config.d` |
| Baseline | Appliance identity, PV counts/states, representative historical samples and current samples |
| Recovery | Backup location, snapshot identifiers, restore method, latest time to start recovery |

## Steps

1. **Record the running installation and preserve its inputs.**

   Before updating Git or invoking Make, save the installed version and any installed `.versions`. Preserve the site inputs listed above, local modifications, installed configuration, and systemd unit files/drop-ins. Record absent optional files as absent.

   The installed `mgmt/conf/context.xml` identifies the backend and endpoint. Read it privately because it can contain a database password. Select the installer for that backend and transport.

   Record representative PV state and retrieve both recent samples and a fixed historical interval. Keep these results for the comparison after startup.

2. **Select the reviewed environment and application source.**

   The environment repository supplies installation scripts; the application source repository supplies the four WARs. Select and qualify both target commits before the maintenance window.

   Use the approved environment commit and an immutable application source commit. Updating the environment repository alone does not necessarily change the installed application version.

   Set the absolute checkout path and enter it:

   ```bash
   repo_root='<absolute_checkout_path>'
   environment_commit='<environment_commit>'
   cd -- "$repo_root"
   ```

   Replace `<absolute_checkout_path>` with the installed host's checkout path and `<environment_commit>` with its approved full environment commit hash. Stop if the directory change fails. Run the remaining commands in this same interactive Bash terminal.

   Inspect Git state before fetching:

   ```bash
   git -C "$repo_root" status --short --branch
   git -C "$repo_root" branch --show-current
   git -C "$repo_root" rev-parse HEAD
   git -C "$repo_root" fetch origin
   ```

   Require a clean checkout on `maven`, with no unrelated local commits. Preserve local changes before continuing; do not reset or overwrite them. Advance only to the reviewed commit:

   ```bash
   git -C "$repo_root" merge --ff-only "$environment_commit"
   git -C "$repo_root" rev-parse HEAD
   ```

   Require that HEAD equals `environment_commit`. An ahead, divergent, or differently named branch requires a separate decision; do not force it.

   Set the application source in `configure/RELEASE.local`, preserving other settings. The environment reads `../RELEASE.local` first, then `configure/RELEASE.local`. Set the source commit with:

   ```make
   SRC_TAG:=<source_commit>
   ```

   Replace `<source_commit>` with the approved full application source commit hash. This value belongs to the application repository, not the environment repository. Verify the resolved value:

   ```bash
   make -s print-SRC_TAG
   ```

3. **Preserve the site configuration and select one installer.**

   Keep site values in `../CONFIG_SITE.local`. The file `configure/CONFIG_SITE.local` must be absent or contain only the generated OS include. Preserve and migrate any settings there before invoking an OS target: that target overwrites the file.

   Carry forward the installed DB backend, endpoint/socket, credentials, archive paths, ports, appliance identity, CA/PVA network settings, Java/Tomcat paths, and service account. Include any local changes to policies, templates, JVM settings, and systemd dependencies. Do not accept repository defaults as replacements for existing site values.

   Confirm that the resolved values identify the existing installation. In particular, a different install path can appear as a first installation and select every layer.

   For SQLite, select:

   ```bash
   db_backend=sqlite
   installer=scripts/install-local-sqlite.bash
   options=(--skip-packages --tomcat existing)
   ```

   For local MariaDB over its existing Unix socket, select:

   ```bash
   db_backend=mariadb
   installer=scripts/install-local-mariadb-uds.bash
   options=(--skip-packages --tomcat existing --existing-db --socket '<existing_socket_path>')
   ```

   Replace `<existing_socket_path>` with the installed socket. Persist the same socket in `../CONFIG_SITE.local` so direct database maintenance uses that endpoint too.

   For local MariaDB over TCP, select:

   ```bash
   db_backend=mariadb
   installer=scripts/install-local-mariadb-tcp.bash
   options=(--skip-packages --tomcat existing --existing-db)
   ```

   The TCP installer requires `DB_HOST_NAME=127.0.0.1`. A remote database does not use this local-installer procedure; use the [manual reinstall procedure](https://github.com/jeonghanlee/epicsarchiverap-env/blob/maven/docs/README.install.md#reinstall-and-upgrade) after checking the remote DB separately. `--existing-db` preserves existing MariaDB accounts; it does not disable schema loading. The application password must match the existing account.

   Optional: if using the soft IOC test, source the site's EPICS environment and check it before the maintenance window:

   ```bash
   bash scripts/verify-local-pv.bash --check-epics
   ```

   Without this environment, select `N` for the optional test and verify existing production PVs after startup.

4. **Inspect the proposed update while the appliance is running.**

   Resolve the configured service names and paths, and require them to match the installed-system inventory:

   ```bash
   appliance_unit=$(make -s print-SYSTEMD_FILENAME)
   health_timer=$(make -s print-SYSTEMD_HEALTH_TIMER)
   health_service=$(make -s print-SYSTEMD_HEALTH_SERVICE)
   install_root=$(make -s print-AA_INSTALL_LOCATION)
   service_user=$(make -s print-AA_USERID)
   ```

   Print the static command sequence, then inspect the installed state:

   ```bash
   bash "$installer" --plan "${options[@]}"
   bash "$installer" --inspect "${options[@]}"
   ```

   `--plan` executes no installation actions. `--inspect` fetches/selects source and renders checkout files, but does not change the installed appliance or stop its services.

   Require `installation present`. Check every changed layer and the build reason. Stop for an unexplained storage path, ownership, identity, port, or schema change; a retained `.payload.*` directory; or an unavailable installed source commit.

   A program change selects a build. A configuration or systemd change reuses existing target WARs, or builds them if a required WAR is missing. Schema-only and storage-only changes do not require WAR installation.

   Inspection can report `build needed` because WARs are missing even when no files need installation. That result alone does not trigger a build or reinstall. The installer builds only when file installation is required.

   Additive schema changes load new tables. Other schema differences stop; `--accept-schema` is not a column migration and must not be added merely to bypass the refusal.

   If all installable layers are unchanged, there is no installation update to apply. Continue with runtime/PV verification without stopping the appliance. An unchanged installer run does not start an appliance that was already stopped.

5. **Take the offline recovery backup before applying changed layers.**

   Use the service names confirmed in step 4. Stop the health timer and its service when both exist, then stop the appliance:

   ```bash
   sudo systemctl stop "$health_timer" "$health_service"
   sudo systemctl stop "$appliance_unit"
   systemctl show "$appliance_unit" -p ActiveState -p SubState
   ```

   If a health unit is absent, omit only that confirmed-absent unit from the first command. Require the appliance and any existing health units to be inactive, and require all four appliance JVMs to exit.

   Do not rely only on the exit status of `make sd_stop`: that target ignores its systemctl error. Verify unit states and processes explicitly. Keep MariaDB itself running when its dump tool needs it.

   Save a coherent recovery set while acquisition is stopped:

   - The entire installed appliance tree, preserving ownership, modes, symlinks, ACLs, and extended attributes.
   - The appliance/health systemd units, their drop-ins and enablement state, plus any Tomcat unit override used by the installation.
   - All original checkout/site inputs preserved in step 1, and the exact old environment/source versions.
   - A database backup using the actual configured backend.
   - A snapshot or offline copy of every STS/MTS/LTS filesystem. Record separately mounted data volumes and network storage explicitly.

   With the resolved settings matching the installed database, render its helper configuration and create the database backup:

   ```bash
   make DB_BACKEND="$db_backend" db.conf
   sudo env DB_BACKEND="$db_backend" ./scripts/mariadb_setup.bash dbBackup
   ```

   Despite its filename, this helper dispatches to both backends. SQLite uses `.backup` and validates a self-contained copy; copying only a live SQLite main file is not a backup. MariaDB produces a compressed SQL dump. Both helpers require the appliance and health units to be inactive.

   Record the exact output filename and native status. Copy the completed backup into the private recovery set, verify readability and integrity, and preserve its ownership. The DB backup contains configuration/registration data, not the archived samples in STS/MTS/LTS.

   Do not begin installation until the recovery set and its restore method are confirmed. Downtime includes this offline backup, any installer build, installation, and startup.

6. **Apply the inspected update as the checkout owner.**

   Keep the same source pin, site values, backend, and options used for inspection. Use the same interactive Bash terminal for these commands. Record terminal output in a private log while preserving the installer's terminal input:

   ```bash
   run_dir=$(mktemp -d "$repo_root/work/operator-upgrade.XXXXXXXX")
   set -o pipefail
   bash "$installer" "${options[@]}" 2>&1 | tee "$run_dir/install.log"; run_status=("${PIPESTATUS[@]}")
   printf 'Installer exit: %s; log exit: %s\n' "${run_status[0]}" "${run_status[1]}"
   ```

   Stop if the log directory cannot be created. Keep the pipeline and `run_status` assignment on the same line; another command can replace `PIPESTATUS`.

   Answer the optional PV question according to step 3. Confirm application only when the reported changed layers match step 4. Enter the sudo password when requested. Keep this run interactive; do not add `--yes` for convenience.

   On a nonzero installer result or interruption, use the recovery steps in the next section. A nonzero log result means the log is incomplete; preserve available output and resolve that failure before closing the maintenance. A logging failure alone does not establish that installation failed. Do not repeatedly rerun a partial installation without checking its last stage and retained payloads.

   If an appliance was deliberately stopped and a normal run unexpectedly reports every layer unchanged, it remains stopped. Inspect why the earlier change disappeared before deciding to start the installed service; that result is not a successful update.

## Recover an interrupted or failed update

1. **Identify the last completed stage and preserve its evidence.** A failure before the appliance stop usually leaves the old service running, except when it was stopped for the offline backup. A later failure can leave partial files or an unready running service. Record actual state instead of inferring it from the error text.
2. **Stop the appliance and health units before restoring files or the database.** Verify inactivity and absence of its JVMs. Preserve the failed payload, logs, and any post-upgrade data under the site's retention procedure; do not delete them or overwrite the only recovery copy.
3. **Restore the previous application tree, site inputs, and matching unit files from the offline recovery set.** Restore into the approved clean destination with original ownership and permissions. Do not overlay old classes onto an unexplained partial deployment. Reload systemd after restoring unit files and restore their recorded enablement state.
4. **Restore database/storage state only as required by the failure and compatibility assessment.** If schema and data did not change, do not discard current data unnecessarily. If reverting them is required, use the coherent pre-upgrade database and archive-volume recovery points. Record the sample interval that this recovery loses or preserves separately.
5. **Apply the backend's restore constraints.** SQLite restore requires the destination database and its WAL/shared-memory files to be absent after preservation. A MariaDB dump loaded over an existing database can leave extra tables; use the site's tested clean-database or snapshot restore method when exact rollback is required. Do not treat `--accept-schema` as a rollback or migration tool.
6. **Start the restored appliance and health timer using the restored service definitions.** After restoring the recorded units and confirming their names, reload systemd and start them:

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl start "$appliance_unit"
   sudo systemctl start "$health_timer"
   ```

   If the old installation has no health timer, omit its start command. Verify the old version, appliance identity, all four components, health, original site settings, historical retrieval, and current PV acquisition. Keep the incident open if any required result remains unverified.

The installer performs no automatic rollback. Rebuilding the old source is not the primary recovery method: an older source can fail the current management-interface preflight. The recorded cold payload and coherent data backups provide the recovery basis.

## Verification

Before ending the maintenance window, require all of the following:

1. If step 6 applied changes, require exit 0 and `Installation completed. All required installation checks passed.` If step 4 found every installable layer unchanged, there is no installation completion message or automatic startup verification to require. Verify the running appliance directly in either case.

   Require each service query to print `active` and exit 0. Require the health command to exit 0 with all four process identities and storage checks passing:

   ```bash
   systemctl is-active "$appliance_unit"
   systemctl is-active "$health_timer"
   sudo -u "$service_user" -- "$install_root/archappl.bash" health
   ```

   Resolve the application API addresses from the confirmed site settings:

   ```bash
   api_host=$(make -s print-ARCHAPPL_HOST_IPADDR)
   mgmt_base="http://$api_host:$(make -s print-ARCHAPPL_MGMT_PORT)/mgmt/bpl"
   engine_base="http://$api_host:$(make -s print-ARCHAPPL_ENGINE_PORT)/engine/bpl"
   etl_base="http://$api_host:$(make -s print-ARCHAPPL_ETL_PORT)/etl/bpl"
   retrieval_base="http://$api_host:$(make -s print-ARCHAPPL_RETRIEVAL_PORT)/retrieval/bpl"
   ```

   Query all four startup APIs. Require each command to exit 0 and return one JSON object whose `status` is `STARTUP_COMPLETE`:

   ```bash
   curl -q --noproxy '*' -fsS --max-time 10 "$mgmt_base/startupState"
   curl -q --noproxy '*' -fsS --max-time 10 "$engine_base/startupState"
   curl -q --noproxy '*' -fsS --max-time 10 "$etl_base/startupState"
   curl -q --noproxy '*' -fsS --max-time 10 "$retrieval_base/startupState"
   ```

   Process health alone does not establish application readiness. A failed command or a different startup state leaves verification incomplete; do not mark the maintenance successful.

2. Query the information API and require exit 0 with one JSON object containing the intended source commit in `version` and the original appliance `identity`:

   ```bash
   curl -q --noproxy '*' -fsS --max-time 10 "$mgmt_base/getApplianceInfo"
   ```

   The installed `.versions` must record the intended source. A changed-source update must show the intended version after real startup. Configuration-only verification does not establish a successful source upgrade.
3. The installed site values, DB connection, archive mounts, ownership, and storage paths match the approved inventory. Existing `config.d` overrides remain effective.
4. Existing PV registration counts and states match the baseline, allowing only the explicitly created test PV. Do not resume intentionally paused production PVs.
5. The representative changing PV acquires samples after startup. Retrieving the same historical interval used before the update returns the expected stored samples. Record timestamps and values, not only an HTTP success code.
6. If selected, the soft IOC test reports its own `PV acquisition, storage and retrieval: PASS`. Choose cleanup option `1` to stop that IOC and leave its test PV paused. An installer exit of 0 can coexist with optional PV-test failure.
7. A final inspection reports no unexplained installable-layer differences:

   ```bash
   bash "$installer" --inspect "${options[@]}"
   ```

Keep the installation log, before/after version and PV observations, final inspection, PV evidence path, backup/snapshot identifiers, and acquisition interruption times. Check the existing health monitor and logs again after a monitoring interval. Retain recovery artifacts through the agreed observation period.
