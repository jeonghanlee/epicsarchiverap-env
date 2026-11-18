# Heap Measurement Input Inspection

## Scope

`inspect-inputs.pl` reads the preserved original soak inputs from an explicitly
selected Ansible checkout. It verifies the requested full commit ID, source
cleanliness, recorded file hashes, ordered PV increments, unique PV/store
identities and the accepted 100/500/903 PV stage populations. Git output is
read as bytes, so a file name that is not valid UTF-8 cannot abort the
inspection. CSV files are read as strict UTF-8; a double quote in a CSV file is
refused.

It writes a JSON inventory to stdout and does not execute the preserved tools,
modify either checkout, contact an appliance or create a VM. The canonical
[heap measurement plan](../../docs/milestone-9576820.md#m7---measure-per-component-heap-needs-by-archiving-load)
owns runtime prerequisites, authorization and T1-T5 acceptance.

## Invocation

Run from this repository's root with Perl 5.26 or newer (`Digest::SHA` and
`JSON::PP` installed) and Git available. Select the Ansible checkout and pass the
commit ID that is currently checked out in it (its HEAD) as the source ref; any
other commit returns 77 because the tool never changes the checkout:

```bash
SOAK_REPO=/path/to/ansible-provision
SOAK_REF=full_40_character_commit_id
perl tests/heap/inspect-inputs.pl --ansible-repository "$SOAK_REPO" --source-ref "$SOAK_REF"
```

The selected source must contain the tracked `tests/archiver-soak/SHA256SUMS`
and the original preserved fixture. Only the source directory must be clean;
unrelated checkout changes do not alter this inspection's inputs.

## Results

Exit 0 means input inspection completed and JSON was written. Invalid or
incomplete source inputs, including a source ref that is not the checkout's
HEAD, return 77 without a success inventory; malformed CLI
arguments return 2. File hashes and stage summaries identify the inspected
inputs. The output always records `execution_ready: false` and
`runtime_verification: "Not run"`, with the remaining unverified inputs.

An inspection success does not establish the original installed policy,
effective per-PV stores, runtime readiness, accepted resource/analysis limits
or any VM test result. The supplied checkout is evidence for preserved source
inputs; it does not substitute for the original installed configuration.

## Test

`tests/heap-inspect-inputs.pl` runs the inspector as a subprocess against
temporary Git repositories. It checks the exit statuses and diagnostics for a
missing option, a malformed and a mismatched source ref, and a dirty source
directory with ASCII and non-UTF-8 file names. With
`AA_HEAP_SOAK_REPO` and `AA_HEAP_SOAK_REF` set to a real preserved soak
checkout, it exports the tracked source directory, requires the unchanged copy
to pass, and applies five single changes to real input (altered fixture,
missing required file, untracked checksum list, duplicate checksum entry,
combined fixture that differs with consistent checksums), each of which must
end with status 77 and its own diagnostic.

```bash
perl tests/heap-inspect-inputs.pl
```
