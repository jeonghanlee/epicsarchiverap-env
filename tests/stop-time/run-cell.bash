#!/usr/bin/env bash
# Run the stops of one cell of the stop time measurement in order on the guest
# (tests/stop-time/README.md).
#
# Purpose: a cell is a set of stops under one condition (PV count, partition,
# hold). run-stop.bash measures one stop and leaves the appliance stopped; this
# script starts the appliance before each further stop, runs run-stop.bash for
# each stop number, and stops the cell when a stop is refused or leaves a
# repeat due, so that the key pending of the status file is not overwritten by
# a later stop.
#
# Usage:
#   run-cell.bash --stops <n> [--first <k>] <options of run-stop.bash without --stop>
#
# --stops     the number of stops to run (for example 3)
# --first     the number of the first stop (default 1); the stops are k to k + n - 1
# The other options go unchanged to run-stop.bash: --run, --cell, --stage,
# --partition, --hold, --evidence, --pv-list (repeatable), --expectation,
# --prediction and --unit. The appliance must be active before the first stop.
#
# Files: <evidence>/<run-id>/console/<cell>-<stop>.log holds the output of each
# run-stop.bash, <cell>-<stop>.sd_start.log the output of each make sd_start,
# and <cell>.rcs one line per stop with its exit status and the key pending.
#
# Exit status: 0 every stop ran (each stop keeps its own verdict in its log and
# in stops.jsonl), 2 the cell stopped at a stop that left a repeat due, 3 usage,
# a refusal of run-stop.bash, or a failed make sd_start.

set -euo pipefail

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TOP
readonly CHECKOUT="${STOP_TIME_CHECKOUT:-$(cd "${TOP}/../.." && pwd)}"

function usage {
    sed -n '12,19p' "${BASH_SOURCE[0]}" >&2
    exit 3
}

function main {
    local stops="" first=1 run="" cell="" evidence="" n stop rc pending log_dir status
    local -a pass=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --stops) stops="${2:-}"; shift 2 ;;
            --first) first="${2:-}"; shift 2 ;;
            --stop) usage ;;
            --run) run="${2:-}"; pass+=("$1" "${2:-}"); shift 2 ;;
            --cell) cell="${2:-}"; pass+=("$1" "${2:-}"); shift 2 ;;
            --evidence) evidence="${2:-}"; pass+=("$1" "${2:-}"); shift 2 ;;
            --stage | --partition | --hold | --pv-list | --expectation | --prediction | --unit)
                pass+=("$1" "${2:-}"); shift 2 ;;
            *) usage ;;
        esac
    done
    [[ "${stops}" =~ ^[1-9][0-9]*$ && "${first}" =~ ^[1-9][0-9]*$ ]] || usage
    [[ -n "${run}" && -n "${cell}" && -n "${evidence}" ]] || usage
    log_dir="${evidence}/${run}/console"
    status="${evidence}/${run}/status"
    mkdir -p "${log_dir}"
    for ((n = 0; n < stops; n++)); do
        stop=$((first + n))
        if [[ ${n} -gt 0 ]]; then
            if ! make -s --no-print-directory -C "${CHECKOUT}" sd_start > "${log_dir}/${cell}-${stop}.sd_start.log" 2>&1; then
                printf 'stop %s: make sd_start failed\n' "${stop}" >> "${log_dir}/${cell}.rcs"
                exit 3
            fi
        fi
        rc=0
        "${TOP}/run-stop.bash" "${pass[@]}" --stop "${stop}" > "${log_dir}/${cell}-${stop}.log" 2>&1 || rc=$?
        pending="$(sed -n 's/^pending=//p' "${status}" 2> /dev/null || true)"
        printf 'stop %s rc=%s pending=%s\n' "${stop}" "${rc}" "${pending}" >> "${log_dir}/${cell}.rcs"
        printf 'run-cell: %s stop %s exit %s%s\n' "${cell}" "${stop}" "${rc}" "${pending:+, pending ${pending}}"
        [[ ${rc} -ne 3 ]] || exit 3
        [[ -z "${pending}" ]] || exit 2
    done
}

main "$@"
