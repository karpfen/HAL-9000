#!/bin/bash

docker-compose \
	-f home-assistant.yml \
	-f mealie.yml \
	-f nextcloud.yml \
	-f paperless.yml \
	-f pocket-id.yml \
	-f caddy.yml \
	pull

docker-compose \
	-f home-assistant.yml \
	-f mealie.yml \
	-f nextcloud.yml \
	-f paperless.yml \
	-f pocket-id.yml \
	-f caddy.yml \
	up \
	-d

