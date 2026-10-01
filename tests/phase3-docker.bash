#!/usr/bin/env bash
# Phase entrypoint for real VM installation verification.
set -euo pipefail
TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TOP
printf '%s\n' 'Phase 3: Installation (systemd VM)'
if [[ $# -eq 0 ]]; then
    printf '%s\n' 'INCOMPLETE: explicit VM inputs are required; no system action ran.' >&2
    exit 77
fi
exec python3 "${TOP}/tests/vm/driver.py" --installation "$@"
