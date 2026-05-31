#!/bin/bash
# Regression test for jj_interactive_guard.sh — the PreToolUse hook that blocks
# editor-opening jj commands. Each case feeds a tool_input.command and asserts
# the hook either BLOCKs (exit 2) or PASSes (exit 0).
#
# Run: ./hooks/jj_interactive_guard.test.sh   (exit 0 = all pass)
set -uo pipefail
cd "$(dirname "$0")/.."
GUARD=./hooks/jj_interactive_guard.sh

fails=0
run() { # <want BLOCK|PASS> <command>
  local want="$1" cmd="$2" json out rc got
  json=$(python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$cmd")
  out=$(printf '%s' "$json" | "$GUARD" 2>/dev/null); rc=$?
  [ "$rc" -eq 2 ] && got=BLOCK || got=PASS
  if [ "$got" = "$want" ]; then
    printf '  ok   %-6s %s\n' "$got" "$cmd"
  else
    printf '  FAIL %-6s (want %s) %s\n' "$got" "$want" "$cmd"; fails=$((fails+1))
  fi
}

# --- should BLOCK (would open an editor / wrong subcommand) ---
run BLOCK 'jj squash --into poquykmp && jj edit poquykmp && jj forget .claude/x.lock && jj new'
run BLOCK 'jj squash'
run BLOCK 'jj describe'
run BLOCK 'jj commit'
run BLOCK 'jj split'
run BLOCK 'jj split --tool meld'
run BLOCK 'jj diffedit -r @-'
run BLOCK 'jj forget foo.txt'
run BLOCK 'jj resolve'
run BLOCK 'cd /tmp && jj squash --into @-'
run BLOCK 'jj config edit'
run BLOCK 'jj config edit --user'
run BLOCK 'jj commit -m "msg" -i'
run BLOCK 'jj squash -m "msg" --interactive'
run BLOCK 'jj commit -m "msg" --tool meld'
run BLOCK 'jj squash -u --tool meld'

# --- should PASS (non-interactive / unrelated) ---
run PASS 'jj squash -m "fix"'
run PASS 'jj squash --into @- -u'
run PASS 'jj describe -m "msg"'
run PASS 'jj commit -m "msg"'
run PASS 'jj new -m "wip"'
run PASS 'jj new'
run PASS 'jj file untrack foo.lock'
run PASS 'jj log -r @ --no-graph'
run PASS 'jj resolve --tool :ours'
run PASS 'jj config set ui.editor nvim'
run PASS 'jj config get ui.editor'
run PASS 'jj squash --message="combine -i please"'
run PASS 'jj describe -m "use -i for interactive"'
run PASS 'jj commit --help'
run PASS 'jj squash -h'
run PASS 'jj describe --help | head'
run PASS 'git commit -m "x"'
run PASS 'echo "jj squash without -m is bad"'

echo
if [ "$fails" -eq 0 ]; then
  echo "jj_interactive_guard: all cases passed"
else
  echo "jj_interactive_guard: $fails case(s) FAILED" >&2
fi
exit "$fails"
