#!/bin/bash
# Regression test for git_dangerous_flags.sh — the PreToolUse hook that blocks
# history-rewriting / verification-skipping git and gh commands. Each case feeds
# a tool_input.command and asserts the hook either BLOCKs (exit 2) or PASSes.
#
# Run: ./hooks/git_dangerous_flags.test.sh   (exit 0 = all pass)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
GUARD=./hooks/git_dangerous_flags.sh

fails=0
run() { # <want BLOCK|PASS> <command>
  local want="$1" cmd="$2" json rc got
  json=$(python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$cmd")
  printf '%s' "$json" | "$GUARD" >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 2 ] && got=BLOCK || got=PASS
  if [ "$got" = "$want" ]; then
    printf '  ok   %-6s %s\n' "$got" "$cmd"
  else
    printf '  FAIL %-6s (want %s) %s\n' "$got" "$want" "$cmd"; fails=$((fails+1))
  fi
}

# --- force-push: every spelling and flag position ---
run BLOCK 'git push --force'
run BLOCK 'git push -f'
run BLOCK 'git push --force-with-lease'
run BLOCK 'git push origin feature --force'            # flag AFTER positionals
run BLOCK 'git push origin feature -f'
run BLOCK 'git -C /some/path push --force'             # global -C before subcommand
run BLOCK 'git -c user.name=x push --force'
run BLOCK 'git --git-dir=/r/.git push -f'              # attached global
run BLOCK 'git push --force-if-includes origin main'
run BLOCK 'jj git push && git push --force'            # dangerous half of a chain

# --- amend / no-verify ---
run BLOCK 'git commit --amend -m "x"'
run BLOCK 'git commit -m "x" --amend'
run BLOCK 'git commit --amend --no-edit'
run BLOCK 'git commit -n -m "x"'
run BLOCK 'git commit --no-verify -m "x"'
run BLOCK 'git push --no-verify'

# --- reset --hard (from rules/version-control.md, not the 2.1.229 line) ---
run BLOCK 'git reset --hard origin/main'
run BLOCK 'git reset origin/main --hard'

# --- gh admin merge ---
run BLOCK 'gh pr merge 42 --admin --squash'

# --- must NOT block: -f/-n mean something else on other subcommands ---
run PASS  'git push'
run PASS  'git push origin main'
run PASS  'git push -u origin feature'
run PASS  'git push -n'                                # -n on push is --dry-run
run PASS  'git push --dry-run'
run PASS  'git clean -f'                               # -f here is local cleanup
run PASS  'git branch -f wip HEAD'
run PASS  'git tag -f v1'
run PASS  'git checkout -f main'
run PASS  'git commit -m "x"'
run PASS  'git reset --soft HEAD~2'                    # the documented squash idiom
run PASS  'git reset HEAD~1'
run PASS  'git log --oneline -n 5'
run PASS  'git status'
run PASS  'gh pr merge 42 --squash'
run PASS  'gh pr view 42 --json reviews,comments'
run PASS  'git push --help'
run PASS  'jj git push'                                # jj-prefixed, not our business
run PASS  'echo "git push --force"'                    # not a git segment at all

# --- flags that only LOOK dangerous because they sit inside a message ---
run PASS  'git commit -m "explain why --amend is risky"'
run PASS  'git commit -m "do not use --no-verify here"'
run PASS  'git commit -m "revert the --force push"'
run PASS  $'git commit -m "line one\n--amend in prose"'  # multi-line message

# --- wrapper prefixes must not smuggle a dangerous command past the anchor ---
# The segment gate is anchored on ^git/^gh, so `timeout 5 git push --force` used
# to slip through entirely. strip_wrappers() peels these before the gate.
run BLOCK 'timeout 5 git push --force'
run BLOCK 'timeout --preserve-status 10s git push -f'
run BLOCK 'command git push --force'
run BLOCK 'env git push --force'
run BLOCK 'env FOO=1 git push --force'
run BLOCK 'FOO=1 BAR=2 git push --force'
run BLOCK 'nice -n 10 git push --force'
run BLOCK 'sudo -u someone git push --force'
run BLOCK 'nohup git push --force'
run BLOCK 'stdbuf -oL git push --force'
run BLOCK 'git status && timeout 5 git push --force'   # wrapper in the second segment
run PASS  'timeout 5 git status'                       # wrapper on a safe command
run PASS  'git commit -m "timeout 5 git push --force"' # wrapper name inside a message

echo
if [ "$fails" -eq 0 ]; then echo "all pass"; else echo "$fails failing"; fi
exit $(( fails > 0 ))
