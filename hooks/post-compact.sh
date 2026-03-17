#!/bin/bash

set -euo pipefail

# Read compact event JSON from stdin
input=$(cat)
summary=$(echo "$input" | jq -r '.compact_summary // .summary // "context compacted"' 2>/dev/null || echo "context compacted")

# Log to journal if cj is available
if command -v cj &>/dev/null; then
  cj add --tag compact "Context compacted: $summary" 2>/dev/null || true
fi
