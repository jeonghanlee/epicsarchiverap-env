#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.1.0
#  date    : Wed 14 Sep 2022 10:46:23 AM PDT

declare -g SC_SCRIPT;
declare -g SC_TOP;
declare -g LOGDATE;
declare -g ENV_TOP;

SC_SCRIPT="$(realpath "$0")";
#SC_SCRIPTNAME=${0##*/};
SC_TOP="${SC_SCRIPT%/*}"
LOGDATE="$(date +%y%m%d%H%M)"
ENV_TOP="${SC_TOP}/.."

# Reject an unselected backend before reading MariaDB configuration or clients.
if [[ ! ${DB_BACKEND+x} ]]; then
    DB_BACKEND=$(make -C "${ENV_TOP}" --no-print-directory -s print-DB_BACKEND) || exit 2
fi
case "$DB_BACKEND" in
    mariadb) ;;
    sqlite)
        printf '%s\n' 'mariadb_setup.bash is not supported for DB_BACKEND=sqlite; no database was changed.' >&2
        exit 2
        ;;
    *)
        printf "DB_BACKEND must be one of: mariadb sqlite (got '%s')\n" "$DB_BACKEND" >&2
        exit 2
        ;;
esac

AA_SITE_TEMPLATE_PATH=$(make -C "${ENV_TOP}" -s print-AA_SITE_TEMPLATE_PATH)

# shellcheck disable=SC1090,SC1091
. "${AA_SITE_TEMPLATE_PATH}/mariadb.conf"
# shellcheck disable=SC1090,SC1091
. "${SC_TOP}/mariadb_generic_function.bash"

declare -g DEFAULT_DB_BACKUP_PATH;
# shellcheck disable=SC2153
DEFAULT_DB_BACKUP_PATH="${ENV_TOP}/${DB_NAME}_sql_backup";

function usage
{
    {
	echo "";
	echo "Usage    : $0 <arg>";
	echo "";
	echo "          <arg>              : info";
	echo "";
	echo "          secureSetup        : mariaDB secure installation";
	echo "          adminAdd           : add the admin account";
	echo "";
	# shellcheck disable=SC2153
	echo "          dbCreate           : create the DB -${DB_NAME}- at -${DB_HOST_NAME}-";
	echo "          dbDrop             : drop   the DB -${DB_NAME}- at -${DB_HOST_NAME}-";
	echo "          dbShow             : show all dbs exist";
	echo "";
	echo "          dbUserCreate       : create the DB -${DB_NAME}- with ${DB_USER} at -${DB_USER_HOST}-";
	echo "          dbUserDrop         : drop   the DB -${DB_NAME}- with ${DB_USER} at -${DB_USER_HOST}-";

	echo "";
	echo "          dbBackup           : back up the DB -${DB_NAME}- at default -${DEFAULT_DB_BACKUP_PATH}.";
	echo "          dbBackupList       : show all backup DB list at default -${DEFAULT_DB_BACKUP_PATH}.";
	echo "          dbRestore          : restore the DB into the running sql at default -${DEFAULT_DB_BACKUP_PATH}.";
	echo "";
	echo "          tableDrop          : drop   the tables";
	echo "          tableShow          : show   the tables";
	echo "          aaShow [table]     : show appliance table rows (PVTypeInfo by default)";
	echo "          isDb               : check whether the configured database exists";
	echo "          userDrop           : drop the application account; keep its database";
	echo "          localAdminAdd      : add the administrator at localhost";
	echo "          hostnameAdminAdd   : add the administrator at DB_HOST_NAME";
	echo "          adminRemove        : remove the administrator at localhost";
	echo "          localAdminRemove   : remove the administrator at localhost";
	echo "          hostnameAdminRemove: remove the administrator at DB_HOST_NAME";
	echo "          Schema creation    : use make sql.fill";
	echo "";
	echo "          query \"sql query\"    : Send any sql query to DB -${DB_NAME}-"
	echo "          queryFile \"sql file\" : Send a query through a sql file to DB -${DB_NAME}-";
	echo "";
    } 1>&2;
    exit 1;
}



# 1 : database name
function drop_procedures
{
    local db_name="$1"; shift;
    local db_exist;
    local cmd;
    db_exist=$(isDb "${db_name}" "" SQL_DBUSER_CMD);

    if [[ $db_exist -ne "$EXIST" ]]; then
	    noDbMessage "${db_name}";
	    exit 1;
    else
        if ! outputs=$(set -o pipefail; "${SQL_DBUSER_CMD[@]}" "${db_name}" -N --execute="SHOW PROCEDURE STATUS" | awk '{print $2}'); then
            clientFailMessage "Listing procedures for removal in ${db_name}"
            return 1
        fi
        # shellcheck disable=SC2086

        printf "\n";
        for output in $outputs
        do
            printf ". %24s was found. Droping .... \n" "${output}"
            "${SQL_DBUSER_CMD[@]}" "${db_name}" --execute="DROP PROCEDURE IF EXISTS $(sql_identifier "$output")"
        done
    fi

}

