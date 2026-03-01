-- ABOUTME: Minimal Neovim 0.11.4 config with custom plugin bootstrap
-- Single-file configuration using mini.nvim modules and catppuccin theme

---@diagnostic disable: inject-field, undefined-field, assign-type-mismatch, param-type-mismatch
-- Disable unused language providers
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0

-- ============================================================================
-- PLUGIN BOOTSTRAP
-- ============================================================================

local function ensure_plugin(user, repo)
	local install_path = vim.fn.stdpath("data") .. "/site/pack/vendor/start/" .. repo

	if vim.fn.isdirectory(install_path) == 0 then
		vim.notify("Installing " .. repo .. "...", vim.log.levels.INFO)
		local url = string.format("https://github.com/%s/%s.git", user, repo)
		vim.fn.system({ "git", "clone", "--depth=1", url, install_path })
		vim.notify("Installed " .. repo, vim.log.levels.INFO)
		return true
	end
	return false
end

local function bootstrap_plugins()
	local installed_any = false

	-- Install mini.nvim
	if ensure_plugin("nvim-mini", "mini.nvim") then
		installed_any = true
	end

	-- Install catppuccin
	if ensure_plugin("catppuccin", "nvim") then
		installed_any = true
	end

	-- Install oil.nvim
	if ensure_plugin("stevearc", "oil.nvim") then
		installed_any = true
	end

	-- Install nvim-treesitter
	if ensure_plugin("nvim-treesitter", "nvim-treesitter") then
		installed_any = true
	end

	if installed_any then
		vim.notify("Run :PluginUpdate to update plugins", vim.log.levels.INFO)
		vim.cmd("packloadall! | helptags ALL")
	end
end

-- Bootstrap on first run
bootstrap_plugins()

-- Create update command (async to avoid UI hang)
vim.api.nvim_create_user_command("PluginUpdate", function()
	local data_path = vim.fn.stdpath("data") .. "/site/pack/vendor/start/"
	local plugins = vim.fn.readdir(data_path)
	local completed = 0
	local total = #plugins

	vim.notify("Plugin updates started (running in background)...", vim.log.levels.INFO)

	for _, plugin in ipairs(plugins) do
		local plugin_path = data_path .. plugin
		vim.notify("Updating " .. plugin .. "...", vim.log.levels.INFO)

		vim.system({ "git", "-C", plugin_path, "pull" }, {}, function(obj)
			completed = completed + 1
			if obj.code == 0 then
				vim.notify("Updated " .. plugin, vim.log.levels.INFO)
			else
				vim.notify("Failed to update " .. plugin, vim.log.levels.WARN)
			end

			if completed == total then
				vim.schedule(function()
					vim.cmd("packloadall! | helptags ALL")
					vim.notify("All plugins updated!", vim.log.levels.INFO)
				end)
			end
		end)
	end
end, {})

-- ============================================================================
-- CORE SETTINGS
-- ============================================================================

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable unused providers
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

-- Settings not covered by mini.basics
vim.opt.termguicolors = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.inccommand = "nosplit"
vim.opt.completeopt = { "menuone", "noinsert" } -- Different from mini.basics 'noselect'
vim.opt.shortmess:append("c")
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.virtualedit = "onemore" -- Different from mini.basics 'block'
vim.opt.wildmode = { "longest", "list:longest" }

-- Custom fillchars (overrides mini.basics default)
vim.opt.fillchars = {
	horiz = "━",
	horizup = "┻",
	horizdown = "┳",
	vert = "┃",
	vertleft = "┫",
	vertright = "┣",
	verthoriz = "╋",
}

-- ============================================================================
-- NEOVIM 0.11 BUILT-IN LSP
-- ============================================================================

-- Configure LSP servers (examples - install servers separately)
-- lua_ls
vim.lsp.config("lua_ls", {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = {
		".luarc.json",
		".luarc.jsonc",
		".luacheckrc",
		".stylua.toml",
		"stylua.toml",
		"selene.toml",
		"selene.yml",
		".git",
	},
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			workspace = {
				checkThirdParty = false,
				library = { vim.env.VIMRUNTIME },
			},
		},
	},
})

