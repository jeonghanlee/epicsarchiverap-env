#!/usr/bin/env bash
# Read-only summary of the store folders of the six sample PVs: file count, bytes, first and last file name
# per tier. It runs ls and du only. Run it with sudo because the store folders belong to the service account.

set -u
shopt -s nullglob

stores=(sts mts lts)
keys=(L1/CH001 L2/CH300 FAST/CH01 L2F/CH100 SLOW/CH01 L2WF/CH01)

date -u '+observed %Y-%m-%dT%H:%M:%SZ'
for key in "${keys[@]}"; do
    dir="${key%/*}"
    base="${key#*/}"
    for tier in "${stores[@]}"; do
        path="/arch/$tier/ArchiverStore/AASOAK/$dir"
        if [[ ! -d "$path" ]]; then
            printf '%s %s: folder absent\n' "$key" "$tier"
            continue
        fi
        files=()
        for p in "$path/${base}":*; do
            files+=("${p##*/}")
        done
        if (( ${#files[@]} == 0 )); then
            printf '%s %s: files=0\n' "$key" "$tier"
            continue
        fi
        bytes=0
        for f in "${files[@]}"; do
            size=$(stat -c %s "$path/$f")
            bytes=$((bytes + size))
        done
        printf '%s %s: files=%d bytes=%d first=%s last=%s\n' "$key" "$tier" "${#files[@]}" "$bytes" "${files[0]}" "${files[-1]}"
    done
done
