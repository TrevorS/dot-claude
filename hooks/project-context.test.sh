#!/bin/bash
# Regression test for user-prompt-submit/project-context.sh — the
# UserPromptSubmit hook that prefixes every prompt with one key=value line.
#
# Pins three things. The output contract (valid JSON, right event name, one
# terse line of key=value fields) because the token-budget argument in the hook
# header only holds while the line stays a line. The sed dialect flag, driven
# entirely by PATH so every outcome is forced regardless of host: gsed present
# -> gnu, GNU sed under its own name -> gnu, a sed that rejects --version ->
# bsd. And the vcs branch, since the jj facts come from one templated call
# whose field parsing can break silently (an empty bookmark column must not
# shift `dirty` into its place).
#
# Run: ./hooks/project-context.test.sh   (exit 0 = all pass)
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/user-prompt-submit/project-context.sh"
REAL_JQ=$(command -v jq) || { echo "project-context: jq required"; exit 1; }

fails=0
ok()   { printf '  ok   PASS   %s\n' "$1"; }
bad()  { printf '  FAIL        %s\n' "$1"; fails=$((fails + 1)); }
skip() { printf '  --   SKIP   %s\n' "$1"; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Run the hook in <dir> with PATH=<bin>:/usr/bin:/bin; prints additionalContext.
ctx_in() {
  local dir=$1 bin=$2
  (cd "$dir" && PATH="$bin:/usr/bin:/bin" "$HOOK" </dev/null 2>/dev/null) \
    | "$REAL_JQ" -r '.hookSpecificOutput.additionalContext // empty'
}

# <label> <ctx> <field that must appear whole, e.g. sed=gnu>
has() {
  local label=$1 ctx=$2 want=$3
  case " $ctx " in
    *" $want "*) ok "$label" ;;
    *) bad "$label (missing '$want' in: $ctx)" ;;
  esac
}

# <label> <ctx> <key that must NOT appear, e.g. root>
lacks() {
  local label=$1 ctx=$2 key=$3
  case " $ctx " in
    *" $key="*) bad "$label (unexpected '$key=' in: $ctx)" ;;
    *) ok "$label" ;;
  esac
}

# --- PATH sandboxes ----------------------------------------------------------
# Only what the hook needs is real: jq (symlinked), date/cat/git from /usr/bin.
# Homebrew is deliberately off PATH so the host's gsed cannot leak in.
mkbin() { # mkbin <tag> [<stub-name> <stub-body>]...
  local d="$work/bin-$1"
  mkdir -p "$d"
  ln -sf "$REAL_JQ" "$d/jq"
  shift
  while (($#)); do
    printf '#!/bin/sh\n%s\n' "$2" >"$d/$1"
    chmod +x "$d/$1"
    shift 2
  done
  echo "$d"
}
bin_bsd=$(mkbin bsd sed 'echo "sed: illegal option -- -" >&2; exit 1')
bin_gnu=$(mkbin gnu sed 'echo "sed (GNU sed) 4.9"')
bin_gsed=$(mkbin gsed gsed 'echo "gsed (GNU sed) 4.10"' sed 'echo "usage: sed" >&2; exit 1')

# --- output contract ---------------------------------------------------------
bare="$work/bare"
mkdir -p "$bare"
raw=$(cd "$bare" && PATH="$bin_bsd:/usr/bin:/bin" "$HOOK" </dev/null 2>/dev/null)
rc=$?
if [ "$rc" -eq 0 ]; then ok "exit 0 in a bare dir"; else bad "exit $rc in a bare dir"; fi
if printf '%s' "$raw" | "$REAL_JQ" -e '.hookSpecificOutput.hookEventName == "UserPromptSubmit"' >/dev/null 2>&1; then
  ok "valid JSON with hookEventName=UserPromptSubmit"
else
  bad "output is not the UserPromptSubmit envelope: $raw"
fi

ctx=$(ctx_in "$bare" "$bin_bsd")
if [ "$(printf '%s' "$ctx" | wc -l | tr -d ' ')" = "0" ]; then ok "context is a single line"; else bad "context spans lines"; fi
shape_ok=1
for tok in $ctx; do
  case "$tok" in *=*) ;; *) shape_ok=0; bad "non key=value field: '$tok'" ;; esac
done
[ "$shape_ok" -eq 1 ] && ok "every field is key=value"
case "$ctx" in
  "date=$(date +%Y-%m-%d) cwd="*) ok "leads with date=YYYY-MM-DD cwd=" ;;
  *) bad "unexpected prefix: $ctx" ;;
esac
has "bare dir reports vcs=none" "$ctx" "vcs=none"
has "bare dir reports pkg=none" "$ctx" "pkg=none"
has "bare dir reports ci=none" "$ctx" "ci=none"
lacks "no root= outside a repo" "$ctx" "root"

