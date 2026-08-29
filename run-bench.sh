#!/bin/sh
# Wait for Docker Model Runner to evict the idle flint models (keepwarm is
# uninstalled, so eviction now actually happens), then run the MTP A/B.
set -u

echo "=== waiting for DMR eviction ==="
i=0
while [ "$i" -lt 42 ]; do
    n=$(docker model ps 2>/dev/null | tail -n +2 | grep -c . || echo 9)
    if [ "$n" = "0" ]; then
        echo "evicted after $((i * 10))s"
        break
    fi
    i=$((i + 1))
    sleep 10
done

echo
echo "=== memory after eviction ==="
top -l 1 -n 0 -s 0 | grep PhysMem
sysctl -n vm.swapusage

echo
python3 /Users/trevor/.claude/.claude/worktrees/qwen38-mtp-bench/bench.py
