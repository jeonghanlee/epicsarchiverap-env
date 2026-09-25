#!/usr/bin/env bash
# Phase 1: Logic checks.
# No build, no network, no setup. Pure structural verification of the
# Makefile system, configure/ tree, and document set after the cleanup.

set -euo pipefail

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TOP
readonly EXPECTED_BRANCH="${EXPECTED_BRANCH:-modernize}"
readonly EXPECTED_SRC_PATH="epicsarchiverap-maven-src"

# shellcheck source=lib/common.bash
source "${TOP}/tests/lib/common.bash"

phase_header "Phase 1: Logic"

# P1.1 Branch sanity (warn-only; not all developers run from the same branch)
current_branch="$(git -C "${TOP}" branch --show-current 2>/dev/null || printf 'unknown')"
if [[ "${current_branch}" == "${EXPECTED_BRANCH}" ]]; then
    _record_pass "On expected branch ${EXPECTED_BRANCH}"
else
    printf '  [WARN] On branch %s (expected %s)\n' "${current_branch}" "${EXPECTED_BRANCH}"
fi

# P1.2 No CONFIG_COMMON references survived in the Makefile system.
remaining=$(grep -rl 'CONFIG_COMMON' "${TOP}/configure/" 2>/dev/null || true)
assert_empty "${remaining}" "No CONFIG_COMMON references in configure/"

# P1.3 OS preset files exist as separately tracked Makefile fragments.
for preset in debian12 rocky8 macos macbrew githubmac; do
    assert_file "${TOP}/configure/os/${preset}.mk" "configure/os/${preset}.mk present"
done

# P1.4 Top-level Makefile rules parse cleanly.
make -C "${TOP}" -n build > "${WORKSPACE}/make-n-build.txt" 2>&1
assert_status $? 0 "make -n build parses"

# P1.5 All five OS conf targets parse and reference their preset.
for target in debian12.conf rocky8.conf macos.conf macbrew.conf githubmac.conf; do
    out=$(make -C "${TOP}" -n "${target}" 2>&1)
    rc=$?
    if [[ ${rc} -ne 0 ]]; then
        _record_fail "make -n ${target}" "rc=${rc} output=${out}"
    fi
    preset_name="${target%.conf}"
    if grep -q "configure/os/${preset_name}\\.mk" <<< "${out}"; then
        _record_pass "make -n ${target} references configure/os/${preset_name}.mk"
    else
        _record_fail "make -n ${target}" "preset include line not found"
    fi
done

# P1.6 SRC_PATH and ARCHAPPL_SITEID_TARGET_PATH resolve correctly.
src_path=$(make -C "${TOP}" --no-print-directory print-SRC_PATH 2>/dev/null | tail -1)
assert_eq "${src_path}" "${EXPECTED_SRC_PATH}" "SRC_PATH = ${EXPECTED_SRC_PATH}"

