#!/usr/bin/env bash
# Launcher health for an instance that has not executed Java yet.
# The shipped run.sh, rendered the way the Make rules render it, runs under the real
# health command. Its instance configuration holds the chain at a stage; the catalina.sh
# of the chain is a stand-in that holds and then executes a live JVM named like Tomcat's
# Bootstrap. Real Tomcat is not installed here, so the real-chain proof is the VM run.

set -euo pipefail

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TOP
# The launcher under test; a mutation run points this at a modified copy.
readonly LAUNCHER_SRC="${HEALTH_LAUNCHER_UNDER_TEST:-${TOP}/scripts/archappl.bash}"
readonly SERVICES=(mgmt engine etl retrieval)

# shellcheck source=lib/common.bash
source "${TOP}/tests/lib/common.bash"

phase_header "Health: instances that have not executed Java yet"

assert_cmd java "java is installed"
assert_cmd javac "javac is installed"

ROOT="${WORKSPACE}/health-starting"
JAVA_BIN="$(readlink -f "$(command -v java)")"
JAVA_HOME_DIR="$(dirname "$(dirname "${JAVA_BIN}")")"
declare -A PIDS=()
HEALTH_OUT=""
HEALTH_RC=0

stop_children() {
    local pid
    for pid in $(jobs -p); do kill "${pid}" 2> /dev/null || true; done
    sleep 0.2
    for pid in $(jobs -p); do kill -KILL "${pid}" 2> /dev/null || true; done
}

cleanup_all() {
    local status=$?
    stop_children
    (exit "${status}")
    cleanup_workspace
}
trap cleanup_all EXIT

wait_for_file() {
    local path="$1" desc="$2" tries
    for (( tries=0; tries<100; tries++ )); do
        if [[ -e "${path}" ]]; then return 0; fi
        sleep 0.1
    done
    _record_fail "${desc}" "timed out waiting for ${path}"
}

wait_ready() {
    local service="$1" tries
    for (( tries=0; tries<100; tries++ )); do
        if grep -qx ready "${ROOT}/${service}.out" 2> /dev/null; then return 0; fi
        sleep 0.1
    done
    _record_fail "${service} JVM is ready" "no ready line in ${ROOT}/${service}.out"
}

release() {
    # shellcheck disable=SC2016
    timeout 5 bash -c 'echo go > "$1"' _ "$1"
}

# Mirror service_start_instance: run the instance wrapper in the background and record its PID.
start_instance() {
    local service="$1"
    "${ROOT}/${service}/bin/run.sh" > "${ROOT}/${service}.out" 2>&1 &
    PIDS[${service}]=$!
    printf '%s\n' "${PIDS[${service}]}" > "${ROOT}/${service}/temp/${service}.pid"
}

stop_instance() {
    local service="$1"
    kill "${PIDS[${service}]}" 2> /dev/null || true
    wait "${PIDS[${service}]}" 2> /dev/null || true
    rm -f "${ROOT}/${service}/temp/${service}.pid" "${ROOT}/hold1.${service}" "${ROOT}/hold2.${service}" \
        "${ROOT}/at1.${service}" "${ROOT}/at2.${service}"
}

hold_instance() {
    local service="$1"
    mkfifo "${ROOT}/hold1.${service}" "${ROOT}/hold2.${service}"
    start_instance "${service}"
    wait_for_file "${ROOT}/at1.${service}" "${service} reaches the run-script hold"
}

run_health() {
    HEALTH_RC=0
    HEALTH_OUT=$(bash "${ROOT}/archappl.bash" health 2>&1) || HEALTH_RC=$?
}

assert_has() {
    local text="$1" needle="$2" desc="$3"
    if [[ "${text}" == *"${needle}"* ]]; then
        _record_pass "${desc}"
    else
        _record_fail "${desc}" "missing: ${needle}; output: ${text}"
    fi
}

assert_last() {
    local text="$1" want="$2" desc="$3" last
    last="${text##*$'\n'}"
    assert_eq "${last}" "${want}" "${desc}"
}

