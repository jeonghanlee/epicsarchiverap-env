#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.4

declare -g SC_SCRIPT;
declare -g SC_TOP;
declare -g ENV_TOP;

SC_SCRIPT="$(realpath "$0")";
#SC_SCRIPTNAME=${0##*/};
SC_TOP="${SC_SCRIPT%/*}"
#LOGDATE="$(date +%y%m%d%H%M)"
ENV_TOP="${SC_TOP}/.."
 
# shellcheck disable=SC1090
. "${ENV_TOP}/site-template/mariadb.conf"
# shellcheck disable=SC1090
. "${SC_TOP}/mariadb_generic_function.bash"

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
    echo "          tableCreate        : create the tables";
    echo "          tableDrop          : drop   the tables";
    echo "          tableShow          : show   the tables";
    echo "          viewCreate         : create the views";
    echo "          viewDrop           : drop   the views";
    echo "          viewShow           : show   the views";
    echo "          sProcCreate        : create the stored_procedures";
    echo "          sProcDrop          : drop   the stored_procedures";
    echo "          sProcShow          : show   the stored_procedures";
    echo "";
    echo "          allCreate          : create the tables, views, and stored_procedures";
    echo "          allViews           : show the tables, views, and stored_procedures";
    echo "          allDrop            : drop the tables, views, and stored_procedures";
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
        cmd+="SHOW PROCEDURE STATUS"
        cmd+=";\"";
        commandPrn "$cmd"
        outputs=$(eval "${cmd}" | awk '{print $2}' )
        # shellcheck disable=SC2086

        printf "\n";
        for output in $outputs
        do
            dropCmd="$SQL_DBUSER_CMD";
            dropCmd+=" ";
            dropCmd+="${db_name}";
            dropCmd+=" ";
            dropCmd+="--execute=\"";
            # Ignore all table orders, drop all
            dropCmd+="DROP PROCEDURE IF EXISTS ${output}"
            dropCmd+=";\"";
            printf ". %24s was found. Droping .... \n" "${output}"
            commandPrn "$dropCmd"
            eval "${dropCmd}"
        done
    fi

}


# 1 : database name
function drop_triggers
{
    local db_name="$1"; shift;
    local db_exist;
    local cmd;
    local dropCmd;
    db_exist=$(isDb "${db_name}");
    ## 
    ## These outputs are defined in $(SRC_PAHT)/db/sql/create_triggers.sql
    ## So, this function is only valid for this CDB application.
    outputs=( "insert_item"  "update_item" "insert_item_element" "update_item_element" )
    if [[ $db_exist -ne "$EXIST" ]]; then
	    noDbMessage "${db_name}";
	    exit;
    else

        # shellcheck disable=SC2086
        printf "\n";
        for output in "${outputs[@]}"
        do
            dropCmd="$SQL_DBUSER_CMD";
            dropCmd+=" ";
            dropCmd+="${db_name}";
            dropCmd+=" ";
            dropCmd+="--execute=\"";
            # Ignore all table orders, drop all
            dropCmd+="DROP TRIGGER IF EXISTS ${output}"
            dropCmd+=";\"";
            printf ". %24s was found. Droping .... \n" "${output}"

	        commandPrn "$dropCmd"
            eval "${dropCmd}"
        done
    fi

}

