#!/bin/bash
#
#  Install the OS packages the Archiver Appliance environment needs,
#  driven by the per-OS package lists under configure/os/*.pkgs.
#
#  Usage: sudo bash scripts/install_os_packages.bash [options]
#         (macOS: run WITHOUT sudo; brew refuses root)
#
#  Options:
#    -l, --list-only   print the resolved package list and exit (no root)
#    -f, --force       do not prompt (CI / unattended runs)
#        --os <id>     override OS detection (debian13, rocky8, macos)
#    -h, --help        this text

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/homebrew/bin"

declare -g SC_SCRIPT SC_TOP OS_DIR
SC_SCRIPT="$(realpath "${BASH_SOURCE[0]:-$0}")"
SC_TOP="${SC_SCRIPT%/*/*}"
OS_DIR="${SC_TOP}/configure/os"

declare -g OPT_FORCE=0 OPT_LIST_ONLY=0 OPT_OS=""

function die {
    printf "ERROR: %s\n" "$1" >&2
    exit 1
}

function usage {
    sed -n '3,13p' "${SC_SCRIPT}" | sed 's/^#[ ]\{0,2\}//'
    exit "${1:-0}"
}

function available_lists {
    local f
    local -a names=()
    for f in "${OS_DIR}"/*.pkgs; do
        [[ -e "${f}" ]] || continue
        f="${f##*/}"
        names+=("${f%.pkgs}")
    done
    printf "%s" "${names[*]}"
}

# Prints the OS id matching a configure/os/<id>.pkgs list.
# /etc/os-release is parsed as plain text, never sourced.
function detect_os {
    local id ver
    if [[ "${OSTYPE:-}" == darwin* ]]; then
        printf "%s" "macos"
        return 0
    fi
    [[ -r /etc/os-release ]] || return 1
    id="$(sed -n 's/^ID="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' /etc/os-release)"
    ver="$(sed -n 's/^VERSION_ID="\{0,1\}\([0-9]*\).*/\1/p' /etc/os-release)"
    case "${id}" in
        debian)                      printf "debian%s" "${ver}" ;;
        rocky|almalinux|rhel|centos) printf "rocky%s" "${ver}" ;;
        *)                           return 1 ;;
    esac
}

# Prints one package per line from a list file: comments, blank lines,
# whitespace, and Windows carriage returns stripped.
function read_pkg_list {
    local list_file="$1"
    local line
    while IFS= read -r line || [[ -n "${line:-}" ]]; do
        line="${line//$'\r'/}"
        line="${line%%#*}"
        line="${line//[[:space:]]/}"
        [[ -n "${line}" ]] && printf "%s\n" "${line}"
    done < "${list_file}"
    return 0
}

function confirm_or_die {
    local count="$1" osid="$2"
    local reply
    if [[ ${OPT_FORCE} -eq 1 ]]; then
        return 0
    fi
    if [[ ! -t 0 ]]; then
        die "Non-interactive stdin detected. Use --force (-f) to run without prompts."
    fi
    printf "Install %d packages for %s? [y/N] " "${count}" "${osid}"
    if ! read -r reply; then
        die "No answer (EOF); aborting."
    fi
    case "${reply}" in
        y|Y|yes|YES) return 0 ;;
        *)           die "Aborted by user." ;;
    esac
}

function install_pkgs {
    local osid="$1"; shift
    case "${osid}" in
        debian*)
            [[ ${EUID} -eq 0 ]] || die "Run with sudo: package installation needs root."
            apt-get update -y
            apt-get install -y "$@"
            ;;
        rocky*)
            [[ ${EUID} -eq 0 ]] || die "Run with sudo: package installation needs root."
            dnf install -y "$@"
            ;;
        macos)
            [[ ${EUID} -ne 0 ]] || die "Run brew without sudo."
            brew install "$@"
            ;;
        *)
            die "No installer mapped for ${osid}."
            ;;
    esac
}

function main {
    local osid list_file
    local -a pkgs=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--list-only) OPT_LIST_ONLY=1 ;;
            -f|--force)     OPT_FORCE=1 ;;
            --os)
                shift
                OPT_OS="${1:-}"
                [[ -n "${OPT_OS}" ]] || die "--os needs a value; available: $(available_lists)"
                ;;
            -h|--help)      usage 0 ;;
            -*)             printf "Unknown option: %s\n" "$1" >&2; usage 1 ;;
            *)              printf "Unexpected argument: %s\n" "$1" >&2; usage 1 ;;
        esac
        shift
    done

    if [[ -n "${OPT_OS}" ]]; then
        osid="${OPT_OS}"
    elif ! osid="$(detect_os)"; then
        die "Unsupported OS. Use --os <id>; available: $(available_lists)"
    fi

    list_file="${OS_DIR}/${osid}.pkgs"
    [[ -s "${list_file}" ]] || die "No package list ${list_file}; available: $(available_lists)"

    mapfile -t pkgs < <(read_pkg_list "${list_file}")
    [[ ${#pkgs[@]} -gt 0 ]] || die "Package list ${list_file} is empty."

    if [[ ${OPT_LIST_ONLY} -eq 1 ]]; then
        printf "%s\n" "${pkgs[@]}"
        return 0
    fi

    confirm_or_die "${#pkgs[@]}" "${osid}"
    install_pkgs "${osid}" "${pkgs[@]}"
    printf "Installed %d packages for %s from %s\n" "${#pkgs[@]}" "${osid}" "${list_file}"
}

main "$@"
