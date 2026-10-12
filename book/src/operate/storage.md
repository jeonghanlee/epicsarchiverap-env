# Storage use reporting

The control script reports how much space the three stores use, and the health check compares each store with a threshold. This page lists both reports and explains the placement check that runs when the storage folders are prepared.

## What the control script reports

| Action | What it prints |
| :--- | :--- |
| `storage` | The size of each folder under `ARCHAPPL_STORAGE_TOP` and the total, with a time stamp, from `du --total --human-readable --time` run with `sudo` |
| `storage all` | The same, with every file listed as well as the folders |
| `health` | One `storage path=...` line for the archive root and for each of the short, medium and long term folders, with the file system usage against `ARCHAPPL_STORAGE_ALARM_PERCENT` (85 by default) |

The `storage` actions need `sudo` rights, because `du` runs as root. [Health check results](health-results.md) lists the forms of the `storage path=...` lines and their status words.

## Output of the storage action

The following lines are an excerpt of `bash scripts/archappl.bash storage`, with `ARCHAPPL_STORAGE_TOP` shown as `<storage_top>` and the folders below the store roots left out:

```text
>>>> Storage Status at 2610120125

2.1M	2026-10-11 17:10	<storage_top>/lts/ArchiverStore
2.1M	2026-10-11 17:10	<storage_top>/lts
2.3M	2026-10-11 17:10	<storage_top>/mts/ArchiverStore
2.3M	2026-10-11 17:10	<storage_top>/mts
40K	2026-10-10 10:38	<storage_top>/config
28K	2026-10-11 01:05	<storage_top>/sts/ArchiverStore
32K	2026-10-11 01:05	<storage_top>/sts
4.4M	2026-10-11 17:10	<storage_top>
4.4M	2026-10-11 17:10	total
```

The header carries the time in the form `yymmddHHMM`. Each line has the size, the latest modification time in the folder, and the path. `du` prints a folder after its contents, so the last two lines are the storage top and the total.

## The placement check

When `make conf.storage` prepares the folders, `scripts/check_storage_placement.bash` reports a store that shares the root file system or lies under a user's home directory. The check only warns and always exits `0`; the placement and the size of the stores belong to the host.

The behavior comes from `scripts/archappl.bash` and `scripts/check_storage_placement.bash`.
