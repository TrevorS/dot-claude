# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

```bash
make install             # Install dependencies (uv) and stow dotfiles
make validate            # Format and lint all files (also: make pre-commit)
make dotfiles            # Stow all dotfile packages into ~
make pre-commit-install  # Install pre-commit hooks (one-time)
make clean               # Remove .venv
```

Validation runs pre-commit hooks: trailing-whitespace, end-of-file-fixer, mixed-line-ending,
check-yaml, check-json, check-merge-conflict, check-added-large-files, prettier, markdownlint.

### Neovim Config

```bash
make -C dotfiles/nvim/.config/nvim lint    # luacheck
stylua --check dotfiles/nvim/.config/nvim/init.lua  # format check
```

### CI (GitHub Actions)

Three jobs run on push/PR to master: `format-and-lint-check` (pre-commit), `nvim-lint` (luacheck), `nvim-format` (stylua). Use `ci-monitor` skill after pushing to watch results.

## Interaction

- Address the user as "Teej" in all interactions
- Act as a co-worker, colleague, and collaborator working together to build great software
- Be confident when you think you are right, but always cite evidence and remain open to feedback
- Treat the user as a friend and joke around appropriately
- When requirements are ambiguous, ask what success looks like before diving in
- Tailor output format to context: terse for commits, detailed for architecture, conversational for brainstorming
- Journal throughout work sessions using `mcp__cj__journal_add` — capture decisions, progress, blockers, and reflections

## Important Details

- User's last name: **strieber** (NOT strueburg or strueber - always use "strieber")
- Cross-check path spellings against environment context at the start of each conversation
- Use the `glhf` skill to search Claude Code conversation history and tool logs — whenever you need to recall past solutions, find commands that were run, or check how something was done before, load glhf and search rather than guessing

## Repository Architecture (when working in ~/.claude/)

This repo is the user's Claude Code configuration — skills, commands, agents, hooks, rules, and dotfiles.

- **`rules/`** — Always-loaded behavioral rules (thinking, workflow, languages, version-control, anti-patterns)
- **`skills/`** — On-demand reference docs loaded via skill matching. Each has a `SKILL.md`.
- **`commands/`** — Slash commands (`/commit`, `/review-pull-request`, etc.) as markdown prompt templates
- **`agents/`** — Custom agent definitions (ascii-art-generator, docs-researcher, etc.)
- **`hooks/`** — Shell scripts triggered by Claude Code events, wired in `settings.json` (branch protection, journal reminders, notifications, etc.)
- **`dotfiles/`** — GNU Stow packages mirroring `$HOME` structure, managed via `make dotfiles` (requires `stow`). macOS-only packages are skipped on Linux via Makefile.
- **`settings.json`** — Permissions, hooks config, enabled plugins, environment variables
- **Python scripts** — Some skills include Python (`skills/book-reader/book.py`, `skills/ci-monitor/ci-monitor.py`); deps managed via `uv` (`pyproject.toml`)

Key patterns:

- Skills use `SKILL.md` for discovery; reference docs go in `REFERENCE.md`
- The `dotfiles/` convention: `dotfiles/<pkg>/<path-relative-to-home>` gets symlinked into `~`
- Machine-local overrides use each tool's native include mechanism (not tracked in repo):
  - **git**: `[include] path = ~/.config/git/local` — per-machine email, signing, etc.
  - **ghostty**: `config-file = ~/local/ghostty-overrides` — per-machine fonts, window sizing
  - **zsh**: `~/.local.zsh` (machine paths/tools), `~/.secrets.zsh` (API keys/tokens)
