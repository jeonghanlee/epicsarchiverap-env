#!/usr/bin/env bash
# Phase 4: System Integration (libvirt VM).
# Boots a Debian 13 VM from the cloud image under
# /data/libvirt/images/debian-13-genericcloud-amd64-daily.qcow2,
# applies a cloud-init seed that runs `make init && make build && make
# install && make sd_start`, then probes the four service HTTP endpoints.
#
# Status: stub. The cloud-init user-data template and per-VM seed
# generator are not yet committed under tests/vm/. Implement after
# Phase 3 stabilises.

set -euo pipefail

readonly TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib/common.bash
source "${TOP}/tests/lib/common.bash"

phase_header "Phase 4: System Integration (libvirt VM)"

assert_cmd virsh "virsh available"
assert_cmd qemu-system-x86_64 "qemu available"

printf '  [SKIP] Phase 4 implementation pending. Tracked TODO: tests/vm/user-data.tmpl + run-vm.bash.\n'
printf '         Validates: systemctl is-active archappl.service, HTTP 200 on mgmt/engine/etl/retrieval ports, MariaDB tables present.\n'

phase_pass "Phase 4: System Integration (skip)"
