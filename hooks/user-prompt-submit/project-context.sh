#!/bin/bash
# Outputs project context for Claude on each prompt
# Input: JSON on stdin (ignored)
# Output: JSON with additionalContext

# Drain stdin to prevent blocking
cat > /dev/null

ctx="time=$(date '+%Y-%m-%d %H:%M %z') cwd=$PWD"

if [[ -d .jj ]]; then
  if [[ -d .git ]]; then
    ctx+=" vcs=jj-colocated"
  else
    ctx+=" vcs=jj"
  fi

  change=$(jj log -r @ --no-graph -T 'change_id.short()' 2>/dev/null) && ctx+=" change=$change"
  bookmarks=$(jj log -r @ --no-graph -T 'bookmarks.join(",")' 2>/dev/null)
  [[ -n "$bookmarks" ]] && ctx+=" bookmark=$bookmarks"

  ctx+=" | For advanced jj workflows (revsets, absorb, oplog), load the using-jj skill."

elif [[ -d .git ]]; then
  ctx+=" vcs=git"

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

  ctx+=" | For advanced git workflows (squashing, rebasing), load the using-git skill."

else
  ctx+=" vcs=none"
fi

# Package manager detection (from lockfile)
if [[ -f bun.lockb || -f bun.lock ]]; then
  ctx+=" pkg=bun"
elif [[ -f pnpm-lock.yaml ]]; then
  ctx+=" pkg=pnpm"
elif [[ -f yarn.lock ]]; then
  ctx+=" pkg=yarn"
elif [[ -f package-lock.json ]]; then
  ctx+=" pkg=npm"
elif [[ -f uv.lock ]]; then
  ctx+=" pkg=uv"
elif [[ -f Cargo.lock ]]; then
  ctx+=" pkg=cargo"
elif [[ -f go.sum ]]; then
  ctx+=" pkg=go"
else
  ctx+=" pkg=none"
fi

# CI/CD detection
if [[ -d .github/workflows ]]; then
  ctx+=" ci=github-actions"
elif [[ -f .gitlab-ci.yml ]]; then
  ctx+=" ci=gitlab"
elif [[ -d .circleci ]]; then
  ctx+=" ci=circleci"
else
  ctx+=" ci=none"
fi

json_ctx=$(printf '%s' "$ctx" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$json_ctx"
