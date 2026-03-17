---
paths:
  - "**/*.lua"
---

# Lua / Neovim

## Formatting & Linting

- **Format**: stylua (configured in `.stylua.toml` or `stylua.toml`)
- **Lint**: luacheck (configured in `.luacheckrc`)
- Run both via `make validate` when available

## Neovim API Patterns

- Use `vim.api.nvim_*` for buffer/window/command operations
- Use `vim.keymap.set(mode, lhs, rhs, opts)` for keymaps (not `vim.api.nvim_set_keymap`)
- Use `vim.opt` for options (not `vim.o` unless performance-critical)
- Use `vim.fn` for calling Vimscript functions
- Prefer `vim.notify()` over `print()` for user-facing messages

## lazy.nvim Plugin Specs

- Each plugin is a table: `{ "author/repo", opts = {}, config = function() end }`
- Use `opts` for simple configuration (auto-calls `setup(opts)`)
- Use `config` only when `opts` is insufficient
- Use `event`, `ft`, `cmd`, `keys` for lazy-loading
- Dependencies go in `dependencies = { "dep/repo" }`
- Keep one plugin per file in `lua/plugins/`
