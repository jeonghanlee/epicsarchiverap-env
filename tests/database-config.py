#!/usr/bin/env python3
"""Run the shipped configuration targets and shell consumers in isolation."""

import socket
import http.server
import sys
import time
from pathlib import Path
import shutil
import os
import subprocess
import tempfile
import threading
import unittest
import xml.etree.ElementTree as ET


TOP = Path(__file__).resolve().parents[1]
SOURCE_TOP = Path(os.environ.get("AA_TEST_SOURCE_PATH", str(TOP / "epicsarchiverap-maven-src")))
SCHEMA_TOP = SOURCE_TOP / "src/main/org/epics/archiverappliance/config/persistence"
DB_TARGETS = ("db.conf", "db.conf.show", "db.secure", "db.addAdmin",
              "db.rmAdmin", "db.create", "db.drop", "db.show")
SQL_TARGETS = ("sql.fill", "sql.show", "sql.update", "sql.update.show",
               "sql.table.fill", "sql.table.show", "sql.drop", "sql.table.drop")
QUERY_TARGETS = ("PVRequests.show", "DataServers.show", "PVAliases.show", "PVTypeInfo.show")
HELPER_ACTIONS = ("secureSetup", "localAdminAdd", "hostnameAdminAdd", "localAdminRemove",
                  "hostnameAdminRemove", "adminAdd", "adminRemove", "dbCreate",
                  "dbUserCreate", "dbShow", "dbUserDrop", "userDrop", "dbDrop", "isDb",
                  "dbBackup", "dbBackupList", "dbRestore", "tableShow", "tableDrop",
                  "aaShow", "query", "queryFile")


class DatabaseConfigTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="aa-db-config-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "checkout"
        self.root.mkdir()
        paths = subprocess.check_output(
            ["git", "-C", str(TOP), "ls-files", "-z", "--cached", "--others", "--exclude-standard"]
        ).decode().split("\0")
        for name in paths:
            if name == "Makefile" or name.startswith(("configure/", "site-template/", "scripts/")):
                if (TOP / name).is_file():
                    dest = self.root / name
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(TOP / name, dest)

    def run_command(self, args, expected=0, **kwargs):
        run = subprocess.run(args, cwd=self.root, capture_output=True, timeout=30, **kwargs)
        self.assertEqual(run.returncode, expected, run.stdout + run.stderr)
        return run.stdout

    def make(self, *args):
        return self.run_command(["make", "--no-print-directory", "-s", *args])

    def value(self, file, name):
        return self.run_command(
            ["bash", "-c", 'source "$1"; printf "%s" "${!2}"', "test", str(file), name]
        ).decode()

    def test_passwords_survive_make_xml_and_shell(self):
        template = self.root / "site-template"
        for password in ("ReviewPlain123", "Review&Value", "a:b|c/d\\e'\" <>& @DB_USER_PASS@",
                         "$(touch INJECTED) `touch INJECTED` $HOME ; * ?", "", "line\nnext\tend"):
            with self.subTest(password=password):
                # GNU Make uses $$ for a literal dollar in variable values.
                value = password.replace("$", "$$")
                self.make("conf.context", "db.conf", f"DB_USER_PASS={value}", f"DB_ADMIN_PASS={value}")
                resource = ET.parse(template / "context.xml").find("Resource")
                self.assertEqual(resource.attrib["password"], password)
                for key in ("DB_USER_PASS", "DB_ADMIN_PASS"):
                    self.assertEqual(self.value(template / "mariadb.conf", key), password)
                self.assertFalse((self.root / "INJECTED").exists())

    def test_password_from_local_override_file(self):
        password = "Local& |/'\" $HOME #literal"
        value = password.replace("$", "$$").replace("#", "\\#")
        (self.root.parent / "CONFIG_SITE.local").write_text(f"DB_USER_PASS := {value}\n")
        self.make("conf.context", "db.conf")
        template = self.root / "site-template"
        resource = ET.parse(template / "context.xml").find("Resource")
        self.assertEqual(resource.attrib["password"], password)
        self.assertEqual(self.value(template / "mariadb.conf", "DB_USER_PASS"), password)

    def test_database_password_file_is_private_on_creation_and_replacement(self):
        config = self.root / "site-template/mariadb.conf"
        for existing in (False, True):
            with self.subTest(existing=existing):
                if existing:
                    config.chmod(0o666)
                self.run_command(["bash", "-c", "umask 000; make --no-print-directory -s db.conf"])
                self.assertEqual(config.stat().st_mode & 0o777, 0o600)
                self.assertEqual(self.value(config, "DB_USER_PASS"), "archappl")

    def test_installers_require_clean_source_inputs_in_checkouts_and_worktrees(self):
        source = self.root / "source"
        self.run_command(["git", "clone", "--quiet", "--shared", str(SOURCE_TOP), str(source)])
        exclude = source / ".git/info/exclude"
        exclude.parent.mkdir(parents=True, exist_ok=True)
        with exclude.open("a") as output:
            output.write("\n/.mvn/maven.config\n/.mvn/jvm.config\n/.mvn/extensions.xml\n")
        worktree = self.root / "source-worktree"
        self.run_command(["git", "-C", str(source), "worktree", "add", "--quiet", "--detach", str(worktree), "HEAD"])
        for tree in (source, worktree):
            (self.root / "configure/CONFIG_VARS.local").write_text(f"SRC_PATH:={tree.name}\n")
            site = tree / "src/sitespecific/als"
            site.mkdir(parents=True, exist_ok=True)
            (site / "GeneratedReviewMarker.txt").write_text("Generated site overlay.\n")
            for mode in ("sqlite", "mariadb-uds", "mariadb-tcp"):
                entry = ["bash", f"scripts/install-local-{mode}.bash", "--plan", "--skip-packages"]
                with self.subTest(tree=tree.name, mode=mode):
                    self.run_command(entry)
                    marker = tree / "src/resources/main/ReviewPinMarker.txt"
                    marker.write_text("Untracked build input.\n")
                    self.run_command(["git", "-C", str(tree), "diff", "--quiet"])
                    run = subprocess.run(entry, cwd=self.root, capture_output=True, timeout=30)
                    self.assertNotEqual(run.returncode, 0)
                    self.assertIn(b"untracked files", run.stderr)
                    marker.unlink()
                    marker = tree / "src/resources/main/ReviewPinMarker.swp"
                    marker.write_text("Ignored build input.\n")
                    run = subprocess.run(entry, cwd=self.root, capture_output=True, timeout=30)
                    self.assertNotEqual(run.returncode, 0)
                    self.assertIn(b"ignored build inputs", run.stderr)
                    marker.unlink()
                    for name in ("maven.config", "jvm.config", "extensions.xml"):
                        with self.subTest(config=name):
                            marker = tree / ".mvn" / name
                            marker.parent.mkdir(parents=True, exist_ok=True)
                            marker.write_text("Ignored Maven build configuration.\n")
                            self.run_command(["git", "-C", str(tree), "check-ignore", str(marker)])
                            run = subprocess.run(entry, cwd=self.root, capture_output=True, timeout=30)
                            self.assertNotEqual(run.returncode, 0)
                            self.assertIn(b"ignored build inputs", run.stderr)
                            self.assertIn(f".mvn/{name}".encode(), run.stderr)
                            marker.unlink()
                    tracked = tree / "pom.xml"
                    original = tracked.read_bytes()
                    tracked.write_bytes(original + b"\n<!-- Local source modification. -->\n")
                    run = subprocess.run(entry, cwd=self.root, capture_output=True, timeout=30)
                    self.assertNotEqual(run.returncode, 0)
                    self.assertIn(b"tracked changes", run.stderr)
                    tracked.write_bytes(original)

    def test_installer_readiness_obeys_deadline(self):
        # Invoke the shipped functions without running the system installation.
        script = (self.root / "scripts/install-local-common.bash").read_text()
        functions, invocation = script.rsplit('\nmain "$@"', 1)
        self.assertFalse(invocation.strip())
        harness = self.root / "scripts/readiness-functions.bash"
        harness.write_text(functions + "\n")
        boundary = self.root / "boundary"
        boundary.mkdir()
        sudo = boundary / "sudo"

        class SlowResponse(http.server.BaseHTTPRequestHandler):
            def do_GET(self):
                time.sleep(3)
                try:
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(b'{"status":"STARTUP_COMPLETE"}')
                except (BrokenPipeError, ConnectionResetError):
                    pass

            def log_message(self, *args):
                pass

        server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), SlowResponse)
        self.addCleanup(server.server_close)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(server.shutdown)
        url = f"http://127.0.0.1:{server.server_port}/startupState"
        command = (
            'source "$1"; PATH="$2:$PATH"; timeout=1; service_user=review; '
            'install_path=/unused; service_unit=review.service; health_timer=review.timer; '
            'component_urls=("$3" "$3" "$3" "$3"); mgmt_url="$3"; wait_ready'
        )
        # Only the outer privilege boundary is replaced; HTTP uses real curl.
        for action in ("exit 1", "sleep 10"):
            with self.subTest(privilege_boundary=action):
                sudo.write_text(f"#!/bin/sh\n{action}\n")
                sudo.chmod(0o755)
                started = time.monotonic()
                run = subprocess.run(
                    ["bash", "-c", command, "review", str(harness), str(boundary), url],
                    cwd=self.root, capture_output=True, timeout=3,
                )
                elapsed = time.monotonic() - started
                self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
                self.assertIn(b"within 1 seconds", run.stderr)
                self.assertLess(elapsed, 2)

        command = (
            'source "$1"; run_before_deadline "$((SECONDS + 5))" true; '
            'run_before_deadline "$SECONDS" true'
        )
        self.run_command(["bash", "-c", command, "review", str(harness)], expected=124)

    def test_configured_database_name_reaches_runtime(self):
        template = self.root / "site-template"
        for backend in ("mariadb", "sqlite"):
            for key in ("DB_NAME", "JDBC_DB_NAME"):
                with self.subTest(backend=backend, key=key):
                    self.make("conf.context", "conf.archappl", f"DB_BACKEND={backend}", f"{key}=review_archive")
                    resource = ET.parse(template / "context.xml").find("Resource")
                    name = self.value(template / "archappl.conf", "ARCHAPPL_DB_NAME")
                    self.assertEqual(name, "review_archive")
                    self.assertEqual(resource.attrib["name"], "jdbc/" + name)
                    exported = self.run_command(
                        ["bash", "-c", 'set -a; source "$1"; bash -c \'printf "%s" "$ARCHAPPL_DB_NAME"\'',
                         "test", str(template / "archappl.conf")])
                    self.assertEqual(exported, b"review_archive")

    def test_archappl_render_failure_preserves_existing_configuration(self):
        self.make("conf.archappl")
        config = self.root / "site-template/archappl.conf"
        previous = config.read_bytes()
        self.run_command(
            ["make", "-s", "conf.archappl", "AA_INSTALL_LOCATION=/tmp/aa:invalid"], expected=2)
        self.assertEqual(config.read_bytes(), previous)
        config.unlink()
        self.run_command(
            ["make", "-s", "conf.archappl", "AA_INSTALL_LOCATION=/tmp/aa:invalid"], expected=2)
        self.assertFalse(config.exists())

    def test_socket_comments_match_jdbc_and_shell_transport(self):
        template = self.root / "site-template"
        for socket_path in ("/tmp/mariadb.sock", ""):
            with self.subTest(socket_path=socket_path):
                (self.root.parent / "CONFIG_SITE.local").write_text(
                    f"DB_SOCKET := {socket_path}   # local transport\n")
                self.make("conf.context", "db.conf")
                self.assertEqual(self.value(template / "mariadb.conf", "DB_SOCKET"), socket_path)
                url = ET.parse(template / "context.xml").find("Resource").attrib["url"]
                expected = (f"jdbc:mariadb://localhost/archappl?localSocket={socket_path}"
                            if socket_path else "jdbc:mariadb://127.0.0.1:3306/archappl")
                self.assertEqual(url, expected)

    def test_system_entrypoints_cannot_report_success(self):
        for args in (["bash", str(TOP / "tests/phase3-docker.bash")],
                     ["bash", str(TOP / "tests/phase4-vm.bash")],
                     ["bash", str(TOP / "tests/run-all-tests.bash"), "--system"]):
            with self.subTest(args=args):
                run = subprocess.run(args, capture_output=True, text=True, timeout=10)
                self.assertEqual(run.returncode, 77)
                self.assertNotIn("[PASS]", run.stdout + run.stderr)
                self.assertIn("INCOMPLETE", run.stderr)
                if args[-1] == "--system":
                    self.assertIn("Phase 3", run.stdout)
                    self.assertIn("Phase 4", run.stdout)

    def test_sqlite_database_targets_skip_without_prerequisites(self):
        self.make("db.conf", "DB_BACKEND=mariadb")
        template = self.root / "site-template"
        config = template / "mariadb.conf"
        original = config.read_bytes()
        (template / "mariadb.conf.in").unlink()
        (self.root / "scripts/mariadb_setup.bash").unlink()
        for target in DB_TARGETS:
            (self.root / target).touch()
        for existing in (True, False):
            if not existing:
                config.unlink()
            for target in DB_TARGETS:
                with self.subTest(target=target, existing=existing):
                    out = self.make(target, "DB_BACKEND=sqlite")
                    self.assertIn(f"[SKIP] {target}".encode(), out)
                    self.assertEqual(config.read_bytes() if config.exists() else None,
                                     original if existing else None)

    def test_invalid_backends_fail_before_database_prerequisites(self):
        self.make("db.conf", "DB_BACKEND=mariadb")
        config = self.root / "site-template/mariadb.conf"
        original = config.read_bytes()
        (self.root / "scripts/mariadb_setup.bash").unlink()
        for target in DB_TARGETS + SQL_TARGETS + QUERY_TARGETS:
            (self.root / target).touch()
            for backend in ("postgres", "", "mariadb sqlite", "mariadb "):
                with self.subTest(target=target, backend=backend):
                    run = subprocess.run(["make", "-s", target, f"DB_BACKEND={backend}"],
                                         cwd=self.root, capture_output=True, timeout=30)
                    self.assertNotEqual(run.returncode, 0, run.stdout + run.stderr)
                    self.assertIn(b"DB_BACKEND must be one of", run.stderr)
                    self.assertEqual(config.read_bytes(), original)
                    self.assertFalse((self.root / "site-template/sql/archappl_sqlite_updated.sql").exists())

    def test_sqlite_queries_and_deletion_reject_without_helper(self):
        (self.root / "scripts/mariadb_setup.bash").unlink()
        for target in QUERY_TARGETS + ("sql.drop", "sql.table.drop"):
            with self.subTest(target=target):
                (self.root / target).touch()
                run = subprocess.run(["make", "-s", target, "DB_BACKEND=sqlite"],
                                     cwd=self.root, capture_output=True, timeout=30)
                self.assertNotEqual(run.returncode, 0)
                self.assertIn(b"not supported for DB_BACKEND=sqlite", run.stderr)

    def test_standalone_helper_rejects_before_reading_configuration(self):
        config = self.root / "site-template/mariadb.conf"
        config.write_text("touch CONFIG_READ\nexit 99\n")
        for backend in ("sqlite", "postgres", "", "mariadb sqlite"):
            for action in HELPER_ACTIONS:
                with self.subTest(backend=backend, action=action):
                    env = dict(os.environ, DB_BACKEND=backend)
                    run = subprocess.run(["bash", "scripts/mariadb_setup.bash", action],
                                         cwd=self.root, env=env, capture_output=True, timeout=30)
                    self.assertEqual(run.returncode, 2, run.stdout + run.stderr)
                    self.assertIn(b"DB_BACKEND", run.stderr)
                    self.assertFalse((self.root / "CONFIG_READ").exists())
        config.unlink()
        (self.root.parent / "CONFIG_SITE.local").write_text("DB_BACKEND:=sqlite\n")
        env = dict(os.environ)
        env.pop("DB_BACKEND", None)
        run = subprocess.run(["bash", "scripts/mariadb_setup.bash", "dbShow"],
                             cwd=self.root, env=env, capture_output=True, timeout=30)
        self.assertEqual(run.returncode, 2)
        self.assertIn(b"not supported for DB_BACKEND=sqlite", run.stderr)
        self.assertNotIn(b"No such file", run.stderr)


