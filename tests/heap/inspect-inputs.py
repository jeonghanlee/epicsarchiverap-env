#!/usr/bin/env python3
"""Inspect preserved soak inputs without executing tools or contacting a VM."""

import argparse
from collections import Counter
import csv
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys


FIXTURE_SHA256 = "037a92691bc23a6dcac37ec3613ad19c9f80b93b689209ec8dc403b519eaf594"
SOURCE_DIRECTORY = "tests/archiver-soak"
CSV_FILES = ("pvs.csv", "pvs-load1.csv", "pvs-load2.csv")
REQUIRED_FILES = (
    "baseline/gen_soak.py", "baseline/gen_load.py",
    "baseline/register.py", "baseline/load_retrieval.py",
    "baseline/store-test.yml",
    "fixtures/aasoak.db", "fixtures/load1.db", "fixtures/load2.db",
    "fixtures/pvs.csv", "fixtures/pvs-load1.csv",
    "fixtures/pvs-load2.csv", "fixtures/pvs-all.csv",
)
CSV_FIELDS = ("pv", "group", "scan", "method", "period", "policy", "store_key")
STAGES = (
    (100, {"1.0": 80, "0.1": 10, "10.0": 10}, 5, 24),
    (500, {"1.0": 480, "0.1": 10, "10.0": 10}, 5, 6),
    (903, {"1.0": 783, "0.1": 110, "10.0": 10}, 8, 27),
)


def git(repository, *arguments):
    result = subprocess.run(
        ["git", "-C", str(repository), *arguments],
        check=True, capture_output=True, text=True,
    )
    return result.stdout.strip()


def digest(path):
    checksum = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(65536), b""):
            checksum.update(block)
    return checksum.hexdigest()


def read_csv(path):
    with path.open(newline="", encoding="utf-8") as stream:
        reader = csv.DictReader(stream)
        if reader.fieldnames != list(CSV_FIELDS):
            raise ValueError("Unexpected CSV columns: " + path.name)
        rows = list(reader)
    if not rows or any(set(row) != set(CSV_FIELDS) or
                       any(value is None for value in row.values()) for row in rows):
        raise ValueError("Incomplete CSV input: " + path.name)
    return rows


def inspect(repository, source_ref):
    if not re.fullmatch(r"[0-9a-f]{40}", source_ref):
        raise ValueError("Source ref must be a full lowercase commit ID")
    if git(repository, "rev-parse", "HEAD") != source_ref:
        raise ValueError("Ansible HEAD does not match the requested source ref")
    if git(repository, "status", "--porcelain", "--untracked-files=all",
           "--", SOURCE_DIRECTORY):
        raise ValueError("Preserved soak source directory is dirty")
    root = repository / SOURCE_DIRECTORY
    checksum_path = root / "SHA256SUMS"
    if not git(repository, "ls-files", "--", SOURCE_DIRECTORY + "/SHA256SUMS"):
        raise ValueError("Checksum list is not tracked")
    recorded = {}
    for line in checksum_path.read_text(encoding="ascii").splitlines():
        match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
        if not match or match[2] in recorded:
            raise ValueError("Invalid or duplicate checksum entry")
        recorded[match[2]] = match[1]
    hashes = {}
    for name in REQUIRED_FILES:
        path = root / name
        if path.is_symlink() or not path.is_file():
            raise ValueError("Missing regular source file: " + name)
        actual = digest(path)
        if recorded.get(name) != actual:
            raise ValueError("Source checksum mismatch: " + name)
        hashes[name] = actual
    if hashes["fixtures/pvs-all.csv"] != FIXTURE_SHA256:
        raise ValueError("Combined fixture differs from the original soak")
    rows_all = read_csv(root / "fixtures/pvs-all.csv")
    cumulative = []
    stages = []
    for filename, (total, periods, waves, hours) in zip(CSV_FILES, STAGES):
        cumulative.extend(read_csv(root / "fixtures" / filename))
        actual_periods = dict(Counter(row["period"] for row in cumulative))
        actual_waves = sum(row["group"] in ("wave", "load2wave") for row in cumulative)
        if len(cumulative) != total or actual_periods != periods or actual_waves != waves:
            raise ValueError("Stage population differs from the accepted plan")
        stages.append({"registered_pvs": total, "periods": actual_periods,
                       "waveform_pvs": actual_waves, "observation_hours": hours})
    if cumulative != rows_all:
        raise ValueError("Combined fixture does not match the ordered increments")
    for column in ("pv", "store_key"):
        if len({row[column] for row in rows_all}) != len(rows_all):
            raise ValueError("Duplicate fixture identity: " + column)
    return {
        "schema": 1,
        "ansible_commit": source_ref,
        "source_directory": SOURCE_DIRECTORY,
        "checksum_list_sha256": digest(checksum_path),
        "file_sha256": hashes,
        "stages": stages,
        "registration_methods": dict(Counter(row["method"] for row in rows_all)),
        "execution_ready": False,
        "unverified_inputs": [
            "original installed policy and ETL properties",
            "original effective per-PV store URLs and post-processing",
            "accepted resource limits, client placement and evidence storage",
            "accepted analysis settings and published run source refs",
        ],
        "runtime_verification": "Not run",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ansible-repository", required=True, type=Path)
    parser.add_argument("--source-ref", required=True)
    args = parser.parse_args()
    try:
        result = inspect(args.ansible_repository.resolve(), args.source_ref)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print("INCOMPLETE: " + str(error), file=sys.stderr)
        return 77
    json.dump(result, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
