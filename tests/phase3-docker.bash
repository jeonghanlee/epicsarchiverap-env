#!/usr/bin/env bash
# Phase 3: Infrastructure (Docker container).
# Runs `make install` end-to-end inside a Debian 13 container using the
# tomcat.action target (systemd-free variant). Validates that the four
# WARs deploy to the expected webapps directory under the install prefix.
#
# Status: stub. The container image and entrypoint script are not yet
# committed under tests/docker/. Implement when Phase 1 and Phase 2 are
# stable in CI.

set -euo pipefail

readonly TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib/common.bash
source "${TOP}/tests/lib/common.bash"

phase_header "Phase 3: Infrastructure (Docker)"

assert_cmd docker "docker available"

printf '  [SKIP] Phase 3 implementation pending. Tracked TODO: tests/docker/Dockerfile + entrypoint.\n'
printf '         Validates: %%/{mgmt,engine,etl,retrieval}/webapps populated after make install.\n'

phase_pass "Phase 3: Infrastructure (skip)"
