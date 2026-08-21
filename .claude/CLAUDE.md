# CLAUDE.md — ~/.claude repo

direct-commits-allowed: true

Project-local context that loads only when cwd is `~/.claude`.

## Development Commands

Run `make help` for the target list. CI mirrors `make validate` on push/PR to
master. Use `monitoring-ci` skill after pushing.

## Repository Architecture

This repo is the user's Claude Code configuration -- skills, hooks, rules, and dotfiles.

- **`teej-skills/`** -- Local plugin, disabled by default. See `teej-skills/CLAUDE.md` for its linking behavior.
- **`teams/`** -- Agent team configurations. Gitignored and machine-local; per-session dirs accumulate here and are safe to prune

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
