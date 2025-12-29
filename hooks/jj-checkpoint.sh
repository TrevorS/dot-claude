#!/bin/bash
# Auto-checkpoint jj repos when Claude Code session stops
#
# This hook runs on Claude Code Stop events. It:
# 1. Checks if we're in a jj repo
# 2. Skips if working copy is clean
# 3. Describes current change with timestamp
# 4. Creates fresh working copy for next session

# Only run in jj repos
if ! jj root &>/dev/null; then
  exit 0
fi

# Skip if working copy is clean (no changes to checkpoint)
if [ -z "$(jj diff --stat 2>/dev/null)" ]; then
  exit 0
fi

# Get current description (if any)
current_desc=$(jj log -r @ --no-graph -T 'description' 2>/dev/null)

# Only add checkpoint prefix if not already described
if [ -z "$current_desc" ] || [ "$current_desc" = "(no description set)" ]; then
  jj describe -m "checkpoint: $(date +%Y-%m-%d_%H:%M:%S)" 2>/dev/null
fi

# Create fresh working copy for next session
jj new 2>/dev/null

exit 0
