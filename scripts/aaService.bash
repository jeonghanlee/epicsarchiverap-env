#!/bin/bash
#
#  Copyright (c) 2016 - Present Jeong Han Lee
#  Copyright (c) 2016 - Present European Spallation Source ERIC
#
#  The program is free software: you can redistribute
#  it and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation, either version 2 of the
#  License, or any newer version.
#
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License along with
#  this program. If not, see https://www.gnu.org/licenses/gpl-2.0.txt
#
# Author : Jeong Han Lee
# email  : han.lee@esss.se
# Date   : 
# version : 0.9.8-rc0
#
# 
ROOT_UID=0  
E_NOTROOT=101

declare -gr SC_SCRIPT="$(realpath "$0")"
declare -gr SC_TOP="$(dirname "$SC_SCRIPT")"
declare -gr SC_LOGDATE="$(date +%Y%b%d-%H%M-%S%Z)"

# Enable core dumps in case the JVM fails
ulimit -c unlimited

declare hostname_cmd="$(hostname)"
export  _HOST_NAME="$(tr -d ' ' <<< $hostname_cmd )"
export  _HOST_IP="$(ip -4 route get 8.8.8.8 | awk {'print $7'} | tr -d '\n')";
export  _USER_NAME="$(whoami)"

# export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64


# # preAA.bash, aaBuild.bash, aaService.bash
# #
# export TOMCAT_HOME=/usr/share/tomcat9
# #
# # /usr/share/tomcat/lib is the symbolic link to /usr/share/java/tomcat
# #
# export TOMCAT_LIB=/usr/share/tomcat9/lib


# export EPICS_BASE_VER="7.0.4";
# export EPICS_BASE=${HOME}/epics-${EPICS_BASE_VER}
# export EPICS_HOST_ARCH=linux-x86_64

# # LD_LIBRARY_PATH should have the EPICS 
# export LD_LIBRARY_PATH=${EPICS_BASE}/lib/${EPICS_HOST_ARCH}:${LD_LIBRARY_PATH}
# export PATH=${EPICS_BASE}/bin/${EPICS_HOST_ARCH}:${PATH}

# export EPICS_CA_ADDR_LIST="127.0.0.1 ${_HOST_IP}";
# export EPICS_CA_AUTO_ADDR_LIST=yes;
# export EPICS_CA_SERVER_PORT=5064
# export EPICS_CA_REPEATER_PORT=5065

# export LD_LIBRARY_PATH=${TOMCAT_LIB}:${LD_LIBRARY_PATH}


# #export ARCHAPPL_APPLIANCES=/opt/epicsarchiverap/appliances.xml
# export ARCHAPPL_MYIDENTITY=appliance0

# export LD_LIBRARY_PATH=${ARCHAPPL_TOP}/engine/webapps/engine/WEB-INF/lib/native/${EPICS_HOST_ARCH}:${ARCHAPPL_TOP}/engine/webapps/engine/WEB-INF/lib:${LD_LIBRARY_PATH}


# ARCHAPPL_STORAGE_TOP=/ArchiverAppliance
# #
# # Set the location of short term and long term stores; this is necessary only if your policy demands it
# export ARCHAPPL_SHORT_TERM_FOLDER=${ARCHAPPL_STORAGE_TOP}/sts/ArchiverStore
# export ARCHAPPL_MEDIUM_TERM_FOLDER=${ARCHAPPL_STORAGE_TOP}/mts/ArchiverStore
# export ARCHAPPL_LONG_TERM_FOLDER=${ARCHAPPL_STORAGE_TOP}/lts/ArchiverStore


AA_TARGET_TOP=/opt
ARCHAPPL_TOP=${AA_TARGET_TOP}/epicsarchiverap


function pushd() { builtin pushd "$@" > /dev/null; }
function popd()  { builtin popd  "$@" > /dev/null; }


function getHostname() {

    local hostname_cmd="$(hostname)";
    
}


function get_ip_address() {
    
    ip -4 route get 8.8.8.8 | awk {'print $7'} | tr -d '\n'
    
}

function get_pid
{
    local  SERVICE_TOP=$1;
    local  SERVICE_NAME=$2;
    local  pid;
    
    pid=$(cat ${SERVICE_TOP}/${SERVICE_NAME}/temp/${SERVICE_NAME}.pid)

    printf "%12s : %6d is running or exist\n" "${SERVICE_NAME}" "$pid"
}


