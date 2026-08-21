#!/bin/bash
# Hook: PreToolUse (Bash) — Block git/jj commits to protected branches (main, master, dev).
# Allows override via "direct-commits-allowed: true" in ./CLAUDE.md.

set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

# Peel leading environment assignments and wrapper commands, so that
# `timeout 5 git push --force` is inspected as `git push --force`. Without this
# the anchored `^git`/`^jj` test below skips the segment entirely and the guard
# silently passes -- verified evadable via `timeout`, `command`, and `env`.
#
# Assigns the global `stripped` rather than echoing, for the same reason
# git_subcommand does: a $(...) call would fork a subshell per segment on a hook
# that runs for every Bash tool call.
#
# Peeling only ever exposes MORE of the command line to the checks below, so an
# over-eager strip risks a false block, never a missed one.
strip_wrappers() {
  local s="$1" prev="" rest
  while [ "$s" != "$prev" ]; do
    prev="$s"
    # VAR=value prefix (also covers `env FOO=1 ...` on the next pass).
    if [[ "$s" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*)$ ]]; then
      s="${BASH_REMATCH[1]}"; continue
    fi
    # Wrappers that take no options of their own.
    if [[ "$s" =~ ^(command|builtin|exec|nohup|setsid|time)[[:space:]]+(.*)$ ]]; then
      s="${BASH_REMATCH[2]}"; continue
    fi
    # timeout [-opts] DURATION cmd
    if [[ "$s" =~ ^timeout[[:space:]]+(-[^[:space:]]+[[:space:]]+)*[0-9]+(\.[0-9]+)?[smhd]?[[:space:]]+(.*)$ ]]; then
      s="${BASH_REMATCH[3]}"; continue
    fi
    # Wrappers that may carry their own flags, some taking a separate value.
    if [[ "$s" =~ ^(env|stdbuf|nice|ionice|sudo)[[:space:]]+(.*)$ ]]; then
      rest="${BASH_REMATCH[2]}"
      while true; do
        if [[ "$rest" =~ ^-[nucgpioeC][[:space:]]+[^[:space:]]+[[:space:]]+(.*)$ ]]; then
          rest="${BASH_REMATCH[1]}"; continue
        fi
        if [[ "$rest" =~ ^-[^[:space:]]+[[:space:]]+(.*)$ ]]; then
          rest="${BASH_REMATCH[1]}"; continue
        fi
        break
      done
      s="$rest"; continue
    fi
  done
  stripped="$s"
}

strip_wrappers "$command"
command="$stripped"

# Only check git/jj commit-related commands
is_jj=false
if [[ "$command" =~ ^jj[[:space:]]+(describe|new|commit|squash) ]]; then
  is_jj=true
elif [[ "$command" =~ ^git[[:space:]]+(commit|add) ]]; then
  : # fall through to protection check
else
  exit 0
fi

# Check for project-level override (root CLAUDE.md or .claude/CLAUDE.md)
for f in ./CLAUDE.md ./.claude/CLAUDE.md; do
  if [ -f "$f" ] && grep -qi "direct-commits-allowed: true" "$f" 2>/dev/null; then
    exit 0
  fi
done

# Get current branch
current_branch=""
if $is_jj; then
  # In jj, only check @'s bookmarks. @ is always a separate change from @-.
  # If @ has no protected bookmark, you're on an unnamed branch — that's fine,
  # even if @- is a protected branch.
  current_branch=$(jj log -r @ --no-graph -T 'bookmarks' 2>/dev/null | tr ',' '\n' | head -1 | xargs)
elif command -v jj &>/dev/null && jj root &>/dev/null; then
  # git command in a jj-colocated repo — check both @ and @-
  current_branch=$(jj log -r @ --no-graph -T 'bookmarks' 2>/dev/null | tr ',' '\n' | head -1 | xargs)
  if [ -z "$current_branch" ]; then
    current_branch=$(jj log -r '@-' --no-graph -T 'bookmarks' 2>/dev/null | tr ',' '\n' | head -1 | xargs)
  fi
else
  current_branch=$(git branch --show-current 2>/dev/null || echo "")
fi

# Block if on protected branch
if [[ "$current_branch" =~ ^(main|master|dev)$ ]]; then
  if $is_jj; then
    cat >&2 <<MSG
Blocked: @ has the '$current_branch' bookmark — you're editing the protected branch directly.

Fix: create a feature bookmark on @ first, then retry:
  jj bookmark create <feature-name> -r @
MSG
  else
    cat >&2 <<MSG
Blocked: committing directly to protected branch '$current_branch'.

Options:
  1. Use a feature branch instead (recommended)
  2. Ask the user if direct commits are OK for this project. If yes, add this line to ./CLAUDE.md:
     direct-commits-allowed: true
MSG
  fi
  exit 2
fi

exit 0
