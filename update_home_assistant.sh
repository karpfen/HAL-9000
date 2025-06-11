#!/bin/bash

docker-compose pull

# map config directory to local machine
mkdir -p ~/home-assistant/config
# run home-assistant
docker-compose run -d

