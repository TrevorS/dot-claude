-- ABOUTME: Minimal Neovim 0.12.0 config with vim.pack and catppuccin theme
-- Single-file configuration using mini.nvim modules

---@diagnostic disable: inject-field, undefined-field, assign-type-mismatch, param-type-mismatch
-- Disable unused language providers
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

-- ============================================================================
-- PLUGIN MANAGEMENT (vim.pack)
-- ============================================================================

vim.pack.add({
	"https://github.com/nvim-mini/mini.nvim",
	"https://github.com/catppuccin/nvim",
	"https://github.com/stevearc/oil.nvim",
	"https://github.com/mrjones2014/smart-splits.nvim",
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main" },
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

-- ui2 (private API in 0.12 — no public path yet, pcall for safety)
pcall(function()
	require("vim._core.ui2").enable({ msg = { targets = "cmd" } })
end)

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

-- LSP servers
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

vim.lsp.config("vtsls", {
	cmd = { "vtsls", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
})

vim.lsp.config("basedpyright", {
	cmd = { "basedpyright-langserver", "--stdio" },
	filetypes = { "python" },
	root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
	settings = {
		basedpyright = {
			analysis = {
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "openFilesOnly",
			},
		},
	},
})

vim.lsp.enable({ "lua_ls", "rust_analyzer", "vtsls", "basedpyright" })

-- 0.12 defaults: K (hover), grn (rename), gra (code action), grr (references),
-- gri (implementation), gO (document symbols), grt (type definition), grx (codelens)
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("config_lsp", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client then
			vim.lsp.completion.enable(true, client.id, args.buf)
		end

		vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to definition" })
	end,
})

-- ============================================================================
-- DIAGNOSTIC FLOAT MANAGEMENT
-- ============================================================================

local diagnostic_float_state = {
	win_id = nil,
	dismissed_line = nil,
	dismissed_buf = nil,
}

local diag_float_group = vim.api.nvim_create_augroup("config_diagnostic_float", { clear = true })

vim.api.nvim_create_autocmd("CursorMoved", {
	group = diag_float_group,
	callback = function()
		if not diagnostic_float_state.dismissed_line then
			return
		end

		local current_line = vim.api.nvim_win_get_cursor(0)[1]
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

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
	group = diag_float_group,
	callback = function()
		diagnostic_float_state.dismissed_line = nil
		diagnostic_float_state.dismissed_buf = nil
	end,
})

vim.api.nvim_create_autocmd("CursorHold", {
	group = diag_float_group,
	callback = function()
		if vim.fn.mode() ~= "n" then
			return
		end

		local current_line = vim.api.nvim_win_get_cursor(0)[1]
		local current_buf = vim.api.nvim_get_current_buf()

		if diagnostic_float_state.win_id and vim.api.nvim_win_is_valid(diagnostic_float_state.win_id) then
			return
		end

		if
			diagnostic_float_state.dismissed_line == current_line
			and diagnostic_float_state.dismissed_buf == current_buf
		then
			return
		end

		local _, winnr = vim.diagnostic.open_float({ focus = false })
		diagnostic_float_state.win_id = winnr
	end,
})

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Get listed buffers
local function get_listed_buffers()
	return vim.tbl_filter(function(b)
		return vim.bo[b].buflisted
	end, vim.api.nvim_list_bufs())
end

-- Update tabline visibility (hide when only one buffer)
local function update_tabline_visibility()
	vim.o.showtabline = #get_listed_buffers() > 1 and 2 or 0
end

-- Format on save: trim whitespace, ensure EOF newline, then format
vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("config_format", { clear = true }),
	callback = function()
		if vim.bo.buftype ~= "" then
			return
		end

		require("mini.trailspace").trim()
		vim.bo.fixeol = true
		vim.bo.eol = true

		if vim.bo.filetype == "lua" and vim.fn.executable("stylua") == 1 then
			local view = vim.fn.winsaveview()
			vim.cmd("%!stylua -")
			if vim.v.shell_error ~= 0 then
				vim.cmd.undo()
			end
			vim.fn.winrestview(view)
		else
			local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/formatting" })
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

require("mini.surround").setup({
	mappings = {
		add = "ys",
		delete = "ds",
		replace = "cs",
		find = "",
		find_left = "",
		highlight = "",
		update_n_lines = "",
		suffix_last = "l",
		suffix_next = "n",
	},
	search_method = "cover_or_next",
})
require("mini.pairs").setup()

-- Disable autopairs in prose filetypes where apostrophes dominate
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("config_minipairs_prose", { clear = true }),
	pattern = { "markdown", "text", "gitcommit", "mail" },
	callback = function()
		vim.b.minipairs_disable = true
	end,
})
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
	delete_to_trash = true,
	skip_confirm_for_simple_edits = true,
	view_options = {
		show_hidden = true,
	},
})

