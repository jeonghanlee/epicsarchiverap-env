#!/bin/bash
# Checks installer status messages against four real WARs and the shipped process/storage inspection.
set -euo pipefail
TOP=$(realpath -- "${BASH_SOURCE[0]%/*}/..")
readonly TOP
readonly SOURCE="${AA_TEST_SOURCE_PATH:-$TOP/epicsarchiverap-maven-src}"
readonly TOMCAT="${AA_TEST_TOMCAT_HOME:?Set AA_TEST_TOMCAT_HOME to readable Tomcat 9}"
readonly PORT="${AA_TEST_PORT_BASE:-28665}"
[[ "$PORT" =~ ^[0-9]{1,5}$ ]] || exit 1
(( PORT >= 1024 && PORT <= 65530 )) || exit 1
workspace=$(mktemp -d "$TOP/work/local-readiness.XXXXXXXX")
launcher=''
function finish {
    local status=$?
    trap - EXIT
    if [[ -n "$launcher" ]]; then
        kill -TERM "$launcher" 2>/dev/null || true
        wait "$launcher" 2>/dev/null || true
    fi
    printf 'Readiness evidence: %s\n' "$workspace"
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
install="$workspace/appliance/instances"
cp "$TOP/scripts/archappl.bash" "$install/archappl.bash"
chmod +x "$install/archappl.bash"
java_home=''
while IFS=$'\t' read -r _boot component pid _start; do
    printf '%s\n' "$pid" > "$install/$component/temp/$component.pid"
    if [[ "$component" == mgmt ]]; then java_home=$(realpath -e -- "/proc/$pid/exe"); fi
done < "$workspace/appliance/children.tsv"
[[ "$java_home" == */bin/java ]]
java_home="${java_home%/bin/java}"
printf 'JAVA_HOME=%q\nCATALINA_HOME=%q\nARCHAPPL_STORAGE_TOP=%q\n' \
    "$java_home" "$TOMCAT" "$workspace/appliance/stores" > "$install/archappl.conf"
printf 'ARCHAPPL_STORAGE_ALARM_PERCENT=100\n' >> "$install/archappl.conf"
for tier in SHORT MEDIUM LONG; do
    case "$tier" in SHORT) folder=sts ;; MEDIUM) folder=mts ;; LONG) folder=lts ;; esac
    printf 'ARCHAPPL_%s_TERM_FOLDER=%q\n' "$tier" "$workspace/appliance/stores/$folder" >> "$install/archappl.conf"
done
mkdir -p "$workspace/scripts" "$workspace/boundary"
# Only the entry call is omitted; all shipped functions run unchanged.
sed '$d' "$TOP/scripts/install-local-common.bash" > "$workspace/scripts/functions.bash"
# Privilege and systemd boundaries are replaced; the actual launcher, JVM inspection, df and HTTP run.
printf '%s\n' '#!/bin/bash' \
    '[[ "$1" == -n ]] && shift' \
    'if [[ "$1" == -u ]]; then shift 2; fi' \
    '[[ "$1" == -- ]] && shift' \
    'if [[ "$1" == systemctl ]]; then' \
    ' if [[ "${*: -1}" == "${READINESS_UNIT_TARGET:-test.service}" ]]; then' \
    '  case "${READINESS_UNIT_CASE:-active}" in' \
    '   denied) printf "%s\n" "sudo: systemctl: permission denied" >&2; exit 1 ;;' \
    '   inactive) printf "%s\n" inactive; exit 3 ;;' \
    '   failed) printf "%s\n" failed; exit 3 ;;' \
    '   error) printf "%s\n" "Failed to connect to bus: Permission denied" >&2; exit 3 ;;' \
    '   missing) printf "%s\n" unknown; exit 4 ;;' \
    '   killed) kill -KILL "$$" ;;' \
    '   delayed) exec sleep 10 ;;' \
    '  esac' \
    ' fi' \
    ' printf "%s\n" active; exit 0' \
    'fi' \
    'if [[ "${*: -1}" == health ]]; then' \
    ' case "${READINESS_HEALTH_CASE:-active}" in' \
    '  killed) kill -KILL "$$" ;;' \
    '  killed-once)' \
    '   if [[ ! -e "$READINESS_HEALTH_STATE" ]]; then touch "$READINESS_HEALTH_STATE"; kill -KILL "$$"; fi ;;' \
    '  healthy-then-killed)' \
    '   if [[ -e "$READINESS_HEALTH_STATE" ]]; then kill -KILL "$$"; fi' \
    '   touch "$READINESS_HEALTH_STATE" ;;' \
    '  delayed) exec sleep 10 ;;' \
    ' esac' \
    'fi' \
    'exec "$@"' > "$workspace/boundary/sudo"
