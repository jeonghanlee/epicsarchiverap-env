#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  date    : Monday, June 29 14:02:20 PDT 2020
#  version : 0.0.1


declare -g SC_SCRIPT;
#declare -g SC_SCRIPTNAME;
declare -g SC_TOP;
#declare -g LOGDATE;

SC_SCRIPT="$(realpath "$0")";
#SC_SCRIPTNAME=${0##*/};
SC_TOP="${SC_SCRIPT%/*}"
#LOGDATE="$(date +%y%m%d%H%M)"

function pushd { builtin pushd "$@" > /dev/null || exit; }
function popd  { builtin popd  > /dev/null || exit; }

function find_dist
{

    local dist_id dist_cn dist_rs PRETTY_NAME
    
    if [[ -f /usr/bin/lsb_release ]] ; then
     	dist_id=$(lsb_release -is)
     	dist_cn=$(lsb_release -cs)
     	dist_rs=$(lsb_release -rs)
     	echo "$dist_id" "${dist_cn}" "${dist_rs}"
    else
        #shellcheck disable=SC2046 disable=SC2002
     	eval $(cat /etc/os-release | grep -E "^(PRETTY_NAME)=")
	    echo "${PRETTY_NAME}"
    fi
}


function define_python_path
{
    local pythonpath="$1"
    echo "PYTHONPATH=${pythonpath}" > "${SC_TOP}/.sourceme"
    echo "export PYTHONPATH"       >> "${SC_TOP}/.sourceme"
    chmod +x "${SC_TOP}/.sourceme"
    
}

function debian10_pkgs
{
    ## Debian 10
    apt update -y
    apt install -y \
    	wget \
        curl \
    	git \
    	sed \
        gawk \
        unzip \
        make \
        gcc \
    	mariadb-server \
        mariadb-client  \
        libmariadbclient-dlibmariadb-dev\
        maven \
        ant \
        tomcat9 \
        tomcat9-common \
        tomcat9-admin \
        tomcat9-user \
        libtomcat9-java \
        jsvc \
        unzip \
        chrony 
    
    ln -sf "$(which mariadb_config)" /usr/bin/mysql_config
    # MySQL-python-1.2.5 doesn't work with mariadb 
    # https://lists.launchpad.net/maria-developers/msg10744.html
    # https://github.com/DefectDojo/django-DefectDojo/issues/407

    if [ ! -f /usr/include/mariadb/mysql.h.bkp ]; then
        sed '/st_mysql_options options;/a unsigned int reconnect;' /usr/include/mariadb/mysql.h -i.bkp
    fi

}


function debian11_pkgs
{
    ## Debian 11
    apt update -y
    apt install -y \
    	wget \
        curl \
    	git \
    	sed \
        gawk \
        unzip \
        make \
        gcc \
    	mariadb-server \
        mariadb-client  \
        libmariadb-dev \
        libmariadb-dev-compat \
        maven \
        ant \
        tomcat9 \
        tomcat9-common \
        tomcat9-admin \
        tomcat9-user \
        libtomcat9-java \
        jsvc \
        unzip \
        chrony 
    
    ln -sf "$(which mariadb_config)" /usr/bin/mysql_config
    # MySQL-python-1.2.5 doesn't work with mariadb 
    # https://lists.launchpad.net/maria-developers/msg10744.html
    # https://github.com/DefectDojo/django-DefectDojo/issues/407

    if [ ! -f /usr/include/mariadb/mysql.h.bkp ]; then
        sed '/st_mysql_options options;/a unsigned int reconnect;' /usr/include/mariadb/mysql.h -i.bkp
    fi

}

function rocky8_pkgs
{
    dnf -y install dnf-plugins-core;
    dnf update -y;
    dnf config-manager --set-enabled powertools
    dnf update -y;
    dnf install -y epel-release;
    dnf update -y;
    dnf install -y gcc libgcc wget sudo git unzip curl make tree sed which\
        java-11-openjdk ant \
        mariadb-server \
        chrony
    echo 2 | update-alternatives --config java
}


dist="$(find_dist)"

echo "$dist"


case "$dist" in
    *buster*)   debian10_pkgs ;;
    *bullseye*) debian11_pkgs ;;
#    *CentOS*) echo "Use Rocky, don't support CentOS" ;;
    *Rocky*)  rocky8_pkgs ;;
#    *RedHat*) centos_pkgs ;;
    *)
	printf "\\n";
	printf "Doesn't support the detected %s\\n" "$dist";
	printf "Please contact jeonghan.lee@gmail.com\\n";
	printf "\\n";
	;;
esac

exit;
#define_python_path "$1"
