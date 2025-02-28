#!/bin/bash

echo "Restarting running containers..."

docker compose down
echo "Containers stopped..."

docker compose up -d --build
echo "Containers restarted!"