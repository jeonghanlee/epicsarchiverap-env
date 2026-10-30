# Additional real-client failure cases for database-operations.bash.

function sqlite_writer_start {
    local file=$1 statement=$2 count
    WRITER_FIFO=$WORK/data/writer.fifo
    WRITER_PID_FILE=$WORK/data/writer.pid
    WRITER_READY=$WORK/data/writer.ready
    rm -f -- "$WRITER_FIFO" "$WRITER_PID_FILE" "$WRITER_READY"
    mkfifo -m 0600 "$WRITER_FIFO"
    chown aa-db-test:aa-db-test "$WRITER_FIFO"
    exec {WRITER_INPUT}<>"$WRITER_FIFO"
    runuser -u aa-db-test -- bash -c 'printf "%s\n" "$BASHPID" > "$3"; exec sqlite3 -init /dev/null -batch -bail "$1" < "$2"' \
        _ "$file" "$WRITER_FIFO" "$WRITER_PID_FILE" > "$WORK/writer.log" 2>&1 &
    WRITER_PARENT=$!
    printf '%s\n.shell touch %s\n' "$statement" "$WRITER_READY" >&"$WRITER_INPUT"
    for ((count=0; count<100; count++)); do
        [[ ! -f $WRITER_READY ]] || return 0
        sleep 0.05
    done
    printf 'Writer did not become ready\n' >&2
    return 1
}

function sqlite_writer_stop {
    local signal=${1:-TERM} pid
    pid=$(cat "$WRITER_PID_FILE")
    kill -"$signal" "$pid"
    wait "$WRITER_PARENT" || true
    exec {WRITER_INPUT}>&-
}

