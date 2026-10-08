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
declare -a component_urls=()

function die {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

function usage {
    printf '%s\n' \
        "Usage: bash scripts/$entry_script [OPTIONS]" \
        '' \
        'Install a systemd-managed appliance on Debian 13 or Rocky 8.' \
        'Run as the ordinary checkout owner; sudo is used for privileged steps.' \
        'The selected source pin and site configuration come from Make settings.' \
        'Existing appliance payloads are replaced; database contents and stores remain.' \
        '' \
        '  --plan             Print the steps without installing or starting anything' \
        '  -y, --yes          Run without the installation confirmation' \
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
        'TCP account preparation needs local root socket authentication; --existing-db skips it.' \
        'The OS preset rewrites configure/CONFIG_SITE.local as documented.' \
        'No VM, tag, release or automatic rollback is performed.'
}

function parse_args {
    while (( $# )); do
        case "$1" in
            --plan) plan=1; shift ;;
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
        *) die "Unsupported host: $id $version; use Debian 13 or Rocky 8" ;;
    esac
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
                debian13) db_socket='/run/mysqld/mysqld.sock' ;;
                rocky8) db_socket='/var/lib/mysql/mysql.sock' ;;
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

# Requires clean source inputs while permitting the generated site and ignored build output.
function check_source {
    local top pending
    [[ -e "$source_path" ]] || return 0
    top=$(git -C "$source_path" rev-parse --show-toplevel) || die 'Existing source path is not a Git checkout'
    [[ "$top" == "$(realpath -- "$source_path")" ]] || die 'Source path must be the root of its Git checkout'
    git -C "$source_path" diff --quiet --ignore-submodules=none || die 'Source checkout contains tracked changes'
    git -C "$source_path" diff --cached --quiet --ignore-submodules=none || die 'Source checkout contains staged changes'
    pending=$(git -C "$source_path" ls-files --others --exclude-standard -- . ':(exclude)src/sitespecific/als') || die 'Cannot inspect untracked source files'
    [[ -z "$pending" ]] || die "Source checkout contains untracked files: $pending"
    pending=$(git -C "$source_path" ls-files --others --ignored --exclude-standard -- src .mvn ':(exclude)src/sitespecific/als') || die 'Cannot inspect ignored source inputs'
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
                mariadb-*|libmariadb-*) continue ;;
            esac
        fi
        [[ -n "$package" ]] && packages+=("$package")
    done <<< "$list"
    (( ${#packages[@]} )) || die 'Empty prerequisite package list'
    case "$os" in
        debian13)
            run sudo -- apt-get update
            run sudo -- apt-get install -y "${packages[@]}" ;;
        rocky8) run sudo -- dnf install -y "${packages[@]}" ;;
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

function wait_ready {
    local deadline=$((SECONDS + timeout)) response ready url
    if (( plan )); then
        printf 'Wait up to %s seconds for process health, four startup states and %s\n' "$timeout" "$mgmt_url"
        return
    fi
    while (( SECONDS < deadline )); do
        ready=1
        run_before_deadline "$deadline" sudo -n -u "$service_user" -- "$install_path/archappl.bash" health || ready=0
        for url in "${component_urls[@]}"; do
            (( SECONDS < deadline )) || break
            response=$(run_before_deadline "$deadline" curl -q --noproxy '*' --fail --silent --max-time 2 "$url") || response=''
            [[ "$response" == *'"STARTUP_COMPLETE"'* ]] || ready=0
        done
        (( SECONDS < deadline )) || break
        if (( ready )) && run_before_deadline "$deadline" curl -q --noproxy '*' --fail --silent --show-error --max-time 2 "$mgmt_url"; then
            printf '\n'
            if run_before_deadline "$deadline" sudo -n systemctl is-active --quiet "$service_unit" &&
                run_before_deadline "$deadline" sudo -n systemctl is-active --quiet "$health_timer"; then
                return
            fi
        fi
        run_before_deadline "$deadline" sleep 2 || true
    done
    die "Startup did not become ready within $timeout seconds; inspect journalctl -u $service_unit"
}

function prepare_database {
    local root_port
    if [[ "$backend" == sqlite ]]; then
        root_make sql.fill
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
                root_port=$(sudo -- mysql --protocol=socket --user=root --batch --skip-column-names --execute='SELECT @@port')
                [[ "$root_port" =~ ^[0-9]+$ ]] || die 'Cannot identify the local MariaDB server port'
                (( 10#$root_port == 10#$db_port )) || die 'Local root socket and configured TCP port identify different servers'
            fi
            run env DB_BACKEND=mariadb bash "$REPO/scripts/mariadb_setup.bash" hostnameAdminAdd
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

function report_exit {
    local status=$?
    if (( status != 0 )); then
        printf 'Installation stopped during %s (exit %s). Data and build files are retained.\n' "$stage" "$status" >&2
        printf '%s\n' 'No rollback or automatic restart is attempted.' >&2
    fi
}

function main {
    local answer tool actual expected java_home java_version
    case "${1:-}" in
        sqlite) backend=sqlite; transport=sqlite; entry_script='install-local-sqlite.bash' ;;
        mariadb-uds) backend=mariadb; transport=uds; setup_db=1; entry_script='install-local-mariadb-uds.bash' ;;
        mariadb-tcp) backend=mariadb; transport=tcp; setup_db=1; entry_script='install-local-mariadb-tcp.bash' ;;
        *) die 'Select sqlite, mariadb-uds or mariadb-tcp through its installation entry script' ;;
    esac
    shift
    parse_args "$@"
    (( EUID != 0 )) || die 'Run as the checkout owner, not with sudo bash'
    for tool in make git realpath bash; do require_command "$tool"; done
    detect_os
    select_backend
    read_settings
    check_source
    printf 'Repository: %s\nOS: %s\nSource pin: %s\nInstall: %s\nBackend: %s\n' \
        "$REPO" "$os" "$source_pin" "$install_path" "$backend"
    if [[ "$backend" == sqlite ]]; then
        printf 'SQLite: %s\n' "$(make_value ARCHAPPL_SQLITE_FILE)"
    elif [[ "$transport" == uds ]]; then
        printf 'MariaDB socket: %s\nPrepare DB/accounts: %s\n' "$db_socket" "$setup_db"
    else
        printf 'MariaDB TCP: %s:%s\nPrepare DB/accounts: %s\n' "$db_host" "$db_port" "$setup_db"
    fi
    if (( ! plan )); then
        require_command sudo
        require_command flock
        [[ -t 0 || "$yes" == 1 ]] || die 'Non-interactive stdin; use --yes'
        if (( ! yes )); then
            if [[ "$backend" == mariadb ]] && (( setup_db )); then
                printf '%s\n' 'Existing MariaDB admin and application accounts receive configured passwords and grants.'
                printf '%s\n' 'Use --existing-db to skip database/account provisioning and keep those accounts.'
            fi
            printf '%s' 'Install packages, build, prepare the database, replace the appliance and start it? [y/N] '
            read -r answer || die 'No answer; installation cancelled'
            [[ "$answer" == y || "$answer" == Y || "$answer" == yes ]] || die 'Installation cancelled'
        fi
        sudo -v
        mkdir -p -- "$REPO/work"
        [[ ! -L "$REPO/work/.local-install.lock" ]] || die 'Installer lock must not be a symlink'
        exec 9>> "$REPO/work/.local-install.lock"
        flock --exclusive --nonblock 9 || die 'Another appliance installer is running in this checkout'
    fi
    trap report_exit EXIT
    stage='prerequisites'
    if (( ! skip_packages )); then install_packages; fi
    run_make "$os.conf"
    read_settings
    if (( ! plan )); then
        for tool in curl unzip sha512sum systemctl timeout; do require_command "$tool"; done
        if [[ "$backend" == sqlite ]]; then require_command sqlite3; else require_command mysql; fi
        [[ -d /run/systemd/system ]] || die 'A running systemd host is required'
        java_home=$(make_value JAVA_HOME)
        [[ -x "$java_home/bin/javac" ]] || die 'Configured JAVA_HOME does not contain a JDK'
        java_version=$("$java_home/bin/java" -version 2>&1)
        [[ "$java_version" == *'version "21.'* || "$java_version" == *'version "21"'* ]] || die 'JDK 21 is required'
        check_source
    fi
    stage='source selection'
    run_make init
    run git -C "$source_path" fetch origin
    run_make srcupdate
    if (( ! plan )); then
        actual=$(git -C "$source_path" rev-parse HEAD)
        expected=$(git -C "$source_path" rev-parse "$source_pin^{commit}")
        [[ "$actual" == "$expected" ]] || die 'Source HEAD does not match the configured pin'
        check_source
    fi
    stage='Tomcat preparation'
    prepare_tomcat
    stage='configuration and build'
    run_make db.conf
    run_make conf.archapplproperties
    run_make build.mvn
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
    if (( ! plan )); then
        printf 'Installation ready: %s\nPV acquisition and retrieval must be checked separately.\n' "$mgmt_url"
    fi
}

main "$@"
