#!/usr/bin/env python3
"""Poll getPVStatus for the soak PV list until every PV is being archived or the time is up."""
import collections
import json
import sys
import time
import urllib.request

MGMT = "http://localhost:17665/mgmt/bpl"
names = [line.strip() for line in open("pvnames.txt") if line.strip()]
deadline = time.time() + float(sys.argv[1])
while True:
    req = urllib.request.Request(f"{MGMT}/getPVStatus", data=json.dumps(names).encode(),
                                 headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=120) as resp:
        reply = json.loads(resp.read().decode())
    counts = collections.Counter(item.get("status", "?") for item in reply)
    print(time.strftime("%H:%M:%S"), dict(counts), flush=True)
    if counts.get("Being archived", 0) == len(names) or time.time() > deadline:
        break
    time.sleep(15)
