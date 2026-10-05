#!/usr/bin/env python3
"""Inspect the real installation and exercise its CA, HTTP and persistence paths."""

import datetime as dt
from decimal import Decimal
import hashlib
import grp
import json
import math
import os
from pathlib import Path
import pwd
import re
import shlex
import signal
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
import zipfile


SERVICES = ("mgmt", "engine", "etl", "retrieval")
TABLES = ("ArchivePVRequests", "ExternalDataServers", "PVAliases", "PVTypeInfo")
MARIADB_UNITS = ("mariadb.service", "mysql.service", "mysqld.service")
UNIT = "epicsarchiverap-maven.service"
HEALTH_UNIT = "epicsarchiverap-maven-health.service"
HEALTH_TIMER = "epicsarchiverap-maven-health.timer"
SAFE_NAME = re.compile(r"[A-Za-z0-9_.-]+")
CA_LINE = re.compile(r"^\S+\s+(\d{4}-\d\d-\d\d)\s+(\d\d:\d\d:\d\d)(\.\d+)\s+([-+0-9.eE]+)")
COMMANDS = []


class CheckError(Exception):
    pass


def check(condition, message):
    if not condition:
        raise CheckError(message)


def execute(argv, timeout=120, check_exit=True, env=None, input_data=None):
    result = subprocess.run(argv, capture_output=True, text=True, timeout=timeout,
                            stdin=subprocess.DEVNULL if input_data is None else None,
                            input=input_data, env=env)
    COMMANDS.append({"argv": argv, "at": timestamp(), "exit": result.returncode,
                     "stdout": result.stdout, "stderr": result.stderr})
    if check_exit:
        check(result.returncode == 0, f"Command failed: {argv[0]} (exit {result.returncode})")
    return result.returncode, result.stdout, result.stderr


def hash_file(path):
    value = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def sqlite_service_units(systemctl=("systemctl",)):
    """Require a readable service inventory containing the appliance and no MariaDB units."""
    _, output, _ = execute([*systemctl, "list-unit-files", "--type=service",
                            "--full", "--no-legend", "--no-pager"])
    rows = [line.split() for line in output.splitlines() if line.strip()]
    check(all(len(row) >= 2 and row[0].endswith(".service") for row in rows),
          "Malformed installed service inventory")
    installed = {row[0] for row in rows}
    check(UNIT in installed, "Service inventory does not contain the installed appliance")
    check(not installed.intersection(MARIADB_UNITS),
          "SQLite species installed a MariaDB service")
    return {"required_unit": UNIT, "forbidden_units": list(MARIADB_UNITS),
            "listed_units": sorted(installed)}


