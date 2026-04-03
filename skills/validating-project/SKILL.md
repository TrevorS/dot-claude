---
name: validating-project
description: Auto-detect and run formatters, linters, type checkers, and tests for the current project. Use when validating a project, running all checks, checking code quality before committing, or verifying the build passes.
context: fork
---

# Validating Project

Auto-detect project tooling and run validation steps in the correct order.

## Process

1. Check `./CLAUDE.md` for validation tools and project permissions
2. Auto-detect project type if needed (package.json, pyproject.toml, Cargo.toml, Makefile, go.mod)
3. Run validation pipeline: **Format -> Lint -> Type Check -> Test**
4. Stop immediately on failures
5. Report results

## Tool Commands by Project Type

### Make-based (check first -- overrides everything)

```bash
make format && make lint && make typecheck && make test
```

Or `make validate` if available.

### Python

```bash
uv run ruff format .
uv run ruff check .
uv run ty check        # or uv run mypy, uv run pyright
uv run pytest
```

### Node.js / TypeScript

```bash
pnpm run format        # or npx prettier --write .
pnpm run lint          # or npx eslint .
pnpm run typecheck     # or npx tsc --noEmit
pnpm test
```

### Rust

```bash
cargo fmt
cargo clippy
cargo test
```

### Go

```bash
gofmt -w .
go vet ./...
go test ./...
```

## Auto-Discovery Priority

Detect project type by checking for config files in this order: `Makefile` → `pyproject.toml` → `package.json` → `Cargo.toml` → `go.mod`. Use the first match to select the tool commands above.

## Failure Recovery

When a validation step fails:

1. Show the specific error output
2. Fix the reported issue (auto-fix if formatter, manual if lint/type error)
3. Re-run **from the failed step** — not the entire pipeline
4. If a tool is missing, install it first:
   ```bash
   # Python example
   uv pip install ruff ty
   # Node.js example
   pnpm add -D prettier eslint typescript
   ```
