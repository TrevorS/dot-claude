#!/usr/bin/env bash
# PostToolUse hook: remind Claude to journal if it's been a while.
# Reads PostToolUse JSON from stdin, checks elapsed time via `cj last --json`,
# and injects additionalContext if threshold exceeded.

set -euo pipefail

THRESHOLD_MINUTES="${CJ_REMINDER_MINUTES:-10}"

# Consume stdin (required — PostToolUse sends JSON)
cat > /dev/null

# Check last journal entry time
last_json=$(cj last --json 2>/dev/null) || exit 0
minutes_ago=$(echo "$last_json" | jq -r '.minutes_ago // empty')

# No entries at all — remind
if [ -z "$minutes_ago" ]; then
	minutes_ago=999
fi

# Under threshold — stay quiet
if [ "$minutes_ago" -lt "$THRESHOLD_MINUTES" ]; then
	exit 0
fi

# Emit reminder as additionalContext
jq -n --arg min "$minutes_ago" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: ("It has been " + $min + " minutes since you last journaled. Consider logging progress, decisions, or blockers with mcp__cj__journal_add.")
  }
}'
