#!/bin/bash
# Hook: statusLine — two rows: starship prompt, then Claude session metrics.
# Falls back to directory + git branch if starship is unavailable.
#
# Non-obvious things, all of which have bitten:
#   - rate_limits is an object keyed by window (.five_hour / .seven_day), NOT an
#     array. `.rate_limits[0]` yields null silently and the segment just vanishes.
#   - ctx and rl both report *consumed*, never remaining, so they read alike.
#   - A bare quota % is not actionable: 18% an hour into a 5h window is healthy,
#     18% ten minutes in is not. resets_at makes pace computable with no network
#     call — see burn_rate below.
#   - Glyphs are limited to what Berkeley Mono ships. No powerline separators or
#     Nerd Font icons; they would also clash with the glyph-free starship row.
#   - Cost is omitted deliberately, matching DISABLE_COST_WARNINGS=1.
#   - Unused on purpose: durations, vim.mode, agent.name, output_style.name,
#     session_name, version, workspace.repo.* (row 1 already shows it).
#
# History belongs to git and skills/syncing-claude-config/baseline.json, not here.
input=$(cat)
now=$(date +%s)

# Truecolor SGR pinned to Catppuccin Mocha (themes/catppuccin-mocha.json
# success/warning/error) -- the shades ghostty already resolved 32/33/31 to.
# Cost of pinning: no longer follows a theme switch. starship row 1 is pinned
# to match, so retune the two together, or revert both to colour names.
GREEN='38;2;166;227;161'  # Mocha Green  #a6e3a1
YELLOW='38;2;249;226;175' # Mocha Yellow #f9e2af
RED='38;2;243;139;168'    # Mocha Red    #f38ba8

paint() { printf '\033[%sm%s\033[0m' "$1" "$2"; }

# Compact fill bar. Thin box-drawing rules rather than block shading: ░ is a 25%
# stipple that reads as heavy next to the glyph-free starship row, where ─ carries
# the same fill/empty concept at a fraction of the visual weight.
#
# Built by loop rather than substring expansion, which is not reliably
# character-wise on multibyte glyphs. Cell count is rounded, not floored -- at five
# cells a floor would render 18% as a completely empty bar.
BAR_WIDTH=5
BAR_FILL='━'
BAR_EMPTY='─'

bar() {
  local pct=$1 w=${2:-$BAR_WIDTH} f i out=''
  f=$(((pct * w + 50) / 100))
  ((f > w)) && f=$w
  ((f < 0)) && f=0
  for ((i = 0; i < f; i++)); do out+="$BAR_FILL"; done
  for ((i = f; i < w; i++)); do out+="$BAR_EMPTY"; done
  printf '%s' "$out"
}

# Burn rate as a percentage: used% relative to elapsed% of the window. 100 means
# exactly even consumption, 600 means burning six times too fast.
#
# This is used-vs-elapsed rather than benabraham's remaining-vs-remaining ratio.
# The remaining form answers "will I run out before reset", which under-reacts
# early on: 18% burned ten minutes into a 5h window scores a mild 0.85 by that
# measure while the observed rate is over 5x even pace. Comparing against elapsed
# time is what jtbr's pacing marker actually visualises.
#
# Prints nothing when the window has no resets_at or has already rolled over.
burn_rate() {
  local resets=$1 window=$2 used=$3 elapsed
  [[ "$resets" == "-" ]] && return 1
  ((resets <= now)) && return 1
  # Elapsed is tracked in tenths of a percent. Whole percent loses too much to
  # truncation now that the multiple is displayed, not just used to pick a colour:
  # ten minutes into a 5h window truncates 3.3% to 4%, reporting 4.5x for a true 5.4x.
  elapsed=$((1000 - (resets - now) * 1000 / window))
  # Guard both the divide-by-zero and the meaningless ratio in the first moments
  # of a window, where any usage at all divides by ~0.
  ((elapsed < 1)) && elapsed=1
  printf '%s' "$((used * 1000 / elapsed))"
}

# Tolerance band is deliberately wide: a signal that flickers on a two-point
# overshoot trains you to ignore it.
PACE_OK=125
PACE_WARN=175

# Usage below this is too small to be worth pacing commentary regardless of rate.
PACE_FLOOR=15

