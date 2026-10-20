#!/usr/bin/env bash
# Self-test of the stop time scripts on the committed fixtures; runs on the local
# host without a guest and never reads the appliance or its storage.
# Usage: selftest.bash
# Environment: KEEP_WORKSPACE=1 keeps the workspace on success; COMPARE_EVIDENCE
# names compare-evidence.py of the test framework skill.
# Exit status: 0 Passed, 1 Failed, 2 Incomplete, 130 INT, 143 TERM.

set -euo pipefail

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TOP
readonly FIX="${TOP}/fixtures"
readonly COMPARE_EVIDENCE="${COMPARE_EVIDENCE:-${HOME}/.claude/skills/test-framework/scripts/compare-evidence.py}"

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
declare -g workspace=""

function mark_incomplete {
    INCOMPLETE_DETAILS+=("$1")
}

function why {
    printf "%bWhy:%b  %s\n" "${CYAN}" "${NC}" "$1"
}

function expect_eq {
    local name="$1" want="$2" got="$3"
    TEST_TOTAL=$((TEST_TOTAL + 1))
    if [[ "${got}" == "${want}" ]]; then
        printf "%b[ PASS ]%b %-52s = %s\n" "${GREEN}" "${NC}" "${name}" "${got}"
        TEST_PASSED=$((TEST_PASSED + 1))
        return 0
    fi
    printf "%b[ FAIL ]%b %s\n" "${RED}" "${NC}" "${name}" >&2
    printf "  %bExpected : %s%b\n" "${YELLOW}" "${want}" "${NC}" >&2
    printf "  %bActual   : %s%b\n" "${YELLOW}" "${got}" "${NC}" >&2
    TEST_FAILED=$((TEST_FAILED + 1))
    FAILED_DETAILS+=("${name} (expected ${want}, actual ${got})")
}

# Run a command, return "<status>" and keep its output in the workspace.
function status_of {
    local name="$1" rc=0
    shift
    "$@" > "${workspace}/out/${name}.out" 2> "${workspace}/out/${name}.err" || rc=$?
    printf '%d' "${rc}"
}

function field {
    sed -n "s/.*\"$2\": \\(\"[^\"]*\"\\|[-0-9.eE+]*\\).*/\\1/p" "$1" | tr -d '"'
}

function kv {
    sed -n "s/^$2=//p" "$1"
}