chmod +x "$workspace/boundary/sudo"
printf '%s\n' '#!/bin/bash' 'source "$1"' 'PATH="$2:$PATH"' \
    'install_path="$3"; port="$4"; timeout="$5"; service_user=test' \
    'service_unit=test.service; health_timer=test.timer; stage="startup verification"' \
    'mgmt_url="http://127.0.0.1:$port/mgmt/bpl/getApplianceInfo"' \
    'for index in "${!COMPONENTS[@]}"; do' \
    ' component_urls+=("http://127.0.0.1:$((port+index))/${COMPONENTS[$index]}/bpl/startupState")' \
    'done' 'trap report_exit EXIT' 'wait_ready' 'installation_completed=1' 'show_ready' > "$workspace/check.bash"
bash "$workspace/check.bash" "$workspace/scripts/functions.bash" "$workspace/boundary" "$install" "$PORT" 90 \
    > "$workspace/pass.log" 2>&1
grep -q '^Installation completed. All required installation checks passed.' "$workspace/pass.log"
grep -q '^Four process identities: PASS$' "$workspace/pass.log"
grep -q '^Storage usage: PASS$' "$workspace/pass.log"
grep -q '^  Identity: appliance0$' "$workspace/pass.log"
[[ $(grep -c 'PRESENT verified-process-presence' "$workspace/pass.log") == 4 ]]
# Unit observations vary only at the systemd/privilege boundary; real JVM and HTTP checks remain unchanged.
for unit_target in test.service test.timer; do
    case "$unit_target" in
        test.service) unit_label='Appliance service' ;;
        test.timer) unit_label='Health timer' ;;
    esac
    for unit_case in denied inactive failed error missing killed delayed; do
        unit_log="$workspace/unit-$unit_target-$unit_case.log"
        status=0
        READINESS_UNIT_TARGET="$unit_target" READINESS_UNIT_CASE="$unit_case" \
            bash "$workspace/check.bash" "$workspace/scripts/functions.bash" \
            "$workspace/boundary" "$install" "$PORT" 4 > "$unit_log" 2>&1 || status=$?
        [[ "$status" == 1 ]]
        case "$unit_case" in
            inactive|failed)
                grep -Fq "$unit_label: NOT ACTIVE ($unit_target)" "$unit_log"
                grep -q "systemctl reports: $unit_case" "$unit_log" ;;
            delayed)
                grep -Fq "$unit_label: TIMED OUT ($unit_target)" "$unit_log"
                grep -q 'unit state query did not complete' "$unit_log" ;;
            *)
                grep -Fq "$unit_label: INSPECTION ERROR ($unit_target)" "$unit_log"
                case "$unit_case" in
                    denied) grep -q 'sudo: systemctl: permission denied' "$unit_log" ;;
                    error) grep -q 'Failed to connect to bus: Permission denied' "$unit_log" ;;
                    missing) grep -q 'exit 4): unknown' "$unit_log" ;;
                    killed) grep -q 'exit 137)' "$unit_log" ;;
                esac ;;
        esac
        grep -q '^Four process identities: PASS$' "$unit_log"
        grep -q '^  Identity: appliance0$' "$unit_log"
        if grep -q '^Installation completed.' "$unit_log"; then exit 1; fi
    done
done
# A killed inspection transport is distinct from an inspection exceeding its deadline.
for health_case in killed delayed; do
    health_log="$workspace/health-$health_case.log"
    status=0
    READINESS_HEALTH_CASE="$health_case" bash "$workspace/check.bash" "$workspace/scripts/functions.bash" \
        "$workspace/boundary" "$install" "$PORT" 4 > "$health_log" 2>&1 || status=$?
    [[ "$status" == 1 ]]
    if [[ "$health_case" == killed ]]; then
        grep -q '^Health check: INSPECTION ERROR$' "$health_log"
        grep -q 'health inspection ended before the startup deadline (exit 137)' "$health_log"
        grep -q '^  Identity: appliance0$' "$health_log"
    else
        grep -q '^Health check: TIMED OUT$' "$health_log"
    fi
    if grep -q '^Installation completed.' "$health_log"; then exit 1; fi
