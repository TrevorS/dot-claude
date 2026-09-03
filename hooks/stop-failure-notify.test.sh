#!/bin/bash
# Regression test for stop-failure-notify.sh — the StopFailure hook that emits
# an OSC 777 desktop notification when a turn dies on an API error.
#
# Two things are worth pinning down. First, the error type lives in `error`, but
# the hook falls back to scanning for any string matching the known enum so a
# rename degrades gracefully; the "renamed field" and "precedence" cases guard
# both halves. Second,
# StopFailure ignores everything except `terminalSequence`, so malformed output
# fails silently in production — hence the explicit JSON-validity and
# byte-level ESC/BEL assertions.
#
# Run: ./hooks/stop-failure-notify.test.sh   (exit 0 = all pass)
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/stop-failure-notify.sh"

fails=0
ok()   { printf '  ok   PASS   %s\n' "$1"; }
bad()  { printf '  FAIL        %s\n' "$1"; fails=$((fails + 1)); }

# <label> <stdin> <substring the notification body must contain>
run() {
  local label="$1" payload="$2" want="$3" out rc body
  out=$(printf '%s' "$payload" | "$HOOK" 2>/dev/null)
  rc=$?

  if [ "$rc" -ne 0 ]; then
    bad "$label (exit $rc, must always be 0)"
    return
  fi
  if ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    bad "$label (output is not valid JSON)"
    return
  fi

  body=$(printf '%s' "$out" | jq -r '.terminalSequence // empty')
  if [ -z "$body" ]; then
    bad "$label (no terminalSequence field)"
    return
  fi
  case "$body" in
    *"$want"*) ok "$label" ;;
    *) bad "$label (body missing '$want')" ;;
  esac
}

run "known error type is extracted" \
  '{"hook_event_name":"StopFailure","error":"rate_limit","cwd":"/x/repo"}' 'rate_limit'
run "account_on_hold is a known type" \
  '{"hook_event_name":"StopFailure","error":"account_on_hold","cwd":"/x/repo"}' 'account_on_hold'
run "error field wins over stray enum strings elsewhere" \
  '{"last_assistant_message":"API Error: rate_limit","error":"overloaded","cwd":"/x/repo"}' 'overloaded'
run "unrecognised error value falls back to the scan" \
  '{"error":"brand_new_kind","error_details":"server_error","cwd":"/x/repo"}' 'server_error'
run "error type found under a renamed field" \
  '{"hookSpecificOutput":{"someFutureName":"overloaded"},"cwd":"/x/repo"}' 'overloaded'
run "cwd basename is appended" \
  '{"error":"server_error","cwd":"/a/b/myrepo"}' '(myrepo)'
run "empty payload degrades to unknown" '{}' 'unknown'
run "garbage stdin degrades to unknown" 'not json at all' 'unknown'
run "empty stdin degrades to unknown" '' 'unknown'
run "semicolons in cwd cannot break out of the OSC field" \
  '{"error":"billing_error","cwd":"/a/b;notify;EVIL"}' 'bnotifyEVIL'

# The sequence must decode to real ESC ... BEL bytes, not the literal text
# "" — jq escapes them in its JSON output and Claude Code decodes them.
seq=$(printf '%s' '{"error":"rate_limit","cwd":"/x/r"}' | "$HOOK" 2>/dev/null | jq -r '.terminalSequence')
if printf '%s' "$seq" | od -An -c | tr -s ' ' | grep -q '033 ] 7 7 7 ; n o t i f y'; then
  ok "decodes to a real ESC ]777;notify; prefix"
else
  bad "decoded prefix is not ESC ]777;notify;"
fi
if printf '%s' "$seq" | od -An -c | tr -s ' ' | grep -q '\\a'; then
  ok "terminated by a real BEL byte"
else
  bad "not terminated by BEL"
fi

if [ "$fails" -eq 0 ]; then
  echo "stop-failure-notify: all cases passed"
else
  echo "stop-failure-notify: $fails case(s) failed"
fi
exit $((fails > 0))
