#!/bin/bash
# Hook: PreToolUse (Bash) — Block jj invocations that would open an interactive
# editor (text, diff, or merge) and hang the agent, or use a renamed subcommand.
# Command set verified against jj 0.44 CLI reference (docs.jj-vcs.dev); global
# options and the built-in desc/ci aliases re-checked against jj 0.45.1.
#
# `jj split` is allowed in exactly one shape — filesets + -m, with no
# -i/--interactive/--tool/--editor. Three separate editors can open otherwise:
#   * no filesets      -> -i is the documented default, so the diff editor opens
#   * no -m/--message  -> the description editor opens (-m is "don't open editor")
#   * -i/--tool        -> diff editor;  --editor -> description editor even with -m
#
# Backstop relationship: $JJ_EDITOR (jj-reject-editor.sh) already fail-fasts any
# *text* editor. This hook stops the command BEFORE it runs with a precise fix,
# and covers the builtin diff/merge editors ($JJ_EDITOR can't) plus the
# forget->file-untrack rename. Defense in depth — keep both.
#
# Regression test: hooks/jj_interactive_guard.test.sh
set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
[ -z "$command" ] && exit 0

block() {
  cat >&2 <<MSG
Blocked (would open an interactive jj editor and hang the agent):
$1
MSG
  exit 2
}

# Flag present as a token in $bare (quoted strings already stripped, so flags
# inside a -m message can't false-match). Pipe-separated alternatives.
has() { [[ " $bare " =~ [[:space:]](${1})([[:space:]]|=|$) ]]; }

# Shared parsing: segment_command, heredoc_word, tokenize, peel_assignment,
# strip_wrappers, resolve_subcommand.
# shellcheck source=SCRIPTDIR/lib/cmdline.sh
. "${BASH_SOURCE[0]%/*}/lib/cmdline.sh"

# jj global options that take a SEPARATE value token (jj 0.45.1 `jj help`).
# The valueless ones (--no-pager, --ignore-working-copy, --ignore-immutable,
# --quiet, --debug, --no-integrate-operation) and attached forms
# (--repository=., -R.) are skipped as single tokens by resolve_subcommand.
JJ_VALUED_GLOBALS='-R|--repository|--at-operation|--at-op|--color|--config|--config-file'