def timestamp():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def journal_since(nanoseconds):
    """Return a journalctl bound in whole epoch seconds at or after the instant."""
    # Integer ceiling (IEEE 754 roundToIntegralTowardPositive) is exact and
    # accepted by systemd 239, which rejects ISO 8601 offsets.
    return "@" + str(-(-nanoseconds // 1_000_000_000))


def ioc_prefix(creation_id):
    return "VMTEST_" + hashlib.sha256(creation_id.encode()).hexdigest()[:12] + "_"


def load_ioc_fixture(binary, fixture, prefix, expected_count):
    """Load the unchanged fixture in the real IOC before enabling record processing."""
    names = re.findall(r'^\s*record\s*\([^,]+,\s*"([^"]+)"',
                       Path(fixture).read_text(), re.MULTILINE)
    expected = {name.replace("$(P)", prefix) for name in names}
    check(len(expected) == expected_count, "Original IOC record inventory mismatch")
    commands = f'dbLoadRecords({json.dumps(str(fixture))}, "P={prefix}")\ndbl\nexit\n'
    _, output, errors = execute([binary], input_data=commands)
    loaded = set(output.splitlines())
    check(expected <= loaded, "Original IOC did not load every fixture record")
    check("ERROR" not in output + errors, "Original IOC reported a database loading error")
    return {"prefix": prefix, "loaded_records": len(expected)}


def read_assignments(path):
    result = {}
    for line in Path(path).read_text().splitlines():
        if not line or line.startswith("#"):
            continue
        name, separator, value = line.partition("=")
        if separator and re.fullmatch("[A-Z_0-9]+", name):
            parts = shlex.split(value)
            result[name] = " ".join(parts)
    return result


def process_info(pid):
    root = Path("/proc") / str(pid)
    stat_line = (root / "stat").read_text()
    fields = stat_line[stat_line.rfind(")") + 2:].split()
    status = dict(line.split(":", 1) for line in (root / "status").read_text().splitlines())
    return {"pid": int(pid), "start": fields[19],
            "cpu_ticks": int(fields[11]) + int(fields[12]),
            "rss_kib": int(status["VmRSS"].split()[0]),
            "uid": int(status["Uid"].split()[0]), "gid": int(status["Gid"].split()[0]),
            "exe": os.readlink(str(root / "exe")),
            "argv": (root / "cmdline").read_bytes().decode().strip("\0").split("\0")}


class Observer:
    """Record actual CA events and process/guest resource samples."""
    def __init__(self, guest):
        self.guest = guest
        self.events = []
        self.resources = []
        self.errors = []
        self.done = threading.Event()
        self.process = None
        self.threads = []

    def __enter__(self):
        self.sample_once()
        env = dict(os.environ, TZ="UTC", EPICS_CA_ADDR_LIST="127.0.0.1",
                   EPICS_CA_AUTO_ADDR_LIST="NO")
        self.process = subprocess.Popen([self.guest.binary("camonitor"), "-t", "s", "-f", "3",
                                          self.guest.pv], stdout=subprocess.PIPE,
                                         stderr=subprocess.STDOUT, text=True, env=env)
        self.threads = [threading.Thread(target=self.read_ca, daemon=True),
                        threading.Thread(target=self.sample, daemon=True)]
        for thread in self.threads:
            thread.start()
        return self

    def read_ca(self):
        try:
            for line in self.process.stdout:
                match = CA_LINE.match(line)
                if match:
                    day, clock, fraction, value = match.groups()
                    seconds = int(dt.datetime.fromisoformat(day + "T" + clock)
                                  .replace(tzinfo=dt.timezone.utc).timestamp())
                    nanos = int(Decimal(fraction) * 1_000_000_000)
                    self.events.append({"time": seconds * 1_000_000_000 + nanos,
                                        "precision_ns": 10 ** max(0, 9 - len(fraction[1:])),
                                        "value": float(value)})
        except Exception as error:
            self.errors.append(type(error).__name__)

    def sample(self):
        while not self.done.wait(1):
            self.sample_once()

    def sample_once(self):
        try:
            memory = dict(line.split(":", 1) for line in Path("/proc/meminfo")
                          .read_text().splitlines())
            _, properties, _ = execute(["systemctl", "show", self.guest.ioc_unit,
                                         "--property=MainPID", "--value"],
                                         check_exit=self.guest.ioc_started)
            pid = int(properties.strip() or "0")
            check(pid > 0 or not self.guest.ioc_started, "Original IOC process disappeared")
            self.resources.append({
                "at": timestamp(), "sampling_interval_seconds": 1,
                "guest_cpu": Path("/proc/stat").read_text().splitlines()[0],
                "available_kib": int(memory["MemAvailable"].split()[0]),
                "swap_used_kib": int(memory["SwapTotal"].split()[0]) -
                int(memory["SwapFree"].split()[0]),
                "ioc": process_info(pid) if pid else None,
                "jvms": self.guest.identities(),
            })
        except (OSError, ValueError, CheckError) as error:
            if self.guest.expected_restart:
                self.resources.append({"at": timestamp(), "expected_restart": True})
            else:
                self.errors.append(type(error).__name__)

    def __exit__(self, *unused):
        self.done.set()
        self.process.terminate()
        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait(timeout=5)
        for thread in self.threads:
            thread.join(timeout=5)
        self.guest.evidence.setdefault("observations", []).append(
            {"events": self.events, "resources": self.resources, "errors": self.errors})
        check(not any(thread.is_alive() for thread in self.threads), "An observation helper did not stop")


class Guest:
    def __init__(self, path):
        self.path = Path(path).resolve()
        self.root = self.path.parent
        self.spec = json.loads(self.path.read_text())
        self.case = self.spec["case"]
        self.settings = self.spec["guest"]
        self.bounds = self.spec["bounds"]
        self.ioc_started = False
        self.expected_restart = False
        self.startup_health = ""
        self.checkout = Path(self.settings["source_parent"]) / "epicsarchiverap-env"
        self.source = self.checkout / "epicsarchiverap-maven-src"
        self.install = Path(self.settings["install_parent"]) / "epicsarchiverap-maven"
        self.uid = pwd.getpwnam(self.settings["user"]).pw_uid
        self.gid = grp.getgrnam(self.settings["group"]).gr_gid
        self.conf = read_assignments(self.install / "archappl.conf")
        self.appliance = ET.parse(self.install / "appliances.xml").find("appliance")
        check(self.appliance is not None, "Missing appliance definition")
        self.mgmt = self.appliance.findtext("mgmt_url").rstrip("/") + "/"
        self.retrieval = self.appliance.findtext("data_retrieval_url").rstrip("/") + "/"
        self.prefix = ioc_prefix(self.case["creation_id"])
        self.pv = self.prefix + "test_0"
        self.ioc_unit = "archiver-test-ioc-" + self.case["creation_id"] + ".service"
        self.evidence = {"at": timestamp(), "action": sys.argv[1], "results": {},
                         "commands": COMMANDS,
                         "case_name": self.case["name"], "creation_id": self.case["creation_id"],
                         "candidate": {name: self.spec["candidate"][name]
                                       for name in ("env_ref", "source_ref")}}

    def binary(self, name):
        matches = [Path(directory) / name for directory in self.settings["epics_bin"].split(":")
                   if (Path(directory) / name).is_file()]
        check(bool(matches) and os.access(matches[0], os.X_OK), f"Missing real EPICS tool: {name}")
        return str(matches[0])

    def result(self, label):
        self.evidence["results"][label] = {"result": "Pass", "at": timestamp()}

    def make_value(self, name):
        _, out, _ = execute(["make", "-s", "--no-print-directory", "-C", str(self.checkout),
                             "print-" + name])
        return out.strip().splitlines()[-1]

    def identities(self):
        result = {}
        for service in SERVICES:
            pid = int((self.install / service / "temp" / (service + ".pid")).read_text().strip())
            result[service] = process_info(pid)
        return result

    def health(self, expected=0, retry_startup=False):
        rc, out, err = execute(["runuser", "-u", self.settings["user"], "--", "bash",
                                str(self.install / "archappl.bash"), "health"], check_exit=False)
        # Right after a start the PID file can name a shell of the start chain; the launcher
        # reports it as STARTING, and a launcher without that verdict as a wrong executable.
        if retry_startup and rc != expected and any(token in out + err for token in
                ("missing-pid-file", "missing-process", "dead-process", "STARTING",
                 "wrong-java-executable")):
            self.startup_health = out + err
            return None
        check(rc == expected, "Shipped launcher health returned an unexpected verdict: " + out + err)
        if not expected:
            check("health PRESENT all-four-processes-verified" in out,
                  "Health did not verify all appliance instances")
            identities = self.identities()
            check(len({value["pid"] for value in identities.values()}) == 4,
                  "Appliance PIDs are not distinct")
            check(all(value["uid"] == self.uid for value in identities.values()),
                  "Appliance JVM service account mismatch")
            for name, process in identities.items():
                check(process["gid"] == self.gid and Path(process["exe"]).resolve() ==
                      (Path(self.conf["JAVA_HOME"]) / "bin/java").resolve(),
                      "Appliance JVM executable/group mismatch")
                check("-Dcatalina.base=" + str(self.install / name) in process["argv"] and
                      "-Dcatalina.home=" + self.conf["CATALINA_HOME"] in process["argv"] and
                      "org.apache.catalina.startup.Bootstrap" in process["argv"],
                      "Appliance JVM instance arguments mismatch")
                check(set(("-Xms256M", "-Xmx256M", "-XX:MaxMetaspaceSize=256M", "-XX:+UseG1GC"))
                      .issubset(process["argv"]), "Effective JVM resource settings mismatch")
            self.evidence["identities"] = identities
        return out + err

    def http(self, base, endpoint, **parameters):
        query = urllib.parse.urlencode(parameters)
        url = base + endpoint + ("?" + query if query else "")
        try:
            with urllib.request.urlopen(url, timeout=10) as response:
                check(response.status == 200, "Unexpected HTTP result")
                raw = response.read()
        except urllib.error.URLError:
            raise
        try:
            value = json.loads(raw)
        except ValueError as error:
            raise CheckError("Malformed API JSON") from error
        self.evidence.setdefault("http", []).append({"endpoint": endpoint, "parameters": parameters,
                                                     "result": value, "at": timestamp()})
        return value

    def ready(self, bound):
        deadline = time.monotonic() + bound
        started = time.monotonic()
        self.startup_health = ""
        while time.monotonic() < deadline:
            try:
                if self.health(retry_startup=True) is None:
                    time.sleep(2)
                    continue
                info = self.http(self.mgmt, "getApplianceInfo")
                check(isinstance(info, dict), "Appliance info must be a JSON object")
                check(info.get("identity") == self.appliance.findtext("identity"),
                      "HTTP appliance identity mismatch")
                for field, element in (("mgmtURL", "mgmt_url"), ("engineURL", "engine_url"),
                                       ("etlURL", "etl_url"), ("retrievalURL", "retrieval_url"),
                                       ("dataRetrievalURL", "data_retrieval_url")):
                    check(info.get(field) == self.appliance.findtext(element),
                          "HTTP appliance URL mismatch")
                version = (self.install / "mgmt/webapps/mgmt/ui/comm/version.txt").read_text().splitlines()[0]
                check(info.get("version") == version, "HTTP/build version mismatch")
                check(time.monotonic() <= deadline, "Application readiness completed after its deadline")
                self.evidence.setdefault("timing", []).append(
                    {"operation": "readiness", "elapsed": time.monotonic() - started, "bound": bound})
                return
            except (urllib.error.URLError, TimeoutError):
                time.sleep(2)
        raise CheckError("Application readiness deadline exceeded" + (
            "; last health: " + self.startup_health.strip() if self.startup_health else ""))

    def payload(self):
        check(execute(["git", "-C", str(self.checkout), "rev-parse", "HEAD"])[1].strip() ==
              self.spec["candidate"]["env_ref"], "Environment checkout mismatch")
        check(execute(["git", "-C", str(self.source), "rev-parse", "HEAD"])[1].strip() ==
              self.spec["candidate"]["source_ref"], "Source checkout mismatch")
        target = Path(self.make_value("ARCHAPPL_WARS_TARGET_PATH"))
        if not target.is_absolute():
            target = self.checkout / target
        logging = target / "tomcat-log4j"
        expected_jars = {path.name: hash_file(path) for path in logging.glob("*.jar")}
        check(bool(expected_jars), "Missing original logging JAR artifacts")
        hashes = {}
        for service in SERVICES:
            wars = list(target.glob("*" + service + ".war"))
            check(len(wars) == 1, "Ambiguous or absent real WAR artifact")
            root = self.install / service / "webapps" / service
            with zipfile.ZipFile(wars[0]) as archive:
                names = {entry.filename for entry in archive.infolist() if not entry.is_dir()}
                actual = {str(path.relative_to(root)) for path in root.rglob("*") if path.is_file()}
                check(actual == names, "Exploded WAR file set mismatch")
                for name in names:
                    path = root / name
                    check(not path.is_symlink() and path.read_bytes() == archive.read(name),
                          "Exploded WAR content mismatch")
                    check(path.stat().st_uid == self.uid, "Installed payload ownership mismatch")
                for name in ("appliances.xml", "archappl.properties", "policies.py"):
                    generated = self.source / "src/sitespecific/als/classpathfiles" / name
                    check(generated.is_file(), "Missing original generated site input")
                    check(archive.read("WEB-INF/classes/" + name) == generated.read_bytes(),
                          "WAR site classpath input mismatch")
                    check((self.install / name).read_bytes() == generated.read_bytes(),
                          "Installed global classpath configuration mismatch")
                site = self.source / "src/sitespecific/als"
                assets = list((site / "img").rglob("*")) + [site / "css/main.css"]
                for asset in assets:
                    if asset.is_file():
                        relative = str(asset.relative_to(site))
                        check(archive.read("ui/comm/" + relative) == asset.read_bytes(),
                              "ALS image/shared CSS content mismatch")
                if service == "mgmt":
                    check(archive.read("ui/css/mgmt.css") == (site / "css/mgmt.css").read_bytes(),
                          "ALS management CSS mismatch")
                    replacements = re.findall(r"<!-- @begin\(([^)]+)\) -->.*?<!-- @end\(\1\) -->",
                                               (site / "template_changes.html").read_text(), re.S)
                    template = (site / "template_changes.html").read_text()
                    pages = [archive.read(name).decode() for name in names
                             if name.startswith("ui/") and name.endswith(".html")]
                    check(bool(replacements) and bool(pages), "Missing ALS template sections/pages")
                    for section in replacements:
                        fragment = re.search(r"<!-- @begin\(" + re.escape(section) +
                            r"\) -->.*?<!-- @end\(" + re.escape(section) + r"\) -->", template, re.S)[0]
                        check(any(fragment in page for page in pages), "ALS template section mismatch")
            actual_jars = {path.name: hash_file(path) for path in
                           (self.install / service / "log4j").glob("*.jar")}
            check(actual_jars == expected_jars, "Installed logging JAR set/content mismatch")
            hashes[service] = hash_file(wars[0])
            runtime_context = self.install / service / "conf/context.xml"
            generated_context = Path(self.make_value("AA_SITE_TEMPLATE_PATH")) / "context.xml"
            check(runtime_context.read_bytes() == generated_context.read_bytes(),
                  "Installed Tomcat datasource configuration mismatch")
            context = ET.parse(runtime_context).find("Resource")
            check(context is not None and context.attrib["name"] == "jdbc/" +
                  self.conf["ARCHAPPL_DB_NAME"], "Installed database resource mismatch")
            server = ET.parse(self.install / service / "conf/server.xml")
            connector = server.find(".//Connector")
            expected_port = urllib.parse.urlsplit(self.appliance.findtext(
                "retrieval_url" if service == "retrieval" else service + "_url")).port
            check(int(connector.attrib["port"]) == expected_port, "Service port mismatch")
            shutdown = int(self.make_value("ARCHAPPL_SHUTDOWN_" + service.upper() + "_PORT"))
            check(int(server.getroot().attrib["port"]) == shutdown, "Service shutdown port mismatch")
            check((self.install / service / "conf" / (service + ".conf")).read_bytes() ==
                  (Path(self.make_value("AA_SITE_TEMPLATE_PATH")) / (service + ".conf")).read_bytes(),
                  "Installed service options mismatch")
        self.evidence["payload_sha256"] = hashes
        check((self.install / "archappl.bash").read_bytes() ==
              (self.checkout / "scripts/archappl.bash").read_bytes(), "Installed launcher mismatch")
        check((self.install / "archappl.conf").read_bytes() ==
              (Path(self.make_value("AA_SITE_TEMPLATE_PATH")) / "archappl.conf").read_bytes(),
              "Installed launcher configuration mismatch")
        for unit in (UNIT, HEALTH_UNIT, HEALTH_TIMER):
            _, actual, _ = execute(["systemctl", "cat", unit])
            generated = self.checkout / "site-template/systemd" / unit
            check(generated.is_file() and generated.read_text().strip() in actual,
                  "Effective systemd unit does not match its generated input")
            _, dropins, _ = execute(["systemctl", "show", unit, "-p", "DropInPaths", "--value"])
            check(not dropins.strip(), "Unaccounted systemd unit override")
        _, version, error = execute([str(Path(self.conf["JAVA_HOME"]) / "bin/java"), "--version"])
        check(re.search(r'(?:openjdk|java) 21[.\s]', version + error), "Actual guest JDK is not 21")
        self.evidence["java_version"] = version + error
        check(self.conf["ARCHAPPL_STORAGE_TOP"] == self.settings["store_top"],
              "Storage root mismatch")
        check("-Xmx256M" in self.conf["CATALINA_OPTS"] and "-Xms256M" in self.conf["CATALINA_OPTS"],
              "JVM heap differs from accepted test resources")
        self.result("T5")

    def sql(self, query):
        context = ET.parse(self.install / "mgmt/conf/context.xml").find("Resource").attrib
        url = context["url"]
        command = ["runuser", "-u", self.settings["user"], "--"]
        if self.case["backend"] == "sqlite":
            check(url.startswith("jdbc:sqlite:"), "SQLite runtime URL mismatch")
            database, _, options = url[len("jdbc:sqlite:"):].partition("?")
            check(urllib.parse.parse_qs(options).get("journal_mode") == ["WAL"],
                  "SQLite runtime journal configuration mismatch")
            check(Path(database).is_file(), "Installed SQLite database is missing")
            return execute(command + ["sqlite3", database, query])[1].strip()
        check(url.startswith("jdbc:mariadb:"), "MariaDB runtime URL mismatch")
        parsed = urllib.parse.urlsplit(url[len("jdbc:"):])
        database = parsed.path.lstrip("/")
        check(SAFE_NAME.fullmatch(database), "Invalid database identifier")
        transport = urllib.parse.parse_qs(parsed.query).get("localSocket", [])
        check(bool(transport) == (self.case["backend"] == "socket"), "MariaDB transport mismatch")
        options = (["--protocol=SOCKET", "--socket=" + transport[0]] if transport else
                   ["--protocol=TCP", "--host=" + parsed.hostname, "--port=" + str(parsed.port or 3306)])
        env = dict(os.environ, MYSQL_PWD=context["password"])
        return execute(command + ["mysql", "--no-defaults", *options, "--user=" + context["username"],
                                   "-N", "-B", database, "-e", query], env=env)[1].strip()

    def schema(self):
        tables = self.sql("SELECT name FROM sqlite_master WHERE type='table';"
                          if self.case["backend"] == "sqlite" else "SHOW TABLES;").splitlines()
        check(set(TABLES).issubset(tables), "Required application schema is missing")
        if self.case["backend"] == "sqlite":
            for unit in (UNIT,):
                dependencies = execute(["systemctl", "show", unit, "-p", "After", "-p", "Requires",
                                        "-p", "Wants", "-p", "BindsTo", "-p", "Requisite", "-p", "PartOf"])[1]
                check(not any(name in dependencies.lower() for name in
                              MARIADB_UNITS),
                      "SQLite has a MariaDB unit dependency")
            self.evidence["sqlite_service_units"] = sqlite_service_units()
        self.result("T6")

    def scheduled(self):
        execute(["systemctl", "is-enabled", "--quiet", HEALTH_TIMER])
        execute(["systemctl", "is-active", "--quiet", HEALTH_TIMER])
        interval = int(self.make_value("SYSTEMD_HEALTH_INTERVAL_SECONDS"))
        startup = int(self.make_value("SYSTEMD_HEALTH_STARTUP_SECONDS"))
        timeout = int(self.make_value("SYSTEMD_HEALTH_TIMEOUT_SECONDS"))
        since = journal_since(time.time_ns())
        deadline = time.monotonic() + startup + 3 * (interval + timeout) + 30
        invocations = set()
        evidence = {}
        while time.monotonic() < deadline:
            _, journal, _ = execute(["journalctl", "-u", HEALTH_UNIT, "--since", since,
                                      "-o", "json", "--no-pager"])
            present = set()
            for line in journal.splitlines():
                entry = json.loads(line)
                if "health PRESENT all-four-processes-verified" in entry.get("MESSAGE", ""):
                    invocation = entry.get("_SYSTEMD_INVOCATION_ID")
                    if invocation:
                        present.add(invocation)
            _, properties, _ = execute(["systemctl", "show", HEALTH_UNIT, "-p", "InvocationID",
                                          "-p", "ExecMainStatus", "-p", "ActiveState",
                                          "-p", "Result", "-p", "ExecMainCode"])
            state = dict(line.split("=", 1) for line in properties.splitlines() if "=" in line)
            invocation = state.get("InvocationID")
            if invocation in present and state.get("ActiveState") == "inactive" and state.get(
                    "ExecMainStatus") == "0" and state.get("Result") == "success":
                invocations.add(invocation)
                evidence[invocation] = state
            if len(invocations) >= 3:
                self.evidence["health_invocations"] = evidence
                self.result("T8")
                return
            time.sleep(2)
        raise CheckError("Three eligible scheduled health invocations were not observed")

    def start_ioc(self):
        fixture = self.root / "UnitTestPVs.db"
        check(hash_file(fixture) == self.spec["fixture"]["sha256"], "Guest fixture digest mismatch")
        rc, state, _ = execute(["systemctl", "is-active", self.ioc_unit], check_exit=False)
        if rc == 0 and state.strip() == "active":
            self.ioc_started = True
            return
        started = time.monotonic()
        self.evidence["ioc_fixture_load"] = load_ioc_fixture(
            self.binary("softIocPVX"), fixture, self.prefix,
            self.spec["fixture_counts"]["records"])
        execute(["systemd-run", "--unit", self.ioc_unit, "--collect",
                 "--property=Restart=no", "--setenv=EPICS_CAS_INTF_ADDR_LIST=127.0.0.1",
                 "--setenv=EPICS_CAS_BEACON_ADDR_LIST=127.0.0.1",
                 "--setenv=EPICS_PVAS_INTF_ADDR_LIST=127.0.0.1",
                 self.binary("softIocPVX"), "-S", "-m", "P=" + self.prefix, "-d", str(fixture)])
        env = dict(os.environ, EPICS_CA_ADDR_LIST="127.0.0.1", EPICS_CA_AUTO_ADDR_LIST="NO")
        self.ioc_started = True
        deadline = started + self.bounds["samples"]
        while time.monotonic() < deadline:
            rc, _, _ = execute([self.binary("caget"), "-w", "2", "-t", self.pv], env=env,
                                check_exit=False)
            if rc == 0:
                self.evidence.setdefault("timing", []).append({"operation": "ioc_startup",
                    "elapsed": time.monotonic() - started, "bound": self.bounds["samples"]})
                return
            time.sleep(1)
        raise CheckError("Original IOC startup deadline exceeded")

    @staticmethod
    def iso(nanos):
        seconds, fraction = divmod(nanos, 1_000_000_000)
        return dt.datetime.fromtimestamp(seconds, dt.timezone.utc).strftime(
            "%Y-%m-%dT%H:%M:%S") + f".{fraction:09d}Z"

    def samples(self, start, end):
        raw = self.http(self.retrieval, "data/getData.json", pv=self.pv,
                        **{"from": self.iso(start), "to": self.iso(end)})
        check(isinstance(raw, list) and len(raw) == 1 and raw[0].get("meta", {}).get("name") == self.pv,
              "Malformed retrieval PV identity")
        data = raw[0].get("data")
        check(isinstance(data, list), "Malformed retrieval sample array")
        result = []
        for event in data:
            check(type(event.get("secs")) is int and type(event.get("nanos")) is int
                  and 0 <= event["nanos"] < 1_000_000_000, "Malformed sample timestamp")
            check(type(event.get("val")) in (int, float) and math.isfinite(float(event["val"])),
                  "Malformed scalar sample value")
            result.append({"time": event["secs"] * 1_000_000_000 + event["nanos"],
                           "value": event["val"]})
        check(result == sorted(result, key=lambda event: event["time"]), "Unordered API timestamps")
        preceding = [event for event in result if event["time"] < start]
        check(len(preceding) <= 1 and (not preceding or preceding[0] == result[0])
              and all(event["time"] <= end for event in result), "Unexpected out-of-window API data")
        return [event for event in result if start <= event["time"] <= end], preceding

    @staticmethod
    def compare(events, observations):
        for event in events:
            check(any(abs(observed["time"] - event["time"]) < observed["precision_ns"] and
                      float(event["value"]) == observed["value"] for observed in observations),
                  "Retrieved timestamp/value does not match real CA")

    def acquire(self, observer, register=False):
        start = time.time_ns()
        deadline = time.monotonic() + self.bounds["samples"]
        started = time.monotonic()
        if register:
            self.http(self.mgmt, "archivePV", pv=self.pv, samplingmethod="MONITOR", samplingperiod="1.0")
        while time.monotonic() < deadline:
            try:
                status = self.http(self.mgmt, "getPVStatus", pv=self.pv)
                check(isinstance(status, list), "Malformed PV status")
                if not any(entry.get("pvName") == self.pv and entry.get("status") == "Being archived"
                           for entry in status):
                    time.sleep(2)
                    continue
                end = time.time_ns()
                events, preceding = self.samples(start, end)
                if len({event["time"] for event in events}) >= 10 and len(
                        {event["value"] for event in events}) >= 2:
                    self.compare(events, observer.events)
                    check(len(observer.resources) >= 2 and not observer.errors and
                          observer.process.poll() is None, "Incomplete resource/CA observations")
                    check(time.monotonic() <= deadline, "Fresh acquisition completed after its deadline")
                    history = {"start": start, "end": end, "events": events, "preceding": preceding}
                    self.evidence.setdefault("timing", []).append(
                        {"operation": "acquisition", "elapsed": time.monotonic() - started,
                         "bound": self.bounds["samples"]})
                    return history
            except (urllib.error.URLError, TimeoutError):
                pass
            time.sleep(2)
        raise CheckError("Fresh acquisition deadline exceeded")

    def persistent_pv(self):
        check(SAFE_NAME.fullmatch(self.pv), "Unsafe PV identifier")
        check(self.sql("SELECT COUNT(*) FROM PVTypeInfo WHERE pvName='" + self.pv + "';") == "1",
              "PV registration is not persisted in the real database")

    def save_history(self, history):
        (self.root / "history.json").write_text(json.dumps(history))

    def history(self):
        return json.loads((self.root / "history.json").read_text())

    def check_history(self):
        history = self.history()
        events, preceding = self.samples(history["start"], history["end"])
        check(events == history["events"], "Historical samples did not survive the action")
        self.persistent_pv()

    def installation(self):
        self.payload()
        self.schema()

    def acceptance(self):
        self.ready(self.bounds["application"])
        self.result("T7")
        self.result("T9")
        self.scheduled()

    def runtime(self):
        self.acceptance()
        before = self.identities()
        with Observer(self) as observation:
            started = time.monotonic()
            self.start_ioc()
            history = self.acquire(observation, register=True)
            self.evidence["ioc_startup_and_acquisition_seconds"] = time.monotonic() - started
            self.persistent_pv()
            self.save_history(history)
            boundary_start = (history["events"][0]["time"] + history["events"][1]["time"]) // 2
            boundary, preceding = self.samples(boundary_start, history["end"])
            self.compare(boundary, observation.events)
            if preceding:
                self.compare(preceding, observation.events)
            self.evidence["raw_boundary"] = {"from": boundary_start, "preceding": preceding}
            self.result("T10")
            self.expected_restart = True
            restart_started = time.monotonic()
            try:
                execute(["make", "-s", "-C", str(self.checkout), "sd_restart"],
                        timeout=self.bounds["restart"])
                remaining = self.bounds["restart"] - (time.monotonic() - restart_started)
                check(remaining > 0, "Restart deadline exceeded before application readiness")
                self.ready(remaining)
                self.evidence.setdefault("timing", []).append({"operation": "restart",
                    "elapsed": time.monotonic() - restart_started, "bound": self.bounds["restart"]})
            finally:
                self.expected_restart = False
            after = self.identities()
            check(all(before[name]["pid"] != after[name]["pid"] or
                      before[name]["start"] != after[name]["start"] for name in SERVICES),
                  "Restart did not replace all appliance JVM identities")
            self.check_history()
            self.acquire(observation)
            self.result("T11")
            (self.root / "before-reapply.json").write_text(json.dumps(self.identities()))

    def snapshot(self):
        self.check_history()
        self.evidence["identities"] = self.identities()

    def unchanged(self):
        before = json.loads((self.root / "before-reapply.json").read_text())
        after = self.identities()
        check(all(before[name]["pid"] == after[name]["pid"] and
                  before[name]["start"] == after[name]["start"] for name in SERVICES),
              "Unchanged re-apply replaced a healthy appliance")
        self.check_history()
        self.ready(self.bounds["application"])
        (self.root / "before-reinstall.json").write_text(json.dumps(after))

    def reinstalled(self):
        before = json.loads((self.root / "before-reinstall.json").read_text())
        self.installation()
        self.acceptance()
        after = self.identities()
        check(all(before[name]["pid"] != after[name]["pid"] or
                  before[name]["start"] != after[name]["start"] for name in SERVICES),
              "Forced reinstall did not replace appliance processes")
        self.check_history()
        with Observer(self) as observation:
            self.acquire(observation)
        self.result("T12")

    def negative(self):
        self.ready(self.bounds["application"])
        before = self.identities()
        path = self.install / "mgmt/temp/mgmt.pid"
        original, metadata = path.read_bytes(), path.stat()
        try:
            path.write_text(str(before["engine"]["pid"]) + "\n")
            output = self.health(expected=1)
            check("wrong-instance-base" in output, "Wrong-PID failure was not an identity failure")
            self.http(self.mgmt, "getApplianceInfo")
            check(self.identities()["engine"]["start"] == before["engine"]["start"],
                  "Wrong-PID inspection changed a genuine process")
        finally:
            path.write_bytes(original)
            os.chown(path, metadata.st_uid, metadata.st_gid)
            os.chmod(path, metadata.st_mode)
        self.health()
        restored = self.identities()
        check(all(restored[name]["pid"] == before[name]["pid"] and
                  restored[name]["start"] == before[name]["start"] for name in SERVICES),
              "Wrong-PID inspection changed a genuine appliance process")
        try:
            execute(["systemctl", "stop", self.ioc_unit])
            start = time.time_ns()
            time.sleep(3)
            fresh, preceding = self.samples(start, time.time_ns())
            check(not fresh, "Stopped IOC still satisfied fresh acquisition")
            self.evidence["ioc_loss"] = {"fresh": fresh, "preceding": preceding, "from": start}
        finally:
            self.start_ioc()
        with Observer(self) as observation:
            self.acquire(observation)
        self.check_history()
        self.result("T13")

    def stop(self):
        execute(["systemctl", "stop", self.ioc_unit])


def main():
    os.environ["PATH"] = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    os.environ["TZ"] = "UTC"
    for name in ("BASH_ENV", "ENV", "CDPATH"):
        os.environ.pop(name, None)
    os.umask(0o077)
    check(os.geteuid() == 0, "Guest verifier requires sudo on its owned disposable VM")
    check(len(sys.argv) == 3 and sys.argv[1] in
          {"installation", "runtime", "snapshot", "unchanged", "reinstalled", "negative", "stop"},
          "Invalid guest operation")
    guest = Guest(sys.argv[2])
    try:
        getattr(guest, sys.argv[1])()
    except (Exception, KeyboardInterrupt) as error:
        guest.evidence["failure"] = {"category": type(error).__name__, "message": str(error)}
        (guest.root / ("failed-" + sys.argv[1] + ".json")).write_text(json.dumps(guest.evidence))
        print(json.dumps(guest.evidence))
        return 1
    print(json.dumps(guest.evidence))
    return 0


def interrupt(*unused):
    raise KeyboardInterrupt()


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, interrupt)
    sys.exit(main())
