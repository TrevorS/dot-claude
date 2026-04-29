# CLAUDE.md — ~/.claude repo

direct-commits-allowed: true

Project-local context that loads only when cwd is `~/.claude`.

## Development Commands

```bash
make install              # Install deps (uv sync), stow dotfiles, install TPM
make deps                 # Install system packages from packages/*.txt
make validate             # All checks: formatting, linting, type checking, stylua, luacheck
make pre-commit           # Run pre-commit on all files (same as the git pre-commit hook)
make typecheck            # Type check Python scripts (ty)
make dotfiles             # Stow all dotfile packages into ~
make tpm                  # Install tmux plugin manager + plugins
make pre-commit-install   # Install pre-commit hooks (one-time)
make pre-commit-update    # Update pre-commit hooks to latest versions
make clean                # Remove .venv
```

CI mirrors `make validate` on push/PR to master. Use `monitoring-ci` skill after pushing.

## Repository Architecture

This repo is the user's Claude Code configuration -- skills, hooks, rules, and dotfiles.

- **`rules/`** -- Always-loaded behavioral rules (version-control, language-specific)
- **`skills/`** -- On-demand capabilities loaded via description matching. Each has a `SKILL.md`.
- **`hooks/`** -- Shell scripts triggered by Claude Code events, wired in `settings.json`
- **`dotfiles/`** -- GNU Stow packages mirroring `$HOME` structure, managed via `make dotfiles`. Includes a `scripts` package for standalone shell scripts (`~/.local/bin`).
- **`packages/`** -- System dependency lists (`brew.txt`, `apt.txt`, `cargo.txt`, `luarocks.txt`) installed via `make deps`
- **`evals/`** -- Skill trigger and context-injection evaluation scripts
- **`scripts/`** -- Tooling scripts (eval runners, description improvers)
- **`teams/`** -- Agent team configurations
- **`settings.json`** -- Permissions, hooks config, enabled plugins, environment variables
- **Python scripts** -- Some skills include Python (`skills/reading-books/book.py`, `skills/monitoring-ci/ci-monitor.py`); deps managed via `uv` (`pyproject.toml`)

Key patterns:

- Skills use `SKILL.md` for discovery; reference docs go in `REFERENCE.md`
- `dotfiles/<pkg>/<path-relative-to-home>` gets symlinked into `~` by stow
- Machine-local overrides use each tool's native include mechanism (not tracked):
  - **git**: `[include] path = ~/.config/git/local`
  - **ghostty**: `config-file = ~/local/ghostty-overrides`
  - **zsh**: `~/.local.zsh` (machine paths/tools), `~/.secrets.zsh` (API keys/tokens)

## Quick References

- Use gifsicle for GIF optimization, always run `gifsicle -I` first
- Use `glhf` CLI binary to search past Claude Code sessions
