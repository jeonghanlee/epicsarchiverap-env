# Work Register

Release line: 2.0.1
Milestone index: 2.0.1
Canonical path: `docs/milestone-2.0.1.md`
Canonical branch or ref: release-2.0.1
Git upstream: origin/release-2.0.1
Remote tracker: [GitHub milestone 2.0.1 / #7](https://github.com/jeonghanlee/epicsarchiverap-env/milestone/7), observed OPEN on 2026-09-30 at 04:34 UTC via `gh api repos/jeonghanlee/epicsarchiverap-env/milestones/7`

Next session entry point: M10, M14, M43, M45, M46 and M50 are Complete; all four external gates of this milestone are Complete. M13 (management web interface rework), assigned to this milestone by D45, is Complete on 2026-10-21; its information architecture is accepted by D49 and the interface was implemented and checked in `site-template/ui` (T1 to T5 and T7 to T12 Pass); the operator documentation (`docs/README.interface.md`, the site inputs section of `docs/README.install.md`, the docs index) and the changelog entry are written (plan item 11, checked against the shipped file names and the `copy.ui` target); the transfer to epicsarchiverap-maven is in its `modernize` branch since `d0932d1b` (plan item 12), and T6 passed on 2026-10-21 on this host; D46 keeps the server code unchanged, D47 sets the plotting limits and response targets, and D48 sets the design principles. M44 (release 2.0.1) is In progress; M13, its last milestone dependency, is Complete. The published candidate is epicsarchiverap-env `48724a28e0ce7a49f3c302f814b10116652b331e`, with source pin `162269e7db97f527626ba0b387933a8c47e8bb57`; the branch has since set `SRC_TAG` to the tag `2026-10` (D66). Current-candidate local checks and four-WAR readiness checks are recorded below with their limits; source CI at the tag `2026-10` passed (Release Verification Results), and the integrated verification is closed (D70). The eight-case VM run passed with epicsarchiverap-env `bbad185` and source `84ae8a83` (recorded in Release Verification Results) and is not repeated at the final source pin (D67). The earlier source CI and Release Verification 2 Pass at `120d53fe` apply only to that historical candidate. The source of release 2.0.1 is the tag `2026-10` of epicsarchiverap-maven, commit `e0a8e66e` (D66, which ends the hold of D56). The day run of 903 PVs on this source passed and the owner accepted it (Release Verification Results). The eight-case VM run passed with env `bbad185` and source `84ae8a83`; for `e0a8e66e` the owner replaced the driver run by a clean install check that follows the install pages (D67), whose result is in `docs/reports/clean-install-20261028.md` (six clean installations and two soft IOC checks, all Pass; the owner accepted it as Release Verification 3, D68). Source CI at `e0a8e66e` passed (Release Verification Results). Release Verification 2 is closed with the limits of D70; release notes and matrix preparation follow it. The local source checkout is at the tag `2026-10` (`e0a8e66e`), the site folder holds only the site's own files (D57, `0c511ae`), and the local suite passes at that source; the page checks and a screen reader check passed at `7e9e2253` (Release Verification Results). One VM case (`debian13-sqlite`) passed on the slim site folder at `514be155`; the four MariaDB cases of the guest verifier passed at `3de600d9` (Release Verification Results), and the eight-case run is not repeated at the final source commit: the check of D67 takes its place. The accepted VM matrix remains Debian 13 and Rocky 8.10; the additional local-install OS presets do not expand it. The release merge targets the default branch `maven`, and post-release verification is one SQLite case per accepted operating system that follows the install pages (D69). Further commits, pushes, guest requests, the VM run and release objects need separate authority. The pinned Ansible and cloud-provision inventory generator remain unchanged. M41 remains Backlog under D37. M54 (policy documents) is Complete. M55 is Complete on 2026-10-20: the six stops of the main cells give the line 0.297 s + 0.00224 s per PV (the timeout of 300 s at about 134000 PVs, cautiously 108000), and the validation stop on the shipped partition took 3.74 s, outside its interval (C3 Failed); the table and the statement are in its Closure Evidence. M58 is Complete on 2026-10-21: the targets that run as root render nothing into the checkout, the rendering runs as the checkout owner (`make conf.install`, `make sql.update`), and the rendering rules remove a rendered file left by root before they write it; commit `0323fab` is on `origin/release-2.0.1`. M56 and M57 were reopened on 2026-10-21 because C3 of the validation stop of M55 is Failed; their plans were accepted and their implementation authorized on 2026-10-21; M56 is Complete on 2026-10-21 (2.368 s at 903 PVs and 8.072 s at 3000 PVs on the 15-minute partition, against 2.324 s and 7.029 s of the line of M55), and M57 is Complete on 2026-10-21 (2.932 s at 903 PVs and 9.730 s at 3000 PVs on the shipped hourly partition, against 2.324 s and 7.029 s of the line of M55). M60 (the health starting bound as a site setting) is Complete on 2026-10-24: its five checks pass (T1 to T4 on the local host, T5 on a guest with a first installation and a reinstall), its code landed in `d7cb9a2` on `origin/release-2.0.1`, and issue #62 is closed.

Evidence file names: a bare file name or run folder name given as evidence in this register (for example `m10-vm-run-e441d59-aa953a4` or a `.log` file without a directory) names a file of the private work folder of the development host. Those files are not part of the repository and are not preserved; the results, times, commits and SHA256 values written in the text are the record. Evidence given with its path under `~/stop-time-evidence/` is kept on the host and is not covered by this statement.

## Scope

The 2.0.1 patch cycle covers backend isolation safeguards, removal of obsolete Ant integration, real installation test automation, and the committed local installation entrypoints and their configuration, readiness and optional PV checks. Heap measurement and guidance are excluded under D37 and retained in Backlog. M43, M14, M10, M45 and M46 and their external gates are Complete. M44 owns final verification and publication under the release plan accepted on 2026-10-05; individual execution actions retain their separate authorization requirements. M13 reworks the management web interface and its site skin under D45; the files that epicsarchiverap-maven owns are prepared in this repository while that repository runs its other tests and are then transferred to it.

Out of scope: adding SQLite deletion, table-query, backup or restore support; changing the shipped heap default; LTS pre-processing; data migration. Existing 2.0.0 release objects remain immutable. No next release after 2.0.1 is assigned.

Baseline: epicsarchiverap-env `d68f66848e1edc174e76fe77326e941baf58f850`, published 2.0.0 tag commit `386c91d74086313efe04e0b64eb5dacfd91f8389`, epicsarchiverap-maven pin `d8a7813f40083c1bf7148e6c3b7bffd368d70ee0`. Prior release results are historical evidence and do not satisfy 2.0.1 checks. Implementation milestones are Complete at the refs recorded in their details; final combined-candidate integration is closed with stated limits (D70) and VM acceptance is accepted (D68).

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DB | M43 | Reject operations on an unselected database backend | Milestone | Complete | No | D31, D32 | SQLite db.* skips; unsupported and invalid selections stop before configuration writes or DB contact; [detail](#m43---reject-operations-on-an-unselected-database-backend) |
| Gate | G6 | epicsarchiverap-maven lands Ant removal with the per-site build contract | External gate | Complete | No | | Exact usable source commit and overlay contract confirmed; [detail](#g6---epicsarchiverap-maven-lands-ant-removal-with-the-per-site-build-contract) |
| Build | M14 | Remove Ant leftovers from epicsarchiverap-env | Milestone | Complete | No | G6, D31, D33, D43 | After Maven stabilization, four real WARs retain generated site content through the Maven-only build; [detail](#m14---remove-ant-leftovers-from-epicsarchiverap-env) |
| Tests | M10 | Automate VM installation and runtime tests | Milestone | Complete | No | M46, D31, D34, D39 | Composed provisioning/install and independent acceptance pass for all accepted OS/backend cases; [detail](#m10---automate-vm-installation-and-runtime-tests) |
| Health | M46 | Report a starting instance distinctly in the launcher health check | Milestone | Complete | No | D40, D41, D42 | A launcher-started PID that has not yet executed Java reports a starting state, not `wrong-java-executable`, and the VM verifier waits on it; [detail](#m46---report-a-starting-instance-distinctly-in-the-launcher-health-check) |
| Gate | G7 | ansible-provision reports the exact cause of the Rocky 8.10 journald gap | External gate | Complete | No | D38 | Cause established as a systemd 239 reader defect; the reproducer and scanner are shared for M45 / T1; [detail](#g7---ansible-provision-reports-the-exact-cause-of-the-rocky-810-journald-gap) |
| Gate | G8 | epicsarchiverap-maven reports the exact cause of the CAJ search-port defect | External gate | Complete | No | D38 | Socket reproducer and engine-start counts confirm or refute the shared-port mechanism; [detail](#g8---epicsarchiverap-maven-reports-the-exact-cause-of-the-caj-search-port-defect) |
| Tests | M45 | Contain the journalctl reader and CAJ search-port defects in VM acceptance | Milestone | Complete | No | G7, G8, D38, D39 | T8 exposure to hidden journal entries is measured, failures carry classifying evidence, and T8 is revised only if exposure is found; [detail](#m45---contain-the-journalctl-reader-and-caj-search-port-defects-in-vm-acceptance) |
| UI | M13 | Rework the management web interface and its site skin | Milestone | Complete | No | D45, D46, D47, D48, D49, D50, D51, D52, D53, D54, D57, D58 | The management console pages, navigation, icons and explanatory text are redesigned and checked in the real appliance at desktop and mobile widths; the files owned by epicsarchiverap-maven are transferred to it; [detail](#m13---rework-the-management-web-interface-and-its-site-skin) |
| UI | M50 | Replace the sample buffer capacity adjustment with the margin in seconds | Milestone | Complete | No | none | The environment writes `sampleBufferMarginSeconds` from `ARCHAPPL_SAMPLE_BUFFER_MARGIN_SECONDS`, the Operations remedies name it, and `SRC_TAG` pins a source that reads it; [detail](#m50---replace-the-sample-buffer-capacity-adjustment-with-the-margin-in-seconds) |
| Runtime | M48 | Review `scripts/archappl.bash`, starting with the `h` case that does nothing | Milestone | Complete | No | none | The first review found nine findings, two of them must-fix (the exit status of a start and a stop, and a start without `archappl.conf`); each accepted finding is fixed with a check that fails on the defect; all nine findings are fixed with checks; [detail](#m48---review-scriptsarchapplbash-starting-with-the-h-case-that-does-nothing) |
| UI | M51 | Remove the interface copy step now that the source carries the management interface | Milestone | Complete | No | none | The build copies no interface files, `site-template/ui` and its rule, script and variables are gone, the static checks run against the selected source, and the installers refuse a source without the interface; [detail](#m51---remove-the-interface-copy-step-now-that-the-source-carries-the-management-interface) |
| UI | M52 | Remove the stylesheet rules, images and screenshots that nothing uses | Milestone | Complete | No | M51 | The shipped site folder holds only `css/main.css`, `template_changes.html`, `img/LBNLLogo.png` and `img/als.ico`, `css/main.css` has no jQuery UI dialog rule, the old-page screenshots are gone, the VM verifier no longer compares `mgmt.css`, and the built WAR carries our files; [detail](#m52---remove-the-stylesheet-rules-images-and-screenshots-that-nothing-uses) |
| Docs | M54 | Align the documents and comments about policies, storage tiers and ETL with the code | Milestone | Complete | No | D59, D61 | Every statement of the documents, comments and test messages in scope about policies, storage tiers and ETL is listed with its code source and is a match, or is corrected, or goes to the owner of the code; the statements about when a file moves come from a run; [detail](#m54---align-the-documents-and-comments-about-policies-storage-tiers-and-etl-with-the-code) |
| Runtime | M55 | Measure the stop time of the appliance with data in the short term store | Milestone | Complete | No | G9 | The stop times of the unit for the stages of 903 and 3000 PVs on the 5-minute short term store partition, one validation stop on the shipped partition, and the slope of the stop time over the PV count show how many PVs the stop timeout (300 seconds by default) allows; [detail](#m55---measure-the-stop-time-of-the-appliance-with-data-in-the-short-term-store) |
| Gate | G9 | A guest with the disk capacity that the stop time measurement needs is available | External gate | Complete | No | none | The provider session creates a fresh Debian 13 guest of 2 vCPU, 4 GiB and 30 GiB from a complete resource request of the requester session, under its standing authorization when the capacity check passes, and hands it off; [detail](#g9---a-guest-with-the-disk-capacity-that-the-stop-time-measurement-needs-is-available) |
| Runtime | M56 | Measure the stop time over the PV count with the 15-minute short term store partition | Milestone | Complete | No | M55 | Reopened on 2026-10-21 because C3 of the validation stop of M55 is Failed: the stop scripts accept `PARTITION_15MIN` and the main cells of M55 are repeated once with it; [detail](#m56---measure-the-stop-time-over-the-pv-count-with-the-15-minute-short-term-store-partition) |
| Runtime | M57 | Measure the stop time over the PV count with the shipped short term store partition | Milestone | Complete | No | M55, M56 | Reopened on 2026-10-21 because C3 of the validation stop of M55 is Failed: the main cells of M55 are repeated once with the shipped partition `PARTITION_HOUR`; [detail](#m57---measure-the-stop-time-over-the-pv-count-with-the-shipped-short-term-store-partition) |
| Install | M58 | Keep the checkout writable for the engineer after `sudo make install` and `sudo make sql.fill` | Milestone | Complete | No | M55 | A checkout that ran the documented `sudo make install` or `sudo make sql.fill` lets the engineer run the next Make target without a permission error, or the installation guide states the step that restores the ownership; [detail](#m58---keep-the-checkout-writable-for-the-engineer-after-sudo-make-install-and-sudo-make-sqlfill) |
| Docs | M59 | Record the measured stop times in the systemd reference | Milestone | Complete | No | M55, M56, M57, D62 | `docs/technicaldocs/README.systemd.md` states the conditions and the measured stop times of the stages of 903 and 3000 PVs on the three partitions, and gives no rule; [detail](#m59---record-the-measured-stop-times-in-the-systemd-reference) |
| Docs | M53 | Write the appliance book of the repository (`book/`) | Milestone | In progress | No | D60 | The pages are written from the code, the generated pages are current, the book builds from a clean checkout, and a workflow publishes it; the pages are written, build and carry a publishing workflow; the first run of that workflow is not recorded; [detail](#m53---write-the-appliance-book-of-the-repository-book) |
| Health | M60 | Let a site set the health starting bound through the configuration files | Milestone | Complete | No | D65 | A value of `ARCHAPPL_HEALTH_STARTING_SECONDS` in `../CONFIG_SITE.local` reaches `archappl.conf` after `make conf.archapplproperties`, and the scheduled health check uses it; [detail](#m60---let-a-site-set-the-health-starting-bound-through-the-configuration-files) |
| Release | M44 | Verify and publish release 2.0.1 | Milestone | In progress | No | M43, M14, M10, M45, M46, M13, D31, D37, D39, D44, D45, D56, D66, D67, D68, D69, D70 | Released objects and required post-release checks pass; candidate `48724a2` published with source `162269e7`, `SRC_TAG` the tag `2026-10` (D66), VM acceptance that follows the install pages, recorded in `docs/reports/clean-install-20261028.md` (D67), accepted by the owner as Release Verification 3 (D68), Release Verification 2 closed with stated limits (D70); [detail](#m44---verify-and-publish-release-201) |

### Decisions

D9, D17, D21 and D29 retain historical decisions from the closed 2.0.0 generation; references within those rows use that historical scope. D31 owns current release assignment and supersedes the earlier deferral of M14 for this cycle.

| ID | Decision | Decision Date |
| --- | --- | --- |
| D9 | Boundary between the two repositories: epicsarchiverap-env owns provisioning, deployment layout, service configuration, source baseline pinning, and the site skin; epicsarchiverap-maven owns source, the Maven build (Ant and Gradle leftovers consolidated onto Maven), dependency management, upstream cherry-pick policy, and independent bug fixes. Build-flavored leftovers inside epicsarchiverap-env are epicsarchiverap-env cleanup rows gated on epicsarchiverap-maven rows; compile verification moves to epicsarchiverap-maven CI and epicsarchiverap-env keeps install tests. No epicsarchiverap-env row migrates; the legacy build items already exist on the epicsarchiverap-maven register. | 2026-09-11 |
| D17 | Align epicsarchiverap-env with epicsarchiverap-maven on Ant removal: it is deferred out of Phase 1 on both sides. epicsarchiverap-maven moved its Ant-removal row (their M10) to the backlog on 2026-09-19 (their D7). epicsarchiverap-env confirmed this first-hand at epicsarchiverap-maven modernize `3c96141d`, whose commit subject is `Move M7 and M10 to the backlog and close out Phase 1`: their register `docs/milestone-daff1b7.md` (historical peer observation; current contract must be rechecked) carries M10 as `Deferred` with an assignment-history row recording the 2026-09-19 move, and the `maven-antrun-plugin` execution `sitespecificantscript` there still drives `build.xml` target `sitespecificbuild`. G10's completion criterion therefore covers the tomcat-servlet-api pin (observed 9.0.122, not the 9.0.121 the gate first named) and the Maven CI only, and G10 closes on that basis. epicsarchiverap-env M14 (Ant leftovers) becomes Deferred and leaves M8's dependency list; G6 stays Open and blocks no row; M14 returns to Not started only by a new dated decision. | 2026-09-20 |
| D21 | The archive store's filesystem and the ETL timing become epicsarchiverap-env work (M26), scoped to the test environment first rather than to production storage architecture. Two facts drive it. On the provisioned hosts the archive store resolves to the root volume, nothing in the install path mounts a dedicated one, and `ARCHAPPL_STORAGE_TOP` only names a directory, so an archiver that fills its store fills `/` and takes the whole host; no quota or threshold exists anywhere in the chain. Separately, the shipped store configuration puts MTS at `PARTITION_MONTH` with `hold=2`, so samples do not leave MTS for roughly two months and the second ETL hop cannot be observed in any realistic test run. Production storage sizing, per-tier media selection and retention for real data stay outside this row. | 2026-09-21 |
| D29 | Limit current DB changes to rejecting `sql.drop` and `sql.table.drop` for SQLite or an invalid backend before invoking any database client. Record full backend consistency as Backlog M42, deferred from current execution; SQLite deletion support and the remaining DB command behavior require a later accepted plan. | 2026-09-28 |
| D31 | Assign the four 2.0.1 candidates: M41, M10, M14 and the backend isolation safeguard split from M42 as M43. Preserve M42 expansion, M13 and M27 as Backlog. M14 resumes as Not started after G6 completes and is Blocked until then. Plans and the proposed order remain draft; assignment authorizes documentation and issue preparation only. | 2026-09-29 |
| D32 | For SQLite, all db.* targets print a skip message and return success without prerequisites or MariaDB configuration reads/writes. Invalid backend values and unsupported SQL/query/helper operations fail before side effects. | 2026-09-29 |
| D33 | Record the site-build migration plan, procedure and real-path tests in the canonical detail and #57. Wait for Maven stabilization before implementation. epicsarchiverap-env generates and copies its site inputs before Maven runs; epicsarchiverap-maven owns template application and WAR packaging. | 2026-09-29 |
| D34 | Plan a combined cloud-provision VM lifecycle, ansible-provision installation and epicsarchiverap-env final acceptance workflow. Preserve the tool ownership boundaries and use disposable systemd VMs for installation/runtime tests. Detailed plan, test matrix and implementation authority remain separate. | 2026-09-30 |
| D35 | Limit heap measurement to the existing 100, 500 and 903 PV workloads, adding event-based post-GC heap and individual pause measurements. Preserve the reported workload and query conditions for comparison. At scope selection, the revised detailed plan remained draft and implementation was not authorized; subsequent plan acceptance is recorded in the detail. | 2026-10-01 |
| D36 | Defer M41 implementation and measurement. Preserve the accepted plan, recovered source evidence and local input-inspection tool. Resumption requires a new dated decision; release assignment and M44 dependencies remain pending a separate scope decision. | 2026-10-01 |
| D37 | Move M41 to Backlog, excluding heap measurement and new heap guidance from 2.0.1 completion requirements. Preserve its accepted plan and evidence. Reassignment requires an environment with sufficient dedicated disk capacity for the complete archive, response and measurement evidence plus shutdown reserves; existing resource stop rules remain applicable. | 2026-10-01 |
| D38 | Split the two independent Rocky 8.10 defects by owner. epicsarchiverap-maven owns the CAJ search-port defect (its #26), ansible-provision owns the systemd 239 journald unlinked-entry gap, and epicsarchiverap-env owns how both reach its VM acceptance checks (M45). Each owner proves the exact cause first, then fixes its own side. Patches stay local; publication and upstream reports are decided after the problem is resolved. A session that needs a VM requests it from cloud-provision directly. | 2026-10-04 |
| D39 | Run M10 acceptance on the latest epicsarchiverap-maven `modernize` commit that carries the current fixes and passes its CI, and keep following newly fixed commits instead of holding an older source. The next run uses `aa953a44bd2e6fb2a299224b97d365e7753a2fd8`, which carries the CAJ correction `7adc7d5a` and passed run 37249019863. The repository source pin `SRC_TAG` in `configure/RELEASE` follows the same commit, so the tested and released source stay equal. | 2026-10-04 |
| D40 | Fix the false `wrong-java-executable` at start in both places: the launcher health reports a starting state for a PID that has not yet executed Java, and the VM verifier waits on that state and on `wrong-java-executable` within its bounded readiness deadline, failing when it persists. The owner chose this for system stability and reliability over the smaller verifier-only change, accepting the larger plan and later M10 run. | 2026-10-04 |
| D41 | Write new tests in Bash and keep Python tests to the minimum that testing Python code requires, because Python versions differ across the supported systems and Python test code needs rewriting as the language changes. Converting the existing Python tests to Bash is the long-term direction and is not scheduled. | 2026-10-04 |
| D42 | Specify the launcher health starting verdict: `STARTING` exits 1, the status that FAIL uses, and is told apart by its output token; the time bound is `ARCHAPPL_HEALTH_STARTING_SECONDS` with a default of 10 seconds, which must stay below the scheduled health startup allowance of 60 seconds. The owner accepted the recommended values. The default is provisional until the VM run records the real window. | 2026-10-04 |
| D43 | Keep the Ant removal in the 2.0.1 Milestone instead of moving it to Backlog: M14 stays Blocked on G6 and M44 waits on M14. The release therefore waits for epicsarchiverap-maven to land its Ant removal with the per-site build contract; this repository then adopts the Ant-free source commit, removes its site `build.xml` and the `ANT_*` settings, and runs the full VM acceptance again. | 2026-10-05 |
| D44 | Adopt epicsarchiverap-maven `modernize` commit `120d53fe43133c7699e4c9624dc948cc96b0ece2` as the 2.0.1 candidate source pin and run preliminary local verification before its Maven CI finishes. This permits candidate preparation ahead of D39's CI condition; release readiness still requires passing source CI and new integrated and eight-case VM verification at the same pin. Preserve earlier results as evidence for their original commits. Commit, push, guest requests, the VM run and release objects remain separately authorized. | 2026-10-07 |
| D45 | Assign M13 to the 2.0.1 Milestone and widen it from the site skin to the whole management web interface: page structure and navigation, visual design, icons, explanatory text and mobile browsing, together with the site skin. This supersedes the preservation of M13 as Backlog in D31 and the premise that the interface lives only in EPICS-Arche while the appliance stays on WARs. The work is prepared in epicsarchiverap-env while epicsarchiverap-maven runs its other tests, and the files that epicsarchiverap-maven owns are then transferred to it. Release verification of 2.0.1 runs after M13 and is carried out separately. Plan acceptance and implementation authorization stay separate records. | 2026-10-09 |
| D46 | Set three M13 constraints. First, the web interface plots at most 100 PVs at once and places no other limit on the number of names that search handles or lists; the cap is set by a stepped measurement of 5, 10, 20, 50 and 100 PVs while the server load is watched, with 100 as the target, and the measured number replaces 100 if the measurement does not support it. Second, the interface needs no change to the server code for now, and server changes may be decided later in the cycle as a separate scope change. Third, the supported browsers are the current releases of Firefox, Microsoft Edge and Safari and of open-source browsers built on web standards; browsers of the Rocky Linux 8 operating hosts are not a target because those hosts run no browser GUI. The interface follows web standards and current browser security practice. The plotting cap of this decision is replaced by D47. | 2026-10-09 |
| D47 | Size the plotting limits to what a person reads on one page and tune them by measurement. Initial values: five series per chart by default and at most eight with distinct line styles, four to six chart panels on one page, about 20 to 30 PVs in detail charts in total, and up to 100 PVs in a sparkline list that scans many PVs at a glance and promotes a chosen PV to a detail chart. The values are interface configuration adjusted from the T11 measurement and from use. Search, selection, status, actions and plots stay on one page. Response targets: feedback to panning and zooming within 0.1 s, and a new time window filled within 0.5 to 1 s, with a coarser resolution shown first. This replaces the plotting cap of D46. | 2026-10-10 |
| D48 | Design the interface by the data-ink principle. Each view names the one thing it emphasizes and spends the most ink there; ink that carries no data is removed; color carries meaning only, with the accent for selection and a saturated color reserved for alarm, disconnection and anomaly; exact data points are shown on zoom and on hover; gaps are drawn as gaps and monitored samples as steps, never interpolated across missing data; many PVs are scanned as sparklines. | 2026-10-10 |
| D49 | Accept the information architecture of the management interface: one Work page that holds finding PVs, a scan list of the selected PVs, detail charts and the detail with actions and the meaning of each state; a System page that merges metrics, storage and appliances; an Integration page; and Help. The report types become quick filters of the finder, the PV details and quick chart become the Inspect and Detail areas of the Work page, and the plot is replaced by the data browser of M13. Pages are written to this architecture. | 2026-10-10 |
| D50 | Keep the list of archived PV names current in the browser by a snapshot and small updates, and never read the whole list at each visit. Archived names do not leave the list when their IOC goes down, so a change is almost always an addition. The page keeps a snapshot in IndexedDB, shows it at once with the time it is current to, checks the number of PVs every 15 s while the page is visible with `getApplianceMetrics`, merges new names from `getRecentlyAddedPVs`, and reads the whole list again when the number falls, when the snapshot is a day old, or when an addition may be incomplete. A name the snapshot lacks is looked up once on the server and kept. Above 500,000 names (confirmed by the owner 2026-10-10; T9 may propose a change) the list is not held in the browser and the server matching endpoint answers each search. No server code changes; a call that returns the names changed since a time is possible later because the metadata table keeps a modification time per PV. | 2026-10-10 |
| D51 | Amend D49: the System section is three pages. Overview for everyone: three verdict lines and a summary table that says what each number means and links to the detail. Operations for the person who looks after the appliance: samples, dropped samples, write path, stores and ETL, processes and configuration, each with the question it answers, when it is a problem and what to do. Retrieval performance for a person whose requests are slow: what the server reports and a request measured in the browser. A percentage is used only where its denominator is the quantity's own limit; the heap is judged by its floor after collection, storage by days left, disconnected PVs by host and time of loss. The thresholds are starting values, shown on the page with their basis, and the server changes that would improve them are listed outside the plan and not made (D46). | 2026-10-10 |
| D52 | Carry the PV operations of the old interface that remain useful into the new one, by conditions the server enforces. On the Work page: change of the sampling period and method (works on a running or a paused PV), the full details list, and pause, resume and stop for several selected PVs through the list form of the calls; in a folded maintenance area of the PV detail: rename, change of type and consolidation, each saying what it changes, with a backup confirmation for the type change; on Operations: pausing the PVs of a disconnected host group. Left out: the storage definition change (it can lose data), the policy text and the stores call (shown elsewhere), the cluster-wide storage report (replaced by the per-appliance report). Postponed: moving a PV to another appliance, aliases, extra meta fields and appending one PV to another. | 2026-10-10 |
| D53 | Amend plan items 5 and 7 to what was built and measured. The interface uses no icon set: text carries every label and an icon would be ink without data (D48). Series are drawn as SVG paths with the reduction the server already offers (`mean_N`), not on a canvas and not reduced again in a worker, because the measured steps stay within the bounds (T11). The data viewer is opened from the Work page for the selected PVs and for the focused PV over the window of the chart, and its CSV download is the export; the state of the rows in view is read in one call so the list shows which names are paused or not archived. | 2026-10-10 |
| D54 | Four rules found by the third review of the interface. A PV name is a base name with an optional `.FIELD`, as the server reads it, so a field PV can be archived, shown and opened in the viewer. A chart line breaks only at a connection loss the archiver recorded (`cnxlostepsecs`, `startup`, `connectionChange`), never after an elapsed time, because a monitored PV that changes rarely keeps its value. Values reduced to means are named as such on the Work page and in the viewer, the server is asked for `meanSample_N`, which leaves an interval without a sample empty (`mean_N` fills it with the previous value and drew a lost connection as a held line), and the CSV carries `interval_seconds`. An unchanged PV count is checked again for additions every fourth poll (D50 amended); a removed name stays until the count falls or the snapshot is a day old. | 2026-10-10 |
| D55 | Make the installers stop, before they change anything, when `configure/CONFIG_SITE.local` holds a line other than the include of its operating system file, and name `../CONFIG_SITE.local` as the place for site values. The target keeps writing the one line, so the file stays generated. The change is scheduled for the release after 2.0.1, which has no milestone yet; it is not part of 2.0.1. | 2026-10-11 |
| D56 | Hold release 2.0.1 until the epicsarchiverap-maven work in progress is finished, and set no source pin now. epicsarchiverap-env tests the latest commit of `origin/modernize` as development continues, which follows D39 for the time before the pin. The owner names the source commit for 2.0.1 when that work is finished, with its Maven workflow result, and the eight-case VM run is repeated at that commit. This replaces the pin plan of D44 for the time being. | 2026-10-12 |
| D57 | Keep in the site folder `site-template/siteid` only the files that carry the site's own values: `img/LBNLLogo.png`, `img/als.ico`, `classpathfiles/` and a `template_changes.html` that fills a site-logo block of the source header. The header logo, its narrow-screen wordmark, the logo sizing and the shared stylesheet come from the source repository's own files, so the site folder keeps no copy of them. The block name and the header markup are set by epicsarchiverap-maven; the change in this repository follows its landing, and the contrast check of `tests/ui-static.bash` then reads the source's stylesheet. | 2026-10-12 |
| D58 | Let the interface check accept the target of a navigation link (`<a href="https://...">`) that names an outside host, and keep refusing an outside address of a script, a style, an image or a data call. The manual link of the help page of the source repository is the first outside address in the interface files; a link is followed by the user and not requested by the page, so the appliance stays usable without internet access. A link of another form is decided when it appears. | 2026-10-13 |
| D59 | Record the findings on the storage and policy guide (`docs/README.policies.md`) that the review of `docs/README.DataJourney.md` produced as Backlog work M54, and change the guide only after the owner decides. The Data Journey document and its figures are corrected separately. | 2026-10-17 |
| D60 | Add to the book one page that adapts the verified Data Journey document: the statements stay as the document makes them, and only the form follows the book (headings, links to sections and to book pages, copied figures). This is the one exception to the owner rule of 2026-10-11 that the book is never written from a `docs/*.md` document, because every statement of that document comes from a run of the real ETL code and the document lists the runs. | 2026-10-18 |
| D61 | Align every statement of the documents, the explanatory comments and the test messages of this repository about policies, storage tiers and ETL with the code, in the scope and order of M54. History records stay as they were. A defect of the code goes to the owner of the code, and the document does not follow it. | 2026-10-18 |
| D62 | Record the measured stop times in `docs/technicaldocs/README.systemd.md` as measurements only, with no sizing rule and no recommended value: two PV counts on three partitions, most cells measured by one stop, do not suffice for a rule. | 2026-10-23 |
| D63 | Correct the sentence of `docs/technicaldocs/README.systemd.md` that sized the timeout from a test host with three PVs stopping in about 10 s, which disagrees with the measured stop times: it points to the new section instead, and the register and the document say the same. | 2026-10-23 |
| D64 | Move the Complete rows and their details that sit in the Backlog section, and the In progress row M53, to the Milestone section, because all of them are work of release 2.0.1: M48, M51, M52, M54, M55, G9, M56, M57, M58, M59 and M53. M27, M41, M42, M47 and M49 stay in the Backlog. | 2026-10-23 |
| D65 | Make `ARCHAPPL_HEALTH_STARTING_SECONDS` a configuration variable of the repository in the same way as `ARCHAPPL_STORAGE_ALARM_PERCENT`: a default in `configure/CONFIG_SITE`, a line in `site-template/archappl.conf.in` and a substitution in `configure/RULES_PROPERTIES`, so that a value in `../CONFIG_SITE.local` reaches `archappl.conf` and the scheduled health check. | 2026-10-24 |
| D66 | Set the source of release 2.0.1 to the tag `2026-10` of epicsarchiverap-maven, commit `e0a8e66e`, the state of its default branch after the merge of `modernize`. `configure/RELEASE` carries `SRC_TAG:=2026-10` (`cb5fb2f`). This ends the hold of D56 and replaces the pin plan of D44. The eight-case VM run is repeated at this commit. The owner accepted the day run of 903 PVs on this source as the install and run check of the source release (decision D11 in `docs/milestone-bfb0dc71.md` of epicsarchiverap-maven, commit `0c103015`); that acceptance does not replace Release Verification 2 or 3. | 2026-10-26 |
| D67 | Verify release 2.0.1 at the tag `2026-10` on fresh guests by following the install pages step by step, in place of the eight-case run of the shipped VM driver, and it replaces the repetition of that run that D66 names: six clean installations (Debian 13 and Rocky 8.10, each with SQLite, MariaDB over a Unix socket and MariaDB over TCP) and the optional soft IOC check on one Debian 13 and one Rocky 8.10 guest. The driver run of 2026-10-27 stopped at its own check `build_proof`, which requires a Make list without `conf.install` while the installer runs it; the review of the driver found one Must-Fix and further Minor findings, and its fixes are deferred to M61. The driver files do not change during a run that was started with them. The check is a method change for this release; D68 records the acceptance of its result. | 2026-10-27 |
| D68 | Accept the result of the check of D67 as Release Verification 3 of release 2.0.1 at the tag `2026-10` (`e0a8e66e`), recorded in `docs/reports/clean-install-20261028.md` (`c40934e`): six clean installations and two soft IOC checks, all Pass. The accepted evidence has one failure path (on Debian 13) and no installed-file comparison; the eight-case run of the VM driver had a build-failure case on each operating system and that comparison. This decision does not settle Release Verification 2 or Release Verification 6. | 2026-10-27 |
| D69 | Verify the released installation (Release Verification 6) at the immutable tag `2.0.1` the same way as D67: a fresh guest for each accepted operating system follows the install pages as written, with the SQLite installer, and the documented verification closes the check. The guest holds EPICS Base, because the soft IOC check of the installer needs it. The VM driver is not used. | 2026-10-27 |
| D70 | Close Release Verification 2 for release 2.0.1 at the tag `2026-10` (`e0a8e66e`) and the branch tip `5c51bc3`: the local suite with the real EPICS Base, the real build with the site overlay, the rejection of a site `build.xml` and the database integration test with a real MariaDB all pass. M45 / T2 and M46 / T3 need guests and the VM verifier; D67 replaces the driver run, so they are not run at this source and their earlier passes on older candidates stay as history. The owner accepts this limit. | 2026-10-28 |

### Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| 265f580 / M10 | docs/milestone-2.0.0.md, release-2.0.1 | docs/milestone-2.0.1.md, release-2.0.1 | this synchronization commit | this synchronization commit |
| 265f580 / M14 | docs/milestone-2.0.0.md, release-2.0.1 | docs/milestone-2.0.1.md, release-2.0.1 | this synchronization commit | this synchronization commit |
| 265f580 / M41 | docs/milestone-2.0.0.md, release-2.0.1 | docs/milestone-2.0.1.md, release-2.0.1 | this synchronization commit | this synchronization commit |
| 265f580 / M13 | docs/milestone-2.0.0.md, release-2.0.1 | docs/milestone-2.0.1.md, release-2.0.1 | this synchronization commit | this synchronization commit |
| 265f580 / M27 | docs/milestone-2.0.0.md, release-2.0.1 | docs/milestone-2.0.1.md, release-2.0.1 | this synchronization commit | this synchronization commit |
| 265f580 / M42 | docs/milestone-2.0.0.md, release-2.0.1 | docs/milestone-2.0.1.md, release-2.0.1 | this synchronization commit | this synchronization commit |
| 265f580 / G6 | docs/milestone-2.0.0.md, release-2.0.1 | docs/milestone-2.0.1.md, release-2.0.1 | this synchronization commit | this synchronization commit |
| 265f580 / M41 | docs/milestone-2.0.1.md, Milestone | docs/milestone-2.0.1.md, Backlog | this synchronization commit | this synchronization commit; D37, 2026-10-01 |
| 265f580 / M13 | docs/milestone-2.0.1.md, Backlog | docs/milestone-2.0.1.md, Milestone | this synchronization commit | this synchronization commit; D45, 2026-10-09 |
| 2.0.1 / M48 | docs/milestone-2.0.1.md, Backlog | docs/milestone-2.0.1.md, Milestone | this synchronization commit | this synchronization commit; D64, 2026-10-23 |
| 2.0.1 / M51 | docs/milestone-2.0.1.md, Backlog | docs/milestone-2.0.1.md, Milestone | this synchronization commit | this synchronization commit; D64, 2026-10-23 |
| 2.0.1 / M52 | docs/milestone-2.0.1.md, Backlog | docs/milestone-2.0.1.md, Milestone | this synchronization commit | this synchronization commit; D64, 2026-10-23 |
| 2.0.1 / M54 | docs/milestone-2.0.1.md, Backlog | docs/milestone-2.0.1.md, Milestone | this synchronization commit | this synchronization commit; D64, 2026-10-23 |
| 2.0.1 / M55 | docs/milestone-2.0.1.md, Backlog | docs/milestone-2.0.1.md, Milestone | this synchronization commit | this synchronization commit; D64, 2026-10-23 |
| 2.0.1 / G9 | docs/milestone-2.0.1.md, Backlog | docs/milestone-2.0.1.md, Milestone | this synchronization commit | this synchronization commit; D64, 2026-10-23 |
| 2.0.1 / M56 | docs/milestone-2.0.1.md, Backlog | docs/milestone-2.0.1.md, Milestone | this synchronization commit | this synchronization commit; D64, 2026-10-23 |
| 2.0.1 / M57 | docs/milestone-2.0.1.md, Backlog | docs/milestone-2.0.1.md, Milestone | this synchronization commit | this synchronization commit; D64, 2026-10-23 |
| 2.0.1 / M58 | docs/milestone-2.0.1.md, Backlog | docs/milestone-2.0.1.md, Milestone | this synchronization commit | this synchronization commit; D64, 2026-10-23 |
| 2.0.1 / M59 | docs/milestone-2.0.1.md, Backlog | docs/milestone-2.0.1.md, Milestone | this synchronization commit | this synchronization commit; D64, 2026-10-23 |
| 2.0.1 / M53 | docs/milestone-2.0.1.md, Backlog | docs/milestone-2.0.1.md, Milestone | this synchronization commit | this synchronization commit; D64, 2026-10-23 |

### Milestone Details

#### M43 - Reject operations on an unselected database backend

Origin: 2.0.1 / M43
Identity History: none
GitHub Issue: [#55](https://github.com/jeonghanlee/epicsarchiverap-env/issues/55)
Status: Complete

##### Summary

At the cycle baseline, `configure/RULES_SQL` guards `sql.drop` and `sql.table.drop`, but `db.*` and the four application-table query targets remain MariaDB-specific and invalid selections fall into the MariaDB schema branch. Commit `3560216c5315088a05bb2e9dea263eac075c52bf` branches before prerequisites, skips SQLite db.* targets, and rejects unsupported or invalid operations. Regression execution against the actual f5037ab rules/helper fails; the committed real paths pass the checks below.

##### Scope

- Inventory the Make DB entrypoints, configuration generation and standalone helper dispatch. Validate backend values before side effects.
- Preserve existing MariaDB behavior over TCP and Unix sockets and existing SQLite schema load/list behavior. Skip every `db.*` target for SQLite with an explanatory success result and no prerequisites; reject unsupported SQL/query/helper operations before MariaDB is contacted.
- Update operator documentation and real-path regression checks.

Out of scope: implementing new SQLite table deletion, application-table queries, lifecycle, backup or restore; schema changes; data migration. Those remain M42.

##### Completion Criteria

- All inventoried generic entrypoints validate the selector before writes or DB contact.
- SQLite `db.*` targets return zero with a skip message without reading or writing MariaDB configuration or running prerequisites.
- Unsupported SQLite SQL/query/helper operations and invalid backend values return nonzero before configuration writes or database contact.
- Supported MariaDB and SQLite behavior remains verified with the shipped rules, scripts and schemas.

##### Dependencies And Decisions

- D32 sets SQLite db.* to an explanatory skip; standalone MariaDB helpers and unsupported SQL/query operations still reject.
- D31 splits the safeguard from M42; M42 remains Deferred. Existing selection and schema support is historical 2.0.0 work, not an unfinished dependency.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-29; SQLite db.* skip, invalid selections and unsupported SQL/query/helper rejection accepted
Implementation Authorization: 2026-09-29; implement and verify the accepted backend isolation plan
Superseded Plan Artifacts: none

1. Branch `configure/RULES_SQL` before prerequisites: all eight `db.*` targets skip for SQLite; MariaDB retains its current operations. Invalid values fail for every DB/SQL/query target.
2. Validate standalone `scripts/mariadb_setup.bash` dispatch before reading configuration; reject SQLite and invalid values. Keep supported SQLite schema load/list paths and reject SQLite deletion and application-table queries.
3. Update install and test documentation and `tests/database-config.py`. Run actual Make targets and helper dispatch for skip/rejection and supported MariaDB TCP/socket and SQLite paths using the source schemas and disposable databases.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Integration | Execute every unsupported/invalid operation through shipped Make targets and standalone helpers; inspect exit status and pre/post configuration and database state | Isolated checkout and disposable DBs | SQLite db.* skips with zero; unsupported/invalid operations reject before writes or MariaDB contact |
| T2 | Database | Execute supported schema load/list and MariaDB operations through real commands with shipped source schemas | SQLite; MariaDB TCP and Unix socket | Selected database has expected results; other database remains unchanged |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-30 05:09 UTC | Isolated copies; private MariaDB 11.8.6 over TCP/socket | Pass | `tests/database-config.py`: all 8 SQLite db.* skip, 20 DB/SQL/query targets reject invalid selectors, 22 helper actions reject SQLite/invalid values before reading config. Config and MariaDB general log remain unchanged; application marker persists. Actual f5037ab comparison fails 16 skip, 80 invalid-selector and 89 helper assertions. |
| T2 | 2026-09-30 05:09 UTC | Private MariaDB 11.8.6 TCP/socket; SQLite 3.46.1 as current OS user | Pass | `python3 tests/database-config.py --integration`: 2 tests pass against epicsarchiverap-maven d8a7813f40083c1bf7148e6c3b7bffd368d70ee0 original schemas selected through `AA_TEST_SOURCE_PATH`. MariaDB account/schema/query/backup/restore and SQLite repeated load/list/missing-table restoration pass; unrelated admin accounts and MariaDB configuration are preserved. |

##### Closure Evidence

- Local verification: `EXPECTED_BRANCH=release-2.0.1 bash tests/run-all-tests.bash --local` passes Logic 224, payload 20, database configuration 10 and build wrapper 13 checks. `bash -n scripts/mariadb_setup.bash`, `shellcheck scripts/mariadb_setup.bash` and `git diff --check` pass. The build wrapper checks command generation; no appliance build or VM runtime check is claimed here.
- Pinned source schema Git blobs: MariaDB `948a38d87765b0e8e6076c76c597996c7765945d`; SQLite `bfe76e0bf87ee2faad942208886828553ad015b0`. Retrieved from the source commit above and validated against their Git blob hashes before execution.
- Implementation commit: `3560216c5315088a05bb2e9dea263eac075c52bf`, carrying the rules, helper, regression tests and operator documentation.
- Landing observed 2026-09-30 at 05:48 UTC: after `git fetch origin`, local HEAD and origin/release-2.0.1 both resolve to the implementation commit. `git diff 3560216c5315088a05bb2e9dea263eac075c52bf origin/release-2.0.1 -- configure/RULES_SQL scripts/mariadb_setup.bash tests/database-config.py docs/README.install.md tests/README.md docs/milestone-2.0.1.md` is empty.
- Issue closure observed 2026-09-30 at 05:54 UTC: #55 is CLOSED, closedAt and updatedAt `2026-09-30T05:54:00Z`. Readback confirms the implemented body, all five completed acceptance criteria and [closure comment](https://github.com/jeonghanlee/epicsarchiverap-env/issues/55#issuecomment-5905030281). No external build gate applies to this work.

##### GitHub Projection

Title: Reject operations on an unselected database backend
Labels: bug
GitHub Milestone: 2.0.1
Observed State: CLOSED
Observed Labels: bug
Observed Milestone: 2.0.1 / #7
Last Compared: 2026-09-30 at 05:54 UTC, `gh issue view 55 --repo jeonghanlee/epicsarchiverap-env`; CLOSED, bug, milestone 2.0.1, assignee jeonghanlee, updatedAt 2026-09-30T05:54:00Z

#### G6 - epicsarchiverap-maven lands Ant removal with the per-site build contract

Origin: 265f580 / G6
GitHub Issue: none
Status: Complete

##### Summary

epicsarchiverap-maven removes Ant from its build (its register row M10) and reports the
commit together with the post-Ant contract for the per-site build step that
`build.xml` target `sitespecificbuild` used to run inside
`src/sitespecific/<site>`. That step applies the site's HTML template and copies
CSS and images before WAR packaging. D33 requires Maven stabilization before
starting this conversion. This gate blocks M14 until the published source
replacement and its site-input contract are verified. It is Complete since 2026-10-05.

epicsarchiverap-maven register row: `docs/milestone-daff1b7.md` (historical peer observation; current contract must be rechecked) M10 (Ant removal, Deferred
and moved to the epicsarchiverap-maven backlog 2026-09-19, their D7).

##### Completion Criteria

- Record the stable epicsarchiverap-maven baseline and its build/test evidence before implementation, with confirmation that it is the baseline to use. No stabilization date or commit has been assigned.
- Identify a published epicsarchiverap-maven commit that replaces its Ant executions with Maven executions and documents the site-input contract.
- Verify template application, shared and mgmt assets, classpath configuration and four real WARs against that exact source commit. Retain supported default/test-site behavior.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-20 | Pending | epicsarchiverap-maven reports M10 (Ant removal) Deferred and moved to its backlog 2026-09-19 (their D7), with no landing commit. epicsarchiverap-env re-derived it at epicsarchiverap-maven modernize `3c96141d`: their register `docs/milestone-daff1b7.md` (historical peer observation; current contract must be rechecked) carries M10 as `Deferred` with an assignment-history row for the 2026-09-19 move, and the `maven-antrun-plugin` execution `sitespecificantscript` still runs `<ant antfile="${project.basedir}/build.xml" target="sitespecificbuild"/>`, so the per-site contract is still Ant-based. Recheck by reading that path and the pom at the then-current epicsarchiverap-maven `modernize` head. |
| 2026-09-30 06:20 UTC | Pending | Code inspection of local epicsarchiverap-maven `5e6c12668c9c55f71ae1ba1c3a4384d86049b806`: `pom.xml` still has `sitespecificantscript` and `create-version-txt` in `maven-antrun-plugin`. epicsarchiverap-env `site-template/siteid/build.xml` invokes the real `SyncStaticContentHeadersFooters` class with `template_changes.html` and the mgmt stage, then copies images, shared CSS and mgmt CSS. This checkout differs from the configured d8a7813f source pin; no migration build or stabilization result is claimed. |
| 2026-10-05 | Pending | The epicsarchiverap-maven session reported by cross-session message that its owner accepted the removal plan and the per-site site-input contract on 2026-10-05: site input files `img/`, `css/main.css`, `css/mgmt.css`, `template_changes.html` and `classpathfiles/`, with a leftover site `build.xml` failing the build, and the removal and that failure landing in one commit. The implementation was in progress with nothing committed or pushed, so no commit exists to adopt; the reported before and after content hashes of the four WARs for its default and tests sites differed only by the new overlay class and the embedded `pom.xml` copy. This is a peer report, not an observation of the repository; recheck with `git ls-remote` of its `modernize` branch and the commit message of the first Ant-free commit |
| 2026-10-05 16:33 PDT | Pass | The producing commit `af2e734857dab01105576086adeca0d4f318d6ee` is the head of `modernize` (`git ls-remote https://github.com/jeonghanlee/epicsarchiverap-maven refs/heads/modernize`) and its Maven run 37385424182 (job "Build and test on JDK 21") completed with conclusion success at 2026-10-05T23:33:14Z (`gh run view 37385424182 --repo jeonghanlee/epicsarchiverap-maven`). Its message states that a Java class run by Maven writes the version file, merges `template_changes.html` into the staged management pages and copies the site `img/`, `css/main.css` and `css/mgmt.css` over the staged defaults, that the antrun plugin and every `build.xml` are removed, and that a site folder holding a `build.xml` stops the build. The contract is documented in `docs/book/src/building.md` of that repository. The exact-commit verification for the ALS site is M14 / T2 and M14 / T3 |

##### Closure Evidence

- Complete on 2026-10-05: the published Ant-free commit and its green Maven run are recorded in the Verification Results, and the site-input contract was verified for the ALS site at that exact commit (M14 / T2, M14 / T3).

#### M14 - Remove Ant leftovers from epicsarchiverap-env

Origin: 265f580 / M14
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved
GitHub Issue: [#57](https://github.com/jeonghanlee/epicsarchiverap-env/issues/57)
Status: Complete

##### Summary

epicsarchiverap-env owns the site inputs under `site-template/siteid`: `template_changes.html`, CSS, images and generated classpath configuration. `configure/RULES_SRC` copies that directory into `src/sitespecific/<ARCHAPPL_SITEID>` before Maven runs. The source POM then invokes Ant, which uses `SyncStaticContentHeadersFooters` to apply the template to mgmt pages and copies site assets into the stage used by WAR packaging. Removing only the Ant file would lose those generated pages and assets. The replacement must preserve the complete input-to-WAR path. The producing repository's replacement is its commit `af2e734857dab01105576086adeca0d4f318d6ee` on `modernize` (its Maven run was still in progress on 2026-10-05); its contract keeps the site folder layout, runs the template class and the copies in one project class before the WAR packaging, and fails the build for a site folder that still holds a `build.xml`.

##### Scope

- Preserve epicsarchiverap-env's template, CSS, images and configuration generation. Preserve the copy into `src/sitespecific/<ARCHAPPL_SITEID>` before each site build.
- Remove `site-template/siteid/build.xml` after the source-owned replacement lands. Remove `ANT_HOME`, `ANT_PATH`, `ANT_CMD`, `ANT_OPTS` and the Ant entry in `PATH` from `configure/CONFIG_SITE` and `configure/CONFIG_SRC`; update Ant-specific comments and tests, including the existing `ANT_OPTS` assertion in `tests/health-local.py`. Document obsolete local overrides without modifying operator-owned `.local` files.
- Keep the configured site selection consistent between the copied directory and the Maven invocation in `configure/RULES_SRC`; preserve the current default ALS site. Inventory all build variants before editing.
- Verify `configure/os/*.pkgs` remains free of an Ant requirement. Update operator and test documentation for the Maven site-input contract.
- Update `configure/RELEASE` to the published, verified source commit after the replacement passes. Coordinate the epicsarchiverap-maven prerequisite through G6.

Out of scope for this repository: implementing epicsarchiverap-maven's POM or Java changes; those are the producing repository's prerequisite described below. Also excluded: UI redesign, changing the template text or branding, appliance runtime changes, installation/VM automation and unrelated dependency upgrades.

##### Completion Criteria

- No Ant configuration, command dependency or site build file remains in epicsarchiverap-env, checked by a Bash test of the tracked tree that fails on the current tracked files.
- With the source pin at the first Ant-free commit whose Maven run finished green, the shipped build targets produce four WARs for the ALS site whose file contents equal those of the Ant-backed baseline built from the current pin, except the differences the producing repository reports: its new overlay class and the embedded POM copy.
- A site folder that still holds a `build.xml` fails the shipped build with the producing repository's message.
- The operator documentation describes the site-input contract, and the local suite passes without skips.
- Two SQLite cases of the shipped VM driver pass on fresh Debian 13 and Rocky 8.10 guests at the new pin.

##### Dependencies And Decisions

- D43, Decision Date: 2026-10-05. M14 stays in the 2.0.1 Milestone and is released only after G6 completes; the Ant removal is not moved to Backlog.

- D33, Decision Date: 2026-09-29. Plan and issue update only. Implementation waits for Maven stabilization and subsequent plan acceptance and authorization; no source pin or build file is changed now.
- D31, Decision Date: 2026-09-29. Assigned to 2.0.1; detailed plan remains draft. Earlier assignment decisions below retain their original dates.

- Decision Date: 2026-09-29. Transferred from Milestone to Backlog for the 2.0.0 cycle close. Existing status, scope, dependencies, plan and verification evidence are preserved; no next release is assigned.
- G6 covers Maven stabilization, the published Ant replacement and its verified site-input contract; it is Complete since 2026-10-05, the implementation authority is recorded in the Implementation Plan, and this work is Complete.
- D9
- D17. 2026-09-20: Ant removal is deferred out of Phase 1 on both sides, so this
  row previously moved to Deferred and left [M8 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md)'s dependency list. epicsarchiverap-maven moved its M10
  to the backlog 2026-09-19; this row returns to Not started only by a new dated
  decision.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-05; owner accepted the simplified plan, including the site id fix in every Maven call of `configure/RULES_SRC`
Implementation Authorization: 2026-10-05; owner authorized implementation of this accepted plan and its local verification, with the code change starting only after the producing commit's Maven run finished green; commit, push, publication, any VM run and every guest request need separate authority
Superseded Plan Artifacts: original draft at epicsarchiverap-env d68f66848e1edc174e76fe77326e941baf58f850, docs/milestone-265f580.md, M14; remove-or-replace draft carried by dcfa39b3f1a6a457ffd6803cb6c618d601768c30, docs/milestone-2.0.1.md, M14; six-check draft with a producing-repository step and site-switch and generator checks carried by 686ea2d79dcad71948eed6195d395fea07ba2b35, docs/milestone-2.0.1.md, M14

1. Before the change, build the Ant-backed baseline from the current source pin with the shipped build targets in an isolated copy of this repository and the ALS site, and record the content hash of every file in the four WARs. This needs no code change.
2. Wait for the Maven run of the producing commit to finish green; record the commit, the run and the contract text as landing evidence. The producing repository owns its generic behavior (other sites, generator errors) and its own tests for it.
3. In one change: move `SRC_TAG` in `configure/RELEASE` to that commit; delete `site-template/siteid/build.xml`; remove `ANT_HOME`, `ANT_PATH`, `ANT_CMD`, `ANT_OPTS` and the Ant entry in `PATH` from `configure/CONFIG_SITE` and `configure/CONFIG_SRC`; remove the Ant comments in `configure/RULES_SRC` and `configure/RULES_INSTALL` and the Ant sentence in `README.md`; pass `$(ARCHAPPL_SITEID)` instead of the literal `als` to the Maven call of every build and clean target in `configure/RULES_SRC` (the `clean.mvn` target currently uses another variable name), so that a site folder with another site id is built when the operator sets that id, with `als` staying the default; replace the `ANT_OPTS` assertion in `tests/health-local.py` and add a Bash test `tests/no-ant.bash`, called from `tests/phase1-logic.bash`, that fails when a tracked Ant setting or site build file exists (D41); document the site-input contract and the failure for a leftover `build.xml` in the operator documentation, without modifying operator-owned `.local` files.
4. Run the local suite, build the four WARs again through the shipped targets, compare every file with the baseline, and put a `build.xml` back into a disposable copy of the site folder to confirm that the shipped build fails.
5. Record each result and both commits. Publication, the issue body, the closure of #57 and the Complete status follow under their own authority. By owner direction on 2026-10-05, a two-case SQLite installation check of the new pin on one Debian 13 and one Rocky 8.10 guest is added as T4; the full eight-case matrix runs once, as Release Verification 3 of the release milestone.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local regression | The real local suite with the new Bash test `tests/no-ant.bash` over the tracked tree, which also prints the Maven call of each build target with `make -n` for the default id and for another id | Isolated epicsarchiverap-env checkout | The suite passes without skips; `tests/no-ant.bash` fails on the current tracked files and passes after the change; every Maven call carries the configured site id |
| T2 | Baseline and WAR comparison | Shipped build targets for the ALS site, once at the current pin (baseline) and once at the Ant-free pin; compare the content hash of every file in the four WARs | JDK 21, source Maven Wrapper, isolated trees and install paths | Equal except the overlay class and the embedded POM copy of the producing repository; shared images, both stylesheets, the merged management pages, the classpath files and `ui/comm/version.txt` are equal |
| T3 | Failure | Put a `build.xml` back into the site folder of a disposable copy and run the shipped build target | Disposable trees | The build exits nonzero with the producing repository's message about the site `build.xml` |
| T4 | System | Two cases of the shipped VM driver at the new pin: `debian13-sqlite` and `rocky8-sqlite`, each on a fresh guest from cloud-provision | Fresh Debian 13 and Rocky 8.10 guests, published environment candidate, source at the Ant-free commit | Installation and runtime checks T3 to T13 of the VM acceptance pass in both cases; the check is not a matrix acceptance |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-05 16:38 PDT | Local Debian 13 host; the shipped `tests/no-ant.bash` inside the real local suite | Pass | The new test passes 22 checks on the changed tree: no site `build.xml`, no `ANT_HOME`, `ANT_PATH`, `ANT_CMD` or `ANT_OPTS` setting in `configure/`, no Ant claim in the README, and for each of `build.mvn`, `build.mvn2`, `build.mvn3`, `build.war`, `build.mvndeps` and `clean.mvn` the dry-run Maven call passes `ARCHAPPL_SITEID=als` by default and the configured id `othersite` and never `als` when overridden. The original tracked tree and five broken variants (site `build.xml` restored, `ANT_OPTS` restored, one target naming `als` again, the clean target on its old variable name, an Ant claim in the README) each fail their targeted check. The full `--local` suite exits 0 without skips: Phase 1 223/0, health 20, new health 32/0, no-Ant 22/0, database 10, VM local 36 tests, Phase 2 13/0. Verified source SHA256: `tests/no-ant.bash` `273b45c4d8412f2d0df1c0d52968a632ab1262a6018b63f101ad4dba9ea14f17`. Evidence: `m14-local-20261005T233817Z.log`, SHA256 `55bd1d340b2eb2f3f3efedfe0d6d5f55124aaeacddc764ef838a82f6b44399bb`; `m14-no-ant-mutation-20261005T233445Z.log`, SHA256 `289b9ac75f12074e19d688c91ce7043ac241d00bc520e2d670eda50aed276d21` |
| T2 | 2026-10-05 16:17-16:37 PDT | Isolated copies of this repository on the local Debian 13 host, JDK 21, SQLite, site `als`, shipped targets `make init`, `make conf.archapplproperties` and `make build.mvn` | Pass | Three builds. The Ant-backed parent `c61d94404c486f6d04a85d2db91f39ff36d80f63` (both `antrun` executions ran, BUILD SUCCESS in 25 s) produced the four WARs with 3,523 file entries, and the Ant-free `af2e734857dab01105576086adeca0d4f318d6ee` (no `antrun`, one `exec` execution `site-overlay`, BUILD SUCCESS in 24 s) produced 3,527 entries. The comparison of every entry of the four WARs shows only four added entries (`SiteOverlay.class` in each WAR) and four changed entries (the embedded `pom.xml` copy in each WAR); nothing is removed, all 261 `ui/` entries across the four WARs are equal, the generated classpath files are equal, and `ui/comm/version.txt` is equal in all four WARs. Against the earlier pin `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` (3,535 entries) the differences are the eleven source commits between the pins (the Redis persistence class and the jars `jedis`, `commons-pool2`, `gson` and `json` are gone and some classes changed), not the site step. Evidence: `m14-baseline-wars.manifest` SHA256 `a765d5c6088691d96128557cee3855443a0677a2f9c44d95d4f5a071f8fb0cdb`, `m14-parent-wars.manifest` SHA256 `fa6683da31f93469d2b70b38c48271c0b2058cd3f4534f4ea7b36c256d35f66b`, `m14-new-wars.manifest` SHA256 `fca620be9f5ac3ed5d0ab85ebbbe972e3b3dcdc03df728fc8332451940f6f39c` (service, entry, size and SHA256 of every file); build logs `m14-baseline-build.log` SHA256 `ad2d9a8499633926b2c8f223941fcec1b41d0bc7b9db6a6cd0e475e6497ee1d5`, `m14-parent-build.log` SHA256 `bba1739c2d9a952590f4dcee334bf425de39250f5015c9082b6fd2ce90cb835f`, `m14-new-build.log` SHA256 `704095ca0c454016dce039cb306afc965642a0fc1aee278fcc377963a63019ac` |
| T3 | 2026-10-05 16:39 PDT | Disposable copy of the changed tree, shipped `make build.mvn` | Pass | With the original `build.xml` placed back into the site folder, the build exits 2 and Maven reports `A site build.xml is no longer run. Remove <site folder>/build.xml and use img/, css/ and template_changes.html as described in the Building chapter.` from the `site-overlay` execution; after the file is removed the same target finishes with BUILD SUCCESS. Evidence: `m14-leftover-build.log` SHA256 `4bbe4911391c577c4116124637ffc447b441ea116c4315a81a1b04c8706d58f2`; `m14-after-restore-build.log` SHA256 `4d8bdb6cc532e397f3fcdee1662606981308a07e52eef15fcff88d14afb6efe4` |
| T4 | 2026-10-05 17:12-17:48 PDT | Run `m10-vm-run-0e5f149-af2e734b` on published environment `0e5f1499363051468182e2c8a3115fe81791eaa7` (the commit of the change), source `af2e734857dab01105576086adeca0d4f318d6ee`, pinned Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5` and cloud-provision inventory generator `a29f4773c14274b447cb66f4b9ab11f4cc1f8583`; fresh guests created by cloud-provision at its commit `974d848e05266b7f69bce5ae04aa566e68a37c7a`, on fallback node labels `test-0e5f149000000011` and `test-0e5f149000000012` because the requested labels' addresses still held leases of just-removed guests | Pass for the installation and runtime checks; the cleanup verification did not pass | Both cases passed T3 to T13 (`debian13-sqlite` 17:12-17:31, `rocky8-sqlite` 17:31-17:48): installation with the Maven build at the Ant-free source, JVM identities, scheduled health, CA acquisition and retrieval, restart, repeat apply, forced reinstall and the negative checks. cloud-provision removed both guests, and none of this run's domains, image files, DHCP reservations or stored host keys remains (checked in libvirt, the image directory, the `lab` network XML and `known_hosts`). The driver's `--verify-cleanup` returned FAIL (`A baseline domain identity was not preserved`) and `--verdict` returned FAIL, because four baseline domains of another session's ETL soak guests were removed and three were added while the run was open; none of them belongs to this run. The check therefore does not establish the run's acceptance, which was not its purpose. An earlier attempt on run `m10-vm-run-0e5f149-af2e734` was refused before any change because its guests had been requested while its initialization was running and entered its baseline; those two unused guests were removed. Evidence: `0e5f149-run-verify-cleanup-20261006T005048Z.log`, SHA256 `3a0b5805d1bf5b277278855ff82d7035953f57afb7ec0793959e3544317f5865`; `0e5f149-run-verdict-20261006T005048Z.log`, SHA256 `4f8e9e45f8a9e1843b81eaf3bdf52a6b778d415d23bf985774a9d34a43f69bd5`; per-case results in `run.json` of the run context |

##### Closure Evidence

- Complete on 2026-10-06: the Ant removal landed in `4800b4aeb8445b0fcd6c4975f522c00fbb69b74e` on `origin/release-2.0.1`; M14 T1 to T4 passed; and #57 was closed as completed on 2026-10-06 at 00:53 UTC (`gh issue view 57 --repo jeonghanlee/epicsarchiverap-env` returned CLOSED, closedAt 2026-10-06T00:53:30Z).

##### GitHub Projection

Title: Remove Ant leftovers from the environment configuration
Labels: enhancement
GitHub Milestone: 2.0.1
Observed State: CLOSED
Observed Labels: enhancement
Observed Milestone: 2.0.1 / #7
Last Compared: 2026-10-06 at 00:54 UTC, `gh issue view 57 --repo jeonghanlee/epicsarchiverap-env`; CLOSED at 2026-10-06T00:53:30Z, enhancement, milestone 2.0.1, assignee jeonghanlee; the live title is unchanged, the live body equals the final draft with the five Acceptance Criteria boxes checked, and the closing comment records the result.

#### M10 - Automate VM installation and runtime tests

Origin: 265f580 / M10
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved
GitHub Issue: [#56](https://github.com/jeonghanlee/epicsarchiverap-env/issues/56)
Status: Complete

##### Summary

Compose the existing cloud-provision VM lifecycle and ansible-provision installation with independent acceptance checks owned by epicsarchiverap-env. The actual path is fresh VM -> SSH/cloud-init readiness -> generated Ansible inventory -> prerequisite provisioning -> real Make/Maven build and installation -> installed payload and runtime verification -> retained evidence -> explicit VM cleanup.

The Phase 3 and Phase 4 entrypoints call the VM driver; the full accepted matrix passed on 2026-10-05 (subsection "VM Acceptance Run On e441d59"). The earlier systemd-free container premise is incompatible with the shipped `make install`: `sd_health_stop`, `sd_install` and `sd_enable` invoke real `systemctl`. Both installation and runtime verification therefore use the same disposable systemd VM. No second VM provisioner or installation implementation is needed here. The test design is in [`docs/README.vmtests.md`](README.vmtests.md).

##### Scope

- Implement a driver under `tests/vm/` that calls pinned, separately maintained cloud-provision and ansible-provision checkouts. Each tool retains ownership of its own implementation.
- Use Phase 3 for fresh VM readiness, prerequisite provisioning, actual installation and installed-payload verification. Use Phase 4 for process identity, scheduled health, HTTP identity, real CA acquisition/retrieval, persistence and repeat-install verification on that same VM.
- Add independent VM acceptance checks and structured results in this repository. Ansible success, a build sentinel, an active unit or HTTP 200 alone cannot satisfy acceptance.
- Adapt `tests/run-all-tests.bash`, phase dispatch, `tests/database-config.py` and `tests/README.md` to the VM-based phase contract. Preserve the existing `tests/phase3-docker.bash` path as a compatibility entrypoint for Phase 3; document its VM prerequisites. No Docker daemon or systemd substitute is required.
- Keep local checks independent of virtualization. System execution requires explicit external-checkout paths and published candidate refs; the local default must never provision a VM.

Out of scope: implementing VM images or cloud-init internals, duplicating Ansible roles, independently maintaining guest install commands, a Docker test environment, CI wiring, production deployment, load/heap soak, ETL retention-capacity validation, UI or Ant migration, and new database features.

##### Completion Criteria

- The full accepted matrix runs through the real three-repository path, with exact refs and the OS/backend/transport recorded. Every required assertion and case passes; a missing prerequisite, skipped assertion or unimplemented phase cannot yield overall success. A single-case run cannot establish full-matrix completion.
- Installed payload/configuration matches the actual WARs, logging JARs and generated inputs. Actual guest checkout commits match the requested epicsarchiverap-env and epicsarchiverap-maven commits.
- Four genuine appliance JVM identities, installed units and three eligible scheduled health successes are observed. Application readiness and identity are checked separately from process presence.
- The real IOC fixture archives and retrieves changing, timestamped values; PV configuration and historical samples survive an appliance restart. A repeat Ansible apply and explicit same-candidate reinstall preserve the configuration database and archive data.
- Wrong PID identity, loss of IOC updates and a real failed source checkout are detected without replacing any install/build/systemd/application span with mocks.
- Results, timing, relevant payload hashes and sanitized diagnostic excerpts are retained. Full-matrix acceptance remains INCOMPLETE until explicit cleanup independently confirms removal of this run's domains, disks, seed ISOs, `.creation-record` files and DHCP reservations, and the final verdict validates the retained test and cleanup evidence. Every resource present before the run, including DHCP reservations, is preserved; retained resources created by an earlier case in this same run remain owned cleanup targets.
- The public issue reflects the implemented scope and observed evidence and its authorized closure is observed. No closure or migration verification is claimed by this plan.

##### Dependencies And Decisions

- D34, Decision Date: 2026-09-30. Accept the combined cloud-provision -> ansible-provision -> epicsarchiverap-env workflow, six-case matrix and T1-T15 plan. VM lifecycle stays in cloud-provision; prerequisite provisioning and Make installation stay in ansible-provision; this repository owns orchestration and final verification. This direction replaces the container-install premise; implementation authorization remains separate.
- D31, Decision Date: 2026-09-29. Assigned to 2.0.1. Assignment authorizes planning, not implementation.
- The six-case matrix and proposed deadlines are accepted with this plan. Exact external tool revisions, published candidate commits and images remain execution inputs to be selected and verified through the planned preflight before guest creation. A dirty local checkout or branch name is not a candidate identity for an Ansible clone.
- M14 is not a behavioral prerequisite for this automation: the existing build can be tested at its verified source pin. A later Ant replacement or source-pin change requires a new integrated run on the combined candidate; existing release-wide verification retains ownership of that final run.
- Decision Date: 2026-09-29. Transferred from Milestone to Backlog for the 2.0.0 cycle close; reassigned under D31.
- Decision Date: 2026-09-22. Earlier assignment left the test host and implementation plan undefined; that historical assignment did not authorize implementation.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-04; owner accepted the VM supply and run structure revision carried by fdbf1eccc6aa0c68553ecb17b9f68d3ece8a3d29, with its design draft kept outside the repository, after four third-person and five second-person passes with all findings applied; the prior plan is re-accepted with the replacements the revision names
Implementation Authorization: 2026-10-04; owner authorized implementation of the accepted revision and its local verification; commit, push, publication, the VM run and every cleanup request require separate authority
Superseded Plan Artifacts: original draft at epicsarchiverap-env d68f66848e1edc174e76fe77326e941baf58f850, docs/milestone-265f580.md, M10; container-install draft carried by dcfa39b3f1a6a457ffd6803cb6c618d601768c30, docs/milestone-2.0.1.md, M10; prior accepted plan state, including the still-current service-inventory revision, accepted and authorized on 2026-10-01 and carried by e799b094b0c20a89664a2fae4901e07954a74a9c, docs/milestone-2.0.1.md, M10; prior accepted plan state, including the still-current Rocky 8.10 compatibility revision, accepted and authorized on 2026-10-02 and carried by f58c3da517d45cd580c8aab82471439ff65b40ab, docs/milestone-2.0.1.md, M10; address selection draft, not accepted, carried by 4a97ae408403ba8c76d6fbc84a6e4794c977a146, docs/milestone-2.0.1.md, M10

###### VM Supply And Run Structure Revision For Review

Dates in this revision are Pacific local dates. The diagnostics and runs recorded below expose five design defects. Apart from the first case of the interrupted full run, every passing VM case at `65cf077b1230f61efdba817aa697483a79a3a5d5` came from guests that cloud-provision created, checked through a private harness that binds the driver's methods to an external guest; the shipped driver can only verify guests it creates itself. Driver-created guests collide with occupied addresses (31 of 95 hashed addresses held by a reservation or lease on 2026-10-03 at 21:30 PDT, recorded in the address selection draft carried by `4a97ae408403ba8c76d6fbc84a6e4794c977a146`) and with stale stored host keys. One driver process runs all eight cases for hours, so an interruption fails the whole run and its completed cases cannot count toward acceptance; the first full run at that candidate failed this way. The tool origin check reads `git remote get-url`, which a common `insteadOf` rule rewrites to SSH form. The design is split between this growing register and `tests/README.md`. Owner direction, Decision Date: 2026-10-03: cloud-provision creates every guest and the driver adopts it from a handoff; each case runs as a separate invocation that appends to one run context; the origin check reads the stored URL; and the design is consolidated into one document. This revision supersedes the unaccepted address selection draft. T5-T14 checks, the fixture, the deadlines and the guest verifier are unchanged. Accepting this revision re-accepts the prior plan with these items and the replacement rows below. It also replaces Implementation Plan items 2, 3 and 9 where they create, shut down or clean up guests through the driver, and the `--system` and `--cleanup` statements of the Phase And Result Contract. In the T15 Assertion Details, "leaving the first case's shut-down VM and DHCP reservation present when the second begins" becomes "leaving the first case's VM and DHCP reservation owned and present, running or shut off, when the second begins". The rest of the plan is unchanged.

1. In `tests/vm/driver.py`, replace `--system`, `--installation`, `--runtime` and `--cleanup` with four operations: `--init --config <file> --evidence <new-dir>`, `--case <case> --handoff <file> <run>`, `--verify-cleanup <run>` and the unchanged read-only `--verdict <run>`. Remove every `create_vm.bash` call (`-F`, `-s`, `-S`, `-c`) from the driver and keep the cloud-provision inventory generator. `--init` keeps the existing preflight, candidate local-suite proof and baseline of domains and live and persistent reservations.
2. Define the guest handoff as a JSON file with `schema`, `os_selector`, `prefix`, `node`, `creation_id`, `uuid`, `vm_name`, `mac`, `address`, `disk`, `seed`, `record` and `tool_ref`. The operator writes it from cloud-provision's private markdown handoff, whose lines carry every field; a JSON handoff emitted by cloud-provision itself is a separate peer request. `--case` derives the VM, disk, seed and record names from the selectors and requires equality with the handoff; requires the UUID to be absent from the baseline and from earlier cases; matches the live domain, single interface, attached disk and seed, creation record, both reservations and the lease; collects shell-only facts; and requires a fresh guest through one `sudo -n sh -c` probe: cloud-init done without errors, none of the configured source, install and store roots or `/usr/local/sbin/archiver-build.sh` and `/var/tmp/archiver-build.done` present, a successful service unit-file listing and no unit name starting with `epicsarchiverap`, `archiver-build`, `mariadb` or `mysql`. It then runs the existing installation, build proof, transfer and guest verifier sequence, or the build-failure path, and stops its own helpers. It records whether earlier cases' guests remain owned and present when it starts. Each invocation locks the run; a recorded case failure is permanent and a case name cannot be run twice. Case order does not matter; the verdict requires each `MATRIX` case exactly once instead of the current exact-order comparison. By owner direction, Decision Date: 2026-10-04, `--case` copies the host key that cloud-provision stored for the guest address in `~/.ssh/known_hosts` into a per-guest known-hosts file before the first guest connection, refuses the handoff when no key is stored, and runs SSH and Ansible with strict host key checking against that file, as ansible-provision does for its guests.
3. Keep the interruption and cleanup-refusal checks on the first positive case. The refusal checks invoke `--verify-cleanup` on missing and mismatched ownership contexts and require refusal with unchanged state. `--verify-cleanup` keeps the existing removal and baseline-preservation inspection; the cleanup itself is a separate request to cloud-provision. By owner direction, Decision Date: 2026-10-04, an inspection error during `--verify-cleanup` returns 77 without recording a failure, so the verification can run again.
4. Read each tool checkout's stored `remote.origin.url` and require HTTPS without credentials; keep the published-commit proof through the HTTPS clone.
5. In `tests/run-all-tests.bash`, forward `--init`, `--case`, `--verify-cleanup` and `--verdict` to the driver. `--system`, `--phase=3`, `--phase=4` and `all` perform no VM operation and no local phase, name the four operations and exit 77; by owner direction, Decision Date: 2026-10-04, they do not run the local phases, because the local suite's `database-config.py` contract test invokes `--system` and must observe an immediate 77 without a pass. `tests/phase3-docker.bash` and `tests/phase4-vm.bash` keep exit 77 without arguments and forward arguments to `--case`. Local modes stay unchanged and contact no VM; update the existing entry point regressions to this behavior. Add `tests/vm/local.py` regressions for each operation's input refusals, handoff validation with real files, the origin check with real `git` under an isolated global configuration that contains an `insteadOf` rule, refusal to rerun or replace a case, and read-only verdict rules.
6. Add the design document `docs/README.vmtests.md`; its draft, kept outside the repository, is reviewed with this revision and moved and committed with the implementation so that it matches the code. Reduce `tests/README.md` to execution and evidence procedures that link to it, and link this detail to it.
7. Run the full `tests/run-all-tests.bash --local` without skips. After separately authorized publication, run `--init`, the eight cases on cloud-provision guests one at a time, cloud-provision cleanup on request, `--verify-cleanup` and `--verdict` on one run context. Existing run contexts stay bound to their driver digests and are not resumed. Their owned resources and the diagnostic guests are removed by cloud-provision on a separate request and inspected with the driver commit that created each context, or by a recorded manual inspection for guests outside any context; none of them enters a run of the revised driver.

###### VM Supply And Run Structure Test Plan

These rows replace the T1, T3 and T15 methods of the Test Plan, and the Fresh VM and Explicit cleanup rows of Repository Responsibilities, once accepted.

| Check | Real Path And Environment | Expected Result |
| --- | --- | --- |
| T1 | `--init`, eight `--case` invocations, cloud-provision cleanup on request, `--verify-cleanup` and `--verdict` on one run context | Before verified cleanup: 77; after it: 0 only with every required check, lifecycle check and cleanup postcondition; recorded failures remain failures |
| T2 / operations | Shipped CLI with missing, invalid and conflicting inputs; real files in isolated directories; no VM | Refusal with 2 or 77 before any external action; no context created or changed |
| T2 / handoff | Shipped validation with real handoff files | Missing fields, derived-name mismatches and baseline UUIDs are refused |
| T2 / origin | Real `git` with an isolated global `insteadOf` rule and stored HTTPS origins | Stored HTTPS origins pass; SSH or credential-bearing stored origins are refused |
| T2 / run rules | Shipped context handling and verdict on constructed contexts | A second invocation of a recorded case is refused; verdict stays read-only |
| T3 | Handed-off fresh guest from cloud-provision | Handoff, live identity, baseline exclusion, facts and freshness match; Ansible limited to that guest |
| T15 | Guests retained across cases; cleanup by cloud-provision on request; `--verify-cleanup` | Earlier guests stay owned when later cases start; every owned resource absent and every baseline entry preserved; refusal checks leave state unchanged |

| Step | Owner | Input | Required Output And Next Condition |
| --- | --- | --- | --- |
| 2. Fresh VM | cloud-provision | Request with OS selector and resources | Fresh guest and its handoff; no address collision or stale host key |
| 8. Explicit cleanup | cloud-provision on request; verified by epicsarchiverap-env | Owned resource list from the run context | Removal by cloud-provision; independent removal and preservation proof by `--verify-cleanup` |

###### Rocky 8.10 Compatibility Revision For Review

Dates in this revision and its diagnostics are Pacific local dates; clock times are PDT (UTC-7). Two shipped harness defects stop every fresh Rocky 8.10 case at published environment `607092b962afd9cbac31ce9f62efba0e7c62b471`, including the build-failure case, because the facts command runs before installation; evidence is in the Rocky 8.10 socket diagnostic below. The fresh base image provides no `python3`, so the driver's pre-installation facts command exits 127; the interpreter available before installation, `/usr/libexec/platform-python`, is Python 3.6.8 and rejects the command's `text=` argument. The verifier passes `journalctl --since` an ISO 8601 timestamp with an offset, which systemd 239 rejects. On 2026-10-02 at 18:17 PDT, read-only queries accepted `@<epoch seconds>` and `YYYY-MM-DD HH:MM:SS UTC` on both the Rocky 8.10 guest (systemd 239) and a Debian 13 guest (systemd 257). Owner direction, Decision Date: 2026-10-02: replace the Python facts command with shell-only collection, and convert the journal bound to whole epoch seconds with the IEEE 754 `roundToIntegralTowardPositive` operation. T10-T13 have not yet run on Rocky 8.10; a further incompatibility found there requires its own revision. Accepting this revision re-accepts the unchanged prior plan with these four items added; nothing else in the plan changes.

1. In `tests/vm/driver.py`, replace the pre-installation Python facts command with one shell command that prints delimited sections from `/etc/os-release`, `getconf _NPROCESSORS_ONLN`, `hostname`, `ip -j address`, `/proc/meminfo` and `stat -f -c '%S %b %a' /` (fundamental block size, total data blocks, free blocks available to non-superuser). `getconf _NPROCESSORS_ONLN` reports the same online-processor count as the current `os.cpu_count()`, whereas `nproc` follows CPU affinity and `OMP_NUM_THREADS`. Parse the sections on the host into the existing `guest_resources` fields, with root bytes as `%S × %b` and free bytes as `%S × %a`. Keep the hostname, interface, OS release, CPU and free-space checks unchanged, and reject a missing or malformed section. Factor the command and parser into module functions so the local regression executes the shipped text.
2. In `tests/vm/guest.py`, derive the scheduled-health journal bound as `@` followed by the current epoch time in whole seconds, converted with the IEEE 754 `roundToIntegralTowardPositive` operation (ceiling). Compute it from integer nanoseconds from `time.time_ns()` rather than the binary64 `time.time()` value, so the conversion is exact. The bound is therefore at or after the original instant, and no earlier journal entry can count; the eligibility rules and the timer interval are unchanged. Factor the conversion into a module function.
3. In `tests/vm/local.py`, run the shipped facts command through the real local shell with a `PATH` containing only the real tools it names and no Python interpreter; parse the real output and compare CPU count, hostname and root size with the local system. The earlier command, which resolves `python3` through `PATH`, fails this test; before replacing the command, run the new test against the earlier command and record its failure. Remove one section from the real output and confirm that the shipped parser rejects it. Run the shipped journal-bound function against the real local `journalctl` and check the conversion at whole and fractional seconds. Local systemd accepts the earlier ISO form, so this test cannot reproduce the systemd 239 rejection; only a real Rocky 8.10 run verifies the journal-bound correction.
4. Run the full `tests/run-all-tests.bash --local` without skips. Review this revision before code changes; commit, push and publication require separate authority. The published correction is a new candidate: no earlier diagnostic verifies it, and the re-verification scope across Debian, Rocky and the full driver remains an owner decision before execution.

###### Rocky 8.10 Compatibility Test Plan

| Check | Real Path And Environment | Expected Result |
| --- | --- | --- |
| T2 / shell facts | Shipped facts command and parser; real local shell and tools; `PATH` without any Python interpreter | Exit 0; parsed CPU count, hostname and root size equal the local observations; a missing section is rejected |
| T2 / journal bound | Shipped conversion; real local `journalctl --since` | Whole seconds stay unchanged, any fractional second converts toward positive and the real command exits 0; systemd 239 behavior is not claimed |
| T3 / Rocky 8.10 | New published candidate; fresh Rocky 8.10 base guest before Ansible | Shipped facts collection passes without `python3` and the existing identity, OS and resource checks pass |
| T8 / Rocky 8.10 | Same candidate; shipped `guest.py runtime` on systemd 239 | Journal query exits 0 and three distinct eligible health invocations are observed |
| T3-T12 / regression | Same candidate on Debian 13 and the remaining Rocky 8.10 cases, scope selected by the owner | Previously passing assertions still pass with unchanged bounds and fixture |

###### Service Inventory Revision For Review

The SQLite absence check must distinguish an absent database service from an unavailable or unreadable service inventory. The selected-unit query can exit 1 when no unit matches; that result alone cannot establish either a provisioning failure or successful absence verification.

1. In `tests/vm/guest.py`, enumerate all installed service unit files with real `systemctl list-unit-files --type=service --full --no-legend --no-pager`. Require command exit 0, structurally valid rows and the installed appliance unit in the inventory. An empty or incomplete inventory cannot prove absence.
2. Reject any installed `mariadb.service`, `mysql.service` or `mysqld.service`, including disabled, static, masked and alias entries. Keep the independent effective dependency check and service-account SQLite schema query. Retain the exact command, status, stdout, stderr and parsed inventory.
3. In `tests/vm/local.py`, exercise the shipped inventory helper using the real systemctl binary against isolated unit-file roots. Cover normal absence, each forbidden name/state, missing appliance inventory and a real invalid-root command failure. These are filesystem-level regressions; they do not verify guest provisioning, SQL or runtime integration.
4. Review the revised plan and draft code. Do not start a new VM matrix or alter retained run contexts before the review and revised execution authorization. Commit/push remain separate operations.
5. After approval and candidate publication, use a new evidence directory and the published revised environment commit with the exact corrected source commit. Run the full six positive cases and both real build-failure cases through the existing driver, preserving accepted resources, deadlines, original IOC fixture and raw inclusive retrieval bounds. Prior partial passes cannot complete this new combined candidate.
6. Request cleanup separately only after evidence review. Confirm real owned-resource removal and preservation of the run-start baseline before the read-only final verdict. Preserve earlier failures permanently.

###### Revised Inventory Test Plan

| Check | Real Path And Environment | Expected Result |
| --- | --- | --- |
| T2 / database service absent | Shipped `sqlite_service_units`; real `systemctl --root`; isolated root containing the appliance unit | Exit 0 inventory, appliance present, forbidden names absent; helper passes |
| T2 / database service present | Same helper and binary; each forbidden name as static, disabled, masked and alias unit-file fixtures | Helper rejects every name/state; presence cannot pass because the service is inactive |
| T2 / incomplete inventory | Same path; root containing a different valid service but no appliance; also a completely empty service root | Both rejected; command failure and missing appliance remain distinguishable |
| T2 / query failure | Same path; a nonexistent root passed to the real systemctl binary | Nonzero command status rejected; actual stderr and exit status retained |
| T6 / real guest backend | New published-candidate Debian 13 and Rocky 8.10 SQLite installs through the unchanged driver/species | Actual service-account SQL and effective dependencies pass; real complete service inventory confirms appliance presence and MariaDB-family absence |
| T1, T3-T15 / combined candidate | All six positive and two negative real VM cases, original fixture, fixed bounds, new context, separately requested cleanup | Complete retained matrix and independent cleanup evidence; no previous partial result or filesystem regression substitutes for VM acceptance |

###### Repository Responsibilities And Handoffs

| Step | Owner | Input | Required Output And Next Condition |
| --- | --- | --- | --- |
| 1. Preflight | epicsarchiverap-env | External checkout paths, exact published candidate/tool refs, selected case, deadlines, private evidence location | Valid prerequisites and resource ownership plan; no guest mutation on invalid input; T14 fault ref kept separate from valid candidates |
| 2. Fresh VM | cloud-provision | OS selector, distinct instance label, image directory and resource limits | New domain/disks only, resolved identity, SSH and completed cloud-init |
| 3. Inventory | cloud-provision | Readiness result and matching species | Runtime inventory naming exactly the new VM; stable OS/species groups |
| 4. Prerequisites | ansible-provision | Its tracked inventory plus generated runtime inventory; limit to the new VM | Real EPICS tools, JDK, shared Tomcat and selected DB available |
| 5. Build/install/start | ansible-provision calling epicsarchiverap-env | Exact `archiver_env_ref`, `archiver_maven_src_tag` and case-specific overrides | Actual Make/Maven steps succeed; installed tree and services ready for independent checks |
| 6. Acceptance | epicsarchiverap-env | VM identity, actual build/configuration outputs and original IOC fixture | Per-assertion payload, database, process, health, HTTP, CA and persistence results |
| 7. Evidence before cleanup | epicsarchiverap-env | Case/assertion results, ownership context and bounded logs | Retained report; full run returns INCOMPLETE/77 while cleanup evidence is pending |
| 8. Explicit cleanup | cloud-provision, called by the driver | Recorded ownership and an explicit cleanup request | Driver independently confirms owned domain/disk/seed/creation-record and live/persistent DHCP removal; pre-existing resources preserved; evidence retained and cleanup errors reported |
| 9. Final verdict | epicsarchiverap-env | Retained results and cleanup evidence bound to the same run/candidate | Read-only evaluation; exit 0 only for complete T2-T15 evidence across the accepted matrix; original failures remain failures |

1. Define and validate the cross-repository input contract. Use explicit paths to initialized tool checkouts, full commit IDs for both tools and both appliance repositories, case selection, timeouts and an evidence directory. Record tool versions and effective `SRC_TAG`; verify every normal candidate/tool commit can be cloned before creating guests. T14 is a separately selected negative case: after normal preflight succeeds, the driver prepares a distinct 40-hex fault ref and confirms its absence in the real source clone. Record the valid source candidate and the absent fault ref separately; absence is required only for this named negative case. Invalid normal refs still stop before guest creation. Publish candidate code under separately authorized commit/push actions before installation tests; never label a run of the old remote commit as verification of local changes.
2. Add the orchestration and result support under `tests/vm/`. Keep lifecycle logic in a single driver; installation and runtime checks are separate commands/functions of that driver. Wire it into the existing phase entrypoints and cumulative runner. For `--system`, the positive matrix loop surrounds both phases: create one case's context, run its Phase 3 then Phase 4, collect results, shut down that owned successful guest through cloud-provision, then begin the next case. Negative cases follow their specified paths; T14 records its expected Phase 3 checkout failure and never enters Phase 4. Never provision all six guests first. A Phase 3-only run selects one positive case, stops after installation checks and records a live VM context; Phase 4 first verifies that context and its candidate identity. Cumulative `--phase=4`/all modes run local phases once before this same matrix loop; `--phase=3` runs local phases and one selected installation case.
3. Before the first guest creation, record one immutable run-start baseline of existing domain identities and DHCP reservations in the selected libvirt network's live and persistent configuration. Keep a separate cumulative ownership list for resources created by every case in this run. Refresh observations before each case to detect collisions, but never add this run's earlier owned resources to the preservation baseline. Call the real `cloud-provision/bin/create_vm.bash` with `-F` and a unique instance label; inspect readiness through its `-s` path. Refuse existing domains/disks and unrecorded targets. Record the created domain UUID, exact disk/seed/`.creation-record` paths, creation identity, network and DHCP MAC/IP attributes (plus a legacy name when present) in the private ownership context. Require the actual domain UUID/name and single network-interface MAC to match; live and persistent reservations must agree without MAC/IP collisions. New unnamed reservations are valid; any legacy name must equal the domain name. Compare the actual guest interface IPv4 address to the reservation and the actual hostname to its cloud-init datasource metadata, with a 63-character limit. Only recorded owned resources are eligible for cleanup; resources outside that list remain untouched. Generate inventory with `bin/generate_ansible_inventory.bash`; combine it with ansible-provision's maintained inventory and always limit the play to the exact created VM. Do not default to a running development or soak VM.
4. Apply the real `archiver_dev` or `archiver_dev_sqlite` species. Pass all candidate refs explicitly instead of inheriting role defaults. Keep `archiver_site_id=als`; select DB backend/transport, service account, install/store roots and heap. The Ansible role executes `init`, `db.conf`, `conf.archapplproperties`, `build.mvn`, `sql.fill`, `conf.storage`, `install` and `sd_start` in the shipped Make system. Observe both the detached build result and actual guest state. Do not insert alternative install commands in this repository.
5. Add installed-payload checks that compare all four exploded WAR trees and Tomcat logging JAR sets against that guest's real build outputs. Check the selected site's classpath files, ALS template/assets, generated service ports, effective unit files, ownership and backend configuration. Separate expected Tomcat/runtime state from immutable WAR/JAR payloads.
6. Add independent runtime assertions: real process identities under the service account, direct shipped launcher health, three non-skipped scheduled health executions, appliance JSON identity, database schema/transport and live IOC archival/retrieval. Confirm the candidate's raw retrieval boundary behavior using the actual API and recorded IOC events. Retrieve at least ten samples within the requested window, with distinct timestamps and changing values matching real CA observations; a value preceding the window cannot count as new acquisition.
7. Add restart, unchanged Ansible re-apply and explicit same-candidate reinstall checks. Retain pre-action identities and data; after the action, verify fresh/live identities as appropriate, health/readiness, persistent PV registration, identical historical samples and additional new samples. Verify state preservation from real data, not only an on-disk marker.
8. Add real failure cases on disposable guests: another real instance's PID in a PID file, stopped IOC, and T14's absent fault ref during a fresh installation. Only T14 supplies that recorded fault ref as `archiver_maven_src_tag` to the real Ansible species; the environment/tool refs remain valid. Positive cases always use the validated source candidate. Assert non-success at the relevant boundary and preserve evidence; restore baseline between runtime cases. Update local runner regressions to check both invalid normal inputs before external action and the separate T14 input contract, rather than asserting that implemented phases always return the old stub result.
9. Implement evidence retention, explicit cleanup and final verdict operations in the same driver. Preserve guests on unexpected failures and interruptions; stop only helper processes owned by the run, and do not advance the matrix after an unexpected failed case. After successful assertions, including an expected T14 build failure, shut down the owned guest through cloud-provision's `-S` path and retain its domain/disks until explicit cleanup. Store all case results and ownership records in one run context. The planned `--cleanup=<run-context>` operation rechecks domain UUID, exact disk/seed/`.creation-record` paths, creation identity and DHCP ownership, then calls the existing cloud-provision cleanup path. Independently inspect every resource afterward, even when the tool exits 0: the owned domain and files must be absent, the recorded DHCP MAC and IP must both be absent from both live and persistent network configuration, and every pre-existing reservation must remain. A failed inspection cannot establish absence or preservation. It requires a separate explicit cleanup request and can operate on retained failed runs without erasing their failure results. Pre-existing guests, directories and operator `.local` files remain untouched. Missing ownership evidence refuses cleanup; shutdown, removal or inspection failures are reported lifecycle failures. The planned `--verdict=<run-context>` operation reads the retained evidence without guest mutation: pending cleanup returns 77, observed failures return nonzero, and only the complete accepted matrix with successful T15 cleanup can return 0.
10. Update operator/test documentation, run local checks and the complete accepted matrix, record each result, and project the revised scope and evidence to #56 under separate issue authority. Keep the milestone In progress until implementation, the accepted real matrix and required external evidence are complete.

###### Proposed Environment Matrix

The proposed acceptance matrix has six fresh successful installations, run sequentially with one active guest per case. Runtime-negative checks use the dedicated SQLite matrix guest for each OS after its healthy assertions; build-failure checks require two additional fresh guests, one per OS. Each guest uses the real OS init/systemd, JDK 21, the existing shared Tomcat provisioner, two vCPUs, 4 GiB nominal RAM, a disk sized for the cold build, and the current 256M per-instance test heap. Record actual guest RAM and disk capacity; require enough free space before build. These are test conditions, not production capacity recommendations. Confirm exact image/tool versions and resource limits before execution.

| OS | Backend / Transport | Species And Required Overrides |
| --- | --- | --- |
| Debian 13 | MariaDB / socket | `archiver_dev`; `archiver_db_backend=mariadb`, `archiver_db_socket=auto`, `mariadb_skip_networking=true` |
| Debian 13 | MariaDB / TCP | `archiver_dev`; empty `archiver_db_socket`, `mariadb_skip_networking=false`; validate the provisioned application account for the effective transport |
| Debian 13 | SQLite | `archiver_dev_sqlite`; `archiver_db_backend=sqlite`; no MariaDB server/service required |
| Rocky 8.10 | MariaDB / socket | Same socket contract through the Rocky species target |
| Rocky 8.10 | MariaDB / TCP | Same TCP contract through the Rocky species target |
| Rocky 8.10 | SQLite | Same SQLite contract through the Rocky species target |

For every case, bind the environment/source refs, tool refs, image digest, site, effective ports, user/group, heap and store policy into the private run context. Both guest Git HEADs in positive installations must equal the requested full commits. T14 additionally binds its separate fault ref and records the actual failed source checkout; it cannot claim a successful installation or require a HEAD at a nonexistent commit. The install stamp and configuration are supporting evidence, never substitutes for reading HEAD and checking payload hashes. Bind an original tracked IOC fixture and its immutable repository commit/path/digest as a separate input; do not reconstruct the fixture from a previous report.

The inspected source at 5e6c12668c9c55f71ae1ba1c3a4384d86049b806 tracks `src/resources/test/UnitTestPVs.db` and its real `SIOCSetup` consumer. Use that original fixture unchanged, with a per-run prefix and its incrementing `test_0` PV, after confirming compatibility with the candidate. The configured source pin d8a7813f40083c1bf7148e6c3b7bffd368d70ee0 is not available as a local tree object for fixture comparison; no same-pin fixture equivalence is claimed. Acquire and verify the exact fixture before running. Start the real `softIocPVX` inside the guest with loopback CA discovery; use real CA tools and the appliance APIs. A fixed fixture ref does not change `SRC_TAG`.

At the inspected fixture commit, the original file contains 10,018 records, including 9,997 with `SCAN` set to `.1 second`. The real consumer loads the entire file; archiving only `test_0` does not limit IOC processing to that PV. Preserve the complete fixture and record its actual record/SCAN counts with its identity. Measure IOC CPU/RSS and guest CPU/memory availability on the proposed two-vCPU, 4-GiB VM, alongside the four appliance JVMs, to verify that the functional checks meet their fixed deadlines. These measurements remain pending; the record counts alone establish neither sufficient resources nor a resource failure.

###### Phase And Result Contract

- Phase 3 checks the fresh installation and its payloads on a VM running real systemd. Phase 4 consumes that same validated installation; it never accepts an arbitrary SSH address or stale context as a verified candidate.
- `--local` runs only the existing local checks and new preflight/verdict negatives. It cannot contact a guest or create resources. Explicit system selection and inputs are required before the VM driver can mutate guest state. The cumulative all-phase mode keeps its documented behavior, but missing explicit system inputs stop before provisioning.
- Diagnostic phase/single-case runs may return 0 for their selected assertions and must identify their limited coverage; they cannot close the acceptance matrix. A full `--system` run retains its context and returns INCOMPLETE/77 when all checks before cleanup succeed but T15 cleanup remains pending. After separately requested `--cleanup=<run-context>`, run `--verdict=<run-context>` to establish full acceptance from the same retained evidence. Cleanup exit 0 describes that operation only; final verdict exit 0 requires the complete accepted matrix and every T2-T15 assertion, including cleanup. Expected negative-test child failures count as successful assertions only when the actual failure and required containment are observed; unexpected failures remain failures after cleanup. Exit 1 denotes observed build/runtime/assertion/cleanup failure; exit 2 denotes invalid invocation or context; exit 77 denotes unavailable prerequisites, unimplemented required checks or pending required cleanup. Any 77 remains overall INCOMPLETE. Preserve the original cause when diagnostic collection also fails.
- The proposed positive deadlines are VM readiness 30 minutes, detached build 45 minutes, application readiness 5 minutes, first ten archived samples 3 minutes and post-restart readiness 5 minutes. Record retries and actual elapsed times. Confirm the runtime bounds with measurements while the complete IOC fixture is running on the accepted VM resources; an exceeded bound is a failed check, not permission to extend it silently. Changing resources or deadlines requires a revised accepted plan and a new run. Healthy startup messages and a transient initial HTTP error may be retried until the bound; permanent malformed responses and identity mismatch fail. Confirm the build bound against the existing role's 80 x 30-second poll limit.
- Scheduled health verification begins only after the effective startup allowance. Record three distinct eligible timer invocations with successful process/storage observations and actual timestamps. Startup/intentional-stop skips do not count. Derive the overall bound from effective startup/interval/timeout values plus a stated scheduling allowance; retain measured times rather than claiming a detection latency from arithmetic.
- Local evidence retains exact target identities, runtime inventory and private diagnostics with restrictive permissions. The public report includes case IDs, immutable code/image refs, tool versions, expected/actual assertions, measured durations, relevant hashes, failure categories and bounded sanitized logs. Exclude credentials, internal VM/host/IP/endpoint identifiers and full secret-bearing configuration.

##### Test Plan

T1 retains the cumulative system-run identity; T2-T15 make its required observations explicit. The six positive installation cases require T3-T12. The two SQLite positive cases additionally require T13 runtime-negative checks. The two dedicated build-failure cases require T3 and T14; they do not require successful installation or T4-T12. T15 covers resource preservation and cleanup for every case. No acceptance row can be marked Pass from code inspection alone.

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | System | Run shipped `tests/run-all-tests.bash --system`; retain its context; separately request driver cleanup, then evaluate the final verdict | All six accepted positive cases and both OS negative cases | Before cleanup: INCOMPLETE/77 with retained results; after actual cleanup: T2-T15 evidence complete, no required skip/failure and final verdict exit 0 |
| T2 | Local preflight | Execute real entrypoints with missing tool paths, invalid normal candidate refs, invalid case/context and unsupported arguments; check distinct normal/fault-ref inputs; run `--local` | Isolated local checkout; no VM credentials/resources | Invalid/missing normal inputs exit 2 or 77 before external action; a fault ref cannot bypass normal preflight or enter a positive case; valid local suite preserves its verdict without guest contact/provisioning |
| T3 | VM lifecycle | Call actual cloud creation/readiness and inventory generator; inspect guest OS, cloud-init and identity | Fresh per-case VM | New recorded domain/disks; SSH and cloud-init ready; exact target limit; existing resources unchanged |
| T4 | Real installation | Apply pinned species with explicit appliance refs; observe build unit, source HEADs, Maven log and actual installation | Six positive installation cases only | Eight real Make steps succeed; both HEADs equal requested commits; no stale sentinel/ref/default can pass; dedicated build-failure cases use T14 instead |
| T5 | Installed payload | Compare real WAR/JAR/configuration bytes, site assets, ports, effective units and ownership | Actual guest build/installed trees | Four intended payloads and required logging JARs match; site/configuration and permissions match the case |
| T6 | Backend contract | Use actual clients as the service account; inspect schema, JNDI and unit dependencies; confirm effective connection transport | Socket, TCP and SQLite cases | Four named application tables; matching resource/runtime DB; selected transport usable; SQLite has no MariaDB dependency/contact |
| T7 | Process identity | Inspect installed launcher health and PID/executable/start-time/CATALINA_BASE under service account | Real four-JVM appliance | Four distinct genuine appliance identities; direct health exit 0; no PID file or `pgrep` match alone accepted |
| T8 | Scheduled health | Inspect effective pair/timer, journal and systemd invocation timestamps after startup allowance | Running guest systemd | Enabled/active timer; three distinct eligible successful checks; no skip counted as success |
| T9 | HTTP identity | Poll real `getApplianceInfo` with a bound and parse its JSON | Selected mgmt port | HTTP 200 plus matching appliance identity/URLs and version contract; independent payload/source checks establish the commit |
| T10 | CA-to-retrieval | Start complete original IOC fixture; measure IOC/guest resource use and elapsed times; record CA updates, register actual PV, confirm raw API boundary behavior and poll status/`getData.json` | Real IOC, engine, store and retrieval on accepted VM resources | Resource/timing evidence retained; `Being archived`; >=10 distinct timestamps and >=2 values inside the requested window matching real CA observations within the deadline; any permitted preceding value excluded from acquisition counts |
| T11 | Restart persistence | Record PV row and retrieved samples; restart through shipped `sd_restart`; repeat identity/health/HTTP/status/retrieval | Same VM and real DB/store | PV row survives; earlier samples unchanged; new samples after restart; fresh process identities and bounded readiness |
| T12 | Repeat installation | Re-apply unchanged pinned species, then explicitly force same-candidate reinstall; repeat payload and runtime checks | Same VM after healthy baseline | Unchanged apply does not rebuild; forced install is real; PV configuration/history retained; new acquisition resumes |
| T13 | Runtime negatives | Use another genuine instance's PID in one PID file; restore; stop real IOC and run fresh-window retrieval checks; restore | Dedicated disposable guest per OS | Health/verifier detects wrong identity despite HTTP readiness; stale history never passes fresh acquisition; real pipeline reports non-success and recovery is reverified |
| T14 | Real build failure | Pass normal preflight with valid candidate/tool refs; on a fresh guest supply only the separately recorded absent fault ref as `archiver_maven_src_tag` to the real species/build path | Dedicated failure guest per OS | Actual source checkout/build fails within bound; preflight rejection alone cannot pass; no new success sentinel/acceptance; Phase 4 is not run; original failure retained |
| T15 | Evidence/cleanup | Run at least two real cases sequentially, retaining the first case's resources; exercise interrupt/failure retention, separately requested cleanup and ownership refusals; independently inspect domain/disks/seed/`.creation-record` and live/persistent DHCP configuration; evaluate retained results | Disposable owned resources, immutable run-start domain/DHCP baseline and cumulative case ownership list | Earlier cases remain owned cleanup targets; all owned resources removed and run-start baseline preserved regardless of tool exit 0; pending cleanup never yields full success; results/logs retained; actual failures cannot be cleared by successful cleanup; final exit 0 requires all other assertions too |

###### Assertion Details

- T5 reads WAR entries and logging JAR digests from the actual Maven target directory and compares installed counterparts. Generated classpath files are checked inside each WAR as well as the installed application; site images/shared CSS and mgmt template sections are checked independently. Timestamped artifact names alone are not identity evidence.
- For SQLite cases only, T6 service inventory requires exit 0 from the full real service listing, the installed appliance unit and no `mariadb.service`, `mysql.service` or `mysqld.service` entries in any install state. MariaDB socket and TCP cases use their selected database service and are not subject to this absence check. Missing-unit filtered-query exit 1 is not used as an absence verdict. Command failure or incomplete inventory fails the check; retain raw evidence.
- T6 requires `ArchivePVRequests`, `ExternalDataServers`, `PVAliases` and `PVTypeInfo`. MariaDB clients use the same socket/TCP transport and application account as Tomcat. SQLite clients run as the actual service account; inspect that there is no MariaDB unit dependency and no accidental MariaDB installation/contact in the SQLite-only species. Confirm the newly registered test PV is persisted in `PVTypeInfo`.
- T8 records health invocation identity, exit status and output. A unit's most recent successful result cannot represent three executions. An enabled timer or a startup skip cannot replace a completed health check.
- T10 records the full fixture's identity and record/SCAN counts, IOC startup duration and timestamped resource observations before IOC startup and throughout acquisition. Record the sampling interval, IOC PID/CPU/RSS, four appliance JVM identities/RSS, and guest CPU, available memory and swap use. Retain elapsed acquisition and post-restart readiness times through T11/T12 with the IOC running. Missing measurements leave the resource/deadline confirmation incomplete; exceeding a fixed readiness/acquisition bound or observing a process loss fails its check. This is functional-test environment verification, not a capacity or long-duration soak result.
- T10 starts CA observation before registration. Capture real IOC event timestamps and values, then compare retrieved `secs`/`nanos` and values to those observations at the CA client's recorded timestamp precision; do not claim nanosecond equality from lower-precision output or invent a time offset. Keep IOC and client in the same guest and record timestamp resolution before judging a match. Use raw `getData.json` without a postprocessor. Query across known recorded events with `from` between two event timestamps and record whether the candidate includes the latest value before `from`. Repeat the observation during T13's stopped-IOC window with `from` after the last observed update. These are actual candidate API checks, not inferred results from the inspected source.
- T10 counts only sample timestamps inside the inclusive `[from, to]` window. If the candidate's observed raw API contract includes a preceding value, permit at most one such first value; record it separately and exclude it from new-sample counts, changing-value counts and the in-window CA comparison. Compare it with the recorded preceding CA event when available. Reject other out-of-window timestamps, malformed/empty data, stale-only history, fewer than ten distinct in-window timestamps or unchanged in-window values. Retry only while the deadline remains. Record requested and observed ranges; do not infer collection from a successful registration response. T11's post-restart acquisition and T13's IOC-loss check use the same rule, so a returned preceding value never proves new acquisition.
- The retrieval boundary check remains unverified until the selected candidate's real API runs. The inspected 5e6c12668c9c55f71ae1ba1c3a4384d86049b806 source has preceding-event handling in `MergeDedupConsumer`; this is a reason to require the check, not proof of the selected candidate's runtime response.
- T11 keeps the original retrieved window and checks it again after restart, then asks for a window after that restart. A persistent PV row without new data, or new data without preserved historical samples, fails.
- T12 records the Ansible outcome, build invocation identity and appliance PID/start times. Re-apply success without actual application checks is insufficient. A forced same-candidate install is explicit and performed only on this run's VM; it must not erase the configuration DB or archive history.
- T13 wrong-PID testing preserves/restores the original PID file and uses a currently verified real other-instance PID; health must fail without signaling/removing either genuine process. IOC loss is judged with a new query window after the last observed update, so old stored data cannot satisfy the test. Restoration is followed by new CA/archival observations.
- T14 prepares a source ref whose absence has been confirmed in the real clone after all normal candidate/tool refs pass preflight. This ref is an intentional fault input, never a candidate identity. The driver passes it only to the named negative case through the actual Ansible variable; the role renders and runs its real detached build script unchanged. Preserve the successful normal preflight, fault-ref absence evidence, Ansible override, build invocation and actual checkout error. A host-side preflight failure cannot satisfy T14. Do not substitute `git`, Maven, Make or `systemctl`; a verifier-only fabricated failure is insufficient.
- T15 compares the immutable run-start baseline and cumulative case ownership list against real post-cleanup state. Execute at least two real cases sequentially through the driver, leaving the first case's shut-down VM and DHCP reservation present when the second begins. Confirm that these earlier-case resources remain in the owned cleanup list and do not become preservation targets through a later observation. After explicit cleanup, independently confirm that every case's owned domain, disk, seed ISO and `.creation-record` are absent, and each owned DHCP MAC and IP are both absent from both live and persistent configuration of the recorded network. Every domain and reservation in the run-start baseline must retain its identity; resources outside the ownership list remain untouched. Capture inspection exit codes and actual results; a query/permission error cannot count as an absent resource. The inspected cloud-provision cleanup at 794eb6b17679a5d48ba61fea3eee110b4b62a97a reports individual failures through messages and its main cleanup branch exits 0, so neither that exit nor an `[OK]` message proves all postconditions. No cleanup failure reproduction is claimed by this inspection. Missing/mismatched context is a refusal, not permission to delete by prefix. Failure/interrupt evidence is preserved before any explicit cleanup. Verify full-run exit 77 while cleanup is pending, cleanup refusal/error or a remaining owned resource without full PASS, and final verdict exit 0 only after all required evidence and resource postconditions are present. A retained unexpected failure must still yield final exit 1 after successful cleanup. A partial context, candidate mismatch or incomplete matrix cannot yield full acceptance.

##### Implementation Evidence

- `tests/vm/driver.py` opens a run with `--init`, adopts one cloud-provision guest per `--case` invocation from a JSON handoff after read-only identity, ownership, disk capacity, stored host key and freshness checks, runs the pinned Ansible species and the guest verifier, and evaluates the run with `--verify-cleanup` and the read-only `--verdict`. It creates, stops and deletes no guest. Implemented in `9dcf72996d10a6fd3c1d3712088900c0ac6fce1d`; the design is `docs/README.vmtests.md`. `tests/vm/guest.py` checks the real artifacts, database, JVMs, scheduled health, HTTP and original IOC/retrieval/persistence paths.
- `tests/run-all-tests.bash` forwards the four operations, and the compatibility entry points `tests/phase3-docker.bash` and `tests/phase4-vm.bash` forward to `--case`; `tests/vm/config.example.json` and `tests/README.md` define explicit inputs and operator commands. `tests/vm/local.py` runs in Phase 1 without virtualization.
- Local verification does not satisfy the accepted real VM matrix. Full candidate publication and explicit checkout/image/key/fixture/binary inputs are required before VM execution; the driver refuses a published candidate whose harness bytes differ from the executing implementation.
- Handoff selectors must derive exactly the recorded VM and file names, and a case is recorded only after every read-only check passes; a refused handoff leaves the run record unchanged. Cleanup is a cloud-provision action on request. `--verify-cleanup` independently confirms that every owned domain, disk, seed, creation record and reservation is absent and that the run-start baseline is preserved; it returns 77 and records nothing while a resource remains or an inspection fails. Original failures remain failures.
- The original fixture commit and SHA256 are enforced, including SHA256 `85778e0ed007ef196ab963a582c9ba7ddbff96bf68e91edab118d1e9ff497e32`, re-derived from the actual committed file. System/installation preflight executes the published candidate's full local suite once; final evaluation requires the matching candidate, exact command, exit 0 and retained output digest rather than a CLI-only result.
- The IOC prefix derives twelve SHA256 hexadecimal characters from the creation ID. Before processing starts, the real IOC must load every original fixture record and report no database loading error. Candidate local checks use the verified candidate source checkout at the expected source path; shell `[SKIP]` and nonzero unittest `skipped=N` counts prevent both preflight and final acceptance through the same completeness check.

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: `--init` passed, all eight `--case` invocations passed, cloud-provision removed the eight guests, `--verify-cleanup` returned PASS and `--verdict` returned PASS (exit 0). Evidence: `e441d59-run-verify-cleanup-20261005T145533Z.log`, SHA256 `ba6c1ca0135a73539dcaff27a3a9d5e36ec198413b776db9dda765c1bf33aa03`; `e441d59-run-verdict-20261005T145533Z.log`, SHA256 `c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431` Earlier, `m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: `--init` passed, three Debian 13 positive cases passed, and `rocky8-socket` failed at T11, so the run holds a failure and four cases did not run (subsection "VM Acceptance Run On f8c457e"). Earlier: Executed the previous shipped `tests/run-all-tests.bash --system`; both unchanged system-phase stubs reported unimplemented checks and the runner exited 77. No installation/runtime acceptance ran. This is the pre-implementation observation, not a result of the new workflow. |
| T2 | 2026-10-04 03:09 PDT | Local Debian 13; real CLI entrypoints | Pass | Latest: the full `--local` suite on the implemented bytes exited 0 without skips (Phase 1 223/0, health 20, database 10, VM local 26, Phase 2 13/0), and the published candidate's own suite passed inside `--init` at 15:42 PDT (subsection "VM Supply And Run Structure Local Verification"). Earlier: Full `tests/run-all-tests.bash --local` exited 0 outside the socket-restricted sandbox: Phase 1 223/0, Phase 2 13/0, health 20, database 10 and VM CLI 10 tests passed without skips. The two added CLI regressions reject noncanonical fixture identities and changed lifecycle selectors before external commands. Bash/Python syntax and `git diff --check` passed; ShellCheck warning gate passed, with only the existing SC1091 info finding in its inventory. Console evidence: `review-fixes-local.log`. A separate actual environment checkout with its candidate source linked at the expected path ran the current full local suite on 2026-10-01 03:53 UTC with exit 0 and no skips (Phase 1 223/0, Phase 2 13/0; health 20, database 10 and VM CLI 10 tests); evidence: `candidate-source-local.log`. On 2026-10-01 05:11 UTC, the corrected full local suite exited 0 without skips (Phase 1 223/0, Phase 2 13/0; health 20, database 10 and VM CLI 11 tests). The new regression runs the shipped health test with a real Java executable and libraries but no adjacent compiler, then rejects its actual unittest skip output. A separate full-suite run with that compiler-free Java also exited 0 with `OK (skipped=1)`; the shared production completeness function accepted the normal output and rejected the skipped output. Evidence: `unittest-skip-normal.log`, `unittest-skip-jre.log` and `unittest-skip-verdict.json`. The published-driver preflight executed before the first real VM attempt; live cleanup progress/retry and the remaining real matrix assertions are unexecuted. Earlier local evidence remains in `local.log` and `vm-local.log`. Local contract checks on 2026-10-01 09:14 UTC exited 0 without skips: Phase 1 223/0, Phase 2 13/0, health 20, database 10 and VM local 14 tests; evidence: `cloud-contract-local.log`. The three new unit checks execute shipped ownership predicates for unnamed/legacy reservations, UUID/interface identity and remaining MAC/IP detection; they do not exercise real VM creation or cleanup. Read-only SSH on the retained Debian guest confirmed `sudo -n cloud-init query ds.meta_data.local-hostname` returns the actual datasource hostname; this is a metadata-query observation only, recorded in the private file `cloud-metadata-query.json`. The actual guest confirmed that `ip -j address` includes MAC and IPv4 data, whereas `ip -j -4 address` omits MAC data; the driver uses the former and selects IPv4 entries. |
| T3 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in all eight cases. Earlier, `m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`; the four remaining cases did not run. Earlier: Real cloud creation exited 1 at SSH readiness; the reserved IP differed from the actual lease and the 90-character guest hostname was rejected. Ansible installation did not run. VM and original failure are recorded in the run `m10-vm-run-e43b973-2`; diagnostic SSH through the observed lease does not satisfy the original run. The cloud-provision correction and current driver require a new matching published-candidate run. A second real run on 2026-10-01 16:19 UTC used published environment `4280f203f87fe2c20de1543ab589cbed9f97e7d0` and cloud-provision `da2ffd56c57cd1814472e85afe3b794339e09464`: cloud creation/readiness and inventory generation exited 0; guest hostname was 63 characters and actual MAC/IP matched the reservation. The driver then failed JSON decoding because its SSH stderr first-connect warning was merged into stdout. Ansible did not run; `m10-vm-run-4280f20` preserves the failed run and VM. On 2026-10-01 17:19 UTC, the corrected shipped SSH function repeated the actual guest facts command with a fresh known_hosts file: stdout decoded as JSON, the first-connect warning was retained separately in stderr, and actual hostname matched cloud-init datasource metadata. Private evidence: `ssh-stream-fix/command-00001.json` and `command-00002.json`. The final local suite on 2026-10-01 17:19 UTC exited 0 without skips: Phase 1 223/0, Phase 2 13/0, health 20, database 10 and VM local 15 tests. The stream regression executes real subprocesses and checks JSON stdout, retained stderr, nonzero exit propagation and the unchanged combined-output default. Evidence: `ssh-stream-fix-local.log`. This read-only diagnostic does not replace a complete matrix run. A third run at 2026-10-01 18:09 UTC with published environment `bdb36baeddeb153ea75a903aafd5cbce0c7effa6` passed this case's lifecycle and identity checks; original run evidence is the file `m10-vm-run-bdb36ba/run.json`. Its overall runtime verdict remains Fail; other matrix cases are unexecuted. |
| T4 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). Earlier, `m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`; the four remaining cases did not run. Earlier: First-case actual Ansible/Make cold build and installation passed. Evidence: `m10-vm-run-bdb36ba/run.json`. Other accepted matrix cases remain unexecuted. |
| T5 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). Earlier, `m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`; the four remaining cases did not run. Earlier: First-case installed payload comparison passed. Evidence: `m10-vm-run-bdb36ba/run.json`. Other accepted matrix cases remain unexecuted. |
| T6 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). Earlier, `m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`; the four remaining cases did not run. Earlier: First-case database schema and socket passed. Evidence: `m10-vm-run-bdb36ba/run.json`. Other accepted matrix cases remain unexecuted. |
| T7 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). Earlier, `m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`, the last read from its runtime evidence `command-01027.json` because the case failed before recording; the four remaining cases did not run. Earlier: First-case JVM readiness passed. Evidence: `m10-vm-run-bdb36ba/command-00298.json`. Other accepted matrix cases remain unexecuted. |
| T8 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). The three scheduled health successes were observed on every Rocky 8.10 case. Earlier, `m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`, the last read from its runtime evidence `command-01027.json` because the case failed before recording; the four remaining cases did not run. Earlier: First-case three eligible scheduled health invocations passed. Evidence: `m10-vm-run-bdb36ba/command-00298.json`. Other accepted matrix cases remain unexecuted. |
| T9 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). Earlier, `m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`, the last read from its runtime evidence `command-01027.json` because the case failed before recording; the four remaining cases did not run. Earlier: First-case HTTP identity passed. Evidence: `m10-vm-run-bdb36ba/command-00298.json`. Other accepted matrix cases remain unexecuted. |
| T10 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). Earlier, `m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-socket`, `debian13-tcp`, `debian13-sqlite` and `rocky8-socket`, the last read from its runtime evidence `command-01027.json` because the case failed before recording; the four remaining cases did not run. Earlier: The published `bdb36ba` runtime failed timestamp/value comparison with zero parsed CA observations: `camonitor -t i` produces incremental timestamps while the parser requires absolute dates. The correction selects CA server timestamps with `-t s`. A focused execution of the shipped `Guest.start_ioc`, `Observer` and `Guest.acquire` loaded all 10,018 original records, recorded 107 CA events without observer errors, and matched all 10 distinct retrieved samples to real CA timestamp/value observations. IOC startup took 1.273 s and acquisition took 106.657 s, within the unchanged 180 s bounds. Private evidence: `ca-timestamp-fix-acquisition-2.json`; full local suite exited 0 without skips (Phase 1 223/0, Phase 2 13/0, health 20, database 10 and VM local 15 tests), evidence `ca-timestamp-fix-local-external.log`. This focused run does not replace the failed full run or satisfy the full matrix and remaining boundary assertions. On 2026-10-01 20:28 UTC, the fresh `52d90166f5995acc332dbeb14945ed26ae32d408` Debian socket run passed T3-T10: real VM creation, installation, payload, database, JVM/HTTP readiness, scheduled health and CA-to-retrieval checks. The original fixture loaded 10,018 records; first acquisition completed in 101.860 s and its raw preceding-value boundary check passed. Runtime evidence: `m10-vm-run-52d9016/command-00304.json`; installation results: `m10-vm-run-52d9016/run.json`. Other accepted matrix cases remain unexecuted. |
| T11 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases, including `rocky8-socket`, `rocky8-tcp` and `rocky8-sqlite` with health polled immediately after `sd_restart`; the case that failed in the run on f8c457e passed. Earlier, `m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the three Debian 13 positive cases; Fail in `rocky8-socket`, where launcher health reported `wrong-java-executable` about 0.4 s after `sd_restart` (M46). Earlier: Shipped `sd_restart` replaced the four JVM identities; readiness returned within 60.074 s and earlier retrieved samples remained unchanged. The following real fresh-acquisition request ended at `2026-10-01T20:29:52.813821124Z`; raw retrieval returned a sample at `2026-10-01T20:29:52.823097908Z`, 9.276784 ms later. The unchanged window check refused this response with `Unexpected out-of-window API data`. The observer recorded 163 CA events and 162 resource samples without errors. Original failure and response: `m10-vm-run-52d9016/command-00304.json`; console `system-52d9016.log`, exit 1. No source correction or window-check relaxation has been applied. T12-T15 and remaining matrix cases did not run; owned IOC/verifier helpers stopped and the VM remains preserved. Diagnosis on 2026-10-01 20:41 UTC reproduced the source bug using the real original IOC and live HTTP retrieval: `to = sample timestamp - 1 ns` still returned that sample; `to = sample timestamp` returned it without upper-bound overflow. Stored-history controls excluded the target at minus 1 ns and included it at its exact timestamp. At pinned source `d8a7813f40083c1bf7148e6c3b7bffd368d70ee0`, `GetEngineDataAction` uses `StreamPBIntoOutput.streamPBIntoOutputStream`, whose lines 50-65 discard fractional seconds and compare epoch seconds; `MergeDedupConsumer` forwards events without a final upper-bound filter. Actual evidence: `retrieval-live-upper-bound-3.json` and `retrieval-upper-bound.json`. The successful live probe recorded 168 CA events with no observer errors; its owned IOC stopped successfully. No production source or acceptance criteria changed. |
| T12 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the six positive cases (Debian 13 and Rocky 8.10, MariaDB socket and TCP, SQLite). Earlier, `m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in the three Debian 13 positive cases; the other cases did not reach it. |
| T13 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-sqlite` and `rocky8-sqlite`. Earlier, `m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-sqlite`; `rocky8-sqlite` did not run. |
| T14 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Pass in `debian13-build-failure` and `rocky8-build-failure`: the build failed at the real checkout of an absent commit, with git 2.47.3 printing `unable to read tree` on Debian 13 and `reference is not a tree` on Rocky 8.10, both recognized by the corrected check. |
| T15 | 2026-10-05 00:08-03:42 PDT | Published `e441d59`; cloud-provision guests | Pass | Latest, run `m10-vm-run-e441d59-aa953a4` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770`, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: Eight guests were retained across the cases, cloud-provision removed them on request, and `--verify-cleanup` returned PASS: every owned domain, disk, seed, creation record and reservation is absent and the baseline is preserved. Earlier, `m10-vm-run-f8c457e-dca485f` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee` and Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`: `debian13-tcp` started while the first guest remained owned and present, and the interruption and cleanup-refusal checks passed in `debian13-socket`; `--verify-cleanup` on this failed run returned PASS at 19:04 PDT after cloud-provision removed its four guests; the run holds a failure, so it yields no verdict. |

###### Published-Candidate Run Before Inventory Revision

Observed on 2026-10-02 at 06:04 UTC, using published environment `8f3bbfe96b7d1ee60cfd11ee0c72b2c422e8d12c`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee`, pinned cloud/Ansible tools, unchanged images and original IOC fixture. The preceding table preserves earlier candidate observations; this run supersedes their current execution status without clearing their failures.

| Check | Observed Result | Evidence And Remaining Work |
| --- | --- | --- |
| T1 | Fail | Full system run exited 1 and stopped on SQLite installation verification; `m10-vm-run-8f3bbfe-dca485f-2/report.json` |
| T2 | Partial | Published candidate full local suite and preflight passed; this does not verify the revised draft code |
| T3-T12 | Partial | Debian 13 MariaDB socket and TCP cases passed all installation, runtime, exact-window, restart and repeat-install assertions; per-case results in `run.json` and guest JSON files. Both guests are shut down and retained |
| T5-T6 SQLite | Fail at T6 | Payload comparison and service-account schema query passed; effective appliance dependencies contain no MariaDB unit. The selected MariaDB unit query returned empty stdout and exit 1, which `execute` rejected before the absence assertion. Actual guest evidence in `command-01583.json`; database absence is not a failed SQLite schema result |
| T13-T14 | Not run | SQLite runtime negatives, Rocky cases and both real build-failure cases remain unexecuted |
| T15 | Partial | Real interruption and cleanup-refusal checks passed on the first owned guest; earlier ownership remained recorded when later cases began. Explicit resource cleanup has not run; no full acceptance |

The failed SQLite VM and all original contexts remain preserved. The revised draft verifier requires its own local checks, review and a new full published-candidate run. No revised VM result or successful cleanup is claimed.

###### Revised Draft Local Verification

Observed on 2026-10-02 at 06:31 UTC. `PYTHONDONTWRITEBYTECODE=1 python3 tests/vm/local.py` exited 0: 16 tests, including real systemctl filesystem inventory regressions. The initial regression draft failed because an empty service root returned command exit 1; the final test distinguishes that command failure from a nonempty inventory missing the appliance. No VM result is inferred from either local execution.

The real `tests/run-all-tests.bash --local` run outside the sandbox exited 0 without skips: Phase 1 logic 223 passed, health 20 tests, database 10 tests, VM local 16 tests, Phase 2 build wrapper 13 passed. Evidence: `sqlite-inventory-revision-local.log`, SHA256 `d6ddaba233302bf305e0c2fc6482b41062b22c288c7d8c56a9b6bc9936d5fd16`. Verified draft `tests/vm/guest.py` SHA256: `c152e9342505cbee9fa3b541b2360358efdf61439f5ad88c1c70dbd4d823a680`; `tests/vm/local.py` SHA256: `1ab7c5ccabdb978b7a3d4642ca787b12da9668bd4c5f1f9ab0798b913faaa8c5`.

Revised plan acceptance and execution authorization are recorded above. The revised verifier was published as `607092b962afd9cbac31ce9f62efba0e7c62b471`; subsequent observations are recorded below. Full matrix acceptance and explicit cleanup remain pending. Retained failed contexts have not been changed.

###### Published Revision And Single-VM Verification

Observed on 2026-10-02, with environment `607092b962afd9cbac31ce9f62efba0e7c62b471` and source `dca485fd28d14cf91e988fae9ade13729a55c7ee`. The full driver preflight passed the published candidate's actual complete local suite without skips at 07:30 UTC. Its first VM creation then exited 1 because the selected address already belonged to another MAC in an unnamed DHCP reservation. Disk and seed creation preceded that refusal; no domain was found afterward. Installation did not start. The original failure is the run `m10-vm-run-607092b-dca485f`, including `command-00116.json`; do not treat a retry or later diagnostic success as clearing it.

Cloud-provision subsequently created a separate basic Debian 13 VM using tool `e468393242000f627f626fffbb2f5b7277f344e3`. Actual domain UUID and MAC/IP ownership matched the private handoff and both live/persistent reservations before guest verification. SSH, two vCPUs, 4 GiB RAM and cloud-init done with no errors were independently observed; a password-unspecified warning remains. Installation used the unchanged pinned Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`, its maintained inventory plus a generated single-host inventory, and an exact host limit. The real `archiver_dev.yml` run exited 0 with failed=0 and unreachable=0. This is a direct Ansible installation, outside a full driver run context.

| Check | Observed Time UTC | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T5-T6 | 2026-10-02 08:29 | Debian 13 MariaDB socket; shipped `guest.py installation` through a real systemd helper | Pass for this VM: exact candidate HEADs, installed payload/configuration and service-account schema/transport verified; `m10-ansible-handoff-607092b/installation.json` |
| T7-T9 | 2026-10-02 08:29-08:31 | Same VM; shipped `guest.py runtime`, actual launcher, timer and HTTP APIs | Pass for this VM: four genuine JVM identities, three distinct eligible health invocations and HTTP appliance identity |
| T10 | 2026-10-02 08:32 | Same runtime path; unchanged original fixture, real IOC/CA and retrieval | Pass for this VM: all 10,018 records loaded; ten distinct retrieved timestamps/values matched CA observations and raw window checks passed; IOC startup 1.306 s, first acquisition 109.625 s, each within its unchanged 180 s bound |
| T11 | 2026-10-02 08:34 | Same runtime path; real `sd_restart` with IOC running | Pass for this VM: all JVM identities replaced, earlier history preserved and fresh acquisition passed; restart/readiness 53.689 s within 300 s, fresh acquisition 10.332 s within 180 s |
| T12 / unchanged reapply | 2026-10-02 08:47 | Same VM and pinned Ansible inputs; actual playbook followed by shipped `guest.py unchanged` | Pass for this VM: Ansible exit 0, changed=0 and failed=0; actual build invocation remained identical, all four JVM PID/start identities and stored history/readiness preserved; `m10-ansible-handoff-607092b/reapply-result.json` |
| T12 / forced reinstall | 2026-10-02 08:58 | Same VM; explicit force variable through actual Ansible, real build journal and shipped `guest.py reinstalled` | Pass for this VM: new build invocation, expected eight Make targets, actual completion sentinel, replaced JVM identities, matching payload/schema, three eligible health successes, stored history and fresh acquisition; acquisition 10.296 s within 180 s; `m10-ansible-handoff-607092b/reinstall-result.json` |
| T13-T15 | Not run in this diagnostic | Planned SQLite negative, build-failure and lifecycle methods | Pending for this candidate; no full matrix or cleanup result inferred |

Installation verifier and runtime verifier both exited 0. Runtime evidence: `m10-ansible-handoff-607092b/runtime.json`, SHA256 `d46370b880c451102bebf500b290376e8fdc7afafe70f3f7661106802c2d6db1`. Installation evidence SHA256: `a5b2d4f93c3b779895bbeeb31a8e0aaf37495b7fbedcb3c858e1c19b13bc2604`. Private inputs, ownership observations and Ansible output remain in the same evidence directory. The published guest verifier ran without internal substitutions and used the original fixture and unchanged deadlines. The current driver has no external-VM adoption operation; these results remain independent diagnostic evidence. No synthetic full-run context, full acceptance, VM shutdown or cleanup is claimed. M10 remains In progress.

Repeat-install evidence was observed through the actual pinned playbook and shipped verifier, without substituting internal build or application paths. Unchanged-reapply evidence SHA256: `0f711ce4748792017f7ad98363022c2e01eaf51ad36fc2be9ef796de16ada00d`; forced-reinstall evidence SHA256: `0edba2c04c578b67b0794562a0c32611f02e04d27b80bce97ef75a1d867210d9`. The full build journals, Ansible command results and raw guest output are retained beside these files. Separate SQLite observations follow below.

###### Published Revision And Debian SQLite Verification

Observed on 2026-10-02 with the same published environment/source commits and pinned Ansible. A separate fresh Debian 13 VM was prepared by cloud-provision `a52bb79687f0ba260123de362f5ade77d136ceb9`. Actual UUID, interface MAC, attached disk/seed and live/persistent DHCP ownership matched the private handoff; the initial guest had no appliance or MariaDB installation. The real single-host `archiver_dev_sqlite.yml` install exited 0 with ok=27, changed=9, failed=0 and unreachable=0. The unchanged published `guest.py` and original IOC fixture digests were confirmed on the guest before runtime verification. These are independent diagnostics outside the failed full driver context.

| Check | Observed Time UTC | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T5-T6 | 2026-10-02 15:54 | Debian 13 SQLite; shipped `guest.py installation`, service-account SQL and complete real service inventory | Pass for this VM: requested source HEADs and installed payload/configuration match; application schema and WAL connection verified; appliance unit present, MariaDB-family units and dependencies absent; `m10-ansible-sqlite-607092b/installation.json` |
| T7-T9 | 2026-10-02 16:26-16:27 | Shipped `guest.py runtime`; genuine processes, launcher health, scheduled timer and HTTP APIs | Pass for this VM: four appliance JVM identities, three distinct eligible health successes and matching HTTP appliance identity |
| T10 | 2026-10-02 16:29 | Same runtime path; complete original IOC, real CA and raw retrieval | Pass for this VM: all 10,018 records loaded; eleven distinct in-window timestamps with eleven different values match CA observations; the between-events boundary query records one preceding value separately. IOC startup 1.300 s and acquisition 101.561 s are within unchanged 180 s bounds |
| T11 | 2026-10-02 16:30 | Real `sd_restart` with IOC running | Pass for this VM: all JVM identities replaced, stored PV/history preserved and new acquisition observed. Restart/readiness 52.706 s within 300 s; fresh acquisition 10.230 s within 180 s |
| T12 / unchanged reapply | 2026-10-02 16:31 | Same pinned Ansible inputs followed by shipped `guest.py unchanged` | Pass for this VM: Ansible exit 0, changed=0 and failed=0; build invocation and four JVM PID/start identities unchanged; stored history and readiness preserved; `m10-ansible-sqlite-607092b/reapply-result.json` |
| T12 / forced reinstall | 2026-10-02 16:38 | Explicit force variable through real Ansible, actual build journal/script/sentinel and shipped `guest.py reinstalled` | Pass for this VM: Ansible exit 0, changed=1 and failed=0; new build invocation and expected eight Make targets; payload/schema and MariaDB absence rechecked; replaced JVMs, three eligible health successes, preserved history and fresh acquisition in 10.304 s; `m10-ansible-sqlite-607092b/reinstall-result.json` |
| T13 | 2026-10-02 16:39 | Shipped `guest.py negative`; genuine other-instance PID, real IOC stop and restoration | Pass for this VM: wrong PID gives health exit 1 with `wrong-instance-base`, despite HTTP readiness; genuine process identities and PID-file ownership restored. Stopped-IOC query has zero fresh samples and one preceding value. Restored IOC resumes acquisition in 12.342 s and stored history remains unchanged; `m10-ansible-sqlite-607092b/negative.json` |
| T1, T3-T4, T14-T15 / full context | Not established by these diagnostics | Accepted full driver, dedicated build-failure and lifecycle/cleanup paths | Pending; the original full-run failure and all retained resources remain preserved |

The runtime verifier exited 0 and retained 165 CA events and 164 one-second resource observations without observer errors. Its original IOC, raw window checks, restart and recovery ran through the published code without internal substitutes or relaxed deadlines. Runtime evidence is `m10-ansible-sqlite-607092b/runtime.json`.

| Retained Artifact | SHA256 |
| --- | --- |
| `installation.json` | `b4dc4d509e0ec21a74a45af3c8a7c1ea5ebe5d9d90e7c464bb2bcd21981145c3` |
| `runtime.json` | `6b2716a6461c3f30eee503a1dd70c172c6986021c3b33a1be272879097557f02` |
| `reapply-result.json` | `d99ed56cec4dfa3b3970e533845038ebbe7de330d86932ca19fd1833cdc384bf` |
| `reinstall-result.json` | `d73d487cad39eb190b2033b31c62632e35222e95abb97c86429fd316cbc21352` |
| `negative.json` | `c7895fa7770763fd815c5d755d1e66f4665bebc0785f1851d90a14b62b08d4bb` |

Private command results, full build journals, Ansible output, actual guest `history.json` and pre-action PID/start records are recorded in the run folder `m10-ansible-sqlite-607092b`. Its `evidence-manifest.json` records 43 retained files and their digests; manifest SHA256: `404d2d2fee79b5bcba5c228bf1b902f604649dca19c47768344ee12c6f17ccd8`. Final observed appliance/IOC services and health timer are active. No shutdown, cleanup, full matrix acceptance or issue closure has been performed. M10 remains In progress.

###### Published Revision And Debian TCP Verification

Observed on 2026-10-02 with the same published environment/source commits, pinned Ansible and original fixture. A separate fresh Debian 13 VM was prepared by cloud-provision `9da0436bf6fbd780015156ea04c2b535fe5507ec`; actual UUID, interface MAC, attached disk/seed, lease and live/persistent DHCP ownership matched the private handoff, and the guest had no install paths or appliance/database units. The shipped `Driver` methods `capture_ownership`, `verify_live_case`, `install`, `build_proof`, `transfer`, `guest` and `runtime` ran unchanged against that guest through a private harness that binds them to the external VM and writes no `run.json`. The real `archiver_dev.yml` play used an empty `archiver_db_socket` and `mariadb_skip_networking=false`. These are independent diagnostics outside a full driver context.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T3 | 2026-10-02 13:29 | Debian 13; ownership, generated single-host inventory and the driver's guest facts, hostname, interface, OS and resource checks | Pass for this VM: 2 vCPUs, 18652266496 free root bytes, cloud-init done with no errors (extended status degraded by the template's password-unspecified warning) |
| T4 | 2026-10-02 13:40 | Real Ansible installation, build journal, build script and sentinel | Pass for this VM: Ansible exit 0, ok=31, changed=11, failed=0 in 630.0 s; the eight accepted Make targets ran in order |
| T5-T6 | 2026-10-02 13:40 | Shipped `guest.py installation` | Pass for this VM: guest HEADs equal the requested environment/source commits; payload/configuration match; the service account reads the four application tables over TCP to the local MariaDB port |
| T7-T9 | 2026-10-02 13:40-13:42 | Shipped `guest.py runtime` | Pass for this VM: four genuine JVM identities, three distinct eligible health successes and matching HTTP appliance identity; readiness 4.363 s |
| T10 | 2026-10-02 13:43 | Same runtime path; complete original IOC, real CA and raw retrieval | Pass for this VM: all 10,018 records loaded; ten distinct in-window timestamps with ten values match CA observations; the between-events boundary query records one preceding value separately. IOC startup 1.306 s and acquisition 103.432 s within unchanged 180 s bounds |
| T11 | 2026-10-02 13:45 | Real `sd_restart` with IOC running | Pass for this VM: all JVM identities replaced, stored PV/history preserved and new acquisition observed. Restart/readiness 60.312 s within 300 s; fresh acquisition 10.349 s within 180 s |
| T12 / unchanged reapply | 2026-10-02 13:45 | Same pinned Ansible inputs followed by shipped `guest.py unchanged` | Pass for this VM: Ansible exit 0, changed=0 and failed=0; build invocation and four JVM PID/start identities unchanged; stored history and readiness preserved |
| T12 / forced reinstall | 2026-10-02 13:48-13:50 | Explicit force variable through real Ansible, actual build journal/script/sentinel and shipped `guest.py reinstalled` | Pass for this VM: Ansible exit 0, changed=1 and failed=0 in 168.0 s; new build invocation and expected eight Make targets; payload/schema rechecked; replaced JVMs, three eligible health successes, preserved history and fresh acquisition in 10.338 s |
| T1, T13-T15 / full context | Not established by these diagnostics | Accepted full driver, SQLite negative, build-failure and lifecycle/cleanup paths | Pending; T13 is not required for a MariaDB case |

The runtime observer retained 175 CA events and 173 one-second resource observations without errors. At 13:50 PDT, `systemctl is-active` over SSH reported the appliance, health timer, test IOC and MariaDB units active. The pinned Ansible checkout reported an SSH-form origin URL at 13:29 PDT; the driver's full preflight requires an HTTPS origin, so that input must be rechecked before a full driver run.

| Retained Artifact | SHA256 |
| --- | --- |
| `debian13-tcp-installation.json` | `8f92dd30bef2694e88285c314fcce592e2f6eb04b7282972782a38683ae67a73` |
| `debian13-tcp-runtime.json` | `e13d7ec58888c428d9a86eed1b96fb980cbf0bec3631b8d18bea671b12b27a33` |
| `debian13-tcp-unchanged.json` | `28c13147ead2aa6d790870254f1030c2c73b0a737a6853b990719c2f1391e8af` |
| `debian13-tcp-reinstalled.json` | `e397be8c571319a34d75c37c9339c14b8f34b4c106dba6f7cb66540700417e6b` |

Private inputs, ownership observations, the harness, 547 command results and the diagnostic state are recorded in the run folder `m10-ansible-tcp-607092b`. No shutdown, cleanup, full matrix acceptance or issue closure has been performed.

###### Published Revision And Rocky 8.10 Socket Diagnostic

Observed on 2026-10-02 with the same published environment/source commits, pinned Ansible, original fixture and harness method. A separate fresh Rocky 8.10 VM was prepared by cloud-provision `6ae1dbf3dd0d115185f7eee29f657ab318f94393`, whose uncommitted paths were documentation and tests only; actual ownership matched the private handoff and the guest was fresh. By owner direction, Decision Date: 2026-10-02, the diagnostic continued after the recorded T3 failure using the adjusted observation only. The case stopped at its first unexpected runtime failure; deadlines, window checks and verifier code were not relaxed.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T3 / shipped facts command | 2026-10-02 18:00 | Rocky 8.10 base guest; the driver's pre-installation facts command over SSH | Fail: `python3` is absent before Ansible installs its Python packages, so the command exits 127 with `python3: command not found`. The shipped `Driver.create` sequence would stop at this point on every fresh Rocky case. Evidence: `command-00117.json` |
| T3 / diagnostic continuation | 2026-10-02 18:00 | Same checks with `/usr/libexec/platform-python` and `text=True` replaced by `universal_newlines=True` for Python 3.6 | Pass for this VM only: 2 vCPUs, 18407264256 free root bytes, cloud-init done with no errors or warnings. This adjusted observation does not verify the shipped command |
| T4 | 2026-10-02 18:08 | Real Ansible installation, build journal, build script and sentinel | Pass for this VM: Ansible exit 0, ok=33, changed=14, failed=0; the eight accepted Make targets ran in order |
| T5-T6 | 2026-10-02 18:08 | Shipped `guest.py installation` | Pass for this VM: guest HEADs equal the requested commits; payload/configuration match; JDK 21; the service account reads the four application tables through the MariaDB socket. SHA256 `dee5556c3459b4305bb6f0b5d5984fd41132f2750503f4a028d48b23c595c515` |
| T7, T9 | 2026-10-02 18:08 | Shipped `guest.py runtime` | Pass within the failed runtime attempt: readiness and appliance identity completed in 17.176 s |
| T8 | 2026-10-02 18:08 | Same runtime path; scheduled health journal query | Fail: `guest.py` passes an ISO 8601 timestamp with fractional seconds and a `+00:00` offset to `journalctl --since`; systemd 239 rejects it with `Failed to parse timestamp`. A read-only repeat on the guest also rejected the form without fractional seconds and accepted `YYYY-MM-DD HH:MM:SS UTC`. The verifier exited 1. Evidence: `command-00404.json` |
| T10-T12 | Not run | Same VM | Not run after the T8 failure; the test IOC was not started |

The Debian 13 cases accepted the same timestamp form, so both failures are specific to the Rocky 8.10 base environment. Correcting them changes the shipped driver and verifier and therefore requires a revised plan, publication and a new candidate run; earlier diagnostics do not verify that candidate. The original failures, private inputs, harness, command results and diagnostic state are recorded in the run folder `m10-ansible-rocky8-socket-607092b`. At 22:50 PDT, `systemctl is-active` over SSH reported the appliance, health timer and MariaDB active and the never-started test IOC inactive; no shutdown or cleanup has been performed.

###### Rocky 8.10 Compatibility Local Verification

Observed on 2026-10-02 on the local Debian 13 host (systemd 257, Python 3.13) with the accepted revision implemented on top of 6751c098eddcca75188418b84de366ed179c5b94. The source SHA256 values below identify the verified bytes: `tests/vm/driver.py` `ddf92f98a71fd292e83c6ff82e4a50e1e9d1483128a3dc0947663390e940c24f`, `tests/vm/guest.py` `755745bf1b5ab19ebbf6b7fcd4ae16d8130afa07e59cda720965bf0d287f2116`, `tests/vm/local.py` `921ac8dcd6a906b14a69057d8b696651f8832b7d5edaad303274ad37bf58da21`.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T2 / earlier facts command | 2026-10-02 23:09 | New shell-facts regression against the earlier Python command, factored into a module function without other change (driver SHA256 `b077eaa730650fa3d01b2b7a0ca479ffc7a3ec1a20e51bf7458bb38546700776`); real `bash -c` with a `PATH` of real `sh`, `cat`, `getconf`, `hostname`, `ip` and `stat` only | Fail as required: exit 127 with `python3: command not found`, the same failure as the Rocky 8.10 guest. Evidence: `rocky-compat-earlier-facts.log` |
| T2 / shell facts | 2026-10-02 23:10 | Same regression against the shipped shell command and parser | Pass: parsed CPU count, hostname, root size and `/etc/os-release` content equal the local observations; removing each of the six sections in turn is rejected |
| T2 / journal bound | 2026-10-02 23:10 | Shipped `journal_since`; real local `journalctl --since` | Pass: a whole second is unchanged and 1 ns, 0.5 s and 0.999999999 s past it convert to the next second; the real command exits 0. systemd 239 behavior is not reproduced locally |
| T2 / full local suite | 2026-10-02 23:10 | `tests/run-all-tests.bash --local` | Pass: exit 0 without skips; Phase 1 223/0, health 20, database 10 and VM local 18 tests, Phase 2 13/0. Evidence: `rocky-compat-local.log`, SHA256 `8a6ace3da4459fe3d376e5fd813f2b325b20e32b72203b65e04427ff305fedb8` |
| Guest facts preview | 2026-10-02 23:10 | Shipped facts command over SSH on the retained Rocky 8.10 socket and Debian 13 TCP guests | Exit 0 on both; parsed OS release, two CPUs, 63-character hostnames and root/free bytes. Both guests were already installed, so this is not T3 evidence. Evidence: `rocky-compat-guest-facts.log` |

The VM verification of this revision follows below.

###### Published Revision And Six-Case Verification

Observed on 2026-10-03 (Pacific local date; times PDT) with published environment `65cf077b1230f61efdba817aa697483a79a3a5d5`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee`, pinned Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5`, the original fixture and unchanged bounds. By owner direction, Decision Date: 2026-10-02, all six positive cases were re-run one fresh guest at a time, each shut down after its case. Cloud-provision `a29f4773c14274b447cb66f4b9ab11f4cc1f8583` prepared every guest, with one uncommitted documentation path; actual UUID, interface MAC, attached disk/seed, lease and live/persistent DHCP ownership matched each private handoff. A private harness bound the unchanged shipped `Driver` methods to each external guest, collected facts through the shipped `guest_facts_command` and `parse_guest_facts`, checked freshness with a shell-only probe, required the executing `tests/` tree to equal the candidate commit and wrote no `run.json`. These are independent diagnostics outside a full driver context.

| Case | Observed Time PDT | Results | Ansible Install / Reapply / Reinstall | IOC Startup / Acquisition / Restart / Post-Restart / Post-Reinstall |
| --- | --- | --- | --- | --- |
| Debian 13 socket | 2026-10-03 00:18-00:37 | T3-T12 Pass | changed=11 in 464 s / changed=0 / changed=1 in 228 s; failed=0 | 1.327 / 105.532 / 55.982 / 10.255 / 10.294 s |
| Debian 13 TCP | 2026-10-03 00:39-00:57 | T3-T12 Pass | changed=11 in 518 s / changed=0 / changed=1 in 168 s; failed=0 | 1.298 / 103.584 / 58.734 / 10.301 / 10.326 s |
| Debian 13 SQLite | 2026-10-03 01:00-01:19 | T3-T13 Pass | changed=9 in 504 s / changed=0 / changed=1 in 197 s; failed=0 | 1.299 / 109.515 / 61.032 / 10.302 / 10.284 s; T13 recovery 10.261 s |
| Rocky 8.10 socket | 2026-10-03 01:23-01:37 | T3-T12 Pass | changed=14 in 312 s / changed=0 / changed=1 in 146 s; failed=0 | 1.300 / 103.416 / 52.985 / 10.252 / 10.225 s |
| Rocky 8.10 TCP | 2026-10-03 01:41-01:58 | T3-T12 Pass | changed=14 in 426 s / changed=0 / changed=1 in 202 s; failed=0 | 1.328 / 105.950 / 54.347 / 10.188 / 10.220 s |
| Rocky 8.10 SQLite | 2026-10-03 02:05-02:20 | T3-T13 Pass | changed=11 in 316 s / changed=0 / changed=1 in 172 s; failed=0 | 1.352 / 105.574 / 51.776 / 10.201 / 10.230 s; T13 recovery 12.234 s |

Each acquisition stays within its 180 s bound and each restart within 300 s. Every runtime loaded all 10,018 fixture records, matched at least ten distinct in-window timestamps with their values to CA observations and retained 167-181 CA events without observer errors. The between-events boundary query recorded one preceding value separately in five cases and none in the Debian 13 SQLite case, within the permitted maximum of one. Socket and TCP cases used the service account through the MariaDB socket and `127.0.0.1` TCP respectively; both SQLite cases confirmed WAL, the appliance unit and the absence of MariaDB-family units. Both T13 runs detected the wrong-instance PID despite HTTP readiness, returned no fresh sample with the IOC stopped and resumed acquisition after restoration.

The Rocky 8.10 failures recorded at `607092b962afd9cbac31ce9f62efba0e7c62b471` are corrected on real guests. Cloud-provision reported no `python3` and no Ansible on each fresh Rocky guest, and a separate SSH check immediately before the socket-case observation confirmed `python3` absent; the shipped facts collection passed T3 on all three. On systemd 239, the journal bound `@<epoch seconds>` was accepted and three distinct eligible health invocations passed T8; T10-T13 then ran on Rocky 8.10 for the first time and passed.

| Case | Installation | Runtime | Unchanged | Reinstalled | Negative |
| --- | --- | --- | --- | --- | --- |
| Debian 13 socket | `f44ae7e6191097ef3a5ff2c4a2fa74964f36a57ac35ca8f01240bb3e42883f8f` | `50d1e4b70ab2c9aeae709fc9779bcaeda0645d5f67bb2d700e913e7fbe8bad8e` | `1c0f295cdcff3643c9af0e24def6cb132853162c0300f7f13417ce4f56c5d6e0` | `47ffccf9175f62ffe1221100409d55b18c943834df28873482232fe89ca608e7` | Not required |
| Debian 13 TCP | `6700679b24f29bc95d825a6c79729e4a53219c63cd2c82444703efdb356268db` | `34dfbe492089205e4bf42cf2853c2ea3e573d34133670eda14f011264ea592b3` | `821d01f6cf4d5a83d715f478dc98d6aa78ff440f39fb2686c0195fc10f575ac4` | `407b108e13df50b2201a0ec6d0ef31ff93b55338a8678ae06534e7fade977f8a` | Not required |
| Debian 13 SQLite | `075d82581328465daca2234d4952e0a6ed6e2b60c191567461604f3b341884a2` | `6ded2b97bb192c62ae3db3f38e521e7136478b96e5498dfed08b07735282d932` | `04882fcf17a8070157a067d7848453f4ca0d94ce44912cdf05df12dcf99d683f` | `a52a21cf346f380f24ac352c1abd321089da222c26ed14c9932a1e5d990ddb17` | `50f37b22ea50578d43ffb9d4be5e83203e14eec9f96c682e9f7f5333bc9cb652` |
| Rocky 8.10 socket | `538a0c3b99c640509862aebdd0439fc0798fccb04fe77a6f7153276829223384` | `4c2135d55e2faac57be2550282e47ed77177a7a2a521ddb9f57fd9aa71c903b2` | `06430804afa97fda1190b2be8a2b0c657543a4e082cd40f755d8bf20836a89a3` | `bdf3e73cae083bd9f5593f1ec14df1f671fc4edea4956eae8834596030ef7cf3` | Not required |
| Rocky 8.10 TCP | `e1f8589189578b671cd9fe74d97eb2a921a5dfd22f69f1ca3488d5aff10623ba` | `4ecddf72365fe3c25bf1cc18ba544b9d95976dd4726c417e4e5823e9e50490ae` | `54577d0f434804c42e2e1e4d1c969fde8304dbf66fc0bea5915390192877f35d` | `6c2735ab81219838610641017f8d4a6402548c5bc52649a556c7bb152b67d12a` | Not required |
| Rocky 8.10 SQLite | `6cbffef8635f0a3ab563339f2ff20764fd83575ea4235028b8f76761c6dd871f` | `704f96069434533805e4fdee0ad3bbf9c889768c25af1356668e07c6a3241652` | `e7885eb152becd814a4b0300ecfa9f7e6a7030a0829da656baa6dc885c7d7865` | `ddcb826df42899aa93bf79839806f4b55fd93f0544359042dd2e920592214cfd` | `67cb53a7d28e9f7393981b0453695767c1a6006afb4e9fa35b81ed3cf93fcc3d` |

Private inputs, ownership observations, command results and diagnostic state are recorded in the run folder `m10-<case>-65cf077` for each case, and the harness in `m10-harness`. All six guests were shut down through cloud-provision after their cases and retained; at 2026-10-03 10:41 PDT `virsh domstate` reported each of them shut off. No cleanup, full driver context, T1, T14, T15 or issue closure has been performed.

###### Interrupted Full Driver Run At 65cf077

Observed on 2026-10-03 (times PDT) with the shipped `tests/run-all-tests.bash --system` on environment `65cf077b1230f61efdba817aa697483a79a3a5d5`, source `dca485fd28d14cf91e988fae9ade13729a55c7ee`, pinned Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5` and cloud-provision `a29f4773c14274b447cb66f4b9ab11f4cc1f8583`. The run was started at 19:30 from a background task of the operator tooling with `GIT_CONFIG_GLOBAL=/dev/null`, because a global `url.<ssh>.insteadOf` rule makes `git remote get-url` report SSH form for the stored HTTPS origins. Before the run, stale `~/.ssh/known_hosts` keys of ten unreserved addresses in the hashed window were removed by owner direction, with a full backup kept outside the repository.

| Check | Observed Time PDT | Result |
| --- | --- | --- |
| Preflight and candidate local suite | 2026-10-03 19:32 | Pass |
| Debian 13 socket | 2026-10-03 19:33-19:54 | T3-T12 Pass; interruption and invalid-ownership cleanup refusal checks passed; guest shut down and retained |
| Debian 13 TCP | 2026-10-03 19:56-20:01 | T3 Pass; terminated during Ansible installation |

At 20:01, coinciding with the tooling stopping the launching background task at its 30-minute limit, the driver's child processes were terminated and the driver recorded `ProcessLookupError` as its failure. This is an execution-environment termination, not an appliance or harness assertion failure; it remains a failure of this run. The context `m10-vm-run-65cf077-dca485f` and console log are retained unchanged. The driver shut down the Debian 13 socket guest after its case; the interrupted TCP guest was shut down through cloud-provision; both are retained. The remaining cases did not run.

###### VM Supply And Run Structure Local Verification

Observed on 2026-10-04 (times PDT) on the local Debian 13 host with the accepted revision implemented on top of fdbf1eccc6aa0c68553ecb17b9f68d3ece8a3d29. The driver offers `--init`, `--case`, `--verify-cleanup` and `--verdict`, calls no `create_vm.bash` action, adopts a guest from a JSON handoff, records a case only after its read-only identity, ownership and freshness checks pass, records any later error of that case as a run failure, checks the handed-off disk capacity against the configured `disk_size`, pins each guest's host key from the key cloud-provision stored at creation and connects through SSH and Ansible with strict host key checking, returns 77 without recording a failure when cleanup inspection fails, checks the digest of every guest verifier evidence file in the verdict, reads the stored tool origin URL, and clones for the publication proof without global or system git configuration. The later-error path and the refusal of an absent-source-commit, `OSError` or `TypeError` error before recording are verified by code reading only; reproducing them needs a live ownership change or a fault inside libvirt or the guest. The design document is `docs/README.vmtests.md`; `tests/README.md` keeps the execution and evidence procedures. Verified source SHA256: `tests/vm/driver.py` `454345b16a3cb873398f50447c0451ab1e79b9ea684632dbd4a29c91cf86fa11`, `tests/vm/guest.py` `755745bf1b5ab19ebbf6b7fcd4ae16d8130afa07e59cda720965bf0d287f2116`, `tests/vm/local.py` `db18b6bdf22926f986e2f0fb845e97209556037e960fa46e99ad454386a2f9f1`, `tests/run-all-tests.bash` `5c9e21a0b77afe7e9287da958763548273ac44a12e1f68af525746cf0598b9fb`.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T2 / full local suite, first run | 2026-10-04 00:47 | `tests/run-all-tests.bash --local` with the runner modes running the local phases as planned | Fail: `database-config.py` `test_system_entrypoints_cannot_report_success` timed out, because its `--system` call reran the local suite. Evidence: `vm-supply-local-20261004T074748Z.log`. The runner change recorded in item 5 followed |
| T2 / full local suite | 2026-10-04 03:09 | Same command after the runner modes stop without running checks | Pass: exit 0 without skips; Phase 1 223/0, health 20, database 10 and VM local 26 tests, Phase 2 13/0. Evidence: `vm-supply-local-20261004T100904Z.log`, SHA256 `bf8929aa43102b3e0d6b1f077433ea255f737cb7f21ca53022b936271f323007` |
| T2 / operations, handoff, origin, run rules | 2026-10-04 03:09 | The VM local tests within that suite: shipped CLI refusals, handoff validation with real files, case refusals, real `git` under an isolated `insteadOf` rule for the stored origin and the publication clone environment, the real fresh-guest probe script with real `systemctl`, real `ssh-keygen` lookup of a hashed stored host key, cleanup verification against a failing `virsh` executable, and order-independent read-only verdicts that refuse changed guest evidence | Pass |
| T2 / regression strength | 2026-10-04 03:09 | Scratch copies of the verified driver with the earlier exact-order verdict, the earlier `remote get-url` origin read, no case-rerun refusal, the inherited git configuration for publication clones, the earlier three-action evidence check, `accept-new` host key checking, a recorded cleanup inspection failure, no Ansible host key checking variable, or a schema check that accepts `true` | Each targeted regression fails on its mutant and the original passes. Evidence: `vm-supply-mutation-20261004T100920Z.log`, SHA256 `65170f5c488d3e7bd08335b91b713d228647c77eb89e631e31f46f9fdcdbaf09` |
| T2 / real `--init` path | 2026-10-04 02:20 | Shipped `--init` of driver `db57f754853f63d82a1752e3b854995e3f1d8c200a59a3b2bcbfef7a6be1fce8`, before the disk capacity check, under the user's real git configuration with a global `insteadOf` rule, the pinned tool clones and published candidate `fdbf1eccc6aa0c68553ecb17b9f68d3ece8a3d29` in a scratch evidence path; git tracing to a file | Stored HTTPS origins pass; all four publication clones use `git-remote-https` with no SSH URL; the run is refused with status 2 because the published candidate lacks these driver bytes, and no failure is recorded. No guest is contacted. Evidence: `vm-supply-init-trace-20261004T092207Z.log` |
| T3 / disk capacity | 2026-10-04 02:32 | Shipped `capture_ownership` of driver `58858f74c0c78f87ce393c94a0b035a8a523041530c14358abc1ef112f7bdec0`, whose method is unchanged in the verified bytes, with read-only `virsh` on the retained shut-off Rocky 8.10 SQLite diagnostic guest, configured `disk_size` 20G and a wrong 30G | 20G passes the capacity check and stops at the absent lease of the shut-off guest; 30G is refused at the capacity check. Evidence: `vm-supply-capacity-20261004T093238Z.log` |
| T3 / stored host key | 2026-10-04 02:56 | Shipped `pin_host_key` of driver `69452348cb2b7b798da61e414bf40900f9037de289159b132f98effe1a8d547a`, whose method is unchanged in the verified bytes, in a scratch run context against the user's real `~/.ssh/known_hosts`, for the retained Rocky 8.10 SQLite diagnostic guest's address and for an unused documentation address | The guest's three stored keys are copied into a mode 0600 file; the unused address is refused with no file written. No guest is contacted. Evidence: `vm-supply-hostkey-20261004T095641Z.log` |
| T3 / Ansible host key checking | 2026-10-04 03:08 | Real `ansible -m ping -vvvv` of ansible-core 2.19.11 under the pinned ansible-provision `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5` configuration, which sets `host_key_checking = False`, toward an unused documentation address, with the shipped `ansible_connection_variables` and with its host key checking variable removed | With the shipped variables, Ansible's SSH command carries only `StrictHostKeyChecking=yes`; without the variable it carries `StrictHostKeyChecking=no` before `yes`, so SSH would use `no`. No guest is contacted. Evidence: `vm-supply-ansible-hostkey-20261004T100839Z.log`, SHA256 `5888d59c54f2c8cb67e1b6dcc840698e152150b1c17366b4cf9d0feb05e8dac5` |

No guest was created or changed for these checks; only the disk capacity check read a retained guest's libvirt state, and the host key check read its stored key. The VM run on a published candidate remains pending under separate authority.

###### Earlier Guest Cleanup Inspection

By owner decision on 2026-10-04, cloud-provision removed all 19 shut-off `archiver-vm-test` guests of earlier M10 runs and diagnostics with `create_vm.bash -c` and each guest's own selectors, and reported every removal with exit 0. Their run contexts stay outside the repository as private records and are not resumed. epicsarchiverap-env then inspected the result independently and read-only, as revision item 7 requires.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| Removal of the 19 guests | 2026-10-04 15:08 | `virsh list --all`, the image directory, live and persistent `lab` network XML and `net-dhcp-leases`, matched against the 19 node selectors and the interface MACs recovered from retained run contexts and cloud-provision handoffs | Pass: no domain or image file names any of the nodes, and no reservation or lease carries any of the 17 recovered MACs or reuses their addresses. The two guests without a recorded MAC (the first two `607092b` diagnostics) rest on the absence of any `archiver-vm-test` reservation and on the cloud-provision report. Evidence: `earlier-guests-cleanup-inspection-20261004T220829Z.log`, SHA256 `85ae6a8f367e2a4c1be7e8f97fe35dc7686c98a10bb9dfc4d63b3757a74c28b6` |
| Removal of the leftover file set | 2026-10-04 15:13 | The same inspection found a disk, seed and creation record without a domain for one Debian 13 node of the failed `607092b` context, whose creation stopped at an address collision. By owner decision on 2026-10-04, cloud-provision removed them with `create_vm.bash -c` and its selectors, exit 0; no reservation existed. Re-inspected with `virsh list --all`, the image directory and both `lab` network XML forms | Pass: no domain, image file or `archiver-vm-test` reservation remains. Evidence: `leftover-cleanup-inspection-20261004T221307Z.log`, SHA256 `62d2b5e665b9a0a891fb3907ff9f6e160baf8cc57542ab89eb9266233022d2a1` |

###### VM Acceptance Run On f8c457e

Run context `m10-vm-run-f8c457e-dca485f`, opened on 2026-10-04 with `--init` on published environment `f8c457eec76184d5d12366923cd7b3c511d5bce0` (implementation `9dcf72996d10a6fd3c1d3712088900c0ac6fce1d`), source `dca485fd28d14cf91e988fae9ade13729a55c7ee`, pinned Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5` and cloud-provision inventory generator `a29f4773c14274b447cb66f4b9ab11f4cc1f8583`. cloud-provision created each guest at its commit `8308105fc59c4e356ac2b51a924a627d6e51159c`. Each case ran as a user unit. The run holds a failure and accepts no further case; a new run is required after M46.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T1 / run initialization | 2026-10-04 15:42 | `--init`: publication clones, candidate full `--local` suite, baseline of 15 domains and 15 live and persistent reservations | Pass |
| `debian13-socket` | 2026-10-04 16:06 | First positive case, including the interruption and cleanup-refusal checks | Pass: T3-T12; interruption and refusal verified |
| `debian13-tcp` | 2026-10-04 16:30 | Started while the first guest remained owned and present | Pass: T3-T12; the T15 precondition is recorded |
| `debian13-sqlite` | 2026-10-04 16:52 | Debian 13 SQLite | Pass: T3-T13 |
| `rocky8-socket` | 2026-10-04 17:06 | Rocky 8.10 MariaDB socket | Fail at T11 after T3-T10 passed. About 0.4 s after `make sd_restart`, the shipped health reported mgmt and engine `FAIL wrong-java-executable`. The same PIDs ran Java afterwards and health then reported PRESENT. The launcher writes the PID of the backgrounded `run.sh` before the shell chain executes Java, and the verifier does not treat that window as startup (M46). Evidence: `command-01027.json` in the run context; `rocky8-socket-restart-race-20261005T004541Z.log`, SHA256 `35688cefd4f5d87afa3a78f0c0e14dfdebeb0170e8e170787c62c790b10a6da8` |

The remaining four cases did not run. By owner decision on 2026-10-04, cloud-provision removed the four guests of this run with `create_vm.bash -c` and reported four removals, each confirmed against the recorded UUID first. The driver's `--verify-cleanup` on this context then returned PASS at 19:04 PDT: every owned domain, disk, seed, creation record and reservation is absent, and the 15 baseline domains and reservations are preserved; the two domains added to the host since the baseline belong to another session. The run keeps its recorded failure. Evidence: `f8c457e-run-verify-cleanup-20261005T020411Z.log`, SHA256 `bb632ef45c2f360b0c408af5542e246b1d34de2e5e288e03c3f86976e4bb447a`; `cleanup.json` in the run context, SHA256 `982738a7bb74fb698e1252d84b808dff34b38564da414054a55437e7571a722e`.

###### VM Acceptance Run On 933b2d8

Run context `m10-vm-run-933b2d8-aa953a4`, opened on 2026-10-04 with `--init` on published environment `933b2d875b7cc3733485644a9315d6643ef00333`, which carries the M46 implementation, source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` under D39, pinned Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5` and cloud-provision inventory generator `a29f4773c14274b447cb66f4b9ab11f4cc1f8583`. cloud-provision created each guest at its commit `8308105fc59c4e356ac2b51a924a627d6e51159c`, one guest per request after the previous case ended. Each case ran as a user unit. The run holds a failure and accepts no further case; a new run is required.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T1 / run initialization | 2026-10-04 20:10 | `--init`: publication clones, candidate full `--local` suite, baseline of the host's domains and reservations | Pass; local suite proof in `command-00017.json` of the run context |
| `debian13-socket` | 2026-10-04 20:14-20:33 | Fresh Debian 13 guest, MariaDB socket | Pass: T3-T12 |
| `debian13-tcp` | 2026-10-04 20:36-20:54 | Fresh Debian 13 guest, MariaDB TCP | Pass: T3-T12 |
| `debian13-sqlite` | 2026-10-04 20:57-21:15 | Fresh Debian 13 guest, SQLite | Pass: T3-T13 |
| `rocky8-socket` | 2026-10-04 21:18-21:34 | Fresh Rocky 8.10 guest, MariaDB socket; the case that failed at T11 on f8c457e | Pass: T3-T12 |
| `rocky8-tcp` | 2026-10-04 21:36-21:52 | Fresh Rocky 8.10 guest, MariaDB TCP; cloud-provision substituted the node label `test-933b2d800000000a` because the requested label mapped to an address reserved by another session's shut-off guest, and the handoff carries the substituted label | Pass: T3-T12 |
| `rocky8-sqlite` | 2026-10-04 21:54-22:10 | Fresh Rocky 8.10 guest, SQLite; node label substituted by `test-933b2d8000000011` for the same reason | Pass: T3-T13 |
| `debian13-build-failure` | 2026-10-04 22:12-22:18 | Fresh Debian 13 guest; installation with an absent source commit | Fail at T14 after T3 passed. The build failed at the real checkout (`make clone` error 128, one failed Ansible task), but the guest's git 2.47.3 printed `fatal: unable to read tree (<commit>)`, which the check's message list did not contain. Evidence: `command-01984.json` and `command-01985.json` in the run context |

The six positive cases passed T11 with health polled immediately after `sd_restart`, including all three Rocky 8.10 cases, and T8 passed on each Rocky 8.10 case. The verifier keeps the retried health output only when readiness expires, so no `STARTING` or `wrong-java-executable` output was retained; the passes do not record how long health reported `STARTING`.

The T14 message list was corrected in `054f1e2bb8a7fadb03618d4ed1519f0e76d82003`: the recognized messages are one constant, and a regression runs the real host git (2.47.3) checking out an absent commit in a path clone and in a `file://` clone. With the old list the regression fails on the real output and with the corrected list it passes; the full `--local` suite exited 0 without skips (Phase 1 223/0, new health 32/0, VM local 31 tests, Phase 2 13/0). Evidence: `t14-absent-ref-local-20261005T065622Z.log`, SHA256 `9fdea6eecea871e8476b869053fc731851046c09aeae272c41b02e560b96335d`. The Rocky 8.10 message for an absent commit has not been observed.

By owner decision on 2026-10-05, cloud-provision removed the seven guests of this run with `create_vm.bash -c`, each confirmed against the recorded UUID first, and cleared their stored host keys. The driver's `--verify-cleanup` returned PASS at 00:01 PDT: every owned domain, disk, seed, creation record and reservation is absent and the baseline is preserved. The current tree's driver refused the context (`Context belongs to another driver version`, exit 2, SHA256 `0b3780b2b5564734601bf469e0ec965b4de10199fe16b55f40b4b9ce90d1df8b`) because the T14 correction changed `tests/vm/driver.py`, so the check ran from the `933b2d8` tree that opened the run, exported with `git archive`. `--verdict` on the same context exited 1 (FAIL). Evidence: `933b2d8-run-verify-cleanup-20261005T070152Z.log`, SHA256 `ba6c1ca0135a73539dcaff27a3a9d5e36ec198413b776db9dda765c1bf33aa03`; `933b2d8-run-verdict-20261005T070157Z.log`, SHA256 `4f8e9e45f8a9e1843b81eaf3bdf52a6b778d415d23bf985774a9d34a43f69bd5`.

###### VM Acceptance Run On e441d59

Run context `m10-vm-run-e441d59-aa953a4`, opened on 2026-10-05 with `--init` on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770` (implementation of `054f1e2bb8a7fadb03618d4ed1519f0e76d82003`, which carries M46 and the T14 message correction), source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8` under D39, pinned Ansible `b8823c1c95c71c0eaea28e1fc292fdf18aa939e5` and cloud-provision inventory generator `a29f4773c14274b447cb66f4b9ab11f4cc1f8583`. cloud-provision created each guest at its commit `8308105fc59c4e356ac2b51a924a627d6e51159c`, one guest per request after the previous case ended, with uncommitted work only in its register and definition files while `bin/create_vm.bash` and the scripts it sources matched that commit. Each case ran as a user unit.

| Check | Observed Time PDT | Actual Environment And Method | Result And Evidence |
| --- | --- | --- | --- |
| T1 / run initialization | 2026-10-05 00:06-00:08 | `--init`: publication clones, candidate full `--local` suite, baseline | Pass |
| `debian13-socket` | 2026-10-05 00:09-00:30 | Fresh Debian 13 guest, MariaDB socket | Pass: T3-T12 |
| `debian13-tcp` | 2026-10-05 00:31-00:53 | Fresh Debian 13 guest, MariaDB TCP | Pass: T3-T12 |
| `debian13-sqlite` | 2026-10-05 00:55-01:20 | Fresh Debian 13 guest, SQLite | Pass: T3-T13 |
| `rocky8-socket` | 2026-10-05 01:28-01:58 | Fresh Rocky 8.10 guest, MariaDB socket; cloud-provision substituted the node label `test-e441d59000000014` because the requested label's address was held by a running guest of another session | Pass: T3-T12 |
| `rocky8-tcp` | 2026-10-05 02:00-02:25 | Fresh Rocky 8.10 guest, MariaDB TCP | Pass: T3-T12 |
| `rocky8-sqlite` | 2026-10-05 02:33-02:54 | Fresh Rocky 8.10 guest, SQLite | Pass: T3-T13 |
| `debian13-build-failure` | 2026-10-05 02:56-03:10 | Fresh Debian 13 guest; installation with an absent source commit | Pass: T3, T14; git 2.47.3 printed `unable to read tree` |
| `rocky8-build-failure` | 2026-10-05 03:24-03:42 | Fresh Rocky 8.10 guest; the same fault; cloud-init on this guest was slower than usual and its readiness wait retried 26 of 61 attempts | Pass: T3, T14; git printed `reference is not a tree` |

cloud-provision removed the eight guests with `create_vm.bash -c` and reported eight removals, each confirmed against the recorded UUID first. The driver's `--verify-cleanup` then returned PASS: every owned domain, disk, seed, creation record and reservation is absent, and the baseline is preserved. `--verdict` returned PASS (exit 0). The verifier keeps retried health output only when readiness expires, so this run recorded no `STARTING` window. Evidence: `e441d59-run-verify-cleanup-20261005T145533Z.log`, SHA256 `ba6c1ca0135a73539dcaff27a3a9d5e36ec198413b776db9dda765c1bf33aa03`; `e441d59-run-verdict-20261005T145533Z.log`, SHA256 `c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431`.

##### Closure Evidence

- Complete on 2026-10-05: the accepted matrix passed in the run on published environment `e441d59fc4f2072032c3bdaf5895c20f131ab770` (all eight cases, independent `--verify-cleanup` PASS and `--verdict` PASS, subsection "VM Acceptance Run On e441d59"), the register record of that run is `067cb8455c485751d4a7fdbd32c8f66b01b125c2`, and #56 was closed as completed on 2026-10-05 at 15:08 UTC (`gh issue view 56 --repo jeonghanlee/epicsarchiverap-env` returned CLOSED, closedAt 2026-10-05T15:08:40Z).
- Not a closure record: the implementation `9dcf72996d10a6fd3c1d3712088900c0ac6fce1d` and its register record landed on `origin/release-2.0.1`; on 2026-10-05 at 01:12 UTC, `git fetch` and `git rev-parse origin/release-2.0.1` returned `f8c457eec76184d5d12366923cd7b3c511d5bce0`.
- Not a closure record: the Rocky 8.10 compatibility revision commit `65cf077b1230f61efdba817aa697483a79a3a5d5` landed on `origin/release-2.0.1`; on 2026-10-02 at 23:52 PDT, `git fetch` followed by `git rev-parse HEAD origin/release-2.0.1` returned that commit for both.

##### GitHub Projection

Title: Automate real VM installation and runtime tests
Labels: enhancement
GitHub Milestone: 2.0.1
Observed State: CLOSED
Observed Labels: enhancement
Observed Milestone: 2.0.1 / #7
Last Compared: 2026-10-05 at 15:09 UTC, `gh issue view 56 --repo jeonghanlee/epicsarchiverap-env`; CLOSED at 2026-10-05T15:08:40Z, enhancement, milestone 2.0.1, assignee jeonghanlee; the live title and body equal the revised draft and the closing comment records the matrix result.


#### G7 - ansible-provision reports the exact cause of the Rocky 8.10 journald gap

Origin: 2.0.1 / G7
GitHub Issue: none
Status: Complete

##### Summary

ansible-provision observed journal entries missing from `journalctl` output on Rocky 8.10 in its M22 soak and owns the cause under D38. Two measures exist: sequence numbers with no readable entry across all journal files of a boot, and lines missing in a concurrent burst test. Debian 13 with systemd 257 showed neither. The stage-1 report below establishes the cause as a reader defect, not lost writes. This gate blocks M45 until the reproducer and scanner reach epicsarchiverap-env for M45 / T1.

##### Completion Criteria

- A minimal reproducer without the appliance runs concurrent `systemd-cat` writers on fresh Rocky 8.10 and Debian 13 guests and compares emitted with read-back lines.
- The report gives, per guest, the systemd and kernel versions, writer count and rate, emitted and read-back counts, `__SEQNUM` holes, the `journalctl --verify` result and the rate-limit exclusion.
- The report states the loss threshold, or that loss occurs without concurrency, and shares the reproducer and sequence scanner for M45 / T1.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-10-04 14:11 PDT | Pending | ansible-provision replies by session message received before this time: its M22 record row "Rocky 8 journald unlinked entries" (2026-10-04T08:26:26Z) holds 9 and 39 missing sequence numbers by passive scan, 16 on a third guest, and 65-137 lines lost per run in a 903-request two-worker burst test with one worker losing none; Debian 13 lost none in four runs. It proposes stage 1 alone first; its owner has not yet authorized execution. Recheck by asking ansible-provision for its stage-1 report. |
| 2026-10-04 15:35 PDT | Pending | Stage-1 report and follow-up by ansible-provision session message. On systemd 239-82.el8 (kernel 4.18.0-553.el8_10), `journalctl` hides an entry whose boot ID, realtime timestamp and content hash equal those of the entry it just returned, without comparing the sequence number (`sd-journal.c` `compare_with_location()` and `journal-file.c` `journal_file_compare_locations()` of v239). journald stamps the lines of one stdout read with one timestamp, so identical lines in a burst collapse to one visible entry per timestamp. The entries are stored: `journalctl --verify` passes and systemd 257 reading a copy returns all of them. One writer of 5,000 identical lines: 295 visible on Rocky 8.10, 5,000 when the same file is read with systemd 257, 5,000 on Debian 13 (257.9). Distinct lines, 1 to 16 writers, widths up to 2000, rate limiting disabled with no Suppressed record: none hidden in 18 runs. The earlier 65-137 burst figure and 9/39/16 sequence holes are this reader defect. Upstream fix: systemd commit b17f651a17cd6ec0ceac7835f2f8607fbd9ddb95, "journalctl: don't skip the entries that have the same seqnum" (2020-12-10, read back through the GitHub API), first released in v248; the latest Rocky 8.10 update `systemd-239-82.el8_10.19` still shows 295 of 5,000. The reproducer and scanner are private to ansible-provision and are sent when M45 / T1 starts. |
| 2026-10-04 18:04 PDT | Complete | Status reply by ansible-provision session message. Its owner chose header accounting for the soak: an unreturned sequence number is recorded, and every collection requires one stored entry per sequence number across fully retained journal files, read from the file headers (its local commits `28d433e` tools and `83b7744` record, not yet pushed). Header accounting found every unreturned number stored: 112,641 entries for sequence 1-112,641 on the appliance guest, and 944,713 for the retained range on the reproduction guest; 20 runs under continuous 903-request bursts passed. Tools shared for M45 / T1, present on this host: `journald-burst-repro.py` and `journal-gap-union.py` under `/data/gitsrc/ansible-provision/work/soak-etl-pass-3bdf378c/`, and the header functions in `tests/archiver-soak/etl-pass/journal_coverage.py` at `28d433e`. |

##### Closure Evidence

- The completion criteria hold: the reproducer ran on Rocky 8.10 and Debian 13 with the per-guest counts above, the cause is a systemd 239 reader defect rather than lost writes, and the reproducer and scanner are shared for M45 / T1.

#### G8 - epicsarchiverap-maven reports the exact cause of the CAJ search-port defect

Origin: 2.0.1 / G8
GitHub Issue: none; tracked in [epicsarchiverap-maven#26](https://github.com/jeonghanlee/epicsarchiverap-maven/issues/26)
Status: Complete

##### Summary

The engine creates one CAJ context per CA command thread, ten by default. On one fresh Rocky 8.10 engine, two contexts shared one UDP search port, and the 95 PVs of one context never connected. It was observed once in about ten deployments. The working hypothesis is that the kernel gives two `SO_REUSEADDR` sockets bound to port 0 the same port. epicsarchiverap-maven owns the cause under D38. The defect affects only CA channel connection, not logging. This gate blocks M45.

##### Completion Criteria

- A standalone reproducer opens ten datagram channels as CAJ does, repeats about 10,000 rounds with and without `SO_REUSEADDR`, and counts duplicate ports on a Rocky 8.10 guest and on Debian 13.
- Repeated engine starts on a Rocky 8.10 guest with the default ten command threads record `ss -uanp` of the engine JVM and connected PV counts per thread; at least 30 starts, or fewer once three occurrences are recorded.
- The report gives the reproducer source or commit, kernel and JDK versions, round and start counts, and the location of the raw `ss` outputs, as a #26 comment and register M43 of epicsarchiverap-maven.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-10-04 14:11 PDT | Pending | `gh issue view 26 -R jeonghanlee/epicsarchiverap-maven` returns OPEN, updatedAt 2026-10-04T20:32:40Z. epicsarchiverap-maven proposes stage 1 alone first and awaits its owner's authorization; the stage-1 method, stopping rule and record above were agreed by session message. |
| 2026-10-04 14:24 PDT | Pending | Interim report by epicsarchiverap-maven session message, Debian 13 half only (kernel 6.12.111, OpenJDK 21.0.12, jca 2.4.12; probe not yet committed). Ten real CAJ contexts per round shared a search port in 11 of 10,000 rounds. Raw channels bound as CAJ binds them shared a port in 16 of 10,000 rounds with `SO_REUSEADDR` and 0 of 10,000 without it. In 3 of 3 shared-port trials, all 100 unicast datagrams reached the later-bound socket and none the earlier one. The mechanism is therefore not specific to kernel 4.18. The Rocky 8.10 probe and the engine-start correlation await a guest. |
| 2026-10-04 15:19 PDT | Complete | Stage-1 report in the [#26 comment](https://github.com/jeonghanlee/epicsarchiverap-maven/issues/26#issuecomment-5985074826) (created 22:19:30 UTC, read back by `gh api`), probe at epicsarchiverap-maven `b6ff8704`, their register M43 T1 in `20e9a133`. Probe, 10,000 rounds of ten sockets each: on Rocky 8.10 (kernel 4.18.0-553.el8_10, OpenJDK 21.0.12.1), real CAJ contexts shared a port in 17 rounds, raw channels in 18 with `SO_REUSEADDR` and 0 without; Debian 13 gave 11, 16 and 0. On both, unicast to a shared port reached only the later-bound socket. Engine on the epicsarchiverap-env deploy path (903 PVs, default ten command threads) on the same Rocky guest: 30 restarts, all 903 PVs connected in each, no shared port. Zero in 30 bounds the per-start rate at about 10% (95%), so the field rate of about one in ten deployments is neither reproduced nor excluded. |

##### Closure Evidence

- The completion criteria hold: the mechanism is confirmed outside the appliance on Rocky 8.10 and Debian 13, the engine correlation ran 30 starts, and the report with counts and identifiers is the #26 comment above. Why the field rate exceeds the probe rate stays open in epicsarchiverap-maven #26.

#### M45 - Contain the journalctl reader and CAJ search-port defects in VM acceptance

Origin: 2.0.1 / M45
Identity History: none
GitHub Issue: [#58](https://github.com/jeonghanlee/epicsarchiverap-env/issues/58)
Status: Complete

##### Summary

Two independent defects can change an M10 acceptance result. The journalctl reader defect (G7) is observed on Rocky 8.10 only; the CAJ search-port defect (G8) occurs on both Rocky 8.10 and Debian 13 kernels. T8 counts three scheduled health runs from journal success lines in `tests/vm/guest.py`, and systemd 239 `journalctl` hides an entry whose realtime timestamp and content equal those of the entry it just returned. Whether a health success line meets that condition is not yet measured. T10 and T11 check CA data from the archived PV, so the CAJ defect can fail them on either OS. A CAJ failure is a real appliance defect, not a harness error. M45 measures this exposure, records evidence that tells the causes apart, and, if the measurement shows exposure, changes the epicsarchiverap-env side so a correct installation does not fail on a hidden journal entry.

##### Scope

- T1: before the failed M10 run's guests are cleaned up, measure T8 exposure read-only on its installed Rocky 8.10 `rocky8-socket` guest, whose health timer has run since installation. Count the health-unit success entries that systemd 239 `journalctl` returns, and compare them with the same journal files read by a newer reader and with G7 header accounting.
- T2: retain classifying evidence on failure. On a T8 failure, keep the health-unit entries as read and the journal files for a newer reader; a sequence hole alone does not prove a lost entry on systemd 239. On a T10 or T11 failure on either OS, keep `ss -uanp` of the engine JVM and the connection status of the archived PVs. This changes `tests/vm/guest.py` together with M46.
- T3, only if T1 shows exposure: change how the verifier establishes T8 so that a hidden identical entry cannot fail a correct installation, and verify it on Rocky 8.10.
- The CAJ defect is handled at its source: under D39 the next M10 run uses an epicsarchiverap-maven commit that carries the CAJ correction, and M45 only keeps the evidence that would classify a recurrence.

Out of scope: fixing journalctl, CAJ or jca, which their owners do under D38; publishing a patch or reporting upstream, which D38 defers until the problem is resolved; changing the M10 acceptance matrix.

##### Completion Criteria

- M45 / T1 records the T8 exposure on Rocky 8.10 over a stated window with both readers and header accounting.
- M45 / T2 shows the shipped verifier retaining the classifying evidence through its real failure path, and the next M10 run carries it.
- M45 / T3 is required only when T1 shows exposure; it then shows T8 passing a correct installation on Rocky 8.10 while identical entries are hidden, and still failing when health runs fail.

##### Dependencies And Decisions

- D38 assigns this work and keeps every fix local; D39 sets the source that the next M10 run uses.
- G7 and G8 blocked M45 when it was created; resume as Not started. Both are Complete since 2026-10-04, so M45 resumed as Not started.
- M10's Rocky 8.10 cases are exposed to the journalctl reader defect, and every case was exposed to the CAJ defect before its correction. The owner has not set an order between M10, M44 and M45; M44's dependencies are unchanged.
- T1 reads the retained `rocky8-socket` guest of the failed run `m10-vm-run-f8c457e-dca485f` without changing it; that run's cleanup request waits until T1 is recorded. Any other guest comes from cloud-provision on a request under separate owner authorization.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-05; owner accepted the revised plan whose remaining work is T2 and whose T3 is not required
Implementation Authorization: 2026-10-05; owner authorized implementation of this accepted plan and its local verification; commit, push, publication, any VM run and every guest request need separate authority
Superseded Plan Artifacts: draft of 2026-10-04 with a fresh-guest T1 and an unconditional T3, carried by 36b17908531bc06863f47c20fa96842581a9b782, docs/milestone-2.0.1.md, M45

1. On the retained `rocky8-socket` guest, copy the journal files read-only to private evidence, count health-unit success entries with the guest's systemd 239 `journalctl` and with a newer `journalctl` over the copy, and run G7 header accounting over the same files.
2. In `tests/vm/guest.py`, add `retain_failure_evidence(action, error)` and call it from the failure handler of `main()` before the failed-evidence file is written. It never masks the original failure: an error inside the retention is recorded as `retention_error`. The failure is classified by a `CheckError` subclass that carries an evidence kind, raised at the final raise of `scheduled()` (journal) and at the acquisition deadline and the CA comparison of `acquire()` and `compare()` (CA). Journal kind: keep the health-unit entries as the guest's `journalctl` returned them (`-o json`, since the check began) in the failure evidence, and copy the journal directories (`/var/log/journal`, `/run/log/journal`) into a private `journal-copy` directory of the case root for a newer reader, recording file names and sizes. CA kind: keep the `ss -uanp` lines of the engine JVM and the management status of the test PV and of the currently disconnected PVs; the exact management endpoints are confirmed on the real guest in step 4.
3. In `tests/vm/local.py`, add a regression that calls the shipped failure handler with the real host `journalctl`, `ss` and `cp` and a temporary journal directory: each kind produces its evidence names and files, a failing retention command leaves the original failure and its category intact, and with the retention disabled the regression fails. It stays Python because the code under test is Python (D41); it is kept small.
4. Run the shipped retention commands on a fresh Rocky 8.10 guest (systemd 239) and a fresh Debian 13 guest of a VM run on the published candidate, by calling `retain_failure_evidence` directly over SSH as in the M46 measurement, to confirm the commands and the management endpoints on both OS; this does not force an acceptance failure.
5. T1 showed no exposure, so no T8 revision is planned; it returns only if the retained evidence of a later failure shows a hidden health entry.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | System | Read-only count of health-unit success entries by systemd 239 and by a newer reader over copies of the same journal files, plus G7 header accounting | Retained installed Rocky 8.10 guest of the failed M10 run | Hidden health-unit entries counted over a stated window; zero means T8 is not exposed |
| T2 | Local and system | Local regression through the shipped failure handler with real `journalctl`, `ss` and `cp`; then the shipped retention on a real guest of each OS | Local host; fresh Rocky 8.10 and Debian 13 guests of a VM run on the published candidate | The failure evidence names the health-unit entries and the journal copy, or the engine JVM's UDP sockets and the PV status, and a retention error never hides the original failure |
| T3 | System | Only if T1 shows exposure: T8 with identical entries hidden under the G7 reproducer, and with a failing health run | Fresh Rocky 8.10 guest | Correct installation passes; a failing health run still fails T8 |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-04 18:59 PDT | Retained installed Rocky 8.10 `rocky8-socket` guest of the failed M10 run, systemd 239-82.el8_10.19, kernel 4.18.0-553.el8_10; its journal files copied read-only and read by host systemd 257.13 | Pass | Health unit entries until 2026-10-05 01:57:00 UTC: the guest's 239 `journalctl` and 257 over the copy both return 2,880 entries, 220 of them health success lines with 220 distinct invocations, over a 114-minute window with gaps of 30.2 s minimum, 31.0 s median and 91.9 s maximum; no health entry is hidden. Whole journal: 239 returns 12,122 entries and 257 returns 12,123; the one entry only 257 returns is an `[INFO]` line of `archiver-build.sh`, a repeated short line of the build unit, and 239 returns no entry that 257 does not. The reader defect is therefore present on the real appliance guest but did not touch the health unit. The 5 non-success invocations are four startup-allowance SKIPs and one oneshot start without an invocation id. G7 header accounting was not run, because comparing the two readers by journal cursor counts the hidden entries directly. Evidence: `m45-t1-journal-reader-exposure-20261005T015917Z.log`, SHA256 `4169db729a89fdb93b1eb5c137cf48aba09c9f8ae8b716cdd8abfc5aaf91ace2`; journal copy `rocky8-socket-journal-20261005T015749Z` |
| T2 | 2026-10-05 10:45 | Local host; the shipped `Guest.fail` and `retain_failure_evidence` in `tests/vm/guest.py` run by `FailureEvidenceTests` in `tests/vm/local.py` with the real host `journalctl`, `ss` and file copy, a real UDP socket of the test process and a local HTTP server as the management transport | Pass | Journal kind keeps the health-unit entries and copies the journal files byte for byte; CA kind keeps the engine process's UDP sockets from `ss -uanp` and the management PV status and disconnected-PV list; a retention fault is recorded without hiding the original failure and its category; an unclassified failure keeps nothing. Each of five broken variants (retention skipped, retention fault propagating, journal files not copied, engine sockets not selected, every failure classified) fails its targeted test and the shipped code passes. Full `--local` suite exit 0 without skips: Phase 1 223/0, health 20, new health 32/0, database 10, VM local 36 tests, Phase 2 13/0. Verified source SHA256: `tests/vm/guest.py` `86721baca6d162e1e718a9de5b4699e747ea7a33facc3764b6d86e696bc05e44`, `tests/vm/local.py` `b0947d273551b0594c231d8ae82e454c8be9b314899930a3c597296cbdbf1f7f`. Evidence: `m45-t2-local-20261005T174521Z.log`, SHA256 `5558d4a8a283bce63466ebbad70a7510e0bc3b724d0a5e335f1ea4eed460a11f`; `m45-t2-mutation-20261005T174552Z.log`, SHA256 `16d1e9c65085afbf7854a45652ab1f5e6dd49fe5d8b3894549c870af58aaa5a7`. Real guests, plan step 4: after both cases of the two-case run `m10-vm-run-da11815-aa953a4` on published environment `da1181580e74a9b8e7b09f78f2cfad2c3d62fb31` passed, the shipped `retain_failure_evidence` was called directly over SSH for both kinds on each retained guest. Rocky 8.10 (Python 3.9, systemd 239): the journal kind kept 255 health-unit entries and two journal files of about 24 MiB without a retention error; the CA kind kept 13 UDP sockets of the engine JVM from `ss -uanp` and the answers of `getPVStatus` and `getCurrentlyDisconnectedPVs`, which listed the test PV as disconnected after the IOC stopped. Debian 13 (Python 3.13, systemd 257): 213 entries, two journal files of about 16 MiB, 13 UDP sockets and the same two answers, also without a retention error. Both endpoints and all commands work on both OS. Evidence: `m45-t2-retention-rocky8-20261005T181721Z.log`, SHA256 `d0b5d4c58402952915850303245fa0198f52c38edfe67f1a818e3f167a7deb6a`; `m45-t2-retention-debian13-20261005T184337Z.log`, SHA256 `22c012a0da89a97bf4f53519d0e00f79458c0a7457c0415e68705a1a9f072201`. The two guests were then removed by cloud-provision and the driver's `--verify-cleanup` returned PASS (owned resources absent, baseline preserved), while `--verdict` returned INCOMPLETE (exit 77) as expected for a two-case run: `da11815-run-verify-cleanup-20261005T193732Z.log`, SHA256 `ba6c1ca0135a73539dcaff27a3a9d5e36ec198413b776db9dda765c1bf33aa03`; `da11815-run-verdict-20261005T193740Z.log`, SHA256 `724885aebf2a73cd857ccd11264ee43e58a832797960b89e039fe9fec9120b8a` |
| T3 | 2026-10-04 18:59 PDT | Conditional on T1 | Not required | T1 found no hidden health entry, so the T8 revision is not needed on this evidence. One guest and 114 minutes is a measurement, not proof for every run; T2 keeps the evidence that would show a hidden health line if one ever fails T8. |

##### Closure Evidence

- Complete on 2026-10-05: T1 passed on 2026-10-04 and T3 was not required, the failure-evidence retention landed in `8db79df` on `origin/release-2.0.1`, T2 passed on real Rocky 8.10 and Debian 13 guests (the T2 row), and #58 was closed as completed on 2026-10-05 at 19:41 UTC (`gh issue view 58 --repo jeonghanlee/epicsarchiverap-env` returned CLOSED, closedAt 2026-10-05T19:41:13Z).

##### GitHub Projection

Title: Contain the journalctl reader and CAJ search-port defects in VM acceptance
Labels: bug
GitHub Milestone: 2.0.1
Observed State: CLOSED
Observed Labels: bug
Observed Milestone: 2.0.1 / #7
Last Compared: 2026-10-05 at 19:42 UTC, `gh issue view 58 --repo jeonghanlee/epicsarchiverap-env`; CLOSED at 2026-10-05T19:41:13Z, bug, milestone 2.0.1, assignee jeonghanlee; the live body equals the final draft with the three Acceptance Criteria boxes checked, and the closing comment records the result.

#### M46 - Report a starting instance distinctly in the launcher health check

Origin: 2.0.1 / M46
Identity History: none
GitHub Issue: [#59](https://github.com/jeonghanlee/epicsarchiverap-env/issues/59)
Status: Complete

##### Summary

`service_start_instance` in `scripts/archappl.bash` starts `bin/run.sh` in the background and writes its `$!` to the instance PID file at once. That PID is still the shell until `run.sh` executes `catalina.sh run` and `catalina.sh` executes Java. A health check in that window finds the PID file and a live process whose executable is not Java, and `health_process_identity` reports `wrong-java-executable` as FAIL. A direct `archappl.bash health` call right after a start or restart therefore fails on a correct installation for a fraction of a second. The scheduled `--systemd` mode is not exposed: it skips for the first `SYSTEMD_HEALTH_STARTUP_SECONDS` (60) seconds after the appliance unit starts, which covers the window, and the first scheduled runs of the failed guest show `SKIP startup-allowance`. The exposed callers are an operator running `health` by hand and the VM verifier. The M10 VM run on f8c457e hit it at T11 on Rocky 8.10 through the verifier's direct call. The verifier retries only `missing-pid-file`, `missing-process` and `dead-process` during startup, within its bounded readiness deadline.

##### Scope

- Under D40, change both places. The launcher health reports a starting state for a PID that has not yet executed Java. The VM verifier waits on that state and on `wrong-java-executable` within its existing bounded readiness deadline and fails when either persists to that deadline.
- Keep `wrong-java-executable` and every other identity failure for a process that stays outside startup.
- Verdict, fixed by D42: an instance line `<name> pid=<pid> STARTING run-script` or `STARTING catalina-script`; `FAIL startup-timeout` once the process is older than the bound; an aggregate line `health STARTING instances-starting; application-readiness-not-checked`. Precedence is ERROR, FAIL, STARTING, PRESENT. `STARTING` exits 1, so the aggregation by largest status stays valid and the health unit, whose `SuccessExitStatus=3` treats skips as success, cannot mask a stuck wrapper in `--systemd` mode.
- Bound, fixed by D42: `${ARCHAPPL_HEALTH_STARTING_SECONDS:-10}`, validated like the storage threshold, with an invalid value reported as `ERROR starting-invalid-bound` and a value of 60 or more refused because it must stay below the scheduled startup allowance. The process age comes from its `/proc` start time, which `exec` keeps.
- Instance signals, observed in a scratch chain of the same shape on a Linux 6.12 host and read by the same user: in the `run-script` stage the second command-line word resolves to `<base>/bin/run.sh` and the environment does not yet carry the instance, because the exports happen after `bash` starts; in the `catalina-script` stage the command line is `<CATALINA_HOME>/bin/catalina.sh run` with no instance, while `CATALINA_BASE` in `/proc/<pid>/environ` resolves to the instance base. Reading exe, command line and environment repeats up to three times when the executable changes between reads, and then reports `ERROR process-changed-during-inspection`. Not yet checked: a process of another user, where health already needs the same read access for `/proc/<pid>/exe`, and the Rocky 8.10 kernel and the shipped Tomcat chain. Evidence: `m46-instance-signal-check-20261005T021900Z.log`, SHA256 `df3433e8074529a8b80a49520aab51d75a7eaded75f8ed0326f47caae99458ca`.
- Update the operator documentation of the health verdicts.

Out of scope: changing when the launcher writes the PID file; changing Tomcat scripts; changing the health timer schedule.

##### Completion Criteria

- M46 / T1 shows the shipped launcher chain (`service_start_instance`, `run.sh`, `catalina.sh`) is polled by the real health while the PID is still a shell, reports the starting state, and then PRESENT. A hand-built shell standing in for the chain does not count.
- M46 / T2 shows `wrong-java-executable` still reported for a live process outside startup whose executable is not the configured Java, and a stuck wrapper is reported as a failure after the time bound.
- M46 / T3 shows the VM verifier passing restarts on Rocky 8.10 and Debian 13 guests with health polled immediately after `sd_restart`, and a persistent wrong executable still fails the check at the readiness deadline.

##### Dependencies And Decisions

- D40 sets the approach and D41 sets Bash for the new launcher tests and D42 fixes the verdict, exit status and bound. Plan review on 2026-10-04 found that scheduled health skips during the startup allowance, so only direct callers are exposed, and that a verifier-only retry with the existing bounded deadline would also fail a persistent wrong executable. The owner still chose both changes for stability and reliability.
- M10 depends on M46: its next run uses a candidate that carries this change.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-04; owner accepted the plan as revised by D40, D41 and D42 after plan review
Implementation Authorization: 2026-10-04; owner authorized implementation of this accepted plan and its local verification; commit, push, publication, the VM run and every guest request need separate authority
Superseded Plan Artifacts: draft with the approach left open between a verifier-only change, a launcher change and both, carried by 3a7bcc9105afbe9d30eb0fcce8c632531a794804, docs/milestone-2.0.1.md, M46

1. Implement the starting verdict exactly as the Scope specifies, implement it in `scripts/archappl.bash`, and add the launcher regressions as a new Bash test under Phase 1 that uses `tests/lib/common.bash`, per D41, leaving `tests/health-local.py` unchanged.
2. In `tests/vm/guest.py`, add the starting verdict and `wrong-java-executable` to the startup tokens of `ready()`, with a small regression in `tests/vm/local.py` that executes the shipped retry path and shows a persistent wrong executable failing at the deadline; it stays Python because the code under test is Python (D41).
3. Document the verdict, and prove the result on real guests with T3.
4. Retain every retried launcher health output of `ready()` with its elapsed time in the readiness timing evidence of `tests/vm/guest.py`, so that T3 can record the observed `STARTING` window (added 2026-10-05 after the first M10 runs showed that a passing restart left no such record), with a local regression in `tests/vm/local.py`.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Integration | The shipped chain polled by the real health while the PID is still a shell, then after Java runs | Local host | Starting verdict, then PRESENT |
| T2 | Integration | Real health against a live process with another executable outside startup, and against a stuck wrapper past the time bound | Local host | `wrong-java-executable` FAIL; stuck wrapper FAIL |
| T3 | System | VM verifier restarts with health polled immediately after `sd_restart`, recording how long health reports `STARTING`, and a persistent wrong executable | Fresh Rocky 8.10 and Debian 13 guests | Restart checks pass; the recorded window is below the bound; the persistent wrong executable fails at the deadline |

##### Verification Results

Observed on 2026-10-04 (times PDT) on the local Debian 13 host, bash 5.2.37, with the accepted plan implemented in `scripts/archappl.bash`, `tests/vm/guest.py`, the new `tests/health-starting.bash` with its fixture `tests/fixtures/tomcat/org/apache/catalina/startup/Bootstrap.java`, `tests/vm/local.py`, `tests/phase1-logic.bash` and the two health guides. Verified source SHA256: `scripts/archappl.bash` `ca22bec9ef9a64b3848a71176e1f1c02f2b4afd1355d71f13b3f0f0282616c24`, `tests/health-starting.bash` `76b8da67f8fe2e376d1fffb8c8b9449504a1a46e28639fa47be60dd74f4bffc6`, `tests/vm/guest.py` `419103264fdf2c01c89783188ab324d13ca8188efc2e6997d43bd5dc3947cd15`, `tests/vm/local.py` `99180ec08352004775683411fd8344ce9d5415ba3bed8f6a6df27a0d6daf9f7c`. The local chain is the shipped `run.sh` rendered with the Make `sed`, a stand-in `catalina.sh` that holds and then executes a live JVM named like Tomcat's Bootstrap; real Tomcat and the shipped launcher start function are not exercised here, so the real-chain proof is T3. The `env` start stage of `#!/usr/bin/env bash`, which lasts under a millisecond, is handled by the code but not exercised; the verifier's retry of `wrong-java-executable` covers it.

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-04 19:41 | Local host; shipped launcher copied as installed, real `health`, shipped `run.sh`, stand-in `catalina.sh`, live Bootstrap-named JVM | Pass | `tests/health-starting.bash`, 32 checks inside the full suite: four live JVMs PRESENT; one PID reported `STARTING run-script`, then `STARTING catalina-script`, then PRESENT with the same PID; each starting verdict exits 1 with the aggregate `health STARTING instances-starting; application-readiness-not-checked`. Evidence: `m46-local-20261005T024120Z.log`, SHA256 `52f27dfccf368f63725aa223524aa44f0247cba4b3cd653bba31b85d07e20bfa`: exit 0 without skips, Phase 1 223/0, health 20, new health 32/0, database 10, VM local 29 tests, Phase 2 13/0 |
| T2 | 2026-10-04 19:39 | Local host; the same test against the launcher before the change and eight scratch mutants | Pass | `wrong-java-executable` is still reported for an unrelated executable and for the run.sh and catalina.sh shells of another instance; `FAIL startup-timeout` in both stages; a failure outranks a start; bounds 0, 60, `abc` and 1.5 give `ERROR starting-invalid-bound` and 59 is accepted. The old launcher and each mutant (starting exits 0, no timeout, run.sh stage ignores the instance, catalina.sh stage ignores the instance, start outranks failure, bound accepts 60, any process counts as starting, no bound validation) fail the targeted check and the shipped launcher passes. Evidence: `m46-launcher-mutation-20261005T023902Z.log`, SHA256 `bbbcb78e6a994306027c2206ecb2539a8c3563bc9f60d4e20bf6ca6fa3dbd2ec`. Verifier: `StartupHealthTests` in `tests/vm/local.py` runs the shipped retry logic against the retained real verdict text and the specified starting verdict; four mutants (no `STARTING` token, no `wrong-java-executable` token, retry of every failure, deadline error without the last verdict) each fail a targeted test and the shipped code passes. Evidence: `m46-verifier-mutation-20261005T024045Z.log`, SHA256 `2d3977b46c8bf0619ca3085e81a45edd2c3017d64a25d951958ebf98155f9e7d` |
| T3 | 2026-10-05 09:03-10:12 | Fresh Rocky 8.10 and Debian 13 guests of the two-case measurement run `m10-vm-run-b0df7e2-aa953a4` on published environment `b0df7e26bf5be681d07a42cb9e70e7c302441e6f` (verifier change `91945bd`), source `aa953a44bd2e6fb2a299224b97d365e7753a2fd8`; the guests are reachable only through the run's SSH identity | Pass | Both cases passed T3-T12, including the restart check T11 (`rocky8-socket` and `debian13-socket`); earlier matrix runs on `933b2d8` and `e441d59` also passed it on all six positive cases. The retained retry list of each passing restart was empty because the first health after `sd_restart` was already PRESENT, so the window was measured by polling the shipped health continuously around six `make sd_restart` runs per guest, run by hand over SSH as a diagnostic with the shipped launcher. Rocky 8.10: no `wrong-java-executable` in about 1,170 samples; one `STARTING catalina-script` sample, a window below 0.54 s; every instance PRESENT again within 0.21-0.70 s of the first non-PRESENT sample. Debian 13: no `wrong-java-executable` in about 700 samples; one `STARTING catalina-script` sample, a window below 0.16 s; PRESENT again within 0.24-1.01 s. All are below the 10 s bound; the sampling interval was about 0.05 s and reached 4.4 s on Rocky while `make` ran, so each value is an upper bound. Persistent wrong executable on the Debian guest: a non-Java process of the service account written to the management PID file makes direct health report `FAIL wrong-java-executable`, and the shipped verifier `ready(20)` failed after 21.2 s with `Application readiness deadline exceeded; last health: ... wrong-java-executable` and ten retained observations; the PID file was restored and health returned PRESENT. A first attempt with a root-owned process gave `ERROR unreadable-process-executable`, which is not a retried verdict, and is not cited. Evidence: `m46-starting-window-rocky8-rounds-20261005T163302Z.log`, SHA256 `e27696dc1278bcfd1a4021fb3c14a99da80f22c6334bca47b0982cb82b5458c9`; `m46-starting-window-debian13-rounds-20261005T170436Z.log`, SHA256 `4b0f56561cf617cc99b6fee71980519434b8109e32e09fb956b9cd007adaa2ad`; `m46-persistent-wrong-executable-debian13-20261005T170821Z.log`, SHA256 `7fbcfdd607bb5fc9676aae57eb2f727ed0addd127a7eb046630095bb2c8ba81d`. cloud-provision then removed both guests with `create_vm.bash -c`, and the driver's `--verify-cleanup` returned PASS (owned resources absent, baseline preserved); `--verdict` returned INCOMPLETE (exit 77), as expected for a two-case run that is not a matrix acceptance: `b0df7e2-run-verify-cleanup-20261005T172116Z.log`, SHA256 `ba6c1ca0135a73539dcaff27a3a9d5e36ec198413b776db9dda765c1bf33aa03`; `b0df7e2-run-verdict-20261005T172117Z.log`, SHA256 `724885aebf2a73cd857ccd11264ee43e58a832797960b89e039fe9fec9120b8a` |
| T3 / retention | 2026-10-05 08:18 | Local host; `tests/vm/guest.py` retains each retried health output with its elapsed time in the readiness timing evidence | Pass (local only) | `StartupHealthTests` in `tests/vm/local.py` (4 tests): two retried verdicts are retained in order with their text and elapsed time, and with the retention disabled the new test fails (`0 != 2`). Full `--local` suite exit 0 without skips: Phase 1 223/0, health 20, new health 32/0, database 10, VM local 32 tests, Phase 2 13/0. Evidence: `startup-window-local-20261005T151841Z.log`, SHA256 `27995c64cb8b43e9f0622b3376498e7f836313a57d17965ab8b594bd95fc6deb`. The retained window is recorded on real guests only by the next VM run |

##### Closure Evidence

- Complete on 2026-10-05: the launcher change and its Bash test landed in `c8dfe50` and the verifier evidence retention in `91945bd`, both on `origin/release-2.0.1`; T1, T2 and T3 passed (the real-guest results are in the T3 row), and #59 was closed as completed on 2026-10-05 at 17:27 UTC (`gh issue view 59 --repo jeonghanlee/epicsarchiverap-env` returned CLOSED, closedAt 2026-10-05T17:27:00Z).

##### GitHub Projection

Title: Report a starting instance distinctly in the launcher health check
Labels: bug
GitHub Milestone: 2.0.1
Observed State: CLOSED
Observed Labels: bug
Observed Milestone: 2.0.1 / #7
Last Compared: 2026-10-05 at 17:28 UTC, `gh issue view 59 --repo jeonghanlee/epicsarchiverap-env`; CLOSED at 2026-10-05T17:27:00Z, bug, milestone 2.0.1, assignee jeonghanlee; the live title and body equal the final draft with the three Acceptance Criteria boxes checked, and the closing comment records the result.

#### M13 - Rework the management web interface and its site skin

Origin: 265f580 / M13
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; transferred from Backlog to Milestone on 2026-10-09 under D45; ID and Origin preserved
GitHub Issue: none
Status: Complete

##### Summary

The management web interface is a set of pages built on jQuery 1.8.2 and jQuery UI 1.9.1: a fixed header, a navigation
bar of Home, Reports, Metrics, Storage, Appliances and Integration, and tables whose statuses and columns carry no
explanation in the interface. An operator enters signal names by hand and looks them up page by page.

This work redesigns the interface as a whole: page structure and navigation, visual design, icons, explanatory text for
statuses and tables, mobile browsing, signal search, and the data browser that plots archived data. The site skin in
`site-template/siteid` is part of it.

The pages, scripts and navigation are owned by epicsarchiverap-maven. While that repository runs its other tests they are
prepared in this repository and then transferred to it. `site-template/siteid` stays owned by this repository.

##### Scope

- `site-template/siteid/{css,img,template_changes.html}` and the `copy.sitespecific` step in `configure/RULES_SRC`.
- The page markup, scripts and navigation of the management interface that epicsarchiverap-maven owns, prepared in this
  repository at a location the plan defines, with the procedure that builds and checks them here.
- Signal search in the browser: an index of the archived PV names kept in the browser, with search, grouping by name
  structure and filtering by status.
- The data browser that opens from the management pages, replacing the vendored SVG viewer, keeping its
  `ui/viewer/archViewer.html?pv=` address working.
- The transfer of the prepared files to epicsarchiverap-maven after they are checked here.

Out of scope: changes to the server code, its API contracts and appliance behavior (D46); the EPICS-Arche runtime;
release verification of 2.0.1, which M44 owns.

##### Completion Criteria

- The redesigned pages render and operate in the real appliance built from the prepared files at desktop width and at a
  390 px mobile width, including the status table, the dialogs, the reports, signal search and the data browser,
  without horizontal page scrolling.
- The detail charts and the sparkline list are capped at the values confirmed by T11 (D47), and the interface states a cap when it is reached.
- Every view follows the data-ink rules of D48, checked by T12.
- The pages work in the current releases of Firefox, of Edge and of WebKitGTK (the engine of Safari), use only
  web-standard features, and pass the security checks of T8.
- The files owned by epicsarchiverap-maven are transferred to it and its CI passes at the resulting commit, with the
  commit recorded here.
- This repository's site skin renders correctly on the transferred interface.

##### Dependencies And Decisions

- Decision Date: 2026-10-09. D46 keeps the server code unchanged for now and names the supported browsers. D47 sets the
  plotting limits and response targets, replacing the cap of D46, D48 sets the design principles, and D49
  accepts the information architecture. D50 sets how the list of PV names is kept current in the browser. D51 splits the System section into three pages and sets how a status is judged. D52 keeps the PV operations that the T3 comparison found missing, as far as they are useful. D53 amends plan items 5 and 7 to what was built and measured. D54 sets four rules found by the third review: field names, line breaks at a recorded connection loss, labelled means, and a periodic check of additions. D45 assigns M13 from Backlog to Milestone, widens its scope to the whole management web
  interface, and orders release verification after it. The owner directed the work to proceed in this repository the
  same day. Plan acceptance and implementation authorization are separate records.
- Decision Date: 2026-10-10. The owner accepted the plan and authorized its implementation in this repository; the status moves from Open to In progress.
- Decision Date: 2026-09-29. Transferred from Milestone to Backlog for the 2.0.0 cycle close.
- Decision Date: 2026-09-22. Assigned from Backlog to Milestone for 2.0.0.
- The earlier premise that the interface lives only in EPICS-Arche is replaced for 2.0.1 by D45. EPICS-Arche
  (post-Phase-2 runtime, D11) remains the place to revisit the interface if it replaces the mgmt UI.
- epicsarchiverap-maven owns template application and WAR packaging (D33). Files transferred to it follow its own
  review and CI.
- Contract inventory, observed 2026-10-10 at source `162269e7`: the management scripts and pages call 43 distinct `bpl/*` endpoints and read 38 element ids through `$("#id")`; the retrieval viewer takes the address parameters `pv` (repeatable), `from` and `to`. The list is the file `ui-contract-inventory.txt` and is reproduced by `grep -h -o -E '(\.\./)?bpl/[A-Za-z0-9_]+' js/*.js *.html | sed 's|.*bpl/||' | sort -u` in `mgmt/staticcontent`.
- The server injects values into two static files: `js/mgmt.js` carries the template markers `minimumSamplingPeriod` and `archivePVWorkflowBatchSize`, and `viewer/index.html` receives the retrieval address. A redesigned main script keeps the path `js/mgmt.js` and those markers, or obtains the values another way.
- The installers refuse a source checkout with changes in its source inputs (`check_source`). The files that `site-template/ui` prepares are generated inputs like the site overlay: the source check names them one by one and permits only those, and the shared header, navigation and footer blocks of a prepared `index.html` stay equal to the source ones so the build's block synchronization changes no other page. A build leaves those prepared paths changed in `epicsarchiverap-maven-src`; building without `site-template/ui` needs that checkout restored first.
- The Work page reads the configured `minimumSamplingPeriod` from the text of `js/mgmt.js`, which the server rewrites, because no endpoint serves it. A server change may replace that read later (D46).
- The shared chart module, the sparkline module, the chart stylesheet and D3 7.9.0 (ISC license, npm package integrity recorded in `d3.SOURCE.txt`) live in `site-template/ui/staticcontent` and reach every web application as `ui/comm`; the Work page and the data viewer both use them. The replacement viewer is prepared as plain files under `retrieval/staticcontent/viewer`; `viewer.zip` stays in the WAR and is shadowed by those files.
- The Integration page keeps the functions of the previous page on the same server calls: the configuration upload (the server redirects back to `integration.html?message=...`, so the page name stays), the external archiver data servers (list, add, remove) and the comparison with a Channel Archiver, which replaces `cacompare.html`; that file is prepared as a forward. The Channel Archiver functions are the oldest part of the interface; the owner decides after the design is complete whether they stay.
- The System page replaces the Metrics, Storage and Appliances pages: those three files are prepared as forwards to `system.html`, and the shared navigation lists Work, System, Integration and Help. The report types of the previous Reports page are selections of the finder on the Work page (14 selections, each with the field it shows beside every PV, the ranked ones in the order of the server); `reports.html` and `pvdetails.html` are prepared as forwards, and `pvdetails.html?pv=` forwards to the Work page with that PV. `capacityUtilized` of `getApplianceMetrics` is a fixed "N/A" in the server code, so the System page computes storage use from `getStorageMetricsForAppliance` instead.
- Keyboard and contrast: the PV list of the Work page is a listbox that takes the arrow keys, Home, End, Page keys, Space and Enter, and the rows of the scan list and of the System table take Enter and Space; the text colors were darkened so that every one reaches 4.5:1 (the faint level was 3.1:1). The browser automation of this host does not activate even a plain native button from a key, so button activation and the focus of a dialog are the browser's own behavior and were not observed.
- `scripts/prepare-ui.bash` undoes the copy of the earlier run, using a list of the copied files kept in the source checkout's Git directory, before it copies again, so a file that left `site-template/ui` leaves the build.
- `StaticContentServlet` serves a file at the exact path first and looks into a `<name>.zip` only when none is found, so a replacement viewer can ship as plain files under `ui/viewer/` beside `viewer.zip`.
- The retrieval WAR serves the current viewer from the vendored `viewer.zip` (upstream svg_viewer v1.2.1, refresh
  procedure in the source repository's `docs/svg-viewer.md`). Both the management pages and the retrieval WAR allow
  cross-origin requests, so a management page can request archived data from the retrieval address.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-10; owner accepted the twelve-item plan and checks T1 to T12 after the information architecture mockup (D49)
Implementation Authorization: 2026-10-10; owner authorized implementing the plan in this repository: the prepared files, the build step, the site skin, the tests and the local verification. Commits, pushes, pull requests, guest requests and release objects remain separately authorized.
Superseded Plan Artifacts: none

Premise recovered from the source: the Maven build copies `src/main/org/epics/archiverappliance/mgmt/staticcontent`
into the stage; `SyncStaticContentHeadersFooters` copies the marker blocks (`@begin(...)` / `@end(...)`) of `index.html`
into the other pages; `SiteOverlay` applies `template_changes.html`, `css/main.css`, `css/mgmt.css` and `img/` at the
package phase. A page without the marker blocks receives no site header or navigation. Name lookup is done by the
server: `getMatchingPVsForThisAppliance` returns names for a glob or Java regex with a default limit of 500, and the
`Lookup` button only writes the returned names back into the input.

1. Prepared-file location and build step. Add `site-template/ui/`, mirroring the layout of epicsarchiverap-maven
   `mgmt/staticcontent`, and a `copy.ui` target in `configure/RULES_SRC` that copies it over the source tree before
   Maven runs, as a prerequisite of every build target that has `copy.sitespecific`. With no files in
   `site-template/ui` the step changes nothing. Verification: T2 and a Phase 1 logic check that the dry run orders
   `copy.ui` before the Maven command.
2. Contract inventory. From `mgmt.js`, `reporttable.js`, the pages and the viewer, list every server endpoint, request
   parameter and response field the interface uses, every element id the scripts read, and every address parameter
   `archViewer.html` accepts. This is the contract the redesign keeps; the server is not changed. Verification: the
   list is reproduced by a command recorded in the detail and reviewed by the owner.
3. Viewer serving. Recover how the retrieval WAR serves `ui/viewer/archViewer.html` from `viewer.zip`, and define how
   the replacement is staged and packaged while keeping that address. Verification: T2 for the packaged files and T1
   for the address.
4. Information architecture proposal (owner decision). Propose the navigation and page structure that replace the six
   top-level pages as one working view: search, selection, status and actions, and the data browser, plus where
   metrics, storage, appliances and integration live, and the explanatory text of statuses and table columns. Present
   it with static page mockups. No page is implemented before the owner accepts it. Verification: acceptance recorded
   as a decision (D49).
5. Visual system and icons. Replace `site-template/siteid/css/{main,mgmt}.css` and `template_changes.html` with the
   accepted design, applying D48 (no ink without data, color only for meaning): color tokens that keep the brand colors, responsive layout, touch targets of at least 44 px, and
   no icon set (amended by D53). Verification: T1, T5.
6. Signal search. Build the name index in a Web Worker from `getAllPVs`, cache it in IndexedDB, and search it in the
   browser: words in any order, case-insensitive, glob and regex modes, grouping by the `:`-separated name segments, and
   filtering by status obtained through batched `getPVStatus` calls for the visible rows only. How the list is kept
   current and when the server answers a search instead is D50. Verification: T9 for index speed with
   generated names and for the refresh path, T1 and T3 against the real appliance.
7. Data browser. Build the plot with D3 scales and axes and SVG drawing for the series (amended by D53): caps on the series per chart, the chart panels per page and the PVs
   in the sparkline list (initial values in D47, confirmed by T11), a sparkline list for scanning many PVs, step lines
   without interpolation across gaps, sample markers on zoom, the exact value on hover, time-range presets, panning and zooming that request data at the resolution of the visible window from the
   existing retrieval data endpoint, caching per PV and window, a cap on concurrent
   requests, and data export by opening the data viewer (amended by D53). Verification: T1 with PVs archived from a soft IOC, T3, T10, T11, T12.
8. Page implementation. For each accepted page, write the markup and script in `site-template/ui` with the marker
   blocks kept, native browser APIs only, no framework and no build tool, native `dialog` in place of jQuery UI, no
   inline script, style or event-handler attribute, data inserted as text and never as markup, and the contract of
   item 2 unchanged. Verification: T1, T3, T8.
9. Static checks. Add a Bash test under `tests/`, called from `tests/phase1-logic.bash`, that fails when a prepared page
   lacks a marker block, references jQuery UI or an external host, contains inline script or event-handler attributes,
   or when a script reads an element id its page does not define. Verification: T4, and a deliberately broken copy is
   rejected.
10. Real appliance check. Build the four WARs through the Make build, run them with the isolated local launcher, and
    drive every page in a browser at 1280 px and 390 px, including the dialogs, search and the data browser.
    Verification: T1, T2, T3, T5, T7.
11. Operator documentation. Update the operator and site-skin documentation and the changelog entry for the new
    interface and the plotting cap. Verification: documentation matches the shipped file names and the Make target of
    item 1.
12. Transfer to epicsarchiverap-maven. In that repository, on a branch from the pinned source commit, move the
    prepared files into `mgmt/staticcontent` and the retrieval static content with their tests, and update its
    `docs/svg-viewer.md`; its CI passes `StaticContentBPLCallsTest` and `SiteOverlayTest`. After the commit, this
    repository adopts the new source pin, removes `site-template/ui` and `copy.ui`, and keeps the site skin. Every
    commit, push and pull request needs its own authorization. Verification: T6.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | UI | Build the four WARs through the Make build, start the appliance with the isolated launcher, and drive every page with a browser at 1280 px and 390 px: check status for names, open the sampling-period dialog, choose a report, search for names, plot selected PVs | Real appliance on isolated ports, PVs archived from a soft IOC | Every page renders and operates; dialogs show their full content and controls; no console errors; the plot shows the archived samples |
| T2 | Build | Compare the prepared files and the site skin files with their copies inside the built WARs | Built WARs | The WARs carry the repository files byte for byte, except that a page may differ inside the three site blocks that the site template replaces |
| T3 | Contract | Compare the endpoint list of the redesigned scripts with the inventory of the original scripts, then observe each endpoint answer during T1 | Real appliance | No endpoint outside the action list of the server (D46); an endpoint of the inventory that is no longer used is a decision (D52); each answers with its expected status |
| T4 | Logic | Run `bash tests/run-all-tests.bash --local` with `AA_TEST_EPICS_BIN` set, including the new static test, and the same test against a deliberately broken copy | Local checkout | All checks pass; the broken copy fails |
| T5 | UI | Measure at 390 px the document width against the viewport and the size of every interactive element | Real appliance, browser | No horizontal page scroll; interactive elements are at least 44 px high |
| T6 | Transfer | Run epicsarchiverap-maven CI at the transfer commit, then build this repository from the new source pin without `site-template/ui` and compare the WAR files with the T2 copies | GitHub Actions; local build | CI passes; the WARs carry the same files |
| T7 | Browser | Run the T1 scenario in Firefox, in Microsoft Edge (Chromium) and in WebKitGTK through `WebKitWebDriver`, which is the engine of Safari but not the Safari application; record Safari observations from the owner's machines when available | Current releases on this host: Firefox, Edge, WebKitGTK from the Debian 13 packages (`xvfb` and `webkitgtk-webdriver` installed by the owner) | Firefox, Edge and WebKitGTK pass; a failure in any of them is a defect to fix; a failure seen only in the Safari application is recorded as a finding |
| T8 | Security | Check the served pages for inline script and event-handler attributes, external hosts, and unescaped data in markup, and load them under a restrictive content security policy | Real appliance, browser | No violation reported; names containing markup characters display as text |
| T9 | Performance | Build and query the name index in a browser with generated names at the sizes the plan sets; with a real appliance, add and delete archived PVs and observe the requests the page makes (D50) | Browser on this host; real appliance | Search results update within the time the plan sets at each size; an unchanged list costs one count request per check, additions cost one report request, and only a falling count, a day-old snapshot or an incomplete report reads the whole list |
| T10 | UI | Select PVs beyond the confirmed cap | Real appliance, browser | The first selection beyond the cap is refused with a message that states the cap |
| T11 | Load | Plot 5, 10, 20, 50 and 100 PVs archived from soft IOCs in steps, as detail charts and as sparkline rows; at each step record the response time of every retrieval request, the CPU and heap of the retrieval and management JVMs, and the browser frame time and memory | Real appliance on isolated ports; browser on this host | Each cap is the largest step whose response times and server load stay within the bounds the owner approves; a step that exceeds them sets that cap at the step before it |
| T12 | Design | Inspect every page against the D48 rules: the emphasized element of each view, borders, shadows, fills and gradients that carry no data, color use, gaps and step drawing, sample markers on zoom, the exact value on hover | Real appliance, browser | Each rule holds on every page; a deviation is recorded as a finding |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-10 15:15 to 15:45 PDT, final run on the built WARs | This host; built WARs; scratch appliance with 201 PVs from a soft IOC | Pass | Final run: one in-page scenario per page (Work: name list, search, report selection, selection of two PVs, chart, value on hover, drag zoom with the samples marked, sampling dialog, stop dialog, details list, archive offer and dialog; System, Operations, Retrieval performance, Integration and viewer: tables, forms and dialogs) with 47 checks over six pages (pan earlier and later of a zoomed window, the links to the viewer, the state of a listed PV that is not selected, the values of the details list and the stop-all button included) passed at 1280 px and 390 px in Edge 154 and in Firefox with the console read (no errors, no policy violation), and at 1280 px and 447 px in WebKitGTK (console not readable through that driver); 26 distinct server calls were observed and all answered 200. One run directly after an appliance restart missed the storage bars; two repeats passed. Earlier observations: Work page and data viewer at 1280 px and 390 px: names loaded, search, selection, status, scan rows with sparklines, three-series chart with hover values, archive dialog, viewer opened by the previous address form (`?pv=` with and without `from` and `to`), PV added through the form, preset range, one chart per unit with the unit shown as archived, no horizontal overflow, no console messages. The System page at 1280 px and 390 px: appliance row, storage notice, load table of 23 measures, process values, versions, forwards of the three old pages. The Integration page at 1280 px and 390 px: server list, add of an EPICS Archiver Appliance server, remove, error report of an unreachable server, comparison error, upload of a configuration file with the returned message, refusal of an empty upload. The distribution and the scatter of two PVs were drawn from three to four averaged samples per PV (the local appliance held few samples), at both widths, and followed the focused PV. The report selections of the Work page were each chosen against the real appliance (14 of 14 answered, five of them with rows); the storage bars and the process trends were not observed with data because the local appliance reported no storage devices and one process sample. Actions driven with real clicks in WebKitGTK through `WebKitWebDriver` (2026-10-10 11:55 to 12:15 PDT, scratch appliance, files copied from `site-template/ui`): Pause, Resume, Stop archiving with its dialog (Cancel, then confirm), Archive from the offer with the period check, Abort the request, Space and arrow keys in the result list, mode and range buttons, the upload check and the add-server dialog. Three defects were found and fixed in the same run: Stop archiving failed for a running PV because the archiver removes only a paused PV (now paused first, and the PV stays in the list when the removal fails); the detail never left Initial sampling or Paused because the status was read once (now read every 3 s while a request is unfinished or an action is recent, every 20 s otherwise, paused while the page is hidden); an action offered before the state was read (now none). System page against the existing local appliance, read only (2026-10-10 12:20 PDT; the page files from this repository were served by a forwarder that passed only seven GET status calls to it and answered a write call with 403; nothing on the appliance was changed): the appliance table, the three storage bars with used and total space, the load table and four one-day process trends rendered at 1280 px and 447 px without horizontal scrolling. Two defects were found and fixed: a direct label that was cut off at the right edge (a chart with one series now labels the end of its line with the value only) and axis labels at padded minimum, middle and maximum values with a negative floor for a percentage (now round ticks and a floor of zero for a series that is never negative). Disconnected PVs by host on the System page (2026-10-10 13:15 PDT, built WARs, two soft IOCs on different ports): after the second IOC stopped the page listed one group of 10 PVs, and 40 s later after the first stopped a second group of 183 PVs, each with host, count, time of loss and name prefixes; a real click on PVs listed the group's names and the link opened the Work page with the prefix and the Disconnected selection (120 of 193 PVs match). With the IOC running and only some PVs removed from its database the server report lists only the missing PVs, which the page cannot yet tell from a stopped IOC without a per-host report (ui-server-change-candidates.md, A11). System section as three pages (D51), 2026-10-10 13:25 to 13:45 PDT, built WARs, scratch appliance with 193 PVs from two soft IOCs and, read only, the existing local appliance through a forwarder that passed 20 listed GET status calls and no other request: Overview (three verdict lines, nine judged rows with links), Operations (samples, hosts, dropped samples, write path, stores and ETL, capacity plan, processes with the floor of each heap, configuration with the basis of every threshold) and Retrieval performance (server facts, retrieval heap floor, a request measured in the browser, PV lookup) rendered without horizontal scrolling at 1280 px and 447 px in WebKitGTK. In the scratch appliance the page flagged a real problem: 83,652 samples dropped from 190 PVs, which the appliance cannot write because the default store folders are the production ones (list C1). A measure the appliance does not report is shown as Not reported, never as Normal. Defects found and fixed in this run: the retrieval page's content security policy did not allow the retrieval address; a long store line overflowed at 447 px; a measure with no value was judged Normal. Maintenance and bulk actions of D52 on the Work page, built WARs, scratch appliance, real clicks in WebKitGTK (2026-10-10 14:15 to 14:25 PDT): change of sampling on a running and on a paused PV (the server settings changed to SCAN, 2.0 s); the details list (22 to 79 rows); consolidation into a store (paused first, the stores offered from the PV settings); rename (the selection took the new name, both names paused); change of type, refused without the backup box and accepted with it; pause and resume of three selected PVs in one call ("1 PV paused, 2 already in that state"); on Operations the pause of a disconnected host group of 178 PVs after a confirmation, which left the other 11 listed. A refusal shows the server's reason in the dialog and, when the PV was paused for it, says it is still paused (observed: AccessDeniedException for a PV whose store folder is the production one). Not driven: removing an external server (none configured), screen readers. After the third review (D54), rebuilt WARs, Edge 154: a PV with a field (`UI:TEST:X2.A`) opens in the viewer and gets an archive offer; a real IOC outage and an engine restart break the line exactly at the samples that carry `cnxlostepsecs` and `startup` (paths of 1, 24, 69 and 37 points equal the ones computed from the server answer); a PV with samples 60 s apart (answer supplied at the HTTP boundary) is one path of 118 segments; the viewer says that values are means and the CSV carries `interval_seconds`; with every call answered 500 the viewer says "2 of 2 could not be read."; with a second appliance row supplied at the HTTP boundary the nine overview links and the address after a change keep `?appliance=` and the `#fragment`; the count probe appears in the server log. A fourth review found that `mean_N` filled an 83-minute connection loss of `UI:ZOOM:P1` with 134 bins of the same value; with `meanSample_N` the answer has the 83-minute gap and the charts show gaps of 219 px (viewer) at a 6-hour range. The T1 scenario on these WARs (2026-10-10 21:20 PDT, four soft IOC databases, scratch appliance): Edge 154 at 1280 and 390 px, Firefox at 1280 and 390 px and WebKitGTK at 1280 px each passed all 47 checks (Work 26, System 4, Operations 7, Retrieval 4, Integration 4, viewer 2) with 28 or 29 distinct server calls, all answered 200, and no console error where readable. |
| T2 | 2026-10-10 15:40 PDT | This host; WARs of the Make build | Pass | Of 45 comparisons of prepared files and site skin files with their copies in the mgmt and retrieval WARs, 40 are byte-identical and 5 pages (`index.html`, `system.html`, `operations.html`, `retrieval.html`, `integration.html`) are identical outside the three site blocks, whose first line the build re-indents; none differs or is missing. Earlier observations: the Work page files, the viewer files and the shared `comm` files are byte-identical in the built WARs. `index.html` differs only in the header and navigation blocks that the site template replaces, so the expected result needs that exception before T2 can pass. |
| T3 | 2026-10-10 | This host; built WARs | Pass | The redesigned files use 44 server calls, all in the action list of the server; five are new (`getApplianceProperties`, `getAppliancesInCluster`, `getProcessMetrics`, `getSlowChangingPVsWithDroppedEvents`, `changeTypeForPV`); four of the original 43 are not used, by decision D52 (`getPolicyText`, `getStorageMetrics`, `getStoresForPV`, `reshardPV`). In the T1 run all 26 distinct calls it makes were answered 200. Earlier observations: `ui-contract-compare-20261010.txt`: the redesigned files use 38 server calls; 33 are in the original inventory and 5 are new reads that the server already provides (`getApplianceProperties`, `getAppliancesInCluster`, `getProcessMetrics`, `getSlowChangingPVsWithDroppedEvents`, and `test/compareWithChannelArchiver`, which the inventory listed as `test`); no call outside the server's action list. Eight original calls are no longer used: `changeArchivalParameters`, `consolidateDataForPV`, `renamePV`, `reshardPV`, `getStoresForPV`, `getPVDetails`, `getPolicyText`, `getStorageMetrics`. They are PV operations and the full details list of the old interface, so the contract is not kept until the owner decides whether the Work page carries them. Each endpoint's answer was observed during T1 only for the calls the new pages make. After D52 the Work page uses `changeArchivalParameters`, `renamePV`, `consolidateDataForPV`, `getPVDetails` and the new `changeTypeForPV` again; `getStoresForPV`, `getPolicyText` and `getStorageMetrics` are left out by decision and `reshardPV` is postponed. |
| T4 | 2026-10-10 15:45 PDT | Local checkout, real Base binaries | Pass | `run-all-tests.bash --local` exit 0: Phase 1 250, Health 32, No Ant 22, Interface files 243, Phase 2 16; fifteen broken copies of the interface files are refused each for its own reason, among them a page that turns text into markup and a server call that is built from parts. Earlier observations: `run-all-tests.bash --local` exit 0: Phase 1 250, Health 32, No Ant 22, Phase 2 16, EPICS preflight resolved (last run after the Integration page); `prepare-ui.bash` and the installer source check are covered by new checks. `tests/ui-static.bash` (plan item 9) passes 197 checks on the prepared files, including the 4.5:1 contrast of every text color, and refuses nine copies with one defect each (missing marker block, inline script, event handler, jQuery reference, unknown element id, outside host, missing policy, missing script, faint text color) for the reason named. The evidence directory is under `/tmp` and is not retained. Final run on the transferred state, 2026-10-21: `run-all-tests.bash --local` exit 0 with `AA_SOURCE_CLONE` set to a fresh clone of `modernize` at `8f0d616a727af60b6abb6b447f231318a08a3e86` and this repository `42179dd`: Phase 1 290, Health 32, No Ant 22, Interface files 345, Phase 2 14. |
| T5 | 2026-10-10 15:40 PDT | This host; Edge 154 at 390 px with the cache disabled; built WARs | Pass | Six pages (the Work page with two PVs selected, so the maintenance summaries and the viewer links are in view): no horizontal scroll and no visible interactive element under 44 px high; the five dialogs measured while open fit inside the viewport with every control and every checkbox label at 44 px. The checkboxes themselves are 13 px inside a 44 px label. Earlier observations: The Work, Overview, Operations, Retrieval performance, Integration and viewer pages had no horizontal scroll and no visible interactive element under 44 px high (the first run found 38, 4, 5, 6, 5 and 13 such elements; the result list rows, the buttons and inputs of every page, the tab links and the site logo link were raised to 44 px). Not measured: the dialogs while open, and the table links inside rows, which count as inline text. |
| T6 | 2026-10-21 | This host; a clone of epicsarchiverap-maven at the transfer commit `d0932d1b026d9045e1b57535561945acb3be5f7f`, this repository `42179dd` | Pass | `ARCHAPPL_SITEID=als ./mvnw -B test -Dtest='SiteOverlayTest,StaticContentBPLCallsTest'` ran 9 tests (8 and 1) with no failure, error or skip, BUILD SUCCESS; this ran on this host, because GitHub Actions has no run at the transfer commit itself (the later `modernize` commits pass its Maven workflow). `make conf.archapplproperties build.mvn` built the four WARs. The WARs of T2 are not retained, so the reference is the 35 prepared files of `site-template/ui` at `a1aab5a^` that T2 compared: they equal their copies in the source tree at the transfer commit (35 of 35) and in the mgmt and retrieval WARs (42 comparisons, the seven shared files in both WARs, all byte-identical, none missing), and `LBNLLogo.png` and `als.ico` of the site folder equal their copies in both WARs. No site block was replaced in this pairing: the site folder of D57 fills the `site_logo` block, which the pages of the transfer commit do not carry; the site skin on the later source is covered by the page checks at `7e9e2253`. Site skin on the transferred interface, 2026-10-21: this repository `42179dd` built the four WARs from `modernize` at `8f0d616a727af60b6abb6b447f231318a08a3e86`; all seven pages that carry the `site_logo` block hold the block of `site-template/siteid/template_changes.html` and equal the source pages outside it (only the indentation of the marker line differs); `LBNLLogo.png` and `als.ico` equal their copies in both WARs; Edge in headless mode showed the Berkeley Lab logo in the header of the built `index.html` at 1280 px and 390 px, with no horizontal scroll, the page opened from the file without a server |
| T7 | 2026-10-10 15:15 to 15:45 PDT | This host; Firefox, Edge 154, WebKitGTK 2.54 (the Safari engine) | Pass | The T1 scenario passed in all three. The Safari application is not installed on this host, so its observations are not available; WebKitGTK is the engine only. Earlier observations: At 1280 px and 390 px the Work page listed 178 PVs with its snapshot saved in IndexedDB, filled the scan list and drew the chart for four selected PVs, and answered a search; the System, Integration and viewer pages rendered; no page scrolled horizontally; the only console message was a 404 for `favicon.ico` on the first load. Button activation, dialogs and the actions were not driven in Edge, WebKitGTK 2.54 (`MiniBrowser` through `WebKitWebDriver` under `xvfb`, user agent `AppleWebKit/605.1.15 Version/60.5 Safari/605.1.15`), 11:45 PDT, same four WARs: the same checks gave the same results at a viewport of 1280 px and of 447 px (the smallest window the driver gave; 390 px was not reached), with no horizontal scrolling; console messages cannot be read through this driver, so a policy violation is excluded only by the pages working. The Safari application itself is not installed on this host. |
| T8 | 2026-10-10 15:45 PDT | This host; Edge and Firefox with the console read | Pass | No inline script, handler or style attribute, no outside host, no jQuery, no markup built from text (a rule of the static test, with a refused broken copy), a content security policy on every full page; no policy violation was reported in Edge or Firefox over the T1 scenario; names reach the page only through text nodes. Earlier observations: The static part runs in `tests/ui-static.bash`: no inline script, event-handler or style attribute, no outside host, a `script-src 'self'` policy on every full page. The browser enforced that policy in every run of the Work, System, Integration and viewer pages and reported no console message. A PV name that contains markup characters (`UI:<b>BOLD</b>:X`) is shown as text in the scan list, the detail and the archive offer, and creates no element. |
| T9 | 2026-10-10 | This host; Firefox headless; the shipped names worker; a real appliance | Pass | Search times of the shipped worker are within the 0.1 s of D47 up to 500,000 names, the size the owner confirmed (D50); the refresh requests match the expected pattern. Not measured: the cost of the count call, of a merge and of a whole read at 500,000 or more names. Earlier observations: Load of the index: 11, 23, 52, 150, 327 and 807 ms for 10,000, 50,000, 100,000, 250,000, 500,000 and 1,000,000 names. A search (one word, two words, no match, glob, regex) took 5 ms or less up to 100,000 names, 12 ms or less at 250,000, 32 ms or less at 500,000 (65 ms with an empty query that returns 50,000 names), and 50 to 134 ms at 1,000,000 (160 ms with the empty query), so the 0.1 s of D47 holds up to 500,000 names and is exceeded in four of six cases at 1,000,000. The list of 1,000,000 names is 22 MB as JSON (2.8 MB gzipped) and parses in 77 ms; whether the server compresses `getAllPVs` was not measured. The owner confirmed 500,000 names as the size the browser holds (D50). Retained in `ui-index-measure-20261010.txt`. Refresh path of D50, observed 2026-10-10 10:50 to 11:02 PDT with the page behind a request-logging forwarder on the scratch appliance (124 to 179 PVs; the changed files were copied into its exploded web application, so the built WARs still have to be rechecked): a first visit made one count request and one whole-list read and showed the list in 246 ms; a reload with a snapshot showed it in 59 to 146 ms and then made only the count request, once per 15 s; 30 added PVs produced one `getRecentlyAddedPVs?limit=50` and 10 added PVs one `limit=30`, both without a whole-list read; one deleted PV produced one whole-list read; with the limit lowered to 100 in the shipped worker a search was answered by the server (contains and glob, partial flag set at the limit); a name removed from a seeded snapshot was found on the server, announced and saved. Not measured: cost of the count request, of a merge and of a whole-list read at 500,000 or more names, and the behavior with more than one appliance. |
| T10 | 2026-10-10 06:50 PDT | This host; 120 PVs archived from soft IOC records | Pass | With 100 PVs in the scan list, Space on the 101st name left the count at 100 and showed "The scan list holds at most 100 PVs."; an address with 103 PVs showed 100 and said the first 100 are shown; the chart drew 5 of the 100 and stated the chart limit. Retained in `ui-load-measure-20261010.txt`. |
| T11 | 2026-10-10 16:00 to 16:15 PDT | This host; four JVMs, 100 PVs at 1 Hz with about ten minutes of samples each, one browser, one user; built WARs | Pass | Bounds applied on the owner's instruction to set the limits (proposed by the assistant, to be vetoed if wrong): every row filled within 1 s, one retrieval request within 200 ms, no frame gap above 100 ms, no failure. Selecting 5, 10, 20, 50 and 100 PVs from a fresh page filled every scan row in 0.19, 0.26, 0.22, 0.34 and 0.65 s; the slowest request took 47 ms; the longest frame gap was 50 ms; no request failed; CPU of the retrieval JVM 1.4 s at 100 PVs, of management 0.3 s, of the engine 0.3 s; heap percentages before and after one run stayed within their normal collection range. The caps therefore stay at 100 PVs in the scan list and 5 series in a chart (D47). A first run needed 1.85 s at 100 PVs because the list and the chart were drawn once per answer; they are now drawn once per 60 ms, which gave 0.45 to 0.65 s. Not measured: browser memory, a week of samples per PV, several users, the retrieval of one hundred PVs at the 7 day and 30 day ranges. Earlier run: `ui-load-measure-20261010.txt`. |
| T12 | 2026-10-10 15:30 PDT | This host; Edge with computed styles; WebKitGTK; built WARs | Pass | After the fixes: no gradient, no shadow, no color outside the token set on any page; saturated colors only for alert and attention; step lines, gaps and the value on hover observed on the Work chart; a drag zooms the chart and marks the samples when 200 or fewer are in view (observed on a PV sampled at 1 Hz). Panning of a zoomed window moves it by half its span and was observed. Earlier observations: Audit of the six pages at 1280 px: no gradient; one shadow, on the site navigation bar, removed; no color outside the token set except a white 14 % rule in the site header, and three hard-coded teal tints in the viewer, replaced by tokens; the saturated colors in use are the alert color and the attention color, both only for judgements and disconnections, and the accent for links and selection. The emphasized element of each page (the chart and the scan list on Work; the three verdict lines on Overview; the judged rows on Operations; the measured request on Retrieval performance) is stated in the page structure, not measured. Step drawing, gaps and the value on hover were observed during T1. Not covered: sample markers on zoom of the new charts. |

##### Closure Evidence

- Complete on 2026-10-21. The interface was built and checked in this repository in `ed2d9b0`, `f8ed517` and `c610b42`, and moved to jeonghanlee/epicsarchiverap-maven in `d0932d1b026d9045e1b57535561945acb3be5f7f`, which is on `origin/modernize`; this repository removed its copy in `a1aab5a` (M51), which is on `origin/release-2.0.1`. T1 to T12 Pass.
- Decision Date: 2026-10-21. The owner accepted as the CI criterion of the transfer the run of the two named CI tests (`SiteOverlayTest`, `StaticContentBPLCallsTest`) at the transfer commit on this host (T6) together with the passing Maven workflow of GitHub Actions at the later `modernize` commits, because GitHub Actions has no run at the transfer commit itself.

#### M50 - Replace the sample buffer capacity adjustment with the margin in seconds

Origin: 2.0.1 / M50
Identity History: none
GitHub Issue: [#60](https://github.com/jeonghanlee/epicsarchiverap-env/issues/60)
Status: Complete

##### Summary

The source repository replaced the engine property `sampleBufferCapacityAdjustment`, a multiplier of the buffer capacity, with `sampleBufferMarginSeconds`, the seconds of write delay a sample buffer absorbs (default and minimum 1.0). This environment generated the old key and advised raising it as the remedy for a buffer overflow.

##### Scope

- `ARCHAPPL_SAMPLE_BUFFER_MARGIN_SECONDS` replaces `ARCHAPPL_SAMPLE_BUFFER_CAPACITY_ADJUSTMENT` in `configure/CONFIG_SITE` and `configure/RULES_PROPERTIES`; `site-template/archappl.properties.in` writes the new key.
- The Operations page, the remedy in `js/system/judge.js`, `docs/README.interface.md` and `CHANGELOG.md` name the new key.
- `SRC_TAG` pins the source commit that reads the key.

Out of scope: the default value and the capacity formula, which belong to epicsarchiverap-maven; a check in `tests/` that the variable reaches `archappl.properties`, which the owner assigned to the work in epicsarchiverap-maven; removing the old key from deployed appliances, where it is ignored.

##### Completion Criteria

- No tracked file outside `CHANGELOG.md` and this register names the old variable or the old key.
- `make conf.archapplproperties` writes `sampleBufferMarginSeconds = 1.0`, and a value set in `../CONFIG_SITE.local` reaches it.
- The Operations page and `js/system/judge.js` name the new key.
- The four WARs built at the pinned source carry the new key.
- `bash tests/run-all-tests.bash --local` passes.

##### Dependencies And Decisions

- No dependency. The owner chose a new configure variable over keeping the old name and accepted the source pin `1f099b2f5fe7ecb714e4a055e8b895f267fb78e0` on `modernize`, which contains the source change `6c6b973a92e23c0881e3964873e3c122799d01a9`.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: the owner chose the configure variable and the pin in the working session of 2026-10-11
Implementation Authorization: the owner started the change in that session
Superseded Plan Artifacts: none

1. Rename the variable and the key in the five places named in #60.
2. Record the change in `CHANGELOG.md` and regenerate the book page of the configuration variables.
3. Move `SRC_TAG` to the source commit that reads the key and build the WARs at it.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | `make conf.archapplproperties`, then the same with `ARCHAPPL_SAMPLE_BUFFER_MARGIN_SECONDS:=2.5` in `../CONFIG_SITE.local` | Local host | The generated file holds `sampleBufferMarginSeconds = 1.0`, then `2.5` |
| T2 | Local | `make init` into a new directory and `make conf.archapplproperties build.mvn` at the pinned source; read `archappl.properties` and the interface files in each WAR | Local host | Four WARs, each with the new key, and the Operations page and `judge.js` name it |
| T3 | Local | `bash tests/run-all-tests.bash --local` | Local host with real Base binaries | Exit 0 with the same groups as before |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-11 | Local host | Pass | The default produced `sampleBufferMarginSeconds = 1.0`; the value 2.5 in `../CONFIG_SITE.local` produced `2.5`, and removing the file restored 1.0 |
| T2 | 2026-10-11 | Local host; source `1f099b2f5fe7ecb714e4a055e8b895f267fb78e0` cloned by `make init` | Pass | BUILD SUCCESS in about 24 s; `mgmt`, `engine`, `etl` and `retrieval` WARs each hold `sampleBufferMarginSeconds = 1.0`; `judge.js` in `mgmt.war` equals the source file and the Operations page names the key |
| T3 | 2026-10-11 | Local checkout, real Base binaries | Pass | `run-all-tests.bash --local` exit 0: Phase 1 250, Health 32, No Ant 22, Interface files 243, Phase 2 16 |

##### Closure Evidence

- Complete on 2026-10-11: the change landed in `3353b74` on `origin/release-2.0.1`, and the register update in `1ca64c6`; T1, T2 and T3 passed and #60 was closed as completed with its body synchronized and the five acceptance criteria checked.

##### GitHub Projection

Title: Replace the sample buffer capacity adjustment with the margin in seconds
Labels: enhancement
GitHub Milestone: 2.0.1
Observed State: CLOSED
Observed Labels: enhancement
Observed Milestone: 2.0.1 / #7
Last Compared: 2026-10-11 at 08:49 UTC, `gh issue view 60 --repo jeonghanlee/epicsarchiverap-env`; CLOSED at 2026-10-11T08:49:40Z, enhancement, milestone 2.0.1, assignee jeonghanlee; one closing comment; the live body equals the synchronized draft with the five acceptance criteria checked

#### M48 - Review scripts/archappl.bash, starting with the `h` case that does nothing

Origin: 2.0.1 / M48
Identity History: moved from Backlog to Milestone on 2026-10-23 under D64
GitHub Issue: [#61](https://github.com/jeonghanlee/epicsarchiverap-env/issues/61)
Status: Complete

##### Summary

`scripts/archappl.bash` (799 lines) is the control script that systemd runs as the main process of the appliance and that operators call for `status`, `health`, `storage` and `loglevel`. A reading for the book found one defect and several points that no test or review has examined as a whole. The defect: the usage text lists `h` as "this screen", the `case` has an empty `h` arm (`h);;` at line 792), so `bash archappl.bash h` prints nothing, while `help`, no argument and any unknown argument print the usage. Observed 2026-10-11 on the author's host before the fixes (`h` now prints the usage and exits 1 like an unknown argument); the recheck then was `bash scripts/archappl.bash help 2>&1 | grep -c .` (13 lines in a checkout) and `bash scripts/archappl.bash h 2>&1 | grep -v 'archappl.conf: No such' | grep -c .` (0 lines).

The first review (2026-10-11, the whole file read and each action run in an isolated copy with a configuration file and instance scripts) found these. They are hypotheses until the owner accepts them. Line numbers and observations in the table refer to the script before the fixes of the same day.

| # | Class | Finding | Evidence to recheck |
| --- | --- | --- | --- |
| F1 | must-fix, accepted, fixed | `startup` and `shutdown` ignore the exit status of `bin/startup.sh` and `bin/shutdown.sh` and exit 0, so `make start`, `make stop` and `restart` report success when an instance failed | In a copy with an instance script that exits 1, `bash archappl.bash startup` starts the others and exits 0 |
| F2 | must-fix, accepted, fixed | Line 26 sources `archappl.conf` without checking; without the file `startup` prints one error, starts the instances with no environment and exits 0 | Remove `archappl.conf` from the copy and run `startup` |
| F3 | minor, accepted, fixed | `shutdown` removes `temp/<component>.pid` even when `shutdown.sh` failed, so a running process is later reported as `missing-pid-file` | Run `shutdown` with a failing `shutdown.sh` and a pid file present |
| F4 | minor, accepted, fixed | `status` prints `>>> Verified process and storage health` before it runs the check, so a failing check follows the word `Verified` (lines 115 and 116) | Run `status` in a copy whose `JAVA_HOME` is wrong |
| F5 | minor, accepted, fixed | `get_ip` (line 42) prints the seventh field of the route to `8.8.8.8`: empty without a route, and `uid` value for a route without `via` | Put an `ip` command that fails or prints `8.8.8.8 dev eth0 src 10.0.0.5 uid 1000` first in `PATH` |
| F6 | minor, accepted, fixed | `help`, no argument and an unknown argument print the usage to stderr and exit 1, while `h` prints nothing and exits 0 | `bash archappl.bash <arg>; echo $?` for each |
| F7 | minor, accepted, fixed | The usage lists `h`, and the `h` arm (line 792) is empty | `bash archappl.bash h` prints no line |
| F8 | info, accepted, fixed | The usage does not name `health --systemd <unit> <own_unit> <allowance>` (used by the timer), `storage all` or `help`, and it spells `possbile` (line 731) | Compare the usage (lines 729 to 745) with the `case` (lines 765 to 796) |
| F9 | info, accepted, fixed | The local checks do not run `startup`, `shutdown`, `restart`, `help` or `h`; `service` is checked only as unit text | `grep` the actions in `tests/health-local.py` and `tests/phase1-logic.bash` |

`shellcheck scripts/archappl.bash` reports no finding on 2026-10-11.

F1 and F2 were accepted and fixed on 2026-10-11 by the owner's direction. F3, F4, F5 and F8 were accepted and fixed the same day. For F6 and F7 the owner chose to remove `h` from the usage and the `case`, so `h` is an unknown argument like any other and `help` is unchanged; F9 is closed by the checks of the actions and of `h`. `restart` stops when its shutdown part failed, and `startup`, `shutdown`, `restart` and `service` stop when `archappl.conf` is missing or is not valid shell, and a valid file whose last command fails still runs; `status`, `storage`, `loglevel` and `help` are unchanged.

##### Scope

- The owner chooses which of F1 to F9 are fixed; each chosen finding is fixed in `scripts/archappl.bash` one at a time.
- The two must-fix findings, F1 and F2, make the exit status of a start, a stop and a restart state what happened; the owner chooses whether the other actions of the script are reviewed again after the fixes.
- For F7 the owner chooses between making `h` print the usage and removing `h` from the usage text.

Out of scope: a change of what `startup`, `shutdown`, `service`, `health` and `loglevel` do for a healthy appliance; replacing the script.

##### Completion Criteria

- Every finding of the table is fixed or recorded as a decision with its reason.
- `startup`, `shutdown` and `restart` exit non-zero when an instance script fails, and `startup` stops when `archappl.conf` cannot be read.
- Each fixed finding has a check in `tests/phase1-logic.bash` that fails on the defect, shown by a mutation of the shipped script.
- The full local suite passes.

##### Dependencies And Decisions

- No dependency. A dated owner decision on the depth of the review and on the `h` option is required before it can become Not started.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: F1 and F2 accepted by the owner on 2026-10-11
Implementation Authorization: the owner started the fixes of F1 and F2 on 2026-10-11
Superseded Plan Artifacts: none

1. The owner accepts, rejects or defers each finding of the table.
2. Fix the accepted findings in `scripts/archappl.bash`, one finding at a time, F1 and F2 first.
3. Add a check for each fixed finding to the logic checks next to the existing `loglevel` and `status` checks, run against an isolated copy with a configuration file and instance scripts.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | The script run with `startup`, `shutdown` and `restart` in an isolated copy whose engine instance script exits 1, against the shipped code and against a mutation that ignores the status | Local host | The shipped script exits non-zero; the mutation exits 0 and fails the check |
| T2 | Local | The script run with `startup` in a copy without `archappl.conf` | Local host | The script stops before it runs an instance script and exits non-zero |
| T3 | Local | The script run with `help`, with `h` and with an unknown argument | Local host | The outcome the owner chose for F6 and F7 |
| T4 | Local | The full local suite `bash tests/run-all-tests.bash --local` | Local host | Passes with the same groups as before |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-11 | Local host; launcher copy beside instance scripts that record their call and exit with a chosen status (`tests/phase1-logic.bash`, P1.28) | Pass | A failed `engine` start gives `startup ERROR engine status=1`, exit non-zero and four calls; a failed `etl` stop gives the same for `shutdown`; `restart` exits non-zero on a failed start and starts nothing after a failed stop; a copy whose status is dropped exits 0 on a failed start and on a failed stop, and a copy that ignores a failed stop in `restart` starts the instances; a failed stop keeps its pid file and removes the others; `status` takes the source address of the route (also without `via`), falls back to the host name and no longer prints `Verified`; each is seen by a copy that restores the defect |
| T2 | 2026-10-11 | Local host; the same copy without `archappl.conf` | Pass | `startup`, `shutdown`, `restart` and `service` exit non-zero and run no instance script when the file is missing or is not valid shell; a valid file whose last command fails still starts the four instances; a copy without the check, and a copy that uses the status of the last command, are seen by the check; `help` still prints the usage |
| T3 | 2026-10-11 | Local host; the launcher copy of the P1.28 checks | Pass | `help` prints the usage and exits 1; `h` prints the same usage and exits 1 like an unknown argument; the usage names `health --systemd`, `storage all` and `help`, spells `possible` and has no `h` line; a copy with the misspelled heading is seen by the check |
| T4 | 2026-10-11 | Local checkout, real Base binaries | Pass | `run-all-tests.bash --local` exit 0: Phase 1 285, Health 32, No Ant 22, Interface files 243, Phase 2 16 |

##### Closure Evidence

- Complete on 2026-10-11: F1 and F2 landed in `922c26c` and F3 to F9 in `972a312` on `origin/release-2.0.1`, the register in `72f6837` and `4686013`; T1 to T4 passed (T4: Phase 1 285, Health 32, No Ant 22, Interface files 243, Phase 2 16); #61 was closed as completed with its body synchronized and its four acceptance criteria checked. The row is in the Milestone section (D64).

##### GitHub Projection

Title: Report failed starts and stops in the appliance control script
Labels: bug
GitHub Milestone: none
Observed State: CLOSED
Observed Labels: bug
Observed Milestone: none
Last Compared: 2026-10-11 at 18:37 UTC, `gh issue view 61 --repo jeonghanlee/epicsarchiverap-env`; CLOSED at 2026-10-11T18:37:22Z, bug, no milestone, assignee jeonghanlee; one closing comment; the live body equals the synchronized draft with the four acceptance criteria checked

#### M51 - Remove the interface copy step now that the source carries the management interface

Origin: 2.0.1 / M51
Identity History: moved from Backlog to Milestone on 2026-10-23 under D64
GitHub Issue: none
Status: Complete

##### Summary

The management interface was developed in `site-template/ui` and copied over the source tree by `make copy.ui` before every Maven build. jeonghanlee/epicsarchiverap-maven carries the same 35 files since `d0932d1b`, so the copy only repeats them. The site skin of `site-template/siteid` stays here.

##### Scope

- Remove `site-template/ui`, the `copy.ui` rule and its prerequisite in the `build.*` targets, `scripts/prepare-ui.bash`, `ARCHAPPL_UI_TEMPLATE_PATH` and `ARCHAPPL_UI_TARGET_PATH`.
- The installers restore the files of an earlier copy from the source clone, stop when the selected source does not carry the interface files, and no longer tolerate a copied tree.
- `tests/ui-static.bash` keeps its checks and reads the files from the selected source clone through `tests/ui-files.list`; without a clone it skips with a message.
- `docs/README.interface.md` becomes a short pointer to the description in the source repository; the book and `CHANGELOG.md` follow; the judgements page of the book is generated from the selected source and fails without a clone.

Out of scope: the site skin and the site folder inputs; the source repository's own checks; a change of the interface itself.

##### Completion Criteria

- No tracked file names `copy.ui`, `prepare-ui.bash` or `ARCHAPPL_UI_*` outside `CHANGELOG.md`, the registers, the book's history, and the check of `tests/phase2-compile.bash` and its description in `tests/README.md` that the rendered build has no copy step.
- `make conf.archapplproperties build.mvn` on a fresh clone of the source builds four WARs whose `mgmt.war` carries every `mgmt` file of `tests/ui-files.list` under `ui/`.
- `tests/ui-static.bash` passes against that clone, reports the missing files of a source without the interface, and skips without a clone.
- `bash tests/run-all-tests.bash --local` passes.

##### Dependencies And Decisions

- Depends on jeonghanlee/epicsarchiverap-maven carrying the interface (`d0932d1b`, on `modernize`). Decisions of the owner on 2026-10-11: the static checks stay here and run against the selected source; the interface guide stays as a short pointer; the checks and the book generator behave as recommended without a clone (the checks skip, the generator fails); the release pin is a `modernize` commit at or after `d0932d1b`.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: accepted by the owner on 2026-10-11 with the decisions above
Implementation Authorization: the owner started the work on 2026-10-11
Superseded Plan Artifacts: none

1. Remove the rule, variables, script and folder; adjust the installers.
2. Retarget `tests/ui-static.bash` and remove the copy checks of `tests/phase1-logic.bash`, `phase2-compile.bash` and `database-config.py`.
3. Update the interface guide, the book, `tests/README.md` and `CHANGELOG.md`.
4. Build on a fresh clone and run the full local suite.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | `make conf.archapplproperties build.mvn` on a fresh clone of the source at the branch tip; list `mgmt.war` | Local host | No copy output; BUILD SUCCESS; every `mgmt` file of `tests/ui-files.list` under `ui/` |
| T2 | Local | `tests/ui-static.bash` against the fresh clone, against a source at `162269e7`-era content without the files, and without a clone | Local host | Passes with 244 checks; reports the missing files; skips with a message |
| T3 | Local | The full local suite with the fresh clone | Local host with real Base binaries | Exit 0 |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-11 | Local host; clone of `modernize` at `0097bc2d` | Pass | BUILD SUCCESS in about 24 s, no `copying the prepared interface files` line, `ui/index.html` present and no `mgmt` file of the list missing |
| T2 | 2026-10-11 | Local host | Pass | 244 checks pass against the fresh clone; a source without the files fails the check that names the missing files; without a clone the checks print a skip message and exit 0 |
| T3 | 2026-10-11 | Local checkout, real Base binaries, `AA_SOURCE_CLONE` set to the fresh clone | Pass | `run-all-tests.bash --local` exit 0: Phase 1 274, Health 32, No Ant 22, Interface files 244, Phase 2 14 |

##### Closure Evidence

- Complete on 2026-10-11: the removal, the installer changes and the check transition landed in `a1aab5a`, the documentation in `582eba2` and the register in `c6a05b9` on `origin/release-2.0.1`; T1 to T3 passed (T3: Phase 1 274, Health 32, No Ant 22, Interface files 244, Phase 2 14, run against a fresh clone of `modernize` at `0097bc2d`). The row has no GitHub issue and is in the Milestone section (D64).

##### GitHub Projection

Title: none
Labels: none
GitHub Milestone: none
Observed State: none; no issue exists
Last Compared: none

#### M52 - Remove the stylesheet rules, images and screenshots that nothing uses

Origin: 2.0.1 / M52
Identity History: moved from Backlog to Milestone on 2026-10-23 under D64
GitHub Issue: none
Status: Complete

##### Summary

`site-template/siteid/css/main.css` held 17 jQuery UI dialog rules (117 lines), and the site folder carried `css/mgmt.css` (641 lines) and 45 more images (about 2.3 MB with `dome.png`) that the old home page used; the documents carried screenshots of the old pages. None of the 35 interface files uses a `.ui-*` class or links `mgmt.css`; the five management pages link only `comm/css/main.css`. jeonghanlee/epicsarchiverap-maven removed the same rules from its copy of `main.css`.

##### Scope

- Remove the `.ui-*` rules from `css/main.css`; the result equals the source repository's `main.css` byte for byte (blob `3ca0ae78`).
- Remove the 45 images of `site-template/siteid/img` that no page, template or stylesheet names, with `convert.sh`, `nav-bar-bg.xcf`, `README.md` and `LICENSE.FeatherIcons`; the site folder keeps `img/LBNLLogo.png` and `img/als.ico`.
- Remove the screenshots of the old pages in `docs/technicaldocs/images` with `README.screenshots.md`, and the screenshot of the old home page in `README.md`.
- Remove `site-template/siteid/css/mgmt.css`; a site can still supply one, and the source keeps its own `mgmt.css`.
- Remove the comparison of `mgmt.css` from the VM verifier; the check of `main.css` and the images stays.
- Declare the browser icon in `template_changes.html` as `image/x-icon`, which is what `als.ico` is.
- Update the interface guide, the install guide, the book and the changelog.

Out of scope: the data journey document and its figures (`docs/README.DataJourney.md`, `docs/figures`), which the owner manages separately and verifies again after the documents are written; the source repository's own static files (`mgmt.css`, `archclient.js`, `testjson.css`), which its owner decides.

##### Completion Criteria

- `css/main.css` has no `.ui-` rule and keeps the tokens and the contrast of the shared stylesheet.
- A WAR built from a fresh clone carries `ui/comm/css/main.css`, `ui/comm/img/LBNLLogo.png` and `ui/comm/img/als.ico` equal to the site folder's files, `ui/css/mgmt.css` equal to the source's own file, and every image that a management page names.
- No tracked file names a removed image, the removed notes or the removed screenshots outside the changelog and the registers.
- `bash tests/run-all-tests.bash --local` passes.

##### Dependencies And Decisions

- Depends on the removal of the interface copy step (M51). Decision of the owner on 2026-10-11: delete what no page uses, keep the stylesheet the pages link and the inputs that a site overlays.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: accepted by the owner on 2026-10-11
Implementation Authorization: the owner started the work on 2026-10-11
Superseded Plan Artifacts: none

1. Remove the rules and the file.
2. Remove the VM check of `mgmt.css` and update the documents.
3. Build on a fresh clone and run the full local suite.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | `tests/ui-static.bash` with the contrast check; `git hash-object` of `css/main.css` against the source's file | Local host | 244 checks pass; the blob equals the source's |
| T2 | Local | `make conf.archapplproperties build.mvn` on a fresh clone; compare `ui/comm/css/main.css` and `ui/css/mgmt.css` of `mgmt.war` | Local host | Equal to the site folder's `main.css` and to the source's `mgmt.css` |
| T3 | Local | The full local suite | Local host with real Base binaries | Exit 0 |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-11 | Local host | Pass | 244 checks pass, including the contrast of at least 4.5:1; the blob of `css/main.css` is `3ca0ae7898dc263b31882fcbc2cfc9651bf3ef99`, the source's |
| T2 | 2026-10-11 | Local host; fresh clone of `modernize` at `0097bc2d` | Pass | BUILD SUCCESS in about 24 s; `ui/comm/css/main.css`, `ui/comm/img/LBNLLogo.png` and `ui/comm/img/als.ico` equal the site folder's files, `ui/css/mgmt.css` equals the source's file, and the source's default images (`archiverheader.svg`, `nav-bar-bg.gif`, `sort_*.png`) are present; a search of the tracked files finds no name of a removed file |
| T3 | 2026-10-11 | Local checkout, real Base binaries, `AA_SOURCE_CLONE` set to the fresh clone | Pass | `run-all-tests.bash --local` exit 0: Phase 1 274, Health 32, No Ant 22, Interface files 244, Phase 2 14 |

##### Closure Evidence

- Complete on 2026-10-11: the site folder cleanup landed in `ac04a08`, the documents in `f5a18f2` and the register in `bb19781` on `origin/release-2.0.1`; T1 to T3 passed (T3: Phase 1 274, Health 32, No Ant 22, Interface files 244, Phase 2 14, run against a fresh clone of `modernize` at `0097bc2d`). The VM verifier change was checked for syntax only: it runs on a VM that this host does not have, and the release verification runs it. The row has no GitHub issue and is in the Milestone section (D64).

##### GitHub Projection

Title: none
Labels: none
GitHub Milestone: none
Observed State: none; no issue exists
Last Compared: none

#### M54 - Align the documents and comments about policies, storage tiers and ETL with the code

Origin: 2.0.1 / M54
Identity History: moved from Backlog to Milestone on 2026-10-23 under D64
GitHub Issue: none
Status: Complete

##### Summary

The review of `docs/README.DataJourney.md` ran the scenario of that document through the real ETL pass scheduler, the real ETL job and the real storage plugins with a simulated clock. The ETL does not run when a partition ends. Each transition has a fixed schedule: the cadence is the source partition length (at most 8 hours), the offset is 5 minutes times (transition number + 1), and every job uses the pass start minus 60 seconds as its current time. A file with partition start `S` leaves its tier in the first pass whose start is at least `S + (hold + 1) * P + 60 s` for `gather=1`. D61 widens the work from the guide `docs/README.policies.md` to every statement of the documents, comments and test messages of the repository about policies, storage tiers and ETL. The findings known on 2026-10-18 are below; the statement list of the plan adds the rest.

1. Section 2.3.3 (example: "an ETL run at each partition boundary") and section 2.3.5 Scenario A ("as soon as the partition boundary is reached") say that the ETL runs when a partition ends. The passes start at fixed times (the Data Journey document, section 2).
2. Section 2.3.1 (Trigger: the oldest sample "is older than `hold` partitions") and the example of section 2.3.2 ("about six hours old" for `PARTITION_HOUR` and `hold=6`) understate the age by up to one partition. A file moves when `hold + 1` partition lengths have passed since its partition began.
3. Withdrawn on 2026-10-18: the sentence "in the first pass after that time" that this item quoted is not in the guide, and section 5.5 already says that the actual move waits for the next ETL pass.
4. Section 5.5 says that `gather=1` stays in the template "on STS". The template fixes `gather=1` on STS and on MTS, so `gather` cannot be changed through the Make variables.
5. Section 5.4 tells the operator to edit the installed `policies.py`. `make install` copies over it the file that `make conf` rendered from `site-template/policies.py.in`, so the edit is lost. The durable edit is in the template, followed by `make conf`.
6. Section 2.3.1 has no pointer to the pass schedule and the timeline in `docs/README.DataJourney.md` (sections 2 and 4).
7. Information only: section 2.1.1 says the file is moved "after the time elapses, according to the `partitionGranularity` setting" without the `hold` rule or the schedule.
8. Information only: the generated page `book/src/configure/policy-parameters.md` repeats the class comment of `PlainPBStoragePlugin` of the selected source (`SRC_TAG`). The comment gives the age at which a file moves as `hold` partitions and the files kept as at least `hold - gather`. The source commit `a02f9ce9` corrects the comment (`hold + 1` partitions counted from the start of the partition; `hold - gather + 1` completed files remain after a pass on schedule), and the page follows when `SRC_TAG` selects a commit that contains it. Resolved on 2026-10-18: `SRC_TAG` is `origin/modernize`, the owner keeps the local source checkout on the tip of that branch, and the page was regenerated at `6554440f`, which contains `a02f9ce9`.
9. Section 5.4 does not say that a changed `policies.py` reaches only the PVs that are archived afterwards. The store URLs of a PV are stored with its type information (checked with a SQLite and a MariaDB database), so a PV that was archived before the change keeps its `hold` and its partitions. The guide does not say how the stores of an archived PV are changed; the source has actions for it that no document of this repository names, and none was run.
10. Section 2.2.2 says that only completed files are subject to `hold`. A file of MTS that has received only some of its parts is a candidate too, and it moves when its boundary is met, as the runs of the Data Journey document show.
11. Section 2.3.4 states that two setters throw an `IOException` when `gather` exceeds `hold`. This was read from the code and not run.

##### Scope

- List every statement about policies, storage tiers and ETL in: `docs/README.policies.md`, `docs/README.install.md`, `docs/technicaldocs/`, `docs/README.vmtests.md`, `tests/README.md`, the pages of `book/src` that are not generated, the explanatory comments of `configure/`, `site-template/` and `scripts/`, and the messages and comments of `tests/`.
- Compare each statement with its code source and class it as match, mismatch or unverifiable. Correct a mismatch in the document or comment. Run a statement about when or how a file moves on the real classes before it is written.
- Report a defect of the code to the owner of the code instead of making the document follow it.

Out of scope: history records (`CHANGELOG.md`, `docs/milestone-*.md`, `docs/reports/`, GitHub issues); `docs/README.DataJourney.md`, its book page and the figures, which change only when a finding requires it; the generated book pages, which follow the selected source (D56); any change of the behavior of the code of this repository or of the source repository.

##### Completion Criteria

- The statement list covers every in-scope file; each statement names its code source and its class.
- Every mismatch is corrected, or reported to the owner of the code, or recorded as unverifiable with the check that would settle it.
- Every statement about when or how a file moves was run on the real classes or on an installed guest.
- A second-person review of each corrected group by a reader who calculates the move times for the shipped policy and for `PARTITION_5MIN` finds nothing above the severity floor.
- Every link and anchor of the corrected passages resolves, `git diff --check` is clean, the book builds with the pinned mdBook release, and the generated pages are current.

##### Dependencies And Decisions

- D59 records the first findings. D61, dated 2026-10-18, widens the scope and orders the work.
- The generated page `book/src/configure/policy-parameters.md` follows the tip of the source branch `origin/modernize` that `SRC_TAG` names; it is regenerated with `book/scripts/generate-all.bash` after the local source checkout moves.
- Statements of `docs/README.policies.md` are changed under the direction of D61; the guide names Sangil Lee and Jeong Han Lee as authors.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: accepted by the owner on 2026-10-18
Implementation Authorization: the owner directed the work on 2026-10-18
Superseded Plan Artifacts: the draft plan of D59

1. Build the statement list for each file group: `docs/README.policies.md`; the install and service documents; the pages of the book; the comments of `configure/`, `site-template/` and `scripts/`; `tests/`. The list is a working file outside the repository.
2. Verify each statement: read the code; run the `make` statements in a copy of the repository with the install path set to a scratch folder; run the statements about files on the real classes or on a retained guest.
3. Correct the documents and comments group by group, one commit per group, and withdraw or correct the findings of this detail that the list shows wrong.
4. Report the defects of the code to its owner.
5. Review each corrected group with the second-person review and apply the findings above the floor.
6. Record the observed results and close the item when the criteria hold.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Compare the statement list with `git ls-files` of the in-scope paths | Local host | Every in-scope file appears in the list or is named as without statements |
| T2 | Run | Run each statement about when or how a file moves on the real classes or on a retained guest | Local host; retained guest | Each statement is confirmed by the observed run or corrected |
| T3 | Local | Run each `make` statement in a copy of the repository with the install path set to a scratch folder | Local host | Each statement is confirmed by the output or corrected |
| T4 | Review | Second-person review of each corrected group by readers that compute the move times for the shipped policy and for `PARTITION_5MIN` | Local host | No finding above the severity floor |
| T5 | Local | Check every link and anchor of the corrected passages, run `git diff --check`, build the book with the pinned mdBook release and run `book/scripts/check-generated.bash` | Local host | All targets exist; no whitespace error; no warning; every generated page current |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-18 | Local host | Pass | `git ls-files` of the in-scope paths (160 files, UI folder and binaries excluded) swept for ETL, STS, MTS, LTS, hold, gather, `policies.py`, `partitionGranularity` and the store names; every file with a hit is either in the four reader lists (`statements-policy-domain.md`, not tracked) or was read in this sweep (glossary, health, storage, components, install pages, `archappl.properties.in`, `tests/health-starting.bash`, scripts); no further mismatch |
| T2 | 2026-10-18 | Local host; retained guest | Pass | Real `PBThreeTierETLPVLookup`, `ETLPassTicker`, `ETLPassDriver`, `ETLJob` and `PlainPBStoragePlugin` with a simulated clock for hold 0 to 6, gather 0 to 4, header-only and zero-byte files, post-processing, reload and stored URLs; pass schedule and a 70-minute real-clock ETL run and the MariaDB persistence case on a guest. The hold 6 `PARTITION_HOUR` example (STS `PARTITION_HOUR`, MTS `PARTITION_DAY`, 10:00 file left STS at 17:05) and the 5-minute test host example (STS `PARTITION_5MIN`, MTS `PARTITION_HOUR`, hold 2, gather 1: the STS 10:00 file left at 10:20, the MTS 10:00 file at 13:10:05) were run on 2026-10-18 21:58 PDT with the scratch copy of the ETL classes; the ETL selection code and the scheduler are identical in the source at `6554440f` (the differences are timing metrics, display, a time parse error handler and a comment) |
| T3 | 2026-10-18 | Local host | Pass | `make conf.policies` and the `make -n` targets run in a scratch copy with the install path, `SUDO` and the user overrides set; `run-all-tests.bash --local` exit 0 at the source tip `6554440f` after the last edit of the comments, with the real Base binaries: Phase 1 273 passed, Health 32, No Ant 22, Interface files 345, Phase 2 14, none failed (2026-10-18 PDT, `local-suite-6554440f-r2.log`, not tracked) |
| T4 | 2026-10-18 | Local host | Pass | Five readers (P1 to P5, a new seat each) audited the guide and the other changed files against the code and the run logs; every item above the floor is applied. P5 found the Completed State definition against partial MTS files (section 2.2.2 now defines Completed per tier and names the partial file as an exception) and the time window of the MONITOR sentence; both corrected. Edits after P5 are the wording of section 2.2 and 5.1 and of two property locations, read back by the author only |
| T5 | 2026-10-18 21:25 PDT | Local host | Pass | `git diff --check` exit 0; pinned mdBook 0.5.4 build exit 0 with no warning; `book/scripts/check-generated.bash` all five pages current after `configure/variables.md` was regenerated; the links of the guide resolved in the third reader audit |

##### Closure Evidence

- Closed on 2026-10-19 after the criteria held. Commits on `release-2.0.1`: `08dc331` (comments and messages of the rendering rules), `02c910f` (policy guide), `c201ec2` (storage tiers page and plan rows), `777724f`, `ed7505d`, `66f4516`, `81f6949`, `eee2723`, `c305587`, `8cb926b`, `ee052de` and `ef49d3a` (register, generated page, example runs, interface check list, test README count and unused macro); the commit that carries this closure adds the references of the guide to the issues below.
- Defects of the code, reported to its owner and filed in epicsarchiverap-maven: [#49](https://github.com/jeonghanlee/epicsarchiverap-maven/issues/49) (`optimized_N` as `reducedata` ignores N), [#50](https://github.com/jeonghanlee/epicsarchiverap-maven/issues/50) (`reducedata` together with `pp`), [#51](https://github.com/jeonghanlee/epicsarchiverap-maven/issues/51) (pp files of a moved partition stay in the source store). The documentation corrections of epicsarchiverap-maven are `8b8a0ae3` (hold and gather row, policy re-read) and `41c33cdf` (pass driver, 60 second margin).
- The local source checkout follows the tip of `origin/modernize`; the generated policy parameters page was regenerated at `6554440f`, which contains `a02f9ce9`.
- Verification Results above hold the observed runs and reviews. After the last review, the edits were the example runs, the unused macro and the issue references; the issue references were read by the author only.

##### GitHub Projection

Title: none
Labels: none
GitHub Milestone: none
Observed State: none; no issue exists
Last Compared: none

#### M55 - Measure the stop time of the appliance with data in the short term store

Origin: 2.0.1 / M55
Identity History: moved from Backlog to Milestone on 2026-10-23 under D64
GitHub Issue: none
Status: Complete

##### Summary

`make sd_stop` stops the four instances in the order engine, retrieval, etl and mgmt. The unit waits up to `SYSTEMD_TIMEOUT_STOP_SECONDS` (300 seconds by default).

When the ETL component receives the stop, it waits for the running pass of each driver, up to the property `org.epics.archiverappliance.etl.common.ETLPassStopWaitSeconds` (60 seconds by default); a pass starts no further job after the stop flag is set, so the wait bounds the one job that runs, not the pass. It interrupts the worker threads and waits once more up to the same value. It then runs one job for each PV whose store sets `consolidateOnShutdown`, one after the other and without a time limit of its own. Each job uses a processing time one year ahead, so the hold keeps no file back (`PBThreeTierETLPVLookup`). The shipped policies set the option on the short term store only.

The unit kills the processes that run when `TimeoutStopSec` (`SYSTEMD_TIMEOUT_STOP_SECONDS`) ends (`KillMode=mixed`). A PV that the loop has not reached by then leaves no line in the log. The error line "PVs left unconsolidated", written after the whole loop, counts only the PVs whose job runs after the wait and the PVs that the skip environment variable names. The loop writes one error line for each such PV ("Not consolidating <pv> ... still running" or "... names its destination"). The lines of the individual jobs are written at debug level, and the shipped root level is info (`ARCHAPPL_ROOT_LOGGER_LEVEL`).

The duration of the stop grows with the number of PVs and with the data in the short term store. No measurement of it exists across the PV count, the data volume and the phase of the stop (the two stops of ansible-provision at 903 PVs are in the Scope), and the code does not show whether 300 seconds suffice. The property `ETLPassStopWaitSeconds` is documented in the source repository (`docs/book/src/configuration.md`, `docs/design-etl-pass-scheduler.md`) and not in the templates or documents of this repository; it is read from the installed `archappl.properties`, which `make install` renders from `site-template/archappl.properties.in` without a placeholder for it, so a site has no hook for the property in this repository, and setting it means a change of the template (a separate item).


##### Scope

Terms

- A pass is one run of the ETL jobs of the PVs that share a transition and a cadence ([The Data Journey](README.DataJourney.md)). The cadence of the first transition is the partition length of the short term store; a pass starts at a partition grid time plus 5 minutes, except the start-up pass that runs once when the ETL component starts and the passes that wait for a running pass.
- The hold is the setting of the store that keeps files back; a file moves in the first pass at or after the start of its partition plus (hold + 1) partitions plus 60 seconds ([policy guide](README.policies.md), section 2.3).
- A stage is a PV count. A cell is one stage on one partition. The main cells are the stage of 903 PVs and the stage of 3000 PVs on the partition `PARTITION_5MIN` with the hold of 2. The validation cell is the stage of 903 PVs on the shipped partition `PARTITION_HOUR` with the hold of 2. A stop is one stop of the unit; each main cell has three stops and the validation cell one.
- The unit is `epicsarchiverap-maven.service` (`SYSTEMD_FILENAME`). The evidence members are the retained files of the runs: journal cuts, unit results, listings, cuts of the ETL log, frozen configuration. The replay rebuilds the table from copies of the members.

Target and environment

- Measure the stop of the installed appliance on one Debian 13 guest (G9). The engineer of the requester session installs the appliance with the local SQLite installation (`scripts/install-local-sqlite.bash`, [installation guide](README.install.md)); the provider installs nothing. SQLite is the owner choice of 2026-10-19. The reset is a deletion of files (see Order and reset). The target `PVTypeInfo.show` rejects SQLite, so the stored URL of a PV is read through the BPL `getPVTypeInfo`.
- A real `softIoc` serves the PVs. Copy the EPICS Base binaries of the host (`/home/jeonglee/alsu-epics/1.3.0/debian-13/7.0.10/base`, about 339 MB) to the guest with `bin` and `lib` together, because the run path of `softIoc` is relative to its location. Install the package `libreadline8`, which `softIoc` needs and `configure/os/debian13.pkgs` does not name. `AA_TEST_EPICS_BIN` is the absolute `bin/linux-x86_64` folder on the guest with `softIoc` and `caget`. The IOC and the appliance run on the same guest, so `EPICS_CA_ADDR_LIST` is `127.0.0.1` with the auto address list off, as in `scripts/verify-local-pv.bash`, and the IOC gets `EPICS_CAS_INTF_ADDR_LIST=127.0.0.1`, `EPICS_CAS_AUTO_BEACON_ADDR_LIST=NO`, `EPICS_CAS_BEACON_ADDR_LIST=127.0.0.1` and `EPICS_CA_MAX_ARRAY_BYTES=16384` (the variables of `install-fixture.py` of ansible-provision); the engine finds the IOC through `EPICS_CA_ADDR_LIST` of `archappl.conf`.
- The owner defers Rocky Linux 8.10 to a separate item after the Debian 13 result. The register records that the journal reader of systemd 239 hides lines (G7, M45), which matters for a measurement that reads the journal.
- Context: ansible-provision observed whole-unit normal stops of 12.516 and 13.770 seconds at 903 PVs on two Rocky Linux 8.10 guests (the shortened and the default chain, its own PV set, installed timeout 300 seconds, aa-maven 120d53fe, aa-env 6599fbb1; observations of 86400 seconds that ended on 2026-10-15; register of ansible-provision, `docs/milestone-38560eb.md`). Those values are the wall time of a blocking `systemctl stop` of the whole unit, taken with the monotonic clock of a Python process (`tests/archiver-soak/etl-pass/observe.py`), after a 24-hour run with an uncontrolled phase of the stop and an unrecorded file count of the short term store, on MariaDB, Rocky Linux 8.10 and 256M heaps. They record no stop time of an instance and no left PV. At 903 PVs they leave the per-PV part of the stop near 5 milliseconds, which puts the stop time at 300 seconds above 10000 PVs. This item therefore adds a stage of 3000 PVs, a controlled phase and the per-instance and per-job times, and does not replace those values.
- Keep the shipped log level (info) for the root logger, so that the logging does not change the stop time. Keep `ETLPassStopWaitSeconds` at its default of 60 seconds, which is not in the installed `archappl.properties`, and record that. The two waits take up to 120 seconds of the 300 seconds of the unit. A stop during a running pass, which would exercise that value, is not part of this item; because the wait bounds one job, the longest job of the pass records (`slowestMillis`) is the evidence for its size, not the duration of a pass.
- Settings that the purpose needs and the base guest lacks, which the engineer sets on the guest and records: a persistent journal (a drop-in of `journald.conf` with `Storage=persistent`, a `SystemMaxUse` large enough for the largest stage, and the rate limit of the ansible-provision role `archiver_build`: 30 seconds and 10000 messages; the role is the model, `roles/archiver_build/tasks/main.yml`), time synchronization with `chrony` (the package is in `configure/os/debian13.pkgs`; record `chronyc tracking`), the package `rsync` for the transfer of the evidence (not in `configure/os/debian13.pkgs`), and outbound network access of the guest for the installation. The service account is `tomcat` (`AA_USERID`), the default of the local installation; the heap setting of each instance and the journald rate limits are part of the frozen configuration. The health timer of the installation stays active; it skips a unit that is stopping, and its state is part of the frozen configuration.
- Fix the refs before the first install and keep them for the whole run: the commit of this repository (the tip of `release-2.0.1` at the start of the run) and the source ref `SRC_TAG` (the tip of the branch `origin/modernize` at the first install, the owner choice of 2026-10-19; the resolved commit is recorded and not changed during the run). The checkout of this repository lies in the home folder of the engineer on the guest, and `../CONFIG_SITE.local` is the file one folder above its top.
- State in the report the differences between the measured guest and a production deployment: the three tiers lie on one virtual disk (a production short term store on tmpfs or SSD and a medium term store on another disk or NFS changes the copy time of the loop, which is the largest risk that no cell tests), the memory is 4 GiB with the IOC on the same two vCPUs (the page cache), the heap value of each instance (`AA_JAVA_HEAPSIZE`, recorded; the stage of 3000 PVs may put the 256M heaps under garbage-collection pressure, and heap sizing itself is M41), the added file appender (one write for each pass and about one line for each PV at the stop), SQLite instead of the MariaDB of other deployments (the loop does not use the database; the effect is on the management instance), and Debian 13 instead of Rocky Linux 8.10.

The test PV set

- Reuse the 903 PVs of ansible-provision (owner choice of 2026-10-19), and add 2097 generated PVs for the stage of 3000 PVs (owner choice of 2026-10-19). The 903 PVs lie in the repository of ansible-provision, `tests/archiver-soak/fixtures/`: the IOC databases `aasoak.db`, `load1.db` and `load2.db`, and the PV lists `pvs.csv` (100 PVs), `pvs-load1.csv` (400) and `pvs-load2.csv` (403); `pvs-all.csv` (903 rows) has the SHA-256 `037a92691bc23a6dcac37ec3613ad19c9f80b93b689209ec8dc403b519eaf594`. Its generators are `baseline/gen_soak.py` and `baseline/gen_load.py`. Copy the files at a pinned commit (recorded) unchanged and check them. ansible-provision stays the single writer of the files; the copy changes nothing there, and its session is informed by message.
- The mix of the 903 PVs (counted from the PV lists): 110 PVs of the policy `VeryFast` (0.1 seconds), 10 of `Fast`, 10 of `Medium`, 773 of `Default`, 8 waveforms of 1000 elements, 783 PVs that update every second, 110 every 0.1 seconds and ten every 10 seconds (`AASOAK:SLOW:CH01` to `CH10`). The deadband override of ansible-provision (`retest-deadband.db`) is applied: it sets `MDEL` and `ADEL` to -1 for the ten records of the group `deadband`, which otherwise change rarely, so that every update of these PVs is archived. The IOC databases carry more records than the lists archive (`aasoak.db` 110 records for 100 PVs, `load2.db` 406 for 403; the helper records `*_SRC` feed the enum, string and waveform records), so the record count of the IOC is not the PV count. The database is SQLite and the account `tomcat`; the ansible-provision installation uses MariaDB and the account `mid-srv`, which this item does not use.
- The script `tests/stop-time/gen-pvs.bash <output folder>` generates the 2097 further PVs `STOPTIME:E0001` to `STOPTIME:E2097` as the file `extra.db` and the PV list `extra.csv`. `extra.db` has the form of `load1.db`: one header comment line, then for each PV a `calc` record with `SCAN` `1 second`, `INPA` the own value with `NPP`, `CALC` `(A+1)%3600`, `VAL` 100 times the index and `PREC` `1`, with one blank line between records. `extra.csv` has the columns of the other lists (`pv`, `group` `extra`, `scan` `1 second`, `method` MONITOR, `period` `1.0`, an empty `policy` for `Default`, and `store_key`). The lists of ansible-provision end their lines with CR LF; `extra.csv` and `extra.db` end them with LF, and the parsers of this item strip a trailing CR from every field. The generator is deterministic: two runs give files with the same SHA-256, which `selftest.bash` checks. The stage of 3000 PVs is the 903 PVs and these 2097. Its share of fast PVs is lower (110 of 3000) than that of the stage of 903 PVs (110 of 903), so the PV count and the data rate vary together; the report states this limit.
- The IOC runs as a system unit `stop-time-ioc.service` that the engineer installs on the guest. The unit runs as the account `tomcat` and starts `softIoc -S -d aasoak.db -d load1.db -d load2.db -d extra.db -d retest-deadband.db`, with the list of `-d` options in a drop-in `stage.conf` of the unit that the engineer writes for the stage (`extra.db` only in the stage of 3000 PVs) and `retest-deadband.db` last, because the records of the override merge into the records of the files before them in the order of the `-d` options. The unit is enabled, so that it comes back after a reboot of the guest, and carries the IOC environment above. Switching the stage is: write `stage.conf`, `systemctl daemon-reload`, restart the unit, and read the ten `MDEL` and `ADEL` fields and one PV of each database with `caget`. The rehearsal reads the fields `MDEL` and `ADEL` of the ten records through Channel Access and requires -1 before the first archiving. The scripts `apply-fixture.py` and `install-fixture.py` of ansible-provision belong to its environment (account `mid-srv`, the Rocky path of Base, the unit `etl-soak-ioc.service`) and are not used. The unit file and the IOC environment are part of the frozen configuration.
- Archive the PVs of the stage with one POST to `/mgmt/bpl/archivePV` with `Content-Type: application/json` (exactly that value; a value with a charset takes another path of the action and fails), as ansible-provision does in `register.py`: the body is a JSON array with one object for each PV, with `pv`, `samplingperiod` and `samplingmethod` from the columns `period` and `method` of the PV list and `policy` when the column is not empty. This reproduces the 880 PVs of the method MONITOR and the 23 of the method SCAN of the set of 903 PVs. The installation guide shows a GET with `pv` only; the list of the 773 PVs of the policy `Default` is 13038 bytes, above the default header limit of 8192 bytes of Tomcat, and the body of a POST has no such limit. Archiving is done when `GET /mgmt/bpl/getPVStatus` (without `pv` it returns every PV that has type information; a PV in the state "Initial sampling" is not in the list, so the number of entries must reach the number of PVs of the stage) shows for every PV exactly one entry with `status` `Being archived` and `connectionState` `true`. Read the stored URL of one PV of each policy with `GET /mgmt/bpl/getPVTypeInfo?pv=<pv>`. The sampling period sizes the sample buffer, and the policy `Default` would drop samples of a 10 Hz PV, so every PV keeps the policy of its row. The rehearsal checks that the short term store holds about 10 samples per second for a 10 Hz PV.

Cells, order and reset

- Order of the runs: the reset after the rehearsal, the three stops of the main cell `main-903`, the reset, the three stops of the main cell `main-3000`, the change of the policy to the shipped values with the reset, and the validation stop of the cell `validation-903`. These three strings and the rehearsal cells `rehearsal-25` and `rehearsal-100` are the values of `--cell`. Render the settings of the main cells (`PARTITION_5MIN`, hold 2) through `ARCHAPPL_STS_GRANULARITY` and `ARCHAPPL_STS_HOLD` in `../CONFIG_SITE.local` before the first install, so that the first archiving uses them. The validation cell uses the shipped values, written into the same file as `PARTITION_HOUR` and `2` (not removed, so that the frozen file shows them); the owner chose them so that the report shows how the stop time of the 5-minute partition compares with the shipped state. The hold of 5 is not measured. The 15-minute and hourly matrices are not measured by this item; M56 and M57 measured them (Deferred on 2026-10-19; reopened and Complete on 2026-10-21).
- A policy change reaches only the PVs that are archived afterwards, because the store URLs with the hold are stored in the type information of each PV (policy guide, section 5.4). The reset calls `make` without the variables that the local installation script passes, so `../CONFIG_SITE.local` carries `DB_BACKEND=sqlite` (`ARCHAPPL_SITEID` defaults to `als`; `DB_BACKEND` defaults to `mariadb`, and a `make conf.archapplproperties` or `make conf.install` without it renders the context files or the unit for MariaDB, after which the unit does not start). The steps that run as root render nothing into the checkout (M58): the engineer renders the units with `make conf.install` and the schema with `make sql.update` first, so the checkout stays writable for the engineer. (The measurement of this item ran before that change; it gave the files that `sudo make install` and `sudo make sql.fill` had rendered as root back to the engineer after each such command.) The reset and the policy change are one sequence, which the rehearsal proves: `make sd_stop`; edit `../CONFIG_SITE.local` when the policy changes; `make conf.archapplproperties` (check the STS URL of the rendered `site-template/policies.py`); `sudo make conf.storage.rm` (it removes `ARCHAPPL_STORAGE_TOP`, so the stores of all three tiers and the SQLite file go together; the leading `-` of the rule hides an error, so list the folder afterwards and require that it is gone); `sudo make conf.storage` (the folders of the three tiers; under `sudo` the placement check of the storage path sees the home of root, which only changes its warning); `make sql.update`, `sudo make sql.table.fill` and `sudo make sql.show` (the folder `config` and the schema of the SQLite file, which `conf.storage` does not create; the local installation script runs the same targets); `make conf.install` and `sudo make install` when the policy changed (it installs the rendered files and does not start the unit); switch the IOC to the stage (below); `make sd_start`; archive the PVs of the stage; check the stored URL of one PV of each policy with `getPVTypeInfo`. Between stages without a policy change the same sequence runs without the edit and without `make conf.install` and `sudo make install`. A stop moves the data of the short term store into the medium term store, so the reset empties the medium and long term stores too; a stage is not grown by adding PVs.
- Between the stops of one cell the PVs stay archived. After a stop start the appliance, wait until every PV shows `Being archived` and `connectionState` `true` (archiving resumed 55 to 60 seconds after a restart in ansible-provision), wait for the partition boundary, accumulate, and stop. When the window of a stop is missed (the engineer was away, or the listing failed twice), the appliance is not restarted: in the steady state the short term store holds hold + 2 files of every PV between a boundary and the next pass, so any following boundary serves as E and the window applies to it; the status file records the planned E and the E actually used. The B0 rule applies only to the first stop after a start of the appliance, and the accumulation bound of (hold + 2) partitions plus 30 seconds applies only to that stop. A restart of the appliance that is not a measured stop is avoided; if one is needed (a reboot of the guest, a failed start), it is recorded in the coverage table as an auxiliary stop with its reason, and the next stop follows the B0 rule.

Accumulation and the phase of the stop

- Passes run at fixed times, and a file moves in the first pass at or after the start of its partition plus (hold + 1) partitions plus 60 seconds. With the cadence equal to the partition length, the first transition runs its pass 5 minutes after each partition boundary. For the 5-minute partition that is the next boundary, so the pass and the boundary coincide.
- Every stop takes place with hold + 2 = 4 files of each PV in the short term store. At the boundary that ends the (hold + 1)-th partition of data the first file has not moved, and the new partition has just opened its file.
- Rule. B0 is the first partition boundary at least 30 seconds after every PV shows `Being archived` and `connectionState` `true` following the restart, so that every PV has a partial file of the partition before B0. The boundary E is B0 plus (hold + 1) partitions. For the hourly partition stop between 30 and 90 seconds after E, which lies before the pass at 5 minutes past E. For the 5-minute partition the pass and the boundary coincide, so stop between 30 and 60 seconds after E, after that pass has started. The lower bound of 30 seconds covers the scan of 10 seconds of the slowest PVs and the write period of the engine of 10 seconds. The accumulation of a stop is the time from the restart to E, at most (hold + 2) partitions plus 30 seconds: 20.5 minutes in a main cell and 4 hours in the validation cell. Nominal accumulation from B0 to E is 15 minutes and 3 hours.
- After a restart the engine archives from the restart time, not from a boundary, so the first file of a PV is a partial file of the partition that contains the restart. For the hourly partition that file moves before E; for the 5-minute partition it moves in the pass at E, which is why the 5-minute stop follows that pass.
- The rule holds for this IOC: after the override of the deadband every PV updates every 0.1 seconds (110 PVs of the set of 903), every second or every 10 seconds (the ten PVs `AASOAK:SLOW:CH01` to `CH10`), so every PV has a file of the new partition within the lower bound of 30 seconds. The listing must show hold + 2 files of every PV; the listing decides. If it does not show them inside the window, do not stop: wait for E plus one partition and check once more; if the second check also fails, stop and mark the stop `off-rule`. A 10 Hz PV can lose a sample when a write pass of the engine is delayed ([epicsarchiverap-maven#29](https://github.com/jeonghanlee/epicsarchiverap-maven/issues/29)); the rule counts files, not samples.
- Check overlap for every stop and for every driver, the first transition (pass 5 minutes after each partition boundary) and the second transition (with the shipped medium term store partition `PARTITION_DAY` at 00:10, 08:10 and 16:10 UTC). The launcher line `archappl-etl: stopping pid` is written just before the signal to the ETL JVM. The ETL component stops its ticker after the stop sequence of Tomcat; the log file has the line "Shutting down ETL threads." at the moment when the ETL component begins to stop, and the ticker checks every 5 seconds, so the table uses the time of that line plus 5 seconds as an upper bound of that moment.
- A stop overlaps a pass when a pass of any driver is running at the start of the stop (`ActiveExitTimestamp`), or is scheduled to start between that start and the time of the stopped ticker. A pass that starts in that interval runs normally and moves files, so the count of files can fall to hold + 1. Before a stop on the 5-minute partition `run-stop.bash` reads `etl-pass.log` and requires the pass record whose `plannedAt` is E (the listing alone shows only that the partial file moved, not that the pass ended); it waits inside the window until the record is present, and a window that ends without it makes the stop `off-rule`. An overlapping stop is marked and reported apart. A wait of the ETL component on a running job shorter than the stop wait of 60 seconds leaves no line at the shipped level; the stop time of the ETL instance is measured, and an excess over the expectation above 20 percent and above 5 seconds is marked.
- Re-run rule: a stop that is marked as overlapping, off-rule or Incomplete is repeated once (accumulate and stop once more) and then both stops stay in the table with their marks; the repeated stop carries the number of the original with the suffix `r` (`--stop 2r`), and the coverage table lists both. Before the repeat the status file carries `pending=<cell>/<stop>r`, and `run-stop.bash` removes the key when the repeat is recorded, so that a successor reads from the directory whether a repeat is due. The fit uses the stops that follow the rule and are not Incomplete, and the report states the stops actually used. A stop that is interrupted before the stop command is repeated from the accumulation with the same suffix, and the coverage table lists both.
- The start-up pass runs once when the ETL component starts after each restart. It finds an empty short term store and moves nothing.

Pass events and the shutdown jobs

- Copy the `log4j2.xml` of the WAR (installed instances carry it under `WEB-INF/classes`) to a site file that the service account `tomcat` can read (mode 644, not under the home folder of the engineer), name it in `ARCHAPPL_LOG4J_SITE_FILE`, and run the stop/install/start procedure of the installation guide once. Check that `archappl.conf` carries `LOG4J_CONFIGURATION_FILE` with the path: a missing or unreadable file makes log4j2 fall back to an error-only console configuration without the priority prefix, and the journal loses its info lines.
- The site file adds, in `Appenders`, a file appender `ETLPASS` with `fileName="${sys:catalina.base}/logs/etl-pass.log"`, `createOnDemand="true"` (the four instances read the same file, and only the ETL instance writes) and the pattern `%d{yyyy-MM-dd'T'HH:mm:ss.SSS}{UTC}Z %-5level [%t] %c - %m%n`. It adds, before `Root`, two loggers at level debug with additivity off, `org.epics.archiverappliance.etl.common.ETLPassDriver` and `org.epics.archiverappliance.etl.common.PBThreeTierETLPVLookup`, each with two appender references: `ETLPASS` and `STDOUT` with `level="info"`. The second reference keeps the info and error lines of these loggers in the journal; without it the error lines of the driver vanish from the journal, and with additivity on the debug lines reach it. A real run with log4j-core 2.26.1 proved this fragment. The root level and the journal stay at info.
- The file holds one line for each pass (the pass record), the line "Shutting down ETL threads." when the ETL component stops, and one line "Need to consolidate data from etl source ... for pv ..." before each job of the loop at the stop. On the guest the file of the ETL instance is `<AA_INSTALL_LOCATION>/etl/logs/etl-pass.log`, owned by `tomcat`; read it with `sudo`. Record its size in bytes before and after each stop; the cut of a stop is the bytes between the two sizes, a line without a time stamp (a stack trace) belongs to the line before it, and a pass record is written at the end of the pass, so the passes around a stop are read from the whole file, which is copied into the evidence at the end of each stage. The pass details of the PV details page are not used, because its figure of the last job time is a running sum.
- The time of a job of the loop is the gap between two consecutive lines "Need to consolidate", so that K lines give K - 1 times. The last job has no end line: the report gives it as not available, with the time to the end of the ETL instance as an upper bound that does not enter the maximum. The rehearsal proves the file, compares its times with the schedule, and checks with the final site file that it does not change the stop time of a rehearsal stop.

Measurement

- Stop the unit with `sudo systemctl stop <unit>`, which is what `make sd_stop` runs with its exit status ignored; keep the exit status. Take the stop duration from the monotonic properties of the unit, `InactiveEnterTimestampMonotonic` minus `ActiveExitTimestampMonotonic` (`systemctl show --timestamp=us+utc -p ...`), so that both values come from one clock. Take the UTC stamps from `ActiveExitTimestamp` and `InactiveEnterTimestamp`. Read `systemctl show -p Result` before the next start, because a start resets it.
- The launcher prints one line `archappl-<service>: stopping pid <pid>` for each instance to the unit journal and no end line. The stop time of an instance is the gap to the next such line, and the stop time of mgmt is the gap to the end of the unit. The engine gap runs from the line of the engine to the line of the retrieval, the ETL gap from the line of the ETL instance to the line of the management instance, and the management gap from its line to `InactiveEnterTimestamp`.
- Take a journal cursor before the stop (`journalctl -u <unit> --show-cursor -n 0 -q`). Cut the journal with it (`TZ=UTC journalctl -u <unit> --after-cursor=<cursor> -o short-iso-precise`; the original text of every line is kept, and the first and the last record of each cut are identified by their cursor and time, not only counted). The launcher lines, the error lines and the info lines are in the journal. The pass records, the line "Shutting down ETL threads." and the lines "Need to consolidate ..." are in the file `etl-pass.log`. Both are required evidence.
- The cursor command returns three cases that the script tells apart: a line `-- cursor: ...` (use it), an empty output with status 0 (the unit has no entries, or the user may not read its entries; the engineer is a member of the group `systemd-journal` or uses `sudo`, and the script checks this before the first stop; take the cursor after the first start), and, for an `--after-cursor` read, the message `Failed to seek to cursor` (a lost cursor, cut by time stamps instead) or `-- No entries --` (an empty cut). Identify the first and the last record of a cut from a second read of the same cut in `-o export` format (`__CURSOR` and the time stamp).
- The shipped level shows only the error lines: the per-PV lines and the count of left PVs described in the Summary. The consolidated PVs and the PVs that the loop did not reach therefore come from the listing of the three stores before and after the stop. The files of a PV are `<store_key>:<partition label>.pb` in each store. The key is the PV name with every separator of the installed property `siteNameSpaceSeparators` (`:`, `-` and `_` in the shipped `archappl.properties`) replaced by `/` (`ConvertPVNameToKey`); applied to the 903 PVs this rule reproduces the column `store_key` of the lists without a mismatch, and for the generated names only `:` occurs. The parsers of this item take the key from the column `store_key` of the lists and never derive it, and a PV name in an error line is mapped to its key with the same lists.
- Check the completeness of the journal: the four launcher lines per stop, the first and the last line of the cut, the retention setting (`SystemMaxUse`) and the size of the journal after a stage. A cursor taken in a quiet journal may not be found afterwards (observed on systemd 239); check that the cut starts at the cursor, and otherwise cut by the timestamps of `ActiveExitTimestamp` and `InactiveEnterTimestamp`. A missing required line makes the stop Incomplete. The exception is a stop that the unit ended with SIGKILL, where the lines of the instances not stopped are absent by design and the result `timeout` is the observed outcome.
- Freeze for every stop the rendered `policies.py`, the site `log4j2.xml`, the settings of journald and chrony (with `chronyc tracking`), the environment of the IOC and the unit file `stop-time-ioc.service`, the SHA-256 of `softIoc` and `caget`, the status file, the expectation files, `../CONFIG_SITE.local`, the installed `archappl.properties` and `archappl.conf`, the refs of this repository and of the source, the kernel and the JDK.
- At the start of each run publish the stage, the start time and the intended end in a status file on the guest and in the terminal of the run, and keep the checkpoints in the evidence. The status file also records the actual end time. Keep the standard output, the standard error and the exit status of every command of the run, failed ones included (`archivePV`, `getPVStatus`, `make install`, `chronyc`, `journalctl`, `systemctl`), in the evidence directory before any reset or cleanup. No fault is injected in this test; a stop that the unit ends is an observed outcome.

Claims, expectation and the fit

- Claims, each with the verdict of the test framework (Passed, Failed, Incomplete). C1, per stop: the stop is measured with complete required evidence (the journal cut with the four launcher lines, the unit properties and result, the listings before and after, the frozen configuration, the cut of `etl-pass.log`); Passed when all are present and usable, Incomplete when any is missing or unusable. C2, per stop: the stop suffices (result `success`, duration at most `SYSTEMD_TIMEOUT_STOP_SECONDS`, no PV left); Passed when it holds, Failed when the evidence shows otherwise. A confirmed violation stays Failed even when other evidence of that stop is Incomplete. C3, the validation stop: its duration lies inside the written 95 percent prediction interval of one more stop of the main cell of 903 PVs; Passed, Failed or Incomplete in the same way.
- A stop that the unit ended (`timeout`) is an observed outcome and the Failed result of C2, not a tool error. A failure of a query or of the parser is a tool error, is reported apart, and does not make a stop Failed; missing required evidence stays Incomplete. Overlap and a stop outside the rule (`off-rule`: the time after the boundary outside the window, or a listing that does not show hold + 2 files of every PV) are qualifiers: a qualified stop keeps its C1 and C2 results and is left out of the fit. A cell suffices when all its stops that are Passed for C1 are Passed for C2; the report states how many stops of the cell this covers.
- Expected native status: the rehearsal records the exit status of `systemctl stop` for a normal stop and for a stop cut at `timeout`. The cut is exercised on the rehearsal guest by shortening `SYSTEMD_TIMEOUT_STOP_SECONDS`, a declared configuration change that the rehearsal reverts. The native status is stored apart from the verdict. The run stops as Incomplete when the guest is lost, the IOC does not serve the stage, the journal is not persistent, or the use of the root file system reaches 85 percent.
- Expectation. A stop of the stage of N PVs has the expected duration a0 + N * b0. The rehearsal measures a0 and b0 from four stops (25 and 100 PVs, two stops each, hold 2; the 25 PVs are every fourth data row of `pvs.csv`, rows 4, 8, ..., 100 without the header line): `fit-line.bash rehearsal` fits the line through the four stops. The expectations of the main cells are written by `fit-line.bash expect` on the guest to `<evidence>/<run-id>/expectation.jsonl` before the cells run, which is the file that `--expectation` names, and its SHA-256 and the time go to the status file. They extrapolate from at most 100 PVs, and the report says so. The mark "excess of the ETL gap" rests on that extrapolation.
- Fit. For the stops of the two main cells that follow the rule, `fit-line.bash line` fits duration = a + b * N by ordinary least squares, without weights, in `awk`. With two values of N the line runs through the two cell means; with n stops used the residual has n - 2 degrees of freedom (4 when all six stops are used), and the standard error of b follows from the pooled variance of the two cells. The report shows the mean, the smallest and the largest stop of each cell, the slope with its standard error and its 95 percent interval (the Student quantile t(0.975, df) from a table of published values for df 1 to 30 that the script carries with its source), the intercept, and the predicted PV count at which the line reaches the value of `SYSTEMD_TIMEOUT_STOP_SECONDS` and 80 percent of it. It gives each PV count twice: from the slope and from the upper end of its interval, which is the cautious value. A slope that is not positive has no PV count; the report then gives only a lower bound from the upper end. A cell with fewer than two stops that follow the rule makes the fit Incomplete. Two values of N cannot test linearity; the rehearsal stops lie beside the line as a plausibility check and do not enter the fit. The line is valid for this IOC and the 5-minute partition, and a prediction beyond 3000 PVs is an extrapolation. The outputs are rounded to 6 significant digits, and `fit-line.bash check <recorded fit>` compares the rounded text exactly.
- Report apart, without a fit: the gap of the engine, of the ETL instance and of the management instance of every stop, the bytes of the short term store from the listing, a summary of the jobs of the loop at the stop (the number, the sum, the mean, the median, the longest with its PV; the individual gaps stay in the evidence) and the PV at which a SIGKILL cut the loop, and for each cell the longest `slowestMillis` and the longest pass duration of the pass records.
- Validation. Before the validation stop runs, `fit-line.bash predict` writes the prediction file on the local host from the n stops of the main cell of 903 PVs that follow the rule: their mean plus and minus t(0.975, n - 1) times their sample standard deviation (divisor n - 1) times the square root of 1 + 1/n (with n = 3: t = 4.303 and the square root of 4/3). With fewer than two such stops the prediction and C3 are Incomplete. The file and its SHA-256 are copied to the evidence directory of the guest with `scp`, and `run-stop.bash` checks the hash and records it with the time in the status file before the stop. The validation stop agrees when it lies inside the interval; outside it, C3 is Failed, and the report names the differences that may explain it (file size, the cadence of the passes, the store ages, the page cache) without assigning one cause. One stop gives agreement or a flag, not an uncertainty of the line.
- Limits that the report states: the stops of one cell run in sequence and the stops after the first merge into a medium term store that holds the data of the stops before them; the standard deviation of the stops can grow with N; the waveform of a `compress` record grows from 1 to 1000 elements in the first 1000 seconds after each restart of the IOC, so the bytes of the first stop of a stage are lower than the estimate; and the time of the line "Shutting down ETL threads." plus 5 seconds is an upper bound of the moment at which the ticker stops.

Test scripts, evidence and tools

- The scripts are new files of this repository in `tests/stop-time/`, a deliverable of this item that follows its own review and commit authority. All of them are Bash (D41: new tests are written in Bash; the arithmetic of the fit runs in `awk`, so the item adds no Python). They are: `gen-pvs.bash` (the 2097 PVs), `archive-stage.bash` (the archivePV POST of a stage and the wait until every PV is archived and connected), `run-cell.bash` (the stops of one cell in order, with `make sd_start` between them and a stop at a refusal or a repeat that is due), `run-stop.bash` (one stop: the checks before the stop, the phase window, the stop, the cuts, the listings, the status file, and for the validation stop the verdict of C3 against the prediction file), `rebuild-table.bash` (the table from the raw evidence), `fit-line.bash` (the subcommands `rehearsal`, `expect`, `line`, `predict` and `check` of this Scope) and `selftest.bash` (the test of the scripts themselves on the committed fixtures, see below). The `README.md` of the folder has the sections Recommended Test Sequence, Debugging and Workspace Retention, Test Execution and Verified Behaviors, a table of the exit statuses, the reason why the scripts do not use `tests/lib/common.bash`, and the sentence that `tests/run-all-tests.bash --local` does not run the folder. `tests/README.md` gets one sentence that names the folder as a test for the guest that `--local` does not run. The scripts hold no runtime evidence.
- Interface of the scripts. `run-stop.bash` takes the options `--run <run-id>`, `--cell <name>` (`rehearsal-25`, `rehearsal-100`, `main-903`, `main-3000` or `validation-903`), `--stop <number>` (a number, or a number with the suffix `r` for a repeat), `--stage <N>`, `--partition <name>`, `--hold <n>`, `--unit <unit>`, `--evidence <directory>` (the parent of the run folders), `--pv-list <csv>` (repeatable), `--expectation <file>`, `--prediction <file>` (validation stop only), `--dry-run` and `--judge <stop folder>`; it reads `ARCHAPPL_STORAGE_TOP` and `AA_INSTALL_LOCATION` from `make -s print-...` of the checkout, runs as the engineer with `sudo` for the commands that need it, and writes one JSON record of the stop to `<evidence>/<run-id>/stops.jsonl`. `--dry-run` parses the options, runs every check before the stop and prints the commands of the stop without running them. `--judge <stop folder>` judges a recorded stop folder without a stop and exits with its verdict, which is how the verdicts are tested on the fixtures. `gen-pvs.bash <output folder>` writes `extra.db` and `extra.csv`. `rebuild-table.bash <evidence copy> <output.jsonl>` rebuilds the table from the raw files. `fit-line.bash <subcommand> <input> [<output>]` reads JSONL; `rehearsal` and `line` write text, `expect` writes `expectation.jsonl`, `predict` writes `prediction.json`, and `check` writes nothing and exits 0 on equal text and 1 on a difference. A refusal of the guard or of the usage exits with status 3 and a message before any side effect, apart from the verdicts 0, 1 and 2; the `README.md` says that status 2 means Incomplete here while `tests/run-all-tests.bash` uses 2 for an invalid usage and 77 for an incomplete system test.
- Bash form of the scripts: `set -euo pipefail`, `function name {`, `TOP` resolved from `BASH_SOURCE` and `readonly`, one assertion for each claim, the counters `TEST_TOTAL`, `TEST_PASSED`, `TEST_FAILED`, `FAILED_DETAILS` and `INCOMPLETE_DETAILS`, the summary block, one EXIT handler, the exit status 0 for Passed, 1 for Failed, 2 for Incomplete, 130 and 143 for INT and TERM. `bash -n` and `shellcheck -x` pass without a finding on every script; this is a condition of the review of the pull request, not a gate of the repository.
- Fixtures and the self-test. The folder `tests/stop-time/fixtures/` holds small files of the shapes that the scripts read: a journal cut with the four launcher lines, a unit record of `systemctl show`, a cut of `etl-pass.log` with pass records, the line "Shutting down ETL threads." and consolidation lines, listings of the three stores, a PV list, an expectation file, a prediction file, a recorded `stops.jsonl` and a recorded fit. They are sanitized excerpts of the rehearsal or, until the rehearsal ran, synthetic files in the same form; the `README.md` says which. `selftest.bash` runs on the local host without a guest and checks: the parsers on the fixtures and on copies with a launcher line removed, a cut without its cursor, a truncated log, a missing required field, a stack trace line and an empty cut (each with the expected Passed or Incomplete result, and a tool error that is not a product failure); the time handling on a known pair of stamps; `gen-pvs.bash` for the count, the names, the record form and the determinism; `fit-line.bash` on a known table (the slope, the intercept and the standard error against recorded values, the 30 table values, `check` failing on a changed digit, a slope that is not positive, and fewer than two stops); the verdict of C3 inside, outside and on the interval; the refusal of the guard and of a wrong `ARCHAPPL_STORAGE_TOP` with status 3; the exit statuses 0, 1 and 2 of `run-stop.bash --judge` on fixture stop folders that are Passed, Failed and Incomplete, and the checks of `run-stop.bash --dry-run`; and that `rebuild-table.bash` on copies leaves the originals byte-identical and agrees with the recorded `stops.jsonl` through `compare-evidence.py`. The self-test is the condition under which the pull request is reviewed; the rehearsal on the guest adds what the host cannot show.
- `run-stop.bash` does not source `tests/lib/common.bash`, whose workspace under `/dev/shm`, its own EXIT trap and its exit at the first failure do not fit the scheme of the test framework; it has its own counters and the single EXIT handler, and the evidence directory is never the cleaned workspace. The folder is a test for the guest and is run explicitly there; `tests/run-all-tests.bash --local` does not call it, and the `README.md` says so. `run-stop.bash` refuses to run (status 3) unless the file `/etc/stop-time-guest` exists (the engineer creates it on the guest at the start) and `ARCHAPPL_STORAGE_TOP` is `/arch`; the script never runs `make conf.storage.rm`.
- Evidence directory: `~/stop-time-evidence/<run-id>/` of the engineer on the guest, outside `ARCHAPPL_STORAGE_TOP` and outside scratch folders, so that `sudo make conf.storage.rm` does not reach it. It holds the status file, the journal cuts, the cuts and the copy of `etl-pass.log`, the listings, the output of every command, the expectation and prediction files and the frozen configuration. On failure or Incomplete the workspace is retained, and `KEEP_WORKSPACE=1` retains it on success too. Originals are frozen after each stop, and replays use separate copies.
- Result location: the coverage table, the statement and the fit text are written as `report.md`, `coverage.md` and `fit.txt` into `~/stop-time-evidence/<run-id>/report/` on the host and copied, with their SHA-256, into the Verification Results and the Closure Evidence of this item in `docs/milestone-2.0.1.md` (the register holds the table and the statement; the raw evidence stays private on the host and the guest). The result changes no document of the repository; the deliverables add the folder `tests/stop-time/` with its `README.md` and one sentence in `tests/README.md`.
- Record contract. Required fields: launcher line (time, service, pid), unit record (`ActiveExitTimestamp`, `InactiveEnterTimestamp`, both monotonic values, `Result`, `InvocationID`), pass record (`plannedAt`, `startedAt`, `endedAt`, `pvCount`, `jobsRun`, `jobsFailed`, `partitionsMoved`, `bytesMoved`, `slowestPv`, `slowestMillis`, `aborted`; the other fields are optional), consolidation line (time, PV), listing row (store, PV key, file, bytes, modification time). A missing required field makes the record Incomplete; a missing optional field does not. The parser runs on retained records and on copies of real records with a launcher line removed, a cut that misses its cursor and a truncated log, and each outcome is checked. The table keeps the original timestamp text and converts to UTC with microsecond precision. The status file `<evidence>/<run-id>/status` has `key=value` lines with the keys `run`, `cell`, `stop`, `stage`, `partition`, `hold`, `start_utc`, `intended_end_utc`, `actual_end_utc`, `b0_utc`, `e_planned_utc`, `e_used_utc`, `expectation_sha256`, `expectation_written_utc`, `prediction_sha256`, `prediction_written_utc`, `chrony_offset_s` and `pending`; `run-stop.bash` copies it as `status.<cell>.<stop>` into the folder of the stop before the stop and updates the live file after it. The expectation file `expectation.jsonl` holds one JSON record for each cell (`cell`, `n_pvs`, `expected_s`, `a0_s`, `b0_s_per_pv`), the prediction file `prediction.json` the fields `cell`, `n_stops`, `mean_s`, `sd_s`, `t`, `lower_s` and `upper_s`, and `run-stop.bash` writes one JSON record for each stop to `stops.jsonl` (the recorded table) with the per-stop fields of the Completion Criteria, the key `stop` carrying the suffix `r` of a repeat; the per-cell values (the longest `slowestMillis`, the longest pass, the ratio of the ETL gap per PV of the validation stop to that of `main-903`) come from `fit-line.bash line`. The contract file of `compare-evidence.py`, `tests/stop-time/stops-contract.json`, declares the keys `cell`, `stop` and `invocation_id`, the time stamps and the numbers with their units; `selftest.bash` uses the same file.
- Tools of the test framework. `check-sources.py` checks the copied test PV set against an independent inventory: the inventory root is a folder extracted with `git archive` from `tests/archiver-soak/fixtures/` at the pinned commit of ansible-provision, made a Git working tree with `git init` (the checker lists its members with `git ls-files`), with a `SHA256SUMS` of all its `.db` and `.csv` files, and the candidate root is the copy on the guest; the check runs on the guest after the copy, with `git` installed there and the archive carried over with the copy; the generated files `extra.db` and `extra.csv` are checked by their own `SHA256SUMS` and the hash of the generator. `compare-evidence.py` compares the table that `rebuild-table.bash` rebuilds with the recorded table of the stops (JSONL records; a key without a value is left out of the record, because the tool treats an empty number as unresolved; keys cell, stop and the `InvocationID` of the unit; time stamps in UTC with `Z`; numbers with their units); the recorded table and the rebuilt table come from the same raw evidence by different paths, so their agreement shows that the rebuild reproduces the recording and is not an independent expectation. `bundle-evidence.py` is not used: it takes a receipt as its input, and no producer of a receipt for `rebuild-table.bash` exists in this item. Freezing a stop is: `run-stop.bash` writes `<stop folder>/SHA256SUMS` over every file of the stop folder after the stop, and the engineer writes `<evidence>/<run-id>/SHA256SUMS` over all stop folders and the live files at the end of each stage and at the end of the run. The evidence moves from the guest to the local host with `rsync -a` into `~/stop-time-evidence/<run-id>/` of the engineer on the host, followed by `sha256sum --check --strict` of both manifests there; the replay runs on a second copy under `~/stop-time-evidence/<run-id>-replay/`, and the originals are compared with their manifests after the replay.
- Readiness is observed, not slept. The wait for the boundary is computed from the UTC clock, with the offset of `chronyc tracking` recorded for each stop; after the IOC restart each PV connection is verified before archiving; the stop is issued only when the listing shows hold + 2 files of every PV and the clock lies inside the window. The listing records its start and end, and the stop begins within 10 seconds after the listing ends.
- Rehearse before the main cells: run the stages of 25 and 100 PVs through installation, archiving, accumulation with the rule, the stop, the final capture of logs, journal and listings, the building of the table and its replay from copies. Measure a0 and b0 with the four stops above and the stop times of engine and retrieval, check that the short term store holds about 10 samples per second for a 10 Hz PV, prove the commands of this Scope, and fix the reset procedure. Rehearse the failure paths: a stop cut at `timeout`, a missing launcher line, a lost cursor, a failed query, a truncated log and an interrupted stop, and show that a tool error is not recorded as a product failure. The rehearsal of 25 and 100 PVs establishes the tools and the commands, and cannot establish the behavior of 3000 PVs, of the hourly partition or of the full volume. It counts for no cell. Repair what blocks capture or judgment before the main cells. Exercise the tools of the table and the replay once on a declared replicate of the retained rehearsal evidence, copied to the member count and size of the largest cell (3000 PVs, 4 files of each PV, 7 stops); this tests the tools only and supports no claim about the appliance.
- A corrected tool is run on the retained evidence as a candidate result, and the original result is kept. A stop is repeated only when a required observation cannot be recovered or the behavior of the target changed.
- After a reboot of the guest: check `journalctl --list-boots` (the journal is persistent, so the cursors of the stops before the reboot stay valid; the monotonic values of a stop come from one boot), the units `epicsarchiverap-maven.service` and `stop-time-ioc.service` (both enabled; the appliance start after the boot is an auxiliary stop in the coverage table), the ten `MDEL` and `ADEL` fields, `chronyc tracking`, the guard file and the evidence directory, and continue with the B0 rule.
- Disk estimate (an assumption that the rehearsal replaces with the measured sample size). The stage of 3000 PVs produces about 3980 scalar samples per second (1884 from the set of 903 PVs and 2097 generated) and 8 waveform samples per second. A scalar sample takes about 25 bytes in a plain file and a waveform sample about 8 kB (packed doubles), which gives about 165 kB per second or 590 MB per hour. A cell of the stage of 3000 PVs holds 4 files of 5 minutes (about 200 MB) in the short term store and the consolidated data of the same size in the medium term store. At the validation stop the short term store of 903 PVs holds hold + 2 files, three full hours and the file just opened (about 1.2 GB), and the medium term store holds the data of the same size after the stop. With the evidence, about 6 GB are data and evidence. The system, the JDK, Tomcat, the Maven cache and the EPICS Base copy take about 12 GB on the same disk, so the request names 30 GiB. Keep the use of the root file system below 85 percent, the threshold of the health check for the storage path.
- Total time: accumulation and waits of the six stops of the main cells up to 20.5 minutes each (about 2 hours) and of the validation stop up to 4 hours; with the starts, stops, resets and checks of 7 stops the run takes about 8 hours without the rehearsal.

Out of scope: a change of the default of `SYSTEMD_TIMEOUT_STOP_SECONDS`, of the ETL code or of the policies of the repository, apart from the new files of `tests/stop-time/` named in this Scope (the raised or changed `ARCHAPPL_STS_*` values are settings of the guest only); a change of `docs/README.install.md` or the systemd reference (a change follows the result and needs its own plan item and authority); heap sizing (M41); a stop during a running pass; the hold of 5; the 15-minute and the hourly matrices (M56 and M57; Deferred on 2026-10-19; reopened and Complete on 2026-10-21); any run on the production appliance of the development host (ports 17665 to 17668, `/opt/epicsarchiverap-maven`, `/arch`; the guest has its own installation at the same default paths); a run on Rocky Linux 8.10.

##### Completion Criteria

- A table lists for every stop of the main cells and the validation cell, with the keys cell, stop and the `InvocationID` of the unit, the qualifiers (overlap, off-rule, incomplete) and the verdicts C1, C2 and C3: the number of PVs, the files of each PV, the files and bytes of the short term store, the time after the boundary, the stop duration of the unit and of each instance, the unit result, the consolidated PVs and the left PVs, the jobs of the loop at the stop as a summary (the number of jobs, the sum, the mean, the median, the longest with its PV, the gap of the ETL instance divided by the PV count; the individual gaps between consecutive "Need to consolidate" lines stay in the evidence) and the PV at which a SIGKILL cut the loop, and for each cell the longest `slowestMillis` and the longest pass duration of the pass records. It names the refs, the kernel, the JDK, the policy values, the installed `TimeoutStopSec` and the value of `ETLPassStopWaitSeconds`, and for the validation stop the ratio of its ETL gap per PV to that of the cell `main-903`. A stop that the unit ended or that overlapped a pass is marked.
- The journal cuts, the unit results, the listings and the frozen configuration reproduce the table. Their hashes and the identities of the rebuilding tools are frozen before the replay. The replay runs on copies, and the originals are unchanged.
- A coverage table lists every cell and every stop with its result: observed stop, ended by the unit (SIGKILL, result `timeout`), overlapping a pass, off-rule, Incomplete (a required record is missing), not run, interrupted, or auxiliary (a start or stop that is not measured, with its reason). A cell or a stop that did not run is not counted as passed.
- A statement gives the line of the stop time over the PV count with its standard error, the PV counts at which it reaches the stop timeout and 80 percent of it (from the slope and from the cautious end of its interval), the predicted stop time at 5000, 10000, 20000 and 50000 PVs (from the slope and from the cautious end, with the note that these are extrapolations beyond 3000 PVs), the sentence that the line and the PV counts assume that no pass runs at the stop and that a running job adds at most two waits of `ETLPassStopWaitSeconds` plus one left PV, the cells that suffice and that do not, and the result of the validation stop against its written interval.
- The statement opens with a block of the conditions of the measurement: for each cell the partition and the hold, the database (SQLite), the memory and vCPU of the guest, the disk layout (the three tiers on one virtual disk), the operating system, the heap of each instance, the log level and the appender, the installed `TimeoutStopSec` and the value of `ETLPassStopWaitSeconds` (not in the installed file; the default), the PV mix as a table (policy, rate, waveforms, the 2097 generated 1 Hz PVs), and for each stop the bytes of the short term store and the average bytes per PV. It names what a site has to do to set each of the two values (`SYSTEMD_TIMEOUT_STOP_SECONDS` in `../CONFIG_SITE.local` followed by `make sd_install`; `ETLPassStopWaitSeconds` only through a change of `site-template/archappl.properties.in`), the cost of a PV left unconsolidated (its files move in the next pass of a store on a disk, and are lost on a reboot with a store on tmpfs), and the follow-up item and the two documents (`docs/README.install.md`, `docs/technicaldocs/README.systemd.md`) that a sizing rule would change. The statement does not change the documents.
- Every stop has its verdicts for C1 and C2 and the validation stop its verdict for C3, as the Scope defines them; the summary of the run gives the counters and the exit status of the driver (0 Passed, 1 Failed, 2 Incomplete); the report files and their hashes are in the Verification Results of this item. The scripts of `tests/stop-time/`, their fixtures and their `README.md` are delivered; `selftest.bash` passes on the local host, and `bash -n` and `shellcheck -x` pass on every script.

##### Dependencies And Decisions

- G9: the guest. The order is: the owner accepts the plan, the owner authorizes the implementation, the second step of the implementation sends the request of G9 (the first step writes and self-tests the scripts on the local host), the provider completes G9, and then the steps that need the guest run. Owner decision of 2026-10-19: the item is In progress with step 1 (the scripts and their self-test on the local host), which needs no guest; G9 is the condition of steps 2 to 7, which do not start while G9 is Open. G9 is Complete since 2026-10-19. The guest stays running during the measurement, because each start after a shutdown needs the authorization of the owner of the provider. The disk size of the request comes from the estimate in the Scope.
- Owner choices of 2026-10-19, taken before the acceptance of the plan: the stages of 903 and 3000 PVs (the choice follows the finding that the measurement of ansible-provision at 903 PVs is 13 seconds), the reuse of the 903 PVs of ansible-provision with 2097 generated PVs for the stage of 3000; the hold of 2; Debian 13, with Rocky Linux 8.10 deferred; the partition `PARTITION_5MIN` for the main cells and the shipped partition for the validation stop; the criterion of sufficiency; three stops for each main cell and one for the validation stop; no stop during a running pass and no hold of 5; SQLite as the database; the guest of 2 vCPU, 4 GiB and 30 GiB; the installation by the engineer with the local script and the account `tomcat`; the pass events from a log file; the verdict model of the test framework (C1, C2, C3); the scripts in `tests/stop-time/` of this repository; the use of `check-sources.py` and `compare-evidence.py` (not `bundle-evidence.py`, which needs a receipt producer); the override of the deadband applied and a lower bound of 30 seconds of the window; the Student quantile from a table of published values; the scripts in Bash with `awk` and no Python (D41), with committed fixtures and a self-test on the local host; a missed window continued at the next boundary without a restart; the report form of the Completion Criteria (conditions block, fixed PV counts, loop summary); no change of the documents within this item. M56 and M57 are Deferred on the same date (reopened and Complete on 2026-10-21).
- The owner accepted the plan and authorized the implementation on 2026-10-19.
- Owner decision of 2026-10-20: the two helpers that the measurement used on the guest, the archiving of a stage and the run of the stops of a cell, become `tests/stop-time/archive-stage.bash` and `tests/stop-time/run-cell.bash`, each with its purpose and usage in its header and in the `README.md` of the folder.
- Owner decision of 2026-10-20: the excerpts of the rehearsal are added to the fixtures beside the synthetic files instead of replacing them; the synthetic files stay as the base of the damaged copies of the self-test, and no real validation stop exists before step 6.
- Owner decision of 2026-10-19: `run-stop.bash` also takes the rehearsal cells `rehearsal-25` and `rehearsal-100`, so that the rehearsal stops are recorded in `stops.jsonl` and `fit-line.bash rehearsal` reads them.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: accepted by the owner on 2026-10-19 (the plan of commit `0ac24de`)
Implementation Authorization: the owner authorized the implementation on 2026-10-19
Superseded Plan Artifacts: none

1. Write the scripts and the fixtures of `tests/stop-time/`, and pass the self-test on the local host (T1).
2. Send the resource request of G9 and receive the handoff. On the guest install the appliance with the local SQLite installation, copy the EPICS Base binaries and install `libreadline8`, set the persistent journal and `chrony`, install the site log4j2 file for the pass events, copy the test PV set at the pinned commit and check it with `check-sources.py`, generate the 2097 PVs, and render the settings of the main cells; the PVs are archived in the sequence of each stage (T2).
3. Rehearse with 25 and 100 PVs, including the failure paths and the stop cut at `timeout`. Measure a0 and b0 and the stop times of engine and retrieval, prove the commands, fix the reset procedure, exercise the tools on the replicated evidence, and replace the synthetic fixtures by sanitized excerpts of the rehearsal (T2).
4. Write the expectation of the main cells with `fit-line.bash expect` and record its hash. Reset after the rehearsal, run the three stops of the stage of 903 PVs, reset, and run the three stops of the stage of 3000 PVs (T3, T4, T5).
5. Freeze the evidence of the main cells (members, SHA-256, tool identities), move it to the local host with `rsync -a` and check its manifest there, fit the line, write the prediction of the validation stop with `fit-line.bash predict`, and copy it to the guest with its hash (T6).
6. Change the policy to the shipped values, reset, and run the validation stop (T3, T4, T5).
7. Freeze all evidence, move it to the local host, rebuild the table from copies, compare the validation stop with its written interval, compile the coverage table and the statement, and record the result without a change of the documents (T7, T8).

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Run `selftest.bash` of `tests/stop-time/` on the committed fixtures, and `bash -n` and `shellcheck -x` on every script | Local host | The self-test passes with exit status 0; the parsers, the generator, the fit, the C3 verdict, the guard and the exit statuses behave as the Scope states; `shellcheck -x` reports nothing |
| T2 | VM | Rehearse with 25 and 100 PVs through installation, archiving, accumulation with the rule, the stop, final capture and the table with its replay, with the PVs served by a real `softIoc`; rehearse the failure paths (a stop cut at `timeout`, a missing launcher line, a lost cursor, a failed query, a truncated log, an interrupted stop); exercise the tools on the replicated evidence of the largest cell | Guest of G9; local host | Every step runs and its evidence is retained; a0, b0, the commands, the native statuses and the reset procedure are fixed; a tool error is not recorded as a product failure; defects that block capture or judgment are repaired; the fixtures are replaced by sanitized excerpts and T1 passes on them too |
| T3 | VM | Stop the unit with `sudo systemctl stop` (the effect of `make sd_stop`) under the rule at each stop of the main cells and in the validation cell, after the expectation is written down | Guest of G9 | A stop duration of the unit and of each instance for every stop, next to its expectation, with the time after the boundary and the file count |
| T4 | VM | At the shipped log level cut the journal of each stop with its cursor, read the error lines of the ETL instance, `systemctl show -p Result` of the unit before the next start and the journal line of the timeout; check the four launcher lines, the first and last line of the cut, and overlap | Guest of G9 | The PVs named as left, the stops that the unit ended or that overlapped, and a stop with a missing required line marked Incomplete |
| T5 | VM | List the three stores before and after each stop | Guest of G9 | After a stop without SIGKILL the short term store holds no file except those of the PVs that the error lines name as left (an empty file is deleted, not moved); after a stop that the unit ended the listing names the PVs that still have files |
| T6 | Local | Freeze the evidence of the main cells (members, SHA-256, tool identities), fit the line with `fit-line.bash line`, and write the prediction of the validation stop with `fit-line.bash predict` and its hash before the stop runs | Local host | The line, its standard error and the interval are retained and reproduce from the frozen table with `fit-line.bash check` |
| T7 | Local | Freeze all evidence, move it from the guest with a check of every member, rebuild the table from separate copies with `rebuild-table.bash`, compare it with the recorded `stops.jsonl` by `compare-evidence.py`, and judge C3 of the validation stop against the interval of T6 | Local host | Every value follows from the retained files, the originals are unchanged, the table agrees with the recorded table, and C3 uses the interval of T6 |
| T8 | Review | Read the coverage table, the line and the statement against the table | Local host | Each claim names the stage and the stop duration that support it, the line reproduces from the retained table, and no cell that did not run counts as passed |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-19, 2026-10-20 | Local host (Debian 13) | Passed | `tests/stop-time/selftest.bash` on 2026-10-19 with the files of commit `943407e`, which adds the folder: 87 of 87 assertions Passed with exit status 0; on 2026-10-20 with the files of the commit that carries the tool repairs and the fixtures of the rehearsal: 128 of 128 Passed with exit status 0. Each run used `awk` once as GNU awk and once as mawk (the awk of the guest), and `bash -n` and `shellcheck -x` reported no finding on the five scripts. On 2026-10-20 with the helpers `archive-stage.bash` and `run-cell.bash` added and the pass window bound to the start of `run-stop.bash`: 138 of 138 Passed with exit status 0, once with GNU awk and once with mawk. On the first two dates a seeded defect in a copy of `rebuild-table.bash` (the PV word of the consolidation line) and in a copy of `fit-line.bash` (the factor of the prediction interval) each made the self-test exit 1 |
| T2 | 2026-10-20 | Guest of G9 (Debian 13, source `a8d07955`, this repository `943407e` with the tool repairs below copied in; the copied files are those of the commit that carries the repairs, equal by SHA-256 to the local files); local host | Passed | Installation, the site log4j2 file, the persistent journal, `chrony`, the IOC unit and the copied PV set (`check-sources.py` Passed against the inventory of ansible-provision `635d76c`) are in place; a 10 Hz PV stores 601 samples in 60 seconds. Four rehearsal stops are Passed for C1 and C2: 25 PVs 1.312 s and 1.336 s, 100 PVs 1.580 s and 1.479 s (engine gap about 1.1 s, ETL gap 0.11 to 0.31 s, no PV left); `fit-line.bash rehearsal` gives a0 1.25554 s and b0 0.00273987 s per PV, and `expectation.jsonl` gives 3.72964 s for 903 PVs and 9.47515 s for 3000 PVs. Failure paths: a stop with `SYSTEMD_TIMEOUT_STOP_SECONDS` 1 ended in `timeout` after 1.08 s with all 100 PVs left and the exit status 0 of `systemctl stop`; a TERM to `run-stop.bash` gave status 143 and Incomplete with the evidence kept; damaged copies of a real stop folder (a launcher line removed, the cursor of the cut missing, a truncated log) are Incomplete, a cut by time stamps is Passed, and an unreadable file is a tool error (status 3). A lost cursor: `journalctl` answers a malformed cursor with status 1 and `Failed to seek to cursor`, but a well-formed cursor that the journal does not hold seeks to another position and returns the journal from its start (a live stop with such a cursor, given through the test hook `STOP_TIME_CURSOR`, cut 25 launcher lines of earlier stops); after the repair below a live stop with the same cursor fell back to the cut by the unit time stamps (`mode=time`, first record at the start of the stop, 4 launcher lines, Passed). A failed query: the appliance stopped 5 seconds after `run-stop.bash` started, so `getPVStatus` failed; after 900 seconds the script ended Incomplete (status 2) without a stop command and without a record in `stops.jsonl`. Tool repairs found by the rehearsal (the original records kept, the repaired tool run on copies as candidate results): the pass records are read from the whole `etl-pass.log` (`etl-pass.records`), `slowestMillis` and the pass duration count the passes of the accumulation of each stop, the rehearsal cells take no `--expectation`, an empty cut is not missing evidence when the unit ended the stop before the ETL instance, `run-stop.bash` cuts by the unit time stamps when the first record of the cursor cut is older than the moment the cursor was taken, `rebuild-table.bash` counts launcher lines from the start of the stop and marks a cut that starts more than 60 seconds before it as Incomplete, and three pipes whose reader can end early under `pipefail` were removed (one of them ended a live stop after the stop command with status 141; that stop is kept and repeated as `4r`), and a stop that ends before its record now writes `ended.txt` and `SHA256SUMS` into its folder and sets `pending` to the same stop before the stop command or to the repeat with the suffix `r` after it, while a recorded clean stop removes the key; on the guest a TERM during the wait gave status 143, a frozen folder and `pending=rehearsal-100/6`, a second run of the same stop moved the old folder aside as `.interrupted-<UTC>`, and a stop whose folder holds `stop-exit.txt` was refused with status 3 and left unchanged (the folders of the stops ended before this repair carry no `ended.txt`). The expectation of the main cells was written from the table recorded at the four rehearsal stops; with the repaired tool the same a0 and b0 come from the candidate results (the folder of `rehearsal-25` stop 1 with the pass records extracted after it), while the original folder of that stop is Incomplete for C1 without `etl-pass.records`, and a table rebuilt from the original folders gives a0 1.27133 s and b0 0.00258193 s per PV from the other three stops. A tool error of `rebuild-table.bash` at the end of a stop writes no record and ends the stop as one that ended before its record; this branch was not executed in a live stop: `run-stop.bash --judge` on a folder with an unreadable file gave status 3 and no record, and the end handling is the one that the interrupted stops above executed. A declared replicate of a rehearsal stop folder at the size of the largest cell (3000 PVs with 4 short term files each, 7 stop folders, 12000 listing rows of the short term store per stop) exercised the tools only: `rebuild-table.bash` built the 7 records in 3.2 s, its run on a copy agreed through `compare-evidence.py` (Passed), the originals stayed byte-identical, and `fit-line.bash line` and `check` ran on the table. Three real stop folders of the rehearsal (normal, timeout, interrupted) are fixtures in `tests/stop-time/fixtures/run-rehearsal/` beside the synthetic ones, and `selftest.bash` judges them again to the values recorded at the stop (128 of 128 assertions Passed with GNU awk and with mawk) |
| T3 | 2026-10-20 | Guest of G9 (this repository `990786e`, source `a8d07955`, SQLite; `PARTITION_5MIN` for the main cells and `PARTITION_HOUR` for the validation stop, hold 2) | Passed | Six stops of the main cells, each about 30 seconds after its boundary E (30.17 s to 30.73 s), with hold + 2 files of every PV and no qualifier: `main-903` 2.34421 s, 2.3907 s and 2.23577 s against the expectation 3.72964 s; `main-3000` 7.80716 s, 6.60475 s and 6.67428 s against 9.47515 s. Engine gap 1.09 s to 1.28 s, ETL gap 1.02 s to 1.10 s at 903 PVs and 5.25 s to 6.40 s at 3000 PVs, management gap 0.05 s to 0.07 s. The validation stop (`PARTITION_HOUR`, 30.42 s after E at 01:00 UTC) took 3.7403 s: engine gap 1.209 s, ETL gap 2.296 s, management gap 0.116 s |
| T4 | 2026-10-20 | Guest of G9 | Passed | Every stop of the main cells: unit result `success`, the four launcher lines, a cut from its cursor (`mode=cursor`), no error line of the ETL instance, no overlap with a pass (the longest pass of the cell `main-3000` took 9.41 s), C1 and C2 Passed; no stop was ended by the unit and none is Incomplete. The validation stop has the same: result `success`, four launcher lines, a cut from its cursor, no error line, no overlap (its longest pass took 0.88 s) |
| T5 | 2026-10-20 | Guest of G9 | Passed | Before each stop of the main cells the listing showed hold + 2 = 4 files of every PV in the short term store; after each stop the short term store held no file and every PV was consolidated (903 and 3000 loop jobs, sums 0.96 s to 1.05 s and 5.17 s to 6.34 s, longest job 14 ms), so no PV was left. The validation stop had 4 files of every PV (1118597163 bytes, 1.24 MB per PV) before and no file after, with 903 loop jobs (sum 2.215 s, longest 119 ms) |
| T6 | 2026-10-20 | Local host | Passed | The run folder (1019 files) moved from the guest with `rsync -a` and passed `sha256sum --check --strict` on the host; the tool identities are in `tool-identity.txt`. On a separate copy `rebuild-table.bash` reproduced the six records of the main cells exactly (`compare-evidence.py` Passed), and `fit-line.bash check` found the line of the rebuilt table equal to the recorded line. The line: intercept 0.297442 s, slope 0.00224376 s per PV, standard error 0.000187137 (df 4, t 2.776, interval 0.00172427 to 0.00276325); the timeout of 300 s at 133571 PVs and cautiously 108460, 80 percent of it at 106831 and 86746.5. The prediction of the validation stop from the three stops of `main-903`: mean 2.32356 s, sd 0.0795025 s, interval 1.92854 s to 2.71858 s, SHA-256 `73f66105047240e1b5edb83c730180f7ca12b2d0777f0f7d088301173a7f4f37`, copied to the guest and checked there before the stop. An independent computation gave the same line and interval |
| T7 | 2026-10-20 | Local host | Passed | The run folder (1103 files, 197 MB) moved from the guest with `rsync -a` and passed `sha256sum --check --strict` on the host; a separate copy `st-20261019-replay-final` holds the rebuilt table and the tool identities. `rebuild-table.bash` rebuilt 11 records; `compare-evidence.py` against the recorded `stops.jsonl` found every unit duration, result, C2 and C3 equal and differences only in the pass statistics and in C1 of `rehearsal-25` stop 1, all from the tool repairs: the pass statistics count the passes from the start of `run-stop.bash` (start_utc of the status copy), because `etl-pass.log` runs on across resets and the window of the hourly partition reached back into the stage of 3000 PVs (the recorded longest pass of the validation stop, 9.41 s, belongs to that stage; its own is 0.88 s). The originals stayed unchanged. The run manifest leaves out the nested `SHA256SUMS` files; each real stop folder passed its own `SHA256SUMS` and `frozen/SHA256SUMS` on the host (22 manifests), the nested manifests are byte-equal on the host and the guest, and those of the declared copies (the damaged copies of the failure paths, the candidate copies and the replicate of the largest cell) differ by design. The run of the failure paths (`st-20261019-fail`, 268 files) moved to the host the same way and passed its manifest and the 8 manifests of its stop folders. The line of the rebuilt table equals the line of T6 apart from the added ratio of the validation stop. C3 of the validation stop: 3.7403 s outside the interval 1.92854 s to 2.71858 s of T6 (the hash of the prediction in the status copy equals the hash of T6), so C3 is Failed; its ETL gap per PV is 2.15936 times that of `main-903`. Report files on the host with SHA-256: `report.md` `1212c93a0d8b155c47ef222cef61a44a4140edfe49e52602532284d216643a03`, `coverage.md` `0828d6cc91da0ca8b76e774c29f152317b5edb5312ed5f7002772ea722cdffa5`, `fit-final.txt` `cc607c8e400bc73b42afe0456c703c6e3cc0b906af21454681f14a088777ff01` |
| T8 | 2026-10-20 | Local host | Passed | Every value of `report.md` and `coverage.md` was recomputed from the rebuilt table, `fit-final.txt`, `prediction.json`, the frozen configuration and the PV lists: the 7 rows of the stop table, the line, its interval and PV counts, the predictions at 5000 to 50000 PVs, the cell means, the ratio of the validation stop, the gap ranges, the job times, the data sizes and the PV mix (110 `VeryFast` at 10 Hz, 10 `Fast` at 1 Hz, 10 `Medium` at 0.1 Hz, 773 `Default` at 1 Hz with 8 waveforms) agree; every claim names the cell and the stops that support it, the line reproduces from the retained table (T7), and no cell that did not run counts as passed (all three cells ran their planned stops) |

##### Closure Evidence

- Complete on 2026-10-20. Deliverables: `tests/stop-time/` (scripts, fixtures, `README.md`) in commits `943407e` and `990786e` and in the commit that carries this record (the helpers `archive-stage.bash` and `run-cell.bash` and the pass window bound to the start of `run-stop.bash`); the records of the run in `f589bb9` and this commit. Every test of the Test Plan is Passed (T1 to T8).
- Report files on the host, `~/stop-time-evidence/st-20261019/report/`: `report.md` (SHA-256 `1212c93a0d8b155c47ef222cef61a44a4140edfe49e52602532284d216643a03`), `coverage.md` (`0828d6cc91da0ca8b76e774c29f152317b5edb5312ed5f7002772ea722cdffa5`), `fit-final.txt` (`cc607c8e400bc73b42afe0456c703c6e3cc0b906af21454681f14a088777ff01`); the raw evidence stays private on the host and the guest.
- Conditions: Debian 13 guest of 2 vCPU, 4 GiB, one 30 GiB disk for the three tiers and SQLite; source `a8d07955`; heap 256M for each instance; root logger INFO with the file appender of the pass events; installed `TimeoutStopSec` 300 s; `ETLPassStopWaitSeconds` 60 s (the default, not in the installed file); the 903 PVs of ansible-provision (110 `VeryFast` at 10 Hz, 10 `Fast`, 10 `Medium` at 0.1 Hz, 773 `Default` with 8 waveforms) and 2097 generated 1 Hz PVs for the stage of 3000.

| Cell | Stop | InvocationID | PVs | Partition | STS bytes per PV | After E (s) | Unit stop (s) | Engine (s) | ETL (s) | Mgmt (s) | Result | Left | Loop jobs | Loop sum (s) | Longest job (ms) | C1 | C2 | C3 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| main-903 | 1 | `495618cc` | 903 | PARTITION_5MIN | 105781 | 30.40 | 2.344 | 1.127 | 1.074 | 0.073 | success | 0 | 903 | 0.957 | 11 | Passed | Passed | — |
| main-903 | 2 | `383d946a` | 903 | PARTITION_5MIN | 106106 | 30.37 | 2.391 | 1.156 | 1.096 | 0.067 | success | 0 | 903 | 1.045 | 9 | Passed | Passed | — |
| main-903 | 3 | `2e966fe1` | 903 | PARTITION_5MIN | 106071 | 30.17 | 2.236 | 1.091 | 1.020 | 0.060 | success | 0 | 903 | 0.979 | 8 | Passed | Passed | — |
| main-3000 | 1 | `9edb4d3f` | 3000 | PARTITION_5MIN | 45814 | 30.73 | 7.807 | 1.281 | 6.396 | 0.069 | success | 0 | 3000 | 6.340 | 12 | Passed | Passed | — |
| main-3000 | 2 | `87e2ddbe` | 3000 | PARTITION_5MIN | 45410 | 30.51 | 6.605 | 1.266 | 5.252 | 0.052 | success | 0 | 3000 | 5.172 | 14 | Passed | Passed | — |
| main-3000 | 3 | `41bd1478` | 3000 | PARTITION_5MIN | 45329 | 30.67 | 6.674 | 1.219 | 5.329 | 0.056 | success | 0 | 3000 | 5.278 | 12 | Passed | Passed | — |
| validation-903 | 1 | `8bb533ed` | 903 | PARTITION_HOUR | 1238760 | 30.42 | 3.740 | 1.209 | 2.296 | 0.116 | success | 0 | 903 | 2.215 | 119 | Passed | Passed | Failed |

- Statement. Over the six stops of the main cells the stop time of the unit is 0.297442 s + 0.00224376 s per PV (standard error 0.000187137, 95 percent interval of the slope 0.00172427 to 0.00276325). It reaches the stop timeout of 300 s at 133571 PVs and cautiously at 108460, and 80 percent of it at 106831 and cautiously at 86746.5; at 5000, 10000, 20000 and 50000 PVs it predicts 11.5 s, 22.7 s, 45.2 s and 112.5 s, cautiously 14.1 s, 27.9 s, 55.6 s and 138.5 s, extrapolations beyond 3000 PVs. Nearly all of the growth is the ETL instance (about 1.06 s at 903 PVs, 5.66 s at 3000), while the engine gap stays between 1.09 s and 1.28 s. The line and the PV counts assume that no pass runs at the stop; a running job adds at most two waits of `ETLPassStopWaitSeconds` and one left PV. All three cells suffice (every stop Passed for C1 and C2: result `success`, within the timeout, no PV left).
- The validation stop on the shipped partition took 3.740 s, outside its written interval of 1.92854 s to 2.71858 s, so C3 is Failed; its ETL gap per PV is 2.15936 times that of `main-903`. Differences that may explain it, without one assigned cause: 1.24 MB per PV in the short term store against 0.106 MB (hour files against 5-minute files), a mean loop job of 2.46 ms against 1.06 to 1.16 ms and a longest job of 119 ms on a waveform PV, one pass an hour against one every 5 minutes, and 1.1 GB of short term data on a guest of 4 GiB.
- A site sets the timeout with `SYSTEMD_TIMEOUT_STOP_SECONDS` in `../CONFIG_SITE.local` and `make sd_install`, and `ETLPassStopWaitSeconds` only through `site-template/archappl.properties.in`. A PV left unconsolidated keeps its files in the short term store, which move in the next pass on a disk and are lost at a reboot on tmpfs. A sizing rule would change `docs/README.install.md` and `docs/technicaldocs/README.systemd.md` and needs its own item; this item changes no document.

##### GitHub Projection

Title: none
Labels: none
GitHub Milestone: none
Observed State: none; no issue exists
Last Compared: none

#### G9 - A guest with the disk capacity that the stop time measurement needs is available

Origin: 2.0.1 / G9
Identity History: moved from Backlog to Milestone on 2026-10-23 under D64
GitHub Issue: none
Status: Complete

##### Summary

M55 needs one Debian 13 guest. The requester is the session of this repository, and the provider is the session that owns the hypervisor and its provisioner. The provider creates a fresh guest for a requester of the same owner under its standing authorization when the capacity check passes; the owner of the requester authorizes the implementation of M55, whose second step sends the request, after the owner has accepted the plan. Responsible parties: the requester session (the request, the finished notice) and the provider session (creation, handoff, shutdown). Affected work: M55, and M56 and M57 if the owner reopens them; they would reuse the guest after a restart from its disk.

The request carries these fields, with the purpose first:

- Purpose: the measurement of the stop time of the unit on a SQLite installation (M55).
- Platform: Debian 13, the bare profile `debian13` of the provisioner (not `debian13-archiver-dev`, which applies an appliance that would conflict with the installation of the engineer).
- Resources: 2 vCPU (fixed by the provisioner), 4 GiB of memory (the default), 30 GiB of disk (the provisioner option `-z 30G`; the estimate of M55: about 6 GB for data and evidence and about 12 GB for the system, with a margin).
- Duration: about 12 hours of running: about 4 hours for the installation and the rehearsal and about 8 hours for the measurement; the guest may be shut down in between and restarted by the requester.
- State: a fresh base image; the disk is evidence to keep until the owner removes it.
- Access: the requester connects by SSH with a key and uses `sudo` without a password.
- Follow-up: none for the provider. The engineer installs the appliance, the EPICS Base binaries, `libreadline8` and `rsync`, and sets the persistent journal and `chrony` on the guest.

##### Completion Criteria

- The requester sends the request with every field above, and the provider answers with the outcome, the guest name, the path of the private handoff and every deviation from the request (for example a vCPU count other than 2).
- The provider's verification of the running guest (provisioner status, key-only login, `sudo`, OS release, CPU, memory, disk) is in the handoff.
- The requester sends a finished notice when its use ends and says that the disk is evidence to keep.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-10-19 | Passed | The provider created a fresh guest of the bare profile `debian13` and answered with the outcome `completed` and every field of the request, without a separate handoff file. Its verification: provisioner exit 0 and ready, 2 vCPU, 4096 MiB, Debian 13 (trixie), a 30 GiB disk with 27 GiB free on the root file system, key-only SSH, `sudo -n` without a password, cloud-init done without errors, `/opt` empty; no deviation from the request. Starting the guest again after a shutdown needs the authorization of the owner of the provider and a capacity check each time. |

##### Closure Evidence

- The guest was handed off on 2026-10-19 (Verification Results above); its name, address and access stay in the private records of the provider and the requester.
- The requester sent the finished notice on 2026-10-20 after the evidence was copied and verified on its host, and asked to keep the disk as evidence; the provider answered that the guest is shut off and stays defined, with its disk, seed, creation record and address reservation kept until the owner decides on removal.

#### M56 - Measure the stop time over the PV count with the 15-minute short term store partition

Origin: 2.0.1 / M56
Identity History: moved from Backlog to Milestone on 2026-10-23 under D64
GitHub Issue: none
Status: Complete

##### Summary

The main cells of M55 use the 5-minute short term store partition, and one validation stop uses the shipped partition. A 15-minute partition holds three times the data of the 5-minute partition in the same number of files and would show how the stop time grows between the two.

##### Scope

- Run the main cells of M55 (the stages of 903 and 3000 PVs with the hold of 2) once more with the short term store partition `PARTITION_15MIN`, set through `ARCHAPPL_STS_GRANULARITY` in `../CONFIG_SITE.local` of the guest, with the rule, the order, the reset, the measurement and the verdicts of M55, and one stop for each cell. Write down the prediction of every cell from the line of M55 before the cells run. The line of M55 was fitted on the 5-minute partition, so a difference is reported without a single cause.
- Extend `tests/stop-time/run-stop.bash` and `tests/stop-time/rebuild-table.bash` to the partition `PARTITION_15MIN` (900 s). The STS to MTS pass of this partition starts 5 minutes after each boundary, as on the hourly partition, so the stop lies between 30 and 90 seconds after E; `tests/stop-time/selftest.bash` gets a case for it.

Out of scope: a change of the repository other than the partition support of `tests/stop-time/`, of the policies or of the defaults; a change of the documents; a run on Rocky Linux 8.10; any run on the production appliance of the development host (ports 17665 to 17668, `/opt/epicsarchiverap-maven`, `/arch`).

##### Completion Criteria

- A table in the form of M55 lists the stops with the stop duration of the unit and of each instance, the files and bytes of the short term store, the time after the boundary, the unit result, the consolidated PVs, the left PVs, the refs and the method.
- The statement gives for each cell the difference between the stop time and the prediction of the line of M55, and the verdicts C1 and C2 of M55 for each stop.

##### Dependencies And Decisions

- Decision Date: 2026-10-19. The owner reduced M55 to the stages of 903 and 3000 PVs after the stop time of ansible-provision at 903 PVs (13 seconds) showed a per-PV part near 5 milliseconds. This item is Deferred until the result of M55. It reopens by a new dated decision when the result of M55 cannot be carried to the shipped partition: C3 of the validation stop is Failed, or the ETL gap per PV of the validation stop exceeds that of the cell `main-903` by more than 50 percent, or a stop time lies near the stop timeout.
- M55 supplies the method, the PV set, the conditions and the line; the guest is a new one (decision of 2026-10-21 below).
- Decision Date: 2026-10-21. The owner reopened this item: its reopening condition is met, because C3 of the validation stop of M55 is Failed (3.74 s on the shipped partition, outside the interval of the line of the main cells). The status returns from Deferred to Not started; the plan stays a draft until its acceptance.
- Decision Date: 2026-10-21. The owner chose a fresh Debian 13 guest for this item and M57, so the disk of the guest of M55 stays unchanged as evidence; M56 runs first and M57 follows on the same guest. Both items run as scoped.
- Decision Date: 2026-10-21. The scripts of M55 accept only the 5-minute and the hourly partition; the owner put their extension to `PARTITION_15MIN` into this item.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: accepted by the owner on 2026-10-21
Implementation Authorization: the owner authorized the implementation on 2026-10-21
Superseded Plan Artifacts: none

1. Extend `run-stop.bash` and `rebuild-table.bash` to `PARTITION_15MIN` (900 s, the stop between 30 and 90 seconds after E) and add its case to `selftest.bash` (T6). The change lands by its own commit and push authority before step 2, or reaches the guest as a patch whose SHA-256 the results record.
2. Request a fresh Debian 13 guest of 2 vCPU, 4 GiB and one 30 GiB disk from the provider session, and prepare it as M55 prepared its guest: the settings of M55 (persistent journal, file appender of the pass events, heap 256M), source `a8d07955`, this repository at the commit that carries step 1 or a later one (it also carries the rendering by the checkout owner of `0323fab`), with the commit used recorded in the results, the 903 PVs of ansible-provision and the 2097 generated PVs (T1).
3. Set the partition `PARTITION_15MIN` in `../CONFIG_SITE.local` and run the reset of M55 with its policy change, which stops the unit first and renders (`make conf.archapplproperties`, `make conf.install`) and installs (`sudo make install`) inside it; archive the PVs on the fresh database, and check the rendered `policies.py` and the stored URL of one PV (T1).
4. Write down the predictions, then run the cells in the order of M55 (T2, T3). Under the rule of M55 a stop lies after the boundary E, B0 plus three partitions, so each stop waits up to one hour on this partition. The main cells take `--expectation` with the expectation file of the rehearsal of M55, `~/stop-time-evidence/st-20261019/expectation.jsonl` on the host, copied to the guest, as the main cells of M55 did.
5. Freeze the evidence, rebuild the table from copies and compare it with the predictions (T4, T5). The guest stays for M57.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | VM | Prepare the fresh guest as M55 prepared its guest, then set the partition `PARTITION_15MIN`, render with `make conf.archapplproperties` and `make conf.install`, install, archive on a fresh database, and read the rendered `policies.py` and the stored URL of one PV | Fresh guest | The partition and the hold of the cell are in the stored URL |
| T2 | VM | Stop each cell once under the rule of M55 with the measurement commands that M55 proved | Fresh guest | A stop duration of the unit and of each instance for every cell, with the unit result, the time after the boundary and the file count |
| T3 | VM | Cut the journal of each stop, read the error lines, the unit result and the four launcher lines, check overlap, and list the three stores before and after the stop | Fresh guest | The consolidated and the left PVs, the stops that the unit ended or that overlapped, and a stop with a missing required line marked Incomplete |
| T4 | Local | Freeze the evidence, rebuild the table from copies, and compare it with the recorded table and the predictions | Local host | Every value follows from the retained files, and the originals are unchanged |
| T5 | Review | Read the coverage table and the comparison with the line of M55 | Local host | Each claim names the stage and the stop duration that support it, and no cell that did not run counts as passed |
| T6 | Local | Run `tests/stop-time/selftest.bash` with the case of `PARTITION_15MIN`, and `run-stop.bash` with an unknown partition | Local host | The selftest passes, the 15-minute case uses 900 s and the window of 30 to 90 seconds, and an unknown partition is still refused |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-21 | Fresh Debian 13 guest from the provider (2 vCPU, 4 GiB, 30 GiB), source `a8d07955`, this repository `877cf38` | Passed | The guest was prepared with the settings of M55 (persistent journal of 1G with the rate limit of 30 s and 10000, `chrony`, the site `log4j2.xml` of M55 with the same SHA-256, heaps of 256M, the guard file), the ansible-provision fixtures at `635d76c` passed `check-sources.py` (8 files) and the 2097 generated PVs have the SHA-256 of M55. The EPICS Base copy needed `dbd` besides `bin` and `lib`: without it `softIoc` stopped with `Can't open file .../dbd/softIoc.dbd`. With `PARTITION_15MIN` in `../CONFIG_SITE.local` before the first installation, the rendered `policies.py` and the stored URL of a PV of each policy (Default, Fast, Medium, VeryFast) carry `partitionGranularity=PARTITION_15MIN&hold=2`; all 903 PVs and, after the reset, all 3000 PVs were `Being archived` and connected; the ten deadband records read -1 |
| T2 | 2026-10-21 | Fresh Debian 13 guest from the provider (2 vCPU, 4 GiB, 30 GiB), source `a8d07955`, this repository `877cf38` | Passed | One stop of each cell under the rule of M55, exit status 0: `main-903` E 10:15:00Z, stop 30.74 s after E, unit 2.368 s; `main-3000` E 11:15:00Z, 31.02 s after E, unit 8.072 s; both `success`. A first start of `run-stop.bash` for `main-903` was refused with status 3 before any side effect, because no pass had written `etl-pass.log` yet; it was started again after the first pass. A first archivePV of the 3000 PVs returned HTTP 500 while the appliance was still starting and archived nothing; it was sent again when `getPVStatus` answered. Both refusals are kept in the evidence |
| T3 | 2026-10-21 | Fresh Debian 13 guest from the provider (2 vCPU, 4 GiB, 30 GiB), source `a8d07955`, this repository `877cf38` | Passed | Both stops have the four launcher lines, the unit result, the listings before and after and the cut of `etl-pass.log` (C1 Passed); every PV had hold + 2 = 4 files before the stop and was consolidated (903 and 3000), no PV was left, no overlap and no off-rule mark (C2 Passed) |
| T4 | 2026-10-21 | Local host | Passed | The evidence (136 files) was copied from the guest and checked against its `SHA256SUMS`; `rebuild-table.bash --stop` on a separate copy rebuilt both records with the 36 fields of the recorded `stops.jsonl` and no difference; the originals were unchanged afterwards |
| T5 | 2026-10-21 | Local host | Passed | The table and the statement in Closure Evidence name the stage and the stop duration of every claim; both cells ran, one stop each, as scoped |
| T6 | 2026-10-21 | Local host | Passed | `tests/stop-time/selftest.bash` exit 0, 149 of 149: `run-stop.bash` with `PARTITION_15MIN` passes the option checks and stops at the guard file, `PARTITION_30MIN` is refused with status 3 and the message that names the three partitions; a copy of the fixture stop `stop-01-passed` with one more pass planned two hours before E counts 1 pass in the window (slowest 850 ms) as `PARTITION_15MIN` and 2 (9999 ms) as `PARTITION_HOUR`. The same selftest with the earlier `rebuild-table.bash` failed the two 15-minute window assertions (2 passes, 9999 ms), so the case detects the 3600 s window; shellcheck reports nothing for the three changed scripts |

##### Closure Evidence

- Complete on 2026-10-21. The support of `PARTITION_15MIN` in `tests/stop-time/` landed in `4c8c9ee` on `origin/release-2.0.1` (T6); T1 to T6 Passed. Report on the host, `~/stop-time-evidence/m56-20261021/report/report.md` (SHA-256 `4d86cdbe2f7e450fd3de7c571cb9f109b3bfe64a9bc5957abe3393dbac89c7e9`); the raw evidence stays private on the host and the guest, whose disk is kept for M57.
- Conditions: those of M55 (Debian 13 guest of 2 vCPU and 4 GiB with one 30 GiB disk, source `a8d07955`, heaps of 256M, root logger INFO with the file appender of the pass events, `TimeoutStopSec` 300 s, `ETLPassStopWaitSeconds` 60 s, the 903 PVs of ansible-provision and the 2097 generated PVs), with `PARTITION_15MIN` and hold 2, on a fresh guest and this repository at `877cf38`.

| Cell | Stop | InvocationID | PVs | Partition | STS bytes per PV | After E (s) | Unit stop (s) | Engine (s) | ETL (s) | Mgmt (s) | Result | Left | Loop jobs | Loop sum (s) | Longest job (ms) | C1 | C2 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| main-903 | 1 | `a8fc26aa` | 903 | PARTITION_15MIN | 309672 | 30.74 | 2.368 | 1.101 | 1.146 | 0.071 | success | 0 | 903 | 1.096 | 15 | Passed | Passed |
| main-3000 | 1 | `07340fc6` | 3000 | PARTITION_15MIN | 132072 | 31.02 | 8.072 | 1.203 | 6.727 | 0.071 | success | 0 | 3000 | 6.668 | 18 | Passed | Passed |

- Statement. The predictions of the line of M55, written before the cells ran, are 2.32356 s at 903 PVs and 7.02872 s at 3000 PVs; the stops took 2.368 s (+0.045 s, +1.9 percent) and 8.072 s (+1.043 s, +14.8 percent). The stop at 903 PVs lies inside the range of the three stops of M55 on the 5-minute partition (2.236 s to 2.391 s); the stop at 3000 PVs lies above the longest of them (7.807 s). As in M55, the growth is the ETL instance (1.146 s and 6.727 s, against means of 1.063 s and 5.659 s in M55), while the engine gap stays near 1.1 s to 1.2 s. Differences that may explain the excess at 3000 PVs, without one assigned cause: about 2.9 times the bytes per PV in the short term store (132072 against 45329 to 45814), a mean loop job of 2.22 ms against 1.72 ms to 2.11 ms, and one stop against three. Both stops suffice (C1 and C2 Passed: result `success`, far inside the timeout of 300 s, no PV left).

##### GitHub Projection

Title: none
Labels: none
GitHub Milestone: none
Observed State: none; no issue exists
Last Compared: none

#### M57 - Measure the stop time over the PV count with the shipped short term store partition

Origin: 2.0.1 / M57
Identity History: moved from Backlog to Milestone on 2026-10-23 under D64
GitHub Issue: none
Status: Complete

##### Summary

The main cells of M55 use the 5-minute short term store partition, and one validation stop uses the shipped partition. The main cells on the shipped partition would measure the stop time of the shipped state for each stage.

##### Scope

- Run the main cells of M55 (the stages of 903 and 3000 PVs with the hold of 2) once more with the short term store partition `PARTITION_HOUR`, set through `ARCHAPPL_STS_GRANULARITY` in `../CONFIG_SITE.local` of the guest, with the rule, the order, the reset, the measurement and the verdicts of M55, and one stop for each cell. Write down the prediction of every cell from the line of M55 before the cells run. The line of M55 was fitted on the 5-minute partition, so a difference is reported without a single cause.

Out of scope: a change of the repository, the policies or the defaults; a change of the documents; a run on Rocky Linux 8.10; any run on the production appliance of the development host (ports 17665 to 17668, `/opt/epicsarchiverap-maven`, `/arch`).

##### Completion Criteria

- A table in the form of M55 lists the stops with the stop duration of the unit and of each instance, the files and bytes of the short term store, the time after the boundary, the unit result, the consolidated PVs, the left PVs, the refs and the method.
- The statement gives for each cell the difference between the stop time and the prediction of the line of M55, and the verdicts C1 and C2 of M55 for each stop.

##### Dependencies And Decisions

- Decision Date: 2026-10-19. The owner reduced M55 to the stages of 903 and 3000 PVs after the stop time of ansible-provision at 903 PVs (13 seconds) showed a per-PV part near 5 milliseconds. This item is Deferred until the result of M55. It reopens by a new dated decision when the result of M55 cannot be carried to the shipped partition: C3 of the validation stop is Failed, or the ETL gap per PV of the validation stop exceeds that of the cell `main-903` by more than 50 percent, or a stop time lies near the stop timeout.
- M55 supplies the method, the PV set, the conditions and the line; the guest is a new one (decision of 2026-10-21 below).
- M56 is a work ordering dependency: this item runs on the guest of M56 after M56.
- Decision Date: 2026-10-21. The owner reopened this item: its reopening condition is met, because C3 of the validation stop of M55 is Failed (3.74 s on the shipped partition, outside the interval of the line of the main cells). The status returns from Deferred to Not started; the plan stays a draft until its acceptance.
- Decision Date: 2026-10-21. The owner chose a fresh Debian 13 guest for this item and M56, so the disk of the guest of M55 stays unchanged as evidence; M56 runs first and M57 follows on the same guest. Both items run as scoped.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: accepted by the owner on 2026-10-21
Implementation Authorization: the owner authorized the implementation on 2026-10-21
Superseded Plan Artifacts: none

1. On the guest of M56, set the partition `PARTITION_HOUR` in `../CONFIG_SITE.local` and run the reset of M55 with its policy change, which stops the unit first and renders (`make conf.archapplproperties`, `make conf.install`) and installs (`sudo make install`) inside it; archive the PVs on the fresh database, and check the rendered `policies.py` and the stored URL of one PV (T1).
2. Write down the predictions, then run the cells in the order of M55 (T2, T3). Under the rule of M55 a stop lies after the boundary E, B0 plus three partitions, so each stop waits up to four hours on this partition, as the validation stop of M55 did. The main cells take `--expectation` with the expectation file of the rehearsal of M55, `~/stop-time-evidence/st-20261019/expectation.jsonl` on the host, copied to the guest, as the main cells of M55 did.
3. Freeze the evidence, rebuild the table from copies and compare it with the predictions (T4, T5), then send the finished notice for the guest and ask to keep its disk as evidence.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | VM | Set the partition `PARTITION_HOUR`, render with `make conf.archapplproperties` and `make conf.install`, install, archive on a fresh database, and read the rendered `policies.py` and the stored URL of one PV | Guest of M56 | The partition and the hold of the cell are in the stored URL |
| T2 | VM | Stop each cell once under the rule of M55 with the measurement commands that M55 proved | Guest of M56 | A stop duration of the unit and of each instance for every cell, with the unit result, the time after the boundary and the file count |
| T3 | VM | Cut the journal of each stop, read the error lines, the unit result and the four launcher lines, check overlap, and list the three stores before and after the stop | Guest of M56 | The consolidated and the left PVs, the stops that the unit ended or that overlapped, and a stop with a missing required line marked Incomplete |
| T4 | Local | Freeze the evidence, rebuild the table from copies, and compare it with the recorded table and the predictions | Local host | Every value follows from the retained files, and the originals are unchanged |
| T5 | Review | Read the coverage table and the comparison with the line of M55 | Local host | Each claim names the stage and the stop duration that support it, and no cell that did not run counts as passed |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-21 | Guest of M56 (fresh Debian 13, 2 vCPU, 4 GiB, 30 GiB), source `a8d07955`, this repository `877cf38` | Passed | The partition was set to `PARTITION_HOUR` in `../CONFIG_SITE.local`, and the reset of M55 ran with its policy change: `make sd_stop`, `make conf.archapplproperties` (the rendered `policies.py` carries `partitionGranularity=PARTITION_HOUR&hold=2`), `sudo make conf.storage.rm` (`/arch` gone), `sudo make conf.storage`, `make sql.update`, `sudo make sql.table.fill`, `sudo make sql.show`, `make conf.install`, `sudo make install`, `make sd_start`, each with exit status 0 and no file owned by root in the checkout. The IOC stage was written for 903 PVs, all 903 PVs were `Being archived` and connected, and the stored URL of `AASOAK:FAST:CH01` carries `PARTITION_HOUR&hold=2`; for the stage of 3000 PVs the reset was repeated (without the install, because the policy did not change), the IOC served the 2097 further PVs (`STOPTIME:E0001` and `E2097` read, the ten deadband records -1), all 3000 PVs were `Being archived` and connected, and the stored URL of `STOPTIME:E0001` carries `PARTITION_HOUR&hold=2` |
| T2 | 2026-10-21 | Guest of M56 (fresh Debian 13, 2 vCPU, 4 GiB, 30 GiB), source `a8d07955`, this repository `877cf38` | Passed | One stop of each cell under the rule of M55, exit status 0: `main-903` E 19:00:00Z (12:00 PDT), stop 31.04 s after E, unit 2.932 s; `main-3000` E 23:00:00Z (16:00 PDT), 30.67 s after E, unit 9.730 s; both `success`. The accumulation took (hold + 2) hourly partitions, so each stop waited about three hours after B0 |
| T3 | 2026-10-21 | Guest of M56 (fresh Debian 13, 2 vCPU, 4 GiB, 30 GiB), source `a8d07955`, this repository `877cf38` | Passed | Both stops have the four launcher lines, the unit result, the listings before and after and the cut of `etl-pass.log` (C1 Passed); every PV had hold + 2 = 4 files before the stop and was consolidated (903 and 3000), no PV was left, no overlap and no off-rule mark (C2 Passed) |
| T4 | 2026-10-21 | Local host | Passed | The evidence (138 files) was copied from the guest and checked against its `SHA256SUMS`; `rebuild-table.bash --stop` on a separate copy rebuilt both records with the 36 fields of the recorded `stops.jsonl` and no difference; the originals were unchanged afterwards |
| T5 | 2026-10-21 | Local host | Passed | The table and the statement in Closure Evidence name the stage and the stop duration of every claim; both cells ran, one stop each, as scoped |

##### Closure Evidence

- Complete on 2026-10-21. The scripts and the guest are those of M56 (support of the partition in `4c8c9ee`, the result of M56 in `0029bc9`); T1 to T5 Passed. Report on the host, `~/stop-time-evidence/m57-20261021/report/report.md` (SHA-256 `8ef283e21485de33eca6be2786cdf18e0a60a7cdf26ab5bc2e4b23add0c62971`); the raw evidence stays private on the host and the guest.
- The requester sent the finished notice for the guest on 2026-10-21 after the evidence was copied and verified on its host, and asked to keep the disk as evidence; the provider answered on 2026-10-21 that the guest is shut off and stays defined, with its disk, seed, creation record and address reservation kept until its owner decides on removal; its name, address and access stay in the private records of the provider and the requester.
- Conditions: those of M55 and M56 (Debian 13 guest of 2 vCPU and 4 GiB with one 30 GiB disk, source `a8d07955`, heaps of 256M, root logger INFO with the file appender of the pass events, `TimeoutStopSec` 300 s, `ETLPassStopWaitSeconds` 60 s, the 903 PVs of ansible-provision and the 2097 generated PVs), with the shipped partition `PARTITION_HOUR` and hold 2, on the guest of M56 and this repository at `877cf38`.

| Cell | Stop | InvocationID | PVs | Partition | STS bytes per PV | After E (s) | Unit stop (s) | Engine (s) | ETL (s) | Mgmt (s) | Result | Left | Loop jobs | Loop sum (s) | Longest job (ms) | C1 | C2 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| main-903 | 1 | `f82c6083` | 903 | PARTITION_HOUR | 1237210 | 31.04 | 2.932 | 1.113 | 1.652 | 0.086 | success | 0 | 903 | 1.592 | 115 | Passed | Passed |
| main-3000 | 1 | `d6f5143d` | 3000 | PARTITION_HOUR | 531658 | 30.67 | 9.730 | 1.247 | 8.333 | 0.089 | success | 0 | 3000 | 8.276 | 94 | Passed | Passed |

- Statement. The predictions of the line of M55, written before the cells ran, are 2.32356 s at 903 PVs and 7.02872 s at 3000 PVs; the stops took 2.932 s (+0.609 s, +26.2 percent) and 9.730 s (+2.701 s, +38.4 percent). Both stops lie above the 5-minute stops of M55 (2.236 s to 2.391 s at 903 PVs and 6.605 s to 7.807 s at 3000 PVs), and the stop at 903 PVs lies above the upper end 2.71858 s of the interval that M55 wrote for the validation stop; the validation stop of M55 (3.740 s) was longer than this one. As in M55 and M56, the growth is the ETL instance (1.652 s and 8.333 s, against 1.146 s and 6.727 s on the 15-minute partition and means of 1.063 s and 5.659 s on the 5-minute partition), while the engine gap stays near 1.1 s to 1.2 s. On the three partitions the stop time at 3000 PVs is 7.0 s (mean, 5 minutes), 8.1 s (15 minutes) and 9.7 s (one hour), one stop each for the last two. Differences that may explain the growth, without one assigned cause: the bytes per PV in the short term store (1237210 and 531658 against 309672 and 132072 on the 15-minute partition, 4.0 times, and about 11.7 times those of the 5-minute partition), a mean loop job of 1.76 ms and 2.76 ms against 1.22 ms and 2.22 ms on the 15-minute partition, and one stop for each cell. The two cells give a slope of 3.24 ms per PV between 903 and 3000 PVs on the shipped partition, against 2.24 ms of the line of M55; with the intercept of 5 ms this reaches the stop timeout of 300 s near 92500 PVs and 80 percent of it near 74000 PVs. That value is an extrapolation beyond 3000 PVs from two single stops, has no interval, and does not replace the line of M55. Both stops suffice (C1 and C2 Passed: result `success`, far inside the timeout of 300 s, no PV left). A site sizing rule would change `docs/README.install.md` and `docs/technicaldocs/README.systemd.md` and needs its own item; this item changes no document.

##### GitHub Projection

Title: none
Labels: none
GitHub Milestone: none
Observed State: none; no issue exists
Last Compared: none

#### M58 - Keep the checkout writable for the engineer after `sudo make install` and `sudo make sql.fill`

Origin: 2.0.1 / M58
Identity History: moved from Backlog to Milestone on 2026-10-23 under D64
GitHub Issue: none
Status: Complete

##### Summary

The installation guide runs `sudo make install` in the checkout of the engineer, and the reset of M55 runs `sudo make sql.fill` there. Both leave rendered files owned by root in the checkout (`site-template/systemd/*`, `site-template/.versions`, `site-template/sql/archappl_sqlite_updated.sql`), and a later Make target that renders into the same folder as the engineer fails; observed on the guest of M55 on 2026-10-20, where `make sd_install` stopped with `cannot create .../site-template/systemd/override.conf: Permission denied`. M55 works around it by giving the files back to the engineer after each such command.

##### Scope

- Find every Make target that the documented sequences run with `sudo` and that writes into the checkout, and the files each leaves owned by root.
- Separate rendering from installation (owner decision of 2026-10-20). The targets that run as root render nothing into the checkout: `install` installs the rendered systemd units and refuses, naming the rendering target, when one is missing or older than its template or the configuration (`configure/CONFIG*`, `configure/RELEASE*`, `../CONFIG_SITE.local`, `../RELEASE.local`); `sql.table.fill` loads the rendered schema. The rendering (`conf.systemd`, `src_version`, `sql.update`) runs as the engineer before them, and each rendering rule removes its file before it writes it, so that a file an earlier root run left in the checkout does not stop it. The removal stops instead when a path variable (`AA_SITE_TEMPLATE_PATH`, `SQL_AA_UPDATE_SQL`, `SQL_AA_UPDATE_SQLITE`) is empty, or when a file name variable (`SYSTEMD_OVERRIDE_FILENAME`, `SYSTEMD_FILENAME`, `APPNAME`) is empty or holds a path.
- The callers follow: `scripts/install-local-common.bash` renders as the engineer before each root step, `docs/README.install.md` (the ordered sequence, the reinstall and the SQLite schema step) names the rendering step, and the reset of M55 names it too.
- The local tests that drive these targets (`tests/phase1-logic.bash`, `tests/health-local.py`, `tests/database-config.py`) follow the split.
- The book pages that show the installation and the schema load follow the split (owner decision of 2026-10-20): `book/src/install/sqlite.md`, `book/src/understand/build-and-install.md` and the generated `book/src/appendix/make-targets.md` change; `book/src/configure/installed-files.md` (the units come from their `.in` templates) and `book/src/install/reinstall.md` (it runs the installer) stay correct as they are.

Out of scope: the ownership of the installed tree under the installation path and of the storage folders; a change of the database backend or of the installation scripts beyond the ownership.

##### Completion Criteria

- After the documented `sudo make install` and `sudo make sql.fill` on a fresh guest, `make sd_install` and `make conf.archapplproperties` run as the engineer without a permission error, or the guide names the command that makes them run.
- The checkout holds no file owned by root after the documented sequence, or the guide states which files and why.

##### Dependencies And Decisions

- Decision Date: 2026-10-20. The owner placed the item in the Backlog, to be fixed after the measurement of M55.
- Decision Date: 2026-10-20. The owner chose the remedy: separate rendering from installation, rather than giving the files back after a root step or documenting a step that restores the ownership.
- Decision Date: 2026-10-20. The installation check runs on a fresh guest, not on the guest of M55, whose disk is evidence. The provider session creates such a guest on a complete request under its standing authorization, so the guest is a step of the plan and not an external gate.
- Decision Date: 2026-10-20. The book pages that show the installation and the schema load are part of this item, and the reset of M55 is rewritten for the split.
- Decision Date: 2026-10-20. A checkout installed before this item holds rendered files owned by root; the rendering rules remove such a file before they write it, instead of a step in the guide that restores the ownership.
- M55 found the behavior and holds its evidence; its reset carries the workaround until this item closes.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: accepted by the owner on 2026-10-20
Implementation Authorization: the owner authorized the implementation on 2026-10-20
Superseded Plan Artifacts: none

1. Rules: `configure/RULES_INSTALL`, `configure/RULES_SYSTEMD` and `configure/RULES_SQL` keep every write into the checkout in a rendering target and every root target free of such writes; `install` refuses with the name of the rendering target when a rendered file is missing (T1, T2).
2. Callers: `scripts/install-local-common.bash` runs the rendering as the engineer before `root_make install` and before the SQLite schema load as root; `docs/README.install.md`, the four book pages and the reset of M55 name the rendering step (T2, T3).
3. Local tests: adapt `tests/phase1-logic.bash` and `tests/database-config.py` to the split and run `tests/run-all-tests.bash --local` (T2).
4. Request a fresh guest from the provider session, run the local installation and the reset of M55 on it, then the engineer targets; on a checkout that an installation before this item left with rendered files owned by root, run the rendering as the engineer (T4); then send the finished notice (T3, T4).

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | `make -n` of every target that the installer and the guide run as root (`install`, `sql.table.fill`, `sql.show`, `conf.storage`, `conf.storage.rm`, `tomcat.install`, `sd_health_stop`, `src_preinst`) | Local host | No command writes into the checkout; before the change `install` writes the four systemd files and `.versions`, and `sql.fill` writes `site-template/sql/archappl_sqlite_updated.sql` |
| T2 | Local | `tests/run-all-tests.bash --local` with the adapted tests, and `install` without the rendered files | Local host | The local suite passes, and `install` refuses with the name of the rendering target |
| T3 | VM | On a fresh guest run `scripts/install-local-sqlite.bash`, the reset of M55, then `make sd_install` and `make conf.archapplproperties` as the engineer, and list the files owned by root in the checkout | Fresh guest | The installation and the appliance start pass, the engineer targets run without a permission error, and no file in the checkout outside the source tree is owned by root |
| T4 | VM | On the guest of T3, run `make sd_stop`, revert the checkout to `240e1e1`, remove the six rendered files (the four units in `site-template/systemd/`, `site-template/.versions`, `site-template/sql/archappl_sqlite_updated.sql`), run `sudo make install` and `sudo make sql.fill` there, apply the change of this item as a patch on `240e1e1`, then run `make conf.install` and `make sql.update` as the engineer, `sudo make install`, `make sd_start`, `make sd_install` and `make conf.archapplproperties`, and list the files owned by root in the checkout | Guest of T3 | Before the change the engineer rendering stops with a permission error; after it the rendering, the installation and the engineer targets pass, the appliance is active, and no file in the checkout outside the source tree is owned by root |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-20 | Local host | Passed | Before the change `make -n install` wrote the four systemd units and `site-template/.versions`, and `make -n sql.fill` wrote `site-template/sql/archappl_sqlite_updated.sql`. After it, `make -n` of `install`, `sql.table.fill`, `sql.show`, `conf.storage`, `conf.storage.rm`, `tomcat.install`, `sd_health_stop` and `src_preinst` prints no write into the checkout; the writes moved to `conf.install` (the four units and `.versions`) and `sql.update` (the schema copy), both run as the checkout owner; `make conf.install` with an invalid `DB_BACKEND` stops before it renders. The third-person review found that a unit rendered before a change of `../CONFIG_SITE.local` was installed unchanged (a timeout of 300 s after a change to 1 s); with the check of the age of the rendered file the install stops and names the newer input and `conf.install`, and after a new rendering it installs the changed value |
| T2 | 2026-10-20 | Local host (Debian 13) | Passed | `tests/run-all-tests.bash --local` exit status 0 with the real EPICS Base, including the new check P1.19a (no write under the checkout by `make -n install` and `make -n sql.table.fill`; `install.systemd0` and `sql.table.fill` stop with status 2 and name `conf.install` and `sql.update` without their rendered files; `install.systemd0` stops on a unit older than its template or `../CONFIG_SITE.local` and installs the changed value after a new rendering; phase 1 287 of 287) and `SystemdFileTests`, which render with the `conf.*` unit rules before `install.systemd`. In a copy without rendered files `install.systemd0`, `install.override`, `install.health.service` and the MariaDB `sql.table.fill` each stopped with status 2 at the check line, before any privileged command. A run under the long scratch path failed one unrelated check (`make db.addAdmin` reports `ERROR 2001` instead of `ERROR 2002`), because the socket path of that check exceeds the length of a Unix socket path; under a short path it passes. Run again on 2026-10-20 with the removal of rendered files left by root and its guards (change SHA256 prefix `b1846312d8b0e978`): exit status 0, phase 1 290 of 290, including the rendering over a unit the checkout owner cannot write and the stop on a unit file name with a path |
| T3 | 2026-10-20 | Fresh Debian 13 guest from the provider (2 vCPU, 4 GiB, 30 GiB), this repository `240e1e1` with the change applied as a patch, source `8f0d616a` | Passed | The first installation with `scripts/install-local-sqlite.bash -y` ran `conf.install` and `sql.update` as the engineer and `sql.table.fill` and `install` as root, exit status 0, appliance active, no file in the checkout outside the source tree owned by root. With the final change (the check of the age of the rendered files) the reinstall with `--tomcat existing` (a run without the choice stops at the Tomcat preparation, as the guide states) exited 0 with no file owned by root. The reset of M55 in its new order (`make sd_stop`, `make conf.archapplproperties`, `sudo make conf.storage.rm`, `sudo make conf.storage`, `make sql.update`, `sudo make sql.table.fill`, `sudo make sql.show`, `make conf.install`, `sudo make install`, `make sd_start`) exited 0 in every step, `/arch` was removed and recreated and the appliance answered again; then `make sd_install` and `make conf.archapplproperties` as the engineer exited 0 (the first failed with a permission error before this item), and no file in the checkout was owned by root |
| T4 | 2026-10-20 | Guest of T3, this repository `240e1e1`, then the change applied as a patch (SHA256 prefix `b1846312d8b0e978`), source `8f0d616a` | Passed | At `240e1e1`, `sudo make install` and `sudo make sql.fill` exited 0 and left six files owned by root (the four units, `site-template/.versions`, `site-template/sql/archappl_sqlite_updated.sql`), and `make conf.systemd` as the engineer exited 2 with `cannot create .../site-template/systemd/override.conf: Permission denied`. With the change, `make conf.install` and `make sql.update` as the engineer exited 0 and left no file owned by root; `sudo make install`, `make sd_start` (appliance active after 60 s), `make sd_install` and `make conf.archapplproperties` exited 0, and no file in the checkout outside the source tree was owned by root. Evidence: guest `~/m58-evidence/t4` |

##### Closure Evidence

- Commit `0323fab7ad642a522a19f977e8f502362ec05697` ("Render install inputs as the checkout owner and install them as root") carries the rules, the installer, the tests, the guide, the book pages and this record; T1 to T4 Passed against it (T3 and T4 on the same change applied as a patch).
- Landing: observed 2026-10-21 with `git ls-remote origin refs/heads/release-2.0.1`, which returned `0323fab7ad642a522a19f977e8f502362ec05697`; the 13 changed paths of `git diff --name-only 240e1e1 0323fab` are the paths of the commit.
- The guest of T3 and T4 was returned to the provider session with a finished notice on 2026-10-21; its disk keeps the evidence.

##### GitHub Projection

Title: none
Labels: none
GitHub Milestone: none
Observed State: none; no issue exists
Last Compared: none

#### M59 - Record the measured stop times in the systemd reference

Origin: 2.0.1 / M59
Identity History: moved from Backlog to Milestone on 2026-10-23 under D64
GitHub Issue: none
Status: Complete

##### Summary

The measurements of M55, M56 and M57 give the stop time of the unit at 903 and 3000 PVs on the 5-minute, 15-minute and hourly short term store partitions. The systemd reference states that a site sets its own `SYSTEMD_TIMEOUT_STOP_SECONDS` after timing its stop, and holds no measured values. The owner judged the measurements too few for a sizing rule (D62) and chose to record them as measurements.

##### Scope

- Add one section to `docs/technicaldocs/README.systemd.md`: the conditions of the measurements (guest, database, hold, time of the stop after the partition boundary), the stop times of the six cells, the share of the ETL instance, and the limits of the measurements.
- Every value of the section is a value of the Verification Results or the statements of M55, M56 and M57.
- Replace the clause of the unit file paragraph that gave a test host with three PVs stopping in about 10 s by a pointer to the new section (D63).

Out of scope: a sizing rule, a recommended timeout, an extrapolation beyond 3000 PVs, a change of the default of `SYSTEMD_TIMEOUT_STOP_SECONDS`, `docs/README.install.md`, and the book.

##### Completion Criteria

- The section states the conditions, the six cell values and the limits, and contains no rule, recommendation or extrapolation.
- Every number of the section equals the value recorded in M55, M56 or M57.
- The unit file paragraph names no stop time that disagrees with the section and points to it.

##### Dependencies And Decisions

- M55, M56 and M57 hold the measurements and their evidence.
- Decision Date: 2026-10-23. D62: record the measurements only, in `docs/technicaldocs/README.systemd.md`.
- Decision Date: 2026-10-23. D63: the owner ordered the register and the document to say the same about the test host sentence. This reopens the item with a third plan step; it is Complete again with T3.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: accepted by the owner on 2026-10-23; step 3 added and accepted by the owner on 2026-10-23
Implementation Authorization: the owner authorized the implementation on 2026-10-23, and step 3 on 2026-10-23
Superseded Plan Artifacts: none

1. Write the section before `## Instance lifecycle` of `docs/technicaldocs/README.systemd.md` from the statements of M55, M56 and M57 (T1).
2. Run a second-person pass on the section, then correct the findings (T2).
3. Replace the clause about a test host with three PVs in the unit file paragraph by a pointer to the section (T3).

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Extract every number of the new section and search each in the text of M55, M56 and M57 of this register | Local host | Every number appears in the cited rows or statements |
| T2 | Local | Second-person pass over the section, `git diff --check`, and a search of the section for a recommendation or an extrapolation | Local host | No finding above the floor; no recommendation or extrapolation |
| T3 | Local | `grep` of `docs/technicaldocs/README.systemd.md` and of `docs/` and `book/` for the old clause | Local host | The old clause is absent from the systemd reference and from the book; in this register it occurs only where D63 and M59 describe it; the pointer and the section heading each occur once |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-23 | Local host | Passed | The 25 distinct numbers of the section `Measured stop times` in `docs/technicaldocs/README.systemd.md` were extracted with a script and each was found in the text of M55, M56 and M57 of this register. The six cell values and the ETL values were then read against the statements of M55 (2.236 s to 2.391 s and 6.605 s to 7.807 s; ETL about 1.06 s and 5.66 s), M56 (2.368 s and 8.072 s) and M57 (2.932 s and 9.730 s; ETL 1.652 s and 8.333 s); the stops of M56 and M57 began 30.67 s to 31.04 s after the boundary, as the section states |
| T2 | 2026-10-23 | Local host | Passed | Two second-person passes over the whole section. The first, from a site engineer who sizes the timeout, found three minor findings: the definition of the stop time, the word `stage` that the page does not explain, and the hold without a link; all three are applied. The second, from a maintainer who checks the values against this register, found nothing above the floor. `git diff --check` exit status 0; the section contains no recommended value, rule or extrapolation |
| T3 | 2026-10-23 | Local host | Passed | `grep -c 'test host with three PVs'` and `grep -c 'about 10 s'` on `docs/technicaldocs/README.systemd.md` returned 0; `grep -rn 'about 10 s' docs book` found the phrase only in D63, in M59 and in two rows of M55 about samples per second; `grep -c 'Measured stop times below'` returned 1 and `grep -c '^## Measured stop times$'` returned 1. A second-person pass over the changed sentence, from a site engineer, found nothing above the floor |

##### Closure Evidence

- Commit `9f369e1ea23459367a9309266466d4fb6d82bdff` ("Document the measured stop times in the systemd reference") carries the section and this record; T1 and T2 Passed against it.
- Landing: observed 2026-10-23 21:17 PDT (2026-10-24 04:17 UTC) with `git ls-remote origin refs/heads/release-2.0.1`, which returned `9f369e1ea23459367a9309266466d4fb6d82bdff`; the two changed paths of `git diff --name-only 377dc38 9f369e1` are `docs/milestone-2.0.1.md` and `docs/technicaldocs/README.systemd.md`.
- The correction of the unit file paragraph (D63, T3) is carried by the commit that carries this line; `git log -- docs/technicaldocs/README.systemd.md` names it.

#### M53 - Write the appliance book of the repository (`book/`)

Origin: 2.0.1 / M53
Identity History: moved from Backlog to Milestone on 2026-10-23 under D64
GitHub Issue: none
Status: In progress

##### Summary

`book/` holds an mdBook for the appliance: concepts, install and operate procedures, reference tables and a glossary, written from the code, the configuration and commands run on a host. Five reference pages (`configure/variables.md`, `appendix/make-targets.md`, `appendix/script-options.md`, `configure/policy-parameters.md`, `interface/judgements.md`) are printed by `book/scripts/gen-*.bash` from the code, and `book/scripts/check-generated.bash` fails when one differs from its generator. The structure and the page rules are in `book/PLAN.md`; the page types and title forms follow the owner's technical-writing skill.

##### Scope

- The pages listed in `book/src/SUMMARY.md`, the generators and the generated-page check.
- The commit of the pages and of the `.gitignore` exception that keeps `book/src/test/` tracked.
- A GitHub Actions workflow that checks the generated pages after `make init`, builds the book with a pinned mdBook release and publishes it from the default branch.
- Commands on the install and operate pages that this host could not run as shown, run on a disposable appliance or VM and recorded as real output.
- The page `book/src/understand/data-journey.md` and its figures, adapted from `docs/README.DataJourney.md` under D60.

Out of scope: any change of the data journey document and its figures (`docs/README.DataJourney.md`, `docs/figures`), which the owner manages separately; the `docs/*.md` guides, which stay as they are.

##### Completion Criteria

- Every page has one type and the title form of that type, and `SUMMARY.md` reaches every page.
- `bash book/scripts/check-generated.bash` reports every generated page current.
- `mdbook build book` passes on a clean clone of the branch with no warning.
- A page shows a command only when it ran as shown; a page whose commands need `sudo`, systemd or an installed appliance says so in its introduction until the VM verification runs them.
- A workflow publishes the built book, and the published site equals a local build.

##### Dependencies And Decisions

- Owner rules of 2026-10-11: the book lives in `book/`, is written from the code and from commands run, never from the existing `docs/*.md`; it holds no working history and no host-specific values; deployment by GitHub Actions comes last.
- The VM verification of 2.0.1 (M44) is the run that can record real output for the pages that need `sudo`, systemd or an installed appliance.
- D60 lets the page of the data journey be adapted from its `docs/` document; the other pages stay written from the code and from commands run.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: accepted by the owner on 2026-10-12
Implementation Authorization: the owner directed the work on 2026-10-11
Superseded Plan Artifacts: none

1. Write the pages and the generators, and review them against the page types (done).
2. Record real output on a disposable appliance or VM for the pages that could not run here.
3. Add the publishing workflow (done) and verify the published site after its first run on the default branch.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | `mdbook build book` in a fresh clone of the branch | Local host | Exit 0, no warning, and the pages of `book/src/test/` are not empty |
| T2 | Local | `bash book/scripts/check-generated.bash` with `AA_SOURCE_CLONE` set to a fresh clone of the source branch | Local host | Every generated page is current |
| T3 | Review | Second-person review of the whole book against the technical-writing checklist | Local host | Findings applied and a final pass without findings |
| T4 | VM | Run the install and operate commands that need `sudo`, systemd or an installed appliance, as shown | Disposable VM of the accepted matrix | Each command runs as shown; the output matches the page |
| T5 | CI | The publishing workflow on the default branch: the jobs `generated`, `build` and `deploy` | GitHub Actions | All three jobs pass and the published site equals a local build |
| T6 | Local | `mdbook build book` with mdBook 0.5.4, the release that the workflow installs, in a fresh copy of the tree | Local host | Exit 0 and no warning |
| T7 | Local | In a shallow fresh clone: `make init`, then `bash book/scripts/check-generated.bash` | Local host | Every generated page is current |
| T8 | Operate | `storage`, `make sd_status`, `make sd_health_status`, `health` as the service account and as an ordinary user, and `journalctl` of the service unit | Installed appliance of the local host | Each output matches its page |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-18 | Local host; fresh clone of the pushed branch at `ae46c35`, mdBook 0.5.4 | Pass | `mdbook build book` exit 0 with no warning or error; 37 pages, among them `understand/data-journey.html` with its six figures; `test/vm.html` builds with 27.7 KB. The run of 2026-10-12 at `d04de37` passed too |
| T2 | 2026-10-12 | Local checkout at `d04de37`; fresh clone of `modernize` at `0097bc2d` | Pass | exit 0; all five generated pages current |
| T3 | 2026-10-12 | Local host | Pass | whole-book pass, applied-findings pass, technical-writing pass and a final pass; the final pass found nothing to change |
| T4 | 2026-10-13 00:58 to 01:05 PDT | Debian 13 guest of the one-case run below (env `c4beb5d`, source `514be155`, service account `mid-srv`) | Pass for the operate, verify and install pages; the next guest run repeats them after the page fixes | Commands of `operate/health.md`, `logs.md`, `loglevel.md`, `storage.md`, `start-stop.md` and `install/verify-pv.md` run as shown with the placeholders replaced, and the outputs equal the pages in form (loglevel byte for byte; values such as process ids and use percentages differ). Two commands did not run as the pages showed them: `sudo -u tomcat` of the health page (the guest account is `mid-srv`; the page now uses `<service_account>`) and `bash scripts/archappl.bash storage` in a checkout (it needs the `archappl.conf` next to the installed script; the page now uses `<install_location>`). The corrected commands exit 0 on the guest. The install pages need a checkout owned by an ordinary user, and the checkout of this guest belongs to root, so they were not run there. They ran on a second fresh Debian 13 guest, 2026-10-13 02:30 to 03:00 PDT (env `148cae1`, source `74258cc7`, ordinary user with `sudo`, checkout cloned from the public repository): `prepare-host.md` (package lists as shown, 17 packages installed, Java 21), `sqlite.md` (installer exit 0, health, four startup APIs and appliance information PASS), `verify-pv.md` (`PV acquisition, storage and retrieval: PASS`, 4 stored samples, EPICS Base copied from the host), `reinstall.md` (exit 0, service active, the registered PV kept in the database), `mariadb-uds.md` and `mariadb-tcp.md` (exit 0, same checks PASS). Three differences from the pages were found and the pages carry the correction: the SQLite plan on a host without Tomcat lists three more lines (`tomcat.get`, the SHA-512 verification and `tomcat.install`); a quoted `DB_HOST_NAME="127.0.0.1"` in `../CONFIG_SITE.local` makes `db.create` fail with `ERROR 2005` because `make` keeps the quote characters (the unquoted value passes); a failed installer leaves the service stopped by design, which the three installer pages now state |
| T5 | Not run | none | Pending | none |
| T6 | 2026-10-18 | Local host; fresh clone of the pushed branch at `ae46c35` | Pass | mdBook 0.5.4 (archive SHA-256 `3f28de05dafca9d0f2eab99c662116b0e37b89b1d96a08f8f430b9eeae958cd7`, checked against the value that the workflow pins) exit 0 with no warning. The run of 2026-10-12 at `92b2aa7` passed after a generator fix; before it the build warned about an unclosed `<os>` tag in `configure/variables.md`, which the browser would have hidden |
| T7 | 2026-10-12 | Local host; shallow clone (depth 1) of the tree of `92b2aa7`; selected source `992d8ac4` | Pass | `make init` exit 0 in about 52 s; `check-generated.bash` exit 0 with all five generated pages current |
| T8 | 2026-10-12 | Installed appliance of the local host | Pass | `storage` printed the three store folders and the total; `make sd_status` showed the service active with the four instances; `make sd_health_status` exits `0` after the fix and printed `Error 3` before it; `health` as the service account printed all four components `PRESENT` and exit `0`, as an ordinary user `unreadable-process-executable` for each and exit `2`; `journalctl -u` as root printed the instance lines, as an ordinary user outside the journal groups `-- No entries --` with exit `0` |

##### Closure Evidence

- none

##### GitHub Projection

Title: none
Labels: none
GitHub Milestone: none
Observed State: none; no issue exists
Last Compared: none

#### M60 - Let a site set the health starting bound through the configuration files

Origin: 2.0.1 / M60
Identity History: none
GitHub Issue: [#62](https://github.com/jeonghanlee/epicsarchiverap-env/issues/62)
Status: Complete

##### Summary

`ARCHAPPL_HEALTH_STARTING_SECONDS` bounds how long `archappl.bash health` reports an instance as starting (default 10 seconds, valid 1 to 59). `scripts/archappl.bash` reads it after it loads the `archappl.conf` next to the script, but nothing writes it into that file: `configure/CONFIG_SITE`, `site-template/archappl.conf.in` and the `conf.archappl` substitution list in `configure/RULES_PROPERTIES` do not name it. A value in `../CONFIG_SITE.local` therefore has no effect, and the scheduled check, which systemd runs without a site environment, always uses the default. `ARCHAPPL_STORAGE_ALARM_PERCENT` has all three parts and works. The book page `book/src/operate/health.md` lists the variable as settable in `../CONFIG_SITE.local`, which is false until this item lands.

##### Scope

- `configure/CONFIG_SITE`: the default `ARCHAPPL_HEALTH_STARTING_SECONDS:=10` and a comment that names the valid range 1 to 59, beside `ARCHAPPL_STORAGE_ALARM_PERCENT`.
- `site-template/archappl.conf.in`: the line `ARCHAPPL_HEALTH_STARTING_SECONDS=@ARCHAPPL_HEALTH_STARTING_SECONDS@`.
- `configure/RULES_PROPERTIES`: the matching substitution in the `conf.archappl` list.
- The tests: `tests/phase1-logic.bash` (the block that checks `ARCHAPPL_STORAGE_ALARM_PERCENT`) and `tests/health-starting.bash`.
- The documents that name the variable: `docs/technicaldocs/README.systemd.md`, `CHANGELOG.md`, `book/src/operate/health.md` (the sentence that a changed value reaches the check only through a reinstall now covers both variables) and the generated page `book/src/configure/variables.md`.

Out of scope: a change of the default of 10 seconds or of the range 1 to 59, a change of the startup allowance `SYSTEMD_HEALTH_STARTUP_SECONDS`, and a change of `scripts/archappl.bash`.

##### Completion Criteria

- With no site setting, the rendered `archappl.conf` holds `ARCHAPPL_HEALTH_STARTING_SECONDS=10`.
- A value in `../CONFIG_SITE.local` reaches `archappl.conf` after `make conf.archapplproperties`.
- The health check uses the rendered value: a start older than it reports `FAIL startup-timeout`, and a value outside 1 to 59 reports `ERROR starting-invalid-bound`.
- The scheduled check, run by systemd, uses the rendered value after a reinstall.
- The documents that name the variable agree with this behavior, and `book/scripts/check-generated.bash` reports every generated page current.

##### Dependencies And Decisions

- D65, Decision Date: 2026-10-24. The variable follows the pattern of `ARCHAPPL_STORAGE_ALARM_PERCENT`.
- The rendered line is a plain assignment, as for `ARCHAPPL_STORAGE_ALARM_PERCENT`. An installed `archappl.conf` is loaded before the variable is read, so it takes precedence over the process environment of a manual run.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-24; revised on 2026-10-24 to add the reinstall to item 6 and T5
Implementation Authorization: 2026-10-24, plan items 1 to 6 as revised, including the guest request and its restart
Superseded Plan Artifacts: none

1. Add the default and its comment to `configure/CONFIG_SITE`, the line to `site-template/archappl.conf.in` and the substitution to `configure/RULES_PROPERTIES`, each beside the entry of `ARCHAPPL_STORAGE_ALARM_PERCENT` (T1).
2. Extend the block of `tests/phase1-logic.bash` that checks `ARCHAPPL_STORAGE_ALARM_PERCENT` with the same checks for the new variable: the default is rendered, and a value in `../CONFIG_SITE.local` reaches `archappl.conf` (T1).
3. Add to `tests/health-starting.bash` a case that sets the bound only in the `archappl.conf` of the test workspace, with no environment variable, and expects the same `FAIL startup-timeout` and `ERROR starting-invalid-bound` results, then checks that the assignment of `archappl.conf` wins over a different value in the environment (T2).
4. Update the documents named in Scope and regenerate the generated pages with `book/scripts/generate-all.bash` (T3).
5. Run `tests/run-all-tests.bash --local` (T4).
6. Request a fresh guest from the provider session, set a value in `../CONFIG_SITE.local`, install, check `archappl.conf` and the scheduled check, then change the value, install again and check both again (T5).

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | The extended block of `tests/phase1-logic.bash` renders `archappl.conf` through the real `make conf.archappl` (the rule that `make conf.archapplproperties` runs) with no setting and with a value in `../CONFIG_SITE.local` | Local host | The default renders as 10 and the site value renders unchanged; before the change the line is absent |
| T2 | Local | The new case of `tests/health-starting.bash` runs the shipped `archappl.bash health` with the bound only in `archappl.conf` | Local host | `FAIL startup-timeout` for a start older than the bound and `ERROR starting-invalid-bound` for a value outside 1 to 59, with no environment variable set; the assignment of `archappl.conf` wins over a different value in the environment |
| T3 | Local | `book/scripts/check-generated.bash` and `mdbook build` | Local host | Every generated page is current and the book builds |
| T4 | Local | `tests/run-all-tests.bash --local` with the real EPICS Base | Local host | Exit status 0 without failures |
| T5 | VM | On a fresh guest, set a value in `../CONFIG_SITE.local`, install with the shipped installer, read the installed `archappl.conf` and the journal of the scheduled health check, then change the value, run the installer again and read both again | Fresh guest | The installed `archappl.conf` holds the value and the scheduled check applies it, and after the second run it holds the changed value |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-10-24 13:19 PDT (20:19 UTC) | Local host | Pass | `tests/phase1-logic.bash` exit 0 with the two new checks OK (default 10, site value 20). A first run at 13:17 PDT failed one existing timestamp check, because the edited inputs were under one minute old; it passed once they were older. In an unchanged copy of HEAD the rendered `archappl.conf` holds no `ARCHAPPL_HEALTH_STARTING_SECONDS` line |
| T2 | 2026-10-24 13:40 PDT (20:40 UTC) | Local host | Pass | `tests/health-starting.bash`: passed=40 failed=0, including `FAIL startup-timeout` for bound 1 and `ERROR starting-invalid-bound` for 0 and 60, all from `archappl.conf` with the environment variable unset, and an invalid bound in `archappl.conf` outranking a valid environment bound and the reverse |
| T3 | 2026-10-24 13:17 PDT (20:17 UTC) | Local host | Pass | `book/scripts/generate-all.bash`, then `book/scripts/check-generated.bash` reports every page current, and `mdbook build` completes |
| T4 | 2026-10-24 13:40 PDT (20:40 UTC); real Base part 2026-10-25 22:41-22:43 PDT (2026-10-26 05:41-05:43 UTC) | Local host | Pass | The run of 2026-10-24 13:40 PDT: `tests/run-all-tests.bash --local` exit 0, no `[FAIL]` line, on the tree that holds the precedence cases of T2, without `AA_TEST_EPICS_BIN`; that run skipped the real Base part that the Test Plan requires. The run of 2026-10-25: `EXPECTED_BRANCH=release-2.0.1 AA_TEST_EPICS_BIN=/home/jeonglee/alsu-epics/1.3.0/debian-13/7.0.10/base/bin/linux-x86_64 bash tests/run-all-tests.bash --local` exit 0 on the tracked tree that was committed three minutes later as `70ffe75`, `854010e` and `6411c82` (the last contains `d7cb9a2`), with only the register file uncommitted, with no `FAIL`, `SKIP` or `WARN` line and `PASS: EPICS preflight resolves the supplied real Base binaries.`: Phase 1 296, Health 40, No Ant 22, Interface files 401, Phase 2 14 |
| T5 | 2026-10-24 13:28-13:34 PDT (20:28-20:34 UTC), reinstall 14:09-14:37 PDT (21:09-21:37 UTC) | Fresh Debian 13 guest `lab-debian13-health20261024a`, request `m60-health-t5-20261024` | Pass | The uncommitted tracked tree of this checkout (base `4f50137`) and `ARCHAPPL_HEALTH_STARTING_SECONDS:=20` in `../CONFIG_SITE.local`; `scripts/install-local-sqlite.bash -y` printed `Installation completed. All required installation checks passed.`; the installed `archappl.conf` holds `ARCHAPPL_HEALTH_STARTING_SECONDS=20`; the shipped `archappl.bash health` run by hand as `tomcat` without the variable in the environment traces `starting_limit=20`; the unit `epicsarchiverap-maven-health.service` has an empty `Environment` and runs that command, and its journal shows `health PRESENT all-four-processes-verified` at 13:33:31 PDT after two `SKIP startup-allowance` runs. The journal does not print the bound, so the scheduled run is tied to the value by the unit and the manual trace, not by its own output. Reinstall: the guest checkout at `d7cb9a2` (the pushed commit) and `ARCHAPPL_HEALTH_STARTING_SECONDS:=30` in `../CONFIG_SITE.local`; the first run of the installer at 14:09 PDT stopped in Tomcat preparation and asked for `--tomcat existing` or `--tomcat replace`, with no installed file changed (the conf still held 20 and the units were active); the second run `scripts/install-local-sqlite.bash -y --tomcat existing` at 14:35 PDT printed `Installation completed. All required installation checks passed.`, the installed `archappl.conf` holds 30, the shipped `archappl.bash health` run as `tomcat` without the variable traces `starting_limit=30`, the unit `Environment` is empty, and the journal shows `health PRESENT all-four-processes-verified` at 14:36:44 PDT after `SKIP` runs for the stop and the startup allowance |

##### Closure Evidence

- Landed: commit `d7cb9a2` ("Render the health starting bound into archappl.conf from site settings") pushed to `origin/release-2.0.1` on 2026-10-24 at 14:06 PDT (21:06 UTC); `git fetch` after the push showed `HEAD` and `origin/release-2.0.1` both at `d7cb9a2`. Recheck: `git -C <repository> rev-parse HEAD origin/release-2.0.1`.
- T1 to T4 were run again from 13:48 to 13:52 PDT (20:48-20:52 UTC) on the tree that became `d7cb9a2`: `tests/phase1-logic.bash`, `tests/health-starting.bash` (40 passed), `tests/run-all-tests.bash --local`, `book/scripts/check-generated.bash` and `mdbook build` all exited 0, the full local run again without `AA_TEST_EPICS_BIN`; T4 with the real Base binaries is recorded in its row.
- GitHub issue #62 was closed on 2026-10-24 at 15:46 PDT (22:46 UTC) with a body that checks every acceptance criterion and a comment that cites `d7cb9a2` and `f1ca8e6`. Recheck: `gh issue view 62 --repo jeonghanlee/epicsarchiverap-env --json state,closedAt`.

#### M44 - Verify and publish release 2.0.1

Origin: 2.0.1 / M44
Identity History: none
GitHub Issue: none
Status: In progress

##### Summary

Produce immutable 2.0.1 release objects from the combined verified patch candidate and verify the actual released installation path.

##### Scope

- Integrated re-runs, production-equivalent installation, version checks, authorized merge/publication, and post-release verification.

Out of scope: another release line, automatic security fixes, changing or deleting 2.0.0 release objects.

##### Completion Criteria

- M43, M14, M10, M45 and M46 complete, G6 complete, and all required final checks Pass. Heap measurement is Backlog work under D37 and is not required for 2.0.1.
- The annotated 2.0.1 tag and GitHub release resolve to the authorized candidate.
- Required issue states and canonical closure agree after publication.

##### Dependencies And Decisions

- M43, M14, M10, M45, M46, M13, D31, D37, D39, D44, D45, D56 and D66. The Ant removal is part of this release and is complete (M14, G6). M13 is a work-ordering dependency set by D45: release verification starts after M13 is complete. The release plan accepted on 2026-10-05 lists no M13 dependency, so its re-acceptance is pending.
- Current committed candidate: epicsarchiverap-env `48724a28e0ce7a49f3c302f814b10116652b331e`, source pin `162269e7db97f527626ba0b387933a8c47e8bb57` (`Replace the archive request client with Bash`) in `configure/RELEASE`. After that commit `SRC_TAG` moved to `origin/modernize`, whose commit `61e1b4c5c819fc2473b27e2046cbab80fecc558c` added over `162269e7` the sample buffer margin change, the replaced management interface and the MariaDB driver 3.5.10; D66 then set `SRC_TAG` to the tag `2026-10` (`e0a8e66e`). The local suite and the day run pass at the tag (Release Verification Results); source CI and the eight-case run at the tag are not recorded. D44 records the earlier `120d53fe` candidate; its results and the earlier `af2e7348` results remain evidence only for their original refs. Release readiness requires passing source CI, new integrated verification and eight-case VM verification at the final pin. The tested and released source must stay equal. The pinned Ansible and cloud-provision inventory generator of the VM acceptance stay fixed for the matrix; the cloud-provision species rename does not block it.
- Historical source CI observation: 2026-10-07 at 16:38 PDT, the public page of [Maven run 37698987276](https://github.com/jeonghanlee/epicsarchiverap-maven/actions/runs/37698987276) for `modernize` commit `120d53fe43133c7699e4c9624dc948cc96b0ece2` reports `Success`. The page is `rv2-120d53fe-20261007/source-ci.html`; the verification manifest records its SHA256. This satisfies source CI only for that historical pin. No source CI result for `162269e7` or for any commit of `modernize` after it is recorded here.
- Candidate publication observation: 2026-10-09 at 22:32 UTC, after `git fetch`, `git status --short --branch` is clean and `git rev-parse HEAD '@{upstream}'` resolves both refs to `48724a28e0ce7a49f3c302f814b10116652b331e`. This confirms release-branch publication, not a merge, tag or GitHub release.
- Report to `jeonghanlee/epicsarchiverap-maven#31`, posted 2026-10-12: the four MariaDB cases of the eight-case run (`debian13-socket`, `debian13-tcp`, `rocky8-socket`, `rocky8-tcp`) passed with source `84ae8a83`, a descendant of `61e1b4c5`. The comment states that the run does not list `WEB-INF/lib` of each WAR to assert that no other driver jar is present.
- Source of the release: the tag `2026-10` of epicsarchiverap-maven, commit `e0a8e66e` (D66). The installer-built appliance at this source ran 903 PVs for a day; the record is `docs/reports/soak-903pv-20261026.md` (`587df6e`), and epicsarchiverap-maven records the acceptance as decision D11 in its `docs/milestone-bfb0dc71.md` at `0c103015`. The record states what the run did not show: the retrieval memory protection acting, the transfer from MTS to LTS and the first 30 minutes. Source CI at the tag and the eight-case VM run at this commit are not recorded here.
- Committed local installation changes provide SQLite, MariaDB UDS and MariaDB TCP entrypoints with shared installation code, Tomcat reuse or backup/replacement, EPICS preparation before optional PV verification, component startup/UI/information URLs, and distinct process/storage inspection results. The optional PV path uses the source Bash archive client and CSV extraction client; pause/resume and IOC ownership are explicit. MariaDB setup selects the administrative socket and preserves existing backup files. Failure output retains successful checks and explains storage limits without deleting data or automatically restarting the appliance.
- Local installer OS selection supports Debian 13, Rocky Linux 8.x, Rocky Linux 10.2, Ubuntu 24.04 LTS and Ubuntu 26.04 LTS. All five presets preserve a custom `JAVA_HOME`. Preset/package checks do not establish real installation on every OS. The accepted Release Verification 3 matrix remains Debian 13 and Rocky 8.10; adding OS cases requires a separate scope decision.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-05; owner accepted the revised release plan (dependencies M43, M14, M10, M45 and M46, source pin under D39, RV3 eight-case matrix, RV6 one SQLite case per operating system); 2026-10-07, owner accepted the candidate pin and preliminary verification before source CI completion under D44
Implementation Authorization: 2026-10-05; owner authorized the changelog entry, the local suite on the release candidate, the release notes draft and the preparation of the eight-case matrix; 2026-10-07, owner authorized the D44 pin update and preliminary local verification. Subsequent local installer changes and the current pin were committed and pushed through the separately delegated actions recorded below. On 2026-10-09, owner authorized this canonical status/evidence update only. Further commits, pushes, every guest request, the VM run, and the release objects (merge, tag, GitHub release, milestone close) need separate authority
Superseded Plan Artifacts: draft written before the Ant removal and the two defect-containment items, carried by d3e16d54d05a57de281fb353802e24947187ca3f, docs/milestone-2.0.1.md, M44

1. Accept this release plan and the work plans, commit the canonical plan, then project issues to GitHub.
2. Complete the ordered work; record actual refs, configuration and evidence for each check.
3. Preserve pre-change checks, write the changelog entry in the style of the 2.0.0 entry from the five closed issues (backend rejection, VM acceptance, launcher starting verdict, journal and CA failure evidence, Ant removal), and prove the combined 2.0.1 candidate. No version-bump commit exists: the repository has no numeric version field beyond the changelog and the release objects.
4. Prepare the exact authorized merge, branch push, annotated tag, tag push and release commands through `git-workflow`.
5. Execute separately authorized actions, verify the released object on clean hosts, reconcile issues and close this cycle.

##### Test Plan

Final checks are owned by Release Verification Plan below; no local T labels apply.

##### Verification Results

Final observations are owned by Release Verification Results below.

##### Closure Evidence

- none

##### Integrated Verification

| Source Check | Re-run Trigger | Shared Surface | Release Verification Label | Expected Result | Result Evidence |
| --- | --- | --- | --- | --- | --- |
| M43 / T1, M43 / T2 | Later Make, install, source schema or DB-helper changes | Backend command routing | Release Verification 2 | Rejections and supported behavior hold on final tree | Pass at `5c51bc3` / `e0a8e66e`: the database integration test with a real MariaDB and the database configuration tests of the local suite (Release Verification Results); historical integrated Pass at `120d53fe` retained |
| M14 / T1, M14 / T3 | Later source-pin, site-input or Make changes | Build and installed WARs | Release Verification 2 | No Ant in the tracked tree; the shipped build passes with the site folder and fails when a site `build.xml` is put back | T3 (site build.xml rejected) Pass at `cb49f3b` / `e0a8e66e`; T1: the local suite of a clean clone at `cb49f3b` with `AA_TEST_EPICS_BIN` set to the real Base of the release 1.3.0 distribution tree exits 0 with No Ant 22/0, Phase 1 316/0, Phase 2 14/0 and no SKIP line; historical build, payload and rejection Pass at `120d53fe` retained |
| M45 / T2, M46 / T1, M46 / T2 | Later launcher, verifier or health changes | Launcher health and VM verifier | Release Verification 3 | The starting verdict and the failure-evidence retention hold on the final tree | M46 / T1 and M46 / T2: the Health group of the local suite (`tests/health-starting.bash`, 40/0) passes at `5c51bc3`; M45 / T2 and M46 / T3 are not run at this source (D70) |
| M10 / T1 | Later install, build or configuration changes | Documented installation | Release Verification 3 | Real VM installation checks pass | Pass for `bbad185` / source `84ae8a83` (eight-case run recorded below); Pass at the final pin `3185bb0` / source `e0a8e66e` by the check of D67, accepted by D68 |

##### Production Environment Tests

| Release Verification Label | Timing | System | Version | Architecture | Deployment Path | Method | Expected Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Release Verification 3 | post-change | Debian; Rocky Linux | 13; 8.10 | x86_64 | Documented prerequisites and eight ordered install targets | The accepted eight-case matrix through the shipped VM driver: Debian 13 and Rocky 8.10 with MariaDB socket, MariaDB TCP and SQLite, plus a build-failure case on each; real WAR build, four JVMs, systemd, health timer, HTTP identity, CA acquisition and timestamped retrieval | Installed candidate works on the accepted backend matrix | Pending |
| Release Verification 6 | post-release | Debian; Rocky Linux | 13; 8.10 | x86_64 | Clean guest using the immutable 2.0.1 tag commit and the install guide | One SQLite case per operating system that follows the install pages at the tag commit (D69): real build, four JVMs, health timer, version, and changing PV acquisition and retrieval by the soft IOC check of the installer, on a guest that holds EPICS Base | Released object runs; evidence records refs, options and backend; the clean installs of Release Verification 3 cover the same source | Pending |

##### Version Changes

| Field | File | Before | Planned After | Pre-check | Pre-check Label | Post-check | Post-check Label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Changelog release heading | CHANGELOG.md | Newest dated release 2.0.0 | One dated 2.0.1 heading above preserved 2.0.0 | Read committed heading and working-tree diff | Release Verification 1 | Check date, uniqueness and actual shipped scope | Release Verification 4 |
| SRC_TAG | configure/RELEASE | d8a7813f40083c1bf7148e6c3b7bffd368d70ee0 before this cycle | Tag `2026-10` (commit `e0a8e66e`, D66, `cb5fb2f`); source CI at this commit must pass and the check of D67 must be recorded before release | Resolve committed Make value and source identity | Release Verification 1 | Resolve effective pin, build refs and source changes | Release Verification 4 |

The source POM belongs to epicsarchiverap-maven. This cycle does not independently bump it. APPNAME, SRC_VERSION and install-path derivation remain checked for consistency; no environment numeric version field has been identified beyond the changelog and release objects. At `48724a2`, `CHANGELOG.md` has an unreleased 2.0.1 heading and still describes the earlier `120d53fe` pin. Release Verification 4 must reconcile the changelog pin and shipped scope, set the release date, and check the release notes before publication; this status update does not change those files.

##### Release Execution

| Step | Action | Authorization | Expected Result | Evidence |
| --- | --- | --- | --- | --- |
| 1 | Planning and candidate commits on release-2.0.1 | Separate Commit/add scope | Only reviewed files committed | Latest candidate `48724a28e0ce7a49f3c302f814b10116652b331e`, committed 2026-10-09 at 00:59 PDT; earlier installer commits `ac516f0`, `e875487`, `bcd34cc` and `482cf29`; later documentation or candidate changes still require their own commit authority |
| 2 | Publish release-2.0.1 branch | Separate Push scope | Same-named branch and upstream verified | `48724a2` published; local HEAD and fetched origin/release-2.0.1 match, observed 2026-10-09 at 22:32 UTC; later changes still require their own push authority |
| 3 | Merge verified release-2.0.1 into the default branch `maven` of this repository (not epicsarchiverap-maven) with a merge commit | Exact preview and separate Release authority | Reviewed merge commit becomes release candidate | Executed 2026-10-28 under the Release scope from the previewed command: `maven` at `d68f668` merged with `--no-ff`; merge commit `e906960f25efdae80f8bd6272519cde23606f393`, parents `d68f668` and `63f2b1e`, tree equal to the tree of `release-2.0.1` |
| 4 | Publish branch `maven` | Separate Push scope or exact authorized release sequence | Remote candidate equals local | Pushed in the previewed sequence; local `maven` and `origin/maven` are both `e906960f25efdae80f8bd6272519cde23606f393` |
| 5 | Create annotated tag 2.0.1 on merge candidate | Exact preview and separate Release authority | Immutable tag object recorded | Annotated tag object `a5f376c64d1f9de5b615d5d7d4e767fae24067f4`, peeled to `e906960f25efdae80f8bd6272519cde23606f393`; the tagged tree has `SRC_TAG:=2026-10` |
| 6 | Publish refs/tags/2.0.1 | Separate Tag push scope | Remote tag object and peeled candidate match | Pushed in the previewed sequence under the Release scope; the remote tag object equals the local object and its peeled commit is `e906960f25efdae80f8bd6272519cde23606f393` |
| 7 | Create GitHub release 2.0.1 with reviewed notes | Exact preview and separate Release authority | Published non-prerelease object references tag | Published 2026-10-28T08:45:18Z: no draft, no prerelease, latest; the body is the 2.0.1 section of `CHANGELOG.md` with the lead line and the compare link (67 lines) |
| 8 | Reconcile issues and close GitHub milestone 2.0.1 | Issue scope for issues; milestone close requires separately authorized exact release sequence or user execution | Required issues closed and milestone closed | Milestone 7 (2.0.1) closed 2026-10-28T08:45:26Z with 7 closed issues and 0 open ones; the issues were closed before the release; issue 53 stays open outside the milestone |
| 9 | Record canonical closure and next entry point | Separate documentation and commit/push authority | Checked closure published; next release unassigned | Pending |

##### Release Verification Plan

| Label | Layer | Timing | Method | Environment | Expected Result | Evidence Target |
| --- | --- | --- | --- | --- | --- | --- |
| Release Verification 1 | Baseline | pre-change | Record current epicsarchiverap-env commit, effective source pin, changelog and existing released refs before candidate version changes | Checkout and origin | Reproducible pre-change baseline | Private evidence with public hashes |
| Release Verification 2 | Integrated | post-change | Execute the shipped local suite, M43 routing and DB checks, and the real build with the Maven-run site overlay on the combined candidate | Supported local toolchain and disposable DBs | No failed or required skipped check | Suite/build logs and payload hashes |
| Release Verification 3 | Deployment | post-change | Run the real VM installation and runtime entrypoints on the accepted eight-case matrix (for release 2.0.1 at `e0a8e66e`, the check of D67 replaces the driver run) | Debian 13 and Rocky 8.10 | Actual installed system, acquisition and retrieval succeed | Install/runtime evidence |
| Release Verification 4 | Candidate | post-change | Resolve changelog/source versions and confirm the shipped heap default is unchanged; no new heap recommendation is included | Combined candidate | Consistent 2.0.1 candidate within the assigned scope | Version and configuration evidence |
| Release Verification 5 | Published objects | post-release | Read origin tag object/peeled commit and GitHub release flags/notes | origin and GitHub | Objects match recorded authorized candidate | Remote observations with time |
| Release Verification 6 | Released installation | post-release | Execute documented clean installation and runtime checks from immutable tag | Clean Debian 13 and Rocky 8.10 hosts | Actual released system succeeds on accepted matrix | Private install/runtime evidence and hashes |
| Release Verification 7 | Closure | post-release | Compare canonical rows/details, GitHub issues/milestone, published closure and next entry | Canonical document, origin and GitHub | Scope complete, evidence coherent, 2.0.0 unchanged, next release unassigned | Dated closure observations |

##### Release Verification Results

Results are specific to the environment and source refs in each row. The 2026-10-07 Release Verification 2 Pass is historical evidence at `120d53fe`, not acceptance of the current `48724a2` / `162269e7` candidate. Release Verification 2 for the candidate at `5c51bc3` / `e0a8e66e` is closed with the limits of D70.

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| Release Verification 1 | 2026-10-28T08:02Z (2026-10-28 01:02 PDT) | Local checkout at `78eabc4d42e95431a283dc015dd0185cf6a3e26c`, `origin` and GitHub read-only | Pass | the baseline of this register (env `d68f668`, tag 2.0.0 commit `386c91d`, source pin `d8a7813f`) is unchanged: `origin/maven` is `d68f668` and an ancestor of `origin/release-2.0.1` (175 commits ahead, 0 behind), the tag 2.0.0 peels to `386c91d74086313efe04e0b64eb5dacfd91f8389`, and the GitHub release 2.0.0 is the latest; `SRC_TAG:=2026-10` in `configure/RELEASE` resolves in the source clone to `e0a8e66ed09e840ab8ed67dae81b25474605db08`, and the published tag 2026-10 of epicsarchiverap-maven peels to the same commit; `CHANGELOG.md` has one 2.0.1 heading, `## [2.0.1] - unreleased` (dated 2026-10-28 in `63f2b1e`), above `## [2.0.0] - 2026-09-28`; read with `git ls-remote`, `git rev-parse`, `gh release list` and a read of `configure/RELEASE` and `CHANGELOG.md` |
| Release Verification 2 | 2026-10-07 16:50 PDT | Local Debian 13, JDK 21; isolated environment at `e2ade5a184098379424ed87972ff308490eeedec` plus the D44 candidate patch, source `120d53fe43133c7699e4c9624dc948cc96b0ece2`, site `als`, SQLite build configuration and short `/tmp` test workspace | Pass | Shipped `--local` exits 0 without failures or skips: Phase 1 223/0, health 20, starting health 32/0, no-Ant 22/0, database 10, VM local 36, Phase 2 13/0; all 20 tracked test files are unchanged. Real `database-config.py --integration` passes both tests, including MariaDB socket/TCP account, schema, query, backup/restore and SQLite schema loading. Shipped `make conf.archapplproperties build.mvn DB_BACKEND=sqlite MAVEN_FLAGS='-o -B -ntp'` produces four real WARs; 246 artifact checks verify 47 site images, main CSS, three classpath files and version in each WAR, mgmt CSS, and 33 merged template blocks. The original site `build.xml` from `4800b4ae^` makes the real build exit 2 with the site-overlay rejection; moving that file out restores BUILD SUCCESS. Evidence: `rv2-120d53fe-20261007/verification.json`, SHA256 `93b5bdcfa1e431f29a4155c3f69f265e8f9429921665c3859e62247e59b6dd54`, records commands, exit statuses, all log hashes, the candidate patch, retained workspace and WAR hashes; `payload-manifest.json`, SHA256 `d9a6e777b9bbdd9aeb0c0f8f511056c064621bf0d8aa56cc01018f03a1249b5a`, records every WAR entry. This verifies the local integrated path only. |
| Release Verification 3 | 2026-10-28T00:43Z to 03:28Z (2026-10-27 17:43 to 20:28 PDT) | See the row Release Verification 3, clean installs at the tag 2026-10 below | Pass | Accepted by the owner (D68); `docs/reports/clean-install-20261028.md` |
| Release Verification 4 | 2026-10-28T08:02Z (2026-10-28 01:02 PDT) | Local checkout at `78eabc4d42e95431a283dc015dd0185cf6a3e26c` | Pass | The release date is set in `63f2b1e` and the release notes are the published release body (Release Verification 5); the 2.0.1 section names the default tag `2026-10` and none of the earlier pins, `AA_JAVA_HEAPSIZE="256M"` is the value of the tag 2.0.0 and no heap line of `configure/` differs from it, and the section holds no heap statement; read with `git show 2.0.0:configure/CONFIG_SITE`, `git diff 2.0.0 HEAD -- configure` and a search of the changelog section |
| Release Verification 5 | 2026-10-28T08:50:46Z (2026-10-28 01:50 PDT) | origin and GitHub, read-only, after the release actions | Pass | origin has the annotated tag 2.0.1, object `a5f376c64d1f9de5b615d5d7d4e767fae24067f4`, peeled to `e906960f25efdae80f8bd6272519cde23606f393`, which is the tip of `origin/maven`; the GitHub release 2.0.1 is published at 2026-10-28T08:45:18Z, is no draft and no prerelease, is the latest, and its body of 67 lines starts with `**epicsarchiverap-env 2.0.1**` and ends with the compare link `2.0.0...2.0.1`; read with `git ls-remote` and `gh release view` |
| Release Verification 6 | 2026-10-28T08:53Z to 09:16Z (2026-10-28 01:53 to 02:16 PDT) | Local libvirt host; two fresh guests built from the golden images that hold EPICS Base 7.0.10 (Debian 13, and Rocky Linux 8.10 with SELinux Enforcing and an active `firewalld`), 2 vCPU, 4 GiB, 20 GiB; clone of the tag 2.0.1 (commit `e906960f25efdae80f8bd6272519cde23606f393`, `SRC_TAG:=2026-10`); `scripts/install-local-sqlite.bash` run interactively with the soft IOC test | Pass | Debian 13: installer exit 0 in 8 min (08:53:29Z to 09:01:29Z), `health` exit 0, four `startupState` values `STARTUP_COMPLETE`, version `e0a8e66e`, restart counter 0, `PV acquisition, storage and retrieval: PASS` with 4 stored samples (latest 2026-10-28T09:00:58Z), no soft IOC left. Rocky Linux 8.10: installer exit 0 in 9 min (09:07:05Z to 09:16:08Z), the same checks, 4 stored samples (latest 2026-10-28T09:16:07Z), no AVC denial. Each guest had 17 GiB available before the clone and the filesystem was 24 to 25 percent used after the installation; the storage preflight of the release procedure was not run before the clones. The logs of the guests are not retained. |
| Release Verification 7 | Not run | Planned environment above | Pending | none |

Current-candidate checks below were executed before commit on the working-tree files subsequently committed as `48724a2`; retained logs were inspected on 2026-10-09. They supplement the final checks and do not complete Release Verification 2 or Release Verification 3.

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| Release Verification 2, local suite only | 2026-10-09 00:54 PDT | Local Debian 13; candidate files subsequently committed as `48724a2`, source pin `162269e7` | Partial; complete integrated check Pending | Shipped `tests/run-all-tests.bash --local` exits 0: Phase 1 238/0, health 23, starting health 32/0, no-Ant 22/0, database configuration 17, VM-driver local tests 36, Phase 2 build wrapper 13/0. Readiness output checks and all three installers' EPICS preparation rejection checks pass. Real Base binary resolution is SKIP because `AA_TEST_EPICS_BIN` is unset; no real IOC round trip is established by this suite. Phase 2 checks the build command, not a real Maven build. Evidence: `commit-local-install-local-tests.log`, SHA256 `ce0b7a209f2bf393227fbff7c5bd6bbb0a4fc7533fbf1b330ca0dbdc2af47da8`. Full real database integration, site-overlay build, payload and rejection checks remain Pending for this candidate. |
| Release Verification 2, native readiness only | 2026-10-09 00:46 PDT | Local Debian 13, JDK 21, Tomcat 9.0.121, four real source `162269e7` WARs; isolated appliance using the candidate readiness functions and launcher | Pass for readiness path; host installation and Release Verification 3 Pending | Shipped `tests/local-install-readiness.bash` records successful four-JVM identity, real filesystem health, four startup APIs, UI and appliance information. It also passes inactive/failed/denied/missing unit diagnostics, early signal termination versus timeout, health recovery and retained observations, real storage-threshold failure, and missing-PID failure. Only privilege and systemd command boundaries are replaced; HTTP, JVM identity and filesystem inspection use the real appliance. Retained readiness functions match the shipped functions, and the launcher copy matches the shipped file. This does not verify package installation, host service/timer operation, PV acquisition or stored samples. Evidence: `review-second-readiness.PuLlWmiL.log`, SHA256 `57e537b916236ebf2f6f253cb435411ff3dbc929c569eb9c0333e7ac757d0dcf`; workspace `local-readiness.NEtllYVI`, including `pass.log`, SHA256 `430731e97227117b973c2b59b6cb719d0b60a2e8edd1f3a2161bf83d4d6e2772`, `storage-failure.log`, SHA256 `f5f589a753ccf65c608302dded8820ece4827edc9ce250e2ac5ead5c38e36048`, and `process-failure.log`, SHA256 `f29f7f802fbf26069c4274390139463db0ce250c241eec7aede9f1dd825fb658`. |
| Release Verification 3, eight-case VM run before the final pin | 2026-10-12 12:41 to 15:40 PDT | Local libvirt host; fresh Debian 13 and Rocky 8.10 guests created after the recorded baseline; epicsarchiverap-env `bbad185366f71d9db66e7e70971dbd381b8d93d4`, source `84ae8a83426d6313397067b26a8ffc9207e577ff`, cloud-provision `05cf57398d09882f628d7356316f31576ca840c6`, ansible-provision `54f28cefb20e2d65779bbd5b614c1ccaf90efaaf`; images Debian 13 SHA-256 `383dbfed19d9c20618beb0068cebeebc36c253a48908265387a2a5c2c619e1d7`, Rocky 8 `e56066c58606191e96184de9a9183a3af33c59bcbd8740d8b10ca054a7a89c14` | Pass for this environment and source; Release Verification 3 at the final pin Pending | Shipped `tests/run-all-tests.bash`: `--init` (local suite Pass at the environment ref), one `--case` per guest, `--verify-cleanup` and `--verdict`. Eight cases verified: `debian13-socket`, `debian13-tcp`, `rocky8-socket`, `rocky8-tcp` (T3 to T12), `debian13-sqlite`, `rocky8-sqlite` (T3 to T13), `debian13-build-failure`, `rocky8-build-failure` (T3 and T14). Each guest was created fresh after the baseline and stayed owned and present until the run ended. The eight owned guests were then removed on the decision of the provisioner's owner; the baseline of 20 domains, which includes two earlier test guests, kept its identity. `--verify-cleanup` and `--verdict` exit 0. The local suite skips the real EPICS Base binary resolution check because `AA_TEST_EPICS_BIN` is unset, which the driver's completeness check accepts. Retained private record: run SHA-256 `922ca36b4ae599e27597de3ffdbe04e6e7e462ef4287d78b33396c30444d6cc1`, cleanup SHA-256 `0f7c6f21f525251ec91372d91f24bcd8e8b3495842fac2fc4b4835798a1c90d3` |
| Release Verification 2, local suite at the latest source | 2026-10-12 19:57 PDT | Local Debian 13; env working tree later committed as `0c511ae`, source `514be155`, real EPICS Base 7.0.10 of the release 1.3.0 distribution tree for Debian 13 | Pass for the local suite; complete integrated check Pending, no source pin | Shipped `tests/run-all-tests.bash --local` with `AA_TEST_EPICS_BIN` set exits 0: Phase 1 273/0, starting health 32/0, no-Ant 22/0, interface files 272/0 (the faint-color rejection included), EPICS preflight resolves the real binaries, Phase 2 build wrapper 14/0 |
| Release Verification 2, build and pages with the source stylesheet | 2026-10-12 19:54 PDT | Local Debian 13; scratch copy of env `adf7eb6` with the slim site folder, source `514be155`, site id `als` | Pass for the build and the pages; menu opening and the VM guest verifier Pending | `make conf.archapplproperties build.mvn` BUILD SUCCESS in 23 s with no warning; `ui/comm/css/main.css` of the mgmt WAR equals the source default byte for byte; `ui/index.html` carries one `pageheader`, the `site_logo` block and the toggle markup; rendered at 1100, 721, 720, 400, 380, 360 and 320 px: header logo 340x44 and 232x30 at 720 px and below, wordmark below 360 px, site logo 144x44, 98x30 and 79x24 at 380 px and below, menu folded behind the Menu button at 720 px and below, no sideways scroll. The render removed the content security meta so the stylesheet loads from a file URL |
| Release Verification 3, one case on the slim site folder | 2026-10-13 00:15 to 00:35 PDT | Local libvirt host; one fresh Debian 13 guest created after the recorded baseline; env `c4beb5d`, source `514be155`, case `debian13-sqlite` | Pass for this case; not an acceptance run, one case of eight | Shipped `tests/run-all-tests.bash --init` (local suite Pass with the real Base) and `--case debian13-sqlite`: T3 to T13 all Pass, which includes the installed WAR and template comparison against the slim site folder (only `img/LBNLLogo.png`, `img/als.ico` and the `site_logo` block), four JVMs, health timer, HTTP identity, acquisition and retrieval, restart and reinstall, and the negative checks. The guest stays retained; its removal is the provisioner owner's decision |
| Release Verification 2, local suite and pages at the source of 2026-10-13 | 2026-10-13 01:14 PDT | Local Debian 13; env `3b1c430` (working tree at the run, the same files), source `93605afa`, real EPICS Base 7.0.10 of the release 1.3.0 distribution tree for Debian 13; scratch copy of env with the slim site folder for the build | Pass for the local suite, the build and the pages; menu opening, the new pages with scripts and the VM guest verifier Pending | `--local` with `AA_TEST_EPICS_BIN` set exits 0: Phase 1 273/0, starting health 32/0, no-Ant 22/0, interface files 302/0 (an outside script and an outside stylesheet are refused, a navigation link is accepted), EPICS preflight resolves the real binaries, build wrapper 14/0. Build with `make conf.archapplproperties build.mvn` succeeds in 23 s without a warning; `ui/comm/css/main.css` equals the source default byte for byte; `index`, `system`, `help` and `external` carry one `pageheader`, the `site_logo` block and the toggle markup; rendered at 1100, 720, 360 and 320 px: header logo 340x44 and 232x30 at 720 px and below, wordmark below 360 px, site logo 144x44, 98x30 and 79x24 at 380 px and below, Menu button at 720 px and below, body font 16 px, no sideways scroll. The render removed the content security meta so the stylesheet loads from a file URL |
| Release Verification 2, menu and pages in a browser with the scripts at the source of 2026-10-13 | 2026-10-13 01:33 PDT | Local Debian 13; an isolated appliance of four WARs built from source `93605afa` with the slim site folder of `0c511ae`, Tomcat 9.0.121, Firefox with a 600 px window and the content security policy kept | Pass for the menu and the page loads; actions of the External servers tab and a screen reader Pending | The Menu button shows and the menu is folded at 600 px; one click opens it as one column of five entries (Archive PVs, Browse PVs, System, Help, Analyzer) with the current entry marked and `aria-expanded` true on the toggle input; a second click folds it. `help.html`, `external.html` and `system.html` load with one `pageheader`, the current entry marked (Help, System, System) and their scripts run (a table and buttons on the External servers page, a table and nine buttons on System). The appliance was empty and was stopped cleanly afterwards |
| Release Verification 2, External servers, touch, keyboard and accessibility tree at the source of 2026-10-13 | 2026-10-13 01:44 to 01:49 PDT | Local Debian 13; an isolated appliance of four WARs built from source `93605afa` with the slim site folder of `0c511ae`, Tomcat 9.0.121, Firefox through Marionette with a 600 px window and the content security policy kept | Pass for these checks; a real screen reader and touch hardware Pending | External servers: the empty list text; the add dialog opens and cancels; an unreachable address shows the validation error in the dialog; the address of the form the hint names (host, port, `/retrieval`) is added, listed with the index `pbraw`, shown in the remove dialog and removed, and the list is empty after a reload; an address of the data endpoint form is refused with a text that names the ping URL (400). Menu: one touch tap (pointer type touch) opens and a second folds it; with the toggle focused Space opens and folds it, Escape does not fold it; a touch on the System entry navigates to `system.html`; the accessibility tree of Firefox reports the toggle as role `checkbox` named `Menu` and the current entry as role `link` with `aria-current="page"`; `aria-expanded` and `aria-controls` sit on the toggle input. Method: W3C actions and computed role and label over Marionette, as the source repository's session described it. The appliance was empty and was stopped cleanly |
| Release Verification 2, local suite, build and a screen reader at the source of 2026-10-13 | 2026-10-13 02:00 to 02:22 PDT | Local Debian 13; env `6fb9e4c`, source `fdd3ba66`, real EPICS Base 7.0.10 of the release 1.3.0 distribution tree for Debian 13; scratch copy of env with the slim site folder for the build; an isolated appliance of four WARs of that build, Tomcat 9.0.121, Firefox with a 600 px window and the content security policy kept, Orca 48.1 in a private session | Pass for the local suite, the build and the checks below; real speech audio, other screen readers, touch hardware and the VM guest verifier Pending | `--local` with `AA_TEST_EPICS_BIN` set exits 0: Phase 1 273/0, starting health 32/0, no-Ant 22/0, interface files 302/0, EPICS preflight resolves the real binaries, build wrapper 14/0. The build succeeds in 24 s with no warning. Orca, with its speech taken from its debug log (speech-dispatcher dummy module, no audio heard): the toggle is spoken as a check box named Menu, not checked, then checked after Space; the five entries are spoken as links in order; Escape folds the menu and focus stays on the toggle; on External servers the Add button is spoken, Enter moves focus to the address field (required, invalid), the full refusal text for an unreachable address is spoken including the sentence that names the `data_retrieval_url`, and Escape closes the dialog with focus back on the Add button; the Help page Tab order is the logo, the toggle and the page links in reading order; on System the four buttons are named `About <title>`, Space sets `aria-expanded` true and opens the card dialog named by its title, and Escape returns focus to the button. Gaps seen: the list of entries and the add dialog have no accessible name, and the current entry is not spoken although the tree marks it `aria-current="page"`. The appliance was empty and was stopped cleanly |
| Release Verification 2, local suite, build and a screen reader at the source of 2026-10-13 after the naming fixes | 2026-10-13 08:38 to 08:49 PDT | Local Debian 13; env `148cae1` plus the file list line of the new treemap script, source `7e9e2253`, real EPICS Base 7.0.10 of the release 1.3.0 distribution tree for Debian 13; scratch copy of env with the slim site folder for the build; an isolated appliance of four WARs of that build, Tomcat 9.0.121, Firefox with a 600 px window and the content security policy kept, Orca 48.1 in a private session | Pass for the local suite, the build and the checks below; real speech audio, other screen readers, touch hardware and the VM guest verifier Pending | `--local` with `AA_TEST_EPICS_BIN` set exits 0: Phase 1 273/0, starting health 32/0, no-Ant 22/0, interface files 305/0, EPICS preflight resolves the real binaries, build wrapper 14/0. The build succeeds in 27 s. Orca with the same method as the row above: the menu keys, the External servers dialog and the System buttons behave and are spoken as before. The add dialog is named `Add an external archiver server` in the tree and the entry list sits in a landmark named `Main menu`. Orca did not speak the landmark name when focus entered the menu, and it did not speak the current entry; the tree marks it `aria-current="page"`. The appliance was empty and was stopped cleanly |
| Release Verification 2, local suite, build and the Browse PVs steps at the source of 2026-10-14 | 2026-10-14 11:20 to 11:55 PDT | Local Debian 13; env `777d17a` plus the interface file list and check for the new Archive PVs page and the renamed Browse PVs files, source `65245250`, real EPICS Base 7.0.10 of the release 1.3.0 distribution tree for Debian 13; Firefox through Marionette with a 1360 px window; soft IOC of one calculated PV | Pass for the local suite, the build and the steps below; screen reader check at this source, other browsers, touch and the VM guest verifier Pending | `--local` with `AA_TEST_EPICS_BIN` set exits 0: Phase 1 273/0, starting health 32/0, no-Ant 22/0, interface files 332/0 (the Archive PVs page has no inline script, event handler or style and carries a content security policy; the script and page id pair is checked), EPICS preflight resolves the real binaries, build wrapper 14/0. The env build succeeds in 25 s and the management WAR holds `archive.html`, `js/archive.js`, `css/archive.css` and `js/browse.js` with the site logo block. On a real appliance of four WARs built by the source itself: the page `index.html` is titled Browse PVs, finds the PV, selects it and offers Pause, Change sampling, Stop archiving and Open in the viewer; Pause shows the state `Paused` with the button Resume and Resume returns the PV to sampling; the link `Archive PVs…` points to `archive.html`; `archive.html` shows Add PVs with the names field, the Sampling choice (method, period, policy, controlling PV), Archive and Clear, and the table of the visit with Pause, Resume, Stop archiving and Cancel requests. Observed on the way: the dev launcher takes `policies.py` from the management WAR, and a WAR built by the env site build carries the storage paths of the site (`/arch/...`), so such WARs under the launcher point the stores at the host's storage; the write was refused by permissions and the PV stayed unpaused until WARs of the source's own build were used |
| Release Verification 3, four MariaDB cases at the source of 2026-10-16 | 2026-10-16 13:44 to 2026-10-16 18:09 PDT | Local libvirt host; one fresh guest for each case created after the recorded baseline (Debian 13 and Rocky 8.10, 2 vCPU, 4 GiB, 20 GiB); epicsarchiverap-env `9b7851c` for three cases and `54dc6b5` for the fourth, source `3de600d93938e88fa9642269c1db0b9c4c9cda9f`, cloud-provision `05cf57398d09882f628d7356316f31576ca840c6`, ansible-provision `54f28cefb20e2d65779bbd5b614c1ccaf90efaaf`; images as in the eight-case run | Pass for the four cases; not an acceptance run (no verdict; the SQLite and build-failure cases were not repeated) | Shipped `tests/run-all-tests.bash` with `--init` (local suite Pass) and one `--case` each. `debian13-socket`, `debian13-tcp` and `rocky8-socket`: T3 to T12 Pass at `9b7851c`. `rocky8-tcp`: the first attempt at `9b7851c` passed T3 to T10 and failed at T11 in the guest verifier, because the readiness poll after the appliance restart did not retry a stalled HTTP read, which raises `socket.timeout` on the Python 3.6 of Rocky 8 and is not a `TimeoutError` before Python 3.10 (cause inferred from the code and the failure category); `54dc6b5` makes the HTTP helper raise `TimeoutError` for it, and the rerun on a new fresh guest in a new run passed T3 to T12 (restart 46 s). The failed attempt stays in its run record. New checks of `9b7851c` (the `WEB-INF/lib` of each WAR and of each installed tree holds exactly the drivers `org.mariadb.jdbc.Driver` and `org.sqlite.JDBC`, each from one JAR and no other driver-like JAR; the MariaDB driver version read from the installed JAR equals its file name and the source `pom.xml`): in all four cases, after the installation and after the forced reinstall, each of the four WARs lists 43 JARs and the driver 3.5.10. Real WARs of a source build also pass, and a mutated copy (another driver JAR, two MariaDB JARs, a missing driver, another pom version) is refused. The retained guests are shut off and kept; removal is the provisioner owner's decision. The results were reported to the session of the source repository for its issue about the driver |
| Release Verification 2, local suite at the tag 2026-10 | 2026-10-27 01:59 to 02:01 PDT | Local Debian 13; env working tree later committed as `4278a4d` and `4123b2c`, source tag `2026-10` (`e0a8e66e`), real EPICS Base 7.0.10 of the release 1.3.0 distribution tree for Debian 13, `EXPECTED_BRANCH=release-2.0.1` | Pass for the local suite; complete integrated check Pending | Shipped `tests/run-all-tests.bash --local` exits 0: Phase 1 315/0, Phase 2 14/0, no FAIL, SKIP or WARN line |
| Release Verification 2, real build and site build.xml rejection at the tag 2026-10 | 2026-10-28T07:18Z to 07:19Z (2026-10-28 00:18 to 00:19 PDT) | Local Debian 13, JDK 21.0.12.1, Maven 3.9.16 of the wrapper; scratch clone of epicsarchiverap-env `cb49f3b536f7e5532f19c82a62a657ae3ee2c351`, source tag `2026-10` (`e0a8e66e`), site id `als` | Pass for the build and the rejection: `make build.mvn` ends with BUILD SUCCESS in 24.1 s with 0 warning lines; with a `build.xml` in the site folder the same target exits nonzero and the producing repository reports `A site build.xml is no longer run.`; M45 / T2 and M46 / T3 need the VM verifier and are not run (D70) | SHA-256 of the four WARs, named `aa-20261028-e0a8e66e-<component>.war`: engine `7cb01e68277934d64a2f773c2920e19bb9c94d618196148e2aa3329c835ff94e`, etl `14ab32385b65c0f02f05155d1852bda9d10ff4552711836c6d7a6da77855a064`, mgmt `2cacf79336cce9a7bd1b8735affb3ddac850f31ae73da6646fdd754521d0d05e`, retrieval `c53da3b9eafff2b93c0397a4c4e5141436b7b4da993653a22fa4beb639fbca04` |
| Release Verification 2, database integration test at the tag 2026-10 | 2026-10-28T07:47Z to 07:48Z (2026-10-28 00:47 PDT) | Local Debian 13; scratch clone of epicsarchiverap-env `5c51bc359bf828039b3e19f14e2e996a01785c5c`, source tag `2026-10` (`e0a8e66e`); the test starts its own `mariadbd` in a temporary data directory on a free port and a temporary socket | Pass: `python3 tests/database-config.py --integration` runs 2 tests in 9.5 s and ends OK; it reports that the socket and TCP account, query, schema, backup and restore paths passed and that unrelated administrative accounts are preserved | Output of the command; the MariaDB of the appliance on port 3306 is not used |
| Install and run check, 903-PV day run at the tag 2026-10 | 2026-10-26T17:02Z to 2026-10-27T17:30Z | Local Debian 13; appliance installed by `scripts/install-local-sqlite.bash` of env `222f8b5` at source `e0a8e66e`, 903 PVs of a soft IOC | Pass for C1 to C6, C8 and C9; C7 observed values only; accepted by the owner | `docs/reports/soak-903pv-20261026.md` at `587df6e`; decision D11 in `docs/milestone-bfb0dc71.md` of epicsarchiverap-maven at `0c103015` |
| Source CI at the tag 2026-10 | 2026-10-28T03:28Z (2026-10-27 20:28 PDT) | GitHub Actions of `jeonghanlee/epicsarchiverap-maven`; commit `e0a8e66ed09e840ab8ed67dae81b25474605db08` | Pass: workflow Maven, run 199 on `master` (2026-10-26T15:14:11Z to 15:31:45Z) and run 200 on the tag branch `2026-10` (15:59:13Z to 16:16:16Z), both `success` | Read with `gh run list -R jeonghanlee/epicsarchiverap-maven --commit e0a8e66ed09e840ab8ed67dae81b25474605db08` |
| Release Verification 3, clean installs at the tag 2026-10 | 2026-10-28T00:43Z to 03:28Z (2026-10-27 17:43 to 20:28 PDT) | Local libvirt host; eight fresh guests (Debian 13 and Rocky 8.10, 2 vCPU, 4 GiB, 20 GiB), epicsarchiverap-env `3185bb05b7131540ec8887f9462eb3124406f6a0`, source tag `2026-10` (`e0a8e66e`), guests created by the cloud-provision session; two guests built from the golden images with EPICS Base 7.0.10 | Pass for six clean installations (installer exit 0, health exit 0, four `startupState` values `STARTUP_COMPLETE`, version `e0a8e66e`, restart counter 0) and for the soft IOC check on Debian 13 and Rocky 8.10 (`PV acquisition, storage and retrieval: PASS`, three stored samples each); the failure path stops in `source selection`; accepted by the owner as Release Verification 3 (D68) | `docs/reports/clean-install-20261028.md` |

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Runtime | M41 | Measure per-component heap needs by archiving load | Carry-forward | Deferred | No | D31, D35, D36, D37 | Event-based GC observations justify the documented heap guidance; deferred 2026-10-01 until a sufficient dedicated test disk is available; [detail](#m41---measure-per-component-heap-needs-by-archiving-load) |
| DB | M42 | Apply backend selection to all database operations | Carry-forward | Deferred | No | M43, D29, D31 | Every generic DB operation uses the selected backend; unsupported operations fail before contacting another backend; deferred 2026-09-28; [detail](#m42---apply-backend-selection-to-all-database-operations) |
| Storage | M27 | LTS retrieval pre-processing (`pp`) | Milestone | Open | No | D21 | Decide from operating experience whether `pp` on LTS earns its disk cost; [detail](#m27---lts-retrieval-pre-processing-pp) |
| Tests | M47 | Replace the Python tests with Bash tests | Carry-forward | Open | No | D41 | Every test of shell code and every driver check runs as Bash under `tests/`; only a test of Python code stays Python; [detail](#m47---replace-the-python-tests-with-bash-tests) |
| Install | M49 | The operating system target rewrites `configure/CONFIG_SITE.local` and the installers run it first | Milestone | Deferred | No | D55 | A value that an operator wrote into `configure/CONFIG_SITE.local` survives the installers, or the installers refuse and say where site values go; the owner chose the stop in D55 and scheduled it for the release after 2.0.1; [detail](#m49---the-operating-system-target-rewrites-configureconfig_sitelocal-and-the-installers-run-it-first) |
| Tests | M61 | Fix the findings of the review of the VM driver | Carry-forward | Deferred | No | D67 | The Must-Fix finding and the Minor findings of the 2026-10-27 review of `tests/vm` are fixed or decided, and the check `build_proof` agrees with the installers; deferred 2026-10-27 under D67; [detail](#m61---fix-the-findings-of-the-review-of-the-vm-driver) |

### Backlog Details

#### M41 - Measure per-component heap needs by archiving load

Origin: 265f580 / M41
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved; moved from Milestone to Backlog on 2026-10-01 under D37
GitHub Issue: [#53](https://github.com/jeonghanlee/epicsarchiverap-env/issues/53)
Status: Deferred

##### Summary

The 256M heap default ([M22 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md)) is a test default; the available measurements
do not establish a heap recommendation by load. The ansible-provision soak
on epicsarchiverap-env `9eed006`, epicsarchiverap-maven `3c96141d` and Ansible `dca2255` covers 100,
500 and 903 PV stages. The 903 PV stage includes 110 PVs at 10 Hz and eight
waveforms. With `-Xms256M -Xmx256M` on every JVM, the largest sampled ETL
heap was 250.9 MiB. Its ten Full GCs cover the combined interval from the
500 PV stage through the run's end, including fault tests; one occurred
in the 500 PV stage. The other three components had no Full GC in that
interval.

The [heap observation report](reports/heap-soak-20260928.md), committed at
`decff38`, records the supplied figures and their limits. Five-minute
samples do not provide immediate post-GC heap or individual GC pauses,
so this evidence does not meet this work item's completion criteria.
The heap needed may depend on different workloads per component (PV count
and rate for engine, partition size for etl, query span for retrieval);
that relationship remains a hypothesis until measured.

##### Scope

- Measure post-GC heap, event counts, individual pauses and RSS for mgmt, engine, etl and retrieval under the existing 100, 500 and 903 PV workloads. Recover the original IOC definitions, PV list and query selection before execution; the summary counts alone cannot reproduce MONITOR/SCAN settings, deadbands or waveform values.
- Capture G1 unified GC logs from JVM startup through every stage. Keep Young, Mixed and Full collections separate. Post-Young-GC heap is an observed occupancy, not proof of the complete live set; do not combine different collection types into one sizing value. Periodic `jstat` and process sampling supplement the event record.
- Derive a candidate heap and validate it against the same workloads before adding guidance beside the four-instance memory calculation in `docs/README.install.md`. State its measured configuration and limits. A multiplier alone does not establish a safe setting.

Out of scope: changing the shipped default ([M22 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md)); per-instance heap
variables, unless the measurements show one shared value cannot fit; GC
tuning beyond sizing; production storage sizing.

##### Completion Criteria

- A recorded table of the after-GC heap, GC counts and pause times per
  instance for each load in the matrix, with the epicsarchiverap-env and epicsarchiverap-maven refs and
  the measurement method used.
- Raw GC logs, workload definitions, stage boundaries, process samples, retrieval responses and ETL observations reproduce the table; missing measurements remain explicit.
- The install guide gives heap guidance supported by both the measurement table and a repeat of the relevant workloads at the proposed setting. Inconclusive data keeps this work unfinished and does not produce a numeric recommendation.

##### Dependencies And Decisions

- D31, Decision Date: 2026-09-29. Assigned to 2.0.1; assignment alone did not accept the detailed plan or authorize implementation. Earlier assignment decisions below retain their original dates.
- D35, Decision Date: 2026-10-01. The owner selected the existing three workloads rather than a larger PV/rate matrix. The accepted run schedule below preserves the reported observation durations; plan acceptance and separate implementation authorization are recorded below.
- D36, Decision Date: 2026-10-01. Implementation and measurement are deferred. The accepted plan, recovered source evidence and local preparation tool are preserved. No VM measurement started, and T1-T5 remain Pending. A new dated decision is required to resume; the earlier implementation authorization does not permit continued work during this deferral. Release assignment and M44 dependencies are unchanged.
- D37, Decision Date: 2026-10-01. Move this work to Backlog and exclude it from the 2.0.1 completion requirements. Resume only by a new dated assignment decision in an environment where the test can use sufficient dedicated disk capacity to retain archive data, complete retrieval responses and GC/collection evidence for the accepted schedule, including orderly-shutdown reserves. Confirm actual usable capacity and filesystem/inode limits before resource-limit acceptance. Existing stop thresholds remain applicable; this condition does not authorize filling a filesystem to exhaustion. The accepted full measurement plan is preserved; no reduced-load replacement experiment is assigned.

- Recorded 2026-09-28 from the owner's direction after the [M22 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md) review of the
  `9eed006` soak figures; not assigned to current work.
- Additional post-GC heap and individual GC pause measurements were requested
  from the Ansible operator on 2026-09-28. Results have not been received;
  no new measurement run is verified here. This historical request remained separate
  from [M8 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md)'s release criteria.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-01; Implementation Plan and Test Plan accepted. Run-specific resource limits and analysis settings retain their stated acceptance requirements.
Implementation Authorization: 2026-10-01; implement the accepted plan. Original-input verification and the stated run-specific acceptance requirements remain prerequisites for the corresponding measurement stages.
Superseded Plan Artifacts: original draft at epicsarchiverap-env d68f66848e1edc174e76fe77326e941baf58f850, docs/milestone-265f580.md, M41

1. Recover the operator's original PV CSV, IOC definitions, installed store policy/properties and retrieval request selection. Record their hashes and verify each stage's total, periods, waveform type/length, MONITOR/SCAN settings and deadbands. Recover the complete per-PV store URLs, partition granularities, STS/MTS hold values, ETL scheduling settings and any post-processing. Missing inputs stop workload acceptance; do not manufacture a replacement from the summary table.
2. Record immutable environment, Maven, Ansible and cloud-provision refs and the installed Java, database and EPICS versions. Use a disposable Rocky 8.10 VM with the reported topology: 2 vCPU, 4 GiB assigned RAM, no swap, MariaDB and IOC on the same VM. Record actual guest RAM and disk capacity. Preflight archive/log space and host memory; retain evidence and stop if either cannot support the run.
3. Install through the shipped Ansible/Make/service path. Start with all four JVMs at `-Xms256M -Xmx256M -XX:MaxMetaspaceSize=256M` and G1. Render `ARCHAPPL_STS_GRANULARITY`, `ARCHAPPL_STS_HOLD`, `ARCHAPPL_MTS_GRANULARITY`, `ARCHAPPL_MTS_HOLD` and `ARCHAPPL_LTS_GRANULARITY` from the recovered policy, preserving the corresponding ETL schedule and post-processing. The reported STS 5 minutes, MTS 1 hour and LTS 1 day alone do not determine exact handoff times. Do not inherit the default hold values of 2 without confirming the original values. Read back the installed policy and each archived PV's effective stores. Historical results are a comparison reference, not validation of the new source revisions.
4. Supply test-only logging through `AA_JAVA_OPTS` in `CONFIG_SITE.local`, rendered by `configure/RULES_PROPERTIES` into `archappl.conf` and exported by `scripts/archappl.bash`. Log `gc*` and `safepoint` events with UTC time, uptime, level and tags. Use a private run directory and distinct PID/startup-time filenames; disable rotation for this bounded run and monitor disk usage. Verify the effective options and writable log output of all four real JVMs. Do not change shipped defaults or enable asynchronous logging that could discard events.
5. Begin the baseline on a newly provisioned VM with an empty test database and archive. Verify that no earlier registered PVs or store files exist. Execute all three stages below in order on that appliance to preserve the defined accumulated history. Record UTC and monotonic stage boundaries and the point at which newly registered PVs actually archive. Each duration starts after stage readiness. Record preparation time separately; planned observation time totals 57 hours before any validation repeat.
6. Sample per-component RSS, CPU, process identity, host memory and filesystem usage every 5 seconds. Collect GC events continuously and retain actual HTTP requests/responses and durations using the bounded collection and stop rules below. Record actual CA/sample rates and individual ETL pass/store-transition observations. Archive the complete evidence before any VM cleanup; cleanup requires separate owner direction.
7. Produce tables by component, load, GC type and query interval. Report event count, post-GC heap distribution, maximum and p99 individual pause, Full GC count, RSS distribution and concurrent total RSS from matching timestamps. Separate GC pause durations from concurrent phases and safepoints; never use cumulative GCT or ETL metrics as individual-event durations. A zero-event class has count zero and no pause percentile; no observed old-generation reclamation is a sizing limitation, not a reason to force a GC.
8. From valid observations, derive a candidate shared heap and explain the margin, measured post-GC occupancy trend and host memory budget. Repeat the complete 100/500/903 PV sequence, 24/6/27-hour durations and final six-hour query interval on a separate newly provisioned VM with an empty test database and archive. Freeze identical source refs, workload hashes, database version, JVM non-heap options, store/ETL settings, VM resources, collector limits and client placement; change only the candidate heap. Record the initial empty-state checks for both runs and preserve the first VM and its evidence. A complete baseline plus one complete candidate repeat requires 114 observation hours, excluding provisioning and preflight. A reduced rerun requires a separate scope decision and cannot establish the original three-stage recommendation. An OOM, unexpected restart, incomplete logs, unvalidated query payload or continuing post-GC growth prevents a sizing conclusion. Record failed or inconclusive workloads rather than changing heap or resources silently. Per-component settings and further GC tuning require a separate decision.
9. Update `docs/README.install.md` only with the validated setting, applicability and limits. Keep the existing observation report unchanged; add the new run's evidence and actual results here. Project the accepted plan/results to #53 under separate issue authority.

###### Workload And Observation Schedule

| Stage | Registered PVs at 1 s / 0.1 s / 10 s | Waveforms included in total | Observation | Concurrent retrieval |
| --- | --- | --- | --- | --- |
| 100 PV | 80 / 10 / 10 | 5 x 1,000 doubles, 1 s | 24 hours | none |
| 500 PV | 480 / 10 / 10 | 5 x 1,000 doubles, 1 s | 6 hours | none |
| 903 PV | 783 / 110 / 10 | 8 x 1,000 doubles, 1 s | 27 hours | final 6 hours |

The 903 PV query interval uses four clients, a two-second wait between requests and one-hour or one-day ranges selected from the recovered original workload. Record the range mix and selected PVs. Keep client resource usage separate from appliance RSS and collect kernel OOM evidence. HTTP 200 alone is insufficient: verify decoded data, timestamps and values against actual IOC observations and retained history. The reproduced live upper-bound defect in jeonghanlee/epicsarchiverap-maven#21 must not be hidden by weakening query validation; any affected query interval remains invalid until verified with a corrected published source.

Registration periods are workload inputs. Record actual archived rates; do not equate configured periods with delivered rates. Require observed complete STS-to-MTS and MTS-to-LTS transitions for each stage's data. If the planned duration lacks the required evidence, report the stage as insufficient and obtain direction before extending it.

###### Bounded Collection And Stop Rules

After detailed plan acceptance and implementation authorization, name the sampler, CA observer, query clients and GC analysis tools. Before any preflight workload or history collection starts, record and obtain acceptance of a provisional resource-limit set: client placement, each collector/client's numeric `MemoryMax`, minimum host `MemAvailable`, minimum free space/inodes and a maximum preflight duration. Reserve memory for the OS, MariaDB, IOC and four JVMs before allocating collector budgets. Use actual guest capacity and conservative estimates of archive, response and GC-log growth plus an orderly-shutdown allowance to set the initial disk reserve; this first limit set does not depend on measurements from the preflight it protects. Missing values, an infeasible budget or a duration insufficient for the required history prevents preflight from starting. Enforce these provisional limits throughout history preparation and concurrent queries.

Conduct the separate preflight with the original IOC waveform definitions and longest original query selection. Measure simultaneous resource use and write rates within the provisional limits, then propose the final resource-limit set for the long observation runs, retaining the provisional values, measurements and reasons for each change. Obtain acceptance of the final numeric limits before the 57-hour baseline starts; missing values, failed or incomplete preflight evidence or a budget that exceeds available RAM prevents that run from starting. Identify both limit sets and their acceptance times in the run description. Use the final limits unchanged in the baseline and candidate repeat. The preflight has its own evidence and must not populate the baseline database/archive. Reaching a provisional limit invokes the same stop and evidence-preservation rules; do not relax it or continue under the same run identity. Any revised preflight limits require separate acceptance and a new preflight run identity.

Prepare the retrieval preflight on a separate disposable VM through the same real installation, IOC, CA acquisition, archive and ETL paths. Use the recovered 903 PV workload and store policy. Collect actual history covering the longest original query range for every PV selected by those requests, including any selected waveforms; a one-day range requires at least one day of real collection plus readiness and store-transition preparation. Do not substitute generated archive files, fabricated timestamps or empty responses. Retain CA observations and store evidence, then verify response timestamps, sample counts, values, waveform lengths and response bytes against that history and the recovered post-processing rules. Run all four clients concurrently with the original range mix and waits while the other collectors operate. An incomplete history, unexpectedly sparse response or invalid payload makes the resource preflight insufficient. Record collection time, complete request/response volumes, simultaneous memory peaks and disk write rates separately from the 57-hour baseline and 57-hour candidate observations; the 114-hour total excludes this additional preparation. Apply the bounded collection and stop rules during preflight as well.

Write process samples and CA events incrementally to append-only files. Stream each HTTP response to disk and decode it incrementally; retain only the current parsing state and bounded timestamp/value comparison buffers. Analyze long GC logs and compute statistics from disk. Do not accumulate all CA events or a full day of waveform responses in memory. Each collector/client must run in an identified cgroup with the applicable accepted `MemoryMax`: provisional during preflight, final during baseline and candidate observations. Monitor memory usage and cgroup limit/OOM events alongside appliance resources. A collector reaching its limit is a measurement failure, not evidence that the appliance heap is too small.

Stop owned IOC/query workload producers, end the observation interval, flush collection evidence and stop the appliance through its shipped service on the first resource or collection failure: memory at the applicable recorded collector limit, a new cgroup max/OOM event, host `MemAvailable` below the applicable accepted minimum, disk usage at or above the installed `ARCHAPPL_STORAGE_ALARM_PERCENT` (default 85), free space/inodes below the applicable recorded minimum, expiration of the provisional preflight duration, write failure, lost collector, missing observation interval, unexpected JVM restart or any JVM/client/kernel OOM. Monitor every filesystem holding archive, GC logs or collected responses. The provisional free-space reserve uses the accepted conservative estimates and shutdown allowance; the final reserve must cover the measured write rate through orderly shutdown. A 5-second check is not a hard disk cap. Preserve the VM and classify the affected interval as failed or incomplete. Do not delete archive files, extend capacity or continue with reduced collection under the same run identity.

###### Evidence And Analysis Contract

Retain one run description with source refs, workload hashes, actual JVM flags, installed policy, guest resources and start/end times. Preserve per-JVM GC logs with process identity, a process/host sample CSV, stage boundary CSV, retrieval request/response records and ETL observations. Identify every parsed GC event by JVM identity and GC ID; pair each completed pause with its own before/after heap values and event type. Calculate p99 with a documented method and report the contributing count and log-reported heap precision. Do not interpolate a periodic heap sample into a missing event measurement.

Warm-up and query intervals remain separately identifiable in the raw record. Analyze steady operation and transitions separately. Distinguish an observed JVM OOM from a client or host OOM, and report both. Hash the retained raw files and show which files and timestamps produce each result; keep private runtime identifiers out of public guidance.

Before the baseline begins, record and obtain acceptance of the analysis settings: warm-up duration after each stage's readiness and after concurrent retrieval begins, comparison interval boundaries, required GC types per component, minimum event counts, heap-change tolerance in MiB and growth-rate tolerance in MiB/hour. Derive the proposed tolerances from log precision and preflight variability, with their rationale; do not choose them from the completed baseline or candidate results. Use the same accepted settings for both runs. Missing settings prevent either long run from starting.

Evaluate each component and GC type separately within a constant workload and query condition. Exclude only the previously specified warm-up intervals from trend calculations and retain their raw events. Divide each remaining comparison interval into four equal-duration bins. Report event counts and median post-GC heap for every bin, the ordinary least-squares slope of those four medians at their bin midpoints, and the last-bin minus first-bin median. Continuing growth is present when both the positive slope and the median increase exceed their accepted tolerances. A bin below the accepted minimum count, an incomplete interval or an unavailable comparable GC type makes that comparison inconclusive; do not borrow events from another load, query condition or GC type. A zero-event class still reports count zero without a percentile; its absence blocks a recommendation only when that class is required by the accepted analysis settings. Report Young occupancy separately, and do not infer a complete live set when old-generation reclamation has not been observed. Absence of continuing growth is necessary but does not replace the candidate repeat, heap margin, host memory budget, payload checks or failure exclusions. If either run is inconclusive or any required comparison shows continuing growth, withhold the recommendation; retain evidence and obtain separate direction before extending a run or revising the analysis settings.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Installation | Render test overrides through the shipped Make configuration, install via Ansible and start through the real launcher/service; inspect all four JVM command lines, GC files, effective per-PV stores, hold values and ETL properties; verify initial empty database/archive | Disposable Rocky 8.10 VM | Recovered policy reproduced completely; correct refs, 256M heaps, G1 and logging; every component writes identifiable logs |
| T2 | Measurement | Verify accepted provisional limits before preflight history collection; prepare full-range real history on a separate VM; run all four original query clients with the collectors; validate sample coverage, values and response bytes; use measured resources to propose final limits and verify acceptance before baseline; parse complete GC logs and compare with original lines | Preflight with actual one-day history where requested, plus all four components over the three stages | Provisional limits enforced from preflight start; complete responses and simultaneous resource measurements retained; sparse, invalid or failed preflight blocks baseline; both limit sets and acceptance times recorded; final limits enforced unchanged in both long runs; actual boundary failure stops collection and preserves evidence; reproducible statistics with explicit unavailable fields |
| T3 | Runtime | Run the original 100/500/903 PV workloads through real CA acquisition, archive queries and ETL; measure process and host resources throughout | 24/6/27-hour schedule; final six hours with four query clients | Original workload/settings verified; actual archived rates and both ETL transitions observed; query data validated; all failures and resource constraints recorded |
| T4 | Sizing | Repeat the complete three-stage 57-hour sequence through the shipped path with the candidate heap; verify matching refs, workload/policy hashes, collector budgets and resources plus initial empty database/archive; apply the previously accepted warm-up intervals, event counts and four-bin trend method to both runs; compare GC, resources and payload validity | Separate newly provisioned VM; otherwise identical recorded conditions and analysis settings | Only heap differs; complete comparable evidence without JVM/client/host OOM or unexpected restart; every required trend comparison has sufficient events and does not trigger the fixed continuing-growth criterion; growth, insufficient evidence or analysis changes prevent recommendation |
| T5 | Documentation | Recalculate each public table from retained raw evidence and match guide settings and limits to the validated repeat | Canonical results and install guide | Recommended heap, source/configuration applicability, margin and measurement limits agree with real results |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Disposable VM | Pending | none |
| T2 | Not run | Disposable VM | Pending | none |
| T3 | Not run | Disposable VM | Pending | none |
| T4 | Not run | Disposable VM | Pending | none |
| T5 | Not run | Canonical results and install guide | Pending | none |

Input recovery observed on 2026-10-01: the clean ansible-provision checkout at `13608fea2b65758f9999c8d462e82a50570146bd` contains the preserved original tools and fixtures under `tests/archiver-soak/`, last changed at `1827046eaa216c1d27c0c22ca57ab729154b50e1`. The real `sha256sum --check SHA256SUMS` in that directory passed all 30 entries. Direct CSV inspection confirmed incremental populations of 100, 400 and 403 PVs; their ordered concatenation equals the 903-PV list, with 903 unique PV names and store keys, 880 MONITOR and 23 SCAN requests. Cumulative periods and waveform counts match all three planned stages. The combined fixture SHA256 is `037a92691bc23a6dcac37ec3613ad19c9f80b93b689209ec8dc403b519eaf594`.

The preserved `baseline/store-test.yml` specifies STS `PARTITION_5MIN`, hold 2; MTS `PARTITION_HOUR`, hold 2; and LTS `PARTITION_DAY`. `baseline/register.py` and `baseline/load_retrieval.py` preserve the registration and four-client query selection: one-hour windows for all selected PVs, with one-day windows allowed only for eligible one-second scalars, and a two-second wait. The original installed policy/properties and effective per-PV stores have not yet been recovered; the separate pilot policy is not evidence for that run. The retained query client counts streamed samples but does not validate or retain full response payloads, so it cannot satisfy the new measurement contract unchanged. These local input checks do not pass T1-T5.

Evidence storage placement remains undecided. The original operator record at ansible-provision `13608fea2b65758f9999c8d462e82a50570146bd`, `docs/milestone-38560eb.md`, M14 / T21, reports approximately 156 GB served in six hours. This is a reported response volume, not a new disk measurement. Retaining complete responses therefore requires a separately accepted evidence-storage budget and placement; the 20 GiB appliance disk alone cannot hold that reported volume. No provisional resource limits or VM measurement start have been accepted yet.

Local preparation tool: `tests/heap/inspect-inputs.py` reads the preserved source inputs without VM contact or mutation and emits their hashes, populations and outstanding execution prerequisites. On 2026-10-01, its real CLI returned 0 against the original files at Ansible `13608fea2b65758f9999c8d462e82a50570146bd`, with the expected three stages and `execution_ready: false`. Supplying a different requested commit returned 77. These are local input-inspection results; T1-T5 remain Pending.

##### Closure Evidence

- none

##### GitHub Projection

Title: Measure per-component heap needs by archiving load
Labels: enhancement
GitHub Milestone: none
Observed State: OPEN
Observed Labels: enhancement
Observed Milestone: none
Last Compared: 2026-10-05 at 17:34 UTC, `gh issue view 53 --repo jeonghanlee/epicsarchiverap-env`; OPEN, enhancement, no milestone, assignee jeonghanlee, updatedAt 2026-10-05T17:33:17Z; the milestone was cleared under D37 and a comment records why and what resumption requires.

#### M42 - Apply backend selection to all database operations

Origin: 265f580 / M42
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved
GitHub Issue: none
Status: Deferred

##### Summary

`DB_BACKEND` selects the appliance JDBC resource and MariaDB service dependency,
but does not consistently select epicsarchiverap-env's database commands. At `46faeb9`,
`configure/RULES_SQL` switches schema generation, loading and table listing;
table deletion and the four application-table queries still invoke
`scripts/mariadb_setup.bash`. All `db.*` commands remain MariaDB-specific.
An unrecognized backend falls through to MariaDB in the SQL rules, while
`conf.context` and `conf.systemd0` reject it. At that earlier commit, the
MariaDB application-table query also hardcoded
`archappl` in `show_archappl`. The 2026-09-28 correction authorized after the
whole-repository review makes it honor `DB_NAME`, exports `JDBC_DB_NAME` as
`ARCHAPPL_DB_NAME` for the JNDI lookup, and makes admin removal honor
`DB_ADMIN`. These identity corrections do not implement backend isolation.

The 2.0.0 correction rejects SQLite and invalid backend values at
`sql.drop` and `sql.table.drop`. M43 now verifies the broader isolation guards
in commit 3560216: SQLite db.* skips, while unsupported SQL/query/helper
operations and invalid selectors reject before side effects. SQLite deletion,
application-table queries, lifecycle, backup and restore remain this row's
deferred scope.

##### Scope

- Inventory every public database operation, including `sql.*`, `db.*`,
  `PVRequests.show`, `DataServers.show`, `PVAliases.show`, `PVTypeInfo.show`,
  and the setup script's query, backup and restore entrypoints.
- Make generic operations consistently select MariaDB over TCP or a Unix
  domain socket, or the SQLite file at `ARCHAPPL_SQLITE_FILE`. Validate the
  backend before any configuration write, database connection or deletion;
  an unknown value must never fall through to MariaDB.
- Implement SQLite table deletion and application-table queries against the
  source repository's shipped schema. Specify handling of associated triggers,
  missing databases, file ownership, WAL files and active appliance connections.
- Define backend-specific behavior for database creation, removal, inspection,
  backup and restore. MariaDB account and server administration have no SQLite
  equivalent: make the command boundary explicit and return a clear error for
  unsupported operations without contacting MariaDB under SQLite selection.
- Keep database identity consistent across Make, generated configuration,
  helper scripts and JDBC. Honor `DB_NAME` on MariaDB and the configured file
  on SQLite; define how stale generated configuration is detected or refreshed.
- Align the install procedure, command documentation and tests with that
  behavior, including when MariaDB configuration generation is unnecessary.

Out of scope: automatic data migration or replication between engines,
application schema redesign, PV archive-file deletion, and DB performance
tuning. The current deletion guard is a partial safeguard, not completion of
this work.

##### Completion Criteria

- Every inventoried entrypoint has documented behavior for both supported
  backends and for invalid selection; no generic command contacts the
  unselected backend.
- SQLite supports schema load, table listing, all four application-table
  queries, table deletion and reload using the shipped schema. MariaDB retains
  those operations over both TCP and its Unix domain socket.
- Database lifecycle, backup and restore follow the documented backend policy;
  unsupported operations and client failures return nonzero status.
- Disposable-database tests verify the selected database's result and that the
  other database's schema and rows remain unchanged, including deletion tests.
- The install and operator documentation describes the same behavior as the
  commands, with no unconditional MariaDB step in the SQLite procedure.

##### Dependencies And Decisions

- D31. Backend isolation guards move to M43 for 2.0.1. This row retains the full SQLite operation, lifecycle, backup and restore expansion; M43 does not close it.

- [M9 in 2.0.0](https://github.com/jeonghanlee/epicsarchiverap-env/blob/d68f66848e1edc174e76fe77326e941baf58f850/docs/milestone-265f580.md) supplies the installed backend selection and source schemas.
- D29, Decision Date: 2026-09-28. Full work remains deferred. The initial
  authorization covered the `sql.drop` / `sql.table.drop` safeguard.
- Decision Date: 2026-09-28. The subsequent whole-repository review correction
  additionally covers password preservation, runtime DB-name propagation,
  application-table DB selection and configured admin removal. It does not
  authorize the full backend matrix; M42 remains Deferred. A new dated
  decision is required to return it to Not started.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the operation matrix and database lifecycle policy, including the
   MariaDB-only administration boundary and standalone script invocation.
2. Apply shared backend validation and route generic operations to the matching
   client and database identity. Implement missing SQLite operations.
3. Align documentation and exercise the complete matrix on disposable databases
   using the shipped rules, scripts and source schemas.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Command routing | Run every entrypoint with both backends, both local configuration locations, command-line overrides and invalid values | Isolated epicsarchiverap-env checkout and disposable databases | Selected client and identity agree; invalid or unsupported operations fail before side effects |
| T2 | Database integration | Load the shipped schemas, insert records, query all four tables, drop tables and reload through real targets | SQLite and MariaDB over TCP and Unix domain socket | Expected schema and rows in the selected database; unselected database unchanged |
| T3 | Database lifecycle | Exercise creation, removal, backup and restore, including a non-default name or file, WAL mode and defined active-connection handling | Disposable databases under the service account | Documented lifecycle and ownership; backup restores the expected rows; failures propagate |
| T4 | Deployment | Follow the documented sequence for each backend and exercise the appliance configuration database | Debian 13 and Rocky Linux 8 disposable VMs | JDBC, helpers and service dependencies use the selected backend consistently |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Isolated epicsarchiverap-env checkout and disposable databases | Pending | none |
| T2 | Not run | SQLite and MariaDB over TCP and Unix domain socket | Pending | none |
| T3 | Not run | Disposable databases under the service account | Pending | none |
| T4 | Not run | Debian 13 and Rocky Linux 8 disposable VMs | Pending | none |

##### Closure Evidence

- none
#### M47 - Replace the Python tests with Bash tests

Origin: 2.0.1 / M47
Identity History: none
GitHub Issue: none
Status: Open

##### Summary

D41 sets Bash for new tests and names the conversion of the existing Python tests as the long-term direction, because Python versions differ across the supported systems and Python test code needs rewriting as the language changes. Seven tracked Python files total 3,755 lines: `tests/vm/driver.py` 1,233, `tests/vm/guest.py` 761, `tests/vm/local.py` 658, `tests/health-local.py` 472, `tests/database-config.py` 344, `tests/install-payload.py` 145 and `tests/heap/inspect-inputs.py` 142. The shell scripts and Make rules of the repository contain no Python; the tests are the only dependency. The guest verifier needs `python3` on the guest, which a fresh Rocky 8.10 guest lacks until Ansible installs it, and the guest then runs Python 3.6 while the host runs 3.13.

The row is Open because its scope and order are unsettled: the owner has set the direction, not a schedule or an acceptance rule.

##### Scope

- Inventory every Python file and the consumers that call it, from `tests/phase1-logic.bash` and `tests/run-all-tests.bash`.
- Convert the tests of shell code first (`tests/health-local.py`, `tests/database-config.py`, `tests/install-payload.py`), keeping each assertion and its real-path method.
- Decide separately how the VM driver and guest verifier are replaced, since they carry the largest logic and run on guests with different Python versions.

Out of scope: any change to what the tests assert; replacing Ansible, which the control host still needs.

##### Completion Criteria

- No test of shell code, Make rules or the installed appliance remains Python.
- Each converted test fails on the defect it covers, shown by a mutation of the shipped code.
- The full local suite and the VM matrix keep their current pass conditions without skips.

##### Dependencies And Decisions

- D41 sets the direction. A dated owner decision on scope and order is required before it can become Not started.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. After the owner decision, inventory each Python file with its callers and the behavior it asserts.
2. Convert the shell-code tests one file at a time, then plan the driver and verifier.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | Each converted test against the shipped code, then against a scratch mutation that reintroduces the defect it covers | Local host | Passes on the shipped code and fails on its mutation |
| T2 | System | Full `tests/run-all-tests.bash --local` and the VM matrix | Local host; fresh guests | Same pass conditions as before, no skips |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Pending | Local host | Pending | none |
| T2 | Pending | Local host; fresh guests | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Replace the Python tests with Bash tests
Labels: enhancement
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M49 - The operating system target rewrites `configure/CONFIG_SITE.local` and the installers run it first

Origin: 2.0.1 / M49
Identity History: none
GitHub Issue: none
Status: Deferred

##### Summary

The targets `<os>.conf` (`debian13.conf`, `rocky8.conf` and the others in `configure/RULES_TOMCAT`) delete `configure/CONFIG_SITE.local` and write one line into it, the include of `configure/os/<os>.mk`. Every installer runs its operating system target as its first step, so a value that an operator wrote into `configure/CONFIG_SITE.local` is lost when the installer runs. `../CONFIG_SITE.local`, next to the checkout, is not touched and is the place for site values.

Observed 2026-10-11 on the author's host. `make -n debian13.conf` prints `rm -f <checkout>/configure/CONFIG_SITE.local` and `echo "include \$(TOP)/configure/os/debian13.mk" > <checkout>/configure/CONFIG_SITE.local`. The plan of `bash scripts/install-local-sqlite.bash --plan --skip-packages` lists `make ... debian13.conf` as its first make step. Recheck with those two commands.

The row is Deferred by D55 (2026-10-11): the owner chose the stop and scheduled it for the release after 2.0.1, which has no milestone yet.

##### Scope

- The installers stop, before they change anything, when `configure/CONFIG_SITE.local` holds a line other than the include of its operating system file, print those lines and name `../CONFIG_SITE.local` (D55). The target keeps writing the one line.
- Keep the documented place for site values, `../CONFIG_SITE.local`.

Out of scope: changing the content of the operating system files `configure/os/*.mk`.

##### Completion Criteria

- An assignment written into `configure/CONFIG_SITE.local` is either present after `make <os>.conf` or the installer stops before it changes anything and names `../CONFIG_SITE.local`.
- The check for this behavior runs the real `make <os>.conf` target in an isolated copy of the repository.

##### Dependencies And Decisions

- D55 (2026-10-11): the stop is the chosen behavior and the work belongs to the release after 2.0.1. It becomes Not started when that release has a milestone and the row is assigned to it.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. After the owner decision, change the `<os>.conf` rules in `configure/RULES_TOMCAT`, or the first step of the installers.
2. Add the real-target check to `tests/phase1-logic.bash`.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | In an isolated copy of the repository, write an assignment into `configure/CONFIG_SITE.local`, run the real `make debian13.conf`, and read the file | Local host | The assignment is present, or the installer stops first with a message that names `../CONFIG_SITE.local` |
| T2 | Local | The full local suite `bash tests/run-all-tests.bash --local` | Local host | Passes with the same groups as before |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Pending | Local host | Pending | none |
| T2 | Pending | Local host | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: The operating system target rewrites `configure/CONFIG_SITE.local` and the installers run it first
Labels: bug
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none

#### M27 - LTS retrieval pre-processing (`pp`)

Origin: 265f580 / M27
Identity History: transferred from docs/milestone-2.0.0.md to docs/milestone-2.0.1.md on 2026-09-29; ID and Origin preserved
GitHub Issue: none
Status: Open

##### Summary

`docs/README.policies.md` recommends `pp=mean_3600` on LTS, and the shipped
`site-template/policies.py.in` sets no `pp` on any tier. The gap is real but the
answer is not obvious from the documents, so it waits for operating experience
rather than being settled now.

Two facts shape the question. `pp` preserves the raw data and writes auxiliary
pre-calculated files beside it, so it *increases* disk use, which runs against
the open concern that the archive store sits on the root filesystem with an
unknown fill rate. And `pp` is mutually exclusive with `reducedata`, which the
shipped Fast, VeryFast, Medium and Slow policies already set on LTS; the
recommendation can therefore only apply to the Default and VerySlow policies.

##### Scope

- Whether the Default and VerySlow policies gain `pp` on LTS, and with which
  operator and interval.
- `site-template/policies.py.in` and the policy guide, if the answer is yes.

Out of scope: `reducedata` on the other policies; the retrieval API; the
storage filesystem work, which M26 carries.

##### Completion Criteria

- After the appliance has run with real queries and a known disk growth rate,
  a dated decision either adds `pp` to the named policies or records that the
  retrieval gain does not justify the additional storage.

##### Dependencies And Decisions

- Decision Date: 2026-09-29. Transferred from Milestone to Backlog for the 2.0.0 cycle close. Existing status, scope, dependencies, plan and verification evidence are preserved; no next release is assigned.
- Decision Date: 2026-09-22. Assigned from Backlog to Milestone. The operating measurements and pp selection remain unresolved. Status stays Open; assignment alone does not accept or authorize implementation.
- Condition for taking this up: an operating installation with a measured disk
  growth rate and real retrieval patterns to judge against. Owner decided
  2026-09-21 to look at it during operation over the long term rather than now.
- D21 (the storage work is scoped to the test environment first).
- The disk growth figure comes from the load test requested of the
  ansible-provision session.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Function | Compare retrieval time and disk use for a long span with and without `pp` on LTS | operating installation | The difference is large enough, or not, to settle the decision |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | operating installation | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: LTS retrieval pre-processing
Labels: enhancement
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M61 - Fix the findings of the review of the VM driver

Origin: 2.0.1 / M61
Identity History: none
GitHub Issue: none
Status: Deferred

##### Summary

The delegated third-person review of `tests/vm/driver.py`, `guest.py`, `local.py` and their documents on 2026-10-27 found one Must-Fix and further findings. The driver run of the same day stopped at its check `build_proof` (`driver.py`, near line 958), whose required Make list lacks `conf.install`, which the installer runs. D67 replaces the driver run for release 2.0.1 by a check that follows the install pages, so the fixes are deferred. The owner decides when they proceed.

##### Scope

- Must-Fix: the driver loads its state (`driver.py` near lines 1153, 1160 and 1166) before it takes the exclusive lock (near line 1188); take the lock first.
- Make the required Make list of `build_proof` agree with the Make steps that the installers run, including `conf.install`.
- Minor findings: the tool reference is not verified; the tool checkouts are checked only at initialization; the SSH host pin is weaker than the stated global known-hosts handling; an interruption before the first record fails the whole run; the refusal check accepts any exit status 2; the snapshot comparison covers the whole libvirt host; a malformed context returns inconsistent exit codes.
- Strengthen the tests: in the mutation sample of the review, 101 of 125 mutations survive; the verdict gates, the cleanup verification, `build_proof`, the adoption path, the species mapping and the guest actions have no test that fails on a mutation.
- Correct the three places where the documents and the code disagree.

Out of scope: replacing the driver (M47 decides the language of the tests); any change to the check of D67.

##### Completion Criteria

- Each finding of Scope is fixed or carries an owner decision that leaves it.
- Each fixed finding has a test that fails on a mutation that reintroduces it.
- The driver files do not change while a run that started with them is open.

##### Dependencies And Decisions

- D67 defers this row. A dated owner decision on timing is required before it can become Not started.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. After the owner decision, list every finding with its location in the current files of `tests/vm`.
2. Fix the Must-Fix and `build_proof` first, each with a failing test before the fix.
3. Work through the Minor findings and the surviving mutations in the order the owner sets.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local | The tests of `tests/vm` against the shipped code, then against a scratch mutation for each fixed finding | Local host | Passes on the shipped code and fails on each mutation |
| T2 | System | One real case of the driver on a fresh guest after the fixes | Local libvirt host; fresh guest | The case reaches its verdict without a driver error |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Pending | Local host | Pending | none |
| T2 | Pending | Local libvirt host; fresh guest | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Fix the findings of the review of the VM driver
Labels: enhancement
GitHub Milestone: none
Observed State: none; no issue exists yet
Last Compared: none
