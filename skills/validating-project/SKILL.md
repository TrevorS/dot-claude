---
name: validating-project
description: Auto-detect and run formatters, linters, type checkers, and tests for the current project. Use when validating a project, running all checks, checking code quality before committing, or verifying the build passes.
when_to_use: "Typed as 'run the checks', 'lint it', 'does this build', 'make sure it is clean', or before opening a PR. Prefer the repo's own gate (make validate) when it has one."
context: fork
model: sonnet
effort: low
disallowed-tools: AskUserQuestion
---

# Validating Project

Auto-detect project tooling and run validation steps in the correct order.

## Process

1. Check `./CLAUDE.md` **and** `./.claude/CLAUDE.md` for validation tools and project permissions — this repo keeps its project instructions in the latter.
2. A Makefile gate wins (`make validate`, else `make format && make lint && make typecheck && make test`); otherwise detect from the manifest.
3. Run **Format -> Lint -> Type Check -> Test**; stop on the first failure.

| project | format | lint | type check | test |
| --- | --- | --- | --- | --- |
| Python (`pyproject.toml`) | `uv run ruff format .` | `uv run ruff check .` | `uv run ty check` (or mypy, pyright) | `uv run pytest` |
| Node / TS (`package.json`) | `bun run format` | `bun run lint` | `bun run typecheck` | `bun test` |
| Rust (`Cargo.toml`) | `cargo fmt` | `cargo clippy` | (clippy) | `cargo test` |
| Go (`go.mod`) | `gofmt -w .` | `go vet ./...`, `staticcheck ./...` (or golangci-lint) | (vet) | `go test ./...` |

Node: prefer `bun`, fall back to `pnpm` then `yarn` (`rules/typescript.md`).

## Reporting Format

Read `~/.claude/references/status-marks.md` and follow its conventions. Report one line per check, then a single plain-text summary line.

Example output:

```
❨`✓`❩ Trim trailing whitespace
❨`✓`❩ Fix end of file markers
❨`~`❩ Mixed line endings (skipped — none found)
❨`✗`❩ Markdownlint (3 errors)
```

After the list, add a plain-text summary with no marks — e.g. "all checks passed" or "1 failure: markdownlint". Skip reasons go in parens on the same line; keep the per-item list, it is the report.
