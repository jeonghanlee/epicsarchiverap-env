#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  date    : Sunday, June 28 00:20:35 PDT 2020
#  version : 0.0.2


function usage
{
    {
	echo "";
	echo "Usage    : $0 [-o JAVA\_OPTIONS] "
	echo "";
	echo "               -o : additional JVM Options"
	echo "";
	echo " bash $0 -o \"-Xms512m -Xmx512m\""
	echo ""
    } 1>&2;
    exit 1;
}




JAR=$(find "${CF_INSTALL_LOCATION}" -name "ChannelFinder*.jar")

options="o:"

while getopts "${options}" opt; do
    case "${opt}" in
        o) JAVA_OPTS=${OPTARG}      ;;
   	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    usage
	    ;;
	h)
	    usage
	    ;;
	\?)
	    echo "Invalid option: -$OPTARG" >&2
	    usage
	    ;;
    esac
done
shift $((OPTIND-1))


# Debian, openjdk is located in /usr/bin/
#
command="/usr/bin/java ${JAVA_OPTS} -jar $JAR"
eval "$command"
