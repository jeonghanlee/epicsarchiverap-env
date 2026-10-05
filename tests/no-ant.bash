#!/usr/bin/env bash
# No Ant remains in the configuration, and the site id reaches every Maven call.
# The tracked tree is inspected for Ant settings and a site build file, and the shipped build
# and clean targets are printed with a dry run for the default site id and for another one.

set -euo pipefail

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TOP
readonly MAVEN_TARGETS=(build.mvn build.mvn2 build.mvn3 build.war build.mvndeps clean.mvn)

# shellcheck source=lib/common.bash
source "${TOP}/tests/lib/common.bash"

phase_header "No Ant: configuration, site build file and Maven site id"

# The tree under test; a mutation run points this at another copy of the repository.
ROOT="${NO_ANT_TREE_UNDER_TEST:-${TOP}}"

assert_not_file "${ROOT}/site-template/siteid/build.xml" "The site folder holds no build.xml"
assert_eq "$(find "${ROOT}/site-template/siteid" -name build.xml | wc -l)" "0" \
    "No build.xml anywhere in the site folder"

ant_settings=$(grep -rIn -E '^[[:space:]]*#?[[:space:]]*ANT_(HOME|PATH|CMD|OPTS)' "${ROOT}/configure" || true)
assert_eq "${ant_settings}" "" "No ANT_HOME, ANT_PATH, ANT_CMD or ANT_OPTS setting in configure/"

ant_words=$(grep -n -i -w 'ant' "${ROOT}/README.md" || true)
assert_eq "${ant_words}" "" "The README does not claim that Ant is used"

for target in "${MAVEN_TARGETS[@]}"; do
    default_call=$(make -C "${ROOT}" --no-print-directory -n "${target}" 2>&1 | grep -F 'mvnw' || true)
    assert_nonempty "${default_call}" "${target} prints a Maven call"
    case "${default_call}" in
        *"ARCHAPPL_SITEID=als "*) _record_pass "${target} passes the default site id als" ;;
        *) _record_fail "${target} passes the default site id als" "${default_call}" ;;
    esac
    other_call=$(make -C "${ROOT}" --no-print-directory -n "${target}" ARCHAPPL_SITEID=othersite 2>&1 \
        | grep -F 'mvnw' || true)
    case "${other_call}" in
        *"ARCHAPPL_SITEID=othersite "*) ;;
        *) _record_fail "${target} passes another site id" "${other_call}" ;;
    esac
    case "${other_call}" in
        *"=als "*) _record_fail "${target} no longer names als" "${other_call}" ;;
        *) _record_pass "${target} passes the configured site id othersite and never als" ;;
    esac
done

phase_pass "No Ant: configuration, site build file and Maven site id"
