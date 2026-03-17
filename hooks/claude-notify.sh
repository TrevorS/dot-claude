#!/bin/bash
# Hook: Notification + Stop — Send macOS desktop notifications via claude-notify.app.
# Passes stdin through to the binary; exits 0 if binary is missing (e.g. SSH).
BINARY="$HOME/Applications/claude-notify.app/Contents/MacOS/claude-notify"
test -x "$BINARY" && exec "$BINARY" "$@" || exit 0
