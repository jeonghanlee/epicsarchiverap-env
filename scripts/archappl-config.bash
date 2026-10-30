# Shared Bash configuration loader for the launcher and installed wrappers.

# Enumerate only regular, non-hidden files in bytewise filename order. Keep
# glob and locale settings in a subshell so configuration can set them later.
function archappl_configuration_files {
    (
        export LC_ALL=C
        set +f
        unset GLOBIGNORE
        shopt -s nullglob
        shopt -u dotglob failglob
        printf '%s\0' "$1/archappl.conf"
        for _aa_config_file in "$1"/config.d/*.conf; do
            [[ -f $_aa_config_file ]] && printf '%s\0' "$_aa_config_file"
        done
        return 0
    )
}

# Validate the complete selection before evaluating any file. Startup keeps
# the historical last-command status behavior; health requires successful
# evaluation and suppresses configuration output. Return 1 for preflight
# errors and 2 for a health evaluation error. Preflight mode validates without
# evaluating files; each child wrapper applies its own environment once.
# Files are trusted Bash input.
function archappl_load_configuration {
    local _aa_config_dir="$1" _aa_config_mode="${2:-startup}"
    local _aa_config_file _aa_config_options="$-" _aa_config_status=0
    local -a _aa_config_files=()

    if [[ -e $_aa_config_dir/config.d ]] &&
        { [[ ! -d $_aa_config_dir/config.d || ! -r $_aa_config_dir/config.d || ! -x $_aa_config_dir/config.d ]]; }; then
        printf 'ERROR: unreadable configuration directory: %s\n' "$_aa_config_dir/config.d" >&2
        return 1
    fi
    mapfile -d '' -t _aa_config_files < <(archappl_configuration_files "$_aa_config_dir")
    for _aa_config_file in "${_aa_config_files[@]}"; do
        if [[ ! -f $_aa_config_file || ! -r $_aa_config_file ]] ||
            ! "${BASH}" -n "$_aa_config_file" >/dev/null 2>&1; then
            printf 'ERROR: unreadable or invalid shell configuration: %s\n' "$_aa_config_file" >&2
            return 1
        fi
    done

    if [[ $_aa_config_mode == preflight ]]; then return 0; fi

    set -a
    for _aa_config_file in "${_aa_config_files[@]}"; do
        if [[ $_aa_config_mode == health ]]; then
            # shellcheck disable=SC1090
            if ! . "$_aa_config_file" >/dev/null 2>&1; then
                printf 'ERROR: configuration evaluation failed: %s\n' "$_aa_config_file" >&2
                _aa_config_status=2
                break
            fi
        else
            # shellcheck disable=SC1090
            . "$_aa_config_file" || :
        fi
    done
    if [[ $_aa_config_options != *a* ]]; then set +a; fi
    return "$_aa_config_status"
}
