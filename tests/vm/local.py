#!/usr/bin/env python3
"""Exercise shipped VM entrypoint refusal paths without virtualization or network."""
import http.server
import json
import hashlib
import importlib.util
import os
from pathlib import Path
import re
import shlex
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
import unittest
import unittest.mock
import xml.etree.ElementTree as ET

TOP = Path(__file__).resolve().parents[2]
DRIVER = TOP / 'tests/vm/driver.py'


def load_driver():
    spec = importlib.util.spec_from_file_location('vm_driver', DRIVER)
    driver = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(driver)
    return driver


def load_guest():
    spec = importlib.util.spec_from_file_location('vm_guest', TOP / 'tests/vm/guest.py')
    guest = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(guest)
    return guest


class ServiceInventoryTests(unittest.TestCase):
    """Exercise the shipped check with real systemctl and isolated unit-file roots."""

    def test_sqlite_service_inventory(self):
        guest = load_guest()
        self.assertIsNotNone(shutil.which('systemctl'))
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            units = root / 'etc/systemd/system'
            units.mkdir(parents=True)
            service = '[Unit]\nDescription=Test service\n[Service]\nExecStart=/bin/true\n'
            (units / guest.UNIT).write_text(service)
            command = ('systemctl', '--root', str(root))
            result = guest.sqlite_service_units(command)
            self.assertIn(guest.UNIT, result['listed_units'])
            self.assertFalse(set(guest.MARIADB_UNITS) & set(result['listed_units']))
            for name in guest.MARIADB_UNITS:
                for kind in ('static', 'disabled', 'masked', 'alias'):
                    with self.subTest(name=name, kind=kind):
                        path = units / name
                        if kind == 'masked':
                            path.symlink_to('/dev/null')
                        elif kind == 'alias':
                            path.symlink_to(guest.UNIT)
                        else:
                            content = service
                            if kind == 'disabled':
                                content += '[Install]\nWantedBy=multi-user.target\n'
                            path.write_text(content)
                        try:
                            with self.assertRaisesRegex(guest.CheckError, 'MariaDB service'):
                                guest.sqlite_service_units(command)
                        finally:
                            path.unlink()
            (units / guest.UNIT).unlink()
            other = units / 'inventory-control.service'
            other.write_text(service)
            with self.assertRaisesRegex(guest.CheckError, 'installed appliance'):
                guest.sqlite_service_units(command)
            other.unlink()
            with self.assertRaises(guest.CheckError):
                guest.sqlite_service_units(command)
            with self.assertRaisesRegex(guest.CheckError, 'Command failed: systemctl'):
                guest.sqlite_service_units(('systemctl', '--root', str(root / 'missing')))
            self.assertNotEqual(guest.COMMANDS[-1]['exit'], 0)
            self.assertTrue(guest.COMMANDS[-1]['stderr'])


class GuestFactsTests(unittest.TestCase):
    """Execute the shipped pre-installation facts command with shell tools only."""

    TOOLS = ('sh', 'cat', 'getconf', 'hostname', 'ip', 'stat')

    def run_facts(self):
        driver = load_driver()
        bash = shutil.which('bash')
        self.assertIsNotNone(bash)
        with tempfile.TemporaryDirectory() as temporary:
            binary = Path(temporary)
            for name in self.TOOLS:
                tool = shutil.which(name)
                self.assertIsNotNone(tool, name)
                (binary / name).symlink_to(Path(tool).resolve())
            # The remote shell runs the joined command, as Driver.ssh sends it.
            result = subprocess.run([bash, '-c', shlex.join(driver.guest_facts_command())],
                                    env={'PATH': str(binary)}, capture_output=True,
                                    text=True, timeout=20)
        return driver, result

    def test_facts_need_no_python_interpreter(self):
        driver, result = self.run_facts()
        self.assertEqual(result.returncode, 0, result.stderr)
        facts = driver.parse_guest_facts(result.stdout)
        system = os.statvfs('/')
        self.assertEqual(facts['cpus'], os.cpu_count())
        self.assertEqual(facts['hostname'], socket.gethostname())
        self.assertEqual(facts['root_bytes'], system.f_blocks * system.f_frsize)
        self.assertEqual(facts['os'], Path('/etc/os-release').read_text())
        self.assertTrue(facts['interfaces'])
        self.assertIn('MemTotal:', facts['memory'])
        self.assertGreater(facts['free_bytes'], 0)
        lines = result.stdout.splitlines()
        markers = [index for index, line in enumerate(lines) if line.startswith('@@')]
        self.assertTrue(markers)
        for position, start in enumerate(markers):
            end = markers[position + 1] if position + 1 < len(markers) else len(lines)
            with self.subTest(section=lines[start]):
                remaining = '\n'.join(lines[:start] + lines[end:]) + '\n'
                with self.assertRaises(driver.Failed):
                    driver.parse_guest_facts(remaining)


