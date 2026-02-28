---
name: tmux-config
description: >
  Build, review, and troubleshoot tmux configurations with modern best practices.
  Use when creating tmux.conf from scratch, adding plugins, configuring themes,
  integrating with Neovim, setting up session management, or debugging tmux issues.
triggers:
  - "tmux config"
  - "tmux configuration"
  - "tmux.conf"
  - "tmux setup"
  - "tmux plugins"
  - "tmux theme"
  - "tmux keybindings"
  - "configure tmux"
---

# tmux Configuration Skill

Help users build, review, and maintain modern tmux configurations. Always check
for an existing config before proposing changes. Prefer the XDG config path.

## Before Making Changes

1. Check tmux version: `tmux -V`
2. Check existing config: `~/.config/tmux/tmux.conf` then `~/.tmux.conf`
3. Check if TPM is installed: `ls ~/.tmux/plugins/tpm`
4. Read the current config before editing

## Config File Location

Prefer the XDG-compliant path (supported since tmux 3.1):

```text
~/.config/tmux/tmux.conf      # modern (preferred)
~/.tmux.conf                   # legacy (still works)
```

If migrating, move the file and remove the old one.

## Essential Baseline Config

These are near-universal best practices. Start here:

```bash
# -- Prefix --
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# -- General --
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g history-limit 50000
set -g display-time 4000
set -g status-interval 5
set -g focus-events on
set -sg escape-time 0

# -- Terminal & Colors --
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"

# -- Copy Mode (vi) --
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-pipe-and-cancel

# -- Easy reload --
bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

# -- Pane splitting (intuitive keys) --
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# -- New windows keep current path --
bind c new-window -c "#{pane_current_path}"
```

## Plugin Manager (TPM)

TPM is the standard. Install:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

In tmux.conf (must be at the BOTTOM):

```bash
# -- Plugins --
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'

# Initialize TPM (keep this line at the very bottom)
run '~/.tmux/plugins/tpm/tpm'
```

After adding plugins: `prefix + I` to install, `prefix + U` to update.

## Plugin Tiers

### Tier 1: Essential (install these first)

| Plugin                        | Purpose                               |
| ----------------------------- | ------------------------------------- |
| `tmux-plugins/tmux-sensible`  | Sane defaults everyone agrees on      |
| `tmux-plugins/tmux-resurrect` | Save/restore sessions across restarts |
| `tmux-plugins/tmux-continuum` | Auto-save sessions every 15 min       |
| `tmux-plugins/tmux-yank`      | System clipboard integration          |

### Tier 2: Power User

| Plugin                           | Purpose                              |
| -------------------------------- | ------------------------------------ |
| `laktak/extrakto`                | Fuzzy-select text from pane with fzf |
| `fcsonline/tmux-thumbs`          | Vimium-like hint copy (Rust)         |
| `sainnhe/tmux-fzf`               | Fuzzy find sessions/windows/panes    |
| `tmux-plugins/tmux-pain-control` | Standard pane navigation bindings    |

### Tier 3: Nice to Have

| Plugin                           | Purpose                              |
| -------------------------------- | ------------------------------------ |
| `tmux-plugins/tmux-open`         | Open highlighted file/URL            |
| `27medkamal/tmux-session-wizard` | Session management with fzf + zoxide |
| `tmux-plugins/tmux-fzf-url`      | Open URLs from pane                  |

## Neovim Integration

For seamless pane/split navigation between tmux and Neovim:

**Option A: All-in-one** — `aserowy/tmux.nvim` (nav + clipboard + resize)
**Option B: Navigation only** — `alexghergh/nvim-tmux-navigation` (Lua)
**Option C: Classic** — `christoomey/vim-tmux-navigator`

The tmux side needs matching keybindings. See [REFERENCE.md](REFERENCE.md) for setup.

## Themes

**catppuccin/tmux** — Modular status line with widgets, most popular modern theme:

```bash
set -g @plugin 'catppuccin/tmux'
set -g @catppuccin_flavor 'mocha'  # latte, frappe, macchiato, mocha
```

**dracula/tmux** — Feature-rich status bar with system info widgets.
**tokyo-night** — Matching theme if you use tokyo-night in your editor.

## tmux 3.6 Features Worth Using

- **Scrollbars**: `set -g pane-scrollbars on`
- **Popup windows**: `display-popup` for floating terminals/menus
- **Mode 2031**: Auto dark/light theme detection
- **Performance**: Better handling of slow terminals and fast output

## Troubleshooting Checklist

1. **Colors wrong?** Check `echo $TERM` inside tmux — should be `tmux-256color`
2. **Slow escape?** Set `escape-time 0` (tmux-sensible does this)
3. **Clipboard not working?** On macOS, tmux-yank should work out of the box.
   On Linux, install `xclip` or `xsel`. Over SSH, use OSC-52.
4. **Plugins not loading?** TPM `run` line must be the LAST line in config.
   Run `prefix + I` after adding new plugins.
5. **After upgrade issues?** Kill all tmux servers: `tmux kill-server`

See [REFERENCE.md](REFERENCE.md) for detailed plugin configs and advanced patterns.
