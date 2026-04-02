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

## vim.pack Plugin Management (Neovim 0.12)

- Add plugins in `vim.pack.add()` with full GitHub URLs
- Configure plugins with `require('plugin').setup({})` after the `vim.pack.add()` call
- Update plugins with `:PackUpdate` (or `:PackUpdate name` for a single plugin)
- No lazy-loading DSL — plugins load at startup. Keep the list small and intentional
