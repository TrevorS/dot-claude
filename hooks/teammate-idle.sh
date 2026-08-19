#!/bin/bash
# Hook: TeammateIdle — refuse to let an agent-team teammate go idle on a red tree.
#
# Exit 2 feeds stderr back and the teammate keeps working; exit 0 lets it idle.
# Fires once per teammate turn-end, the right granularity for a gate --
# TaskCompleted fires on every TaskUpdate and would run constantly. The event
# supports no matchers, so scoping happens below: no validate target, no opinion.

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