done
# Inspection recovery must clear the interruption, while a later interruption preserves completed observations.
READINESS_HEALTH_CASE=killed-once READINESS_HEALTH_STATE="$workspace/health-recovery.state" \
    bash "$workspace/check.bash" "$workspace/scripts/functions.bash" "$workspace/boundary" "$install" "$PORT" 15 \
    > "$workspace/health-recovery.log" 2>&1
grep -q '^Installation completed. All required installation checks passed.' "$workspace/health-recovery.log"
grep -q '^Health check: PASS$' "$workspace/health-recovery.log"
if grep -q 'health inspection ended' "$workspace/health-recovery.log"; then exit 1; fi
status=0
READINESS_HEALTH_CASE=healthy-then-killed READINESS_HEALTH_STATE="$workspace/health-history.state" \
    READINESS_UNIT_CASE=inactive bash "$workspace/check.bash" "$workspace/scripts/functions.bash" \
    "$workspace/boundary" "$install" "$PORT" 6 > "$workspace/health-history.log" 2>&1 || status=$?
[[ "$status" == 1 ]]
grep -q '^Health check: INSPECTION ERROR$' "$workspace/health-history.log"
grep -q 'health inspection ended before the startup deadline (exit 137)' "$workspace/health-history.log"
grep -q '^Four process identities: PASS$' "$workspace/health-history.log"
grep -q '^Storage usage: PASS$' "$workspace/health-history.log"
[[ $(grep -c 'PRESENT verified-process-presence' "$workspace/health-history.log") == 4 ]]
# The actual filesystem's usage becomes the configured failing boundary.
usage=$(df -P -- "$workspace/appliance/stores" | awk 'NR==2 {gsub(/%/, "", $5); print $5}')
(( usage > 0 && usage <= 100 ))
printf 'ARCHAPPL_STORAGE_ALARM_PERCENT=%s\n' "$usage" >> "$install/archappl.conf"
status=0
bash "$workspace/check.bash" "$workspace/scripts/functions.bash" "$workspace/boundary" "$install" "$PORT" 8 \
    > "$workspace/storage-failure.log" 2>&1 || status=$?
[[ "$status" == 1 ]]
grep -q '^Four process identities: PASS$' "$workspace/storage-failure.log"
grep -q '^Storage usage: FAIL$' "$workspace/storage-failure.log"
grep -q 'The four components have started and the information API responds.' "$workspace/storage-failure.log"
grep -q 'The failed storage check does not mean that the appliance failed to start.' "$workspace/storage-failure.log"
grep -q 'Appliance files are installed. Verification failed' "$workspace/storage-failure.log"
grep -q 'sudo journalctl' "$workspace/storage-failure.log"
[[ $(grep -c '^storage .*FAIL storage-threshold' "$workspace/storage-failure.log") == 4 ]]
[[ $(grep -c '^  .*: PASS$' "$workspace/storage-failure.log") == 4 ]]
grep -q '^  Identity: appliance0$' "$workspace/storage-failure.log"
grep -q '^Management UI: ' "$workspace/storage-failure.log"
if grep -q '^Installation completed.' "$workspace/storage-failure.log"; then exit 1; fi
# A missing PID is a distinct real inspection failure, even though the HTTP API responds.
printf 'ARCHAPPL_STORAGE_ALARM_PERCENT=100\n' >> "$install/archappl.conf"
mv "$install/engine/temp/engine.pid" "$install/engine/temp/engine.pid.saved"
status=0
bash "$workspace/check.bash" "$workspace/scripts/functions.bash" "$workspace/boundary" "$install" "$PORT" 8 \
    > "$workspace/process-failure.log" 2>&1 || status=$?
[[ "$status" == 1 ]]
grep -q '^Four process identities: NOT VERIFIED$' "$workspace/process-failure.log"
grep -q '^Storage usage: PASS$' "$workspace/process-failure.log"
grep -q 'missing-pid-file' "$workspace/process-failure.log"
if grep -q 'The four components have started' "$workspace/process-failure.log"; then exit 1; fi
printf '%s\n' 'PASS: actual four-WAR startup, unit query diagnostics, storage-only failure and missing-PID diagnostics.'
