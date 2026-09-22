#!/bin/bash
# Shared config/helpers for backup.sh and restore.sh.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BACKUP_ROOT="${BACKUP_ROOT:-/mnt/terramaster/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

# docker-compose derives its project name from the containing directory.
PROJECT_NAME="$(basename "$REPO_DIR" | tr '[:upper:]' '[:lower:]')"

# These scripts run as root (via sudo), so "~" would resolve to /root rather
# than the home directory the bind mounts actually live in. Resolve the home
# of the user who ran sudo instead.
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
HOME_ASSISTANT_DIR="$TARGET_HOME/home-assistant/config"
MEALIE_DIR="$TARGET_HOME/mealie-data"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

require_root() {
	if [ "$(id -u)" -ne 0 ]; then
		echo "This must be run as root (it needs to read docker volume data)." >&2
		exit 1
	fi
}

# Fails loudly instead of silently writing backups to the root filesystem
# if the backup drive isn't actually mounted.
require_backup_mount() {
	if ! mountpoint -q "$(dirname "$BACKUP_ROOT")"; then
		echo "$(dirname "$BACKUP_ROOT") is not mounted, refusing to back up." >&2
		exit 1
	fi
}

# Resolves the host path backing a named docker volume declared in a compose file.
volume_path() {
	docker volume inspect -f '{{ .Mountpoint }}' "${PROJECT_NAME}_$1"
}

confirm() {
	if [ "${ASSUME_YES:-0}" = "1" ]; then
		return 0
	fi
	read -r -p "$1 Continue? [y/N] " reply
	case "$reply" in
	[yY] | [yY][eE][sS]) ;;
	*)
		echo "Aborted."
		exit 1
		;;
	esac
}

# Removes snapshot directories older than RETENTION_DAYS. Cheap to do, since
# unchanged files are hardlinked into newer snapshots and survive the delete.
prune_old_snapshots() {
	find "$1" -mindepth 1 -maxdepth 1 -type d -mtime "+$RETENTION_DAYS" -print -exec rm -rf {} +
}

# Backs up a single directory (used for bind-mounted config/data dirs).
# Stops the given compose service(s) for a consistent copy, then restarts them.
backup_dir() {
	local label="$1" compose_file="$2" src_dir="$3"
	local dest_root="$BACKUP_ROOT/$label"
	local snapshot="$dest_root/$(date +%Y-%m-%d_%H%M%S)"
	local latest_link="$dest_root/latest"

	log "Backing up $label..."
	docker-compose -f "$compose_file" stop

	mkdir -p "$snapshot"
	if [ -e "$latest_link" ]; then
		rsync -a --delete --link-dest="$latest_link" "$src_dir"/ "$snapshot"/
	else
		rsync -a "$src_dir"/ "$snapshot"/
	fi

	docker-compose -f "$compose_file" start
	ln -sfn "$(basename "$snapshot")" "$latest_link"
	prune_old_snapshots "$dest_root"
	log "$label done ($snapshot)"
}

# Restores a single directory backup. Overwrites the live directory in place.
restore_dir() {
	local label="$1" compose_file="$2" dest_dir="$3" snapshot_path="$4"

	confirm "This will REPLACE the current $label data with the backup at $snapshot_path."
	docker-compose -f "$compose_file" stop
	rsync -a --delete "$snapshot_path"/ "$dest_dir"/
	docker-compose -f "$compose_file" start
	log "$label restored from $snapshot_path"
}

# Resolves a snapshot name ("latest" or a literal timestamp dir) to a real path.
resolve_snapshot() {
	local label="$1" name="$2"
	local path="$BACKUP_ROOT/$label/$name"

	if [ ! -e "$path" ]; then
		echo "No such snapshot: $path" >&2
		echo "Available snapshots for $label:" >&2
		ls "$BACKUP_ROOT/$label" 2>/dev/null >&2
		exit 1
	fi
	readlink -f "$path"
}

# Paperless stores its data in named docker volumes rather than bind mounts,
# so it gets its own backup/restore that copies each volume into a subfolder
# of one snapshot.
PAPERLESS_VOLUMES="data media pgdata redisdata"
PAPERLESS_COMPOSE_FILE="$REPO_DIR/paperless.yml"

backup_paperless() {
	local dest_root="$BACKUP_ROOT/paperless"
	local snapshot="$dest_root/$(date +%Y-%m-%d_%H%M%S)"
	local latest_link="$dest_root/latest"

	log "Backing up paperless..."
	docker-compose -f "$PAPERLESS_COMPOSE_FILE" stop

	mkdir -p "$snapshot"
	for vol in $PAPERLESS_VOLUMES; do
		local src
		src="$(volume_path "$vol")"
		mkdir -p "$snapshot/$vol"
		if [ -d "$latest_link/$vol" ]; then
			rsync -a --delete --link-dest="$latest_link/$vol" "$src"/ "$snapshot/$vol"/
		else
			rsync -a "$src"/ "$snapshot/$vol"/
		fi
	done

	docker-compose -f "$PAPERLESS_COMPOSE_FILE" start
	ln -sfn "$(basename "$snapshot")" "$latest_link"
	prune_old_snapshots "$dest_root"
	log "paperless done ($snapshot)"
}

restore_paperless() {
	local snapshot_path="$1"

	confirm "This will REPLACE all current paperless data with the backup at $snapshot_path."
	docker-compose -f "$PAPERLESS_COMPOSE_FILE" stop
	for vol in $PAPERLESS_VOLUMES; do
		local dest
		dest="$(volume_path "$vol")"
		rsync -a --delete "$snapshot_path/$vol"/ "$dest"/
	done
	docker-compose -f "$PAPERLESS_COMPOSE_FILE" start
	log "paperless restored from $snapshot_path"
}
