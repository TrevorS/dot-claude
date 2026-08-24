#!/bin/bash
# Regression test for flagged-words.py — the PostToolUse hook that surfaces
# AI-slop words in prose written to docs, commit messages, and PR bodies.
#
# The cases that matter are about the code-fence stripper. It used to be a
# single regex whose closing fence was a backreference; because the opening
# `{3,} could backtrack, an *unclosed* fence made the match quadratic, and an
# Edit fragment carrying half a code block is routine. The hook now runs with
# `asyncRewake: true` so that no longer blocks the tool call, but a background
# process spinning for seconds is still waste and still delays the rewake, so
# the last test pins wall-clock time, not just output. The rest pin the
# stripping semantics so the rewrite can't silently start missing (or
# inventing) flagged words.
#
# Run: ./hooks/flagged-words.test.sh   (exit 0 = all pass)
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/flagged-words.py"

fails=0
ok()  { printf '  ok   PASS   %s\n' "$1"; }
bad() { printf '  FAIL        %s\n' "$1"; fails=$((fails + 1)); }

# <label> <tool> <file_path> <text> <expect: WORD:<w> | SILENT>
run() {
  local label="$1" tool="$2" path="$3" text="$4" want="$5" payload key out rc
  key=$([ "$tool" = "Write" ] && echo content || echo new_string)
  payload=$(jq -cn --arg t "$tool" --arg p "$path" --arg k "$key" --arg v "$text" \
    '{tool_name:$t, tool_input:({file_path:$p} + {($k):$v})}')
  # asyncRewake contract: stay silent and exit 0 when there is nothing to say;
  # write the suggestion to stderr and exit 2 to wake Claude when there is.
  out=$(printf '%s' "$payload" | python3 "$HOOK" 2>&1 >/dev/null); rc=$?

  if [ "$want" = "SILENT" ]; then
    if [ "$rc" -ne 0 ]; then bad "$label (exit $rc, a silent run must exit 0)"
    elif [ -n "$out" ]; then bad "$label (expected no output, got: ${out:0:60})"
    else ok "$label"; fi
    return
  fi

  if [ "$rc" -ne 2 ]; then
    bad "$label (exit $rc, a flagged run must exit 2 to rewake Claude)"; return
  fi
  if printf '%s' "$out" | grep -q "\"${want#WORD:}\""; then ok "$label"
  else bad "$label (expected ${want#WORD:} on stderr, got: ${out:0:80})"; fi
}

echo "flagged-words.py"

run "flags a slop word in prose"            Write /tmp/a.md 'This is a robust solution.'            WORD:robust
run "ignores non-doc file extensions"       Write /tmp/a.py 'This is a robust solution.'            SILENT
run "clean prose stays silent"              Write /tmp/a.md 'This reads plainly and says nothing.'  SILENT
run "commit-message filename is checked"    Write /tmp/commit-msg.txt 'A seamless change.'          WORD:seamless
run "strips closed backtick fence"          Write /tmp/a.md $'intro\n```\nrobust\n```\ndone'        SILENT
run "strips closed tilde fence"             Write /tmp/a.md $'intro\n~~~\nrobust\n~~~\ndone'        SILENT
run "longer closing fence still closes"     Write /tmp/a.md $'intro\n```\nrobust\n`````\ndone'      SILENT
run "prose after a closed fence is checked" Write /tmp/a.md $'```\ncode\n```\nA robust result.'     WORD:robust
run "unclosed fence keeps text as prose"    Write /tmp/a.md $'```bash\nrobust prose here'           WORD:robust
run "tilde does not close a backtick fence" Write /tmp/a.md $'```\nrobust\n~~~\nmore'               WORD:robust
run "Edit fragment is checked"              Edit  /tmp/a.md 'A comprehensive rewrite.'              WORD:comprehensive

# Performance: an unclosed fence over a large payload was the quadratic case.
# ~260k chars took ~4s with the old regex; the linear scan is milliseconds.
big=$(python3 -c 'print("```bash\n" + "some robust prose line here\n" * 6400, end="")')
payload=$(jq -cn --arg v "$big" '{tool_name:"Write", tool_input:{file_path:"/tmp/a.md", content:$v}}')
start=$(python3 -c 'import time; print(time.time())')
printf '%s' "$payload" | python3 "$HOOK" >/dev/null 2>&1
elapsed=$(python3 -c "import time; print(f'{time.time() - $start:.2f}')")
if python3 -c "import sys; sys.exit(0 if $elapsed < 1.0 else 1)"; then
  ok "large unclosed fence completes fast (${elapsed}s)"
else
  bad "large unclosed fence too slow (${elapsed}s, want < 1.0s)"
fi

echo
if [ "$fails" -eq 0 ]; then echo "all tests passed"; exit 0; fi
echo "$fails test(s) failed"; exit 1
