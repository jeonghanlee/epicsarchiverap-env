#!/usr/bin/env bash
# Checks that the three installers refuse an invalid configure/CONFIG_SITE.local before any Make call, sudo, lock or
# package step. Every case runs a shipped entry script, the common driver and the real Makefiles in an isolated copy of
# the checkout; only exec traces, exit statuses and file states are observed.
# Modes: --local (default) runs every installer call with --plan or --help. --disposable-host also runs --yes calls
# without --plan and requires an ordinary user on an authorized disposable guest; it is never selected by environment.
# Exit status: 0 passed, 1 a violation was observed, 77 a prerequisite or required evidence is missing.
# Usage: bash tests/local-install-config.bash [--local | --disposable-host] [--smoke] [--evidence DIR]
set -euo pipefail

TOP=$(realpath -- "${BASH_SOURCE[0]%/*}/..")
SELF=$(realpath -- "${BASH_SOURCE[0]}")
readonly TOP SELF
readonly ORIGINAL_DRIVER_COMMIT='c4b27bcc65fa70ee7c80ccee7d40136bab64d995'
readonly DRIVER='scripts/install-local-common.bash'
readonly CASE_TIMEOUT=30
readonly INCLUDE_LINE='include $(TOP)/configure/os/debian13.mk'
readonly PARENT_LINE='AA_PARENT_KEEP=1'
readonly SENTINEL='m2sentinel'
readonly MARKER_NAME='m2-parse-marker'
readonly GENERIC_REASON='does not hold only the generated operating system include'
readonly FORBIDDEN_RE='(make|gmake|sudo|apt|apt-get|dnf|yum|rpm|dpkg|systemctl|flock)'
readonly FORBIDDEN_NO_MAKE_RE='(sudo|apt|apt-get|dnf|yum|rpm|dpkg|systemctl|flock)'
readonly INSTALLER_EXEC_RE='execve\("[^"]*/bash", \[.*install-local-(sqlite|mariadb-uds|mariadb-tcp|common)\.bash"'
readonly -a INSTALLERS=(sqlite mariadb-uds mariadb-tcp)
readonly -a PRESETS=(debian12 debian13 rocky8 rocky10 ubuntu24 ubuntu26)
readonly -a TARGETS=(debian12 debian13 rocky8 rocky10 ubuntu24 ubuntu26 centos7 centos8)

# Invalid inputs as id|kind|content|offending lines|reason. @INC@ stands for the generated include line and the
# content is expanded with printf %b. GENERIC stands for the reason that names the include contract.
readonly -a FIXTURES=(
    'assign-after|file|@INC@\nAA_m2sentinel_NAME=secret-m2sentinel\n|2|GENERIC'
    'password-like|file|@INC@\nDB_USER_PASS := m2sentinel-Pa55\n|2|GENERIC'
    'assign-first|file|AA_m2sentinel_FIRST=1\n@INC@\n|1|GENERIC'
    'comment|file|@INC@\n# m2sentinel comment\n|2|GENERIC'
    'blank|file|@INC@\n\n|2|GENERIC'
    'repeated|file|@INC@\n@INC@\n|2|GENERIC'
    'unknown-include|file|include $(TOP)/configure/os/m2sentinelOS.mk\n|1|GENERIC'
    'other-path|file|include /etc/m2sentinel.mk\n|1|GENERIC'
    'expression-include|file|include $(TOP)/configure/os/$(m2sentinel_OS).mk\n|1|GENERIC'
    'expression-marker|file|@INC@\nAA_m2sentinel_MARK := $(shell printf parsed > $(TOP)/m2-parse-marker)\n|2|GENERIC'
    'space-leading|file| @INC@\n|1|GENERIC'
    'space-trailing|file|@INC@ \n|1|GENERIC'
    'tab-for-space|file|include\t$(TOP)/configure/os/debian13.mk\n|1|GENERIC'
    'no-space|file|include$(TOP)/configure/os/debian13.mk\n|1|GENERIC'
    'crlf|file|@INC@\r\n|1|GENERIC'
    'crlf-no-final|file|@INC@\r|1|GENERIC'
    'empty|file||none|is empty'
    'nul-byte|file|@INC@\0\n|none|contains a NUL byte'
    'symlink|symlink||none|is a symbolic link'
    'dangling-symlink|dangling||none|is a symbolic link'
    'directory|directory||none|is not a regular file'
    'unreadable|unreadable||none|is not readable'
)

declare -g TEST_TOTAL=0
declare -g TEST_PASSED=0
declare -g TEST_FAILED=0
declare -g TEST_COMPLETE=0
declare -g VIOLATION=0
declare -g MODE=local
declare -g SMOKE=0
declare -g EVIDENCE=''
declare -g PRISTINE=''
declare -g RESULTS=''
declare -g CURRENT=''
declare -g CASE_DIR=''
declare -g CASE_RC=0
declare -g -a FAILED_DETAILS=()
declare -g -a INCOMPLETE_DETAILS=()

readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly BLUE=$'\033[0;34m'
readonly NC=$'\033[0m'

function usage {
    printf '%s\n' \
        'Usage: bash tests/local-install-config.bash [--local | --disposable-host] [--smoke] [--evidence DIR]' \
        '  --local            Run every installer call with --plan or --help (default)' \
        '  --disposable-host  Also run --yes calls without --plan; needs an ordinary user, AA_TEST_DISPOSABLE_HOST=YES' \
        '                     and AA_TEST_AUTHORIZED_GUEST set to the host name of the authorized guest' \
        '  --smoke            Run one refusal fixture per installer only' \
        '  --evidence DIR     Keep evidence in DIR (default work/m2-install-config/<UTC time>)'
}

function mark_incomplete {
    INCOMPLETE_DETAILS+=("$1")
}

function incomplete_exit {
    printf 'INCOMPLETE: %s\n' "$1" >&2
    mark_incomplete "$1"
    exit 77
}

function print_divider {
    printf '%s\n' '------------------------------------------------------------'
}

function print_summary {
    local detail
    printf '\n'
    print_divider
    printf '%b%s%b\n' "$BLUE" 'LOCAL INSTALL CONFIGURATION SUMMARY' "$NC"
    printf '  %-20s : %s\n' 'Mode' "$MODE"
    printf '  %-20s : %d\n' 'Total Assertions' "$TEST_TOTAL"
    printf '  %-20s : %d\n' 'Passed' "$TEST_PASSED"
    printf '  %-20s : %d\n' 'Failed' "$TEST_FAILED"
    printf '  %-20s : %d\n' 'Incomplete Reasons' "${#INCOMPLETE_DETAILS[@]}"
    for detail in "${FAILED_DETAILS[@]}"; do
        printf '%b  [FAIL] %s%b\n' "$RED" "$detail" "$NC"
    done
    for detail in "${INCOMPLETE_DETAILS[@]}"; do
        printf '%b  [INCOMPLETE] %s%b\n' "$YELLOW" "$detail" "$NC"
    done
    if [[ -n "$EVIDENCE" ]]; then printf '  %-20s : %s\n' 'Evidence' "$EVIDENCE"; fi
    if (( TEST_FAILED > 0 )); then
        printf '%b[VERDICT] Failed%b\n' "$RED" "$NC"
    elif (( ${#INCOMPLETE_DETAILS[@]} > 0 )); then
        printf '%b[VERDICT] Incomplete%b\n' "$YELLOW" "$NC"
    else
        printf '%b[VERDICT] Passed%b\n' "$GREEN" "$NC"
    fi
    print_divider
}

# Reports the native status, then 1 for a violation or 77 for missing evidence; the evidence directory is kept.
function handle_exit {
    local rc=$? final=0
    if (( TEST_COMPLETE != 1 && rc == 0 )); then mark_incomplete 'The run did not complete'; fi
    final=$rc
    if (( final == 0 )); then
        if (( TEST_FAILED > 0 )); then
            final=1
        elif (( ${#INCOMPLETE_DETAILS[@]} > 0 )); then
            final=77
        fi
    fi
    print_summary
    exit "$final"
}

# Records one assertion. The command after the two descriptions decides: success is a pass.
function assert_that {
    local name="$1" detail="$2"
    shift 2
    TEST_TOTAL=$((TEST_TOTAL + 1))
    if "$@"; then
        TEST_PASSED=$((TEST_PASSED + 1))
        printf '%s\t%s\tPASS\n' "$CURRENT" "$name" >> "$RESULTS"
        return 0
    fi
    TEST_FAILED=$((TEST_FAILED + 1))
    FAILED_DETAILS+=("$CURRENT: $name ($detail)")
    printf '%s\t%s\tFAIL\t%s\n' "$CURRENT" "$name" "$detail" >> "$RESULTS"
    printf '%b[ FAIL ]%b %s: %s\n' "$RED" "$NC" "$CURRENT" "$name" >&2
    printf '  %b%s%b\n' "$YELLOW" "$detail" "$NC" >&2
}

function contains { [[ "$1" == *"$2"* ]]; }
function lacks { [[ "$1" != *"$2"* ]]; }
function same_file { cmp -s -- "$1" "$2"; }
function has_plan_or_help {
    local argument
    for argument in "$@"; do
        case "$argument" in --plan|--help|-h) return 0 ;; esac
    done
    return 1
}

# Prints a stable description of a path: its type, link target, mode and content hash, never its timestamps.
function describe_path {
    local path="$1"
    if [[ -L "$path" ]]; then
        printf 'symlink %s\n' "$(readlink -- "$path")"
    elif [[ -d "$path" ]]; then
        printf 'directory\n'
    elif [[ -f "$path" && -r "$path" ]]; then
        printf 'file %s %s\n' "$(stat -c %a -- "$path")" "$(sha256sum -- "$path" | cut -d' ' -f1)"
    elif [[ -f "$path" ]]; then
        printf 'file unreadable %s\n' "$(stat -c %a -- "$path")"
    elif [[ -e "$path" ]]; then
        printf 'other\n'
    else
        printf 'absent\n'
    fi
}

function tree_listing {
    find "$1" -printf '%y %p %s %m %l\n' | LC_ALL=C sort
}

# Exec records that started a matching command successfully, taken from an strace execve trace.
function exec_hits {
    grep -E "execve\(\"([^\"]*/)?$2\", .*\) = 0\$" "$1" || true
}

# Successful bash execs that open an installer entry script or the common driver, taken from one trace.
function installer_execs {
    grep -E "$INSTALLER_EXEC_RE" "$1" | grep ') = 0$' || true
}

function host_preset {
    local id='' version='' key value
    while IFS='=' read -r key value || [[ -n "${key:-}" ]]; do
        value="${value//\"/}"
        case "$key" in
            ID) id="$value" ;;
            VERSION_ID) version="$value" ;;
        esac
    done < /etc/os-release
    case "$id:$version" in
        debian:13|debian:13.*) printf 'debian13\n' ;;
        rocky:8|rocky:8.*) printf 'rocky8\n' ;;
        rocky:10.2|rocky:10.2.*) printf 'rocky10\n' ;;
        ubuntu:24.04|ubuntu:24.04.*) printf 'ubuntu24\n' ;;
        ubuntu:26.04|ubuntu:26.04.*) printf 'ubuntu26\n' ;;
        *) printf 'unsupported\n' ;;
    esac
}