# Drop "double"- and 'single'-quoted substrings so flag scanning can't match text
# inside a -m message. Must span lines: a line-wise sed leaves a multi-line
# message's body in $bare, where `-i` written in prose trips the interactive check.
strip_quoted() {
  local s="$1" c q="" out="" i
  for (( i = 0; i < ${#s}; i++ )); do
    c="${s:i:1}"
    if [ -n "$q" ]; then
      # Inside "..." a backslash escapes the next char, so \" is literal and
      # must NOT close the string. Single quotes take no escapes.
      if [ "$c" = '\' ] && [ "$q" = '"' ]; then i=$((i+1)); continue; fi
      [ "$c" = "$q" ] && q=""
      continue
    fi
    if [ "$c" = '"' ] || [ "$c" = "'" ]; then q="$c"; continue; fi
    out+="$c"
  done
  printf '%s' "$out"
}

# True when a `jj split` segment names at least one positional fileset.
#
# Parses the ORIGINAL segment rather than $bare: quote-stripping would turn
# `-m "msg"` into a bare `-m`, and the following path would then be swallowed as
# its value. Only called on a `jj split` segment whose global options were
# already removed, so toks[1] is `split`.
split_has_fileset() {
  local tok skip_next=0 seen_ddash=0 i
  tokenize "$1"

  # Skip toks[0]=jj and toks[1]=split.
  for (( i = 2; i < ${#toks[@]}; i++ )); do
    tok="${toks[i]}"
    if [ "$skip_next" -eq 1 ]; then skip_next=0; continue; fi
    if [ "$seen_ddash" -eq 1 ]; then return 0; fi
    case "$tok" in
      --) seen_ddash=1 ;;
      # Flags that take a value as a SEPARATE token. Attached forms (-r@-,
      # --message=x) fall through to the -* arm below and consume nothing.
      -r | --revision | -o | --onto | -A | --insert-after | -B | --insert-before \
        | -m | --message | --tool | -R | --repository | --at-operation | --color \
        | --config | --config-file) skip_next=1 ;;
      -*) ;;
      *) return 0 ;;
    esac
  done
  return 1
}

segment_command "$command"
for seg in "${segments[@]}"; do
  # Trim with parameter expansion, not sed: a segment can now legitimately
  # contain newlines, and sed would trim every line of the message instead.
  seg="${seg#"${seg%%[![:space:]]*}"}"
  seg="${seg%"${seg##*[![:space:]]}"}"
  strip_wrappers "$seg"
  seg="$stripped"
  [[ "$seg" =~ ^jj([[:space:]]|$) ]] || continue

  # Drop jj's global options so the checks below, anchored on `^jj <sub>`, see
  # the subcommand: `jj --no-pager describe` and `jj -R . describe` opened the
  # editor unchecked. The segment is rebuilt from the subcommand's offset, so
  # everything after it keeps its original quoting.
  tokenize "$seg"
  if resolve_subcommand "$JJ_VALUED_GLOBALS" && (( argstart > 2 )); then
    seg="jj ${seg:${tokpos[argstart-1]}}"
  fi
  bare="$(strip_quoted "$seg")"

  # --help / -h just prints usage; never opens an editor.
  [[ "$bare" =~ (^|[[:space:]])(-h|--help)([[:space:]]|$) ]] && continue

  # 1. diffedit has no non-interactive mode at all.
  if [[ "$bare" =~ ^jj[[:space:]]+diffedit([[:space:]]|$) ]]; then
    block "  $seg
  -> jj diffedit has no non-interactive mode. Restructure with
     \`jj squash -m\`, \`jj new -m\`, or \`jj describe -m\` instead."
  fi

  # 1b. split is safe only as: filesets + -m, no -i/--interactive/--tool/--editor.
  if [[ "$bare" =~ ^jj[[:space:]]+split([[:space:]]|$) ]]; then
    if has '-i|--interactive|--tool|--editor'; then
      block "  $seg
  -> -i/--interactive/--tool opens the diff editor; --editor opens the
     description editor even with -m. Drop the flag — name the paths instead:
     \`jj split -r <rev> -m \"msg\" <paths>\`."
    fi
    if ! has '-m|--message'; then
      block "  $seg
  -> jj split without -m opens the description editor for the split-out
     commit. Add -m \"msg\"."
    fi
    if ! split_has_fileset "$seg"; then
      block "  $seg
  -> jj split with no filesets defaults to -i and opens the diff editor.
     Name the paths to make it non-interactive:
     \`jj split -r <rev> -m \"msg\" <paths>\`."
    fi
  fi

  # 2. config edit opens the editor; use the non-interactive setter.
  if [[ "$bare" =~ ^jj[[:space:]]+config[[:space:]]+edit([[:space:]]|$) ]]; then
    block "  $seg
  -> \`jj config edit\` opens an editor. Use \`jj config set <name> <value>\`
     (add --user or --repo to pick the scope)."
  fi

  # 3. Subcommand renamed in this jj version.
  if [[ "$bare" =~ ^jj[[:space:]]+forget([[:space:]]|$) ]]; then
    block "  $seg
  -> \`jj forget\` does not exist in this jj. To stop tracking a file:
     \`jj file untrack <path>\`."
  fi

  # 4. describe / commit (and the built-in desc / ci aliases) open a
  #    description editor with no message.
  if [[ "$bare" =~ ^jj[[:space:]]+(describe|desc|commit|ci)([[:space:]]|$) ]] && ! has '-m|--message|--stdin'; then
    block "  $seg
  -> opens a description editor with no -m. Add -m \"msg\" (or --stdin)."
  fi

  # 5. squash opens an editor to combine descriptions unless given -m or -u.
  if [[ "$bare" =~ ^jj[[:space:]]+squash([[:space:]]|$) ]] \
     && ! has '-m|--message|--stdin' && ! has '-u|--use-destination-message'; then
    block "  $seg
  -> opens an editor to combine descriptions. Add -m \"msg\", or -u to
     reuse the destination commit's message."
  fi

  # 6. commit / squash hunk pickers open a diff editor even WITH -m.
  #    (--tool implies --interactive for these commands.)
  if [[ "$bare" =~ ^jj[[:space:]]+(commit|ci|squash)([[:space:]]|$) ]] && has '-i|--interactive|--tool'; then
    block "  $seg
  -> -i/--interactive/--tool opens a diff editor to pick hunks and will hang.
     Drop the flag; stage by editing files, then \`jj squash -m\`."
  fi

  # 7. resolve opens the interactive merge editor unless a tool is named.
  #    -l/--list only prints the conflicted paths and never opens anything.
  if [[ "$bare" =~ ^jj[[:space:]]+resolve([[:space:]]|$) ]] && ! has '--tool' && ! has '-l|--list'; then
    block "  $seg
  -> opens the interactive merge editor. Resolve by editing the conflict
     markers in the files directly, then \`jj squash -m\` / \`jj describe -m\`."
  fi
done

exit 0
