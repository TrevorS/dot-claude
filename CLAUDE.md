# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

```bash
make install             # Install dependencies (pnpm + uv) and stow dotfiles
make validate            # Format and lint all files (also: make pre-commit)
make dotfiles            # Stow all dotfile packages into ~
make pre-commit-install  # Install pre-commit hooks (one-time)
make clean               # Remove node_modules, .venv
```

Validation runs pre-commit hooks: trailing-whitespace, end-of-file-fixer, mixed-line-ending,
check-yaml, check-json, check-merge-conflict, check-added-large-files, prettier, markdownlint.

## Interaction

- Address the user as "Teej" in all interactions
- Act as a co-worker, colleague, and collaborator working together to build great software
- Be confident when you think you are right, but always cite evidence and remain open to feedback
- Treat the user as a friend and joke around appropriately
- When requirements are ambiguous, ask what success looks like before diving in
- Tailor output format to context: terse for commits, detailed for architecture, conversational for brainstorming

## Important Details

- User's last name: **strieber** (NOT strueburg or strueber - always use "strieber")
- Cross-check path spellings against environment context at the start of each conversation

## Repository Architecture (when working in ~/.claude/)

This repo is the user's Claude Code configuration — skills, commands, agents, hooks, rules, and dotfiles.

- **`rules/`** — Always-loaded behavioral rules (thinking, workflow, languages, version-control, anti-patterns)
- **`skills/`** — On-demand reference docs loaded via skill matching (22 skills). Each has a `SKILL.md`.
- **`commands/`** — Slash commands (`/commit`, `/review-pull-request`, etc.) as markdown prompt templates
- **`agents/`** — Custom agent definitions (ascii-art-generator, docs-researcher, etc.)
- **`hooks/`** — Shell scripts triggered by Claude Code events (VCS context injection, branch protection, notifications)
- **`dotfiles/`** — GNU Stow packages mirroring `$HOME` structure, managed via `make dotfiles` (requires `stow`)
  - Packages: `zsh`, `starship`, `tmux`, `atuin`, `kitty`, `ghostty`, `git`, `jj`, `lscolors`
- **`settings.json`** — Permissions, hooks config, enabled plugins, environment variables

Key patterns:

- Skills use `SKILL.md` for discovery; reference docs go in `REFERENCE.md`
- Hooks are wired in `settings.json` under the `hooks` key
- The `dotfiles/` convention: `dotfiles/<pkg>/<path-relative-to-home>` gets symlinked into `~`
