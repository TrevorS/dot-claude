# CLAUDE.md — ~/.claude repo

direct-commits-allowed: true

This repo is the user's Claude Code configuration: skills, hooks, rules, and dotfiles. The marker above is read by `hooks/branch_protection.sh` and `committing-changes`; it is the documented exception to "branch first on the default branch".

## Development Commands

Run `make help` for the target list. CI mirrors `make validate` on push/PR to master.

## Repository Architecture

- **`teej-skills/`** -- Local plugin, disabled by default. See `teej-skills/CLAUDE.md` for its linking behavior.
- **`teams/`** -- Agent team configurations. Gitignored and machine-local; per-session dirs accumulate here and are safe to prune.
- `dotfiles/<pkg>/<path-relative-to-home>` gets symlinked into `~` by stow.
- Machine-local overrides are untracked files reached through each tool's include mechanism:
  - **git**: `[include] path = ~/.config/git/local`
  - **ghostty**: `config-file = ~/local/ghostty-overrides`
  - **zsh**: `~/.local.zsh` (machine paths/tools), `~/.secrets.zsh` (API keys/tokens)

## Quick References

- Use gifsicle for GIF optimization; run `gifsicle -I` first.
- `glhf` searches past Claude Code sessions.