# The configuration and the shipped wrapper of each instance.
mkdir -p "${ROOT}/classes" "${ROOT}/bin"
javac -d "${ROOT}/classes" "${TOP}/tests/fixtures/tomcat/org/apache/catalina/startup/Bootstrap.java"
cp "${LAUNCHER_SRC}" "${ROOT}/archappl.bash"
cat > "${ROOT}/archappl.conf" << EOF
JAVA_HOME="${JAVA_HOME_DIR}"
CATALINA_HOME="${ROOT}"
ARCHAPPL_STORAGE_TOP="${ROOT}"
ARCHAPPL_STORAGE_ALARM_PERCENT=100
EOF
cat > "${ROOT}/bin/catalina.sh" << EOF
#!/bin/sh
# Stand-in for Tomcat's catalina.sh: hold when asked, then replace the shell by the live JVM.
if [ -p "\${HEALTH_HOLD2}" ]; then
    : > "\${HEALTH_AT2}"
    read -r _ < "\${HEALTH_HOLD2}"
fi
exec "\${JAVA_HOME}/bin/java" -Dcatalina.base="\${CATALINA_BASE}" -Dcatalina.home="\${CATALINA_HOME}" \\
    -cp "${ROOT}/classes" org.apache.catalina.startup.Bootstrap start
EOF
chmod +x "${ROOT}/bin/catalina.sh"
for service in "${SERVICES[@]}"; do
    mkdir -p "${ROOT}/${service}/temp" "${ROOT}/${service}/conf" "${ROOT}/${service}/bin"
    cat > "${ROOT}/${service}/conf/${service}.conf" << EOF
HEALTH_HOLD2="${ROOT}/hold2.${service}"
HEALTH_AT2="${ROOT}/at2.${service}"
if [ -p "${ROOT}/hold1.${service}" ]; then
    : > "${ROOT}/at1.${service}"
    read -r _ < "${ROOT}/hold1.${service}"
fi
EOF
    sed -e "s|@INSTALL_LOCATION@|${ROOT}/${service}|g" -e "s|@SERVICE_NAME@|${service}|g" \
        -e "s|@ARCHAPPL_TOP@|${ROOT}|g" "${TOP}/site-template/run.sh.in" > "${ROOT}/${service}/bin/run.sh"
    chmod +x "${ROOT}/${service}/bin/run.sh"
done

# Four live instances.
for service in "${SERVICES[@]}"; do start_instance "${service}"; done
for service in "${SERVICES[@]}"; do wait_ready "${service}"; done
run_health
assert_status "${HEALTH_RC}" 0 "Four live JVMs are PRESENT"
assert_last "${HEALTH_OUT}" "health PRESENT all-four-processes-verified; application-readiness-not-checked" \
    "Four live JVMs report the PRESENT verdict"

# The same PID is first the run.sh shell, then the catalina.sh shell, then the JVM.
stop_instance mgmt
hold_instance mgmt
pid="${PIDS[mgmt]}"
run_health
assert_status "${HEALTH_RC}" 1 "A run.sh stage reports status 1"
assert_has "${HEALTH_OUT}" "mgmt pid=${pid} STARTING run-script" "The run.sh stage is STARTING run-script"
assert_last "${HEALTH_OUT}" "health STARTING instances-starting; application-readiness-not-checked" \
    "The run.sh stage reports the STARTING verdict"
release "${ROOT}/hold1.mgmt"
wait_for_file "${ROOT}/at2.mgmt" "mgmt reaches the catalina.sh hold"
run_health
assert_status "${HEALTH_RC}" 1 "A catalina.sh stage reports status 1"
assert_has "${HEALTH_OUT}" "mgmt pid=${pid} STARTING catalina-script" "The catalina.sh stage is STARTING catalina-script"
release "${ROOT}/hold2.mgmt"
wait_ready mgmt
run_health
assert_status "${HEALTH_RC}" 0 "The same PID is PRESENT once Java runs"
assert_has "${HEALTH_OUT}" "mgmt pid=${pid} PRESENT verified-process-presence" "The JVM keeps the PID of the held chain"

