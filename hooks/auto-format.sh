#!/bin/bash
# ABOUTME: Auto-format files after Edit/Write tools for consistency without token cost
# Auto-applies prettier, ruff, rustfmt based on file type detected from TOOL_OUTPUT

set -e

# Get file path from tool output
FILE_PATH="${TOOL_OUTPUT}"

# Only process if we have a valid file path
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Detect file type and apply appropriate formatter
case "$FILE_PATH" in
  *.py)
    # Python: Try ruff first (faster), fall back to black
    if command -v ruff &> /dev/null; then
      ruff format "$FILE_PATH" 2>/dev/null || true
    elif command -v black &> /dev/null; then
      black "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.rs)
    # Rust: rustfmt
    if command -v rustfmt &> /dev/null; then
      rustfmt "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.ts|*.tsx|*.js|*.jsx)
    # TypeScript/JavaScript: prettier
    if command -v prettier &> /dev/null; then
      prettier --write "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.md|*.yaml|*.yml|*.json)
    # Markdown/YAML/JSON: prettier
    if command -v prettier &> /dev/null; then
      prettier --write "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

exit 0
