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
# Caddy's HTTPS-fronted ports for Pocket ID SSO (see Caddyfile). The
# underlying plain-HTTP ports above are left exactly as they were; these are
# new, separate ports, not a replacement for them.
sudo ufw allow 8443/tcp
sudo ufw allow 18123/tcp
sudo ufw allow 19925/tcp
sudo ufw allow 18000/tcp
sudo ufw allow 18080/tcp
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

# Install hass-oidc-auth (Pocket ID SSO login for Home Assistant), pinned to a
# specific release for reproducibility. Skipped if that version is already
# installed; safe to re-run.
HASS_OIDC_AUTH_VERSION="v1.2.1"
HASS_OIDC_AUTH_DIR="$HOME/home-assistant/config/custom_components/auth_oidc"
if ! grep -q "\"version\": \"${HASS_OIDC_AUTH_VERSION#v}\"" "$HASS_OIDC_AUTH_DIR/manifest.json" 2>/dev/null; then
	tmpdir="$(mktemp -d)"
	curl -sL "https://github.com/christiaangoossens/hass-oidc-auth/archive/refs/tags/${HASS_OIDC_AUTH_VERSION}.tar.gz" | tar -xz -C "$tmpdir"
	mkdir -p "$(dirname "$HASS_OIDC_AUTH_DIR")"
	rm -rf "$HASS_OIDC_AUTH_DIR"
	cp -r "$tmpdir"/hass-oidc-auth-*/custom_components/auth_oidc "$HASS_OIDC_AUTH_DIR"
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

