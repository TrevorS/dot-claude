# Languages & Code Standards

## General

- Always examine project structure before making changes
- Check package.json, cargo.toml, pyproject.toml for available dependencies
- When creating complex modules, document them at the top
- Check for Makefile, npm scripts, or project docs for validation commands

## Python

- Use `uv` for everything (`uv add`, `uv remove`, `uv run`, `uv sync`)
- NEVER use `pip install` — use `uv add` for project deps, `uv run --with` or `uvx --with` for one-off scripts
- HuggingFace downloads: `uv run --with huggingface_hub hf download <repo> --local-dir <path>`
- One-off scripts with deps: `uvx --with pkg1 --with pkg2 python3 -c "..."`
- PEP 723 inline scripts: use `#!/usr/bin/env -S uv run --script` header with `# /// script` deps block
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