function generate_admin_local_password
{
    local db_name="$1"; shift;
    local db_user_name="$1"; shift;
    local local_password="$1"; shift;
    local python_path="$1";shift;
    local python_cmd="$1"; shift;

    local db_exist;
    local cmd;
    
    local adminWithLocalPassword;

    db_exist=$(isDb "${db_name}" "" SQL_DBUSER_CMD);


    if [[ $db_exist -ne "$EXIST" ]]; then
	    noDbMessage "${db_name}";
	    exit 1;
    else
        adminWithLocalPassword=$(query_from_sql_file "${db_name}" "${ENV_TOP}/site-template/sql/check_cdb_admin.sql" -N) || exit 1
        if [ -z "$adminWithLocalPassword" ]; then
            printf ">>> We've found there is the CDB admin user %s with a local password.\n" "$db_user_name"
            printf "    Updating ........ \n"
#           echo "$db_name, $db_user_name, $local_password, $python_path"
#            cmd="PYTHONPATH=${python_path} ${python_cmd} -c \"from cdb.common.utility.cryptUtility import CryptUtility; print CryptUtility.cryptPasswordWithPbkdf2('${local_password}')\""
#            echo "$cmd"
            adminCryptPassword=$(get_admin_crypt_password  "${db_name}" "$local_password" "${python_path}" "${python_cmd}") || exit 1
#            echo $adminCryptPassword
            ## we have to create a temp file to handle this crypt password, because bash cannot handle these special character well within 
            ##
            temp_sql_file=$(mktemp -q) || die 1 "CANNOT create the $temp_sql_file file, please check the disk space";
            echo "UPDATE user_info SET password = ('$adminCryptPassword')  WHERE (username='$db_user_name');" > "${temp_sql_file}"
            query_from_sql_file "${db_name}" "${temp_sql_file}"
            rm -f "${temp_sql_file}"
        else
            printf ">>> We've found there is the CDB admin user %s with a local password.\n" "$db_user_name"
            printf "    It is OK.\n"
        fi
        printf ">>> One can check it via the SQL query \"SELECT username, password FROM user_info;\"\n"
    fi
}


function get_admin_crypt_password
{
    local db_name="$1"; shift;
    local local_password="$1"; shift;
    local python_path="$1";shift;
    local python_cmd="$1"; shift;
    local db_exist;
    local cmd;

    local adminWithLocalPassword;

    db_exist=$(isDb "${db_name}");


    if [[ $db_exist -ne "$EXIST" ]]; then
	    noDbMessage "${db_name}";
	    exit 1;
    else
        cmd="PYTHONPATH=${python_path} ${python_cmd} -c \"from cdb.common.utility.cryptUtility import CryptUtility; print CryptUtility.cryptPasswordWithPbkdf2('${local_password}')\""
        adminCryptPassword=$(eval "$cmd")
        echo "$adminCryptPassword"
    fi
}



#adminWithLocalPassword=`eval $mysqlCmd temporaryAdminCommand.sql`
#if [ -z "$adminWithLocalPassword" ]; then
#   echo "No portal admin user with a local password exists"
#    read -sp "Enter password for local portal admin (username: cdb): [leave blank for no local password] " CDB_LOCAL_SYSTEM_ADMIN_PASSWORD
#    echo ""
#    if [ ! -z "$CDB_LOCAL_SYSTEM_ADMIN_PASSWORD" ]; then
#	adminCryptPassword=`python -c "from cdb.common.utility.cryptUtility import CryptUtility; print CryptUtility.cryptPasswordWithPbkdf2('$CDB_LOCAL_SYSTEM_ADMIN_PASSWORD')"`
#	echo "update user_info set password = '$adminCryptPassword' where username='cdb'" > temporaryAdminCommand.sql
#        execute $mysqlCmd temporaryAdminCommand.sql
#    fi
#fi




#printf ">> Show current databases .. with admin account\\n\n"
#${SQL_ADMIN_CMD} -e "SELECT SCHEMA_NAME 'database', default_character_set_name 'charset', DEFAULT_COLLATION_NAME 'collation' FROM information_schema.SCHEMATA;"


