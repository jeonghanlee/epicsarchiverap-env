#!/usr/bin/env python3
"""Exercise shipped health and Make paths without systemd mutation or fake JVMs."""

import os
from pathlib import Path
import select
import shutil
import subprocess
import tempfile
import unittest


TOP = Path(__file__).resolve().parents[1]
SERVICES = ("mgmt", "engine", "etl", "retrieval")


class WorkspaceTest(unittest.TestCase):
    def workspace(self, prefix):
        path = Path(tempfile.mkdtemp(prefix=prefix))
        self.addCleanup(self.cleanup_workspace, path)
        return path

    def cleanup_workspace(self, path):
        result = self._outcome.result
        if result.failures or result.errors or os.environ.get("KEEP_WORKSPACE") == "1":
            print(f"Workspace retained: {path}")
        else:
            shutil.rmtree(path)


class HealthTests(WorkspaceTest):
    def setUp(self):
        self.root = self.workspace("archappl-health-")
        self.launcher = self.root / "archappl.bash"
        shutil.copyfile(TOP / "scripts/archappl.bash", self.launcher)
        for name in SERVICES:
            (self.root / name / "temp").mkdir(parents=True)
        self.config = self.root / "archappl.conf"

    def configure(self):
        java = shutil.which("java")
        if not java:
            self.skipTest("A real installed Java executable is required for PID-path tests")
        java_home = Path(java).resolve().parent.parent
        self.config.write_text(f'JAVA_HOME="{java_home}"\nCATALINA_HOME="{self.root}"\n')

    def pid(self, name, value):
        path = self.root / name / "temp" / (name + ".pid")
        path.write_bytes(value)
        return path

    def health(self, expected, *args):
        run = subprocess.run(
            ["bash", str(self.launcher), "health", *args],
            text=True, capture_output=True, timeout=8,
        )
        with (self.root / "run.log").open("a") as log:
            log.write(f"exit={run.returncode}\n{run.stdout}{run.stderr}")
        self.assertEqual(run.returncode, expected, run.stdout + run.stderr)
        self.assertNotIn(" PRESENT ", run.stdout)
        return run.stdout + run.stderr

    def all_reported(self, output):
        for name in SERVICES:
            self.assertEqual(sum(line.startswith(name + " pid=") for line in output.splitlines()), 1)

    def test_configuration_errors_and_privacy(self):
        for value in (None, "", 'JAVA_HOME="PRIVATE_CONFIG_CONTENT\n', "false\n"):
            with self.subTest(value=value):
                if value is not None:
                    self.config.write_text(value)
                output = self.health(2)
                self.all_reported(output)
                self.assertIn("health ERROR", output)
                self.assertNotIn("PRIVATE_CONFIG_CONTENT", output)

    @unittest.skipIf(os.geteuid() == 0, "Permission denial requires a non-root test account")
    def test_unreadable_configuration(self):
        self.configure()
        self.config.chmod(0)
        self.addCleanup(self.config.chmod, 0o600)
        self.all_reported(self.health(2))

    def test_missing_pid_files(self):
        self.configure()
        output = self.health(1)
        self.all_reported(output)
        self.assertEqual(output.count("missing-pid-file"), 4)

    def test_invalid_pid_files_are_preserved(self):
        self.configure()
        values = (b"", b"0\n", b"-1\n", b"1 2\n", b"1\n2\n", b"1\x00", b"9" * 64, b"text\n")
        for value in values:
            with self.subTest(value=value):
                paths = [self.pid(name, value) for name in SERVICES]
                output = self.health(1)
                self.all_reported(output)
                self.assertEqual(output.count("invalid-pid-file"), 4)
                for path in paths:
                    self.assertEqual(path.read_bytes(), value)

    def test_absent_process(self):
        self.configure()
        unused = 2147483647
        self.assertFalse(Path(f"/proc/{unused}").exists())
        for name in SERVICES:
            self.pid(name, f"{unused}\n".encode())
        output = self.health(1)
        self.all_reported(output)
        self.assertEqual(output.count("missing-process"), 4)

    def test_real_unrelated_process_is_not_signalled(self):
        self.configure()
        child = subprocess.Popen(["sleep", "60"])
        self.addCleanup(child.wait)
        self.addCleanup(child.terminate)
        value = f"{child.pid}\n".encode()
        paths = [self.pid(name, value) for name in SERVICES]
        output = self.health(1)
        self.all_reported(output)
        self.assertEqual(output.count("wrong-java-executable"), 4)
        self.assertIsNone(child.poll())
        for path in paths:
            self.assertEqual(path.read_bytes(), value)

    def test_unrelated_java_with_tomcat_application_arguments(self):
        self.configure()
        java = Path(shutil.which("java")).resolve()
        javac = java.with_name("javac")
        if not javac.is_file():
            self.skipTest("The installed JDK compiler is required for the unrelated JVM test")
        build = subprocess.run(
            [str(javac), "-d", str(self.root), str(TOP / "tests/fixtures/UnrelatedJava.java")],
            capture_output=True, text=True, timeout=15,
        )
        self.assertEqual(build.returncode, 0, build.stdout + build.stderr)
        properties = [f"-Dcatalina.base={self.root / 'mgmt'}", f"-Dcatalina.home={self.root}"]
        for vm_properties in (False, True):
            with self.subTest(vm_properties=vm_properties):
                command = [str(java), "-cp", str(self.root)]
                command += (properties + ["UnrelatedJava"] if vm_properties
                            else ["UnrelatedJava"] + properties)
                command += ["org.apache.catalina.startup.Bootstrap", "start"]
                with subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE) as child:
                    try:
                        self.assertTrue(select.select([child.stdout], [], [], 5)[0], "No JVM readiness output")
                        self.assertEqual(child.stdout.readline(), b"ready\n")
                        value = f"{child.pid}\n".encode()
                        path = self.pid("mgmt", value)
                        output = self.health(1)
                        self.assertIn(f"mgmt pid={child.pid} FAIL wrong-tomcat-identity", output)
                        self.assertIsNone(child.poll())
                        self.assertEqual(path.read_bytes(), value)
                    finally:
                        child.terminate()
                        child.communicate(timeout=5)

    @unittest.skipIf(os.geteuid() == 0, "Permission denial requires a non-root test account")
    def test_pid_symlink_target_ancestor_permission_error(self):
        self.configure()
        denied = self.root / "denied"
        target = denied / "nested"
        target.mkdir(parents=True)
        (target / "mgmt.pid").write_text("1\n")
        temp = self.root / "mgmt/temp"
        temp.rmdir()
        temp.symlink_to(target, target_is_directory=True)
        denied.chmod(0)
        self.addCleanup(denied.chmod, 0o700)
        output = self.health(2)
        self.all_reported(output)
        self.assertIn("mgmt pid=- ERROR", output)

    @unittest.skipIf(os.geteuid() == 0, "Permission denial requires a non-root test account")
    def test_inspection_error_takes_precedence(self):
        self.configure()
        path = self.pid("engine", b"1\n")
        path.chmod(0)
        self.addCleanup(path.chmod, 0o600)
        output = self.health(2)
        self.all_reported(output)
        self.assertIn("engine pid=- ERROR unreadable-pid-file", output)
        self.assertIn("mgmt pid=- FAIL missing-pid-file", output)

    def test_nonregular_pid_file_does_not_block(self):
        self.configure()
        os.mkfifo(self.root / "engine/temp/engine.pid")
        self.all_reported(self.health(2))

    def test_real_zombie_is_rejected(self):
        self.configure()
        child = os.fork()
        if child == 0:
            os._exit(0)
        self.addCleanup(os.waitpid, child, 0)
        # WNOWAIT observes exit while leaving a real zombie for the launcher.
        os.waitid(os.P_PID, child, os.WEXITED | os.WNOWAIT)
        self.pid("mgmt", f"{child}\n".encode())
        output = self.health(1)
        self.assertIn(f"mgmt pid={child} FAIL dead-process", output)

    def test_invalid_cli(self):
        self.assertIn("invalid-arguments", self.health(2, "unexpected"))
        self.assertIn("invalid-arguments", self.health(2, "--systemd", "bad/name", "health.service", "60"))


