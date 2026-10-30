#!/bin/bash -p
# Real database checks on an explicitly disposable systemd host. Evidence stays.
set -euo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
umask 022
TOP=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd)
MODE=${1:-}
SOURCE=${2:-$TOP/epicsarchiverap-maven-src}
[[ $EUID == 0 && ${AA_TEST_DISPOSABLE_HOST:-} == YES ]] || {
    printf '%s\n' 'Requires root and AA_TEST_DISPOSABLE_HOST=YES on a disposable systemd guest.' >&2; exit 2;
}
case $MODE in sqlite|mariadb-uds|mariadb-tcp) ;; *) printf '%s\n' 'Select sqlite, mariadb-uds or mariadb-tcp.' >&2; exit 2 ;; esac
systemctl show --property=Version >/dev/null
WORK=$(mktemp -d /tmp/aa-database-test.XXXXXXXX)
chmod 0755 "$WORK"
printf 'Evidence: %s\n' "$WORK"
exec > >(tee "$WORK/run.log") 2>&1
mkdir "$WORK/checkout" "$WORK/data"
cp -a "$TOP/Makefile" "$TOP/configure" "$TOP/scripts" "$TOP/site-template" "$WORK/checkout/"
if ! id aa-db-test >/dev/null 2>&1; then useradd --system --user-group --no-create-home aa-db-test; fi
chown aa-db-test:aa-db-test "$WORK/data"
chmod 0700 "$WORK/data"
CHECKOUT=$WORK/checkout
CONFIG=$CHECKOUT/configure/CONFIG_SITE.local
DB_FILE=$WORK/data/selected.sqlite
DB_NAME=aa_m1_${WORK##*.}
DB_USER=aa_m1_user
DB_PASS=M1DisposableValue
TESTS=0
OTHER_DATABASE=${DB_NAME}_other
OTHER_SQLITE=$WORK/data/unselected.sqlite

function cleanup {
    local rc=$?
    printf 'Result: exit=%s assertions=%s evidence=%s\n' "$rc" "$TESTS" "$WORK"
}
trap cleanup EXIT

function equal {
    [[ $1 == "$2" ]] || { printf 'FAIL: %s (expected=%s actual=%s)\n' "$3" "$2" "$1"; exit 1; }
    TESTS=$((TESTS + 1))
    printf 'PASS: %s\n' "$3"
}

function expect_status {
    local expected=$1 rc=0
    shift
    "$@" >"$WORK/last.stdout" 2>"$WORK/last.stderr" || rc=$?
    equal "$rc" "$expected" "$* exit"
}

function make_db { make -C "$CHECKOUT" --no-print-directory -s "$@"; }
function helper { bash -p "$CHECKOUT/scripts/mariadb_setup.bash" "$@"; }
function sql { helper query "$1"; }
function scalar {
    if [[ $MODE == sqlite ]]; then
        runuser -u aa-db-test -- sqlite3 -batch -noheader "$DB_FILE" "$1"
    else
        mysql --no-defaults "${CONNECT[@]}" -u "$DB_USER" "--password=$DB_PASS" -N -B "$DB_NAME" -e "$1"
    fi
}

printf 'SRC_PATH := %s\n' "$SOURCE" > "$CHECKOUT/configure/CONFIG_VARS.local"
printf '%s\n' 'AA_USERID := aa-db-test' 'AA_GROUPID := aa-db-test' \
    'APPNAME := aa-m1-maintenance' "ARCHAPPL_SQLITE_FILE := $DB_FILE" \
    "DB_NAME := $DB_NAME" "DB_USER := $DB_USER" "DB_USER_PASS := $DB_PASS" \
    'DB_ADMIN := aa_m1_admin' "DB_ADMIN_PASS := $DB_PASS" > "$CONFIG"
CONNECT=()
if [[ $MODE == sqlite ]]; then
    printf '%s\n' 'DB_BACKEND := sqlite' >> "$CONFIG"
    make_db db.conf db.conf.show
    for target in db.secure db.addAdmin db.rmAdmin; do expect_status 2 make_db "$target"; done
    for action in secureSetup localAdminAdd hostnameAdminAdd localAdminRemove hostnameAdminRemove adminAdd adminRemove userDrop dbUserCreate dbUserDrop; do expect_status 2 helper "$action"; done
else
    systemctl start mariadb.service
    DB_SOCKET=$(mysql --no-defaults -u root -N -B -e 'SELECT @@socket;')
    DB_PORT=$(mysql --no-defaults -u root -N -B -e 'SELECT @@port;')
    printf '%s\n' 'DB_BACKEND := mariadb' "DB_HOST_PORT := $DB_PORT" 'DB_HOST_NAME := 127.0.0.1' >> "$CONFIG"
    if [[ $MODE == mariadb-uds ]]; then
        printf 'DB_SOCKET := %s\n' "$DB_SOCKET" >> "$CONFIG"
        CONNECT=(--protocol=socket "--socket=$DB_SOCKET")
    else
        printf '%s\n' 'DB_SOCKET :=' >> "$CONFIG"
        CONNECT=(--protocol=tcp --host=127.0.0.1 "--port=$DB_PORT")
    fi
    make_db db.conf
    helper localAdminAdd
    helper hostnameAdminAdd
    make_db db.conf.show > "$WORK/client-config.txt"
    chmod 0600 "$WORK/client-config.txt"
    make_db db.secure
    helper localAdminRemove
    make_db db.addAdmin
fi

# The selected database must not alter either a second same-backend database
# or the unselected backend. Both fixtures use the real shipped schemas.
systemctl start mariadb.service
mysql --no-defaults -u root -e "CREATE DATABASE $OTHER_DATABASE;"
mysql --no-defaults -u root "$OTHER_DATABASE" < "$SOURCE/src/main/org/epics/archiverappliance/config/persistence/archappl_mysql.sql"
mysql --no-defaults -u root "$OTHER_DATABASE" -e "INSERT INTO ExternalDataServers(serverid,serverinfo) VALUES('unselected MariaDB','{}');"
runuser -u aa-db-test -- sqlite3 "$OTHER_SQLITE" < "$SOURCE/src/main/org/epics/archiverappliance/config/persistence/archappl_sqlite.sql"
runuser -u aa-db-test -- sqlite3 "$OTHER_SQLITE" "INSERT INTO ExternalDataServers(serverid,serverinfo) VALUES('unselected SQLite','{}');"
function snapshot_others {
    sha256sum "$OTHER_SQLITE"
    mysqldump --no-defaults -u root --compact --skip-comments --skip-lock-tables "$OTHER_DATABASE" | sha256sum
}
snapshot_others > "$WORK/unselected.before"
if [[ $MODE == sqlite ]]; then
    expect_status 2 env DB_BACKEND=mariadb bash -p "$CHECKOUT/scripts/mariadb_setup.bash" aaShow ExternalDataServers
    grep -q 'db.conf' "$WORK/last.stderr"
else
    output=$(env DB_BACKEND=sqlite ARCHAPPL_SQLITE_FILE="$OTHER_SQLITE" bash -p "$CHECKOUT/scripts/mariadb_setup.bash" aaShow ExternalDataServers)
    [[ $output == *'unselected SQLite' ]] || { printf 'Backend override selected the wrong file\n'; exit 1; }
    printf 'PASS: explicit SQLite backend override selects its own shipped-schema fixture\n'
fi
snapshot_others > "$WORK/unselected.after-switch"
cmp "$WORK/unselected.before" "$WORK/unselected.after-switch"

ALL_ACTIONS=(secureSetup localAdminAdd hostnameAdminAdd localAdminRemove hostnameAdminRemove adminAdd adminRemove userDrop dbUserCreate dbUserDrop dbCreate dbDrop dbShow isDb tableShow tableDrop aaShow query queryFile querySFile dbBackup dbBackupList dbRestore addProject updateCDBAdminPassword showAdminCryptPassword)
for action in "${ALL_ACTIONS[@]}"; do
    expect_status 2 env DB_BACKEND=invalid bash -p "$CHECKOUT/scripts/mariadb_setup.bash" "$action"
done
for backend in invalid '' 'mariadb sqlite'; do
    expect_status 2 env DB_BACKEND="$backend" bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
done
for action in addProject updateCDBAdminPassword showAdminCryptPassword; do expect_status 2 helper "$action"; done
expect_status 2 helper dbShow unexpected
expect_status 2 helper dbRestore
expect_status 2 helper queryFile /missing '' MAYBE
expect_status 2 helper queryFile /missing '' NO extra
expect_status 2 helper queryFile /missing '--password=DO_NOT_PRINT'
if grep -q DO_NOT_PRINT "$WORK/last.stderr"; then printf 'Credential leaked\n'; exit 1; fi

expect_status 1 helper isDb
helper dbCreate
helper isDb
helper dbDrop
expect_status 1 helper isDb
make_db db.create
helper isDb
make_db db.show
make_db sql.fill
make_db sql.fill
sql 'DROP TABLE PVAliases;'
make_db sql.fill
make_db sql.show
make_db sql.update.show > "$WORK/rendered-schema.txt"
equal "$(scalar "SELECT count(*) FROM PVTypeInfo;")" 0 'empty shipped table'
make_db PVTypeInfo.show
helper aaShow
output=$(helper query)
if [[ $MODE == sqlite ]]; then
    [[ $output == *PVTypeInfo* ]] || { printf 'Default SQLite query omitted the shipped table\n'; exit 1; }
    expect_status 2 helper queryFile
else
    [[ $output == *"$DB_NAME"* ]] || { printf 'Default MariaDB query omitted the selected database\n'; exit 1; }
    helper queryFile > "$WORK/default-file-query.txt"
    grep -Fq "$DB_NAME" "$WORK/default-file-query.txt"
fi
expect_status 1 helper aaShow MissingTable
cat > "$WORK/rows.sql" <<'SQL'
INSERT INTO PVTypeInfo(pvName,typeInfoJSON) VALUES('type with spaces','{}');
INSERT INTO PVAliases(pvName,realName) VALUES('alias with spaces','type with spaces');
INSERT INTO ArchivePVRequests(pvName,userParams) VALUES('request with spaces','{}');
INSERT INTO ExternalDataServers(serverid,serverinfo) VALUES('server with spaces','{}');
SQL
helper querySFile "$WORK/rows.sql"
for pair in 'PVTypeInfo:type' 'PVAliases:alias' 'PVRequests:request' 'DataServers:server'; do
    target=${pair%:*}; marker=${pair#*:}
    output=$(make_db "$target.show")
    [[ $output == *"$marker with spaces" ]] || { printf 'Incomplete identifier: %s\n' "$output"; exit 1; }
    TESTS=$((TESTS + 1))
done
if [[ $MODE == sqlite ]]; then
    before=$(scalar "SELECT last_modified FROM PVTypeInfo;")
    sleep 2
    sql "UPDATE PVTypeInfo SET typeInfoJSON='{\"test\":true}';"
    after=$(scalar "SELECT last_modified FROM PVTypeInfo;")
    [[ $before != "$after" ]] || exit 1
    equal "$(stat -c '%a' "$DB_FILE")" 600 'database mode'
fi

helper dbBackup
helper dbBackupList > "$WORK/backups.list"
if [[ $MODE == sqlite ]]; then
    backup_name=$(cat "$WORK/backups.list")
    stamp=${backup_name#selected.sqlite_}; stamp=${stamp%.sqlite3}
    expect_status 2 helper dbRestore "$stamp"
    sql 'DELETE FROM PVTypeInfo;'
    make_db db.drop
    expect_status 1 helper isDb
    helper dbBackupList > "$WORK/backups-after-drop.list"
    cmp "$WORK/backups.list" "$WORK/backups-after-drop.list"
    helper dbRestore "$stamp"
    equal "$(scalar 'SELECT pvName FROM PVTypeInfo;')" 'type with spaces' 'restored row'
else
    backup_path=$CHECKOUT/${DB_NAME}_sql_backup
    archives=("$backup_path/${DB_NAME}_"*.sql.gz)
    stamp=${archives[0]##*/}; stamp=${stamp#"${DB_NAME}_"}; stamp=${stamp%.sql.gz}
    sql 'DELETE FROM PVTypeInfo;'
    helper dbRestore "$stamp"
    equal "$(scalar 'SELECT pvName FROM PVTypeInfo;')" 'type with spaces' 'restored row'
    printf 'SELECT serverid FROM ExternalDataServers;\n' > "$WORK/output.sql"
    for flag in '' -N --skip-column-names -B --batch -r --raw -t --table; do
        for action in queryFile querySFile; do
            helper "$action" "$WORK/output.sql" "$flag" > "$WORK/format-${action}-${flag:1}.txt"
            output=$(cat "$WORK/format-${action}-${flag:1}.txt")
            case $flag in
                -N|--skip-column-names) equal "$output" 'server with spaces' 'headerless query output' ;;
                -t|--table) grep -q '^| serverid' "$WORK/format-${action}-${flag:1}.txt"; grep -q '^+' "$WORK/format-${action}-${flag:1}.txt" ;;
                *) equal "$output" $'serverid\nserver with spaces' 'native batch query output' ;;
            esac
        done
    done
    # General-log connection rows establish that rejection precedes isDb.
    mysql --no-defaults -u root -e "SET GLOBAL log_output='TABLE'; SET GLOBAL general_log=ON;"
    before=$(mysql --no-defaults -u root -N -B -e "SELECT count(*) FROM mysql.general_log WHERE command_type='Connect' AND user_host LIKE '[aa_m1%';")
    helper query 'SELECT 1;' > "$WORK/log-positive-control.txt"
    after=$(mysql --no-defaults -u root -N -B -e "SELECT count(*) FROM mysql.general_log WHERE command_type='Connect' AND user_host LIKE '[aa_m1%';")
    [[ $after -gt $before ]] || { printf 'Connection log did not observe the positive control\n'; exit 1; }
    printf 'PASS: connection log observes real helper connections (%s -> %s)\n' "$before" "$after"
    for action in queryFile querySFile; do
    for bad in '--host=other' '-hother' '--socket=/other' '-S/other' '--user=other' '-uother' '--password=DO_NOT_PRINT' '-pDO_NOT_PRINT' '--database=other' '-Dother' '--defaults-file=/other' '--execute=DELETE' '-eDELETE' '--force' '--hos=other' '-NB' other '-N --port=2'; do
        before=$(mysql --no-defaults -u root -N -B -e "SELECT count(*) FROM mysql.general_log WHERE command_type='Connect' AND user_host LIKE '[aa_m1%';")
        expect_status 2 helper "$action" "$WORK/output.sql" "$bad"
        after=$(mysql --no-defaults -u root -N -B -e "SELECT count(*) FROM mysql.general_log WHERE command_type='Connect' AND user_host LIKE '[aa_m1%';")
        equal "$after" "$before" 'forbidden option made no connection'
    done
    done
    mysql --no-defaults -u root -e 'SET GLOBAL general_log=OFF;'
    expect_status 2 env DB_NAME=other bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
    expect_status 2 env DB_SOCKET=/missing bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
    make_db db.conf "DB_SOCKET=$WORK/missing.sock"
    expect_status 2 env DB_SOCKET="$WORK/missing.sock" bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
    grep -q 'Cannot check the database' "$WORK/last.stderr"
    expect_status 1 env DB_SOCKET="$WORK/missing.sock" bash -p "$CHECKOUT/scripts/mariadb_setup.bash" dbCreate
    grep -q 'Creating the database' "$WORK/last.stderr"
    make_db db.conf
    # Resolve identical non-ASCII settings across generation/execution locales.
    locale_password=$'locale\303\251'
    for generation in C C.UTF-8; do
        LC_ALL=$generation make_db db.conf "DB_USER_PASS=$locale_password"
        for execution in C C.UTF-8; do
            expect_status 0 env LC_ALL="$execution" DB_USER_PASS="$locale_password" bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
            expect_status 2 env LC_ALL="$execution" DB_USER_PASS="${locale_password}changed" bash -p "$CHECKOUT/scripts/mariadb_setup.bash" isDb
            grep -q 'Settings changed; run make db.conf' "$WORK/last.stderr"
        done
    done
    make_db db.conf
    printf 'corrupt gzip\n' > "$backup_path/${DB_NAME}_0000000000.sql.gz"
    expect_status 1 helper dbRestore 0000000000
    equal "$(scalar 'SELECT pvName FROM PVTypeInfo;')" 'type with spaces' 'invalid gzip leaves database unchanged'
fi

if [[ $MODE == sqlite ]]; then
    # shellcheck source=tests/lib/database-sqlite-cases.bash
    source "$TOP/tests/lib/database-sqlite-cases.bash"
    sqlite_failure_cases
fi

for target in sql.drop sql.table.drop; do
    sql 'CREATE TABLE `extra quoted`` table` (id INTEGER PRIMARY KEY); CREATE TABLE child_table (id INTEGER, FOREIGN KEY(id) REFERENCES `extra quoted`` table`(id));'
    for entry in helper make; do
        if [[ $entry == helper ]]; then output=$(helper tableShow); else output=$(make_db sql.show); fi
        [[ $output == *'extra quoted` table'* ]] || { printf 'Incomplete table name: %s\n' "$output"; exit 1; }
        TESTS=$((TESTS + 1))
        printf 'PASS: %s table listing preserves spaces and backticks\n' "$entry"
    done
    if [[ $MODE == sqlite ]]; then
        sql 'CREATE VIRTUAL TABLE documents USING fts5(content); INSERT INTO documents(content) VALUES("search fixture");'
    fi
    make_db "$target"
    snapshot_others > "$WORK/unselected.after"
    cmp "$WORK/unselected.before" "$WORK/unselected.after"
    if [[ $MODE == sqlite ]]; then
        equal "$(scalar "SELECT count(*) FROM sqlite_master WHERE type='table' AND name NOT GLOB 'sqlite_*';")" 0 'all user tables removed'
    else
        equal "$(scalar "SELECT count(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';")" 0 'all user tables removed'
    fi
    equal "$(helper tableShow)" '' 'empty table listing'
    helper isDb
    make_db sql.fill
    helper queryFile "$WORK/rows.sql"
done

systemd-run --unit=aa-m1-maintenance --property=Type=exec /bin/sleep 120
expect_status 2 helper tableDrop
helper aaShow PVTypeInfo
equal "$(systemctl is-active aa-m1-maintenance.service)" active 'helper left active service unchanged'
systemctl stop aa-m1-maintenance.service
make_db db.drop
snapshot_others > "$WORK/unselected.after"
cmp "$WORK/unselected.before" "$WORK/unselected.after"
expect_status 1 helper isDb
if [[ $MODE != sqlite ]]; then
    helper hostnameAdminRemove
    make_db db.rmAdmin
fi
printf 'PASS: database operations %s\n' "$MODE"
