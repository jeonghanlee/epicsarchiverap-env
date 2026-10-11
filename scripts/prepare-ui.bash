#!/bin/bash
# Copies the interface files of site-template/ui over the source tree. It first undoes an earlier copy, so a file
# that site-template/ui no longer holds does not stay in the build. Only the files of the earlier copy are touched.
set -euo pipefail

if [[ $# -ne 3 ]]; then
    printf 'Usage: %s <template folder> <target folder> <source checkout>\n' "${0##*/}" >&2
    exit 2
fi
template=$1
target=$2
source=$3

gitdir=$(git -C "$source" rev-parse --absolute-git-dir 2>/dev/null) || gitdir=$source
manifest="$gitdir/aa-ui-prepared.list"
prefix=${target#"$source"/}

if [[ -f "$manifest" ]]; then
    while IFS= read -r relative; do
        [[ -n "$relative" ]] || continue
        if git -C "$source" ls-files --error-unmatch -- "$prefix/$relative" > /dev/null 2>&1; then
            git -C "$source" checkout -- "$prefix/$relative"
        else
            rm -f -- "$target/$relative"
        fi
    done < "$manifest"
    rm -f -- "$manifest"
fi

[[ -d "$template" ]] || exit 0
if [[ ! -d "$target" ]]; then
    printf 'The source tree %s is missing; run make init first.\n' "$target" >&2
    exit 1
fi
cp -rf "$template/." "$target/"
(cd "$template" && find . -type f -print | sed 's|^\./||' | LC_ALL=C sort) > "$manifest"