function generate_admin_local_password
{
    local db_name="$1"; shift;
    local db_user_name="$1"; shift;
    local local_password="$1"; shift;
    local python_path="$1";shift;
    local db_exist;
    local python_cmd;
    
    local adminWithLocalPassword;

    db_exist=$(isDb "${db_name}");


    if [[ $db_exist -ne "$EXIST" ]]; then
	    noDbMessage "${db_name}";
	    exit;
    else
        adminWithLocalPassword=$(query_from_sql_file "${db_name}" "${ENV_TOP}/site-template/sql/check_cdb_admin.sql" -N)
        if [ -z "$adminWithLocalPassword" ]; then
            printf ">>> We've found there is the CDB admin user %s with a local password.\n" "$db_user_name"
            printf "    Updating ........ \n"
#           echo "$db_name, $db_user_name, $local_password, $python_path"
#            python_cmd="PYTHONPATH=${python_path} python -c \"from cdb.common.utility.cryptUtility import CryptUtility; print CryptUtility.cryptPasswordWithPbkdf2('${local_password}')\""
#            echo "$python_cmd"
            adminCryptPassword=$(get_admin_crypt_password  "${db_name}" "$local_password" "${python_path}")
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
    local db_exist;
    local python_cmd;
    
    local adminWithLocalPassword;

    db_exist=$(isDb "${db_name}");


    if [[ $db_exist -ne "$EXIST" ]]; then
	    noDbMessage "${db_name}";
	    exit;
    else
        python_cmd="PYTHONPATH=${python_path} python -c \"from cdb.common.utility.cryptUtility import CryptUtility; print CryptUtility.cryptPasswordWithPbkdf2('${local_password}')\""
        adminCryptPassword=$(eval "$python_cmd")
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



input="$1";
additional_input="$2"; 


case "$input" in
    secureSetup)
        # shellcheck disable=SC2153
    	mariadb_secure_setup "${DB_HOST_NAME}" "${DB_HOST_IPADDR}";
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
        remove_admin_account_local;
        ;;
    hostnameAdminRemove)
	    remove_admin_account_hostname "${DB_HOST_NAME}";
        ;;
    adminAdd)
	    # shellcheck disable=SC2153
        add_admin_account_local "${DB_ADMIN}" "${DB_ADMIN_PASS}";
	    ## shellcheck disable=SC2153
	    # add_admin_account_hostname "${DB_ADMIN}" "${DB_ADMIN_PASS}" "${DB_HOST_NAME}";
	    ;;
    adminRemove)
	    remove_admin_account_local;
	    #remove_admin_account_hostname "${DB_HOST_NAME}";
	    ;;
    dbCreate)
        # shellcheck disable=SC2153
        create_db_and_user "${DB_NAME}" "${DB_ADMIN_HOSTS}" "${DB_USER}" "${DB_USER_PASS}";
        ;;     
    dbShow)
        show_dbs;
        ;;
    dbDrop)
        drop_db_and_user "${DB_NAME}" "${DB_ADMIN_HOSTS}" "${DB_USER}";
        ;;  
    isDb)
        isDb "${DB_NAME}" "YES";
        ;;
    tableCreate)
        if [ -z "${additional_input}" ]; then
            additional_input="${ENV_TOP}/ComponentDB-src/db/sql/create_cdb_tables.sql"
        fi
        query_from_sql_file "${DB_NAME}" "${additional_input}";
        ;;    
    tableShow)
        show_tables "${DB_NAME}" "BASE TABLE";
        ;;
    tableDrop)
        drop_tables "${DB_NAME}" "BASE TABLE";
        ;; 
    viewCreate)
        if [ -z "${additional_input}" ]; then
            additional_input="${ENV_TOP}/ComponentDB-src/db/sql/create_views.sql"
        fi
        query_from_sql_file "${DB_NAME}" "${additional_input}";
        ;;
    viewShow)
        show_tables "${DB_NAME}" "VIEW";
        ;;
    viewDrop)
        drop_tables "${DB_NAME}" "VIEW";
        ;;
    sProcCreate)
        if [ -z "${additional_input}" ]; then
            additional_input="${ENV_TOP}/ComponentDB-src/db/sql/create_stored_procedures.sql"
        fi
        query_from_sql_file "${DB_NAME}" "${additional_input}";
        ;;
    sProcShow)
        show_procedures "${DB_NAME}";
        ;;
    sProcDrop)
        drop_procedures "${DB_NAME}";
        ;;
    triggersCreate)
        if [ -z "${additional_input}" ]; then
            additional_input="${ENV_TOP}/ComponentDB-src/db/sql/create_triggers.sql"
        fi
        query_from_sql_file "${DB_NAME}" "${additional_input}"
        ;;
    triggersShow)
        execute_query "${DB_NAME}" "show TRIGGERS;"
        ;;
    triggersDrop)
        drop_triggers "${DB_NAME}";
        ;;
    allCreate)
        input1="${ENV_TOP}/ComponentDB-src/db/sql/create_cdb_tables.sql"
        input2="${ENV_TOP}/ComponentDB-src/db/sql/create_views.sql"
        input3="${ENV_TOP}/ComponentDB-src/db/sql/create_stored_procedures.sql"
        query_from_sql_file "${DB_NAME}" "$input1"
        query_from_sql_file "${DB_NAME}" "$input2"
        query_from_sql_file "${DB_NAME}" "$input3"
        ;;
    allShow)
        show_tables "${DB_NAME}" "BASE TABLE";
        show_tables "${DB_NAME}" "VIEW";
        show_procedures "${DB_NAME}";
        ;;
    allDrop)
        drop_tables "${DB_NAME}" "BASE TABLE";  
        drop_tables "${DB_NAME}" "VIEW";
        drop_procedures "${DB_NAME}";
        ;;
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
            input_sql_file="${ENV_TOP}/site-template/sql/default_query.sql"
        fi
        query_from_sql_file "${DB_NAME}" "$input_sql_file" "$input_options" "$verbose"
        ;;
    querySFile)
        query_sql_file="${additional_input}"
        query_options="$3"
        if [ -z "${sql_file}" ]; then
             sql_file="${ENV_TOP}/site-template/sql/default_query.sql"
        fi
        query_from_sql_file "${DB_NAME}" "${query_sql_file}" "$query_options"
        ;;
    updateCDBAdminPassword)
        python_path="$additional_input"
        if [ -z "${python_path}" ]; then
             python_path="${ENV_TOP}/ComponentDB-src/src/python"
        fi
        generate_admin_local_password  "${DB_NAME}" "${CDB_USER}" "${CDB_USER_PASS}" "$python_path"
        ;;
    showAdminCryptPassword)
        get_admin_crypt_password  "${DB_NAME}" "$additional_input" "$3"
        ;;
    *)
        usage;
    ;;

esac
