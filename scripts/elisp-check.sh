#!/usr/bin/env bash
# pre-commit entry for elisp linting; skips when emacs is absent (CI runners).
set -euo pipefail

if ! command -v emacs >/dev/null 2>&1; then
  echo "elisp-check: emacs not found, skipping"
  exit 0
fi

exec emacs --batch -l "$(cd "$(dirname "$0")" && pwd)/elisp-check.el" "$@"
