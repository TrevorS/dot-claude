#!/bin/bash
# ABOUTME: Warns when attempting git commits on protected branches
# ABOUTME: Simple branch protection for main/master/dev

set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

# Only check git commit commands
[[ "$command" =~ ^git[[:space:]]+(commit|add) ]] || { echo "$input"; exit 0; }

# Get current branch
current_branch=$(git branch --show-current 2>/dev/null || echo "")

# Warn if on protected branch
if [[ "$current_branch" =~ ^(main|master|dev)$ ]]; then
    echo "⚠️  On protected branch '$current_branch' - consider using a feature branch" >&2
fi

echo "$input"
