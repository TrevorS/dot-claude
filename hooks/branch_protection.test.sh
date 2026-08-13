#!/bin/bash
# Regression test for branch_protection.sh — the PreToolUse hook that blocks
# git/jj commits made directly on a protected branch (main/master/dev).
#
# Each case builds a throwaway repo in a temp dir so the branch name is
# controlled. This isolation is the whole point: ~/.claude's own
# .claude/CLAUDE.md carries `direct-commits-allowed: true`, so running the hook
# from the repo root would pass everything and prove nothing.
#
# Run: ./hooks/branch_protection.test.sh   (exit 0 = all pass)
set -uo pipefail
GUARD="$(cd "$(dirname "$0")" && pwd)/branch_protection.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fails=0
run() { # <want BLOCK|PASS> <branch> <override yes|no> <command> <label>
  local want="$1" branch="$2" override="$3" cmd="$4" label="$5"
  local dir="$tmp/$RANDOM$RANDOM" json rc got
  mkdir -p "$dir"
  git -C "$dir" init -q -b "$branch" 2>/dev/null
  [ "$override" = yes ] && printf 'direct-commits-allowed: true\n' > "$dir/CLAUDE.md"
  json=$(python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$cmd")
  ( cd "$dir" && printf '%s' "$json" | "$GUARD" >/dev/null 2>&1 ); rc=$?
  [ "$rc" -eq 2 ] && got=BLOCK || got=PASS
  if [ "$got" = "$want" ]; then
    printf '  ok   %-6s %s\n' "$got" "$label"
  else
    printf '  FAIL %-6s (want %s) %s\n' "$got" "$want" "$label"; fails=$((fails+1))
  fi
}

# --- protected branches block commit-shaped commands ---
run BLOCK master no 'git commit -m "x"'   'git commit on master'
run BLOCK main   no 'git commit -m "x"'   'git commit on main'
run BLOCK dev    no 'git commit -m "x"'   'git commit on dev'
run BLOCK master no 'git add .'           'git add on master'

# --- feature branches are always fine ---
run PASS  feature no 'git commit -m "x"'  'git commit on feature branch'
run PASS  wip-123 no 'git add .'          'git add on feature branch'

# --- the documented per-project escape hatch ---
run PASS  master yes 'git commit -m "x"'  'master + direct-commits-allowed override'

# --- non-commit commands are out of scope even on master ---
run PASS  master no 'git status'          'git status on master'
run PASS  master no 'git log --oneline'   'git log on master'
run PASS  master no 'git push'            'git push on master (not commit-shaped)'
run PASS  master no 'echo hi'             'unrelated command on master'

echo
if [ "$fails" -eq 0 ]; then echo "branch_protection: all cases passed"; else echo "$fails failing"; fi
exit $(( fails > 0 ))
