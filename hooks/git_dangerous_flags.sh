#!/bin/bash
# Hook: PreToolUse (Bash) — Block git/gh invocations that rewrite published
# history or bypass verification, so `rules/pr-safety.md` is enforced by the
# harness instead of by prose the model may or may not recall.
#
# Why this exists: settings.json allows `Bash(git:*)`, which auto-approves
# EVERY git command including `git push --force`. Claude Code 2.1.229 stopped
# auto-approving dangerous flags in its own /commit-push-pr command, but a
# user-level blanket allow is broader than the thing upstream tightened, so
# that default never reaches this config.
#
# Why a hook and not permissions.deny entries: deny patterns are prefix globs.
# `Bash(git push --force*)` misses `git push origin foo --force` and
# `git -C /path push --force`. This walks tokens instead, so flag position and
# git's global options (-C, -c, --git-dir=...) don't matter.
#
# Escape hatch: this blocks the AGENT, not Teej. Run the command yourself with
# the `!` prefix when you actually intend it (pr-safety.md: force-pushing is
# allowed once Teej confirms).
#
# Regression test: hooks/git_dangerous_flags.test.sh
set -euo pipefail

sub=""; argstart=0
toks=(); segments=()

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
[ -z "$command" ] && exit 0

block() {
  cat >&2 <<MSG
Blocked (rewrites published history or skips verification — see rules/pr-safety.md):
$1
MSG
  exit 2
}

# Split a command line into segments on unquoted && || ; and newline.
# Quote-aware so a separator inside a -m message is message text, not a split
# point. Backslash-newline is honoured as a line continuation.
# Never eval/word-split untrusted command text.
segment_command() {
  local s="$1" c nxt q="" cur="" i
  segments=()
  for (( i = 0; i < ${#s}; i++ )); do
    c="${s:i:1}"
    if [ -n "$q" ]; then
      cur+="$c"
      [ "$c" = "$q" ] && q=""
      continue
    fi
    case "$c" in
      '\')
        nxt="${s:i+1:1}"
        if [ "$nxt" = $'\n' ]; then i=$((i+1)); else cur+="$c$nxt"; i=$((i+1)); fi
        ;;
      '"' | "'") q="$c"; cur+="$c" ;;
      $'\n' | ';') segments+=("$cur"); cur="" ;;
      '&') if [ "${s:i+1:1}" = '&' ]; then segments+=("$cur"); cur=""; i=$((i+1)); else cur+="$c"; fi ;;
      '|') if [ "${s:i+1:1}" = '|' ]; then segments+=("$cur"); cur=""; i=$((i+1)); else cur+="$c"; fi ;;
      *) cur+="$c" ;;
    esac
  done
  segments+=("$cur")
}