function backup_db
{
    local db_name="$1"; shift;
    local db_backup_path="$1"; shift;
    local dbDir;
    local db_exist;
    local backup_file;
    local backup_temp;

    db_exist=$(isDb "${db_name}" "" SQL_DBUSER_CMD);

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
            if ! "${SQL_BACKUP_CMD[@]}" "${db_name}" | gzip -9 > "$backup_temp"; then
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


    # The restore fails when either gunzip or the client fails; the subshell
    # confines pipefail without requiring 'local -'.
    if ! ( set -o pipefail; gunzip < "${db_backup_path}/${db_backup_file}" | "${SQL_ADMIN_CMD[@]}" "${DB_NAME}" ); then
	printf "\nRestoring >> %s << into >> %s << failed.\n\n" "${db_backup_file}" "${DB_NAME}" >&2
	exit 1;
    fi
}


# 1 : Table name
function show_archappl
{
    local db_name="${DB_NAME}";
    local table_name="$1"; shift;
    local db_exist;
    local tables;
    local cmd;
    local i;
    i=0;

    db_exist=$(isDb "${db_name}" "" SQL_DBUSER_CMD);

    if [[ $db_exist -ne "$EXIST" ]]; then
	    noDbMessage "${db_name}";
	    exit 1;
    else
        if ! tables=$(set -o pipefail; "${SQL_DBUSER_CMD[@]}" "${db_name}" -N --execute="SELECT * FROM $(sql_identifier "$table_name")" | awk '{print $1}'); then
            clientFailMessage "Reading ${db_name}.${table_name}"
            return 1
        fi
        printf "\n";
        # shellcheck disable=SC2206
        declare -a  table_array=( ${tables} )
        for table in $tables
        do
            ((++i))
            ((++j))
            printf ">> %4d/%4d/%4d<< %80s\\n" "$j" "$i" "${#table_array[@]}" "${table}"
	    done
    fi
}




input="$1";
additional_input="$2";


case "$input" in
    secureSetup)
        # shellcheck disable=SC2153
        mariadb_secure_setup;
        ;;
    localAdminAdd)
        # shellcheck disable=SC2153
        add_admin_account_local "${DB_ADMIN}" "${DB_ADMIN_PASS}";
        ;;
    hostnameAdminAdd)
        # shellcheck disable=SC2153
        add_admin_account_hostname "${DB_ADMIN}" "${DB_ADMIN_PASS}" "${DB_HOST_NAME}";
	    ;;
    localAdminRemove)
        remove_admin_account_local "${DB_ADMIN}";
        ;;
    hostnameAdminRemove)
        remove_admin_account_hostname "${DB_ADMIN}" "${DB_HOST_NAME}";
        ;;
    adminAdd)
        #shellcheck disable=SC2153
        add_admin_account_local "${DB_ADMIN}" "${DB_ADMIN_PASS}";
        ##shellcheck disable=SC2153
        #add_admin_account_hostname "${DB_ADMIN}" "${DB_ADMIN_PASS}" "${DB_HOST_NAME}";
	    ;;
    adminRemove)
        remove_admin_account_local "${DB_ADMIN}";
        #remove_admin_account_hostname "${DB_ADMIN}" "${DB_HOST_NAME}";
	    ;;
    dbCreate)
        create_db "${DB_NAME}";
        ;;
    dbUserCreate)
        # shellcheck disable=SC2153
        create_db_and_user "${DB_NAME}" "${DB_USER_HOST}" "${DB_USER}" "${DB_USER_PASS}";
        ;;
    dbShow)
        show_dbs;
        ;;
    dbUserDrop)
        drop_db_and_user "${DB_NAME}" "${DB_USER_HOST}" "${DB_USER}";
        ;;
    userDrop)
      drop_user "${DB_USER_HOST}" "${DB_USER}";
        ;;
    dbDrop)
        drop_db "${DB_NAME}"
        ;;
    isDb)
        isDb "${DB_NAME}" "YES";
        ;;
    dbBackup)
	    backup_path="$additional_input"
	    if [ -z "${backup_path}" ]; then
            backup_path="${DEFAULT_DB_BACKUP_PATH}"
        fi
	    backup_db "${DB_NAME}" "${backup_path}";
        ;;
    dbBackupList)
	    backup_path="$additional_input"
	    if [ -z "${backup_path}" ]; then
            backup_path="${DEFAULT_DB_BACKUP_PATH}"
        fi
        backup_db_list "${backup_path}"
        ;;
    dbRestore)
        date="$additional_input";
	    backup_path="$3"
	    if [ -z "${backup_path}" ]; then
            backup_path="${DEFAULT_DB_BACKUP_PATH}"
        fi
        restore_db "${date}" "${backup_path}";
        ;;
