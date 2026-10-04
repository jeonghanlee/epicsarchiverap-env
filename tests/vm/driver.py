#!/usr/bin/env python3
"""Coordinate pinned provisioning tools and retain independent VM evidence."""

import argparse
import datetime as dt
import fcntl
import hashlib
import ipaddress
import json
import os
from pathlib import Path
import re
import secrets
import shlex
import shutil
import signal
import stat
import subprocess
import sys
import time
import xml.etree.ElementTree as ET


HERE = Path(__file__).resolve().parent
TOP = HERE.parents[1]
SCHEMA = 1
OS_NAMES = ("debian13", "rocky8")
BACKENDS = ("socket", "tcp", "sqlite")
POSITIVE = tuple(f"{os_name}-{backend}" for os_name in OS_NAMES for backend in BACKENDS)
NEGATIVE = tuple(f"{os_name}-build-failure" for os_name in OS_NAMES)
MATRIX = POSITIVE + NEGATIVE
DEFAULT_BOUNDS = {"vm": 1800, "build": 2700, "application": 300, "samples": 180,
                  "restart": 300, "command": 120, "shutdown": 90}
FULL_REF = re.compile(r"[0-9a-f]{40}")
SAFE_NAME = re.compile(r"[a-zA-Z0-9][a-zA-Z0-9_.-]*")
REQUIRED = {"cloud", "ansible", "candidate", "fixture", "images", "guest", "ssh"}
FIXTURE_REF = "5e6c12668c9c55f71ae1ba1c3a4384d86049b806"
FIXTURE_SHA256 = "85778e0ed007ef196ab963a582c9ba7ddbff96bf68e91edab118d1e9ff497e32"
UNITTEST_SKIPS = re.compile(r"\bskipped=[1-9][0-9]*\b")
GUEST_HOSTNAME_LIMIT = 63


class Invalid(Exception):
    pass


class Incomplete(Exception):
    pass


class Failed(Exception):
    pass


def utc():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def local_suite_complete(output):
    """Require shell and unittest checks to run without skipped assertions."""
    return (isinstance(output, str) and "[SKIP]" not in output
            and not UNITTEST_SKIPS.search(output))


def domain_mac(tree, network, uuid, name):
    """Require one interface on the owned domain's selected network."""
    if tree.findtext("uuid") != uuid or tree.findtext("name") != name:
        raise Invalid("Domain UUID/name identity mismatch")
    matches = [node.find("mac").get("address", "").lower()
               for node in tree.findall("./devices/interface")
               if node.find("source") is not None and node.find("mac") is not None
               and node.find("source").get("network") == network]
    if len(matches) != 1 or not re.fullmatch(r"(?:[0-9a-f]{2}:){5}[0-9a-f]{2}", matches[0]):
        raise Invalid("Cannot identify one owned network interface MAC")
    return matches[0]


def owned_reservation(reservations, mac, name):
    """Bind live and persistent DHCP entries to the actual interface MAC."""
    selected = []
    for kind in ("live", "persistent"):
        entries = reservations[kind]
        matches = [entry for entry in entries if entry.get("mac", "").lower() == mac]
        if len(matches) != 1 or matches[0].get("name") not in (None, "", name):
            raise Invalid("Missing, ambiguous or foreign DHCP MAC ownership")
        entry = matches[0]
        try:
            ipaddress.IPv4Address(entry["ip"])
        except (KeyError, ValueError) as error:
            raise Invalid("Owned DHCP entry requires an IPv4 address") from error
        if any(other is not entry and other.get("ip") == entry["ip"] for other in entries):
            raise Invalid("Owned DHCP address overlaps another reservation")
        selected.append(entry)
    if selected[0] != selected[1]:
        raise Invalid("Live/persistent DHCP ownership mismatch")
    return selected[0]


def guest_facts_command():
    """Return the pre-installation guest facts command; it needs no interpreter."""
    # A fresh base image may lack python3 before Ansible installs it.
    return ["sh", "-c",
            "set -e; echo @@os; cat /etc/os-release; "
            "echo @@cpus; getconf _NPROCESSORS_ONLN; "
            "echo @@hostname; hostname; "
            "echo @@interfaces; ip -j address; "
            "echo @@memory; cat /proc/meminfo; "
            "echo @@filesystem; stat -f -c '%S %b %a' /"]


def parse_guest_facts(output):
    """Parse the delimited guest facts output into guest resource fields."""
    sections, name = {}, None
    for line in output.splitlines():
        if line.startswith("@@"):
            name = line[2:]
            if name in sections:
                raise Failed("Duplicated guest facts section")
            sections[name] = []
        elif name is None:
            raise Failed("Guest facts output precedes its first section")
        else:
            sections[name].append(line)
    if set(sections) != {"os", "cpus", "hostname", "interfaces", "memory", "filesystem"}:
        raise Failed("Missing or unexpected guest facts section")
    try:
        cpus, = sections["cpus"]
        hostname, = sections["hostname"]
        block, total, available = (int(field) for field in sections["filesystem"][0].split())
        if len(sections["filesystem"]) != 1:
            raise ValueError("filesystem")
        interfaces = json.loads("\n".join(sections["interfaces"]))
        if not isinstance(interfaces, list) or not sections["os"] or not sections["memory"]:
            raise ValueError("content")
        return {"os": "\n".join(sections["os"]) + "\n", "cpus": int(cpus),
                "hostname": hostname, "interfaces": interfaces,
                "memory": "\n".join(sections["memory"]) + "\n",
                "root_bytes": block * total, "free_bytes": block * available}
    except (ValueError, IndexError) as error:
        raise Failed("Malformed guest facts section") from error


HANDOFF_FIELDS = {"schema", "os_selector", "prefix", "node", "creation_id", "uuid", "vm_name",
                  "mac", "address", "disk", "seed", "record", "tool_ref"}
CREATION_ID = re.compile(r"\d{8}T\d{6}Z-[0-9a-f]{12}")
DOMAIN_UUID = re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")
MAC_ADDRESS = re.compile(r"(?:[0-9a-f]{2}:){5}[0-9a-f]{2}")
FRESH_UNIT_PREFIXES = ("epicsarchiverap", "archiver-build", "mariadb", "mysql")
FRESH_SCRIPT = (
    'for p in "$@"; do if [ -e "$p" ] || [ -L "$p" ]; then echo "present $p"; '
    'else echo "absent $p"; fi; done; echo @@opt; ls -A /opt; echo @@units; '
    "systemctl list-unit-files --type=service --full --no-legend --no-pager; "
    'echo "@@units_exit $?"')


def case_from_handoff(name, handoff, config):
    """Validate a cloud-provision guest handoff and derive the owned case selectors."""
    if name not in MATRIX:
        raise Invalid("Unknown case")
    if (not isinstance(handoff, dict) or set(handoff) != HANDOFF_FIELDS
            or type(handoff["schema"]) is not int or handoff["schema"] != 1):
        raise Invalid("Handoff requires exactly the schema 1 fields")
    if any(not isinstance(handoff[field], str) for field in HANDOFF_FIELDS - {"schema"}):
        raise Invalid("Handoff values must be strings")
    os_name, backend = name.split("-", 1)
    if (handoff["os_selector"] != os_name + "-archiver-dev" or
            handoff["prefix"] != config["cloud"]["prefix"]):
        raise Invalid("Handoff OS selector or prefix differs from the case and configuration")
    if (not SAFE_NAME.fullmatch(handoff["node"]) or not CREATION_ID.fullmatch(handoff["creation_id"])
            or not DOMAIN_UUID.fullmatch(handoff["uuid"]) or not MAC_ADDRESS.fullmatch(handoff["mac"])
            or not FULL_REF.fullmatch(handoff["tool_ref"])):
        raise Invalid("Malformed handoff identity")
    try:
        address = str(ipaddress.IPv4Address(handoff["address"]))
    except ValueError as error:
        raise Invalid("Handoff address must be an IPv4 address") from error
    vm_name = "-".join((handoff["prefix"], handoff["os_selector"], handoff["node"],
                        handoff["creation_id"]))
    disk = Path(config["images"][os_name]["directory"]) / (vm_name + ".qcow2")
    derived = {"vm_name": vm_name, "disk": str(disk), "record": str(disk) + ".creation-record",
               "seed": str(disk.with_name(vm_name + "-seed.iso"))}
    if address != handoff["address"] or any(handoff[field] != value for field, value in derived.items()):
        raise Invalid("Handoff names differ from the names derived from its selectors")
    return {"name": name, "os": os_name, "backend": "sqlite" if backend == "build-failure" else backend,
            "negative": backend == "build-failure", "node": handoff["node"],
            "creation_id": handoff["creation_id"], "uuid": handoff["uuid"], "results": {},
            "lifecycle": "adopted", "tool_ref": handoff["tool_ref"],
            "handoff": {"mac": handoff["mac"], "address": address}, **derived}


