-- Run with: luajit rex/tests/attention-jump.lua
local root = assert(debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])"))
local actions, bindings, blocks, records, focused, queued, failure
local ctx = { session_id = "session:here", block_id = "block:here" }
local function block(id, placement)
	return { block_id = id, window_id = "window:" .. id, creator_name = "com.superlogical.terminal", placement = placement or "placed" }
end
local config = assert(loadfile(root .. "../init.lua"))
actions, bindings = {}, {}
setfenv(config, setmetatable({
	rex = {
		action = function(action) actions[action.name] = action.run end,
		bind = function(key, name) bindings[key] = name end,
		mode = function() end,
		call = function(method, args)
			if failure == method then return nil, "API failed" end
			if method == "session.attach_all" then
				assert(args.event_scope == "session")
				return { sessions = { { session_id = ctx.session_id }, { session_id = "session:other" } } }
			elseif method == "session.list_blocks" then
				return { blocks = blocks[args.session_id] }
			end
			assert(method == "session.focus_block")
			focused = args
			return {}
		end,
		block = { call = function(creator, method, args)
			assert(creator == "com.superlogical.terminal" and method == "program_status")
			assert(args.block_id ~= ctx.block_id, "Skip the currently focused pane")
			if failure == method then return nil, "API failed" end
			return { records = records[args.block_id] or {} }
		end },
		client = { queue = function(name, args)
			assert(name == "session.select" and focused, "Focus the target before showing its session")
			queued = args
		end },
	},
	dofile = function() return setmetatable({ setup = function() end }, { __call = function() end }) end,
}, { __index = _G }))
config()
assert(bindings["ctrl+k>k"] == "attention_jump")
local jump = assert(actions.attention_jump)
local function reset()
	blocks = {
		[ctx.session_id] = { block(ctx.block_id), block("block:old") },
		["session:other"] = { block("block:new"), block("block:detached", "detached") },
	}
	records = {
		["block:old"] = { { state = "blocked", updated_at = "2026-11-16T10:00:00+09:00" } },
		["block:new"] = { { state = "done", updated_at = "2026-11-16T11:00:00+09:00" } },
		["block:detached"] = { { state = "blocked", updated_at = "2026-11-16T12:00:00+09:00" } },
	}
	focused, queued, failure = nil, nil, nil
end

reset()
jump(ctx)
assert(focused.block_id == "block:old", "Blocked takes priority over a newer completed result")

reset()
records["block:new"][1].state = "blocked"
jump(ctx)
assert(focused.block_id == "block:new" and focused.session_id == "session:other")
assert(queued.session_id == focused.session_id and queued.window_id == "window:block:new")

for _, state in ipairs({ "done", "error" }) do
	reset()
	records["block:old"][1].state = state
	jump(ctx)
	assert(focused.block_id == "block:new", "Completed and failed results use newest-first order")
end

reset()
records["block:old"] = { { state = "working", updated_at = "2026-11-16T12:00:00Z" } }
records["block:new"] = { { state = "idle", updated_at = "2026-11-16T12:00:00Z" } }
jump(ctx)
assert(not focused and not queued, "Idle, working, current and detached panes do not cause a jump")

reset()
records["block:old"] = { { state = "working", updated_at = "2026-11-16T12:00:00Z" },
	{ id = "worker", state = "blocked", updated_at = "2026-11-16T10:00:00.1Z" } }
records["block:new"] = { { state = "blocked", updated_at = "2026-11-16T10:00:00.11Z" } }
jump(ctx)
assert(focused.block_id == "block:new", "Fractional seconds sort correctly")
records["block:new"][1].state = "unknown"
jump(ctx)
assert(focused.block_id == "block:old", "A blocked child record is actionable even while its parent works")

for _, method in ipairs({ "session.attach_all", "session.list_blocks", "program_status", "session.focus_block" }) do
	reset()
	failure = method
	local ok, err = pcall(jump, ctx)
	assert(not ok and tostring(err):find("API failed", 1, true) and not queued)
end
print("PASS: attention priority, newest-first order, cross-session focus, skipped panes, child status, and API errors")