# --- sed dialect -------------------------------------------------------------
has "sed rejecting --version -> sed=bsd" "$ctx" "sed=bsd"
has "GNU sed under its own name -> sed=gnu" "$(ctx_in "$bare" "$bin_gnu")" "sed=gnu"
has "gsed on PATH wins even beside a BSD sed -> sed=gnu" "$(ctx_in "$bare" "$bin_gsed")" "sed=gnu"

# --- lockfile / ci detection -------------------------------------------------
proj="$work/proj"
mkdir -p "$proj/.github/workflows"
touch "$proj/uv.lock"
ctx=$(ctx_in "$proj" "$bin_bsd")
has "uv.lock -> pkg=uv" "$ctx" "pkg=uv"
has ".github/workflows -> ci=github-actions" "$ctx" "ci=github-actions"

# --- git -----------------------------------------------------------------------
if command -v git >/dev/null 2>&1; then
  g="$work/git"
  mkdir -p "$g"
  (
    cd "$g" && git init -q -b main . &&
      git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
  ) 2>/dev/null
  ctx=$(ctx_in "$g" "$bin_bsd")
  has "git repo -> vcs=git" "$ctx" "vcs=git"
  has "git repo -> branch=main" "$ctx" "branch=main"
  has "clean git repo -> dirty=no" "$ctx" "dirty=no"
  lacks "no root= when cwd is the repo root" "$ctx" "root"
  touch "$g/f"
  has "untracked file -> dirty=yes" "$(ctx_in "$g" "$bin_bsd")" "dirty=yes"

  # Subdirectory: vcs/root/ci resolve via the walk-up; pkg prefers cwd's own
  # lockfile and falls back to the root's.
  mkdir -p "$g/.github/workflows" "$g/pkgs/rs/deep" "$g/pkgs/plain"
  touch "$g/uv.lock" "$g/pkgs/rs/Cargo.lock"
  ctx=$(ctx_in "$g/pkgs/rs/deep" "$bin_bsd")
  has "subdir -> vcs=git" "$ctx" "vcs=git"
  has "subdir -> root=<repo>" "$ctx" "root=$g"
  has "subdir -> branch=main" "$ctx" "branch=main"
  has "subdir -> ci from repo root" "$ctx" "ci=github-actions"
  has "subdir without its own lockfile -> pkg from root" "$ctx" "pkg=uv"
  has "subdir with its own lockfile -> pkg from cwd" "$(ctx_in "$g/pkgs/rs" "$bin_bsd")" "pkg=cargo"
  has "plain subdir -> pkg from root" "$(ctx_in "$g/pkgs/plain" "$bin_bsd")" "pkg=uv"

  # Linked worktree: .git is a file, not a directory.
  wt="$work/wt"
  (cd "$g" && git worktree add -q -b wt-branch "$wt") 2>/dev/null
  if [ -f "$wt/.git" ]; then
    ctx=$(ctx_in "$wt" "$bin_bsd")
    has "worktree (.git file) -> vcs=git" "$ctx" "vcs=git"
    has "worktree (.git file) -> branch=wt-branch" "$ctx" "branch=wt-branch"
  else
    skip "git worktree add unavailable"
  fi
else
  skip "git not installed"
fi

# --- jj ------------------------------------------------------------------------
if command -v jj >/dev/null 2>&1; then
  ln -sf "$(command -v jj)" "$bin_bsd/jj"
  j="$work/jj"
  mkdir -p "$j"
  (cd "$j" && jj git init --colocate . >/dev/null 2>&1)
  ctx=$(ctx_in "$j" "$bin_bsd")
  has "colocated jj repo -> vcs=jj-colocated" "$ctx" "vcs=jj-colocated"
  if printf '%s' "$ctx" | grep -qE ' change=[k-z]{8,}( |$)'; then
    ok "jj repo -> change=<id>"
  else
    bad "jj repo missing change=<id>: $ctx"
  fi
  # Empty bookmark column must not shift dirty into its place.
  has "fresh jj repo, no bookmark -> dirty=no" "$ctx" "dirty=no"
  case " $ctx " in
    *" bookmark="*) bad "phantom bookmark= field with no bookmark: $ctx" ;;
    *) ok "no bookmark= field when @ has none" ;;
  esac
  touch "$j/f"
  has "jj working-copy change -> dirty=yes" "$(ctx_in "$j" "$bin_bsd")" "dirty=yes"
  (cd "$j" && jj bookmark create -r @ feature >/dev/null 2>&1)
  has "jj bookmark on @ -> bookmark=feature" "$(ctx_in "$j" "$bin_bsd")" "bookmark=feature"

  mkdir -p "$j/sub/dir"
  ctx=$(ctx_in "$j/sub/dir" "$bin_bsd")
  has "jj subdir -> vcs=jj-colocated" "$ctx" "vcs=jj-colocated"
  has "jj subdir -> root=<repo>" "$ctx" "root=$j"
  has "jj subdir -> bookmark=feature" "$ctx" "bookmark=feature"
else
  skip "jj not installed"
fi

if [ "$fails" -eq 0 ]; then
  echo "project-context: all cases passed"
else
  echo "project-context: $fails case(s) failed"
fi
exit $((fails > 0))
