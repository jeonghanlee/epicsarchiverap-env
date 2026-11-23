#!/usr/bin/env bash
# Read-only watchdog of the 2-hour rehearsal: every WATCH_INTERVAL seconds it checks the guest services, the four
# appliance JVM identities, the accepted stop thresholds and the cgroup limit events of the guest collectors, and the
# query clients of the analysis host; it appends one line per check to the log and exits with an ALERT line at the
# first deviation or with a WATCH-END line after the end of the watch.
set -u

readonly GUEST='<user>@<guest-address>'
readonly LOG='<evidence-dir>/rehearsal-2h-20261122/watch.log'
readonly JVM_PIDS='<jvm-pids>'
readonly QUERY_START='2026-11-22T09:06:42Z'
readonly QUERY_END='2026-11-22T09:46:42Z'
readonly WATCH_END='2026-11-22T09:58:00Z'
readonly WATCH_INTERVAL=300
readonly MIN_AVAILABLE_KIB=$((200 * 1024))
readonly MAX_DISK_PERCENT=80
readonly MIN_FREE_INODE_PERCENT=10

# Prints the facts of one check on the guest as key=value lines; every command only reads.
guest_check() {
    ssh -o BatchMode=yes -o ConnectTimeout=20 "$GUEST" '
printf "sampler=%s\ncamonitor=%s\napp=%s\n" "$(systemctl is-active reh-sampler)" "$(systemctl is-active reh-camonitor)" "$(systemctl is-active epicsarchiverap-maven)"
printf "jvms=%s\n" "$(pgrep -u <service-account> java | sort -n | tr "\n" " " | sed "s/ $//")"
printf "available_kib=%s\n" "$(awk "/MemAvailable/ {print \$2}" /proc/meminfo)"
printf "disk_percent=%s\n" "$(df --output=pcent / | tail -1 | tr -dc 0-9)"
printf "free_inode_percent=%s\n" "$(df --output=ipcent / | tail -1 | tr -dc 0-9 | awk "{print 100 - \$1}")"
for u in reh-sampler reh-camonitor; do d=/sys/fs/cgroup/memory/system.slice/$u.service; printf "%s_failcnt=%s\n%s_oom=%s\n%s_rss=%s\n%s_cache=%s\n%s_limit=%s\n" "$u" "$(cat $d/memory.failcnt 2>/dev/null)" "$u" "$(grep -E "^oom_kill " $d/memory.oom_control 2>/dev/null | cut -d" " -f2)" "$u" "$(awk "/^rss / {print \$2}" $d/memory.stat)" "$u" "$(awk "/^cache / {print \$2}" $d/memory.stat)" "$u" "$(cat $d/memory.limit_in_bytes)"; done
printf "samples_rows=%s\n" "$(wc -l < ~/rehearsal/samples/samples.csv)"
printf "camonitor_bytes=%s\n" "$(stat -c %s ~/rehearsal/ca/run1/camonitor.out)"
'
}

alerts=()

# Adds an alert text when the named fact differs from its expectation.
expect() {
    local name=$1 expected=$2
    [[ "${fact[$name]-missing}" == "$expected" ]] || alerts+=("$name=${fact[$name]-missing} expected $expected")
    return 0
}

