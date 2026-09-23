# shellcheck shell=bash disable=SC2034  # globals are read by the sourcing guard
# Shared command-line parsing for the PreToolUse Bash guards
# (branch_protection.sh, git_dangerous_flags.sh, jj_interactive_guard.sh).
# Sourced, never executed; bash 3.2 compatible. Never eval/word-split untrusted
# command text: eval would run any $(...) embedded in it.
#
# One copy on purpose. The guards used to carry verbatim copies of these
# functions, and they drifted: only the jj guard learned that \" inside "..."
# does not close the string, so in the other two
# `git commit -m "say \"hi\"" && git push --force` reopened a quote over the
# `&&` and the force-push was never seen (found 2026-09-23).
#
# What reaches the guards is bounded by the `if` filters in settings.json.
# `"if": "Bash(git *)"` looks past leading VAR=value assignments only, so a
# command that STARTS with a wrapper (`timeout 5 git ...`, `env git ...`,
# `nice git ...`) never runs a guard at all. Wrapper and keyword stripping
# therefore only matter inside a compound command the filter already let
# through, e.g. `git status && timeout 5 git push --force`.
#
# Globals set here: segments toks tokpos sub argstart peeled stripped
#                   hd_delim hd_dash hd_end

segments=(); toks=(); tokpos=(); sub=""; argstart=0; peeled=""; stripped=""
hd_delim=""; hd_dash=0; hd_end=0

