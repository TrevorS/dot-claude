#!/bin/sh
# Start Qwen3.6-35B-A3B on llama.cpp for hermes, detached from this shell.
#
# --parallel 1 matters: llama-server defaults to n_slots=4, which sizes the KV
# pool for four concurrent requests. hermes is a single agent, so the default
# would waste 4x the KV for nothing.
#
# Bound to 0.0.0.0 because hermes runs in Docker and reaches the host via
# host.docker.internal, not loopback.
set -u

LOG=/tmp/hermes-llama-server.log

if lsof -nP -iTCP:8090 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "port 8090 already in use; not starting a second server"
    exit 0
fi

nohup /Users/trevor/Projects/llama.cpp/build/bin/llama-server \
    --model /Users/trevor/Models/Qwen3.6-35B-A3B-GGUF/Qwen3.6-35B-A3B-UD-IQ3_XXS.gguf \
    --alias qwen36-35b-a3b \
    --host 0.0.0.0 --port 8090 \
    -ngl 999 \
    --ctx-size 131072 \
    --parallel 1 \
    --cache-type-k q8_0 --cache-type-v q8_0 \
    --jinja \
    >"$LOG" 2>&1 &

echo "started pid $! (log: $LOG)"
