#!/bin/bash
# Wrapper for claude-notify — installed by `claude-notify init`
# Passes stdin through to the binary; exits 0 if binary is missing (e.g. SSH)
BINARY="/Users/trevorstrieber/Applications/claude-notify.app/Contents/MacOS/claude-notify"
test -x "$BINARY" && exec "$BINARY" "$@" || exit 0
