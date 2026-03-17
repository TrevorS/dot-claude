#!/bin/bash

set -euo pipefail

# Read failure event JSON from stdin
input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
error=$(echo "$input" | jq -r '.error // .message // "unknown error"' 2>/dev/null || echo "unknown error")

# Log to journal if cj is available
if command -v cj &>/dev/null; then
  cj add --tag tool-failure "Tool failure: $tool_name - $error" 2>/dev/null || true
fi