function cleanup {
    local rc="$1" target
    [[ -n "${workspace}" ]] || return 0
    if [[ ${rc} -ne 0 || "${KEEP_WORKSPACE:-0}" -eq 1 ]]; then
        printf "Workspace retained: %s\n" "${workspace}"
        return 0
    fi
    [[ "${workspace}" == /* && "${workspace}" != / && -d "${workspace}" && ! -L "${workspace}" ]] || return 1
    target=$(readlink -f -- "${workspace}") || return 1
    [[ "${target}" == "${workspace}" ]] || return 1
    printf "Removing scratch workspace: %s\n" "${target}"
    rm -rf -- "${workspace:?}"
}

function print_divider {
    printf "%s\n" "------------------------------------------------------------"
}

function print_summary {
    local detail
    printf "\n"
    print_divider
    printf "%b%s%b\n" "${BLUE}" "STOP TIME SELF-TEST SUMMARY" "${NC}"
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
    local rc=$? final_rc=0 cleanup_rc=0
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
    cleanup "${final_rc}" || cleanup_rc=$?
    print_summary
    if [[ ${cleanup_rc} -ne 0 ]]; then
        printf "Cleanup tool error: status %d\n" "${cleanup_rc}" >&2
        [[ ${final_rc} -ne 0 ]] || final_rc=${cleanup_rc}
    fi
    exit "${final_rc}"
}

# A copy of a fixture stop folder under the workspace.
function copy_stop {
    local src="$1" name="$2"
    cp -r "${FIX}/run-synthetic/${src}" "${workspace}/stops/${name}"
    printf '%s' "${workspace}/stops/${name}"
}

function judge {
    status_of "judge-$(basename "$1")" "${TOP}/rebuild-table.bash" --stop "$1"
}

function test_fixture_verdicts {
    why "The four fixture stop folders give Passed, Failed by timeout, Incomplete and the validation stop Passed."
    local name want
    for name in stop-01-passed:0 stop-02-timeout:1 stop-03-incomplete:2 stop-04-validation:0; do
        want="${name##*:}"; name="${name%%:*}"
        expect_eq "rebuild --stop ${name} status" "${want}" "$(judge "${FIX}/run-synthetic/${name}")"
    done
    local out="${workspace}/out/judge-stop-01-passed.out"
    expect_eq "passed: duration_s" "13" "$(field "${out}" duration_s)"
    expect_eq "passed: after_boundary_s" "40" "$(field "${out}" after_boundary_s)"
    expect_eq "passed: etl_gap_s" "10" "$(field "${out}" etl_gap_s)"
    expect_eq "passed: mgmt_gap_s" "1" "$(field "${out}" mgmt_gap_s)"
    expect_eq "passed: loop_median_s" "2.5" "$(field "${out}" loop_median_s)"
    expect_eq "passed: loop_max_pv" "STOPTIME:E0002" "$(field "${out}" loop_max_pv)"
    expect_eq "passed: sts_bytes_per_pv" "8000" "$(field "${out}" sts_bytes_per_pv)"
    expect_eq "passed: qualifier absent" "" "$(field "${out}" qualifier)"
    out="${workspace}/out/judge-stop-02-timeout.out"
    expect_eq "timeout: c1" "Passed" "$(field "${out}" c1)"
    expect_eq "timeout: c2" "Failed" "$(field "${out}" c2)"
    expect_eq "timeout: left_pvs" "2" "$(field "${out}" left_pvs)"
    expect_eq "timeout: sigkill_pv" "STOPTIME:E0003" "$(field "${out}" sigkill_pv)"
    out="${workspace}/out/judge-stop-03-incomplete.out"
    expect_eq "incomplete: reasons" "etl-pass.cut listing-after.txt" "$(field "${out}" incomplete)"
}

function test_parser_variants {
    why "Damaged copies of real-shaped records end Incomplete, a stack trace line is ignored, an unreadable file is a tool error."
    local d
    d="$(copy_stop stop-01-passed no-launcher)"; sed -i '/archappl-etl:/d' "${d}/journal.txt"
    expect_eq "launcher line removed: status" "2" "$(judge "${d}")"
    expect_eq "launcher line removed: reason" "launcher:etl" "$(field "${workspace}/out/judge-no-launcher.out" incomplete)"
    d="$(copy_stop stop-01-passed no-cursor)"; sed -i '/^first_cursor=/d' "${d}/journal.bounds"
    expect_eq "cut without its cursor: status" "2" "$(judge "${d}")"
    d="$(copy_stop stop-01-passed time-cut)"; sed -i 's/^mode=.*/mode=time/' "${d}/journal.bounds"
    expect_eq "cut by time stamps: status" "0" "$(judge "${d}")"
    d="$(copy_stop stop-01-passed truncated)"; printf 'before=4987\nafter=100\n' > "${d}/etl-pass.size"
    expect_eq "truncated log: status" "2" "$(judge "${d}")"
    expect_eq "truncated log: reason" "etl-pass:truncated" "$(field "${workspace}/out/judge-truncated.out" incomplete)"
    d="$(copy_stop stop-01-passed no-jobsrun)"; sed -i 's/ jobsRun=3,//' "${d}/etl-pass.cut"
    expect_eq "pass record without jobsRun: status" "2" "$(judge "${d}")"
    expect_eq "pass record without jobsRun: reason" "pass-record:jobsRun" "$(field "${workspace}/out/judge-no-jobsrun.out" incomplete)"
    d="$(copy_stop stop-01-passed no-invocation)"; sed -i '/^InvocationID=/d' "${d}/unit.txt"
    expect_eq "unit without InvocationID: status" "2" "$(judge "${d}")"
    d="$(copy_stop stop-01-passed stack-trace)"
    sed -i '3a\\tat org.epics.archiverappliance.etl.common.ETLPassDriver.run(ETLPassDriver.java:1)' "${d}/etl-pass.cut"
    expect_eq "stack trace line: status" "0" "$(judge "${d}")"
    expect_eq "stack trace line: loop_jobs" "3" "$(field "${workspace}/out/judge-stack-trace.out" loop_jobs)"
    d="$(copy_stop stop-01-passed empty-cut)"; : > "${d}/etl-pass.cut"
    expect_eq "empty cut: status" "2" "$(judge "${d}")"
    expect_eq "empty cut: reason" "etl-pass.cut:empty" "$(field "${workspace}/out/judge-empty-cut.out" incomplete)"
    d="$(copy_stop stop-01-passed malformed-listing)"; sed -i '1s/ 2026-[^ ]* / /' "${d}/listing-before.txt"
    expect_eq "listing row without time: status" "2" "$(judge "${d}")"
    d="$(copy_stop stop-01-passed no-frozen)"; rm "${d}/frozen/SHA256SUMS"
    expect_eq "no frozen configuration: status" "2" "$(judge "${d}")"
    d="$(copy_stop stop-01-passed off-rule)"; sed -i '/E0003:2026_10_19_20_05/d' "${d}/listing-before.txt"
    expect_eq "three files of one PV: status" "0" "$(judge "${d}")"
    expect_eq "three files of one PV: qualifier" "off-rule" "$(field "${workspace}/out/judge-off-rule.out" qualifier)"
    d="$(copy_stop stop-01-passed overlap)"
    sed -i 's/plannedAt=2026-10-19T20:05:00Z, startedAt=2026-10-19T20:05:00.100Z, endedAt=2026-10-19T20:05:02Z/plannedAt=2026-10-19T20:05:30Z, startedAt=2026-10-19T20:05:30Z, endedAt=2026-10-19T20:05:44Z/' "${d}/etl-pass.cut"
    expect_eq "pass running at the stop: qualifier" "overlap" "$(judge "${d}" > /dev/null; field "${workspace}/out/judge-overlap.out" qualifier)"
    if [[ ${EUID} -ne 0 ]]; then
        d="$(copy_stop stop-01-passed unreadable)"; chmod 000 "${d}/unit.txt"
        expect_eq "unreadable file: tool error status" "3" "$(judge "${d}")"
        chmod 644 "${d}/unit.txt"
    else
        mark_incomplete "unreadable file case needs a user other than root"
    fi
}

function test_time_handling {
    why "Time stamps of the unit, the journal and the log convert to the same epoch, across a month and a year."
    local d want e
    for e in 2026-09-30T23:59:59Z 2025-12-31T23:59:59.5Z; do
        d="$(copy_stop stop-01-passed "time-${e%%T*}")"
        sed -i "s/^e_used_utc=.*/e_used_utc=${e}/" "${d}/meta.env"
        judge "${d}" > /dev/null
        want="$(awk -v a="$(date -u -d '2026-10-19 20:05:40' +%s)" -v b="$(date -u -d "${e%Z}" +%s.%N)" 'BEGIN { printf "%.6g", a - b }')"
        expect_eq "after_boundary_s from ${e}" "${want}" "$(field "${workspace}/out/judge-time-${e%%T*}.out" after_boundary_s)"
    done
}

function test_gen_pvs {
    why "The generator writes 2097 records of the load1.db form and the list, deterministically."
    local a="${workspace}/gen-a" b="${workspace}/gen-b"
    mkdir -p "${a}" "${b}"
    expect_eq "gen-pvs status" "0" "$(status_of gen-a "${TOP}/gen-pvs.bash" "${a}")"
    status_of gen-b "${TOP}/gen-pvs.bash" "${b}" > /dev/null
    expect_eq "extra.db records" "2097" "$(grep -c '^record(calc, "STOPTIME:E[0-9][0-9][0-9][0-9]") {$' "${a}/extra.db")"
    expect_eq "extra.csv rows" "2097" "$(tail -n +2 "${a}/extra.csv" | wc -l)"
    expect_eq "extra.csv header" "pv,group,scan,method,period,policy,store_key" "$(head -n 1 "${a}/extra.csv")"
    expect_eq "first row" "STOPTIME:E0001,extra,1 second,MONITOR,1.0,,STOPTIME/E0001" "$(sed -n 2p "${a}/extra.csv")"
    expect_eq "last row" "STOPTIME:E2097,extra,1 second,MONITOR,1.0,,STOPTIME/E2097" "$(tail -n 1 "${a}/extra.csv")"
    expect_eq "first record" 'record(calc, "STOPTIME:E0001") {|  field(SCAN, "1 second")|  field(INPA, "STOPTIME:E0001.VAL NPP")|  field(CALC, "(A+1)%3600")|  field(VAL, "100")|  field(PREC, "1")|}' \
        "$(sed -n '2,8p' "${a}/extra.db" | paste -sd'|')"
    expect_eq "deterministic extra.db" "$(sha256sum < "${a}/extra.db")" "$(sha256sum < "${b}/extra.db")"
    expect_eq "deterministic extra.csv" "$(sha256sum < "${a}/extra.csv")" "$(sha256sum < "${b}/extra.csv")"
    expect_eq "no CR in the output" "0" "$(cat "${a}/extra.db" "${a}/extra.csv" | grep -c $'\r' || true)"
}

function test_fit_line {
    why "The fit of the known table matches values computed independently, and check, the table and the limits behave."
    local fit="${workspace}/fit.txt" n i t tbl
    expect_eq "fit-line line status" "0" "$(status_of fit-line "${TOP}/fit-line.bash" line "${FIX}/fit/stops.jsonl" "${fit}")"
    expect_eq "slope_s_per_pv" "0.0033381" "$(kv "${fit}" slope_s_per_pv)"
    expect_eq "intercept_s" "10.1857" "$(kv "${fit}" intercept_s)"
    expect_eq "slope_se" "0.00031512" "$(kv "${fit}" slope_se)"
    expect_eq "df" "4" "$(kv "${fit}" df)"
    expect_eq "check equal" "0" "$(status_of check-equal "${TOP}/fit-line.bash" check "${FIX}/fit/stops.jsonl" "${FIX}/fit/fit.txt")"
    sed 's/^intercept_s=10.1857$/intercept_s=10.1858/' "${FIX}/fit/fit.txt" > "${workspace}/fit-changed.txt"
    expect_eq "check on a changed digit" "1" "$(status_of check-changed "${TOP}/fit-line.bash" check "${FIX}/fit/stops.jsonl" "${workspace}/fit-changed.txt")"
    "${TOP}/fit-line.bash" predict "${FIX}/fit/stops.jsonl" "${workspace}/prediction.json"
    expect_eq "prediction lower_s" "9.13296" "$(field "${workspace}/prediction.json" lower_s)"
    expect_eq "prediction upper_s" "17.267" "$(field "${workspace}/prediction.json" upper_s)"
    "${TOP}/fit-line.bash" rehearsal "${FIX}/fit/stops.jsonl" "${workspace}/rehearsal.txt"
    expect_eq "rehearsal a0_s" "3.08333" "$(kv "${workspace}/rehearsal.txt" a0_s)"
    expect_eq "rehearsal b0_s_per_pv" "0.00466667" "$(kv "${workspace}/rehearsal.txt" b0_s_per_pv)"
    grep -v '"main-3000"' "${FIX}/fit/stops.jsonl" | sed 's/"duration_s": 14.1/"duration_s": 14.1, "qualifier": "overlap"/' > "${workspace}/few.jsonl"
    awk '/"main-903"/ && ++n == 1 { sub(/"cell": "main-903"/, "\"cell\": \"main-3000\""); sub(/"n_pvs": 903/, "\"n_pvs\": 3000") } { print }' "${workspace}/few.jsonl" > "${workspace}/few2.jsonl"
    expect_eq "line with one usable stop of a cell" "2" "$(status_of few "${TOP}/fit-line.bash" line "${workspace}/few2.jsonl")"
    grep '"main-903"' "${FIX}/fit/stops.jsonl" | head -n 1 > "${workspace}/one.jsonl"
    expect_eq "predict with one stop" "2" "$(status_of predict-one "${TOP}/fit-line.bash" predict "${workspace}/one.jsonl" "${workspace}/p1.json")"
    sed -e 's/"duration_s": 20.2/"duration_s": 10.2/' -e 's/"duration_s": 21.0/"duration_s": 11.0/' -e 's/"duration_s": 19.4/"duration_s": 9.4/' \
        "${FIX}/fit/stops.jsonl" > "${workspace}/negative.jsonl"
    "${TOP}/fit-line.bash" line "${workspace}/negative.jsonl" "${workspace}/negative.txt"
    expect_eq "slope not positive: pvs_at_timeout" "none" "$(kv "${workspace}/negative.txt" pvs_at_timeout)"
    # The published Student quantiles t(0.975, df), df 1 to 30.
    tbl="12.706 4.303 3.182 2.776 2.571 2.447 2.365 2.306 2.262 2.228 2.201 2.179 2.160 2.145 2.131 2.120 2.110 2.101 2.093 2.086 2.080 2.074 2.069 2.064 2.060 2.056 2.052 2.048 2.045 2.042"
    t=""
    for ((n = 2; n <= 31; n++)); do
        : > "${workspace}/tq.jsonl"
        for ((i = 1; i <= n; i++)); do
            printf '{"cell": "main-903", "n_pvs": 903, "duration_s": %d.%d, "c1": "Passed"}\n' $((10 + i % 3)) "${i}" >> "${workspace}/tq.jsonl"
        done
        "${TOP}/fit-line.bash" predict "${workspace}/tq.jsonl" "${workspace}/tq.json"
        t+=" $(awk '{ match($0, /"t": [0-9.]+/); printf "%.3f", substr($0, RSTART + 5, RLENGTH - 5) }' "${workspace}/tq.json")"
    done
    expect_eq "Student quantiles for df 1 to 30" "${tbl}" "${t# }"
}

function test_c3 {
    why "The validation stop of 13 s is Passed inside and on the interval, Failed outside, Incomplete without it."
    local d
    d="$(copy_stop stop-04-validation c3-inside)"
    expect_eq "C3 inside: status" "0" "$(judge "${d}")"
    d="$(copy_stop stop-04-validation c3-edge)"; sed -i 's/^prediction_lower_s=.*/prediction_lower_s=13/' "${d}/meta.env"
    expect_eq "C3 on the lower end: status" "0" "$(judge "${d}")"
    d="$(copy_stop stop-04-validation c3-outside)"; sed -i -e 's/^prediction_lower_s=.*/prediction_lower_s=14/' -e 's/^prediction_upper_s=.*/prediction_upper_s=20/' "${d}/meta.env"
    expect_eq "C3 outside: status" "1" "$(judge "${d}")"
    expect_eq "C3 outside: c3" "Failed" "$(field "${workspace}/out/judge-c3-outside.out" c3)"
    d="$(copy_stop stop-04-validation c3-none)"; sed -i '/^prediction_/d' "${d}/meta.env"
    expect_eq "C3 without the prediction: status" "2" "$(judge "${d}")"
}

function test_run_stop {
    why "run-stop refuses with status 3 before any side effect, and --judge exits with the verdict of the folder."
    local common=() co="${workspace}/checkout"
    printf 'pv,group,scan,method,period,policy,store_key\r\nA:B,g,1 second,MONITOR,1.0,,A/B\r\n' > "${workspace}/pvs.csv"
    common=(--run selftest --stop 1 --stage 1 --partition PARTITION_5MIN --hold 2
        --evidence "${workspace}/evidence" --pv-list "${workspace}/pvs.csv" --expectation "${FIX}/fit/expectation.jsonl")
    expect_eq "run-stop without options" "3" "$(status_of rs-usage "${TOP}/run-stop.bash")"
    expect_eq "run-stop with an unknown cell" "3" "$(status_of rs-cell "${TOP}/run-stop.bash" --cell main-1 "${common[@]}")"
    expect_eq "run-stop with a bad stop number" "3" "$(status_of rs-stop "${TOP}/run-stop.bash" --cell main-903 "${common[@]}" --stop x)"
    expect_eq "run-stop main cell with a prediction" "3" "$(status_of rs-pred "${TOP}/run-stop.bash" --cell main-903 "${common[@]}" --prediction "${FIX}/fit/prediction.json")"
    expect_eq "run-stop validation without a prediction" "3" "$(status_of rs-nopred "${TOP}/run-stop.bash" --cell validation-903 "${common[@]}")"
    expect_eq "run-stop without the guard file" "3" \
        "$(STOP_TIME_GUARD_FILE="${workspace}/absent" status_of rs-guard "${TOP}/run-stop.bash" --cell main-903 "${common[@]}" --dry-run)"
    expect_eq "run-stop guard message" "1" "$(grep -c 'guard file' "${workspace}/out/rs-guard.err")"
    STOP_TIME_GUARD_FILE="${workspace}/absent" status_of rs-rehearsal "${TOP}/run-stop.bash" --cell rehearsal-25 "${common[@]}" --dry-run > /dev/null
    expect_eq "run-stop rehearsal cell reaches the guard" "1" "$(grep -c 'guard file' "${workspace}/out/rs-rehearsal.err")"
    mkdir -p "${co}/env"
    cp -r "${TOP}/../../Makefile" "${TOP}/../../configure" "${co}/env/"
    printf 'ARCHAPPL_STORAGE_TOP=/srv/stop-time-selftest\n' > "${co}/CONFIG_SITE.local"
    : > "${workspace}/guard"
    expect_eq "run-stop with a wrong ARCHAPPL_STORAGE_TOP" "3" \
        "$(STOP_TIME_GUARD_FILE="${workspace}/guard" STOP_TIME_CHECKOUT="${co}/env" status_of rs-top "${TOP}/run-stop.bash" --cell main-903 "${common[@]}" --dry-run)"
    expect_eq "run-stop storage message" "1" "$(grep -c "is '/srv/stop-time-selftest', not /arch" "${workspace}/out/rs-top.err")"
    expect_eq "no evidence written on refusal" "absent" "$([[ -e "${workspace}/evidence" ]] && echo present || echo absent)"
    local name want
    for name in stop-01-passed:0 stop-02-timeout:1 stop-03-incomplete:2; do
        want="${name##*:}"; name="${name%%:*}"
        expect_eq "run-stop --judge ${name}" "${want}" "$(status_of "rs-judge-${name}" "${TOP}/run-stop.bash" --judge "${FIX}/run-synthetic/${name}")"
    done
}

function test_rebuild_and_compare {
    why "The rebuild on a copy leaves the originals byte-identical and agrees with the recorded table."
    local copy="${workspace}/replay" before after rc
    before="$(cd "${FIX}" && find . -type f -printf '%P\n' | LC_ALL=C sort | xargs sha256sum | sha256sum)"
    cp -r "${FIX}/run-synthetic" "${copy}"
    expect_eq "rebuild-table on the copy" "0" "$(status_of rebuild "${TOP}/rebuild-table.bash" "${copy}" "${workspace}/rebuilt.jsonl")"
    after="$(cd "${FIX}" && find . -type f -printf '%P\n' | LC_ALL=C sort | xargs sha256sum | sha256sum)"
    expect_eq "fixtures unchanged" "${before}" "${after}"
    expect_eq "rebuilt records" "$(wc -l < "${FIX}/run-synthetic/stops.jsonl")" "$(wc -l < "${workspace}/rebuilt.jsonl")"
    if [[ -r "${COMPARE_EVIDENCE}" ]] && command -v python3 > /dev/null; then
        rc="$(status_of compare python3 -B "${COMPARE_EVIDENCE}" --config "${TOP}/stops-contract.json" \
            --expected "${FIX}/run-synthetic/stops.jsonl" --actual "${workspace}/rebuilt.jsonl")"
        expect_eq "compare-evidence.py verdict" "0" "${rc}"
        sed 's/"duration_s": 13,/"duration_s": 13.5,/' "${workspace}/rebuilt.jsonl" > "${workspace}/rebuilt-changed.jsonl"
        expect_eq "compare-evidence.py on a changed duration" "1" "$(status_of compare-changed python3 -B "${COMPARE_EVIDENCE}" \
            --config "${TOP}/stops-contract.json" --expected "${FIX}/run-synthetic/stops.jsonl" --actual "${workspace}/rebuilt-changed.jsonl")"
    else
        mark_incomplete "compare-evidence.py or python3 is not available (${COMPARE_EVIDENCE})"
    fi
}

trap _handle_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

function main {
    [[ $# -eq 0 ]] || { sed -n '4,7p' "${BASH_SOURCE[0]}" >&2; exit 3; }
    workspace="$(mktemp -d "${TMPDIR:-/tmp}/stop-time-selftest.XXXXXX")"
    mkdir -p "${workspace}/out" "${workspace}/stops"
    test_fixture_verdicts
    test_parser_variants
    test_time_handling
    test_gen_pvs
    test_fit_line
    test_c3
    test_run_stop
    test_rebuild_and_compare
    TEST_COMPLETE=1
}

main "$@"