class JournalBoundTests(unittest.TestCase):
    """Check the shipped journal bound against the real local journalctl."""

    def test_bound_rounds_toward_positive_whole_seconds(self):
        guest = load_guest()
        second = 1_790_990_249
        self.assertEqual(guest.journal_since(second * 1_000_000_000), '@%d' % second)
        for fraction in (1, 500_000_000, 999_999_999):
            with self.subTest(fraction=fraction):
                self.assertEqual(guest.journal_since(second * 1_000_000_000 + fraction),
                                 '@%d' % (second + 1))
        journalctl = shutil.which('journalctl')
        self.assertIsNotNone(journalctl)
        # Local systemd also accepts the earlier ISO form; systemd 239 is not reproduced.
        result = subprocess.run([journalctl, '--since', guest.journal_since(time.time_ns()),
                                 '-n', '0', '--no-pager'],
                                capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('Failed to parse', result.stderr)


class EntrypointTests(unittest.TestCase):
    def test_separate_stderr_preserves_json_and_failure_evidence(self):
        driver = load_driver()
        command = [sys.executable, '-c',
                   'import sys; print("{\\"ready\\": true}"); '
                   'print("diagnostic warning", file=sys.stderr); '
                   'sys.exit(int(sys.argv[1]))']
        with tempfile.TemporaryDirectory() as temporary:
            log = Path(temporary) / 'command.json'
            for status in (0, 3):
                rc, output = driver.run(command + [str(status)], log=log,
                                        check=False, separate_stderr=True)
                self.assertEqual(rc, status)
                self.assertEqual(json.loads(output), {'ready': True})
                evidence = json.loads(log.read_text())
                self.assertEqual(evidence['output'], output)
                self.assertEqual(evidence['stderr'], 'diagnostic warning\n')
                self.assertEqual(evidence['exit'], status)
            with self.assertRaises(driver.Failed):
                driver.run(command + ['3'], log=log, separate_stderr=True)
            self.assertEqual(json.loads(log.read_text())['stderr'], 'diagnostic warning\n')
            rc, output = driver.run(command + ['0'])
            self.assertEqual(rc, 0)
            self.assertIn('diagnostic warning', output)

    def test_dhcp_ownership_accepts_unnamed_and_legacy_named_entries(self):
        driver = load_driver()
        mac, address, name = '02:00:00:00:00:01', '192.0.2.10', 'owned-domain'
        for label in (None, name):
            entry = {'mac': mac, 'ip': address}
            if label is not None:
                entry['name'] = label
            reservations = {'live': [entry.copy()], 'persistent': [entry.copy()]}
            self.assertEqual(driver.owned_reservation(reservations, mac, name), entry)
            for kind in ('live', 'persistent'):
                invalid = json.loads(json.dumps(reservations))
                invalid[kind][0]['name'] = 'foreign-domain'
                with self.assertRaises(driver.Invalid):
                    driver.owned_reservation(invalid, mac, name)
                invalid = json.loads(json.dumps(reservations))
                invalid[kind].append({'mac': '02:00:00:00:00:02', 'ip': address})
                with self.assertRaises(driver.Invalid):
                    driver.owned_reservation(invalid, mac, name)
                invalid = json.loads(json.dumps(reservations))
                invalid[kind].append(entry.copy())
                with self.assertRaises(driver.Invalid):
                    driver.owned_reservation(invalid, mac, name)
                invalid = json.loads(json.dumps(reservations))
                invalid[kind][0]['ip'] = '192.0.2.11'
                with self.assertRaises(driver.Invalid):
                    driver.owned_reservation(invalid, mac, name)

    def test_domain_ownership_requires_uuid_and_one_network_interface(self):
        driver = load_driver()
        tree = ET.fromstring('<domain><uuid>owned-uuid</uuid><name>owned-domain</name>'
                             '<devices><interface type="network"><source network="lab"/>'
                             '<mac address="02:00:00:00:00:01"/></interface></devices></domain>')
        self.assertEqual(driver.domain_mac(tree, 'lab', 'owned-uuid', 'owned-domain'),
                         '02:00:00:00:00:01')
        for network, uuid, name in (('foreign', 'owned-uuid', 'owned-domain'),
                                    ('lab', 'foreign-uuid', 'owned-domain'),
                                    ('lab', 'owned-uuid', 'foreign-domain')):
            with self.assertRaises(driver.Invalid):
                driver.domain_mac(tree, network, uuid, name)
        tree.find('devices').append(ET.fromstring(ET.tostring(tree.find('./devices/interface'))))
        with self.assertRaises(driver.Invalid):
            driver.domain_mac(tree, 'lab', 'owned-uuid', 'owned-domain')

    def test_cleanup_cannot_accept_a_changed_owned_reservation(self):
        driver = load_driver()
        instance = object.__new__(driver.Driver)
        with tempfile.TemporaryDirectory() as temporary:
            case = {'uuid': 'owned-uuid', 'vm_name': 'owned-domain',
                    'reservation': {'mac': '02:00:00:00:00:01', 'ip': '192.0.2.10'},
                    **{name: str(Path(temporary) / name) for name in ('disk', 'seed', 'record')}}
            snapshot = {'domains': {}, 'reservations': {'live': [], 'persistent': []}}
            self.assertTrue(instance.resources_absent(case, snapshot))
            for kind in ('live', 'persistent'):
                for entry in ({'mac': case['reservation']['mac'], 'ip': '192.0.2.11'},
                              {'mac': '02:00:00:00:00:02', 'ip': case['reservation']['ip']}):
                    changed = json.loads(json.dumps(snapshot))
                    changed['reservations'][kind].append(entry)
                    self.assertFalse(instance.resources_absent(case, changed))

    def test_real_unittest_skip_cannot_pass_local_suite(self):
        java = shutil.which('java')
        if not java:
            self.skipTest('A real Java executable is required for the unittest skip regression')
        java = Path(java).resolve()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binary = root / 'bin'
            binary.mkdir()
            shutil.copy2(java, binary / 'java')
            for name in ('lib', 'conf', 'release'):
                original = java.parent.parent / name
                if original.exists():
                    (root / name).symlink_to(original, target_is_directory=original.is_dir())
            version = subprocess.run([str(binary / 'java'), '--version'],
                                     capture_output=True, text=True, timeout=10)
            self.assertEqual(version.returncode, 0, version.stderr)
            self.assertFalse((binary / 'javac').exists())
            result = subprocess.run(
                ['python3', str(TOP / 'tests/health-local.py'),
                 'HealthTests.test_unrelated_java_with_tomcat_application_arguments'],
                env=dict(os.environ, PATH=str(binary) + ':' + os.environ['PATH']),
                capture_output=True, text=True, timeout=20)
            self.assertEqual(result.returncode, 0, result.stderr)
            output = result.stdout + result.stderr
            self.assertIn('OK (skipped=1)', output)
            self.assertNotIn('[SKIP]', output)
            spec = importlib.util.spec_from_file_location('vm_driver', DRIVER)
            driver = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(driver)
            self.assertFalse(driver.local_suite_complete(output))

    def config(self):
        config = json.loads((DRIVER.parent / 'config.example.json').read_text())
        for image in config['images'].values():
            image['minimum_build_free_bytes'] = 1
        return config

    def invoke(self, *arguments):
        return subprocess.run(['python3', str(DRIVER), *map(str, arguments)],
                              capture_output=True, text=True, timeout=10)

    def context_operations(self, context):
        handoff = Path(tempfile.mkdtemp()) / 'handoff.json'
        handoff.write_text('{}')
        self.addCleanup(shutil.rmtree, handoff.parent)
        return (('--verify-cleanup', context), ('--verdict', context),
                ('--case', 'debian13-sqlite', '--handoff', handoff, context))

    def test_missing_execution_inputs(self):
        for arguments in (('--init',), ('--case', 'debian13-socket')):
            with self.subTest(arguments=arguments):
                result = self.invoke(*arguments)
                self.assertEqual(result.returncode, 77, result.stderr)
                self.assertIn('no system action ran', result.stderr)

    def test_unknown_and_conflicting_operations(self):
        for arguments in (('--system',), ('--init', '--verdict', '/unowned'),
                          ('--case', 'unknown'), ('--init', '--handoff', '/unowned'),
                          ('--case', 'debian13-socket', '--config', '/unowned',
                           '--handoff', '/unowned', '/unowned')):
            with self.subTest(arguments=arguments):
                self.assertEqual(self.invoke(*arguments).returncode, 2)

    def test_original_fixture_identity_is_required(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config, evidence = root / 'input.json', root / 'evidence'
            for field, value in (('ref', 'a' * 40), ('sha256', 'b' * 64)):
                spec = self.config()
                spec['fixture'][field] = value
                config.write_text(json.dumps(spec))
                result = self.invoke('--init', '--config', config, '--evidence', evidence)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertIn('accepted original', result.stderr)
                self.assertFalse(evidence.exists())

    def test_lifecycle_selectors_are_refused_before_external_commands(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            root.chmod(0o700)
            spec = self.config()
            creation, node = '20260930T120000Z-123456789abc', 'test-original'
            name = spec['cloud']['prefix'] + '-debian13-archiver-dev-' + node + '-' + creation
            disk = str(Path(spec['images']['debian13']['directory']) / (name + '.qcow2'))
            case = {'name': 'debian13-sqlite', 'os': 'debian13', 'backend': 'sqlite',
                    'negative': False, 'node': node, 'creation_id': creation, 'vm_name': name,
                    'disk': disk, 'record': disk + '.creation-record',
                    'seed': str(Path(disk).with_name(name + '-seed.iso')), 'results': {}}
            state = {'schema': 1, 'config': spec, 'mode': 'installation', 'cases': [case],
                     'driver_sha256': hashlib.sha256(DRIVER.read_bytes()).hexdigest(),
                     'guest_sha256': hashlib.sha256((DRIVER.parent / 'guest.py').read_bytes()).hexdigest()}
            for field, value in (('node', 'test-other'), ('os', 'rocky8'), ('backend', 'tcp'),
                                 ('creation_id', '20260930T120000Z-aaaaaaaaaaaa'),
                                 ('vm_name', 'unowned'), ('disk', '/unowned.qcow2'),
                                 ('record', '/unowned.creation-record'), ('seed', '/unowned.iso')):
                modified = json.loads(json.dumps(state))
                modified['cases'][0][field] = value
                (root / 'run.json').write_text(json.dumps(modified))
                for arguments in self.context_operations(root):
                    result = self.invoke(*arguments)
                    self.assertEqual(result.returncode, 2, result.stderr)
                    self.assertFalse((root / 'lock').exists())
                    self.assertFalse(list(root.glob('command-*.json')))

    def test_invalid_configuration_creates_no_context(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config, evidence = root / 'input.json', root / 'evidence'
            for value in (None, [], {}, {'cloud': None}):
                config.write_text(json.dumps(value))
                result = self.invoke('--init', '--config', config, '--evidence', evidence)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertFalse(evidence.exists())

    def test_normal_refs_and_field_types_are_rejected_before_context_creation(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config, evidence = root / 'input.json', root / 'evidence'
            for section, field, value in (('candidate', 'env_ref', 'release-2.0.1'),
                                         ('candidate', 'source_ref', 'missing'),
                                         ('candidate', 'source_ref', None),
                                         ('cloud', 'ref', 'HEAD'),
                                         ('ssh', 'user', 'root'),
                                         ('guest', 'epics_bin', '/unresolved'),
                                         ('guest', 'store_top', '/unsafe/$(command)'),
                                         ('candidate', 'env_url', 'https://example.com/$(command)'),
                                         ('images', 'debian13', None)):
                spec = self.config()
                spec[section][field] = value
                config.write_text(json.dumps(spec))
                result = self.invoke('--init', '--config', config, '--evidence', evidence)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertFalse(evidence.exists())

    def test_verdict_is_read_only_and_keeps_failure(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            root.chmod(0o700)
            state = {'schema': 1, 'config': self.config(), 'mode': 'system', 'cases': [],
                     'driver_sha256': hashlib.sha256(DRIVER.read_bytes()).hexdigest(),
                     'guest_sha256': hashlib.sha256((DRIVER.parent / 'guest.py').read_bytes()).hexdigest()}
            for failure, expected in ((None, 77), ({'category': 'Failed'}, 1)):
                if failure:
                    state['failure'] = failure
                (root / 'run.json').write_text(json.dumps(state))
                before = {str(path): path.read_bytes() for path in root.iterdir()}
                result = self.invoke('--verdict', root)
                self.assertEqual(result.returncode, expected, result.stderr)
                self.assertEqual(before, {str(path): path.read_bytes() for path in root.iterdir()})
            state['driver_sha256'] = '0' * 64
            (root / 'run.json').write_text(json.dumps(state))
            self.assertEqual(self.invoke('--verdict', root).returncode, 2)

    def test_missing_unowned_and_symlink_contexts_are_refused(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            absent = root / 'absent'
            linked = root / 'linked'
            linked.symlink_to(root, target_is_directory=True)
            for context in (root, absent, linked):
                for arguments in self.context_operations(context):
                    with self.subTest(context=context, arguments=arguments[0]):
                        result = self.invoke(*arguments)
                        self.assertEqual(result.returncode, 2, result.stderr)
            self.assertFalse((root / 'lock').exists())
            self.assertFalse((root / 'run.json').exists())

    def test_local_runner_rejects_vm_inputs_before_tests(self):
        result = subprocess.run(['bash', str(TOP / 'tests/run-all-tests.bash'),
                                 '--local', '--config', '/unowned'],
                                capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn('local modes accept no VM inputs', result.stderr)

    def test_compatibility_entrypoints_require_explicit_inputs(self):
        for name in ('phase3-docker.bash', 'phase4-vm.bash'):
            result = subprocess.run(['bash', str(TOP / 'tests' / name)],
                                    capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 77, result.stderr)
            self.assertIn('no system action ran', result.stderr)


class StartupHealthTests(unittest.TestCase):
    """Run the shipped retry logic of the guest verifier against launcher verdict text."""

    STARTING = ("mgmt pid=11 STARTING run-script\nengine pid=12 PRESENT verified-process-presence\n"
                "health STARTING instances-starting; application-readiness-not-checked\n")
    # The verdict a correct guest returned about 0.4 s after a restart, as retained by the VM run.
    WRONG_JAVA = ("mgmt pid=63614 FAIL wrong-java-executable\nengine pid=63630 FAIL wrong-java-executable\n"
                  "etl pid=63653 PRESENT verified-process-presence\n"
                  "retrieval pid=63664 PRESENT verified-process-presence\n"
                  "health FAIL one-or-more-invalid-instances\n")
    OTHER_FAILURE = "mgmt pid=11 FAIL wrong-tomcat-identity\nhealth FAIL one-or-more-invalid-instances\n"

    def guest_printing(self, text):
        """Return a verifier whose launcher command is replaced by a runuser that prints text."""
        module = load_guest()
        directory = Path(tempfile.mkdtemp(prefix='startup-health-'))
        self.addCleanup(shutil.rmtree, directory)
        (directory / 'verdict').write_text(text)
        runuser = directory / 'runuser'
        runuser.write_text('#!/bin/sh\ncat "%s/verdict"\nexit 1\n' % directory)
        runuser.chmod(0o755)
        patch = unittest.mock.patch.dict(os.environ, PATH=str(directory) + os.pathsep + os.environ['PATH'])
        patch.start()
        self.addCleanup(patch.stop)
        guest = module.Guest.__new__(module.Guest)
        guest.settings = {'user': 'service'}
        guest.install = directory
        guest.startup_health = ''
        guest.startup_observations = []
        guest.ready_started = time.monotonic()
        return module, guest

    def test_start_chain_verdicts_are_retried(self):
        for text in (self.STARTING, self.WRONG_JAVA):
            with self.subTest(text=text.splitlines()[0]):
                module, guest = self.guest_printing(text)
                self.assertIsNone(guest.health(retry_startup=True))
                self.assertEqual(guest.startup_health, text)

    def test_retried_health_is_retained_with_its_elapsed_time(self):
        module, guest = self.guest_printing(self.STARTING)
        self.assertIsNone(guest.health(retry_startup=True))
        self.assertIsNone(guest.health(retry_startup=True))
        self.assertEqual(len(guest.startup_observations), 2)
        for observation in guest.startup_observations:
            self.assertEqual(observation['output'], self.STARTING.strip())
            self.assertGreaterEqual(observation['elapsed'], 0)
        self.assertLessEqual(guest.startup_observations[0]['elapsed'], guest.startup_observations[1]['elapsed'])

    def test_other_failures_are_not_retried(self):
        module, guest = self.guest_printing(self.OTHER_FAILURE)
        with self.assertRaises(module.CheckError):
            guest.health(retry_startup=True)

    def test_persistent_wrong_executable_fails_at_the_deadline_with_the_last_verdict(self):
        module, guest = self.guest_printing(self.WRONG_JAVA)
        with self.assertRaises(module.CheckError) as raised:
            guest.ready(3)
        self.assertIn('Application readiness deadline exceeded', str(raised.exception))
        self.assertIn('mgmt pid=63614 FAIL wrong-java-executable', str(raised.exception))


class FailureEvidenceTests(unittest.TestCase):
    """Run the shipped failure handler with the real journalctl, ss and file copy."""

    def guest(self):
        module = load_guest()
        root = Path(tempfile.mkdtemp(prefix='failure-evidence-'))
        self.addCleanup(shutil.rmtree, root)
        guest = module.Guest.__new__(module.Guest)
        guest.root = root
        guest.evidence = {}
        guest.install = root / 'install'
        (guest.install / 'engine/temp').mkdir(parents=True)
        guest.pv = 'VMTEST_0123456789ab_test_0'
        return module, guest

    def test_journal_failure_keeps_the_health_entries_and_the_journal_files(self):
        if shutil.which('journalctl') is None:
            self.skipTest('journalctl is required')
        module, guest = self.guest()
        journal = guest.root / 'source-journal'
        (journal / 'machine').mkdir(parents=True)
        (journal / 'machine/system.journal').write_bytes(b'LPKSHHRH' + bytes(range(64)))
        with unittest.mock.patch.object(module, 'JOURNAL_DIRECTORIES', (str(journal),)):
            guest.fail('runtime', module.ClassifiedError('Three health invocations missing', 'journal'))
        kept = guest.evidence['classifying_evidence']
        self.assertEqual(kept['kind'], 'journal')
        self.assertNotIn('retention_error', kept)
        self.assertIsInstance(kept['health_unit_entries'], list)
        self.assertEqual([entry['bytes'] for entry in kept['journal_copy']], [72])
        copy = guest.root / kept['journal_copy'][0]['file']
        self.assertEqual(copy.read_bytes(), (journal / 'machine/system.journal').read_bytes())
        written = json.loads((guest.root / 'failed-runtime.json').read_text())
        self.assertEqual(written['failure']['message'], 'Three health invocations missing')

    def test_ca_failure_keeps_the_engine_sockets_and_the_pv_view(self):
        if shutil.which('ss') is None:
            self.skipTest('ss is required')
        module, guest = self.guest()
        replies = {'/getPVStatus': [{'pvName': guest.pv, 'status': 'Being archived'}],
                   '/getCurrentlyDisconnectedPVs': []}

        class Handler(http.server.BaseHTTPRequestHandler):
            def do_GET(handler):
                body = json.dumps(replies[handler.path.split('?')[0]]).encode()
                handler.send_response(200)
                handler.send_header('Content-Length', str(len(body)))
                handler.end_headers()
                handler.wfile.write(body)

            def log_message(handler, *unused):
                pass

        server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        guest.mgmt = 'http://127.0.0.1:%d/' % server.server_address[1]
        (guest.install / 'engine/temp/engine.pid').write_text('%d\n' % os.getpid())
        udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.addCleanup(udp.close)
        udp.bind(('127.0.0.1', 0))
        guest.fail('runtime', module.ClassifiedError('Fresh acquisition deadline exceeded', 'ca'))
        kept = guest.evidence['classifying_evidence']
        self.assertEqual(kept['kind'], 'ca')
        self.assertNotIn('retention_error', kept)
        self.assertTrue(any(':%d ' % udp.getsockname()[1] in line for line in kept['engine_udp_sockets']),
                        kept['engine_udp_sockets'])
        self.assertEqual(kept['pv_status'], replies['/getPVStatus'])
        self.assertEqual(kept['disconnected_pvs'], [])

    def test_a_retention_fault_never_hides_the_original_failure(self):
        module, guest = self.guest()
        guest.fail('runtime', module.ClassifiedError('Fresh acquisition deadline exceeded', 'ca'))
        kept = guest.evidence['classifying_evidence']
        self.assertIn('retention_error', kept)
        self.assertEqual(guest.evidence['failure']['message'], 'Fresh acquisition deadline exceeded')
        self.assertEqual(guest.evidence['failure']['category'], 'ClassifiedError')
        self.assertTrue((guest.root / 'failed-runtime.json').is_file())

    def test_an_unclassified_failure_keeps_no_classifying_evidence(self):
        module, guest = self.guest()
        guest.fail('runtime', module.CheckError('Application readiness deadline exceeded'))
        self.assertNotIn('classifying_evidence', guest.evidence)
        self.assertEqual(guest.evidence['failure']['category'], 'CheckError')


class RunOperationTests(unittest.TestCase):
    """Exercise the shipped handoff, origin, freshness and run rules with real files and tools."""

    def setUp(self):
        self.driver = load_driver()
        self.spec = json.loads((DRIVER.parent / 'config.example.json').read_text())
        for image in self.spec['images'].values():
            image['minimum_build_free_bytes'] = 1

    def handoff(self, name, index):
        os_name = name.split('-', 1)[0]
        node, creation = 'test-%016x' % index, '20261004T000000Z-%012x' % index
        vm_name = '-'.join((self.spec['cloud']['prefix'], os_name + '-archiver-dev', node, creation))
        disk = Path(self.spec['images'][os_name]['directory']) / (vm_name + '.qcow2')
        return {'schema': 1, 'os_selector': os_name + '-archiver-dev',
                'prefix': self.spec['cloud']['prefix'], 'node': node, 'creation_id': creation,
                'uuid': '%08x-0000-4000-8000-000000000000' % index, 'vm_name': vm_name,
                'mac': '02:00:00:00:00:%02x' % index, 'address': '192.0.2.%d' % index,
                'disk': str(disk), 'seed': str(disk.with_name(vm_name + '-seed.iso')),
                'record': str(disk) + '.creation-record', 'tool_ref': 'a' * 40}

    def state(self, cases):
        return {'schema': 1, 'config': self.spec, 'mode': 'system', 'cases': cases,
                'driver_sha256': hashlib.sha256(DRIVER.read_bytes()).hexdigest(),
                'guest_sha256': hashlib.sha256((DRIVER.parent / 'guest.py').read_bytes()).hexdigest(),
                'preflight': {'result': 'Pass'},
                'baseline': {'domains': {'%08x-0000-4000-8000-000000000000' % 99: 'preserved'},
                             'reservations': {'live': [], 'persistent': []}}}

    def invoke(self, *arguments):
        return subprocess.run(['python3', str(DRIVER), *map(str, arguments)],
                              capture_output=True, text=True, timeout=10)

    def test_handoff_validation_with_real_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'handoff.json'
            valid = self.handoff('rocky8-tcp', 1)
            path.write_text(json.dumps(valid))
            case = self.driver.case_from_handoff('rocky8-tcp', self.driver.load(path), self.spec)
            self.assertEqual((case['os'], case['backend'], case['negative']), ('rocky8', 'tcp', False))
            self.assertEqual(case['vm_name'], valid['vm_name'])
            negative = self.driver.case_from_handoff('debian13-build-failure',
                                                     self.handoff('debian13-build-failure', 2), self.spec)
            self.assertEqual((negative['backend'], negative['negative']), ('sqlite', True))
            for field, value in (('schema', 2), ('schema', True), ('prefix', 'other'), ('os_selector', 'debian13-archiver-dev'),
                                 ('vm_name', 'unowned'), ('disk', '/unowned.qcow2'), ('uuid', 'unowned'),
                                 ('mac', '02:00:00:00:00:0G'), ('address', '192.0.2.300'),
                                 ('tool_ref', 'HEAD'), ('node', 1)):
                with self.subTest(field=field, value=value):
                    modified = dict(valid, **{field: value})
                    path.write_text(json.dumps(modified))
                    with self.assertRaises(self.driver.Invalid):
                        self.driver.case_from_handoff('rocky8-tcp', self.driver.load(path), self.spec)
            for modified in ({key: value for key, value in valid.items() if key != 'seed'},
                             dict(valid, extra='value')):
                path.write_text(json.dumps(modified))
                with self.assertRaises(self.driver.Invalid):
                    self.driver.case_from_handoff('rocky8-tcp', self.driver.load(path), self.spec)

    def test_case_refusals_leave_the_run_unchanged(self):
        recorded = self.driver.case_from_handoff('debian13-socket', self.handoff('debian13-socket', 3), self.spec)
        baseline_guest = dict(self.handoff('debian13-tcp', 99))
        for label, cases, failure, name, handoff in (
                ('baseline UUID', [], None, 'debian13-tcp', baseline_guest),
                ('recorded case', [recorded], None, 'debian13-socket', self.handoff('debian13-socket', 4)),
                ('failed run', [], {'category': 'Failed'}, 'debian13-tcp', self.handoff('debian13-tcp', 5))):
            with self.subTest(label=label), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary) / 'run'
                root.mkdir(mode=0o700)
                state = self.state(cases)
                if failure:
                    state['failure'] = failure
                (root / 'run.json').write_text(json.dumps(state))
                path = Path(temporary) / 'handoff.json'
                path.write_text(json.dumps(handoff))
                before = (root / 'run.json').read_bytes()
                result = self.invoke('--case', name, '--handoff', path, root)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertEqual((root / 'run.json').read_bytes(), before)
                self.assertFalse(list(root.glob('command-*.json')))
                self.assertFalse(list(root.glob('*-handoff.json')))

    def test_origin_check_uses_the_stored_url(self):
        git = shutil.which('git')
        self.assertIsNotNone(git)
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'global.gitconfig').write_text('[url "git@github.com:"]\n\tinsteadOf = https://github.com/\n')
            env = dict(os.environ, GIT_CONFIG_GLOBAL=str(root / 'global.gitconfig'), GIT_CONFIG_NOSYSTEM='1')
            subprocess.run([git, 'init', '-q', str(root / 'tool')], check=True, env=env)
            for stored, accepted in (('https://github.com/example/tool', True),
                                     ('git@github.com:example/tool', False),
                                     ('https://user@github.com/example/tool', False)):
                with self.subTest(stored=stored):
                    subprocess.run([git, '-C', str(root / 'tool'), 'remote', 'remove', 'origin'],
                                   env=env, capture_output=True)
                    subprocess.run([git, '-C', str(root / 'tool'), 'remote', 'add', 'origin', stored],
                                   check=True, env=env)
                    result = subprocess.run(self.driver.tool_origin_command(root / 'tool'),
                                            capture_output=True, text=True, env=env, check=True)
                    self.assertEqual(result.stdout.strip(), stored)
                    self.assertIs(self.driver.published_origin(result.stdout.strip()), accepted)
            rewritten = subprocess.run([git, '-C', str(root / 'tool'), 'remote', 'get-url', 'origin'],
                                       capture_output=True, text=True, env=env, check=True)
            self.assertFalse(self.driver.published_origin(rewritten.stdout.strip()))

    def test_publication_clone_ignores_rewrite_rules(self):
        git = shutil.which('git')
        self.assertIsNotNone(git)
        url = 'https://github.com/example/tool'
        with tempfile.TemporaryDirectory() as temporary:
            rules = Path(temporary) / 'global.gitconfig'
            rules.write_text('[url "git@github.com:"]\n\tinsteadOf = https://github.com/\n')
            with unittest.mock.patch.dict(os.environ, GIT_CONFIG_GLOBAL=str(rules)):
                rewritten = subprocess.run([git, 'ls-remote', '--get-url', url], capture_output=True,
                                           text=True, check=True)
                published = subprocess.run([git, 'ls-remote', '--get-url', url], capture_output=True,
                                           text=True, check=True, env=self.driver.publication_env())
        self.assertEqual(rewritten.stdout.strip(), 'git@github.com:example/tool')
        self.assertEqual(published.stdout.strip(), url)

    def test_fresh_probe_reads_paths_and_units(self):
        self.assertIsNotNone(shutil.which('systemctl'))
        with tempfile.TemporaryDirectory() as temporary:
            present, absent = Path(temporary), Path(temporary) / 'absent'
            command = self.driver.fresh_probe_command([str(present), str(absent)])
            self.assertEqual(command[:4], ['sudo', '-n', 'sh', '-c'])
            result = subprocess.run(command[2:], capture_output=True, text=True, timeout=20)
            self.assertEqual(result.returncode, 0, result.stderr)
            fresh = self.driver.parse_fresh_probe(result.stdout, 2)
            self.assertEqual(fresh['paths'], {str(present): True, str(absent): False})
            self.assertEqual(fresh['units_exit'], 0)
            self.assertTrue(all(unit.endswith('.service') for unit in fresh['units']))
            lines = result.stdout.splitlines()
            for broken in ([line for line in lines if not line.startswith('@@units_exit')],
                           ['unknown ' + str(present)] + lines[1:]):
                with self.assertRaises(self.driver.Failed):
                    self.driver.parse_fresh_probe('\n'.join(broken), 2)

    def test_host_key_comes_from_the_stored_creation_key(self):
        keygen = shutil.which('ssh-keygen')
        self.assertIsNotNone(keygen)
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            (home / '.ssh').mkdir(mode=0o700)
            entries = {}
            for address in ('192.0.2.1', '192.0.2.2'):
                key = home / ('key-' + address)
                subprocess.run([keygen, '-q', '-t', 'ed25519', '-N', '', '-f', str(key)], check=True)
                entries[address] = key.with_suffix(key.suffix + '.pub').read_text().split()[:2]
            known_hosts = home / '.ssh/known_hosts'
            known_hosts.write_text(''.join('%s %s %s\n' % (address, *entry) for address, entry in entries.items()))
            subprocess.run([keygen, '-H', '-f', str(known_hosts)], check=True, capture_output=True)
            with unittest.mock.patch.dict(os.environ, HOME=temporary):
                command = self.driver.stored_host_key_command('192.0.2.1')
                found = subprocess.run(command, capture_output=True, text=True)
                missing = subprocess.run(self.driver.stored_host_key_command('192.0.2.3'),
                                         capture_output=True, text=True)
            self.assertEqual(command[-1], str(known_hosts))
            lines = self.driver.host_key_lines(found.stdout)
            self.assertEqual(len(lines), 1)
            self.assertTrue(lines[0].startswith('|1|'))
            self.assertEqual(lines[0].split()[1:], entries['192.0.2.1'])
            self.assertNotEqual(missing.returncode, 0)
            self.assertEqual(self.driver.host_key_lines(missing.stdout), [])
        options = self.driver.ssh_options('/run/case.known_hosts')
        self.assertIn('StrictHostKeyChecking=yes', options)
        self.assertIn('UserKnownHostsFile=/run/case.known_hosts', options)
        variables = self.driver.ansible_connection_variables('/run/case.known_hosts', '/key')
        self.assertIs(variables['ansible_host_key_checking'], True)
        self.assertEqual(shlex.split(variables['ansible_ssh_common_args']), options)

    def test_cleanup_inspection_error_is_incomplete_and_unrecorded(self):
        case = self.driver.case_from_handoff('debian13-socket', self.handoff('debian13-socket', 6), self.spec)
        case['reservation'] = {'mac': case['handoff']['mac'], 'ip': case['handoff']['address']}
        with tempfile.TemporaryDirectory() as temporary:
            root, tools = Path(temporary) / 'run', Path(temporary) / 'bin'
            root.mkdir(mode=0o700)
            tools.mkdir()
            # The libvirt client is the outer boundary; it fails as a transient error would.
            (tools / 'virsh').write_text('#!/bin/sh\necho "error: failed to connect" >&2\nexit 1\n')
            (tools / 'virsh').chmod(0o755)
            (root / 'run.json').write_text(json.dumps(self.state([case])))
            before = (root / 'run.json').read_bytes()
            result = subprocess.run(['python3', str(DRIVER), '--verify-cleanup', str(root)],
                                    capture_output=True, text=True, timeout=10,
                                    env=dict(os.environ, PATH=str(tools) + os.pathsep + os.environ['PATH']))
            self.assertEqual(result.returncode, 77, result.stderr)
            self.assertEqual((root / 'run.json').read_bytes(), before)
            self.assertFalse((root / 'cleanup.json').exists())

    def test_verdict_accepts_any_case_order_and_requires_each_case_once(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / 'run'
            root.mkdir(mode=0o700)
            proof = root / 'command-00001.json'
            proof.write_text(json.dumps({'command': ['bash', str(root / 'candidate-env/tests/run-all-tests.bash'),
                                                     '--local'], 'exit': 0, 'output': 'Ran 1 test\nOK\n'}))
            cases = []
            for index, name in enumerate(self.driver.MATRIX, start=10):
                case = self.driver.case_from_handoff(name, self.handoff(name, index), self.spec)
                labels = ['T3', 'T14'] if case['negative'] else ['T%d' % n for n in range(3, 13)]
                if case['backend'] == 'sqlite' and not case['negative']:
                    labels.append('T13')
                case['results'] = {label: {'result': 'Pass'} for label in labels}
                case.update(lifecycle='verified', cleanup={'result': 'Pass'},
                            reservation={'mac': case['handoff']['mac'], 'ip': case['handoff']['address']},
                            previous_owned=[c['uuid'] for c in cases[:1]])
                if not case['negative']:
                    actions = ['installation', 'runtime', 'snapshot', 'unchanged', 'reinstalled', 'stop'] + (
                        ['negative'] if case['backend'] == 'sqlite' else [])
                    for action in actions:
                        (root / ('%s-%s.json' % (name, action))).write_text(action)
                    case['artifacts'] = {action: hashlib.sha256(action.encode()).hexdigest()
                                         for action in actions}
                cases.append(case)
            state = self.state(list(reversed(cases)))
            state['local_suite'] = {'result': 'Pass', 'env_ref': self.spec['candidate']['env_ref'],
                                    'command_file': proof.name,
                                    'sha256': hashlib.sha256(proof.read_bytes()).hexdigest()}
            state.update(interruption_verified=True, refusal_verified=True)
            for stem in ('lifecycle', 'interruption', 'cleanup'):
                (root / (stem + '.json')).write_text(stem)
                state[stem + '_sha256'] = hashlib.sha256(stem.encode()).hexdigest()
            (root / 'run.json').write_text(json.dumps(state))
            before = {str(path): path.read_bytes() for path in root.iterdir()}
            result = self.invoke('--verdict', root)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(before, {str(path): path.read_bytes() for path in root.iterdir()})
            for action in ('snapshot', 'unchanged', 'stop'):
                with self.subTest(changed=action):
                    evidence = root / ('debian13-socket-%s.json' % action)
                    evidence.write_text('changed')
                    self.assertEqual(self.invoke('--verdict', root).returncode, 77)
                    evidence.write_text(action)
            state['cases'][-1] = json.loads(json.dumps(state['cases'][0]))
            (root / 'run.json').write_text(json.dumps(state))
            self.assertEqual(self.invoke('--verdict', root).returncode, 77)


class AbsentRefFailureTests(unittest.TestCase):
    def checkout_failure(self, remote):
        """Return the real git output of checking out an absent commit in a clone."""
        git = shutil.which('git')
        if git is None:
            self.skipTest('git is required')
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / 'source'
            env = dict(os.environ, GIT_AUTHOR_NAME='n', GIT_AUTHOR_EMAIL='n@example.org',
                       GIT_COMMITTER_NAME='n', GIT_COMMITTER_EMAIL='n@example.org')
            for command in ([git, 'init', '-q', str(source)],
                            [git, '-C', str(source), 'commit', '-q', '--allow-empty', '-m', 'x']):
                subprocess.run(command, env=env, check=True, capture_output=True)
            clone = Path(tmp) / 'clone'
            subprocess.run([git, 'clone', '-q', ('file://' if remote else '') + str(source), str(clone)],
                           env=env, check=True, capture_output=True)
            result = subprocess.run([git, '-C', str(clone), 'checkout', '0123456789' * 4],
                                    env=env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        return result.stdout + result.stderr

    def test_real_git_absent_commit_failure_is_recognized(self):
        driver = load_driver()
        for remote in (False, True):
            with self.subTest(remote=remote):
                output = self.checkout_failure(remote)
                self.assertIsNotNone(re.search(driver.ABSENT_REF_FAILURE, output), output)

    def test_other_checkout_failures_are_not_recognized(self):
        driver = load_driver()
        for output in ('fatal: unable to access the repository',
                       'fatal: could not read from remote repository',
                       'make: *** [clone] Error 128'):
            with self.subTest(output=output):
                self.assertIsNone(re.search(driver.ABSENT_REF_FAILURE, output))


if __name__ == '__main__':
    unittest.main(verbosity=2)
