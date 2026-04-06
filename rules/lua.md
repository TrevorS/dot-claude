---
paths:
  - "**/*.lua"
---

# Lua / Neovim

- **Format**: stylua -- **Lint**: luacheck -- run both via `make validate`

## vim.pack Plugin Management (Neovim 0.12)

- Add plugins with `vim.pack.add()` using full GitHub URLs
- Configure with `require('plugin').setup({})` after the `vim.pack.add()` call
- Update with `:PackUpdate` (or `:PackUpdate name` for a single plugin)
- No lazy-loading DSL -- plugins load at startup
