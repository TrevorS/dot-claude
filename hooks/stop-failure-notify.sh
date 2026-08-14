#!/bin/bash
# Hook: StopFailure — desktop-notify when a turn dies on an API error.
#
# Added 2026-08-17. Replaces hooks/claude-notify.sh, which shelled out to an
# untracked machine-local binary (~/Applications/claude-notify.app). The
# Notification and Stop events no longer need a hook at all: the native
# `preferredNotifChannel` ("ghostty" here) already raises a desktop notification
# for permission prompts and task completion. StopFailure is the gap it does not
# cover, and it matters for unattended sessions (CLAUDE_CODE_RETRY_WATCHDOG=1)
# where a rate_limit death is otherwise silent.
#
# StopFailure discards output and exit code EXCEPT `terminalSequence`, so the
# notification is emitted as an escape the terminal renders. Ghostty supports
# OSC 777 (`desktop-notifications` defaults to true).
#
# The error type arrives as a matcher value (rate_limit, overloaded,
# authentication_failed, oauth_org_not_allowed, billing_error, invalid_request,
# model_not_found, server_error, max_output_tokens, unknown). The payload field
# carrying it is undocumented, so rather than guess a key this scans the payload
# for any string matching the known enum — name-agnostic, and stable if the
# field is ever renamed.
#
# Input:  JSON on stdin (StopFailure payload)
# Output: JSON with terminalSequence
#
# Output hook, not a gate: deliberately no `set -euo pipefail`, and always exits
# 0 — a failure here must never interfere with the turn.

INPUT=$(cat)

KNOWN='["rate_limit","overloaded","authentication_failed","oauth_org_not_allowed","billing_error","invalid_request","model_not_found","server_error","max_output_tokens","unknown"]'

TYPE=$(printf '%s' "$INPUT" | jq -r --argjson known "$KNOWN" \
  '[.. | strings | select(. as $s | $known | index($s))] | first // "unknown"' 2>/dev/null)
[ -n "$TYPE" ] || TYPE="unknown"

DIR=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
DIR=${DIR##*/}

# OSC 777 is `<ESC>]777;notify;<title>;<body><BEL>` — strip ';' and control
# bytes from the body so a value cannot break out of the field.
BODY="turn failed: $TYPE"
[ -n "$DIR" ] && BODY="$BODY ($DIR)"
BODY=$(printf '%s' "$BODY" | tr -d ';[:cntrl:]')

jq -cn --arg body "$BODY" \
  '{terminalSequence: ("\u001b]777;notify;Claude Code;" + $body + "\u0007")}' 2>/dev/null

exit 0
