#!/usr/bin/env python3
"""Exercise the shipped config loader, launcher, and configuration install rules."""

import http.server
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import threading
import unittest


TOP = Path(__file__).resolve().parents[1]


class ConfigTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix="archappl-config-d-"))
        self.addCleanup(print, f"Workspace retained: {self.root}")
        self.config = self.root / "archappl.conf"
        self.config.write_text("CONFIG_TEST_VALUE=base\nCONFIG_TEST_EMPTY=base\n")
        for name in ("archappl.bash", "archappl-config.bash"):
            shutil.copyfile(TOP / "scripts" / name, self.root / name)

    def run_command(self, args, expected=0, **kwargs):
        run = subprocess.run(args, capture_output=True, timeout=30, cwd="/", **kwargs)
        with (self.root / "commands.log").open("ab") as log:
            log.write(f"command={args!r}\nexit={run.returncode}\n".encode())
            log.write(run.stdout + run.stderr + b"\n")
        self.assertEqual(run.returncode, expected, run.stdout + run.stderr)
        return run

    def load(self, expected=0, mode="startup", prefix=""):
        script = prefix + '\n. "$1/archappl-config.bash"; archappl_load_configuration "$1" "$2" || exit $?; env -0'
        run = self.run_command(["bash", "-c", script, "config-test", str(self.root), mode], expected)
        values = dict(item.split(b"=", 1) for item in run.stdout.split(b"\0") if b"=" in item)
        return values, run

    def drops(self):
        path = self.root / "config.d"
        path.mkdir(exist_ok=True)
        return path

    def test_absent_empty_and_export_option(self):
        for present in (False, True):
            if present:
                self.drops()
            values, _ = self.load()
            self.assertEqual(values[b"CONFIG_TEST_VALUE"], b"base")
        script = '. "$1/archappl-config.bash"; set -a; archappl_load_configuration "$1"; [[ $- == *a* ]]'
        self.run_command(["bash", "-c", script, "config-test", str(self.root)])
        script = '. "$1/archappl-config.bash"; set +a; archappl_load_configuration "$1"; [[ $- != *a* ]]'
        self.run_command(["bash", "-c", script, "config-test", str(self.root)])

    def test_order_quotes_empty_and_file_selection(self):
        drops = self.drops()
        (drops / "20-last.conf").write_text("CONFIG_TEST_VALUE='last value'\nCONFIG_TEST_EMPTY=''\n")
        (drops / "10-first.conf").write_text("CONFIG_TEST_VALUE=first\nCONFIG_TEST_NEW='one two * $three'\n")
        (drops / "15 with spaces.conf").write_text("CONFIG_TEST_SPACE=yes\n")
        (self.root / "linked.conf").write_text("CONFIG_TEST_LINK=yes\n")
        (drops / "16-link.conf").symlink_to(self.root / "linked.conf")
        for name in (".hidden.conf", "20-last.conf~", "disabled.conf.bak"):
            (drops / name).write_text("CONFIG_TEST_VALUE=wrong\n")
        (drops / "30-directory.conf").mkdir()
        (drops / "30-directory.conf" / "child.conf").write_text("CONFIG_TEST_VALUE=wrong\n")
        values, _ = self.load(prefix="shopt -s dotglob; export GLOBIGNORE=unused")
        self.assertEqual(values[b"CONFIG_TEST_VALUE"], b"last value")
        self.assertEqual(values[b"CONFIG_TEST_EMPTY"], b"")
        self.assertEqual(values[b"CONFIG_TEST_NEW"], b"one two * $three")
        self.assertEqual(values[b"CONFIG_TEST_SPACE"], b"yes")
        self.assertEqual(values[b"CONFIG_TEST_LINK"], b"yes")

    def test_noglob_preserves_selection_and_caller_option(self):
        (self.drops() / "50-site.conf").write_text("CONFIG_TEST_VALUE=local\n")
        values, _ = self.load(prefix="set -f")
        self.assertEqual(values[b"CONFIG_TEST_VALUE"], b"local")
        script = '. "$1/archappl-config.bash"; set -f; archappl_load_configuration "$1"; [[ $- == *f* ]]'
        self.run_command(["bash", "-c", script, "config-test", str(self.root)])
        invalid = self.drops() / "99-invalid.conf"
        invalid.write_text('CONFIG_TEST_VALUE="unterminated\n')
        for action, status in (("startup", 1), ("service", 1), ("health", 2)):
            run = self.run_command(["bash", "-f", str(self.root / "archappl.bash"), action], status)
            self.assertIn(str(invalid).encode(), run.stderr)

    def test_preflight_does_not_evaluate_configuration(self):
        marker = self.root / "evaluated"
        self.config.write_text(f"printf evaluated > {shlex.quote(str(marker))}\n")
        self.load(mode="preflight")
        self.assertFalse(marker.exists())
        invalid = self.drops() / "99-invalid.conf"
        invalid.write_text('CONFIG_TEST_VALUE="unterminated\n')
        _, run = self.load(expected=1, mode="preflight")
        self.assertIn(str(invalid).encode(), run.stderr)
        self.assertFalse(marker.exists())

    def test_loglevel_blocks_invalid_configuration_with_inherited_port(self):
        requests = []

        class Handler(http.server.BaseHTTPRequestHandler):
            def do_GET(self):
                requests.append(self.path)
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"[]")

            def log_message(self, *args):
                pass

        server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        env = dict(os.environ, ARCHAPPL_MGMT_PORT=str(server.server_port))
        command = ["bash", str(self.root / "archappl.bash"), "loglevel", "engine", "root", "DEBUG"]
        try:
            # Establish that the actual launcher reaches the transport with valid settings.
            self.config.write_text(f"ARCHAPPL_MGMT_PORT={server.server_port}\n")
            self.run_command(command, env=env)
            self.assertEqual(requests, ["/mgmt/bpl/setLogLevel?component=engine&logger=root&level=DEBUG"])
            requests.clear()
            invalid = self.drops() / "99-invalid.conf"
            invalid.write_text('CONFIG_TEST_VALUE="unterminated\n')
            run = self.run_command(command, expected=1, env=env)
            self.assertIn(str(invalid).encode(), run.stderr)
            self.assertEqual(requests, [])
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=5)

    def test_preflight_before_evaluation_or_component_start(self):
        marker = self.root / "evaluated"
        self.config.write_text(f"printf evaluated > {shlex.quote(str(marker))}\n")
        invalid = self.drops() / "99-invalid.conf"
        invalid.write_text('CONFIG_TEST_VALUE="PRIVATE_CONFIG_CONTENT\n')
        _, run = self.load(expected=1)
        self.assertIn(str(invalid).encode(), run.stderr)
        self.assertNotIn(b"PRIVATE_CONFIG_CONTENT", run.stderr)
        self.assertFalse(marker.exists())
        for action, status in (("startup", 1), ("service", 1), ("restart", 1), ("shutdown", 1), ("health", 2)):
            run = self.run_command(["bash", str(self.root / "archappl.bash"), action], status)
            self.assertIn(str(invalid).encode(), run.stderr)
            self.assertFalse(marker.exists())
            self.assertNotIn(b"PRIVATE_CONFIG_CONTENT", run.stdout + run.stderr)
            if action == "health":
                self.assertIn(b"unreadable-or-invalid-configuration", run.stdout)
            else:
                self.assertIn(b"no instance was touched", run.stderr)

    @unittest.skipIf(os.geteuid() == 0, "Unreadability must be checked as an unprivileged user")
    def test_unreadable_file_and_directory(self):
        drops = self.drops()
        private = drops / "10-private.conf"
        private.write_text("CONFIG_TEST_VALUE=unreadable\n")
        private.chmod(0)
        try:
            _, run = self.load(expected=1)
            self.assertIn(str(private).encode(), run.stderr)
            for action, status in (("startup", 1), ("service", 1), ("health", 2)):
                run = self.run_command(["bash", str(self.root / "archappl.bash"), action], status)
                self.assertIn(str(private).encode(), run.stderr)
        finally:
            private.chmod(0o600)
        drops.chmod(0)
        try:
            _, run = self.load(expected=1)
            self.assertIn(str(drops).encode(), run.stderr)
        finally:
            drops.chmod(0o700)

    def test_last_command_status_compatibility(self):
        self.config.write_text("CONFIG_TEST_VALUE=base\nfalse\n")
        self.assertEqual(self.load()[0][b"CONFIG_TEST_VALUE"], b"base")
        _, run = self.load(expected=2, mode="health")
        self.assertIn(b"configuration evaluation failed", run.stderr)

    def test_health_uses_local_runtime_paths(self):
        java = shutil.which("java")
        if not java:
            self.skipTest("A real Java installation is required")
        java_home = Path(java).resolve().parent.parent
        self.config.write_text("JAVA_HOME=/missing\nCATALINA_HOME=/missing\n")
        (self.drops() / "50-runtime.conf").write_text(
            f"JAVA_HOME={shlex.quote(str(java_home))}\nCATALINA_HOME={shlex.quote(str(self.root))}\n"
            f"ARCHAPPL_STORAGE_TOP={shlex.quote(str(self.root))}\nARCHAPPL_STORAGE_ALARM_PERCENT=100\n"
        )
        for name in ("mgmt", "engine", "etl", "retrieval"):
            (self.root / name / "temp").mkdir(parents=True)
        run = self.run_command(["bash", str(self.root / "archappl.bash"), "health"], 1)
        self.assertNotIn(b"invalid-runtime-paths", run.stdout)
        self.assertIn(b"storage path=" + str(self.root).encode(), run.stdout)

    def test_status_and_health_evaluate_configuration_once(self):
        java = shutil.which("java")
        if not java:
            self.skipTest("A real Java installation is required")
        java_home = Path(java).resolve().parent.parent
        self.config.write_text(
            f"JAVA_HOME={shlex.quote(str(java_home))}\nCATALINA_HOME={shlex.quote(str(self.root))}\n"
            f"ARCHAPPL_STORAGE_TOP={shlex.quote(str(self.root))}\nARCHAPPL_STORAGE_ALARM_PERCENT=100\n"
        )
        marker = self.root / "evaluations"
        local = self.drops() / "50-site.conf"
        local.write_text(f"printf 'loaded\\n' >> {shlex.quote(str(marker))}\n")
        for action in ("status", "health"):
            run = self.run_command(["bash", str(self.root / "archappl.bash"), action], expected=1)
            self.assertIn(b"missing-pid-file", run.stdout)
            self.assertEqual(marker.read_text(), "loaded\n")
            marker.unlink()
        local.write_text("false\n")
        for action in ("status", "health"):
            run = self.run_command(["bash", str(self.root / "archappl.bash"), action], expected=2)
            self.assertIn(b"configuration-load-failed", run.stdout)
        local.write_text("# No local runtime paths.\n")
        self.config.write_text(f"ARCHAPPL_STORAGE_TOP={shlex.quote(str(self.root))}\n")
        env = dict(os.environ, JAVA_HOME=str(java_home), CATALINA_HOME=str(self.root))
        for action in ("status", "health"):
            run = self.run_command(["bash", str(self.root / "archappl.bash"), action], expected=2, env=env)
            self.assertIn(b"invalid-runtime-paths", run.stdout)

    def test_install_and_regeneration_preserve_local_bytes(self):
        checkout = self.root / "checkout"
        checkout.mkdir()
        for name in ("configure", "site-template", "scripts"):
            shutil.copytree(TOP / name, checkout / name)
        shutil.copyfile(TOP / "Makefile", checkout / "Makefile")
        installed = self.root / "installed"
        command = ["make", "--no-print-directory", "-C", str(checkout), "SUDO=",
                   f"AA_INSTALL_LOCATION={installed}", "conf.archappl", "archapplconf.install", "archapplshell.install"]
        self.run_command(command)
        local_file = installed / "config.d" / "90-site.conf"
        content = b"CONFIG_TEST_VALUE='kept exactly'\n# Operator-owned settings.\n"
        local_file.write_bytes(content)
        self.run_command(command)
        self.assertEqual(local_file.read_bytes(), content)
        self.assertEqual((installed / "archappl-config.bash").read_bytes(), (TOP / "scripts/archappl-config.bash").read_bytes())


if __name__ == "__main__":
    unittest.main(verbosity=2)