-- rust-analyzer
vim.lsp.config("rust_analyzer", {
	cmd = { "rust-analyzer" },
	filetypes = { "rust" },
	root_markers = { "Cargo.toml", "Cargo.lock", "rust-project.json" },
	settings = {
		["rust-analyzer"] = {
			cargo = {
				allFeatures = true,
			},
			check = {
				command = "clippy",
			},
		},
	},
})

-- vtsls (TypeScript)
vim.lsp.config("vtsls", {
	cmd = { "vtsls", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
})

-- Enable LSP servers
vim.lsp.enable({ "lua_ls", "rust_analyzer", "vtsls" })

-- LSP keymaps
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local opts = { buffer = args.buf }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
	end,
})

-- Global format keymap
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format buffer" })

-- ============================================================================
-- DIAGNOSTIC FLOAT MANAGEMENT
-- ============================================================================

local diagnostic_float_state = {
	win_id = nil,
	dismissed_line = nil,
	dismissed_buf = nil,
}

-- Helper: Find the diagnostic float window
local function find_diagnostic_float()
	local current_win = vim.api.nvim_get_current_win()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local config = vim.api.nvim_win_get_config(win)
		if config.relative ~= "" and win ~= current_win then
			return win
		end
	end
	return nil
end

-- Setup diagnostic float autocmds
local function setup_diagnostic_float()
	-- Clear dismissed state when cursor moves to different line
	vim.api.nvim_create_autocmd("CursorMoved", {
		callback = function()
			local current_line = vim.fn.line(".")
			local current_buf = vim.api.nvim_get_current_buf()

			if
				diagnostic_float_state.dismissed_line ~= current_line
				or diagnostic_float_state.dismissed_buf ~= current_buf
			then
				diagnostic_float_state.dismissed_line = nil
				diagnostic_float_state.dismissed_buf = nil
			end
		end,
	})

	-- Clear dismissed state when text changes
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		callback = function()
			diagnostic_float_state.dismissed_line = nil
			diagnostic_float_state.dismissed_buf = nil
		end,
	})

	-- Auto-show diagnostic on cursor hold
	vim.api.nvim_create_autocmd("CursorHold", {
		callback = function()
			local current_line = vim.fn.line(".")
			local current_buf = vim.api.nvim_get_current_buf()

			-- Don't auto-show if float is open or line was dismissed
			if diagnostic_float_state.win_id and vim.api.nvim_win_is_valid(diagnostic_float_state.win_id) then
				return
			end

			if
				diagnostic_float_state.dismissed_line == current_line
				and diagnostic_float_state.dismissed_buf == current_buf
			then
				return
			end

			vim.diagnostic.open_float(nil, { focus = false })
			diagnostic_float_state.win_id = find_diagnostic_float()
		end,
	})
end

setup_diagnostic_float()

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Get listed buffers
local function get_listed_buffers()
	return vim.tbl_filter(function(b)
		return vim.fn.buflisted(b) == 1
	end, vim.api.nvim_list_bufs())
end

-- Update tabline visibility (hide when only one buffer)
local function update_tabline_visibility()
	vim.o.showtabline = #get_listed_buffers() > 1 and 2 or 0
end

-- Format on save: trim whitespace, ensure EOF newline, then format
vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function()
		require("mini.trailspace").trim()
		vim.bo.fixeol = true
		vim.bo.eol = true

		-- Format Lua files with stylua if available
		if vim.bo.filetype == "lua" and vim.fn.executable("stylua") == 1 then
			local view = vim.fn.winsaveview()
			vim.cmd("%!stylua -")
			vim.fn.winrestview(view)
		else
			-- Use LSP format for other filetypes
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if #clients > 0 then
				vim.lsp.buf.format()
			end
		end
	end,
})

-- ============================================================================
-- MINI.NVIM MODULES
-- ============================================================================

-- Text Editing
-- ----------------------------------------------------------------------------

require("mini.basics").setup({
	options = { basic = true, extra_ui = false },
	mappings = { basic = true, option_toggle_prefix = [[\]], windows = true, move_with_alt = false },
	autocommands = { basic = true, relnum_in_visual_mode = false },
})

require("mini.comment").setup()
require("mini.surround").setup()
require("mini.pairs").setup()
require("mini.ai").setup()
require("mini.snippets").setup()

