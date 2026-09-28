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
for preset in debian12 rocky8; do
    assert_file "${TOP}/configure/os/${preset}.mk" "configure/os/${preset}.mk present"
done

# P1.4 Top-level Makefile rules parse cleanly.
make -C "${TOP}" -n build > "${WORKSPACE}/make-n-build.txt" 2>&1
assert_status $? 0 "make -n build parses"

# P1.5 Both OS conf targets parse and reference their preset.
for target in debian12.conf rocky8.conf; do
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

# P1.7 No tracked document links to the five removed obsolete documents.
# CHANGELOG.md, the milestone register and tests/README.md legitimately
# mention the names while recording the removal; exclude them from the
# link check. Untracked working files are outside the check. git grep exits
# 1 when nothing matches; any higher status means the search did not run.
for removed in README.ant.md README.centos7.md README.centos8.md README.javapkgs.md README.macos.md; do
    refs_rc=0
    refs=$(git -C "${TOP}" grep -l -F "${removed}" -- '*.md' \
        ':!CHANGELOG.md' ':!docs/milestone-*.md' ':!tests/' 2>/dev/null) || refs_rc=$?
    if [[ ${refs_rc} -gt 1 ]]; then
        _record_fail "No live references to removed ${removed}" "git grep rc=${refs_rc}"
    else
        assert_empty "${refs}" "No live references to removed ${removed}"
    fi
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

# P1.20 The WARs' own log4j2 configuration is in effect: no site log4j2.xml is
# shipped or installed, and the rendered archappl.conf exports the root level
# with INFO as the default and a commented site override hook. The real
# conf.archappl rule renders from the isolated copy made for P1.19.
assert_not_file "${TOP}/site-template/log4j2.xml" "No site log4j2.xml is shipped"
install_rules=$(make -C "${unit_env}" --no-print-directory -n services.install 2>&1 || true)
case "${install_rules}" in
    *log4j2*) _record_fail "Install rules carry no log4j2 step" "found a log4j2 reference" ;;
    *) _record_pass "Install rules carry no log4j2 step" ;;
esac
conf_out="${unit_env}/site-template/archappl.conf"
rm -f "${conf_out}"
conf_rc=0
make -C "${unit_env}" -s conf.archappl > "${WORKSPACE}/conf-default.txt" 2>&1 || conf_rc=$?
assert_status "${conf_rc}" 0 "conf.archappl renders with the default level"
conf_text=$(cat "${conf_out}")
case "${conf_text}" in
    *$'\nARCHAPPL_ROOT_LOGGER_LEVEL=INFO\n'*) _record_pass "archappl.conf exports ARCHAPPL_ROOT_LOGGER_LEVEL=INFO by default" ;;
    *) _record_fail "archappl.conf exports ARCHAPPL_ROOT_LOGGER_LEVEL=INFO by default" "missing" ;;
esac
case "${conf_text}" in
    *$'\nLOG4J_CONFIGURATION_FILE='*) _record_fail "LOG4J_CONFIGURATION_FILE stays a commented hook" "an active assignment remains" ;;
    *'#LOG4J_CONFIGURATION_FILE='*) _record_pass "LOG4J_CONFIGURATION_FILE stays a commented hook" ;;
    *) _record_fail "LOG4J_CONFIGURATION_FILE stays a commented hook" "hook missing" ;;
esac
rm -f "${conf_out}"
conf_rc=0
make -C "${unit_env}" -s conf.archappl ARCHAPPL_ROOT_LOGGER_LEVEL=WARN > "${WORKSPACE}/conf-warn.txt" 2>&1 || conf_rc=$?
assert_status "${conf_rc}" 0 "conf.archappl renders with a WARN override"
case "$(cat "${conf_out}")" in
    *$'\nARCHAPPL_ROOT_LOGGER_LEVEL=WARN\n'*) _record_pass "The level override reaches archappl.conf" ;;
    *) _record_fail "The level override reaches archappl.conf" "WARN missing" ;;
esac
# The site override file one directory above the checkout must win over the
# shipped default; the command-line check above cannot show include order.
rm -f "${conf_out}"
printf 'ARCHAPPL_ROOT_LOGGER_LEVEL:=ERROR\n' > "${unit_env}/../CONFIG_SITE.local"
conf_rc=0
make -C "${unit_env}" -s conf.archappl > "${WORKSPACE}/conf-local.txt" 2>&1 || conf_rc=$?
rm -f "${unit_env}/../CONFIG_SITE.local"
assert_status "${conf_rc}" 0 "conf.archappl renders with a level in ../CONFIG_SITE.local"
case "$(cat "${conf_out}")" in
    *$'\nARCHAPPL_ROOT_LOGGER_LEVEL=ERROR\n'*) _record_pass "A level in ../CONFIG_SITE.local reaches archappl.conf" ;;
    *) _record_fail "A level in ../CONFIG_SITE.local reaches archappl.conf" "the shipped default won" ;;
