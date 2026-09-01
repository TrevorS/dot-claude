#!/bin/sh
# What is actually consuming memory on the mini? RSS alone lies here: the model
# has been paged out, so its RSS reads ~1GB while its pages sit in swap.
set -u

echo "=== top 15 by RSS ==="
ps -Ao rss=,pid=,comm= -r | head -15 \
    | awk '{r=$1/1048576; pid=$2; $1=""; $2=""; printf "  %6.2f GB  pid %-7s %s\n", r, pid, substr($0,3)}'

echo
echo "=== top by physical footprint (includes compressed + swapped) ==="
for p in $(ps -Ao pid= -r | head -45); do
    fp=$(footprint -p "$p" 2>/dev/null | awk '/TOTAL/{print $2; exit}')
    un=$(footprint -p "$p" 2>/dev/null | awk '/TOTAL/{print $3; exit}')
    nm=$(ps -p "$p" -o comm= 2>/dev/null | sed 's|.*/||')
    case "$un" in
        GB) mb=$(echo "$fp" | awk '{printf "%.0f", $1*1024}') ;;
        MB) mb=$(echo "$fp" | awk '{printf "%.0f", $1}') ;;
        KB) mb=0 ;;
        *)  mb=0 ;;
    esac
    [ "$mb" -gt 100 ] 2>/dev/null && printf "%08d|%s %s|%s|%s\n" "$mb" "$fp" "$un" "$nm" "$p"
done 2>/dev/null | sort -r | head -14 \
    | awk -F'|' '{printf "  %-12s %-30s pid %s\n", $2, $3, $4}'

echo
echo "=== docker containers ==="
docker stats --no-stream --format '  {{.Name}}  {{.MemUsage}}  {{.MemPerc}}' 2>/dev/null

echo
echo "=== claude code sessions ==="
echo "  count: $(pgrep -cf 'claude' 2>/dev/null || echo 0)"
ps -Ao rss=,comm= | grep -i claude | awk '{s+=$1} END {printf "  combined rss: %.2f GB\n", s/1048576}'
