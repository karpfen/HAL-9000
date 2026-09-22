#!/bin/bash
# Backs up home-assistant, mealie and/or paperless to $BACKUP_ROOT
# (default: /mnt/terramaster/backups) as incremental, hardlinked snapshots.
#
# Usage: backup.sh [home-assistant|mealie|paperless|all]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

require_root
require_backup_mount

SERVICE="${1:-all}"

case "$SERVICE" in
home-assistant)
	backup_dir "home-assistant" "$REPO_DIR/home-assistant.yml" "$HOME_ASSISTANT_DIR"
	;;
mealie)
	backup_dir "mealie" "$REPO_DIR/mealie.yml" "$MEALIE_DIR"
	;;
paperless)
	backup_paperless
	;;
all)
	backup_dir "home-assistant" "$REPO_DIR/home-assistant.yml" "$HOME_ASSISTANT_DIR"
	backup_dir "mealie" "$REPO_DIR/mealie.yml" "$MEALIE_DIR"
	backup_paperless
	;;
*)
	echo "Usage: $0 [home-assistant|mealie|paperless|all]" >&2
	exit 1
	;;
esac

log "Backup complete."