esac
rm -f "${conf_out}"
conf_rc=0
make -C "${unit_env}" -s conf.archappl ARCHAPPL_LOG4J_SITE_FILE=/opt/site/log4j2-site.xml > "${WORKSPACE}/conf-site.txt" 2>&1 || conf_rc=$?
assert_status "${conf_rc}" 0 "conf.archappl renders with a site log4j2 file"
case "$(cat "${conf_out}")" in
    *$'\nLOG4J_CONFIGURATION_FILE="/opt/site/log4j2-site.xml"\n'*) _record_pass "ARCHAPPL_LOG4J_SITE_FILE renders an active LOG4J_CONFIGURATION_FILE" ;;
    *) _record_fail "ARCHAPPL_LOG4J_SITE_FILE renders an active LOG4J_CONFIGURATION_FILE" "line missing" ;;
esac
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

# P1.22 The launcher's loglevel command checks its arguments before any
# request, needs curl, and reports a refused request. The shipped launcher
# runs from a copy with an archappl.conf whose mgmt port has no listener.
# Every run drops an ARCHAPPL_MGMT_PORT exported by the caller, so the
# copy's archappl.conf alone decides the port.
ll_env="${WORKSPACE}/loglevel-env"
mkdir -p "${ll_env}/nocurl"
cp "${TOP}/scripts/archappl.bash" "${ll_env}/"
printf 'ARCHAPPL_MGMT_PORT=1\n' > "${ll_env}/archappl.conf"
ll_rc=0
env -u ARCHAPPL_MGMT_PORT bash "${ll_env}/archappl.bash" loglevel nosuch > "${ll_env}/out.txt" 2>&1 || ll_rc=$?
assert_status "${ll_rc}" 2 "loglevel rejects an unknown component"
ll_rc=0
env -u ARCHAPPL_MGMT_PORT bash "${ll_env}/archappl.bash" loglevel engine root LOUD > "${ll_env}/out.txt" 2>&1 || ll_rc=$?
assert_status "${ll_rc}" 2 "loglevel rejects an unknown level"
ll_rc=0
env -u ARCHAPPL_MGMT_PORT bash "${ll_env}/archappl.bash" loglevel engine root debug > "${ll_env}/out.txt" 2>&1 || ll_rc=$?
assert_status "${ll_rc}" 1 "loglevel accepts a lower-case level and reports a refused request"
case "$(cat "${ll_env}/out.txt")" in
    *"setLogLevel?component=engine&logger=root&level=DEBUG"*" failed:"*) _record_pass "loglevel sends the level upper case and names the failed request" ;;
    *) _record_fail "loglevel sends the level upper case and names the failed request" "got: $(cat "${ll_env}/out.txt")" ;;
esac
for tool in realpath date; do ln -sf "$(command -v "${tool}")" "${ll_env}/nocurl/${tool}"; done
ll_rc=0
env -u ARCHAPPL_MGMT_PORT PATH="${ll_env}/nocurl" "$(command -v bash)" "${ll_env}/archappl.bash" loglevel engine > "${ll_env}/out.txt" 2>&1 || ll_rc=$?
assert_status "${ll_rc}" 2 "loglevel stops when curl is absent"
case "$(cat "${ll_env}/out.txt")" in
    *"curl is required"*) _record_pass "loglevel names curl when it is absent" ;;
    *) _record_fail "loglevel names curl when it is absent" "got: $(cat "${ll_env}/out.txt")" ;;
esac
# A reply other than 200 is a failed request: a local HTTP server that
# answers 404 stands in for the transport only, and the shipped launcher runs
# unchanged against it.
ll_port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')
python3 -c 'import http.server, sys
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_error(404)
    def log_message(self, *args):
        pass
http.server.HTTPServer(("127.0.0.1", int(sys.argv[1])), H).serve_forever()' "${ll_port}" &
ll_server=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do
    if python3 -c 'import socket, sys; socket.create_connection(("127.0.0.1", int(sys.argv[1])), 1)' "${ll_port}" 2> /dev/null; then break; fi
    sleep 0.2
