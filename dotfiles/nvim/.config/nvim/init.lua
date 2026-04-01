-- ABOUTME: Minimal Neovim 0.12.0 config with vim.pack and catppuccin theme
-- Single-file configuration using mini.nvim modules

---@diagnostic disable: inject-field, undefined-field, assign-type-mismatch, param-type-mismatch
-- Disable unused language providers
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0

-- ============================================================================
-- PLUGIN MANAGEMENT (vim.pack)
-- ============================================================================

vim.pack.add({
	"https://github.com/nvim-mini/mini.nvim",
	"https://github.com/catppuccin/nvim",
	"https://github.com/stevearc/oil.nvim",
	"https://github.com/nvim-treesitter/nvim-treesitter",
})

vim.api.nvim_create_user_command("PackUpdate", function(args)
	local names = #args.fargs > 0 and args.fargs or nil
	vim.pack.update(names)
end, { nargs = "*" })

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
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.virtualedit = "onemore"
vim.opt.wildmode = { "longest", "list:longest" }

-- built-in completion
vim.opt.autocomplete = true
vim.opt.completeopt = { "menuone", "noinsert", "popup", "fuzzy" }
vim.opt.complete = ".,w,b,u,o"

-- UI borders
vim.opt.winborder = "rounded"
vim.opt.pumborder = "rounded"

-- ui2
require("vim._core.ui2").enable({ msg = { targets = "cmd" } })

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

-- LSP keymaps and built-in completion
-- 0.12 defaults: K (hover), grn (rename), gra (code action), grr (references),
-- gri (implementation), gO (document symbols), grt (type definition), grx (codelens)
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client then
			vim.lsp.completion.enable(true, client.id, args.buf)
		end

		vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf })
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

			vim.diagnostic.open_float({ focus = false })
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

require("mini.surround").setup()
require("mini.pairs").setup()
require("mini.ai").setup()
require("mini.snippets").setup()

-- UI & Appearance
-- ----------------------------------------------------------------------------

require("mini.icons").setup()
require("mini.indentscope").setup({ symbol = "│", options = { try_as_border = true } })
require("mini.trailspace").setup()
require("mini.tabline").setup()
require("mini.notify").setup()
vim.notify = require("mini.notify").make_notify()

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
	view_options = {
		show_hidden = true,
	},
})

require("nvim-treesitter").setup()
require("nvim-treesitter").install({
	"lua",
	"rust",
	"typescript",
	"javascript",
	"json",
	"toml",
	"markdown",
	"python",
	"go",
	"elixir",
	"elm",
	"gleam",
	"zig",
	"ruby",
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
	custom_highlights = function(colors)
		return {
			-- 0.12 highlight groups not yet in catppuccin
			PmenuBorder = { link = "FloatBorder" },
			PmenuShadow = { link = "FloatShadow" },
			PmenuShadowThrough = { link = "FloatShadowThrough" },
			DiffTextAdd = { link = "DiffAdd" },
			OkMsg = { link = "DiagnosticOk" },
			StderrMsg = { link = "ErrorMsg" },
			StdoutMsg = { link = "ModeMsg" },
			-- jj diamond highlights
			StJJDirty = { fg = colors.green, bg = colors.surface1, bold = true },
			StJJEmpty = { fg = colors.overlay0, bg = colors.surface1 },
		}
	end,
})

vim.cmd.colorscheme("catppuccin")

-- ============================================================================
-- JJ INTEGRATION
-- ============================================================================

-- Cache jj info per buffer (nil = not checked, false = not a jj repo)
-- Access via vim.b.jj or jj_get(buf)
local jj_cache = {}

local jj_tmpl = 'change_id.shortest() ++ "\\n"'
	.. ' ++ bookmarks.filter(|b| b.remote() == "").map(|b| b.name()).join(" ") ++ "\\n"'
	.. ' ++ description.first_line() ++ "\\n"'
	.. ' ++ if(empty, "empty", "dirty")'

local function jj_refresh(buf)
	local file = vim.api.nvim_buf_get_name(buf)
	if file == "" or file:find("^%w+:") then
		return
	end
	local dir = vim.fn.fnamemodify(file, ":h")
	if vim.fn.isdirectory(dir) == 0 then
		return
	end
	vim.system(
		{ "jj", "log", "-r", "@", "--no-graph", "-T", jj_tmpl, "--ignore-working-copy" },
		{ cwd = dir },
		vim.schedule_wrap(function(result)
			if result.code == 0 and result.stdout and result.stdout ~= "" then
				local lines = vim.split(result.stdout, "\n")
				local info = {
					id = (lines[1] or ""):match("^%S+") or "",
					bookmark = (lines[2] or ""):match("^%S+") or "",
					desc = ((lines[3] or ""):gsub("%s+$", "")),
					empty = (lines[4] or ""):match("^empty") ~= nil,
				}
				jj_cache[buf] = info
				vim.b[buf].jj = info
			else
				jj_cache[buf] = false
				vim.b[buf].jj = nil
			end
		end)
	)
end

local function jj_get(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	return jj_cache[buf]
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
	callback = function(args)
		jj_refresh(args.buf)
	end,
})

-- ============================================================================
-- STATUSLINE
-- ============================================================================

require("mini.statusline").setup({
	content = {
		active = function()
			local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
			local git = MiniStatusline.section_git({ trunc_width = 75 })
			local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
			local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
			local filename = MiniStatusline.section_filename({ trunc_width = 140 })

			-- jj: show change info instead of git when in a jj repo
			local jj_info = jj_get()
			local jj = ""
			if jj_info and jj_info ~= false then
				local diamond = jj_info.empty and "%#StJJEmpty#◇" or "%#StJJDirty#◆"
				local parts = { diamond .. "%#MiniStatuslineDevinfo# " .. jj_info.id }
				if jj_info.bookmark ~= "" then
					parts[#parts + 1] = " " .. jj_info.bookmark
				end
				if jj_info.desc ~= "" then
					local desc = jj_info.desc
					if #desc > 30 then
						desc = desc:sub(1, 27) .. "..."
					end
					parts[#parts + 1] = " " .. desc
				end
				jj = table.concat(parts)
			end

			-- In colocated repos, show jj instead of git
			local vcs = jj ~= "" and jj or git

			return MiniStatusline.combine_groups({
				{ hl = mode_hl, strings = { mode } },
				{ hl = "MiniStatuslineFilename", strings = { filename } },
				"%<",
				{ hl = "MiniStatuslineDevinfo", strings = { vcs, lsp, diagnostics } },
				"%=",
			})
		end,
	},
	use_icons = true,
})

-- ============================================================================
-- KEYMAPS
-- ============================================================================

-- Tab/S-Tab to navigate completion menu
vim.keymap.set("i", "<Tab>", function()
	return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true, desc = "Next completion or insert tab" })

vim.keymap.set("i", "<S-Tab>", function()
	return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true, desc = "Prev completion or unindent" })

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
		vim.diagnostic.open_float({ focus = false })
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
