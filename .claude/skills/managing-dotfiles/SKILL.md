---
name: managing-dotfiles
description: Manage dotfiles tracked in ~/.claude/dotfiles/ using GNU Stow. Use when adding config files to dotfiles, stowing/unstowing packages, or troubleshooting symlink conflicts.
when_to_use: "Typed as 'add this to dotfiles', 'stow this', 'track my <tool> config', or on any symlink conflict from stow."
---

# Dotfiles Management with GNU Stow

## Adding a New Package

The package name (e.g. `tmux`, `git`) is just an organizational label. The internal directory structure determines where symlinks land.

```bash
# 1. Create the package directory mirroring $HOME structure
mkdir -p ~/.claude/dotfiles/<pkg>/<path-relative-to-home>

# 2. Move the existing config into the package
mv ~/<path-to-config> ~/.claude/dotfiles/<pkg>/<path-relative-to-home>/

# 3. Stow to create the symlink
stow -d ~/.claude/dotfiles -t ~ <pkg>
```

## Common Commands

```bash
# Unstow a package (remove symlinks)
stow -d ~/.claude/dotfiles -t ~ -D <pkg>

# Re-stow (unstow + stow, useful after restructuring)
stow -d ~/.claude/dotfiles -t ~ -R <pkg>

# Dry run (see what would happen without doing it)
stow -d ~/.claude/dotfiles -t ~ -n -v <pkg>

# Stow all packages at once
make dotfiles
```

## Troubleshooting

### Conflict: existing target is not a symlink

Stow won't overwrite real files. Use `--adopt` to pull the existing file into the package, then stow:

```bash
stow -d ~/.claude/dotfiles -t ~ --adopt <pkg>
```

**Warning**: `--adopt` replaces the package file with the existing target file; run `git diff` after adopting to see what changed.

### Stow created a directory symlink instead of file symlinks

Stow uses "tree folding" — if a package is the only owner of a directory, it symlinks the directory itself rather than individual files. This is usually fine. If you need file-level symlinks (e.g., because the directory has other non-stowed files), use `--no-folding`:

```bash
stow -d ~/.claude/dotfiles -t ~ --no-folding <pkg>
```
