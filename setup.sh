# Setup for home assistant

# enable ssh access
sudo apt update
sudo apt install openssh-server
sudo ./utils/set_static_ip.sh
# TODO add to utils/sshd_config
# PermitRootLogin no
# AllowUsers your_username

# cp utils/sshd_config /etc/ssh/sshd_config
sudo systemctl restart ssh
sudo ufw allow ssh
sudo ufw enable

# Install docker
## Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

## Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker

# pull home-assistant
docker pull homeassistant/home-assistant

# map config directory to local machine
mkdir -p /home/home-assistant/config
# run home-assistant
docker run -d \
  --name HAL-9000 \
  --restart=unless-stopped \
  -e TZ=Europe/Berlin \
  -v /home/home-assistant/config:/config \
  --network=host \
  ghcr.io/home-assistant/home-assistant:stable

# autostart docker and home-assistant
cp ./utils/home-assistant.service /etc/systemd/system/home-assistant.service
sudo systemctl daemon-reload
sudo systemctl enable home-assistant
sudo systemctl start home-assistant

# TODO if needed, expose home-assistant to local wifi
