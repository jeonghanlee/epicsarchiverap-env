#!/usr/bin/env python3
"""Condense the request files of the query clients of a rehearsal.

Usage: summarize-queries.py <folder with requests-<client>.csv>

Prints the number of requests, the HTTP statuses, the errors, the window mix, the elapsed time (minimum, median, 99th
percentile, maximum), the response volume and the three largest responses. The script reads the files only.
"""

import collections
import csv
import glob
import os
import statistics
import sys


def main():
    rows = []
    for path in sorted(glob.glob(os.path.join(sys.argv[1], "requests-*.csv"))):
        with open(path, newline="") as handle:
            rows += list(csv.DictReader(handle))
    print("requests", len(rows))
    print("http", dict(collections.Counter(r["http"] for r in rows)))
    print("errors", sum(1 for r in rows if r["error"]), "windows", dict(collections.Counter(r["window"] for r in rows)))
    ms = [int(r["ms"]) for r in rows]
    print("ms min/median/p99/max", min(ms), statistics.median(ms), sorted(ms)[int(0.99 * len(ms))], max(ms))
    sizes = [int(r["bytes"]) for r in rows]
    print("bytes total GiB", round(sum(sizes) / 2**30, 2), "max MiB", round(max(sizes) / 2**20, 1))
    for r in sorted(rows, key=lambda r: -int(r["bytes"]))[:3]:
        print("  largest", r["pv"], r["window"], r["bytes"], r["ms"], r["http"])
    print("first", min(r["time_utc"] for r in rows), "last", max(r["time_utc"] for r in rows))


if __name__ == "__main__":
    main()
