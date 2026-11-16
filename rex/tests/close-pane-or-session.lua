-- Run with: luajit rex/tests/close-pane-or-session.lua
local root = assert(debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])"))
local actions, bindings = {}, {}
local ctx = { session_id = "session:test", block_id = "block:current" }
local current = { block_id = ctx.block_id, window_id = "window:first" }
local other = { block_id = "block:other", window_id = "window:second", placement = "detached" }
local blocks, after_dialog, lookups, queued, prompts, destroyed, exec_result, call_error, on_prompt, exec_throw
local label = [[名前 "quoted"; $(not-a-command)]]
local config = assert(loadfile(root .. "../actions.lua"))
setfenv(config, setmetatable({
	rex = {
		bind = function(key, name) bindings[key] = name end,
		action = function(action) actions[action.name] = action.run end,
		mode = function() end,
		call = function(method, args)
			assert(args.session_id == ctx.session_id, "Always target the original session")
			if method == "session.list_blocks" then
				lookups = lookups + 1
				if call_error == lookups then return nil, "lookup failed" end
				return { blocks = lookups > 1 and after_dialog or blocks }
			elseif method == "session.view" then
				if call_error == "view" then return nil, "view failed" end
				return { label = label }
			end
			assert(method == "session.destroy")
			destroyed = destroyed + 1
			return {}
		end,
		client = { queue = function(name)
			assert(name == "pane.close")
			queued = queued + 1
		end },
		exec = function(argv, opts)
			prompts = prompts + 1
			assert(argv[1] == "/usr/bin/osascript" and argv[2] == "-e")
			assert(argv[4] == label and not argv[3]:find(label, 1, true), "Pass labels as data, never AppleScript code")
			assert(argv[3]:find('default button "閉じる"', 1, true))
			assert(argv[3]:find('cancel button "キャンセル"', 1, true))
			assert(argv[3]:find("giving up after 20", 1, true) and opts.timeout == 25)
			if on_prompt then on_prompt() end
			if exec_throw then error("exec threw") end
			return exec_result, "could not start dialog"
		end,
	},
}, { __index = _G }))
config()
local keybindings = assert(loadfile(root .. "../keybindings.lua"))
setfenv(keybindings, getfenv(config))()({ copy_mode = function() end })
assert(bindings["ctrl+k>x"] == "close_pane_or_session")
local close = assert(actions.close_pane_or_session)
local function reset()
	blocks, after_dialog = { current }, nil
	lookups, queued, prompts, destroyed = 0, 0, 0, 0
	exec_result = { ok = true, stdout = "close\n" }
	call_error, on_prompt, exec_throw = nil, nil, nil
end
local function fails()
	assert(not pcall(close, ctx), "Expected safe failure")
	assert(destroyed == 0 and queued == 0)
end

reset()
blocks = { current, other }
close(ctx)
assert(queued == 1 and prompts == 0 and destroyed == 0, "Other tabs and detached panes must prevent session closure")

reset()
close(ctx)
assert(prompts == 1 and destroyed == 1 and queued == 0 and lookups == 2)

for _, response in ipairs({ "cancel\n", "", "close\nextra" }) do
	reset()
	exec_result.stdout = response
	close(ctx)
	assert(destroyed == 0 and queued == 0 and lookups == 1, "Only explicit approval may close a session")
end

reset()
exec_result = { ok = false, timed_out = true }
close(ctx)
assert(destroyed == 0 and queued == 0)

for _, failure in ipairs({ 1, 2, "view" }) do
	reset()
	call_error = failure
	fails()
end

for _, changed in ipairs({ {}, { current, other }, { other } }) do
	reset()
	after_dialog = changed
	fails()
end

reset()
blocks = { other }
fails()
assert(prompts == 0)

reset()
exec_result = nil
fails()
reset()
exec_result = { ok = false, stderr = "dialog failed" }
fails()
reset()
exec_throw = true
fails()
reset()
close(ctx)
assert(destroyed == 1, "Dialog failures must release the pending guard")

reset()
on_prompt = function() close(ctx) end
close(ctx)
assert(prompts == 1 and destroyed == 1, "Repeated keys must not open concurrent confirmations")

reset()
assert(not pcall(close, {}))
assert(lookups == 0 and destroyed == 0)
print("PASS: pane closure, explicit approval, cancellation, timeout, changing layouts, lookup errors, and repeated keys")
