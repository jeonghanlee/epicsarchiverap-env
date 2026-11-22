#!/usr/bin/env python3
"""Record the state of the appliance and the soak IOC at a fixed interval until a deadline.

Every cycle appends one row to evidence/soak-log.csv and writes the full detail of the cycle to
evidence/cycle-<utc>.json. The script only reads: management and retrieval HTTP requests, the process
table, the unit states and the disk usage.

Usage: collect.py <until_utc_iso> <interval_seconds>
"""

import collections
import csv
import datetime
import json
import os
import subprocess
import sys
import time
import urllib.request

MGMT = "http://localhost:17665/mgmt/bpl"
RETRIEVAL = "http://localhost:17668/retrieval/data/getData.json"
EVIDENCE = "evidence"
PV_LIST = "pvnames.txt"
PV_TABLE = "pvs-all.csv"
SAMPLE_PVS = ["AASOAK:L1:CH001", "AASOAK:L2:CH300", "AASOAK:FAST:CH01", "AASOAK:L2F:CH100",
              "AASOAK:SLOW:CH01", "AASOAK:L2WF:CH01"]
CHANGING_PREFIXES = ("AASOAK:L1:", "AASOAK:L2:", "AASOAK:L2F:", "AASOAK:L2WF:", "AASOAK:FAST:", "AASOAK:SLOW:")
STALE_SECONDS = 60
WINDOW_SECONDS = 600
SETTLE_SECONDS = 120
COLUMNS = ["utc", "appliance_unit", "ioc_unit", "tomcat_java", "connected", "disconnected", "pv_count",
           "event_rate", "data_gb_per_day", "status", "being_archived", "not_archived", "dropped_buffer",
           "dropped_timestamp", "dropped_type_change", "stale_changing_pvs", "disk_use", "disk_avail_gb",
           "tomcat_rss_mb", "ioc_rss_mb", "loadavg_1m", "loadavg_5m", "loadavg_15m", "tomcat_cpu_ticks", "ioc_cpu_ticks",
           "samples_ok", "samples_detail", "error"]


def http_json(url, body=None, timeout=60):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, method="GET" if body is None else "POST",
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode() or "null")


def run(cmd):
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    return out.stdout.strip()


def rss_mb(pids):
    total = 0
    for pid in pids:
        text = run(["ps", "-o", "rss=", "-p", pid])
        total += int(text) if text.isdigit() else 0
    return round(total / 1024)


def cpu_ticks(pids):
    """Sum of utime and stime (clock ticks) of the processes, read from /proc/PID/stat."""
    total = 0
    for pid in pids:
        try:
            with open(f"/proc/{pid}/stat") as handle:
                fields = handle.read().rsplit(") ", 1)[1].split()
        except (OSError, IndexError):
            continue
        total += int(fields[11]) + int(fields[12])
    return total


def loadavg():
    with open("/proc/loadavg") as handle:
        return handle.read().split()[:3]


def utc(moment):
    return moment.strftime("%Y-%m-%dT%H:%M:%S.000Z")


def stale_changing_pvs():
    """PVs whose value must change at least once in STALE_SECONDS but whose last event is older."""
    listed = http_json(f"{MGMT}/getSilentPVsReport?limit=2000")
    local_now = datetime.datetime.now()
    stale = []
    for item in listed:
        name = item.get("pvName", "")
        if not name.startswith(CHANGING_PREFIXES):
            continue
        try:
            last = datetime.datetime.strptime(item["lastKnownEvent"].rsplit(" ", 1)[0], "%b/%d/%Y %H:%M:%S")
            age = (local_now - last).total_seconds()
        except (KeyError, ValueError):
            age = float("inf")
        if age > STALE_SECONDS:
            stale.append(name)
    return stale


def window_samples(table, now):
    end = now - datetime.timedelta(seconds=SETTLE_SECONDS)
    start = end - datetime.timedelta(seconds=WINDOW_SECONDS)
    detail = {}
    for pv in SAMPLE_PVS:
        period = float(table[pv])
        expected = WINDOW_SECONDS / period
        reply = http_json(f"{RETRIEVAL}?pv={pv}&from={utc(start)}&to={utc(end)}", timeout=120)
        got = len(reply[0]["data"]) if reply else 0
        detail[pv] = {"period": period, "expected": expected, "got": got, "ratio": round(got / expected, 4)}
    return detail


