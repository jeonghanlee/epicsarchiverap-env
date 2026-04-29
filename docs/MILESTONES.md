# epicsarchiverap-maven Development Milestones

## Scope

This document covers the Maven build system (`pom.xml`) development roadmap for
`jeonghanlee/epicsarchiverap-maven`, from the current v2.0.10 baseline through
the v2.2.x stabilization target.

**Out of scope:** Java source changes, EPICS IOC integration, Parquet/Hadoop
storage backend (deferred indefinitely), and upstream v2.3.x features.

---

## Timeline

| Milestone | Target date | Notes |
|-----------|-------------|-------|
| M0 — Cleanup branch test and merge | 2026-05-15 | Current PR cycle on `cleanup` branch |
| M1 — pom.xml correctness (v2.0.10 baseline) | 2026-07-31 | |
| M2 — Build infrastructure | 2026-09-30 | |
| M3 — Upstream sync v2.1.x | 2026-11-30 | Optional |
| M4 — Upstream sync v2.2.x (Jakarta / Tomcat 10) | 2027-02-28 | Last upstream merge |
| M5 — Independent maintenance baseline | 2027-03-31 | Ongoing thereafter |

Targets are calendar dates, not version tags. M5 marks the start of
ongoing maintenance, not an end state.

---

## Upstream Relationship Model

This fork tracks upstream `archiver-appliance/epicsarchiverap` via `git merge`
through v2.2.x. The merge strategy changes at each phase boundary:

| Phase | Upstream range | Merge strategy | Gradle files |
|-------|---------------|----------------|--------------|
| M1–M2 | at v2.0.10 | none (stabilize only) | kept as reference |
| M3 *(optional)* | v2.0.10 → v2.1.2 | `git merge` | kept, conflicts resolved |
| M4 | v2.0.10 or v2.1.2 → v2.2.1 | `git merge` (last merge) | **removed at M4 close** |
| M5+ | v2.2.1 and beyond | **diverged — cherry-pick only** | gone |

**M3 is optional.** If PV pause/resume stability is not a priority for ALS-U
operations, skip M3 and merge directly from v2.0.10 to v2.2.1 in M4.

**Divergence rationale:** Upstream v2.3.x introduces Parquet/Hadoop and a
`build.gradle.kts` version catalog. Neither is applicable to this Maven track.
From v2.2.1 onwards, this fork is maintained independently. Upstream changes
are assessed per release and cherry-picked individually — no bulk merges.

---

## Baseline

| Item | Value |
|------|-------|
| Fork base commit | `a81b5e4` |
| Upstream release | v2.0.10 |
| Build system | Maven (`pom.xml`) alongside legacy `build.gradle` (Groovy DSL) |
| Tomcat | 9.x |
| Servlet API | `javax.servlet` (pre-Jakarta) |
| Parquet/Hadoop | Not present in source |

---

## M0 — Cleanup branch test and merge

**Target:** 2026-05-15
**Goal:** Validate the configure/ restructure, documentation pass, and phased
install test framework on the `cleanup` branch, then merge to `maven`.

### M0.1 Local validation

- [ ] Run `tests/run-all-tests.bash --local` on cleanup HEAD
- [ ] Confirm Phase 1 (21 assertions) and Phase 2 (14 assertions) pass

### M0.2 PR cycle

- [ ] Push `cleanup` to `origin`
- [ ] Open PR against `maven`
- [ ] Address review comments
- [ ] Merge to `maven`

### M0.3 Post-merge

- [ ] Tag the merged state for traceability
- [ ] Confirm CI passes on the merged commit (once M2.1 lands)

---

## M1 — pom.xml Correctness (v2.0.10 baseline)

**Target:** 2026-07-31
**Goal:** `mvn clean package` produces a reproducible, assembly-complete build
equivalent to `gradle buildRelease` at v2.0.10.

### M1.1 Dependency hygiene

- [ ] Remove `scope=system` for `redisnio` and `BPLTaglets`; replace with
  `maven-install-plugin:install-file` execution at `initialize` phase
- [ ] Pin all version ranges (`[2.14.0,)`, `[32.0.0-android,)`,
  `[3.25.5,)`) to fixed versions matching v2.0.10 `build.gradle`
