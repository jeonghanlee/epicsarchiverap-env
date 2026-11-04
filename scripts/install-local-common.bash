#!/bin/bash
# Drives the pinned systemd appliance installation for the selected database backend.
set -euo pipefail
export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
unset BASH_ENV ENV MAKEFLAGS MFLAGS GNUMAKEFLAGS
umask 022

SCRIPT_PATH=$(realpath -- "${BASH_SOURCE[0]}")
readonly SCRIPT_PATH
readonly REPO="${SCRIPT_PATH%/*/*}"
readonly OS_RELEASE='/etc/os-release'
readonly SITE_LOCAL="$REPO/configure/CONFIG_SITE.local"
readonly SITE_INCLUDE_PREFIX='include $(TOP)/configure/os/'
readonly SITE_INCLUDE_SUFFIX='.mk'
readonly -a OS_PRESETS=(debian12 debian13 rocky8 rocky10 ubuntu24 ubuntu26)
readonly -a COMPONENTS=(mgmt engine etl retrieval)
declare -a MAKE_OPTIONS=(ARCHAPPL_SITEID=als)
backend=''
transport=''
entry_script=''
db_socket=''
db_host=''
db_port=''
requested_socket=''
setup_db=0
plan=0
inspect=0
accept_schema=0
yes=0
skip_packages=0
tomcat_action=''
timeout=180
os=''
stage='preflight'
source_path=''
source_pin=''
tomcat_home=''
install_path=''
service_user=''
service_unit=''
health_timer=''
mgmt_url=''
ready_info=''
ready_health=''
ready_processes='NOT CHECKED'
ready_storage='NOT CHECKED'
ready_health_status='NOT CHECKED'
ready_health_detail=''
ready_information='NOT CHECKED'
ready_service='NOT CHECKED'
ready_timer='NOT CHECKED'
ready_service_detail=''
ready_timer_detail=''
installation_completed=0
verify_pv=0
pv_epics_bin=''
declare -a component_urls=()
declare -a ready_components=('NOT CHECKED' 'NOT CHECKED' 'NOT CHECKED' 'NOT CHECKED')
declare -A layer_state=()
declare -A layer_reason=()
installation_state='present'
build_state='not-needed'
changed_layers=''
do_install=0
do_build=0
do_schema=0
do_storage=0

