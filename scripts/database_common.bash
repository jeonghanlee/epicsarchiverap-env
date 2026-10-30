# Shared settings and maintenance preconditions for the public database helper.

DATABASE_KEYS=(DB_BACKEND DB_ADMIN_HOST DB_ADMIN DB_ADMIN_PASS DB_HOST_NAME
    DB_HOST_IPADDR DB_NAME DB_HOST_PORT DB_USER DB_USER_PASS DB_SOCKET
    ARCHAPPL_SQLITE_FILE AA_USERID AA_GROUPID AA_SITE_TEMPLATE_PATH
    SYSTEMD_FILENAME SYSTEMD_HEALTH_SERVICE SYSTEMD_HEALTH_TIMER)

function database_error {
    printf 'Database operation refused: %s\n' "$*" >&2
    return 2
}

# Make exports resolved values. Direct calls ask the same Makefile to resolve
# settings, preserving explicit empty environment overrides without eval.
function database_settings {
    local key index
    local -a values=() make_args=() overrides=()
    if [[ ${AA_DATABASE_SETTINGS_READY:-} == 1 ]]; then
        for key in "${DATABASE_KEYS[@]}"; do
            [[ ${!key+x} ]] || { database_error 'Incomplete Make settings'; return 2; }
        done
        return 0
    fi
    for key in "${DATABASE_KEYS[@]}"; do
        if [[ ${!key+x} ]]; then
            overrides+=("AA_INPUT_${key}=${!key}")
            make_args+=(--eval "override ${key} := \$(value AA_INPUT_${key})")
        fi
    done
    mapfile -d '' -t values < <(
        env -u MAKEFLAGS -u MFLAGS -u MAKEOVERRIDES "${overrides[@]}" \
            make -C "$ENV_TOP" --no-print-directory -s "${make_args[@]}" _database.settings &&
            printf '%s\0' AA_DATABASE_SETTINGS_END
    )
    if [[ ${#values[@]} != $((${#DATABASE_KEYS[@]} + 1)) || ${values[-1]:-} != AA_DATABASE_SETTINGS_END ]]; then
        database_error 'Cannot resolve Make settings'; return 2
    fi
    for index in "${!DATABASE_KEYS[@]}"; do
        printf -v "${DATABASE_KEYS[index]}" '%s' "${values[index]}"
        export "${DATABASE_KEYS[index]}"
    done
}

# Generated configuration is data, never executable input. Exact renderer
# assignments establish identity independently of timestamps.
function database_normalize_settings {
    DB_SOCKET="${DB_SOCKET#"${DB_SOCKET%%[![:space:]]*}"}"
    DB_SOCKET="${DB_SOCKET%"${DB_SOCKET##*[![:space:]]}"}"
}

function database_check_mariadb_config {
    local key expected line found
    local config="${AA_SITE_TEMPLATE_PATH}/mariadb.conf"
    [[ -f $config && -r $config ]] || { database_error 'Run make db.conf before this operation'; return 2; }
    for key in DB_BACKEND DB_ADMIN_HOST DB_ADMIN DB_ADMIN_PASS DB_HOST_NAME DB_HOST_IPADDR DB_NAME DB_HOST_PORT DB_USER DB_USER_PASS DB_SOCKET; do
        LC_ALL=C printf -v expected '%s=%q' "$key" "${!key}"
        found=0
        while IFS= read -r line || [[ -n $line ]]; do
            if [[ $line == "$key="* ]]; then
                [[ $line == "$expected" ]] || { database_error 'Settings changed; run make db.conf'; return 2; }
                found=$((found + 1))
            fi
        done < "$config"
        [[ $found == 1 ]] || { database_error 'Settings changed; run make db.conf'; return 2; }
    done
}

function database_offline {
    local unit output key value load active
    for unit in "$SYSTEMD_FILENAME" "$SYSTEMD_HEALTH_SERVICE" "$SYSTEMD_HEALTH_TIMER"; do
        [[ -n $unit && $unit != -* && $unit != */* ]] || { database_error 'Invalid service unit'; return 2; }
        if ! output=$(systemctl show --property=LoadState --property=ActiveState -- "$unit"); then
            database_error "Cannot inspect service state: $unit"; return 2
        fi
        load='' active=''
        while IFS='=' read -r key value; do
            case $key in LoadState) load=$value ;; ActiveState) active=$value ;; esac
        done <<< "$output"
        case "$load:$active" in
            loaded:inactive|loaded:failed|not-found:inactive|masked:inactive) ;;
            *) database_error "Stop the appliance and health units before maintenance: $unit ($load/$active)"; return 2 ;;
        esac
    done
}

function database_query_arguments {
    local token
    DATABASE_QUERY_OPTIONS=()
    case ${1:-} in queryFile|querySFile)
        [[ $# -le 4 ]] || { database_error 'Too many file-query arguments'; return 2; }
        case ${4:-NO} in ''|NO|YES) ;; *) database_error 'Verbose must be YES or NO'; return 2 ;; esac
        if [[ ${DB_BACKEND:-mariadb} == sqlite ]]; then
            [[ -n ${2:-} && -z ${3:-} ]] || { database_error 'SQLite requires a SQL file and no client options'; return 2; }
        else
            # Convert all permitted whitespace to spaces before read; no shell evaluation.
            token=${3:-}
            token=${token//$'\n'/ }
            token=${token//$'\r'/ }
            read -r -a DATABASE_QUERY_OPTIONS <<< "$token"
            for token in "${DATABASE_QUERY_OPTIONS[@]}"; do
                case $token in -N|--skip-column-names|-B|--batch|-r|--raw|-t|--table) ;;
                    *) database_error 'Unsupported query output option'; return 2 ;;
                esac
            done
        fi
        ;;
    esac
}

function database_number_rows {
    local index
    local -a rows=()
    [[ -n $1 ]] || return 0
    mapfile -t rows <<< "$1"
    for index in "${!rows[@]}"; do
        printf '>> %4d/%4d/%4d<< %80s\n' "$((index + 1))" "$((index + 1))" "${#rows[@]}" "${rows[index]}"
    done
}