require("smart-splits").setup({
	at_edge = "stop",
})
local ss = require("smart-splits")
vim.keymap.set("n", "<C-h>", ss.move_cursor_left, { desc = "Move to left split/pane" })
vim.keymap.set("n", "<C-j>", ss.move_cursor_down, { desc = "Move to below split/pane" })
vim.keymap.set("n", "<C-k>", ss.move_cursor_up, { desc = "Move to above split/pane" })
vim.keymap.set("n", "<C-l>", ss.move_cursor_right, { desc = "Move to right split/pane" })

require("nvim-treesitter").setup()
require("nvim-treesitter").install({
	"bash",
	"comment",
	"diff",
	"elixir",
	"elm",
	"gleam",
	"go",
	"javascript",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"python",
	"regex",
	"ruby",
	"rust",
	"toml",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
	"zig",
})

-- nvim-treesitter main branch: highlights/injections aren't auto-started
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("config_treesitter", { clear = true }),
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
	end,
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
	group = vim.api.nvim_create_augroup("config_tabline", { clear = true }),
	callback = function()
		vim.schedule(update_tabline_visibility)
	end,
})

-- ============================================================================
-- CATPPUCCIN THEME
-- ============================================================================

require("catppuccin").setup({
	flavour = "mocha",
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
			-- Reverse-highlight TODO-style comment markers (TODO, FIXME, NOTE, WARN, etc.)
			Todo = { fg = colors.base, bg = colors.yellow, bold = true },
			["@comment.todo"] = { fg = colors.base, bg = colors.yellow, bold = true },
			["@comment.note"] = { fg = colors.base, bg = colors.blue, bold = true },
			["@comment.warning"] = { fg = colors.base, bg = colors.peach, bold = true },
			["@comment.error"] = { fg = colors.base, bg = colors.red, bold = true },
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
	local dir = vim.fs.dirname(file)
	if not vim.uv.fs_stat(dir) then
		return
	end
	vim.system(
		{ "jj", "log", "-r", "@", "--no-graph", "-T", jj_tmpl, "--ignore-working-copy" },
		{ cwd = dir },
		vim.schedule_wrap(function(result)
			if result.code == 0 and result.stdout ~= "" then
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

local jj_group = vim.api.nvim_create_augroup("config_jj", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
	group = jj_group,
	callback = function(args)
		if jj_cache[args.buf] == nil then
			jj_refresh(args.buf)
		end
	end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
	group = jj_group,
	callback = function(args)
		jj_refresh(args.buf)
	end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
	group = jj_group,
	callback = function(args)
		jj_cache[args.buf] = nil
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
			if type(jj_info) == "table" then
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

vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format buffer" })

-- Splits
vim.keymap.set("n", "<leader>v", "<cmd>vsplit<cr><c-w>l", { desc = "Vertical split" })
vim.keymap.set("n", "<leader>h", "<cmd>split<cr><c-w>j", { desc = "Horizontal split" })

-- Edit config files
vim.keymap.set("n", "<leader>ev", function()
	vim.cmd.edit(vim.fn.stdpath("config") .. "/init.lua")
end, { desc = "Edit vim config" })
vim.keymap.set("n", "<leader>ez", function()
	vim.cmd.edit("~/.zshrc")
end, { desc = "Edit zshrc" })
vim.keymap.set("n", "<leader>eg", function()
	vim.cmd.edit("~/Library/Application Support/com.mitchellh.ghostty/config")
end, { desc = "Edit ghostty config" })

-- Redraw and clear highlights
vim.keymap.set("n", "<leader>l", function()
	vim.cmd.redraw({ bang = true })
	vim.cmd.nohlsearch()
end, { desc = "Redraw and clear highlights" })

-- System clipboard yank in visual mode
vim.keymap.set("v", "<leader>y", '"+y', { desc = "Yank to system clipboard" })

-- File explorer
vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })

-- mini.pick keymaps
local pick = require("mini.pick").builtin
vim.keymap.set("n", "<leader>p", pick.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>b", pick.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>gg", pick.grep_live, { desc = "Live grep" })

vim.keymap.set("n", "<leader>*", function()
	pick.grep({ pattern = vim.fn.expand("<cword>") })
end, { desc = "Grep word under cursor" })

-- Pick files changed vs base branch (committed + staged + unstaged)
local function pick_changed_vs_base(base)
	base = base ~= "" and base or "master"

	local mb = vim.system({ "git", "merge-base", base, "HEAD" }, { text = true }):wait()
	if mb.code ~= 0 then
		vim.notify("merge-base " .. base .. " HEAD failed: " .. (mb.stderr or ""), vim.log.levels.ERROR)
		return
	end
	local merge_base = vim.trim(mb.stdout)

	-- Comparing working tree to merge-base catches all three:
	-- committed-on-branch, staged, and unstaged.
	local diff = vim.system({ "git", "diff", "--name-only", merge_base }, { text = true }):wait()
	if diff.code ~= 0 then
		vim.notify("git diff failed: " .. (diff.stderr or ""), vim.log.levels.ERROR)
		return
	end

	local files = vim.split(vim.trim(diff.stdout), "\n", { trimempty = true })
	if #files == 0 then
		vim.notify("No changes vs " .. base, vim.log.levels.INFO)
		return
	end

	require("mini.pick").start({
		source = {
			items = files,
			name = "Changed vs " .. base,
			cwd = vim.fn.getcwd(),
		},
	})
end

vim.api.nvim_create_user_command("PickChanged", function(opts)
	pick_changed_vs_base(opts.args)
end, { nargs = "?", desc = "Pick files changed vs base branch (default: master)" })

vim.keymap.set("n", "<leader>gc", function()
	pick_changed_vs_base("master")
end, { desc = "Pick files changed vs master" })

-- mini.extra diagnostic picker
vim.keymap.set("n", "<leader>xx", function()
	require("mini.extra").pickers.diagnostic()
end, { desc = "Show diagnostics" })

-- Diagnostic toggle keymap
vim.keymap.set("n", "<leader>d", function()
	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	local current_buf = vim.api.nvim_get_current_buf()

	if diagnostic_float_state.win_id and vim.api.nvim_win_is_valid(diagnostic_float_state.win_id) then
		-- Close and mark as dismissed
		vim.api.nvim_win_close(diagnostic_float_state.win_id, true)
		diagnostic_float_state.win_id = nil
		diagnostic_float_state.dismissed_line = current_line
		diagnostic_float_state.dismissed_buf = current_buf
	else
		-- Open and clear dismissed state
		local _, winnr = vim.diagnostic.open_float({ focus = false })
		diagnostic_float_state.win_id = winnr
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
		vim.cmd.quit()
	else
		vim.cmd.bdelete()
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

-- Render current buffer as markdown via glow, either in a tmux popup or split
local function glow_preview(target)
	if vim.fn.executable("glow") == 0 then
		vim.notify("glow not installed (macOS: brew install glow)", vim.log.levels.WARN)
		return
	end
	if vim.env.TMUX == nil then
		vim.notify("Not running inside tmux", vim.log.levels.WARN)
		return
	end
	local tmpfile = vim.fn.tempname() .. ".md"
	vim.fn.writefile(vim.api.nvim_buf_get_lines(0, 0, -1, false), tmpfile)
	local quoted = vim.fn.shellescape(tmpfile)
	local cmd = string.format("glow -p %s; rm -f %s", quoted, quoted)
	if target == "popup" then
		vim.system({ "tmux", "display-popup", "-E", "-w", "90%", "-h", "90%", cmd })
	else
		vim.system({ "tmux", "split-window", "-h", cmd })
	end
end

vim.keymap.set("n", "<leader>mp", function()
	glow_preview("popup")
end, { desc = "Markdown preview in tmux popup" })
vim.keymap.set("n", "<leader>ms", function()
	glow_preview("split")
end, { desc = "Markdown preview in tmux right split" })

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

-- Toggle inlay hints
vim.keymap.set("n", "<leader>ih", function()
	local enabled = vim.lsp.inlay_hint.is_enabled()
	vim.lsp.inlay_hint.enable(not enabled)
	vim.notify("Inlay hints " .. (enabled and "off" or "on"), vim.log.levels.INFO)
end, { desc = "Toggle inlay hints" })

-- ============================================================================
-- TEST RUNNER
-- ============================================================================

local test_commands = {
	rust = "cargo test",
	python = "pytest",
	javascript = "npm test",
	typescript = "npm test",
	go = "go test ./...",
	lua = "make test",
}

vim.keymap.set("n", "<leader>tt", function()
	local cmd = test_commands[vim.bo.filetype] or "make test"
	vim.cmd.botright("split | terminal " .. cmd)
end, { desc = "Run tests" })

vim.keymap.set("n", "<leader>tf", function()
	local ft = vim.bo.filetype
	local file = vim.fn.expand("%")
	local cmd
	if ft == "rust" then
		cmd = "cargo test"
	elseif ft == "python" then
		cmd = "pytest " .. file
	elseif ft == "go" then
		cmd = "go test -run . " .. vim.fn.expand("%:h")
	else
		cmd = test_commands[ft] or "make test"
	end
	vim.cmd.botright("split | terminal " .. cmd)
end, { desc = "Run tests for current file" })

-- Better indenting
vim.keymap.set("v", "<", "<gv", { desc = "Indent left" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right" })
