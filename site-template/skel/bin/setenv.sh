#!/bin/sh
#

CATALINA_HOME=/usr/share/tomcat9

# Find the Java runtime and set JAVA_HOME
. /usr/libexec/tomcat9/tomcat-locate-java.sh

# Default Java options
if [ -z "$JAVA_OPTS" ]; then
	JAVA_OPTS="-Djava.awt.headless=true"
fi
