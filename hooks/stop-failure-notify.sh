#!/bin/bash
# Hook: StopFailure — desktop-notify when a turn dies on an API error.
#
# preferredNotifChannel already covers permission prompts and task completion;
# StopFailure is the gap, and it matters for unattended sessions where a
# rate_limit death is otherwise silent.
#
# StopFailure discards output and exit code EXCEPT `terminalSequence`, hence the
# OSC 777 escape. The error type arrives in `error` (hooks reference, StopFailure
# input). Any non-empty string there is reported as-is, so a new enum value
# shows up by name: the old allow-list (verified against the 2.1.260 binary)
# did not list cloud_credential_error and reported it as "unknown". Only a missing or
# non-string `error` falls back to scanning every string for a known value.
# `error_details` (free text, 2.1.260 payload) is appended when present,
# truncated so the toast stays readable.
#
# Debounce: StopFailure can fire many times for one outage (about 14 a minute
# for a single rate limit, anthropics/claude-code#91419). One toast per
# session_id and error type per 120 s, tracked by the mtime of a stamp file
# under ${TMPDIR:-/tmp}. The stamp is refreshed only when a toast is sent, so a
# long outage still re-notifies every 120 s.
#
# Never gates: no `set -euo pipefail`, always exits 0.
#
# Regression test: hooks/stop-failure-notify.test.sh

INPUT=$(cat)

KNOWN='["rate_limit","overloaded","authentication_failed","oauth_org_not_allowed","account_on_hold","billing_error","invalid_request","model_not_found","server_error","max_output_tokens","cloud_credential_error","unknown"]'
DEBOUNCE_SECS=120

TYPE=$(printf '%s' "$INPUT" | jq -r --argjson known "$KNOWN" \
  '(.error // empty | strings | select(length > 0))
   // ([.. | strings | select(. as $s | $known | index($s))] | first)
   // "unknown"' 2>/dev/null)
# The type also names the stamp file, so keep it to enum-shaped characters.
TYPE=${TYPE//[!A-Za-z0-9_.-]/}
TYPE=${TYPE:0:40}
[ -n "$TYPE" ] || TYPE="unknown"

SID=$(printf '%s' "$INPUT" | jq -r '.session_id // "" | strings' 2>/dev/null)
SID=${SID//[!A-Za-z0-9_-]/}
STAMP="${TMPDIR:-/tmp}"
STAMP="${STAMP%/}/claude-stop-failure.${SID:-nosession}.$TYPE"
NOW=$(date +%s)
if [ -f "$STAMP" ] && LAST=$(date -r "$STAMP" +%s 2>/dev/null) \
   && [ $((NOW - LAST)) -lt "$DEBOUNCE_SECS" ]; then
  exit 0
fi
touch "$STAMP" 2>/dev/null

DIR=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
DIR=${DIR##*/}

DETAILS=$(printf '%s' "$INPUT" | jq -r '.error_details // "" | strings' 2>/dev/null)
DETAILS=${DETAILS:0:120}

# OSC 777 is `<ESC>]777;notify;<title>;<body><BEL>` — strip ';' and control
# bytes from the body so a value cannot break out of the field.
BODY="turn failed: $TYPE"
[ -n "$DIR" ] && BODY="$BODY ($DIR)"
[ -n "$DETAILS" ] && BODY="$BODY: $DETAILS"
BODY=$(printf '%s' "$BODY" | tr -d ';[:cntrl:]')

jq -cn --arg body "$BODY" \
  '{terminalSequence: ("\u001b]777;notify;Claude Code;" + $body + "\u0007")}' 2>/dev/null

exit 0