target_path=$(make -C "${TOP}" --no-print-directory print-ARCHAPPL_SITEID_TARGET_PATH 2>/dev/null | tail -1)
case "${target_path}" in
    */${EXPECTED_SRC_PATH}/src/sitespecific/*)
        _record_pass "ARCHAPPL_SITEID_TARGET_PATH well-formed: ${target_path}"
        ;;
    *)
        _record_fail "ARCHAPPL_SITEID_TARGET_PATH" "got: ${target_path}"
        ;;
esac

# P1.7 No surviving doc links to the four removed obsolete documents.
# CHANGELOG.md and tests/README.md legitimately mention the names while
# documenting the removal; exclude them from the link check.
for removed in README.ant.md README.centos7.md README.centos8.md README.javapkgs.md; do
    refs=$(grep -rln "${removed}" "${TOP}" --include='*.md' \
        --exclude=CHANGELOG.md --exclude-dir=tests 2>/dev/null || true)
    assert_empty "${refs}" "No live references to removed ${removed}"
done

# P1.8 Changelog rename applied (CHANGELOG.md kept, CHANGLOG.md gone).
assert_file "${TOP}/CHANGELOG.md" "CHANGELOG.md exists"
assert_not_file "${TOP}/CHANGLOG.md" "CHANGLOG.md (typo) removed"

# P1.9 checkfile macro: deletes an existing file, leaves an absent one alone.
# Exercise the real macro from configure/RULES_FUNC through an ad-hoc makefile;
# make -n prints the branch the macro selects without running rm.
checkfile_probe() {
    # shellcheck disable=SC2016  # $(TOP) and $(call ...) are make syntax, not shell
    printf 'TOP:=%s\ninclude $(TOP)/configure/RULES_FUNC\nprobe:\n\t$(call checkfile,%s)\n' \
        "${TOP}" "$1" | make -n -f - probe 2>&1 || true
}
touch "${WORKSPACE}/checkfile-present.conf"
rm -f "${WORKSPACE}/checkfile-absent.conf"
present_out=$(checkfile_probe "${WORKSPACE}/checkfile-present.conf")
absent_out=$(checkfile_probe "${WORKSPACE}/checkfile-absent.conf")
case "${present_out}" in
    *"rm -f"*) _record_pass "checkfile removes an existing file" ;;
    *)         _record_fail "checkfile removes an existing file" "got: ${present_out}" ;;
esac
case "${absent_out}" in
    *"rm -f"*) _record_fail "checkfile leaves an absent file alone" "got: ${absent_out}" ;;
    *)         _record_pass "checkfile leaves an absent file alone" ;;
esac
# The caller must pass a bare path: a quoted argument never matches $(wildcard).
quoted_calls=$(grep -n 'call checkfile,.*"' "${TOP}/configure/RULES_SQL" || true)
assert_empty "${quoted_calls}" "checkfile caller in RULES_SQL passes an unquoted path"

# P1.10 serverxml.install: each service pairs with its own shutdown-port variable.
engine_line=$(grep -E 'engine/conf/server\.xml' "${TOP}/configure/RULES_INSTALL" | grep -c 'ARCHAPPL_SHUTDOWN_ENGINE_PORT' || true)
etl_line=$(grep -E 'etl/conf/server\.xml' "${TOP}/configure/RULES_INSTALL" | grep -c 'ARCHAPPL_SHUTDOWN_ETL_PORT' || true)
assert_eq "${engine_line}" "1" "serverxml.install engine uses ARCHAPPL_SHUTDOWN_ENGINE_PORT"
assert_eq "${etl_line}" "1" "serverxml.install etl uses ARCHAPPL_SHUTDOWN_ETL_PORT"

# P1.11 JDBC driver rules removed: Maven packages mariadb-java-client into each WAR.
jdbc_rules=$(grep -n 'jdbc' "${TOP}/configure/RULES_REQ" || true)
assert_empty "${jdbc_rules}" "No get.jdbc/install.jdbc rules in RULES_REQ"

# P1.12 Toolchain: distro JDK plus the source Maven Wrapper; package lists
# replace the hand-written package scripts.
for gone in required_pkgs.sh install_java_pkgs_local.bash; do
    assert_not_file "${TOP}/scripts/${gone}" "legacy ${gone} removed"
done
assert_file "${TOP}/scripts/install_os_packages.bash" "package-list installer present"
bash -n "${TOP}/scripts/install_os_packages.bash"
assert_status $? 0 "installer parses (bash -n)"
assert_file "${TOP}/configure/os/debian13.pkgs" "Debian 13 package list present"
jdkpkg=$(grep -c '^openjdk-21-jdk-headless$' "${TOP}/configure/os/debian13.pkgs" || true)
assert_eq "${jdkpkg}" "1" "Debian 13 list names the distro JDK"
stale=$(grep -rln 'java-env\|MAVEN_HOME\|install_java_pkgs_local' "${TOP}/configure/" "${TOP}/scripts/" "${TOP}/README.md" 2>/dev/null || true)
assert_empty "${stale}" "No java-env, MAVEN_HOME, or local-install references in configure/, scripts/, README.md"
mvncmd=$(make -C "${TOP}" --no-print-directory print-MAVEN_CMD 2>/dev/null | tail -1)
case "${mvncmd}" in
    */mvnw) _record_pass "MAVEN_CMD is the source Maven Wrapper: ${mvncmd}" ;;
    *)      _record_fail "MAVEN_CMD is the source Maven Wrapper" "got: ${mvncmd}" ;;
esac

# P1.13 The command wrapper must preserve the actual child exit status.
logged_rc=0
run_logged "Successful child command" bash -c 'exit 0' || logged_rc=$?
assert_status "${logged_rc}" 0 "run_logged preserves success"
logged_rc=0
run_logged "Failing child command" bash -c 'exit 23' || logged_rc=$?
assert_status "${logged_rc}" 23 "run_logged preserves failure"