done
printf 'ARCHAPPL_MGMT_PORT=%s\n' "${ll_port}" > "${ll_env}/archappl.conf"
ll_rc=0
env -u ARCHAPPL_MGMT_PORT bash "${ll_env}/archappl.bash" loglevel engine > "${ll_env}/out.txt" 2>&1 || ll_rc=$?
kill "${ll_server}" 2> /dev/null || true
wait "${ll_server}" 2> /dev/null || true
assert_status "${ll_rc}" 1 "loglevel treats an HTTP 404 reply as a failed request"
case "$(cat "${ll_env}/out.txt")" in
    *"getLogLevel returned HTTP 404"*) _record_pass "loglevel names the HTTP status of a failed reply" ;;
    *) _record_fail "loglevel names the HTTP status of a failed reply" "got: $(cat "${ll_env}/out.txt")" ;;
esac
# An archappl.conf installed before the port was added stops the command.
printf '# no mgmt port\n' > "${ll_env}/archappl.conf"
ll_rc=0
env -u ARCHAPPL_MGMT_PORT bash "${ll_env}/archappl.bash" loglevel engine > "${ll_env}/out.txt" 2>&1 || ll_rc=$?
assert_status "${ll_rc}" 2 "loglevel stops when archappl.conf has no mgmt port"
case "$(cat "${ll_env}/out.txt")" in
    *"ARCHAPPL_MGMT_PORT is missing"*) _record_pass "loglevel names the missing mgmt port" ;;
    *) _record_fail "loglevel names the missing mgmt port" "got: $(cat "${ll_env}/out.txt")" ;;
esac
rm -f "${conf_out}"
make -C "${unit_env}" -s conf.archappl > /dev/null 2>&1 || true
case "$(cat "${conf_out}")" in
    *$'\nARCHAPPL_MGMT_PORT=17665\n'*) _record_pass "archappl.conf carries ARCHAPPL_MGMT_PORT" ;;
    *) _record_fail "archappl.conf carries ARCHAPPL_MGMT_PORT" "missing" ;;
esac

# P1.23 status prints the mgmt URLs with the configured port, and the shipped
# default when an older archappl.conf lacks it. Only the three URL lines are
# judged; the PID lines and the exit status depend on running instances.
printf 'ARCHAPPL_MGMT_PORT=18765\n' > "${ll_env}/archappl.conf"
env -u ARCHAPPL_MGMT_PORT bash "${ll_env}/archappl.bash" status > "${ll_env}/status.txt" 2>&1 || true
st_urls=$(grep -c ':18765/mgmt/ui/index.html$' "${ll_env}/status.txt" || true)
assert_eq "${st_urls}" "3" "status prints the configured mgmt port in all three URLs"
printf '# no mgmt port\n' > "${ll_env}/archappl.conf"
env -u ARCHAPPL_MGMT_PORT bash "${ll_env}/archappl.bash" status > "${ll_env}/status.txt" 2>&1 || true
st_urls=$(grep -c ':17665/mgmt/ui/index.html$' "${ll_env}/status.txt" || true)
assert_eq "${st_urls}" "3" "status falls back to 17665 without ARCHAPPL_MGMT_PORT"

# P1.24 DB_BACKEND selects the configuration database. The default renders the
# MariaDB resource and unit as before; sqlite set in ../CONFIG_SITE.local
# renders the SQLite resource and a unit without mariadb.service; any other
# value stops both renderings. The shipped SQLite schema rules run with the
# real sqlite3 against a file in the workspace, as the running user.
be_env="${WORKSPACE}/backend-env"
mkdir -p "${be_env}"
cp -a "${TOP}/Makefile" "${TOP}/configure" "${TOP}/site-template" "${be_env}/"
rm -f "${be_env}/configure/"*.local "${be_env}/site-template/context.xml" "${be_env}/site-template/systemd/"*.service
be_ctx="${be_env}/site-template/context.xml"
be_unit="${be_env}/site-template/systemd/epicsarchiverap-maven.service"
be_rc=0
make -C "${be_env}" -s conf.context conf.systemd0 > "${WORKSPACE}/backend-mariadb.txt" 2>&1 || be_rc=$?
assert_status "${be_rc}" 0 "The default backend renders context.xml and the unit"
for expected in 'driverClassName="org.mariadb.jdbc.Driver"' 'url="jdbc:mariadb://127.0.0.1:3306/archappl"' 'maxActive="10"'; do
    case "$(cat "${be_ctx}")" in
        *"${expected}"*) _record_pass "MariaDB resource carries ${expected}" ;;
        *) _record_fail "MariaDB resource carries ${expected}" "missing in ${be_ctx}" ;;
    esac
done
case "$(grep -E '^(After|Requires)=' "${be_unit}")" in
    *'After=network.target mariadb.service'*'Requires=mariadb.service'*) _record_pass "MariaDB unit requires mariadb.service" ;;
    *) _record_fail "MariaDB unit requires mariadb.service" "$(grep -E '^(After|Requires)=' "${be_unit}")" ;;
