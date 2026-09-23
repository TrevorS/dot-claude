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
# No date and no cwd: since 2.1.2xx the system prompt carries today's date and
# the environment block carries the working directory, so emitting them here
# was a per-turn duplicate. Only VCS, package-manager, CI, and sed facts remain.

# Drain stdin to prevent blocking
cat > /dev/null

ctx=""

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

ctx="vcs=$vcs"
[[ $root != "$PWD" ]] && ctx+=" root=$root"

case $vcs in
jj*)
  # Bookmark names come from b.name() over local_bookmarks: the rendered list
  # decorates them (`master@origin`, `feat*`), and `bookmarks` also lists an
  # untracked remote bookmark on its own, so names repeat (`master,master`).
  # Trunk falls back to remote_bookmarks when no local bookmark points there.
  # Every jj call but the next passes --ignore-working-copy.

  # Snapshots on purpose: fileCheckpointingEnabled=false, so the per-prompt snapshot is the only restore point.
  at=$(jj log -r @ --no-graph \
    -T 'change_id.short() ++ ":" ++ if(empty, "no", "yes") ++ "\n"' \
    2>/dev/null)
  IFS=: read -r change dirty <<< "$at"

  trunk=$(jj log --ignore-working-copy -r 'trunk()' --no-graph \
    -T 'if(local_bookmarks, local_bookmarks.map(|b| b.name()).join(","), remote_bookmarks.map(|b| b.name()).join(","))' \
    2>/dev/null | tr ',' '\n' | awk 'NF && !seen[$0]++' | paste -sd, -)
  [[ -n "$trunk" ]] && ctx+=" trunk=$trunk"
  [[ -n "$change" ]] && ctx+=" change=$change"

  # The feature bookmark: the nearest bookmarked ancestors of @ that are not
  # already in trunk. A bookmark on @ itself is rare in jj (work usually sits
  # in a child of the bookmarked change), so reading only @ missed it.
  feature=$(jj log --ignore-working-copy -r 'heads((::@ & bookmarks()) ~ ::trunk())' \
    --no-graph -T 'local_bookmarks.map(|b| b.name()).join(",") ++ "\n"' 2>/dev/null)
  feature=${feature//$'\n'/,}
  [[ -n "$feature" ]] && ctx+=" bookmark=$feature"
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
