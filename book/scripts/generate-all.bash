#!/usr/bin/env bash
# Regenerates every generated page of the book from the repository.
# Usage: bash book/scripts/generate-all.bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for generator in gen-config-vars gen-make-targets gen-judgements gen-policy-parameters gen-script-options; do
    bash "${here}/${generator}.bash"
done
