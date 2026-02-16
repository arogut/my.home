#!/bin/bash

set -e

DEPLOY_DIR="~/dev/my.home"

echo "Starting restart-container script"
cd "$DEPLOY_DIR" || { echo "Failed to change directory"; exit 1; }
docker compose restart homeassistant

echo "Done."