# Tokenize one segment, quote-aware, into the global `toks` array. Quotes are
# consumed (they delimit, they aren't content), so `-m "a b"` yields `-m` and
# `a b` — a flag written inside a commit message can never look like a token.
# Hand-rolled for the same reason as the jj guard: eval would execute any
# $(...) embedded in the command text.
tokenize() {
  local s="$1" c q="" tok="" had=0 i
  toks=()
  for (( i = 0; i < ${#s}; i++ )); do
    c="${s:i:1}"
    if [ -n "$q" ]; then
      if [ "$c" = "$q" ]; then q=""; else tok+="$c"; fi
      had=1
    elif [ "$c" = '"' ] || [ "$c" = "'" ]; then
      q="$c"; had=1
    elif [ "$c" = " " ] || [ "$c" = $'\t' ] || [ "$c" = $'\n' ]; then
      if [ "$had" -eq 1 ]; then toks+=("$tok"); tok=""; had=0; fi
    else
      tok+="$c"; had=1
    fi
  done
  [ "$had" -eq 1 ] && toks+=("$tok")
}

# Resolve the real subcommand, skipping git's global options. `git -C /path push`
# and `git -c user.name=x commit` must resolve to push/commit, not to -C/-c.
# Assigns the globals `sub` and `argstart` (index just past the subcommand)
# rather than echoing: a $(...) call would run this in a subshell and the
# argstart assignment would be lost, leaving has_arg scanning from nowhere.
git_subcommand() {
  local i=1 t
  sub=""; argstart=0
  while (( i < ${#toks[@]} )); do
    t="${toks[i]}"
    case "$t" in
      # Global options taking a value as a SEPARATE token.
      -C | -c | --git-dir | --work-tree | --namespace | --exec-path | --config-env)
        i=$((i+2)); continue ;;
      # Attached (--git-dir=x) and valueless (-P, --no-pager, --bare) globals.
      -*) i=$((i+1)); continue ;;
      *) sub="$t"; argstart=$((i+1)); return 0 ;;
    esac
  done
  return 1
}

# True if any token AFTER the subcommand matches one of the pipe-separated
# alternatives. Matches both `--flag` and the attached `--flag=value` form.
has_arg() {
  local pat="$1" i t
  for (( i = argstart; i < ${#toks[@]}; i++ )); do
    t="${toks[i]}"
    [[ "$t" =~ ^(${pat})$ ]] && return 0
    [[ "$t" =~ ^(${pat})= ]] && return 0
  done
  return 1
}

# Peel leading environment assignments and wrapper commands, so that
# `timeout 5 git push --force` is inspected as `git push --force`. Without this
# the anchored `^git`/`^jj` test below skips the segment entirely and the guard
# silently passes -- verified evadable via `timeout`, `command`, and `env`.
#
# Assigns the global `stripped` rather than echoing, for the same reason
# git_subcommand does: a $(...) call would fork a subshell per segment on a hook
# that runs for every Bash tool call.
#
# Peeling only ever exposes MORE of the command line to the checks below, so an
# over-eager strip risks a false block, never a missed one.
strip_wrappers() {
  local s="$1" prev="" rest
  while [ "$s" != "$prev" ]; do
    prev="$s"
    # VAR=value prefix (also covers `env FOO=1 ...` on the next pass).
    if [[ "$s" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*)$ ]]; then
      s="${BASH_REMATCH[1]}"; continue
    fi
    # Wrappers that take no options of their own.
    if [[ "$s" =~ ^(command|builtin|exec|nohup|setsid|time)[[:space:]]+(.*)$ ]]; then
      s="${BASH_REMATCH[2]}"; continue
    fi
    # timeout [-opts] DURATION cmd
    if [[ "$s" =~ ^timeout[[:space:]]+(-[^[:space:]]+[[:space:]]+)*[0-9]+(\.[0-9]+)?[smhd]?[[:space:]]+(.*)$ ]]; then
      s="${BASH_REMATCH[3]}"; continue
    fi
    # Wrappers that may carry their own flags, some taking a separate value.
    if [[ "$s" =~ ^(env|stdbuf|nice|ionice|sudo)[[:space:]]+(.*)$ ]]; then
      rest="${BASH_REMATCH[2]}"
      while true; do
        if [[ "$rest" =~ ^-[nucgpioeC][[:space:]]+[^[:space:]]+[[:space:]]+(.*)$ ]]; then
          rest="${BASH_REMATCH[1]}"; continue
        fi
        if [[ "$rest" =~ ^-[^[:space:]]+[[:space:]]+(.*)$ ]]; then
          rest="${BASH_REMATCH[1]}"; continue
        fi
        break
      done
      s="$rest"; continue
    fi
  done
  stripped="$s"
}

segment_command "$command"
for seg in "${segments[@]}"; do
  seg="${seg#"${seg%%[![:space:]]*}"}"
  seg="${seg%"${seg##*[![:space:]]}"}"
  strip_wrappers "$seg"
  seg="$stripped"
  [[ "$seg" =~ ^(git|gh)([[:space:]]|$) ]] || continue

  tokenize "$seg"
  (( ${#toks[@]} )) || continue
  git_subcommand || continue

  # --help/-h only prints usage.
  has_arg '-h|--help' && continue

  if [ "${toks[0]}" = "git" ]; then
    case "$sub" in
      push)
        # -f/--force only mean "force" for push; `git clean -f`, `git branch -f`,
        # `git tag -f` and `git checkout -f` are local and stay allowed.
        # --force-with-lease is included deliberately: pr-safety.md names it.
        if has_arg '-f|--force|--force-with-lease|--force-if-includes'; then
          block "  $seg
  -> force-push rewrites already-published commits and detaches any PR review
     threads anchored to them. Default to adding a commit on top instead.
     If you really want it, ask Teej — or run it yourself with \`!\`."
        fi
        # `git push -n` is --dry-run (harmless), so only the long spelling here.
        if has_arg '--no-verify'; then
          block "  $seg
  -> --no-verify skips pre-push hooks. Fix what the hook reports instead."
        fi
        ;;
      commit)
        if has_arg '--amend'; then
          block "  $seg
  -> --amend rewrites the last commit. If it is already pushed, this detaches
     PR review threads. Add a new commit, or ask Teej before amending."
        fi
        # For commit (unlike push) -n IS --no-verify.
        if has_arg '-n|--no-verify'; then
          block "  $seg
  -> --no-verify skips pre-commit hooks, which this repo relies on for
     formatting and lint. Run \`make pre-commit\` and fix the findings."
        fi
        ;;
      reset)
        # Beyond the 2.1.229 changelog line: version-control.md classes
        # \`reset --hard\` as destructive and wants a backup branch first.
        if has_arg '--hard'; then
          block "  $seg
  -> \`git reset --hard\` discards working-copy changes irreversibly.
     Make a backup first: \`git branch backup-\$(date +%s)\`."
        fi
        ;;
    esac
  else
    # gh: --admin on a merge bypasses required reviews and branch protection.
    if [ "$sub" = "pr" ] && has_arg '--admin'; then
      block "  $seg
  -> --admin bypasses required reviews and branch protection. Ask Teej."
    fi
  fi
done

exit 0
