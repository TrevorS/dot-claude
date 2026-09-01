#!/bin/bash
# UserPromptSubmit hook: one key=value line of project context per prompt.
#
# Budget. Whatever this prints lands inside the user turn on every prompt and
# stays in the transcript for the life of the session, so the cost is per-turn
# tokens x turns -- keep it to one line of terse key=value pairs, no prose. It
# is appended to the newest turn, never spliced into earlier tokens, so per-turn
# variation (change id, dirty flag) cannot invalidate the cached prefix; the
# only caching rule is to never emit anything that belongs in the system prompt.
#
# Date only, no clock: a clock time invites commentary about working late.

# Drain stdin to prevent blocking
cat > /dev/null

ctx="date=$(date '+%Y-%m-%d') cwd=$PWD"

# Repo root = nearest ancestor (cwd included) holding .jj or .git, walked in
# pure bash so a session started in a subdirectory still sees its repo without
# spawning jj/git for the lookup. .git may be a file (worktrees, submodules),
# hence -e. Nearest marker wins, so a git repo nested in a jj repo reports git.
root=$PWD vcs=none d=$PWD
while :; do
  if [[ -d $d/.jj ]]; then
    root=$d vcs=jj
    [[ -e $d/.git ]] && vcs=jj-colocated
    break
  elif [[ -e $d/.git ]]; then
    root=$d vcs=git
    break
  fi
  [[ $d == / ]] && break
  d=${d%/*}
  d=${d:-/}
done

ctx+=" vcs=$vcs"
[[ $root != "$PWD" ]] && ctx+=" root=$root"

case $vcs in
jj*)
  trunk=$(jj log -r 'trunk()' --no-graph -T 'bookmarks.join(",")' 2>/dev/null)
  [[ -n "$trunk" ]] && ctx+=" trunk=$trunk"

  # One jj call for the @ facts. Delimiter is ':' (illegal in git refnames), not
  # a tab: tab is IFS whitespace, so `read` would collapse the empty bookmark
  # column and shift `dirty` into its place.
  at=$(jj log -r @ --no-graph \
    -T 'change_id.short() ++ ":" ++ bookmarks.join(",") ++ ":" ++ if(empty, "no", "yes") ++ "\n"' \
    2>/dev/null)
  IFS=: read -r change bookmarks dirty <<< "$at"
  [[ -n "$change" ]] && ctx+=" change=$change"
  [[ -n "$bookmarks" ]] && ctx+=" bookmark=$bookmarks"
  [[ -n "$dirty" ]] && ctx+=" dirty=$dirty"
  ;;
git)
  branch=$(git branch --show-current 2>/dev/null)
  if [[ -n "$branch" ]]; then
    ctx+=" branch=$branch"
  else
    hash=$(git rev-parse --short HEAD 2>/dev/null)
    [[ -n "$hash" ]] && ctx+=" head=$hash"
  fi

  if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    ctx+=" dirty=yes"
  else
    ctx+=" dirty=no"
  fi
  ;;
esac

# Package manager from lockfile: cwd first (monorepo sub-package), then root.
detect_pkg() {
  local d=$1
  pkg=""
  if [[ -f $d/bun.lockb || -f $d/bun.lock ]]; then
    pkg=bun
  elif [[ -f $d/pnpm-lock.yaml ]]; then
    pkg=pnpm
  elif [[ -f $d/yarn.lock ]]; then
    pkg=yarn
  elif [[ -f $d/package-lock.json ]]; then
    pkg=npm
  elif [[ -f $d/uv.lock ]]; then
    pkg=uv
  elif [[ -f $d/Cargo.lock ]]; then
    pkg=cargo
  elif [[ -f $d/go.sum ]]; then
    pkg=go
  fi
}
detect_pkg "$PWD"
[[ -z $pkg && $root != "$PWD" ]] && detect_pkg "$root"
ctx+=" pkg=${pkg:-none}"

# CI/CD config lives at the repo root.
if [[ -d $root/.github/workflows ]]; then
  ctx+=" ci=github-actions"
elif [[ -f $root/.gitlab-ci.yml ]]; then
  ctx+=" ci=gitlab"
elif [[ -d $root/.circleci ]]; then
  ctx+=" ci=circleci"
else
  ctx+=" ci=none"
fi

# sed dialect. The agent's shell aliases sed to gsed whenever gsed is installed
# (`shim sed gsed sed` in dotfiles/zsh/.zshrc); this hook runs under bash and
# cannot see that alias, so it mirrors the rule: gsed by name is GNU, otherwise
# ask the sed on PATH. BSD sed rejects --version; GNU prints "(GNU sed)". The
# flag tells the agent which -i form and regex dialect to use before it guesses.
if command -v gsed >/dev/null 2>&1 || sed --version 2>/dev/null | grep -q '(GNU sed)'; then
  ctx+=" sed=gnu"
else
  ctx+=" sed=bsd"
fi

jq -cn --arg ctx "$ctx" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
