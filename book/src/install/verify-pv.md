# Archive a test PV and check the stored samples

This page proves that a running appliance acquires, stores and returns data. The script `scripts/verify-local-pv.bash` starts a soft input/output controller (IOC) on the loopback interface, registers one unique process variable (PV) with the appliance, waits for stored samples and reads them back as comma-separated values (CSV). The [glossary](../appendix/glossary.md) explains the terms of this page.

## Prerequisites

- An ordinary user account: the script refuses to run as root.
- The commands `curl`, `jq`, `timeout`, `date`, `awk`, `nohup`, `mktemp`, `mkdir`, `ln` and `cp`. The script stops with `Required executable not found: <tool>` when one is missing.
- A running appliance, with the address of the `mgmt` bpl endpoint and the address of the retrieval application. With the default settings they are `http://localhost:17665/mgmt/bpl` and `http://localhost:17668/retrieval`.
- The source clone of the appliance, `epicsarchiverap-maven-src` in the root of this checkout. The script reads `docs/book/src/samples/getDataToCsv.bash` from it; it is the third argument of step 2.
- Experimental Physics and Industrial Control System (EPICS) Base with `softIoc` and `caget`, either exported as `EPICS_BASE` or named with `--epics-bin <epics_bin_dir>`.

## Steps

1. Check the EPICS prerequisites. The option `--check-epics` validates them and prints the binary directory; it takes no addresses.

   ```bash
   bash scripts/verify-local-pv.bash --check-epics --epics-bin <epics_bin_dir>
   ```

   `<epics_bin_dir>` is the absolute path of the directory that holds `softIoc` and `caget`. The command prints that directory:

   ```text
   <epics_bin_dir>
   ```

   Without `EPICS_BASE` and without `--epics-bin` the command stops with `ERROR: EPICS_BASE is not exported. Source your EPICS environment setup file in this terminal, then rerun.`

2. Run the verification with the same script. The command takes three arguments in this order: the `mgmt` bpl endpoint, the retrieval application and the source checkout.

   ```bash
   bash scripts/verify-local-pv.bash --epics-bin <epics_bin_dir> --cleanup stop <mgmt_bpl> <retrieval> <source_checkout>
   ```

   `<mgmt_bpl>` and `<retrieval>` are the two addresses of the prerequisites; the script accepts only the host `localhost` or `127.0.0.1` in them, in the forms `http://localhost:<port>/mgmt/bpl` and `http://localhost:<port>/retrieval`. `<source_checkout>` is the path of `epicsarchiverap-maven-src`. The run adds a permanent PV registration to the target appliance. The option `--timeout <seconds>` limits the verification to 10 to 3600 seconds; the default is 180. The option `--cleanup stop` pauses the test PV and stops the soft IOC when the check ends; `--cleanup keep` leaves both running, so the PV keeps archiving; without the option an interactive menu asks. The script prints the test PV name and the evidence folder, then reports each stage: the accepted archive request, the PV being archived, the pause that flushes the stored samples, and the CSV that it reads back.

3. Read the result. A successful run prints `PV acquisition, storage and retrieval: PASS` and the path of the CSV file.

## Verification

The line `PV acquisition, storage and retrieval: PASS` is the result. The evidence folder that the script names keeps the registration response, the status, the observations of the IOC and the CSV; the script never deletes the PV registration or the stored samples. On a failure or an interruption the script stops its IOC and tries to pause the PV.

Step 2 registers a PV with the appliance that answers at the addresses. The messages above are those that `verify-local-pv.bash` prints. When the script ends without `PASS`, open the files in its evidence folder, the path after `Evidence:` in its output: `ioc.log` for the soft IOC, `register.json` and `status.json` for the registration and its status, and `extract-<n>.log` and `csv-<n>/` for the retrieval. The message `No two changing stored samples matched real CA observations within <N> seconds` is the timeout message of the whole check. It appears when the status `Being archived`, the retrieval or the comparison of the stored and the observed samples did not finish in time; the evidence files show which one. The PV stays registered.
