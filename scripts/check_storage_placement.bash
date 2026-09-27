#!/usr/bin/env bash
#
# Warns when the archive store shares the root filesystem or lies under a user
# home directory. The store's placement and size belong to the host, so the
# check only reports and always exits 0.
#
# Usage: check_storage_placement.bash <store directory> <invoking user's home>

set -u

store="${1:-}"
invoker_home="${2:-}"

# Prints the mount point df -P reports for a path; empty when df cannot read it.
function mount_of {
    local line mount=""
    line=$(df -P -- "$1" 2>/dev/null | sed -n '2p')
    if [[ -n $line ]]; then
        read -r _ _ _ _ _ mount <<< "$line"
    fi
    printf '%s' "$mount"
}

# Prints a directory with every symbolic link resolved.
function resolve {
    ( cd -P -- "$1" 2>/dev/null && pwd -P )
}

# True when the first path equals the second or lies below it, by whole components.
function is_under {
    [[ $1 == "$2" || $1 == "$2"/* ]]
}

function main {
    local store_real store_mount root_mount candidate home_real
    local -a homes=()
    if [[ -z $store ]] || ! store_real=$(resolve "$store"); then
        printf '>>> WARNING: cannot resolve the archive store %s to check its placement\n' "$store"
        return 0
    fi
    store_mount=$(mount_of "$store_real")
    root_mount=$(mount_of /)
    if [[ -n $store_mount && $store_mount == "$root_mount" ]]; then
        printf '>>> WARNING: the archive store %s is on the root filesystem (%s);' "$store_real" "$store_mount"
        printf ' a full store fills the root filesystem. Place it on a volume of its own.\n'
    fi
    for candidate in /home /root "$invoker_home"; do
        [[ -n $candidate ]] || continue
        if home_real=$(resolve "$candidate"); then
            homes+=("$home_real")
        fi
    done
    for home_real in "${homes[@]}"; do
        if is_under "$store_real" "$home_real"; then
            printf '>>> WARNING: the archive store %s lies under the home directory %s;' "$store_real" "$home_real"
            printf ' the service account may not reach it. Place it outside any user home.\n'
            break
        fi
    done
    return 0
}

main
exit 0
