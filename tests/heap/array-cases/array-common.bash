#!/usr/bin/env bash
# Shared configuration and helpers of the array case drivers: appliance access, stop rules, heap overrides with restore, and JVM state records.
# shellcheck shell=bash
# shellcheck disable=SC2034  # the constants are used by the drivers that source this file
#
# Sourced by prepare-frames.bash, run-retrieval-cells.bash and run-engine-cells.bash on the guest that runs the appliance.
# The values below are read from the environment first so that another installation can run the same drivers.

readonly ARRAY_HOME="${ARRAY_HOME:-${HOME}/array}"
readonly APPLIANCE_DIR="${APPLIANCE_DIR:-/opt/epicsarchiverap-maven}"
readonly SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-mid-srv}"
readonly SERVICE_UNIT="${SERVICE_UNIT:-epicsarchiverap-maven.service}"
readonly MGMT_URL="${MGMT_URL:-http://localhost:17665/mgmt/bpl}"
readonly RETRIEVAL_URL="${RETRIEVAL_URL:-http://localhost:17668/retrieval/data/getData.json}"
readonly STORE_ROOT="${STORE_ROOT:-/arch/sts}"
readonly PV_PREFIX="${PV_PREFIX:-AASOAK:ARR:}"
readonly PV_STORE_GLOB="${PV_STORE_GLOB:-*AASOAK/ARR*}"
readonly PREP_HEAP_MIB="${PREP_HEAP_MIB:-512}"
readonly ENGINE_CA_BYTES="${ENGINE_CA_BYTES:-24000000}"
readonly RESTART_WAIT_S="${RESTART_WAIT_S:-60}"
readonly STOP_MEM_MIB=200
readonly STOP_ROOT_PCT=80
readonly STOP_INODE_PCT=90
readonly EXIT_USAGE=2
readonly EXIT_STOP=3
readonly EXIT_PRECONDITION=4
readonly EXIT_REFERENCE=5
readonly SAVED_DIR="${ARRAY_HOME}/saved"
readonly COMPONENTS="mgmt engine etl retrieval"
TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TOOLS_DIR

# LOG_FILE is set by the driver before the first call of log.
CONFIGS_CHANGED=0

# Prints one line with the UTC time to the terminal and appends it to LOG_FILE.
function log {
    printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" | tee -a "${LOG_FILE}"
}

# Ends the run with the stop status when the guest reaches one of the declared stop rules.
function guard {
    local mem
    local used
    local inodes
    mem=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
    used=$(df --output=pcent / | tail -1 | tr -dc '0-9')
    inodes=$(df --output=ipcent / | tail -1 | tr -dc '0-9')
    if (( mem < STOP_MEM_MIB || used >= STOP_ROOT_PCT || inodes >= STOP_INODE_PCT )); then
        log "STOP rule reached mem_available_mib=${mem} root_used_pct=${used} inode_used_pct=${inodes}"
        exit "${EXIT_STOP}"
    fi
    return 0
}

# Prints the pid of the JVM of one component; the bracket keeps the pattern from matching this command.
function component_pid {
    ps -eo pid,args | grep "[c]atalina.base=${APPLIANCE_DIR}/${1} " | awk '{print $1; exit}'
}

# Prints the number of kernel out-of-memory kills in the journal of this boot.
function kernel_kills {
    sudo -n journalctl -k --no-pager 2>/dev/null | grep -c 'Out of memory: Killed process'
}

# Prints "<status>/<connection state>" of one array PV, with underscores for spaces, or none/none.
function status_of {
    curl -s --max-time 20 --get --data-urlencode "pv=${PV_PREFIX}$1" "${MGMT_URL}/getPVStatus" |
        perl -MJSON::PP -e 'local $/; my $d = eval { decode_json(<STDIN>) }; if (ref $d eq "ARRAY" && ref $d->[0] eq "HASH") { (my $s = $d->[0]{status} // "?") =~ s/ /_/g; print $s, "/", $d->[0]{connectionState} // "None", "\n" } else { print "none/none\n" }'
}

# Prints the size of the first stored file of one array PV in the short-term store, nothing when there is none.
function stored_size {
    sudo -n find "${STORE_ROOT}" -path "${PV_STORE_GLOB}" -name "$1:*" -type f -printf '%s\n' 2>/dev/null | head -1
}

# Succeeds when any array PV is registered in any state or has a stored file, the state a fresh engine attempt must not start from.
function array_pvs_present {
    local pv
    for pv in LASER AIRY BOUND; do
        if [[ "$(status_of "${pv}")" != Not_being_archived/None ]] || [[ -n "$(stored_size "${pv}")" ]]; then
            return 0
        fi
    done
    return 1
}

