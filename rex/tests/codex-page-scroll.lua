-- Run with: luajit rex/tests/codex-page-scroll.lua
local root = assert(debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])"))
local bindings, sent = {}, {}
local context = { session_id = "test-session", block_id = "test-block" }
local process, process_error, lookups, write_fails, write_error
local keybindings = assert(loadfile(root .. "../keybindings.lua"))
setfenv(keybindings, setmetatable({
	rex = {
		bind = function(key, fn) bindings[key] = fn end,
		mode = function() end,
		block = { call = function(creator, method, args)
			assert(creator == "com.superlogical.terminal")
			assert(args.session_id == context.session_id and args.block_id == context.block_id)
			if method == "process" then
				lookups = lookups + 1
				return process, process_error
			end
			assert(method == "write" and type(args.args.data) == "string")
			if write_fails then return nil, write_error end
			sent[#sent + 1] = args.args.data
			return { bytes_written = #args.args.data }
		end },
		client = { queue = function()
			error("rex.client.queue: a key handler cannot queue client actions")
		end },
	},
}, { __index = _G }))
keybindings()({ copy_mode = function() end })

for key, page in pairs({ b = "\27[5~", f = "\27[6~" }) do
	local scroll = assert(bindings["ctrl+" .. key])
	process, process_error, lookups, sent = { foreground = { name = "codex" } }, nil, 0, {}
	assert(scroll(context) == true and #sent == 1 and sent[1] == page:rep(3), "Each shortcut must send three line-scroll keys")

	for _, name in ipairs({ "zsh", "nvim", "ssh" }) do
		process, sent = { foreground = { name = name } }, {}
		assert(scroll(context) == false and #sent == 0, "Other programs must receive the original key")
	end
	process = { last_exit = { exit_code = 0 } }
	assert(scroll(context) == false and #sent == 0)
	lookups = 0
	assert(scroll({}) == false and lookups == 0, "No pane means no lookup or key injection")

	process, process_error = nil, "process lookup failed"
	local ok, err = pcall(scroll, context)
	assert(not ok and tostring(err):find(process_error, 1, true) and #sent == 0)
	process_error = nil
	ok, err = pcall(scroll, context)
	assert(not ok and tostring(err):find("Cannot determine the foreground process", 1, true))

	process, write_fails, write_error = { foreground = { name = "codex" } }, true, "write failed"
	ok, err = pcall(scroll, context)
	assert(not ok and tostring(err):find(write_error, 1, true) and #sent == 0)
	write_error = nil
	ok, err = pcall(scroll, context)
	assert(not ok and tostring(err):find("Cannot send page key to Codex", 1, true) and #sent == 0)
	write_fails = false
end
print("PASS: Codex three-line key bytes, other-program passthrough, key-handler API restrictions, and lookup/write errors")
