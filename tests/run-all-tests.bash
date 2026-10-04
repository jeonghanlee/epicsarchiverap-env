#!/usr/bin/env bash
# Cumulative local checks and the VM driver operations.
set -euo pipefail
TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TOP

function usage {
    printf '%s\n' 'Usage: run-all-tests.bash [--local|--phase=1|--phase=2] or a VM operation'
    printf '%s\n' 'VM operations: --init --config FILE --evidence NEW_DIRECTORY'
    printf '%s\n' '               --case CASE --handoff FILE RUN'
    printf '%s\n' '               --verify-cleanup RUN | --verdict RUN'
}

function main {
    local mode="${1:-all}"
    if [[ $# -gt 0 ]]; then shift; fi
    case "${mode}" in
        --phase=1|--phase1|--phase=2|--phase2|--local)
            if [[ $# -ne 0 ]]; then printf '%s\n' 'INVALID: local modes accept no VM inputs.' >&2; exit 2; fi
            bash "${TOP}/tests/phase1-logic.bash"
            if [[ "${mode}" != --phase=1 && "${mode}" != --phase1 ]]; then
                bash "${TOP}/tests/phase2-compile.bash"
            fi ;;
        --phase=3|--phase3|--phase=4|--phase4|--system|all)
            # Local checks run through --local; these modes report and stop without a verdict.
            if [[ $# -ne 0 ]]; then printf '%s\n' 'INVALID: this mode accepts no VM inputs.' >&2; exit 2; fi
            printf '%s\n' 'Phase 3: Installation; Phase 4: Runtime (one handed-off VM per case)'
            printf '%s\n' 'INCOMPLETE: VM verification runs as explicit operations; no system action ran.' >&2
            usage >&2
            exit 77 ;;
        --init|--case|--verify-cleanup|--verdict)
            exec python3 "${TOP}/tests/vm/driver.py" "${mode}" "$@" ;;
        --help|-h) usage ;;
        *) printf 'INVALID: unknown mode: %s\n' "${mode}" >&2; usage; exit 2 ;;
    esac
}

main "$@"
