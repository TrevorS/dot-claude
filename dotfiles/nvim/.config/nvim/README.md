# nvim-mini

Minimal, single-file Neovim 0.11+ configuration.

## Features

- **No plugin manager** - Custom bootstrap function clones plugins directly
- **Everything in init.lua** - Single file, no complex directory structure
- **Native LSP** - Uses Neovim 0.11 built-in `vim.lsp.config()` and `vim.lsp.enable()`
- **Explicit parsers** - Treesitter with controlled language support

## Plugins

- [mini.nvim](https://github.com/echasnovski/mini.nvim) - 14+ modules for editing, UI, navigation, and completion
- [oil.nvim](https://github.com/stevearc/oil.nvim) - File explorer that lets you edit directories like buffers
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - Syntax highlighting and code parsing
- [catppuccin](https://github.com/catppuccin/nvim) - Mocha theme

## Quick Start

```bash
# Clone this repo
git clone https://github.com/TrevorS/nvim-mini.git ~/.config/nvim

# Install LSP servers (optional, for language support)
brew install lua-language-server rust-analyzer

# Start Neovim - plugins auto-install on first run
nvim
```

## Key Bindings

- `<Space>` - Leader key
- `-` - File explorer (oil.nvim)
- `<leader>p` - Find files
- `<leader>b` - Find buffers
- `<leader>gg` - Live grep
- `gd` - Go to definition (LSP)
- `K` - Hover documentation (LSP)
- `<leader>th` - Toggle inlay hints

See `CLAUDE.md` for complete documentation.

## Development

```bash
make lint    # Run luacheck
make format  # Run stylua
make check   # CI validation
```

## Requirements

- Neovim 0.11+
- Git (for plugin bootstrap)
- Optional: `lua-language-server`, `rust-analyzer`, `vtsls`, `stylua`, `luacheck`
