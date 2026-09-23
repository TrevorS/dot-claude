#!/bin/bash
# Hook: PreToolUse (Bash) — Block git/jj commits to protected branches (main,
# master, dev). Per-project override: "direct-commits-allowed: true" in
# ./CLAUDE.md or ./.claude/CLAUDE.md.
#
# jj has no current branch. A protected bookmark is committed to when:
#   * the change it points at is rewritten in place
#       jj describe / jj commit on @ while @ carries it, jj describe -r <it>
#   * content is squashed INTO the change it points at
#       jj squash (into @- when @- is master), jj squash --into master
#   * the bookmark itself is moved onto new work
#       jj bookmark set|move|advance master
# All three shapes are checked. `jj new` is not: it only creates a child and
# never moves a bookmark, so `jj new master` (how work normally starts) passes.
#
# Bookmark names come from the template API, bookmarks.map(|b| b.name()), not
# the rendered `bookmarks` string. That string decorates a bookmark that is
# ahead of its remote as `master*` and a conflicted one as `master??`, and the
# old ^(main|master|dev)$ match saw neither -- the hook was blind exactly when
# master carried local, unpushed commits, and also when a change carried more
# than one bookmark. Found 2026-09-15 after 0 fires in 30 days of transcripts;
# the test suite now builds a colocated repo with a remote to cover both.
#
# Regression test: hooks/branch_protection.test.sh
set -euo pipefail

PROTECTED='^(main|master|dev)$'

switched=""

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
[ -z "$command" ] && exit 0

# Project-level override (root CLAUDE.md or .claude/CLAUDE.md).
for f in ./CLAUDE.md ./.claude/CLAUDE.md; do
  if [ -f "$f" ] && grep -qi "direct-commits-allowed: true" "$f" 2>/dev/null; then
    exit 0
  fi
done

block() {
  cat >&2 <<MSG
$1

Per-project override: add "direct-commits-allowed: true" to ./CLAUDE.md.
MSG
  exit 2
}

# ---------------------------------------------------------------------------
# Command-line parsing: segment_command, heredoc_word, tokenize,
# peel_assignment, strip_wrappers and resolve_subcommand live in lib/cmdline.sh,
# shared with git_dangerous_flags.sh and jj_interactive_guard.sh.
# ---------------------------------------------------------------------------
# shellcheck source=SCRIPTDIR/lib/cmdline.sh
. "${BASH_SOURCE[0]%/*}/lib/cmdline.sh"

