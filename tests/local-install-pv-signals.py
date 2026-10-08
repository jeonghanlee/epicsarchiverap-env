#!/usr/bin/env python3
"""Exercise the shipped verifier and IOC with only HTTP transport faulted."""

import json
import os
from pathlib import Path
import shlex
import signal
import subprocess
import tempfile
import time


TOP = Path(__file__).resolve().parent.parent
SOURCE = Path(os.environ.get("AA_TEST_SOURCE_PATH") or TOP / "epicsarchiverap-maven-src")
EPICS_BIN = os.environ["AA_TEST_EPICS_BIN"]
WORKSPACE = Path(tempfile.mkdtemp(prefix="local-pv-signals.", dir=TOP / "work"))
BOUNDARY = WORKSPACE / "boundary"
BOUNDARY.mkdir()
CURL = BOUNDARY / "curl"
CURL.write_text("""#!/bin/bash
case "${*: -1}" in
    */archivePV)
        touch "$SIGNAL_REGISTER_MARKER"
        if [[ "$SIGNAL_INITIAL" == yes ]]; then sleep 3; fi
        exit 7 ;;
    */pauseArchivingPV)
        touch "$SIGNAL_PAUSE_MARKER"
        sleep 3
        printf '%s\\n' '{"status":"ok"}' ;;
    *) exit 7 ;;
esac
""")
CURL.chmod(0o700)


def process_identity(pid):
    """Return state and start ticks without treating PID existence as ownership."""
    try:
        fields = Path(f"/proc/{pid}/stat").read_text().rsplit(") ", 1)[1].split()
        return fields[0], fields[19]
    except (FileNotFoundError, ProcessLookupError):
        return None


def wait_marker(marker, child):
    deadline = time.monotonic() + 40
    while not marker.exists():
        if child.poll() is not None or time.monotonic() >= deadline:
            raise AssertionError(f"Boundary not reached: {marker}")
        time.sleep(0.05)


def run_case(name, initial_signal=None, cleanup_signal=None, terminal=False):
    register_marker = WORKSPACE / f"{name}.register"
    pause_marker = WORKSPACE / f"{name}.pause"
    log = WORKSPACE / f"{name}.log"
    env = os.environ.copy()
    env.update(PATH=f"{BOUNDARY}:{env['PATH']}",
               SIGNAL_REGISTER_MARKER=str(register_marker),
               SIGNAL_PAUSE_MARKER=str(pause_marker),
               SIGNAL_INITIAL="yes" if initial_signal else "no")
    child = None
    ioc_pid = None
    ioc_identity = None
    try:
        with log.open("w") as output:
            command = [
                "bash", str(TOP / "scripts/verify-local-pv.bash"),
                "--epics-bin", EPICS_BIN, "--cleanup", "stop", "--timeout", "30",
                "http://127.0.0.1:33665/mgmt/bpl",
                "http://127.0.0.1:33668/retrieval",
                str(SOURCE),
            ]
            if terminal:
                command = ["script", "--quiet", "--return", "--command",
                           shlex.join(command), str(WORKSPACE / f"{name}.raw")]
            child = subprocess.Popen(command, stdin=subprocess.PIPE if terminal else None,
                                     stdout=output, stderr=subprocess.STDOUT, env=env)
            wait_marker(register_marker, child)
            evidence = Path(next(line.removeprefix("Evidence: ")
                                 for line in log.read_text().splitlines()
                                 if line.startswith("Evidence: ")))
            ioc_pid = int((evidence / "ioc.pid").read_text())
            ioc_identity = process_identity(ioc_pid)
            assert ioc_identity and ioc_identity[0] not in ("Z", "X")
            if initial_signal:
                if terminal:
                    child.stdin.write(b"\x03")
                    child.stdin.flush()
                else:
                    child.send_signal(initial_signal)
            wait_marker(pause_marker, child)
            if cleanup_signal:
                if terminal:
                    child.stdin.write(b"\x03")
                    child.stdin.flush()
                else:
                    child.send_signal(cleanup_signal)
            code = child.wait(timeout=20)
        expected = 128 + initial_signal if initial_signal else 1
        assert code == expected, (name, code, expected)
        current = process_identity(ioc_pid)
        assert current is None or current[0] in ("Z", "X") or current[1] != ioc_identity[1], name
        assert json.loads((evidence / "pause.json").read_text())["status"] == "ok", name
        assert "Test IOC stopped." in log.read_text(), name
        assert "Test PV paused:" in log.read_text(), name
        assert (evidence / "register.json").read_text() == "", name
        print(f"PASS: {name}; exit={code}; owned IOC stopped; cleanup messages visible")
    finally:
        if child is not None and child.poll() is None:
            child.terminate()
            child.wait(timeout=20)
        if child is not None and child.stdin is not None:
            child.stdin.close()
        if ioc_pid is not None and ioc_identity is not None:
            current = process_identity(ioc_pid)
            if current and current[1] == ioc_identity[1] and current[0] not in ("Z", "X"):
                os.kill(ioc_pid, signal.SIGTERM)
                for _ in range(50):
                    current = process_identity(ioc_pid)
                    if not current or current[1] != ioc_identity[1] or current[0] in ("Z", "X"):
                        break
                    time.sleep(0.1)
                else:
                    os.kill(ioc_pid, signal.SIGKILL)


try:
    run_case("failure-control")
    run_case("failure-cleanup-term", cleanup_signal=signal.SIGTERM)
    run_case("failure-cleanup-int", cleanup_signal=signal.SIGINT)
    run_case("term-then-term", signal.SIGTERM, signal.SIGTERM)
    run_case("int-then-int", signal.SIGINT, signal.SIGINT)
    run_case("terminal-cleanup-ctrlc", cleanup_signal=signal.SIGINT, terminal=True)
    run_case("terminal-ctrlc-then-ctrlc", signal.SIGINT, signal.SIGINT, terminal=True)
finally:
    print(f"Signal test evidence: {WORKSPACE}")
