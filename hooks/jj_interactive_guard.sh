#!/bin/bash
# Hook: PreToolUse (Bash) — Block jj invocations that would open an interactive
# editor (text, diff, or merge) and hang the agent, or use a renamed subcommand.
# Command set verified against jj 0.44 CLI reference (docs.jj-vcs.dev).
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

# Split a command line into segments on unquoted && || ; and newline.
#
# Quote-aware for the same reason split_has_fileset is: a newline inside a -m
# message is message text, not a command separator. The old sed split blindly
# and broke both ways -- it severed trailing filesets from `jj split` (blocking
# a legal command) and, worse, left a trailing -i in a segment that no longer
# began with `jj`, so `jj commit -m "sub<newline>" -i` was never scanned and
# hung the agent. Backslash-newline is honoured as a line continuation.
# Never eval/word-split untrusted command text.
segment_command() {
  local s="$1" c nxt q="" cur="" i
  segments=()
  for (( i = 0; i < ${#s}; i++ )); do
    c="${s:i:1}"
    if [ -n "$q" ]; then
      if [ "$c" = '\' ] && [ "$q" = '"' ]; then cur+="$c${s:i+1:1}"; i=$((i+1)); continue; fi
      cur+="$c"
      [ "$c" = "$q" ] && q=""
      continue
    fi
    case "$c" in
      '\')
        nxt="${s:i+1:1}"
        # Line continuation: backslash and newline both vanish. Any other
        # escaped character is literal and cannot act as a separator.
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
# its value. Tokenizes quote-aware by hand — never eval/word-split untrusted
# command text, which would execute any $(...) inside it. Only called on a
# `jj split` segment, so the character loop costs nothing on other commands.
split_has_fileset() {
  local s="$1" c q="" tok="" had_tok=0 skip_next=0 seen_ddash=0 i
  local -a toks=()
  for (( i = 0; i < ${#s}; i++ )); do
    c="${s:i:1}"
    if [ -n "$q" ]; then
      if [ "$c" = '\' ] && [ "$q" = '"' ]; then tok+="${s:i+1:1}"; i=$((i+1)); had_tok=1; continue; fi
      if [ "$c" = "$q" ]; then q=""; else tok+="$c"; fi
      had_tok=1
    elif [ "$c" = '"' ] || [ "$c" = "'" ]; then
      q="$c"
      had_tok=1
    elif [ "$c" = " " ] || [ "$c" = $'\t' ]; then
      if [ "$had_tok" -eq 1 ]; then toks+=("$tok"); tok=""; had_tok=0; fi
    else
      tok+="$c"
      had_tok=1
    fi
  done
  [ "$had_tok" -eq 1 ] && toks+=("$tok")

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

# Split chained commands (&& || ; newline) and inspect each jj segment.
segment_command "$command"
for seg in "${segments[@]}"; do
  # Trim with parameter expansion, not sed: a segment can now legitimately
  # contain newlines, and sed would trim every line of the message instead.
  seg="${seg#"${seg%%[![:space:]]*}"}"
  seg="${seg%"${seg##*[![:space:]]}"}"
  [[ "$seg" =~ ^jj([[:space:]]|$) ]] || continue
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

  # 4. describe / commit open a description editor with no message.
  if [[ "$bare" =~ ^jj[[:space:]]+(describe|commit)([[:space:]]|$) ]] && ! has '-m|--message|--stdin'; then
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
  if [[ "$bare" =~ ^jj[[:space:]]+(commit|squash)([[:space:]]|$) ]] && has '-i|--interactive|--tool'; then
    block "  $seg
  -> -i/--interactive/--tool opens a diff editor to pick hunks and will hang.
     Drop the flag; stage by editing files, then \`jj squash -m\`."
  fi

  # 7. resolve opens the interactive merge editor unless a tool is named.
  if [[ "$bare" =~ ^jj[[:space:]]+resolve([[:space:]]|$) ]] && ! has '--tool'; then
    block "  $seg
  -> opens the interactive merge editor. Resolve by editing the conflict
     markers in the files directly, then \`jj squash -m\` / \`jj describe -m\`."
  fi
done

exit 0
