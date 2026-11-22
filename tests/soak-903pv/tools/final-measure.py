#!/usr/bin/env python3
"""One-shot read-only measurements at the end of the 903-PV run.

Usage: final-measure.py <window_start_utc> <window_end_utc> [--sample-only]

The script reads through the retrieval and management web interfaces, the store folders and the process table.
It writes nothing outside the standard output.
"""

import csv
import datetime
import http.client
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse

RETRIEVAL = "http://localhost:17668/retrieval/data/getData.json"
MGMT = "http://localhost:17665/mgmt/bpl"
SAMPLE_PVS = ["AASOAK:L1:CH001", "AASOAK:L2:CH300", "AASOAK:FAST:CH01", "AASOAK:L2F:CH100",
              "AASOAK:SLOW:CH01", "AASOAK:L2WF:CH01"]
OTHER_PVS = ["AASOAK:L1:CH100", "AASOAK:L1:CH400", "AASOAK:L2:CH001", "AASOAK:L2:CH150", "AASOAK:L2F:CH001",
             "AASOAK:L2F:CH050", "AASOAK:L2WF:CH02", "AASOAK:L2WF:CH03", "AASOAK:FAST:CH10", "AASOAK:SLOW:CH10"]
RATIO_MIN = 0.99
STORES = (("STS", "/arch/sts/ArchiverStore"), ("MTS", "/arch/mts/ArchiverStore"), ("LTS", "/arch/lts/ArchiverStore"))


def stamp(moment):
    return moment.strftime("%Y-%m-%dT%H:%M:%SZ")


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc)


def parse(text):
    return datetime.datetime.strptime(text, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)


def get_json(url):
    import urllib.request
    with urllib.request.urlopen(url, timeout=60) as resp:
        return json.loads(resp.read().decode())


def retrieval_rss_mb():
    """Resident memory of the processes of the user tomcat whose command line names the retrieval instance."""
    out = subprocess.run(["ps", "-u", "tomcat", "-o", "rss=,args="], capture_output=True, text=True).stdout
    total = 0
    for line in out.splitlines():
        rss, _, args = line.strip().partition(" ")
        if re.search(r"/retrieval(/|\s|$)", args) and "java" in args:
            total += int(rss)
    return round(total / 1024)


def count_events(pv, start, end):
    """Stream one retrieval and count the events without keeping the body."""
    query = urllib.parse.urlencode({"pv": pv, "from": stamp(start).replace("Z", ".000Z"), "to": stamp(end).replace("Z", ".000Z")})
    parts = urllib.parse.urlsplit(RETRIEVAL)
    conn = http.client.HTTPConnection(parts.hostname, parts.port, timeout=900)
    began = time.monotonic()
    result = {"pv": pv, "status": None, "events": 0, "bytes": 0, "complete": False, "seconds": None, "error": ""}
    try:
        conn.request("GET", parts.path + "?" + query)
        resp = conn.getresponse()
        result["status"] = resp.status
        token = b'"secs"'
        tail = b""
        last = b""
        while True:
            chunk = resp.read(1 << 20)
            if not chunk:
                break
            result["bytes"] += len(chunk)
            data = tail + chunk
            result["events"] += data.count(token)
            tail = data[-(len(token) - 1):]
            last = (last + chunk)[-16:]
        result["complete"] = resp.status == 200 and last.rstrip().endswith(b"]")
    except Exception as error:  # a refused or cut retrieval is an observation
        result["error"] = f"{type(error).__name__}: {error}"[:160]
    finally:
        conn.close()
    result["seconds"] = round(time.monotonic() - began, 1)
    return result


def report_retrieval(label, pvs, start, end, table):
    seconds = (end - start).total_seconds()
    print(f"--- {label}: window {stamp(start)} .. {stamp(end)} ({seconds:.0f} s)")
    for pv in pvs:
        expected = seconds / float(table[pv]["period"])
        r = count_events(pv, start, end)
        ratio = r["events"] / expected if expected else 0
        verdict = "ok" if r["status"] == 200 and r["complete"] and ratio >= RATIO_MIN else "CHECK"
        print(f"  {stamp(utc_now())} {pv} status={r['status']} complete={r['complete']} events={r['events']} "
              f"expected={expected:.0f} ratio={ratio:.4f} MB={r['bytes'] / 1048576:.1f} s={r['seconds']} {verdict} {r['error']}")


def folders(table):
    print("--- (c) store folders of the sample PVs (STS, MTS, LTS)")
    for pv in SAMPLE_PVS:
        key = table[pv]["store_key"]
        directory, base = os.path.dirname(key), os.path.basename(key)
        for name, root in STORES:
            path = os.path.join(root, directory)
            try:
                files = sorted(f for f in os.listdir(path) if f.startswith(base + ":"))
                size = sum(os.path.getsize(os.path.join(path, f)) for f in files)
                span = f"{files[0]} .. {files[-1]}" if files else "none"
                print(f"  {pv} {name}: files={len(files)} bytes={size} {span}")
            except OSError as error:
                print(f"  {pv} {name}: not readable ({error.__class__.__name__})")
    ident = get_json(MGMT + "/getApplianceInfo")["identity"]
    print("  storage metrics:", json.dumps(get_json(f"{MGMT}/getStorageMetricsForAppliance?appliance={ident}")))


def last_hour_all(table):
    end = utc_now().replace(minute=0, second=0, microsecond=0)
    start = end - datetime.timedelta(hours=1)
    print(f"--- (e) all {len(table)} PVs, last closed hour {stamp(start)} .. {stamp(end)} observed from {stamp(utc_now())}")
    below, deadband = [], []
    for pv, row in table.items():
        r = count_events(pv, start, end)
        expected = 3600.0 / float(row["period"])
        if row["group"] == "deadband":
            deadband.append((pv, r["events"]))
            continue
        if r["status"] != 200 or r["events"] / expected < RATIO_MIN:
            below.append((pv, r["events"], round(expected), r["status"]))
    print(f"  PVs below {RATIO_MIN:.0%} (period rule): {len(below)}")
    for item in below:
        print("   ", item)
    print(f"  deadband group (change-driven, no period rule): {len(deadband)} PVs, events min={min(e for _, e in deadband)} max={max(e for _, e in deadband)}")


def main():
    start, end = parse(sys.argv[1]), parse(sys.argv[2])
    sample_only = "--sample-only" in sys.argv
    table = {r["pv"]: r for r in csv.DictReader(open("pvs-all.csv", newline=""))}
    print(f"observation start {stamp(utc_now())}")
    print("versions:", json.dumps(get_json(MGMT + "/getVersions")))
    print("appliance:", get_json(MGMT + "/getApplianceInfo")["version"])
    print(f"retrieval RSS before: {retrieval_rss_mb()} MB at {stamp(utc_now())}")
    report_retrieval("(a) six sample PVs", SAMPLE_PVS, start, end, table)
    if not sample_only:
        report_retrieval("(b) ten more PVs", OTHER_PVS, start, end, table)
    print(f"retrieval RSS after: {retrieval_rss_mb()} MB at {stamp(utc_now())}")
    if not sample_only:
        folders(table)
        last_hour_all(table)
    print(f"observation end {stamp(utc_now())}")


if __name__ == "__main__":
    main()
