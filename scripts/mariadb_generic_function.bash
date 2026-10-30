#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  version : 0.0.6


if ! declare -F database_query_arguments >/dev/null; then
    # shellcheck source=scripts/database_common.bash
    source "${BASH_SOURCE[0]%/*}/database_common.bash"
fi

DB_PROTOCOL="tcp";

# Application, administrator and backup clients use DB_SOCKET when set, otherwise
# TCP. Root account operations use a local socket for either appliance transport.
# MariaDB names a socket client's host localhost; grants follow DB_USER_HOST.
if [ -n "${DB_SOCKET:-}" ]; then
    DB_CONNECT_OPTS=(--protocol=socket "--socket=${DB_SOCKET}")
    SQL_ROOT_CMD=(sudo mysql --user=root --host=localhost --protocol=socket "--socket=${DB_SOCKET}")
    DB_USER_HOST="localhost"
else
    # shellcheck disable=SC2153
    DB_CONNECT_OPTS=("--port=${DB_HOST_PORT}" "--host=${DB_HOST_NAME}" "--protocol=${DB_PROTOCOL}")
    SQL_ROOT_CMD=(sudo mysql --user=root --host=localhost --protocol=socket)
    # shellcheck disable=SC2034
    DB_USER_HOST="${DB_HOST_NAME}"
fi
# shellcheck disable=SC2153
SQL_ADMIN_CMD=(mysql --no-defaults "--user=${DB_ADMIN}" "--password=${DB_ADMIN_PASS}" "${DB_CONNECT_OPTS[@]}")
# shellcheck disable=SC2153
SQL_DBUSER_CMD=(mysql --no-defaults "--user=${DB_USER}" "--password=${DB_USER_PASS}" "${DB_CONNECT_OPTS[@]}")
# shellcheck disable=SC2034
SQL_BACKUP_CMD=(mysqldump --no-defaults "--user=${DB_USER}" "--password=${DB_USER_PASS}" "${DB_CONNECT_OPTS[@]}")

