# CLAUDE.md — ~/.claude repo

direct-commits-allowed: true

Project-local context that loads only when cwd is `~/.claude`.

## Development Commands

```bash
make install              # Install deps (uv sync), stow dotfiles, install TPM
make deps                 # Install system packages from packages/*.txt
make upgrade              # Bump managed brew/cargo/luarocks packages + Emacs plugins to latest
make emacs-plugins        # Update Emacs packages (elpaca) headlessly
make validate             # All checks: formatting, linting (ruff), type checking, stylua, luacheck, hook tests
make pre-commit           # Run pre-commit on all files (same as the git pre-commit hook)
make typecheck            # Type check Python scripts (ty)
make hook-tests           # Run hooks/*.test.sh regression suites
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
- **`skills/`** -- User-scope, always-on skills loaded in every session via description matching. Each has a `SKILL.md`.
- **`.claude/skills/`** -- Project-scope skills that load only when cwd is `~/.claude` (i.e., when working on this repo itself: `maintaining-claude-code`, `managing-dotfiles`).
- **`teej-skills/`** -- Local plugin (registered as a `directory` marketplace) bundling domain-specific skills (TTS/ML, frontend, niche tooling, situational personal tools). **Disabled by default** -- enable with `claude plugin enable teej-skills@teej-skills` when needed. The plugin entry uses a `command` source with `mode: "link"` (Claude Code 2.1.229), so the plugin cache links to this directory instead of copying it: **edit a skill here and it applies next session -- no version bump, no `plugin update`, no restart.** Still bump `version` in `teej-skills/.claude-plugin/plugin.json` for real releases. If you change the `command` string itself, that one change does need an explicit `claude plugin update teej-skills@teej-skills`.
- **`hooks/`** -- Shell scripts triggered by Claude Code events, wired in `settings.json`
- **`dotfiles/`** -- GNU Stow packages mirroring `$HOME` structure, managed via `make dotfiles`. Includes a `scripts` package for standalone shell scripts (`~/.local/bin`).
- **`packages/`** -- System dependency lists (`brew.txt`, `apt.txt`, `cargo.txt`, `luarocks.txt`) installed via `make deps`
- **`evals/`** -- Skill trigger and context-injection evaluation scripts
- **`scripts/`** -- Tooling scripts (eval runners, description improvers)
- **`teams/`** -- Agent team configurations. Gitignored and machine-local; per-session dirs accumulate here and are safe to prune
- **`settings.json`** -- Permissions, hooks config, enabled plugins, environment variables
- **Python scripts** -- Some skills include Python (`skills/monitoring-ci/ci-monitor.py`, `teej-skills/skills/reading-books/book.py`, `teej-skills/skills/testing-whisper/transcribe.py`); deps managed via `uv` (`pyproject.toml`)

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
