#!/bin/bash
# Outputs VCS context for Claude on each prompt
# Input: JSON on stdin (ignored)
# Output: key=value pairs, space-separated

# Drain stdin to prevent blocking
cat > /dev/null

out="time=$(date '+%Y-%m-%d %H:%M %z') cwd=$PWD"

if [[ -d .jj ]]; then
  if [[ -d .git ]]; then
    out+=" vcs=jj-colocated"
  else
    out+=" vcs=jj"
  fi

  change=$(jj log -r @ --no-graph -T 'change_id.short()' 2>/dev/null) && out+=" change=$change"
  bookmarks=$(jj log -r @ --no-graph -T 'bookmarks.join(",")' 2>/dev/null)
  [[ -n "$bookmarks" ]] && out+=" bookmark=$bookmarks"

elif [[ -d .git ]]; then
  out+=" vcs=git"

  branch=$(git branch --show-current 2>/dev/null)
  if [[ -n "$branch" ]]; then
    out+=" branch=$branch"
  else
    hash=$(git rev-parse --short HEAD 2>/dev/null)
    [[ -n "$hash" ]] && out+=" head=$hash"
  fi

  if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    out+=" dirty=yes"
  else
    out+=" dirty=no"
  fi

else
  out+=" vcs=none"
fi

echo "$out"
