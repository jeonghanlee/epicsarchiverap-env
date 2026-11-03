#!/bin/bash
# Compares an installed Archiver Appliance with the state that a checkout renders and prints one line per layer.
# Reads the installed state and changes nothing on the system; the installer scripts call it before they act.
#
# Output, one tab separated line each: installation (present or first), the layers program, configuration, systemd,
# schema, storage and runtime with their state and reason, and build (needed or not-needed) with its reason. Lines that
# start with a hash sign carry detail for a person. A layer is unchanged, changed or refuse; runtime is observed.
# Exit status: 0 when no layer refuses, 1 when a layer refuses, 2 for a usage error or a source that cannot be read.
set -euo pipefail
export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
unset BASH_ENV ENV CDPATH

readonly -a COMPONENTS=(mgmt engine etl retrieval)
readonly -a CLASSPATH_VARIABLES=(ARCHAPPL_APPLIANCES ARCHAPPL_POLICIES ARCHAPPL_PROPERTIES_FILENAME)
readonly -a CONFIG_FILES=(archappl.conf appliances.xml archappl.properties policies.py)
readonly -a SCRIPT_FILES=(archappl.bash archappl-config.bash)
readonly OVERRIDE_FOLDER='tomcat9.service.d'
readonly SOH=$'\001'

install_dir=''
systemd_dir=''
rendered_dir=''
scripts_dir=''
source_dir=''
war_dir=''
sql_file=''
service_user=''
service_unit=''
health_timer=''
mgmt_url=''
accept_schema=0
no_sudo=0
skip_runtime=0
declare -a storage_dirs=()
declare -A ports=()
declare -A shutdown_ports=()

installation='present'
installed_commit=''
target_commit=''
refused=0
declare -a results=()
declare -a details=()
layer_state='unchanged'
layer_reason=''
build_state='not-needed'
build_reason=''

function usage {
    printf '%s\n' \
        'Usage: inspect-local-install.bash [OPTIONS]' \
        '' \
        'Required: --install-dir DIR --systemd-dir DIR --rendered-dir DIR --scripts-dir DIR --source-dir DIR' \
        '          --war-dir DIR --sql-file PATH --service-user NAME --service-unit NAME --health-timer NAME' \
        'Optional: --storage-dir DIR (repeat), --port SERVICE=PORT (repeat), --shutdown-port SERVICE=PORT (repeat),' \
        '          --mgmt-url URL, --accept-schema, --no-sudo, --skip-runtime, --help' \
        '' \
        'Reads the installed appliance below --install-dir and --systemd-dir and the rendered files of the checkout.' \
        '--sql-file is relative to --source-dir. --no-sudo never calls sudo; --skip-runtime observes no unit or URL.'
}

function fail {
    printf 'inspect-local-install: %s\n' "$1" >&2
    exit 2
}

function parse_pair {
    local option="$1" value="$2" name port
    [[ "$value" == *=* ]] || fail "$option needs SERVICE=PORT"
    name="${value%%=*}"
    port="${value#*=}"
    [[ " ${COMPONENTS[*]} " == *" $name "* ]] || fail "$option names an unknown service: $name"
    [[ "$port" =~ ^-?[0-9]{1,5}$ ]] || fail "$option needs a numeric port: $port"
    if [[ "$option" == --port ]]; then ports["$name"]="$port"; else shutdown_ports["$name"]="$port"; fi
}

