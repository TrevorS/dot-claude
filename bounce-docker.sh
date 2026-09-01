#!/bin/sh
# Restart Docker Desktop to reclaim the VM memory balloon (~21GB of footprint
# against a 7.75GB configured MemTotal, while its containers need ~1GB).
#
# Both containers are `restart: unless-stopped`, so they should come back on
# their own; this verifies that rather than assuming it.
set -u

echo "=== before ==="
top -l 1 -n 0 -s 0 | grep PhysMem | sed 's/^/  /'
sysctl -n vm.swapusage | sed 's/^/  swap: /'
top -l 1 -o mem -n 3 -stats pid,command,mem,cmprs 2>/dev/null | tail -4 | sed 's/^/  /'

echo
echo "=== restarting docker desktop ==="
docker desktop restart 2>&1 | sed 's/^/  /'

echo
echo "=== waiting for engine ==="
i=0
until docker info >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -gt 90 ]; then echo "  TIMED OUT waiting for docker"; exit 1; fi
    sleep 2
done
echo "  engine up after $((i * 2))s"

echo
echo "=== waiting for hermes container ==="
i=0
until docker ps --filter name=^hermes$ --filter status=running --format '{{.Names}}' 2>/dev/null | grep -q hermes; do
    i=$((i + 1))
    if [ "$i" -gt 90 ]; then
        echo "  hermes did not come back on its own; starting it"
        docker compose -f /Users/trevor/Projects/bot/compose.yaml up -d 2>&1 | sed 's/^/    /'
        break
    fi
    sleep 2
done
docker ps --filter name=hermes --format '  {{.Names}}\t{{.Status}}' 2>/dev/null

echo
echo "=== after ==="
top -l 1 -n 0 -s 0 | grep PhysMem | sed 's/^/  /'
sysctl -n vm.swapusage | sed 's/^/  swap: /'
top -l 1 -o mem -n 3 -stats pid,command,mem,cmprs 2>/dev/null | tail -4 | sed 's/^/  /'

echo
echo "=== model still serving? ==="
curl -sf -m 5 http://127.0.0.1:8090/health >/dev/null 2>&1 \
    && echo "  llama-server OK" || echo "  llama-server NOT RESPONDING"

echo
echo "=== container -> model ==="
docker exec hermes sh -c \
    'curl -sf -m 8 http://host.docker.internal:8090/health >/dev/null && echo "  OK" || echo "  UNREACHABLE"' 2>/dev/null \
    || echo "  could not test yet (container may still be starting)"
