#!/bin/bash
#
#  Copyright (c) 2016 - 2020 Jeong Han Lee
#  Copyright (c) 2016 - 2017 European Spallation Source ERIC
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
# email  : jeonghan.lee@gmail.com
# 

#declare -g SC_SCRIPT;
#declare -g SC_SCRIPTNAME;
#declare -g SC_TOP;
declare -g SC_LOGDATE;

#SC_SCRIPT="$(realpath "$0")";
#SC_SCRIPTNAME=${0##*/};
#SC_TOP="${SC_SCRIPT%/*}"
SC_LOGDATE="$(date +%y%m%d%H%M)"

# Enable core dumps in case the JVM fails
ulimit -c unlimited

declare hostname_cmd=""
hostname_cmd=$(hostname)
_HOST_NAME="$(tr -d ' ' <<< "$hostname_cmd" )"
_HOST_IP="$(ip -4 route get 8.8.8.8 | awk \{'print $7'\} | tr -d '\n')";

export  _HOST_NAME
export  _HOST_IP


AA_TARGET_TOP=/opt
ARCHAPPL_TOP=${AA_TARGET_TOP}/epicsarchiverap


function pushdd { builtin pushd "$@" > /dev/null || exit; }
function popdd  { builtin popd  > /dev/null || exit; }


function getHostname
{
    local hostname_cmd="";
    hostname_cmd=$(hostname);
}


function get_ip_address 
{
    ip -4 route get 8.8.8.8 | awk \{'print $7'\} | tr -d '\n'
}

function get_pid
{
    local  SERVICE_TOP=$1;
    local  SERVICE_NAME=$2;
    local  pid;
    pid=$(cat "${SERVICE_TOP}/${SERVICE_NAME}/temp/${SERVICE_NAME}.pid")
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

    pushdd "${catalina_base}" 
    rm -rf temp/"${SERVICE_NAME}.pid"
    sh bin/startup.sh
    popdd
    
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
	 -pidfile "${SERVICE_TOP}/${SERVICE_NAME}/temp/${SERVICE_NAME}.pid" \
	 org.apache.catalina.startup.Bootstrap
    echo ""
}

# Service order is matter, don't change them
tomcat_services=("mgmt" "engine" "etl" "retrieval")


function status
{

#    printf "\n>>>> EPICS Env outputs\n";
#    printf "     EPICS_BASE %s\n" "${EPICS_BASE}";
#    printf "     LD_LIBRARY_PATH %s\n" "${LD_LIBRARY_PATH}";
#    printf "     EPICS_CA_ADDR_LIST %s\n" "${EPICS_CA_ADDR_LIST}";
#    printf "\n";
    printf ">>>> Status outputs \n" ;
    printf "   > Web url \n";
    printf "     http://%s:17665/mgmt/ui/index.html\n" "${_HOST_NAME}";
    printf "                         OR\n";
    printf "     http://%s:17665/mgmt/ui/index.html\n" "${_HOST_IP}";
    printf "                         OR\n";
    printf "     http://%s:17665/mgmt/ui/index.html\n" "localhost";
    
    printf "\n";
    printf "   > Logs \n";
    printf "     tail -f %s/mgmt/logs/archappl_service.log\n"      "${ARCHAPPL_TOP}";
    printf "     tail -f %s/engine/logs/archappl_service.log\n"    "${ARCHAPPL_TOP}";
    printf "     tail -f %s/etl/logs/archappl_service.log\n"       "${ARCHAPPL_TOP}";
    printf "     tail -f %s/retrieval/logs/archappl_service.log\n" "${ARCHAPPL_TOP}";

 
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
    du --total --human-readable --time --"${all}" "${ARCHAPPL_STORAGE_TOP}";
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
    for service in "${tomcat_services[@]}"; do
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
	        all) stroage_status "$2" ;;
	    *)       stroage_status      ;;
	    esac
	    ;;
    *)
	echo "Usage: $0 {start|stop|restart|status|stroage}"
	exit 2
esac
