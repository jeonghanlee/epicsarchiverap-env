#!/usr/bin/env bash
# Cumulative local checks and sequential installation/runtime VM verification.
set -euo pipefail
TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TOP

function usage {
    printf '%s\n' 'Usage: run-all-tests.bash [--local|--system|--phase=N|all] [VM options]'
    printf '%s\n' 'VM options: --config FILE --evidence NEW_DIRECTORY [--case OS-BACKEND]'
    printf '%s\n' 'Context operations: --cleanup CONTEXT or --verdict CONTEXT'
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
        --phase=3|--phase3)
            bash "${TOP}/tests/phase3-docker.bash" "$@" ;;
        --phase=4|--phase4|all)
            exec python3 "${TOP}/tests/vm/driver.py" --system "$@" ;;
        --system)
            printf '%s\n' 'Phase 3: Installation; Phase 4: Runtime (sequential systemd VM matrix)'
            exec python3 "${TOP}/tests/vm/driver.py" --system "$@" ;;
        --cleanup|--verdict)
            exec python3 "${TOP}/tests/vm/driver.py" "${mode}" "$@" ;;
        --cleanup=*|--verdict=*)
            exec python3 "${TOP}/tests/vm/driver.py" "${mode}" "$@" ;;
        --help|-h) usage ;;
        *) printf 'INVALID: unknown mode: %s\n' "${mode}" >&2; usage; exit 2 ;;
    esac
}

main "$@"
