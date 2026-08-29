#!/bin/sh
# Point hermes at the local Qwen3.6-35B-A3B server instead of the spark.
#
# Line-targeted edits rather than a YAML round-trip: config.yaml carries 36
# comments that a load/dump cycle would silently delete.
#
# base_url uses host.docker.internal because hermes runs in a container -- from
# inside it, 127.0.0.1 is the container, not the Mac.
# context_length drops 262144 -> 131072 to match what the local server serves.
# max_tokens (32768) is left alone; it still fits inside 131072.
set -eu

CFG=/Users/trevor/Projects/bot/data/config.yaml

sed -i '' \
    -e '2s|default: qwen38-flash-next|default: qwen36-35b-a3b|' \
    -e '4s|base_url: http://spark-ebf0.local:8081/v1|base_url: http://host.docker.internal:8090/v1|' \
    -e '5s|context_length: 262144|context_length: 131072|' \
    -e '10s|qwen38-flash-next:|qwen36-35b-a3b:|' \
    "$CFG"

echo "=== resulting model block ==="
sed -n '1,12p' "$CFG"

echo
echo "=== comments preserved? ==="
echo "  comment lines now: $(grep -c '^[[:space:]]*#' "$CFG")  (was 36)"

echo
echo "=== yaml still parses? ==="
python3 -c "import yaml,sys; yaml.safe_load(open('$CFG')); print('  OK')"
