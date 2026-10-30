#!/bin/bash -p
# Select the configured database backend for administration and maintenance.
set -eo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
umask 077
unset BASH_ENV ENV MYSQL_HOME MYSQL_GROUP_SUFFIX MYSQL_TEST_LOGIN_FILE
if [[ $EUID == 0 && $- != *p* ]]; then
    printf '%s\n' 'Invoke this helper directly or with bash -p.' >&2
    exit 2
fi
SC_SCRIPT=$(realpath -- "$0")
SC_TOP=${SC_SCRIPT%/*}
ENV_TOP=${SC_TOP%/*}
LOGDATE=$(date +%y%m%d%H%M)
# shellcheck source=scripts/database_common.bash
source "${SC_TOP}/database_common.bash"

function usage {
    printf '%s\n' 'Usage: mariadb_setup.bash ACTION [ARGUMENTS]' \
        'Actions: dbCreate dbDrop dbShow isDb tableShow tableDrop aaShow [table]' \
        '         query [sql], queryFile [file] [options] [verbose], querySFile (alias)' \
        '         dbBackup [directory], dbBackupList [directory], dbRestore stamp [directory]' \
        'MariaDB: secureSetup localAdminAdd hostnameAdminAdd localAdminRemove hostnameAdminRemove' \
        '         adminAdd adminRemove userDrop dbUserCreate dbUserDrop' \
        'Schema creation: use make sql.fill' >&2
    return 1
}

input=${1:-}
case $input in
    addProject|updateCDBAdminPassword|showAdminCryptPassword)
        database_error 'This legacy ComponentDB action is unsupported'; exit 2 ;;
    secureSetup|localAdminAdd|hostnameAdminAdd|localAdminRemove|hostnameAdminRemove|adminAdd|adminRemove|userDrop|dbUserCreate|dbUserDrop|dbCreate|dbDrop|dbShow|isDb|tableShow|tableDrop)
        [[ $# == 1 ]] || { database_error 'Unexpected action arguments'; exit 2; } ;;
    aaShow|query|dbBackup|dbBackupList)
        [[ $# -le 2 ]] || { database_error 'Unexpected action arguments'; exit 2; } ;;
    dbRestore)
        [[ $# -ge 2 && $# -le 3 && -n $2 && $2 != */* ]] || { database_error 'A backup stamp is required'; exit 2; } ;;
    queryFile|querySFile) ;;
    *) usage; exit 1 ;;
esac
if [[ ${DB_BACKEND+x} && $DB_BACKEND != mariadb && $DB_BACKEND != sqlite ]]; then
    database_error 'DB_BACKEND must be mariadb or sqlite'; exit 2
fi
database_settings || exit 2
database_normalize_settings
case $DB_BACKEND in
    sqlite)
        case $input in
            secureSetup|localAdminAdd|hostnameAdminAdd|localAdminRemove|hostnameAdminRemove|adminAdd|adminRemove|userDrop|dbUserCreate|dbUserDrop)
                database_error 'This account/server action is unsupported for SQLite'; exit 2 ;;
        esac ;;
    mariadb) ;;
    *) database_error 'DB_BACKEND must be mariadb or sqlite'; exit 2 ;;
esac
database_query_arguments "$@" || exit 2
case $input in
    dbCreate|dbUserCreate|dbDrop|dbUserDrop|tableDrop|query|queryFile|querySFile|dbBackup|dbRestore) offline=YES ;;
    *) offline=NO ;;
esac
if [[ $DB_BACKEND == sqlite ]]; then
    # shellcheck source=scripts/sqlite_database.bash
    source "${SC_TOP}/sqlite_database.bash"
    sqlite_initialize "$@"
    if [[ $offline == YES ]]; then database_offline; sqlite_no_open_files; fi
    sqlite_dispatch "$@"
    exit $?
fi
database_check_mariadb_config || exit 2
if [[ $offline == YES ]]; then database_offline; fi
# shellcheck source=scripts/mariadb_generic_function.bash
source "${SC_TOP}/mariadb_generic_function.bash"
DEFAULT_DB_BACKUP_PATH="${ENV_TOP}/${DB_NAME}_sql_backup"
verbose=NO

function backup_db
{
    local db_name="$1"; shift;
    local db_backup_path="$1"; shift;
    local dbDir;
    local db_exist;
    local backup_file;
    local backup_temp;

    db_exist=$(isDb "${db_name}" "" SQL_DBUSER_CMD) || return $?;

    if [[ $db_exist -ne "$EXIST" ]]; then
	    noDbMessage "${db_name}";
	    exit 1;
    else
	dbDir=$(isDir "${db_backup_path}")
	if [[ $dbDir -ne "$EXIST" ]]; then
	    mkdir -p "${db_backup_path}"
	fi
	backup_file="${db_backup_path}/${db_name}_${LOGDATE}.sql.gz"
        if [[ -e "$backup_file" || -L "$backup_file" ]]; then
            printf 'Backup already exists; refusing to overwrite: %s\n' "$backup_file" >&2
            return 1
        fi
        # A private temporary file holds the complete dump. A same-directory
        # hard link publishes it atomically without replacing a competing file.
        (
            set -o pipefail
            backup_temp=$(mktemp -- "${db_backup_path}/.${db_name}_${LOGDATE}.XXXXXXXX") || exit 1
            trap 'rm -f -- "$backup_temp"' EXIT
            trap 'exit 130' INT
            trap 'exit 143' TERM
            if ! "${SQL_BACKUP_CMD[@]}" -- "${db_name}" | gzip -9 > "$backup_temp"; then
                printf 'Database backup failed; no backup published: %s\n' "$backup_file" >&2
                exit 1
            fi
            if ! ln -T -- "$backup_temp" "$backup_file"; then
                printf 'Cannot publish backup without replacing an existing path: %s\n' "$backup_file" >&2
                exit 1
            fi
        )
    fi
}


