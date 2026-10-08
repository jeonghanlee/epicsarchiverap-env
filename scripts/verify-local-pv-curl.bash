#!/bin/bash
# Retains and validates the exact retrieval response consumed by the pinned CSV client.
set -euo pipefail
umask 077
output=''
status=''
code=0
previous=''
for argument in "$@"; do
    if [[ "$previous" == --output ]]; then output="$argument"; fi
    previous="$argument"
done
[[ -n "$output" && "${*: -1}" == "${AA_PV_RETRIEVAL_URL:?}" ]] || {
    printf '%s\n' 'ERROR: Unexpected CSV client retrieval request' >&2
    exit 1
}
status=$("${AA_PV_CURL_BIN:?}" -q --noproxy '*' "$@") || code=$?
if [[ -f "$output" ]]; then cp -- "$output" "${AA_PV_RESPONSE:?}"; fi
if (( code != 0 )); then exit "$code"; fi
if [[ "$status" == 200 ]]; then
    if ! jq -e -s --arg pv "${AA_PV_EXPECTED:?}" \
        'length == 1 and (.[0] | type == "array" and length == 1 and .[0].meta.name == $pv)' \
        "$output" >/dev/null 2>&1; then
        printf '%s\n' 'ERROR: Retrieval response does not identify the requested test PV' >&2
        exit 1
    fi
fi
printf '%s' "$status"
