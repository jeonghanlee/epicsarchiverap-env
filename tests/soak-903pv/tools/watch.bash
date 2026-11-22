#!/usr/bin/env bash
# Read-only watchdog of the 24-hour run on the guest: checks the units, the JVM count, the age and content of the
# last collector row every WATCH_INTERVAL seconds, appends one line per check to the log, and exits with an ALERT
# line at the first deviation or with a WATCH-END line after the end of the run.
set -u

readonly GUEST='<user>@<guest-address>'
readonly LOG='<work-dir>/watch.log'
readonly COLLECTOR_UNTIL='2026-11-21T23:53:16Z'
readonly WATCH_END='2026-11-22T00:10:00Z'
readonly WATCH_INTERVAL=600
readonly MAX_ROW_AGE=900
readonly MIN_DISK_GB=10
readonly PV_COUNT=903
readonly JAVA_COUNT=4

# Prints the facts of one check as key=value lines; every command only reads.
remote_check() {
    ssh -o BatchMode=yes -o ConnectTimeout=20 "$GUEST" 'export XDG_RUNTIME_DIR=/run/user/$(id -u); cd ~/rv15/run
printf "collector=%s\nioc=%s\napp=%s\njava=%s\n" "$(systemctl --user is-active rv15-collector.service)" "$(systemctl --user is-active epics-@aasoak-soak.service)" "$(systemctl is-active epicsarchiverap-maven.service)" "$(pgrep -u tomcat java | wc -l)"
printf "row_age=%s\nrows=%s\n" "$(( $(date +%s) - $(stat -c %Y evidence/soak-log.csv) ))" "$(( $(wc -l < evidence/soak-log.csv) - 1 ))"
python3 -c "
import csv
rows = list(csv.DictReader(open(\"evidence/soak-log.csv\", newline=\"\")))
r = rows[-1]
for k in (\"utc\", \"being_archived\", \"connected\", \"disconnected\", \"dropped_buffer\", \"dropped_timestamp\", \"dropped_type_change\", \"stale_changing_pvs\", \"samples_ok\", \"disk_avail_gb\", \"error\"):
    print(k + \"=\" + str(r[k]))
"'
}

alerts=()

# Adds an alert text when the named fact differs from its expectation.
expect() {
    local name=$1 expected=$2
    [[ "${fact[$name]-missing}" == "$expected" ]] || alerts+=("$name=${fact[$name]-missing} expected $expected")
    return 0
}

end_epoch=$(date -u -d "$WATCH_END" +%s)
until_epoch=$(date -u -d "$COLLECTOR_UNTIL" +%s)
while (( $(date -u +%s) < end_epoch )); do
    if ! output=$(remote_check 2>&1); then
        printf '%s ALERT check failed: %s\n' "$(date -u +%FT%TZ)" "$output" | tee -a "$LOG"
        exit 1
    fi
    declare -A fact=()
    while IFS='=' read -r key value; do
        fact[$key]=$value
    done <<< "$output"
    alerts=()
    expect ioc active
    expect app active
    expect java "$JAVA_COUNT"
    expect being_archived "$PV_COUNT"
    expect connected "$PV_COUNT"
    expect disconnected 0
    expect dropped_buffer 0
    expect dropped_timestamp 0
    expect dropped_type_change 0
    expect stale_changing_pvs 0
    expect samples_ok 6
    expect error ''
    if (( $(date -u +%s) < until_epoch )); then
        expect collector active
        (( ${fact[row_age]:-99999} <= MAX_ROW_AGE )) || alerts+=("row_age=${fact[row_age]:-missing} above $MAX_ROW_AGE")
    fi
    (( ${fact[disk_avail_gb]:-0} >= MIN_DISK_GB )) || alerts+=("disk_avail_gb=${fact[disk_avail_gb]:-missing} below $MIN_DISK_GB")
    printf '%s check rows=%s last=%s collector=%s ioc=%s app=%s java=%s archived=%s connected=%s samples_ok=%s disk_gb=%s\n' \
        "$(date -u +%FT%TZ)" "${fact[rows]:-?}" "${fact[utc]:-?}" "${fact[collector]:-?}" "${fact[ioc]:-?}" "${fact[app]:-?}" \
        "${fact[java]:-?}" "${fact[being_archived]:-?}" "${fact[connected]:-?}" "${fact[samples_ok]:-?}" "${fact[disk_avail_gb]:-?}" >> "$LOG"
    if (( ${#alerts[@]} > 0 )); then
        printf '%s ALERT %s\n' "$(date -u +%FT%TZ)" "${alerts[*]}" | tee -a "$LOG"
        exit 1
    fi
    sleep "$WATCH_INTERVAL"
done
printf '%s WATCH-END no deviation seen until %s\n' "$(date -u +%FT%TZ)" "$WATCH_END" | tee -a "$LOG"
