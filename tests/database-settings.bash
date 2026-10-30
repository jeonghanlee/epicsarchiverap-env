#!/usr/bin/env bash
# Resolve real Make settings and call the shipped helper against a missing socket.
set -euo pipefail
command -v mysql >/dev/null || { printf 'SKIP: database-settings requires the real mysql client\n'; exit 77; }
TOP=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd)
WORK=$(mktemp -d /tmp/aa-database-settings.XXXXXXXX)
CHECKOUT=$WORK/checkout
mkdir "$CHECKOUT"
cp -a "$TOP/Makefile" "$TOP/configure" "$TOP/scripts" "$TOP/site-template" "$CHECKOUT/"
printf 'Evidence: %s\n' "$WORK"
printf 'DB_BACKEND := mariadb\nDB_NAME := parent_identity\nDB_SOCKET := %s/missing.sock\n' "$WORK" > "$WORK/CONFIG_SITE.local"
printf 'DB_NAME := child_identity\n' > "$CHECKOUT/configure/CONFIG_SITE.local"
TESTS=0

function expect_failure {
    local expected=$1 message=$2 rc=0
    shift 2
    "$@" > "$WORK/stdout" 2> "$WORK/stderr" || rc=$?
    [[ $rc == "$expected" ]] && grep -Fq "$message" "$WORK/stderr" || {
        printf 'FAIL: expected exit=%s message=%s, got exit=%s\n' "$expected" "$message" "$rc" >&2
        cat "$WORK/stderr" >&2; exit 1;
    }
    TESTS=$((TESTS + 1))
}

function helper { bash -p "$CHECKOUT/scripts/mariadb_setup.bash" "$@"; }
function make_db { make -C "$CHECKOUT" --no-print-directory -s "$@"; }

make_db db.conf
expect_failure 2 'Cannot check the database >> child_identity' helper isDb
expect_failure 2 'Settings changed; run make db.conf' env DB_NAME=parent_identity bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
expect_failure 2 'Settings changed; run make db.conf' env DB_SOCKET= bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
expect_failure 2 'Settings changed; run make db.conf' env DB_HOST_NAME=192.0.2.1 bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
expect_failure 2 'Settings changed; run make db.conf' env DB_HOST_PORT=1 bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
expect_failure 2 'Settings changed; run make db.conf' env DB_NAME= bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
expect_failure 2 'Settings changed; run make db.conf' make_db sql.show DB_NAME=command_identity
make_db db.conf DB_NAME=command_identity
expect_failure 2 'Cannot check the database >> command_identity' env DB_NAME=command_identity bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
expect_failure 2 'Settings changed; run make db.conf' helper isDb
touch -r "$CHECKOUT/site-template/mariadb.conf" "$WORK/config.timestamp"
printf 'DB_NAME := timestamp_identity\n' > "$CHECKOUT/configure/CONFIG_SITE.local"
touch -r "$WORK/config.timestamp" "$CHECKOUT/configure/CONFIG_SITE.local"
expect_failure 2 'Settings changed; run make db.conf' helper isDb

# Raw environment values are not re-evaluated as Make or shell expressions.
password='spaces $HOME $(touch INJECTED) `touch INJECTED` # quote '\''" & ;'
make_password=${password//\$/\$\$}
make_db db.conf "DB_USER_PASS=$make_password" "DB_ADMIN_PASS=$make_password"
expect_failure 2 'Cannot check the database >> timestamp_identity' env DB_USER_PASS="$password" DB_ADMIN_PASS="$password" bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
[[ ! -e $CHECKOUT/INJECTED && ! -e $TOP/INJECTED ]]
# Shell configuration identity must not depend on the caller's locale.
locale_password=$'locale\303\251'
for generation in C C.UTF-8; do
    LC_ALL=$generation make_db db.conf "DB_USER_PASS=$locale_password"
    for execution in C C.UTF-8; do
        expect_failure 2 'Cannot check the database >> timestamp_identity' env LC_ALL="$execution" DB_USER_PASS="$locale_password" bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
        expect_failure 2 'Settings changed; run make db.conf' env LC_ALL="$execution" DB_USER_PASS="${locale_password}changed" bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
    done
done
make_db db.conf DB_USER_PASS= DB_ADMIN_PASS=
expect_failure 2 'Cannot check the database >> timestamp_identity' env DB_USER_PASS= DB_ADMIN_PASS= bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
printf 'touch "%s/CONFIG_EXECUTED"\n' "$WORK" > "$CHECKOUT/site-template/mariadb.conf"
expect_failure 2 'run make db.conf' helper dbShow
[[ ! -e $WORK/CONFIG_EXECUTED ]]
for action in queryFile querySFile; do
    for value in '--host=DO_NOT_PRINT' '-N --password=DO_NOT_PRINT' '-NB' 'other_database' '--force'; do
        expect_failure 2 'Unsupported query output option' helper "$action" /missing "$value"
        if grep -q DO_NOT_PRINT "$WORK/stderr"; then printf 'Credential leaked\n' >&2; exit 1; fi
    done
done
printf 'PASS: database settings (%s assertions); evidence=%s\n' "$TESTS" "$WORK"
