#!/bin/bash

# Read JSON input from stdin and extract workspace directory + Claude Code metrics
input=$(cat)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

# Extract Claude Code metrics
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty' 2>/dev/null)
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)

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
        # Append metrics even without starship
        metrics=""
        [ -n "$remaining" ] && metrics="${remaining}%"
        [ -n "$cost" ] && metrics="${metrics:+$metrics }$${cost}"
        [ -n "$metrics" ] && result="$result | $metrics"
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

# Append Claude Code metrics
metrics=""
[ -n "$remaining" ] && metrics="ctx:${remaining}%"
[ -n "$cost" ] && metrics="${metrics:+$metrics }\$${cost}"
[ -n "$metrics" ] && result="$result | $metrics"

echo "$result" | head -c 120