# Pauses the array PVs and deletes them with their stored data through the management interface.
function delete_array_pvs {
    local pv
    for pv in LASER AIRY BOUND; do
        curl -s --max-time 30 --get --data-urlencode "pv=${PV_PREFIX}${pv}" "${MGMT_URL}/pauseArchivingPV" > /dev/null
        curl -s --max-time 120 --get --data-urlencode "pv=${PV_PREFIX}${pv}" --data 'deleteData=true' "${MGMT_URL}/deletePV" > /dev/null
    done
    sleep 5
}

# Prints the outcome of one engine attempt: failed is 1 when the JVM ended, the kernel killed a process or the engine
# logged an OutOfMemoryError; all is 1 when every PV reached the archived state; matched counts the PVs whose stored
# frames equal the pins, total the PVs of the cell.
function decide_outcome {
    local failed=$1
    local all=$2
    local matched=$3
    local total=$4
    if (( failed == 1 )); then
        printf 'Failed\n'
    elif (( all == 1 && matched == total )); then
        printf 'Archived\n'
    elif (( all == 1 )); then
        printf 'Connected-without-storage\n'
    else
        printf 'Not-connected\n'
    fi
}

# Keeps the first copy of the engine and retrieval configuration files; later runs never replace it.
function save_originals {
    local component
    local conf
    mkdir -p "${SAVED_DIR}"
    for component in engine retrieval; do
        conf="${APPLIANCE_DIR}/${component}/conf/${component}.conf"
        if [[ ! -s "${SAVED_DIR}/${component}.conf.orig" ]]; then
            cp "${conf}" "${SAVED_DIR}/${component}.conf.orig"
        fi
    done
}

# Writes the saved configuration of one component plus the heap flags (and the Channel Access limit for the engine).
function write_component_conf {
    local component=$1
    local heap=$2
    local ca=${3:-}
    CONFIGS_CHANGED=1
    {
        cat "${SAVED_DIR}/${component}.conf.orig"
        printf '%s\n' "CATALINA_OPTS=\"\$CATALINA_OPTS -Xms${heap}M -Xmx${heap}M\""
        if [[ -n "${ca}" ]]; then
            printf '%s\n' "EPICS_CA_MAX_ARRAY_BYTES=${ca}"
        fi
    } | sudo -n -u "${SERVICE_ACCOUNT}" tee "${APPLIANCE_DIR}/${component}/conf/${component}.conf" > /dev/null
}

# Prints the pid, start time, heap flags and Channel Access limit of the four JVMs and the status of the management interface.
function jvm_state {
    local component
    local pid
    local heap
    local ca
    local started
    for component in ${COMPONENTS}; do
        pid=$(component_pid "${component}")
        if [[ -z "${pid}" ]]; then
            printf '%s: not found\n' "${component}"
            continue
        fi
        heap=$(tr '\0' ' ' < "/proc/${pid}/cmdline" | grep -o -E '\-Xm[sx][0-9]+M' | tr '\n' ' ')
        ca=$(sudo -n cat "/proc/${pid}/environ" | tr '\0' '\n' | grep -E '^EPICS_CA_MAX_ARRAY_BYTES')
        started=$(ps -o lstart= -p "${pid}")
        printf '%s pid=%s start=%s heap=[%s] %s\n' "${component}" "${pid}" "${started}" "${heap}" "${ca}"
    done
    curl -s -o /dev/null -w 'mgmt http=%{http_code}\n' "${MGMT_URL}/getApplianceInfo"
}

# Restarts the whole service (the supervising service ends when one JVM ends) and records the four JVMs.
function restart_service {
    sudo -n systemctl restart "${SERVICE_UNIT}"
    sleep "${RESTART_WAIT_S}"
    log "restart $* service=$(systemctl is-active "${SERVICE_UNIT}")"
    jvm_state | tee -a "${LOG_FILE}"
}

# Puts the saved configuration files back and restarts the service once; the drivers call it from their EXIT trap.
function restore_configs {
    local component
    if (( CONFIGS_CHANGED == 0 )); then
        return 0
    fi
    CONFIGS_CHANGED=0
    for component in engine retrieval; do
        sudo -n -u "${SERVICE_ACCOUNT}" tee "${APPLIANCE_DIR}/${component}/conf/${component}.conf" < "${SAVED_DIR}/${component}.conf.orig" > /dev/null
    done
    log "configuration restored from ${SAVED_DIR}"
    restart_service "restore"
}