function all_pids
{
    # Stopping order is matter! 
    get_pid "${ARCHAPPL_TOP}" "engine";
    get_pid "${ARCHAPPL_TOP}" "retrieval";
    get_pid "${ARCHAPPL_TOP}" "etl";
    get_pid "${ARCHAPPL_TOP}" "mgmt";
    
}


function startTomcatAtLocation
{

    if [ $# -eq 0 ]; then
	printf "startTomcatAtLocation called without any arguments\n";
	exit 1;
    fi

    local SERVICE_TOP=$1;
    local SERVICE_NAME=$2;
    local catalina_base=${SERVICE_TOP}/${SERVICE_NAME};
    
    echo ""
    echo ">> Starting ${SERVICE_NAME} at ${catalina_base}"

    pushd "${catalina_base}";
    rm -rf temp/${SERVICE_NAME}.pid
    sh bin/startup.sh
    popd
    

    echo ""
}


function stopTomcatAtLocation
{
    if [ $# -eq 0 ]; then
	printf "stopTomcatAtLocation called without any arguments\n";
	exit 1;
    fi
    
    local SERVICE_TOP=$1;
    local SERVICE_NAME=$2;
    local catalina_base=${SERVICE_TOP}/${SERVICE_NAME};
    
    echo ""
    echo ">> Stopping ${SERVICE_NAME} at ${catalina_base}"
    sudo /usr/bin/jsvc \
	 -stop \
	 -pidfile ${SERVICE_TOP}/${SERVICE_NAME}/temp/${SERVICE_NAME}.pid \
	 org.apache.catalina.startup.Bootstrap
    echo ""
}

# Service order is matter, don't change them
tomcat_services=("mgmt" "engine" "etl" "retrieval")


function status
{

    printf "\n>>>> EPICS Env outputs\n";
    printf "     EPICS_BASE %s\n" "${EPICS_BASE}";
    printf "     LD_LIBRARY_PATH %s\n" "${LD_LIBRARY_PATH}";
    printf "     EPICS_CA_ADDR_LIST %s\n" "${EPICS_CA_ADDR_LIST}";
    printf "\n";
    printf ">>>> Status outputs \n" ;
    printf "   > Web url \n";
    printf "     http://%s:17665/mgmt/ui/index.html\n" "${_HOST_NAME}";
    printf "                         OR\n";
    printf "     http://%s:17665/mgmt/ui/index.html\n" "${_HOST_IP}";
    
    printf "\n";
    printf "   > Log \n";
    printf "     %s/mgmt/logs/mgmt_catalina.err may help you.\n" "${ARCHAPPL_TOP}";
    printf "     tail -f %s/mgmt/logs/mgmt_catalina.err\n" "${ARCHAPPL_TOP}";
    printf "     tail -f %s/mgmt/archiverappliance.log\n" "${ARCHAPPL_TOP}";

    printf "\n";

    printf "All java process\n";
    ps aux |grep java| grep -v "grep" | awk ' {print $2} '
    
    printf "\nTomcat9 process\n";
    ps aux |grep 'catalina.base=/usr/share/tomcat9' | grep -v "grep" | awk ' {print $2} '
    printf "\nArchiver Appliance PIDs\n"
    
    all_pids
    
    printf "\n";
 
}



function stroage_status
{
    local all=$1
    printf "\n>>>> Stroage Status at %s\n\n" "${SC_LOGDATE}";
    du --total --human-readable --time --${all} ${ARCHAPPL_STORAGE_TOP};
    printf "\n";

}


function stop
{

 
    # Stopping order is matter! 
    stopTomcatAtLocation "${ARCHAPPL_TOP}" "engine";
    stopTomcatAtLocation "${ARCHAPPL_TOP}" "retrieval";
    stopTomcatAtLocation "${ARCHAPPL_TOP}" "etl";
    stopTomcatAtLocation "${ARCHAPPL_TOP}" "mgmt";

    status;

}


function start
{ 
    
    for service in ${tomcat_services[@]}; do
	startTomcatAtLocation "${ARCHAPPL_TOP}" "${service}";
    done

    status;
}


case "$1" in
    start)
	start
	;;
    stop)
	stop
	;;
    restart)
	stop
	start
	;;
    status)
	status
	;;
    stroage)
	case "$2" in
	    all) 
		stroage_status "$2"
		;;
	    *)
		stroage_status 
		;;
	esac
	;;
    *)
	echo "Usage: $0 {start|stop|restart|status|stroage}"
	exit 2
esac


