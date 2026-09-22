#!/bin/bash
# Restores a previous backup created by backup.sh. Overwrites live data in
# place, so it asks for confirmation unless --yes is given.
#
# Usage: restore.sh <home-assistant|mealie|paperless> [snapshot-name] [--yes]
#   snapshot-name defaults to "latest". Run without a valid one to list
#   available snapshots for that service.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

require_root
require_backup_mount

ASSUME_YES=0
args=()
for arg in "$@"; do
	if [ "$arg" = "--yes" ]; then
		ASSUME_YES=1
	else
		args+=("$arg")
	fi
done

SERVICE="${args[0]:-}"
SNAPSHOT_NAME="${args[1]:-latest}"

if [ -z "$SERVICE" ]; then
	echo "Usage: $0 <home-assistant|mealie|paperless> [snapshot-name] [--yes]" >&2
	exit 1
fi

case "$SERVICE" in
home-assistant)
	snapshot="$(resolve_snapshot "home-assistant" "$SNAPSHOT_NAME")"
	restore_dir "home-assistant" "$REPO_DIR/home-assistant.yml" "$HOME_ASSISTANT_DIR" "$snapshot"
	;;
mealie)
	snapshot="$(resolve_snapshot "mealie" "$SNAPSHOT_NAME")"
	restore_dir "mealie" "$REPO_DIR/mealie.yml" "$MEALIE_DIR" "$snapshot"
	;;
paperless)
	snapshot="$(resolve_snapshot "paperless" "$SNAPSHOT_NAME")"
	restore_paperless "$snapshot"
	;;
*)
	echo "Usage: $0 <home-assistant|mealie|paperless> [snapshot-name] [--yes]" >&2
	exit 1
	;;
esac
