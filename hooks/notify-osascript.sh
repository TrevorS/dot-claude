#!/bin/bash

set -euo pipefail

# Check if jq is available for JSON parsing
if ! command -v jq &> /dev/null; then
    echo "Error: jq not found. Install with: brew install jq" >&2
    exit 1
fi

# Read JSON from stdin
if [ -t 0 ]; then
    echo "Error: Expected JSON input from stdin" >&2
    exit 1
fi

json_input=$(cat)

# Parse JSON fields with defaults
message=$(echo "$json_input" | jq -r '.message // "Notification from Claude Code"')
session_id=$(echo "$json_input" | jq -r '.session_id // "unknown"')
transcript_path=$(echo "$json_input" | jq -r '.transcript_path // ""')

# Extract short session ID (first 8 characters)
short_session_id="${session_id:0:8}"

# Create enhanced title based on message content
title="Claude Code"
if echo "$message" | grep -qi "permission"; then
    title="Claude Code - Permission Required"
elif echo "$message" | grep -qi -E "(error|failed|critical)"; then
    title="Claude Code - Error"
elif echo "$message" | grep -qi -E "(warning|attention)"; then
    title="Claude Code - Warning"
elif echo "$message" | grep -qi -E "(complete|success|done|finished)"; then
    title="Claude Code - Success"
fi

# Create rich subtitle with session info and timestamp
current_time=$(date '+%H:%M')
subtitle="Session ${short_session_id} • ${current_time}"

# Extract tool name from message if present
tool_name=""
if echo "$message" | grep -q "permission to use "; then
    tool_name=$(echo "$message" | sed -n 's/.*permission to use \([^[:space:]]*\).*/\1/p')
    if [[ -n "$tool_name" && "$tool_name" != "" ]]; then
        subtitle="${subtitle} • ${tool_name}"
    fi
fi

# Determine notification sound based on message content and context
sound="Ping"  # Default attention sound
if echo "$message" | grep -qi -E "(error|failed|critical)"; then
    sound="Basso"  # Error sound
elif echo "$message" | grep -qi -E "(warning|attention)"; then
    sound="Purr"   # Warning sound
elif echo "$message" | grep -qi -E "(complete|success|done|finished)"; then
    sound="Glass"  # Success sound
elif echo "$message" | grep -qi "permission"; then
    sound="Tink"   # Permission request sound
fi

# Create osascript command for notification
osascript_cmd="display notification \"$message\" with title \"$title\" subtitle \"$subtitle\" sound name \"$sound\""

# Send notification using osascript
notification_output=$(osascript -e "$osascript_cmd" 2>&1)
notification_exit_code=$?

if [ $notification_exit_code -eq 0 ]; then
    echo "Enhanced notification sent successfully for session $short_session_id"
    exit 0
else
    echo "Error: Failed to send notification" >&2
    exit 1
fi
