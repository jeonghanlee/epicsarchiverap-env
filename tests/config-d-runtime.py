#!/usr/bin/env python3
"""Verify config.d through real install rules, Tomcat wrappers, and four WARs.

Requires a built WAR directory with tomcat-log4j, Tomcat 9, Java, and journald.
Runs the installed launcher's manual and foreground service paths; does not
install systemd units. Retains commands, observations, payloads, and logs.
"""

import argparse
import grp
import hashlib
import json
import os
from pathlib import Path
import pwd
import shlex
import shutil
import signal
import socket
import sqlite3
import subprocess
import tempfile
import time
import urllib.error
import urllib.request
import zipfile


TOP = Path(__file__).resolve().parents[1]
SERVICES = ("mgmt", "engine", "etl", "retrieval")


class RuntimeCheck:
    def __init__(self, args):
        self.args = args
        self.root = Path(tempfile.mkdtemp(prefix="archappl-config-runtime-"))
        self.checkout = self.root / "checkout"
        self.installed = self.root / "installed"
        self.launcher = self.installed / "archappl.bash"
        self.supervisor = None
        self.pids = {}
        self.round = "setup"
        self.http = urllib.request.build_opener(urllib.request.ProxyHandler({}))
        print(f"Evidence: {self.root}", flush=True)

    def command(self, args, expected=0, timeout=120):
        run = subprocess.run(args, cwd="/", capture_output=True, timeout=timeout)
        with (self.root / "commands.log").open("ab") as log:
            log.write(f"command={args!r}\nexit={run.returncode}\n".encode())
            log.write(run.stdout + run.stderr + b"\n")
        assert run.returncode == expected, (args, run.returncode, run.stdout, run.stderr)
        return run

    def make(self, *targets):
        return self.command(self.make_args + list(targets))

    def prepare(self):
        first = self.args.port_base
        assert 1024 <= first <= 65522, "Port base must leave room for HTTP, cluster, and shutdown ports"
        for name in ("startup.sh", "shutdown.sh", "catalina.sh"):
            path = self.args.tomcat_home / "bin" / name
            assert os.access(path, os.R_OK | os.X_OK), f"Tomcat script is not readable and executable: {path}"
        for port in (*range(first, first + 4), *range(first + 10, first + 14), first + 5):
            with socket.socket() as check:
                check.bind(("127.0.0.1", port))
        self.checkout.mkdir()
        self.installed.mkdir()
        for name in ("configure", "site-template", "scripts"):
            shutil.copytree(TOP / name, self.checkout / name)
        shutil.copyfile(TOP / "Makefile", self.checkout / "Makefile")
        java_home = Path(shutil.which("java")).resolve().parent.parent
        store = self.root / "store"
        store.mkdir()
        for name in ("sts", "mts", "lts"):
            (store / name / "ArchiverStore").mkdir(parents=True)
        self.make_args = ["make", "--no-print-directory", "-C", str(self.checkout), "SUDO=",
                          f"AA_USERID={pwd.getpwuid(os.getuid()).pw_name}",
                          f"AA_GROUPID={grp.getgrgid(os.getgid()).gr_name}",
                          f"AA_INSTALL_LOCATION={self.installed}", f"JAVA_HOME={java_home}",
                          f"TOMCAT_HOME={self.args.tomcat_home}", "DB_BACKEND=sqlite",
                          f"ARCHAPPL_SQLITE_FILE={self.root / 'archappl.sqlite'}",
                          f"ARCHAPPL_STORAGE_TOP={store}", "ARCHAPPL_STORAGE_ALARM_PERCENT=100",
                          f"ARCHAPPL_WARS_TARGET_PATH={self.args.war_dir}",
                          "ARCHAPPL_HOST_IPADDR=127.0.0.1", f"ARCHAPPL_CLUSTER_INETPORT=127.0.0.1:{first + 5}"]
        for offset, name in enumerate(SERVICES):
            self.make_args += [f"ARCHAPPL_{name.upper()}_PORT={first + offset}",
                               f"ARCHAPPL_SHUTDOWN_{name.upper()}_PORT={first + 10 + offset}"]
        self.make("conf.archapplproperties", "services.install", "serveroption.install")
        war = list(self.args.war_dir.glob("*-mgmt.war"))
        assert len(war) == 1, war
        with zipfile.ZipFile(war[0]) as archive:
            schema = archive.read("install/archappl_sqlite.sql")
        with sqlite3.connect(self.root / "archappl.sqlite") as database:
            database.executescript(schema.decode())
        (self.installed / "config.d/10-common.conf").write_text(
            "CONFIG_TEST_NEW='quoted value * $literal'\nCONFIG_TEST_EMPTY=nonempty\n"
            f'PATH={shlex.quote(str(self.root / "path-prefix"))}:"$PATH"\n'
            "EPICS_CA_ADDR_LIST=127.0.0.1\nEPICS_CA_AUTO_ADDR_LIST=NO\n"
            "CATALINA_OPTS='-Xms64m -Xmx256m -XX:ActiveProcessorCount=2 -Dconfig.common=present'\n"
        )
        with (self.installed / "engine/conf/engine.conf").open("a") as config:
            config.write('\nCATALINA_OPTS="$CATALINA_OPTS -Dconfig.component=engine"\n')
        self.edit("initial", 100)
        members = [self.installed / name for name in ("archappl.conf", "archappl.bash", "archappl-config.bash")]
        members += [self.installed / name / "bin" / script for name in SERVICES
                    for script in ("startup.sh", "shutdown.sh", "run.sh", "setenv.sh")]
        members += list(self.args.war_dir.glob("*.war"))
        (self.root / "sources.json").write_text(json.dumps(
            {str(path): hashlib.sha256(path.read_bytes()).hexdigest() for path in members}, indent=2))

    def edit(self, value, threshold):
        (self.installed / "config.d/90-site.conf").write_text(
            f"CONFIG_TEST_LIVE={shlex.quote(value)}\nCONFIG_TEST_EMPTY=''\n"
            f"ARCHAPPL_STORAGE_ALARM_PERCENT={threshold}\n"
        )

    def start(self, mode, label):
        self.round = label
        if mode == "service":
            with (self.root / f"{label}-service.log").open("wb") as log:
                self.supervisor = subprocess.Popen(["bash", str(self.launcher), "service"], cwd="/", stdout=log, stderr=log)
        elif mode == "direct":
            for name in SERVICES:
                self.command(["bash", "-f", str(self.installed / name / "bin/startup.sh")])
        else:
            self.command(["bash", str(self.launcher), mode])
        deadline = time.monotonic() + 150
        while time.monotonic() < deadline:
            if self.supervisor is not None:
                assert self.supervisor.poll() is None, "Service launcher exited before readiness"
            ready = True
            states = {}
            for offset, name in enumerate(SERVICES):
                pidfile = self.installed / name / "temp" / f"{name}.pid"
                if pidfile.exists():
                    self.pids[name] = int(pidfile.read_text().strip())
                try:
                    url = f"http://127.0.0.1:{self.args.port_base + offset}/{name}/bpl/startupState"
                    with self.http.open(url, timeout=1) as response:
                        states[name] = response.read().decode()
                    ready &= '"STARTUP_COMPLETE"' in states[name]
                except (OSError, urllib.error.URLError) as error:
                    states[name] = str(error)
                    ready = False
            (self.root / f"{label}-startup.json").write_text(json.dumps(states, indent=2))
            if ready and len(self.pids) == 4:
                return
            time.sleep(0.25)
        raise AssertionError(f"Readiness timeout; inspect {self.root}")

    def observe(self, label, value, threshold):
        observations = {}
        for name, pid in self.pids.items():
            process = Path(f"/proc/{pid}")
            assert process.joinpath("exe").resolve() == Path(shutil.which("java")).resolve()
            environ = dict(item.split(b"=", 1) for item in process.joinpath("environ").read_bytes().split(b"\0") if b"=" in item)
            arguments = process.joinpath("cmdline").read_bytes().split(b"\0")
            wanted = {"CONFIG_TEST_LIVE": value, "CONFIG_TEST_NEW": "quoted value * $literal",
                      "CONFIG_TEST_EMPTY": "", "EPICS_CA_ADDR_LIST": "127.0.0.1", "EPICS_CA_AUTO_ADDR_LIST": "NO"}
            observations[name] = {"pid": pid, "environment": {key: environ.get(key.encode(), b"<missing>").decode() for key in wanted},
                                  "path_prefix_count": environ[b"PATH"].split(b":").count(str(self.root / "path-prefix").encode()),
                                  "arguments": [item.decode() for item in arguments]}
        (self.root / f"{label}-jvms.json").write_text(json.dumps(observations, indent=2))
        assert len(observations) == 4
        for name, observed in observations.items():
            assert observed["environment"] == wanted, observed
            assert observed["path_prefix_count"] == 1, observed
            assert "-Dconfig.common=present" in observed["arguments"], observed
            assert f"-Dcatalina.base={self.installed / name}" in observed["arguments"], observed
            if name == "engine":
                assert "-Dconfig.component=engine" in observed["arguments"], observed
        health = self.command(["bash", str(self.launcher), "health"])
        (self.root / f"{label}-health.txt").write_bytes(health.stdout + health.stderr)
        assert f"threshold={threshold}%".encode() in health.stdout
        assert b"all-four-processes-verified" in health.stdout
        status = self.command(["bash", str(self.launcher), "status"])
        (self.root / f"{label}-status.txt").write_bytes(status.stdout + status.stderr)
        assert f"threshold={threshold}%".encode() in status.stdout
        assert b"all-four-processes-verified" in status.stdout
        print(f"PASS: {label}: four JVMs, component options, and health", flush=True)

    def stop(self, normal=True):
        if self.supervisor is not None:
            if self.supervisor.poll() is None:
                self.supervisor.terminate()
            rc = self.supervisor.wait(timeout=90)
            self.supervisor = None
            if normal:
                assert rc == 0, rc
        elif self.pids and normal:
            self.command(["bash", str(self.launcher), "shutdown"], timeout=90)
        for pid in self.pids.values():
            stat = Path(f"/proc/{pid}/stat")
            if not normal and stat.exists() and stat.read_text().split(") ", 1)[1][0] != "Z":
                os.kill(pid, signal.SIGTERM)
            deadline = time.monotonic() + 30
            while stat.exists() and stat.read_text().split(") ", 1)[1][0] != "Z":
                assert time.monotonic() < deadline, f"JVM {pid} did not stop"
                time.sleep(0.1)
        self.pids.clear()
        print(f"Stopped: {self.round}", flush=True)

    def run(self):
        verdict = "INCOMPLETE"
        try:
            self.prepare()
            self.start("direct", "direct-noglob")
            self.observe("direct-noglob", "initial", 100)
            self.stop()
            self.start("startup", "manual")
            self.observe("manual", "initial", 100)
            self.start("restart", "manual-restart")
            self.observe("manual-restart", "initial", 100)
            self.stop()
            self.start("service", "service-before-edit")
            self.observe("service-before-edit", "initial", 100)
            self.edit("changed", 99)
            self.observe("service-after-edit", "initial", 99)
            self.stop()
            self.start("service", "service-after-restart")
            self.observe("service-after-restart", "changed", 99)
            self.stop()
            invalid = self.installed / "config.d/99-invalid.conf"
            invalid.write_text('CONFIG_TEST_LIVE="unterminated\n')
            for options in ([], ["-f"]):
                for action in ("startup", "service"):
                    run = self.command(["bash", *options, str(self.launcher), action], expected=1)
                    assert str(invalid).encode() in run.stderr
                    assert all(not (self.installed / name / "temp" / f"{name}.pid").exists() for name in SERVICES)
                for name in SERVICES:
                    for script in ("startup.sh", "shutdown.sh", "run.sh"):
                        run = self.command(["bash", *options, str(self.installed / name / "bin" / script)], expected=1)
                        assert str(invalid).encode() in run.stderr
            verdict = "PASS"
        finally:
            self.stop(normal=False)
            (self.root / "verdict.txt").write_text(verdict + "\n")
        print(f"{verdict}: installed runtime configuration; evidence retained at {self.root}", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tomcat-home", required=True, type=Path)
    parser.add_argument("--war-dir", required=True, type=Path)
    parser.add_argument("--port-base", type=int, default=29665)
    options = parser.parse_args()
    options.tomcat_home = options.tomcat_home.resolve(strict=True)
    options.war_dir = options.war_dir.resolve(strict=True)
    RuntimeCheck(options).run()
