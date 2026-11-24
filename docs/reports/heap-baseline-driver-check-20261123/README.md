# Checks of the 48-hour baseline driver

Checks of `tests/heap/run-baseline.pl` before it runs the 48-hour baseline: its local checks, three real runs on the guest of the rehearsals with the time scaled down, and five scratch mutants. All times are UTC. The procedure is in `tests/heap/README.md`.

## Local checks

`perl tests/heap-run-baseline.pl` runs the real driver as a subprocess: 37 checks, all passing on the final bytes. They cover the usage errors and exit statuses, the schedule against dates that `date -u -d` computes independently (each of the 13 events at the scale of 3600 seconds per hour, the whole plan at the scale of 60), the order of events that fall on the same time, the refusal of collectors that start more than half an hour before `R`, the refusal of a `run` without the service account, and the hard-linked staging by inode number and link count (a nested file, a second run, a file that appears later).

## Runs with the time scaled down

All runs used the guest of the rehearsals (appliance running, soft IOC with the 100 PVs, the 100 PVs already archived), `run` of the driver (runs 1 and 2 with `watch`, and with `R` given; run 3 with the registration and without `watch`), the sampler and the CA observer under their limits, and four query clients under 512 MiB each. Evidence is the stage record in this folder.

| Item | Run 1 (one hour is 60 s) | Run 2 (one hour is 30 s) | Run 3 (one hour is 12 s) |
| :--- | :--- | :--- | :--- |
| Start, `R` | 08:38:25Z, 08:39:24Z | 16:30:31Z, 16:30:37Z | 19:14:48Z, 19:14:48Z (registered by the run) |
| Cutoff, last block | 09:27:24Z, 09:29:18Z | 16:54:37Z, 16:57:02Z | 19:24:24Z, 19:26:55Z |
| Bytes of the driver | `626072c1e70e808429b0b5a4096b7605232eb3f5eaafa293320ed6142d73ae36` | `eb6d9456d51ede955a19ea63459096245efb9f7fdc445c6a7f7287619bd91826` | `f6c77fe4b820a12c52dae3053d578f6924c8bffb60264411d93ce74391d329e3` |
| Blocks | 9, every manifest `ok`, none skipped, exit status 0 | 9, every manifest `ok`, none skipped, exit status 0 | 9, every manifest `ok`, none skipped, exit status 0 |
| Query clients | 360 s, 694 requests, all HTTP 200, 2.75 GiB | 180 s, 342 requests, all HTTP 200, 1.31 GiB | 72 s, 132 requests, all HTTP 200 |
| Staged query files that are hard links | 698 of 698 | 346 of 346 | 136 of 136 |
| Sampler spacing | 4.994 to 5.006 s | 4.997 to 5.003 s | not read |
| Query clients started | 5 s after the plan | 0 s after the plan | 0 s after the plan |
| Cutoff marker | 19 s after the plan | 0 s after the plan | 0 s after the plan |
| Watchdog | 1 alert at 09:21:27Z, where it ended (see below) | no alert, `WATCH-END` at 16:56:52Z | not run |
| Port forward after the run | left running | left running | stopped by the run |

Defects of the driver that run 1 showed, each corrected before run 2, and one that a start of run 3 showed:

1. Events that fall on the same time ran in the order of the schedule, so the block copy of block 7 delayed the start of the query clients by 5 seconds and the block copy of block 8 delayed the cutoff marker by 19 seconds. A block copy takes minutes in the real run. The query start and the cutoff now come first.
2. The watchdog allowed the query clients one second (60 seconds scaled) to start, found the four clients inactive while block 7 was copied and ended with an `ALERT` (`watch-run1-alert.txt`). The allowance is now at least 5 seconds.
3. The collectors ended 29 seconds before the cutoff because `R` was given 59 seconds after their start, more than the half hour (scaled) of margin, and nothing noticed. `plan` and `run` now refuse a schedule whose collectors end before the cutoff.

4. The port forward of a run stayed after the run, so the next run could not create it under the same name (`Unit base-tunnel.service was already loaded`) and failed at its start. The run now stops the forward that it started, when it ends or fails, and never the forward of another run.

In run 2 the end of the collectors was recorded 2 seconds after the plan, because the block copy of block 8 (10 seconds) fell on the same time at this scale; in the real run the collectors end half an hour after the cutoff.

## Scratch mutants

Five changes of a scratch copy of the driver were run once each on the final bytes (driver `645ba8961b899933eb1cc3eac589e3e9f7ffcf8789c488db0286c20830bbac6e`, checks `01f12e326e366ddac046be18a2e0e41ee19a55bd7a0e67ce6b3462d31ccc134c`), after the unchanged driver passed all 37 checks. The failing checks were written down before the series and matched exactly; each run read the mutated file with the recorded hash.

| Mutant | Change | Failing checks (predicted and observed) |
| :--- | :--- | :--- |
| M1 | the query clients start at hour 41 instead of 42 | the `query_start` event and the whole plan at the scale of 60 (2) |
| M2 | blocks every 5 hours instead of 6 | `block_1` to `block_8`, the whole plan at the scale of 60 and the order of the query start and the cutoff before the block copy (10) |
| M3 | the staging folder gets copies instead of hard links | the shared inode, the link count of two and the link of a file that appears later (3) |
| M4 | the collectors run 0.4 hours past the cutoff instead of 0.5 | `collectors_end`, `final_block`, the whole plan at the scale of 60 and the acceptance of collectors that start 29 minutes before `R` (4) |
| M5 | `run` does not require the service account | the refusal of a `run` without the service account (1) |

M1 to M4 also ran on earlier bytes (`ca7f90c8…` and `f6c77fe4…`) with the same failing checks. M5 was added with the check of the service account. Run 2 used `eb6d9456…`; the final bytes differ from it in the stop of the port forward (run 3), in the sentence of the documentation that names the requirements (`python3`), and in the service account, which has no default any more and is a required option of `prepare` and `run`; a `prepare` with the final bytes ran against the guest after that change, and `run` with the option given takes the same path as in run 3.

## Leftover of mutant M5

M5 lets `run` start without the service account. The check of that case then starts a real `run` against a placeholder host: the port forward fails at once and leaves a failed `base-tunnel.service` unit in the user manager, which blocks the next `run` of the same prefix (`Unit base-tunnel.service was already loaded or has a fragment file`). The first start of the 48-hour run hit this. The unit is cleared with `systemctl --user reset-failed base-tunnel.service`; nothing had started on the guest. A run of the mutant series is followed by that command.

## What these checks do not cover

The registration was exercised by run 3 only on PVs that were already archived (all 100 reported `Being archived` 0.24 s after the request), so the wait loop with PVs that are not yet archived, and the registration on the empty guest, have not run; the real durations of the blocks (the copy of about 127 GiB of query responses and 7 GiB of CA output, and the re-reading of the earlier bytes of every file by `copy-block.pl`); the port forward and the collectors on the empty guest of the baseline; and a restart of a collector under the resume rule, which the driver leaves to the operator.
