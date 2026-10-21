#!/usr/bin/env bash
# Archive the PVs of one stage of the stop time measurement and wait until the
# appliance archives every one of them (tests/stop-time/README.md).
#
# Purpose: after a reset the appliance archives nothing. This script sends the
# PVs of the given lists in one archivePV POST, as the measurement requires,
# and returns only when getPVStatus shows every PV "Being archived" with
# connectionState true, which is the readiness that run-stop.bash also checks.
#
# Usage:
#   archive-stage.bash [--dry-run] <output folder> <pv-list.csv> [<pv-list.csv> ...]
#
# Each PV list has the columns pv, group, scan, method, period, policy and
# store_key (a trailing CR is stripped). A PV is sent with "pv",
# "samplingperiod" (column period), "samplingmethod" (column method) and
# "policy" when the column is not empty.
#
# Files written into <output folder>:
#   archivePV.json     the request body
#   archivePV.utc      the time of the request
#   archivePV.http     the HTTP status of the request
#   archivePV.reply    the reply of the appliance
#   getPVStatus.json   the last status read
#   ready.utc          the time at which every PV was ready
#
# --dry-run writes archivePV.json only and sends nothing.
#
# Environment: MGMT_URL (default http://localhost:17665/mgmt/bpl) and
# READY_LIMIT_S (default 1200), the longest wait for readiness in seconds.
#
# Exit status: 0 every PV ready (or the body written with --dry-run), 1 the POST
# failed, 2 not every PV ready within READY_LIMIT_S, 3 usage.

set -euo pipefail

readonly MGMT_URL="${MGMT_URL:-http://localhost:17665/mgmt/bpl}"
readonly READY_LIMIT_S="${READY_LIMIT_S:-1200}"

function usage {
    sed -n '9,11p' "${BASH_SOURCE[0]}" >&2
    exit 3
}

function utc_now {
    date -u +%Y-%m-%dT%H:%M:%S.%6NZ
}

# The JSON array of the archivePV request from the PV lists.
function write_body {
    awk -F',' '
        FNR == 1 {
            for (i = 1; i <= NF; i++) { h = $i; sub(/\r$/, "", h); col[h] = i }
            if (!("pv" in col) || !("method" in col) || !("period" in col) || !("policy" in col)) {
                printf "archive-stage: %s lacks a column pv, method, period or policy\n", FILENAME > "/dev/stderr"
                bad = 1; exit 3
            }
            next
        }
        {
            sub(/\r$/, "")
            if ($col["pv"] == "") next
            printf "%s{\"pv\": \"%s\", \"samplingperiod\": \"%s\", \"samplingmethod\": \"%s\"%s}", \
                (n++ ? ", " : "["), $col["pv"], $col["period"], $col["method"], \
                ($col["policy"] != "" ? ", \"policy\": \"" $col["policy"] "\"" : "")
        }
        END { if (!bad) print (n ? "]" : "[]") }' "$@"
}

# Count of the PVs with exactly one entry "Being archived" and connected.
function count_ready {
    awk 'BEGIN { RS = "}" }
        {
            if (!match($0, /"pvName" *: *"[^"]*"/)) next
            pv = substr($0, RSTART, RLENGTH); sub(/^"pvName" *: *"/, "", pv); sub(/"$/, "", pv)
            n[pv]++
            if ($0 ~ /"status" *: *"Being archived"/ && $0 ~ /"connectionState" *: *"?true"?/) ok[pv]++
        }
        END { for (pv in n) if (n[pv] == 1 && ok[pv] == 1) good++; print good + 0 }' "$1"
}

function main {
    local dry_run=0 out want i got http list
    if [[ "${1:-}" == "--dry-run" ]]; then
        dry_run=1
        shift
    fi
    [[ $# -ge 2 ]] || usage
    out="$1"
    shift
    for list in "$@"; do
        [[ -r "${list}" ]] || { printf 'archive-stage: cannot read %s\n' "${list}" >&2; exit 3; }
    done
    mkdir -p "${out}"
    write_body "$@" > "${out}/archivePV.json" || exit 3
    want="$(awk -F',' 'FNR > 1 { sub(/\r$/, ""); if ($1 != "") n++ } END { print n + 0 }' "$@")"
    if [[ ${dry_run} -eq 1 ]]; then
        printf 'archive-stage: wrote %s with %s PVs; nothing sent\n' "${out}/archivePV.json" "${want}"
        return 0
    fi
    utc_now > "${out}/archivePV.utc"
    http="$(curl -sS -o "${out}/archivePV.reply" -w '%{http_code}' -H 'Content-Type: application/json' \
        --data-binary @"${out}/archivePV.json" "${MGMT_URL}/archivePV")" || http="000"
    printf '%s\n' "${http}" > "${out}/archivePV.http"
    printf 'archive-stage: archivePV HTTP %s for %s PVs\n' "${http}" "${want}"
    [[ "${http}" == "200" ]] || exit 1
    for ((i = 0; i * 10 < READY_LIMIT_S; i++)); do
        if curl -fsS "${MGMT_URL}/getPVStatus" > "${out}/getPVStatus.json"; then
            got="$(count_ready "${out}/getPVStatus.json")"
            if [[ "${got}" -eq "${want}" ]]; then
                utc_now > "${out}/ready.utc"
                printf 'archive-stage: %s of %s PVs ready\n' "${got}" "${want}"
                return 0
            fi
        fi
        sleep 10
    done
    printf 'archive-stage: %s of %s PVs ready after %s s\n' "${got:-0}" "${want}" "${READY_LIMIT_S}" >&2
    exit 2
}

main "$@"