class DatabaseIntegrationTests(unittest.TestCase):
    """Run only on explicit request; use a private real MariaDB server."""

    setUp = DatabaseConfigTests.setUp
    run_command = DatabaseConfigTests.run_command
    make = DatabaseConfigTests.make

    def test_real_sqlite_schema_load_and_list(self):
        schema = SCHEMA_TOP / "archappl_sqlite.sql"
        self.assertTrue(schema.is_file(), "Real SQLite source schema is required")
        db = Path(self.temp.name) / "sqlite/archappl.sqlite"
        options = ["DB_BACKEND=sqlite", "SUDO=", "SQLITE_RUN_AS=",
                   "AA_USERID=" + self.run_command(["id", "-un"]).decode().strip(),
                   "AA_GROUPID=" + self.run_command(["id", "-gn"]).decode().strip(),
                   f"ARCHAPPL_SQLITE_FILE={db}", f"SQL_AA_ORIG_SQLITE={schema}"]
        self.make("db.conf", "DB_BACKEND=mariadb")
        config = self.root / "site-template/mariadb.conf"
        before = config.read_bytes()
        self.make(*DB_TARGETS, *options)
        self.make("sql.fill", *options)
        self.make("sql.fill", *options)
        tables = self.make("sql.show", *options)
        for table in (b"ArchivePVRequests", b"ExternalDataServers", b"PVAliases", b"PVTypeInfo"):
            self.assertIn(table, tables)
        self.run_command(["sqlite3", str(db), "DROP TABLE PVAliases;"])
        self.make("sql.fill", *options)
        self.assertIn(b"PVAliases", self.make("sql.show", *options))
        self.assertEqual(config.read_bytes(), before)

    def test_real_database_credentials_and_account_identity(self):
        server = shutil.which("mariadbd") or "/usr/sbin/mariadbd"
        self.assertTrue(Path(server).is_file(), "mariadbd is required")
        datadir = Path(self.temp.name) / "data"
        sock = Path(self.temp.name) / "db.sock"
        general_log = Path(self.temp.name) / "general.log"
        with socket.socket() as probe:
            probe.bind(("127.0.0.1", 0))
            port = probe.getsockname()[1]
        self.run_command(["mariadb-install-db", "--no-defaults", f"--datadir={datadir}",
                          "--auth-root-authentication-method=normal", "--skip-test-db"])
        process = subprocess.Popen(
            [server, "--no-defaults", f"--datadir={datadir}", f"--socket={sock}",
             f"--pid-file={datadir}/server.pid", f"--port={port}", "--bind-address=127.0.0.1",
             f"--log-error={datadir}/server.log", "--skip-log-bin",
             "--general-log", f"--general-log-file={general_log}"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        def stop():
            process.terminate()
            process.wait(timeout=30)
        self.addCleanup(stop)
        root = ["mysql", "--no-defaults", "--user=root", f"--socket={sock}", "-N", "-B"]
        for _ in range(150):
            if subprocess.run(root + ["-e", "SELECT 1"], capture_output=True).returncode == 0:
                break
            if process.poll() is not None:
                self.fail((datadir / "server.log").read_text())
            time.sleep(0.1)
        else:
            self.fail("Private MariaDB did not become ready")
        self.run_command(root + ["-e", "CREATE USER 'admin'@'localhost'; CREATE USER 'admin'@'127.0.0.1';"])
        password = "Review& :|/\\ '\" $HOME $(touch INJECTED) `touch INJECTED` ; *"
        common = ["DB_ADMIN=review_admin", "DB_USER=review_user", "DB_NAME=review_archive",
                  "DB_HOST_NAME=127.0.0.1", f"DB_HOST_PORT={port}",
                  "DB_ADMIN_PASS=" + password.replace("$", "$$"),
                  "DB_USER_PASS=" + password.replace("$", "$$")]
        # Only the privilege boundary is replaced: this private server permits
        # root SQL authentication by the current OS user. The real mysql client,
        # generated configuration, setup dispatcher and SQL functions all run.
        wrappers = Path(self.temp.name) / "bin"
        wrappers.mkdir()
        sudo = wrappers / "sudo"
        sudo.write_text('#!/bin/bash\n[[ "$1" == mysql ]] || exit 2\nexec "$@"\n')
        sudo.chmod(0o755)
        original_path = os.environ["PATH"]
        os.environ["PATH"] = str(wrappers) + os.pathsep + original_path
        self.addCleanup(os.environ.__setitem__, "PATH", original_path)
        self.make("db.conf", *common, f"DB_SOCKET={sock}")
        helper = ["bash", "scripts/mariadb_setup.bash"]
        self.run_command(helper + ["adminAdd"])
        self.run_command(helper + ["hostnameAdminAdd"])
        schema = SCHEMA_TOP / "archappl_mysql.sql"
        self.assertTrue(schema.is_file(), "Real source schema is required")
        (self.root.parent / "CONFIG_SITE.local").write_text(f"DB_SOCKET := {sock} # local socket\n")
        for transport in ([], ["DB_SOCKET="]):
            with self.subTest(transport=transport):
                self.make("db.conf", *common, *transport)
                create_output = self.run_command(helper + ["dbUserCreate"])
                self.assertNotIn(b"Password", create_output)
                self.assertNotRegex(create_output.decode(), r"\*[0-9A-Fa-f]{40}\b")
                self.make("sql.fill", f"SQL_AA_ORIG_SQL={schema}")
                self.run_command(helper + ["query", "SELECT 'query-ok'"])
                sql = Path(self.temp.name) / "query file.sql"
                sql.write_text("SELECT 'file-ok';\n")
                self.assertIn(b"file-ok", self.run_command(helper + ["queryFile", str(sql), "-N"]))
                self.run_command(helper + ["query", "INSERT INTO ExternalDataServers (serverid, serverinfo) VALUES ('review-marker', 'http://localhost');"])
                self.assertIn(b"review-marker", self.make("DataServers.show"))
                config = self.root / "site-template/mariadb.conf"
                before_config = config.read_bytes()
                before_log = general_log.read_bytes()
                for backend in ("sqlite", "postgres", "", "mariadb sqlite"):
                    for target in DB_TARGETS + SQL_TARGETS + QUERY_TARGETS:
                        if backend == "sqlite" and target in SQL_TARGETS[:-2]:
                            continue
                        args = ["make", "-s", target, *common, f"DB_BACKEND={backend}"]
                        if backend == "sqlite" and target in DB_TARGETS:
                            self.assertIn(b"[SKIP]", self.run_command(args))
                        else:
                            self.run_command(args, expected=2)
                    for action in HELPER_ACTIONS:
                        self.run_command(helper + [action], expected=2,
                                         env=dict(os.environ, DB_BACKEND=backend))
                self.assertEqual(general_log.read_bytes(), before_log,
                                 "Skip/rejection must not connect to MariaDB")
                self.assertEqual(config.read_bytes(), before_config)
                self.assertIn(b"review-marker", self.make("DataServers.show"))
                backup = Path(self.temp.name) / "backup path"
                self.run_command(helper + ["dbBackup", str(backup)])
                archive = next(backup.glob("review_archive_*.sql.gz"))
                stamp = archive.name[len("review_archive_"):-len(".sql.gz")]
                self.run_command(helper + ["query", "DELETE FROM ExternalDataServers"])
                self.run_command(helper + ["dbRestore", stamp, str(backup)])
                self.assertIn(b"review-marker", self.make("DataServers.show"))
                self.run_command(helper + ["tableShow"])
                self.run_command(helper + ["tableDrop"])
                self.run_command(helper + ["dbUserDrop"])
        self.make("db.conf", *common, f"DB_SOCKET={sock}")
        self.run_command(helper + ["hostnameAdminRemove"])
        self.run_command(helper + ["adminRemove"])
        users = self.run_command(root + ["-e", "SELECT User, Host FROM mysql.user WHERE User IN ('admin','review_admin','review_user') ORDER BY User, Host"])
        self.assertEqual(users.decode().splitlines(), ["admin\t127.0.0.1", "admin\tlocalhost"])
        self.assertFalse((self.root / "INJECTED").exists())
        print("Real MariaDB: socket and TCP account/query/schema/backup/restore paths passed; unrelated admin accounts preserved.")


if __name__ == "__main__":
    integration = "--integration" in sys.argv
    if integration:
        sys.argv.remove("--integration")
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(
        DatabaseIntegrationTests if integration else DatabaseConfigTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)
