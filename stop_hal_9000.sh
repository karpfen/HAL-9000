#!/bin/bash

docker-compose \
	-f docker_compose/home-assistant.yml \
	-f docker_compose/mealie.yml \
	-f docker_compose/nextcloud.yml \
	-f docker_compose/paperless.yml \
	down \
	--remove-orphans


