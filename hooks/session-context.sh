#!/bin/bash
# ABOUTME: Prepare context at session start - load project-specific config and check for issues
# Runs once per session to provide proactive context without consuming conversation tokens

set -e

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  exit 0
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
PROJECT_CLAUDE="$REPO_ROOT/.claude/CLAUDE.md"

# 1. Notify about project-specific context
if [ -f "$PROJECT_CLAUDE" ]; then
  echo "📋 Project-specific context available in .claude/CLAUDE.md"
fi

# 2. Check for common issues
# Outdated dependencies
if [ -f "$REPO_ROOT/package.json" ]; then
  if command -v pnpm &> /dev/null; then
    OUTDATED_COUNT=$(pnpm outdated --format json 2>/dev/null | grep -c '"name"' || echo 0)
    if [ "$OUTDATED_COUNT" -gt 0 ]; then
      echo "⚠️  $OUTDATED_COUNT outdated npm dependencies detected (run 'pnpm up' to update)"
    fi
  fi
fi

# 3. Check for uncommitted changes
CHANGES=$(git status --porcelain 2>/dev/null | wc -l)
if [ "$CHANGES" -gt 0 ]; then
  echo "📝 $CHANGES uncommitted changes (use '/commit' when ready)"
fi

# 4. Check for active feature branches
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" =~ ^(main|master|develop|dev)$ ]]; then
  echo "⚠️  On protected branch '$CURRENT_BRANCH' (use '/feature-branch create' to create feature branch)"
else
  echo "✓ On feature branch: $CURRENT_BRANCH"
fi

# 5. Check for pre-commit framework
if [ -f "$REPO_ROOT/.pre-commit-config.yaml" ]; then
  echo "✓ Pre-commit hooks configured"
fi

exit 0
