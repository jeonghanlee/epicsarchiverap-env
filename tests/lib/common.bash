#!/usr/bin/env bash
# Shared assertion and workspace helpers for the phased install tests.
# Sourced by every phase script and the master runner.

# Each phase resolves TOP relative to its own location; common.bash itself
# does not assume cwd. WORKSPACE is created on first source and cleaned up
# in cleanup_workspace().

WORKSPACE="${WORKSPACE:-$(mktemp -d -p "${TMPDIR:-/dev/shm}" archappl-test.XXXXXX)}"
LOGFILE="${LOGFILE:-${WORKSPACE}/run.log}"
KEEP_WORKSPACE="${KEEP_WORKSPACE:-0}"

PASS_COUNT=0
FAIL_COUNT=0

cleanup_workspace() {
    local rc=$?
    if [[ ${rc} -ne 0 ]] || [[ ${KEEP_WORKSPACE} -eq 1 ]]; then
        printf '\nWorkspace retained: %s (rc=%d, log=%s)\n' \
            "${WORKSPACE}" "${rc}" "${LOGFILE}" >&2
        return
    fi
    rm -rf "${WORKSPACE}"
}
trap cleanup_workspace EXIT

phase_header() {
    printf '\n=== %s ===\n' "$1"
}

phase_pass() {
    printf '\n[PASS] %s (passed=%d failed=%d)\n\n' "$1" "${PASS_COUNT}" "${FAIL_COUNT}"
}

phase_fail() {
    printf '\n[FAIL] %s (passed=%d failed=%d)\n' "$1" "${PASS_COUNT}" "${FAIL_COUNT}" >&2
    exit 1
}

_record_pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  [OK]   %s\n' "$1"
}

_record_fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  [FAIL] %s\n' "$1" >&2
    if [[ -n "${2:-}" ]]; then
        printf '         %s\n' "$2" >&2
    fi
    exit 1
}

assert_eq() {
    local got="$1" want="$2" desc="$3"
    if [[ "${got}" == "${want}" ]]; then
        _record_pass "${desc}"
    else
        _record_fail "${desc}" "got=${got} want=${want}"
    fi
}

assert_status() {
    local got="$1" want="$2" desc="$3"
    if [[ "${got}" -eq "${want}" ]]; then
        _record_pass "${desc} (rc=${got})"
    else
        _record_fail "${desc}" "got rc=${got} want rc=${want}"
    fi
}

assert_file() {
    local path="$1" desc="$2"
    if [[ -f "${path}" ]]; then
        _record_pass "${desc}"
    else
        _record_fail "${desc}" "missing: ${path}"
    fi
}

assert_not_file() {
    local path="$1" desc="$2"
    if [[ ! -f "${path}" ]]; then
        _record_pass "${desc}"
    else
        _record_fail "${desc}" "unexpected: ${path}"
    fi
}

assert_dir() {
    local path="$1" desc="$2"
    if [[ -d "${path}" ]]; then
        _record_pass "${desc}"
    else
        _record_fail "${desc}" "missing dir: ${path}"
    fi
}

assert_empty() {
    local val="$1" desc="$2"
    if [[ -z "${val}" ]]; then
        _record_pass "${desc}"
    else
        _record_fail "${desc}" "got: ${val}"
    fi
}

assert_nonempty() {
    local val="$1" desc="$2"
    if [[ -n "${val}" ]]; then
        _record_pass "${desc}"
    else
        _record_fail "${desc}" "value is empty"
    fi
}

assert_cmd() {
    local cmd="$1" desc="$2"
    if command -v "${cmd}" >/dev/null 2>&1; then
        _record_pass "${desc}"
    else
        _record_fail "${desc}" "command not in PATH: ${cmd}"
    fi
}

assert_file_size_min() {
    local path="$1" min="$2" desc="$3"
    if [[ ! -f "${path}" ]]; then
        _record_fail "${desc}" "missing: ${path}"
    fi
    local size
    size=$(stat -c '%s' "${path}")
    if [[ ${size} -ge ${min} ]]; then
        _record_pass "${desc} (size=${size})"
    else
        _record_fail "${desc}" "size=${size} below min=${min}"
    fi
}

run_logged() {
    local desc="$1"
    shift
    printf '  >> %s\n' "${desc}" >&2
    if "$@" >> "${LOGFILE}" 2>&1; then
        return 0
    fi
    return $?
}