-- Completion
-- ----------------------------------------------------------------------------

require("mini.completion").setup({
	lsp_completion = { source_func = "omnifunc", auto_setup = true },
	window = {
		info = { height = 25, width = 80, border = "none" },
		signature = { height = 25, width = 80, border = "none" },
	},
})

-- Tab to confirm completion
vim.keymap.set("i", "<Tab>", function()
	return vim.fn.pumvisible() == 1 and "<C-y>" or "<Tab>"
end, { expr = true, desc = "Confirm completion or insert tab" })

-- UI & Appearance
-- ----------------------------------------------------------------------------

require("mini.icons").setup()
require("mini.indentscope").setup({ symbol = "│", options = { try_as_border = true } })
require("mini.trailspace").setup()
require("mini.tabline").setup()
require("mini.notify").setup()
vim.notify = require("mini.notify").make_notify()

require("mini.statusline").setup({
	content = {
		active = function()
			local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
			local git = MiniStatusline.section_git({ trunc_width = 75 })
			local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
			local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
			local filename = MiniStatusline.section_filename({ trunc_width = 140 })

			return MiniStatusline.combine_groups({
				{ hl = mode_hl, strings = { mode } },
				{ hl = "MiniStatuslineFilename", strings = { filename } },
				"%<",
				{ hl = "MiniStatuslineDevinfo", strings = { git, lsp, diagnostics } },
				"%=",
			})
		end,
	},
	use_icons = true,
})

-- Navigation & Workflow
-- ----------------------------------------------------------------------------

require("mini.pick").setup()
require("mini.extra").setup()
require("mini.visits").setup()
require("mini.bracketed").setup()
require("mini.move").setup()
require("mini.git").setup()

require("oil").setup({
	default_file_explorer = true,
	delete_to_trash = true,
	skip_confirm_for_simple_edits = true,
})

require("nvim-treesitter.configs").setup({
	ensure_installed = { "lua", "rust", "typescript", "javascript", "json", "toml", "markdown" },
	highlight = { enable = true },
})

require("mini.clue").setup({
	triggers = {
		{ mode = "n", keys = "<Leader>" },
		{ mode = "x", keys = "<Leader>" },
		{ mode = "n", keys = "g" },
		{ mode = "x", keys = "g" },
		{ mode = "n", keys = "[" },
		{ mode = "n", keys = "]" },
	},
	clues = {
		require("mini.clue").gen_clues.builtin_completion(),
		require("mini.clue").gen_clues.g(),
		require("mini.clue").gen_clues.marks(),
		require("mini.clue").gen_clues.registers(),
		require("mini.clue").gen_clues.windows(),
		require("mini.clue").gen_clues.z(),
	},
	window = { delay = 500 },
})

-- Auto-hide tabline when only one buffer exists
update_tabline_visibility()
vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
	callback = function()
		vim.schedule(update_tabline_visibility)
	end,
})

-- ============================================================================
-- CATPPUCCIN THEME
-- ============================================================================

require("catppuccin").setup({
	flavour = "mocha",
	transparent_background = false,
	integrations = {
		mini = {
			enabled = true,
			indentscope_color = "",
		},
	},
})

vim.cmd.colorscheme("catppuccin")

-- ============================================================================
-- KEYMAPS
-- ============================================================================

-- Splits
vim.keymap.set("n", "<leader>v", "<cmd>vsplit<cr><c-w>l", { desc = "Vertical split" })
vim.keymap.set("n", "<leader>h", "<cmd>split<cr><c-w>j", { desc = "Horizontal split" })

-- Edit config files
vim.keymap.set("n", "<leader>ev", function()
	vim.cmd.edit(vim.fn.stdpath("config") .. "/init.lua")
end, { desc = "Edit vim config" })
vim.keymap.set("n", "<leader>ez", "<cmd>edit $HOME/.zshrc<cr>", { desc = "Edit zshrc" })
vim.keymap.set(
	"n",
	"<leader>eg",
	"<cmd>edit $HOME/Library/Application\\ Support/com.mitchellh.ghostty/config<cr>",
	{ desc = "Edit ghostty config" }
)

