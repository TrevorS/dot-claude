#!/bin/bash
# Hook: StopFailure — desktop-notify when a turn dies on an API error.
#
# preferredNotifChannel already covers permission prompts and task completion;
# StopFailure is the gap, and it matters for unattended sessions where a
# rate_limit death is otherwise silent.
#
# StopFailure discards output and exit code EXCEPT `terminalSequence`, hence the
# OSC 777 escape. The field carrying the error type is undocumented, so this
# scans the payload for any string in the known enum rather than guessing a key.
# Never gates: no `set -euo pipefail`, always exits 0.

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
