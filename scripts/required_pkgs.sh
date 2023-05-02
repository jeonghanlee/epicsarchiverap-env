#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  date    : Sat Oct 30 22:21:16 PDT 2021
#  version : 0.0.3


declare -g SC_SCRIPT;
#declare -g SC_SCRIPTNAME;
declare -g SC_TOP;
#declare -g LOGDATE;

SC_SCRIPT="${BASH_SOURCE[0]:-${0}}";
#SC_SCRIPTNAME=${0##*/};
#SC_TOP="${SC_SCRIPT%/*}"
SC_TOP="$( cd -P "$( dirname "$SC_SCRIPT" )" && pwd )"

#LOGDATE="$(date +%y%m%d%H%M)"

function pushd { builtin pushd "$@" > /dev/null || exit; }
function popd  { builtin popd  > /dev/null || exit; }

function centos_dist
{
    local VERSION_ID
    # shellcheck disable=SC2046 disable=SC2002
    eval $(cat /etc/os-release | grep -E "^(VERSION_ID)=")
    # shellcheck disable=SC2086
    echo ${VERSION_ID}
}

function find_dist
{

    local dist_id dist_cn dist_rs PRETTY_NAME
    local name version

    if [[ $OSTYPE == 'darwin'* ]]; then
        name=$(sw_vers -productName)
        version=$(sw_vers -productVersion)
        echo "$name" "$version"
    else
        if [[ -f /usr/bin/lsb_release ]] ; then
     	    dist_id=$(lsb_release -is)
     	    dist_cn=$(lsb_release -cs)
     	    dist_rs=$(lsb_release -rs)
     	    echo "$dist_id" "${dist_cn}" "${dist_rs}"
        else 
            # shellcheck disable=SC2046 disable=SC2002
     	    eval $(cat /etc/os-release | grep -E "^(PRETTY_NAME)=")
            # shellcheck disable=SC2086
            echo "${PRETTY_NAME}"
        fi
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
    apt install -y wget \
                   curl \
    	           git \
    	           sed \
                   gawk \
                   unzip \
                   make \
                   gcc \
                   tree \
    	           mariadb-server \
                   mariadb-client  \
                   libmariadbclient-dev \
                   libmariadb-dev \
                   openjdk-11-jdk \
                   ant \
                   tomcat9 \
                   tomcat9-common \
                   tomcat9-admin \
                   tomcat9-user \
                   libtomcat9-java \
                   jsvc \
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
    apt install -y wget \
                   curl \
    	           git \
    	           sed \
                   gawk \
                   unzip \
                   make \
                   gcc \
                   tree \
    	           mariadb-server \
                   mariadb-client  \
                   libmariadb-dev \
                   libmariadb-dev-compat \
                   openjdk-17-jdk \
                   ant \
                   tomcat9 \
                   tomcat9-common \
                   tomcat9-admin \
                   tomcat9-user \
                   libtomcat9-java \
                   jsvc \
                   chrony 
    
    ln -sf "$(which mariadb_config)" /usr/bin/mysql_config
    # MySQL-python-1.2.5 doesn't work with mariadb 
    # https://lists.launchpad.net/maria-developers/msg10744.html
    # https://github.com/DefectDojo/django-DefectDojo/issues/407

    if [ ! -f /usr/include/mariadb/mysql.h.bkp ]; then
        sed '/st_mysql_options options;/a unsigned int reconnect;' /usr/include/mariadb/mysql.h -i.bkp
    fi
}

function centos7_pkgs
{
    yum update -y;
    yum install -y epel-release;
    yum update -y;
    yum install -y gcc \
                   libgcc \
                   wget \
                   sudo \
                   git \
                   unzip \
                   curl \
                   make \
                   tree \
                   sed \
                   which \
                   java-11-openjdk \
                   ant \
                   mariadb-server \
                   chrony

    echo 2 | update-alternatives --config java
}

function rocky8_pkgs
{
    dnf -y install dnf-plugins-core;
    dnf update -y;
    dnf config-manager --set-enabled powertools
    dnf update -y;
    dnf install -y epel-release;
    dnf update -y;
    dnf install -y gcc \
                   libgcc \
                   wget \
                   sudo \
                   git \
                   unzip \
                   curl \
                   make \
                   tree \
                   sed \
                   which \
                   java-17-openjdk \
                   ant \
                   mariadb-server \
                   chrony

    echo 2 | update-alternatives --config java
}


function macos_pkgs
{
    if command -v brew &> /dev/null
    then
	brew install tree wget unzip mariadb ant nmap openjdk@17
 
    elif command -v port &> /dev/null
    then
	echo "Port"
	exit
	sudo port install openjdk17-zulu \
        	        tree \
               	    wget \
                    unzip \
                    curl \
                    mariadb-10.5 \
                    mariadb-10.5-server \
                    apache-ant \
                    nmap
    else
	echo "Please install port or brew first";
	exit
    fi
}

dist="$(find_dist)"

echo "$dist"

case "$dist" in
    *buster*)   debian10_pkgs ;;
    *bullseye*) debian11_pkgs ;;
    *CentOS* | *Scientific* ) 
        centos_version=$(centos_dist)
        if [ "$centos_version" == "7" ]; then
            centos7_pkgs
        elif [ "$centos_version" == "8" ]; then
            rocky8_pkgs
        else
	    printf "\\n";
	    printf "Sorry, we don't support CentOS anymore\\n";
	    printf "Please use Rocky or other variant\\n";
	    printf "\\n";
        fi
        ;;
    *Rocky*) rocky8_pkgs ;;
    *macOS*) macos_pkgs ;;
    *)
	printf "\\n";
	printf "Doesn't support the detected %s\\n" "$dist";
	printf "Please contact jeonghan.lee@gmail.com\\n";
	printf "\\n";
	;;
esac

exit;
