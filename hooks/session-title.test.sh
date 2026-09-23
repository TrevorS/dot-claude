#!/bin/bash
# Regression test for session-title.sh — the SessionStart hook that names a
# session <folder>[/<bookmark or branch>].
#
# Pins the jj source of the name: the feature bookmark, i.e. the nearest
# bookmarked ancestors of @ outside trunk, by undecorated name. @ is normally
# an unbookmarked child of the bookmarked change, so reading @'s own bookmarks
# left almost every title as the bare folder, and the rendered list said
# `feat*` for a bookmark ahead of its remote. Also pins that naming a session
# records no jj snapshot operation.
#
# Run: ./hooks/session-title.test.sh   (exit 0 = all pass)
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/session-title.sh"

fails=0
ok()   { printf '  ok   PASS   %s\n' "$1"; }
bad()  { printf '  FAIL        %s\n' "$1"; fails=$((fails + 1)); }
skip() { printf '  --   SKIP   %s\n' "$1"; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# title_for <cwd> [session_title]: prints the sessionTitle, or nothing.
title_for() {
  jq -cn --arg cwd "$1" --arg t "${2:-}" \
    '{hook_event_name:"SessionStart",source:"startup",cwd:$cwd} + (if $t == "" then {} else {session_title:$t} end)' \
    | "$HOOK" 2>/dev/null | jq -r '.hookSpecificOutput.sessionTitle // empty' 2>/dev/null
}

# <label> <got> <want>
is() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (got '$2', want '$3')"; fi; }

plain="$work/plain"
mkdir -p "$plain"
is "plain folder -> folder name" "$(title_for "$plain")" "plain"
is "an existing title is never overwritten" "$(title_for "$plain" "my title")" ""
is "missing cwd -> no title" "$(title_for "$work/nope")" ""

g="$work/gitrepo"
(git init -q -b main "$g" && git -C "$g" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init) 2>/dev/null
is "git on main -> folder only" "$(title_for "$g")" "gitrepo"
git -C "$g" switch -q -c feat-x 2>/dev/null
is "git feature branch -> folder/branch" "$(title_for "$g")" "gitrepo/feat-x"

if command -v jj >/dev/null 2>&1; then
  j="$work/jjrepo"
  (
    git init -q -b master "$j" &&
      git -C "$j" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init &&
      git init -q --bare -b master "$j.git" &&
      git -C "$j" remote add origin "$j.git" &&
      git -C "$j" push -q origin master &&
      cd "$j" && jj git init --colocate
  ) >/dev/null 2>&1
  is "jj on trunk, no feature bookmark -> folder only" "$(title_for "$j")" "jjrepo"

  (cd "$j" && jj describe -m a && jj bookmark create feat -r @ && jj new -m b) >/dev/null 2>&1
  is "jj bookmark on @- -> folder/bookmark" "$(title_for "$j")" "jjrepo/feat"

  (cd "$j" && jj git push -b feat && jj describe -m b2 && jj bookmark set feat -r @ && jj new -m c) >/dev/null 2>&1
  is "bookmark ahead of its remote -> feat, not feat*" "$(title_for "$j")" "jjrepo/feat"

  (cd "$j" && jj new master -m m1 && jj bookmark set master -r @ && jj new -m m2) >/dev/null 2>&1
  is "local master ahead of origin is still not a title" "$(title_for "$j")" "jjrepo"

  # No snapshot: a new file must not be recorded by naming the session.
  ops() { (cd "$j" && jj op log --ignore-working-copy --no-graph -T 'id ++ "\n"' | wc -l | tr -d ' '); }
  before=$(ops)
  echo x >"$j/untracked-by-title"
  title_for "$j" >/dev/null
  after=$(ops)
  is "naming a session records no jj operation" "$after" "$before"
else
  skip "jj not installed"
fi

if [ "$fails" -eq 0 ]; then
  echo "session-title: all cases passed"
else
  echo "session-title: $fails case(s) failed"
fi
exit $((fails > 0))
