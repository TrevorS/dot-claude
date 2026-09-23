```text
 ▄████▄   ██▓    ▄▄▄       █    ██ ▓█████▄ ▓█████
▒██▀ ▀█  ▓██▒   ▒████▄     ██  ▓██▒▒██▀ ██▌▓█   ▀
▒▓█    ▄ ▒██░   ▒██  ▀█▄  ▓██  ▒██░░██   █▌▒███
▒▓▓▄ ▄██▒▒██░   ░██▄▄▄▄██ ▓▓█  ░██░░▓█▄   ▌▒▓█  ▄
▒ ▓███▀ ░░██████▒▓█   ▓██▒▒▒█████▓ ░▒████▓ ░▒████▒
░ ░▒ ▒  ░░ ▒░▓  ░▒▒   ▓▒█░░▒▓▒ ▒ ▒  ▒▒▓  ▒ ░░ ▒░ ░
  ░  ▒   ░ ░ ▒  ░ ▒   ▒▒ ░░░▒░ ░ ░  ░ ▒  ▒  ░ ░  ░
░          ░ ░    ░   ▒    ░░░ ░ ░  ░ ░  ░    ░
░ ░          ░  ░     ░  ░   ░        ░       ░  ░
```

Personal Claude Code configuration: skills, hooks, behavioral rules, and dotfiles,
all managed from one repo and symlinked into `$HOME` with GNU Stow.

## Setup

```bash
make install      # make deps, uv sync, stow dotfiles, install TPM
make deps         # system packages from packages/*.txt
make validate     # pre-commit hooks (lint + format checks), ty, hook tests
```

`make help` lists every target. CI runs `make validate` on push and PR to `master`, except that luacheck and stylua run as separate jobs over the two tracked Lua files and elisp-check skips (no Emacs on the runner).

## Layout

| Path            | What lives there                                                       |
| --------------- | ---------------------------------------------------------------------- |
| `rules/`        | Always-loaded behavioral rules; language rules are `paths:`-scoped     |
| `skills/`       | User-scope skills, auto-loaded by description match in every session   |
| `.claude/`      | Project-scope skills + CLAUDE.md, loaded only when cwd is this repo    |
| `teej-skills/`  | Local plugin of domain-specific skills, disabled by default            |
| `hooks/`        | Shell scripts wired to Claude Code events via `settings.json`          |
| `scripts/`      | Repo tooling: dep installer, skill lint, trigger eval, plugin updaters |
| `dotfiles/`     | Stow packages mirroring `$HOME` (nvim, tmux, zsh, ghostty, scripts, …) |
| `packages/`     | Dependency lists for brew, apt, cargo, luarocks, and uv tools          |
| `references/`   | On-demand reference docs, not auto-loaded                              |
| `themes/`       | Custom Claude Code themes, picked by `theme` in `settings.json`        |
| `evals/`        | Skill-trigger, context-injection, and behavioral eval harnesses        |
| `CLAUDE.md`     | User-scope instructions, loaded in every session                       |
| `settings.json` | Permissions, env vars, hook wiring, enabled plugins, statusline        |

Machine-local overrides stay untracked via each tool's own include mechanism:
`~/.config/git/local`, `~/.local/ghostty-overrides`, `~/.local.zsh`, `~/.secrets.zsh`.

`.claude/CLAUDE.md` holds the notes Claude loads when working in this repo.
