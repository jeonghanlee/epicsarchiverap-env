#!/usr/bin/env bash
# Phase 2: Build wrapper.
# Inspect command generation from the real Makefile. No source clone, JDK,
# Maven execution, configuration generation, or build artifacts are required.
# Compilation and artifact verification belong to aa-maven CI.

set -euo pipefail

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TOP

# shellcheck source=lib/common.bash
source "${TOP}/tests/lib/common.bash"

phase_header "Phase 2: Build wrapper"

# P2.1 Resolve paths from the same configuration used by the dry run.
# Empty CLI flags isolate the build contract from optional local Maven flags.
make_cmd=(make -C "${TOP}" --no-print-directory MAVEN_FLAGS=)
config_output=$("${make_cmd[@]}" -s print-SRC_PATH print-MAVEN_CMD \
    print-AA_SITE_TEMPLATE_PATH print-ARCHAPPL_SITEID_TEMPATE_PATH \
    print-ARCHAPPL_SITEID_TARGET_PATH print-ARCHAPPL_UI_TEMPLATE_PATH print-ARCHAPPL_UI_TARGET_PATH)
mapfile -t config_values <<< "${config_output}"
assert_eq "${#config_values[@]}" 7 "Build configuration resolves seven paths"
for value in "${config_values[@]}"; do
    assert_nonempty "${value}" "Build configuration path is nonempty"
done
src_path="${config_values[0]}"
mvncmd="${config_values[1]}"
template_path="${config_values[2]}"
overlay_path="${config_values[3]}"
target_path="${config_values[4]}"
ui_template_path="${config_values[5]}"
ui_target_path="${config_values[6]}"

# P2.2 Render the public build target without executing its recipes.
build_rc=0
build_output=$("${make_cmd[@]}" -n build 2>&1) || build_rc=$?
printf '%s\n' "${build_output}" >> "${LOGFILE}"
assert_status "${build_rc}" 0 "make -n build succeeds (see ${LOGFILE})"

# P2.3 Match the build invocation, not the informational mvnw --version line.
# Only simple unquoted environment assignments may precede the executable.
assignment_pattern='([a-zA-Z_][a-zA-Z0-9_]*=[a-zA-Z0-9_./:+-]*[[:space:]]+)*'
build_prefix="cd ${src_path} && "
maven_suffix="${mvncmd}  clean package -DskipTests && cd .."
maven_line=""
maven_count=0
while IFS= read -r line; do
    case "${line}" in
        "${build_prefix}"*"${maven_suffix}")
            assignments="${line#"${build_prefix}"}"
            assignments="${assignments%"${maven_suffix}"}"
            if [[ "${assignments}" =~ ^${assignment_pattern}$ ]]; then
                maven_line="${line}"
                maven_count=$((maven_count + 1))
            fi
            ;;
    esac
done <<< "${build_output}"
assert_eq "${maven_count}" 1 "Build invokes the source Maven Wrapper with clean package -DskipTests"

# P2.4 Each rendered configuration precedes the overlay copy and Maven build.
copy_command="cp -rf ${overlay_path} ${target_path}"
for config_file in appliances.xml archappl.properties policies.py context.xml archappl.conf; do
    case "$config_file" in
        context.xml) config_redirection="bash ${TOP}/scripts/render-db-config.bash xml \"${template_path}/context.xml.in\" \"${template_path}/context.xml\"" ;;
        archappl.conf) config_redirection="| bash ${TOP}/scripts/render-db-config.bash shell - \"${template_path}/archappl.conf\" JDBC_DB_NAME" ;;
        *) config_redirection="< ${template_path}/${config_file}.in > ${template_path}/${config_file}" ;;
    esac
    case $'\n'"${build_output}"$'\n' in
        *"${config_redirection}"*$'\n'*$'\n'"${copy_command}"$'\n'*"${maven_line}"$'\n'*)
            _record_pass "${config_file} generation precedes overlay copy and Maven build"
            ;;
        *)
            _record_fail "${config_file} build ordering" "see ${LOGFILE}"
            ;;
    esac
done

# P2.5 The prepared interface files are copied after the site overlay and before the Maven build.
ui_copy_command="bash \"${TOP}/scripts/prepare-ui.bash\" \"${ui_template_path}\" \"${ui_target_path}\" \"${TOP}/${src_path}\""
case $'\n'"${build_output}"$'\n' in
    *$'\n'"${copy_command}"$'\n'*$'\n'"${ui_copy_command}"$'\n'*$'\n'"${maven_line}"$'\n'*)
        _record_pass "Prepared interface copy follows the overlay copy and precedes the Maven build"
        ;;
    *)
        _record_fail "Prepared interface copy ordering" "see ${LOGFILE}"
        ;;
esac

phase_pass "Phase 2: Build wrapper"
