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
make install      # uv sync, stow dotfiles, install TPM
make deps         # system packages from packages/*.txt
make validate     # formatting, linting, type checking, stylua, luacheck
```

`make help` lists every target. CI mirrors `make validate` on push and PR to `master`.

## Layout

| Path            | What lives there                                                       |
| --------------- | ---------------------------------------------------------------------- |
| `rules/`        | Always-loaded behavioral rules; language rules are `paths:`-scoped     |
| `skills/`       | User-scope skills, auto-loaded by description match in every session   |
| `.claude/`      | Project-scope skills + CLAUDE.md, loaded only when cwd is this repo    |
| `teej-skills/`  | Local plugin of domain-specific skills, disabled by default            |
| `hooks/`        | Shell scripts wired to Claude Code events via `settings.json`          |
| `dotfiles/`     | Stow packages mirroring `$HOME` (nvim, tmux, zsh, ghostty, scripts, …) |
| `packages/`     | System dependency lists for brew, apt, cargo, luarocks                 |
| `references/`   | On-demand reference docs, not auto-loaded                              |
| `evals/`        | Skill-trigger, context-injection, and behavioral eval harnesses        |
| `settings.json` | Permissions, env vars, hook wiring, enabled plugins, statusline        |

Machine-local overrides stay untracked via each tool's own include mechanism —
`~/.config/git/local`, `~/local/ghostty-overrides`, `~/.local.zsh`, `~/.secrets.zsh`.

See `.claude/CLAUDE.md` for the full architecture notes and per-directory conventions.
