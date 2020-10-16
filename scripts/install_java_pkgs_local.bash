#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.1


declare -g SC_SCRIPT;
#declare -g SC_SCRIPTNAME;
declare -g SC_TOP;
#declare -g LOGDATE;

SC_SCRIPT="$(realpath "$0")";
#SC_SCRIPTNAME=${0##*/};
SC_TOP="${SC_SCRIPT%/*}"
#LOGDATE="$(date +%y%m%d%H%M)"

ENV_TOP="${SC_TOP}/.."


# 11 GA (build 11+28)
# https://jdk.java.net/archive/
OPENJDK11_SRC="openjdk-11_linux-x64_bin.tar.gz"
OPENJDK11_URL="https://download.java.net/java/ga/jdk11/${OPENJDK11_SRC}"

#JULUJDK11_SRC="zulu11.41.23-ca-jdk11.0.8-linux_musl_x64.tar.gz"
#JULUJDK11_URL="https://cdn.azul.com/zulu/bin/${JULUJDK11_SRC}"

OPENJDK12_SRC="openjdk-12_linux-x64_bin.tar.gz"
OPENJDK12_URL="https://download.java.net/java/GA/jdk12/33/GPL/${OPENJDK12_SRC}"
# https://download.java.net/java/GA/jdk12/33/GPL/openjdk-12_linux-x64_bin.tar.gz

MAVEN_VER=3.6.3
MAVEN_SRC="apache-maven-${MAVEN_VER}-bin.tar.gz"
MAVEN_URL="https://downloads.apache.org/maven/maven-3/${MAVEN_VER}/binaries/${MAVEN_SRC}"

ANT_VER=1.10.9
ANT_SRC="apache-ant-${ANT_VER}-bin.tar.gz"
ANT_URL="https://archive.apache.org/dist/ant/binaries/${ANT_SRC}"

JDBC_VER=2.3.0
JDBC_SRC="mariadb-java-client-${JDBC_VER}.jar"
JDBC_URL="https://downloads.mariadb.com/Connectors/java/connector-java-${JDBC_VER}/${JDBC_SRC}"


function pushd { builtin pushd "$@" > /dev/null || exit; }
function popd  { builtin popd  > /dev/null || exit; }


## http://ant.apache.org/bindownload.cgi
## https://maven.apache.org/download.cgi

function usage
{
    {
	echo "";
	echo "Usage    : $0 <pkg> <dest>";
	echo "";
    echo "          <pkg>";
	echo "";
	echo "          ant     : ant     ${ANT_VER}";
    echo "          maven   : maven   ${MAVEN_VER}";
    echo "          jdk11   : openjdk 11";
    echo "          jdk12   : openjdk 12"
    echo "";
    echo "          <dest>";
   	echo "";
	echo "           ""     : ${SC_TOP}/JAVA";
    echo ""
    } 1>&2;
    exit 1;
}


pkg="$1"
dest="$2"

if [ -z "${dest}" ]; then
    # shellcheck disable=SC2086
    dest="$(realpath ${ENV_TOP}/JAVA)";
    mkdir -p "${dest}"
fi


function vars
{
    printf ">>>  Makefile Rules for Local JAVA\n\n"
    printf "MAVEN_HOME:=\$(TOP)/JAVA/maven\n" 
    printf "ANT_HOME:=\$(TOP)/JAVA/ant\n" 
    printf "JAVA_HOME:=\$(TOP)/JAVA/openjdk_your_install_version\n\n\n" 

}

case "$pkg" in
    ant)
        wget -qc "$ANT_URL"
        rm -rf "$dest/apache-ant-*"
        tar -C "${dest}" -xzf ${ANT_SRC}
        rm -f "$dest/ant"
        ln -sf "$dest/apache-ant-${ANT_VER}" "$dest/ant"
        tree -L 1 "${dest}"
        ;;
    maven)
        wget -qc "$MAVEN_URL"
        rm -rf "$dest/apache-maven-*"
        tar -C "${dest}" -xzf ${MAVEN_SRC}
        rm -f "$dest/maven"
        ln -sf "$dest/apache-maven-${MAVEN_VER}" "$dest/maven"
        tree -L 1 "${dest}"
        ;;
    jdk11)
        wget -qc "$OPENJDK11_URL"
        rm -rf "$dest/jdk-11"
        tar -C "${dest}" -xzf ${OPENJDK11_SRC}
        rm -f "$dest/openjdk11"
        ln -sf "$dest/jdk-11" "$dest/openjdk11"
        tree -L 1 "${dest}"
        ;;
    jdk12)
        wget -qc "$OPENJDK12_URL"
        rm -rf "$dest/jdk-12"
        tar -C "${dest}" -xzf ${OPENJDK12_SRC}
        rm -f "$dest/openjdk12"
        ln -sf "$dest/jdk-12" "$dest/openjdk12"
        tree -L 1 "${dest}"
        ;;
    jdbc)
        wget -qc "$JDBC_URL"
        ;;
    vars)
        vars;
        ;;
    *)
        usage;
    ;;

esac

