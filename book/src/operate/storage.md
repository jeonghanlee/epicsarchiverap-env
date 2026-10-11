# Watch the storage use

The control script shows how much space the three stores use, and the health check compares each store with a threshold. This page reads both, and explains the placement check that runs when the storage folders are prepared.

## Prerequisites

- An installed appliance.
- `sudo` rights, because the storage action runs `du` as root.

## Steps

1. Show the total of the archive root with its time stamp.

   ```bash
   bash /opt/epicsarchiverap-maven/archappl.bash storage
   ```

   The script runs `du --total --human-readable --time` on `ARCHAPPL_STORAGE_TOP` with `sudo` and prints the size of each folder and the total.

2. Optional: list every file.

   ```bash
   bash /opt/epicsarchiverap-maven/archappl.bash storage all
   ```

3. Compare each store with the alarm threshold.

   ```bash
   bash /opt/epicsarchiverap-maven/archappl.bash health
   ```

   The `storage path=...` lines show the file system usage of the archive root and of the short, medium and long term folders against `ARCHAPPL_STORAGE_ALARM_PERCENT` (85 by default); [Health check results](health-results.md) lists their forms.

## The placement check

When `make conf.storage` prepares the folders, `scripts/check_storage_placement.bash` reports a store that shares the root file system or lies under a user's home directory. The check only warns and always exits `0`; the placement and the size of the stores belong to the host.

## Verification

The command of step 1 prints a size line for each folder and a total line. The command of step 3 prints one `storage path=...` line for each path and a status of `PRESENT` or `FAIL storage-threshold`.

The commands of this page were not run for the book, because the host that wrote it serves a live archive; the behavior comes from `scripts/archappl.bash` and `scripts/check_storage_placement.bash`.