def disk_bytes(size):
    """Convert a configured disk size such as 20G to bytes."""
    return int(size[:-1]) * 1024 ** 3


def tool_origin_command(path):
    """Return the command reading a tool checkout's stored origin URL."""
    # "git remote get-url" would apply the user's insteadOf rewrite rules.
    return ["git", "-C", str(path), "config", "--get", "remote.origin.url"]


def publication_env():
    """Return an environment that clones over anonymous HTTPS, ignoring user rewrite rules."""
    return dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1",
                GIT_TERMINAL_PROMPT="0")


def stored_host_key_command(address):
    """Return the lookup of the host key cloud-provision stored for a guest address."""
    return ["ssh-keygen", "-F", address, "-f", str(Path.home() / ".ssh" / "known_hosts")]


def host_key_lines(output):
    """Keep the known-hosts entries of an ssh-keygen -F lookup, without its comments."""
    return [line for line in output.splitlines() if line.strip() and not line.startswith("#")]


def ssh_options(known_hosts):
    """Return SSH options that accept only the pinned guest host key."""
    return ["-o", "StrictHostKeyChecking=yes", "-o", f"UserKnownHostsFile={known_hosts}"]


def ansible_connection_variables(known_hosts, key):
    """Return Ansible SSH variables that keep the pinned host key in force."""
    # A tool configuration with host_key_checking disabled would otherwise prepend
    # StrictHostKeyChecking=no, and SSH uses the first value of an option.
    return {"ansible_host_key_checking": True, "ansible_ssh_private_key_file": key,
            "ansible_ssh_common_args": shlex.join(ssh_options(known_hosts))}


def published_origin(url):
    """Accept only a credential-free HTTPS origin."""
    return url.startswith("https://") and "@" not in url


def fresh_probe_command(paths):
    """Return the shell-only probe of installation paths and service unit files."""
    return ["sudo", "-n", "sh", "-c", FRESH_SCRIPT, "sh", *paths]


def parse_fresh_probe(output, count):
    """Parse the fresh-guest probe into path presence, /opt entries and service units."""
    paths, opt, units, exit_status, section = {}, [], [], None, "paths"
    for line in output.splitlines():
        if line in ("@@opt", "@@units"):
            section = line[2:]
        elif line.startswith("@@units_exit "):
            exit_status = int(line.split()[1])
        elif section == "paths":
            state, _, path = line.partition(" ")
            if state not in ("present", "absent") or not path:
                raise Failed("Malformed fresh-guest path line")
            paths[path] = state == "present"
        elif section == "opt":
            opt.append(line)
        elif line.strip():
            units.append(line.split()[0])
    if exit_status is None or len(paths) != count:
        raise Failed("Fresh-guest probe output is incomplete")
    return {"paths": paths, "opt": sorted(opt), "units_exit": exit_status, "units": units}


def digest(path):
    checksum = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            checksum.update(block)
    return checksum.hexdigest()


def save(path, value):
    """Persist evidence atomically without following an existing target symlink."""
    path = Path(path)
    if path.is_symlink():
        raise Invalid("Evidence target is a symlink")
    temporary = path.with_name(path.name + "." + secrets.token_hex(6))
    fd = os.open(str(temporary), os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w") as stream:
        json.dump(value, stream, indent=2, sort_keys=True)
        stream.write("\n")
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)


def private_root(path):
    path = Path(path)
    if path.is_symlink() or not path.is_dir():
        raise Invalid("Run context must be a real private directory")
    info = path.stat()
    if info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) & 0o077:
        raise Invalid("Run context must belong to this user and have mode 0700")
    return path.resolve()


def load(path):
    try:
        if Path(path).is_symlink():
            raise Invalid("Symlink input is refused")
        return json.loads(Path(path).read_text())
    except (OSError, ValueError) as error:
        raise Invalid(f"Unreadable JSON input: {error}") from error


def run(command, timeout=120, env=None, log=None, check=True, input_data=None, cwd=None,
        separate_stderr=False):
    """Run the actual command with bounded lifetime and retained raw evidence."""
    started = time.monotonic()
    process = subprocess.Popen(command, stdin=subprocess.PIPE if input_data is not None
                               else subprocess.DEVNULL, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE if separate_stderr else subprocess.STDOUT,
                               text=True, env=env,
                               start_new_session=True, cwd=cwd)
    try:
        output, errors = process.communicate(input_data, timeout=timeout)
    except (subprocess.TimeoutExpired, KeyboardInterrupt):
        os.killpg(process.pid, signal.SIGTERM)
        try:
            output, errors = process.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            output, errors = process.communicate()
        if log:
            save(log, {"command": command, "at": utc(), "elapsed": time.monotonic() - started,
                       "exit": process.returncode, "output": output, "stderr": errors,
                       "interrupted": True})
        raise
    if log:
        save(log, {"command": command, "at": utc(), "elapsed": time.monotonic() - started,
                   "exit": process.returncode, "output": output, "stderr": errors})
    if check and process.returncode:
        raise Failed(f"Command exited {process.returncode}; retained command evidence")
    return process.returncode, output


def required_string(value, label, absolute=False):
    if not isinstance(value, str) or not value or any(c in value for c in "\0\r\n"):
        raise Invalid(f"Invalid {label}")
    if absolute and (not value.startswith("/") or Path(value).resolve() == Path("/")):
        raise Invalid(f"{label} must be an absolute non-root path")
    return value


def validate(config):
    try:
        return validate_fields(config)
    except (TypeError, KeyError, AttributeError) as error:
        raise Invalid("Malformed configuration field types") from error


