#!/bin/bash
# Exercises shipped readiness/output code with only HTTP and privilege boundaries replaced.
set -euo pipefail
TOP=$(realpath -- "${BASH_SOURCE[0]%/*}/..")
readonly TOP
workspace=$(mktemp -d "$TOP/work/local-install-output.XXXXXXXX")
mkdir -p "$workspace/scripts" "$workspace/boundary"
# The entrypoint is omitted; every shipped function is sourced without modification.
sed '$d' "$TOP/scripts/install-local-common.bash" > "$workspace/scripts/functions.bash"
printf '%s\n' '#!/bin/bash' \
    'case "$*" in *health) printf "%s\n" "HEALTH_BOUNDARY_RESULT" ;; esac' \
    > "$workspace/boundary/sudo"
printf '%s\n' '#!/bin/bash' \
    'case "${*: -1}" in' \
    '  */getApplianceInfo)' \
    '    if [[ ! -e "$STATE" ]]; then touch "$STATE"; printf "%s\n" "<html>not ready</html>";' \
    '    else printf "%s\n" "{\"identity\":\"appliance0\",\"version\":\"Test version\"}"; fi ;;' \
    '  *) printf "%s\n" "{\"status\":\"STARTUP_COMPLETE\"}" ;;' \
    'esac' > "$workspace/boundary/curl"
chmod +x "$workspace/boundary/sudo" "$workspace/boundary/curl"
STATE="$workspace/state" bash -c '
    source "$1"
    PATH="$2:$PATH"
    timeout=15
    service_user=test
    service_unit=test.service
    health_timer=test.timer
    install_path=/test
    component_urls=(http://localhost:1/mgmt/bpl/startupState http://localhost:2/engine/bpl/startupState
        http://localhost:3/etl/bpl/startupState http://localhost:4/retrieval/bpl/startupState)
    mgmt_url=http://localhost:1/mgmt/bpl/getApplianceInfo
    wait_ready
    show_ready
    yes=1
    prepare_pv_verification
    offer_pv_verification
' test "$workspace/scripts/functions.bash" "$workspace/boundary" > "$workspace/output.log"
[[ $(grep -c 'HEALTH_BOUNDARY_RESULT' "$workspace/output.log") == 1 ]]
[[ $(grep -c '^Waiting ' "$workspace/output.log") == 1 ]]
grep -q 'appliance information;' "$workspace/output.log"
grep -q '^Installation completed.' "$workspace/output.log"
grep -q '^Management UI: http://localhost:1/mgmt/ui/index.html$' "$workspace/output.log"
grep -q '^  Identity: appliance0' "$workspace/output.log"
grep -q 'PV acquisition, storage and retrieval: NOT CHECKED' "$workspace/output.log"
grep -q 'skipped in unattended mode' "$workspace/output.log"
if grep -q '[{}]' "$workspace/output.log"; then printf '%s\n' 'FAIL: raw JSON in completion output'; exit 1; fi
status=0
bash -c 'source "$1"; installation_completed=1; trap report_exit EXIT; exit 130' \
    test "$workspace/scripts/functions.bash" > "$workspace/interrupted.log" 2>&1 || status=$?
[[ "$status" == 130 ]]
grep -q 'Installation completed. Post-install verification stopped' "$workspace/interrupted.log"
if grep -q 'Installation stopped during' "$workspace/interrupted.log"; then exit 1; fi
printf 'PASS: readiness output unit checks (HTTP/privilege boundaries only). Evidence: %s\n' "$workspace"