# P1.14 The launcher uses Tomcat scripts and needs no jsvc package.
launcher_text=$(cat "${TOP}/scripts/archappl.bash")
case "${launcher_text}" in
    *jsvc*) _record_fail "Launcher has no jsvc path" "Found a jsvc reference" ;;
    *)      _record_pass "Launcher has no jsvc path" ;;
esac
for package_list in "${TOP}/configure/os/"*.pkgs; do
    package_os="${package_list##*/}"
    package_os="${package_os%.pkgs}"
    package_rc=0
    package_output=$(bash "${TOP}/scripts/install_os_packages.bash" \
        --os "${package_os}" --list-only) || package_rc=$?
    assert_status "${package_rc}" 0 "Package selection succeeds for ${package_os}"
    assert_nonempty "${package_output}" "Resolved package list for ${package_os} is nonempty"
    case $'\n'"${package_output}"$'\n' in
        *$'\njsvc\n'*) _record_fail "No jsvc package for ${package_os}" "Found jsvc in the resolved list" ;;
        *)             _record_pass "No jsvc package for ${package_os}" ;;
    esac
done

# P1.15 Maven CLI flags reach every target through the real Makefile.
# The settings path is only rendered by make -n; no settings file is read.
maven_flags="-B -ntp -gs ${WORKSPACE}/maven-settings.xml"
for maven_target in clean.mvn build.mvn build.mvn2 build.mvn3 build.war build.mvndeps; do
    maven_rc=0
    maven_output=$(make -C "${TOP}" --no-print-directory -n "${maven_target}" \
        "MAVEN_FLAGS=${maven_flags}" 2>&1) || maven_rc=$?
    assert_status "${maven_rc}" 0 "make -n ${maven_target} parses with MAVEN_FLAGS"
    case "${maven_output}" in
        *"${mvncmd} ${maven_flags} "*) _record_pass "${maven_target} passes MAVEN_FLAGS after the wrapper" ;;
        *) _record_fail "${maven_target} passes MAVEN_FLAGS after the wrapper" "got: ${maven_output}" ;;
    esac
done

# P1.16 A database existence check that cannot confirm the database stops the
# caller with a non-zero status and a stderr message. The real
# query_from_sql_file runs against a closed loopback port, so the client fails
# before any server is reached. Application-account callers check existence
# through SQL_DBUSER_CMD; only get_admin_crypt_password keeps the admin check.
db_stderr="${WORKSPACE}/db-check-stderr.txt"
db_rc=0
DB_ADMIN=p1_admin DB_ADMIN_PASS=x DB_USER=p1_user DB_USER_PASS=x \
DB_HOST_NAME=127.0.0.1 DB_HOST_PORT=1 bash -c '
    source "$1/scripts/mariadb_generic_function.bash"
    query_from_sql_file archappl /dev/null
' _ "${TOP}" > /dev/null 2> "${db_stderr}" || db_rc=$?
if [[ "${db_rc}" -ne 0 ]]; then
    _record_pass "query_from_sql_file exits non-zero when the check fails (rc=${db_rc})"
else
    _record_fail "query_from_sql_file exits non-zero when the check fails" "got rc=0"
fi
case "$(cat "${db_stderr}")" in
    *"Cannot check the database >> archappl <<"*) _record_pass "Failed existence check is reported on stderr" ;;
    *) _record_fail "Failed existence check is reported on stderr" "stderr: $(cat "${db_stderr}")" ;;
esac
for db_script in mariadb_generic_function.bash mariadb_setup.bash; do
    # shellcheck disable=SC2016  # the pattern matches the literal source text
    zero_exits=$(grep -A1 'noDbMessage "${db_name}";' "${TOP}/scripts/${db_script}" \
        | grep -E '^[[:space:]]*exit;?[[:space:]]*$' || true)
    assert_empty "${zero_exits}" "No zero-status exit after noDbMessage in ${db_script}"
    admin_checks=$(awk '/^function /{f=$2} /db_exist=\$\(isDb / && !/SQL_DBUSER_CMD/{print f}' \
        "${TOP}/scripts/${db_script}")
    case "${db_script}" in
        mariadb_setup.bash) assert_eq "${admin_checks}" "get_admin_crypt_password" \
            "Only get_admin_crypt_password checks through the admin account in ${db_script}" ;;
        *) assert_empty "${admin_checks}" "Every existence check uses the application account in ${db_script}" ;;
    esac