function die {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

function usage {
    printf '%s\n' \
        "Usage: bash scripts/$entry_script [OPTIONS]" \
        '' \
        'Install a systemd-managed appliance on Debian 13, Rocky 8, Rocky 10.2 or Ubuntu 24.04/26.04.' \
        'Run as the ordinary checkout owner; sudo is used for privileged steps.' \
        'The selected source and site configuration come from Make settings.' \
        'Existing appliance payloads are replaced; database contents and stores remain.' \
        '' \
        '  --plan             Print the steps without installing or starting anything' \
        '  --inspect          Update the checkout, compare it with the installed appliance, print the result' \
        '                     per layer and stop; nothing on the system is changed' \
        '  --accept-schema    Continue after a schema difference that is more than whole new tables' \
        '  -y, --yes          Run without the confirmation and the soft IOC test question' \
        '  --skip-packages    Use the host-provided prerequisites' \
        '  --tomcat ACTION    existing: use as service user; replace: back up and install' \
        '  --socket PATH      MariaDB UDS path; otherwise DB_SOCKET or the OS default' \
        '  --existing-db      MariaDB: keep provisioned accounts; load schema only' \
        '  --timeout SEC      Startup deadline, 1..86400 seconds (180)' \
        '  -h, --help         Show this help' \
        '' \
        'Use ../CONFIG_SITE.local for storage, Tomcat and service-account settings.' \
        'The selected DB_BACKEND, transport and ARCHAPPL_SITEID=als apply to all Make steps.' \
        'Source inputs must be clean; the generated als site and ignored build outputs are allowed.' \
        'MariaDB starts its service and creates or updates the configured database and accounts.' \
        'Existing admin and application accounts receive configured passwords and grants.' \
        'Use --existing-db to skip database/account provisioning; schema loading still runs.' \
        'With --existing-db, DB_USER_PASS must match the existing application account password.' \
        'Set DB_ADMIN_PASS and DB_USER_PASS in ../CONFIG_SITE.local before preparing accounts.' \
        'UDS uses DB_SOCKET or the OS default; TCP clears DB_SOCKET and requires DB_HOST_NAME=127.0.0.1.' \
        'TCP uses DB_HOST_PORT and prepares the admin account at 127.0.0.1.' \
        'Account preparation needs local root socket authentication; --existing-db skips it.' \
        'The installer stops before any change unless configure/CONFIG_SITE.local is absent or holds only the generated OS include.' \
        'The OS preset rewrites configure/CONFIG_SITE.local as documented.' \
        'No VM, tag, release or automatic rollback is performed.'
}

function parse_args {
    while (( $# )); do
        case "$1" in
            --plan) plan=1; shift ;;
            --inspect) inspect=1; shift ;;
            --accept-schema) accept_schema=1; shift ;;
            -y|--yes) yes=1; shift ;;
            --skip-packages) skip_packages=1; shift ;;
            --tomcat)
                (( $# >= 2 )) || die '--tomcat requires existing or replace'
                case "$2" in
                    existing|replace) tomcat_action="$2" ;;
                    *) die '--tomcat requires existing or replace' ;;
                esac
                shift 2 ;;
            --existing-db)
                [[ "$backend" == mariadb ]] || die '--existing-db requires MariaDB'
                setup_db=0; shift ;;
            --socket)
                [[ "$transport" == uds ]] || die '--socket requires MariaDB UDS'
                (( $# >= 2 )) || die '--socket requires a path'
                requested_socket="$2"
                [[ "$requested_socket" == /* && "$requested_socket" != *[[:space:]]* ]] || die 'Socket must be an absolute path without whitespace'
                shift 2 ;;
            --timeout)
                (( $# >= 2 )) || die '--timeout requires a value'
                [[ "$2" =~ ^[0-9]{1,5}$ ]] || die 'Invalid startup timeout'
                timeout=$((10#$2))
                (( timeout >= 1 && timeout <= 86400 )) || die 'Timeout must be 1..86400'
                shift 2 ;;
            -h|--help) usage; exit 0 ;;
            --) shift; (( $# == 0 )) || die 'Unexpected positional arguments' ;;
            *) die "Unknown argument: $1" ;;
        esac
    done
    (( ! (plan && inspect) )) || die '--plan and --inspect cannot be combined'
}

function require_command {
    local resolved
    resolved=$(command -v "$1") || die "Required command not found: $1"
    [[ -x "$resolved" ]] || die "Required command is not executable: $1"
}

function detect_os {
    local key value id='' version=''
    while IFS='=' read -r key value || [[ -n "${key:-}" ]]; do
        value="${value//$'\r'/}"
        value="${value#\"}"
        value="${value%\"}"
        case "$key" in
            ID) id="$value" ;;
            VERSION_ID) version="$value" ;;
        esac
    done < "$OS_RELEASE"
    case "$id:$version" in
        debian:13|debian:13.*) os=debian13 ;;
        rocky:8|rocky:8.*) os=rocky8 ;;
        rocky:10.2|rocky:10.2.*) os=rocky10 ;;
        ubuntu:24.04|ubuntu:24.04.*) os=ubuntu24 ;;
        ubuntu:26.04|ubuntu:26.04.*) os=ubuntu26 ;;
        *) die "Unsupported host: $id $version; use Debian 13, Rocky 8, Rocky 10.2 or Ubuntu 24.04/26.04" ;;
    esac
}

# Accepts exactly the line that an operating system target generates: the include of one shipped preset.
function is_generated_include {
    local line="$1" preset known
    [[ "$line" == "$SITE_INCLUDE_PREFIX"*"$SITE_INCLUDE_SUFFIX" ]] || return 1
    preset="${line#"$SITE_INCLUDE_PREFIX"}"
    preset="${preset%"$SITE_INCLUDE_SUFFIX"}"
    for known in "${OS_PRESETS[@]}"; do
        if [[ "$preset" == "$known" ]]; then return 0; fi
    done
    return 1
}

# Refuses before any Make call, sudo, lock or package step unless configure/CONFIG_SITE.local is absent or holds
# only the generated include of one shipped preset. The file is read with Bash builtins and never evaluated.
# The diagnostic names the path, the reason and the offending line numbers, never the file contents.
function validate_site_configuration {
    local content='' body line number joined message inspect reason='' rc=0 include_seen=0
    local -a lines=() offending=()
    [[ -e "$SITE_LOCAL" || -L "$SITE_LOCAL" ]] || return 0
    if [[ -L "$SITE_LOCAL" ]]; then
        reason='is a symbolic link'
    elif [[ ! -f "$SITE_LOCAL" ]]; then
        reason='is not a regular file'
    elif [[ ! -r "$SITE_LOCAL" ]]; then
        reason='is not readable'
    else
        IFS= read -r -d '' content < "$SITE_LOCAL" || rc=$?
        if (( rc == 0 )); then
            reason='contains a NUL byte'
        elif (( rc > 1 )); then
            reason='could not be read'
        elif [[ -z "$content" ]]; then
            reason='is empty'
        else
            body="${content%$'\n'}"
            mapfile -t lines <<< "$body"
            for number in "${!lines[@]}"; do
                line="${lines[number]}"
                if (( ! include_seen )) && is_generated_include "$line"; then
                    include_seen=1
                else
                    offending+=("$((number + 1))")
                fi
            done
            if (( ${#offending[@]} )); then reason='does not hold only the generated operating system include'; fi
        fi
    fi
    [[ -n "$reason" ]] || return 0
    inspect='Inspect the file'
    printf -v message '%s %s.\n' "$SITE_LOCAL" "$reason"
    if (( ${#offending[@]} )); then
        printf -v joined '%s, ' "${offending[@]}"
        printf -v message '%sOffending lines: %s\n' "$message" "${joined%, }"
        inspect='Inspect the named lines'
    fi
    printf -v message '%s%s' "$message" \
        "The installer neither evaluates, repairs, moves nor deletes this file. $inspect, move site settings to ../CONFIG_SITE.local first, then delete configure/CONFIG_SITE.local so that the installer writes the generated include again, and run the installer again. Running make <os>.conf before the move overwrites the settings."
    die "$message"
}

function make_value {
    make --no-print-directory -s -C "$REPO" "${MAKE_OPTIONS[@]}" "print-$1"
}

function select_backend {
    MAKE_OPTIONS+=("DB_BACKEND=$backend")
    if [[ "$transport" == tcp ]]; then
        MAKE_OPTIONS+=(DB_SOCKET=)
        db_host=$(make_value DB_HOST_NAME)
        db_port=$(make_value DB_HOST_PORT)
        [[ "$db_host" == 127.0.0.1 ]] || die 'Local TCP installation requires DB_HOST_NAME=127.0.0.1'
        [[ "$db_port" =~ ^[0-9]{1,5}$ ]] || die 'Invalid MariaDB TCP port'
        (( 10#$db_port >= 1 && 10#$db_port <= 65535 )) || die 'MariaDB TCP port must be 1..65535'
    elif [[ "$transport" == uds ]]; then
        db_socket="$requested_socket"
        if [[ -z "$db_socket" ]]; then db_socket=$(make_value DB_SOCKET); fi
        if [[ -z "$db_socket" ]]; then
            case "$os" in
                debian13|ubuntu24|ubuntu26) db_socket='/run/mysqld/mysqld.sock' ;;
                rocky8|rocky10) db_socket='/var/lib/mysql/mysql.sock' ;;
            esac
        fi
        [[ "$db_socket" == /* && "$db_socket" != *[[:space:]]* ]] || die 'DB_SOCKET must be an absolute path without whitespace'
        MAKE_OPTIONS+=("DB_SOCKET=$db_socket")
    fi
}

function read_settings {
    local component port host
    source_path=$(make_value SRC_PATH)
    [[ "$source_path" == /* ]] || source_path="$REPO/$source_path"
    source_pin=$(make_value SRC_TAG)
    tomcat_home=$(make_value TOMCAT_HOME)
    install_path=$(make_value AA_INSTALL_LOCATION)
    service_user=$(make_value AA_USERID)
    service_unit=$(make_value SYSTEMD_FILENAME)
    health_timer=$(make_value SYSTEMD_HEALTH_TIMER)
    host=$(make_value ARCHAPPL_HOST_IPADDR)
    [[ -n "$source_pin" && -n "$service_user" && -n "$host" ]] || die 'Incomplete Make settings'
    [[ "$tomcat_home" == /* && "$install_path" == /* ]] || die 'Tomcat and install paths must be absolute'
    [[ "$service_unit" =~ ^[a-zA-Z0-9_.@-]+\.service$ && "$health_timer" =~ ^[a-zA-Z0-9_.@-]+\.timer$ ]] || die 'Invalid unit names'
    component_urls=()
    for component in "${COMPONENTS[@]}"; do
        port=$(make_value "ARCHAPPL_${component^^}_PORT")
        [[ "$port" =~ ^[0-9]+$ ]] || die 'Invalid component port'
        component_urls+=("http://$host:$port/$component/bpl/startupState")
    done
    port=$(make_value ARCHAPPL_MGMT_PORT)
    mgmt_url="http://$host:$port/mgmt/bpl/getApplianceInfo"
}

# Pathspecs for the files that an earlier build of this checkout copied over the source tree, read
# from the list kept in the Git directory of the source. They are tolerated until the source
# update restores them.
function prepared_ui_excludes {
    local gitdir manifest relative
    gitdir=$(git -C "$source_path" rev-parse --absolute-git-dir 2>/dev/null) || return 0
    manifest="$gitdir/aa-ui-prepared.list"
    [[ -f "$manifest" ]] || return 0
    while IFS= read -r relative; do
        [[ -n "$relative" ]] && printf '%s\0' ":(exclude,literal)src/main/org/epics/archiverappliance/$relative"
    done < "$manifest"
}

# Restores the files that an earlier build of this checkout copied over the source tree. The
# list of that copy is kept in the Git directory of the source; the interface is part of the
# source now, so the copied files are replaced by the source's own content and the list is removed.
function restore_prepared_ui {
    local gitdir manifest relative file
    local prefix='src/main/org/epics/archiverappliance'
    [[ -e "$source_path" ]] || return 0
    gitdir=$(git -C "$source_path" rev-parse --absolute-git-dir 2>/dev/null) || return 0
    manifest="$gitdir/aa-ui-prepared.list"
    [[ -f "$manifest" ]] || return 0
    while IFS= read -r relative; do
        [[ -n "$relative" ]] || continue
        file="$prefix/$relative"
        if git -C "$source_path" ls-files --error-unmatch -- "$file" > /dev/null 2>&1; then
            git -C "$source_path" checkout -- "$file"
        else
            rm -f -- "$source_path/$file"
        fi
    done < "$manifest"
    rm -f -- "$manifest"
}

# The management interface is part of the selected source; an older source does not carry it.
function require_interface_sources {
    local page
    for page in mgmt/staticcontent/index.html retrieval/staticcontent/viewer/archViewer.html; do
        [[ -f "$source_path/src/main/org/epics/archiverappliance/$page" ]] \
            || die "The selected source does not carry the management interface: missing $page"
    done
}

# Requires clean source inputs while permitting the generated site, the files of an earlier copy and ignored build output.
function check_source {
    local top pending item
    local -a prepared=()
    [[ -e "$source_path" ]] || return 0
    top=$(git -C "$source_path" rev-parse --show-toplevel) || die 'Existing source path is not a Git checkout'
    [[ "$top" == "$(realpath -- "$source_path")" ]] || die 'Source path must be the root of its Git checkout'
    while IFS= read -r -d '' item; do
        prepared+=("$item")
    done < <(prepared_ui_excludes)
    git -C "$source_path" diff --quiet --ignore-submodules=none -- . "${prepared[@]}" || die 'Source checkout contains tracked changes'
    git -C "$source_path" diff --cached --quiet --ignore-submodules=none -- . "${prepared[@]}" || die 'Source checkout contains staged changes'
    pending=$(git -C "$source_path" ls-files --others --exclude-standard -- . ':(exclude)src/sitespecific/als' "${prepared[@]}") || die 'Cannot inspect untracked source files'
    [[ -z "$pending" ]] || die "Source checkout contains untracked files: $pending"
    pending=$(git -C "$source_path" ls-files --others --ignored --exclude-standard -- src .mvn ':(exclude)src/sitespecific/als' "${prepared[@]}") || die 'Cannot inspect ignored source inputs'
    [[ -z "$pending" ]] || die "Source checkout contains ignored build inputs: $pending"
}

function run {
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    if (( ! plan )); then
        "$@"
    fi
}

function run_make {
    run make --no-print-directory -C "$REPO" "${MAKE_OPTIONS[@]}" "$@"
}

function root_make {
    run sudo -- make --no-print-directory -C "$REPO" "${MAKE_OPTIONS[@]}" "$@"
}

function install_packages {
    local package list
    local -a packages=()
    list=$(bash "$REPO/scripts/install_os_packages.bash" --list-only --os "$os")
    while IFS= read -r package; do
        if [[ "$backend" == sqlite ]]; then
            case "$package" in
                mariadb|mariadb-*|libmariadb-*) continue ;;
            esac
        fi
        [[ -n "$package" ]] && packages+=("$package")
    done <<< "$list"
    (( ${#packages[@]} )) || die 'Empty prerequisite package list'
    case "$os" in
        debian13|ubuntu24|ubuntu26)
            run sudo -- apt-get update
            run sudo -- apt-get install -y "${packages[@]}" ;;
        rocky8|rocky10) run sudo -- dnf install -y "${packages[@]}" ;;
    esac
}

# Stops an installed appliance before replacing shared runtime files or payloads.
function stop_appliance {
    local load state
    if (( plan )); then
        printf 'If installed, stop %s and require it to be inactive before changing installed files.\n' "$service_unit"
        return
    fi
    load=$(systemctl show --property=LoadState --value "$service_unit")
    if [[ "$load" != not-found ]]; then
        run sudo -- systemctl stop "$service_unit"
        state=$(systemctl show --property=ActiveState --value "$service_unit")
        [[ "$state" == inactive || "$state" == failed ]] || die "Appliance is not stopped: $state"
    fi
}

# Rejects replacement paths that would move build inputs or appliance data.
function validate_tomcat_replacement {
    local location candidate key protected
    location=$(make_value TOMCAT_INSTALL_LOCATION) || return 1
    candidate=$(realpath -m -- "$tomcat_home") || return 1
    if [[ "$tomcat_home" != "$location" || "$candidate" == / || "$candidate" != "$tomcat_home" || -L "$tomcat_home" || ( -e "$tomcat_home" && ! -d "$tomcat_home" ) ]]; then
        printf '%s\n' 'Tomcat replacement requires the default canonical directory without symlink paths.' >&2
        return 1
    fi
    if [[ "$REPO/" == "$candidate/"* ]]; then
        printf 'Tomcat replacement would move the checkout: %s\n' "$REPO" >&2
        return 1
    fi
    for key in SRC_PATH AA_INSTALL_LOCATION ARCHAPPL_STORAGE_TOP ARCHAPPL_SHORT_TERM_FOLDER ARCHAPPL_MEDIUM_TERM_FOLDER ARCHAPPL_LONG_TERM_FOLDER ARCHAPPL_SQLITE_FILE; do
        protected=$(make_value "$key") || return 1
        [[ -n "$protected" ]] || return 1
        [[ "$protected" == /* ]] || protected="$REPO/$protected"
        protected=$(realpath -m -- "$protected") || return 1
        if [[ "$protected/" == "$candidate/"* || "$candidate/" == "$protected/"* ]]; then
            printf 'Tomcat replacement overlaps %s: %s\n' "$key" "$protected" >&2
            return 1
        fi
    done
    return 0
}

# Requires an explicit choice when the checkout owner cannot execute Tomcat.
function choose_tomcat {
    local answer replace_allowed=0
    [[ -e "$tomcat_home" || -L "$tomcat_home" ]] || return 0
    [[ -z "$tomcat_action" ]] || return 0
    [[ ! -x "$tomcat_home/bin/catalina.sh" ]] || return 0
    if validate_tomcat_replacement 2>/dev/null; then
        replace_allowed=1
    fi
    printf 'The checkout owner cannot execute %s/bin/catalina.sh.\n' "$tomcat_home"
    printf '1) Use existing Tomcat after checking access as %s.\n' "$service_user"
    if (( replace_allowed )); then
        printf '%s\n' '2) Back up existing Tomcat and install the configured version (stops the appliance).'
    else
        printf '%s\n' '2) Unavailable: replacement requires the default canonical directory separate from checkout, source, appliance and data paths.'
    fi
    if (( plan )); then
        if (( replace_allowed )); then
            printf '%s\n' 'Installation will ask for a choice; --tomcat existing or --tomcat replace selects it explicitly.'
        else
            printf '%s\n' 'Use --tomcat existing to check and use this installation; replacement is unavailable.'
        fi
        return
    fi
    (( ! yes )) || die 'Select --tomcat existing or --tomcat replace for unattended installation'
    if (( replace_allowed )); then
        printf '%s' 'Tomcat choice [1/2; anything else cancels]: '
    else
        printf '%s' 'Tomcat choice [1; anything else cancels]: '
    fi
    read -r answer || die 'No answer; Tomcat preparation cancelled'
    case "$answer" in
        1) tomcat_action=existing ;;
        2)
            (( replace_allowed )) || die 'Tomcat replacement is unavailable for this path'
            tomcat_action=replace ;;
        *) die 'Tomcat preparation cancelled' ;;
    esac
}

# Retains the original directory under a unique root-created sibling directory.
function backup_tomcat {
    local backup
    validate_tomcat_replacement || die 'Unsafe Tomcat replacement path'
    [[ -d "$tomcat_home" ]] || die 'Tomcat backup requires an existing directory'
    stop_appliance
    root_make sd_health_stop
    if (( plan )); then
        printf 'Back up %s in a unique %s.backup.XXXXXXXX directory before installing Tomcat.\n' "$tomcat_home" "$tomcat_home"
        return
    fi
    backup=$(sudo -- mktemp -d -- "$tomcat_home.backup.XXXXXXXX")
    [[ -d "$backup" && ! -L "$backup" ]] || die 'Cannot create Tomcat backup directory'
    printf 'Tomcat backup: %s/tomcat\n' "$backup"
    run sudo -- mv -T -- "$tomcat_home" "$backup/tomcat"
    [[ ! -e "$tomcat_home" && ! -L "$tomcat_home" ]] || die "Tomcat backup failed: $backup"
    sudo -- test -d "$backup/tomcat" || die "Tomcat backup is unavailable: $backup"
}

function prepare_tomcat {
    local location archive url expected _unused info
    location=$(make_value TOMCAT_INSTALL_LOCATION)
    choose_tomcat
    if [[ "$tomcat_action" == replace ]]; then
        validate_tomcat_replacement || die 'Unsafe Tomcat replacement path'
    fi
    if [[ ! -e "$tomcat_home" || "$tomcat_action" == replace ]]; then
        [[ "$tomcat_action" != existing ]] || die "Existing Tomcat is missing: $tomcat_home"
        [[ "$tomcat_home" == "$location" ]] || die 'Custom TOMCAT_HOME must already contain Tomcat 9'
        run_make tomcat.get
        archive=$(make_value TOMCAT_SRC)
        url=$(make_value TOMCAT_URL)
        url="${url#\"}"
        url="${url%\"}"
        if (( ! plan )); then
            expected=$(curl -q --fail --silent --show-error --location --proto '=https' \
                --proto-redir '=https' --connect-timeout 15 --max-time 60 "$url.sha512")
            read -r expected _unused <<< "$expected"
            [[ "$expected" =~ ^[a-fA-F0-9]{128}$ ]] || die 'Invalid Tomcat SHA-512 checksum'
            printf '%s  %s\n' "$expected" "$REPO/$archive" | sha512sum --check --status
        else
            printf '%s\n' 'Verify the downloaded Tomcat archive against its Apache SHA-512 before extraction.'
        fi
        if [[ -e "$tomcat_home" ]]; then backup_tomcat; fi
        root_make tomcat.install
    fi
    if (( ! plan )); then
        sudo -n -u "$service_user" -- test -x "$tomcat_home/bin/catalina.sh" || die "Service user $service_user cannot execute $tomcat_home/bin/catalina.sh"
        sudo -n -u "$service_user" -- test -r "$tomcat_home/bin/catalina.sh" || die "Service user $service_user cannot read $tomcat_home/bin/catalina.sh"
        sudo -n -u "$service_user" -- test -r "$tomcat_home/bin/setclasspath.sh" || die "Service user $service_user cannot read $tomcat_home/bin/setclasspath.sh"
        info=$(sudo -n -u "$service_user" -- unzip -p "$tomcat_home/lib/catalina.jar" org/apache/catalina/util/ServerInfo.properties) || die "Service user $service_user cannot inspect $tomcat_home/lib/catalina.jar"
        [[ "$info" == *'server.number=9.'* ]] || die 'Tomcat 9 is required'
    fi
}

# Bounds each readiness command and rejects results returned after the deadline.
function run_before_deadline {
    local deadline="$1" remaining status=0
    shift
    remaining=$((deadline - SECONDS))
    (( remaining > 0 )) || return 124
    timeout --signal=KILL -- "$remaining" "$@" || status=$?
    (( SECONDS < deadline )) || return 124
    return "$status"
}

# Separates the shipped launcher's process and storage observations without changing its verdict.
function classify_health {
    local status="$1" component line present=0 storage_seen=0 storage_failed=0 storage_error=0
    ready_health_detail=''
    if (( status == 0 )); then
        ready_health_status=PASS
        ready_processes=PASS
        ready_storage=PASS
        return
    fi
    ready_health_status=FAIL
    if (( status == 124 )); then
        ready_health_status='TIMED OUT'
        return
    fi
    if (( status >= 128 )); then
        ready_health_status='INSPECTION ERROR'
        ready_health_detail="The health inspection ended before the startup deadline (exit $status)."
        return
    fi
    ready_processes='NOT VERIFIED'
    ready_storage='NOT CHECKED'
    for component in "${COMPONENTS[@]}"; do
        while IFS= read -r line; do
            if [[ "$line" == "$component pid="*' PRESENT verified-process-presence' ]]; then
                present=$((present + 1))
                break
            fi
        done <<< "$ready_health"
    done
    if (( present == ${#COMPONENTS[@]} )); then ready_processes=PASS; fi
    while IFS= read -r line; do
        [[ "$line" == 'storage path='* ]] || continue
        storage_seen=1
        case "$line" in
            *' FAIL storage-threshold') storage_failed=1 ;;
            *' PRESENT') ;;
            *) storage_error=1 ;;
        esac
    done <<< "$ready_health"
    if (( storage_error )); then ready_storage=ERROR
    elif (( storage_failed )); then ready_storage=FAIL
    elif (( storage_seen )); then ready_storage=PASS
    fi
}

# Requires an observed unit state before reporting inactivity; query errors remain inspection failures.
function check_unit_ready {
    local deadline="$1" unit="$2" output status=0 unit_result unit_detail=''
    output=$(run_before_deadline "$deadline" sudo -n systemctl is-active "$unit" 2>&1) || status=$?
    unit_detail=''
    case "$status:$output" in
        0:*) unit_result=PASS ;;
        124:*)
            unit_result='TIMED OUT'
            unit_detail='The unit state query did not complete within the startup deadline.' ;;
        3:inactive|3:failed|3:activating|3:deactivating|3:maintenance)
            unit_result='NOT ACTIVE'
            unit_detail="systemctl reports: $output" ;;
        *)
            unit_result='INSPECTION ERROR'
            unit_detail="Unit state could not be verified (exit $status): ${output:-No diagnostic output.}" ;;
    esac
    printf -v "$3" '%s' "$unit_result"
    printf -v "$4" '%s' "$unit_detail"
}

function wait_ready {
    local started=$SECONDS deadline=$((SECONDS + timeout)) response url index
    local pending previous='' health_status health_output remaining
    if (( plan )); then
        printf 'Wait up to %s seconds for process health, four startup states and %s\n' "$timeout" "$mgmt_url"
        printf '%s\n' 'Show the management UI, four component URLs, health result and appliance information.' \
            'Run the soft IOC PV registration/storage/CSV test if selected before installation; unattended mode skips it.'
        return
    fi
    while (( SECONDS < deadline )); do
        pending=''
        health_status=0
        health_output=$(run_before_deadline "$deadline" sudo -n -u "$service_user" -- "$install_path/archappl.bash" health 2>&1) || health_status=$?
        if (( health_status != 124 && health_status < 128 )); then ready_health="$health_output"; fi
        classify_health "$health_status"
        if [[ "$ready_processes" != PASS ]]; then pending+=' process identity checks;'; fi
        if [[ "$ready_storage" == FAIL ]]; then
            pending+=' storage usage at or above configured limit;'
        elif [[ "$ready_storage" != PASS ]]; then
            pending+=' storage inspection;'
        fi
        if (( health_status != 0 )) && [[ "$ready_processes" == PASS && "$ready_storage" == PASS ]]; then
            pending+=' health inspection;'
        fi
        for index in "${!component_urls[@]}"; do
            (( SECONDS < deadline )) || break
            url="${component_urls[$index]}"
            response=$(run_before_deadline "$deadline" curl -q --noproxy '*' --fail --silent --max-time 2 "$url") || response=''
            if ! jq -e -s 'length == 1 and (.[0] | type == "object" and .status == "STARTUP_COMPLETE")' <<< "$response" >/dev/null 2>&1; then
                ready_components[index]='NOT READY'
                pending+=" ${COMPONENTS[$index]} startup;"
            else
                ready_components[index]=PASS
            fi
        done
        (( SECONDS < deadline )) || break
        ready_info=$(run_before_deadline "$deadline" curl -q --noproxy '*' --fail --silent --max-time 2 "$mgmt_url") || ready_info=''
        if ! jq -e -s 'length == 1 and (.[0] | type == "object" and (.identity | type == "string" and length > 0)
            and (.version | type == "string" and length > 0))' <<< "$ready_info" >/dev/null 2>&1; then
            pending+=' appliance information;'
            ready_information='NOT READY'
        else
            ready_information=PASS
        fi
        check_unit_ready "$deadline" "$service_unit" ready_service ready_service_detail
        if [[ "$ready_service" != PASS ]]; then pending+=' appliance service;'; fi
        check_unit_ready "$deadline" "$health_timer" ready_timer ready_timer_detail
        if [[ "$ready_timer" != PASS ]]; then pending+=' health timer;'; fi
        if [[ -z "$pending" ]] && (( SECONDS < deadline )); then
            printf 'Startup checks passed in %s seconds.\n' "$((SECONDS - started))"
            return
        fi
        if [[ "$pending" != "$previous" ]]; then
            printf 'Waiting (%ss/%ss):%s\n' "$((SECONDS - started))" "$timeout" "$pending"
            previous="$pending"
        fi
        remaining=$((deadline - SECONDS))
        if (( remaining > 2 )); then sleep 2
        elif (( remaining > 0 )); then sleep "$remaining"
        fi
    done
    printf '\nVerification could not pass within %s seconds. Last observed results:\n' "$timeout" >&2
    show_readiness >&2
    if [[ "$ready_storage" == FAIL ]]; then
        printf '\n' >&2
        printf '%s\n' 'Storage usage has reached or exceeded the configured limit. See the usage and threshold for each path above.' \
            'Free space on the affected filesystem or move the archive stores to a filesystem with enough space.' \
            'The installer keeps the storage limit unchanged and does not delete any data.' >&2
        if [[ "$ready_processes" == PASS && "$ready_information" == PASS && "$ready_service" == PASS && "${ready_components[*]}" == 'PASS PASS PASS PASS' ]]; then
            printf '%s\n' 'The four components have started and the information API responds.' \
                'The failed storage check does not mean that the appliance failed to start.' >&2
        fi
    fi
    printf '\nInspect the service journal: ' >&2
    printf '%q ' sudo journalctl -u "$service_unit" -n 80 --no-pager >&2
    printf '\n' >&2
    die 'Installation verification did not pass; use the results above to identify the failed check.'
}

function show_readiness {
    local index
    printf 'Appliance service: %s (%s)\n' "$ready_service" "$service_unit"
    if [[ -n "$ready_service_detail" ]]; then printf '  %s\n' "$ready_service_detail"; fi
    printf 'Health timer: %s (%s)\n' "$ready_timer" "$health_timer"
    if [[ -n "$ready_timer_detail" ]]; then printf '  %s\n' "$ready_timer_detail"; fi
    printf 'Four process identities: %s\nStorage usage: %s\nHealth check: %s\n' "$ready_processes" "$ready_storage" "$ready_health_status"
    if [[ -n "$ready_health_detail" ]]; then printf '  %s\n' "$ready_health_detail"; fi
    printf '\nManagement UI: %s/ui/index.html\n' "${mgmt_url%/bpl/getApplianceInfo}"
    printf '%s\n' 'Component startup APIs (PASS means STARTUP_COMPLETE):'
    for index in "${!component_urls[@]}"; do
        printf '  %s: %s\n    %s\n' "${COMPONENTS[$index]}" "${ready_components[$index]}" "${component_urls[$index]}"
    done
    printf '\n%s\n' 'Last completed process/storage inspection:' "${ready_health:-No completed inspection result is available.}"
    printf 'Repeat health check: '
    printf '%q ' sudo -u "$service_user" -- "$install_path/archappl.bash" health
    printf '\n\nAppliance information: %s\n  %s\n' "$mgmt_url" "$ready_information"
    if [[ "$ready_information" == PASS ]]; then
        jq -r '["  Identity: " + .identity, "  Version: " + .version][]' <<< "$ready_info"
    fi
    printf '%s\n' 'The information API reports appliance identity and version; it does not verify PV acquisition or stored samples.' \
        'localhost refers to the installed machine. Open its browser or use SSH port forwarding.' \
        'PV acquisition, storage and retrieval: NOT CHECKED'
}

function show_ready {
    printf '\n%s\n' 'Installation completed. All required installation checks passed.'
    show_readiness
}

# Selects the optional data-path test and validates Base before any installation changes.
function prepare_pv_verification {
    local answer
    if (( plan )); then
        printf '%s\n' 'Before installation, offer the optional soft IOC test and validate exported EPICS_BASE, softIoc and caget.'
        return
    fi
    if (( yes )) || [[ ! -t 0 ]]; then
        printf '%s\n' 'Optional soft IOC test skipped in unattended mode; see scripts/README.md to run it separately.'
        return
    fi
    printf '\n%s\n' 'Optional test: start one changing soft IOC PV, register it, and extract real stored samples to CSV.'
    printf '%s' 'Run the PV acquisition/storage/retrieval test after installation? [y/N] '
    read -r answer || answer=''
    case "$answer" in
        y|Y|yes)
            pv_epics_bin=$(bash "$REPO/scripts/verify-local-pv.bash" --check-epics) || die 'EPICS preparation failed. No installation changes have been made. Source your EPICS environment setup file in this terminal, then rerun the installer.'
            verify_pv=1
            printf 'EPICS prerequisites ready: %s\n' "$pv_epics_bin" ;;
        *) printf '%s\n' 'Optional PV verification skipped. PV acquisition, storage and retrieval remain NOT CHECKED.' ;;
    esac
}

function offer_pv_verification {
    local retrieval_url local_mgmt
    if (( ! verify_pv )); then
        printf '%s\n' 'Optional PV verification was not selected before installation; PV acquisition, storage and retrieval remain NOT CHECKED.'
        return
    fi
    local_mgmt="http://localhost:$(make_value ARCHAPPL_MGMT_PORT)/mgmt/bpl"
    retrieval_url="http://localhost:$(make_value ARCHAPPL_RETRIEVAL_PORT)/retrieval"
    if ! bash "$REPO/scripts/verify-local-pv.bash" --epics-bin "$pv_epics_bin" "$local_mgmt" "$retrieval_url" "$source_path" 9>&-; then
        printf '%s\n' 'Installation remains completed. Optional PV verification FAILED; inspect its retained evidence.' >&2
    fi
}

function prepare_database {
    local root_port
    if [[ "$backend" == sqlite ]]; then
        # Render the schema as the checkout owner; the root step only loads it.
        run_make sql.update
        root_make sql.table.fill
        root_make sql.show
        return
    fi
    run sudo -- systemctl start mariadb.service
    if [[ "$transport" == uds ]] && (( ! plan )); then
        [[ -S "$db_socket" ]] || die "MariaDB socket is unavailable: $db_socket"
    fi
    if (( setup_db )); then
        if [[ "$transport" == tcp ]]; then
            if (( plan )); then
                printf 'Require the local root socket server port to match TCP port %s before preparing accounts.\n' "$db_port"
            else
                root_port=$(sudo -- mysql --host=localhost --protocol=socket --user=root --batch --skip-column-names --execute='SELECT @@port')
                [[ "$root_port" =~ ^[0-9]+$ ]] || die 'Cannot identify the local MariaDB server port'
                (( 10#$root_port == 10#$db_port )) || die 'Local root socket and configured TCP port identify different servers'
            fi
            run env DB_BACKEND=mariadb bash -p "$REPO/scripts/mariadb_setup.bash" hostnameAdminAdd
        else
            run_make db.addAdmin
        fi
        run_make db.create
    fi
    run_make sql.fill
    run_make sql.show
    root_make src_preinst
    if [[ "$transport" == uds ]]; then
        run sudo -n -u "$service_user" -- test -S "$db_socket"
        run sudo -n -u "$service_user" -- test -w "$db_socket"
    fi
}

# Takes the installer lock of this checkout, or stops when another installer or inspection holds it.
function take_lock {
    mkdir -p -- "$REPO/work"
    [[ ! -L "$REPO/work/.local-install.lock" ]] || die 'Installer lock must not be a symlink'
    exec 9>> "$REPO/work/.local-install.lock"
    flock --exclusive --nonblock 9 || die 'Another appliance installer is running in this checkout'
}

# Updates the source clone to the configured pin and checks that it is clean; the checkout is the only thing it changes.
function select_source {
    local actual expected
    stage='source selection'
    if (( ! plan )); then restore_prepared_ui; fi
    run_make init
    run git -C "$source_path" fetch origin
    run_make srcupdate
    if (( ! plan )); then
        actual=$(git -C "$source_path" rev-parse HEAD)
        expected=$(git -C "$source_path" rev-parse "$source_pin^{commit}")
        [[ "$actual" == "$expected" ]] || die 'Source HEAD does not match the configured pin'
        require_interface_sources
        check_source
    fi
}

# Compares the installed appliance with the state that the checkout renders, through the inspection helper, and prints
# one line per layer. The helper changes nothing on the system; it returns 1 when a layer refuses.
function inspect_installation {
    local component sql_file status=0 line output
    local -a arguments=()
    if [[ "$backend" == sqlite ]]; then sql_file=$(make_value SQL_AA_ORIG_SQLITE); else sql_file=$(make_value SQL_AA_ORIG_SQL); fi
    [[ "$sql_file" == /* ]] || sql_file="$REPO/$sql_file"
    sql_file="${sql_file#"$source_path"/}"
    [[ "$sql_file" != /* ]] || die 'The schema file is not below the source clone'
    arguments=(--install-dir "$install_path" --systemd-dir "$(make_value SYSTEMD_PATH)"
        --rendered-dir "$(make_value AA_SITE_TEMPLATE_PATH)" --scripts-dir "$REPO/scripts" --source-dir "$source_path"
        --war-dir "$(make_value ARCHAPPL_WARS_TARGET_PATH)" --sql-file "$sql_file" --service-user "$service_user"
        --service-unit "$service_unit" --health-timer "$health_timer" --mgmt-url "$mgmt_url"
        --storage-dir "$(make_value ARCHAPPL_STORAGE_TOP)" --storage-dir "$(make_value ARCHAPPL_SHORT_TERM_FOLDER)"
        --storage-dir "$(make_value ARCHAPPL_MEDIUM_TERM_FOLDER)" --storage-dir "$(make_value ARCHAPPL_LONG_TERM_FOLDER)")
    for component in "${COMPONENTS[@]}"; do
        arguments+=(--port "$component=$(make_value "ARCHAPPL_${component^^}_PORT")"
            --shutdown-port "$component=$(make_value "ARCHAPPL_SHUTDOWN_${component^^}_PORT")")
    done
    if (( accept_schema )); then arguments+=(--accept-schema); fi
    output=$(bash "$REPO/scripts/inspect-local-install.bash" "${arguments[@]}") || status=$?
    (( status <= 1 )) || die "The inspection stopped with status $status"
    while IFS= read -r line; do
        if [[ "$line" == '#'* ]]; then
            printf '%s\n' "$line"
        else
            printf '%s\n' "$line" | awk -F'\t' '{ printf "%-14s %-10s %s\n", $1, $2, $3 }'
        fi
    done <<< "$output"
    parse_inspection "$output"
    return "$status"
}

# Reads the lines of the inspection helper into the state of each layer, the installation and the build.
function parse_inspection {
    local name state reason
    while IFS=$'\t' read -r name state reason; do
        case "$name" in
            installation) installation_state="$state" ;;
            build) build_state="$state" ;;
            program|configuration|systemd|schema|storage|runtime)
                layer_state["$name"]="$state"
                layer_reason["$name"]="$reason" ;;
        esac
    done <<< "$1"
}

# Prints the reason of every layer that the inspection refused.
function report_refusals {
    local layer
    for layer in program configuration systemd schema storage; do
        if [[ "${layer_state[$layer]:-}" == refuse ]]; then
            printf 'REFUSED %s: %s\n' "$layer" "${layer_reason[$layer]:-}" >&2
        fi
    done
}

# Renders the files that the installation reads from the checkout, as the checkout owner; the root install writes
# nothing into the checkout.
function render_configuration {
    stage='configuration'
    run_make db.conf
    run_make conf.archapplproperties
    run_make conf.install
}

# Updates the checkout, renders the configuration and prints the comparison; nothing on the system is changed.
function inspect_checkout {
    local status=0
    require_command flock
    take_lock
    trap report_exit EXIT
    stage='prerequisites'
    run_make "$os.conf"
    read_settings
    check_source
    select_source
    render_configuration
    stage='inspection'
    inspect_installation || status=$?
    if (( status )); then report_refusals; fi
    return "$status"
}

# Decides from the inspection which steps run: the installation of the appliance files for a changed program,
# configuration or systemd layer (or a replaced Tomcat), the schema load, the storage folders, and the build when the
# installation needs WARs that are missing. A first installation runs every step.
function decide_layers {
    local layer
    local -a names=()
    do_install=0
    do_build=0
    do_schema=0
    do_storage=0
    for layer in program configuration systemd schema storage; do
        if [[ "${layer_state[$layer]:-}" == changed ]]; then names+=("$layer"); fi
    done
    if [[ "$installation_state" == first ]]; then
        do_install=1
        do_schema=1
        do_storage=1
        names=('first installation')
    else
        for layer in program configuration systemd; do
            if [[ "${layer_state[$layer]:-}" == changed ]]; then do_install=1; fi
        done
        if [[ "${layer_state[schema]:-}" == changed ]]; then do_schema=1; fi
        if [[ "${layer_state[storage]:-}" == changed ]]; then do_storage=1; fi
        if [[ "$tomcat_action" == replace ]]; then
            do_install=1
            names+=('Tomcat replacement')
        fi
    fi
    if (( do_install )) && [[ "$build_state" == needed ]]; then do_build=1; fi
    changed_layers=''
    for layer in "${names[@]}"; do changed_layers+="${changed_layers:+, }$layer"; done
}

# Asks the confirmation of the changes, naming the layers.
function confirm_changes {
    local answer note=''
    [[ -t 0 || "$yes" == 1 ]] || die 'Non-interactive stdin; use --yes'
    if (( do_build )); then note=', build first'; fi
    if (( yes )); then return 0; fi
    if [[ "$backend" == mariadb ]] && (( setup_db && do_schema )); then
        printf '%s\n' 'Existing MariaDB admin and application accounts receive configured passwords and grants.'
        printf '%s\n' 'Use --existing-db to skip database/account provisioning and keep those accounts.'
    fi
    if [[ "$installation_state" == first ]]; then
        printf '%s' 'Install packages, build, prepare the database, replace the appliance and start it? [y/N] '
    else
        printf 'Apply the changes (%s)%s and start the appliance? [y/N] ' "$changed_layers" "$note"
    fi
    read -r answer || die 'No answer; installation cancelled'
    [[ "$answer" == y || "$answer" == Y || "$answer" == yes ]] || die 'Installation cancelled'
}

# Checks the host tools, the systemd host and the JDK that the changes need.
function check_host {
    local tool java_home java_version
    for tool in curl jq unzip sha512sum systemctl timeout; do require_command "$tool"; done
    if [[ "$backend" == sqlite ]]; then
        for tool in sqlite3 lsof runuser; do require_command "$tool"; done
    else require_command mysql; fi
    [[ -d /run/systemd/system ]] || die 'A running systemd host is required'
    java_home=$(make_value JAVA_HOME)
    [[ -x "$java_home/bin/javac" ]] || die 'Configured JAVA_HOME does not contain a JDK'
    java_version=$("$java_home/bin/java" -version 2>&1)
    [[ "$java_version" == *'version "21.'* || "$java_version" == *'version "21"'* ]] || die 'JDK 21 is required'
    check_source
}

# Runs the steps that the inspection selected, then starts the appliance and waits for its readiness.
function apply_changes {
    require_command sudo
    sudo -v
    stage='prerequisites'
    if (( ! skip_packages )); then install_packages; fi
    run_make "$os.conf"
    read_settings
    check_host
    if (( do_install )); then
        stage='Tomcat preparation'
        prepare_tomcat
    fi
    if (( do_build )); then
        stage='build'
        run_make build.mvn
    fi
    stage='appliance stop'
    stop_appliance
    stage='database and installation'
    root_make sd_health_stop
    if (( do_schema )); then prepare_database; fi
    if (( do_storage )); then root_make conf.storage; fi
    if (( do_install )); then root_make install; fi
    stage='startup verification'
    run_make sd_start
    wait_ready
    installation_completed=1
    show_ready
    offer_pv_verification
}

# A normal run: lock the checkout, update and render it, inspect the installed appliance, and run only what differs.
function run_installation {
    local status=0
    require_command flock
    take_lock
    trap report_exit EXIT
    stage='prerequisites'
    run_make "$os.conf"
    read_settings
    check_source
    select_source
    render_configuration
    stage='inspection'
    inspect_installation || status=$?
    if (( status )); then
        report_refusals
        die 'The inspection found a layer that refuses; nothing was changed on the system'
    fi
    decide_layers
    if (( ! do_install && ! do_schema && ! do_storage )); then
        printf '%s\n' 'The installation is up to date: no layer differs from the checkout.'
        return 0
    fi
    printf 'Changes to apply: %s\n' "$changed_layers"
    stage='confirmation'
    confirm_changes
    apply_changes
}

# The straight-line sequence that --plan prints: every command in order, nothing executed.
function plan_sequence {
    trap report_exit EXIT
    stage='prerequisites'
    if (( ! skip_packages )); then install_packages; fi
    run_make "$os.conf"
    read_settings
    select_source
    stage='Tomcat preparation'
    prepare_tomcat
    stage='configuration and build'
    run_make db.conf
    run_make conf.archapplproperties
    run_make build.mvn
    run_make conf.install
    stage='appliance stop'
    stop_appliance
    stage='database and installation'
    root_make sd_health_stop
    prepare_database
    root_make conf.storage
    root_make install
    stage='startup verification'
    run_make sd_start
    wait_ready
}

function report_exit {
    local status=$?
    if (( status != 0 )); then
        if (( inspect )); then
            printf 'Inspection stopped during %s (exit %s). Nothing on the system was changed.\n' "$stage" "$status" >&2
            return
        fi
        if (( installation_completed )); then
            printf 'Installation completed. Post-install verification stopped (exit %s); inspect its retained evidence.\n' "$status" >&2
            return
        fi
        if [[ "$stage" == 'startup verification' ]]; then
            printf 'Appliance files are installed. Verification failed (exit %s); data and build files are retained.\n' "$status" >&2
            printf '%s\n' 'The installer does not roll back the installation, stop the appliance, or restart it after this failure.' >&2
            return
        fi
        printf 'Installation stopped during %s (exit %s). Data and build files are retained.\n' "$stage" "$status" >&2
        printf '%s\n' 'No rollback or automatic restart is attempted.' >&2
    fi
}

function main {
    local tool
    case "${1:-}" in
        sqlite) backend=sqlite; transport=sqlite; entry_script='install-local-sqlite.bash' ;;
        mariadb-uds) backend=mariadb; transport=uds; setup_db=1; entry_script='install-local-mariadb-uds.bash' ;;
        mariadb-tcp) backend=mariadb; transport=tcp; setup_db=1; entry_script='install-local-mariadb-tcp.bash' ;;
        *) die 'Select sqlite, mariadb-uds or mariadb-tcp through its installation entry script' ;;
    esac
    shift
    parse_args "$@"
    (( EUID != 0 )) || die 'Run as the checkout owner, not with sudo bash'
    validate_site_configuration
    for tool in make git realpath bash; do require_command "$tool"; done
    detect_os
    select_backend
    read_settings
    check_source
    if (( ! inspect )); then prepare_pv_verification; fi
    printf 'Repository: %s\nOS: %s\nSource pin: %s\nInstall: %s\nBackend: %s\n' \
        "$REPO" "$os" "$source_pin" "$install_path" "$backend"
    if [[ "$backend" == sqlite ]]; then
        printf 'SQLite: %s\n' "$(make_value ARCHAPPL_SQLITE_FILE)"
    elif [[ "$transport" == uds ]]; then
        printf 'MariaDB socket: %s\nPrepare DB/accounts: %s\n' "$db_socket" "$setup_db"
    else
        printf 'MariaDB TCP: %s:%s\nPrepare DB/accounts: %s\n' "$db_host" "$db_port" "$setup_db"
    fi
    if (( inspect )); then
        inspect_checkout
        return
    fi
    if (( plan )); then
        plan_sequence
        return
    fi
    run_installation
}

# Parse the entry call and exit together before a long-running operation can change this file.
main "$@"; exit "$?"
