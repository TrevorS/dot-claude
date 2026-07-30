#!/bin/bash
# Hook: TeammateIdle — refuse to let an agent-team teammate go idle on a red tree.
#
# Added 2026-07-29 (event landed in v2.1.33). Exit 2 feeds stderr back to the
# teammate as feedback and it keeps working; exit 0 lets it idle. TeammateIdle
# fires once per teammate turn-end, which is the right granularity for a gate --
# TaskCompleted fires on every TaskUpdate completion and would run constantly.
#
# TeammateIdle supports no matchers and fires on every occurrence, so scoping
# has to happen here: no Makefile `validate` target means no opinion.
#
# Input:  JSON on stdin (teammate_name, cwd)
# Output: nothing on pass; stderr + exit 2 to send the teammate back to work

input=$(cat)

dir=$(jq -r '.cwd // ""' <<<"$input" 2>/dev/null)
[[ -n "$dir" && -d "$dir" ]] || exit 0
cd "$dir" || exit 0

# Only gate repos that declare a validate target.
[[ -f Makefile ]] || exit 0
grep -qE '^validate:' Makefile || exit 0

if ! out=$(make validate 2>&1); then
  who=$(jq -r '.teammate_name // "teammate"' <<<"$input" 2>/dev/null)
  {
    printf '%s: `make validate` is failing; fix it before going idle.\n\n' "$who"
    printf '%s\n' "$out" | tail -40
  } >&2
  exit 2
fi

exit 0
