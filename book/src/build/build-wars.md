# Fetch and build the web applications

This page produces the four web application archive (WAR) files of the appliance from the source commit that `SRC_TAG` selects. The build skips the unit tests of the source repository; its continuous integration (CI) runs them.

## Prerequisites

- A host with the Java Development Kit (JDK) that `JAVA_HOME` names (`configure/CONFIG_SITE`), `git` and `make`, prepared as in [Prepare the host for the appliance](../install/prepare-host.md).
- Network access to the source repository and to the Maven repositories on the first build.
- A write-capable `sudo` only for the target `make build`, which also prepares the storage folders. The steps below avoid it.

## Steps

1. Fetch the source. The target clones `SRC_GITURL` into `SRC_PATH` when the folder is absent and updates its submodules.

   ```bash
   make init
   ```

   The command prints nothing when the clone exists, and it does not update an existing clone. To follow the branch tip, fetch and check it out:

   ```bash
   git -C epicsarchiverap-maven-src fetch origin
   make srcupdate
   ```

2. Check that the checkout is at the commit that `SRC_TAG` names.

   ```bash
   make -s print-SRC_TAG
   git -C epicsarchiverap-maven-src rev-parse HEAD origin/modernize
   ```

   The first command prints the reference and the second prints the same commit twice. After the fetch and `make srcupdate` above, the commit is the tip of the branch on the day of the run, in this form:

   ```text
   origin/modernize
   <commit_hash>
   <commit_hash>
   ```

3. Generate the configuration files, apply the site inputs, and build the WAR files. The management interface comes with the source. This form needs no `sudo`.

   ```bash
   make conf.archapplproperties build.mvn
   ```

   The command prints a line that starts with `>>>` for each generated file and each copy of the site folder, then the Maven output. It ends with:

   ```text
   [INFO] BUILD SUCCESS
   ```

## Verification

List the WAR files. The source build writes one file per component into `target/` of the checkout.

```bash
ls epicsarchiverap-maven-src/target/*.war
```

The output has four lines, one for each component, in this form:

```text
epicsarchiverap-maven-src/target/aa-<build_date>-<short_commit>-engine.war
epicsarchiverap-maven-src/target/aa-<build_date>-<short_commit>-etl.war
epicsarchiverap-maven-src/target/aa-<build_date>-<short_commit>-mgmt.war
epicsarchiverap-maven-src/target/aa-<build_date>-<short_commit>-retrieval.war
```

The name of a file is `aa-<build_date>-<short_commit>-<component>.war`.
