#!/bin/bash
# ABOUTME: Claude Code status line script that generates clean Starship prompts
# ABOUTME: Handles directory switching and output formatting for status line display

# Read JSON input from stdin and extract workspace directory
input=$(cat)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

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
        echo "$(basename "$(pwd)") on $(git branch --show-current 2>/dev/null || echo "no-git")"
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
    tr -d '\n\r' | head -c 120)

# Provide fallback if Starship output is empty
if [ -z "$result" ]; then
    result="$(basename "$(pwd)") on $(git branch --show-current 2>/dev/null || echo "no-git")"
fi

echo "$result"
