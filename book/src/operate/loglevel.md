# Change a log level at run time

The control script reads or sets the level of one logger on one component of a running appliance. The request goes to the `mgmt` application, which forwards it to the other components, so no restart is needed.

## Prerequisites

- A running appliance.
- `curl` in `PATH`.
- `ARCHAPPL_MGMT_PORT` in the `archappl.conf` next to the script.

## Steps

1. Read the level of the root logger of a component. The component is one of `mgmt`, `engine`, `etl` and `retrieval`; the logger defaults to `root`.

   ```bash
   bash /opt/epicsarchiverap-maven/archappl.bash loglevel <component>
   ```

2. Optional: read the level of a named logger.

   ```bash
   bash /opt/epicsarchiverap-maven/archappl.bash loglevel <component> <logger>
   ```

   `<logger>` holds letters, digits, `_`, `.` and `-`.

3. Set a level. The level is one of `OFF`, `FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE` and `ALL`, in upper or lower case.

   ```bash
   bash /opt/epicsarchiverap-maven/archappl.bash loglevel <component> <logger> <level>
   ```

The script sends `getLogLevel` or `setLogLevel` to `http://localhost:<ARCHAPPL_MGMT_PORT>/mgmt/bpl/` and prints the answer of the server.

## Exit status and messages

| Exit | Meaning |
| ---: | :--- |
| 0 | The server answered with HTTP 200; the answer is printed |
| 1 | The request failed or the server answered with another status |
| 2 | An argument or the host is not valid; the request is not sent |

The script checks the arguments before it sends anything. In a checkout these two commands were run as shown, and print:

```bash
bash scripts/archappl.bash loglevel bogus
```

```text
loglevel: component must be one of: mgmt engine etl retrieval
```

```bash
bash scripts/archappl.bash loglevel mgmt "bad logger!"
```

```text
loglevel: invalid logger name: bad logger!
```

(A checkout without `archappl.conf` also prints an error about the missing file before these lines.)

## Verification

Read the level again with step 1 after step 3; it prints the level that you set. A level set this way applies to the running process only and is lost at the next start; the permanent level is `ARCHAPPL_ROOT_LOGGER_LEVEL`.

The requests of steps 1 to 3 were not run against an appliance for the book; the argument checks above were run as shown.
