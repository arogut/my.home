#!/bin/bash

echo "Restarting HA container..."

docker compose restart homeassistant

echo "Done.