esac
rm -f "${be_ctx}" "${be_unit}"
printf 'DB_BACKEND:=sqlite\n' > "${be_env}/../CONFIG_SITE.local"
be_rc=0
make -C "${be_env}" -s conf.context conf.systemd0 > "${WORKSPACE}/backend-sqlite.txt" 2>&1 || be_rc=$?
rm -f "${be_env}/../CONFIG_SITE.local"
assert_status "${be_rc}" 0 "sqlite in ../CONFIG_SITE.local renders context.xml and the unit"
for expected in 'driverClassName="org.sqlite.JDBC"' 'url="jdbc:sqlite:/arch/config/archappl.sqlite?journal_mode=WAL"' 'maxActive="1"'; do
    case "$(cat "${be_ctx}")" in
        *"${expected}"*) _record_pass "SQLite resource carries ${expected}" ;;
        *) _record_fail "SQLite resource carries ${expected}" "missing in ${be_ctx}" ;;
    esac
done
case "$(cat "${be_ctx}")" in
    *username=*|*password=*) _record_fail "SQLite resource carries no user or password" "found in ${be_ctx}" ;;
    *) _record_pass "SQLite resource carries no user or password" ;;
esac
case "$(cat "${be_unit}")" in
    *mariadb.service*) _record_fail "SQLite unit does not name mariadb.service" "found in ${be_unit}" ;;
    *) _record_pass "SQLite unit does not name mariadb.service" ;;
esac
for target in conf.context conf.systemd0; do
    be_rc=0
    be_out=$(make -C "${be_env}" -s "${target}" DB_BACKEND=postgres 2>&1) || be_rc=$?
    if [[ "${be_rc}" -ne 0 && "${be_out}" == *"DB_BACKEND must be one of: mariadb sqlite"* ]]; then
        _record_pass "${target} rejects DB_BACKEND=postgres (rc=${be_rc})"
    else
        _record_fail "${target} rejects DB_BACKEND=postgres" "rc=${be_rc} output=${be_out}"
    fi
done
be_run=$(make -C "${be_env}" --no-print-directory print-SQLITE_RUN_AS AA_USERID=svcacct 2>/dev/null | tail -1)
assert_eq "${be_run}" "sudo -u svcacct" "SQLITE_RUN_AS uses sudo for a user-run build"
mkdir -p "${WORKSPACE}/root-id"
printf '#!/bin/sh\necho 0\n' > "${WORKSPACE}/root-id/id"
chmod +x "${WORKSPACE}/root-id/id"
be_run=$(PATH="${WORKSPACE}/root-id:${PATH}" make -C "${be_env}" --no-print-directory print-SQLITE_RUN_AS AA_USERID=svcacct 2>/dev/null | tail -1)
assert_eq "${be_run}" "runuser -u svcacct --" "SQLITE_RUN_AS uses runuser for a root-run build"
be_schema="${TOP}/$(make -C "${TOP}" --no-print-directory print-SQL_AA_ORIG_SQLITE 2>/dev/null | tail -1)"
if ! command -v sqlite3 > /dev/null 2>&1 || [[ ! -f "${be_schema}" ]]; then
    printf '  [SKIP] SQLite schema rules: needs sqlite3 and %s\n' "${be_schema}"
else
    be_db="${WORKSPACE}/backend-db/archappl.sqlite"
    be_mysql_copy="${be_env}/site-template/sql/archappl_mysql_updated.sql"
    be_mysql_sum=$(cksum "${be_mysql_copy}" 2>/dev/null || true)
    be_opts=(DB_BACKEND=sqlite SUDO= SQLITE_RUN_AS= "AA_USERID=$(id -un)" "AA_GROUPID=$(id -gn)"
             "ARCHAPPL_SQLITE_FILE=${be_db}" "SQL_AA_ORIG_SQLITE=${be_schema}")
    for run in first second; do
        be_rc=0
        make -C "${be_env}" -s sql.fill "${be_opts[@]}" > "${WORKSPACE}/backend-fill.txt" 2>&1 || be_rc=$?
        assert_status "${be_rc}" 0 "SQLite sql.fill succeeds on the ${run} run"
    done
    be_copy="${be_env}/site-template/sql/archappl_sqlite_updated.sql"
    assert_eq "$(grep -c '^CREATE [A-Z]* IF NOT EXISTS ' "${be_copy}")" "$(grep -c '^CREATE ' "${be_copy}")" \
        "Every CREATE in the SQLite copy is guarded by IF NOT EXISTS"
    assert_eq "$(cksum "${be_mysql_copy}" 2>/dev/null || true)" "${be_mysql_sum}" "The SQLite schema load leaves the MariaDB copy unchanged"
    sqlite3 "${be_db}" 'DROP TABLE PVAliases;'
    be_rc=0
    make -C "${be_env}" -s sql.fill "${be_opts[@]}" > "${WORKSPACE}/backend-fill.txt" 2>&1 || be_rc=$?
    assert_status "${be_rc}" 0 "SQLite sql.fill restores a dropped table"
    sqlite3 "${be_db}" 'PRAGMA journal_mode=WAL;' > /dev/null
    be_rc=0
    make -C "${be_env}" -s sql.fill "${be_opts[@]}" > "${WORKSPACE}/backend-fill.txt" 2>&1 || be_rc=$?
    assert_status "${be_rc}" 0 "SQLite sql.fill succeeds on a WAL-mode file"
    be_rc=0
    be_out=$(make -C "${be_env}" -s sql.show "${be_opts[@]}" 2>&1) || be_rc=$?
    assert_status "${be_rc}" 0 "SQLite sql.show lists the tables of a WAL-mode file"
    for table in PVTypeInfo PVAliases ArchivePVRequests ExternalDataServers; do
        case "${be_out}" in
            *"${table}"*) _record_pass "SQLite sql.show lists ${table}" ;;
            *) _record_fail "SQLite sql.show lists ${table}" "output=${be_out}" ;;
        esac
    done
