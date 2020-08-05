#!/bin/bash
#  Copyright (c) 2016 Jeong Han Lee
#  Copyright (c) 2016 European Spallation Source ERIC
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
# version : 0.1.4

export THIS_SCRIPT=$(realpath "$0")
export THIS_TOP="$(dirname "$THIS_SCRIPT")"


# Hostname is not reliable to use it in the appliances.xml, so force to get the running
# IP, and use it into... need to change them by other demands

declare hostname_cmd="$(hostname)"
export  _HOST_NAME="$(tr -d ' ' <<< $hostname_cmd )"
export  _HOST_IP="$(ip -4 route get 8.8.8.8 | awk {'print $7'} | tr -d '\n')";
export  _USER_NAME="$(whoami)"


export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
# preAA.bash, aaBuild.bash, aaService.bash
#
export TOMCAT_HOME=/usr/share/tomcat9
#
# /usr/share/tomcat/lib is the symbolic link to /usr/share/java/tomcat
#
export TOMCAT_LIB=${TOMCAT_HOME}/lib



# We assume that we inherit the EPICS environment variables 
# This includes setting up the LD_LIBRARY_PATH to include the JCA .so file.
# EPICS BASE is installed in the local directory

export EPICS_BASE_VER="7.0.4";
export EPICS_BASE=/home/jhlee/epics-${EPICS_BASE_VER}
export EPICS_HOST_ARCH=linux-x86_64

# LD_LIBRARY_PATH should have the EPICS 
export LD_LIBRARY_PATH=${EPICS_BASE}/lib/${EPICS_HOST_ARCH}:${LD_LIBRARY_PATH}
export PATH=${EPICS_BASE}/bin/${EPICS_HOST_ARCH}:${PATH}

export EPICS_CA_ADDR_LIST="127.0.0.1 ${_HOST_IP}";
export EPICS_CA_AUTO_ADDR_LIST=yes;
export EPICS_CA_SERVER_PORT=5064
export EPICS_CA_REPEATER_PORT=5065


if [ -f ${HOME}/.bashrc_local ]; then
# Overwrite EPICS_CA_ADDR_LIST and others...
# 
    . ${HOME}/.bashrc_local
fi

export EPICS_CA_ADDR_LIST=
export EPICS_CA_AUTO_ADDR_LIST=auto


# Tomcat lib 
export LD_LIBRARY_PATH=${TOMCAT_LIB}:${LD_LIBRARY_PATH}

export AA_GIT_URL="https://github.com/slacmshankar";
export AA_GIT_NAME="epicsarchiverap";
export AA_GIT_DIR=${THIS_TOP}/${AA_GIT_NAME};

# aaSetup, aaService
export AA_TARGET_TOP=/opt
export ARCHAPPL_TOP=${AA_TARGET_TOP}/epicsarchiverap

export LD_LIBRARY_PATH=${ARCHAPPL_TOP}/engine/webapps/engine/WEB-INF/lib/native/${EPICS_HOST_ARCH}:${ARCHAPPL_TOP}/engine/webapps/engine/WEB-INF/lib:${LD_LIBRARY_PATH}


# Tomcat user
TOMCAT_USER="tomcat"
TOMCAT_GROUP=${TOMCAT_USER}
TOMCAT_USER_HOME=${ARCHAPPL_TOP}/temp

# # Use an in memory persistence layer
# export ARCHAPPL_PERSISTENCE_LAYER=org.epics.archiverappliance.config.persistence.InMemoryPersistence

# # Tell the appliance that we are deploying all the components in one VM.
# # This reduces the thread count and other parameters in an effort to optimize memory.
#export ARCHAPPL_ALL_APPS_ON_ONE_JVM="true"

#
# This approach is only valid for the single appliance installation.
# If one wants to install multiple appliances, appliances.xml should
# has the different structures. 
#
export AACHAPPL_SINGLE_IDENTITY="appliance0"
export APPLIANCES_XML="appliances.xml";
# The following variables are defined in archappl.
# Do not change other names
export ARCHAPPL_APPLIANCES=${ARCHAPPL_TOP}/${APPLIANCES_XML};
export ARCHAPPL_MYIDENTITY=${AACHAPPL_SINGLE_IDENTITY};


export SITE_POLICIES_FILE="policies.py";
export ARCHAPPL_POLICIES=${ARCHAPPL_TOP}/${SITE_POLICIES_FILE}


export SITE_PROPERTIES_FILE="archappl.properties";
export ARCHAPPL_PROPERTIES_FILENAME=${ARCHAPPL_TOP}/${SITE_PROPERTIES_FILE}

# Archiever Appliance User and Password for DB
# One should change the the default AA user password properly. 
export DB_USER_NAME="archappl";
export DB_USER_PWD="archappl";
export DB_NAME="archappl";

# The physical memory  :  64G, so I use 8G instead of 4G, since we don't have any other application on the server.
# Set MaxMetaspaceSize : 256M, so it reduces the GC execution to compare with the original option.
# 
export JAVA_HEAPSIZE="512M"
export JAVA_MAXMETASPACE="256M"
export JAVA_OPTS="-XX:MaxMetaspaceSize=${JAVA_MAXMETASPACE} -XX:+UseG1GC -Xms${JAVA_HEAPSIZE} -Xmx${JAVA_HEAPSIZE} -ea"



# It might be better to assign the proper directory, while the installating CentOS.
# Anyway, /home has the most of space, so I created
# Make tmpfs for the short term storage by editing /etc/fstab file.
#  For 10G file size add this line: 
# tmpfs    /srv/sts 		tmpfs 	defaults,size=10g 0 0 
# preAA.bash 
# aaService.bash

declare ARCHAPPL_STORAGE_TOP=/ArchiverAppliance/
#
# Set the location of short term and long term stores; this is necessary only if your policy demands it
export ARCHAPPL_SHORT_TERM_FOLDER=${ARCHAPPL_STORAGE_TOP}/sts/ArchiverStore
export ARCHAPPL_MEDIUM_TERM_FOLDER=${ARCHAPPL_STORAGE_TOP}/mts/ArchiverStore
export ARCHAPPL_LONG_TERM_FOLDER=${ARCHAPPL_STORAGE_TOP}/lts/ArchiverStore
