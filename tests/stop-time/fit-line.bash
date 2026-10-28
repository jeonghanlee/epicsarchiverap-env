#!/usr/bin/env bash
# Fit the stop time of the unit over the PV count, and derive the expectation
# and the prediction of the measurement in tests/stop-time/README.md.
# Usage:
#   fit-line.bash rehearsal <stops.jsonl> [<output>]   a0 and b0 from the rehearsal stops
#   fit-line.bash expect <rehearsal-fit> <output>      expectation.jsonl of the main cells
#   fit-line.bash line <stops.jsonl> [<output>]        the line of the main cells
#   fit-line.bash predict <stops.jsonl> <output>       prediction.json of the validation stop
#   fit-line.bash check <stops.jsonl> <recorded-fit>   exit 0 when the line text is equal
# A stop enters a fit when its record has no qualifier and C1 is Passed.
# Exit status: 0 done, 1 check differs, 2 too few stops (Incomplete), 3 usage.
# The arithmetic runs in POSIX awk; the outputs are rounded to 6 significant digits.

set -euo pipefail

TIMEOUT_S="${TIMEOUT_S:-300}"
readonly TIMEOUT_S

function usage {
    sed -n '4,9p' "${BASH_SOURCE[0]}" >&2
    exit 3
}

# Shared awk code: a reader for the flat one-line JSON records of stops.jsonl,
# and the Student quantile t(0.975, df) for df 1 to 30 (published table values;
# source: any standard table of the t distribution, two-sided 95 percent).
readonly AWK_LIB='
function jget(line, key,    re, m, v) {
    re = "\"" key "\"[ ]*:[ ]*"
    if (!match(line, re)) return ""
    v = substr(line, RSTART + RLENGTH)
    if (substr(v, 1, 1) == "\"") {
        v = substr(v, 2)
        m = index(v, "\"")
        return substr(v, 1, m - 1)
    }
    if (match(v, /^[-+0-9.eE]+/)) return substr(v, 1, RLENGTH)
    return ""
}
function tq(df) {
    split("12.706 4.303 3.182 2.776 2.571 2.447 2.365 2.306 2.262 2.228 2.201 2.179 2.160 2.145 2.131 2.120 2.110 2.101 2.093 2.086 2.080 2.074 2.069 2.064 2.060 2.056 2.052 2.048 2.045 2.042", T, " ")
    if (df < 1 || df > 30) return ""
    return T[df] + 0
}
function r6(x) { return sprintf("%.6g", x) }
function usable(line) {
    return (jget(line, "qualifier") == "" && jget(line, "c1") == "Passed" && jget(line, "duration_s") != "")
}
'

function fit_rehearsal {
    awk -v OFS='=' "${AWK_LIB}"'
    usable($0) && jget($0, "cell") ~ /^rehearsal/ {
        n++; x[n] = jget($0, "n_pvs") + 0; y[n] = jget($0, "duration_s") + 0
    }
    END {
        if (n < 3) { print "status", "incomplete"; print "n_stops", n + 0; exit 2 }
        for (i = 1; i <= n; i++) { sx += x[i]; sy += y[i] }
        mx = sx / n; my = sy / n
        for (i = 1; i <= n; i++) { sxx += (x[i] - mx) ^ 2; sxy += (x[i] - mx) * (y[i] - my) }
        if (sxx == 0) { print "status", "incomplete"; print "n_stops", n; exit 2 }
        b = sxy / sxx; a = my - b * mx
        print "status", "fitted"
        print "n_stops", n
        print "a0_s", r6(a)
        print "b0_s_per_pv", r6(b)
    }' "$1"
}

function write_expect {
    local fit="$1" out="$2" a0 b0
    a0=$(sed -n 's/^a0_s=//p' "${fit}")
    b0=$(sed -n 's/^b0_s_per_pv=//p' "${fit}")
    [[ -n "${a0}" && -n "${b0}" ]] || { printf 'fit-line: no a0 and b0 in %s\n' "${fit}" >&2; exit 2; }
    awk -v a0="${a0}" -v b0="${b0}" 'BEGIN {
        n["main-903"] = 903; n["main-3000"] = 3000
        split("main-903 main-3000", order, " ")
        for (i = 1; i <= 2; i++) {
            c = order[i]
            printf "{\"cell\": \"%s\", \"n_pvs\": %d, \"expected_s\": %.6g, \"a0_s\": %.6g, \"b0_s_per_pv\": %.6g}\n", c, n[c], a0 + n[c] * b0, a0, b0
        }
    }' > "${out}"
}

