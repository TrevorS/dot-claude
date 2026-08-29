#!/bin/sh
# Remove the flint FLUX image-gen server agent.
#
# It costs ~0 at rest (macOS pages its weights out), but it is KeepAlive'd and
# wants ~6GB the moment anything asks it for an image -- memory the box no
# longer has now that a 13.7GB model is resident for hermes.
#
# Fully reversible: the source plist stays in ~/Projects/flint/services/.
#   cp ~/Projects/flint/services/org.flint.sd-server.plist ~/Library/LaunchAgents/
#   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.flint.sd-server.plist
set -u

echo "=== before ==="
top -l 1 -n 0 -s 0 | grep PhysMem | sed 's/^/  /'
sysctl -n vm.swapusage | sed 's/^/  swap: /'

echo
echo "=== removing ==="
launchctl bootout "gui/$(id -u)/org.flint.sd-server" 2>&1 || echo "  (already stopped)"
rm -f /Users/trevor/Library/LaunchAgents/org.flint.sd-server.plist
echo "  booted out and plist deleted"

sleep 5

echo
echo "=== verify ==="
if launchctl list 2>/dev/null | grep -q org.flint.sd-server; then
    echo "  STILL LOADED"
else
    echo "  agent gone"
fi
pgrep -f 'bin/sd-server' >/dev/null 2>&1 && echo "  process STILL RUNNING" || echo "  process gone"
lsof -nP -iTCP:8085 -sTCP:LISTEN >/dev/null 2>&1 && echo "  port 8085 still bound" || echo "  port 8085 free"

echo
echo "=== after ==="
top -l 1 -n 0 -s 0 | grep PhysMem | sed 's/^/  /'
sysctl -n vm.swapusage | sed 's/^/  swap: /'

echo
echo "=== model still serving? ==="
curl -sf -m 5 http://127.0.0.1:8090/health >/dev/null 2>&1 \
    && echo "  llama-server OK" || echo "  llama-server NOT RESPONDING"