def cycle(names, table, now):
    row = {col: "" for col in COLUMNS}
    row["utc"] = now.strftime("%Y-%m-%dT%H:%M:%SZ")
    snapshot = {"utc": row["utc"]}
    row["appliance_unit"] = run(["systemctl", "is-active", "epicsarchiverap-maven.service"])
    row["ioc_unit"] = run(["systemctl", "--user", "is-active", "epics-@aasoak-soak.service"])
    java = run(["pgrep", "-u", "tomcat", "java"]).split()
    row["tomcat_java"] = len(java)
    row["tomcat_rss_mb"] = rss_mb(java)
    ioc = run(["pgrep", "-u", os.environ.get("USER", ""), "-f", "softIocPVX ./st.cmd"]).split()
    row["ioc_rss_mb"] = rss_mb(ioc[-1:]) if ioc else 0
    row["tomcat_cpu_ticks"] = cpu_ticks(java)
    row["ioc_cpu_ticks"] = cpu_ticks(ioc[-1:]) if ioc else 0
    row["loadavg_1m"], row["loadavg_5m"], row["loadavg_15m"] = loadavg()
    disk = run(["df", "--output=pcent,avail", "-BG", "/arch"]).splitlines()[-1].split()
    row["disk_use"], row["disk_avail_gb"] = disk[0], disk[1].rstrip("G")
    metrics = http_json(f"{MGMT}/getApplianceMetrics")[0]
    snapshot["metrics"] = metrics
    row["connected"] = metrics.get("connectedPVCount")
    row["disconnected"] = metrics.get("disconnectedPVCount")
    row["pv_count"] = metrics.get("pvCount")
    row["event_rate"] = metrics.get("eventRate")
    row["data_gb_per_day"] = metrics.get("dataRateGBPerDay")
    row["status"] = metrics.get("status")
    counts = collections.Counter(item.get("status", "?") for item in http_json(f"{MGMT}/getPVStatus", names))
    snapshot["status_counts"] = dict(counts)
    row["being_archived"] = counts.get("Being archived", 0)
    row["not_archived"] = len(names) - counts.get("Being archived", 0)
    for column, endpoint in (("dropped_buffer", "getPVsByDroppedEventsBuffer"),
                             ("dropped_timestamp", "getPVsByDroppedEventsTimestamp"),
                             ("dropped_type_change", "getPVsByDroppedEventsTypeChange")):
        listed = http_json(f"{MGMT}/{endpoint}?limit=1000")
        snapshot[endpoint] = listed
        row[column] = len(listed)
    stale = stale_changing_pvs()
    snapshot["stale_changing_pvs"] = stale
    row["stale_changing_pvs"] = len(stale)
    detail = window_samples(table, now)
    snapshot["window_samples"] = detail
    row["samples_ok"] = sum(1 for v in detail.values() if v["ratio"] >= 0.98)
    row["samples_detail"] = ";".join(f"{pv.split(':', 1)[1]}={v['got']}/{int(v['expected'])}" for pv, v in detail.items())
    return row, snapshot


def main():
    until = datetime.datetime.strptime(sys.argv[1], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
    interval = int(sys.argv[2])
    names = [line.strip() for line in open(PV_LIST) if line.strip()]
    with open(PV_TABLE, newline="") as handle:
        table = {r["pv"]: r["period"] for r in csv.DictReader(handle)}
    os.makedirs(EVIDENCE, exist_ok=True)
    log = os.path.join(EVIDENCE, "soak-log.csv")
    if not os.path.exists(log):
        with open(log, "w", newline="") as handle:
            csv.DictWriter(handle, COLUMNS).writeheader()
    while True:
        now = datetime.datetime.now(datetime.timezone.utc)
        if now > until:
            break
        try:
            row, snapshot = cycle(names, table, now)
        except Exception as error:  # a failed cycle is data: keep the error in the row and go on
            row = {col: "" for col in COLUMNS}
            row["utc"] = now.strftime("%Y-%m-%dT%H:%M:%SZ")
            row["error"] = f"{type(error).__name__}: {error}"[:200]
            snapshot = {"utc": row["utc"], "error": row["error"]}
        with open(log, "a", newline="") as handle:
            csv.DictWriter(handle, COLUMNS).writerow(row)
        stamp = row["utc"].replace(":", "").replace("-", "")
        with open(os.path.join(EVIDENCE, f"cycle-{stamp}.json"), "w") as handle:
            json.dump(snapshot, handle, indent=1)
        time.sleep(max(1, interval - (datetime.datetime.now(datetime.timezone.utc) - now).total_seconds()))


if __name__ == "__main__":
    main()
