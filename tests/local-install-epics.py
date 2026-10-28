#!/usr/bin/env python3
"""Exercise shipped EPICS preflight and installer entrypoints without installing."""
import os
from pathlib import Path
import pty
import subprocess

TOP = Path(__file__).resolve().parent.parent
ENV = os.environ.copy()
ENV.pop('EPICS_BASE', None)
ENV.pop('EPICS_HOST_ARCH', None)


def check(env, *options):
    return subprocess.run(
        ['bash', str(TOP / 'scripts/verify-local-pv.bash'), '--check-epics', *options],
        env=env, capture_output=True, text=True, timeout=15,
    )


result = check(ENV)
assert result.returncode == 1 and 'Source your EPICS environment setup file' in result.stderr
for base in ('~/EPICS-env-distribution', '/nonexistent-epics-base'):
    result = check(dict(ENV, EPICS_BASE=base))
    assert result.returncode == 1 and 'existing absolute Base directory' in result.stderr

for backend in ('sqlite', 'mariadb-uds', 'mariadb-tcp'):
    master, slave = pty.openpty()
    try:
        process = subprocess.Popen(
            ['bash', str(TOP / f'scripts/install-local-{backend}.bash')],
            cwd=TOP, env=ENV, stdin=slave, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, text=True,
        )
        os.write(master, b'y\n')
        output, _ = process.communicate(timeout=20)
    finally:
        os.close(master)
        os.close(slave)
    assert process.returncode == 1, output
    assert 'No installation changes have been made' in output, output
    assert 'Source your EPICS environment setup file' in output, output
    assert 'Install packages, build' not in output, output
    assert '+ sudo' not in output and '+ make' not in output, output

epics_bin = os.environ.get('AA_TEST_EPICS_BIN')
if epics_bin:
    base = str(Path(epics_bin).parent.parent)
    for env, options in (
        (dict(ENV, EPICS_BASE=base), ()),
        (dict(ENV, EPICS_BASE=base, EPICS_HOST_ARCH=Path(epics_bin).name), ()),
        (ENV, ('--epics-bin', epics_bin)),
    ):
        result = check(env, *options)
        assert result.returncode == 0 and result.stdout.strip() == epics_bin, result
    result = check(dict(ENV, EPICS_BASE=base, EPICS_HOST_ARCH='missing-architecture'))
    assert result.returncode == 1 and 'executable softIoc and caget' in result.stderr, result
    print('PASS: EPICS preflight resolves the supplied real Base binaries.')
else:
    print('SKIP: real Base binary resolution; AA_TEST_EPICS_BIN is unset.')
print('PASS: all three installers require EPICS preparation before installation when PV verification is selected.')
