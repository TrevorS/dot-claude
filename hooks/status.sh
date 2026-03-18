#!/bin/bash
# Hook: statusLine — Render starship prompt + context remaining % for the status bar.
# Falls back to directory + git branch if starship is unavailable.

# Read JSON input from stdin and extract workspace directory + Claude Code metrics
input=$(cat)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

# Extract context remaining percentage
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty' 2>/dev/null)

# Extract rate limit usage (5-hour window)
rate_used=$(echo "$input" | jq -r '.rate_limits[0].used_percentage // empty' 2>/dev/null)

# Change to the workspace directory, fallback to current directory if needed
if [ -n "$dir" ] && [ -d "$dir" ]; then
    cd "$dir"
else
    cd "${PWD:-$HOME}"
fi

# Locate starship executable
if [ ! -x "/opt/homebrew/bin/starship" ]; then
    starship_path=$(which starship 2>/dev/null)
    if [ -z "$starship_path" ]; then
        result="$(basename "$(pwd)") on $(git branch --show-current 2>/dev/null || echo "no-git")"
        [ -n "$remaining" ] && result="$result | ctx:${remaining}%"
        [ -n "$rate_used" ] && result="$result | rl:${rate_used}%"
        echo "$result"
        exit 0
    fi
    STARSHIP_CMD="$starship_path"
else
    STARSHIP_CMD="/opt/homebrew/bin/starship"
fi

# Generate clean Starship prompt output
export STARSHIP_SHELL=generic
result=$("$STARSHIP_CMD" prompt --terminal-width=120 2>/dev/null | \
    sed 's/❯[[:space:]]*$//' | \
    sed 's/%{[^}]*}//g' | \
    tr -s ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
    tr -d '\n\r' | head -c 80)

# Provide fallback if Starship output is empty
if [ -z "$result" ]; then
    result="$(basename "$(pwd)") on $(git branch --show-current 2>/dev/null || echo "no-git")"
fi

# Append context remaining and rate limit
[ -n "$remaining" ] && result="$result | ctx:${remaining}%"
[ -n "$rate_used" ] && result="$result | rl:${rate_used}%"

echo "$result" | head -c 120
