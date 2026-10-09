#!/bin/bash
# Runs the shipped PV verifier against four real WARs and a real soft IOC.
set -euo pipefail
TOP=$(realpath -- "${BASH_SOURCE[0]%/*}/..")
readonly TOP
readonly SOURCE="${AA_TEST_SOURCE_PATH:-$TOP/epicsarchiverap-maven-src}"
readonly TOMCAT="${AA_TEST_TOMCAT_HOME:?Set AA_TEST_TOMCAT_HOME to readable Tomcat 9}"
readonly EPICS_BIN="${AA_TEST_EPICS_BIN:?Set AA_TEST_EPICS_BIN to EPICS Base bin}"
readonly PORT="${AA_TEST_PORT_BASE:-28665}"
[[ "$PORT" =~ ^[0-9]{1,5}$ ]] || exit 1
(( PORT >= 1024 && PORT <= 65530 )) || exit 1
workspace=$(mktemp -d "$TOP/work/local-pv-integration.XXXXXXXX")
mkdir -p "$workspace/scripts/fixtures"
cp "$TOP/scripts/verify-local-pv.bash" "$workspace/scripts/verify-local-pv.bash"
cp "$TOP/scripts/verify-local-pv-curl.bash" "$workspace/scripts/verify-local-pv-curl.bash"
cp "$TOP/scripts/fixtures/local-install-pv.db" "$workspace/scripts/fixtures/local-install-pv.db"
sha256sum "$workspace/scripts/verify-local-pv.bash" "$workspace/scripts/verify-local-pv-curl.bash" \
    "$workspace/scripts/fixtures/local-install-pv.db" > "$workspace/inputs.sha256"
launcher=''
kept_pid=''
kept_start=''
kept_pv=''

function kept_alive {
    local line
    local -a fields=()
    [[ -n "$kept_pid" ]] || return 1
    IFS= read -r line 2>/dev/null < "/proc/$kept_pid/stat" || return 1
    read -r -a fields <<< "${line##*) }"
    [[ "${fields[19]:-}" == "$kept_start" && "${fields[0]:-}" != Z ]]
}

