docker stop HAL-9000
docker rm HAL-9000

# run home-assistant
docker run -d \
  --privileged \
  --name HAL-9000 \
  --restart=unless-stopped \
  -e TZ=Europe/Berlin \
  -v ~/home-assistant/config:/config \
  -v /run/dbus:/run/dbus:ro \
  --network=host \
  ghcr.io/home-assistant/home-assistant:stable
