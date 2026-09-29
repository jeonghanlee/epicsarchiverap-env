#!/usr/bin/env python3
"""Compare the real install target against two supplied build artifact sets."""

import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile


TOP = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("old_target", type=Path)
parser.add_argument("new_target", type=Path)
parser.add_argument("--old-log4j", type=Path, required=True)
args = parser.parse_args()
workspace = Path(tempfile.mkdtemp(prefix="aa-reinstall-"))
root = workspace / "checkout"
root.mkdir()
print(f"Workspace: {workspace}", flush=True)
paths = subprocess.check_output(
    ["git", "-C", str(TOP), "ls-files", "-z", "--cached", "--others", "--exclude-standard"]
).decode().split("\0")
for name in paths:
    if name == "Makefile" or name.startswith(("configure/", "scripts/", "site-template/")):
        if (TOP / name).is_file():
            dest = root / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(TOP / name, dest)
install = workspace / "installed"
make = ["make", "--no-print-directory", "-s", "-C", str(root), "SUDO=",
        f"AA_USERID={os.getuid()}", f"AA_GROUPID={os.getgid()}", f"AA_INSTALL_LOCATION={install}"]


def digest(path):
    checksum = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            checksum.update(chunk)
    return checksum.hexdigest()


def run(*arguments, expected=0):
    result = subprocess.run(make + list(arguments), capture_output=True, text=True, timeout=120)
    with (workspace / "run.log").open("a") as log:
        log.write(f"exit={result.returncode}\n{result.stdout}{result.stderr}")
    if result.returncode != expected:
        raise AssertionError(f"make exit {result.returncode}, expected {expected}: {result.stderr}")
    return result


run("conf.context")
old_log4j = workspace / "old-log4j"
old_log4j.mkdir()
for jar in args.old_log4j.glob("log4j-*.jar"):
    shutil.copyfile(jar, old_log4j / jar.name)
assert list(old_log4j.glob("*.jar")), "Real old log4j JARs are required"
services = ("mgmt", "engine", "etl", "retrieval")
protected = {}
storage = workspace / "storage/config/database.sqlite"
storage.parent.mkdir(parents=True)
storage.write_bytes(b"filesystem preservation marker")
protected[storage] = storage.read_bytes()
for service in services:
    for index, (target, log4j) in enumerate(((args.old_target, old_log4j),
                                           (args.new_target, args.new_target / "tomcat-log4j"))):
        war = list(target.glob(f"*{service}.war"))
        assert len(war) == 1, "Each target must contain exactly one real WAR per service"
        print(f"WAR {war[0]} sha256={digest(war[0])}", flush=True)
        run(f"install.{service}", f"ARCHAPPL_WARS_TARGET_PATH={target.resolve()}",
            f"ARCHAPPL_TOMCAT_LOG4J_PATH={log4j.resolve()}")
        # Only filesystem boundary fixtures are synthetic; both deployed WARs
        # and the old/new JAR sets are real build artifacts.
        if index == 0:
            for relative in ("logs/operator.log", "conf/operator.conf", "log4j/operator.xml",
                             "work/operator.cache", "temp/operator.pid", "webapps/other/index.html"):
                path = install / service / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("preserved operator state\n")
                protected[path] = path.read_bytes()

    war = next(args.new_target.glob(f"*{service}.war"))
    destination = install / service / "webapps" / service
    with zipfile.ZipFile(war) as archive:
        entries = {entry.filename for entry in archive.infolist() if not entry.is_dir()}
        actual = {str(path.relative_to(destination)) for path in destination.rglob("*") if path.is_file()}
        stale = sorted(actual - entries)
        missing = sorted(entries - actual)
        mismatched = [name for name in sorted(entries & actual)
                      if (destination / name).read_bytes() != archive.read(name)]
    expected_jars = {path.name for path in (args.new_target / "tomcat-log4j").glob("*.jar")}
    actual_jars = {path.name for path in (install / service / "log4j").glob("*.jar")}
    print(f"{service}: stale WAR files={len(stale)}; missing={len(missing)}; mismatched={len(mismatched)}")
    print(f"{service}: stale logging JARs={sorted(actual_jars - expected_jars)}", flush=True)
    assert not stale and not missing and not mismatched, stale
    assert actual_jars == expected_jars
    for name in expected_jars:
        assert (install / service / "log4j" / name).read_bytes() == (args.new_target / "tomcat-log4j" / name).read_bytes()
    assert not list((install / service).glob(".payload.*")), "Staging directory leaked"


def snapshot():
    directories = (install / "mgmt/webapps/mgmt", install / "mgmt/log4j")
    return {str(path): digest(path) for directory in directories for path in directory.rglob("*") if path.is_file()}


before = snapshot()
empty = workspace / "empty"
empty.mkdir()
ambiguous = workspace / "ambiguous"
ambiguous.mkdir()
for index, target in enumerate((args.old_target, args.new_target)):
    (ambiguous / f"{index}-mgmt.war").symlink_to(next(target.glob("*mgmt.war")).resolve())
corrupt = workspace / "corrupt"
corrupt.mkdir()
with next(args.new_target.glob("*mgmt.war")).open("rb") as original:
    (corrupt / "broken-mgmt.war").write_bytes(original.read(100))
for label, target, jars in (("missing WAR", empty, args.new_target / "tomcat-log4j"),
                            ("ambiguous WARs", ambiguous, args.new_target / "tomcat-log4j"),
                            ("truncated WAR", corrupt, args.new_target / "tomcat-log4j"),
                            ("missing JARs", args.new_target, empty)):
    run("install.mgmt", f"ARCHAPPL_WARS_TARGET_PATH={target.resolve()}",
        f"ARCHAPPL_TOMCAT_LOG4J_PATH={jars.resolve()}", expected=2)
    assert snapshot() == before, f"Existing payload changed after {label}"
    assert not list((install / "mgmt").glob(".payload.*"))
    print(f"PASS: {label} rejected; existing payload preserved.", flush=True)
link = workspace / "linked-instance"
link.symlink_to(install / "mgmt", target_is_directory=True)
for instance, service, reason in ((Path("/"), "mgmt", "absolute non-root path"),
                                  (workspace / ".." / "..", "mgmt", "resolves to the filesystem root"),
                                  (link, "mgmt", "must not be a symlink"),
                                  (install / "mgmt", "../other", "Unknown appliance service")):
    result = subprocess.run(["bash", "-p", str(root / "scripts/install-payload.bash"),
                             str(instance), service, str(args.new_target.resolve()),
                             str((args.new_target / "tomcat-log4j").resolve())],
                            capture_output=True, text=True, timeout=10)
    assert result.returncode == 1 and reason in result.stderr, result.stderr
    assert snapshot() == before, "Path rejection changed the installed payload"
print("PASS: root, root alias, symlink and invalid service destinations rejected.")
for path, content in protected.items():
    assert path.read_bytes() == content, f"Operator state changed: {path}"
print("PASS: all four installed WARs and JAR sets match; operator state survived; invalid input preserved the payload.")