quota_colour() {
  local used=$1 resets=$2 window=$3 rate
  # Absolute floor first: near the cap, pace stops mattering.
  ((used >= 90)) && {
    printf '%s' "$RED"
    return
  }
  ((used >= 75)) && {
    printf '%s' "$YELLOW"
    return
  }
  ((used < PACE_FLOOR)) && {
    printf '%s' "$GREEN"
    return
  }
  if ! rate=$(burn_rate "$resets" "$window" "$used"); then
    # No reset time: fall back to flat thresholds.
    ((used >= 50)) && {
      printf '%s' "$YELLOW"
      return
    }
    printf '%s' "$GREEN"
    return
  fi
  ((rate <= PACE_OK)) && {
    printf '%s' "$GREEN"
    return
  }
  ((rate <= PACE_WARN)) && {
    printf '%s' "$YELLOW"
    return
  }
  printf '%s' "$RED"
}

# Renders "2.2x pace" from a burn rate held as an integer percentage.
fmt_rate() { printf '%d.%dx pace' $(($1 / 100)) $((($1 % 100) / 10)); }

# One quota window: "5h 45% 2.2x pace". The marker is deliberately NOT the word
# "fast" -- that is the fast_mode segment's word, and reusing it here made one
# token mean two unrelated things on the same row. Showing the actual multiple is
# also more useful than a flag: it says how far over, not merely that you are.
#
# The marker only appears past the warn band, so a healthy window stays bare.
quota_seg() {
  local label=$1 used=$2 resets=$3 window=$4 rate out
  out="${label} $(paint "$(quota_colour "$used" "$resets" "$window")" "${used}%")"
  if rate=$(burn_rate "$resets" "$window" "$used"); then
    if ((used >= PACE_FLOOR && rate > PACE_WARN)); then
      out+=" $(fmt_rate "$rate")"
    fi
  fi
  printf '%s' "$out"
}