done

# P1.17 Backup listing and restore stop with a non-zero status and a stderr
# message when they cannot run. The real mariadb_setup.bash runs from an
# isolated copy of the Make system, whose site-template/mariadb.conf comes
# from the real db.conf rule; every case fails before a database client runs.
db_env="${WORKSPACE}/db-env"
backup_stderr="${WORKSPACE}/db-backup-stderr.txt"
mkdir -p "${db_env}" "${WORKSPACE}/db-backup-empty"
cp -a "${TOP}/Makefile" "${TOP}/configure" "${TOP}/scripts" "${TOP}/site-template" "${db_env}/"
rm -f "${db_env}/site-template/mariadb.conf" "${db_env}/configure/"*.local
make -C "${db_env}" -s db.conf > /dev/null 2>&1
assert_file "${db_env}/site-template/mariadb.conf" "db.conf renders mariadb.conf in the isolated copy"
db_cases=(
    "dbBackupList with a missing directory|There is no >>|dbBackupList ${WORKSPACE}/db-backup-missing"
    "dbRestore without a date|Date is missing|dbRestore"
    "dbRestore with a missing directory|There is no >>|dbRestore 2601010000 ${WORKSPACE}/db-backup-missing"
    "dbRestore with an absent backup file|There is no readable >>|dbRestore 2601010000 ${WORKSPACE}/db-backup-empty"
)
for db_case in "${db_cases[@]}"; do
    IFS='|' read -r case_desc case_text case_args <<< "${db_case}"
    db_rc=0
    # shellcheck disable=SC2086  # case_args holds the dispatch word and its arguments
    bash "${db_env}/scripts/mariadb_setup.bash" ${case_args} > /dev/null 2> "${backup_stderr}" || db_rc=$?
    if [[ "${db_rc}" -ne 0 ]]; then
        _record_pass "${case_desc} exits non-zero (rc=${db_rc})"
    else
        _record_fail "${case_desc} exits non-zero" "got rc=0"
    fi
    case "$(cat "${backup_stderr}")" in
        *"${case_text}"*) _record_pass "${case_desc} reports on stderr" ;;
        *) _record_fail "${case_desc} reports on stderr" "stderr: $(cat "${backup_stderr}")" ;;
    esac
done

# P1.18 The store granularity and hold reach the rendered policy through Make
# variables, and a value the source cannot accept stops conf.policies before
# policies.py is written. The real conf.policies rule runs from an isolated
# copy of the Make system so nothing under the checkout is rewritten.
policy_env="${WORKSPACE}/policy-env"
mkdir -p "${policy_env}"
cp -a "${TOP}/Makefile" "${TOP}/configure" "${TOP}/site-template" "${policy_env}/"
rm -f "${policy_env}/site-template/policies.py" "${policy_env}/configure/"*.local
policy_out="${policy_env}/site-template/policies.py"
policy_rc=0
make -C "${policy_env}" -s conf.policies > "${WORKSPACE}/policy-default.txt" 2>&1 || policy_rc=$?
assert_status "${policy_rc}" 0 "conf.policies renders with the default store values"
for expected in "name=STS&rootFolder=/arch/sts/ArchiverStore&partitionGranularity=PARTITION_HOUR&hold=2&" \
                "name=MTS&rootFolder=/arch/mts/ArchiverStore&partitionGranularity=PARTITION_DAY&hold=2&" \
                "name=LTS&rootFolder=/arch/lts/ArchiverStore&partitionGranularity=PARTITION_YEAR'"; do
    case "$(cat "${policy_out}")" in
        *"${expected}"*) _record_pass "Default policy carries ${expected%%&*}'s store settings" ;;
        *) _record_fail "Default policy carries ${expected%%&*}'s store settings" "missing: ${expected}" ;;
    esac
done
rm -f "${policy_out}"
policy_rc=0
make -C "${policy_env}" -s conf.policies ARCHAPPL_STS_GRANULARITY=PARTITION_5MIN ARCHAPPL_MTS_GRANULARITY=PARTITION_HOUR \
    ARCHAPPL_LTS_GRANULARITY=PARTITION_DAY ARCHAPPL_STS_HOLD=3 > "${WORKSPACE}/policy-test.txt" 2>&1 || policy_rc=$?
