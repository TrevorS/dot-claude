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
# `git -C /path push --force`. This walks tokens instead, so flag position,
# bundled short flags (-uf) and git's global options (-C, -c, --git-dir=...)
# don't matter.
#
# Escape hatch: this blocks the AGENT, not Teej. Run the command yourself with
# the `!` prefix when you actually intend it (pr-safety.md: force-pushing is
# allowed once Teej confirms).
#
# Regression test: hooks/git_dangerous_flags.test.sh
set -euo pipefail

opts=(); args=()

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

# Shared parsing: segment_command, heredoc_word, tokenize, peel_assignment,
# strip_wrappers, resolve_subcommand.
# shellcheck source=SCRIPTDIR/lib/cmdline.sh
. "${BASH_SOURCE[0]%/*}/lib/cmdline.sh"

# Sort the tokens after the subcommand into `opts` (one flag per entry) and
# `args` (everything else), the way git's option parser reads them:
#   * a short bundle is expanded, so `-uf` is -u -f and `-anm x` is -a -n -m;
#   * an option's value is skipped, never read as a flag, so the message in
#     `-m -n` or `-am "-n"` is not --no-verify. In a bundle, a value-taking
#     letter takes the rest of the bundle (`-mn` is -m "n") or else the next
#     token;
#   * after `--` every token is an arg.
# $1: short letters whose value may be the next token.
# $2: short letters whose value is optional and only ever attached (-S<keyid>).
# $3: pipe-separated long options whose value may be the next token.
collect_opts() {
  local vshort="$1" oshort="$2" vlong="$3" i j t c
  opts=(); args=()
  for (( i = argstart; i < ${#toks[@]}; i++ )); do
    t="${toks[i]}"
    case "$t" in
      --)
        for (( j = i + 1; j < ${#toks[@]}; j++ )); do args+=("${toks[j]}"); done
        break ;;
      --?*)
        opts+=("$t")
        if [ -n "$vlong" ] && [[ "$t" =~ ^(${vlong})$ ]]; then i=$((i+1)); fi ;;
      -?*)
        for (( j = 1; j < ${#t}; j++ )); do
          c="${t:j:1}"
          opts+=("-$c")
          if [[ "$vshort" == *"$c"* ]]; then
            (( j == ${#t} - 1 )) && i=$((i+1))
            break
          fi
          [[ "$oshort" == *"$c"* ]] && break
        done ;;
      *) args+=("$t") ;;
    esac
  done
  return 0
}

# True if any collected option matches one of the pipe-separated alternatives,
# as `--flag` or in the attached `--flag=value` form.
has_opt() {
  local pat="$1" i t
  for (( i = 0; i < ${#opts[@]}; i++ )); do
    t="${opts[i]}"
    [[ "$t" =~ ^(${pat})$ ]] && return 0
    [[ "$t" =~ ^(${pat})= ]] && return 0
  done
  return 1
}

# True if any non-option argument matches the pattern.
has_positional() {
  local pat="$1" i
  for (( i = 0; i < ${#args[@]}; i++ )); do
    [[ "${args[i]}" =~ ^(${pat})$ ]] && return 0
  done
  return 1
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
  resolve_subcommand '-C|-c|--git-dir|--work-tree|--namespace|--exec-path|--config-env' || continue

  # Value-taking options per subcommand, so their values are skipped.
  case "${toks[0]} $sub" in
    "git push") collect_opts o '' '--push-option|--repo|--receive-pack|--exec' ;;
    "git commit")
      collect_opts mFCct Su '--message|--file|--reuse-message|--reedit-message|--fixup|--squash|--author|--date|--template|--cleanup|--trailer|--pathspec-from-file' ;;
    *) collect_opts '' '' '' ;;
  esac

  # --help/-h only prints usage.
  has_opt '-h|--help' && continue

  if [ "${toks[0]}" = "git" ]; then
    case "$sub" in
      push)
        # -f/--force only mean "force" for push; `git clean -f`, `git branch -f`,
        # `git tag -f` and `git checkout -f` are local and stay allowed.
        # --force-with-lease is included deliberately: pr-safety.md names it.
        if has_opt '-f|--force|--force-with-lease|--force-if-includes'; then
          block "  $seg
  -> force-push rewrites already-published commits and detaches any PR review
     threads anchored to them. Default to adding a commit on top instead.
     If you really want it, ask Teej — or run it yourself with \`!\`."
        fi
        # A leading + on a refspec force-pushes that one ref: `git push origin
        # +master` passed every check above.
        if has_positional '\+.+'; then
          block "  $seg
  -> a leading + on a refspec force-pushes that ref, the same as --force.
     Push without the + and add a commit on top instead, or ask Teej."
        fi
        # `git push -n` is --dry-run (harmless), so only the long spelling here.
        if has_opt '--no-verify'; then
          block "  $seg
  -> --no-verify skips pre-push hooks. Fix what the hook reports instead."
        fi
        ;;
      commit)
        if has_opt '--amend'; then
          block "  $seg
  -> --amend rewrites the last commit. If it is already pushed, this detaches
     PR review threads. Add a new commit, or ask Teej before amending."
        fi
        # For commit (unlike push) -n IS --no-verify.
        if has_opt '-n|--no-verify'; then
          block "  $seg
  -> -n/--no-verify skips pre-commit hooks. Fix what the hook reports instead."
        fi
        ;;
      reset)
        # Not from the 2.1.229 changelog line: pr-safety.md lists reset --hard
        # among the forms this hook blocks, since it discards uncommitted work.
        if has_opt '--hard'; then
          block "  $seg
  -> \`git reset --hard\` discards working-copy changes irreversibly.
     Make a backup first: \`git branch backup-\$(date +%s)\`."
        fi
        ;;
    esac
  else
    # gh: --admin on a merge bypasses required reviews and branch protection.
    if [ "$sub" = "pr" ] && has_opt '--admin'; then
      block "  $seg
  -> --admin bypasses required reviews and branch protection. Ask Teej."
    fi
  fi
done

exit 0
