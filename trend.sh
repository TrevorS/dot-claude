#!/bin/sh
# Did generation throughput decay over the 3.7 days of uptime, or drop at once?
# A gradual slide points at fragmentation or a leak; a step points at something
# that happened on the box.
set -u

LOG=/tmp/hermes-llama-server.log

echo "=== generation tok/s across the log (chronological, every ~20th sample) ==="
grep -E '\| *eval time =' "$LOG" 2>/dev/null \
    | sed -E 's/^([0-9]+)\..*tokens per second.*/\1/; s/^([0-9]+)\.[0-9.]+.*\|[^|]*eval time[^(]*\(([^,]*),[[:space:]]*([0-9.]+) tokens per second.*/\1 \3/' \
    | awk 'NF==2' | awk 'NR%20==1 {printf "  uptime %6ss  %6.2f tok/s\n", $1, $2}' | head -30

echo
echo "=== first 5 vs last 5 generation samples ==="
grep -E '\| *eval time =' "$LOG" 2>/dev/null \
    | grep -oE '[0-9.]+ tokens per second' | awk '{print $1}' > /tmp/_tps.$$
echo "  first 5:"; head -5 /tmp/_tps.$$ | sed 's/^/    /'
echo "  last 5:";  tail -5 /tmp/_tps.$$ | sed 's/^/    /'
awk '{s+=$1; n++} END {if(n) printf "\n  mean over %d samples: %.2f tok/s\n", n, s/n}' /tmp/_tps.$$
rm -f /tmp/_tps.$$

echo
echo "=== swap growth markers: memory pressure events in system log ==="
/usr/bin/log show --last 2h --predicate 'eventMessage CONTAINS "memorystatus" OR eventMessage CONTAINS "jetsam"' 2>/dev/null \
    | grep -icE 'memorystatus|jetsam' | sed 's/^/  pressure log lines (2h): /'

echo
echo "=== vm_stat detail ==="
vm_stat | awk -F: '/Pages free|Pages active|Pages inactive|Pages wired|Anonymous|File-backed|compressor|Swapouts|Swapins/ {
    gsub(/[ .]/,"",$2);
    if ($1 ~ /Swap/) printf "  %-32s %s\n", $1, $2;
    else printf "  %-32s %6.2f GB\n", $1, $2*16384/1073741824
}'