end_epoch=$(date -u -d "$WATCH_END" +%s)
query_start=$(date -u -d "$QUERY_START" +%s)
query_end=$(date -u -d "$QUERY_END" +%s)
last_rows=0
while (( $(date -u +%s) < end_epoch )); do
    if ! output=$(guest_check 2>&1); then
        printf '%s ALERT guest check failed: %s\n' "$(date -u +%FT%TZ)" "$output" | tee -a "$LOG"
        exit 1
    fi
    declare -A fact=()
    while IFS='=' read -r key value; do
        fact[$key]=$value
    done <<< "$output"
    alerts=()
    now=$(date -u +%s)
    if (( now < $(date -u -d "2026-11-22T09:54:00Z" +%s) )); then
        expect sampler active
        expect camonitor active
    fi
    expect app active
    expect jvms "$JVM_PIDS"
    expect reh-sampler_oom 0
    expect reh-camonitor_oom 0
    for u in reh-sampler reh-camonitor; do
        rss=${fact[${u}_rss]:-0}; limit=${fact[${u}_limit]:-1}
        (( rss * 10 < limit * 9 )) || alerts+=("$u anonymous memory $rss at 90 percent of its limit $limit")
    done
    (( ${fact[available_kib]:-0} >= MIN_AVAILABLE_KIB )) || alerts+=("available_kib=${fact[available_kib]:-missing} below $MIN_AVAILABLE_KIB")
    (( ${fact[disk_percent]:-100} < MAX_DISK_PERCENT )) || alerts+=("disk_percent=${fact[disk_percent]:-missing} at or above $MAX_DISK_PERCENT")
    (( ${fact[free_inode_percent]:-0} >= MIN_FREE_INODE_PERCENT )) || alerts+=("free_inode_percent=${fact[free_inode_percent]:-missing} below $MIN_FREE_INODE_PERCENT")
    (( ${fact[samples_rows]:-0} > last_rows )) || alerts+=("samples_rows=${fact[samples_rows]:-missing} did not grow from $last_rows")
    last_rows=${fact[samples_rows]:-0}
    queries=''
    for n in 0 1 2 3; do
        state=$(systemctl --user is-active "reh-q$n.service" 2>/dev/null)
        cgroup="/sys/fs/cgroup/user.slice/user-<uid>.slice/user@<uid>.service/app.slice/reh-q$n.service"
        peak=$(cat "$cgroup/memory.peak" 2>/dev/null); anon=$(awk '/^anon / {print $2}' "$cgroup/memory.stat" 2>/dev/null); limit=$(cat "$cgroup/memory.max" 2>/dev/null)
        queries="$queries q$n=$state(peak=${peak:--},anon=${anon:--})"
        if [[ -n "$anon" && "$limit" =~ ^[0-9]+$ ]] && (( anon * 10 >= limit * 9 )); then
            alerts+=("query client q$n anonymous memory $anon at 90 percent of its limit $limit")
        fi
        if (( now > query_start + 60 && now < query_end - 60 )) && [[ "$state" != active ]]; then
            alerts+=("query client q$n is $state during the query phase")
        fi
        events=$(cat "/sys/fs/cgroup/user.slice/user-<uid>.slice/user@<uid>.service/app.slice/reh-q$n.service/memory.events" 2>/dev/null | grep -E "^(max|oom|oom_kill) " | tr '\n' ' ')
        [[ -z "$events" || "$events" == *"oom_kill 0"* ]] || alerts+=("query client q$n memory events: $events")
    done
    printf '%s check sampler=%s camonitor=%s app=%s jvms_same=%s avail_mib=%s disk=%s%% rows=%s failcnt_sampler=%s failcnt_camonitor=%s rss_sampler=%s rss_camonitor=%s cache_camonitor=%s%s\n' "$(date -u +%FT%TZ)" \
        "${fact[sampler]:-?}" "${fact[camonitor]:-?}" "${fact[app]:-?}" "$([[ ${fact[jvms]:-} == "$JVM_PIDS" ]] && echo yes || echo NO)" \
        "$(( ${fact[available_kib]:-0} / 1024 ))" "${fact[disk_percent]:-?}" "${fact[samples_rows]:-?}" "${fact[reh-sampler_failcnt]:-?}" "${fact[reh-camonitor_failcnt]:-?}" "${fact[reh-sampler_rss]:-?}" "${fact[reh-camonitor_rss]:-?}" "${fact[reh-camonitor_cache]:-?}" "$queries" >> "$LOG"
    if (( ${#alerts[@]} > 0 )); then
        printf '%s ALERT %s\n' "$(date -u +%FT%TZ)" "${alerts[*]}" | tee -a "$LOG"
        exit 1
    fi
    interval=$WATCH_INTERVAL
    (( now >= query_start - 60 && now < query_end )) && interval=60
    sleep "$interval"
done
printf '%s WATCH-END no deviation seen until %s\n' "$(date -u +%FT%TZ)" "$WATCH_END" | tee -a "$LOG"
