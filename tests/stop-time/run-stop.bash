#!/usr/bin/env bash
# Measure one stop of the appliance unit on the stop time guest (tests/stop-time/README.md).
# Usage:
#   run-stop.bash --run <run-id> --cell <cell> --stop <n|nr> --stage <N> --partition <name>
#                 --hold <n> --evidence <dir> --pv-list <csv> [--pv-list <csv> ...]
#                 --expectation <file> [--prediction <file>] [--unit <unit>] [--dry-run]
#   run-stop.bash --judge <stop folder>
# Cells: rehearsal-25, rehearsal-100, main-903, main-3000, validation-903 (the only cell that takes --prediction).
# Exit status: 0 Passed, 1 Failed, 2 Incomplete, 3 refusal or usage, 130 INT, 143 TERM.
# Test hooks: STOP_TIME_GUARD_FILE (default /etc/stop-time-guest) and STOP_TIME_CHECKOUT
# (default the checkout that holds this script).

set -euo pipefail

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TOP
readonly GUARD_FILE="${STOP_TIME_GUARD_FILE:-/etc/stop-time-guest}"
readonly CHECKOUT="${STOP_TIME_CHECKOUT:-$(cd "${TOP}/../.." && pwd)}"
readonly REQUIRED_STORAGE_TOP="/arch"
readonly IOC_UNIT="stop-time-ioc.service"
readonly READY_LIMIT_S=900
readonly LISTING_GRACE_S=10
readonly DISK_LIMIT_PCT=85

readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly BLUE=$'\033[0;34m'
readonly CYAN=$'\033[0;36m'
readonly NC=$'\033[0m'

declare -g TEST_TOTAL=0
declare -g TEST_PASSED=0
declare -g TEST_FAILED=0
declare -g TEST_COMPLETE=0
declare -g -a FAILED_DETAILS=()
declare -g -a INCOMPLETE_DETAILS=()
declare -g SUMMARY_ON=0

declare -g RUN_ID="" CELL="" STOP="" STAGE="" PARTITION="" HOLD="" UNIT="" EVIDENCE=""
declare -g EXPECTATION="" PREDICTION="" DRY_RUN=0 JUDGE=""
declare -g -a PV_LISTS=()
declare -g STORAGE_TOP="" INSTALL_LOCATION="" MGMT_URL="" TIMEOUT_S="" LOG4J_SITE_FILE=""
declare -g RUN_DIR="" STOP_DIR="" STATUS="" PART_S=0

function refuse {
    printf 'run-stop: %s\n' "$1" >&2
    exit 3
}

function usage {
    sed -n '3,9p' "${BASH_SOURCE[0]}" >&2
    exit 3
}

function mark_incomplete {
    INCOMPLETE_DETAILS+=("$1")
}

function why {
    printf "%bWhy:%b  %s\n" "${CYAN}" "${NC}" "$1"
}

function assert_claim {
    local name="$1" verdict="$2"
    case "${verdict}" in
        Passed)
            TEST_TOTAL=$((TEST_TOTAL + 1)); TEST_PASSED=$((TEST_PASSED + 1))
            printf "%b[ PASS ]%b %-40s = %s\n" "${GREEN}" "${NC}" "${name}" "${verdict}" ;;
        Failed)
            TEST_TOTAL=$((TEST_TOTAL + 1)); TEST_FAILED=$((TEST_FAILED + 1))
            printf "%b[ FAIL ]%b %s\n" "${RED}" "${NC}" "${name}" >&2
            FAILED_DETAILS+=("${name}") ;;
        *)
            mark_incomplete "${name}: required evidence missing" ;;
    esac
}

function print_divider {
    printf "%s\n" "------------------------------------------------------------"
}

