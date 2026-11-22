#!/usr/bin/env python3
"""Condense evidence/soak-log.csv into the statistics of the run record.

The script reads the local log only. It prints the statistics as text and does not touch the appliance.

Usage: summarize.py [expected_pv_count] [baseline_disconnected]
"""

import csv
import datetime
import re
import statistics
import sys

LOG = "evidence/soak-log.csv"
INTERVAL_SECONDS = 600
SAMPLE_RATIO_MIN = 0.99


def number(text):
    return float(str(text).replace(",", "")) if str(text).strip() else None


def parse_time(text):
    return datetime.datetime.strptime(text, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)


def main():
    expected = int(sys.argv[1]) if len(sys.argv) > 1 else 903
    baseline_down = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    rows = list(csv.DictReader(open(LOG, newline="")))
    good = [r for r in rows if not r["error"]]
    errors = [r for r in rows if r["error"]]
    times = [parse_time(r["utc"]) for r in rows]
    print(f"window: {rows[0]['utc']} .. {rows[-1]['utc']}  cycles={len(rows)}  cycles_with_error={len(errors)}")
    gaps = [(times[i - 1], times[i], (times[i] - times[i - 1]).total_seconds()) for i in range(1, len(times))]
    long_gaps = [g for g in gaps if g[2] > 1.5 * INTERVAL_SECONDS]
    print(f"gaps over {int(1.5 * INTERVAL_SECONDS)} s: {len(long_gaps)}; longest gap {max(g[2] for g in gaps):.0f} s")
    for start, end, span in long_gaps:
        print(f"  gap {start:%H:%M:%S} .. {end:%H:%M:%S} UTC = {span:.0f} s")

    checks = {
        "C1 appliance and IOC units active, four JVMs": lambda r: r["appliance_unit"] == "active" and r["ioc_unit"] == "active" and r["tomcat_java"] == "4",
        "C2 all PVs Being archived": lambda r: number(r["being_archived"]) == expected and number(r["not_archived"]) == 0,
        "C3 connected = expected, no new disconnect": lambda r: number(r["connected"]) == expected and number(r["disconnected"]) == baseline_down,
        "C5 dropped events 0": lambda r: all(number(r[k]) == 0 for k in ("dropped_buffer", "dropped_timestamp", "dropped_type_change")),
        "C6 stale changing PVs 0": lambda r: number(r["stale_changing_pvs"]) == 0,
    }
    for name, test in checks.items():
        bad = [r["utc"] for r in good if not test(r)]
        print(f"{name}: evaluated={len(good)} violations={len(bad)}" + (f" first={bad[0]} last={bad[-1]}" if bad else ""))

    classes = {}
    cycle_bad = []
    for r in good:
        ok = True
        for item in r["samples_detail"].split(";"):
            match = re.match(r"(.+)=(\d+)/(\d+)$", item)
            if not match:
                ok = False
                continue
            name, got, want = match.group(1), int(match.group(2)), int(match.group(3))
            ratio = got / want
            classes.setdefault(name, []).append(ratio)
            ok = ok and ratio >= SAMPLE_RATIO_MIN
        if not ok:
            cycle_bad.append(r["utc"])
    print(f"C4 per cycle, six sample PVs at or above {SAMPLE_RATIO_MIN:.0%}: evaluated={len(good)} violations={len(cycle_bad)}")
    for name, ratios in sorted(classes.items()):
        print(f"  {name}: min={min(ratios):.4f} mean={statistics.mean(ratios):.4f} max={max(ratios):.4f}")

    def series(column):
        return [number(r[column]) for r in good if number(r[column]) is not None]

    for column, label in (("tomcat_rss_mb", "appliance JVM RSS MB"), ("ioc_rss_mb", "IOC RSS MB"), ("event_rate", "event rate per second")):
        values = series(column)
        print(f"{label}: start={values[0]:.0f} min={min(values):.0f} peak={max(values):.0f} mean={statistics.mean(values):.0f} end={values[-1]:.0f}")
    avail = series("disk_avail_gb")
    print(f"disk: use start={good[0]['disk_use']} end={good[-1]['disk_use']}; available GB start={avail[0]:.0f} end={avail[-1]:.0f} drop={avail[0] - avail[-1]:.0f}")
    print(f"reported data rate GB/day: last={number(good[-1]['data_gb_per_day'])}")


if __name__ == "__main__":
    main()
