# SQLite operations run clients as the appliance account under a per-file lock.
SQLITE_BUSY_MS=5000
SQLITE_OPERATION_SECONDS=30
SQLITE_TEMP_FILES=()
SQLITE_AS=()

function sqlite_cleanup {
    local path
    for path in "${SQLITE_TEMP_FILES[@]}"; do
        [[ -n $path ]] && rm -f -- "$path"
    done
}

function sqlite_client {
    "${SQLITE_AS[@]}" timeout --signal=TERM --kill-after=2 "$SQLITE_OPERATION_SECONDS" \
        sqlite3 -init /dev/null -batch -bail -cmd ".timeout $SQLITE_BUSY_MS" "$@"
}

function sqlite_dot_quote {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    printf '"%s"' "$value"
}

function sqlite_prepare_directory {
    local directory=${1:-/} writable=${2:-YES} parent
    [[ $directory == /* && $directory != *$'\n'* && $directory != *$'\r'* ]] || {
        database_error 'A directory must be an absolute path without line breaks'; return 2;
    }
    if [[ ! -e $directory ]]; then
        parent=${directory%/*}
        [[ -n $parent ]] || parent=/
        sqlite_prepare_directory "$parent" NO || return
        mkdir -m 0700 -- "$directory" || return
        chown "$AA_USERID:$AA_GROUPID" -- "$directory" || return
    fi
    [[ -d $directory ]] && "${SQLITE_AS[@]}" test -x "$directory" || {
        database_error "Directory is not accessible to the service account: $directory"; return 2;
    }
    if [[ $writable == YES ]]; then
        "${SQLITE_AS[@]}" test -w "$directory" || {
            database_error "Directory is not writable by the service account: $directory"; return 2;
        }
    fi
}

function sqlite_file_state {
    local file=$1 writable=${2:-NO} owner
    [[ ! -L $file ]] || { database_error "Symlink database refused: $file"; return 2; }
    [[ -e $file ]] || return 1
    [[ -f $file ]] || { database_error "Not a regular database file: $file"; return 2; }
    owner=$(stat -c '%u:%g' -- "$file") || return 2
    [[ $owner == "$SQLITE_UID:$SQLITE_GID" ]] || { database_error "Unexpected database owner: $file"; return 2; }
    "${SQLITE_AS[@]}" test -r "$file" || { database_error "Unreadable database: $file"; return 2; }
    if [[ $writable == YES ]]; then
        "${SQLITE_AS[@]}" test -w "$file" || { database_error "Database is not writable: $file"; return 2; }
    fi
}

function sqlite_valid {
    local result
    [[ -s $1 ]] || { database_error "Empty database: $1"; return 2; }
    result=$(sqlite_client -readonly "$1" 'PRAGMA quick_check;') || return 2
    [[ $result == ok ]] || { database_error "Invalid database: $1"; return 2; }
}

# lsof is invoked with full host privileges. An error is not an empty result.
function sqlite_no_open_files {
    local suffix path result errors rc=0
    local -a files=()
    for suffix in '' -wal -shm; do
        path=${ARCHAPPL_SQLITE_FILE}${suffix}
        if [[ -e $path || -L $path ]]; then files+=("$path"); fi
    done
    [[ ${#files[@]} -gt 0 ]] || return 0
    errors=$(mktemp) || return 2
    SQLITE_TEMP_FILES+=("$errors")
    result=$(lsof -t -- "${files[@]}" 2>"$errors") || rc=$?
    if [[ -n $result || -s $errors || $rc -gt 1 ]]; then
        database_error 'Open SQLite files or an incomplete open-file inspection'; return 2
    fi
}

function sqlite_initialize {
    local canonical directory existing filesystem lock_hash lock_path key
    local -a settings=()
    [[ $ARCHAPPL_SQLITE_FILE == /* && $ARCHAPPL_SQLITE_FILE != */ &&
       $ARCHAPPL_SQLITE_FILE != *$'\n'* && $ARCHAPPL_SQLITE_FILE != *$'\r'* ]] || {
        database_error 'SQLite requires an absolute database file path without line breaks'; return 2;
    }
    [[ ! -L $ARCHAPPL_SQLITE_FILE ]] || { database_error 'Symlink database refused'; return 2; }
    canonical=$(realpath -m -- "$ARCHAPPL_SQLITE_FILE") || return 2
    ARCHAPPL_SQLITE_FILE=$canonical
    if [[ $EUID != 0 ]]; then
        for key in "${DATABASE_KEYS[@]}"; do settings+=("$key=${!key}"); done
        exec sudo -n -- env "${settings[@]}" AA_DATABASE_SETTINGS_READY=1 bash -p "$SC_SCRIPT" "$@"
    fi
    for key in sqlite3 lsof flock timeout runuser; do
        [[ -x $(command -v "$key") ]] || { database_error "Required executable missing: $key"; return 2; }
    done
    SQLITE_UID=$(id -u "$AA_USERID") || return 2
    SQLITE_GID=$(getent group "$AA_GROUPID") || return 2
    SQLITE_GID=${SQLITE_GID#*:*:}; SQLITE_GID=${SQLITE_GID%%:*}
    SQLITE_AS=(runuser -u "$AA_USERID" -g "$AA_GROUPID" --)
    directory=${canonical%/*}; [[ -n $directory ]] || directory=/
    existing=$directory
    while [[ ! -e $existing ]]; do existing=${existing%/*}; [[ -n $existing ]] || existing=/; done
    filesystem=$(stat -f -c %T -- "$existing") || return 2
    case $filesystem in ext2/ext3|xfs|btrfs|tmpfs|overlayfs|zfs|f2fs) ;;
        *) database_error "SQLite requires a supported local filesystem: $filesystem"; return 2 ;;
    esac
    lock_path=/run/lock/epicsarchiverap-database
    if [[ ! -e $lock_path ]]; then mkdir -m 0700 -- "$lock_path" || return 2; fi
    [[ ! -L $lock_path && $(stat -c '%u:%a' -- "$lock_path") == 0:700 ]] || {
        database_error 'Unsafe database lock directory'; return 2;
    }
    lock_hash=$(printf '%s' "$canonical" | sha256sum) || return 2
    lock_path+=/${lock_hash%% *}.lock
    [[ ! -L $lock_path ]] || { database_error 'Unsafe database lock file'; return 2; }
    exec {SQLITE_LOCK_FD}>"$lock_path" || return 2
    flock -w 5 "$SQLITE_LOCK_FD" || { database_error 'Another database helper holds the lock'; return 2; }
    trap sqlite_cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
}

function sqlite_require_existing {
    sqlite_file_state "$ARCHAPPL_SQLITE_FILE" "${1:-NO}" || return $?
    sqlite_valid "$ARCHAPPL_SQLITE_FILE"
}

function sqlite_create {
    local rc=0
    sqlite_file_state "$ARCHAPPL_SQLITE_FILE" YES || rc=$?
    [[ $rc -le 1 ]] || return "$rc"
    if [[ $rc == 0 && -s $ARCHAPPL_SQLITE_FILE ]]; then
        sqlite_valid "$ARCHAPPL_SQLITE_FILE"; return $?
    fi
    [[ ! -e $ARCHAPPL_SQLITE_FILE-wal && ! -L $ARCHAPPL_SQLITE_FILE-wal &&
       ! -e $ARCHAPPL_SQLITE_FILE-shm && ! -L $ARCHAPPL_SQLITE_FILE-shm ]] || {
        database_error 'Orphan SQLite side files require recovery'; return 2;
    }
    sqlite_prepare_directory "${ARCHAPPL_SQLITE_FILE%/*}" || return
    sqlite_client "$ARCHAPPL_SQLITE_FILE" 'PRAGMA user_version=0;' || return
    sqlite_valid "$ARCHAPPL_SQLITE_FILE"
}

function sqlite_drop {
    local rc=0 result
    sqlite_file_state "$ARCHAPPL_SQLITE_FILE" YES || rc=$?
    [[ $rc -le 1 ]] || return "$rc"
    if [[ $rc == 0 ]]; then
        sqlite_valid "$ARCHAPPL_SQLITE_FILE" || return
        result=$(sqlite_client "$ARCHAPPL_SQLITE_FILE" 'PRAGMA wal_checkpoint(TRUNCATE); PRAGMA journal_mode=DELETE;') || return
        [[ $result == *$'\n'delete ]] || { database_error 'SQLite journal cleanup failed'; return 2; }
    fi
    [[ ! -e $ARCHAPPL_SQLITE_FILE-wal && ! -L $ARCHAPPL_SQLITE_FILE-wal &&
       ! -e $ARCHAPPL_SQLITE_FILE-shm && ! -L $ARCHAPPL_SQLITE_FILE-shm ]] || {
        database_error 'SQLite side files remain; database retained'; return 2;
    }
    if [[ $rc == 0 ]]; then rm -- "$ARCHAPPL_SQLITE_FILE"; fi
}

function sqlite_drop_tables {
    local temporary quoted
    sqlite_require_existing YES || return
    temporary=$("${SQLITE_AS[@]}" mktemp -- "${ARCHAPPL_SQLITE_FILE%/*}/.aa-table-drop.XXXXXXXX") || return
    SQLITE_TEMP_FILES+=("$temporary")
    quoted=$(sqlite_dot_quote "$temporary")
    sqlite_client "$ARCHAPPL_SQLITE_FILE" <<EOF
PRAGMA foreign_keys=OFF;
BEGIN IMMEDIATE;
.output $quoted
SELECT 'DROP TABLE IF EXISTS "' || replace(name, '"', '""') || '";' FROM sqlite_master WHERE type='table' AND name NOT GLOB 'sqlite_*' ORDER BY (upper(sql) LIKE 'CREATE VIRTUAL TABLE%') DESC, name;
.output stdout
.read $quoted
COMMIT;
EOF
}

function sqlite_backup_directory {
    SQLITE_BACKUP_DIRECTORY=${1:-${ARCHAPPL_SQLITE_FILE}.backups}
    [[ $SQLITE_BACKUP_DIRECTORY == /* && $SQLITE_BACKUP_DIRECTORY != *$'\n'* &&
       $SQLITE_BACKUP_DIRECTORY != *$'\r'* ]] || { database_error 'Backup directory must be absolute without line breaks'; return 2; }
    SQLITE_BACKUP_BASENAME=${ARCHAPPL_SQLITE_FILE##*/}
}

function sqlite_publish_backup {
    local temporary destination stamp result
    sqlite_require_existing YES || return
    sqlite_backup_directory "${1:-}" || return
    sqlite_prepare_directory "$SQLITE_BACKUP_DIRECTORY" || return
    stamp=$(date -u +%Y%m%dT%H%M%SZ)
    destination=$SQLITE_BACKUP_DIRECTORY/${SQLITE_BACKUP_BASENAME}_${stamp}.sqlite3
    temporary=$("${SQLITE_AS[@]}" mktemp -- "$SQLITE_BACKUP_DIRECTORY/.aa-backup.XXXXXXXX") || return
    SQLITE_TEMP_FILES+=("$temporary")
    sqlite_client "$ARCHAPPL_SQLITE_FILE" ".backup $(sqlite_dot_quote "$temporary")" || return
    result=$(sqlite_client "$temporary" 'PRAGMA journal_mode=DELETE; PRAGMA quick_check;') || return
    [[ $result == $'delete\nok' ]] || { database_error 'Backup validation failed'; return 2; }
    "${SQLITE_AS[@]}" ln -T -- "$temporary" "$destination" || return
    printf '%s\n' "$destination"
}

function sqlite_list_backups {
    local path name stamp
    sqlite_backup_directory "${1:-}" || return
    [[ -d $SQLITE_BACKUP_DIRECTORY ]] && "${SQLITE_AS[@]}" test -r "$SQLITE_BACKUP_DIRECTORY" &&
        "${SQLITE_AS[@]}" test -x "$SQLITE_BACKUP_DIRECTORY" || {
        database_error 'Backup directory is missing or unreadable'; return 2;
    }
    for path in "$SQLITE_BACKUP_DIRECTORY/${SQLITE_BACKUP_BASENAME}_"*.sqlite3; do
        [[ -f $path && ! -L $path ]] || continue
        name=${path##*/}; stamp=${name#"${SQLITE_BACKUP_BASENAME}_"}; stamp=${stamp%.sqlite3}
        if [[ $stamp =~ ^[0-9]{8}T[0-9]{6}Z$ ]]; then printf '%s\n' "$name"; fi
    done | LC_ALL=C sort
}

function sqlite_restore {
    local stamp=$1 source temporary result
    [[ $stamp =~ ^[0-9]{8}T[0-9]{6}Z$ ]] || { database_error 'Invalid SQLite backup stamp'; return 2; }
    sqlite_backup_directory "${2:-}" || return
    for source in "$ARCHAPPL_SQLITE_FILE" "$ARCHAPPL_SQLITE_FILE-wal" "$ARCHAPPL_SQLITE_FILE-shm"; do
        [[ ! -e $source && ! -L $source ]] || { database_error 'Restore requires an absent database and absent side files'; return 2; }
    done
    source=$SQLITE_BACKUP_DIRECTORY/${SQLITE_BACKUP_BASENAME}_${stamp}.sqlite3
    [[ -f $source && ! -L $source && ! -e $source-wal && ! -e $source-shm ]] || {
        database_error 'A self-contained regular backup file is required'; return 2;
    }
    sqlite_valid "$source" || return
    sqlite_prepare_directory "${ARCHAPPL_SQLITE_FILE%/*}" || return
    temporary=$("${SQLITE_AS[@]}" mktemp -- "${ARCHAPPL_SQLITE_FILE%/*}/.aa-restore.XXXXXXXX") || return
    SQLITE_TEMP_FILES+=("$temporary")
    sqlite_client -readonly "$source" ".backup $(sqlite_dot_quote "$temporary")" || return
    result=$(sqlite_client "$temporary" 'PRAGMA journal_mode=DELETE; PRAGMA quick_check;') || return
    [[ $result == $'delete\nok' ]] || { database_error 'Restored database validation failed'; return 2; }
    [[ ! -e $ARCHAPPL_SQLITE_FILE-wal && ! -L $ARCHAPPL_SQLITE_FILE-wal &&
       ! -e $ARCHAPPL_SQLITE_FILE-shm && ! -L $ARCHAPPL_SQLITE_FILE-shm ]] || return 2
    "${SQLITE_AS[@]}" ln -T -- "$temporary" "$ARCHAPPL_SQLITE_FILE"
}

function sqlite_dispatch {
    local action=$1 table table_literal column rows rc=0
    shift
    case $action in
        dbCreate) sqlite_create ;;
        dbDrop) sqlite_drop ;;
        isDb)
            sqlite_require_existing || rc=$?
            printf 'SQLite database %s: %s\n' "$ARCHAPPL_SQLITE_FILE" "$([[ $rc == 0 ]] && printf present || printf 'absent or invalid')" >&2
            return "$rc" ;;
        dbShow) sqlite_require_existing && printf '%s\n' "$ARCHAPPL_SQLITE_FILE" ;;
        tableShow) sqlite_require_existing && sqlite_client -readonly "$ARCHAPPL_SQLITE_FILE" .tables ;;
        tableDrop) sqlite_drop_tables ;;
        aaShow)
            sqlite_require_existing || return
            table=${1:-PVTypeInfo}
            table_literal=${table//\'/\'\'}
            column=$(sqlite_client -readonly "$ARCHAPPL_SQLITE_FILE" "SELECT char(34) || replace(name, char(34), char(34) || char(34)) || char(34) FROM pragma_table_info('$table_literal') WHERE cid=0;") || return
            [[ -n $column ]] || { printf '%s\n' 'Table does not exist' >&2; return 1; }
            table=${table//\"/\"\"}
            rows=$(sqlite_client -readonly "$ARCHAPPL_SQLITE_FILE" "SELECT $column FROM \"$table\";") || return
            database_number_rows "$rows" ;;
        query)
            sqlite_require_existing YES || return
            sqlite_client "$ARCHAPPL_SQLITE_FILE" "${1:-SELECT name FROM sqlite_master WHERE type='table' AND name NOT GLOB 'sqlite_*';}" ;;
        queryFile|querySFile)
            [[ -f $1 && -r $1 ]] || { database_error 'SQL file is missing or unreadable'; return 2; }
            sqlite_create || return
            [[ ${3:-NO} != YES ]] || printf 'Query SQLite database %s from %s\n' "$ARCHAPPL_SQLITE_FILE" "$1"
            sqlite_client "$ARCHAPPL_SQLITE_FILE" < "$1" ;;
        dbBackup) sqlite_publish_backup "${1:-}" ;;
        dbBackupList) sqlite_list_backups "${1:-}" ;;
        dbRestore) sqlite_restore "$1" "${2:-}" ;;
    esac
}
