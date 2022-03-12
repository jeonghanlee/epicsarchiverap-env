#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.3


declare -g SC_RPATH;
#declare -g SC_NAME;
declare -g SC_TOP;
declare -g SC_TIME;

SC_RPATH="$(realpath "$0")";
#SC_NAME=${0##*/};
SC_TOP="${SC_RPATH%/*}"
SC_TIME="$(date +%y%m%d%H%M)"


# epicsarchiver-env will put the global archiver configuration file in /opt/epicsarchiver, where
# this script will be located. 
# JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
# JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom"
# CATALINA_HOME="/usr/share/tomcat9"
# CATALINA_OPTS="-XX:MaxMetaspaceSize=256m -Xms512m -Xmx512m -XX:+UseG1GC -ea"
# ARCHAPPL_APPLIANCES="/opt/epicsarchiverap/appliances.xml"
# ARCHAPPL_POLICIES="/opt/epicsarchiverap/policies.py"
# ARCHAPPL_PROPERTIES_FILENAME="/opt/epicsarchiverap/archappl.properties"
# ARCHAPPL_MYIDENTITY="appliance0"
# ARCHAPPL_STORAGE_TOP="/arch"
# ARCHAPPL_SHORT_TERM_FOLDER="/arch/sts/ArchiverStore"
# ARCHAPPL_MEDIUM_TERM_FOLDER="/arch/mts/ArchiverStore"
# ARCHAPPL_LONG_TERM_FOLDER="/arch/lts/ArchiverStore"

set -a
# shellcheck disable=SC1091,SC1090
. "${SC_TOP}/archappl.conf"
set +a

# Enable core dumps in case the JVM fails
ulimit -c unlimited

# shutdown_services is not the same as startup_services
# Order is matter. Please don't change their order.
startup_services=("mgmt" "engine" "etl" "retrieval")
shutdown_services=("engine" "retrieval" "etl" "mgmt")

function pushdd { builtin pushd "$@" > /dev/null || exit; }
function popdd  { builtin popd  > /dev/null || exit; }

function get_ip
{
    ip -4 route get 8.8.8.8 | awk \{'print $7'\} | tr -d '\n'
}

# 1 : Archappl installation path : /opt/epicsarchiver
# 2 : Service name : one of mgmt, engine, etl, retrieval
function get_pid
{
    local  archappl_top="$1";shift;
    local  name="$1";shift;
    local  pid;
    pid=$(cat "${archappl_top}/${name}/temp/${name}.pid")
    printf "%12s : pid %6d exists.\n" "${name}" "$pid"
}

# shellcheck disable=SC2120
function startup_archappl
{
    local archappl_top="$1";shift;

    if [ -z "$archappl_top" ]; then
	    archappl_top="${SC_TOP}"
    fi

    # shutdown_services is not the same as startup_services
    # Order is matter
    for service in "${startup_services[@]}"; do
        pushdd "${archappl_top}/${service}"
        rm -rf "temp/${service}.pid"
        bash bin/startup.sh
        popdd
    done
}

# shellcheck disable=SC2120
function shutdown_archappl
{
    local archappl_top="$1";shift;

    if [ -z "$archappl_top" ]; then
	    archappl_top="${SC_TOP}"
    fi

    # shutdown_services is not the same as startup_services
    # Order is matter
    for service in "${shutdown_services[@]}"; do
        pushdd "${archappl_top}/${service}"
        bash bin/shutdown.sh
        rm -rf "temp/${service}.pid"
        popdd
    done  
}

# shellcheck disable=SC2120
function jsvc_shutdown_archappl
{
    local archappl_top="$1";shift;

    if [ -z "$archappl_top" ]; then
	    archappl_top="${SC_TOP}"
    fi

    # Does tomcat user can shutdown all without sudo?
    for service in "${startup_services[@]}"; do
        "${JAVA_HOME}"/bin/jsvc -stop -pidfile "${archappl_top}/${service}/temp/${service}.pid" org.apache.catalina.startup.Bootstrap
 #      sudo "${JAVA_HOME}"/bin/jsvc -stop -pidfile "${archappl_top}/${service}/temp/${service}.pid" org.apache.catalina.startup.Bootstrap
    done  
}

# shellcheck disable=SC2120
function status_archappl
{

    local archappl_top="$1";shift;

    if [ -z "$archappl_top" ]; then
	    archappl_top="${SC_TOP}"
    fi

    local ip_addr="";
    ip_addr=$(get_ip);

    printf ">>> Current Time %s\n" "${SC_TIME}"
    printf ">>> Archiver Appliance Status"
    printf "    http://%s:17665/mgmt/ui/index.html\n" "${HOSTNAME}";
    printf "                        OR\n";
    printf "    http://%s:17665/mgmt/ui/index.html\n" "${ip_addr}";
    printf "                         OR\n";
    printf "    http://%s:17665/mgmt/ui/index.html\n" "localhost";
    
    printf "\n";
    printf ">>> Consult Service Logs \n";
    
    for service in "${startup_services[@]}"; do
        printf "  tail -f %s/%s/logs/archappl_service.log\n" "${archappl_top}" "${service}";
    done  

    printf ">>> Service PIDs \n"
    printf "    All Tomcat processes\n";
    pgrep 'org.apache.catalina.startup.Bootstrap'
    printf "    Archiver Appliance PIDs\n"
    for service in "${startup_services[@]}"; do
        get_pid "${archappl_top}" "${service}";
    done  
    printf "\n";
}


function status_storage
{
    local all=$1; shift;
    printf "\n>>>> Storage Status at %s\n\n" "${SC_TIME}";
    # ARCHAPPL_STORAGE_TOP is defined in archappl.conf
    if [[ $OSTYPE == 'darwin'* ]]; then
        sudo du -c -h -a "${ARCHAPPL_STORAGE_TOP}"
    else
        sudo -E bash -c "du --total --human-readable --time --\"${all}\" \"${ARCHAPPL_STORAGE_TOP}\"";
    fi
    printf "\n";
}

function usage
{
    {
        echo "";
        echo "Usage    : $0  args"
        echo "";
        echo "              possbile args";
        echo "";
        echo "               startup   : startup all services in order";
        echo "               shutdown  : shutdown all services in order ";
        echo "               restartup : shutdown and startup";
        echo "               storage   : show the storage status";
        echo "               status    : show summary for status";      
        echo "               h         : this screen";
        echo "";
        echo " bash $0 startup "
        echo ""
    } 1>&2;
    exit 1;
}



case "$1" in
    startup)
	    startup_archappl
	    ;;
    shutdown)
	    shutdown_archappl
	    ;;
    restart)
	    startup_archappl
	    shutdown_archappl
	    ;;
    status)
	    status_archappl 
	    ;;
    storage)
	    case "$2" in
	        all) status_storage "$2" ;;
	    *)       status_storage      ;;
	    esac
	    ;;
    h);;
    help)
        usage;
        ;;
    *)
	    usage;
    ;;
esac