assert_status "${policy_rc}" 0 "conf.policies renders with test store values"
for expected in "name=STS&rootFolder=/arch/sts/ArchiverStore&partitionGranularity=PARTITION_5MIN&hold=3&" \
                "name=MTS&rootFolder=/arch/mts/ArchiverStore&partitionGranularity=PARTITION_HOUR&hold=2&" \
                "name=LTS&rootFolder=/arch/lts/ArchiverStore&partitionGranularity=PARTITION_DAY'"; do
    case "$(cat "${policy_out}")" in
        *"${expected}"*) _record_pass "Test policy carries ${expected%%&*}'s store settings" ;;
        *) _record_fail "Test policy carries ${expected%%&*}'s store settings" "missing: ${expected}" ;;
    esac
done
for invalid in "ARCHAPPL_MTS_GRANULARITY=PARTITION_WEEK" "ARCHAPPL_STS_GRANULARITY=PARTITION_HOUR PARTITION_DAY" \
               "ARCHAPPL_STS_HOLD=0" "ARCHAPPL_MTS_HOLD=two"; do
    rm -f "${policy_out}"
    policy_rc=0
    make -C "${policy_env}" -s conf.policies "${invalid}" > "${WORKSPACE}/policy-invalid.txt" 2>&1 || policy_rc=$?
    if [[ "${policy_rc}" -ne 0 ]]; then
        _record_pass "conf.policies rejects ${invalid} (rc=${policy_rc})"
    else
        _record_fail "conf.policies rejects ${invalid}" "got rc=0"
    fi
    assert_not_file "${policy_out}" "No policies.py written for ${invalid}"
done

# P1.19 The appliance unit runs the launcher as its main process with the four
# Tomcats in the foreground, and Tomcat's own logs leave no file behind. The
# real conf.systemd0 rule renders the unit from an isolated copy of the Make
# system; the launcher, the run wrapper and the skel configuration are read
# as shipped.
unit_env="${WORKSPACE}/unit-env"
mkdir -p "${unit_env}"
cp -a "${TOP}/Makefile" "${TOP}/configure" "${TOP}/site-template" "${unit_env}/"
rm -f "${unit_env}/configure/"*.local "${unit_env}/site-template/systemd/"*.service
unit_out="${unit_env}/site-template/systemd/epicsarchiverap-maven.service"
unit_rc=0
make -C "${unit_env}" -s conf.systemd0 > "${WORKSPACE}/unit-render.txt" 2>&1 || unit_rc=$?
assert_status "${unit_rc}" 0 "conf.systemd0 renders the appliance unit"
assert_file "${unit_out}" "Rendered appliance unit exists"
unit_text=$(cat "${unit_out}")
for directive in "Type=simple" "KillMode=mixed" "Restart=no" "TimeoutStopSec=300s" "/archappl.bash\" service"; do
    case "${unit_text}" in
        *"${directive}"*) _record_pass "Appliance unit carries ${directive}" ;;
        *) _record_fail "Appliance unit carries ${directive}" "missing in ${unit_out}" ;;
    esac
done
case "${unit_text}" in
    *ExecStop=*|*Type=forking*) _record_fail "Appliance unit has no ExecStop and is not forking" "found one in ${unit_out}" ;;
    *) _record_pass "Appliance unit has no ExecStop and is not forking" ;;
esac
launcher_rc=0
bash -n "${TOP}/scripts/archappl.bash" || launcher_rc=$?
assert_status "${launcher_rc}" 0 "Launcher parses"
if command -v shellcheck > /dev/null 2>&1; then
    launcher_rc=0
    shellcheck -x "${TOP}/scripts/archappl.bash" > "${WORKSPACE}/launcher-shellcheck.txt" 2>&1 || launcher_rc=$?
    assert_status "${launcher_rc}" 0 "Launcher passes shellcheck"
fi
launcher_text=$(cat "${TOP}/scripts/archappl.bash")
for needle in "systemd-cat --identifier=\"archappl-\${service}\" --level-prefix=true" "wait -n" "bin/run.sh"; do
    case "${launcher_text}" in
        *"${needle}"*) _record_pass "Launcher service mode uses ${needle}" ;;
        *) _record_fail "Launcher service mode uses ${needle}" "missing" ;;
    esac