function parse_args {
    while (( $# )); do
        case "$1" in
            --install-dir|--systemd-dir|--rendered-dir|--scripts-dir|--source-dir|--war-dir|--sql-file|--service-user|\
--service-unit|--health-timer|--mgmt-url|--storage-dir|--port|--shutdown-port)
                (( $# >= 2 )) || fail "$1 needs a value"
                case "$1" in
                    --install-dir) install_dir="$2" ;;
                    --systemd-dir) systemd_dir="$2" ;;
                    --rendered-dir) rendered_dir="$2" ;;
                    --scripts-dir) scripts_dir="$2" ;;
                    --source-dir) source_dir="$2" ;;
                    --war-dir) war_dir="$2" ;;
                    --sql-file) sql_file="$2" ;;
                    --service-user) service_user="$2" ;;
                    --service-unit) service_unit="$2" ;;
                    --health-timer) health_timer="$2" ;;
                    --mgmt-url) mgmt_url="$2" ;;
                    --storage-dir) storage_dirs+=("$2") ;;
                    --port|--shutdown-port) parse_pair "$1" "$2" ;;
                esac
                shift 2 ;;
            --accept-schema) accept_schema=1; shift ;;
            --no-sudo) no_sudo=1; shift ;;
            --skip-runtime) skip_runtime=1; shift ;;
            -h|--help) usage; exit 0 ;;
            *) fail "Unknown argument: $1" ;;
        esac
    done
    local name
    for name in install_dir systemd_dir rendered_dir scripts_dir source_dir war_dir sql_file service_user service_unit health_timer; do
        [[ -n "${!name}" ]] || fail "Missing option for ${name//_/-}"
    done
    [[ -d "$source_dir" ]] || fail "Source folder does not exist: $source_dir"
}

# Joins its arguments with a semicolon and a space.
function join_reasons {
    local joined='' item
    for item in "$@"; do
        if [[ -n "$joined" ]]; then joined+='; '; fi
        joined+="$item"
    done
    printf '%s' "$joined"
}

function emit {
    local name="$1" state="$2" reason="$3"
    reason="${reason//$'\n'/; }"
    reason="${reason//$'\t'/ }"
    results+=("$(printf '%s\t%s\t%s' "$name" "$state" "$reason")")
    if [[ "$state" == refuse ]]; then refused=1; fi
}

# Reads the value of NAME from a file of NAME=value lines, without quotes.
function conf_value {
    awk -v name="$2" 'index($0, name "=") == 1 { value = substr($0, length(name) + 2); gsub(/^"|"$/, "", value); print value; exit }' "$1"
}

# Appends a difference to the global list when the installed file is missing or differs from the rendered one.
function compare_file {
    local rendered="$1" installed="$2" label="$3"
    if [[ ! -f "$rendered" ]]; then
        differences+=("not rendered: $label")
    elif [[ ! -f "$installed" ]]; then
        differences+=("not installed: $label")
    elif ! cmp -s -- "$rendered" "$installed"; then
        differences+=("differs: $label")
    fi
}

