#!/usr/bin/env bash
#
# PiHole Blocklists Uninstaller
# Removes adlists / allowlist entries previously added by install.sh
# (identified by the "pihole-tools:<category>" comment tag).
#
set -euo pipefail

GRAVITY_DB="/etc/pihole/gravity.db"
TAG_PREFIX="pihole-tools"
BACKUP_DIR="${HOME}/pihole-tools-backups"

C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_RED='\033[0;31m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'

info()    { echo -e "${C_CYAN}$*${C_RESET}"; }
success() { echo -e "${C_GREEN}$*${C_RESET}"; }
warn()    { echo -e "${C_YELLOW}$*${C_RESET}"; }
error()   { echo -e "${C_RED}$*${C_RESET}" >&2; }

sqlite() { sqlite3 "${GRAVITY_DB}" "$@"; }

if ! command -v pihole &>/dev/null || [[ ! -f "${GRAVITY_DB}" ]]; then
    error "Pi-hole / gravity database not found."
    exit 1
fi

mkdir -p "${BACKUP_DIR}"
ts="$(date +%Y%m%d-%H%M%S)"
cp "${GRAVITY_DB}" "${BACKUP_DIR}/gravity-${ts}-preuninstall.db"
info "Backup saved to ${BACKUP_DIR}/gravity-${ts}-preuninstall.db"

echo "=========================================="
echo " PiHole Blocklists Uninstaller"
echo "=========================================="
echo

mapfile -t categories < <(
    sqlite "SELECT DISTINCT comment FROM adlist WHERE comment LIKE '${TAG_PREFIX}:%';"
    sqlite "SELECT DISTINCT comment FROM domainlist WHERE comment LIKE '${TAG_PREFIX}:%';"
) 
mapfile -t categories < <(printf '%s\n' "${categories[@]}" | sort -u)

if [[ ${#categories[@]} -eq 0 ]]; then
    warn "No entries tagged '${TAG_PREFIX}' were found. Nothing to remove."
    exit 0
fi

echo "The following categories were installed by this tool:"
echo
for i in "${!categories[@]}"; do
    printf "  %2d. %s\n" "$((i+1))" "${categories[$i]#${TAG_PREFIX}:}"
done
echo "   a. Remove ALL of the above"
echo "   0. Cancel"
echo
read -r -p "Choice: " choice

targets=()
case "${choice}" in
    0) info "Cancelled."; exit 0 ;;
    a|A) targets=("${categories[@]}") ;;
    *)
        idx=$((choice-1))
        if [[ ${idx} -ge 0 && ${idx} -lt ${#categories[@]} ]]; then
            targets=("${categories[$idx]}")
        else
            error "Invalid option."
            exit 1
        fi
        ;;
esac

for tag in "${targets[@]}"; do
    n_ad=$(sqlite "SELECT COUNT(*) FROM adlist WHERE comment = '${tag}';")
    n_dom=$(sqlite "SELECT COUNT(*) FROM domainlist WHERE comment = '${tag}';")
    sqlite "DELETE FROM adlist WHERE comment = '${tag}';"
    sqlite "DELETE FROM domainlist WHERE comment = '${tag}';"
    success "✓ Removed ${tag#${TAG_PREFIX}:} (${n_ad} adlist entries, ${n_dom} allowlist entries)"
done

echo
info "Updating Gravity..."
pihole -g >/tmp/pihole-tools-gravity.log 2>&1 || {
    error "Gravity update failed. See /tmp/pihole-tools-gravity.log"
    exit 1
}

echo
success "Done."