function print_summary {
    local detail
    printf "\n"
    print_divider
    printf "%b%s%b\n" "${BLUE}" "STOP TIME SUMMARY" "${NC}"
    printf "  %-20s : %d\n" "Total Assertions" "${TEST_TOTAL}"
    printf "  %-20s : %d\n" "Passed" "${TEST_PASSED}"
    printf "  %-20s : %d\n" "Failed" "${TEST_FAILED}"
    printf "  %-20s : %d\n" "Incomplete Reasons" "${#INCOMPLETE_DETAILS[@]}"
    for detail in "${FAILED_DETAILS[@]}"; do
        printf "%b  [FAIL] %s%b\n" "${RED}" "${detail}" "${NC}"
    done
    for detail in "${INCOMPLETE_DETAILS[@]}"; do
        printf "%b  [INCOMPLETE] %s%b\n" "${YELLOW}" "${detail}" "${NC}"
    done
    if [[ ${TEST_FAILED} -gt 0 ]]; then
        printf "%b[VERDICT] Failed%b\n" "${RED}" "${NC}"
    elif [[ ${#INCOMPLETE_DETAILS[@]} -gt 0 ]]; then
        printf "%b[VERDICT] Incomplete%b\n" "${YELLOW}" "${NC}"
    else
        printf "%b[VERDICT] Passed%b\n" "${GREEN}" "${NC}"
    fi
    print_divider
}

function _handle_exit {
    local rc=$? final_rc=0
    # Refusals, usage errors and --judge exit before the measurement starts.
    [[ ${SUMMARY_ON} -eq 1 ]] || exit "${rc}"
    if [[ ${rc} -ne 0 ]]; then
        printf "Script exited with native status %d\n" "${rc}" >&2
    fi
    if [[ ${TEST_COMPLETE} -ne 1 ]]; then
        mark_incomplete "Required capture or evaluation did not complete"
    fi
    final_rc=${rc}
    if [[ ${final_rc} -eq 0 ]]; then
        if [[ ${TEST_FAILED} -gt 0 ]]; then
            final_rc=1
        elif [[ ${#INCOMPLETE_DETAILS[@]} -gt 0 ]]; then
            final_rc=2
        fi
    fi
    if [[ -n "${STATUS}" && -f "${STATUS}" ]]; then
        set_status actual_end_utc "$(utc_now)" || true
    fi
    if [[ -n "${STOP_DIR}" ]]; then
        printf "Evidence retained: %s\n" "${STOP_DIR}"
    fi
    print_summary
    exit "${final_rc}"
}

function utc_now {
    date -u +%Y-%m-%dT%H:%M:%S.%6NZ
}

function utc_of {
    date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ
}

# Run a command and keep its standard output, standard error and exit status
# under <stop folder>/cmd/<name>.{out,err,rc}; return its status.
function keep {
    local name="$1" rc=0
    shift
    mkdir -p "${STOP_DIR}/cmd"
    "$@" > "${STOP_DIR}/cmd/${name}.out" 2> "${STOP_DIR}/cmd/${name}.err" || rc=$?
    printf '%d\n' "${rc}" > "${STOP_DIR}/cmd/${name}.rc"
    return "${rc}"
}

function make_var {
    make -s --no-print-directory -C "${CHECKOUT}" "print-$1"
}

function set_status {
    local key="$1" value="$2" tmp
    tmp="${STATUS}.tmp"
    if [[ -f "${STATUS}" ]]; then
        grep -v "^${key}=" "${STATUS}" > "${tmp}" || true
    else
        : > "${tmp}"
    fi
    [[ -z "${value}" ]] || printf '%s=%s\n' "${key}" "${value}" >> "${tmp}"
    mv "${tmp}" "${STATUS}"
}

function parse_options {
    [[ $# -gt 0 ]] || usage
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --run) RUN_ID="${2:-}"; shift 2 ;;
            --cell) CELL="${2:-}"; shift 2 ;;
            --stop) STOP="${2:-}"; shift 2 ;;
            --stage) STAGE="${2:-}"; shift 2 ;;
            --partition) PARTITION="${2:-}"; shift 2 ;;
            --hold) HOLD="${2:-}"; shift 2 ;;
            --unit) UNIT="${2:-}"; shift 2 ;;
            --evidence) EVIDENCE="${2:-}"; shift 2 ;;
            --pv-list) PV_LISTS+=("${2:-}"); shift 2 ;;
            --expectation) EXPECTATION="${2:-}"; shift 2 ;;
            --prediction) PREDICTION="${2:-}"; shift 2 ;;
            --dry-run) DRY_RUN=1; shift ;;
            --judge) JUDGE="${2:-}"; shift 2 ;;
            *) usage ;;
        esac
    done
}

