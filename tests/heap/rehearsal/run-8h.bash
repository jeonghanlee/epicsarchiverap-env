#!/usr/bin/env bash
# Runs the 8-hour rehearsal of the heap measurement from its start time S: collectors on the guest at S, a deliberate stop
# and restart of the sampler at S+4:00 and S+4:10, four query clients at S+5:00 for one hour, block 1 at S+6:00 and block 2
# at the end. Every step is written to stages.csv; a failed step is recorded and ends the run.
# Usage: run-8h.bash <S as 2026-11-22T17:35:00Z> <pvs.csv of the 100 PVs>
set -u

readonly S=${1:?start time required}
readonly PVS=${2:?pvs.csv required}
readonly GUEST='<user>@<guest-address>'
readonly H='<evidence-dir>/rehearsal-8h-20261122'
readonly REPO='<repo>'
readonly CAMONITOR='/opt/epics/1.5.0/rocky-8.10/7.0.10/base/bin/linux-x86_64/camonitor'
readonly RUN_SECONDS=28800
readonly STOP_AFTER=14400
readonly RESTART_AFTER=15000
readonly QUERY_AFTER=18000
readonly QUERY_SECONDS=3600
readonly BLOCK1_AFTER=21600

stage() {
    printf '%s,%s,%s,%s\n' "$(date -u +%FT%T.%3NZ)" "$(cut -d' ' -f1 /proc/uptime)" "$1" "$2" >> "$H/stages.csv"
}

# Waits until the given number of seconds after S.
at() {
    local target=$(( $(date -u -d "$S" +%s) + $1 ))
    while (( $(date -u +%s) < target )); do sleep 2; done
}

fail() {
    stage run_failed "$1"
    echo "FAILED: $1" >&2
    exit 1
}

guest() {
    ssh -o BatchMode=yes -o ConnectTimeout=20 "$GUEST" "$@"
}

# Starts the sampler on the guest for the given number of seconds; the output file is appended to.
start_sampler() {
    guest "cd ~/rehearsal && sudo -n systemd-run --unit=reh-sampler8 -p User=<user> -p WorkingDirectory=<home>/rehearsal -p MemoryLimit=64M -p Type=simple /usr/bin/perl tools/sample-resources.pl --output samples8h/samples.csv --interval 5 --duration $1 \$(cat tools/sampler.args)" > /dev/null 2>&1
}

# Pulls the guest files into the staging folder and copies one block.
copy_block() {
    local number=$1
    stage "block${number}_pull_start" "rsync of the guest files into the staging folder"
    mkdir -p "$H/staging/gc" "$H/staging/samples" "$H/staging/ca" || fail "mkdir staging"
    rsync -a --rsync-path="sudo rsync" -e "ssh -o BatchMode=yes" "$GUEST:/arch/gc/" "$H/staging/gc/" || fail "rsync gc"
    rsync -a -e "ssh -o BatchMode=yes" "$GUEST:rehearsal/samples8h/" "$H/staging/samples/" || fail "rsync samples"
    rsync -a -e "ssh -o BatchMode=yes" "$GUEST:rehearsal/ca8h/" "$H/staging/ca/" || fail "rsync ca"
    rsync -a "$H/queries/" "$H/staging/queries/" 2> /dev/null
    stage "block${number}_pull_end" "staging complete"
    stage "block${number}_copy_start" "copy-block.pl block $number"
    perl "$REPO/tests/heap/copy-block.pl" --source "$H/staging" --dest "$H/blocks" --block "$number" 2>> "$H/copy-block.err"
    stage "block${number}_copy_end" "exit status $?"
}

mkdir -m 700 -p "$H/queries" "$H/staging" || fail "mkdir evidence"
[[ -s $H/stages.csv ]] || echo 'time_utc,uptime_s,event,detail' > "$H/stages.csv"
cp "$PVS" "$H/pvs.csv" || fail "copy of $PVS"
stage run_waiting "start time $S"

at 0
guest 'mkdir -p ~/rehearsal/samples8h ~/rehearsal/ca8h' || fail "guest folders"
stage collectors_start "sampler 64M and CA observer 128M on the guest, $RUN_SECONDS s"
start_sampler "$RUN_SECONDS" || fail "sampler start"
guest "cd ~/rehearsal && sudo -n systemd-run --unit=reh-camonitor8 -p User=<user> -p WorkingDirectory=<home>/rehearsal -p MemoryLimit=128M -p Type=simple -p Environment='EPICS_CA_ADDR_LIST=127.0.0.1 EPICS_CA_AUTO_ADDR_LIST=NO EPICS_CA_MAX_ARRAY_BYTES=16384' /usr/bin/perl tools/observe-ca.pl --pv-list ioc/iocBoot/iocAasoak/pvnames.txt --output-dir ca8h/run --camonitor $CAMONITOR --duration $RUN_SECONDS" > /dev/null 2>&1 || fail "CA observer start"
sleep 10
stage collectors_running "$(guest 'systemctl is-active reh-sampler8 reh-camonitor8 | tr "\n" " "')"

at "$STOP_AFTER"
before=$(guest 'systemctl show reh-sampler8 -p MainPID --value')
guest 'sudo -n systemctl stop reh-sampler8' || fail "sampler stop"
stage deliberate_stop "sampler stopped by systemctl stop; main PID was $before"

at "$RESTART_AFTER"
remaining=$(( RUN_SECONDS - RESTART_AFTER ))
start_sampler "$remaining" || fail "sampler restart"
sleep 5
after=$(guest 'systemctl show reh-sampler8 -p MainPID --value')
stage deliberate_restart "sampler restarted for $remaining s; main PID is $after; the output file is appended to"

at "$QUERY_AFTER"
stage query_clients_start "four clients, $QUERY_SECONDS s, MemoryMax 512M each"
for n in 0 1 2 3; do
    systemd-run --user --unit="reh-q$n" -p MemoryMax=512M /usr/bin/perl "$REPO/tests/heap/query-archive.pl" --pv-csv "$H/pvs.csv" --output-dir "$H/queries" --url http://127.0.0.1:18668/retrieval/data/getData.json --client "$n" --pause 2 --duration "$QUERY_SECONDS" > /dev/null 2>&1 || fail "query client $n start"
done

at "$BLOCK1_AFTER"
copy_block 1

at "$(( RUN_SECONDS + 120 ))"
stage collectors_state_at_end "$(guest 'systemctl is-active reh-sampler8 reh-camonitor8 | tr "\n" " "')"
copy_block 2
stage run_complete "blocks 1 and 2 copied"