function sqlite_failure_cases {
    local original checksum stamp file rc start elapsed i child lock_hash lock_ready column
    local -a reserved=()
    systemd-run --unit=aa-m1-maintenance-health --on-active=120 /bin/true
    expect_status 2 helper dbDrop
    grep -q 'health.timer' "$WORK/last.stderr"
    equal "$(systemctl is-active aa-m1-maintenance-health.timer)" active 'helper left health timer unchanged'
    systemctl stop aa-m1-maintenance-health.timer
    expect_status 2 unshare --mount --propagation private bash -p -c 'mount -t tmpfs tmpfs /run; mkdir /run/lock; exec bash -p "$1" dbDrop' _ "$CHECKOUT/scripts/mariadb_setup.bash"
    grep -q 'Cannot inspect service state' "$WORK/last.stderr"
    mkdir -m 0755 "$WORK/root-parent"
    expect_status 0 env ARCHAPPL_SQLITE_FILE="$WORK/root-parent/new/db.sqlite" bash -p "$CHECKOUT/scripts/mariadb_setup.bash" dbCreate
    equal "$(stat -c '%U:%G:%a' "$WORK/root-parent")" root:root:755 'existing parent remains unchanged'
    equal "$(stat -c '%U:%G:%a' "$WORK/root-parent/new")" aa-db-test:aa-db-test:700 'new database directory is private'
    equal "$(stat -c '%U:%G:%a' "$WORK/root-parent/new/db.sqlite")" aa-db-test:aa-db-test:600 'new file has service ownership'
    original=$(sha256sum "$DB_FILE")
    for file in corrupt wrong-owner symlink empty; do
        case $file in
            corrupt) printf 'invalid SQLite content\n' > "$WORK/data/$file"; chown aa-db-test:aa-db-test "$WORK/data/$file" ;;
            wrong-owner) cp "$DB_FILE" "$WORK/data/$file" ;;
            symlink) ln -s "$DB_FILE" "$WORK/data/$file" ;;
            empty) touch "$WORK/data/$file"; chown aa-db-test:aa-db-test "$WORK/data/$file" ;;
        esac
        checksum=$(sha256sum "$WORK/data/$file")
        expect_status 2 env ARCHAPPL_SQLITE_FILE="$WORK/data/$file" bash -p "$CHECKOUT/scripts/mariadb_setup.bash" dbShow
        equal "$(sha256sum "$WORK/data/$file")" "$checksum" "read failure preserves $file"
    done
    equal "$(sha256sum "$DB_FILE")" "$original" 'failed reads preserve selected database'
    printf 'orphan\n' > "$WORK/data/orphan-wal"
    expect_status 2 env ARCHAPPL_SQLITE_FILE="$WORK/data/orphan" bash -p "$CHECKOUT/scripts/mariadb_setup.bash" dbDrop
    equal "$(cat "$WORK/data/orphan-wal")" orphan 'orphan WAL retained'
    mkdir -m 000 "$WORK/data/denied"
    expect_status 2 helper dbBackup "$WORK/data/denied"
    equal "$(stat -c %a "$WORK/data/denied")" 0 'existing directory permissions retained'

    sqlite_writer_start "$DB_FILE" "PRAGMA journal_mode=WAL; INSERT INTO ExternalDataServers(serverid,serverinfo) VALUES('retained WAL','{}');"
    expect_status 2 helper dbBackup "$WORK/data/live-backup"
    grep -q 'Open SQLite files' "$WORK/last.stderr"
    [[ -s $DB_FILE-wal ]] || { printf 'No real WAL present\n'; return 1; }
    sqlite_writer_stop KILL
    [[ -s $DB_FILE-wal ]] || { printf 'No retained WAL after writer exit\n'; return 1; }
    helper dbBackup "$WORK/data/wal-backup" > "$WORK/wal-backup.path"
    file=$(cat "$WORK/wal-backup.path")
    equal "$(runuser -u aa-db-test -- sqlite3 -readonly "$file" "SELECT serverid FROM ExternalDataServers WHERE serverid='retained WAL';")" 'retained WAL' 'backup includes committed WAL content'
    equal "$(runuser -u aa-db-test -- sqlite3 -readonly "$file" 'PRAGMA journal_mode;')" delete 'backup is self-contained'
    mkdir "$WORK/data/collisions"
    chown aa-db-test:aa-db-test "$WORK/data/collisions"
    # Reserve a bounded real-time filename window; no clock or client substitute.
    for i in {0..45}; do
        stamp=$(date -u -d "+$i seconds" +%Y%m%dT%H%M%SZ)
        file=$WORK/data/collisions/selected.sqlite_${stamp}.sqlite3
        printf 'preserved\n' > "$file"
        reserved+=("$file")
    done
    sha256sum "${reserved[@]}" > "$WORK/collisions.before"
    expect_status 1 helper dbBackup "$WORK/data/collisions"
    sha256sum "${reserved[@]}" > "$WORK/collisions.after"
    cmp "$WORK/collisions.before" "$WORK/collisions.after"

    lock_hash=$(printf '%s' "$DB_FILE" | sha256sum); lock_hash=${lock_hash%% *}
    lock_ready=$WORK/lock.ready
    flock -F "/run/lock/epicsarchiverap-database/$lock_hash.lock" bash -c 'touch "$1"; exec sleep 15' _ "$lock_ready" &
    child=$!
    for i in {1..100}; do [[ ! -f $lock_ready ]] || break; sleep 0.05; done
    start=$SECONDS
    expect_status 2 helper dbShow
    elapsed=$((SECONDS - start))
    kill "$child"; wait "$child" || true
    [[ $elapsed -ge 4 && $elapsed -le 9 ]] || { printf 'Helper lock deadline: %s\n' "$elapsed"; return 1; }
    printf 'PASS: helper lock wait bounded (%s seconds)\n' "$elapsed"

    runuser -u aa-db-test -- sqlite3 "$WORK/data/busy.sqlite" 'CREATE TABLE busy_marker (value INTEGER);'
    sqlite_writer_start "$WORK/data/busy.sqlite" 'BEGIN EXCLUSIVE; INSERT INTO busy_marker VALUES(1);'
    printf "ATTACH '%s' AS busy; INSERT INTO busy.busy_marker VALUES(2);\n" "$WORK/data/busy.sqlite" > "$WORK/busy.sql"
    start=$SECONDS
    expect_status 1 helper queryFile "$WORK/busy.sql"
    elapsed=$((SECONDS - start))
    grep -q 'database is locked' "$WORK/last.stderr"
    sqlite_writer_stop
    [[ $elapsed -ge 4 && $elapsed -le 10 ]] || { printf 'SQLite busy deadline: %s\n' "$elapsed"; return 1; }
    printf 'PASS: real SQLite busy wait bounded (%s seconds)\n' "$elapsed"
    start=$SECONDS
    expect_status 124 helper query 'WITH RECURSIVE counter(x) AS (VALUES(1) UNION ALL SELECT x+1 FROM counter WHERE x<1000000000000) SELECT sum(x) FROM counter;'
    elapsed=$((SECONDS - start))
    [[ $elapsed -ge 29 && $elapsed -le 35 ]] || { printf 'SQLite operation deadline: %s\n' "$elapsed"; return 1; }
    printf 'PASS: real SQLite operation timeout (%s seconds)\n' "$elapsed"

    sql 'CREATE TABLE restore_payload (data BLOB); INSERT INTO restore_payload VALUES(zeroblob(67108864));'
    helper dbBackup "$WORK/data/large-backup" > "$WORK/large-backup.path"
    file=$(cat "$WORK/large-backup.path")
    checksum=$(sha256sum "$file")
    stamp=${file##*/}; stamp=${stamp#selected.sqlite_}; stamp=${stamp%.sqlite3}
    mkdir "$WORK/data/interrupted-backup"
    chown aa-db-test:aa-db-test "$WORK/data/interrupted-backup"
    bash -p "$CHECKOUT/scripts/mariadb_setup.bash" dbBackup "$WORK/data/interrupted-backup" > "$WORK/interrupted.stdout" 2> "$WORK/interrupted.stderr" &
    child=$!
    column=0
    for i in {1..2000}; do
        reserved=("$WORK/data/interrupted-backup/".aa-backup.*)
        if [[ -f ${reserved[0]} ]]; then kill -TERM "$child"; column=1; break; fi
        kill -0 "$child" 2>/dev/null || break
        sleep 0.005
    done
    rc=0; wait "$child" || rc=$?
    equal "$column" 1 'backup interrupted during private staging'
    [[ $rc != 0 ]] || { printf 'Interrupted backup reported success\n'; return 1; }
    equal "$(helper dbBackupList "$WORK/data/interrupted-backup")" '' 'interrupted backup publishes no completed file'
    make_db db.drop
    printf 'corrupt backup\n' > "$WORK/data/large-backup/selected.sqlite_20000101T000000Z.sqlite3"
    chmod 0644 "$WORK/data/large-backup/selected.sqlite_20000101T000000Z.sqlite3"
    expect_status 2 helper dbRestore 20000101T000000Z "$WORK/data/large-backup"
    [[ ! -e $DB_FILE ]] || { printf 'Failed restore created destination\n'; return 1; }
    helper dbRestore "$stamp" "$WORK/data/large-backup" > "$WORK/restore-race.stdout" 2> "$WORK/restore-race.stderr" &
    child=$!
    column=0
    for i in {1..2000}; do
        reserved=("$WORK/data/".aa-restore.*)
        if [[ -f ${reserved[0]} ]]; then
            if (set -o noclobber; printf 'competitor\n' > "$DB_FILE") 2>/dev/null; then column=1; fi
            break
        fi
        kill -0 "$child" 2>/dev/null || break
        sleep 0.005
    done
    rc=0; wait "$child" || rc=$?
    equal "$column" 1 'competing destination created during restore staging'
    [[ $rc != 0 ]] || { printf 'Restore overwrote competing destination\n'; return 1; }
    equal "$(cat "$DB_FILE")" competitor 'restore preserves competing destination'
    equal "$(sha256sum "$file")" "$checksum" 'restore leaves backup unchanged'
    rm -- "$DB_FILE"
    helper dbRestore "$stamp" "$WORK/data/large-backup"
    equal "$(scalar 'SELECT length(data) FROM restore_payload;')" 67108864 'large restore is complete'
}
