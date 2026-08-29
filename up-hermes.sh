#!/bin/sh
# Recreate the hermes containers on the freshly built image and prove the
# rebuild did not disturb the local-model wiring.
#
# config.yaml lives in the bind-mounted data/ dir, so it survives a container
# recreate -- but verify rather than assume.
set -eu

cd /Users/trevor/Projects/bot

echo "=== up -d ==="
docker compose up -d 2>&1 | tail -10

echo
echo "=== containers ==="
docker ps --filter name=hermes --format '  {{.Names}}\t{{.Status}}\t{{.Image}}'

echo
echo "=== running the new image? ==="
running=$(docker inspect hermes --format '{{.Image}}' | cut -c8-19)
built=$(docker images hermes-browser:local --format '{{.ID}}')
echo "  container image: $running"
echo "  hermes-browser:local: $built"

echo
echo "=== config still points at the local MoE ==="
sed -n '1,6p' /Users/trevor/Projects/bot/data/config.yaml | sed 's/^/  /'

echo
echo "=== container can reach the model ==="
docker exec hermes sh -c \
    'curl -sf -m 5 http://host.docker.internal:8090/health >/dev/null && echo "  OK" || echo "  UNREACHABLE"'
