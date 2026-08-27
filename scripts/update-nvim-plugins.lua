-- update-nvim-plugins.lua --- headless vim.pack update-all
--
-- Usage: nvim --headless -c 'luafile scripts/update-nvim-plugins.lua' -c 'qa!'
--
-- init.lua registers every plugin via vim.pack.add(), so this runs *after*
-- normal init sourcing and only has to drive the update. force = true skips
-- the confirmation buffer, which would otherwise block forever headlessly --
-- vim.pack.update() defaults to force = false and waits on :write / :quit.

local errors = {}
local orig_notify = vim.notify
vim.notify = function(msg, level, opts)
	if level and level >= vim.log.levels.ERROR then
		errors[#errors + 1] = tostring(msg)
	end
	return orig_notify(msg, level, opts)
end

local function revs()
	local out = {}
	for _, p in ipairs(vim.pack.get(nil, { info = false })) do
		out[p.spec.name] = p.rev
	end
	return out
end

local before = revs()
if vim.tbl_isempty(before) then
	io.stderr:write("vim.pack: no plugins registered — is init.lua being sourced?\n")
	vim.cmd("cquit 1")
end

local ok, err = pcall(vim.pack.update, nil, { force = true })
if not ok then
	errors[#errors + 1] = tostring(err)
end

local after = revs()
local changed, count = {}, 0
for name, rev in pairs(after) do
	count = count + 1
	local was = before[name]
	if was ~= rev then
		changed[#changed + 1] = string.format("  %s %s -> %s", name, was:sub(1, 8), rev:sub(1, 8))
	end
end
table.sort(changed)

if #errors > 0 then
	io.stderr:write("vim.pack: FAILED\n")
	for _, e in ipairs(errors) do
		io.stderr:write("  " .. e:gsub("\n", "\n  ") .. "\n")
	end
	vim.cmd("cquit 1")
end

if #changed == 0 then
	io.stdout:write(string.format("vim.pack: all %d plugins up to date\n", count))
else
	io.stdout:write(string.format("vim.pack: updated %d of %d plugins\n", #changed, count))
	io.stdout:write(table.concat(changed, "\n") .. "\n")
end
