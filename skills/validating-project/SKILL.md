---
name: validating-project
description: Auto-detect and run formatters, linters, type checkers, and tests for the current project. Use when validating a project, running all checks, checking code quality before committing, or verifying the build passes.
when_to_use: "Typed as 'run the checks', 'lint it', 'does this build', 'make sure it is clean', or before opening a PR."
context: fork
model: sonnet
effort: low
disallowed-tools: AskUserQuestion
---

# Validating Project

## Process

1. A Makefile gate wins (`make validate`, else `make format && make lint && make typecheck && make test`); otherwise detect from the manifest.
2. Run **Format -> Lint -> Type Check -> Test**; stop on the first failure.

| project | format | lint | type check | test |
| --- | --- | --- | --- | --- |
| Python (`pyproject.toml`) | `uv run ruff format .` | `uv run ruff check .` | `uv run ty check` (or mypy, pyright) | `uv run pytest` |
| Node / TS (`package.json`; `bun`, else `pnpm`, then `yarn`) | `bun run format` | `bun run lint` | `bun run typecheck` | `bun test` |

Go: also run `staticcheck ./...` or `golangci-lint` when present.

## Reporting Format

Read `~/.claude/references/status-marks.md` and follow its conventions. Report one line per check, then a single plain-text summary line.

The summary line carries no marks. Keep the per-item list; it is the report.
