#!/bin/bash
# Hook: SessionStart — name the session from worktree/bookmark/branch/folder.
#
# SessionStart rather than UserPromptSubmit because only SessionStart receives
# `session_title`, so only here can the hook see an existing title and decline to
# clobber it. sessionTitle applies on startup|resume|fork, ignored on
# clear|compact.

input=$(cat)

# Never overwrite a title the user set explicitly (--name / /rename) or one
# already generated for this session.
existing=$(jq -r '.session_title // ""' <<<"$input" 2>/dev/null)
[[ -n "$existing" ]] && exit 0

dir=$(jq -r '.cwd // ""' <<<"$input" 2>/dev/null)
[[ -n "$dir" && -d "$dir" ]] || exit 0
cd "$dir" || exit 0

base=$(basename "$dir")
ref=""

# Named refs only. A change id or detached short hash is meaningless in a title
# and churns every time the change is rewritten, so those degrade to bare $base.
if [[ -d .jj ]]; then
  ref=$(jj log -r @ --no-graph -T 'bookmarks.join(",")' 2>/dev/null)
elif [[ -d .git ]]; then
  ref=$(git branch --show-current 2>/dev/null)
fi

# Trunk adds no information beyond the folder name.
case "$ref" in
  master | main | trunk) ref="" ;;
esac

if [[ -n "$ref" ]]; then
  title="$base/$ref"
else
  title="$base"
fi

jq -cn --arg title "$title" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",sessionTitle:$title}}'
