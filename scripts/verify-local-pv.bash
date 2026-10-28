#!/bin/bash
# Verifies a unique changing CA PV through registration and the pinned CSV client.
set -euo pipefail
umask 077
export LC_ALL=C TZ=UTC
SCRIPT_PATH=$(realpath -- "${BASH_SOURCE[0]}")
readonly SCRIPT_DIR="${SCRIPT_PATH%/*}"
epics_bin=''
check_epics_only=0
cleanup_action=''
limit=180
workspace=''
pv=''
ioc_pid=''
submitted=0
paused=0
ioc_start=''
mgmt=''
retrieval=''
source_path=''
curl_bin=''
begin=0
declare -a positional=()

function die {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

function usage {
    printf '%s\n' \
        'Usage: bash scripts/verify-local-pv.bash [OPTIONS] MGMT_BPL RETRIEVAL SOURCE_CHECKOUT' \
        'Start a loopback soft IOC, register one unique PV and verify changing stored CSV samples.' \
        '  --epics-bin DIR     EPICS Base bin directory containing softIoc and caget' \
        '  --check-epics       Validate EPICS prerequisites and print the binary directory only' \
        '  --cleanup ACTION    stop: pause PV and stop IOC; keep: leave both running' \
        '  --timeout SEC       Verification limit, 10..3600 seconds (180)' \
        '  -h, --help          Show this help' \
        'Without --cleanup, an interactive success menu selects stop or keep.' \
        'Failure or interruption stops this IOC and attempts to pause its PV.' \
        'Evidence, PV registration and stored samples are always retained; nothing is deleted.'
}

function ioc_alive {
    local line
    local -a fields=()
    [[ -n "$ioc_pid" && -n "$ioc_start" ]] || return 1
    IFS= read -r line 2>/dev/null < "/proc/$ioc_pid/stat" || return 1
    read -r -a fields <<< "${line##*) }"
    [[ "${fields[19]:-}" == "$ioc_start" && "${fields[0]:-}" != Z && "${fields[0]:-}" != X ]]
}

# Only the child owned by this shell is signalled; no PID file is trusted for cleanup.
function finish {
    local status=$? attempt
    trap '' INT TERM
    trap - EXIT
    if [[ -n "$ioc_pid" ]]; then
        if (( submitted && ! paused )); then
            if curl -q --noproxy '*' --fail --silent --show-error --max-time 10 \
                --get --data-urlencode "pv=$pv" "$mgmt/pauseArchivingPV" > "$workspace/pause.json" &&
                jq -e '.status == "ok"' "$workspace/pause.json" >/dev/null 2>&1; then
                printf 'Test PV paused: %s\n' "$pv" >&2
            else
                printf 'WARNING: PV pause was not confirmed; inspect the registration before resuming it: %s\n' "$pv" >&2
            fi
        fi
        if ioc_alive; then kill -TERM "$ioc_pid" 2>/dev/null || true; fi
        for attempt in 1 2 3 4 5; do
            ioc_alive || break
            sleep 1
        done
        if ioc_alive; then kill -KILL "$ioc_pid" 2>/dev/null || true; fi
        wait "$ioc_pid" 2>/dev/null || true
        printf '%s\n' 'Test IOC stopped. Registration and stored samples are retained.' >&2
    fi
    [[ -z "$workspace" ]] || printf 'Evidence: %s\n' "$workspace" >&2
    exit "$status"
}

function before_deadline {
    local remaining=$((deadline - SECONDS))
    (( remaining > 0 )) || return 124
    timeout --signal=KILL "$remaining" "$@"
}

# Matches fresh archived counter samples to independently observed CA values and timestamps.
function check_csv {
    local file="$1" end="$2"
    awk -F, -v begin="$begin" -v end="$end" '
        NR == FNR { split($0, a, "\t"); observed[a[2]]=a[1]; fractions[a[2]]=a[3]; next }
        FNR == 1 { if ($0 != "time_utc,secs,nanos,value,severity,status") exit 1; next }
        NF == 6 && $2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/ && $4 ~ /^[0-9]+([.]0+)?$/ {
            if ($2 < begin || $2 > end || ($2 == end && $3 > 0) ||
                $3 >= 1000000000 || $5 != 0 || $6 != 0) next
            value=sprintf("%.0f", $4)
            if (value in observed) {
                delta=$2-observed[value]; fraction=$3-fractions[value]
                if (fraction < 0) { delta--; fraction+=1000000000 }
                if (delta >= -1 && (delta < 1 || (delta == 1 && fraction == 0))) {
                    values[value]=1; count++; lasttime=$1; lastvalue=$4
                }
            }
        }
        END { for (v in values) distinct++; if (distinct < 2) exit 1
              printf "Verified %d stored samples matching changing CA values.\n", count
              gsub(/"/, "", lasttime)
              printf "Latest matched sample UTC: %s\nValue: %s\n", lasttime, lastvalue }
    ' "$workspace/ca.tsv" "$file"
}

# Resolves the exported Base environment without executing an environment setup file.
function resolve_epics_bin {
    local candidate
    local -a candidates=()
    if [[ -z "$epics_bin" ]]; then
        [[ -n "${EPICS_BASE:-}" ]] || die 'EPICS_BASE is not exported. Source your EPICS environment setup file in this terminal, then rerun.'
        [[ "$EPICS_BASE" == /* && -d "$EPICS_BASE" ]] || die 'EPICS_BASE must name an existing absolute Base directory. Source your EPICS environment setup file, then rerun.'
        if [[ -n "${EPICS_HOST_ARCH:-}" ]]; then
            [[ "$EPICS_HOST_ARCH" != */* && "$EPICS_HOST_ARCH" != . && "$EPICS_HOST_ARCH" != .. ]] || die 'Invalid EPICS_HOST_ARCH'
            epics_bin="$EPICS_BASE/bin/$EPICS_HOST_ARCH"
        else
            for candidate in "$EPICS_BASE"/bin/*; do
                if [[ -x "$candidate/softIoc" && -x "$candidate/caget" ]]; then candidates+=("$candidate"); fi
            done
            (( ${#candidates[@]} == 1 )) || die 'Cannot select a unique EPICS Base binary directory. Source your EPICS environment setup file with EPICS_HOST_ARCH, then rerun.'
            epics_bin="${candidates[0]}"
        fi
    fi
    [[ "$epics_bin" == /* && -x "$epics_bin/softIoc" && -x "$epics_bin/caget" ]] || die 'EPICS binary directory must contain executable softIoc and caget. Source your EPICS environment setup file or correct --epics-bin, then rerun.'
}

function main {
    local option tool resolved answer prefix deadline remaining from to now attempt=0
    local response name day clock value _unused seconds nanos stamp client file line archiving_since=-1
    local -a fields=()
    while (( $# )); do
        option="$1"
        case "$option" in
            --check-epics) check_epics_only=1; shift ;;
            --epics-bin|--cleanup|--timeout)
                (( $# >= 2 )) || die "Missing value for $option"
                case "$option" in
                    --epics-bin) epics_bin="$2" ;;
                    --cleanup) cleanup_action="$2"; [[ "$2" == stop || "$2" == keep ]] || die 'Cleanup must be stop or keep' ;;
                    --timeout)
                        [[ "$2" =~ ^[0-9]{1,4}$ ]] || die 'Invalid timeout'
                        limit=$((10#$2)); (( limit >= 10 && limit <= 3600 )) || die 'Timeout must be 10..3600' ;;
                esac
                shift 2 ;;
            -h|--help) usage; exit 0 ;;
            --) shift; positional+=("$@"); break ;;
            -*) die "Unknown option: $option" ;;
            *) positional+=("$1"); shift ;;
        esac
    done
    (( EUID != 0 )) || die 'Run as an ordinary user'
    if (( check_epics_only )); then
        (( ${#positional[@]} == 0 )) || die '--check-epics does not accept API arguments'
        resolve_epics_bin
        printf '%s\n' "$epics_bin"
        return
    fi
    (( ${#positional[@]} == 3 )) || die 'Supply MGMT_BPL, RETRIEVAL and SOURCE_CHECKOUT; see --help'
    [[ -t 0 || -n "$cleanup_action" ]] || die 'Non-interactive stdin; select --cleanup stop or keep'
    mgmt="${positional[0]%/}"
    retrieval="${positional[1]%/}"
    source_path="${positional[2]}"
    for tool in curl jq timeout date awk nohup mktemp mkdir ln cp; do
        resolved=$(command -v "$tool") || die "Required executable not found: $tool"
        [[ -x "$resolved" ]] || die "Required executable is not executable: $tool"
    done
    curl_bin=$(command -v curl)
    [[ -x "$SCRIPT_DIR/verify-local-pv-curl.bash" ]] || die 'The retrieval adapter is missing or not executable'
    [[ "$mgmt" =~ ^http://(localhost|127\.0\.0\.1):[0-9]+/mgmt/bpl$ ]] || die 'Use the local loopback management URL'
    [[ "$retrieval" =~ ^http://(localhost|127\.0\.0\.1):[0-9]+/retrieval$ ]] || die 'Use the local loopback retrieval URL'
    client="$source_path/docs/book/src/samples/getDataToCsv.bash"
    [[ -r "$client" && -r "${client%/*}/archiverClient.bash" ]] || die 'The selected source does not provide the CSV client'
    resolve_epics_bin
    workspace=$(mktemp -d /tmp/archiver-local-pv.XXXXXXXX)
    mkdir -- "$workspace/client-bin"
    ln -s -- "$SCRIPT_DIR/verify-local-pv-curl.bash" "$workspace/client-bin/curl"
    prefix="LocalInstall:${workspace##*.}:"
    pv="${prefix}Value"
    printf '%s\n' "$pv" > "$workspace/pvs.txt"
    : > "$workspace/ca.tsv"
    printf 'Test PV: %s\nEvidence: %s\n' "$pv" "$workspace"
    trap finish EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    export EPICS_CA_ADDR_LIST=127.0.0.1 EPICS_CA_AUTO_ADDR_LIST=NO
    export EPICS_CAS_INTF_ADDR_LIST=127.0.0.1 EPICS_CAS_BEACON_ADDR_LIST=127.0.0.1
    export EPICS_CAS_AUTO_BEACON_ADDR_LIST=NO
    begin=$(date -u +%s)
    deadline=$((SECONDS + limit))
    nohup "$epics_bin/softIoc" -S -m "P=$prefix" -d "$SCRIPT_DIR/fixtures/local-install-pv.db" \
        > "$workspace/ioc.log" 2>&1 < /dev/null &
    ioc_pid=$!
    IFS= read -r line < "/proc/$ioc_pid/stat" || die 'Cannot record IOC process identity'
    read -r -a fields <<< "${line##*) }"
    ioc_start="${fields[19]}"
    printf '%s\n' "$ioc_pid" > "$workspace/ioc.pid"
    printf '%s\n' 'Waiting for real CA observations and stored samples; evidence is retained on every outcome.'
    while (( SECONDS < deadline )); do
        ioc_alive || die 'Soft IOC exited; inspect ioc.log'
        response=$(before_deadline timeout 3 "$epics_bin/caget" -a -f0 -w 1 "$pv" 2>> "$workspace/ca.err") || response=''
        printf '%s\n' "$response" >> "$workspace/ca.log"
        read -r name day clock value _unused <<< "$response"
        if [[ "$name" == "$pv" && "${value:-}" =~ ^[0-9]+$ ]] && stamp=$(date -u -d "$day $clock" '+%s %N' 2>/dev/null); then
            read -r seconds nanos <<< "$stamp"
            printf '%s\t%s\t%s\n' "$seconds" "$value" "$nanos" >> "$workspace/ca.tsv"
            if (( ! submitted )); then
                jq -n --arg pv "$pv" '[{pv:$pv,samplingmethod:"MONITOR",samplingperiod:"1.0"}]' > "$workspace/request.json"
                submitted=1
                before_deadline curl -q --noproxy '*' --fail --silent --show-error --max-time 10 \
                    -H 'Content-Type: application/json' --data-binary "@$workspace/request.json" \
                    "$mgmt/archivePV" > "$workspace/register.json" || die 'Registration response was not confirmed'
                jq -e --arg pv "$pv" 'type == "array" and length == 1 and .[0].pvName == $pv
                    and .[0].status == "Archive request submitted"' "$workspace/register.json" >/dev/null || die 'Registration was not accepted'
                printf 'Archive request accepted: %s\n' "$pv"
            fi
            if (( ! paused )); then
                if before_deadline curl -q --noproxy '*' --fail --silent --max-time 2 --get \
                    --data-urlencode "pv=$pv" "$mgmt/getPVStatus" > "$workspace/status.json" &&
                    jq -e --arg pv "$pv" 'type == "array" and length == 1 and .[0].pvName == $pv
                        and .[0].status == "Being archived"' "$workspace/status.json" >/dev/null 2>&1; then
                    if (( archiving_since < 0 )); then
                        archiving_since=$SECONDS
                        printf '%s\n' 'PV is being archived; collecting five seconds before pausing to flush stored samples.'
                    elif (( SECONDS - archiving_since >= 5 )); then
                        before_deadline curl -q --noproxy '*' --fail --silent --show-error --max-time 10 --get \
                            --data-urlencode "pv=$pv" "$mgmt/pauseArchivingPV" > "$workspace/pause.json" || die 'Cannot confirm PV pause before storage verification'
                        jq -e '.status == "ok"' "$workspace/pause.json" >/dev/null || die 'Pause did not confirm a successful flush'
                        paused=1
                        printf 'Test PV paused: %s; reading persisted samples.\n' "$pv"
                    fi
                fi
            fi
            now=$(date -u +%s)
            if (( paused && now > begin + 2 )); then
                attempt=$((attempt + 1))
                remaining=$((deadline - SECONDS))
                (( remaining > 0 )) || break
                from=$(date -u -d "@$begin" +%Y-%m-%dT%H:%M:%SZ)
                to=$(date -u -d "@$now" +%Y-%m-%dT%H:%M:%SZ)
                if AA_PV_CURL_BIN="$curl_bin" AA_PV_EXPECTED="$pv" \
                    AA_PV_RETRIEVAL_URL="$retrieval/data/getData.json" \
                    AA_PV_RESPONSE="$workspace/retrieval-$attempt.json" PATH="$workspace/client-bin:$PATH" \
                    timeout --signal=KILL "$remaining" bash "$client" --timeout 5 "$retrieval" \
                    "$workspace/pvs.txt" "$from" "$to" "$workspace/csv-$attempt" > "$workspace/extract-$attempt.log" 2>&1; then
                    file="$workspace/csv-$attempt/${pv//[^A-Za-z0-9._-]/_}.csv"
                    if (( SECONDS < deadline )) && check_csv "$file" "$now" > "$workspace/result.txt"; then
                        printf '\n%s\n' 'PV acquisition, storage and retrieval: PASS'
                        cat "$workspace/result.txt"
                        printf 'CSV: %s\n' "$file"
                        if [[ -z "$cleanup_action" ]]; then
                            printf '%s\n' 'Current state: test PV is Paused; IOC is running. Stored samples and CSV are retained.' \
                                '1. Stop IOC; leave test PV Paused (default)' \
                                '2. Resume test PV archiving; keep IOC running'
                            printf '%s' 'Select [1/2]: '
                            read -r answer || answer=1
                            case "$answer" in 2) cleanup_action=keep ;; *) cleanup_action=stop ;; esac
                        fi
                        if [[ "$cleanup_action" == keep ]]; then
                            ioc_alive || die 'Test IOC stopped while waiting for the cleanup choice; PV remains paused'
                            paused=0
                            curl -q --noproxy '*' --fail --silent --show-error --max-time 10 --get \
                                --data-urlencode "pv=$pv" "$mgmt/resumeArchivingPV" > "$workspace/resume.json" || die 'Cannot confirm test PV resume'
                            jq -e '.status == "ok"' "$workspace/resume.json" >/dev/null || die 'Test PV resume failed'
                            ioc_alive || die 'Test IOC stopped during PV resume; cleanup will pause the PV'
                            printf 'IOC retained: PID %s; PV %s. See README for pause and stop commands.\n' "$ioc_pid" "$pv"
                            ioc_pid=''
                        fi
                        return
                    fi
                fi
            fi
        fi
        before_deadline sleep 2 || true
    done
    die "No two changing stored samples matched real CA observations within $limit seconds"
}

# Parse the entry call and exit together before a long-running operation can change this file.
main "$@"; exit "$?"
