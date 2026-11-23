#!/usr/bin/env python3
"""Condense the CSV of the resource sampler: samples, spacing, liveness and the resident set of each process.

Usage: summarize-samples.py <samples.csv>

Prints the number of rows and samples, the smallest and largest spacing between two samples, the alive values of each
process (a process identity that changes is shown by a second start_ticks value) and the resident set (first, minimum,
maximum, last) of each process in MiB and the minimum and maximum of the host MemAvailable. The script reads the file only.
"""

import collections
import csv
import sys


def main():
    with open(sys.argv[1], newline="") as handle:
        rows = list(csv.DictReader(handle))
    print("sample rows", len(rows))
    times = sorted({float(r["monotonic_s"]) for r in rows})
    gaps = [b - a for a, b in zip(times, times[1:])]
    print("samples", len(times))
    print("sample gap min/max s", round(min(gaps), 3), round(max(gaps), 3))
    alive, ticks = collections.defaultdict(set), collections.defaultdict(set)
    for r in rows:
        if r["scope"] == "process" and r["metric"] == "alive":
            alive[r["name"]].add(r["value"])
        if r["scope"] == "process" and r["metric"] == "start_ticks":
            ticks[r["name"]].add(r["value"])
    print("alive values per process", {k: sorted(v) for k, v in sorted(alive.items())})
    print("start_ticks values per process", {k: len(v) for k, v in sorted(ticks.items())})
    for name in sorted(alive):
        series = [int(r["value"]) for r in rows if r["name"] == name and r["metric"] == "rss_kib"]
        if series:
            print(name, "rss MiB first/min/max/last", round(series[0] / 1024), round(min(series) / 1024), round(max(series) / 1024), round(series[-1] / 1024))
    available = [int(r["value"]) for r in rows if r["name"] == "host" and r["metric"] == "mem_available_kib"]
    print("host MemAvailable MiB min/max", round(min(available) / 1024), round(max(available) / 1024))


if __name__ == "__main__":
    main()
