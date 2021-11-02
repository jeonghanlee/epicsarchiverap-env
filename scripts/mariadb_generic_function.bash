#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.6


if [[ $OSTYPE == 'darwin'* ]]; then
    SQL_ROOT_CMD="sudo /opt/local/lib/mariadb-10.5/bin/mysql --user=root"
    # shellcheck disable=SC2153
    SQL_ADMIN_CMD="/opt/local/lib/mariadb-10.5/bin/mysql --user=${DB_ADMIN} --password=${DB_ADMIN_PASS} --port=${DB_HOST_PORT} --host=${DB_HOST_NAME}"
    # shellcheck disable=SC2153
    SQL_DBUSER_CMD="/opt/local/lib/mariadb-10.5/bin/mysql --user=${DB_USER} --password=${DB_USER_PASS} --port=${DB_HOST_PORT} --host=${DB_HOST_NAME}"
    # shellcheck disable=SC2034
    SQL_BACKUP_CMD="/opt/local/lib/mariadb-10.5/bin/mysqldump --user=${DB_USER} --password=${DB_USER_PASS} --port=${DB_HOST_PORT} --host=${DB_HOST_NAME}"
else
    SQL_ROOT_CMD="sudo mysql --user=root"
    # shellcheck disable=SC2153
    SQL_ADMIN_CMD="mysql --user=${DB_ADMIN} --password=${DB_ADMIN_PASS} --port=${DB_HOST_PORT} --host=${DB_HOST_NAME}"
    # shellcheck disable=SC2153
    SQL_DBUSER_CMD="mysql --user=${DB_USER} --password=${DB_USER_PASS} --port=${DB_HOST_PORT} --host=${DB_HOST_NAME}"
    # shellcheck disable=SC2034
    SQL_BACKUP_CMD="mysqldump --user=${DB_USER} --password=${DB_USER_PASS} --port=${DB_HOST_PORT} --host=${DB_HOST_NAME}"
fi

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

