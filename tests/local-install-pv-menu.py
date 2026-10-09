#!/usr/bin/env python3
"""Check IOC ownership at the keep menu with only HTTP transport replaced."""

import json
import os
from pathlib import Path
import pty
import select
import signal
import subprocess
import sys
import tempfile
import time


TOP = Path(__file__).resolve().parent.parent


def identity(pid):
    try:
        fields = Path(f"/proc/{pid}/stat").read_text().rsplit(") ", 1)[1].split()
        return fields[0], fields[19]
    except (FileNotFoundError, ProcessLookupError):
        return None


def alive(owned):
    current = identity(owned["pid"])
    return current is not None and current[1] == owned["start"] and current[0] not in ("Z", "X", "x")


def stop_owned(owned):
    if not alive(owned):
        return
    os.kill(owned["pid"], signal.SIGTERM)
    for _ in range(100):
        if not alive(owned):
            return
        time.sleep(0.05)
    raise AssertionError("Owned test IOC did not stop")


if Path(sys.argv[0]).name == "curl":
    if sys.argv[-1].endswith("/resumeArchivingPV"):
        root = Path(os.environ["RANGE_EVIDENCE"])
        (root / "resume-called").write_text("resume\n")
        if os.environ["MENU_MODE"] == "resume-exit":
            stop_owned(json.loads((root / "ioc.json").read_text()))
        print('{"status":"ok"}')
        sys.exit(0)
    fixture = os.environ["MENU_RANGE_CURL"]
    os.execv(fixture, [fixture, *sys.argv[1:]])


source = Path(os.environ.get("AA_TEST_SOURCE_PATH") or TOP / "epicsarchiverap-maven-src")
epics = os.environ["AA_TEST_EPICS_BIN"]
workspace = Path(tempfile.mkdtemp(prefix="local-pv-menu.", dir=TOP / "work"))
boundary = workspace / "boundary"
boundary.mkdir()
(boundary / "curl").symlink_to(Path(__file__).resolve())
fixture = workspace / "range"
fixture.mkdir()
(fixture / "curl").symlink_to(TOP / "tests/local-install-pv-range.py")

try:
    for mode in ("keep-live", "menu-exit", "resume-exit"):
        evidence = workspace / mode
        evidence.mkdir()
        env = dict(os.environ, PATH=str(boundary) + os.pathsep + os.environ["PATH"],
                   RANGE_EVIDENCE=str(evidence), RANGE_EPICS=epics, RANGE_MODE="inside",
                   MENU_MODE=mode, MENU_RANGE_CURL=str(fixture / "curl"))
        master, slave = pty.openpty()
        child = None
        owned = None
        output = b""
        try:
            child = subprocess.Popen(
                ["bash", str(TOP / "scripts/verify-local-pv.bash"), "--epics-bin", epics,
                 "--timeout", "40", "http://127.0.0.1:33665/mgmt/bpl",
                 "http://127.0.0.1:33668/retrieval", str(source)],
                stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env)
            deadline = time.monotonic() + 60
            while b"Select [1/2]:" not in output:
                if child.poll() is not None or time.monotonic() >= deadline:
                    raise AssertionError(output.decode())
                if select.select([child.stdout], [], [], 1)[0]:
                    output += os.read(child.stdout.fileno(), 65536)
            retained = Path(next(line.removeprefix("Evidence: ") for line in output.decode().splitlines()
                                 if line.startswith("Evidence: ")))
            pid = int((retained / "ioc.pid").read_text())
            current = identity(pid)
            assert current is not None and current[0] not in ("Z", "X", "x")
            owned = {"pid": pid, "start": current[1]}
            pv = (retained / "pvs.txt").read_text().strip()
            assert Path(f"/proc/{pid}/exe").resolve() == Path(epics + "/softIoc").resolve()
            args = Path(f"/proc/{pid}/cmdline").read_bytes().split(b"\0")
            assert ("P=" + pv.removesuffix("Value")).encode() in args
            (evidence / "ioc.json").write_text(json.dumps(owned))
            if mode == "menu-exit":
                stop_owned(owned)
            os.write(master, b"2\n")
            output += child.communicate(timeout=25)[0]
            text = output.decode()
            (evidence / "log").write_text(text)
            assert "PV acquisition, storage and retrieval: PASS" in text
            if mode == "keep-live":
                assert child.returncode == 0 and "IOC retained: PID" in text, text
                assert alive(owned)
                assert (evidence / "resume-called").is_file()
            else:
                assert child.returncode == 1 and "IOC retained: PID" not in text, text
                assert not alive(owned)
                assert "Test IOC stopped." in text
                assert (evidence / "resume-called").exists() == (mode == "resume-exit")
                if mode == "resume-exit":
                    assert "Test PV paused:" in text
            print(f"PASS: {mode}; exit={child.returncode}; owned IOC state checked", flush=True)
        finally:
            if child is not None and child.poll() is None:
                child.terminate()
                child.wait(timeout=25)
            if child is not None and child.stdout is not None:
                child.stdout.close()
            if owned is not None:
                stop_owned(owned)
            os.close(master)
            os.close(slave)
finally:
    print(f"Menu test evidence: {workspace}", flush=True)
