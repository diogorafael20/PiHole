#!/usr/bin/env bash
#
# PiHole Blocklists Installer
# https://github.com/diogorafael20/PiHole
#
# Interactively select blocklist categories and add them to Pi-hole,
# avoiding duplicates, then refresh Gravity.
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
REPO_RAW_BASE="https://raw.githubusercontent.com/diogorafael20/PiHole/main"
GRAVITY_DB="/etc/pihole/gravity.db"
TAG_PREFIX="pihole-tools"
BACKUP_DIR="${HOME}/pihole-tools-backups"

# Colors
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_GREEN='\033[0;32m'
C_RED='\033[0;31m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'

# Where to read category/list files from: prefer local checkout, fall back
# to fetching from GitHub raw (so the one-liner curl|bash install also works).
# Files (categories.txt, recommended.txt, privacy.txt, etc.) live in the
# repo root, not in a subfolder.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd)"
if [[ -f "${SCRIPT_DIR}/categories.txt" ]]; then
    LISTS_SOURCE="local"
    LISTS_DIR="${SCRIPT_DIR}"
else
    LISTS_SOURCE="remote"
    LISTS_DIR="$(mktemp -d)"
    trap 'rm -rf "${LISTS_DIR}"' EXIT
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { echo -e "${C_CYAN}$*${C_RESET}"; }
success() { echo -e "${C_GREEN}$*${C_RESET}"; }
warn()    { echo -e "${C_YELLOW}$*${C_RESET}"; }
error()   { echo -e "${C_RED}$*${C_RESET}" >&2; }

require_cmd() {
    command -v "$1" &>/dev/null || { error "Missing required command: $1"; exit 1; }
}

check_pihole_installed() {
    if ! command -v pihole &>/dev/null; then
        error "Pi-hole does not appear to be installed."
        read -r -p "Install Pi-hole now using the official installer? [y/N]: " ans
        if [[ "${ans,,}" == "y" ]]; then
            curl -sSL https://install.pi-hole.net | bash
        else
            error "Aborting: Pi-hole is required."
            exit 1
        fi
    fi

    if [[ ! -f "${GRAVITY_DB}" ]]; then
        error "Gravity database not found at ${GRAVITY_DB}."
        exit 1
    fi
}

backup_gravity() {
    mkdir -p "${BACKUP_DIR}"
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    cp "${GRAVITY_DB}" "${BACKUP_DIR}/gravity-${ts}.db"
    info "Backup saved to ${BACKUP_DIR}/gravity-${ts}.db"
}

# Fetch a list file (local copy or remote raw.githubusercontent.com)
fetch_list_file() {
    local filename="$1"
    local dest="${LISTS_DIR}/${filename}"

    if [[ "${LISTS_SOURCE}" == "remote" ]]; then
        curl -fsSL "${REPO_RAW_BASE}/${filename}" -o "${dest}" || return 1
    else
        dest="${LISTS_DIR}/${filename}"
    fi
    echo "${dest}"
}

sqlite() {
    sqlite3 "${GRAVITY_DB}" "$@"
}

# ---------------------------------------------------------------------------
# Category loading
# ---------------------------------------------------------------------------
declare -a CAT_KEY CAT_NAME CAT_FILE CAT_TYPE CAT_SELECTED