class SystemdFileTests(WorkspaceTest):
    def setUp(self):
        self.temp = self.workspace("archappl-units-")
        self.root = self.temp / "checkout"
        self.root.mkdir()
        paths = subprocess.check_output(
            ["git", "-C", str(TOP), "ls-files", "-z", "--cached", "--others", "--exclude-standard"]
        ).decode().split("\0")
        for item in paths:
            if item and (item == "Makefile" or item.startswith(("configure/", "site-template/", "scripts/"))):
                destination = self.root / item
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(TOP / item, destination)
        self.units = self.temp / "units"

    def make(self, *args):
        run = subprocess.run(
            ["make", "--no-print-directory", "-C", str(self.root), *args,
             "SUDO=", f"SYSTEMD_PATH={self.units}"],
            text=True, capture_output=True, timeout=30,
        )
        with (self.temp / "run.log").open("a") as log:
            log.write(f"exit={run.returncode}\n{run.stdout}{run.stderr}")
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
        return run.stdout

    def test_real_file_install_default_and_alternate(self):
        for jobs, install, user in (("-j1", "/opt/epicsarchiverap-maven", "tomcat"),
                                    ("-j8", "/srv/aa-test", "aa-test")):
            with self.subTest(jobs=jobs):
                # The shipped global .NOTPARALLEL remains in force in both runs.
                self.make(jobs, "install.systemd", f"AA_INSTALL_LOCATION={install}",
                          f"AA_USERID={user}", f"AA_GROUPID={user}")
                for name in ("epicsarchiverap-maven.service", "epicsarchiverap-maven-health.service",
                             "epicsarchiverap-maven-health.timer", "tomcat9.service.d/override.conf"):
                    path = self.units / name
                    self.assertEqual(path.stat().st_mode & 0o777, 0o644)
                    self.assertNotRegex(path.read_text(), r"@[A-Z_]+@")
                service = (self.units / "epicsarchiverap-maven-health.service").read_text()
                timer = (self.units / "epicsarchiverap-maven-health.timer").read_text()
                self.assertIn(f'"{install}/archappl.bash" health --systemd', service)
                self.assertIn(f"User={user}\n", service)
                self.assertIn("TimeoutStartSec=5s\n", service)
                self.assertIn("TimeoutStopSec=1s\n", service)
                self.assertIn("SuccessExitStatus=3\n", service)
                self.assertIn("StartLimitIntervalSec=0\n", service)
                self.assertIn("OnUnitInactiveSec=30s\n", timer)
                self.assertIn("AccuracySec=1s\n", timer)
                self.assertIn("WantedBy=timers.target epicsarchiverap-maven.service\n", timer)
                for directive in ("Requires=", "BindsTo=", "PartOf=", "OnFailure=", "Restart=", "ExecStop="):
                    self.assertNotIn(directive, service + timer)
                if shutil.which("systemd-analyze"):
                    verify = subprocess.run(
                        ["systemd-analyze", "verify", str(self.units / "epicsarchiverap-maven-health.service"),
                         str(self.units / "epicsarchiverap-maven-health.timer")],
                        text=True, capture_output=True, timeout=20,
                    )
                    self.assertEqual(verify.returncode, 0, verify.stdout + verify.stderr)

    def test_site_timing_overrides(self):
        (self.root.parent / "CONFIG_SITE.local").write_text("SYSTEMD_HEALTH_STARTUP_SECONDS=90\nSYSTEMD_HEALTH_INTERVAL_SECONDS=20\n")
        self.make("install.health.service", "install.health.timer")
        self.assertIn(".service 90\n", (self.units / "epicsarchiverap-maven-health.service").read_text())
        self.assertIn("OnUnitInactiveSec=20s\n", (self.units / "epicsarchiverap-maven-health.timer").read_text())

    def test_full_install_and_monitor_removal_command_order(self):
        self.make("conf.archapplproperties")
        output = self.make("-j8", "-n", "install")
        self.assertLess(output.index("systemctl stop"), output.index("usergroup.postinst"))
        self.assertLess(output.rindex("chown -R"), output.rindex("systemctl daemon-reload"))
        self.assertLess(output.rindex("systemctl daemon-reload"), output.index("systemctl enable"))
        self.assertNotIn("systemctl start", output)
        removal = self.make("-n", "sd_health_clean")
        self.assertLess(removal.index("systemctl stop"), removal.index("systemctl disable"))
        self.assertLess(removal.index("systemctl disable"), removal.index("rm -f"))
        self.assertNotIn("systemctl stop epicsarchiverap-maven.service", removal)
        self.assertNotIn("--now", removal)


if __name__ == "__main__":
    unittest.main(verbosity=2)