# ---- Row 2 data: one jq pass, tab-separated, "-" for anything absent.
IFS=$'\t' read -r dir model fast effort ctx win rl5 rl5r rl7 rl7r la lr prnum prstate prurl wt <<<"$(
  jq -r '[
    (.workspace.current_dir // .cwd // "-"),
    # Strip a trailing "(1M context)" style parenthetical: the ctx segment already
    # reports the window from context_window_size, which is authoritative and also
    # present for models whose display name carries no size. Only parentheticals
    # mentioning context are removed, so something like "(fast)" would survive.
    (.model.display_name // "-" | gsub(" *\\([^)]*[Cc]ontext[^)]*\\)"; "")),
    (if .fast_mode then "fast" else "-" end),
    (.effort.level // "-"),
    (if .context_window.used_percentage then (.context_window.used_percentage | round | tostring) else "-" end),
    (if .context_window.context_window_size then
       (.context_window.context_window_size as $s
        | if   $s >= 1000000 then (($s / 1000000 | floor | tostring) + "M")
          elif $s >= 1000    then (($s / 1000    | floor | tostring) + "k")
          else ($s | tostring) end)
     else "-" end),
    (if .rate_limits.five_hour.used_percentage then (.rate_limits.five_hour.used_percentage | round | tostring) else "-" end),
    (.rate_limits.five_hour.resets_at // "-" | tostring),
    (if .rate_limits.seven_day.used_percentage then (.rate_limits.seven_day.used_percentage | round | tostring) else "-" end),
    (.rate_limits.seven_day.resets_at // "-" | tostring),
    (.cost.total_lines_added // "-"),
    (.cost.total_lines_removed // "-"),
    (.pr.number // "-"),
    (.pr.review_state // "-"),
    (.pr.url // "-"),
    (.workspace.git_worktree // .worktree.name // "-")
  ] | @tsv' <<<"$input" 2>/dev/null
)"

# ---- Row 1: starship, rendered from the workspace directory.
if [[ "$dir" != "-" && -d "$dir" ]]; then
  cd "$dir" 2>/dev/null || cd "${PWD:-$HOME}" || exit 0
else
  cd "${PWD:-$HOME}" || exit 0
fi

if [[ -x /opt/homebrew/bin/starship ]]; then
  STARSHIP_CMD=/opt/homebrew/bin/starship
else
  STARSHIP_CMD=$(command -v starship 2>/dev/null)
fi

row1=""
if [[ -n "$STARSHIP_CMD" ]]; then
  export STARSHIP_SHELL=generic
  # Strip everything from the prompt char on: starship trails it with a reset
  # escape, so an anchored `❯[[:space:]]*$` never matches. Re-reset explicitly
  # below so the removed escape can't leave colour bleeding into row 2.
  row1=$("$STARSHIP_CMD" prompt --terminal-width="${COLUMNS:-120}" 2>/dev/null |
    sed 's/❯.*$//' |
    sed 's/%{[^}]*}//g' |
    tr -s ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
    tr -d '\n\r')
  [[ -n "$row1" ]] && row1+=$'\033[0m'
fi
if [[ -z "$row1" ]]; then
  row1="$(basename "$(pwd)") on $(git branch --show-current 2>/dev/null || echo no-git)"
fi

# ---- Row 2: only segments that carry data.
seg=()
[[ "$model" != "-" ]] && seg+=("$model")
[[ "$fast" != "-" ]] && seg+=("$fast")
[[ "$effort" != "-" ]] && seg+=("$effort")

# Context: window size prefixes the percentage so "34%" is unambiguous about what
# it is 34% of -- a fallback to a 200k model is otherwise invisible here. A "+" on
# the size marks having crossed 200k total tokens, i.e. into long-context premium
# pricing on a 1M window; that subsumes the old standalone "200k+" segment.
# Every percentage on this row is consumption, spelled out as "used" rather than
# left to convention -- the direction is not guessable and reading it backwards
# inverts the meaning.
if [[ "$ctx" != "-" ]]; then
  cc=$GREEN
  ((ctx >= 70)) && cc=$YELLOW
  ((ctx >= 90)) && cc=$RED
  label="ctx $(paint "$cc" "$(bar "$ctx")") ${ctx}%"
  [[ "$win" != "-" ]] && label+=" of ${win}"
  seg+=("$label")
fi

# Subscription rate limits, labelled by window rather than an "rl" abbreviation --
# two bare numbers behind one opaque label don't say what they measure. Each window
# can be absent independently, so they are emitted separately.
rl=()
[[ "$rl5" != "-" ]] && rl+=("$(quota_seg 5h "$rl5" "$rl5r" 18000)")
[[ "$rl7" != "-" ]] && rl+=("$(quota_seg 7d "$rl7" "$rl7r" 604800)")
if ((${#rl[@]})); then
  seg+=("${rl[*]}")
fi

# Session churn, in the ↑/↓ notation from rules/status-marks.md. Suppressed while
# both are zero so an untouched session carries no segment.
#
# Only the glyphs are coloured, per that same rule ("style only the glyph; leave
# the number plain"). That also keeps the red ↓ from reading as an alert the way a
# red *number* would, since red carries the critical threshold elsewhere on this row.
if [[ "$la" != "-" || "$lr" != "-" ]]; then
  [[ "$la" == "-" ]] && la=0
  [[ "$lr" == "-" ]] && lr=0
  if ((la > 0 || lr > 0)); then
    seg+=("$(paint "$GREEN" '↑') ${la} $(paint "$RED" '↓') ${lr}")
  fi
fi

# PR label, hyperlinked via OSC 8 when a URL is present. Plain text inside the
# link per the linked-labels rule in rules/status-marks.md.
if [[ "$prnum" != "-" ]]; then
  label="PR#${prnum}"
  [[ "$prstate" != "-" ]] && label+=" ${prstate}"
  if [[ "$prurl" != "-" ]]; then
    label=$'\033]8;;'"${prurl}"$'\033\\'"${label}"$'\033]8;;\033\\'
  fi
  seg+=("$label")
fi

[[ "$wt" != "-" ]] && seg+=("wt:${wt}")

# Both rows are emitted whole: row1 carries ANSI colour and row2 can carry an OSC 8
# hyperlink, and slicing by character count can cut an escape mid-sequence and
# corrupt the terminal. Claude Code handles over-width rows itself (v2.1.141).
printf '%s\n' "$row1"
if ((${#seg[@]})); then
  row2=$(
    IFS='|'
    printf '%s' "${seg[*]}"
  )
  printf '%s\n' "${row2//|/ · }"
fi