# A start older than the bound is a failure, in both stages.
stop_instance mgmt
hold_instance mgmt
sleep 2.2
HEALTH_RC=0
HEALTH_OUT=$(ARCHAPPL_HEALTH_STARTING_SECONDS=1 bash "${ROOT}/archappl.bash" health 2>&1) || HEALTH_RC=$?
assert_status "${HEALTH_RC}" 1 "A run.sh stage older than the bound reports status 1"
assert_has "${HEALTH_OUT}" "mgmt pid=${PIDS[mgmt]} FAIL startup-timeout" "A run.sh stage older than the bound is startup-timeout"
assert_last "${HEALTH_OUT}" "health FAIL one-or-more-invalid-instances" "The timeout reports the FAIL verdict"
release "${ROOT}/hold1.mgmt"
wait_for_file "${ROOT}/at2.mgmt" "mgmt reaches the catalina.sh hold again"
sleep 1.2
HEALTH_RC=0
HEALTH_OUT=$(ARCHAPPL_HEALTH_STARTING_SECONDS=1 bash "${ROOT}/archappl.bash" health 2>&1) || HEALTH_RC=$?
assert_has "${HEALTH_OUT}" "mgmt pid=${PIDS[mgmt]} FAIL startup-timeout" "A catalina.sh stage older than the bound is startup-timeout"
release "${ROOT}/hold2.mgmt"
wait_ready mgmt

# A failure outranks a start.
stop_instance mgmt
hold_instance mgmt
stop_instance etl
run_health
assert_status "${HEALTH_RC}" 1 "A failed instance and a starting one report status 1"
assert_has "${HEALTH_OUT}" "etl pid=- FAIL missing-pid-file" "The missing instance still fails"
assert_has "${HEALTH_OUT}" "mgmt pid=${PIDS[mgmt]} STARTING run-script" "The starting instance is still named"
assert_last "${HEALTH_OUT}" "health FAIL one-or-more-invalid-instances" "A failure outranks a start in the verdict"
start_instance etl
wait_ready etl
release "${ROOT}/hold1.mgmt"
wait_for_file "${ROOT}/at2.mgmt" "mgmt reaches the catalina.sh hold for the instance checks"

# A shell of another instance, or another executable, is not this instance starting.
sleep 300 &
other=$!
printf '%s\n' "${other}" > "${ROOT}/engine/temp/engine.pid"
run_health
assert_has "${HEALTH_OUT}" "engine pid=${other} FAIL wrong-java-executable" "An unrelated executable still fails"
kill "${other}" 2> /dev/null || true
printf '%s\n' "${PIDS[engine]}" > "${ROOT}/engine/temp/engine.pid"
printf '%s\n' "${PIDS[mgmt]}" > "${ROOT}/etl/temp/etl.pid"
run_health
assert_has "${HEALTH_OUT}" "etl pid=${PIDS[mgmt]} FAIL wrong-java-executable" \
    "A catalina.sh shell of another instance fails"
assert_has "${HEALTH_OUT}" "mgmt pid=${PIDS[mgmt]} STARTING catalina-script" "The owning instance is still STARTING"
printf '%s\n' "${PIDS[etl]}" > "${ROOT}/etl/temp/etl.pid"
release "${ROOT}/hold2.mgmt"
wait_ready mgmt

stop_instance retrieval
hold_instance retrieval
printf '%s\n' "${PIDS[retrieval]}" > "${ROOT}/etl/temp/etl.pid"
run_health
assert_has "${HEALTH_OUT}" "etl pid=${PIDS[retrieval]} FAIL wrong-java-executable" \
    "A run.sh shell of another instance fails"
printf '%s\n' "${PIDS[etl]}" > "${ROOT}/etl/temp/etl.pid"
release "${ROOT}/hold1.retrieval"
wait_for_file "${ROOT}/at2.retrieval" "retrieval reaches the catalina.sh hold"
release "${ROOT}/hold2.retrieval"
wait_ready retrieval

# The bound must be a whole number of seconds below the scheduled startup allowance.
for bound in 0 60 abc 1.5; do
    HEALTH_RC=0
    HEALTH_OUT=$(ARCHAPPL_HEALTH_STARTING_SECONDS="${bound}" bash "${ROOT}/archappl.bash" health 2>&1) || HEALTH_RC=$?
    assert_status "${HEALTH_RC}" 2 "A bound of ${bound} is refused"
    assert_has "${HEALTH_OUT}" "mgmt pid=- ERROR starting-invalid-bound" "A bound of ${bound} names the invalid bound"
done
HEALTH_RC=0
HEALTH_OUT=$(ARCHAPPL_HEALTH_STARTING_SECONDS=59 bash "${ROOT}/archappl.bash" health 2>&1) || HEALTH_RC=$?
assert_status "${HEALTH_RC}" 0 "A bound of 59 is accepted"

phase_pass "Health: instances that have not executed Java yet"
