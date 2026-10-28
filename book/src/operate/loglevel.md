# Change a log level at run time

The control script reads or sets the level of one logger on one component of a running appliance. The request goes to the `mgmt` application, which forwards it to the other components, so no restart is needed. The script sends plain HTTP requests without credentials, so anyone who can reach the `mgmt` port can send the same request. The [glossary](../appendix/glossary.md) explains the terms of this page.

## Prerequisites

- A running appliance.
- `curl` in `PATH`.
- `ARCHAPPL_MGMT_PORT` in the `archappl.conf` next to the script.
- A shell in the installation directory `AA_INSTALL_LOCATION` (`/opt/epicsarchiverap-maven` by default; `make -s print-AA_INSTALL_LOCATION` prints it), which holds `archappl.bash` and `archappl.conf`.

## Steps

1. Read the level of the root logger of a component. The component is one of `mgmt`, `engine`, `etl` and `retrieval`; the logger defaults to `root`.

   ```bash
   bash archappl.bash loglevel engine
   ```

   The command prints the answer of the server:

   ```text
   {"component":"engine","level":"INFO","logger":"root"}
   ```

2. Optional: read the level of a named logger. A logger name holds letters, digits, `_`, `.` and `-`.

   ```bash
   bash archappl.bash loglevel engine org.epics.archiverappliance.engine
   ```

   The command prints the level of that logger:

   ```text
   {"component":"engine","level":"INFO","logger":"org.epics.archiverappliance.engine"}
   ```

3. Set a level. The level is one of `OFF`, `FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE` and `ALL`, in upper or lower case.

   ```bash
   bash archappl.bash loglevel engine org.epics.archiverappliance.engine debug
   ```

   The answer names the level that the logger had before:

   ```text
   {"previousLevel":"INFO","component":"engine","level":"DEBUG","logger":"org.epics.archiverappliance.engine"}
   ```

4. Return the logger to its previous level when the diagnosis ends. Use the level that the answer of step 3 names as `previousLevel`. A lower level writes more lines to the journal, so do not leave `DEBUG` or `TRACE` set longer than needed.

   ```bash
   bash archappl.bash loglevel engine org.epics.archiverappliance.engine info
   ```

   The answer names `DEBUG` as the previous level and `INFO` as the level:

   ```text
   {"previousLevel":"DEBUG","component":"engine","level":"INFO","logger":"org.epics.archiverappliance.engine"}
   ```

## Verification

Read the level again with the command of step 2. It prints the level that you set last, `INFO` after step 4:

```text
{"component":"engine","level":"INFO","logger":"org.epics.archiverappliance.engine"}
```

A level set this way applies to the running process only and is lost at the next start; the permanent level is `ARCHAPPL_ROOT_LOGGER_LEVEL`. The script sends `getLogLevel` or `setLogLevel` to `http://localhost:<mgmt_port>/mgmt/bpl/`. The script exits with `0` when the server answers with the Hypertext Transfer Protocol (HTTP) status 200. It exits with `1` when the request fails or the server answers with another status. It exits with `2` when an argument is not valid, when `curl` is not in `PATH`, or when `archappl.conf` has no numeric `ARCHAPPL_MGMT_PORT`. The script checks the arguments before it sends anything, and an invalid component stops it with exit status `2`:

```bash
bash archappl.bash loglevel bogus
```

The script prints the valid components:

```text
loglevel: component must be one of: mgmt engine etl retrieval
```