function sql_string
{
    local value="$1"
    value=${value//\'/\'\'}
    printf "'%s'" "$value"
}

function sql_identifier
{
    local value="$1"
    value=${value//\`/\`\`}
    printf '`%s`' "$value"
}

EXIST=1
NON_EXIST=0

VERBOSE=YES

function isDir
{
    local dir=$1; shift;
    local result;
    result="";
    if [ ! -d "$dir" ]; then result=$NON_EXIST
    else                     result=$EXIST
    fi
    echo "${result}"
}

function isVar() {

    local var=$1; shift;
    local result;
    result=""
    if [ -z "$var" ]; then result=$NON_EXIST
    else                   result=$EXIST
    fi
    echo "${result}"
}

# Reports on stderr that an account or database step failed in the client;
# callers return non-zero after it.
function clientFailMessage
{
    printf ">> %s failed, the database client returned an error.\\n" "$1" >&2
}

function noDbMessage
{
    local db_name="$1"; shift;
    if [ "${VERBOSE}" == "YES" ]; then
        printf ">> There is no >> %s << in the dababase, please check your SQL enviornment.\\n" "${db_name}" >&2
    fi
}

function die #@ Print error message and exit with error code
{
    #@ USAGE: die [errno [message]]
    error=${1:-1}
    ## exits with 1 if error number not given
    shift
    [ -n "$*" ] &&
	printf "%s%s: %s\n" "$SC_SCRIPTNAME" ${SC_VERSION:+" ($SC_VERSION)"} "$*" >&2
    exit "$error"
};


# No arguments: root@'localhost' is kept and every other root plus anonymous
# users are dropped, independent of the configured DB host.
function mariadb_secure_setup
{
    # Keeps root@'localhost' with its existing authentication method and removes
    # other root accounts, anonymous users, and the test database. DROP USER
    # supports both the mysql.user table and its MariaDB 10.4+ view. Root
    # passwords, authentication plugins, and TCP access are host settings;
    # this operation does not change them or guarantee socket-only root access.

    # remove_anonymous_users(), remove_remote_root(): read mysql.user (readable
    # on every version) to build DROP USER statements, then execute them.
    # remove_test_database(), reload_privilege_tables().
    local rc=0
    local -                 # confine 'set' options to this function
    set -o pipefail
    printf ">> MariaDB Secure Installation\\n";
    # shellcheck disable=SC2154
    if ! "${SQL_ROOT_CMD[@]}" -N -B <<'GENSQL' | "${SQL_ROOT_CMD[@]}"
SET SESSION sql_mode='';
SELECT CONCAT('DROP USER IF EXISTS ', QUOTE(User), '@', QUOTE(Host), ';')
  FROM mysql.user
  WHERE User = '' OR (User = 'root' AND Host <> 'localhost');
GENSQL
    then rc=1; fi
    # shellcheck disable=SC2154
    if ! "${SQL_ROOT_CMD[@]}" <<EOF
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR HEX(Db) IN ('746573745C5F25', '746573745F25');
    FLUSH PRIVILEGES;
EOF
    then rc=1; fi
    printf "\\n"
    return "$rc"
}


# 1 : MariaDB Admin name      :
# 2 : MariaDB Admin password  :
function add_admin_account_local
{
    local db_admin_name="$1"; shift;
    local db_admin_pass="$1"; shift;
    # add admin user with the password via the environment variable $CDB_ADMIN_PWD
    #
    #
    printf ">> Add %s user with GRANT ALL in the MariaDB \\n" "${db_admin_name}"
    if ! "${SQL_ROOT_CMD[@]}" <<EOF
    SET SESSION sql_mode='NO_BACKSLASH_ESCAPES';
    GRANT ALL ON *.* TO $(sql_string "$db_admin_name")@'localhost' IDENTIFIED BY $(sql_string "$db_admin_pass") WITH GRANT OPTION;
    FLUSH PRIVILEGES;
EOF
    then
        clientFailMessage "Adding the ${db_admin_name}@localhost account"
        return 1
    fi
    printf "\\n"
}


# 1 : MariaDB Admin name      :
# 2 : MariaDB Admin password  :
# 3 : Hostname
function add_admin_account_hostname
{
    local db_admin_name="$1"; shift;
    local db_admin_pass="$1"; shift;
    local db_hostname="$1"; shift;
    # add admin user with the password via the environment variable $CDB_ADMIN_PWD
    #
    #
    printf ">> Add %s user with GRANT ALL in the MariaDB \\n" "${db_admin_name}"
    if ! "${SQL_ROOT_CMD[@]}" <<EOF
    SET SESSION sql_mode='NO_BACKSLASH_ESCAPES';
    GRANT ALL ON *.* TO $(sql_string "$db_admin_name")@$(sql_string "$db_hostname") IDENTIFIED BY $(sql_string "$db_admin_pass") WITH GRANT OPTION;
    FLUSH PRIVILEGES;
EOF
    then
        clientFailMessage "Adding the ${db_admin_name}@${db_hostname} account"
        return 1
    fi
    printf "\\n"
}


# 1 : MariaDB admin name
# 2 : Hostname
function remove_admin_account_hostname
{
    local db_admin_name="$1"; shift;
    local db_hostname="$1"; shift;
    if ! "${SQL_ROOT_CMD[@]}" <<EOF
    SET SESSION sql_mode='NO_BACKSLASH_ESCAPES';
    DROP USER IF EXISTS $(sql_string "$db_admin_name")@$(sql_string "$db_hostname");
    FLUSH PRIVILEGES;
EOF
    then
        clientFailMessage "Removing the ${db_admin_name}@${db_hostname} account"
        return 1
    fi
    printf "\\n"
}


function remove_admin_account_local
{
    local db_admin_name="$1"
    printf ">> Remove local %s user \\n" "$db_admin_name"
    if ! "${SQL_ROOT_CMD[@]}" <<EOF
    SET SESSION sql_mode='NO_BACKSLASH_ESCAPES';
    DROP USER IF EXISTS $(sql_string "$db_admin_name")@'localhost';
    FLUSH PRIVILEGES;
EOF
    then
        clientFailMessage "Removing the ${db_admin_name}@localhost account"
        return 1
    fi
    printf "\\n"
}


# 1 : sql file (with path) for database creation
# 2 : additional options (useful to use -N )
function admin_query_from_sql_file
{
    local sql_file="$1"
    local -a options=()
    read -r -a options <<< "${2:-}"
    "${SQL_ADMIN_CMD[@]}" "${options[@]}" < "$sql_file"
}

function create_db_and_user 
{
    local db_name="$1"; shift;
    local db_hosts="$1"; shift;
    local db_user_name="$1"; shift;
    local db_user_pass="$1";shift;

    local aHost
    local temp_sql_file="";
    temp_sql_file=$(mktemp -q) || die 1 "CANNOT create the $temp_sql_file file, please check the disk space";
    printf "%s\n" "SET SESSION sql_mode='NO_BACKSLASH_ESCAPES';" "CREATE DATABASE IF NOT EXISTS $(sql_identifier "$db_name") CHARACTER SET utf8mb4;" > "$temp_sql_file";
    for aHost in $db_hosts;  do
        printf '%s\n' "GRANT ALL PRIVILEGES ON $(sql_identifier "$db_name").* TO $(sql_string "$db_user_name")@$(sql_string "$aHost") IDENTIFIED BY $(sql_string "$db_user_pass");" >> "$temp_sql_file";
    done
    echo "FLUSH PRIVILEGES;" >> "${temp_sql_file}"; 
#    echo "${temp_sql_file}"
    if ! admin_query_from_sql_file "${temp_sql_file}"; then
        rm -f "${temp_sql_file}"
        clientFailMessage "Creating the database ${db_name} and the ${db_user_name} account"
        return 1
    fi
    rm -f "${temp_sql_file}"
    
    temp_sql_file=$(mktemp -q) || die 1 "CANNOT create the $temp_sql_file file, please check the disk space";
    echo "SHOW databases;" >  "$temp_sql_file";
    echo "SELECT user, host, Grant_priv, Show_db_priv FROM mysql.user;" >>  "$temp_sql_file";
    if ! admin_query_from_sql_file "${temp_sql_file}"; then
        rm -f "${temp_sql_file}"
        clientFailMessage 'Listing databases and accounts'
        return 1
    fi
    rm -f "${temp_sql_file}"
}

function drop_db_and_user
{
    local db_name="$1"; shift;
    local db_hosts="$1"; shift;
    local db_user_name="$1"; shift;

    printf ">> Drop the Database -%s- \\n" "${db_name}";
    printf ">> Drop the user -%s- at -%s- \\n" "${db_user_name}" "${db_hosts[@]}"
    
    local aHost
    local temp_sql_file="";
    temp_sql_file=$(mktemp -q) || die 1 "CANNOT create the $temp_sql_file file, please check the disk space";
    printf '%s\n' "SET SESSION sql_mode='NO_BACKSLASH_ESCAPES';" "DROP DATABASE IF EXISTS $(sql_identifier "$db_name");" > "$temp_sql_file";
    for aHost in $db_hosts;  do
        printf '%s\n' "SET SESSION sql_mode='NO_BACKSLASH_ESCAPES';" "DROP USER IF EXISTS $(sql_string "$db_user_name")@$(sql_string "$aHost");" >> "$temp_sql_file";
    done
    echo "${temp_sql_file}"
    if ! admin_query_from_sql_file "${temp_sql_file}"; then
        rm -f "${temp_sql_file}"
        clientFailMessage "Dropping the database ${db_name} and the ${db_user_name} account"
        return 1
    fi
    rm -f "${temp_sql_file}"

    temp_sql_file=$(mktemp -q) || die 1 "CANNOT create the $temp_sql_file file, please check the disk space";
    echo "SHOW databases;" >  "$temp_sql_file";
    printf '%s\n' 'SELECT user, host, Grant_priv, Show_db_priv FROM mysql.user;' >> "$temp_sql_file"
    if ! admin_query_from_sql_file "${temp_sql_file}"; then
        rm -f "${temp_sql_file}"
        clientFailMessage 'Listing databases and accounts'
        return 1
    fi
    rm -f "${temp_sql_file}"
}


function drop_user
{
    local db_hosts="$1"; shift;
    local db_user_name="$1"; shift;

    printf ">> Drop the user -%s- at -%s- \\n" "${db_user_name}" "${db_hosts[@]}"
    
    local aHost
    local temp_sql_file="";
    temp_sql_file=$(mktemp -q) || die 1 "CANNOT create the $temp_sql_file file, please check the disk space";
    for aHost in $db_hosts;  do
        printf '%s\n' "SET SESSION sql_mode='NO_BACKSLASH_ESCAPES';" "DROP USER IF EXISTS $(sql_string "$db_user_name")@$(sql_string "$aHost");" >> "$temp_sql_file";
    done
    echo "${temp_sql_file}"
    if ! admin_query_from_sql_file "${temp_sql_file}"; then
        rm -f "${temp_sql_file}"
        clientFailMessage "Dropping the ${db_user_name} account"
        return 1
    fi
    rm -f "${temp_sql_file}"

    temp_sql_file=$(mktemp -q) || die 1 "CANNOT create the $temp_sql_file file, please check the disk space";
    printf '%s\n' 'SELECT user, host, Grant_priv, Show_db_priv FROM mysql.user;' >> "$temp_sql_file"
    if ! admin_query_from_sql_file "${temp_sql_file}"; then
        rm -f "${temp_sql_file}"
        clientFailMessage 'Listing accounts'
        return 1
    fi
    rm -f "${temp_sql_file}"
}

# 1 : MariaDB Database name 
# SQL_ADMIN_CMD contains host information which the command can be executed.
function create_db
{
   local db_name="$1"; shift;
   if [ "$verbose" == "YES" ]; then
       printf ">> Create the Database %s \\n" "${db_name}";
   fi
   if ! "${SQL_ADMIN_CMD[@]}" <<EOF
CREATE DATABASE IF NOT EXISTS $(sql_identifier "$db_name") CHARACTER SET utf8mb4;
EOF
   then
       clientFailMessage "Creating the database ${db_name}"
       return 1
   fi
   printf "\\n"  
}

# 1 : MariaDB Database name 
# SQL_ADMIN_CMD contains host information which the command can be executed. 
function drop_db
{
    local db_name="$1"; shift;
    if [ "$verbose" == "YES" ]; then
        printf ">> Drop the Database %s \\n" "${db_name}";
    fi

    if ! "${SQL_ADMIN_CMD[@]}" <<EOF
DROP DATABASE IF EXISTS $(sql_identifier "$db_name");
EOF
    then
        clientFailMessage "Dropping the database ${db_name}"
        return 1
    fi
    printf "\\n"
}

function show_dbs
{
    local dBs db
    if ! dBs=$("${SQL_ADMIN_CMD[@]}" -N --execute="SHOW DATABASES;"); then
        clientFailMessage "Listing databases"
        return 1
    fi
    for db in $dBs; do
        printf ">>>>> %24s was found.\n" "$db"
    done
}

# 1 : database name
# 2 : verbose
# 3 : client command array name (default: SQL_ADMIN_CMD); callers that act
#     as the application account pass SQL_DBUSER_CMD
# Exit status: 0 present, 1 absent, 2 inspection failure. Non-verbose
# stdout retains the internal EXIST/NON_EXIST values for existing callers.
function isDb
{
    local db_name="$1"
    local verbose="${2:-}"
    local -n sql_cmd="${3:-SQL_ADMIN_CMD}"
    local outputs
    if ! outputs=$("${sql_cmd[@]}" -N --execute="SET SESSION sql_mode='NO_BACKSLASH_ESCAPES'; SELECT schema_name FROM information_schema.schemata WHERE schema_name=$(sql_string "$db_name")"); then
        printf ">> Cannot check the database >> %s <<, the database client failed.\n" "$db_name" >&2
        return 2
    fi
    if [[ $verbose == YES ]]; then
        printf "Database %s: %s\n" "$db_name" "${outputs:-absent}" >&2
    elif [[ -n $outputs ]]; then
        printf '%s\n' "$EXIST"
    else
        printf '%s\n' "$NON_EXIST"
    fi
    [[ -n $outputs ]]
}   

function commandPrn
{
    local cmd="$1"; shift;
    local verbose="$1"; shift;

    if [ "$verbose" == "YES" ]; then
        # shellcheck disable=SC2001
        cmd=$(echo "${cmd}" | sed -e "s/--password=.*--port/--password=******* --port/g" -e "s/PASSWORD = .*WHERE/set PASSWORD = ******* WHERE/g")
        printf ">> command :\\n"
        printf "%s\\n" "$cmd"
        printf ">>\\n"
    fi
}

# 1 : database name
# 2 : sql file (with path) for database creation
# 3 : additional options (useful to use -N )
# 4 : verbose
function query_from_sql_file
{
    local db_name="$1"
    local sql_file="$2"
    local verbose="${4:-NO}"
    local db_exist
    local -a options=()
    database_query_arguments queryFile "$sql_file" "${3:-}" "$verbose" || return 2
    options=("${DATABASE_QUERY_OPTIONS[@]}")
    db_exist=$(isDb "$db_name" "" SQL_DBUSER_CMD) || return $?
    if [[ $db_exist -ne $EXIST ]]; then
        noDbMessage "$db_name"
        return 1
    fi
    if [[ $verbose == YES ]]; then
        printf ">> Query database %s from %s\n" "$db_name" "$sql_file"
    fi
    "${SQL_DBUSER_CMD[@]}" "${options[@]}" "--database=$db_name" < "$sql_file"
}


# 1 : database name
function show_tables
{
    local db_name="$1"; shift;
    local type="$1"; shift;
    local db_exist;
    local tables;
    local table;
    local -a table_array=();
    local i;
    i=0;
    db_exist=$(isDb "${db_name}" "" SQL_DBUSER_CMD) || return $?;
    
    if [[ $db_exist -ne "$EXIST" ]]; then
	    noDbMessage "${db_name}";
	    exit 1;
    else
        if ! tables=$("${SQL_DBUSER_CMD[@]}" "--database=${db_name}" -N --batch --execute="SHOW FULL TABLES WHERE Table_type='${type}'"); then
            clientFailMessage "Listing tables in ${db_name}"
            return 1
        fi
        printf "\n";

        if [[ -n $tables ]]; then mapfile -t table_array <<< "$tables"; fi
        for table in "${table_array[@]}"
        do
            table=${table%%$'\t'*}
            ((++i))
            ((++j))
            printf ">> %4d/%4d/%4d<< %40s\\n" "$j" "$i" "${#table_array[@]}" "${table}"
        done
    fi
    
}


# 1 : database name
function show_procedures
{
    local db_name="$1"; shift;
    local db_exist;
    local outputs;
    local cmd;
    local i;
    i=0;

    db_exist=$(isDb "${db_name}" "" SQL_DBUSER_CMD) || return $?;
    
    if [[ $db_exist -ne "$EXIST" ]]; then
	    noDbMessage "${db_name}";
	    exit 1;
    else
        if ! outputs=$(set -o pipefail; "${SQL_DBUSER_CMD[@]}" "--database=${db_name}" -N --execute="SHOW PROCEDURE STATUS" | awk '{print $2}'); then
            clientFailMessage "Listing procedures in ${db_name}"
            return 1
        fi
        printf "\n";
        # shellcheck disable=SC2206
        declare -a  array=( ${outputs} )
   	    for output in $outputs
	    do
            ((++i))
            ((++j))
            printf ">> %4d/%4d/%4d<< %40s\\n" "$j" "$i" "${#array[@]}" "${output}"

	    done
    fi
    
}




# 1 : database name
function drop_tables
{
    local db_name=$1 type=$2 statements
    isDb "$db_name" '' SQL_DBUSER_CMD >/dev/null || return $?
    statements=$("${SQL_DBUSER_CMD[@]}" "--database=$db_name" -N -B -r --execute="SET SESSION sql_mode='NO_BACKSLASH_ESCAPES'; SELECT CONCAT('DROP TABLE ', CHAR(96), REPLACE(TABLE_NAME, CHAR(96), CONCAT(CHAR(96), CHAR(96))), CHAR(96), ';') FROM information_schema.tables WHERE TABLE_SCHEMA=$(sql_string "$db_name") AND TABLE_TYPE=$(sql_string "$type");") || return
    [[ -n $statements ]] || return 0
    printf '%s\n' 'SET foreign_key_checks=0;' "$statements" 'SET foreign_key_checks=1;' | "${SQL_DBUSER_CMD[@]}" "--database=$db_name"
}


# 1 : database name
# 2 : MariaDB query
function execute_query
{
    local db_name="$1"
    local query="$2"
    local db_exist
    db_exist=$(isDb "$db_name" "" SQL_DBUSER_CMD) || return $?
    if [[ $db_exist -ne $EXIST ]]; then
        noDbMessage "$db_name"
        return 1
    fi
    "${SQL_DBUSER_CMD[@]}" "--database=$db_name" --execute="$query"
}
