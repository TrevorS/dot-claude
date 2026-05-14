#!/usr/bin/env bash
# PostToolUse hook: nudge toward journaling after sustained Bash activity.
#
# Silent when any of:
#   - cj binary not installed
#   - journal directory missing or not writable (bot can't journal anyway)
#   - last command was a read-only inspection
#   - last journal entry was within THRESHOLD_MINUTES
#   - last reminder fired within COOLDOWN_MINUTES
#
# Env overrides: CJ_REMINDER_MINUTES, CJ_REMINDER_COOLDOWN, CJ_REMINDER_STAMP

set -euo pipefail

THRESHOLD_MINUTES="${CJ_REMINDER_MINUTES:-60}"
COOLDOWN_MINUTES="${CJ_REMINDER_COOLDOWN:-20}"
STAMP_FILE="${CJ_REMINDER_STAMP:-$HOME/.cache/claude/journal-reminder.stamp}"

payload=$(cat)
cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

# Read-only inspection commands — these shouldn't retrigger a reminder
case "$cmd" in
	ls*|cat*|head*|tail*|wc*|find*|grep*|rg*|less*|more*|file*|stat*|du*|df*|tree*) exit 0 ;;
	pwd*|echo*|printf*|which*|whereis*|date*|ps*|top*|htop*|env*|cd*|test*|true*|false*|":"*) exit 0 ;;
	"jj log"*|"jj diff"*|"jj show"*|"jj status"*|"jj evolog"*|"jj op log"*|"jj bookmark list"*) exit 0 ;;
	"git log"*|"git diff"*|"git show"*|"git status"*|"git blame"*|"git branch"*|"git remote"*) exit 0 ;;
	"gh run view"*|"gh run watch"*|"gh run list"*|"gh pr view"*|"gh pr list"*|"gh issue view"*|"gh issue list"*) exit 0 ;;
esac

# Cooldown — suppress until COOLDOWN_MINUTES have elapsed since the last fire
if [ -f "$STAMP_FILE" ] && [ -n "$(find "$STAMP_FILE" -mmin -"$COOLDOWN_MINUTES" 2>/dev/null)" ]; then
	exit 0
fi

# Bail if the bot can't actually write to the journal — no point nagging
command -v cj >/dev/null 2>&1 || exit 0
journal_dir=$(cj dir 2>/dev/null) || exit 0
[ -d "$journal_dir" ] && [ -w "$journal_dir" ] || exit 0

last_json=$(cj last --json 2>/dev/null) || exit 0
minutes_ago=$(echo "$last_json" | jq -r '.minutes_ago // empty')
[ -z "$minutes_ago" ] && minutes_ago=999

if [ "$minutes_ago" -lt "$THRESHOLD_MINUTES" ]; then
	exit 0
fi

mkdir -p "$(dirname "$STAMP_FILE")"
touch "$STAMP_FILE"

jq -n --arg min "$minutes_ago" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: ("It has been " + $min + " minutes since you last journaled. Consider logging progress, decisions, or blockers with mcp__cj__journal_add.")
  }
}'
