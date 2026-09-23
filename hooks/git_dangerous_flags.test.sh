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

# --- reset --hard (listed in rules/pr-safety.md, not the 2.1.229 line) ---
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
# The segment gate is anchored on ^git/^gh, and strip_wrappers() peels these
# before it. In the harness this only matters inside a compound command: the
# `if: Bash(git *)` filter never runs the hook for a command that STARTS with a
# wrapper, so the direct forms below are parser tests, not live paths.
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
# An assignment value is one shell word even when it holds whitespace inside
# quotes or $(...). The old prefix regex stopped at the first space and skipped
# the segment entirely.
run BLOCK 'X="$(a b)" git push --force'
run BLOCK 'X=$(a b) git push -f'
run BLOCK "X='a b' git commit --amend"
run BLOCK 'X="a\" b" git push --force'                  # escaped quote in the value
run BLOCK 'X="$(echo "a b")" git push --force'          # quotes nested inside $( )
run PASS  'X="$(a b)" git push'
run PASS  'X="git push --force" echo hi'                # git only inside the value

# --- a leading + on a refspec force-pushes that ref ---
run BLOCK 'git push origin +master'
run BLOCK 'git push origin +HEAD:refs/heads/feat'
run PASS  'git push origin HEAD:refs/heads/feat'
# --- heredoc bodies are data: an apostrophe in one opened a quote that hid
# every later command (4 commits to master slipped past, 2026-09-18) ---
run BLOCK $'git commit -F - <<EOF\nfix: don\'t break\nEOF\ngit push --force'
run BLOCK $'cat > /tmp/m <<\'EOF\'\nit\'s fine\nEOF\ngit commit --amend -F /tmp/m'
run BLOCK $'cat <<-EOF > /tmp/m\n\tdon\'t\n\tEOF\ngit push -f'   # <<- strips leading tabs
run BLOCK $'bash <<EOF\ngit push --force\nEOF'                    # body lines are still checked
run BLOCK $'cat <<A <<B\nit\'s\nA\nwon\'t\nB\ngit push -f'        # two heredocs on one line
run PASS  $'git commit -F - <<EOF\nfix: don\'t break\nEOF\ngit push'
run PASS  'grep -c x <<< "a b" && git push'                       # here-string, not a heredoc

# --- \" inside double quotes is a literal quote, not the end of the string ---
# Read as a closing quote, it reopened a quote over the && and hid the push.
run BLOCK 'git commit -m "say \"hi\"" && git push --force'
run BLOCK 'git commit -m "a \\" && git push -f'                # \\ then a real closing quote
run BLOCK 'git commit -m "x \" y" --amend'                      # --amend after the message
run PASS  'git commit -m "say \"hi\" && git push --force"'     # all message text
run PASS  'git commit -m "say \"hi\"" && git push'

# --- every command boundary starts a segment: ( ) { } | & and backtick ---
run BLOCK '(git push --force)'
run BLOCK 'echo x | xargs git push -f'
run BLOCK 'echo x | xargs -I {} git push -f {}'                  # xargs option with a value
run BLOCK '{ git push --force; }'
run BLOCK 'for r in a; do git push -f; done'
run BLOCK 'echo $(git push -f)'
run BLOCK 'echo `git push -f`'
run BLOCK 'git fetch & git push -f'
run BLOCK 'if git push -f; then :; fi'
run BLOCK 'if true; then git status; else git push -f; fi'
run BLOCK '! git commit --amend'
run PASS  '(git push)'
run PASS  'echo x | xargs git status'
run PASS  'for r in a; do git push; done'
run PASS  'git log $(git rev-parse HEAD) | head'
run PASS  'git log 2>&1 | head'                                  # 2>&1 is a redirection, not &
run PASS  'git status &>/dev/null && git push'
run PASS  'git status >| /tmp/out'
run PASS  'git log @{u}..HEAD'                                   # braces inside a word
run PASS  'git log --format=x HEAD@{1} ${X}'

# --- bundled short flags, and option values are never flags ---
run BLOCK 'git push -uf'
run BLOCK 'git push -fu origin feat'
run BLOCK 'git push -vf'
run BLOCK 'git commit -nm x'
run BLOCK 'git commit -anm x'
run BLOCK 'git commit -m "-h" --amend'                           # the message is not --help
run PASS  'git push -uv origin feat'
run PASS  'git push -o -f'                                       # -o takes "-f" as its value
run PASS  'git commit -am x'
run PASS  'git commit -mn'                                       # -m with the message "n"
run PASS  'git commit -amn'
run PASS  'git commit -am "-n"'
run PASS  'git commit -m -n'
run PASS  'git commit -m --amend'
run PASS  'git commit -F -n'                                     # -F takes a file name
run PASS  'git commit -m x -- -n'                                # a path after --

# --- messages point at real remedies ---
msg=$(printf '%s' '{"tool_input":{"command":"git commit -n -m x"}}' | "$GUARD" 2>&1 >/dev/null)
case "$msg" in
  *"make pre-commit"*) printf '  FAIL        --no-verify message names a ~/.claude-only make target\n'; fails=$((fails+1)) ;;
  *) printf '  ok   PASS   --no-verify message is repo-neutral\n' ;;
esac

echo
if [ "$fails" -eq 0 ]; then echo "all pass"; else echo "$fails failing"; fi
exit $(( fails > 0 ))