- [ ] Resolve `jca` version discrepancy (`2.4.7` in Gradle vs `2.4.10` in
  `pom.xml`) — confirm intentional upgrade or align

### M1.2 Build correctness

- [ ] Add `lib/native` packaging to `engine-war` execution
  (`caRepeater` + `*.so` — present in Gradle, missing from `pom.xml`)
- [ ] Replace `scp` local file copy with `maven-resources-plugin`
  `copy-resources` for `mgmt_scriptables.txt`
- [ ] Clarify `<packaging>jar</packaging>` — document intent or change to
  `pom` since actual outputs are four WARs + assembly tar.gz

### M1.3 Version string

- [ ] Align `<version>` string format with assembly output filename documented
  in README (`archappl_2025-06-05.tar.gz` vs `archappl_2025-6.tar.gz`)

### M1.4 Verification

- [ ] Diff assembly tar.gz file list against a known-good `gradle buildRelease`
  output at `a81b5e4`
- [ ] Confirm all four WARs deploy and start on Tomcat 9
- [ ] Tag `maven-v2.0.10-r1`

---

## M2 — Build Infrastructure

**Target:** 2026-09-30
**Goal:** Reproducible CI build, clean git history, usable developer workflow.

### M2.1 GitHub Actions workflow

- [ ] Add `.github/workflows/maven.yml` —
  `mvn clean package -Dsphinx.skip=true` on push/PR to master
- [ ] Cache `~/.m2/repository` in CI
- [ ] Upload assembly tar.gz as workflow artifact

### M2.2 Local developer ergonomics

- [ ] Document `mvn clean package -Dsphinx.skip=true` as the fast inner-loop
  build in README
- [ ] Document `ARCHAPPL_SITEID` override behavior in README

### M2.3 Git hygiene

- [ ] Establish tagging convention: `maven-v<upstream>-r<revision>`
- [ ] Annotate `build.gradle` / `gradlew` with a header comment marking them
  as upstream reference artifacts, not the active build system

---

## M3 — Upstream Sync: v2.1.x *(optional)*

**Target:** 2026-11-30
**Goal:** Absorb upstream v2.1.0–v2.1.2 bug fixes while staying on
Tomcat 9 / `javax.servlet`. Last phase before the Jakarta boundary.
Skip this milestone and proceed directly to M4 if v2.1.x bug fixes
(pause/resume, ETL threading) are not operationally critical.

### M3.1 Source sync

- [ ] `git merge` upstream range `a81b5e4..2.1.2` into master
- [ ] Resolve any merge conflicts (`pom.xml` is fork-only; conflicts expected
  only in Java source and `build.gradle`)

### M3.2 Dependency updates from v2.1.x

