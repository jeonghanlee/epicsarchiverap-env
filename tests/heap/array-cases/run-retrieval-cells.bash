#!/usr/bin/env bash
# Runs the raw retrieval cells: a reference group at the preparation heap, then one-client and four-client cells for each retrieval heap.
#
# Usage: run-retrieval-cells.bash --first-event UTC [--heaps "256 384 512"] [--clients "1 4"] [--groups N] [--output DIR]
#   --first-event is the UTC second of the first stored event of the frames (for example 2026-11-26T23:32:26Z); the
#   windows of the plan are one event (that second) and three events (that second plus 60 s) of the three array PVs.
#   Every cell restarts the whole service with the heap of its retrieval JVM; the engine runs at the preparation heap.
#   The saved configuration files are put back and the service restarted when the script ends.
#   The reference group must hold only answers with status 200 of at least 1,000,000 bytes (a window without the frames
#   answers with a few bytes and would make every later answer look delivered); otherwise the run ends with status 5.
#   Exit status: 0 complete, 1 the classification failed, 2 usage, 3 stop rule, 5 the reference group is not usable.

set -u
# shellcheck source=array-common.bash
source "$(dirname "${BASH_SOURCE[0]}")/array-common.bash"

readonly REQUEST_TOOL="${REQUEST_TOOL:-${TOOLS_DIR}/../request-array.pl}"
readonly CLASSIFY_TOOL="${CLASSIFY_TOOL:-${TOOLS_DIR}/classify-cells.pl}"
readonly REFERENCE_MIN_BYTES=1000000
readonly PAUSE_S=5

FIRST_EVENT=""
HEAPS="256 384 512"
CLIENT_COUNTS="1 4"
GROUPS_PER_CELL=3
OUTPUT="${ARRAY_HOME}/logs/retrieval-cells"
RESTART_TS=""

function usage {
    printf 'Usage: %s --first-event UTC [--heaps "256 384 512"] [--clients "1 4"] [--groups N] [--output DIR]\n' "$(basename "$0")"
}

function parse_args {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --first-event) FIRST_EVENT=${2:?--first-event needs a value}; shift ;;
            --heaps) HEAPS=${2:?--heaps needs a value}; shift ;;
            --clients) CLIENT_COUNTS=${2:?--clients needs a value}; shift ;;
            --groups) GROUPS_PER_CELL=${2:?--groups needs a value}; shift ;;
            --output) OUTPUT=${2:?--output needs a value}; shift ;;
            -h|--help) usage; exit 0 ;;
            *) usage >&2; exit "${EXIT_USAGE}" ;;
        esac
        shift
    done
    if [[ -z "${FIRST_EVENT}" ]] || ! date -u -d "${FIRST_EVENT}" > /dev/null 2>&1; then
        usage >&2
        exit "${EXIT_USAGE}"
    fi
    if [[ ! "${GROUPS_PER_CELL}" =~ ^[1-9][0-9]*$ ]]; then
        usage >&2
        exit "${EXIT_USAGE}"
    fi
}

# Writes the request plan of the four windows from the time of the first stored event.
function write_plan {
    local from
    local to_one
    local to_three
    from=$(date -u -d "${FIRST_EVENT}" +%Y-%m-%dT%H:%M:%S.000Z)
    to_one=$(date -u -d "${FIRST_EVENT}" +%Y-%m-%dT%H:%M:%S.999Z)
    to_three=$(date -u -d "${FIRST_EVENT} + 60 seconds" +%Y-%m-%dT%H:%M:%S.999Z)
    {
        printf '%s\n' 'name,pv,from,to'
        printf '%s\n' "laser1,${PV_PREFIX}LASER,${from},${to_one}"
        printf '%s\n' "airy1,${PV_PREFIX}AIRY,${from},${to_one}"
        printf '%s\n' "airy3,${PV_PREFIX}AIRY,${from},${to_three}"
        printf '%s\n' "bound1,${PV_PREFIX}BOUND,${from},${to_one}"
    } > "${OUTPUT}/plan.csv"
}

# Restarts the service with the retrieval heap of one cell; the time is local, like the journal.
function restart_for_cell {
    local heap=$1
    guard
    write_component_conf retrieval "${heap}"
    RESTART_TS=$(date '+%Y-%m-%d %H:%M:%S')
    restart_service "retrieval_heap=${heap} engine_heap=${PREP_HEAP_MIB}"
}

function run_cell {
    local heap=$1
    local clients=$2
    local directory="${OUTPUT}/r${heap}-c${clients}"
    local lines
    guard
    log "cell start heap=${heap} clients=${clients}"
    perl "${REQUEST_TOOL}" --plan "${OUTPUT}/plan.csv" --output-dir "${directory}" --url "${RETRIEVAL_URL}" \
        --clients "${clients}" --groups "${GROUPS_PER_CELL}" --pause "${PAUSE_S}" > "${directory}.out" 2>&1
    log "cell end heap=${heap} clients=${clients} exit=$?"
    lines=$(sudo -n journalctl -u "${SERVICE_UNIT}" --no-pager --since "${RESTART_TS}" 2>/dev/null | grep -c 'OutOfMemoryError')
    log "oom_lines_since_restart=${lines}"
    jvm_state | grep -E '^(engine|retrieval)' | tee -a "${LOG_FILE}"
}

function main {
    local heap
    local clients
    local check
    parse_args "$@"
    mkdir -p "${OUTPUT}"
    LOG_FILE="${OUTPUT}/run.log"
    trap restore_configs EXIT
    save_originals
    write_plan
    write_component_conf engine "${PREP_HEAP_MIB}" "${ENGINE_CA_BYTES}"
    restart_for_cell "${PREP_HEAP_MIB}"
    log "reference group"
    perl "${REQUEST_TOOL}" --plan "${OUTPUT}/plan.csv" --output-dir "${OUTPUT}/reference-${PREP_HEAP_MIB}" --url "${RETRIEVAL_URL}" \
        --clients 1 --groups 1 > "${OUTPUT}/reference-${PREP_HEAP_MIB}.out" 2>&1
    log "reference end exit=$?"
    if ! check=$(perl "${CLASSIFY_TOOL}" --check-reference "${REFERENCE_MIN_BYTES}" "${OUTPUT}" 2>&1); then
        log "the reference group is not usable: ${check}"
        return "${EXIT_REFERENCE}"
    fi
    log "${check}"
    for clients in ${CLIENT_COUNTS}; do
        for heap in ${HEAPS}; do
            restart_for_cell "${heap}"
            run_cell "${heap}" "${clients}"
        done
    done
    if ! check=$(perl "${CLASSIFY_TOOL}" "${OUTPUT}" 2>&1); then
        log "the classification failed: ${check}"
        return 1
    fi
    log "classification of the cells"
    printf '%s\n' "${check}" | tee -a "${LOG_FILE}"
    log "DONE retrieval cells"
    return 0
}

main "$@"
exit $?
