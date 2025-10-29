# Language-Specific Tooling & Guidelines

This skill provides language-specific development guidelines and best practices for Python, TypeScript/JavaScript, and Rust projects.

## Python Projects

When working with Python (detected via `pyproject.toml`):

### Package Management & Execution

- Use `uv` for everything (`uv add`, `uv remove`, `uv run`)
- Never use `pip` or `python` directly; always use `uv run`
- The command_blocker hook enforces this pattern

### Code Quality

- Use type annotations for all function parameters and return values
- Use `pytest` + `pytest-mock` for testing
- Use specific exception types for error handling
- Follow PEP 8 style guidelines

### Validation Commands

- `uv run pytest` - Run tests
- `uv run ruff format` - Format code
- `uv run ruff check` - Lint code
- `make test`, `make lint`, `make format` - Project-level validation

## TypeScript/JavaScript Projects

When working with Node.js/TypeScript projects (detected via `package.json`):

### Environment & Package Management

- Use `fnm` for Node.js version management
- Check `.node-version` file for required version
- Prefer `pnpm` first and `yarn` second for package management
- Use the installed package manager version in the lock file

### Code Quality

- Enable strict TypeScript compiler options
- Avoid `any` type; use proper typing instead
- Use `async/await` for asynchronous code
- Use template literals for strings
- Follow ESLint and Prettier rules from project config

### Validation Commands

- `pnpm run lint` or `yarn lint` - Lint code
- `pnpm run format` or `yarn format` - Format code
- `pnpm run type-check` - Run TypeScript compiler
- `pnpm run test` or `yarn test` - Run tests
- `make test`, `make lint`, `make format` - Project-level validation

## Rust Projects

When working with Rust (detected via `Cargo.toml`):

### Build & Package Management

- Use `cargo` for everything (`cargo add`, `cargo remove`, `cargo run`, `cargo build`)
- Never use `rustc` directly unless specifically debugging
- Check `Cargo.lock` for dependency pinning

### Code Quality

- Use `cargo clippy` for linting (includes Clippy recommendations)
- Use `cargo fmt` for formatting (enforces Rust style guide)
- Use `cargo test` for testing
- Follow Rust API guidelines and idioms

### Validation Commands

- `cargo clippy` - Lint code
- `cargo fmt` - Format code
- `cargo test` - Run tests
- `cargo build --release` - Optimize build
- `make lint`, `make format`, `make test` - Project-level validation

## Universal Rules

Across all languages:

- Always examine project structure before making changes
- Check `package.json`, `Cargo.toml`, `pyproject.toml` for available dependencies
- Start code files with "ABOUTME: " comments explaining what the file does
- Look for `Makefile` - use `make` targets when available
- Run validation commands before committing
- Use specific tool patterns, don't mix package managers (one `uv`, one `pnpm`, one `cargo` per project)

## When to Use This Skill

Use this skill when:

- Starting work in a Python, TypeScript, JavaScript, or Rust project
- Configuring build tools or package management
- Selecting testing frameworks or linting tools
- Running validation or formatting commands
- Setting up development environment (Node.js version, Python version)
