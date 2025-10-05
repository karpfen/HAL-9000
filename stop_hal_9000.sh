#!/bin/bash

docker-compose \
	-f home-assistant.yml \
	-f mealie.yml \
	-f nextcloud.yml \
	-f paperless.yml \
	down \
	--remove-orphans


