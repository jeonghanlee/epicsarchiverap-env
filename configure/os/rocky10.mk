# Select the Rocky JDK default while preserving custom site paths.
ifeq ($(JAVA_HOME),/usr/lib/jvm/java-21-openjdk-amd64)
JAVA_HOME:=/usr/lib/jvm/java-21-openjdk
endif