done
case "${launcher_text}" in
    *archappl_service.log*) _record_fail "Launcher no longer points at archappl_service.log" "found the stale hint" ;;
    *) _record_pass "Launcher no longer points at archappl_service.log" ;;
esac
run_wrapper=$(cat "${TOP}/site-template/run.sh.in")
# shellcheck disable=SC2016
case "${run_wrapper}" in
    *'exec "${CATALINA_HOME}/bin/catalina.sh" run'*) _record_pass "Run wrapper execs catalina.sh run" ;;
    *) _record_fail "Run wrapper execs catalina.sh run" "missing exec line" ;;
esac
install_rules=$(make -C "${unit_env}" --no-print-directory -n install.mgmt 2>&1 || true)
case "${install_rules}" in
    *"run.sh.in > "*"/mgmt/bin/run.sh"*) _record_pass "Instance install renders bin/run.sh" ;;
    *) _record_fail "Instance install renders bin/run.sh" "got: ${install_rules}" ;;
esac
assert_not_file "${TOP}/site-template/skel/conf/logging.properties" "No JULI logging.properties is shipped"
case "$(cat "${TOP}/site-template/skel/conf/server.xml")" in
    *'prefix="localhost_access_log" suffix=".txt" maxDays="90"'*) _record_pass "Access log valve carries maxDays=90" ;;
    *) _record_fail "Access log valve carries maxDays=90" "attribute missing" ;;
esac
assert_not_file "${TOP}/site-template/log4j.properties.in" "Dead log4j.properties template is gone"
log4j_rc=0
make -C "${unit_env}" --no-print-directory -n conf.log4j > /dev/null 2>&1 || log4j_rc=$?
if [[ "${log4j_rc}" -ne 0 ]]; then
    _record_pass "conf.log4j is no longer a target (rc=${log4j_rc})"
else
    _record_fail "conf.log4j is no longer a target" "make -n conf.log4j succeeded"
fi

# P1.21 Tomcat's own logging and java.util.logging go through log4j2: each
# instance gets bin/setenv.sh with the log4j class path and LogManager, the
# four jars from the source build, and log4j2-tomcat.xml with the priority
# prefix. The real install rule is expanded with make -n from the isolated
# copy made for P1.19.
setenv_text=$(cat "${TOP}/site-template/setenv.sh.in")
# shellcheck disable=SC2016
for needle in 'CLASSPATH="${CATALINA_BASE}/log4j/*:${CATALINA_BASE}/log4j/"' \
              'LOGGING_MANAGER="-Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager"'; do
    case "${setenv_text}" in
        *"${needle}"*) _record_pass "setenv.sh sets ${needle%%=*}" ;;
        *) _record_fail "setenv.sh sets ${needle%%=*}" "missing: ${needle}" ;;
    esac
done
tomcat_log4j=$(cat "${TOP}/site-template/skel/log4j/log4j2-tomcat.xml")
# shellcheck disable=SC2016
for needle in 'ERROR=&lt;3&gt;' 'INFO=&lt;6&gt;' 'level="${env:ARCHAPPL_ROOT_LOGGER_LEVEL:-INFO}"' 'monitorInterval='; do
    case "${tomcat_log4j}" in
        *"${needle}"*) _record_pass "log4j2-tomcat.xml carries ${needle}" ;;
        *) _record_fail "log4j2-tomcat.xml carries ${needle}" "missing" ;;
    esac
done
install_rules=$(make -C "${unit_env}" --no-print-directory -n install.engine 2>&1 || true)
for needle in "setenv.sh.in /opt/epicsarchiverap-maven/engine/bin/setenv.sh" \
              "rm -f /opt/epicsarchiverap-maven/engine/conf/logging.properties" \
              "test -d ${unit_env}/epicsarchiverap-maven-src/target/tomcat-log4j" \
              "target/tomcat-log4j/*.jar /opt/epicsarchiverap-maven/engine/log4j/"; do
    case "${install_rules}" in
        *"${needle}"*) _record_pass "Instance install carries: ${needle}" ;;
        *) _record_fail "Instance install carries: ${needle}" "got: ${install_rules}" ;;
    esac
done

phase_pass "Phase 1: Logic"

# Real launcher negatives and isolated unit installation; no systemd mutation.
python3 "${TOP}/tests/health-local.py"
