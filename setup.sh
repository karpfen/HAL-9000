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
# run home-assistant
docker-compose up -d

# autostart docker and home-assistant
sudo cp ./utils/home-assistant.service /etc/systemd/system/home-assistant.service
sudo systemctl daemon-reload
sudo systemctl enable home-assistant.service
sudo systemctl start home-assistant.service

