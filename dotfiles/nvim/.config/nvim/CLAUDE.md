# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This is a **single-file Neovim 0.12.0 configuration** (`init.lua`) with zero external dependencies except plugins. The config follows a minimal, pragmatic philosophy:

- **`vim.pack` for plugin management** — Neovim 0.12 built-in. Plugins listed in `vim.pack.add()` call
- **Everything in init.lua** — No split config files, no `lua/` directory, no complexity
- **Neovim 0.12 built-in LSP** — Uses `vim.lsp.config()` and `vim.lsp.enable()` directly (no nvim-lspconfig)
- **Mini.nvim for core features** — 18 modules handling text editing, completion, UI, navigation, and git
- **Explicit parser management** — nvim-treesitter with `ensure_installed` for only necessary languages

### Plugin Stack

1. **mini.nvim** (18 modules) — Core editing and workflow tools

   - Text editing: basics, ai, surround, pairs, snippets, move
   - UI: icons, indentscope, statusline, notify, trailspace, tabline, clue
   - Navigation: pick (fuzzy finder), git, bracketed, extra, visits

2. **oil.nvim** — File explorer (edit directories like buffers, `-` to open)

3. **nvim-treesitter** — Syntax highlighting with explicit parsers

4. **catppuccin** (mocha) — Theme with mini.nvim integration

### LSP Configuration

LSP servers are configured inline using Neovim 0.12's built-in APIs:

```lua
vim.lsp.config('server_name', {
  cmd = {'executable_name'},
  filetypes = {'filetype'},
  root_markers = {'root_marker'},
  settings = {}  -- Language-specific settings
})
vim.lsp.enable({'server_name'})
```

**Currently configured servers:**

- `lua_ls` — Lua (requires `lua-language-server` binary)
- `rust_analyzer` — Rust (requires `rust-analyzer` binary, uses clippy for check)
- `vtsls` — TypeScript/JavaScript (requires `vtsls` binary)

**Note:** LSP binaries must be installed separately (e.g., via Homebrew, cargo, npm).

### Diagnostic Float Management

Custom state machine for diagnostic floats:

- Auto-shows on `CursorHold` after 250ms (configurable via `updatetime`)
- `<leader>d` toggles the float — dismissing once per line prevents spam
- Automatically clears dismissed state on line change or text modification
- Respects multi-line diagnostics

### Format-on-Save Behavior

- Trims trailing whitespace via mini.trailspace
- Ensures EOF newline
- Lua files: Uses `stylua` if available (via shell), otherwise LSP format
- Other files: Uses LSP format if clients are available

## Common Development Tasks

### Validation Commands

- `make` — runs both luacheck and stylua
- `make lint` — luacheck only
- `make format` — stylua only
- `:checkhealth` — verify providers, LSP, treesitter
- `:PackUpdate` — update all plugins (or `:PackUpdate name` for one)

### Adding a Plugin

1. Edit `init.lua` — add URL to the `vim.pack.add()` call
2. Add setup code for the plugin (e.g., `require('plugin_name').setup({...})`)
3. Restart Neovim or run `:PackUpdate`

### Language Support

To add support for a new language:

1. Install the LSP server binary (e.g., `brew install lua-language-server`)
2. Add `vim.lsp.config()` block with server settings
3. Add to `vim.lsp.enable()` array
4. Add parser to treesitter `ensure_installed` array if syntax highlighting needed
5. Add to format-on-save logic if custom formatter available
6. Update `.luarc.json` and `.luacheckrc` as needed for new globals

## Key Bindings Reference

**Leader key:** `<Space>`

### Essential

- `-` — Open file explorer (oil.nvim)
- `<leader>p` — Find files (mini.pick)
- `<leader>b` — Find buffers (mini.pick)
- `<leader>gg` — Live grep (mini.pick)
- `<leader>*` — Grep word under cursor (mini.pick)

### Navigation

- `Ctrl-h/j/k/l` — Move between windows
- `<TAB>` / `<S-TAB>` — Next/previous buffer
- `<leader>1-9` — Jump to buffer by position in tabline
- `j/k` — Move down/up respecting line wrapping (gj/gk)

### LSP (0.12 built-in defaults)

- `gd` — Go to definition
- `K` — Hover documentation
- `grn` — Rename symbol
- `gra` — Code action
- `grr` — Show references
- `gri` — Implementation
- `gO` — Document symbols
- `grx` — Codelens
- `<leader>f` — Format buffer (custom)

### Editing

- `<leader>h` / `<leader>v` — Horizontal/vertical split
- `<leader>q` — Close buffer (quit if last)
- `<leader>d` — Toggle diagnostic float
- `<leader>xx` — Show all diagnostics (mini.extra picker)
- `<leader>l` — Redraw and clear highlights

### Formatting

- `<leader>jf` — Format JSON with jq
- `<leader>sf` — Format SQL with sleek

### Config Editing

- `<leader>ev` — Edit vim config (init.lua)
- `<leader>ez` — Edit zshrc

### Utility

- `<leader>y` — Yank selection to system clipboard (visual mode)

## Settings Overview

**Key non-defaults:**

- 2-space indentation (expandtab, tabstop, shiftwidth, softtabstop)
- `autocomplete = true` with fuzzy built-in completion
- `updatetime = 250ms` — Controls diagnostic float auto-show delay
- `timeoutlen = 300ms` — Leader key timeout
- `winborder = "rounded"` / `pumborder = "rounded"` — Rounded borders everywhere
- Unicode box-drawing fillchars for window separators
- `virtualedit = "onemore"` — Allow cursor past end of line

## Important Implementation Notes

- **mini.basics** provides window navigation (Ctrl-hjkl), so don't duplicate these
- **Built-in completion** with `vim.lsp.completion.enable()` — Tab confirms, no mini.completion
- Buffer switching (`<leader>1-9`) matches tabline order (sorted by buffer number)
- Tabline auto-hides when only one buffer exists
- Diagnostic float state persists across line changes but resets on text modification
- Format-on-save hooks into `BufWritePre` — stylua for Lua, LSP format for others
- LSP servers use Neovim 0.12 built-in APIs — do NOT add nvim-lspconfig
- Plugin management uses `vim.pack` (0.12 built-in) — do NOT add lazy.nvim or other plugin managers

## Project Configuration Files

- `.luarc.json` — lua_ls server config (disables false-positives for Neovim API)
- `.luacheckrc` — luacheck linter config (defines globals)
- `Makefile` — `make lint` and `make format` targets

## Disabled Language Providers

To minimize startup overhead, the following providers are disabled:

- Node.js provider (`vim.g.loaded_node_provider = 0`)
- Python 3 provider (`vim.g.loaded_python3_provider = 0`)
- Ruby provider (`vim.g.loaded_ruby_provider = 0`)
- Perl provider (`vim.g.loaded_perl_provider = 0`)

These are not needed for the current setup and would only generate checkhealth warnings.
