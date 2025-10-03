#!/bin/bash

#	-f docker_compose/home-assistant.yml \
#	-f docker_compose/mealie.yml \
#	-f docker_compose/nextcloud.yml \
#	-f docker_compose/paperless.yml \
docker-compose \
	-f docker_compose/nextcloud.yml \
	up 