function noDbMessage
{
    local db_name="$1"; shift;
    if [ "${VERBOSE}" == "YES" ]; then
        printf ">> There is no >> %s << in the dababase, please check your SQL enviornment.\\n" "${db_name}"
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


# 1 : MariaDB Hostname 
# 2 : MariaDB IP address 
function mariadb_secure_setup
{
    local db_hostname="$1"; shift;
    local db_host_ipaddr="$1"; shift;

    # MariaDB Secure Installation without MariaDB root password
    # the same as mysql_secure_installation, but skip to setup
    # the root password in the script. The reference of the sql commands
    # is https://goo.gl/DnyijD

    # remove_anonymous_users()
    # remove_remote_root()
    # remove_test_database()
    # reload_privilege_tables()
    printf ">> MariaDB Secure Installation\\n";
    # shellcheck disable=SC2154
    ${SQL_ROOT_CMD} <<EOF
    -- DELETE FROM mysql.user WHERE User='';
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('${db_hostname}', '${db_host_ipaddr}', '::1');
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    FLUSH PRIVILEGES;
EOF
    printf "\\n"
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
    ${SQL_ROOT_CMD} <<EOF
    GRANT ALL ON *.* TO '${db_admin_name}'@'localhost' IDENTIFIED BY '${db_admin_pass}' WITH GRANT OPTION;
    FLUSH PRIVILEGES;
EOF
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
    ${SQL_ROOT_CMD} <<EOF
    GRANT ALL ON *.* TO '${db_admin_name}'@'${db_hostname}' IDENTIFIED BY '${db_admin_pass}' WITH GRANT OPTION;
    FLUSH PRIVILEGES;
EOF
    printf "\\n"
}


# 1 : Hostname
function remove_admin_account_hostname
{
    local db_hostname="$1"; shift;
    ${SQL_ROOT_CMD} <<EOF
    DROP USER 'admin'@'${db_hostname}';
    FLUSH PRIVILEGES;
EOF
    printf "\\n"
}


function remove_admin_account_local
{
    printf ">> Remove local admin user \\n"
    ${SQL_ROOT_CMD} <<EOF
    DROP USER 'admin'@'localhost';
    FLUSH PRIVILEGES;
EOF
    printf "\\n"
}


# 1 : sql file (with path) for database creation
# 2 : additional options (useful to use -N )
function admin_query_from_sql_file
{
    local sql_file="$1"; shift;
    local options="$1"; shift;
    local cmd;

    cmd+="$SQL_ADMIN_CMD";
    cmd+=" ";
    cmd+="${options}";
    cmd+=" ";
    cmd+="<";
    cmd+=" ";
    cmd+=""\";   
    cmd+="${sql_file}";
    cmd+="\"";
    # The following cmd contains only mysql standard query
    commandPrn "$cmd"
    eval "${cmd}"
}

function create_db_and_user 
{
    local db_name="$1"; shift;
    local db_hosts="$1"; shift;
    local db_user_name="$1"; shift;
    local db_user_pass="$1";shift;

    local temp_sql_file="";
    temp_sql_file=$(mktemp -q) || die 1 "CANNOT create the $temp_sql_file file, please check the disk space";
    echo "CREATE DATABASE IF NOT EXISTS ${db_name} CHARACTER SET utf8mb4;" > "$temp_sql_file";
    for aHost in $db_hosts;  do
        echo "GRANT ALL PRIVILEGES ON ${db_name}.* TO '$db_user_name'@'$aHost' IDENTIFIED BY '$db_user_pass';" >> "$temp_sql_file";
    done
    echo "FLUSH PRIVILEGES;" >> "${temp_sql_file}"; 
#    echo "${temp_sql_file}"
    admin_query_from_sql_file "${temp_sql_file}";
    rm -f "${temp_sql_file}"
    
    temp_sql_file=$(mktemp -q) || die 1 "CANNOT create the $temp_sql_file file, please check the disk space";
    echo "SHOW databases;" >  "$temp_sql_file";
#   authentication_string, default_role, is_role are for MariaDB
#   https://mariadb.com/kb/en/mysqluser-table/
#   echo "SELECT user, host, Password, Grant_priv, Show_db_priv, authentication_string, default_role, is_role FROM mysql.user;" >>  "$temp_sql_file";
    echo "SELECT user, host, Password, Grant_priv, Show_db_priv FROM mysql.user;" >>  "$temp_sql_file";
    admin_query_from_sql_file "${temp_sql_file}";
    rm -f "${temp_sql_file}"
}

function drop_db_and_user
{
    local db_name="$1"; shift;
    local db_hosts="$1"; shift;
    local db_user_name="$1"; shift;

    printf ">> Drop the Database -%s- \\n" "${db_name}";
    printf ">> Drop the user -%s- at -%s- \\n" "${db_user_name}" "${db_hosts[@]}"
    
    local temp_sql_file="";
    temp_sql_file=$(mktemp -q) || die 1 "CANNOT create the $temp_sql_file file, please check the disk space";
    echo "DROP DATABASE IF EXISTS ${db_name};" > "$temp_sql_file";
    for aHost in $db_hosts;  do
        echo "DROP USER '$db_user_name'@'$aHost';" >> "$temp_sql_file";
    done
    echo "${temp_sql_file}"
    admin_query_from_sql_file "${temp_sql_file}";

    temp_sql_file=$(mktemp -q) || die 1 "CANNOT create the $temp_sql_file file, please check the disk space";
    echo "SHOW databases;" >  "$temp_sql_file";
    echo "SELECT user, host, Password, Grant_priv, Show_db_priv, authentication_string, default_role, is_role FROM mysql.user;" >>  "$temp_sql_file";
    admin_query_from_sql_file "${temp_sql_file}";
    rm -f "${temp_sql_file}"
}


function drop_user
{
    local db_hosts="$1"; shift;
    local db_user_name="$1"; shift;

    printf ">> Drop the user -%s- at -%s- \\n" "${db_user_name}" "${db_hosts[@]}"
    
    local temp_sql_file="";
    temp_sql_file=$(mktemp -q) || die 1 "CANNOT create the $temp_sql_file file, please check the disk space";
    for aHost in $db_hosts;  do
        echo "DROP USER '$db_user_name'@'$aHost';" >> "$temp_sql_file";
    done
    echo "${temp_sql_file}"
    admin_query_from_sql_file "${temp_sql_file}";

    temp_sql_file=$(mktemp -q) || die 1 "CANNOT create the $temp_sql_file file, please check the disk space";
    echo "SELECT user, host, Password, Grant_priv, Show_db_priv, authentication_string, default_role, is_role FROM mysql.user;" >>  "$temp_sql_file";
    admin_query_from_sql_file "${temp_sql_file}";
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
   ${SQL_ADMIN_CMD} <<EOF
CREATE DATABASE IF NOT EXISTS ${db_name} CHARACTER SET utf8mb4;
EOF
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

    ${SQL_ADMIN_CMD} <<EOF
DROP DATABASE IF EXISTS ${db_name};
EOF
    printf "\\n"
}

function show_dbs
{
    local dBs;
    local cmd;
    cmd+="$SQL_ADMIN_CMD";
    cmd+=" ";
    cmd+="-N";
    cmd+=" ";   
    cmd+="--execute=\"";
    # The following cmd contains only mysql standard query
    cmd+="SHOW DATABASES;";
    cmd+="\"";
    commandPrn "$cmd"
    dBs=$(eval "${cmd}" | awk '{print $1}')
    for db in $dBs
    do
        printf ">>>>> %24s was found.\n" "${db}"
    done
}

# 1 : database name
# If the database exists,        it returns 1
# If the database doesn't exist, it returns 0
function isDb 
{
    local db_name="$1"; shift;
    local verbose="$1"; shift;

    local outputs;
    local cmd;
    cmd+="$SQL_ADMIN_CMD";
    cmd+=" ";
    cmd+="-N";
    cmd+=" ";   
    cmd+="--execute=\"";
    # The following cmd contains only mysql standard query
    cmd+="SELECT schema_name FROM information_schema.schemata WHERE schema_name='${db_name}'";
    cmd+="\"";
    outputs=$(eval "${cmd}" | awk '{print $1}')
    if [ "$verbose" == "YES" ]; then
        commandPrn "$cmd"
        printf "We've found the DB -%s- \\n" "$outputs";
    else
        local result=""
        if [[ -z "${outputs}" ]]; then
            result=${NON_EXIST} # does not exist
        else
            result=${EXIST}     # exists
        fi
        echo "${result}"
    fi
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
    local db_name="$1"; shift;
    local sql_file="$1"; shift;
    local options="$1"; shift;
    local verbose="$1"; shift;
    local db_exist;
    local cmd;

    if [ -z "${options}" ]; then
        options="";
    fi

    if [ -z "${verbose}" ]; then
        verbose="NO"
    fi

    db_exist=$(isDb "${db_name}");

    if [[ $db_exist -ne "$EXIST" ]]; then
   	    noDbMessage "${db_name}";
	    exit;
    else
        cmd+="$SQL_DBUSER_CMD";
        cmd+=" ";
        cmd+="${options}";
        cmd+=" ";
        cmd+="${db_name}";
        cmd+=" ";
        cmd+="<";
        cmd+=" ";
        cmd+=""\";   
        cmd+="${sql_file}";
        cmd+="\"";
        # The following cmd contains only mysql standard query
        commandPrn "$cmd" "$verbose"
        eval "${cmd}"
    fi
}


# 1 : database name
function show_tables
{
    local db_name="$1"; shift;
    local type="$1"; shift;
    local db_exist;
    local tables;
    local cmd;
    local i;
    i=0;
    db_exist=$(isDb "${db_name}");
    
    if [[ $db_exist -ne "$EXIST" ]]; then
	    noDbMessage "${db_name}";
	    exit;
    else
        cmd+="$SQL_DBUSER_CMD";
        cmd+=" ";
        cmd+="${db_name}";
        cmd+=" ";
        cmd+="-N";
        cmd+=" ";   
        cmd+="--execute=\"";
        # The following cmd contains only mysql standard query
        cmd+="SHOW FULL TABLES WHERE Table_type='${type}'"
        cmd+=";\"";
        commandPrn "$cmd"
        tables=$(eval "${cmd}" | awk '{print $1}')
        printf "\n";
        # shellcheck disable=SC2206
        declare -a  table_array=( ${tables} )
   	    for table in $tables
	    do
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

    db_exist=$(isDb "${db_name}");
    
    if [[ $db_exist -ne "$EXIST" ]]; then
	    noDbMessage "${db_name}";
	    exit;
    else
        cmd+="$SQL_DBUSER_CMD";
        cmd+=" ";
        cmd+="${db_name}";
        cmd+=" ";
        cmd+="-N";
        cmd+=" ";   
        cmd+="--execute=\"";
        # The following cmd contains only mysql standard query
        cmd+="SHOW PROCEDURE STATUS"
        cmd+=";\"";
        commandPrn "$cmd"
        outputs=$(eval "${cmd}" | awk '{print $2}')
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
    local db_name="$1"; shift;
    local type="$1"; shift;
    local tables;
    local db_exist;
    local cmd;
    local dropCmd;
    db_exist=$(isDb "${db_name}");

    if [[ $db_exist -ne "$EXIST" ]]; then
	    noDbMessage "${db_name}";
	    exit;
    else
        cmd+="$SQL_DBUSER_CMD";
        cmd+=" ";
        cmd+="${db_name}";
        cmd+=" ";
        cmd+="-N";
        cmd+=" ";   
        cmd+="--silent"
        cmd+=" ";   
        cmd+="--execute=\"";
        # The following cmd contains only mysql standard query
        # It is ok to get all table and views, because we only use DROP TABEL query
        cmd+="SHOW FULL TABLES WHERE Table_type='${type}'"
        cmd+=";\"";
        commandPrn "$cmd"
        tables=$(eval "${cmd}" | awk '{print $1}' )
        if [ "$tables" ]; then
            # shellcheck disable=SC2086
            tables_cmd=$(echo ${tables} | tr -s ' ' ',')
            printf "\n";
            dropCmd+="$SQL_DBUSER_CMD";
            dropCmd+=" ";
            dropCmd+="${db_name}";
            dropCmd+=" ";
            dropCmd+="--execute=\"";
            # Ignore all table orders, drop all
            dropCmd+="SET foreign_key_checks = 0;"
            if [ "$type" == "VIEW" ]; then
                dropCmd+="DROP VIEW IF EXISTS ${tables_cmd};"
            else
                dropCmd+="DROP TABLE IF EXISTS ${tables_cmd};"
            fi
            dropCmd+="SET foreign_key_checks = 1"
            dropCmd+=";\"";
       
            commandPrn "$dropCmd"
            eval "${dropCmd}"
        fi

    fi

}



# 1 : database name
# 2 : MariaDB query
function execute_query
{
    local db_name="$1"; shift;
    local query="$1"; shift;
    local db_exist;
    local cmd;

    db_exist=$(isDb "${db_name}");

    if [[ $db_exist -ne "$EXIST" ]]; then
   	    noDbMessage "${db_name}";
	    exit;
    else
        cmd+="$SQL_DBUSER_CMD";
        cmd+=" ";
        cmd+="${db_name}";
        cmd+=" ";
        cmd+="--execute=\"";
        cmd+="${query}";
        cmd+="\"";
        # The following cmd contains only mysql standard query
        commandPrn "$cmd"
        eval "${cmd}"
    fi
}
