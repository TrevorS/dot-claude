#!/bin/sh
# Block until the local model server answers /health, then prove it generates.
set -u

i=0
until curl -sf -m 3 http://127.0.0.1:8090/health >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -gt 120 ]; then
        echo "TIMED OUT waiting for health"
        tail -20 /tmp/hermes-llama-server.log
        exit 1
    fi
    sleep 2
done
echo "healthy after $((i * 2))s"

echo
echo "=== generation probe ==="
curl -s -m 300 http://127.0.0.1:8090/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d '{"model":"qwen36-35b-a3b","messages":[{"role":"user","content":"Reply with exactly: local model online"}],"max_tokens":32}' \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print('  ', d['choices'][0]['message']['content'].strip())"

echo
echo "=== reachable from the hermes container? ==="
docker exec hermes sh -c 'curl -sf -m 5 http://host.docker.internal:8090/health >/dev/null && echo "  OK: container can reach host.docker.internal:8090" || echo "  FAIL: container cannot reach it"'
