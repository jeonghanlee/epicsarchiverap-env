# Fetch and build the web applications

This page produces the four WAR files of the appliance from the source commit that the repository pins. The build skips the unit tests of the source repository; its CI runs them.

## Prerequisites

- A host with the JDK that `JAVA_HOME` names (`configure/CONFIG_SITE`), `git` and `make`, prepared as in [Prepare the host for the appliance](../install/prepare-host.md).
- Network access to the source repository and to the Maven repositories on the first build.
- A write-capable `sudo` only for the target `make build`, which also prepares the storage folders. The steps below avoid it.

## Steps

1. Fetch the source. The target clones `SRC_GITURL` into `SRC_PATH` when the folder is absent and updates its submodules.

   ```bash
   make init
   ```

   The command prints nothing when the clone exists.

2. Check that the checkout is at the pinned commit.

   ```bash
   make -s print-SRC_TAG
   git -C epicsarchiverap-maven-src rev-parse HEAD
   ```

   Both commands print the same commit:

   ```text
   162269e7db97f527626ba0b387933a8c47e8bb57
   162269e7db97f527626ba0b387933a8c47e8bb57
   ```

3. Generate the configuration files, apply the site inputs and the interface files, and build the WAR files. This form needs no `sudo`.

   ```bash
   make conf.archapplproperties build.mvn
   ```

   The command prints a line that starts with `>>>` for each generated file and each copy, then the Maven output. It ends with:

   ```text
   [INFO] BUILD SUCCESS
   ```

   The build of the pinned commit took about 24 seconds on the host of this book, with the Maven dependencies cached.

## Verification

List the WAR files. The source build writes one file per component into `target/` of the checkout.

```bash
ls epicsarchiverap-maven-src/target/*.war
```

The output has four lines, one for each component:

```text
epicsarchiverap-maven-src/target/aa-20261011-162269e7-engine.war
epicsarchiverap-maven-src/target/aa-20261011-162269e7-etl.war
epicsarchiverap-maven-src/target/aa-20261011-162269e7-mgmt.war
epicsarchiverap-maven-src/target/aa-20261011-162269e7-retrieval.war
```

The name of a file is `aa-<build_date>-<short_commit>-<component>.war`.
