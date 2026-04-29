#!/usr/bin/env bash
# Phase 1: Logic checks.
# No build, no network, no setup. Pure structural verification of the
# Makefile system, configure/ tree, and document set after the cleanup.

set -euo pipefail

readonly TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly EXPECTED_BRANCH="${EXPECTED_BRANCH:-cleanup}"
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

phase_pass "Phase 1: Logic"
