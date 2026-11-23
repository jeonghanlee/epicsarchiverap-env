# Settings of the 48-hour heap baseline

Status: accepted by the owner on 2026-11-23 as written below, with the condition that the values are not changed from baseline or candidate outcomes and apply unchanged to both runs. The values are not measured safe limits; each was derived from the 2-hour and 8-hour rehearsals (`docs/reports/heap-rehearsal-20261122`) and from their retained GC logs. The baseline needs its own authorization after the appliance is installed on the new guest and its collection driver exists.

## Observed behavior that the settings rest on

All numbers are the median heap after a Young collection in MiB. The GC logs of the 8-hour rehearsal cover the whole life of the JVMs (start 06:50:13Z; readiness of the 100 PVs at 07:48:23Z, uptime 0.97 h).

| Uptime (h) | mgmt | engine | etl | retrieval | Condition |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 0 to 1 | 36 | 33.5 | 32.5 | 31 | start and registration |
| 1 to 2 | 66 | 38 | 31.5 | 31 | after readiness |
| 2 to 3 | 65.5 | 39 | 31 | 40 | 40 minutes of query load (2-hour run) |
| 4 to 5 | 64 | 39 | 32 | 38 | no query |
| 5 to 10 | 63 to 64 | 39 | 32 to 35.5 | 38 | no query |
| 10 to 15 | 64 | 40 | 32 to 35.5 | 38 | no query |
| 15 to 16 | 63 | 40 | 32 | 43 | query hour of the 8-hour run, first quarter hour 43 |
| 16 to 17 | 63 | 40 | 32 | 29 | query hour, remainder |
| 17 to 18 | 63 | 40 | 32 | 28 | no query again |

- mgmt rises to 66 at registration and settles at 63 to 64 about 5 hours after readiness. engine rises from 38 to 40 between uptime 1 and 10 hours and is flat at 40 afterwards.
- The heap after collection is in whole MiB, so a bin median has a resolution of 0.5 MiB. The largest difference between any two bin medians of the no-query series, which use bins of 1.25 hours or less, is 1 MiB (mgmt 64 to 63, engine 37 to 38).
- etl has an hourly median of 35.5 MiB in two hours (uptime 6 to 7 and 10 to 11, four events each) against 32 in the others, so an etl bin of about 5 events can differ from its neighbors by 3.5 MiB without growth. The 2 MiB tolerance rests on the 5-hour no-query series, whose etl bins all had a median of 32; the rule that both tolerances must be exceeded applies unchanged to an etl change above 2 MiB in the 5-hour query interval.
- retrieval depends on its query history: it stayed at 38 after the first query period (31 before it) and was 28 to 29 after the second. The order of the baseline therefore stays no-query interval first, queries last, on a JVM that has not served queries before.
- Events per hour without query: engine about 35, mgmt about 7.5, etl 4, retrieval 4.6. retrieval had 2,241 Young collections in one query hour.
- Query load of four clients (two seconds between requests, 100 PVs): 21.2 GiB of responses per hour (the 2-hour run: 11.3 GiB per hour at 40 minutes of load).

## Observation schedule

`R` is the time at which all 100 PVs report `Being archived`.

| Part | From | To | Remark |
| :--- | :--- | :--- | :--- |
| Warm-up after readiness | R | R + 6 h | excluded from trend calculations; raw events retained |
| No-query comparison interval | R + 6 h | R + 42 h | 36 hours of constant load (the plan's minimum is 120 minutes) |
| Query phase | R + 42 h | R + 48 h | four clients, `--pause 2`, continuous, started by a timer with `AccuracySec=1s` |
| Warm-up after query onset | R + 42 h | R + 43 h | excluded |
| Query comparison interval | R + 43 h | R + 48 h | 5 hours |
| Evidence blocks | every 6 hours from R + 6 h to the cutoff | | block copy with the resume rule; the collectors start before R and run to R + 48 h |

The GC logs, the sampler and the CA observer run from the start of the appliance. The cutoff R + 48 h is fixed; a shortened interval leaves its coverage incomplete (plan rule). The 36-hour no-query interval is chosen so that every JVM has at least 5 events in each of four bins (etl: 36 events in 9 hours per bin expected at 4 per hour); the 120-minute minimum gives etl, mgmt and retrieval fewer than 5 events per bin, which the 2-hour rehearsal confirms (bins of 0 to 2 events).

## Analysis settings

| Setting | Accepted value | Rationale |
| :--- | :--- | :--- |
| Warm-up after readiness | 6 hours | mgmt needs about 5 hours to settle after registration |
| Warm-up after query onset | 1 hour | in the 8-hour run the first quarter hour of the query hour (43 MiB) differs from the rest (29 MiB); in the 2-hour run the first 10 minutes differ from the rest by 1 MiB |
| Required GC type per component | Young for all four JVMs | Young events occur in every JVM at every interval; Mixed, Remark and Cleanup events are rare (mgmt one Mixed event in 5 hours) and are reported without being required |
| Minimum events per bin | 5 | the default of `analyze-gc.pl`; expected 315 (engine), 68 (mgmt), 36 (etl), 41 (retrieval) per 9-hour bin of the no-query interval; in the 5-hour query interval etl expects about 5 per bin and may be inconclusive |
| Heap-change tolerance (`--tolerance-mib`) | 2 MiB | twice the 1 MiB largest difference seen in stationary rehearsal series; the last-bin minus first-bin median must exceed it |
| Growth-rate tolerance (`--tolerance-mib-per-hour`) | 0.5 MiB per hour | a slope that adds 24 MiB over the 48-hour window, about 60 percent of the engine's median after collection; a single 1 MiB step already gives a slope of 1.14 MiB per hour in the 63-minute no-query interval of the 2-hour run (engine) and about 0.03 in 36 hours, which is why the change tolerance is required in addition |

Continuing growth is present only when both tolerances are exceeded (plan rule). The same accepted settings apply to the baseline and to the candidate repeat. The rehearsals are short, so the variability behind the two tolerances comes from three no-query intervals (63 minutes, 5 hours and 2 hours); the values are not derived from any baseline outcome.

## Evidence volume for 48 hours

| Item | Estimate | Basis |
| :--- | :--- | :--- |
| Query responses | 127 GiB | 21.2 GiB per hour for 6 hours; the client stores every response |
| CA observer output | 6.6 GiB | 1,189,203,956 bytes in 8 hours |
| Sampler CSV | about 0.14 GB | 17.6 MB per 6 hours |
| GC logs | tens of MB | 7.2 MB for the 8-hour rehearsal with 2 query hours |
| Copies | 3 times the query and CA data | the rehearsal kept the query files, the staging folder and the block tree (22, 23 and 23 GB for one query hour); the peak would be about 400 GiB |

The envelope of the plan is 752 GiB and the stop rule needs 200 GiB free. The peak drops to about two copies when the staging folder hard-links the query files instead of copying them (the procedure says link; the 8-hour driver copied). The owner decided both the staging method and the deletion of the response bodies after the analysis (see Decisions taken).

## Decisions taken

1. The schedule is accepted: 36 hours without query, 6 hours of queries, 6-hour warm-up, 1-hour query warm-up.
2. The two tolerances (2 MiB and 0.5 MiB per hour) and the minimum of 5 events per bin are accepted.
3. The staging folder holds the query files by hard link, and the response bodies are deleted after the analysis; their hashes and the request records are kept.
