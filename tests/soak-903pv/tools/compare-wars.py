#!/usr/bin/env python3
"""Compare the four WARs of two builds entry by entry (name, CRC and size) and sort the differences.

Usage: compare-wars.py <dir-with-first-wars> <dir-with-second-wars>

Each directory holds mgmt.war, engine.war, etl.war and retrieval.war. The differences are sorted into
configuration files (non-class files under WEB-INF/classes), UI files and logos (ui/) and everything else
(classes, libraries, other resources). The script reads the files only and prints text.
"""

import os
import sys
import zipfile

WARS = ("mgmt", "engine", "etl", "retrieval")
CONFIG_SUFFIXES = ("properties", "py", "xml", "conf", "json", "yml", "yaml", "txt")


def entries(path):
    out = {}
    with zipfile.ZipFile(path) as archive:
        for info in archive.infolist():
            if not info.is_dir():
                out.setdefault(info.filename, []).append((info.CRC, info.file_size))
    return out


def category(name):
    if name.startswith("ui/"):
        return "UI files and logos"
    if name.startswith("WEB-INF/classes/") and not name.endswith(".class") and name.rsplit(".", 1)[-1] in CONFIG_SUFFIXES:
        return "configuration files"
    return "everything else"


def main():
    first_dir, second_dir = sys.argv[1], sys.argv[2]
    for war in WARS:
        first_path, second_path = os.path.join(first_dir, f"{war}.war"), os.path.join(second_dir, f"{war}.war")
        first, second = entries(first_path), entries(second_path)
        print(f"== {war}.war: first entries={sum(len(v) for v in first.values())} second entries={sum(len(v) for v in second.values())}; "
              f"first size={os.path.getsize(first_path)} second size={os.path.getsize(second_path)}")
        diffs = {"configuration files": [], "UI files and logos": [], "everything else": []}
        for name in sorted(set(first) | set(second)):
            if first.get(name) == second.get(name):
                continue
            if name not in second:
                kind = "only in first"
            elif name not in first:
                kind = "only in second"
            else:
                kind = "CRC or size differs"
            diffs[category(name)].append(f"   {kind}: {name}  first={first.get(name)} second={second.get(name)}")
        for label, lines in diffs.items():
            print(f"  {label}: {len(lines)}")
            for line in lines:
                print(line)


if __name__ == "__main__":
    main()
