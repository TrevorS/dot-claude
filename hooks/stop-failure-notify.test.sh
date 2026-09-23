#!/bin/bash
# Regression test for stop-failure-notify.sh — the StopFailure hook that emits
# an OSC 777 desktop notification when a turn dies on an API error.
#
# Three things are worth pinning down. First, any string in `error` is the
# type, so a new enum value is reported by name; only a missing or non-string
# `error` falls back to scanning for a known value. Second, StopFailure ignores
# everything except `terminalSequence`, so malformed output fails silently in
# production — hence the explicit JSON-validity and byte-level ESC/BEL
# assertions. Third, the 120 s debounce per session and error type, keyed on a
# stamp file under $TMPDIR: every other case gets a fresh TMPDIR so the
# debounce cannot swallow it.
#
# Run: ./hooks/stop-failure-notify.test.sh   (exit 0 = all pass)
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/stop-failure-notify.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fails=0
ok()   { printf '  ok   PASS   %s\n' "$1"; }
bad()  { printf '  FAIL        %s\n' "$1"; fails=$((fails + 1)); }

# <label> <stdin> <substring the notification body must contain>
run() {
  local label="$1" payload="$2" want="$3" out rc body
  out=$(printf '%s' "$payload" | TMPDIR=$(mktemp -d "$work/t.XXXXXX") "$HOOK" 2>/dev/null)
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
run "an unrecognised error value is reported by name" \
  '{"error":"brand_new_kind","error_details":"server_error","cwd":"/x/repo"}' 'turn failed: brand_new_kind'
run "cloud_credential_error is not collapsed to unknown" \
  '{"error":"cloud_credential_error","cwd":"/x/repo"}' 'turn failed: cloud_credential_error'
run "a non-string error falls back to the scan" \
  '{"error":{"kind":"overloaded"},"cwd":"/x/repo"}' 'turn failed: overloaded'
run "an empty error string falls back to the scan" \
  '{"error":"","error_details":"rate_limit","cwd":"/x/repo"}' 'turn failed: rate_limit'
run "an error value is cut to enum-shaped characters" \
  '{"error":"x;notify;EVIL","cwd":"/x/repo"}' 'turn failed: xnotifyEVIL'
run "error type found under a renamed field" \
  '{"hookSpecificOutput":{"someFutureName":"overloaded"},"cwd":"/x/repo"}' 'overloaded'
run "cwd basename is appended" \
  '{"error":"server_error","cwd":"/a/b/myrepo"}' '(myrepo)'
run "empty payload degrades to unknown" '{}' 'unknown'
run "garbage stdin degrades to unknown" 'not json at all' 'unknown'
run "empty stdin degrades to unknown" '' 'unknown'
run "semicolons in cwd cannot break out of the OSC field" \
  '{"error":"billing_error","cwd":"/a/b;notify;EVIL"}' 'bnotifyEVIL'
run "error_details is appended when present" \
  '{"error":"rate_limit","error_details":"429 retry after 30s","cwd":"/x/r"}' 'rate_limit (r): 429 retry after 30s'
run "semicolons in error_details are scrubbed too" \
  '{"error":"rate_limit","error_details":"x;notify;EVIL","cwd":"/x/r"}' 'xnotifyEVIL'
run "non-string error_details is ignored" \
  '{"error":"rate_limit","error_details":{"code":429},"cwd":"/x/r"}' 'rate_limit (r)'

# The sequence must decode to real ESC ... BEL bytes, not the literal text
# "" — jq escapes them in its JSON output and Claude Code decodes them.
seq=$(printf '%s' '{"error":"rate_limit","cwd":"/x/r"}' | TMPDIR=$(mktemp -d "$work/t.XXXXXX") "$HOOK" 2>/dev/null | jq -r '.terminalSequence')
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

# --- debounce: one toast per session and error type per 120 s ---------------
d=$(mktemp -d "$work/deb.XXXXXX")
fire() { printf '%s' "{\"session_id\":\"$1\",\"error\":\"$2\",\"cwd\":\"/x/r\"}" | TMPDIR="$d" "$HOOK" 2>/dev/null; }
if [ -n "$(fire s1 rate_limit)" ]; then ok "first failure notifies"; else bad "first failure was silent"; fi
if [ -z "$(fire s1 rate_limit)" ]; then ok "same session + type within 120 s is suppressed"; else bad "repeat was not suppressed"; fi
if [ -n "$(fire s1 overloaded)" ]; then ok "a different error type still notifies"; else bad "different type was suppressed"; fi
if [ -n "$(fire s2 rate_limit)" ]; then ok "a different session still notifies"; else bad "different session was suppressed"; fi
stamp="$d/claude-stop-failure.s1.rate_limit"
if [ -f "$stamp" ]; then
  python3 -c 'import os,sys,time; t=time.time()-300; os.utime(sys.argv[1],(t,t))' "$stamp"
  if [ -n "$(fire s1 rate_limit)" ]; then ok "a stamp older than 120 s notifies again"; else bad "stale stamp still suppressed"; fi
else
  bad "no stamp file at \$TMPDIR/claude-stop-failure.<session>.<type>"
fi
rc=$(printf '%s' '{"session_id":"s1","error":"rate_limit"}' | TMPDIR="$d" "$HOOK" >/dev/null 2>&1; echo $?)
if [ "$rc" = 0 ]; then ok "a suppressed failure still exits 0"; else bad "suppressed run exited $rc"; fi

if [ "$fails" -eq 0 ]; then
  echo "stop-failure-notify: all cases passed"
else
  echo "stop-failure-notify: $fails case(s) failed"
fi
exit $((fails > 0))