- [ ] `pbrawclient` 0.2.1 → 0.2.2 (upstream PR #440)
- [ ] `core-pva` already at 5.0.0 — verify no regression
- [ ] Review upstream PR #439 "Update dependencies" for any version bumps
  to carry into `pom.xml`

### M3.3 Notable source changes (build impact check only)

- [ ] `PlainPBStoragePlugin` → `PlainStoragePlugin` rename (PR #387) —
  no `pom.xml` impact, verify compile passes
- [ ] ETL threading refactor (PR #368) — no `pom.xml` impact, verify WAR
  contents unchanged

### M3.4 Verification

- [ ] `mvn test -Dsphinx.skip=true` unit test pass
- [ ] Tomcat 9 WAR deployment smoke test
- [ ] Tag `maven-v2.1.2-r1`

---

## M4 — Upstream Sync: v2.2.x (Jakarta / Tomcat 10) — Last Merge

**Target:** 2027-02-28
**Goal:** Migrate to Jakarta Servlet API and Tomcat 10+. This is the
long-term maintenance baseline. Tomcat 9 EOL is 2027.
**This is the final upstream `git merge`. The fork diverges permanently
at the close of M4.**

### M4.1 Jakarta migration in pom.xml

- [ ] `tomcat-servlet-api:9.x` (javax) →
  `tomcat-servlet-api:10.x` or `jakarta.servlet-api` equivalent
- [ ] `commons-fileupload:1.5` →
  `commons-fileupload2-jakarta` + `commons-fileupload2-core` (PR #434)
- [ ] Add `jakarta.validation` dependency
- [ ] Verify `<packagingExcludes>` in `maven-war-plugin` still correctly
  excludes the servlet API jar from WARs

### M4.2 Source sync

- [ ] `git merge` upstream into master:
  `a81b5e4..2.2.1` (if M3 skipped) or `2.1.2..2.2.1` (if M3 done)
- [ ] Resolve merge conflicts — expect changes in Java source imports
  (`javax.*` → `jakarta.*`) and `build.gradle`

### M4.3 Gradle removal (at merge close)

At the close of M4, Gradle files are no longer useful. Upstream has moved
to `build.gradle.kts` + version catalog which diverges from this fork's
Maven track. Remove in a single dedicated commit.

- [ ] Delete `build.gradle`, `gradlew`, `gradlew.bat`, `gradle/` directory
- [ ] Delete `_README.md` (Gradle-era developer guide — superseded)
- [ ] Commit message:
  `Remove Gradle artifacts: fork diverges from upstream at v2.2.1`

### M4.4 Tomcat version bump

- [ ] Update `epicsarchiverap-env` `TOMCAT_MAJOR_VER` → 10 in lockstep
- [ ] Confirm Tomcat 10 end-to-end WAR deployment and PV archival

### M4.5 Verification

- [ ] Deploy all four WARs on Tomcat 10, archive at least one test PV
- [ ] `mvn test -Dsphinx.skip=true` unit test pass
- [ ] Tag `maven-v2.2.1-r1`
- [ ] Update README: Tomcat 9 → Tomcat 10+, note fork independence
  from upstream

---

## M5 — Independent Maintenance (post-divergence)

**Target:** 2027-03-31
**Goal:** Long-term maintainability of the Maven track as an independent
fork. No upstream merges. Upstream changes assessed individually.

### M5.1 Cherry-pick policy

Upstream changes are reviewed per release. The criteria for cherry-picking:

- CVE fix in a dependency already in `pom.xml` — **always cherry-pick**
- Critical data-loss or corruption bug fix — **cherry-pick after review**
- Performance improvement or new feature — **evaluate per case**
- Parquet/Hadoop related — **skip unconditionally**
- `build.gradle.kts` / version catalog changes — **skip unconditionally**

Cherry-picks are applied to a short-lived branch, built, and merged to
master via PR — never directly to master.

### M5.2 Dependency maintenance cadence

- [ ] Establish a periodic review (e.g., each upstream release) of:
  log4j, guava, protobuf-java, hazelcast for CVE exposure
- [ ] Keep `mariadb-java-client`, `jedis` aligned with
  `epicsarchiverap-env` database versions

### M5.3 Parquet/Hadoop (conditional)

Deferred indefinitely. Revisit only if ALS-U operations require Parquet
storage backend. At that point, open a separate `feature/parquet` branch —
do not merge into master until fully validated on a staging deployment.

---

## Dependency Version Reference

### v2.0.10 baseline targets (M1)

| Artifact | Gradle v2.0.10 | Current pom.xml | M1 action |
|----------|---------------|-----------------|-----------|
| `jca` | 2.4.7 | 2.4.10 | Confirm intent |
| `commons-io` | 2.11.0 | `[2.14.0,)` | Pin to 2.14.0 |
| `guava` | 31.1-jre | `[32.0.0-android,)` | Pin to 32.0.1-jre |
| `protobuf-java` | 3.23.0 | `[3.25.5,)` | Pin to 3.25.5 |
| `log4j` family | 2.20.0 | 2.20.0 | OK |
| `hazelcast` | 5.4.0 | 5.4.0 | OK |
| `jedis` | 4.4.0 | 4.4.0 | OK |
| `mariadb-java-client` | 3.3.3 | 3.3.3 | OK |
| `pbrawclient` | 0.2.1 | 0.2.1 (local jar) | Upgrade in M3 |

### v2.2.x new/changed dependencies (M4)

| Artifact | Change |
|----------|--------|
| `tomcat-servlet-api` | javax → jakarta namespace |
| `commons-fileupload` | 1.5 → fileupload2-jakarta + fileupload2-core |
| `jakarta.validation` | new addition |