#    tableCreate)
#        if [ -z "${additional_input}" ]; then
#            additional_input="${ENV_TOP}//ComponentDB-src/db/sql/create_cdb_tables.sql"
#        fi
#        query_from_sql_file "${DB_NAME}" "${additional_input}";
#        ;;    
    tableShow)
        show_tables "${DB_NAME}" "BASE TABLE";
        ;;
    tableDrop)
        drop_tables "${DB_NAME}" "BASE TABLE";
        ;; 
    aaShow)
        if [ -z "${additional_input}" ]; then
            additional_input="PVTypeInfo"
        fi
        show_archappl "${additional_input}";
        ;;
#    viewCreate)
#        if [ -z "${additional_input}" ]; then
#            additional_input="${ENV_TOP}/ComponentDB-src/db/sql/create_views.sql"
#        fi
#        query_from_sql_file "${DB_NAME}" "${additional_input}";
#        ;;
#    viewShow)
#        show_tables "${DB_NAME}" "VIEW";
#        ;;
#    viewDrop)
#        drop_tables "${DB_NAME}" "VIEW";
#        ;;
#    sProcCreate)
#        if [ -z "${additional_input}" ]; then
#            additional_input="${ENV_TOP}/ComponentDB-src/db/sql/create_stored_procedures.sql"
#        fi
#        query_from_sql_file "${DB_NAME}" "${additional_input}";
#        ;;
#    sProcShow)
#        show_procedures "${DB_NAME}";
#        ;;
#    sProcDrop)
#        drop_procedures "${DB_NAME}";
#        ;;
#    triggersCreate)
#        if [ -z "${additional_input}" ]; then
#            additional_input="${ENV_TOP}/ComponentDB-src/db/sql/create_triggers.sql"
#        fi
#        query_from_sql_file "${DB_NAME}" "${additional_input}"
#        ;;
#    triggersShow)
#        execute_query "${DB_NAME}" "show TRIGGERS;"
#        ;;
#    triggersDrop)
#        drop_triggers "${DB_NAME}";
#        ;;
#    allCreate)
#        input1="${ENV_TOP}/ComponentDB-src/db/sql/create_cdb_tables.sql"
#        input2="${ENV_TOP}/ComponentDB-src/db/sql/create_views.sql"
#        input3="${ENV_TOP}/ComponentDB-src/db/sql/create_stored_procedures.sql"
#        query_from_sql_file "${DB_NAME}" "$input1"
#        query_from_sql_file "${DB_NAME}" "$input2"
#        query_from_sql_file "${DB_NAME}" "$input3"
#        ;;
#    allShow)
#        show_tables "${DB_NAME}" "BASE TABLE";
#        show_tables "${DB_NAME}" "VIEW";
#        show_procedures "${DB_NAME}";
#        ;;
#    allDrop)
#        drop_tables "${DB_NAME}" "BASE TABLE";  
#        drop_tables "${DB_NAME}" "VIEW";
#        drop_procedures "${DB_NAME}";
#        ;;
    query)
        if [ -z "${additional_input}" ]; then
            additional_input="SHOW DATABASES;"
        fi
        execute_query "${DB_NAME}" "$additional_input";
        ;;
    addProject)
        project_name="${additional_input}";
        execute_query "${DB_NAME}" "INSERT into item_project (name) VALUES('$project_name')"
        execute_query "${DB_NANE}" "SELECT * from item_project"
        ;;
    queryFile)
        input_sql_file="$additional_input"
        input_options="$3"
        verbose="$4"
        if [ -z "${input_sql_file}" ]; then
            input_sql_file="${SITE_TEMPLATE_PATH}/sql/default_query.sql"
        fi
        query_from_sql_file "${DB_NAME}" "$input_sql_file" "$input_options" "$verbose"
        ;;
    querySFile)
        query_sql_file="${additional_input}"
        query_options="$3"
        if [ -z "${sql_file}" ]; then
             sql_file="${SITE_TEMPLATE_PATH}/sql/default_query.sql"
        fi
        query_from_sql_file "${DB_NAME}" "${query_sql_file}" "$query_options"
        ;;
    updateCDBAdminPassword)
        python_path="$additional_input"
        # local python command instead of the system-wide
        python_cmd="$3"
        if [ -z "${python_path}" ]; then
             python_path="${ENV_TOP}/ComponentDB-src/src/python"
        fi
        generate_admin_local_password  "${DB_NAME}" "${CDB_USER}" "${CDB_USER_PASS}" "$python_path" "$3"
        ;;
    showAdminCryptPassword)
        get_admin_crypt_password  "${DB_NAME}" "$additional_input" "$3"
        ;;
    *)
        usage;
        ;;

esac