fi

# P1.25 conf.storage warns when the store shares the root filesystem or lies
# under a user home and succeeds either way; archappl.conf carries the alarm
# threshold, with a value in ../CONFIG_SITE.local winning; health prints the
# storage line and names the storage cause at or above the threshold. The real
# rules and the shipped launcher run from isolated copies as the running user.
st_env="${WORKSPACE}/storage-env"
mkdir -p "${st_env}"
cp -a "${TOP}/Makefile" "${TOP}/configure" "${TOP}/site-template" "${TOP}/scripts" "${st_env}/"
rm -f "${st_env}/configure/"*.local "${st_env}/site-template/archappl.conf"
st_opts=(SUDO= "SUDOBASH=bash -c" "AA_USERID=$(id -un)" "AA_GROUPID=$(id -gn)")
st_root_mount=$(df -P / | sed -n '2p' | awk '{print $NF}')
for st_case in root:/var/tmp shm:/dev/shm home:"${HOME}"; do
    st_kind="${st_case%%:*}"
    st_base="${st_case#*:}"
    if ! st_dir=$(mktemp -d "${st_base}/archappl-store.XXXXXX" 2>/dev/null); then
        printf '  [SKIP] conf.storage %s case: cannot create a directory under %s\n' "${st_kind}" "${st_base}"
        continue
    fi
    st_mount=$(df -P "${st_dir}" | sed -n '2p' | awk '{print $NF}')
    if [[ "${st_kind}" == shm && "${st_mount}" == "${st_root_mount}" ]]; then
        printf '  [SKIP] conf.storage shm case: /dev/shm shares the root filesystem\n'
        rm -rf "${st_dir}"
        continue
    fi
    st_rc=0
    st_out=$(make -C "${st_env}" -s conf.storage "${st_opts[@]}" "ARCHAPPL_STORAGE_TOP=${st_dir}" 2>&1) || st_rc=$?
    rm -rf "${st_dir}"
    assert_status "${st_rc}" 0 "conf.storage succeeds for the ${st_kind} store"
    if [[ "${st_mount}" == "${st_root_mount}" ]]; then st_want=yes; else st_want=no; fi
    if [[ "${st_out}" == *"is on the root filesystem"* ]]; then st_got=yes; else st_got=no; fi
    assert_eq "${st_got}" "${st_want}" "conf.storage root-filesystem warning for the ${st_kind} store"
    if [[ "${st_kind}" == home ]]; then st_want=yes; else st_want=no; fi
    if [[ "${st_out}" == *"lies under the home directory"* ]]; then st_got=yes; else st_got=no; fi
    assert_eq "${st_got}" "${st_want}" "conf.storage user-home warning for the ${st_kind} store"
done
st_conf="${st_env}/site-template/archappl.conf"
make -C "${st_env}" -s conf.archappl > /dev/null 2>&1 || true
case "$(cat "${st_conf}")" in
    *$'\nARCHAPPL_STORAGE_ALARM_PERCENT=85\n'*) _record_pass "archappl.conf carries ARCHAPPL_STORAGE_ALARM_PERCENT=85 by default" ;;
    *) _record_fail "archappl.conf carries ARCHAPPL_STORAGE_ALARM_PERCENT=85 by default" "missing in ${st_conf}" ;;
