#!/bin/sh
# Health check for the mini after the 2026-08-28 local-model switchover.
# The model server was started with nohup and no launchd agent, so the first
# question is simply whether it is still alive.
set -u

echo "=== uptime / did the box reboot? ==="
uptime | sed 's/^/  /'
echo "  booted: $(sysctl -n kern.boottime | sed -E 's/.*sec = ([0-9]+).*/\1/' | xargs -I{} date -r {} '+%Y-%m-%d %H:%M')"

echo
echo "=== model server ==="
pid=$(pgrep -f 'llama-server --model' | head -1)
if [ -n "${pid:-}" ]; then
    ps -p "$pid" -o pid=,etime=,rss=,%cpu= \
        | awk '{printf "  pid %s  up %s  rss %.2f GB  cpu %s%%\n", $1, $2, $3/1048576, $4}'
    if curl -sf -m 5 http://127.0.0.1:8090/health >/dev/null 2>&1; then
        echo "  /health OK"
    else
        echo "  /health FAILING"
    fi
else
    echo "  NOT RUNNING"
fi

echo
echo "=== hermes ==="
docker ps --filter name=hermes --format '  {{.Names}}\t{{.Status}}\t{{.Image}}' 2>/dev/null \
    || echo "  docker not responding"
echo "  config model: $(sed -n '2p' /Users/trevor/Projects/bot/data/config.yaml 2>/dev/null | tr -d ' ')"
echo "  config url:   $(sed -n '4p' /Users/trevor/Projects/bot/data/config.yaml 2>/dev/null | tr -d ' ')"
docker exec hermes sh -c \
    'curl -sf -m 5 http://host.docker.internal:8090/health >/dev/null && echo "  container -> model: OK" || echo "  container -> model: UNREACHABLE"' 2>/dev/null \
    || echo "  container -> model: could not test"

echo
echo "=== memory ==="
top -l 1 -n 0 -s 0 | grep PhysMem | sed 's/^/  /'
sysctl -n vm.swapusage | sed 's/^/  swap: /'

echo
echo "=== disk ==="
df -h / | tail -1 | sed 's/^/  /'

echo
echo "=== model server errors since start ==="
errs=$(grep -icE 'error|failed|out of memory|assert' /tmp/hermes-llama-server.log 2>/dev/null || echo 0)
echo "  error-ish lines in llama-server log: $errs"
[ "$errs" -gt 0 ] && grep -iE 'error|failed|out of memory|assert' /tmp/hermes-llama-server.log 2>/dev/null | tail -5 | sed 's/^/    /'

echo
echo "=== recent model traffic ==="
grep -E 'eval time' /tmp/hermes-llama-server.log 2>/dev/null | tail -4 | sed 's/^/  /'
echo "  total requests served: $(grep -c 'launch_slot_' /tmp/hermes-llama-server.log 2>/dev/null || echo 0)"

echo
echo "=== leftover flint agents (should be none) ==="
launchctl list 2>/dev/null | grep -E 'flint|hermes' | sed 's/^/  /' || echo "  none loaded"