function finish {
    local status=$?
    trap - EXIT
    if kept_alive; then
        curl -q --noproxy '*' --fail --silent --max-time 10 --get --data-urlencode "pv=$kept_pv" \
            "$mgmt/pauseArchivingPV" > "$workspace/keep-pause.json" || true
        if kept_alive; then kill -TERM "$kept_pid" 2>/dev/null || true; fi
    fi
    if [[ -n "$launcher" ]]; then
        kill -TERM "$launcher" 2>/dev/null || true
        wait "$launcher" 2>/dev/null || true
    fi
    printf 'Integration evidence: %s\n' "$workspace"
    exit "$status"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

bash "$SOURCE/scripts/run-local-appliance.bash" --war-dir "$SOURCE/target" \
    --tomcat-home "$TOMCAT" --port-base "$PORT" "$workspace/appliance" > "$workspace/appliance.log" 2>&1 &
launcher=$!
deadline=$((SECONDS + 180))
while ! curl -q --noproxy '*' --fail --silent --max-time 2 \
    "http://127.0.0.1:$PORT/mgmt/bpl/getApplianceInfo" > "$workspace/info.json"; do
    kill -0 "$launcher" 2>/dev/null || { cat "$workspace/appliance.log"; exit 1; }
    (( SECONDS < deadline )) || exit 1
    sleep 2
done
# The installed WAR can contain site paths; the isolated fixture uses its own stores.
sed -i "s|rootFolder=/arch/sts/ArchiverStore|rootFolder=$workspace/appliance/stores/sts|g; s|rootFolder=/arch/mts/ArchiverStore|rootFolder=$workspace/appliance/stores/mts|g; s|rootFolder=/arch/lts/ArchiverStore|rootFolder=$workspace/appliance/stores/lts|g" "$workspace/appliance/config/policies.py"
mgmt="http://127.0.0.1:$PORT/mgmt/bpl"
retrieval="http://127.0.0.1:$((PORT + 3))/retrieval"
bash "$workspace/scripts/verify-local-pv.bash" --epics-bin "$EPICS_BIN" --cleanup stop \
    "$mgmt" "$retrieval" "$SOURCE" > "$workspace/pass.log" 2>&1 || { cat "$workspace/pass.log"; exit 1; }
cat "$workspace/pass.log"
grep -q 'PV acquisition, storage and retrieval: PASS' "$workspace/pass.log"
grep -q 'Test PV paused:' "$workspace/pass.log"
evidence=$(sed -n 's/^Evidence: //p' "$workspace/pass.log" | tail -n 1)
[[ -s "$evidence/ca.tsv" && -s "$evidence/result.txt" && -s "$evidence/pause.json" ]]
pid=$(cat "$evidence/ioc.pid")
if kill -0 "$pid" 2>/dev/null; then printf '%s\n' 'FAIL: test IOC survived stop'; exit 1; fi

# A real terminal chooses keep; the same verifier must resume its paused PV.
printf '%q ' bash "$workspace/scripts/verify-local-pv.bash" --epics-bin "$EPICS_BIN" \
    "$mgmt" "$retrieval" "$SOURCE" > "$workspace/keep.bash"
printf '\n' >> "$workspace/keep.bash"
printf -v keep_command '%q %q' bash "$workspace/keep.bash"
printf '2\n' | script --quiet --return --command "$keep_command" "$workspace/keep.raw" > /dev/null
tr -d '\r' < "$workspace/keep.raw" > "$workspace/keep.log"
grep -q 'IOC retained: PID' "$workspace/keep.log"
grep -q 'Current state: test PV is Paused; IOC is running.' "$workspace/keep.log"
grep -q '2. Resume test PV archiving; keep IOC running' "$workspace/keep.log"
evidence=$(sed -n 's/^Evidence: //p' "$workspace/keep.log" | tail -n 1)
jq -e '.status == "ok"' "$evidence/resume.json" >/dev/null
kept_pid=$(cat "$evidence/ioc.pid")
kept_pv=$(cat "$evidence/pvs.txt")
command_line=$(tr '\0' ' ' < "/proc/$kept_pid/cmdline")
[[ "$command_line" == *"P=${kept_pv%Value}"* ]] || exit 1
IFS= read -r line < "/proc/$kept_pid/stat"
read -r -a fields <<< "${line##*) }"
kept_start="${fields[19]}"
kept_alive
curl -q --noproxy '*' --fail --silent --max-time 10 --get --data-urlencode "pv=$kept_pv" \
    "$mgmt/pauseArchivingPV" > "$workspace/keep-pause.json"
jq -e '.status == "ok"' "$workspace/keep-pause.json" >/dev/null
if kept_alive; then kill -TERM "$kept_pid"; fi
for _attempt in 1 2 3 4 5; do kept_alive || break; sleep 1; done
if kept_alive; then printf '%s\n' 'FAIL: retained IOC did not stop'; exit 1; fi
kept_pid=''

# A real unavailable retrieval endpoint must fail after registration and stop its IOC.
status=0
bash "$workspace/scripts/verify-local-pv.bash" --epics-bin "$EPICS_BIN" --cleanup stop --timeout 140 \
    "$mgmt" "http://127.0.0.1:$((PORT + 4))/retrieval" "$SOURCE" > "$workspace/failure.log" 2>&1 || status=$?
(( status != 0 ))
grep -q 'Archive request accepted:' "$workspace/failure.log"
if grep -q 'PV acquisition, storage and retrieval: PASS' "$workspace/failure.log"; then exit 1; fi
evidence=$(sed -n 's/^Evidence: //p' "$workspace/failure.log" | tail -n 1)
[[ -s "$evidence/ioc.log" && -s "$evidence/ca.tsv" && -s "$evidence/register.json" ]]
jq -e '.status == "ok"' "$evidence/pause.json" >/dev/null
grep -q 'request failed:' "$evidence"/extract-*.log
pid=$(cat "$evidence/ioc.pid")
if kill -0 "$pid" 2>/dev/null; then printf '%s\n' 'FAIL: failed test IOC survived cleanup'; exit 1; fi
AA_TEST_SOURCE_PATH="$SOURCE" AA_TEST_EPICS_BIN="$EPICS_BIN" python3 "$TOP/tests/local-install-pv-signals.py"
AA_TEST_SOURCE_PATH="$SOURCE" AA_TEST_EPICS_BIN="$EPICS_BIN" python3 "$TOP/tests/local-install-pv-range.py"
AA_TEST_SOURCE_PATH="$SOURCE" AA_TEST_EPICS_BIN="$EPICS_BIN" python3 "$TOP/tests/local-install-pv-menu.py"
printf '%s\n' 'PASS: real PV round trip, interactive keep/resume and failed-retrieval cleanup'
