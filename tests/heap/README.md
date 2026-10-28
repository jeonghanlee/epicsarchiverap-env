# Heap Measurement Input Inspection

## Scope

`inspect-inputs.py` reads the preserved original soak inputs from an explicitly
selected Ansible checkout. It verifies the requested full commit ID, source
cleanliness, recorded file hashes, ordered PV increments, unique PV/store
identities and the accepted 100/500/903 PV stage populations.

It writes a JSON inventory to stdout and does not execute the preserved tools,
modify either checkout, contact an appliance or create a VM. The canonical
[heap measurement plan](../../docs/milestone-2.0.1.md#m41---measure-per-component-heap-needs-by-archiving-load)
owns runtime prerequisites, authorization and T1-T5 acceptance.

## Invocation

Run from this repository's root with Python 3 and Git available. Select the
Ansible checkout and its exact commit before inspection:

```bash
SOAK_REPO=/path/to/ansible-provision
SOAK_REF=full_40_character_commit_id
python3 tests/heap/inspect-inputs.py --ansible-repository "$SOAK_REPO" --source-ref "$SOAK_REF"
```

The selected source must contain the tracked `tests/archiver-soak/SHA256SUMS`
and the original preserved fixture. Only the source directory must be clean;
unrelated checkout changes do not alter this inspection's inputs.

## Results

Exit 0 means input inspection completed and JSON was written. Invalid or
incomplete source inputs return 77 without a success inventory; malformed CLI
arguments return 2. File hashes and stage summaries identify the inspected
inputs. The output always records `execution_ready: false` and
`runtime_verification: "Not run"`, with the remaining unverified inputs.

An inspection success does not establish the original installed policy,
effective per-PV stores, runtime readiness, accepted resource/analysis limits
or any VM test result. The supplied checkout is evidence for preserved source
inputs; it does not substitute for the original installed configuration.
