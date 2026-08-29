#!/bin/sh
# Pull a fresh nousresearch/hermes-agent base and rebuild the local browser
# image, per the note in compose.yaml ("Rebuild after pulling a new base").
#
# The previous image is tagged hermes-browser:rollback-20260828 first, so a bad
# update is one retag away from being undone.
set -eu

cd /Users/trevor/Projects/bot

echo "=== base image before ==="
docker images nousresearch/hermes-agent:latest \
    --format '  {{.ID}}  {{.CreatedSince}}  {{.Size}}' || echo "  (not present locally)"

echo
echo "=== build --pull ==="
docker compose build --pull 2>&1 | tail -25

echo
echo "=== base image after ==="
docker images nousresearch/hermes-agent:latest \
    --format '  {{.ID}}  {{.CreatedSince}}  {{.Size}}'

echo
echo "=== resulting local image ==="
docker images hermes-browser --format '  {{.Repository}}:{{.Tag}}  {{.ID}}  {{.CreatedSince}}  {{.Size}}'