load_categories() {
    local cat_file
    cat_file="$(fetch_list_file "categories.txt")"

    local i=0
    while IFS='|' read -r key name file type; do
        [[ -z "${key}" || "${key}" == \#* ]] && continue
        CAT_KEY[i]="${key}"
        CAT_NAME[i]="${name}"
        CAT_FILE[i]="${file}"
        CAT_TYPE[i]="${type}"
        CAT_SELECTED[i]=0
        ((i++))
    done < "${cat_file}"
}

# ---------------------------------------------------------------------------
# Checkbox menu
# ---------------------------------------------------------------------------
show_menu() {
    clear
    echo "=========================================="
    echo -e " ${C_BOLD}PiHole Blocklists Installer${C_RESET}"
    echo "=========================================="
    echo
    echo "Select the categories you want to install."
    echo "Type a number to toggle it, 'a' to select all,"
    echo "ENTER to confirm, or 0 to exit."
    echo
    for i in "${!CAT_KEY[@]}"; do
        local mark=" "
        [[ "${CAT_SELECTED[$i]}" == "1" ]] && mark="x"
        printf "  [%s] %2d. %s\n" "${mark}" "$((i+1))" "${CAT_NAME[$i]}"
    done
    echo
}

run_menu() {
    local choice
    while true; do
        show_menu
        read -r -p "Choice: " choice

        case "${choice}" in
            0)
                info "Bye."
                exit 0
                ;;
            "")
                # confirm / install
                local any=0
                for s in "${CAT_SELECTED[@]}"; do [[ "$s" == "1" ]] && any=1; done
                if [[ "${any}" == "0" ]]; then
                    warn "Nothing selected."
                    read -r -p "Press ENTER to continue..." _
                    continue
                fi
                break
                ;;
            a|A)
                for i in "${!CAT_KEY[@]}"; do CAT_SELECTED[$i]=1; done
                ;;
            *[!0-9]*)
                warn "Invalid input."
                sleep 1
                ;;
            *)
                local idx=$((choice-1))
                if [[ ${idx} -ge 0 && ${idx} -lt ${#CAT_KEY[@]} ]]; then
                    if [[ "${CAT_SELECTED[$idx]}" == "1" ]]; then
                        CAT_SELECTED[$idx]=0
                    else
                        CAT_SELECTED[$idx]=1
                    fi
                else
                    warn "Invalid option."
                    sleep 1
                fi
                ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# Install logic
# ---------------------------------------------------------------------------
declare -a RESULT_OK RESULT_SKIP

install_block_category() {
    local key="$1" file="$2"
    local list_path
    list_path="$(fetch_list_file "${file}")"

    local added=0 skipped=0
    while IFS= read -r url; do
        [[ -z "${url}" || "${url}" == \#* ]] && continue

        local existing
        existing="$(sqlite "SELECT id FROM adlist WHERE address = '${url}';")"
        if [[ -n "${existing}" ]]; then
            ((skipped++))
            continue
        fi

        sqlite "INSERT INTO adlist (address, enabled, comment) VALUES ('${url}', 1, '${TAG_PREFIX}:${key}');"
        ((added++))
    done < "${list_path}"

    RESULT_OK+=("${key}: ${added} added, ${skipped} already present")
}

install_allow_category() {
    local key="$1" file="$2"
    local list_path
    list_path="$(fetch_list_file "${file}")"

    local added=0 skipped=0
    while IFS= read -r domain; do
        [[ -z "${domain}" || "${domain}" == \#* ]] && continue

        local existing
        existing="$(sqlite "SELECT id FROM domainlist WHERE domain = '${domain}' AND type = 0;")"
        if [[ -n "${existing}" ]]; then
            ((skipped++))
            continue
        fi

        sqlite "INSERT INTO domainlist (domain, type, enabled, comment) VALUES ('${domain}', 0, 1, '${TAG_PREFIX}:${key}');"
        ((added++))
    done < "${list_path}"

    RESULT_OK+=("${key}: ${added} added, ${skipped} already present")
}

do_install() {
    echo
    info "Installing..."
    echo

    for i in "${!CAT_KEY[@]}"; do
        [[ "${CAT_SELECTED[$i]}" != "1" ]] && continue

        local key="${CAT_KEY[$i]}" name="${CAT_NAME[$i]}" file="${CAT_FILE[$i]}" type="${CAT_TYPE[$i]}"

        if [[ "${type}" == "allow" ]]; then
            install_allow_category "${key}" "${file}"
        else
            install_block_category "${key}" "${file}"
        fi
        success "✓ ${name}"
    done

    echo
    info "Updating Gravity..."
    pihole -g >/tmp/pihole-tools-gravity.log 2>&1 || {
        error "Gravity update failed. See /tmp/pihole-tools-gravity.log"
        exit 1
    }

    echo
    success "Done."
    echo
    echo -e "${C_BOLD}Summary:${C_RESET}"
    for line in "${RESULT_OK[@]}"; do
        echo "  - ${line}"
    done
    echo
    success "Installed $(( $(printf '%s\n' "${RESULT_OK[@]}" | wc -l) )) categories successfully."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    require_cmd curl
    require_cmd sqlite3
    check_pihole_installed
    backup_gravity
    load_categories
    run_menu
    do_install
}

main "$@"