function inspect_program {
    local version_file="$install_dir/mgmt/webapps/mgmt/ui/comm/version.txt" line='' conf variable
    local -a reasons=()
    layer_state='unchanged'
    target_commit=$(git -C "$source_dir" rev-parse HEAD) || fail "Cannot read the commit of $source_dir"
    if [[ ! -r "$version_file" ]]; then
        installation='first'
        layer_state='changed'
        layer_reason='no installed version.txt: first installation'
        return 0
    fi
    IFS= read -r line < "$version_file" || [[ -n "$line" ]] || fail "Cannot read $version_file"
    if [[ "$line" =~ Version[[:space:]]+([0-9a-fA-F]{7,40}) ]]; then
        installed_commit="${BASH_REMATCH[1],,}"
    else
        layer_state='refuse'
        layer_reason="the installed version.txt names no commit: $version_file"
        return 0
    fi
    if [[ "$target_commit" != "$installed_commit"* ]]; then
        layer_state='changed'
        reasons+=("installed $installed_commit, target ${target_commit:0:8}")
    fi
    conf="$install_dir/archappl.conf"
    if [[ -r "$conf" ]]; then
        for variable in "${CLASSPATH_VARIABLES[@]}"; do
            if ! grep -q "^${variable}=" "$conf"; then
                layer_state='changed'
                reasons+=("the installed archappl.conf does not set $variable: the copy inside the WAR is in use")
            fi
        done
    fi
    if compgen -G "$install_dir/*/.payload.*" > /dev/null; then
        layer_state='refuse'
        reasons+=("a retained payload folder of a failed install exists below $install_dir")
    fi
    if (( ${#reasons[@]} )); then layer_reason=$(join_reasons "${reasons[@]}"); else layer_reason="commit $installed_commit"; fi
}

# A build is needed when the program changed or the four WARs of the target commit are not in the WAR folder.
function inspect_build {
    local abbreviation="${target_commit:0:8}" service
    local -a missing=()
    for service in "${COMPONENTS[@]}"; do
        if ! compgen -G "$war_dir/*-$abbreviation-$service.war" > /dev/null; then missing+=("$service"); fi
    done
    if [[ "$layer_state" == changed && "$installation" == first ]]; then
        build_state='needed'
        build_reason='first installation'
    elif (( ${#missing[@]} )); then
        build_state='needed'
        build_reason="no WAR of commit $abbreviation in $war_dir for: ${missing[*]}"
    elif [[ "$installation" == present && "$target_commit" != "$installed_commit"* ]]; then
        build_state='needed'
        build_reason="the program changed from $installed_commit to $abbreviation"
    else
        build_state='not-needed'
        build_reason="the four WARs of commit $abbreviation are in $war_dir"
    fi
}

function inspect_configuration {
    local service name conf java_home catalina_home port shutdown server_xml
    local -a differences=() refusals=()
    layer_state='unchanged'
    if [[ "$installation" == first ]]; then
        layer_state='changed'
        layer_reason='first installation'
        return 0
    fi
    for name in "${CONFIG_FILES[@]}"; do compare_file "$rendered_dir/$name" "$install_dir/$name" "$name"; done
    for name in "${SCRIPT_FILES[@]}"; do compare_file "$scripts_dir/$name" "$install_dir/$name" "$name"; done
    for service in "${COMPONENTS[@]}"; do
        compare_file "$rendered_dir/context.xml" "$install_dir/$service/conf/context.xml" "$service/conf/context.xml"
        compare_file "$rendered_dir/$service.conf" "$install_dir/$service/conf/$service.conf" "$service/conf/$service.conf"
        server_xml="$install_dir/$service/conf/server.xml"
        port="${ports[$service]:-}"
        shutdown="${shutdown_ports[$service]:-}"
        if [[ -n "$port" ]] && ! grep -qF "Connector port=\"$port\"" "$server_xml" 2> /dev/null; then
            differences+=("$service/conf/server.xml does not name the port $port")
        fi
        if [[ -n "$shutdown" ]] && ! grep -qF "Server port=\"$shutdown\" shutdown=\"SHUTDOWN\"" "$server_xml" 2> /dev/null; then
            differences+=("$service/conf/server.xml does not name the shutdown port $shutdown")
        fi
    done
    conf="$rendered_dir/archappl.conf"
    if [[ -r "$conf" ]]; then
        java_home=$(conf_value "$conf" JAVA_HOME)
        catalina_home=$(conf_value "$conf" CATALINA_HOME)
        if [[ -n "$java_home" && ! -x "$java_home/bin/java" ]]; then refusals+=("the configured JDK is missing: $java_home"); fi
        if [[ -n "$catalina_home" && ! -d "$catalina_home" ]]; then refusals+=("the configured Tomcat is missing: $catalina_home"); fi
    fi
    if (( ${#refusals[@]} )); then
        layer_state='refuse'
        layer_reason=$(join_reasons "${refusals[@]}")
    elif (( ${#differences[@]} )); then
        layer_state='changed'
        layer_reason=$(join_reasons "${differences[@]}")
    else
        layer_reason='the rendered files equal the installed files'
    fi
}

function inspect_systemd {
    local file name target
    local -a differences=()
    layer_state='unchanged'
    if [[ "$installation" == first ]]; then
        layer_state='changed'
        layer_reason='first installation'
        return 0
    fi
    if [[ ! -d "$rendered_dir/systemd" ]]; then
        layer_state='refuse'
        layer_reason="no rendered units in $rendered_dir/systemd: run make conf.install"
        return 0
    fi
    for file in "$rendered_dir"/systemd/*; do
        name="${file##*/}"
        [[ "$name" == *.in || ! -f "$file" ]] && continue
        if [[ "$name" == override.conf ]]; then target="$systemd_dir/$OVERRIDE_FOLDER/$name"; else target="$systemd_dir/$name"; fi
        compare_file "$file" "$target" "$name"
    done
    if (( ${#differences[@]} )); then
        layer_state='changed'
        layer_reason=$(join_reasons "${differences[@]}")
    else
        layer_reason='the rendered units equal the installed units'
    fi
}

# Reduces a SQL file to one line per statement; the line breaks inside a statement become SOH characters.
function sql_statements {
    awk 'BEGIN { RS = ";" } { text = $0; gsub(/\r/, "", text); stripped = text; gsub(/[ \t\n]/, "", stripped); if (stripped == "") next; gsub(/\n/, "\001", text); print text }'
}

# Prints the table that a statement creates, or nothing when it is not a whole CREATE TABLE statement.
function created_table {
    local statement="$1" pattern
    pattern="^(${SOH}|[[:space:]]|--[^${SOH}]*${SOH})*CREATE[[:space:]]+TABLE[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)"
    shopt -s nocasematch
    if [[ "$statement" =~ $pattern ]]; then printf '%s' "${BASH_REMATCH[3]}"; fi
    shopt -u nocasematch
}

function inspect_schema {
    local installed_full old_text new_text removed added statement table old_tables=' ' diff_text
    local -a added_tables=() other=()
    layer_state='unchanged'
    if [[ "$installation" == first ]]; then
        layer_state='changed'
        layer_reason='first installation'
        return 0
    fi
    if [[ "$target_commit" == "$installed_commit"* ]]; then
        layer_reason="the installed and the target commit are the same: ${installed_commit}"
        return 0
    fi
    if ! installed_full=$(git -C "$source_dir" rev-parse --verify --quiet "${installed_commit}^{commit}"); then
        layer_state='refuse'
        layer_reason="the installed commit $installed_commit is not in the source clone: fetch it"
        return 0
    fi
    old_text=$(git -C "$source_dir" show "$installed_full:$sql_file" 2> /dev/null) || {
        layer_state='refuse'
        layer_reason="$sql_file does not exist at the installed commit $installed_commit"
        return 0
    }
    new_text=$(git -C "$source_dir" show "$target_commit:$sql_file" 2> /dev/null) || {
        layer_state='refuse'
        layer_reason="$sql_file does not exist at the target commit ${target_commit:0:8}"
        return 0
    }
    removed=$(comm -23 <(sql_statements <<< "$old_text" | LC_ALL=C sort) <(sql_statements <<< "$new_text" | LC_ALL=C sort))
    added=$(comm -13 <(sql_statements <<< "$old_text" | LC_ALL=C sort) <(sql_statements <<< "$new_text" | LC_ALL=C sort))
    if [[ -z "$removed" && -z "$added" ]]; then
        layer_reason="the SQL file is the same at $installed_commit and ${target_commit:0:8}"
        return 0
    fi
    while IFS= read -r statement; do
        [[ -n "$statement" ]] || continue
        table=$(created_table "$statement")
        [[ -z "$table" ]] || old_tables+="$table "
    done <<< "$(sql_statements <<< "$old_text")"
    if [[ -z "$removed" ]]; then
        while IFS= read -r statement; do
            [[ -n "$statement" ]] || continue
            table=$(created_table "$statement")
            if [[ -n "$table" && "$old_tables" != *" $table "* ]]; then added_tables+=("$table"); else other+=("$statement"); fi
        done <<< "$added"
    fi
    if [[ -z "$removed" ]] && (( ! ${#other[@]} )); then
        layer_state='changed'
        layer_reason="only whole tables are added, to be loaded: ${added_tables[*]}"
        return 0
    fi
    diff_text=$(git -C "$source_dir" diff --no-color --unified=1 "$installed_full" "$target_commit" -- "$sql_file" || true)
    while IFS= read -r statement; do details+=("# schema diff: $statement"); done <<< "$diff_text"
    if (( accept_schema )); then
        layer_state='changed'
        layer_reason="the schema differs in more than whole tables and was accepted with --accept-schema"
    else
        layer_state='refuse'
        layer_reason="the schema differs in more than whole tables: read the diff, then run again with --accept-schema"
    fi
}

function inspect_storage {
    local dir owner
    local -a differences=()
    layer_state='unchanged'
    if (( ! ${#storage_dirs[@]} )); then
        layer_reason='no storage folder was given'
        return 0
    fi
    for dir in "${storage_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            differences+=("missing: $dir")
            continue
        fi
        owner=$(stat -c '%U' -- "$dir")
        if [[ "$owner" != "$service_user" ]]; then differences+=("$dir is owned by $owner, not $service_user"); fi
    done
    if (( ${#differences[@]} )); then
        layer_state='changed'
        layer_reason=$(join_reasons "${differences[@]}")
    else
        layer_reason="the storage folders exist and belong to $service_user"
    fi
}

function inspect_runtime {
    local unit state http version health_status
    local -a observations=()
    layer_state='observed'
    if (( skip_runtime )); then
        layer_reason='not observed: skipped'
        return 0
    fi
    for unit in "$service_unit" "$health_timer"; do
        state=$(systemctl is-active "$unit" 2> /dev/null || true)
        observations+=("$unit is ${state:-unknown}")
    done
    if [[ -n "$mgmt_url" ]]; then
        if ! command -v curl > /dev/null; then
            observations+=("HTTP not observed: curl is missing")
        elif http=$(curl -fsS --max-time 5 "$mgmt_url" 2> /dev/null); then
            version=$(awk 'match($0, /"version" *: *"[^"]*"/) { print substr($0, RSTART, RLENGTH); exit }' <<< "$http")
            observations+=("HTTP answers${version:+ with $version}")
        else
            observations+=("HTTP does not answer at $mgmt_url")
        fi
    fi
    if (( no_sudo )) || ! sudo -n true 2> /dev/null; then
        observations+=('health not observed: needs sudo')
    elif [[ ! -x "$install_dir/archappl.bash" ]]; then
        observations+=('health not observed: no installed archappl.bash')
    else
        health_status=0
        sudo -n -u "$service_user" -- "$install_dir/archappl.bash" health > /dev/null 2>&1 || health_status=$?
        observations+=("health exits $health_status")
    fi
    layer_reason=$(join_reasons "${observations[@]}")
}

function main {
    parse_args "$@"
    inspect_program
    emit program "$layer_state" "$layer_reason"
    inspect_build
    inspect_configuration
    emit configuration "$layer_state" "$layer_reason"
    inspect_systemd
    emit systemd "$layer_state" "$layer_reason"
    inspect_schema
    emit schema "$layer_state" "$layer_reason"
    inspect_storage
    emit storage "$layer_state" "$layer_reason"
    inspect_runtime
    emit runtime "$layer_state" "$layer_reason"
    printf 'installation\t%s\n' "$installation"
    printf '%s\n' "${results[@]}"
    printf 'build\t%s\t%s\n' "$build_state" "$build_reason"
    if (( ${#details[@]} )); then printf '%s\n' "${details[@]}"; fi
    return "$refused"
}

main "$@"
exit "$?"
