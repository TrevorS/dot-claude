#!/bin/bash
# Hook: PostToolUse — Log tool failures to the journal for debugging.
# Only acts when the tool result contains an error indicator.

set -euo pipefail

input=$(cat)

# Check if this was a failure — PostToolUse includes tool_result
is_error=$(echo "$input" | jq -r '.tool_result.is_error // .is_error // false' 2>/dev/null || echo "false")

if [ "$is_error" != "true" ]; then
  exit 0
fi

tool_name=$(echo "$input" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
error=$(echo "$input" | jq -r '.tool_result.content // .error // .message // "unknown error"' 2>/dev/null | head -c 500)

# Log to journal if cj is available
if command -v cj &>/dev/null; then
  cj add --tag tool-failure "Tool failure: $tool_name - $error" 2>/dev/null || true
fi
