#!/bin/bash -p
# Replace one instance's exploded WAR and logging JARs from prepared artifacts.
set -euo pipefail
if [[ $EUID -eq 0 && ! -o privileged ]]; then
    printf '%s\n' 'Run this installer with bash -p.' >&2
    exit 2
fi
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
unset BASH_ENV ENV CDPATH UNZIP UNZIPOPT ZIPINFO ZIPINFOOPT
umask 022

function die {
    printf 'Payload install failed: %s\n' "$1" >&2
    exit 1
}

[[ $# -eq 4 ]] || die 'Expected instance directory, service, WAR directory and log4j directory.'
instance=$1
service=$2
war_dir=$3
jar_dir=$4
case $service in
    mgmt|engine|etl|retrieval) ;;
    *) die 'Unknown appliance service.' ;;
esac
[[ $instance == /* && $instance != / ]] || die 'Instance directory must be an absolute non-root path.'
[[ -d $instance && ! -L $instance ]] || die 'Instance directory must exist and must not be a symlink.'
instance=$(realpath -e -- "$instance")
[[ $instance != / ]] || die 'Instance directory resolves to the filesystem root.'
for target in "$instance/webapps" "$instance/webapps/$service" "$instance/log4j"; do
    [[ ! -L $target && ( ! -e $target || -d $target ) ]] || die "Expected a real directory: $target"
done
shopt -s nullglob
wars=("$war_dir/"*"$service.war")
jars=("$jar_dir/"*.jar)
[[ ${#wars[@]} -eq 1 ]] || die 'Expected exactly one WAR for the service; clean and rebuild the source.'
[[ ${#jars[@]} -gt 0 ]] || die 'Missing Tomcat log4j JARs; build the source first.'
[[ -s ${wars[0]} && -r ${wars[0]} ]] || die 'WAR is empty or unreadable.'
for jar in "${jars[@]}"; do
    [[ -f $jar && -s $jar && -r $jar ]] || die "JAR is missing, empty or unreadable: $jar"
done

stage=$(mktemp -d "$instance/.payload.XXXXXXXX")
war_replacing=0
jars_replacing=0
function cleanup {
    local rc=$?
    local restore_failed=0
    trap - EXIT
    if [[ $rc -ne 0 ]]; then
        if [[ $war_replacing -eq 1 ]]; then
            if [[ -d $stage/old-webapp ]]; then
                rm -rf -- "$instance/webapps/$service" || restore_failed=1
                mv -- "$stage/old-webapp" "$instance/webapps/$service" || restore_failed=1
            elif [[ ! -d $stage/webapp ]]; then
                rm -rf -- "$instance/webapps/$service" || restore_failed=1
            fi
        fi
        if [[ $jars_replacing -eq 1 ]]; then
            if [[ -d $stage/old-log4j ]]; then
                rm -rf -- "$instance/log4j" || restore_failed=1
                mv -- "$stage/old-log4j" "$instance/log4j" || restore_failed=1
            elif [[ ! -d $stage/log4j ]]; then
                rm -rf -- "$instance/log4j" || restore_failed=1
            fi
        fi
    fi
    if [[ $restore_failed -eq 0 ]]; then
        rm -rf -- "$stage"
    else
        printf 'Restore failed; retained payload backup: %s\n' "$stage" >&2
    fi
    exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

mkdir -p -- "$stage/webapp" "$stage/log4j"
unzip -q "${wars[0]}" -d "$stage/webapp"
[[ -s $stage/webapp/WEB-INF/web.xml ]] || die 'WAR has no WEB-INF/web.xml.'
# Preserve logging configuration and other non-JAR files outside the WAR.
if [[ -d $instance/log4j ]]; then
    cp -a -- "$instance/log4j/." "$stage/log4j/"
fi
old_jars=("$stage/log4j/"*.jar)
if [[ ${#old_jars[@]} -gt 0 ]]; then
    rm -f -- "${old_jars[@]}"
fi
install -m 644 -- "${jars[@]}" "$stage/log4j/"
mkdir -p -- "$instance/webapps"
war_replacing=1
if [[ -d $instance/webapps/$service ]]; then
    mv -- "$instance/webapps/$service" "$stage/old-webapp"
fi
mv -- "$stage/webapp" "$instance/webapps/$service"
jars_replacing=1
if [[ -d $instance/log4j ]]; then
    mv -- "$instance/log4j" "$stage/old-log4j"
fi
mv -- "$stage/log4j" "$instance/log4j"
printf 'Installed fresh %s WAR and %d Tomcat logging JARs.\n' "$service" "${#jars[@]}"
