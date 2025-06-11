# Validate Project

Auto-detect and run formatter, linter, type checker, and tests for the current project.

## Task

I'll systematically detect the project type and available tooling, then execute validation steps in the proper order.

I will:

1. **Check local CLAUDE.md first** for existing tool configuration information to avoid redundant detection

2. **Auto-detect project characteristics** (if not in CLAUDE.md) by checking for:
   - `package.json` → Node.js/TypeScript project
   - `pyproject.toml` → Python project  
   - `Cargo.toml` → Rust project
   - `Makefile` → Make-based project
   - `.pre-commit-config.yaml` → Pre-commit enabled

3. **Identify available tooling** by examining:
   - Package.json scripts section
   - Makefile targets
   - Pre-commit hook configurations
   - Tool-specific config files

4. **Execute validation steps in order**:
   - **Format**: Run formatters (prettier, black, rustfmt, etc.)
   - **Lint**: Run linters (eslint, ruff, clippy, markdownlint, etc.)
   - **Type Check**: Run type checkers if applicable (tsc, mypy)
   - **Test**: Run test suites (jest, pytest, cargo test, etc.)

5. **Update local CLAUDE.md** with discovered tool information for future runs

## Tool Preferences

- **Make**: Prefer Makefile targets when available (format, lint, test)
- **Python**: Use `uv run` for all Python commands
- **Node.js/TypeScript**: Auto-detect package manager (check for `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`) and use appropriate manager
- **Rust**: Use `cargo` for all Rust commands
- **Pre-commit**: Use `uv run pre-commit run --all-files` when .pre-commit-config.yaml exists

## CLAUDE.md Integration

### Check Local CLAUDE.md First

Before auto-detection, check if `./CLAUDE.md` exists and contains a "Project Validation Tools" section with:
- Project type (Python/Node.js/Rust/etc.)
- Preferred commands for format/lint/typecheck/test
- Package manager (pnpm/npm/yarn/uv)
- Any project-specific tool configurations

If found, use these commands directly and skip auto-detection.

### Update Local CLAUDE.md

After successful validation run, update/create `./CLAUDE.md` with a "Project Validation Tools" section containing:

```markdown
# Project Validation Tools

## Project Type
[Python|Node.js/TypeScript|Rust|Other]

## Package Manager
[uv|pnpm|npm|yarn|cargo]

## Validation Commands
- **Format**: [command]
- **Lint**: [command] 
- **Type Check**: [command]
- **Test**: [command]

## Last Updated
[current date]
```

This ensures future runs are faster and more consistent.

## Execution Strategy

1. **Check local CLAUDE.md first** - if validation tools are documented, use them

2. **Check for Makefile** - if targets exist, use them:
   - `make format` → `make lint` → `make test`

3. **Fall back to tool-specific commands** based on project type:

   **Python projects** (pyproject.toml exists):
   ```bash
   uv run ruff format .          # Format
   uv run ruff check .           # Lint  
   uv run mypy .                 # Type check (if mypy configured)
   uv run pytest                 # Test
   ```

   **Node.js/TypeScript projects** (package.json exists):
   ```bash
   # Auto-detect package manager:
   # - pnpm-lock.yaml exists → use pnpm
   # - yarn.lock exists → use yarn  
   # - package-lock.json exists → use npm
   # - packageManager field in package.json → use specified manager
   
   <pkg-manager> prettier --write .      # Format
   <pkg-manager> eslint .                # Lint (if configured)
   <pkg-manager> tsc --noEmit            # Type check (if TypeScript)
   <pkg-manager> test                    # Test
   ```

   **Rust projects** (Cargo.toml exists):
   ```bash
   cargo fmt                    # Format
   cargo clippy                 # Lint
   cargo check                  # Type check
   cargo test                   # Test
   ```

4. **Use pre-commit when available**:
   ```bash
   uv run pre-commit run --all-files
   ```

## Output Requirements

For each step, I will:
- Clearly indicate what tool is being run and why
- Show the command being executed
- Report success/failure status
- Display any errors or warnings that need attention
- Provide a summary of all validation results

**CRITICAL**: If any step fails, I will stop and report the failure details before proceeding to subsequent steps.
