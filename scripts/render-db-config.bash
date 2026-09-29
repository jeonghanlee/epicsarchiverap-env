#!/usr/bin/env bash
# Render selected database placeholders from the environment as XML or shell data.
set -euo pipefail

mode=$1
input=$2
output=$3
shift 3
text=$(cat -- "$input")
rendered=
while [[ $text =~ @([A-Z_][A-Z_0-9]*)@ ]]; do
    token=${BASH_REMATCH[0]}
    key=${BASH_REMATCH[1]}
    rendered+=${text%%"$token"*}
    text=${text#*"$token"}
    value=$token
    for name in "$@"; do
        if [[ $key == "$name" ]]; then
            name="RENDER_${key}"
            value=${!name}
            case $mode in
                xml)
                    value=${value//&/\&amp;}
                    value=${value//</\&lt;}
                    value=${value//>/\&gt;}
                    value=${value//\"/\&quot;}
                    value=${value//\'/\&apos;}
                    value=${value//$'\n'/\&#10;}
                    value=${value//$'\r'/\&#13;}
                    value=${value//$'\t'/\&#9;}
                    ;;
                shell) printf -v value '%q' "$value" ;;
                *) printf 'Unknown rendering mode: %s\n' "$mode" >&2; exit 2 ;;
            esac
            break
        fi
    done
    rendered+=$value
done
printf '%s\n' "$rendered$text" > "$output"