-- Redraw and clear highlights
vim.keymap.set("n", "<leader>l", "<cmd>redraw!<cr><cmd>nohl<cr><esc>", { desc = "Redraw and clear highlights" })

-- System clipboard yank in visual mode
vim.keymap.set("v", "<leader>y", '"+y', { desc = "Yank to system clipboard" })

-- File explorer
vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })

-- mini.pick keymaps
local pick_maps = {
	{ "<leader>p", "files", "Find files" },
	{ "<leader>b", "buffers", "Find buffers" },
	{ "<leader>gg", "grep_live", "Live grep" },
}

for _, map in ipairs(pick_maps) do
	vim.keymap.set("n", map[1], function()
		require("mini.pick").builtin[map[2]]()
	end, { desc = map[3] })
end

vim.keymap.set("n", "<leader>*", function()
	require("mini.pick").builtin.grep({ pattern = vim.fn.expand("<cword>") })
end, { desc = "Grep word under cursor" })

-- mini.extra diagnostic picker
vim.keymap.set("n", "<leader>xx", function()
	require("mini.extra").pickers.diagnostic()
end, { desc = "Show diagnostics" })

-- Diagnostic toggle keymap (defined here to access state/helpers)
vim.keymap.set("n", "<leader>d", function()
	local current_line = vim.fn.line(".")
	local current_buf = vim.api.nvim_get_current_buf()

	if diagnostic_float_state.win_id and vim.api.nvim_win_is_valid(diagnostic_float_state.win_id) then
		-- Close and mark as dismissed
		vim.api.nvim_win_close(diagnostic_float_state.win_id, true)
		diagnostic_float_state.win_id = nil
		diagnostic_float_state.dismissed_line = current_line
		diagnostic_float_state.dismissed_buf = current_buf
	else
		-- Open and clear dismissed state
		vim.diagnostic.open_float(nil, { focus = false })
		diagnostic_float_state.win_id = find_diagnostic_float()
		diagnostic_float_state.dismissed_line = nil
		diagnostic_float_state.dismissed_buf = nil
	end
end, { desc = "Toggle diagnostic float" })

-- Navigate wrapped lines
vim.keymap.set("n", "j", "gj", { desc = "Move down (wrapped)" })
vim.keymap.set("n", "k", "gk", { desc = "Move up (wrapped)" })

-- Buffer navigation
vim.keymap.set("n", "<TAB>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-TAB>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })

-- Close buffer (quit if last buffer)
vim.keymap.set("n", "<leader>q", function()
	local buffers = get_listed_buffers()

	if #buffers == 1 then
		-- Last buffer, quit Neovim
		vim.cmd("quit")
	else
		-- Delete current buffer
		vim.cmd("bdelete")
		-- Update tabline visibility (will hide if down to 1 buffer)
		vim.schedule(update_tabline_visibility)
	end
end, { desc = "Close buffer" })

-- Buffer switching by position
for i = 1, 9 do
	vim.keymap.set("n", "<leader>" .. i, function()
		local buffers = get_listed_buffers()
		table.sort(buffers)
		if buffers[i] then
			vim.api.nvim_set_current_buf(buffers[i])
		end
	end, { desc = "Go to buffer " .. i })
end

-- Format JSON with jq
vim.keymap.set("n", "<leader>jf", "<cmd>%!jq .<cr>", { desc = "Format JSON with jq" })

-- Format SQL with sleek
vim.keymap.set("n", "<leader>sf", "<cmd>%!sleek<cr>", { desc = "Format SQL with sleek" })

-- Copy buffer path to system clipboard
vim.keymap.set("n", "<leader>xp", function()
	local path = vim.api.nvim_buf_get_name(0)
	vim.fn.setreg("+", path)
	vim.notify("Copied path: " .. path, vim.log.levels.INFO)
end, { desc = "Copy buffer path to clipboard" })

-- Trim trailing whitespace
vim.keymap.set("n", "<leader>ts", function()
	require("mini.trailspace").trim()
	vim.notify("Trimmed trailing whitespace", vim.log.levels.INFO)
end, { desc = "Trim trailing whitespace" })

-- Better indenting
vim.keymap.set("v", "<", "<gv", { desc = "Indent left" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right" })