# Value of the first option after the subcommand matching the pattern, in
# either the separate (`-r x`) or attached (`--revision=x`) form. Prints
# nothing when absent.
opt_value() {
  local pat="$1" i t
  for (( i = argstart; i < ${#toks[@]}; i++ )); do
    t="${toks[i]}"
    if [[ "$t" =~ ^(${pat})$ ]]; then printf '%s' "${toks[i+1]:-}"; return 0; fi
    if [[ "$t" =~ ^(${pat})=(.*)$ ]]; then printf '%s' "${BASH_REMATCH[2]}"; return 0; fi
  done
  return 0
}

# Positional arguments after the subcommand, one per line. $1 is the
# pipe-separated list of options whose value is a separate token.
positionals() {
  local valued="$1" i t skip=0
  for (( i = argstart; i < ${#toks[@]}; i++ )); do
    t="${toks[i]}"
    if [ "$skip" -eq 1 ]; then skip=0; continue; fi
    if [[ "$t" =~ ^(${valued})$ ]]; then skip=1; continue; fi
    case "$t" in
      --) ;;
      -*) ;;
      *) printf '%s\n' "$t" ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Repository queries.
# ---------------------------------------------------------------------------

in_jj_repo() { jj root --ignore-working-copy >/dev/null 2>&1; }

# First protected bookmark on a revset, or nothing. --ignore-working-copy: the
# answer does not depend on file contents, and snapshotting on every hook call
# would be slow on a big tree and would record an operation as a side effect.
protected_on() {
  local names n
  names=$(jj log --ignore-working-copy --color never --no-graph -r "$1" \
            -T 'bookmarks.map(|b| b.name()).join("\n") ++ "\n"' 2>/dev/null || true)
  while IFS= read -r n; do
    if [[ "$n" =~ $PROTECTED ]]; then printf '%s' "$n"; return 0; fi
  done <<<"$names"
  return 0
}

# First protected name among the given lines, or nothing.
protected_name() {
  local n
  while IFS= read -r n; do
    if [[ "$n" =~ $PROTECTED ]]; then printf '%s' "$n"; return 0; fi
  done <<<"$1"
  return 0
}

# ---------------------------------------------------------------------------
# Checks.
# ---------------------------------------------------------------------------

segment_command "$command"
for seg in "${segments[@]}"; do
  seg="${seg#"${seg%%[![:space:]]*}"}"
  seg="${seg%"${seg##*[![:space:]]}"}"
  strip_wrappers "$seg"
  seg="$stripped"
  [[ "$seg" =~ ^(git|jj)([[:space:]]|$) ]] || continue

  tokenize "$seg"
  (( ${#toks[@]} )) || continue
  name=""

  if [ "${toks[0]}" = "jj" ]; then
    resolve_subcommand '-R|--repository|--at-operation|--at-op|--config|--config-file|--color' || continue
    case "$sub" in
      describe | desc | commit | ci)
        rev="@"
        if [ "$sub" = describe ] || [ "$sub" = desc ]; then
          rev=$(opt_value '-r|--revision')
          if [ -z "$rev" ]; then
            rev=$(positionals '-m|--message|-r|--revision|--author|--config|--config-file')
            rev="${rev%%$'\n'*}"   # first positional; no `| head` so SIGPIPE can't trip pipefail
          fi
          [ -z "$rev" ] && rev="@"
        fi
        name=$(protected_on "$rev")
        if [ -n "$name" ]; then
          block "Blocked: '$rev' carries the '$name' bookmark, so \`jj $sub\` rewrites the protected branch in place.

Fix: put $name back where the remote has it and keep working on a feature bookmark:
  jj bookmark set $name -r ${name}@origin --allow-backwards
  jj bookmark create <feature-name> -r @"
        fi
        ;;
      squash)
        src=$(opt_value '-r|--revision|-f|--from')
        [ -z "$src" ] && src="@"
        dest=$(opt_value '-t|--into')
        [ -z "$dest" ] && dest="($src)-"
        name=$(protected_on "$dest")
        if [ -n "$name" ]; then
          block "Blocked: \`jj squash\` would move content into the change carrying the '$name' bookmark — a direct commit to the protected branch.

Fix: squash into a feature change, or start one and squash there:
  jj new $name -m \"...\" && jj bookmark create <feature-name> -r @"
        fi
        name=$(protected_on "$src")
        if [ -n "$name" ]; then
          block "Blocked: \`jj squash\` would empty the change carrying the '$name' bookmark and rewrite the protected branch.

Fix: put $name back where the remote has it first:
  jj bookmark set $name -r ${name}@origin --allow-backwards"
        fi
        ;;
      bookmark | b)
        subsub="${toks[argstart]:-}"
        argstart=$((argstart + 1))
        case "$subsub" in
          set | s | move | m | advance | a)
            name=$(protected_name "$(positionals '-r|--revision|--to|--from')")
            if [ -z "$name" ]; then
              from=$(opt_value '--from')
              [ -n "$from" ] && name=$(protected_on "$from")   # move --from <rev> moves every bookmark on it
            fi
            if [ -n "$name" ]; then
              block "Blocked: moving the '$name' bookmark commits to the protected branch.

Fix: work on a feature bookmark and open a PR; $name advances on \`jj git fetch\` after the merge:
  jj bookmark create <feature-name> -r @"
            fi
            ;;
        esac
        ;;
    esac
  else
    resolve_subcommand '-C|-c|--git-dir|--work-tree|--namespace|--exec-path|--config-env' || continue
    case "$sub" in
      checkout | switch)
        # A branch created or switched to earlier in this same command is where
        # a later commit lands, but the repo queries below run before any of it
        # and still see the old HEAD. `git checkout -b x && git commit` on
        # master was blocked 3 times in 30 days, twice as the fix for a block.
        # Plain `git checkout <name>` is skipped: it may name a path.
        if [ "$sub" = checkout ]; then
          nb=$(opt_value '-b|-B|--orphan')
        else
          nb=$(opt_value '-c|-C|--create|--force-create|--orphan')
          if [ -z "$nb" ]; then
            nb=$(positionals '-c|-C|--create|--force-create|--orphan')
            nb="${nb%%$'\n'*}"
          fi
        fi
        [ -n "$nb" ] && switched="$nb"
        continue ;;
      commit | add) ;;
      *) continue ;;
    esac
    if [ -n "$switched" ]; then
      [[ "$switched" =~ $PROTECTED ]] && name="$switched"
    elif in_jj_repo; then
      # git commit in a colocated repo lands on @; check @ and then @-.
      name=$(protected_on '@')
      [ -z "$name" ] && name=$(protected_on '@-')
    else
      branch=$(git branch --show-current 2>/dev/null || true)
      [[ "$branch" =~ $PROTECTED ]] && name="$branch"
    fi
    if [ -n "$name" ]; then
      block "Blocked: committing directly to protected branch '$name'.

Options:
  1. Use a feature branch instead (recommended)
  2. Ask the user if direct commits are OK for this project."
    fi
  fi
done

exit 0
