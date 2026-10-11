#!/usr/bin/env bash
# Checks that the committed generated pages equal what the generators print now.
# Usage: bash book/scripts/check-generated.bash
# Exit status 0 when every generated page is current, 1 when one differs.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="${here}/../src"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

declare -A pages=(
    [gen-config-vars]=configure/variables.md
    [gen-make-targets]=appendix/make-targets.md
    [gen-judgements]=interface/judgements.md
    [gen-policy-parameters]=configure/policy-parameters.md
    [gen-script-options]=appendix/script-options.md
)
status=0
for generator in "${!pages[@]}"; do
    page="${pages[${generator}]}"
    bash "${here}/${generator}.bash" "${work}/page.md" > /dev/null
    if cmp -s "${work}/page.md" "${src}/${page}"; then
        printf 'current  %s\n' "${page}"
    else
        printf 'DIFFERS  %s (run book/scripts/generate-all.bash)\n' "${page}"
        status=1
    fi
done
exit "${status}"
