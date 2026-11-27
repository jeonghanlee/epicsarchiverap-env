#!/usr/bin/env bash
# Registers the three array PVs at the preparation configuration, waits for their stored files, then pauses them.
#
# Usage: prepare-frames.bash [--output DIR]
#   The feeder (feed-frames.py serve) must already publish the three PVs. The engine runs with the preparation heap and
#   the Channel Access limit, the retrieval JVM with the preparation heap, so that the stored frames can be read back.
#   The log line first_event=UTC names the second of the first stored event, the input of run-retrieval-cells.bash.
#   The saved configuration files are put back and the service restarted when the script ends.
#   Exit status: 0 frames stored and PVs paused, 1 no stored files within the bound, 2 usage, 3 stop rule.

set -u
# shellcheck source=array-common.bash
source "$(dirname "${BASH_SOURCE[0]}")/array-common.bash"

readonly STORE_BOUND_S=300
readonly EXTRA_FRAMES_S=100
readonly POLL_S=10
readonly READ_BOUND_S=250
readonly PVS="LASER AIRY BOUND"

OUTPUT="${ARRAY_HOME}/logs/prepare"

function usage {
    printf 'Usage: %s [--output DIR]\n' "$(basename "$0")"
}

function parse_args {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output) OUTPUT=${2:?--output needs a value}; shift ;;
            -h|--help) usage; exit 0 ;;
            *) usage >&2; exit "${EXIT_USAGE}" ;;
        esac
        shift
    done
}

function all_stored {
    local pv
    for pv in ${PVS}; do
        if [[ -z "$(stored_size "${pv}")" ]]; then
            return 1
        fi
    done
    return 0
}

# Reads the stored events of the first PV from the registration time on and logs the UTC second of the first one.
function log_first_event {
    local from=$1
    local file="${OUTPUT}/first-event.json"
    local to
    local secs
    to=$(date -u -d '+1 minute' +%Y-%m-%dT%H:%M:%S.000Z)
    curl -s --max-time "${READ_BOUND_S}" -o "${file}" --get --data-urlencode "pv=${PV_PREFIX}LASER" \
        --data-urlencode "from=${from}" --data-urlencode "to=${to}" "${RETRIEVAL_URL}"
    secs=$(perl "${TOOLS_DIR}/hash-events.pl" "${file}" | head -1 | sed -E 's/^secs=([0-9]+) .*/\1/')
    if [[ "${secs}" =~ ^[0-9]+$ ]]; then
        log "first_event=$(date -u -d "@${secs}" +%Y-%m-%dT%H:%M:%SZ)"
    else
        log "first_event=unknown"
    fi
}

function main {
    local registered
    local started
    local elapsed
    local pv
    local stored=0
    parse_args "$@"
    mkdir -p "${OUTPUT}"
    LOG_FILE="${OUTPUT}/run.log"
    trap restore_configs EXIT
    save_originals
    write_component_conf engine "${PREP_HEAP_MIB}" "${ENGINE_CA_BYTES}"
    write_component_conf retrieval "${PREP_HEAP_MIB}"
    restart_service "preparation heap=${PREP_HEAP_MIB}"
    guard
    registered=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    log "registered at ${registered}"
    for pv in ${PVS}; do
        curl -s --get --data-urlencode "pv=${PV_PREFIX}${pv}" --data 'samplingperiod=30' --data 'samplingmethod=MONITOR' "${MGMT_URL}/archivePV" > /dev/null
    done
    started=$(date +%s)
    while true; do
        elapsed=$(( $(date +%s) - started ))
        if all_stored; then
            stored=1
            break
        fi
        if (( elapsed >= STORE_BOUND_S )); then
            break
        fi
        sleep "${POLL_S}"
    done
    log "stored_check=${stored} after ${elapsed} s"
    sleep "${EXTRA_FRAMES_S}"
    for pv in ${PVS}; do
        curl -s --get --data-urlencode "pv=${PV_PREFIX}${pv}" "${MGMT_URL}/pauseArchivingPV" > /dev/null
    done
    log "paused"
    log_first_event "${registered}"
    if (( stored == 0 )); then
        return 1
    fi
    return 0
}

main "$@"
exit $?
