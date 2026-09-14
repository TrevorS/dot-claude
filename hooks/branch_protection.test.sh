#!/bin/bash
# Regression test for branch_protection.sh — the PreToolUse hook that blocks
# git/jj commits made directly on a protected branch (main/master/dev).
#
# Each case builds a throwaway repo in a temp dir so the branch state is
# controlled. This isolation is the whole point: ~/.claude's own
# .claude/CLAUDE.md carries `direct-commits-allowed: true`, so running the hook
# from the repo root would pass everything and prove nothing.
#
# jj cases build a colocated repo WITH a remote so the protected bookmark can
# sit ahead of origin -- jj renders that as `master*`, and the hook's first
# version matched the rendered string, so it never saw it (0 fires in 30 days).
#
# Run: ./hooks/branch_protection.test.sh   (exit 0 = all pass)
set -uo pipefail
GUARD="$(cd "$(dirname "$0")" && pwd)/branch_protection.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fails=0
verdict() { # <want> <rc> <label>  -- exit 2 is BLOCK, 0 is PASS, anything else is a hook bug
  local want="$1" rc="$2" label="$3" got
  case "$rc" in 2) got=BLOCK ;; 0) got=PASS ;; *) got="ERR($rc)" ;; esac
  if [ "$got" = "$want" ]; then
    printf '  ok   %-6s %s\n' "$got" "$label"
  else
    printf '  FAIL %-6s (want %s) %s\n' "$got" "$want" "$label"; fails=$((fails+1))
  fi
}
payload() { python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$1"; }

run() { # <want BLOCK|PASS> <branch> <override yes|no> <command> <label>
  local want="$1" branch="$2" override="$3" cmd="$4" label="$5"
  local dir="$tmp/$RANDOM$RANDOM" rc
  mkdir -p "$dir"
  git -C "$dir" init -q -b "$branch" 2>/dev/null
  [ "$override" = yes ] && printf 'direct-commits-allowed: true\n' > "$dir/CLAUDE.md"
  ( cd "$dir" && printf '%s' "$(payload "$cmd")" | "$GUARD" >/dev/null 2>&1 ); rc=$?
  verdict "$want" "$rc" "$label"
}

# --- protected branches block commit-shaped commands ---
run BLOCK master no 'git commit -m "x"'   'git commit on master'
run BLOCK main   no 'git commit -m "x"'   'git commit on main'
run BLOCK dev    no 'git commit -m "x"'   'git commit on dev'
run BLOCK master no 'git add .'           'git add on master'
run BLOCK master no 'git status && git commit -m "x"'  'git commit in a && chain on master'
run BLOCK master no 'timeout 30 git commit -m "x"'     'git commit behind a wrapper on master'

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
# jj commands in a plain git repo: jj fails, the hook must exit 0, not crash (was exit 1).
run PASS  master no 'jj describe -m x'    'jj command in a non-jj repo'

# ---------------------------------------------------------------------------
# jj: colocated repo with a remote. master@origin = init commit; @ = empty
# child of master. Setup snippets then shape the working copy per case.
# ---------------------------------------------------------------------------
have_jj=0; command -v jj >/dev/null 2>&1 && have_jj=1

mk_jj_repo() { # <dir>
  local dir="$1"
  git init -q -b master "$dir"
  git -C "$dir" -c user.email=t@x -c user.name=t commit -q --allow-empty -m init
  git init -q --bare -b master "$dir.git"
  git -C "$dir" remote add origin "$dir.git"
  git -C "$dir" push -q origin master
  ( cd "$dir" && jj git init --colocate )
}

run_jj() { # <want BLOCK|PASS> <setup shell> <override yes|no> <command> <label>
  local want="$1" setup="$2" override="$3" cmd="$4" label="$5"
  local dir="$tmp/jj$RANDOM$RANDOM" rc
  if [ "$have_jj" -eq 0 ]; then printf '  skip %-6s %s (jj not installed)\n' "$want" "$label"; return; fi
  mk_jj_repo "$dir" >/dev/null 2>&1
  ( cd "$dir" && eval "$setup" ) >/dev/null 2>&1
  if [ "$override" = yes ]; then mkdir -p "$dir/.claude"; printf 'direct-commits-allowed: true\n' > "$dir/.claude/CLAUDE.md"; fi
  ( cd "$dir" && printf '%s' "$(payload "$cmd")" | "$GUARD" >/dev/null 2>&1 ); rc=$?
  verdict "$want" "$rc" "$label"
}

# @ carries master, ahead of origin -> renders as `master*`.
ON_MASTER='jj describe -m work; jj bookmark set master -r @'
# @ is off master; @- carries master (at origin, no decoration).
OFF_MASTER=''
# @ is off master; @- carries master* (ahead of origin).
OFF_MASTER_AHEAD='jj describe -m a; jj bookmark set master -r @; jj new -m b'
# @ = b, @- = a carries feat, @-- = master.
FEATURE='jj describe -m a; jj bookmark create feat -r @; jj new -m b'
# @ carries two bookmarks, `feat* master*`.
MULTI='jj describe -m a; jj bookmark create feat -r @; jj bookmark set master -r @'

echo
echo "jj: rewriting the change that carries master"
run_jj BLOCK "$ON_MASTER" no 'jj describe -m x'      'jj describe on @ = master*'
run_jj BLOCK "$ON_MASTER" no 'jj commit -m x'        'jj commit on @ = master*'
run_jj BLOCK "$ON_MASTER" no 'git commit -m x'       'git commit in colocated repo, @ = master*'
run_jj BLOCK "$MULTI"     no 'jj describe -m x'      'jj describe on @ = feat* master*'
run_jj BLOCK "$OFF_MASTER_AHEAD" no 'jj describe -r @- -m x'  'jj describe -r <master change>'
run_jj BLOCK "$OFF_MASTER_AHEAD" no 'jj describe master -m x' 'jj describe <master> (positional)'
run_jj BLOCK "$ON_MASTER" no 'JJ_EDITOR="$(jq -r .x)" timeout 10 jj describe -m x' 'wrapped jj describe on master*'
run_jj PASS  "$ON_MASTER" yes 'jj describe -m x'     'master* + direct-commits-allowed override'
run_jj PASS  "$ON_MASTER" no 'jj new'                'jj new on master* (creates a child, moves nothing)'
run_jj PASS  "$ON_MASTER" no 'jj log'                'jj log on master*'
run_jj PASS  "$OFF_MASTER_AHEAD" no 'jj describe -m x'  'jj describe on @ when only @- is master*'
run_jj PASS  "$OFF_MASTER_AHEAD" no 'jj commit -m x'    'jj commit on @ when only @- is master*'

echo
echo "jj: squashing into the change that carries master"
run_jj BLOCK "$OFF_MASTER"       no 'jj squash'                  'jj squash into @- = master'
run_jj BLOCK "$OFF_MASTER_AHEAD" no 'jj squash -m x'             'jj squash into @- = master*'
run_jj BLOCK "$OFF_MASTER_AHEAD" no 'jj log && jj squash -m x'   'jj squash in a && chain'
run_jj BLOCK "$FEATURE"          no 'jj squash --into master -m x'      'jj squash --into master'
run_jj BLOCK "$FEATURE"          no 'jj squash --from @ --into master -u' 'jj squash --from/--into master'
run_jj BLOCK "$ON_MASTER"        no 'jj squash -m x'             'jj squash FROM master* (empties it)'
run_jj PASS  "$FEATURE"          no 'jj squash -m x'             'jj squash into @- = feat'
run_jj PASS  "$FEATURE"          no 'jj squash --into feat -m x' 'jj squash --into feat'
run_jj BLOCK "$OFF_MASTER_AHEAD" no 'git commit -m x'            'git commit in colocated repo, @- = master*'

echo
echo "jj: moving the master bookmark"
run_jj BLOCK "$OFF_MASTER_AHEAD" no 'jj bookmark set master -r @'        'jj bookmark set master'
run_jj BLOCK "$OFF_MASTER_AHEAD" no 'jj bookmark move master --to @'     'jj bookmark move master'
run_jj BLOCK "$OFF_MASTER_AHEAD" no 'jj bookmark move --from @- --to @'  'jj bookmark move --from <master change>'
run_jj BLOCK "$OFF_MASTER_AHEAD" no 'jj bookmark advance master'         'jj bookmark advance master'
run_jj BLOCK "$OFF_MASTER_AHEAD" no 'jj b s master -r @'                 'jj b s master (aliases)'
run_jj PASS  "$OFF_MASTER_AHEAD" no 'jj bookmark set feat -r @'          'jj bookmark set feat'
run_jj PASS  "$FEATURE"          no 'jj bookmark move feat --to @'       'jj bookmark move feat'
run_jj PASS  "$OFF_MASTER_AHEAD" no 'jj bookmark list'                   'jj bookmark list'
run_jj PASS  "$OFF_MASTER_AHEAD" no 'jj new master'                      'jj new master (start work off master)'

echo
if [ "$fails" -eq 0 ]; then echo "branch_protection: all cases passed"; else echo "$fails failing"; fi
exit $(( fails > 0 ))
