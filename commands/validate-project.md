# Validate Project

<!-- ABOUTME: Auto-detects and runs formatter, linter, type checker, and tests -->

<!-- ABOUTME: Validates project using detected tools and provides complete feedback -->

Auto-detect and run formatter, linter, type checker, and tests for the current project.

## Task

I'll figure out the best validation approach and systematically validate this project.

I will:

1. **Auto-detect project type** - Scan for `pyproject.toml`, `package.json`, `Cargo.toml`, `Makefile`
2. **Discover available tooling** - Check which formatters, linters, type checkers are configured
3. **Execute validation pipeline** - Run steps in proper order (format → lint → typecheck → test)
4. **Handle validation failures** - Provide clear guidance for fixing issues
5. **Update project metadata** - Cache discovered tool information in local CLAUDE.md
6. **Report complete results** - Show what passed/failed and next steps

## Validation Pipeline

The validation follows this order to maximize success:

### 1. **Format Code**

- **Python**: `uv run ruff format` or `uv run black`
- **TypeScript/JavaScript**: `pnpm run format` or `npx prettier`
- **Rust**: `cargo fmt`
- **Mixed projects**: Run all detected formatters

### 2. **Lint Code**

- **Python**: `uv run ruff check` or `uv run flake8`
- **TypeScript/JavaScript**: `pnpm run lint` or `npx eslint`
- **Rust**: `cargo clippy`
- **Markdown**: `pnpm run lint:md` if available

### 3. **Type Check**

- **Python**: `uv run mypy` or `uv run pyright`
- **TypeScript**: `pnpm run typecheck` or `npx tsc --noEmit`
- **Rust**: Built into `cargo check`

### 4. **Run Tests**

- **Python**: `uv run pytest` or `uv run python -m pytest`
- **TypeScript/JavaScript**: `pnpm test` or `npm test`
- **Rust**: `cargo test`

## Auto-Discovery Logic

The command intelligently detects project configuration:

````bash
# Project type detection (priority order)
if [ -f "pyproject.toml" ]; then
  # Python project - check for uv, poetry, pip-tools
elif [ -f "package.json" ]; then
  # Node.js project - check for pnpm, npm, yarn
elif [ -f "Cargo.toml" ]; then
  # Rust project - use cargo commands
elif [ -f "Makefile" ]; then
  # Make-based project - check for make validate/test targets
fi

# Tool availability detection
# Check package.json scripts, pyproject.toml tools, Makefile targets
# Verify CLI tools are actually installed before attempting to run
```text

## CLAUDE.md Integration

Updates project metadata for future reference:

```markdown
## Project Validation Tools

### Project Type

Mixed Python/Node.js project with markdown documentation

### Package Managers

- **Python**: `uv`
- **Node.js**: `pnpm`

### Validation Commands

- **Format**: `make format`
- **Lint**: `make lint`
- **Type Check**: Not configured
- **Test**: `make test` (no tests configured yet)

### Last Updated

2025-08-13
```text

## Error Handling

- **Tool not found**: Clear installation instructions
- **Configuration missing**: Suggest minimal setup
- **Validation failures**: Specific fix recommendations
- **Permission issues**: Guidance for access problems
- **Dependency conflicts**: Resolution strategies
````