esac
printf 'ARCHAPPL_STORAGE_ALARM_PERCENT:=70\n' > "${st_env}/../CONFIG_SITE.local"
rm -f "${st_conf}"
make -C "${st_env}" -s conf.archappl > /dev/null 2>&1 || true
rm -f "${st_env}/../CONFIG_SITE.local"
case "$(cat "${st_conf}")" in
    *$'\nARCHAPPL_STORAGE_ALARM_PERCENT=70\n'*) _record_pass "A threshold in ../CONFIG_SITE.local reaches archappl.conf" ;;
    *) _record_fail "A threshold in ../CONFIG_SITE.local reaches archappl.conf" "the shipped default won" ;;
esac
st_java=$(command -v java || true)
if [[ -z "${st_java}" ]]; then
    printf '  [SKIP] health storage line: needs a real java executable\n'
else
    st_jh=$(dirname "$(dirname "$(readlink -f "${st_java}")")")
    st_hl="${WORKSPACE}/storage-health"
    mkdir -p "${st_hl}/catalina"
    cp "${TOP}/scripts/archappl.bash" "${st_hl}/"
    for st_svc in mgmt engine etl retrieval; do mkdir -p "${st_hl}/${st_svc}/temp"; done
    st_use=$(df -P "${TOP}" | sed -n '2p' | awk '{print $5}')
    st_use="${st_use%\%}"
    for st_threshold in "${st_use}" $((st_use + 1)); do
        if (( st_threshold < 1 || st_threshold > 100 )); then
            printf '  [SKIP] health threshold %s is outside 1 to 100\n' "${st_threshold}"
            continue
        fi
        printf 'JAVA_HOME="%s"\nCATALINA_HOME="%s"\nARCHAPPL_STORAGE_TOP="%s"\nARCHAPPL_STORAGE_ALARM_PERCENT=%s\n' \
            "${st_jh}" "${st_hl}/catalina" "${TOP}" "${st_threshold}" > "${st_hl}/archappl.conf"
        st_rc=0
        st_out=$(env -u ARCHAPPL_STORAGE_TOP -u ARCHAPPL_STORAGE_ALARM_PERCENT bash "${st_hl}/archappl.bash" health 2>&1) || st_rc=$?
        assert_status "${st_rc}" 1 "health exits 1 with no instances and threshold ${st_threshold}%"
        if (( st_use >= st_threshold )); then
            st_line="storage path=${TOP} mount=* use=${st_use}% threshold=${st_threshold}% FAIL storage-threshold"
            st_verdict="health FAIL one-or-more-invalid-instances; storage-threshold"
        else
            st_line="storage path=${TOP} mount=* use=${st_use}% threshold=${st_threshold}% PRESENT"
            st_verdict="health FAIL one-or-more-invalid-instances"
        fi
        st_found=no
        while IFS= read -r st_text; do
            # shellcheck disable=SC2053
            if [[ "${st_text}" == ${st_line} ]]; then st_found=yes; fi
        done <<< "${st_out}"
        assert_eq "${st_found}" yes "health storage line at threshold ${st_threshold}% (use ${st_use}%)"
        assert_eq "$(tail -1 <<< "${st_out}")" "${st_verdict}" "health verdict at threshold ${st_threshold}%"
    done
    printf 'false\n' > "${st_hl}/archappl.conf"
    st_rc=0
    st_out=$(bash "${st_hl}/archappl.bash" health 2>&1) || st_rc=$?
    assert_status "${st_rc}" 2 "health exits 2 when archappl.conf does not load"
    case "${st_out}" in
        *$'\nstorage path=- ERROR configuration-load-failed\n'*) _record_pass "health reports the storage path as unknown when archappl.conf does not load" ;;
        *) _record_fail "health reports the storage path as unknown when archappl.conf does not load" "output=${st_out}" ;;
    esac
    printf 'JAVA_HOME="%s"\nCATALINA_HOME="/nonexistent"\nARCHAPPL_STORAGE_TOP="%s"\nARCHAPPL_STORAGE_ALARM_PERCENT=100\n' \
        "${st_jh}" "${TOP}" > "${st_hl}/archappl.conf"
    st_rc=0
    st_out=$(env -u ARCHAPPL_STORAGE_TOP -u ARCHAPPL_STORAGE_ALARM_PERCENT bash "${st_hl}/archappl.bash" health 2>&1) || st_rc=$?
    assert_status "${st_rc}" 2 "health exits 2 with invalid runtime paths"
    case "${st_out}" in
        *$'\nstorage path='"${TOP}"' mount='*) _record_pass "health still reports the store when only the runtime paths are invalid" ;;
        *) _record_fail "health still reports the store when only the runtime paths are invalid" "output=${st_out}" ;;
    esac
fi

