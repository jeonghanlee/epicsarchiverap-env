#!/usr/bin/env python3
"""Check inclusive CSV time bounds through the shipped verifier and real IOC."""
import datetime
import json
import os
from pathlib import Path
import subprocess
import sys


def read_ca(pv):
    """Observe the real IOC while keeping CA diagnostics separate from HTTP errors."""
    root = Path(os.environ['RANGE_EVIDENCE'])
    with (root / 'ca-boundary.err').open('a') as diagnostics:
        line = subprocess.check_output(
            [os.environ['RANGE_EPICS'] + '/caget', '-a', '-f0', '-w', '1', pv],
            text=True, stderr=diagnostics)
    fields = line.split()
    instant = datetime.datetime.fromisoformat(fields[1] + 'T' + fields[2]).replace(
        tzinfo=datetime.timezone.utc)
    return {'secs': int(instant.timestamp()), 'val': int(fields[3])}


if Path(sys.argv[0]).name != 'curl':
    import tempfile
    top = Path(__file__).resolve().parent.parent
    source = Path(os.environ.get('AA_TEST_SOURCE_PATH') or top / 'epicsarchiverap-maven-src')
    epics = os.environ['AA_TEST_EPICS_BIN']
    workspace = Path(tempfile.mkdtemp(prefix='local-pv-range.', dir=top / 'work'))
    (workspace / 'curl').symlink_to(Path(__file__).resolve())
    try:
        for mode in ('inside', 'boundary', 'outside', 'time-skew', 'wrong-pv'):
            evidence = workspace / mode
            evidence.mkdir()
            env = dict(os.environ, PATH=str(workspace) + ':' + os.environ['PATH'],
                       RANGE_EVIDENCE=str(evidence), RANGE_EPICS=epics, RANGE_MODE=mode)
            command = ['bash', str(top / 'scripts/verify-local-pv.bash'), '--epics-bin', epics,
                       '--cleanup', 'stop', '--timeout', '20', 'http://127.0.0.1:33665/mgmt/bpl',
                       'http://127.0.0.1:33668/retrieval', str(source)]
            with (evidence / 'log').open('w') as output:
                result = subprocess.run(command, env=env, stdout=output,
                                        stderr=subprocess.STDOUT, timeout=40)
            text = (evidence / 'log').read_text()
            expected = 1 if mode in ('outside', 'time-skew', 'wrong-pv') else 0
            assert result.returncode == expected, (mode, result.returncode, text)
            assert ('PV acquisition, storage and retrieval: PASS' in text) == (expected == 0), mode
            assert 'Test IOC stopped.' in text, mode
            retained = Path(next(line[len('Evidence: '):] for line in text.splitlines()
                                 if line.startswith('Evidence: ')))
            pid = int((retained / 'ioc.pid').read_text())
            assert not Path(f'/proc/{pid}').exists(), mode
            query = json.loads((evidence / 'query.json').read_text())
            response = json.loads((evidence / 'response.json').read_text())
            upper = int(datetime.datetime.fromisoformat(query['to'].replace('Z', '+00:00')).timestamp())
            valid = [sample for sample in response[0]['data']
                     if sample['secs'] < upper or (sample['secs'] == upper and sample['nanos'] == 0)]
            assert len(valid) == (1 if mode == 'outside' else 2), mode
            if mode == 'wrong-pv':
                assert response[0]['meta']['name'] != query['pv'], mode
                assert 'does not identify the requested test PV' in ''.join(
                    item.read_text() for item in retained.glob('extract-*.log')), mode
            assert list(retained.glob('retrieval-*.json')), mode
            print(f'PASS: {mode}; exit={result.returncode}; PV and time checks; IOC stopped', flush=True)
    finally:
        print(f'Time range test evidence: {workspace}', flush=True)
    sys.exit(0)

args = sys.argv[1:]
url = args[-1]
root = Path(os.environ['RANGE_EVIDENCE'])
query = {}
for i, arg in enumerate(args):
    if arg == '--data-urlencode':
        key, value = args[i + 1].split('=', 1)
        query[key] = value
if url.endswith('/archivePV'):
    request = args[args.index('--data-binary') + 1]
    pv = json.loads(Path(request[1:]).read_text())[0]['pv']
    payload = [{'pvName': pv, 'status': 'Archive request submitted'}]
elif url.endswith('/getPVStatus'):
    pv = query['pv']
    observation = read_ca(pv)
    with (root / 'observations.jsonl').open('a') as stream:
        stream.write(json.dumps(observation) + '\n')
    payload = [{'pvName': pv, 'status': 'Being archived'}]
elif url.endswith('/pauseArchivingPV'):
    payload = {'status': 'ok'}
elif url.endswith('/getData.json'):
    observed = [json.loads(line) for line in (root / 'observations.jsonl').read_text().splitlines()]
    first = observed[0]
    last = read_ca(query['pv'])
    end = int(datetime.datetime.fromisoformat(query['to'].replace('Z', '+00:00')).timestamp())
    bad = os.environ['RANGE_MODE'] == 'outside'
    data = [dict(first, nanos=0, severity=0, status=0),
            dict(last, secs=end if os.environ['RANGE_MODE'] in ('boundary', 'outside') else last['secs'],
                 nanos=999999999 if bad else 0, severity=0, status=0)]
    if os.environ['RANGE_MODE'] == 'time-skew':
        data[0]['secs'] += 1
        data[0]['nanos'] = 999999999
    name = query['pv'] + ':Wrong' if os.environ['RANGE_MODE'] == 'wrong-pv' else query['pv']
    payload = [{'meta': {'name': name}, 'data': data}]
    (root / 'query.json').write_text(json.dumps(query))
    (root / 'response.json').write_text(json.dumps(payload))
else:
    sys.exit(7)
encoded = json.dumps(payload)
if '--output' in args:
    Path(args[args.index('--output') + 1]).write_text(encoded)
    print('200', end='')
else:
    print(encoded)