# Split a command line into `segments` at unquoted command boundaries: ; && ||
# newline, | and & (pipes and background jobs), ( ) and backtick (subshells and
# command substitution), and { } where they stand alone as words. Every one of
# those starts a new command, and a command that does not start a segment is
# never checked: `(git push --force)`, `x | xargs git push -f`,
# `echo $(git push -f)` and `git fetch & git push -f` all passed before.
# Redirections stay whole (2>&1, &>f, >|f), as do braces inside a word
# (HEAD@{1}, ${x}, {a,b}, find's {}). Over-splitting only exposes more
# segments to the anchored ^git/^jj checks, so a spurious split risks a false
# block, never a missed one.
#
# Quote-aware: a separator inside a -m message is message text, and \" inside
# "..." is a literal quote that does not close the string. Backslash-newline is
# a line continuation. A plain sed split broke both ways: it severed trailing
# filesets from `jj split`, and left a trailing -i in a segment that no longer
# began with `jj`, so `jj commit -m "sub<newline>" -i` was never scanned.
segment_command() {
  local s="$1" c nxt prv q="" cur="" i d line cmp tab=$'\t' docs
  segments=(); docs=()
  for (( i = 0; i < ${#s}; i++ )); do
    c="${s:i:1}"
    if [ -n "$q" ]; then
      # Inside "..." a backslash escapes the next character. Single quotes
      # take no escapes.
      if [ "$c" = '\' ] && [ "$q" = '"' ]; then cur+="$c${s:i+1:1}"; i=$((i+1)); continue; fi
      cur+="$c"
      [ "$c" = "$q" ] && q=""
      continue
    fi
    prv=""; (( i > 0 )) && prv="${s:i-1:1}"
    nxt="${s:i+1:1}"
    case "$c" in
      '\')
        # Line continuation: backslash and newline both vanish. Any other
        # escaped character is literal and cannot act as a separator.
        if [ "$nxt" = $'\n' ]; then i=$((i+1)); else cur+="$c$nxt"; i=$((i+1)); fi
        ;;
      '"' | "'") q="$c"; cur+="$c" ;;
      '<')
        if [ "${s:i:3}" = '<<<' ]; then
          cur+='<<<'; i=$((i+2))
        elif [ "$nxt" = '<' ]; then
          heredoc_word "$s" "$i"
          cur+="${s:i:hd_end-i+1}"; i=$hd_end
          [ -n "$hd_delim" ] && docs+=("$hd_dash$hd_delim")
        else
          cur+="$c"
        fi ;;
      $'\n' | ';')
        segments+=("$cur"); cur=""
        # The newline ends the line that opened any heredocs; their bodies come
        # next. Each body line is its own segment with quote tracking off, so a
        # `bash <<EOF` body is still checked line by line.
        if [ "$c" = $'\n' ] && (( ${#docs[@]} )); then
          for d in "${docs[@]}"; do
            while (( i + 1 < ${#s} )); do
              line="${s:i+1}"; line="${line%%$'\n'*}"
              i=$(( i + 1 + ${#line} ))
              cmp="$line"; [ "${d:0:1}" = 1 ] && cmp="${cmp#"${cmp%%[!$tab]*}"}"
              [ "$cmp" = "${d:1}" ] && break
              segments+=("$line")
            done
          done
          docs=()
        fi ;;
      '&')
        if [ "$nxt" = '&' ]; then
          segments+=("$cur"); cur=""; i=$((i+1))
        elif [ "$nxt" = '>' ] || [ "$prv" = '>' ] || [ "$prv" = '<' ]; then
          cur+="$c"                      # &> >& <& are redirections
        else
          segments+=("$cur"); cur=""     # background job: `a & b` runs both
        fi ;;
      '|')
        if [ "$nxt" = '|' ]; then
          segments+=("$cur"); cur=""; i=$((i+1))
        elif [ "$prv" = '>' ]; then
          cur+="$c"                      # >| is a redirection
        else
          segments+=("$cur"); cur=""     # pipe: `x | xargs git push -f`
        fi ;;
      '(' | ')' | '`') segments+=("$cur"); cur="" ;;
      '{' | '}')
        if { [ -z "$prv" ] || [[ "$prv" == [[:space:]\;\&\|\(\)] ]]; } \
           && { [ -z "$nxt" ] || [[ "$nxt" == [[:space:]\;\&\|\)] ]]; }; then
          segments+=("$cur"); cur=""
        else
          cur+="$c"
        fi ;;
      *) cur+="$c" ;;
    esac
  done
  segments+=("$cur")
  return 0
}

# Heredoc bodies are data, not shell. Tracked as quoted text, an apostrophe in
# `don't` opened a quote that never closed and swallowed every later command:
# 4 direct commits to master slipped past all three guards that way (found
# 2026-09-18). Parses the delimiter after the `<<` or `<<-` at index $2 of $1.
# Sets hd_delim (quotes removed), hd_dash (1 for <<-), and hd_end (index of the
# delimiter's last character).
heredoc_word() {
  local s="$1" j=$(( $2 + 2 )) c q=""
  hd_delim=""; hd_dash=0
  if [ "${s:j:1}" = "-" ]; then hd_dash=1; j=$((j+1)); fi
  while [ "${s:j:1}" = " " ] || [ "${s:j:1}" = $'\t' ]; do j=$((j+1)); done
  for (( ; j < ${#s}; j++ )); do
    c="${s:j:1}"
    if [ -n "$q" ]; then
      if [ "$c" = "$q" ]; then q=""; else hd_delim+="$c"; fi
      continue
    fi
    case "$c" in
      "'" | '"') q="$c" ;;
      '\') j=$((j+1)); hd_delim+="${s:j:1}" ;;
      ' ' | $'\t' | $'\n' | ';' | '&' | '|' | '<' | '>' | '(' | ')') break ;;
      *) hd_delim+="$c" ;;
    esac
  done
  hd_end=$((j-1))
}

# Tokenize one segment into `toks` the way the shell forms words, and record
# where each token starts in the segment in `tokpos`. Quotes delimit and are
# removed, so `-m "a b"` yields `-m` and `a b` and a flag written inside a
# message can never look like a token. Inside "...", \" \\ \$ \` are escapes
# (so \" does not close the string); an unquoted backslash escapes the next
# character, as in the shell (`\--force` is `--force`).
tokenize() {
  local s="$1" c nxt q="" tok="" had=0 start=0 i
  toks=(); tokpos=()
  for (( i = 0; i < ${#s}; i++ )); do
    c="${s:i:1}"
    if [ -n "$q" ]; then
      if [ "$c" = '\' ] && [ "$q" = '"' ]; then
        nxt="${s:i+1:1}"
        case "$nxt" in
          '"' | '\' | '$' | '`') tok+="$nxt"; i=$((i+1)) ;;
          $'\n') i=$((i+1)) ;;
          *) tok+="$c" ;;
        esac
      elif [ "$c" = "$q" ]; then
        q=""
      else
        tok+="$c"
      fi
      continue
    fi
    case "$c" in
      ' ' | $'\t' | $'\n')
        if [ "$had" -eq 1 ]; then toks+=("$tok"); tokpos+=("$start"); tok=""; had=0; fi
        continue ;;
    esac
    [ "$had" -eq 0 ] && start=$i
    had=1
    case "$c" in
      '"' | "'") q="$c" ;;
      '\')
        nxt="${s:i+1:1}"; i=$((i+1))
        [ "$nxt" = $'\n' ] || tok+="$nxt" ;;
      *) tok+="$c" ;;
    esac
  done
  if [ "$had" -eq 1 ]; then toks+=("$tok"); tokpos+=("$start"); fi
  return 0
}

# NAME=value prefix, quote-aware. The value is one shell word, and a word may
# carry whitespace inside quotes or $(...) -- `X="$(a b)" git ...` is a single
# assignment followed by a git command. The old `[^[:space:]]*` regex stopped at
# the first space, so the segment never began with `git` and skipped every check
# (found 2026-09-07 via `JJ_EDITOR="$(jq -r ...)" timeout 10 jj describe`).
# Sets the global `peeled` to the text after the assignment, or "" when the
# segment is not an assignment prefix (or is an assignment with nothing after).
peel_assignment() {
  local s="$1" c q="" stack="" i n
  n=${#s}
  peeled=""
  [[ "$s" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] || return 0
  for (( i = ${#BASH_REMATCH[0]}; i < n; i++ )); do
    c="${s:i:1}"
    if [ "$q" = "'" ]; then
      if [ "$c" = "'" ]; then q=""; fi
      continue
    fi
    if [ "$c" = '\' ]; then i=$((i+1)); continue; fi
    if [ "$q" = '"' ]; then
      case "$c" in
        '"') q="" ;;
        # $( ) opens a fresh unquoted context inside the string; remember to
        # return to double-quote mode at the matching ).
        '$') if [ "${s:i+1:1}" = '(' ]; then stack+='"'; q=""; i=$((i+1)); fi ;;
      esac
      continue
    fi
    case "$c" in
      "'" | '"') q="$c" ;;
      '(') stack+='-' ;;
      ')')
        if [ -n "$stack" ]; then
          q="${stack: -1}"; if [ "$q" = '-' ]; then q=""; fi
          stack="${stack%?}"
        fi ;;
      ' ' | $'\t')
        if [ -z "$stack" ]; then
          peeled="${s:i}"
          peeled="${peeled#"${peeled%%[![:space:]]*}"}"
          return 0
        fi ;;
    esac
  done
  return 0
}

# Peel what runs the real command after it: env assignments, shell keywords
# that begin a command inside a compound (`for ...; do git push -f; done`,
# `if x; then git push -f; fi`, `! git commit`), and wrapper commands
# (`timeout 5 git ...`, `x | xargs git push -f`), so the anchored ^git/^jj/^gh
# test sees the command. See the header for why this matters only inside
# compound commands. Sets the global `stripped` rather than echoing: a $(...)
# call would fork a subshell per segment. Peeling only ever exposes MORE of the
# command line, so an over-eager strip risks a false block, never a missed one.
strip_wrappers() {
  local s="$1" prev="" rest
  local kw_re='^(then|do|else|elif|if|while|until|!)[[:space:]]+(.*)$'
  # xargs short options that take a SEPARATE value (BSD and GNU): -I {} etc.
  local xargs_re='^-[aEIJLnPRSsd][[:space:]]+[^[:space:]]+[[:space:]]+(.*)$'
  while [ "$s" != "$prev" ]; do
    prev="$s"
    # VAR=value prefix (also covers `env FOO=1 ...` on the next pass).
    if [[ "$s" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      peel_assignment "$s"
      if [ -n "$peeled" ]; then s="$peeled"; continue; fi
    fi
    # Reserved words that start a command inside a compound.
    if [[ "$s" =~ $kw_re ]]; then
      s="${BASH_REMATCH[2]}"; continue
    fi
    # Wrappers that take no options of their own.
    if [[ "$s" =~ ^(command|builtin|exec|nohup|setsid|time)[[:space:]]+(.*)$ ]]; then
      s="${BASH_REMATCH[2]}"; continue
    fi
    # timeout [-opts] DURATION cmd
    if [[ "$s" =~ ^timeout[[:space:]]+(-[^[:space:]]+[[:space:]]+)*[0-9]+(\.[0-9]+)?[smhd]?[[:space:]]+(.*)$ ]]; then
      s="${BASH_REMATCH[3]}"; continue
    fi
    # xargs [-opts] cmd
    if [[ "$s" =~ ^xargs[[:space:]]+(.*)$ ]]; then
      rest="${BASH_REMATCH[1]}"
      while true; do
        if [[ "$rest" =~ $xargs_re ]]; then
          rest="${BASH_REMATCH[1]}"; continue
        fi
        if [[ "$rest" =~ ^-[^[:space:]]+[[:space:]]+(.*)$ ]]; then
          rest="${BASH_REMATCH[1]}"; continue
        fi
        break
      done
      s="$rest"; continue
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

# Resolve the subcommand in `toks`, skipping the tool's global options. $1 is
# the pipe-separated list of global options that take a SEPARATE value token;
# attached (--git-dir=x, -R.) and valueless (--no-pager) globals are one token.
# Sets `sub` and `argstart` (index just past the subcommand) rather than
# echoing: a $(...) call would run this in a subshell and lose argstart.
resolve_subcommand() {
  local valued="$1" i=1 t
  sub=""; argstart=0
  while (( i < ${#toks[@]} )); do
    t="${toks[i]}"
    if [[ "$t" =~ ^(${valued})$ ]]; then i=$((i+2)); continue; fi
    case "$t" in
      -*) i=$((i+1)); continue ;;
      *) sub="$t"; argstart=$((i+1)); return 0 ;;
    esac
  done
  return 1
}
