#!/usr/bin/env python3
"""Condense the CPU columns of the collector log: load average and CPU time of the appliance JVMs and the IOC.

Usage: cpu-stats.py [evidence/soak-log.csv]

CPU time is in clock ticks (100 per second) summed over the processes. The use of a process group is the
increase of its CPU time divided by the time between two cycles, in vCPU. The script reads the log only.
"""

import csv
import datetime
import statistics
import sys

TICKS_PER_SECOND = 100


def parse_time(text):
    return datetime.datetime.strptime(text, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "evidence/soak-log.csv"
    with open(path, newline="") as handle:
        rows = list(csv.DictReader(handle))
    print("rows", len(rows), rows[0]["utc"], rows[-1]["utc"])
    for key in ("loadavg_1m", "loadavg_5m", "loadavg_15m"):
        values = [float(r[key]) for r in rows]
        print(key, "min", min(values), "mean", round(statistics.mean(values), 2), "max", max(values), "first", values[0], "last", values[-1])
    values = [float(r["loadavg_1m"]) for r in rows]
    print("max loadavg_1m at", rows[values.index(max(values))]["utc"])
    for key in ("tomcat_cpu_ticks", "ioc_cpu_ticks"):
        ticks = [int(r[key]) for r in rows]
        span = (parse_time(rows[-1]["utc"]) - parse_time(rows[0]["utc"])).total_seconds()
        total = (ticks[-1] - ticks[0]) / TICKS_PER_SECOND
        per_interval = [(b - a) / TICKS_PER_SECOND / (parse_time(rows[i + 1]["utc"]) - parse_time(rows[i]["utc"])).total_seconds()
                        for i, (a, b) in enumerate(zip(ticks, ticks[1:]))]
        print(key, "first", ticks[0], "last", ticks[-1], "never decreases", all(b >= a for a, b in zip(ticks, ticks[1:])),
              "cpu_seconds", total, "span_s", span, "mean_vcpu", round(total / span, 3),
              "interval_vcpu min/mean/max", round(min(per_interval), 3), round(statistics.mean(per_interval), 3), round(max(per_interval), 3))


if __name__ == "__main__":
    main()