function validate_options {
    [[ "${RUN_ID}" =~ ^[A-Za-z0-9._-]+$ ]] || refuse "--run needs a name of letters, digits, '.', '_' or '-'"
    case "${CELL}" in
        rehearsal-25 | rehearsal-100 | main-903 | main-3000 | validation-903) ;;
        *) refuse "--cell must be rehearsal-25, rehearsal-100, main-903, main-3000 or validation-903" ;;
    esac
    [[ "${STOP}" =~ ^[0-9]+r?$ ]] || refuse "--stop must be a number, optionally with the suffix r"
    [[ "${STAGE}" =~ ^[1-9][0-9]*$ ]] || refuse "--stage must be a positive number"
    case "${PARTITION}" in
        PARTITION_5MIN) PART_S=300 ;;
        PARTITION_HOUR) PART_S=3600 ;;
        *) refuse "--partition must be PARTITION_5MIN or PARTITION_HOUR" ;;
    esac
    [[ "${HOLD}" =~ ^[1-9][0-9]*$ ]] || refuse "--hold must be a positive number"
    [[ -n "${EVIDENCE}" ]] || refuse "--evidence is required"
    [[ ${#PV_LISTS[@]} -gt 0 ]] || refuse "--pv-list is required"
    local list
    for list in "${PV_LISTS[@]}"; do
        [[ -r "${list}" ]] || refuse "cannot read the PV list ${list}"
    done
    [[ -r "${EXPECTATION}" ]] || refuse "--expectation must name a readable file"
    if [[ "${CELL}" == "validation-903" ]]; then
        [[ -r "${PREDICTION}" ]] || refuse "the validation stop needs --prediction"
        [[ -r "${PREDICTION}.sha256" ]] || refuse "the prediction needs its hash file ${PREDICTION}.sha256"
    else
        [[ -z "${PREDICTION}" ]] || refuse "--prediction is for the validation stop only"
    fi
}

# The guard comes before any command that reads the appliance or its storage.
function check_guard {
    [[ -e "${GUARD_FILE}" ]] || refuse "the guard file ${GUARD_FILE} is absent; this is not the stop time guest"
    STORAGE_TOP="$(make_var ARCHAPPL_STORAGE_TOP)" || refuse "cannot read ARCHAPPL_STORAGE_TOP from ${CHECKOUT}"
    [[ "${STORAGE_TOP}" == "${REQUIRED_STORAGE_TOP}" ]] \
        || refuse "ARCHAPPL_STORAGE_TOP is '${STORAGE_TOP}', not ${REQUIRED_STORAGE_TOP}"
    INSTALL_LOCATION="$(make_var AA_INSTALL_LOCATION)" || refuse "cannot read AA_INSTALL_LOCATION"
    MGMT_URL="$(make_var ARCHAPPL_MGMT_URL)" || refuse "cannot read ARCHAPPL_MGMT_URL"
    TIMEOUT_S="$(make_var SYSTEMD_TIMEOUT_STOP_SECONDS)" || refuse "cannot read SYSTEMD_TIMEOUT_STOP_SECONDS"
    LOG4J_SITE_FILE="$(make_var ARCHAPPL_LOG4J_SITE_FILE)" || refuse "cannot read ARCHAPPL_LOG4J_SITE_FILE"
    [[ -n "${UNIT}" ]] || UNIT="$(make_var SYSTEMD_FILENAME)" || refuse "cannot read SYSTEMD_FILENAME"
    local evidence_abs
    evidence_abs="$(realpath -m -- "${EVIDENCE}")"
    case "${evidence_abs}/" in
        "${STORAGE_TOP}"/* | /dev/shm/* | /tmp/*) refuse "the evidence directory must lie outside ${STORAGE_TOP} and scratch folders" ;;
    esac
    EVIDENCE="${evidence_abs}"
}

# Checks that need the guest but change nothing.
function check_before {
    local tool use list
    for tool in systemctl journalctl sudo find sha256sum curl chronyc awk; do
        command -v "${tool}" > /dev/null || refuse "the tool ${tool} is missing"
    done
    systemctl is-active --quiet "${UNIT}" || refuse "the unit ${UNIT} is not active"
    systemctl is-active --quiet "${IOC_UNIT}" || refuse "the IOC unit ${IOC_UNIT} is not active"
    [[ -n "${LOG4J_SITE_FILE}" ]] || refuse "ARCHAPPL_LOG4J_SITE_FILE is empty; the pass events need the site file"
    sudo test -r "${INSTALL_LOCATION}/etl/logs/etl-pass.log" || refuse "no etl-pass.log under ${INSTALL_LOCATION}/etl/logs"
    use="$(df --output=pcent / | tail -n 1 | tr -dc '0-9')"
    [[ "${use}" -lt "${DISK_LIMIT_PCT}" ]] || refuse "the root file system is at ${use} percent"
    [[ -n "$(journalctl -u "${UNIT}" --show-cursor -n 0 -q 2> /dev/null)" ]] \
        || refuse "journalctl gives no cursor for ${UNIT}; join the group systemd-journal or start the unit once"
    grep -q '^Storage=persistent' /etc/systemd/journald.conf /etc/systemd/journald.conf.d/*.conf 2> /dev/null \
        || [[ -d /var/log/journal ]] || refuse "the journal is not persistent"
    for list in "${PV_LISTS[@]}"; do
        head -n 1 "${list}" | tr -d '\r' | tr ',' '\n' | grep -qx store_key || refuse "${list} has no column store_key"
    done
    if [[ "${CELL}" == "validation-903" ]]; then
        (cd "$(dirname "${PREDICTION}")" && sha256sum --check --status "$(basename "${PREDICTION}").sha256") \
            || refuse "the prediction file does not match its hash"
    fi
}

# The store keys of the stage, from the column store_key of the PV lists.
function write_keys {
    local list
    for list in "${PV_LISTS[@]}"; do
        awk -F',' 'NR == 1 { for (i = 1; i <= NF; i++) { h = $i; sub(/\r$/, "", h); if (h == "store_key") c = i }; next }
                   c { v = $c; sub(/\r$/, "", v); if (v != "") print v }' "${list}"
    done > "$1"
}

# Every PV of the stage has exactly one entry Being archived with connectionState true.
function pvs_ready {
    local body="$1"
    curl -fsS --max-time 60 "${MGMT_URL}/getPVStatus" > "${body}" || return 1
    awk -v want="${STAGE}" 'BEGIN { RS = "}" }
        {
            if (!match($0, /"pvName" *: *"[^"]*"/)) next
            pv = substr($0, RSTART, RLENGTH); sub(/^"pvName" *: *"/, "", pv); sub(/"$/, "", pv)
            n[pv]++
            if ($0 ~ /"status" *: *"Being archived"/ && $0 ~ /"connectionState" *: *"?true"?/) ok[pv]++
        }
        END {
            for (pv in n) { total++; if (n[pv] == 1 && ok[pv] == 1) good++ }
            exit !(total == want && good == want)
        }' "${body}"
}

# The listing of the three stores: <store> <bytes> <mtime UTC> <path>.
function list_stores {
    local store
    for store in sts mts lts; do
        sudo env TZ=UTC find "${STORAGE_TOP}/${store}/ArchiverStore" -type f -name '*.pb' \
            -printf "${store} %s %TY-%Tm-%TdT%TH:%TM:%TSZ %p\n" 2> /dev/null || true
    done | LC_ALL=C sort -k4
}

# Number of keys of the stage whose files in the short term store differ from hold + 2.
function off_count {
    awk -v want="$((HOLD + 2))" 'FILENAME == ARGV[1] { sub(/\r$/, ""); keys[$0] = 1; next }
        $1 == "sts" { p = $4; sub(/.*\/ArchiverStore\//, "", p); sub(/:[^:\/]*\.pb$/, "", p); if (p in keys) n[p]++ }
        END { for (k in keys) if (n[k] + 0 != want) off++; print off + 0 }' "$1" "$2"
}

function wait_until {
    local target="$1" now
    while :; do
        now="$(date -u +%s)"
        [[ ${now} -lt ${target} ]] || return 0
        sleep "$(( target - now > 30 ? 30 : target - now ))"
    done
}

function etl_log_size {
    sudo stat -c %s "${INSTALL_LOCATION}/etl/logs/etl-pass.log"
}

function pass_record_at {
    local e_iso="$1"
    sudo grep -q "ETLPassRecord\[plannedAt=${e_iso}" "${INSTALL_LOCATION}/etl/logs/etl-pass.log"
}

# Read a file as root; the caller writes the copy as the engineer.
function sudo_read {
    sudo cat -- "$1"
}

# Write <folder>/SHA256SUMS over every other file of the folder.
function write_sums {
    local folder="$1" depth="$2" sums
    sums="$(cd "${folder}" && find . -maxdepth "${depth}" -type f ! -name SHA256SUMS -printf '%P\n' | LC_ALL=C sort | xargs -r sha256sum)"
    printf '%s\n' "${sums}" > "${folder}/SHA256SUMS"
}

function freeze_config {
    local f="${STOP_DIR}/frozen" bin
    mkdir -p "${f}"
    cp -p "${CHECKOUT}/site-template/policies.py" "${f}/policies.rendered.py" 2> /dev/null || true
    cp -p "${CHECKOUT}/../CONFIG_SITE.local" "${f}/CONFIG_SITE.local" 2> /dev/null || true
    sudo_read "${LOG4J_SITE_FILE}" > "${f}/log4j2-site.xml" 2> /dev/null || true
    sudo_read "${INSTALL_LOCATION}/archappl.properties" > "${f}/archappl.properties" 2> /dev/null || true
    sudo_read "${INSTALL_LOCATION}/archappl.conf" > "${f}/archappl.conf" 2> /dev/null || true
    sudo_read "${INSTALL_LOCATION}/policies.py" > "${f}/policies.installed.py" 2> /dev/null || true
    cat /etc/systemd/journald.conf /etc/systemd/journald.conf.d/*.conf > "${f}/journald.conf" 2> /dev/null || true
    cat /etc/chrony/chrony.conf > "${f}/chrony.conf" 2> /dev/null || true
    chronyc tracking > "${f}/chronyc-tracking.txt" 2>&1 || true
    systemctl cat "${IOC_UNIT}" > "${f}/${IOC_UNIT}" 2>&1 || true
    systemctl show "${UNIT}" -p TimeoutStopUSec -p KillMode > "${f}/unit-timeout.txt" 2>&1 || true
    for bin in softIoc caget; do
        command -v "${bin}" > /dev/null && sha256sum "$(command -v "${bin}")" >> "${f}/epics-binaries.sha256"
    done
    git -C "${CHECKOUT}" rev-parse HEAD > "${f}/env-ref.txt" 2>&1 || true
    git -C "${CHECKOUT}" status --short >> "${f}/env-ref.txt" 2>&1 || true
    uname -a > "${f}/kernel.txt"
    java -version > "${f}/jdk.txt" 2>&1 || true
    write_sums "${f}" 1
}

function write_meta {
    local lower="" upper=""
    if [[ "${CELL}" == "validation-903" ]]; then
        lower="$(sed -n 's/.*"lower_s": *\([-0-9.eE+]*\).*/\1/p' "${PREDICTION}")"
        upper="$(sed -n 's/.*"upper_s": *\([-0-9.eE+]*\).*/\1/p' "${PREDICTION}")"
    fi
    {
        printf 'run=%s\ncell=%s\nstop=%s\nn_pvs=%s\npartition=%s\nhold=%s\ntimeout_s=%s\ne_used_utc=%s\n' \
            "${RUN_ID}" "${CELL}" "${STOP}" "${STAGE}" "${PARTITION}" "${HOLD}" "${TIMEOUT_S}" "$1"
        [[ -z "${lower}" ]] || printf 'prediction_lower_s=%s\nprediction_upper_s=%s\n' "${lower}" "${upper}"
    } > "${STOP_DIR}/meta.env"
}

# Cut the journal from the cursor; fall back to the unit time stamps when the
# cursor is lost, and identify the first and the last record from an export read.
function cut_journal {
    local cursor="$1" since="$2" until="$3" mode="cursor" rc=0
    keep journal-cut env TZ=UTC journalctl -u "${UNIT}" --after-cursor="${cursor}" -o short-iso-precise --no-pager || rc=$?
    if [[ ${rc} -ne 0 ]] || grep -q 'Failed to seek to cursor' "${STOP_DIR}/cmd/journal-cut.err"; then
        mode="time"
        keep journal-cut-time env TZ=UTC journalctl -u "${UNIT}" --since="${since}" --until="${until}" -o short-iso-precise --no-pager || true
        cp "${STOP_DIR}/cmd/journal-cut-time.out" "${STOP_DIR}/journal.txt"
        keep journal-export journalctl -u "${UNIT}" --since="${since}" --until="${until}" -o export --no-pager || true
    else
        cp "${STOP_DIR}/cmd/journal-cut.out" "${STOP_DIR}/journal.txt"
        keep journal-export journalctl -u "${UNIT}" --after-cursor="${cursor}" -o export --no-pager || true
    fi
    awk -v mode="${mode}" '
        /^__CURSOR=/ { c = substr($0, 10) }
        /^__REALTIME_TIMESTAMP=/ { t = substr($0, 22); if (first == "") { first = c; ft = t }; last = c; lt = t }
        END {
            if (first == "") exit
            printf "first_cursor=%s\nfirst_utc=%s\nlast_cursor=%s\nlast_utc=%s\nmode=%s\n", first, ft, last, lt, mode
        }' "${STOP_DIR}/cmd/journal-export.out" > "${STOP_DIR}/journal.bounds"
    # The export gives microseconds since the epoch; convert them to UTC text.
    if [[ -s "${STOP_DIR}/journal.bounds" ]]; then
        local ft lt
        ft="$(sed -n 's/^first_utc=//p' "${STOP_DIR}/journal.bounds")"
        lt="$(sed -n 's/^last_utc=//p' "${STOP_DIR}/journal.bounds")"
        sed -i -e "s/^first_utc=.*/first_utc=$(date -u -d "@${ft:0:-6}.${ft: -6}" +%Y-%m-%dT%H:%M:%S.%6NZ)/" \
               -e "s/^last_utc=.*/last_utc=$(date -u -d "@${lt:0:-6}.${lt: -6}" +%Y-%m-%dT%H:%M:%S.%6NZ)/" \
               "${STOP_DIR}/journal.bounds"
    fi
}

function judge_folder {
    local record rc=0
    record="$("${TOP}/rebuild-table.bash" --stop "$1")" || rc=$?
    [[ ${rc} -le 2 ]] || exit 3
    printf '%s\n' "${record}"
    return "${rc}"
}

function claim_of {
    sed -n "s/.*\"$2\": \"\\([A-Za-z]*\\)\".*/\\1/p" <<< "$1"
}

function measure {
    local now ready b0 e_planned e_used lo hi off second=0 cursor size_before size_after
    local listing_end stop_rc=0 record rc=0 qualifier
    RUN_DIR="${EVIDENCE}/${RUN_ID}"
    STOP_DIR="${RUN_DIR}/stop-${CELL}-${STOP}"
    STATUS="${RUN_DIR}/status"
    [[ ! -e "${STOP_DIR}" ]] || refuse "the stop folder ${STOP_DIR} exists; a repeat takes the suffix r"
    mkdir -p "${STOP_DIR}"
    SUMMARY_ON=1

    now="$(date -u +%s)"
    set_status run "${RUN_ID}"; set_status cell "${CELL}"; set_status stop "${STOP}"
    set_status stage "${STAGE}"; set_status partition "${PARTITION}"; set_status hold "${HOLD}"
    set_status start_utc "$(utc_of "${now}")"
    set_status intended_end_utc "$(utc_of $((now + READY_LIMIT_S + (HOLD + 3) * PART_S + 30 + TIMEOUT_S)))"
    set_status actual_end_utc ""
    set_status expectation_sha256 "$(sha256sum "${EXPECTATION}" | cut -d' ' -f1)"
    set_status expectation_written_utc "$(utc_of "$(stat -c %Y "${EXPECTATION}")")"
    if [[ "${CELL}" == "validation-903" ]]; then
        set_status prediction_sha256 "$(cut -d' ' -f1 "${PREDICTION}.sha256")"
        set_status prediction_written_utc "$(utc_of "$(stat -c %Y "${PREDICTION}")")"
        cp -p "${PREDICTION}" "${PREDICTION}.sha256" "${STOP_DIR}/"
    fi
    cp -p "${EXPECTATION}" "${STOP_DIR}/"
    write_keys "${STOP_DIR}/keys.txt"
    [[ "$(wc -l < "${STOP_DIR}/keys.txt")" -eq "${STAGE}" ]] || refuse "the PV lists give $(wc -l < "${STOP_DIR}/keys.txt") keys, not ${STAGE}"

    why "B0 is the first boundary at least 30 seconds after every PV is archived and connected."
    while :; do
        if pvs_ready "${STOP_DIR}/cmd-getPVStatus.json"; then break; fi
        [[ $(( $(date -u +%s) - now )) -lt ${READY_LIMIT_S} ]] || { mark_incomplete "PVs not archived within ${READY_LIMIT_S} s"; return 0; }
        sleep 10
    done
    ready="$(date -u +%s)"
    b0=$(( ( (ready + 30 + PART_S - 1) / PART_S ) * PART_S ))
    e_planned=$(( b0 + (HOLD + 1) * PART_S ))
    hi=$(( PART_S == 300 ? 60 : 90 ))
    set_status b0_utc "$(utc_of "${b0}")"; set_status e_planned_utc "$(utc_of "${e_planned}")"
    printf 'Checkpoint: ready %s, B0 %s, E %s\n' "$(utc_of "${ready}")" "$(utc_of "${b0}")" "$(utc_of "${e_planned}")"

    e_used=${e_planned}
    while :; do
        lo=$(( e_used + 30 ))
        wait_until "${lo}"
        if [[ $(date -u +%s) -gt $(( e_used + hi )) ]]; then
            e_used=$(( e_used + PART_S )); continue
        fi
        if [[ ${PART_S} -eq 300 ]]; then
            until pass_record_at "$(utc_of "${e_used}")"; do
                [[ $(date -u +%s) -lt $(( e_used + hi )) ]] || break
                sleep 2
            done
        fi
        printf 'listing_start=%s\n' "$(utc_now)" > "${STOP_DIR}/listing-before.times"
        list_stores > "${STOP_DIR}/listing-before.txt"
        listing_end="$(date -u +%s)"
        printf 'listing_end=%s\n' "$(utc_now)" >> "${STOP_DIR}/listing-before.times"
        off="$(off_count "${STOP_DIR}/keys.txt" "${STOP_DIR}/listing-before.txt")"
        if [[ "${off}" -eq 0 && ${listing_end} -le $(( e_used + hi )) ]]; then break; fi
        if [[ "${off}" -ne 0 && ${second} -eq 0 ]]; then
            second=1; e_used=$(( e_used + PART_S )); continue
        fi
        [[ ${listing_end} -le $(( e_used + hi )) ]] || { e_used=$(( e_used + PART_S )); continue; }
        break
    done
    set_status e_used_utc "$(utc_of "${e_used}")"
    set_status chrony_offset_s "$(chronyc tracking 2> /dev/null | awk '/^System time/ { v = $4; if ($6 == "slow") v = -v; print v }')"

    cursor="$(journalctl -u "${UNIT}" --show-cursor -n 0 -q 2> /dev/null | sed -n 's/^-- cursor: //p')"
    [[ -n "${cursor}" ]] || mark_incomplete "no journal cursor before the stop"
    size_before="$(etl_log_size)"
    cp -p "${STATUS}" "${STOP_DIR}/status.${CELL}.${STOP}"
    [[ $(( $(date -u +%s) - listing_end )) -le ${LISTING_GRACE_S} ]] || mark_incomplete "the stop began more than ${LISTING_GRACE_S} s after the listing"

    why "The stop duration comes from the monotonic properties of the unit; the native status is kept apart."
    keep systemctl-stop sudo systemctl stop "${UNIT}" || stop_rc=$?
    printf '%d\n' "${stop_rc}" > "${STOP_DIR}/stop-exit.txt"
    keep systemctl-show systemctl show --timestamp=us+utc "${UNIT}" -p ActiveExitTimestamp -p ActiveExitTimestampMonotonic \
        -p InactiveEnterTimestamp -p InactiveEnterTimestampMonotonic -p Result -p InvocationID || true
    cp "${STOP_DIR}/cmd/systemctl-show.out" "${STOP_DIR}/unit.txt"

    local ax ie
    ax="$(sed -n 's/^ActiveExitTimestamp=[A-Za-z]* \(.*\) UTC$/\1/p' "${STOP_DIR}/unit.txt")"
    ie="$(sed -n 's/^InactiveEnterTimestamp=[A-Za-z]* \(.*\) UTC$/\1/p' "${STOP_DIR}/unit.txt")"
    if [[ -n "${cursor}" ]]; then
        cut_journal "${cursor}" "${ax} UTC" "$(date -u -d "${ie} UTC + 1 second" '+%Y-%m-%d %H:%M:%S') UTC"
    fi

    size_after="$(etl_log_size)"
    printf 'before=%s\nafter=%s\n' "${size_before}" "${size_after}" > "${STOP_DIR}/etl-pass.size"
    if [[ "${size_after}" -ge "${size_before}" ]]; then
        sudo tail -c "+$((size_before + 1))" "${INSTALL_LOCATION}/etl/logs/etl-pass.log" \
            | head -c "$((size_after - size_before))" > "${STOP_DIR}/etl-pass.cut"
    fi
    list_stores > "${STOP_DIR}/listing-after.txt"
    write_meta "$(utc_of "${e_used}")"
    freeze_config

    why "C1 needs complete evidence, C2 a sufficient stop, C3 the validation stop inside its interval."
    record="$(judge_folder "${STOP_DIR}")" || rc=$?
    printf '%s\n' "${record}" >> "${RUN_DIR}/stops.jsonl"
    assert_claim "C1 ${CELL}/${STOP} evidence complete" "$(claim_of "${record}" c1)"
    assert_claim "C2 ${CELL}/${STOP} stop suffices" "$(claim_of "${record}" c2)"
    [[ "${CELL}" != "validation-903" ]] || assert_claim "C3 ${CELL}/${STOP} inside the prediction" "$(claim_of "${record}" c3)"
    qualifier="$(sed -n 's/.*"qualifier": "\([^"]*\)".*/\1/p' <<< "${record}")"
    if [[ "${STOP}" == *r ]]; then
        set_status pending ""
    elif [[ -n "${qualifier}" || $(claim_of "${record}" c1) != "Passed" ]]; then
        set_status pending "${CELL}/${STOP}r"
    fi
    write_sums "${STOP_DIR}" 3
    TEST_COMPLETE=1
    : "${rc}"
}

function dry_run {
    printf 'Dry run: every check before the stop passed.\n'
    printf 'Unit %s, storage %s, install %s, timeout %s s, mgmt %s\n' "${UNIT}" "${STORAGE_TOP}" "${INSTALL_LOCATION}" "${TIMEOUT_S}" "${MGMT_URL}"
    printf 'Commands of the stop:\n'
    printf '  journalctl -u %s --show-cursor -n 0 -q\n' "${UNIT}"
    printf '  sudo stat -c %%s %s/etl/logs/etl-pass.log\n' "${INSTALL_LOCATION}"
    printf '  sudo systemctl stop %s\n' "${UNIT}"
    printf '  systemctl show --timestamp=us+utc %s -p ActiveExitTimestamp -p ActiveExitTimestampMonotonic -p InactiveEnterTimestamp -p InactiveEnterTimestampMonotonic -p Result -p InvocationID\n' "${UNIT}"
    printf '  TZ=UTC journalctl -u %s --after-cursor=<cursor> -o short-iso-precise\n' "${UNIT}"
    printf '  sudo env TZ=UTC find %s/{sts,mts,lts}/ArchiverStore -type f -name *.pb\n' "${STORAGE_TOP}"
    printf 'Evidence folder: %s/%s/stop-%s-%s\n' "${EVIDENCE}" "${RUN_ID}" "${CELL}" "${STOP}"
}

function main {
    parse_options "$@"
    if [[ -n "${JUDGE}" ]]; then
        [[ -d "${JUDGE}" ]] || refuse "--judge needs a stop folder"
        judge_folder "${JUDGE}"
        return
    fi
    validate_options
    check_guard
    check_before
    if [[ ${DRY_RUN} -eq 1 ]]; then
        dry_run
        return
    fi
    measure
}

trap _handle_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

main "$@"
