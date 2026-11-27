#!/usr/bin/env bash
# Runs the engine subscription cells: for each engine heap, fresh subscription attempts of each array PV set with a time bound.
#
# Usage: run-engine-cells.bash [--heaps "256 512"] [--attempts N] [--bound-seconds S] [--cells "airy bound airy+bound"]
#                              [--output DIR] [--delete-existing]
#   Each attempt registers the PV set, polls the status until every PV is archived and has a stored file or the bound is
#   reached, waits for further frames, reads the stored frames back through the retrieval service (retrieval at the
#   preparation heap), compares the element count and the SHA-256 of every stored event with the pins, and then pauses and
#   deletes the PVs with their data through the management interface. An attempt is Failed when the engine JVM ended, the
#   kernel killed a process or the engine logged an OutOfMemoryError. The saved configuration files are put back and the
#   service restarted when the script ends.
#   The array PVs must not exist when the run starts (a PV left by prepare-frames.bash would be paused and never reach
#   the archived state); the run refuses to start while one exists, or deletes them with their data under --delete-existing.
#   Exit status: 0 complete, 2 usage, 3 stop rule, 4 an array PV or its data exists and --delete-existing is not given.

set -u
# shellcheck source=array-common.bash
source "$(dirname "${BASH_SOURCE[0]}")/array-common.bash"

readonly HASH_TOOL="${HASH_TOOL:-${TOOLS_DIR}/hash-events.pl}"
readonly POLL_S=10
readonly EXTRA_FRAMES_S=40
readonly READ_BOUND_S=250

declare -A PIN_ELEMENTS=( [AIRY]=4915200 [BOUND]=5529600 )
declare -A PIN_SHA256=(
    [AIRY]=7a06547103de3ca762ac66bfcf8a7ebeb7bb43bfa63d626522c472a6d90361e6
    [BOUND]=b3d85b7834d78afefb875e8a6ef636aa7799ec07035674c4fbc9b58265aa0199
)

HEAPS="256 512"
CELLS="airy bound airy+bound"
ATTEMPTS=3
BOUND_S=300
OUTPUT="${ARRAY_HOME}/logs/engine-cells"
DELETE_EXISTING=0

function usage {
    printf 'Usage: %s [--heaps "256 512"] [--attempts N] [--bound-seconds S] [--cells "airy bound airy+bound"] [--output DIR] [--delete-existing]\n' "$(basename "$0")"
}

function parse_args {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --heaps) HEAPS=${2:?--heaps needs a value}; shift ;;
            --attempts) ATTEMPTS=${2:?--attempts needs a value}; shift ;;
            --bound-seconds) BOUND_S=${2:?--bound-seconds needs a value}; shift ;;
            --cells) CELLS=${2:?--cells needs a value}; shift ;;
            --output) OUTPUT=${2:?--output needs a value}; shift ;;
            --delete-existing) DELETE_EXISTING=1 ;;
            -h|--help) usage; exit 0 ;;
            *) usage >&2; exit "${EXIT_USAGE}" ;;
        esac
        shift
    done
    if [[ ! "${ATTEMPTS}" =~ ^[1-9][0-9]*$ || ! "${BOUND_S}" =~ ^[1-9][0-9]*$ ]]; then
        usage >&2
        exit "${EXIT_USAGE}"
    fi
}

# Prints the PV names of a cell, upper case, one per word.
function cell_pvs {
    local cell=$1
    printf '%s\n' "${cell^^}" | tr '+' ' '
}

# Reads the stored frames of one PV from the registration time on and prints "events=N pinned=M".
function read_back {
    local pv=$1
    local from=$2
    local file="${OUTPUT}/readback.json"
    local to
    local code
    local events
    local pinned
    to=$(date -u -d '+1 minute' +%Y-%m-%dT%H:%M:%S.000Z)
    code=$(curl -s --max-time "${READ_BOUND_S}" -o "${file}" -w '%{http_code}' --get --data-urlencode "pv=${PV_PREFIX}${pv}" \
        --data-urlencode "from=${from}" --data-urlencode "to=${to}" "${RETRIEVAL_URL}")
    events=$(perl "${HASH_TOOL}" "${file}" 2> /dev/null | grep -c 'secs=')
    pinned=$(perl "${HASH_TOOL}" "${file}" 2> /dev/null | grep -c "elements=${PIN_ELEMENTS[${pv}]} sha256=${PIN_SHA256[${pv}]}")
    printf '%s:events=%s:pinned=%s:http=%s' "${pv}" "${events}" "${pinned}" "${code}"
}

