#!/bin/bash

docker-compose \
	-f home-assistant.yml \
	-f mealie.yml \
	-f nextcloud.yml \
	-f paperless.yml \
	pull

docker-compose \
	-f home-assistant.yml \
	-f mealie.yml \
	-f nextcloud.yml \
	-f paperless.yml \
	up \
	-d

