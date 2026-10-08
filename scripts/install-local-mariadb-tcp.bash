#!/bin/bash
# Installs the MariaDB TCP appliance through the shared installation driver.
set -euo pipefail
script_path=$(realpath -- "${BASH_SOURCE[0]}")
exec /bin/bash "${script_path%/*}/install-local-common.bash" mariadb-tcp "$@"
