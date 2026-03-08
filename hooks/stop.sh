#!/bin/bash

# Stop hook: notify and run project-specific checks

NOTIFY="$HOME/Applications/claude-notify.app/Contents/MacOS/claude-notify"

if [ -x "$NOTIFY" ]; then
    "$NOTIFY"
fi
