#!/usr/bin/env bash
# Rebuild the table of the stop time measurement from the raw files of the stops.
# Usage:
#   rebuild-table.bash <run folder> <output.jsonl>   one record for every stop folder
#   rebuild-table.bash --stop <stop folder>          one record on stdout, exit with its verdict
# A stop folder holds the files that run-stop.bash writes (see README.md, Stop folder).
# The record keeps the claims C1, C2 and C3 of the README; a key without a value
# is left out of the record.
# Exit status of --stop: 0 Passed, 1 Failed, 2 Incomplete, 3 usage or tool error.

set -euo pipefail

readonly STOP_FILES="meta.env unit.txt stop-exit.txt keys.txt journal.txt journal.bounds etl-pass.size etl-pass.cut etl-pass.records listing-before.txt listing-after.txt"

function usage {
    sed -n '3,5p' "${BASH_SOURCE[0]}" >&2
    exit 3
}

# The judgement of one stop folder. All time stamps are UTC: the journal is cut
# with TZ=UTC, the log pattern writes Z, the unit is read with --timestamp=us+utc.
# shellcheck disable=SC2016  # awk fields, not shell expansions
readonly AWK_STOP='
function civil(y, m, d,    era, yoe, doy, doe) {
    y -= (m <= 2)
    era = int((y >= 0 ? y : y - 399) / 400)
    yoe = y - era * 400
    doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
    doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
    return era * 146097 + doe - 719468
}
# "2026-10-19T20:00:05.123456+00:00", "2026-10-19T20:00:05.123Z"
# or "Mon 2026-10-19 20:00:05.123456 UTC" (systemctl show --timestamp=us+utc)
function epoch(ts,    d, t, D, H) {
    if (ts == "" || ts == "null") return ""
    sub(/^[A-Za-z][A-Za-z][A-Za-z] /, "", ts)
    if (ts !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][T ][0-9][0-9]:[0-9][0-9]:[0-9][0-9]/) return ""
    d = substr(ts, 1, 10); t = substr(ts, 12)
    sub(/(Z|[+-]00:00| UTC)$/, "", t)
    split(d, D, "-"); split(t, H, ":")
    return civil(D[1] + 0, D[2] + 0, D[3] + 0) * 86400 + H[1] * 3600 + H[2] * 60 + H[3]
}
# "Mon 2026-10-19 20:00:05.123456 UTC" -> "2026-10-19T20:00:05.123456Z"
function isoz(ts) {
    sub(/^[A-Za-z][A-Za-z][A-Za-z] /, "", ts)
    if (sub(/ UTC$/, "Z", ts)) sub(/ /, "T", ts)
    return ts
}
function stamped(line) { return line ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T/ }
function rec(line, key,    v) {
    if (!match(line, "[[ ]" key "=[^,]*")) return ""
    v = substr(line, RSTART + length(key) + 2, RLENGTH - length(key) - 2)
    sub(/\]$/, "", v)
    return v
}
function q(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return "\"" s "\"" }
function add(k, v, isnum) {
    if (v == "") return
    out = out (out == "" ? "" : ", ") q(k) ": " (isnum ? v : q(v))
}
function miss(what) { missing = missing " " what }
function r6(x) { return sprintf("%.6g", x) }
function key_of(path,    p) {
    p = path; sub(/.*\/ArchiverStore\//, "", p); sub(/:[^:\/]*\.pb$/, "", p); return p
}
function base(f) { sub(/.*\//, "", f); return f }
{ sub(/\r$/, "") }
base(FILENAME) == "meta.env" { split($0, kv, "="); meta[kv[1]] = substr($0, length(kv[1]) + 2); next }
base(FILENAME) == "unit.txt" { split($0, kv, "="); unit[kv[1]] = substr($0, length(kv[1]) + 2); next }
base(FILENAME) == "journal.bounds" { split($0, kv, "="); bounds[kv[1]] = substr($0, length(kv[1]) + 2); next }
base(FILENAME) ~ /^status\./ { split($0, kv, "="); stat[kv[1]] = substr($0, length(kv[1]) + 2); next }
base(FILENAME) == "etl-pass.size" { split($0, kv, "="); size[kv[1]] = substr($0, length(kv[1]) + 2); next }
base(FILENAME) == "stop-exit.txt" { if ($1 ~ /^[0-9]+$/) stop_exit = $1; next }
base(FILENAME) == "keys.txt" { if ($0 != "") { keys[$0] = 1; nkeys++ } ; next }
base(FILENAME) == "journal.txt" {
    if (!stamped($0)) next
    if (match($0, /archappl-(engine|retrieval|etl|mgmt): stopping pid [0-9]+/)) {
        svc = substr($0, RSTART + 9); sub(/:.*/, "", svc)
        jl[++njl] = svc; jlt[njl] = epoch($1)
    }
    next
}
base(FILENAME) == "etl-pass.cut" {
    if (!stamped($0)) next
    ts = epoch($1)
    if (index($0, "Shutting down ETL threads.")) shutdown = ts
    if (match($0, /Need to consolidate data from etl source [^ ]+ for pv [^ ]+/)) {
        nj++; jt[nj] = ts; split(substr($0, RSTART, RLENGTH), w, " "); jpv[nj] = w[11]
    }
    next
}
# The pass records of the whole etl-pass.log: a record is written at the end of
# its pass, so the passes around a stop are not all in the cut of the stop.
base(FILENAME) == "etl-pass.records" {
    if (!stamped($0)) next
    if (index($0, "ETLPassRecord[")) {
        np++
        nreq = split("plannedAt startedAt endedAt pvCount jobsRun jobsFailed partitionsMoved bytesMoved slowestPv slowestMillis aborted", req, " ")
        for (i = 1; i <= nreq; i++) if (rec($0, req[i]) == "") badpass = badpass " " req[i]
        pplan[np] = epoch(rec($0, "plannedAt")); pstart[np] = epoch(rec($0, "startedAt"))
        pend[np] = epoch(rec($0, "endedAt"))
        psm[np] = rec($0, "slowestMillis") + 0
    }
    next
}
base(FILENAME) == "listing-before.txt" {
    if (NF != 4 || $2 !~ /^[0-9]+$/ || epoch($3) == "") { badlist = 1; next }
    k = key_of($4)
    if ((k in keys) && $1 == "sts") { before[k]++; bfiles++; bbytes += $2 }
    next
}
base(FILENAME) == "listing-after.txt" {
    if (NF != 4 || $2 !~ /^[0-9]+$/ || epoch($3) == "") { badlist = 1; next }
    k = key_of($4)
    if ((k in keys) && $1 == "sts") after[k]++
    next
}
END {
    missing = ""
    split(present, have, " ")
    for (i in have) got[have[i]] = 1
    split(nonempty, full, " ")
    for (i in full) filled[full[i]] = 1
    nall = split(required, all, " ")
    for (i = 1; i <= nall; i++) if (!(all[i] in got)) miss(all[i])
    if (!frozen) miss("frozen")
    split("ActiveExitTimestamp ActiveExitTimestampMonotonic InactiveEnterTimestamp InactiveEnterTimestampMonotonic Result InvocationID", need, " ")
    for (i = 1; i <= 6; i++) if (unit[need[i]] == "") miss("unit:" need[i])
    split("run cell stop n_pvs partition hold timeout_s e_used_utc", mneed, " ")
    for (i = 1; i <= 8; i++) if (("meta.env" in got) && meta[mneed[i]] == "") miss("meta:" mneed[i])
    if (("stop-exit.txt" in got) && stop_exit == "") miss("stop-exit")
    if (("keys.txt" in got) && nkeys == 0) miss("keys:empty")
    if (badlist) miss("listing:malformed")
    if ("journal.bounds" in got) {
        split("first_cursor first_utc last_cursor last_utc mode", bneed, " ")
        for (i = 1; i <= 5; i++) if (bounds[bneed[i]] == "") miss("journal.bounds:" bneed[i])
        if (bounds["mode"] != "" && bounds["mode"] != "cursor" && bounds["mode"] != "time") miss("journal.bounds:mode")
    }
    if ("etl-pass.size" in got) {
        if (size["before"] !~ /^[0-9]+$/ || size["after"] !~ /^[0-9]+$/) miss("etl-pass.size:value")
        else if (size["after"] + 0 < size["before"] + 0) miss("etl-pass:truncated")
    }
    # Launcher lines count only from the start of the stop; a cut that reaches
    # back before it holds the lines of earlier stops.
    axs = epoch(unit["ActiveExitTimestamp"])
    for (i = 1; i <= njl; i++) if (axs == "" || jlt[i] >= axs - 1) launch[jl[i]] = jlt[i]
    fb = epoch(bounds["first_utc"])
    if (fb != "" && axs != "" && fb < axs - 60) miss("journal.bounds:first-before-stop")
    result = unit["Result"]
    if (result != "timeout") {
        split("engine retrieval etl mgmt", svcs, " ")
        for (i = 1; i <= 4; i++) if (!(svcs[i] in launch)) miss("launcher:" svcs[i])
    }
    # A stop that the unit ended before the launcher reached the ETL instance has
    # no ETL lines by design; its cut may be empty.
    if (("etl-pass.cut" in got) && !("etl-pass.cut" in filled)) {
        if (result != "timeout" || ("etl" in launch)) miss("etl-pass.cut:empty")
    }
    else if (("etl-pass.cut" in got) && ("etl" in launch) && shutdown == "") miss("etl-pass.cut:shutdown-line")
    if (("etl-pass.records" in got) && np == 0) miss("etl-pass.records:empty")
    if (badpass != "") miss("pass-record:" substr(badpass, 2))
    c1 = (missing == "" ? "Passed" : "Incomplete")

    if (unit["InactiveEnterTimestampMonotonic"] ~ /^[0-9]+$/ && unit["ActiveExitTimestampMonotonic"] ~ /^[0-9]+$/)
        duration = (unit["InactiveEnterTimestampMonotonic"] - unit["ActiveExitTimestampMonotonic"]) / 1000000
    else duration = ""
    ax = epoch(unit["ActiveExitTimestamp"]); ie = epoch(unit["InactiveEnterTimestamp"])
    hold = meta["hold"] + 0; timeout = meta["timeout_s"] + 0
    have_before = ("listing-before.txt" in got); have_after = ("listing-after.txt" in got)

    # files of each PV and the keys that were consolidated or left
    offfiles = 0; cons = 0; left = 0
    for (k in keys) {
        if (before[k] + 0 != hold + 2) offfiles++
        if (before[k] + 0 > 0 && after[k] + 0 == 0) cons++
        if (after[k] + 0 > 0) left++
    }
    eu = epoch(meta["e_used_utc"])
    afterb = (eu != "" && ax != "" ? ax - eu : "")
    hi = (meta["partition"] == "PARTITION_5MIN" ? 60 : 90)
    qual = ""
    if ((have_before && offfiles > 0) || afterb == "" || afterb < 30 || afterb > hi) qual = "off-rule"
    # slowestMillis and the pass duration count the passes planned in the
    # accumulation of this stop: from (hold + 2) partitions before E, and not
    # before run-stop.bash started (start_utc of the status copy; etl-pass.log
    # runs on across resets, so earlier passes may belong to an earlier stage),
    # to the end of the unit.
    part = (meta["partition"] == "PARTITION_5MIN" ? 300 : (meta["partition"] == "PARTITION_15MIN" ? 900 : 3600))
    wstart = (eu != "" ? eu - (hold + 2) * part : "")
    st0 = epoch(stat["start_utc"])
    if (st0 != "" && wstart != "" && st0 > wstart) wstart = st0
    nwin = 0; slowest = 0; passmax = 0
    for (i = 1; i <= np; i++) {
        if (wstart == "" || ie == "" || pplan[i] == "" || pplan[i] < wstart || pplan[i] > ie) continue
        nwin++
        if (psm[i] > slowest) slowest = psm[i]
        if (pend[i] != "" && pend[i] - pstart[i] > passmax) passmax = pend[i] - pstart[i]
    }
    lim = (shutdown != "" ? shutdown + 5 : ie)
    for (i = 1; i <= np; i++) {
        running = (pstart[i] != "" && ax != "" && pstart[i] <= ax && (pend[i] == "" || pend[i] >= ax))
        planned = (pplan[i] != "" && ax != "" && pplan[i] >= ax && pplan[i] <= lim)
        if (running || planned) { qual = (qual == "" ? "overlap" : qual "+overlap"); break }
    }

    # jobs of the loop at the stop: K lines give K - 1 times
    jsum = 0; jmax = -1
    for (i = 1; i < nj; i++) {
        g = jt[i + 1] - jt[i]; gaps[i] = g; jsum += g
        if (g > jmax) { jmax = g; jmaxpv = jpv[i] }
    }
    ng = (nj > 1 ? nj - 1 : 0)
    if (ng > 0) {
        for (i = 1; i <= ng; i++) srt[i] = gaps[i]
        for (i = 2; i <= ng; i++) { v = srt[i]; j = i - 1; while (j >= 1 && srt[j] > v) { srt[j + 1] = srt[j]; j-- } ; srt[j + 1] = v }
        med = (ng % 2 ? srt[(ng + 1) / 2] : (srt[ng / 2] + srt[ng / 2 + 1]) / 2)
    }

    if (result != "" && result != "success") c2 = "Failed"
    else if (duration != "" && duration > timeout) c2 = "Failed"
    else if (have_after && !badlist && nkeys > 0 && left > 0) c2 = "Failed"
    else if (result == "" || duration == "" || !have_after || badlist || nkeys == 0) c2 = "Incomplete"
    else c2 = "Passed"
    c3 = ""
    if (meta["cell"] == "validation-903") {
        lo = meta["prediction_lower_s"]; up = meta["prediction_upper_s"]
        if (lo == "" || up == "" || duration == "") c3 = "Incomplete"
        else if (duration >= lo + 0 && duration <= up + 0) c3 = "Passed"
        else c3 = "Failed"
    }

    add("run", meta["run"]); add("cell", meta["cell"]); add("stop", meta["stop"])
    add("invocation_id", unit["InvocationID"])
    add("active_exit_utc", isoz(unit["ActiveExitTimestamp"])); add("inactive_enter_utc", isoz(unit["InactiveEnterTimestamp"]))
    add("n_pvs", meta["n_pvs"], 1); add("partition", meta["partition"]); add("hold", meta["hold"], 1)
    add("timeout_s", meta["timeout_s"], 1); add("stop_exit", stop_exit, 1)
    add("result", result)
    if (duration != "") add("duration_s", r6(duration), 1)
    if (afterb != "") add("after_boundary_s", r6(afterb), 1)
    if (have_before && nkeys > 0 && !badlist) {
        add("files_per_pv_expected", hold + 2, 1); add("pvs_off_file_count", offfiles, 1)
        add("sts_files", bfiles + 0, 1); add("sts_bytes", bbytes + 0, 1)
        add("sts_bytes_per_pv", r6(bbytes / nkeys), 1)
    }
    if (("engine" in launch) && ("retrieval" in launch)) add("engine_gap_s", r6(launch["retrieval"] - launch["engine"]), 1)
    if (("retrieval" in launch) && ("etl" in launch)) add("retrieval_gap_s", r6(launch["etl"] - launch["retrieval"]), 1)
    if (("etl" in launch) && ("mgmt" in launch)) add("etl_gap_s", r6(launch["mgmt"] - launch["etl"]), 1)
    if (("mgmt" in launch) && ie != "") add("mgmt_gap_s", r6(ie - launch["mgmt"]), 1)
    if (have_after && nkeys > 0 && !badlist) { add("consolidated_pvs", cons, 1); add("left_pvs", left, 1) }
    if ("etl-pass.cut" in got) add("loop_jobs", nj + 0, 1)
    if (ng > 0) {
        add("loop_sum_s", r6(jsum), 1); add("loop_mean_s", r6(jsum / ng), 1)
        add("loop_median_s", r6(med), 1); add("loop_max_s", r6(jmax), 1); add("loop_max_pv", jmaxpv)
    }
    if (result == "timeout" && nj > 0) add("sigkill_pv", jpv[nj])
    if (nwin > 0) { add("passes_in_window", nwin, 1); add("slowest_ms_max", slowest, 1); add("pass_duration_max_s", r6(passmax), 1) }
    add("qualifier", qual)
    add("c1", c1); add("c2", c2); add("c3", c3)
    if (missing != "") add("incomplete", substr(missing, 2))
    print "{" out "}"
    v = 0
    if (c2 == "Failed" || c3 == "Failed") v = 1
    else if (c1 != "Passed" || c2 != "Passed" || c3 == "Incomplete") v = 2
    exit v
}
'

# Print the record of one stop folder; the exit status is its verdict.
function stop_record {
    local folder="$1" f present="" nonempty="" frozen=0 rc=0
    local -a files=()
    for f in ${STOP_FILES}; do
        if [[ -f "${folder}/${f}" ]]; then
            [[ -r "${folder}/${f}" ]] || { printf 'rebuild-table: cannot read %s\n' "${folder}/${f}" >&2; return 3; }
            files+=("${folder}/${f}")
            present+=" ${f}"
            [[ -s "${folder}/${f}" ]] && nonempty+=" ${f}"
        fi
    done
    [[ -s "${folder}/frozen/SHA256SUMS" ]] && frozen=1
    # The status file as it was before the stop gives the start of run-stop.bash.
    for f in "${folder}"/status.*; do
        [[ -f "${f}" && -r "${f}" ]] && files+=("${f}")
    done
    awk -v required="${STOP_FILES}" -v present="${present}" -v nonempty="${nonempty}" -v frozen="${frozen}" \
        "${AWK_STOP}" "${files[@]}" /dev/null || rc=$?
    [[ ${rc} -le 2 ]] || { printf 'rebuild-table: awk failed on %s (status %d)\n' "${folder}" "${rc}" >&2; return 3; }
    return "${rc}"
}

function main {
    [[ $# -eq 2 ]] || usage
    if [[ "$1" == "--stop" ]]; then
        [[ -d "$2" ]] || usage
        stop_record "$2"
        return
    fi
    local run="$1" out="$2" folder rc
    [[ -d "${run}" ]] || usage
    : > "${out}"
    while IFS= read -r folder; do
        # A stop that ended before its record (no meta.env, or an ended.txt of
        # run-stop.bash) stays in the coverage table but not in the table.
        if [[ ! -f "${folder}/meta.env" || -f "${folder}/ended.txt" ]]; then
            printf 'rebuild-table: not recorded: %s (%s)\n' "${folder##*/}" \
                "$(paste -sd' ' "${folder}/ended.txt" 2> /dev/null || echo 'no ended.txt')" >&2
            continue
        fi
        rc=0
        stop_record "${folder}" >> "${out}" || rc=$?
        [[ ${rc} -le 2 ]] || { printf 'rebuild-table: failed on %s\n' "${folder}" >&2; exit 3; }
    done < <(find "${run}" -mindepth 1 -maxdepth 1 -type d -name 'stop-*' | LC_ALL=C sort)
}

main "$@"
