#!/bin/bash
# Hook: PreToolUse (Bash) — Block jj invocations that would open an interactive
# editor (text, diff, or merge) and hang the agent, or use a renamed subcommand.
# Command set verified against jj 0.43 CLI reference (docs.jj-vcs.dev).
# KNOWN OVER-BLOCK: `jj split` is rejected unconditionally below, but since 0.43 it
# only opens an editor when no filesets are given (`-i` is the default in that case).
# `jj split -r <rev> -m "msg" <paths>` is safe. Teaching the check that exception
# needs positional-vs-flag parsing, so it is left strict for now — see the caveat in
# rules/version-control.md for the restore-based workaround.
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

# Split chained commands (&& || ; newline) and inspect each jj segment.
segments=$(printf '%s' "$command" | sed -E 's/\&\&|\|\||;/\n/g')
while IFS= read -r seg; do
  seg="$(echo "$seg" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  [[ "$seg" =~ ^jj([[:space:]]|$) ]] || continue
  # Strip "double" and 'single' quoted substrings before flag scanning.
  bare="$(printf '%s' "$seg" | sed -E "s/\"[^\"]*\"//g; s/'[^']*'//g")"

  # --help / -h just prints usage; never opens an editor.
  [[ "$bare" =~ (^|[[:space:]])(-h|--help)([[:space:]]|$) ]] && continue

  # 1. No non-interactive mode at all.
  if [[ "$bare" =~ ^jj[[:space:]]+(split|diffedit)([[:space:]]|$) ]]; then
    block "  $seg
  -> jj ${BASH_REMATCH[1]} has no non-interactive mode. Restructure with
     \`jj squash -m\`, \`jj new -m\`, or \`jj describe -m\` instead."
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
done <<< "$segments"

exit 0
