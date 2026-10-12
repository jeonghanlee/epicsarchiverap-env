# Override a setting for one host

This page changes a repository setting for one host without editing a tracked file. It uses the heap size of the four Java virtual machines (JVMs), `AA_JAVA_HEAPSIZE`, as the example; the same steps apply to every variable that [Configuration variables and their defaults](variables.md) lists.

## Prerequisites

- A checkout of the repository.
- The name of the variable that you change, from the page of configuration variables.

## Steps

1. Print the value that is in effect.

   ```bash
   make -s print-AA_JAVA_HEAPSIZE
   ```

   The command prints the default:

   ```text
   256M
   ```

2. Write the value into `../CONFIG_SITE.local`, the file next to the checkout. Do not use `configure/CONFIG_SITE.local` for site values: the target `<os>.conf`, which every installer runs first, deletes that file and writes the include of the operating system file into it.

   The command appends, so a file that already holds other settings keeps them. Check the file first when it exists.

   ```bash
   printf 'AA_JAVA_HEAPSIZE="512M"\n' >> ../CONFIG_SITE.local
   ```

3. Print the value again.

   ```bash
   make -s print-AA_JAVA_HEAPSIZE
   ```

   The command prints:

   ```text
   512M
   ```

4. Check that the value reaches the Java options of the four JVMs. The variable `CATALINA_OPTS` in `configure/CONFIG_SRC` builds `-Xms` and `-Xmx` from it.

   ```bash
   make -s print-CATALINA_OPTS
   ```

   The command prints:

   ```text
   -XX:MaxMetaspaceSize=256M -Xms512M -Xmx512M -XX:+UseG1GC -ea
   ```

5. Generate the files again and install them. The value is written into `archappl.conf` by `make conf.archapplproperties`, and the installer installs the file; see [Reinstall or upgrade an appliance](../install/reinstall.md).

## Verification

The commands of steps 3 and 4 print the value. After the reinstall, `AA_INSTALL_LOCATION/archappl.conf` carries it.