function backup_db_list
{
    local db_backup_path="$1"; shift;
    local dbDir;

    dbDir=$(isDir "${db_backup_path}");
    if [[ $dbDir -ne "$EXIST" ]]; then
	printf "\nThere is no >> %s << directory, please check your enviornment.\n\n" "${db_backup_path}" >&2
	exit 1;
    fi

    ls --almost-all -m -o --author --human-readable --time-style=iso -v  "${db_backup_path}"
}



function restore_db
{
    local date="$1"; shift;
    local db_backup_path="$1"; shift;
    local dbDir;
    local dbDate;
    local cmd;

    dbDate=$(isVar "${date}")

    if [[ $dbDate -ne "$EXIST" ]]; then
	printf "\nDate is missing, please check the backup data file name.\n\n" >&2
	exit 1;
    fi

    dbDir=$(isDir "${db_backup_path}")

    if [[ $dbDir -ne "$EXIST" ]]; then
	printf "\nThere is no >> %s << directory, please check your enviornment.\n\n" "${db_backup_path}" >&2
	exit 1;
    fi

    db_backup_file="${DB_NAME}_${date}.sql.gz"
    if [[ ! -r "${db_backup_path}/${db_backup_file}" ]]; then
	printf "\nThere is no readable >> %s << backup file, please check the backup data file name.\n\n" "${db_backup_path}/${db_backup_file}" >&2
	exit 1;
    fi


    isDb "$DB_NAME" "" SQL_ADMIN_CMD >/dev/null || return $?
    gzip -t -- "${db_backup_path}/${db_backup_file}" || return 1

    # The restore fails when either gunzip or the client fails; the subshell
    # confines pipefail without requiring 'local -'.
    if ! ( set -o pipefail; gunzip < "${db_backup_path}/${db_backup_file}" | "${SQL_ADMIN_CMD[@]}" "--database=${DB_NAME}" ); then
	printf "\nRestoring >> %s << into >> %s << failed.\n\n" "${db_backup_file}" "${DB_NAME}" >&2
	exit 1;
    fi
}



function show_archappl {
    local table=${1:-PVTypeInfo} column rows
    isDb "$DB_NAME" '' SQL_DBUSER_CMD >/dev/null || return $?
    column=$("${SQL_DBUSER_CMD[@]}" "--database=$DB_NAME" -N -B -r --execute="SET SESSION sql_mode='NO_BACKSLASH_ESCAPES'; SELECT CONCAT(CHAR(96), REPLACE(COLUMN_NAME, CHAR(96), CONCAT(CHAR(96), CHAR(96))), CHAR(96)) FROM information_schema.columns WHERE TABLE_SCHEMA=$(sql_string "$DB_NAME") AND TABLE_NAME=$(sql_string "$table") ORDER BY ORDINAL_POSITION LIMIT 1;") || return
    [[ -n $column ]] || { printf '%s\n' 'Table does not exist' >&2; return 1; }
    rows=$("${SQL_DBUSER_CMD[@]}" "--database=$DB_NAME" -N -B -r --execute="SELECT $column FROM $(sql_identifier "$table");") || return
    database_number_rows "$rows"
}

case $input in
    secureSetup) mariadb_secure_setup ;;
    localAdminAdd|adminAdd) add_admin_account_local "$DB_ADMIN" "$DB_ADMIN_PASS" ;;
    hostnameAdminAdd) add_admin_account_hostname "$DB_ADMIN" "$DB_ADMIN_PASS" "$DB_HOST_NAME" ;;
    localAdminRemove|adminRemove) remove_admin_account_local "$DB_ADMIN" ;;
    hostnameAdminRemove) remove_admin_account_hostname "$DB_ADMIN" "$DB_HOST_NAME" ;;
    dbCreate) create_db "$DB_NAME" ;;
    dbUserCreate) create_db_and_user "$DB_NAME" "$DB_USER_HOST" "$DB_USER" "$DB_USER_PASS" ;;
    dbShow) show_dbs ;;
    dbDrop) drop_db "$DB_NAME" ;;
    dbUserDrop) drop_db_and_user "$DB_NAME" "$DB_USER_HOST" "$DB_USER" ;;
    userDrop) drop_user "$DB_USER_HOST" "$DB_USER" ;;
    isDb) isDb "$DB_NAME" YES ;;
    tableShow) show_tables "$DB_NAME" 'BASE TABLE' ;;
    tableDrop) drop_tables "$DB_NAME" 'BASE TABLE' ;;
    aaShow) show_archappl "${2:-PVTypeInfo}" ;;
    query) execute_query "$DB_NAME" "${2:-SHOW DATABASES;}" ;;
    queryFile|querySFile) query_from_sql_file "$DB_NAME" "${2:-${AA_SITE_TEMPLATE_PATH}/sql/default_query.sql}" "${3:-}" "${4:-NO}" ;;
    dbBackup) backup_db "$DB_NAME" "${2:-$DEFAULT_DB_BACKUP_PATH}" ;;
    dbBackupList) backup_db_list "${2:-$DEFAULT_DB_BACKUP_PATH}" ;;
    dbRestore) restore_db "$2" "${3:-$DEFAULT_DB_BACKUP_PATH}" ;;
esac