def validate_fields(config):
    if not isinstance(config, dict) or set(config) != REQUIRED:
        raise Invalid("Configuration requires exactly: " + ", ".join(sorted(REQUIRED)))
    if any(not isinstance(config[name], dict) for name in REQUIRED):
        raise Invalid("Configuration sections must be objects")
    for tool in ("cloud", "ansible"):
        item = config[tool]
        if set(item) != ({"path", "ref", "uri", "network", "prefix"} if tool == "cloud"
                         else {"path", "ref", "inventory"}):
            raise Invalid(f"Invalid {tool} fields")
        required_string(item["path"], f"{tool} path", True)
        if not isinstance(item["ref"], str) or not FULL_REF.fullmatch(item["ref"]):
            raise Invalid("Tool refs must be full commit IDs")
    for name in ("network", "prefix"):
        if not SAFE_NAME.fullmatch(config["cloud"][name]):
            raise Invalid(f"Invalid cloud {name}")
    if config["cloud"]["uri"] != "qemu:///system" or config["cloud"]["network"] != "lab":
        raise Invalid("The existing cloud tool requires qemu:///system and the lab network")
    for name in ("env_ref", "source_ref"):
        if not FULL_REF.fullmatch(config["candidate"].get(name, "")):
            raise Invalid("Normal candidate refs must be full commit IDs")
    if set(config["candidate"]) != {"env_ref", "source_ref", "env_url", "source_url"}:
        raise Invalid("Invalid candidate fields")
    for name in ("env_url", "source_url"):
        url = required_string(config["candidate"][name], name)
        if not re.fullmatch(r"https://[A-Za-z0-9._:/-]+", url) or "@" in url:
            raise Invalid("Candidate clone URLs must be HTTPS without credentials")
    fixture = config["fixture"]
    if set(fixture) != {"repository", "ref", "path", "sha256"}:
        raise Invalid("Invalid fixture fields")
    required_string(fixture["repository"], "fixture repository", True)
    if not FULL_REF.fullmatch(fixture["ref"]) or not re.fullmatch("[0-9a-f]{64}", fixture["sha256"]):
        raise Invalid("Fixture requires a full commit and SHA256")
    if fixture["ref"] != FIXTURE_REF or fixture["sha256"] != FIXTURE_SHA256:
        raise Invalid("Fixture identity must match the accepted original commit and SHA256")
    if fixture["path"] != "src/resources/test/UnitTestPVs.db":
        raise Invalid("The original tracked UnitTestPVs.db fixture is required")
    if set(config["images"]) != set(OS_NAMES):
        raise Invalid("Both accepted OS images are required")
    for os_name, image in config["images"].items():
        if set(image) != {"directory", "filename", "sha256", "disk_size", "minimum_build_free_bytes"}:
            raise Invalid("Invalid image fields")
        required_string(image["directory"], "image directory", True)
        expected = ("debian-13-genericcloud-amd64-daily.qcow2" if os_name == "debian13"
                    else "Rocky-8-GenericCloud-Base.latest.x86_64.qcow2")
        if image["filename"] != expected or not re.fullmatch("[0-9a-f]{64}", image["sha256"]):
            raise Invalid("Image identity does not match the real provisioner")
        if not re.fullmatch("[1-9][0-9]*G", image["disk_size"]):
            raise Invalid("Disk size must be a positive integer followed by G")
        if type(image["minimum_build_free_bytes"]) is not int or image["minimum_build_free_bytes"] <= 0:
            raise Invalid("An explicit positive cold-build free-space threshold is required")
    guest = config["guest"]
    if set(guest) != {"source_parent", "install_parent", "store_top", "user", "group", "epics_bin"}:
        raise Invalid("Invalid guest fields")
    for name in ("source_parent", "install_parent", "store_top"):
        required_string(guest[name], name, True)
        if not re.fullmatch(r"/[A-Za-z0-9_./-]+", guest[name]):
            raise Invalid("Guest roots must be safe literal shell paths")
    if not isinstance(guest["epics_bin"], dict) or set(guest["epics_bin"]) != set(OS_NAMES):
        raise Invalid("EPICS binary directories must be specified for both OS cases")
    for directories in guest["epics_bin"].values():
        for directory in required_string(directories, "EPICS directories").split(":"):
            required_string(directory, "EPICS directory", True)
    for name in ("user", "group"):
        if not SAFE_NAME.fullmatch(guest[name]):
            raise Invalid("Invalid guest service identity")
    if set(config["ssh"]) != {"user", "key"} or not SAFE_NAME.fullmatch(config["ssh"]["user"]):
        raise Invalid("SSH requires user and key")
    if config["ssh"]["user"] != "vmadmin":
        raise Invalid("The existing cloud tool provisions and probes the vmadmin account")
    required_string(config["ssh"]["key"], "SSH key", True)
    required_string(config["ansible"]["inventory"], "Ansible inventory", True)
    return config


