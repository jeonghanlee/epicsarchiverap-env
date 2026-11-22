#!/usr/bin/env python3
"""Register the soak PVs with the appliance in one archivePV JSON POST.

Reads pvs.csv, posts one JSON array to mgmt, and records the request time
as the zero point for first-arrival times in registered.csv.
Usage: register.py <pvs.csv> <out_dir> [out_name] [mgmt_url]
"""

import csv
import datetime
import json
import os
import sys
import urllib.request


def main():
    pvs_csv, out_dir = sys.argv[1], sys.argv[2]
    out_name = sys.argv[3] if len(sys.argv) > 3 else "registered.csv"
    mgmt = sys.argv[4] if len(sys.argv) > 4 else "http://localhost:17665/mgmt/bpl"

    with open(pvs_csv, newline="") as f:
        rows = list(csv.DictReader(f))

    body = []
    for r in rows:
        item = {"pv": r["pv"], "samplingperiod": r["period"], "samplingmethod": r["method"]}
        if r["policy"]:
            item["policy"] = r["policy"]
        body.append(item)

    req = urllib.request.Request(
        f"{mgmt}/archivePV",
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    sent = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    with urllib.request.urlopen(req, timeout=120) as resp:
        reply = json.loads(resp.read().decode())

    status = {item.get("pvName", item.get("pv")): item.get("status", "") for item in reply}
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, out_name), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["pv", "group", "method", "period", "policy", "requested_utc", "reply_status"])
        for r in rows:
            w.writerow([r["pv"], r["group"], r["method"], r["period"], r["policy"], sent,
                        status.get(r["pv"], "missing")])
    missing = sum(1 for r in rows if r["pv"] not in status)
    print(f"requested {len(rows)} PVs at {sent}; replies {len(reply)}; missing {missing}")


if __name__ == "__main__":
    main()
