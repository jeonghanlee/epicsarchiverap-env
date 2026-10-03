#!/usr/bin/env python3
"""Exercise shipped VM entrypoint refusal paths without virtualization or network."""
import json
import hashlib
import importlib.util
import os
from pathlib import Path
import shlex
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import unittest
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

    def test_missing_execution_inputs(self):
        for mode in ('--system', '--installation'):
            with self.subTest(mode=mode):
                result = self.invoke(mode)
                self.assertEqual(result.returncode, 77, result.stderr)
                self.assertIn('no system action ran', result.stderr)

    def test_unknown_and_conflicting_operations(self):
        for arguments in (('--system', '--unknown'), ('--system', '--installation'),
                          ('--system', '--case', 'unknown')):
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
                result = self.invoke('--system', '--config', config, '--evidence', evidence)
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
                for mode in ('--cleanup', '--runtime', '--verdict'):
                    result = self.invoke(mode, root)
                    self.assertEqual(result.returncode, 2, result.stderr)
                    self.assertFalse((root / 'lock').exists())
                    self.assertFalse(list(root.glob('command-*.json')))

    def test_invalid_configuration_creates_no_context(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config, evidence = root / 'input.json', root / 'evidence'
            for value in (None, [], {}, {'cloud': None}):
                config.write_text(json.dumps(value))
                result = self.invoke('--system', '--config', config, '--evidence', evidence)
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
                result = self.invoke('--system', '--config', config, '--evidence', evidence)
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
                for mode in ('--cleanup', '--runtime', '--verdict'):
                    with self.subTest(context=context, mode=mode):
                        result = self.invoke(mode, context)
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


if __name__ == '__main__':
    unittest.main(verbosity=2)
