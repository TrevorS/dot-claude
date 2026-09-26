#!/bin/bash
# Hook: TeammateIdle — refuse to let an agent-team teammate go idle on a red tree.
#
# Exit 2 feeds stderr back and the teammate keeps working; exit 0 lets it idle.
# Fires once per teammate turn-end, the right granularity for a gate --
# TaskCompleted fires on every TaskUpdate and would run constantly. The event
# supports no matchers, so scoping happens below: no validate or check target,
# no opinion.
set -euo pipefail

input=$(cat)

dir=$(jq -r '.cwd // ""' <<<"$input" 2>/dev/null) || exit 0
[[ -n "$dir" && -d "$dir" ]] || exit 0
cd "$dir" || exit 0

# Only gate repos that declare a validate target, or a check target when there
# is no validate. Validate-only gated none of the 14 teammates in the 30 days to
# 2026-09-18: their repos (glaes-go among them) spell it `make check`.
[[ -f Makefile ]] || exit 0
target=""
for t in validate check; do
  if grep -qE "^${t}:" Makefile; then target="$t"; break; fi
done
[[ -n "$target" ]] || exit 0

if ! out=$(make "$target" 2>&1); then
  who=$(jq -r '.teammate_name // "teammate"' <<<"$input" 2>/dev/null) || who=teammate
  {
    printf '%s: `make %s` is failing; fix it before going idle.\n\n' "$who" "$target"
    printf '%s\n' "$out" | tail -40
  } >&2
  exit 2
fi

exit 0