function attempt {
    local heap=$1
    local cell=$2
    local number=$3
    local pvs
    local pv
    local started
    local elapsed
    local registered
    local registered_local
    local ended_local
    local archived=-1
    local stored_at=-1
    local failed=0
    local all
    local stored
    local state
    local statuses=""
    local pid_before
    local pid_after
    local kills_before
    local kills_after
    local oom
    local reads=""
    local matched=0
    local piece
    local outcome
    pvs=$(cell_pvs "${cell}")
    guard
    pid_before=$(component_pid engine)
    kills_before=$(kernel_kills)
    registered=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
    registered_local=$(date '+%Y-%m-%d %H:%M:%S')
    started=$(date +%s)
    for pv in ${pvs}; do
        curl -s --max-time 30 --get --data-urlencode "pv=${PV_PREFIX}${pv}" --data 'samplingperiod=30' --data 'samplingmethod=MONITOR' "${MGMT_URL}/archivePV" > /dev/null
    done
    while true; do
        elapsed=$(( $(date +%s) - started ))
        all=1
        stored=1
        for pv in ${pvs}; do
            state=$(status_of "${pv}")
            if [[ "${state}" != Being_archived/true ]]; then
                all=0
            fi
            if [[ -z "$(stored_size "${pv}")" ]]; then
                stored=0
            fi
        done
        if (( all == 1 && archived < 0 )); then
            archived=${elapsed}
        fi
        if (( stored == 1 && stored_at < 0 )); then
            stored_at=${elapsed}
        fi
        if (( all == 1 && stored == 1 )) || (( elapsed >= BOUND_S )); then
            break
        fi
        sleep "${POLL_S}"
    done
    sleep "${EXTRA_FRAMES_S}"
    ended_local=$(date '+%Y-%m-%d %H:%M:%S')
    pid_after=$(component_pid engine)
    kills_after=$(kernel_kills)
    for pv in ${pvs}; do
        piece=$(read_back "${pv}" "${registered}")
        reads="${reads}${piece};"
        if [[ "${piece}" != *":pinned=0:"* ]]; then
            matched=$(( matched + 1 ))
        fi
        statuses="${statuses}${pv}=$(status_of "${pv}");"
    done
    oom=$(sudo -n journalctl -u "${SERVICE_UNIT}" --no-pager --since "${registered_local}" --until "${ended_local}" 2> /dev/null |
        grep 'archappl-engine' | grep -c 'OutOfMemoryError')
    if [[ "${pid_before}" != "${pid_after}" ]] || (( oom > 0 || kills_after > kills_before )); then
        failed=1
    fi
    outcome=$(decide_outcome "${failed}" "${all}" "${matched}" "$(wc -w <<< "${pvs}")")
    printf '%s\n' "${heap},${cell},${number},${registered},${archived},${stored_at},${statuses},${reads},${pid_before}/${pid_after},${kills_before}/${kills_after},${oom},${outcome}" >> "${OUTPUT}/results.csv"
    log "attempt heap=${heap} cell=${cell} att=${number} archived_s=${archived} stored_s=${stored_at} status=${statuses} read=${reads} pid=${pid_before}/${pid_after} kills=${kills_before}/${kills_after} oom=${oom} outcome=${outcome}"
    for pv in ${pvs}; do
        curl -s --max-time 30 --get --data-urlencode "pv=${PV_PREFIX}${pv}" "${MGMT_URL}/pauseArchivingPV" > /dev/null
        curl -s --max-time 120 --get --data-urlencode "pv=${PV_PREFIX}${pv}" --data 'deleteData=true' "${MGMT_URL}/deletePV" > /dev/null
    done
    sleep 5
    log "after delete stored_files=$(sudo -n find "${STORE_ROOT}" -path "${PV_STORE_GLOB}" -type f | wc -l)"
}

function main {
    local heap
    local cell
    local number
    parse_args "$@"
    mkdir -p "${OUTPUT}"
    LOG_FILE="${OUTPUT}/run.log"
    trap restore_configs EXIT
    save_originals
    if array_pvs_present; then
        if (( DELETE_EXISTING == 0 )); then
            log "an array PV or its stored data exists; delete it first or give --delete-existing"
            exit "${EXIT_PRECONDITION}"
        fi
        delete_array_pvs
        log "existing array PVs deleted with their data; present=$(array_pvs_present && printf yes || printf no)"
    fi
    printf '%s\n' 'heap,cell,attempt,registered_utc,archived_s,stored_s,status,read_back,engine_pid,kernel_kills,oom_lines,outcome' > "${OUTPUT}/results.csv"
    write_component_conf retrieval "${PREP_HEAP_MIB}"
    for heap in ${HEAPS}; do
        guard
        write_component_conf engine "${heap}" "${ENGINE_CA_BYTES}"
        restart_service "engine_heap=${heap} retrieval_heap=${PREP_HEAP_MIB}"
        for cell in ${CELLS}; do
            for (( number = 1; number <= ATTEMPTS; number++ )); do
                attempt "${heap}" "${cell}" "${number}"
            done
        done
    done
    log "DONE engine cells"
    return 0
}

main "$@"
exit $?