class Driver:
    def __init__(self, root):
        self.root = private_root(root)
        self.state = load(self.root / "run.json")
        required = {"schema", "config", "mode", "cases", "driver_sha256", "guest_sha256"}
        if not isinstance(self.state, dict) or not required.issubset(self.state) or self.state.get(
                "schema") != SCHEMA or not isinstance(self.state["cases"], list):
            raise Invalid("Unsupported or incomplete run context")
        if any(not isinstance(case, dict) or case.get("name") not in MATRIX
               for case in self.state["cases"]):
            raise Invalid("Invalid owned case context")
        self.config = validate(self.state["config"])
        for case in self.state["cases"]:
            self.case_identity(case)
        if self.state.get("driver_sha256") != digest(HERE / "driver.py"):
            raise Invalid("Context belongs to another driver version")
        if self.state.get("guest_sha256") != digest(HERE / "guest.py"):
            raise Invalid("Context belongs to another guest verifier version")
        self.log_number = len(list(self.root.glob("command-*.json")))
        self.recorded = False

    def case_identity(self, case):
        """Bind lifecycle command selectors to the recorded resource names."""
        os_name, backend = case["name"].split("-", 1)
        negative = backend == "build-failure"
        if case.get("os") != os_name or case.get("backend") != (
                "sqlite" if negative else backend) or case.get("negative") is not negative:
            raise Invalid("Case selectors do not match the accepted matrix identity")
        if not isinstance(case.get("node"), str) or not SAFE_NAME.fullmatch(case["node"]):
            raise Invalid("Invalid lifecycle node selector")
        if not isinstance(case.get("creation_id"), str) or not re.fullmatch(
                r"\d{8}T\d{6}Z-[0-9a-f]{12}", case["creation_id"]):
            raise Invalid("Invalid lifecycle creation selector")
        expected = (self.config["cloud"]["prefix"] + "-" + os_name + "-archiver-dev-" +
                    case["node"] + "-" + case["creation_id"])
        disk = Path(self.config["images"][os_name]["directory"]) / (expected + ".qcow2")
        if case.get("vm_name") != expected or case.get("disk") != str(disk) or case.get(
                "record") != str(disk) + ".creation-record" or case.get("seed") != str(
                disk.with_name(expected + "-seed.iso")):
            raise Invalid("Lifecycle selectors do not match recorded VM and file identities")

    def persist(self):
        save(self.root / "run.json", self.state)
        save(self.root / "report.json", {
            "schema": SCHEMA, "at": utc(), "candidate": {
                name: self.config["candidate"][name] for name in ("env_ref", "source_ref")},
            "failure": self.state.get("failure"),
            "cases": [{"name": case["name"], "results": case["results"],
                       "cleanup": case.get("cleanup", {"result": "Pending"})}
                      for case in self.state["cases"]],
            "full_matrix_verdict": self.verdict()})

    def command(self, argv, **kwargs):
        self.log_number += 1
        prefix = getattr(self, "log_prefix", "command")
        return run(argv, log=self.root / f"{prefix}-{self.log_number:05}.json", **kwargs)

    def virsh(self, *args):
        return self.command(["virsh", "--connect", self.config["cloud"]["uri"], *args])[1]

    def snapshot(self):
        domains = {}
        for uuid in self.virsh("list", "--all", "--uuid").split():
            tree = ET.fromstring(self.virsh("dumpxml", uuid))
            domains[uuid] = tree.findtext("name")
        network = self.config["cloud"]["network"]
        reservations = {}
        for kind, flags in (("live", ()), ("persistent", ("--inactive",))):
            tree = ET.fromstring(self.virsh("net-dumpxml", network, *flags))
            reservations[kind] = sorted([dict(entry.attrib)
                                         for entry in tree.findall("./ip/dhcp/host")],
                                        key=lambda entry: json.dumps(entry, sort_keys=True))
        return {"domains": domains, "reservations": reservations}

    def ssh(self, case, command, **kwargs):
        config = self.config["ssh"]
        options = ["-F", "/dev/null", "-i", config["key"], "-o", "BatchMode=yes",
                   "-o", "ConnectTimeout=10", *ssh_options(self.known_hosts(case))]
        return self.command(["ssh", *options, f"{config['user']}@{case['address']}",
                             shlex.join(command)], separate_stderr=True, **kwargs)

    def known_hosts(self, case):
        return self.root / (case["creation_id"] + ".known_hosts")

    def pin_host_key(self, case):
        """Copy the host key cloud-provision stored at creation into the guest's own file."""
        rc, output = self.command(stored_host_key_command(case["address"]), check=False)
        lines = host_key_lines(output) if rc == 0 else []
        if not lines:
            raise Invalid("cloud-provision stored no host key for the handed-off address")
        path = self.known_hosts(case)
        if path.is_symlink():
            raise Invalid("Known-hosts target is a symlink")
        fd = os.open(str(path), os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w") as stream:
            stream.write("\n".join(lines) + "\n")

    def leases(self):
        """Return the configured network's active DHCP leases as (MAC, IPv4) pairs."""
        result = []
        for line in self.virsh("net-dhcp-leases", self.config["cloud"]["network"]).splitlines():
            fields = line.split()
            if len(fields) >= 5 and MAC_ADDRESS.fullmatch(fields[2].lower()) and "/" in fields[4]:
                result.append((fields[2].lower(), fields[4].split("/", 1)[0]))
        return result

    def prepare(self):
        for executable in ("git", "virsh", "ssh", "ssh-keygen", "scp", "ansible-playbook"):
            if not shutil.which(executable):
                raise Incomplete(f"Required executable unavailable: {executable}")
        if not Path(self.config["ssh"]["key"]).is_file():
            raise Incomplete("SSH identity is unavailable")
        public_keys = [Path.home() / ".ssh" / name for name in ("id_ed25519.pub", "id_rsa.pub")]
        selected = next((path for path in public_keys if path.is_file()), None)
        if selected is None or Path(str(selected)[:-4]).resolve() != Path(
                self.config["ssh"]["key"]).resolve():
            raise Invalid("SSH key must match the existing cloud tool's first default key")
        for tool, files in (("cloud", ("bin/generate_ansible_inventory.bash",)),
                            ("ansible", ("playbooks/species/archiver_dev.yml",
                                         "playbooks/species/archiver_dev_sqlite.yml"))):
            path = self.config[tool]["path"]
            head = self.command(["git", "-C", path, "rev-parse", "HEAD"])[1].strip()
            if head != self.config[tool]["ref"]:
                raise Invalid("Tool checkout does not match its requested immutable ref")
            if self.command(["git", "-C", path, "status", "--porcelain", "--untracked-files=no"])[1]:
                raise Invalid("Tool checkout has tracked modifications")
            if any(not (Path(path) / name).is_file() for name in files):
                raise Incomplete("Pinned tool does not provide the required public entrypoints")
            url = self.command(tool_origin_command(path))[1].strip()
            if not published_origin(url):
                raise Invalid("Tool origin must be HTTPS without credentials")
            clone = self.root / ("tool-" + tool)
            self.command(["git", "clone", "--no-checkout", url, str(clone)],
                         timeout=DEFAULT_BOUNDS["build"], env=publication_env())
            rc, _ = self.command(["git", "-C", str(clone), "cat-file", "-e",
                                  head + "^{commit}"], check=False)
            if rc:
                raise Invalid("Pinned tool commit is not present in its published repository")
        if not Path(self.config["ansible"]["inventory"]).is_file():
            raise Incomplete("Maintained Ansible inventory is unavailable")
        for image in self.config["images"].values():
            path = Path(image["directory"]) / image["filename"]
            if not path.is_file() or path.is_symlink() or digest(path) != image["sha256"]:
                raise Invalid("Base image is missing or does not match its digest")
        for kind in ("env", "source"):
            checkout = self.root / ("candidate-" + kind)
            self.command(["git", "clone", "--no-checkout", self.config["candidate"][kind + "_url"],
                          str(checkout)], timeout=DEFAULT_BOUNDS["build"], env=publication_env())
            ref = self.config["candidate"][kind + "_ref"]
            rc, _ = self.command(["git", "-C", str(checkout), "checkout", "--detach", ref], check=False)
            if rc:
                raise Invalid("Normal candidate ref is not available from its published repository")
            if self.command(["git", "-C", str(checkout), "rev-parse", "HEAD"])[1].strip() != ref:
                raise Invalid("Cloned normal candidate identity mismatch")
        for name in ("tests/vm/driver.py", "tests/vm/guest.py", "tests/vm/local.py",
                     "tests/phase3-docker.bash", "tests/phase4-vm.bash", "tests/run-all-tests.bash"):
            published = self.root / "candidate-env" / name
            if not published.is_file() or digest(published) != digest(TOP / name):
                raise Invalid("Publish the requested implementation before VM acceptance")
        checkout = self.root / "candidate-env"
        (checkout / "epicsarchiverap-maven-src").symlink_to(self.root / "candidate-source",
                                                         target_is_directory=True)
        _, local_output = self.command(
            ["bash", str(checkout / "tests/run-all-tests.bash"), "--local"],
            cwd=str(checkout), timeout=DEFAULT_BOUNDS["build"])
        if not local_suite_complete(local_output):
            raise Incomplete("Candidate local suite skipped required checks")
        proof = self.root / f"command-{self.log_number:05}.json"
        self.state["local_suite"] = {"at": utc(), "result": "Pass",
                                     "env_ref": self.config["candidate"]["env_ref"],
                                     "command_file": proof.name, "sha256": digest(proof)}
        fixture = self.config["fixture"]
        data = subprocess.check_output(["git", "-C", fixture["repository"], "show",
                                        fixture["ref"] + ":" + fixture["path"]])
        if hashlib.sha256(data).hexdigest() != fixture["sha256"]:
            raise Invalid("Original committed fixture digest mismatch")
        (self.root / "UnitTestPVs.db").write_bytes(data)
        self.state["fixture_counts"] = {
            "records": len(re.findall(rb"record\s*\(", data)),
            "scans": {period.decode(): len(re.findall(
                rb'field\s*\(\s*SCAN\s*,\s*"' + re.escape(period) + rb'"', data))
                      for period in (b".1 second", b"1 second", b"10 second")}}
        self.state["tool_versions"] = {}
        for tool, option in (("git", "--version"), ("virsh", "--version"),
                             ("ansible-playbook", "--version"), ("ssh", "-V")):
            self.state["tool_versions"][tool] = self.command([tool, option])[1]
        self.state["baseline"] = self.snapshot()
        self.state["preflight"] = {"at": utc(), "result": "Pass"}
        self.persist()

    def install(self, case, force=False, fault=False):
        self.verify_live_case(case)
        cfg = self.config
        variables = {
            "repo_archiver_env": cfg["candidate"]["env_url"],
            "archiver_env_ref": cfg["candidate"]["env_ref"],
            "archiver_maven_src_tag": case["fault_ref"] if fault else cfg["candidate"]["source_ref"],
            "archiver_site_id": "als", "archiver_java_heapsize": "256M",
            "path_archiver_env_src": cfg["guest"]["source_parent"],
            "archiver_install_parent": cfg["guest"]["install_parent"],
            "archiver_storage_top": cfg["guest"]["store_top"],
            "archiver_user": cfg["guest"]["user"], "archiver_group": cfg["guest"]["group"],
            "archiver_db_backend": "sqlite" if case["backend"] == "sqlite" else "mariadb",
            "archiver_db_socket": "auto" if case["backend"] == "socket" else "",
            "mariadb_skip_networking": case["backend"] == "socket",
            "archiver_force_reinstall": force,
            **ansible_connection_variables(self.known_hosts(case), cfg["ssh"]["key"]),
        }
        path = self.root / (case["name"] + "-variables.json")
        save(path, variables)
        play = "archiver_dev_sqlite" if case["backend"] == "sqlite" else "archiver_dev"
        return self.command(["ansible-playbook", "-i", cfg["ansible"]["inventory"],
                             "-i", str(self.root / (case["name"] + ".ini")), "--limit", case["vm_name"],
                             "-e", "@" + str(path), str(Path(cfg["ansible"]["path"]) /
                                                      f"playbooks/species/{play}.yml")],
                            timeout=DEFAULT_BOUNDS["build"], check=not fault,
                            cwd=cfg["ansible"]["path"],
                            env=dict(os.environ, ANSIBLE_CONFIG=str(
                                Path(cfg["ansible"]["path"]) / "ansible.cfg")))

    def guest(self, case, action, **kwargs):
        self.verify_live_case(case)
        unit = "archiver-verifier-" + case["creation_id"] + "-" + action + ".service"
        helpers = case.setdefault("helper_units", [])
        for owned in (unit, "archiver-test-ioc-" + case["creation_id"] + ".service"):
            if owned not in helpers:
                helpers.append(owned)
        self.persist()
        _, output = self.ssh(case, ["sudo", "-n", "systemd-run", "--quiet", "--wait", "--pipe",
                                   "--collect", "--unit=" + unit, "--property=KillMode=control-group",
                                   "--property=TimeoutStopSec=15s", "/usr/bin/python3", "-I",
                                   case["remote"] + "/guest.py",
                                   action, case["remote"] + "/case.json"],
                             timeout=DEFAULT_BOUNDS["build"], **kwargs)
        try:
            result = json.loads(output)
        except ValueError as error:
            raise Failed("Guest verifier did not return valid structured evidence") from error
        if result.get("case_name") != case["name"] or result.get("creation_id") != case["creation_id"]:
            raise Failed("Guest evidence belongs to another installation context")
        path = self.root / f"{case['name']}-{action}.json"
        save(path, result)
        case.setdefault("artifacts", {})[action] = digest(path)
        return result

    def stop_helpers(self):
        errors = []
        for case in self.state["cases"]:
            if not case.get("helper_units") or case.get("lifecycle") == "verified":
                continue
            try:
                self.verify_live_case(case)
                allowed = {"archiver-test-ioc-" + case["creation_id"] + ".service",
                           "archiver-interrupt-" + case["creation_id"] + ".service"}
                allowed.update("archiver-verifier-" + case["creation_id"] + "-" + action + ".service"
                               for action in ("installation", "runtime", "snapshot", "unchanged",
                                              "reinstalled", "negative", "stop"))
                for unit in case["helper_units"]:
                    if unit not in allowed:
                        raise Invalid("Unowned helper unit refused")
                    self.ssh(case, ["sudo", "-n", "systemctl", "stop", unit], check=False, timeout=30)
                    _, raw = self.ssh(case, ["sudo", "-n", "systemctl", "show", unit,
                                            "-p", "LoadState", "-p", "ActiveState", "-p", "MainPID"],
                                     check=False)
                    state = dict(line.split("=", 1) for line in raw.splitlines() if "=" in line)
                    if state.get("LoadState") not in ("loaded", "not-found") or state.get(
                            "ActiveState") not in ("inactive", "failed") or state.get("MainPID") != "0":
                        raise Failed("Owned helper shutdown could not be confirmed")
            except (Exception, KeyboardInterrupt) as error:
                errors.append({"case": case["name"], "category": type(error).__name__})
        self.state["helper_stop_errors"] = errors

    def verify_live_case(self, case):
        self.case_identity(case)
        if not case.get("uuid") or not case.get("reservation"):
            raise Invalid("Live operation requires complete VM ownership")
        if case["uuid"] in self.state.get("baseline", {}).get("domains", {}):
            raise Invalid("Live target overlaps the preservation baseline")
        if not re.fullmatch(r"\d{8}T\d{6}Z-[0-9a-f]{12}", case["creation_id"]) or not SAFE_NAME.fullmatch(
                case["node"]):
            raise Invalid("Invalid creation identity")
        expected_name = (self.config["cloud"]["prefix"] + "-" + case["os"] + "-archiver-dev-" +
                         case["node"] + "-" + case["creation_id"])
        if case["vm_name"] != expected_name:
            raise Invalid("Live VM name does not match its creation identity")
        record = dict(line.split("=", 1) for line in Path(case["record"]).read_text().splitlines()
                      if "=" in line)
        if record.get("image_id") != case["creation_id"] or record.get("image_name") != case["vm_name"] + ".qcow2":
            raise Invalid("Live creation record mismatch")
        tree = ET.fromstring(self.virsh("dumpxml", case["uuid"]))
        mac = domain_mac(tree, self.config["cloud"]["network"], case["uuid"], case["vm_name"])
        if mac != case["reservation"]["mac"].lower():
            raise Invalid("Recorded live VM identity has changed")
        if case["address"] != case["reservation"]["ip"]:
            raise Invalid("Recorded SSH/DHCP identity mismatch")
        snapshot = self.snapshot()
        if owned_reservation(snapshot["reservations"], mac, case["vm_name"]) != case["reservation"]:
            raise Invalid("Recorded live DHCP ownership has changed")
        if self.virsh("domstate", case["uuid"]).strip() != "running":
            raise Invalid("Runtime requires the recorded live installation VM")

    def adopt(self, name, handoff):
        """Verify a handed-off fresh guest without changing the run, then run one case on it."""
        if self.state.get("failure"):
            raise Invalid("The run already holds a failure; start a separate run")
        if self.state.get("preflight", {}).get("result") != "Pass":
            raise Invalid("A case requires an initialized run")
        if any(item["name"] == name for item in self.state["cases"]):
            raise Invalid("The case is already recorded in this run")
        case = case_from_handoff(name, handoff, self.config)
        if case["uuid"] in self.state["baseline"]["domains"] or any(
                case["uuid"] == item.get("uuid") for item in self.state["cases"]):
            raise Invalid("The handed-off guest overlaps the baseline or an earlier case")
        # Every check before the case is recorded refuses the handoff without failing the run.
        try:
            snapshot = self.snapshot()
            self.capture_ownership(case, snapshot)
            self.observe_fresh(case)
            if case["negative"]:
                self.absent_source_ref(case)
        except (Failed, OSError, ValueError, KeyError, TypeError, ET.ParseError,
                subprocess.SubprocessError) as error:
            raise Invalid("Handed-off guest refused before any change: " + str(error)) from error
        # Earlier guests still owned and present prove the cumulative ownership of T15.
        case["previous_owned"] = [
            item["uuid"] for item in self.state["cases"]
            if snapshot["domains"].get(item.get("uuid")) == item["vm_name"] and all(
                item.get("reservation") in snapshot["reservations"][kind]
                for kind in ("live", "persistent"))]
        case["adoption_snapshot"] = snapshot
        case["results"]["T3"] = {"result": "Pass", "at": utc()}
        save(self.root / (name + "-handoff.json"), handoff)
        self.state["cases"].append(case)
        self.recorded = True
        self.persist()
        if case["negative"]:
            rc, output = self.install(case, fault=True)
            _, journal = self.ssh(case, ["sudo", "-n", "journalctl", "-u", "archiver-build",
                                          "--no-pager", "-n", "300"], check=False)
            if not rc or case["fault_ref"] not in output + journal or not re.search(
                    "invalid reference|reference is not a tree|pathspec.*did not match", output + journal):
                raise Failed("T14 did not observe the real absent-ref checkout failure")
            rc, _ = self.ssh(case, ["test", "-e", "/var/tmp/archiver-build.done"], check=False)
            if rc != 1:
                raise Failed("T14 unexpected success sentinel or unreadable sentinel state")
            case["results"]["T14"] = {"result": "Pass", "at": utc(), "fault_ref": case["fault_ref"]}
        else:
            self.install(case)
            self.build_proof(case)
            case["results"]["T4"] = {"result": "Pass", "at": utc()}
            self.transfer(case)
            result = self.guest(case, "installation")
            case["results"].update(result["results"])
        self.persist()
        return case

    def absent_source_ref(self, case):
        """Select a source commit that the published candidate repository does not contain."""
        while True:
            fault = secrets.token_hex(20)
            rc, output = self.command(["git", "-C", str(self.root / "candidate-source"),
                                       "cat-file", "-e", fault + "^{commit}"], check=False)
            if rc in (1, 128) and "Not a valid object name" in output:
                case["fault_ref"] = fault
                return
            if rc:
                raise Failed("Cannot establish fault-ref absence")

    def capture_ownership(self, case, snapshot):
        """Match the handed-off guest against its domain, files, reservations and lease."""
        if snapshot["domains"].get(case["uuid"]) != case["vm_name"]:
            raise Invalid("The handed-off domain UUID and name are not defined together")
        xml = ET.fromstring(self.virsh("dumpxml", case["uuid"]))
        if xml.findtext("vcpu") != "2" or int(xml.findtext("memory")) != 4096 * 1024:
            raise Invalid("Handed-off VM resources differ from the accepted matrix")
        mac = domain_mac(xml, self.config["cloud"]["network"], case["uuid"], case["vm_name"])
        if mac != case["handoff"]["mac"]:
            raise Invalid("The handed-off MAC differs from the domain interface")
        disks = {node.get("file") for node in xml.findall("./devices/disk/source")}
        if disks != {case["disk"], case["seed"]}:
            raise Invalid("Attached disk and seed differ from the handoff")
        capacity = re.search(r"^Capacity:\s+(\d+)\s*$", self.virsh("domblkinfo", case["uuid"], case["disk"]), re.M)
        if not capacity or int(capacity.group(1)) != disk_bytes(self.config["images"][case["os"]]["disk_size"]):
            raise Invalid("Handed-off disk capacity differs from the accepted matrix")
        for name in ("disk", "seed", "record"):
            if Path(case[name]).is_symlink() or not Path(case[name]).is_file():
                raise Invalid("A handed-off resource file is missing or a symlink")
        record = dict(line.split("=", 1) for line in Path(case["record"]).read_text().splitlines()
                      if "=" in line)
        if record.get("image_id") != case["creation_id"] or record.get("image_name") != Path(case["disk"]).name:
            raise Invalid("VM creation record identity mismatch")
        case["reservation"] = owned_reservation(snapshot["reservations"], mac, case["vm_name"])
        case["address"] = str(ipaddress.IPv4Address(case["reservation"]["ip"]))
        if case["address"] != case["handoff"]["address"]:
            raise Invalid("The owned reservation differs from the handed-off address")
        leases = [lease for lease in self.leases() if lease[0] == mac or lease[1] == case["address"]]
        if leases != [(mac, case["address"])]:
            raise Invalid("The handed-off lease is missing or ambiguous")
        if self.virsh("domstate", case["uuid"]).strip() != "running":
            raise Invalid("The handed-off guest is not running")

    def observe_fresh(self, case):
        """Check identity, resources and freshness of the handed-off guest before any change."""
        os_name = case["os"]
        generator = Path(self.config["cloud"]["path"]) / "bin/generate_ansible_inventory.bash"
        _, inventory = self.command(["bash", str(generator), "--os-type", os_name + "-archiver-dev",
                                      "--species", "archiver-dev-sqlite" if case["backend"] == "sqlite"
                                      else "archiver-dev", "--vm-name", case["vm_name"],
                                      "--address", case["address"],
                                      "--ansible-user", self.config["ssh"]["user"]])
        (self.root / (case["name"] + ".ini")).write_text(inventory)
        groups = re.findall(r"^\[([^]]+)\]$", inventory, re.M)
        hosts = [line.split()[0] for line in inventory.splitlines()
                 if line and not line.startswith(("[", "#"))]
        if set(hosts) != {case["vm_name"]} or len(groups) != 2:
            raise Invalid("Generated inventory does not limit execution to the handed-off VM")
        self.pin_host_key(case)
        _, facts = self.ssh(case, guest_facts_command())
        case["guest_resources"] = parse_guest_facts(facts)
        _, metadata = self.ssh(case, ["sudo", "-n", "cloud-init", "query",
                                      "ds.meta_data.local-hostname"])
        hostname = metadata.strip()
        interfaces = [entry for entry in case["guest_resources"]["interfaces"]
                      if entry.get("address", "").lower() == case["reservation"]["mac"].lower()]
        addresses = [item["local"] for entry in interfaces for item in entry.get("addr_info", [])
                     if item.get("family") == "inet"]
        if (not re.fullmatch(r"[A-Za-z0-9-]+", hostname) or
                len(hostname) > GUEST_HOSTNAME_LIMIT or
                case["guest_resources"]["hostname"] != hostname):
            raise Invalid("Actual guest hostname differs from the cloud-init seed")
        if len(interfaces) != 1 or addresses != [case["address"]]:
            raise Invalid("Actual guest interface IP differs from its owned DHCP reservation")
        release = dict(line.split("=", 1) for line in case["guest_resources"]["os"].splitlines()
                       if "=" in line)
        expected = ("debian", "13") if os_name == "debian13" else ("rocky", "8.10")
        if tuple(release.get(key, "").strip('"') for key in ("ID", "VERSION_ID")) != expected:
            raise Invalid("Actual guest OS differs from the selected matrix case")
        minimum_free = self.config["images"][os_name]["minimum_build_free_bytes"]
        if case["guest_resources"]["cpus"] != 2 or case["guest_resources"]["free_bytes"] < minimum_free:
            raise Invalid("Actual guest resources differ from the accepted matrix")
        rc, raw = self.ssh(case, ["sudo", "-n", "cloud-init", "status", "--long", "--format", "json"],
                           check=False)
        status = json.loads(raw)
        if status.get("status") != "done" or status.get("errors"):
            raise Invalid("cloud-init did not finish without errors")
        guest = self.config["guest"]
        paths = [guest["source_parent"], guest["install_parent"] + "/epicsarchiverap-maven",
                 guest["store_top"], "/usr/local/sbin/archiver-build.sh", "/var/tmp/archiver-build.done"]
        _, probe = self.ssh(case, fresh_probe_command(paths))
        fresh = parse_fresh_probe(probe, len(paths))
        present = [path for path, exists in fresh["paths"].items() if exists]
        installed = [unit for unit in fresh["units"] if unit.startswith(FRESH_UNIT_PREFIXES)]
        if fresh["units_exit"] != 0 or present or installed:
            raise Invalid(f"Handed-off guest is not fresh: paths {present}, units {installed}")
        case["fresh_guest"] = {"cloud_init": {"exit": rc, "status": status}, "observation": fresh}

    def finish(self, case):
        """Stop the case's owned test IOC and mark the case verified."""
        if case.get("remote"):
            self.guest(case, "stop")
        case["lifecycle"] = "verified"
        self.persist()

    def transfer(self, case):
        remote = "/var/tmp/archiver-vm-test-" + case["creation_id"]
        case["remote"] = remote
        settings = dict(self.config["guest"])
        settings["epics_bin"] = settings["epics_bin"][case["os"]]
        payload = {"schema": SCHEMA, "candidate": self.config["candidate"], "guest": settings,
                   "case": case, "bounds": DEFAULT_BOUNDS,
                   "fixture": self.config["fixture"], "fixture_counts": self.state["fixture_counts"]}
        path = self.root / (case["name"] + "-guest.json")
        save(path, payload)
        self.ssh(case, ["mkdir", "-m", "700", "--", remote])
        for source, dest in ((HERE / "guest.py", "guest.py"),
                             (self.root / "UnitTestPVs.db", "UnitTestPVs.db"), (path, "case.json")):
            content = source.read_text()
            self.ssh(case, ["python3", "-c",
                           "import pathlib,sys; pathlib.Path(sys.argv[1]).write_text(sys.stdin.read())",
                           remote + "/" + dest], input_data=content)

    def runtime(self, case):
        result = self.guest(case, "runtime")
        case["results"].update(result["results"])
        self.persist()
        before = self.guest(case, "snapshot")
        build_before = self.build_identity(case)
        self.install(case)
        if self.build_identity(case) != build_before:
            raise Failed("Unchanged Ansible apply executed another detached build")
        self.guest(case, "unchanged")
        self.install(case, force=True)
        self.build_proof(case)
        build_after = self.build_identity(case)
        if not build_after or build_after == build_before:
            raise Failed("Forced Ansible apply did not execute a new detached build")
        result = self.guest(case, "reinstalled")
        case["results"].update(result["results"])
        case["history_snapshot"] = before
        case["build_invocations"] = {"before": build_before, "forced": build_after}
        self.persist()
        if case["backend"] == "sqlite":
            result = self.guest(case, "negative")
            case["results"].update(result["results"])
            self.persist()

    def build_identity(self, case):
        raw = self.ssh(case, ["sudo", "-n", "journalctl", "-u", "archiver-build.service",
                              "--no-pager", "-o", "json"])[1]
        identifiers = [item.get("_SYSTEMD_INVOCATION_ID") for item in
                       (json.loads(line) for line in raw.splitlines())]
        identifiers = [value for value in identifiers if value]
        if not identifiers:
            raise Failed("No actual detached build invocation was observed")
        return identifiers[-1]

    def build_proof(self, case):
        _, script = self.ssh(case, ["sudo", "-n", "cat", "/usr/local/sbin/archiver-build.sh"])
        required = ["init", "db.conf", "conf.archapplproperties", "build.mvn", "sql.fill",
                    "conf.storage", "install", "sd_start"]
        observed = re.findall(r"^\s*make ([a-z._]+)\s*$", script, re.M)
        if observed != required:
            raise Failed("Actual detached build does not execute the accepted Make sequence")
        self.ssh(case, ["test", "-f", "/var/tmp/archiver-build.done"])
        case.setdefault("build_proofs", []).append({"at": utc(), "targets": observed,
                                                    "invocation": self.build_identity(case)})

    def lifecycle_checks(self, case):
        """Exercise the actual interrupted child and cleanup refusal on owned resources."""
        before = self.snapshot()
        marker = case["remote"] + "/interrupt-ready"
        case.setdefault("helper_units", []).append("archiver-interrupt-" + case["creation_id"] + ".service")
        self.persist()
        child = subprocess.Popen([sys.executable, str(HERE / "driver.py"),
                                  "--interruption-probe", str(self.root), "--probe-case", case["name"]],
                                 stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        try:
            deadline = time.monotonic() + DEFAULT_BOUNDS["command"]
            while time.monotonic() < deadline:
                rc, _ = self.ssh(case, ["test", "-f", marker], check=False)
                if rc == 0:
                    break
                if child.poll() is not None:
                    raise Failed("Interruption child exited before its real SSH operation")
                time.sleep(1)
            else:
                raise Failed("Interruption child did not enter its SSH operation")
            child.send_signal(signal.SIGTERM)
            output, _ = child.communicate(timeout=15)
            proof = load(self.root / "interruption.json")
            if child.returncode != 1 or proof.get("result") != "Expected interruption":
                raise Failed("The actual driver did not retain its interruption evidence")
            save(self.root / "interruption-child.json", {"exit": child.returncode, "output": output})
        finally:
            if child.poll() is None:
                child.terminate()
                child.wait(timeout=15)
            self.ssh(case, ["sudo", "-n", "systemctl", "stop",
                            "archiver-interrupt-" + case["creation_id"] + ".service"])
        if self.snapshot() != before:
            raise Failed("Interruption altered retained VM or DHCP identities")
        for label in ("missing", "mismatched"):
            context = self.root / ("refusal-" + label)
            context.mkdir(mode=0o700)
            modified = json.loads(json.dumps(self.state))
            if label == "missing":
                modified.pop("baseline", None)
            else:
                modified["cases"][0]["uuid"] = "00000000-0000-0000-0000-000000000000"
            save(context / "run.json", modified)
            rc, _ = self.command([sys.executable, str(HERE / "driver.py"), "--verify-cleanup", str(context)],
                                 check=False)
            if rc != 2 or self.snapshot() != before:
                raise Failed("Cleanup verification did not refuse invalid ownership")
        save(self.root / "lifecycle.json", {"at": utc(), "result": "Pass", "before": before,
                                            "after": self.snapshot()})
        self.state["interruption_verified"] = True
        self.state["refusal_verified"] = True
        self.state["lifecycle_sha256"] = digest(self.root / "lifecycle.json")
        self.state["interruption_sha256"] = digest(self.root / "interruption.json")
        self.persist()

    def verify_cleanup(self):
        """Confirm independently that owned resources are gone and the baseline is preserved."""
        baseline = self.state.get("baseline")
        if not baseline or not self.state["cases"]:
            raise Invalid("Missing run-start baseline or owned resources")
        # An inspection error is not an observed cleanup failure; the check can run again.
        try:
            snapshot = self.snapshot()
        except (Failed, OSError, ET.ParseError, subprocess.SubprocessError) as error:
            raise Incomplete("Cleanup inspection failed; nothing recorded: " + str(error)) from error
        for case in self.state["cases"]:
            self.case_identity(case)
            if not case.get("uuid") or not case.get("reservation"):
                raise Invalid("Incomplete ownership: cleanup verification refused")
            if case["uuid"] in baseline["domains"] or any(
                    case["reservation"] in baseline["reservations"][kind] for kind in ("live", "persistent")):
                raise Invalid("Owned identity overlaps the preservation baseline")
            named = [uuid for uuid, name in snapshot["domains"].items() if name == case["vm_name"]]
            if named and named != [case["uuid"]]:
                raise Invalid("A domain with an owned name has another UUID; verification refused")
        for uuid, name in baseline["domains"].items():
            if snapshot["domains"].get(uuid) != name:
                raise Failed("A baseline domain identity was not preserved")
        for kind, entries in baseline["reservations"].items():
            if any(entry not in snapshot["reservations"][kind] for entry in entries):
                raise Failed("A baseline DHCP reservation was not preserved")
        remaining = [case["name"] for case in self.state["cases"] if not self.resources_absent(case, snapshot)]
        save(self.root / "cleanup.json", {"at": utc(), "baseline": baseline, "after": snapshot,
                                          "remaining": remaining})
        self.state["cleanup_sha256"] = digest(self.root / "cleanup.json")
        if remaining:
            self.persist()
            raise Incomplete("Owned resources remain: " + ", ".join(remaining))
        for case in self.state["cases"]:
            case["cleanup"] = {"at": utc(), "result": "Pass"}
        self.persist()

    def resources_absent(self, case, snapshot):
        return (case["uuid"] not in snapshot["domains"] and
                case["vm_name"] not in snapshot["domains"].values() and
                not any(os.path.lexists(case[name]) for name in ("disk", "seed", "record")) and
                all(not any(entry.get("mac", "").lower() == case["reservation"]["mac"].lower()
                            or entry.get("ip") == case["reservation"]["ip"]
                            for entry in snapshot["reservations"][kind])
                    for kind in ("live", "persistent")))

    def verdict(self):
        if self.state.get("failure"):
            return 1
        names = [case["name"] for case in self.state["cases"]]
        # Cases run as separate invocations, so the matrix is a set, not a sequence.
        if self.state.get("mode") != "system" or sorted(names) != sorted(MATRIX):
            return 77
        if any(case.get("lifecycle") != "verified" for case in self.state["cases"]):
            return 77
        if self.state.get("preflight", {}).get("result") != "Pass":
            return 77
        local = self.state.get("local_suite", {})
        if local.get("result") != "Pass" or local.get("env_ref") != self.config["candidate"]["env_ref"]:
            return 77
        name = local.get("command_file", "")
        if not re.fullmatch(r"command-\d+\.json", name):
            return 77
        proof = self.root / name
        if not proof.is_file() or proof.is_symlink() or digest(proof) != local.get("sha256"):
            return 77
        recorded = load(proof)
        expected = ["bash", str(self.root / "candidate-env/tests/run-all-tests.bash"), "--local"]
        if (recorded.get("exit") != 0 or recorded.get("interrupted")
                or recorded.get("command") != expected
                or not local_suite_complete(recorded.get("output"))):
            return 77
        for case in self.state["cases"]:
            required = ("T3", "T14") if case["negative"] else tuple(f"T{i}" for i in range(3, 13))
            if case["backend"] == "sqlite" and not case["negative"]:
                required += ("T13",)
            if any(case["results"].get(label, {}).get("result") != "Pass" for label in required):
                return 77
            if case.get("cleanup", {}).get("result") != "Pass":
                return 77
            if not case["negative"]:
                actions = ("installation", "runtime", "snapshot", "unchanged", "reinstalled", "stop")
                if case["backend"] == "sqlite":
                    actions += ("negative",)
                for action in actions:
                    path = self.root / f"{case['name']}-{action}.json"
                    if not path.is_file() or digest(path) != case.get("artifacts", {}).get(action):
                        return 77
        # Interruption and ownership refusal require real lifecycle observations.
        if not self.state.get("interruption_verified") or not self.state.get("refusal_verified"):
            return 77
        if not any(case.get("previous_owned") for case in self.state["cases"]):
            return 77
        for stem in ("lifecycle", "interruption", "cleanup"):
            path = self.root / (stem + ".json")
            if not path.is_file() or digest(path) != self.state.get(stem + "_sha256"):
                return 77
        return 0


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    mode = result.add_mutually_exclusive_group(required=True)
    mode.add_argument("--init", action="store_true")
    mode.add_argument("--case", choices=MATRIX)
    mode.add_argument("--verify-cleanup", type=Path, metavar="RUN")
    mode.add_argument("--verdict", type=Path, metavar="RUN")
    mode.add_argument("--interruption-probe", type=Path, metavar="RUN", help=argparse.SUPPRESS)
    result.add_argument("run", type=Path, nargs="?")
    result.add_argument("--config", type=Path)
    result.add_argument("--evidence", type=Path)
    result.add_argument("--handoff", type=Path)
    result.add_argument("--probe-case", choices=POSITIVE, help=argparse.SUPPRESS)
    return result


def main(argv=None):
    args = parser().parse_args(argv)
    if args.init:
        if args.run or args.handoff or args.probe_case:
            raise Invalid("--init accepts only --config and --evidence")
        if not args.config or not args.evidence:
            raise Incomplete("Explicit --config and --evidence are required; no system action ran")
        config = validate(load(args.config))
        root = args.evidence
        if root.exists() or root.is_symlink():
            raise Invalid("Evidence directory already exists; refusing reuse")
        root.mkdir(mode=0o700, parents=False)
        save(root / "run.json", {"schema": SCHEMA, "at": utc(), "config": config, "mode": "system",
                                "cases": [], "driver_sha256": digest(HERE / "driver.py"),
                                "guest_sha256": digest(HERE / "guest.py")})
        driver = Driver(root)
    elif args.case:
        if args.config or args.evidence or args.probe_case:
            raise Invalid("--case accepts only --handoff and the run directory")
        if not args.handoff or not args.run:
            raise Incomplete("Explicit --handoff and run directory are required; no system action ran")
        handoff = load(args.handoff)
        driver = Driver(args.run)
    else:
        root = args.verify_cleanup or args.verdict or args.interruption_probe
        if (args.config or args.evidence or args.handoff or args.run or
                bool(args.probe_case) != bool(args.interruption_probe)):
            raise Invalid("Context operations cannot replace configuration or evidence")
        driver = Driver(root)
        if args.interruption_probe:
            driver.log_prefix = "interruption-command"
            matches = [case for case in driver.state["cases"] if case["name"] == args.probe_case]
            if len(matches) != 1 or not matches[0].get("remote"):
                raise Invalid("Interruption probe requires an owned installation context")
            try:
                driver.ssh(matches[0], ["sudo", "-n", "systemd-run", "--collect", "--wait", "--pipe",
                           "--unit=archiver-interrupt-" + matches[0]["creation_id"], "python3", "-c",
                           "import pathlib,sys,time; pathlib.Path(sys.argv[1]).touch(); time.sleep(300)",
                           matches[0]["remote"] + "/interrupt-ready"], timeout=360)
            except KeyboardInterrupt:
                save(driver.root / "interruption.json", {"at": utc(), "result": "Expected interruption"})
                return 1
            raise Failed("Interruption probe completed without its expected signal")
        if args.verdict:
            code = driver.verdict()
            print("PASS" if code == 0 else "FAIL" if code == 1 else "INCOMPLETE")
            return code
    lock_path = driver.root / "lock"
    if lock_path.is_symlink():
        raise Invalid("Symlink lock refused")
    with lock_path.open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise Invalid("Another operation owns this run context") from error
        try:
            if args.verify_cleanup:
                driver.verify_cleanup()
                print("PASS: owned resources are absent and the baseline is preserved")
                return 0
            if args.init:
                driver.prepare()
                print("PASS: run initialized; no guest was contacted")
                return 0
            case = driver.adopt(args.case, handoff)
            if not case["negative"]:
                driver.runtime(case)
                if not driver.state.get("interruption_verified"):
                    driver.lifecycle_checks(case)
            driver.finish(case)
            print("PASS: case " + case["name"] + " recorded; only --verdict establishes acceptance")
            return 0
        except (Failed, Invalid, KeyboardInterrupt, OSError, ValueError, KeyError, ET.ParseError,
                subprocess.SubprocessError) as error:
            # A refusal before a case is recorded leaves the run record unchanged.
            if isinstance(error, Invalid) and not driver.recorded:
                raise
            failure = {"at": utc(), "category": type(error).__name__}
            driver.state.setdefault("failure", failure)
            driver.state.setdefault("failures", []).append(failure)
            driver.persist()
            if not args.verify_cleanup:
                driver.stop_helpers()
                driver.persist()
            if isinstance(error, Invalid):
                raise Failed(str(error)) from error
            raise


def interrupt(*unused):
    raise KeyboardInterrupt()


if __name__ == "__main__":
    os.umask(0o077)
    signal.signal(signal.SIGTERM, interrupt)
    try:
        sys.exit(main())
    except Invalid as error:
        print(f"INVALID: {error}", file=sys.stderr)
        sys.exit(2)
    except Incomplete as error:
        print(f"INCOMPLETE: {error}", file=sys.stderr)
        sys.exit(77)
    except (Failed, OSError, ValueError, KeyError, ET.ParseError, subprocess.SubprocessError) as error:
        print(f"FAIL: {type(error).__name__}: {error}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("FAIL: interrupted; context and owned guest retained", file=sys.stderr)
        sys.exit(1)
