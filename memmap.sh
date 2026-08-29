#!/bin/sh
# Who is using the 24GB right now, and how much slack is left.
set -u

echo "=== totals ==="
sysctl -n hw.memsize | awk '{printf "  installed      %6.2f GB\n", $1/1073741824}'
top -l 1 -n 0 -s 0 | grep PhysMem | sed 's/^/  /'
sysctl -n vm.swapusage | sed 's/^/  swap: /'

echo
echo "=== page breakdown ==="
vm_stat | awk -F: '
/Pages free|Pages active|Pages inactive|Pages speculative|Pages wired down|Pages occupied by compressor|File-backed|Anonymous/ {
    gsub(/[ .]/,"",$2); printf "  %-30s %6.2f GB\n", $1, $2*16384/1073741824
}'

echo
echo "=== the big consumers (physical footprint, includes compressed) ==="
for pid in $(ps -Ao pid=,rss= -r | head -14 | awk '{print $1}'); do
    name=$(ps -p "$pid" -o comm= 2>/dev/null | sed 's|.*/||')
    fp=$(footprint -p "$pid" 2>/dev/null | awk '/TOTAL/{print $2, $3; exit}')
    [ -n "${fp:-}" ] && printf "  %-34s %s\n" "$name" "$fp"
done

echo
echo "=== the model server ==="
pid=$(pgrep -f 'llama-server --model' | head -1)
if [ -n "${pid:-}" ]; then
    ps -p "$pid" -o pid=,rss= | awk '{printf "  pid %s  rss %.2f GB\n", $1, $2/1048576}'
    vmmap -summary "$pid" 2>/dev/null | grep -E 'Physical footprint' | sed 's/^/  /'
else
    echo "  not running"
fi

echo
echo "=== docker ==="
docker stats --no-stream --format '  {{.Name}}  {{.MemUsage}}  {{.MemPerc}}' 2>/dev/null
ps -Ao rss=,comm= | grep -i VirtualMachine | head -1 \
    | awk '{printf "  Docker VM (host RSS)  %.2f GB\n", $1/1048576}'

echo
echo "=== idle-but-installed ==="
for label in org.flint.sd-server org.flint.keepwarm org.hermes.llama-server; do
    if launchctl list 2>/dev/null | grep -q "$label"; then
        p=$(launchctl list 2>/dev/null | awk -v l="$label" '$3==l{print $1}')
        r=$(ps -p "$p" -o rss= 2>/dev/null | awk '{printf "%.2f GB", $1/1048576}')
        echo "  $label: loaded (pid $p, rss ${r:-n/a})"
    else
        echo "  $label: not loaded"
    fi
done
