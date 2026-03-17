#!/bin/bash
# Hook: PreToolUse (Bash) — Block git/jj commits to protected branches (main, master, dev).
# Allows override via "direct-commits-allowed: true" in ./CLAUDE.md.

set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

# Only check git/jj commit-related commands
if [[ "$command" =~ ^git[[:space:]]+(commit|add) ]] || [[ "$command" =~ ^jj[[:space:]]+(describe|new|commit) ]]; then
  : # fall through to protection check
else
  echo "$input"
  exit 0
fi

# Check for project-level override
if [ -f "./CLAUDE.md" ] && grep -qi "direct-commits-allowed: true" ./CLAUDE.md 2>/dev/null; then
  echo "$input"
  exit 0
fi

# Get current branch (try jj first — check @ then @-, then fall back to git)
current_branch=""
if command -v jj &>/dev/null && jj root &>/dev/null; then
  current_branch=$(jj log -r @ --no-graph -T 'bookmarks' 2>/dev/null | tr ',' '\n' | head -1 | xargs)
  if [ -z "$current_branch" ]; then
    current_branch=$(jj log -r '@-' --no-graph -T 'bookmarks' 2>/dev/null | tr ',' '\n' | head -1 | xargs)
  fi
fi
if [ -z "$current_branch" ]; then
  current_branch=$(git branch --show-current 2>/dev/null || echo "")
fi

# Block if on protected branch
if [[ "$current_branch" =~ ^(main|master|dev)$ ]]; then
  cat >&2 <<MSG
Blocked: committing directly to protected branch '$current_branch'.

Options:
  1. Use a feature branch instead (recommended)
  2. Ask the user if direct commits are OK for this project. If yes, add this line to ./CLAUDE.md:
     direct-commits-allowed: true
MSG
  exit 2
fi

echo "$input"
