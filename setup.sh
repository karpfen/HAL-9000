#!/bin/bash

# Setup for home assistant

# enable ssh access
sudo pacman -S openssh
sudo systemctl enable --now sshd

sudo cp utils/sshd_config /etc/ssh/sshd_config
sudo systemctl restart sshd.service
sudo ufw allow ssh
sudo ufw allow 22/tcp
sudo ufw allow 8123/tcp
sudo ufw allow 9925/tcp
sudo ufw enable

# Install docker
sudo pacman -S docker-compose

sudo systemctl start docker.service
sudo systemctl enable docker.service

sudo setfacl --modify user:andreas:rw /var/run/docker.sock

# pull home-assistant
docker-compose pull

# map config directory to local machine
mkdir -p ~/home-assistant/config
mkdir -p ~/mealie-data

# Install HACS (Home Assistant Community Store) so community integrations
# (e.g. the Dreame vacuum integration) can be installed through its UI.
# Only bootstraps the files - HACS updates itself through its own UI after
# that, so this is skipped once it's already present rather than
# re-downloading "latest" on every setup.sh run.
sudo pacman -S unzip

HACS_DIR="$HOME/home-assistant/config/custom_components/hacs"
if [ ! -d "$HACS_DIR" ]; then
	tmpdir="$(mktemp -d)"
	curl -sL "https://github.com/hacs/integration/releases/latest/download/hacs.zip" -o "$tmpdir/hacs.zip"
	mkdir -p "$HACS_DIR"
	unzip -q "$tmpdir/hacs.zip" -d "$HACS_DIR"
	rm -rf "$tmpdir"
fi

# run home-assistant
docker-compose up -d

# autostart docker and home-assistant
sudo cp ./utils/home-assistant.service /etc/systemd/system/home-assistant.service
sudo systemctl daemon-reload
sudo systemctl enable home-assistant.service
sudo systemctl start home-assistant.service

# configure hdd
sudo cp ./utils/69-hdparm.rules /etc/udev/rules.d/

# install nightly backup timer (see backup/README.md)
sed "s#__REPO_DIR__#$(pwd)#g" utils/hal-9000-backup.service | sudo tee /etc/systemd/system/hal-9000-backup.service >/dev/null
sudo cp ./utils/hal-9000-backup.timer /etc/systemd/system/hal-9000-backup.timer
sudo systemctl daemon-reload
sudo systemctl enable --now hal-9000-backup.timer