# P1.26 DB_SOCKET selects the MariaDB transport. Empty keeps the TCP URL and
# TCP client commands; a socket path set in ../CONFIG_SITE.local renders the
# localSocket URL, carries the path into mariadb.conf, and turns all four
# client commands and the account host to the socket. The shipped
# mariadb_generic_function.bash expands the commands from the rendered
# mariadb.conf; no database client runs.
so_env="${WORKSPACE}/socket-env"
so_path="/run/p1-socket/mysqld.sock"
mkdir -p "${so_env}"
cp -a "${TOP}/Makefile" "${TOP}/configure" "${TOP}/scripts" "${TOP}/site-template" "${so_env}/"
rm -f "${so_env}/configure/"*.local "${so_env}/../CONFIG_SITE.local" \
    "${so_env}/site-template/context.xml" "${so_env}/site-template/mariadb.conf"
so_ctx="${so_env}/site-template/context.xml"
so_conf="${so_env}/site-template/mariadb.conf"
# Prints the four client commands and the account host from the rendered mariadb.conf.
function socket_commands
{
    bash -c '
        source "$1/site-template/mariadb.conf"
        source "$1/scripts/mariadb_generic_function.bash"
        printf "root=%s\nadmin=%s\nuser=%s\nbackup=%s\nhost=%s\n" \
            "${SQL_ROOT_CMD}" "${SQL_ADMIN_CMD}" "${SQL_DBUSER_CMD}" "${SQL_BACKUP_CMD}" "${DB_USER_HOST}"
    ' _ "${so_env}"
}
so_rc=0
make -C "${so_env}" -s conf.context db.conf > /dev/null 2>&1 || so_rc=$?
assert_status "${so_rc}" 0 "Empty DB_SOCKET renders context.xml and mariadb.conf"
case "$(cat "${so_ctx}")" in
    *'url="jdbc:mariadb://127.0.0.1:3306/archappl"'*) _record_pass "Empty DB_SOCKET keeps the TCP URL" ;;
    *) _record_fail "Empty DB_SOCKET keeps the TCP URL" "$(grep 'url=' "${so_ctx}" || true)" ;;
esac
assert_eq "$(grep '^DB_SOCKET=' "${so_conf}" || true)" 'DB_SOCKET=""' "Empty DB_SOCKET renders an empty value in mariadb.conf"
so_cmds=$(socket_commands)
assert_eq "$(grep '^root=' <<< "${so_cmds}" || true)" "root=sudo mysql --user=root" "Empty DB_SOCKET keeps the root command"
for so_role in admin user backup; do
    case "$(grep "^${so_role}=" <<< "${so_cmds}" || true)" in
        *'--port=3306 --host=127.0.0.1 --protocol=tcp') _record_pass "Empty DB_SOCKET keeps the TCP ${so_role} command" ;;
        *) _record_fail "Empty DB_SOCKET keeps the TCP ${so_role} command" "$(grep "^${so_role}=" <<< "${so_cmds}" || true)" ;;
    esac
done
assert_eq "$(grep '^host=' <<< "${so_cmds}" || true)" "host=127.0.0.1" "Empty DB_SOCKET grants the account at DB_HOST_NAME"
rm -f "${so_ctx}" "${so_conf}"
printf 'DB_SOCKET:=%s\n' "${so_path}" > "${so_env}/../CONFIG_SITE.local"
so_rc=0
make -C "${so_env}" -s conf.context db.conf > /dev/null 2>&1 || so_rc=$?
assert_status "${so_rc}" 0 "DB_SOCKET in ../CONFIG_SITE.local renders context.xml and mariadb.conf"
case "$(cat "${so_ctx}")" in
    *'url="jdbc:mariadb://localhost/archappl?localSocket='"${so_path}"'"'*) _record_pass "DB_SOCKET renders the localSocket URL" ;;
    *) _record_fail "DB_SOCKET renders the localSocket URL" "$(grep 'url=' "${so_ctx}" || true)" ;;
esac
assert_eq "$(grep '^DB_SOCKET=' "${so_conf}" || true)" "DB_SOCKET=\"${so_path}\"" "DB_SOCKET reaches mariadb.conf"
so_cmds=$(socket_commands)
assert_eq "$(grep '^root=' <<< "${so_cmds}" || true)" "root=sudo mysql --user=root --socket=${so_path}" "DB_SOCKET reaches the root command"
for so_role in admin user backup; do
    so_line=$(grep "^${so_role}=" <<< "${so_cmds}" || true)
    if [[ "${so_line}" == *"--protocol=socket --socket=${so_path}" && "${so_line}" != *--host=* && "${so_line}" != *--port=* ]]; then
        _record_pass "DB_SOCKET turns the ${so_role} command to the socket"
    else
        _record_fail "DB_SOCKET turns the ${so_role} command to the socket" "${so_line}"
    fi
