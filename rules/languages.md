# Languages & Code Standards

## General

- Always examine project structure before making changes
- Check package.json, cargo.toml, pyproject.toml for available dependencies
- When creating complex modules, document them at the top
- Check for Makefile, npm scripts, or project docs for validation commands

## Python

- Use `uv` for everything (`uv add`, `uv remove`, `uv run`, `uv sync`)
- Type annotations required for all function params and returns
- Testing: `pytest` + `pytest-mock`, run with `uv run pytest`
- Prefer `pathlib.Path` over string paths

## TypeScript/JavaScript

- Node version: `fnm` (check `.node-version` or `.nvmrc`)
- Package manager: prefer `pnpm`, fallback to `yarn`
- Strict TypeScript: no `any`, enable all strict options

## Rust

- Use `cargo` for everything (`cargo add`, `cargo run`, `cargo clippy`, `cargo fmt`)
- Run `cargo clippy` before committing