function fit_line {
    awk -v OFS='=' -v timeout="${TIMEOUT_S}" "${AWK_LIB}"'
    {
        cell = jget($0, "cell")
        if (cell == "validation-903" && usable($0)) {
            vn++; vratio += (jget($0, "etl_gap_s") + 0) / (jget($0, "n_pvs") + 0)
        }
        if (cell != "main-903" && cell != "main-3000") next
        sm = jget($0, "slowest_ms_max"); if (sm != "" && sm + 0 > slow[cell]) slow[cell] = sm + 0
        pd = jget($0, "pass_duration_max_s"); if (pd != "" && pd + 0 > pass[cell]) pass[cell] = pd + 0
        if (!usable($0)) next
        n++; x[n] = jget($0, "n_pvs") + 0; y[n] = jget($0, "duration_s") + 0
        cn[cell]++; cs[cell] += y[n]
        if (!(cell in cmin) || y[n] < cmin[cell]) cmin[cell] = y[n]
        if (!(cell in cmax) || y[n] > cmax[cell]) cmax[cell] = y[n]
        if (cell == "main-903") { m9n++; m9r += (jget($0, "etl_gap_s") + 0) / x[n] }
    }
    END {
        if (cn["main-903"] < 2 || cn["main-3000"] < 2) {
            print "status", "incomplete"
            print "stops_main_903", cn["main-903"] + 0
            print "stops_main_3000", cn["main-3000"] + 0
            exit 2
        }
        for (i = 1; i <= n; i++) { sx += x[i]; sy += y[i] }
        mx = sx / n; my = sy / n
        for (i = 1; i <= n; i++) { sxx += (x[i] - mx) ^ 2; sxy += (x[i] - mx) * (y[i] - my) }
        b = sxy / sxx; a = my - b * mx
        for (i = 1; i <= n; i++) sse += (y[i] - a - b * x[i]) ^ 2
        df = n - 2; t = tq(df)
        se = sqrt(sse / df / sxx)
        print "status", "fitted"
        print "timeout_s", timeout
        split("main-903 main-3000", order, " ")
        for (k = 1; k <= 2; k++) {
            c = order[k]
            print c "_stops", cn[c]
            print c "_mean_s", r6(cs[c] / cn[c])
            print c "_min_s", r6(cmin[c])
            print c "_max_s", r6(cmax[c])
            print c "_slowest_ms_max", r6(slow[c] + 0)
            print c "_pass_duration_max_s", r6(pass[c] + 0)
        }
        print "df", df
        print "t", t
        print "intercept_s", r6(a)
        print "slope_s_per_pv", r6(b)
        print "slope_se", r6(se)
        print "slope_low", r6(b - t * se)
        print "slope_high", r6(b + t * se)
        bh = b + t * se
        split("1 0.8", frac, " ")
        split("timeout 80pct", fname, " ")
        for (k = 1; k <= 2; k++) {
            target = timeout * frac[k]
            print "pvs_at_" fname[k], (b > 0 ? r6((target - a) / b) : "none")
            print "pvs_at_" fname[k] "_cautious", (bh > 0 ? r6((target - a) / bh) : "none")
        }
        split("5000 10000 20000 50000", at, " ")
        for (k = 1; k <= 4; k++) {
            print "stop_s_at_" at[k], r6(a + b * at[k])
            print "stop_s_at_" at[k] "_cautious", r6(a + bh * at[k])
        }
        if (vn > 0 && m9n > 0) print "validation_etl_gap_per_pv_ratio", r6((vratio / vn) / (m9r / m9n))
    }' "$1"
}

function write_predict {
    local stops="$1" out="$2" body rc=0
    body=$(awk "${AWK_LIB}"'
    usable($0) && jget($0, "cell") == "main-903" { n++; y[n] = jget($0, "duration_s") + 0 }
    END {
        if (n < 2) exit 2
        for (i = 1; i <= n; i++) s += y[i]
        m = s / n
        for (i = 1; i <= n; i++) v += (y[i] - m) ^ 2
        sd = sqrt(v / (n - 1)); t = tq(n - 1)
        h = t * sd * sqrt(1 + 1 / n)
        printf "{\"cell\": \"validation-903\", \"n_stops\": %d, \"mean_s\": %s, \"sd_s\": %s, \"t\": %s, \"lower_s\": %s, \"upper_s\": %s}\n", n, r6(m), r6(sd), t, r6(m - h), r6(m + h)
    }' "${stops}") || rc=$?
    if [[ ${rc} -ne 0 ]]; then
        printf 'fit-line: fewer than two usable stops of main-903; the prediction is Incomplete\n' >&2
        exit 2
    fi
    printf '%s\n' "${body}" > "${out}"
}

function main {
    [[ $# -ge 2 ]] || usage
    local command="$1" input="$2" output="${3:-}"
    [[ -r "${input}" ]] || { printf 'fit-line: cannot read %s\n' "${input}" >&2; exit 3; }
    case "${command}" in
        rehearsal)
            if [[ -n "${output}" ]]; then fit_rehearsal "${input}" > "${output}"; else fit_rehearsal "${input}"; fi ;;
        expect)
            [[ -n "${output}" ]] || usage
            write_expect "${input}" "${output}" ;;
        line)
            if [[ -n "${output}" ]]; then fit_line "${input}" > "${output}"; else fit_line "${input}"; fi ;;
        predict)
            [[ -n "${output}" ]] || usage
            write_predict "${input}" "${output}" ;;
        check)
            [[ -n "${output}" && -r "${output}" ]] || usage
            local fresh rc=0
            fresh=$(fit_line "${input}") || rc=$?
            [[ ${rc} -eq 0 ]] || exit "${rc}"
            if [[ "${fresh}" == "$(cat "${output}")" ]]; then exit 0; fi
            diff <(printf '%s\n' "${fresh}") "${output}" >&2 || true
            exit 1 ;;
        *) usage ;;
    esac
}

main "$@"