done
assert_eq "$(grep '^host=' <<< "${so_cmds}" || true)" "host=localhost" "DB_SOCKET grants the account at localhost"
rm -f "${so_ctx}"
make -C "${so_env}" -s conf.context DB_BACKEND=sqlite > /dev/null 2>&1
so_sqlite_socket=$(cat "${so_ctx}")
rm -f "${so_ctx}" "${so_env}/../CONFIG_SITE.local"
make -C "${so_env}" -s conf.context DB_BACKEND=sqlite > /dev/null 2>&1
assert_eq "${so_sqlite_socket}" "$(cat "${so_ctx}")" "DB_SOCKET leaves the SQLite resource unchanged"

# P1.27 The account and database targets stop with a non-zero status and a
# stderr message naming the failed step when the database client fails. The
# real mysql client runs from an isolated copy of the Make system: the targets
# on the admin command against a closed loopback port, the targets on the root
# command against a missing socket through DB_SOCKET, with a pass-through sudo
# first in PATH because this host's sudo prompts. DB_HOST_PORT and DB_SOCKET go
# on every make command line, since each target re-renders mariadb.conf.
if ! command -v mysql > /dev/null 2>&1; then
    printf '  [SKIP] database target failures: needs a mysql client\n'
else
    cf_env="${WORKSPACE}/client-fail-env"
    cf_bin="${WORKSPACE}/client-fail-bin"
    cf_err="${WORKSPACE}/client-fail-stderr.txt"
    cf_socket="${WORKSPACE}/client-fail-missing.sock"
    mkdir -p "${cf_env}" "${cf_bin}"
    cp -a "${TOP}/Makefile" "${TOP}/configure" "${TOP}/scripts" "${TOP}/site-template" "${cf_env}/"
    rm -f "${cf_env}/configure/"*.local "${cf_env}/../CONFIG_SITE.local" "${cf_env}/site-template/mariadb.conf"
    printf '#!/bin/sh\nexec "$@"\n' > "${cf_bin}/sudo"
    chmod +x "${cf_bin}/sudo"
    # description|client|runner|target or command|message naming the failed step
    cf_cases=(
        "make db.create|admin|make|db.create|Creating the database archappl and the archappl account failed"
        "make db.drop|admin|make|db.drop|Dropping the database archappl and the archappl account failed"
        "dbCreate|admin|setup|dbCreate|Creating the database archappl failed"
        "dbDrop|admin|setup|dbDrop|Dropping the database archappl failed"
        "userDrop|admin|setup|userDrop|Dropping the archappl account failed"
        "make db.addAdmin|root|make|db.addAdmin|Adding the admin@localhost account failed"
        "make db.rmAdmin|root|make|db.rmAdmin|Removing the admin@localhost account failed"
        "hostnameAdminAdd|root|setup|hostnameAdminAdd|Adding the admin@127.0.0.1 account failed"
        "hostnameAdminRemove|root|setup|hostnameAdminRemove|Removing the admin@127.0.0.1 account failed"
    )
    for cf_case in "${cf_cases[@]}"; do
        IFS='|' read -r cf_desc cf_client cf_runner cf_target cf_text <<< "${cf_case}"
        if [[ "${cf_client}" == admin ]]; then
            cf_vars=(DB_HOST_PORT=1 DB_SOCKET=)
        else
            cf_vars=(DB_SOCKET="${cf_socket}")
        fi
        cf_rc=0
        if [[ "${cf_runner}" == make ]]; then
            PATH="${cf_bin}:${PATH}" make -C "${cf_env}" -s "${cf_target}" "${cf_vars[@]}" \
                > /dev/null 2> "${cf_err}" || cf_rc=$?
        else
            make -C "${cf_env}" -s db.conf "${cf_vars[@]}" > /dev/null 2>&1
            PATH="${cf_bin}:${PATH}" bash "${cf_env}/scripts/mariadb_setup.bash" "${cf_target}" \
                > /dev/null 2> "${cf_err}" || cf_rc=$?
        fi
        if [[ "${cf_rc}" -ne 0 ]]; then
            _record_pass "${cf_desc} exits non-zero when the client fails (rc=${cf_rc})"
        else
            _record_fail "${cf_desc} exits non-zero when the client fails" "got rc=0"
        fi
        case "$(cat "${cf_err}")" in
            *"ERROR 2002"*"${cf_text}"*) _record_pass "${cf_desc} reports the client error and the failed step" ;;
            *) _record_fail "${cf_desc} reports the client error and the failed step" "stderr: $(cat "${cf_err}")" ;;
        esac
    done
fi

phase_pass "Phase 1: Logic"

# Real launcher negatives and isolated unit installation; no systemd mutation.
python3 "${TOP}/tests/health-local.py"
