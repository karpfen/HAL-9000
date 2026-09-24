# Backups

Nightly incremental backups of home-assistant, mealie, paperless and
nextcloud to `/mnt/terramaster/backups` (visible through Nextcloud's external
storage).

## How it works

Each backup is a full-looking snapshot folder named by timestamp, but files
unchanged since the previous snapshot are hardlinked instead of copied
(`rsync --link-dest`). So every snapshot can be restored on its own, while
unchanged data only takes up disk space once. Snapshots older than
`RETENTION_DAYS` (default 30) are pruned automatically after each backup.

The affected containers are stopped for the duration of the copy, then
restarted, to guarantee a consistent copy without needing per-service
database dump logic.

A `latest` symlink in each service's backup folder always points at the most
recent snapshot.

## Usage

Run as root (needs to read docker volume data):

```bash
# back up everything
sudo ./backup/backup.sh

# back up a single service
sudo ./backup/backup.sh mealie

# list snapshots for a service
ls /mnt/terramaster/backups/paperless

# restore the latest snapshot (asks for confirmation)
sudo ./backup/restore.sh paperless

# restore a specific snapshot without confirmation
sudo ./backup/restore.sh home-assistant 2026-09-20_030000 --yes
```

## Automation

`setup.sh` installs `hal-9000-backup.timer`, which runs `backup.sh all`
nightly at 03:00. To trigger it manually instead of waiting:

```bash
sudo systemctl start hal-9000-backup.service
journalctl -u hal-9000-backup.service -f
```
