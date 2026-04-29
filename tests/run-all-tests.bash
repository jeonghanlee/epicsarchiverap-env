#!/usr/bin/env bash
# Master runner for the phased install test SOP.
#
# Phases execute in strict ascending order; each later phase assumes
# all earlier phases have passed.
#
#   Phase 1 — Logic           (no setup, no network)
#   Phase 2 — Compile         (full Maven build with sphinx)
#   Phase 3 — Infrastructure  (Docker container, no systemd)
#   Phase 4 — System          (libvirt VM, full systemd stack)
#
# Usage:
#   tests/run-all-tests.bash                 # all phases
#   tests/run-all-tests.bash --phase=1       # phase 1 only
#   tests/run-all-tests.bash --phase=2       # phases 1 and 2
#   tests/run-all-tests.bash --local         # phases 1 and 2
#   tests/run-all-tests.bash --system        # phases 3 and 4

set -euo pipefail

readonly TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    sed -n '3,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

run_phase() {
    local n="$1"
    local script="${TOP}/tests/phase${n}-"*.bash
    # Glob expands to the unique phase script for this number.
    bash ${script}
}

main() {
    local mode="${1:-all}"
    case "${mode}" in
        --phase=1|--phase1) run_phase 1 ;;
        --phase=2|--phase2) run_phase 1; run_phase 2 ;;
        --phase=3|--phase3) run_phase 1; run_phase 2; run_phase 3 ;;
        --phase=4|--phase4) run_phase 1; run_phase 2; run_phase 3; run_phase 4 ;;
        --local)            run_phase 1; run_phase 2 ;;
        --system)           run_phase 3; run_phase 4 ;;
        --help|-h)          usage; exit 0 ;;
        all)                for n in 1 2 3 4; do run_phase "${n}"; done ;;
        *)                  printf 'unknown mode: %s\n' "${mode}" >&2; usage; exit 2 ;;
    esac
}

main "$@"
