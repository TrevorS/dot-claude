# tmux Configuration Reference

Detailed plugin configurations, advanced patterns, and session management.

## Table of Contents

- [Plugin Configurations](#plugin-configurations)
- [Neovim Integration Setup](#neovim-integration-setup)
- [Theme Configuration](#theme-configuration)
- [Session Management Tools](#session-management-tools)
- [Advanced Patterns](#advanced-patterns)
- [macOS-Specific Notes](#macos-specific-notes)
- [Complete Example Config](#complete-example-config)

---

## Plugin Configurations

### tmux-resurrect

```bash
set -g @plugin 'tmux-plugins/tmux-resurrect'

# Restore neovim sessions (requires vim-obsession or similar)
set -g @resurrect-strategy-nvim 'session'

# Restore pane contents
set -g @resurrect-capture-pane-contents 'on'

# Custom save/restore dir
# set -g @resurrect-dir '~/.local/share/tmux/resurrect'
```

Keys: `prefix + Ctrl-s` (save), `prefix + Ctrl-r` (restore)

### tmux-continuum

```bash
set -g @plugin 'tmux-plugins/tmux-continuum'

# Auto-restore on tmux start
set -g @continuum-restore 'on'

# Save interval in minutes (default: 15)
set -g @continuum-save-interval '15'

# Auto-start tmux on boot (macOS)
# set -g @continuum-boot 'on'
# set -g @continuum-boot-options 'iterm'
```

### tmux-yank

```bash
set -g @plugin 'tmux-plugins/tmux-yank'

# Stay in copy mode after yanking
set -g @yank_action 'copy-pipe'

# Use system clipboard (default behavior on macOS via pbcopy)
# On Linux, requires xclip or xsel
```

### extrakto

```bash
set -g @plugin 'laktak/extrakto'

# Use popup window (requires tmux >= 3.2)
set -g @extrakto_popup_size '60%'

# Filter order (first is default)
set -g @extrakto_filter_order 'word line path url quote'

# Insert into pane or copy to clipboard
set -g @extrakto_insert_key 'enter'
set -g @extrakto_copy_key 'tab'
```

Key: `prefix + tab` to activate

### tmux-thumbs

**Requires Rust.** After TPM clones it, build: `cd ~/.config/tmux/plugins/tmux-thumbs && cargo build --release`

```bash
set -g @plugin 'fcsonline/tmux-thumbs'

# Customize hint characters
set -g @thumbs-alphabet colemak-homerow
# Options: qwerty, qwerty-homerow, azerty, colemak, colemak-homerow

# Command to run on match
set -g @thumbs-command 'echo -n {} | pbcopy'
set -g @thumbs-upcase-command 'echo -n {} | pbcopy && open {}'
```

Key: `prefix + Space` to activate

### tmux-fzf

```bash
set -g @plugin 'sainnhe/tmux-fzf'

# Use popup (tmux >= 3.2)
TMUX_FZF_LAUNCH_KEY="f"
TMUX_FZF_PREVIEW=1

# Customize available actions
TMUX_FZF_ORDER="session|window|pane|command|keybinding|clipboard|process"
```

Key: `prefix + F` (Shift+F) to activate

---

## Neovim Integration Setup

### Option A: aserowy/tmux.nvim (Recommended)

**tmux side** (`tmux.conf`):

```bash
# Smart pane switching with awareness of Neovim splits
is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?\.?(view|n?vim?x?|fzf)(diff)?$'"

bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'

# Resize with Alt+hjkl
bind-key -n 'M-h' if-shell "$is_vim" 'send-keys M-h' 'resize-pane -L 1'
bind-key -n 'M-j' if-shell "$is_vim" 'send-keys M-j' 'resize-pane -D 1'
bind-key -n 'M-k' if-shell "$is_vim" 'send-keys M-k' 'resize-pane -U 1'
bind-key -n 'M-l' if-shell "$is_vim" 'send-keys M-l' 'resize-pane -R 1'
```

**Neovim side** (lazy.nvim):

```lua
{
  "aserowy/tmux.nvim",
  opts = {
    copy_sync = { enable = true },
    navigation = { enable_default_keybindings = true, cycle_navigation = false },
    resize = { enable_default_keybindings = true },
  },
}
```

### Option B: vim-tmux-navigator (Classic)

**tmux side:**

```bash
set -g @plugin 'christoomey/vim-tmux-navigator'
# That's it — the plugin handles the keybindings
```

**Neovim side** (lazy.nvim):

```lua
{ "christoomey/vim-tmux-navigator" }
```

### Clipboard Over SSH (OSC-52)

For clipboard to work over SSH, use tmux's built-in OSC-52 support:

```bash
# In tmux.conf
set -g set-clipboard on

# In Neovim (init.lua) — uses built-in OSC-52 provider
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}
```

---

## Theme Configuration

### catppuccin/tmux (Recommended)

```bash
set -g @plugin 'catppuccin/tmux'
set -g @catppuccin_flavor 'mocha'  # latte, frappe, macchiato, mocha

# Status bar modules
set -g @catppuccin_window_status_style 'rounded'
set -g @catppuccin_status_modules_right 'session date_time'
set -g @catppuccin_status_modules_left ''

# Window format
set -g @catppuccin_window_default_text '#W'
set -g @catppuccin_window_current_text '#W'
```

### dracula/tmux

```bash
set -g @plugin 'dracula/tmux'
set -g @dracula-show-powerline true
set -g @dracula-plugins "cpu-usage ram-usage"
set -g @dracula-show-left-icon session
```

### Minimal Custom Theme (No Plugin)

```bash
# Status bar
set -g status-position top
set -g status-style 'bg=default,fg=white'
set -g status-left '#[bold]#S #[default]'
set -g status-left-length 20
set -g status-right '%H:%M'

# Window tabs
setw -g window-status-current-style 'bold'
setw -g window-status-current-format ' #I:#W '
setw -g window-status-format ' #I:#W '

# Pane borders
set -g pane-border-style 'fg=brightblack'
set -g pane-active-border-style 'fg=white'
```

---

## Session Management Tools

### smug (Go, zero dependencies — recommended)

Install: `go install github.com/ivaaaan/smug@latest` or `brew install smug`

Config at `~/.config/smug/project.yml`:

```yaml
session: project
root: ~/code/project
windows:
  - name: editor
    commands:
      - nvim
  - name: server
    commands:
      - make dev
  - name: shell
```

Usage: `smug start project`, `smug stop project`

### tmuxp (Python, most features)

Install: `pipx install tmuxp`

Config at `~/.config/tmuxp/project.yaml`:

```yaml
session_name: project
start_directory: ~/code/project
windows:
  - window_name: editor
    panes:
      - shell_command: nvim
  - window_name: server
    panes:
      - shell_command: make dev
  - window_name: shell
    panes:
      - blank
```

Usage: `tmuxp load project`, `tmuxp freeze` (save current session)

---

## Advanced Patterns

### Popup Terminal (tmux 3.2+)

```bash
# Floating terminal with prefix + t
bind t display-popup -E -w 80% -h 80% -d "#{pane_current_path}"

# Floating lazygit
bind g display-popup -E -w 90% -h 90% -d "#{pane_current_path}" "lazygit"

# Floating file picker
bind f display-popup -E -w 60% -h 60% "fzf --preview 'bat --color=always {}'"
```

### Session Switcher with fzf

```bash
bind s display-popup -E -w 40% -h 50% "\
  tmux list-sessions -F '#{session_name}' | \
  fzf --reverse --header='Switch Session' | \
  xargs tmux switch-client -t"
```

### Conditional Config (Per-Environment)

```bash
# Source local overrides if they exist
if-shell "test -f ~/.config/tmux/local.conf" \
  "source-file ~/.config/tmux/local.conf"

# SSH-specific settings
if-shell 'test -n "$SSH_CLIENT"' \
  'set -g status-style "bg=red,fg=white"'
```

### Nesting (Local + Remote tmux)

```bash
# Toggle outer/inner tmux with F12
bind -T root F12 \
  set prefix None \;\
  set key-table off \;\
  set status-style "bg=brightblack" \;\
  if -F '#{pane_in_mode}' 'send-keys -X cancel' \;\
  refresh-client -S

bind -T off F12 \
  set -u prefix \;\
  set -u key-table \;\
  set -u status-style \;\
  refresh-client -S
```

---

## macOS-Specific Notes

### Shell Integration

```bash
# Use default shell (zsh on macOS)
set -g default-command "${SHELL}"

# If using reattach-to-user-namespace (older macOS, usually not needed now)
# set -g default-command "reattach-to-user-namespace -l ${SHELL}"
```

### Undercurl Support (for Neovim diagnostics)

```bash
set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'
```

### iTerm2 Integration

iTerm2 has its own tmux integration mode (`tmux -CC`), but most users prefer
native tmux. If using iTerm2, ensure "Applications in terminal may access
clipboard" is enabled in Preferences > General > Selection.

---

## Complete Example Config

Our default config. SSH-first, lean, C-Space prefix. Copy to
`~/.config/tmux/tmux.conf`:

```bash
# -- Prefix --
unbind C-b
set -g prefix C-Space
bind C-Space send-prefix

# -- General --
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g history-limit 50000
set -g focus-events on
set -sg escape-time 0
set -g set-clipboard on

# -- Terminal & Colors --
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"

# -- Copy mode (vi) --
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-pipe-and-cancel

# -- Pane splitting --
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# -- New windows keep path --
bind c new-window -c "#{pane_current_path}"

# -- Reload config --
bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

# -- Plugins --
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'fcsonline/tmux-thumbs'
set -g @plugin 'sainnhe/tmux-fzf'
set -g @plugin 'catppuccin/tmux'
set -g @catppuccin_flavor 'mocha'

# -- Initialize TPM (keep at bottom) --
set-environment -g TMUX_PLUGIN_MANAGER_PATH '~/.config/tmux/plugins/'
run '~/.config/tmux/plugins/tpm/tpm'
```