# Copies the files the installers read into one pristine tree; case checkouts are hard-linked from it.
function make_pristine {
    local item
    PRISTINE="$EVIDENCE/pristine"
    mkdir -p "$PRISTINE" "$EVIDENCE/moved-local"
    cp -a "$TOP/Makefile" "$TOP/configure" "$TOP/scripts" "$TOP/site-template" "$PRISTINE/"
    for item in "$PRISTINE"/configure/*.local; do
        [[ -e "$item" ]] || continue
        mv -- "$item" "$EVIDENCE/moved-local/"
    done
    (cd "$PRISTINE" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) > "$EVIDENCE/pristine.sha256"
}

function new_checkout {
    local case_dir="$1"
    mkdir -p "$case_dir"
    cp -al "$PRISTINE" "$case_dir/co"
    printf '%s\n' "$PARENT_LINE" > "$case_dir/CONFIG_SITE.local"
}

# Writes one fixture as configure/CONFIG_SITE.local of a case checkout.
function install_fixture {
    local kind="$1" spec="$2" case_dir="$3" target="$3/co/configure/CONFIG_SITE.local"
    spec="${spec//@INC@/$INCLUDE_LINE}"
    case "$kind" in
        file) printf '%b' "$spec" > "$target" ;;
        symlink)
            printf '%s\n' "$INCLUDE_LINE" > "$case_dir/real-include.local"
            ln -s "$case_dir/real-include.local" "$target" ;;
        dangling) ln -s "$case_dir/missing-include.local" "$target" ;;
        directory) mkdir "$target" ;;
        unreadable)
            printf '%s\n' "$INCLUDE_LINE" > "$target"
            chmod 000 "$target" ;;
        *) incomplete_exit "Unknown fixture kind: $kind" ;;
    esac
}

# Runs one entry script under strace in a case checkout. Sets CASE_DIR and CASE_RC and writes the evidence files.
function run_case {
    local name="$1" case_dir="$2" entry="$3"
    shift 3
    local checkout="$case_dir/co"
    CASE_DIR="$case_dir"
    CURRENT="$name"
    if [[ "$MODE" == local ]] && ! has_plan_or_help "$@"; then
        incomplete_exit "Internal error: local mode would launch an installer without --plan: $name"
    fi
    describe_path "$checkout/configure/CONFIG_SITE.local" > "$case_dir/local.before"
    describe_path "$case_dir/CONFIG_SITE.local" > "$case_dir/parent.before"
    tree_listing "$checkout" > "$case_dir/tree.before"
    printf '%s\n' "$entry" "$@" > "$case_dir/args.txt"
    CASE_RC=0
    (cd "$checkout" && strace -f -qq -s 4096 -e trace=execve -o "$case_dir/trace.txt" -- \
        timeout --kill-after=5 "$CASE_TIMEOUT" \
        bash -c 'exec "$@" < /dev/null > "$0/stdout.txt" 2> "$0/stderr.txt"' "$case_dir" \
        bash "scripts/$entry" "$@") > "$case_dir/strace.log" 2>&1 || CASE_RC=$?
    printf '%s\n' "$CASE_RC" > "$case_dir/status.txt"
    describe_path "$checkout/configure/CONFIG_SITE.local" > "$case_dir/local.after"
    describe_path "$case_dir/CONFIG_SITE.local" > "$case_dir/parent.after"
    tree_listing "$checkout" > "$case_dir/tree.after"
}

# The trace must show the installer itself; otherwise the case has no usable evidence.
function trace_usable {
    if [[ ! -s "$CASE_DIR/trace.txt" ]] || ! grep -q 'install-local-' "$CASE_DIR/trace.txt"; then
        mark_incomplete "$CURRENT: no installer exec in the trace (tracing unavailable or the start failed)"
        return 1
    fi
    if (( CASE_RC == 124 || CASE_RC == 137 )); then
        mark_incomplete "$CURRENT: the case hit the ${CASE_TIMEOUT} second timeout"
    fi
    return 0
}

# Every installer exec in local mode carries --plan or --help, as the trace itself shows.
function assert_plan_in_trace {
    local line bad=''
    while IFS= read -r line; do
        if [[ "$line" != *'"--plan"'* && "$line" != *'"--help"'* && "$line" != *'"-h"'* ]]; then bad="$line"; fi
    done < <(installer_execs "$CASE_DIR/trace.txt")
    assert_that 'every installer exec carries --plan or --help' "$bad" [ -z "$bad" ]
}

# Any change of the configuration file, the parent file or the checkout tree is a state change that stops guest runs.
function assert_unchanged {
    local state
    for state in local parent tree; do
        if ! same_file "$CASE_DIR/$state.before" "$CASE_DIR/$state.after"; then VIOLATION=1; fi
    done
    assert_that 'configure/CONFIG_SITE.local type and bytes are unchanged' 'local.before differs from local.after' \
        same_file "$CASE_DIR/local.before" "$CASE_DIR/local.after"
    assert_that '../CONFIG_SITE.local is unchanged' 'parent.before differs from parent.after' \
        same_file "$CASE_DIR/parent.before" "$CASE_DIR/parent.after"
    assert_that 'the checkout tree is unchanged' 'tree.before differs from tree.after' \
        same_file "$CASE_DIR/tree.before" "$CASE_DIR/tree.after"
}

function assert_refusal {
    local lines="$1" reason="$2" installer="$3" forbidden='' stdout stderr checkout="$CASE_DIR/co"
    trace_usable || return 0
    if [[ "$reason" == GENERIC ]]; then reason="$GENERIC_REASON"; fi
    forbidden=$(exec_hits "$CASE_DIR/trace.txt" "$FORBIDDEN_RE")
    if [[ -n "$forbidden" ]]; then VIOLATION=1; fi
    assert_that 'no Make, sudo, package or service command starts' "$forbidden" [ -z "$forbidden" ]
    if (( CASE_RC == 124 || CASE_RC == 137 )); then return 0; fi
    stdout=$(< "$CASE_DIR/stdout.txt")
    stderr=$(< "$CASE_DIR/stderr.txt")
    assert_that 'status is 1' "status $CASE_RC" [ "$CASE_RC" -eq 1 ]
    assert_that 'diagnostic names the file and the reason' "$installer stderr lacks the path and reason" \
        grep -Fq -- "ERROR: $checkout/configure/CONFIG_SITE.local $reason." "$CASE_DIR/stderr.txt"
    if [[ "$lines" == none ]]; then
        assert_that 'diagnostic names no line numbers' 'an Offending lines entry is present' \
            lacks "$stderr" 'Offending lines:'
    else
        assert_that "diagnostic names offending lines $lines" "expected Offending lines: $lines" \
            grep -Fxq -- "Offending lines: $lines" "$CASE_DIR/stderr.txt"
    fi
    assert_that 'diagnostic names ../CONFIG_SITE.local' 'the parent file is not named' contains "$stderr" '../CONFIG_SITE.local'
    assert_that 'no configuration content reaches the output' "the sentinel $SENTINEL appeared" lacks "$stdout$stderr" "$SENTINEL"
    assert_that 'no installer work or lock file exists' 'work exists in the checkout' [ ! -e "$checkout/work" ]
    assert_unchanged
    if [[ "$MODE" == local ]]; then assert_plan_in_trace; fi
}

function group_report {
    local label="$1" failed_before="$2" runs="$3"
    if (( TEST_FAILED == failed_before )); then
        printf '%b[ PASS ]%b %-44s (%d runs)\n' "$GREEN" "$NC" "$label" "$runs"
    else
        printf '%b[ FAIL ]%b %-44s (%d runs)\n' "$RED" "$NC" "$label" "$runs" >&2
    fi
}

# T1: every invalid fixture is refused by all three installers, with and without --skip-packages.
function run_t1 {
    local record id kind spec lines reason installer variant name case_dir runs failed_before
    local -a variants=('plan:--plan' 'plan-skip:--plan --skip-packages') args=()
    if [[ "$MODE" == disposable ]]; then variants+=('yes:--yes' 'yes-skip:--yes --skip-packages'); fi
    for record in "${FIXTURES[@]}"; do
        IFS='|' read -r id kind spec lines reason <<< "$record"
        failed_before=$TEST_FAILED
        runs=0
        for installer in "${INSTALLERS[@]}"; do
            for variant in "${variants[@]}"; do
                name="t1/$id/$installer/${variant%%:*}"
                case_dir="$EVIDENCE/cases/$name"
                new_checkout "$case_dir"
                install_fixture "$kind" "$spec" "$case_dir"
                read -r -a args <<< "${variant#*:}"
                run_case "$name" "$case_dir" "install-local-$installer.bash" "${args[@]}"
                assert_refusal "$lines" "$reason" "$installer"
                runs=$((runs + 1))
                if (( VIOLATION )) && [[ "$MODE" == disposable ]]; then
                    group_report "T1 $id" "$failed_before" "$runs"
                    printf '%s\n' 'A forbidden command or state change was observed: stop, keep the evidence and inspect surviving installer processes.' >&2
                    return 0
                fi
            done
        done
        group_report "T1 $id" "$failed_before" "$runs"
        if (( SMOKE )); then return 0; fi
    done
}

# T2: the marker fixture shows that Make parses the extra line in the original driver and in a copy with only the
# guard call removed, and that the corrected driver refuses before Make runs.
function run_t2 {
    local installer variant case_dir stdout failed_before=$TEST_FAILED runs=0 name original_ok=1 removed_ok=1 marker
    local call_count
    mkdir -p "$EVIDENCE/drivers"
    if git -C "$TOP" show "$ORIGINAL_DRIVER_COMMIT:$DRIVER" > "$EVIDENCE/drivers/original.bash" 2> "$EVIDENCE/drivers/original.err"; then
        :
    else
        original_ok=0
        mark_incomplete "T2: the original driver is not available at $ORIGINAL_DRIVER_COMMIT"
    fi
    call_count=$(grep -c -x -- '    validate_site_configuration' "$TOP/$DRIVER" || true)
    if [[ "$call_count" == 1 ]]; then
        grep -v -x -- '    validate_site_configuration' "$TOP/$DRIVER" > "$EVIDENCE/drivers/guard-removed.bash"
    else
        removed_ok=0
        mark_incomplete "T2: expected one guard call in the driver, found $call_count"
    fi
    sha256sum -- "$TOP/$DRIVER" "$EVIDENCE"/drivers/*.bash > "$EVIDENCE/drivers/sha256.txt"
    for installer in "${INSTALLERS[@]}"; do
        for variant in corrected original guard-removed; do
            if [[ "$variant" == original && $original_ok == 0 ]]; then continue; fi
            if [[ "$variant" == guard-removed && $removed_ok == 0 ]]; then continue; fi
            name="t2/$installer/$variant"
            case_dir="$EVIDENCE/cases/$name"
            new_checkout "$case_dir"
            printf '%b' "${INCLUDE_LINE}\nAA_m2sentinel_MARK := \$(shell printf parsed > \$(TOP)/$MARKER_NAME)\n" \
                > "$case_dir/co/configure/CONFIG_SITE.local"
            if [[ "$variant" != corrected ]]; then
                cp --remove-destination -- "$EVIDENCE/drivers/$variant.bash" "$case_dir/co/$DRIVER"
            fi
            run_case "$name" "$case_dir" "install-local-$installer.bash" --plan
            marker="$case_dir/co/$MARKER_NAME"
            if [[ "$variant" == corrected ]]; then
                assert_refusal 2 GENERIC "$installer"
                assert_that 'Make never parsed the rejected configuration' 'the parse marker exists' [ ! -e "$marker" ]
            elif trace_usable; then
                assert_that "the $variant driver parsed the rejected configuration" 'the parse marker is missing' [ -e "$marker" ]
                if [[ -e "$marker" ]]; then
                    assert_that 'the marker holds the value Make wrote' "marker content: $(< "$marker")" \
                        [ "$(< "$marker")" = parsed ]
                fi
                assert_that "the $variant driver does not refuse with the include contract" 'the diagnostic was produced' \
                    lacks "$(< "$case_dir/stderr.txt")" "$GENERIC_REASON"
            fi
            runs=$((runs + 1))
        done
    done
    group_report 'T2 defect sensitivity' "$failed_before" "$runs"
}

# T3: valid inputs and --help still work; the plan reports the host operating system and the selected backend.
function run_t3 {
    local installer preset newline name case_dir expected backend failed_before runs=0 stdout forbidden
    expected=$(host_preset)
    if [[ "$expected" == unsupported ]]; then
        mark_incomplete 'T3: this host is not a supported installer host'
        return 0
    fi
    failed_before=$TEST_FAILED
    for installer in "${INSTALLERS[@]}"; do
        backend=mariadb
        if [[ "$installer" == sqlite ]]; then backend=sqlite; fi
        for preset in absent "${PRESETS[@]}"; do
            for newline in with without; do
                if [[ "$preset" == absent && "$newline" == without ]]; then continue; fi
                name="t3/$installer/$preset-$newline-newline"
                case_dir="$EVIDENCE/cases/$name"
                new_checkout "$case_dir"
                if [[ "$preset" != absent ]]; then
                    printf '%s' "include \$(TOP)/configure/os/$preset.mk" > "$case_dir/co/configure/CONFIG_SITE.local"
                    if [[ "$newline" == with ]]; then printf '\n' >> "$case_dir/co/configure/CONFIG_SITE.local"; fi
                fi
                run_case "$name" "$case_dir" "install-local-$installer.bash" --plan
                trace_usable || continue
                forbidden=$(exec_hits "$CASE_DIR/trace.txt" "$FORBIDDEN_NO_MAKE_RE")
                assert_that 'no sudo, package or service command starts' "$forbidden" [ -z "$forbidden" ]
                assert_that 'the plan exits 0' "status $CASE_RC" [ "$CASE_RC" -eq 0 ]
                assert_that "the plan prints OS: $expected" 'the host line is missing' \
                    grep -Fxq -- "OS: $expected" "$CASE_DIR/stdout.txt"
                assert_that "the plan prints Backend: $backend" 'the backend line is missing' \
                    grep -Fxq -- "Backend: $backend" "$CASE_DIR/stdout.txt"
                assert_unchanged
                assert_plan_in_trace
                runs=$((runs + 1))
            done
        done
        name="t3/$installer/help-invalid"
        case_dir="$EVIDENCE/cases/$name"
        new_checkout "$case_dir"
        printf '%b' "${INCLUDE_LINE}\nAA_m2sentinel_MARK := \$(shell printf parsed > \$(TOP)/$MARKER_NAME)\n" \
            > "$case_dir/co/configure/CONFIG_SITE.local"
        run_case "$name" "$case_dir" "install-local-$installer.bash" --help
        trace_usable || continue
        forbidden=$(exec_hits "$CASE_DIR/trace.txt" "$FORBIDDEN_RE")
        assert_that 'help starts no Make, sudo, package or service command' "$forbidden" [ -z "$forbidden" ]
        assert_that 'help exits 0' "status $CASE_RC" [ "$CASE_RC" -eq 0 ]
        assert_that 'help prints the usage' 'the usage line is missing' grep -q '^Usage: bash scripts/install-local-' "$CASE_DIR/stdout.txt"
        assert_that 'help did not parse the configuration' 'the parse marker exists' [ ! -e "$CASE_DIR/co/$MARKER_NAME" ]
        assert_unchanged
        runs=$((runs + 1))
    done
    group_report 'T3 accepted input and --help' "$failed_before" "$runs"
}

# T4: the real OS targets still write the generated include and leave ../CONFIG_SITE.local alone.
function run_t4 {
    local target mapped name case_dir expected failed_before=$TEST_FAILED runs=0 other status
    for target in "${TARGETS[@]}"; do
        mapped="$target"
        case "$target" in centos7|centos8) mapped=rocky8 ;; esac
        other=debian12
        if [[ "$mapped" == debian12 ]]; then other=rocky8; fi
        name="t4/$target"
        case_dir="$EVIDENCE/cases/$name"
        CURRENT="$name"
        new_checkout "$case_dir"
        printf '%s\n' "include \$(TOP)/configure/os/$other.mk" > "$case_dir/co/configure/CONFIG_SITE.local"
        describe_path "$case_dir/CONFIG_SITE.local" > "$case_dir/parent.before"
        status=0
        timeout --kill-after=5 "$CASE_TIMEOUT" make --no-print-directory -s -C "$case_dir/co" "$target.conf" \
            > "$case_dir/stdout.txt" 2> "$case_dir/stderr.txt" || status=$?
        printf 'include $(TOP)/configure/os/%s.mk\n' "$mapped" > "$case_dir/expected.txt"
        describe_path "$case_dir/CONFIG_SITE.local" > "$case_dir/parent.after"
        assert_that "make $target.conf exits 0" "status $status" [ "$status" -eq 0 ]
        assert_that 'the generated include is exactly the expected line' 'bytes differ from expected.txt' \
            same_file "$case_dir/co/configure/CONFIG_SITE.local" "$case_dir/expected.txt"
        assert_that '../CONFIG_SITE.local is unchanged' 'parent.before differs from parent.after' \
            same_file "$case_dir/parent.before" "$case_dir/parent.after"
        runs=$((runs + 1))
    done
    group_report 'T4 direct OS targets' "$failed_before" "$runs"
}

# Successful installer execs recorded in every trace below an evidence directory.
function child_installer_execs {
    if [[ ! -d "$1/cases" ]]; then return 0; fi
    find "$1/cases" -name trace.txt -print0 | xargs -0 -r grep -h -E "$INSTALLER_EXEC_RE" | grep ') = 0$' || true
}

# T5 dispatch: the mode is chosen by argument only. Children run the smoke fixture and the parent reads their traces.
function check_dispatch {
    local tag child rc expectation hits failed_before=$TEST_FAILED runs=0 line bad
    local -a launch=()
    for tag in default-no-ack default-ack local-no-ack local-ack disposable-no-ack disposable-ack; do
        case "$tag" in
            default-no-ack) launch=(env -u AA_TEST_DISPOSABLE_HOST -u AA_TEST_AUTHORIZED_GUEST bash "$SELF" --smoke) expectation=0 ;;
            default-ack) launch=(env -u AA_TEST_AUTHORIZED_GUEST AA_TEST_DISPOSABLE_HOST=YES bash "$SELF" --smoke) expectation=0 ;;
            local-no-ack) launch=(env -u AA_TEST_DISPOSABLE_HOST -u AA_TEST_AUTHORIZED_GUEST bash "$SELF" --local --smoke) expectation=0 ;;
            local-ack) launch=(env -u AA_TEST_AUTHORIZED_GUEST AA_TEST_DISPOSABLE_HOST=YES bash "$SELF" --local --smoke) expectation=0 ;;
            disposable-no-ack) launch=(env -u AA_TEST_DISPOSABLE_HOST -u AA_TEST_AUTHORIZED_GUEST bash "$SELF" --disposable-host --smoke) expectation=77 ;;
            disposable-ack) launch=(env -u AA_TEST_AUTHORIZED_GUEST AA_TEST_DISPOSABLE_HOST=YES bash "$SELF" --disposable-host --smoke) expectation=77 ;;
        esac
        child="$EVIDENCE/dispatch/$tag"
        CURRENT="dispatch/$tag"
        mkdir -p "$child"
        rc=0
        "${launch[@]}" --evidence "$child/evidence" > "$child/stdout.txt" 2> "$child/stderr.txt" || rc=$?
        printf '%s\n' "${launch[@]}" > "$child/command.txt"
        assert_that "the child exits $expectation" "status $rc" [ "$rc" -eq "$expectation" ]
        if [[ "$expectation" == 0 ]]; then
            hits=$(child_installer_execs "$child/evidence" | wc -l)
            bad=''
            while IFS= read -r line; do
                if [[ "$line" != *'"--plan"'* && "$line" != *'"--help"'* ]]; then bad="$line"; fi
            done < <(child_installer_execs "$child/evidence")
            assert_that 'the child launched installers' "installer execs: $hits" [ "$hits" -ge 3 ]
            assert_that 'every installer the child launched carries --plan' "$bad" [ -z "$bad" ]
            assert_that 'the child ran in local mode' 'the summary does not name local mode' grep -q 'Mode  *: local' "$child/stdout.txt"
        else
            assert_that 'the child launched no installer' 'a case directory exists' [ ! -d "$child/evidence/cases" ]
            assert_that 'the child reported INCOMPLETE' 'no INCOMPLETE line' grep -q '^INCOMPLETE:' "$child/stderr.txt"
        fi
        runs=$((runs + 1))
    done
    group_report 'T5 mode dispatch' "$failed_before" "$runs"
}

# Confirms on the machine every item of the guest identity list that a program can observe before any case runs.
function confirm_disposable_guest {
    local id='' version='' key value unit location reason='' virt
    local -a missing=()
    if [[ "${AA_TEST_DISPOSABLE_HOST:-}" != YES ]]; then missing+=('AA_TEST_DISPOSABLE_HOST is not YES'); fi
    if (( EUID == 0 )); then missing+=('the user is root'); fi
    while IFS='=' read -r key value || [[ -n "${key:-}" ]]; do
        value="${value//\"/}"
        case "$key" in ID) id="$value" ;; VERSION_ID) version="$value" ;; esac
    done < /etc/os-release
    case "$id:$version" in
        debian:13|debian:13.*|rocky:8.10|rocky:8.10.*) ;;
        *) missing+=("the operating system is not Debian 13 or Rocky 8.10") ;;
    esac
    virt=$(systemd-detect-virt --vm 2> /dev/null || true)
    if [[ -z "$virt" || "$virt" == none ]]; then missing+=('systemd-detect-virt --vm does not report a virtual machine'); fi
    if [[ "${AA_TEST_AUTHORIZED_GUEST:-}" != "$(hostname)" ]]; then missing+=('AA_TEST_AUTHORIZED_GUEST does not name this host'); fi
    location=$(make --no-print-directory -s -C "$PRISTINE" print-AA_INSTALL_LOCATION 2> /dev/null || true)
    unit=$(make --no-print-directory -s -C "$PRISTINE" print-SYSTEMD_FILENAME 2> /dev/null || true)
    if [[ -z "$location" || -e "$location" ]]; then missing+=('the installation path is unresolved or already exists'); fi
    if [[ -z "$unit" || -n "$(systemctl list-unit-files --no-legend -- "$unit" 2> /dev/null || true)" ]]; then
        missing+=('the appliance service unit is unresolved or already exists')
    fi
    printf 'os=%s:%s\nvirt=%s\nhost=%s\nuid=%s\ninstall_path=%s\nunit=%s\nmissing=%s\n' \
        "$id" "$version" "$virt" "$(hostname)" "$EUID" "$location" "$unit" "${#missing[@]}" > "$EVIDENCE/guest-identity.txt"
    if (( ${#missing[@]} )); then
        printf -v reason '%s; ' "${missing[@]}"
        incomplete_exit "the guest is not confirmed: ${reason%; }"
    fi
}

function record_environment {
    {
        printf 'utc_start=%s\nmode=%s\nsmoke=%s\nuser=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$MODE" "$SMOKE" "$(id -un)"
        printf 'kernel=%s\n' "$(uname -srm)"
        printf 'bash=%s\n' "$(bash --version | head -n1)"
        printf 'strace=%s\n' "$(strace -V | head -n1)"
        printf 'make=%s\n' "$(make --version | head -n1)"
        printf 'git_head=%s\n' "$(git -C "$TOP" rev-parse HEAD)"
        printf 'original_driver_commit=%s\n' "$ORIGINAL_DRIVER_COMMIT"
        printf 'host_preset=%s\n' "$(host_preset)"
        sha256sum -- "$TOP/$DRIVER" "$TOP"/scripts/install-local-*.bash "$SELF"
    } > "$EVIDENCE/environment.txt"
}

function main {
    local stamp pristine_check mode_given=''
    while (( $# )); do
        case "$1" in
            --local|--disposable-host)
                if [[ -n "$mode_given" && "$mode_given" != "$1" ]]; then printf '%s\n' 'Choose one mode' >&2; exit 2; fi
                mode_given="$1"
                MODE=local
                if [[ "$1" == --disposable-host ]]; then MODE=disposable; fi
                shift ;;
            --smoke) SMOKE=1; shift ;;
            --evidence)
                (( $# >= 2 )) || { printf '%s\n' '--evidence requires a directory' >&2; exit 2; }
                EVIDENCE="$2"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
        esac
    done
    trap handle_exit EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    if (( EUID == 0 )); then incomplete_exit 'the installers refuse root; run this test as the checkout owner'; fi
    if [[ -z "$EVIDENCE" ]]; then
        stamp=$(date -u +%Y%m%dT%H%M%SZ)
        EVIDENCE="$TOP/work/m2-install-config/$stamp"
    fi
    mkdir -p "$EVIDENCE"
    EVIDENCE=$(realpath -- "$EVIDENCE")
    RESULTS="$EVIDENCE/results.tsv"
    : > "$RESULTS"
    if ! strace -qq -f -e trace=execve -o /dev/null -- true 2> /dev/null; then
        incomplete_exit 'strace cannot trace commands here (ptrace is not permitted or strace is missing)'
    fi
    make_pristine
    record_environment
    if [[ "$MODE" == disposable ]]; then confirm_disposable_guest; fi
    printf '%b%s%b mode=%s smoke=%s evidence=%s\n' "$BLUE" 'Local install configuration checks' "$NC" "$MODE" "$SMOKE" "$EVIDENCE"
    run_t1
    if (( ! SMOKE && ! VIOLATION )); then
        run_t2
        run_t3
        run_t4
        if [[ "$MODE" == local ]]; then check_dispatch; fi
    fi
    CURRENT='pristine'
    pristine_check="$EVIDENCE/pristine.after.sha256"
    (cd "$PRISTINE" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) > "$pristine_check"
    assert_that 'the pristine tree was not written by any case' 'pristine hashes changed' \
        same_file "$EVIDENCE/pristine.sha256" "$pristine_check"
    TEST_COMPLETE=1
}

main "$@"
