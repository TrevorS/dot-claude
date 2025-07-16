#!/bin/bash
# ABOUTME: Simple command blocker hook that provides recommendations to Claude via stderr
# ABOUTME: Blocks dangerous commands and suggests better alternatives

set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

# Exit early if we can't parse the command
[[ -n "$command" ]] || { echo "$input"; exit 0; }

# Rules: pattern~message
rules=(
    # Block cat redirects to files (cat > file.txt)
    "^cat.*\>[[:space:]]*[^[:space:]]+~Use 'echo content > file.txt' or Write tool instead"
)

# Add Python rules only if pyproject.toml exists
if [[ -f pyproject.toml ]]; then
    rules+=(
        # Block direct Python tool usage (python, pytest, pip, etc.)
        "^(python|pytest|pip|mypy|black|isort|flake8|ruff)([[:space:]]|\$)~Use 'uv run' prefix for Python commands"
        # Block direct .py file execution (but not python script.py)
        "^[^[:space:]]*\.py([[:space:]]|\$)~Use 'uv run python script.py' instead of direct execution"
    )
fi

for rule in "${rules[@]}"; do
    IFS='~' read -r pattern message <<< "$rule"

    [[ "$command" =~ $pattern ]] || continue

    echo "❌ Blocked: $message" >&2
    # Truncate long commands for readability
    if [[ ${#command} -gt 60 ]]; then
        echo "🔧 Command: ${command:0:60}..." >&2
    else
        echo "🔧 Command: $command" >&2
    fi
    exit 2
done

# If no rules match, pass through unchanged
echo "$input"
