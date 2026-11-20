-- Run with: luajit rex/tests/copy-mode-routing.lua
local root = assert(debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])"))
local bindings, options = {}, nil
local process, process_error, invoke_error, invoked = nil, nil, nil, 0
local context = { session_id = "test-session", block_id = "test-block" }
local config = assert(loadfile(root .. "../plugins.lua"))
setfenv(
	config,
	setmetatable({
		rex = {
			bind = function(key, fn)
				bindings[key] = fn
			end,
			action = function() end,
			mode = function() end,
			block = {
				call = function(creator, method, args)
					assert(creator == "com.superlogical.terminal" and method == "process")
					assert(args.session_id == context.session_id and args.block_id == context.block_id)
					return process, process_error
				end,
			},
			invoke = function(name)
				assert(name == "copy_mode")
				invoked = invoked + 1
				return {}, invoke_error
			end,
		},
		dofile = function(file)
			if file:match("/rexflash%.lua$") then
				return function(value)
					assert(not value.hint_key and not value.flash_key, "Plugin shortcuts belong in keybindings.lua")
					assert(value.bin == os.getenv("HOME") .. "/dev/dotfiles/rex/rexflash")
					assert(value.main_action == '"' .. value.bin .. '" --open')
					assert(value.ctrl_action == ":paste:" and value.shift_action == ":copy:")
				end
			end
			return {
				setup = function(value)
					if file:match("/copy%-mode%.lua$") then
						options = value
					else
						assert(file:match("/smart%-splits%-rex/init%.lua$"))
					end
				end,
			}
		end,
	}, { __index = _G })
)
local plugins = config()
local keybindings = assert(loadfile(root .. "../keybindings.lua"))
setfenv(keybindings, getfenv(config))()(plugins)
assert(options and options.key == false, "The plugin must not install its default shortcut")
assert(bindings["f6"] == nil and bindings["ctrl+a>enter"] == nil)
local route = assert(bindings["ctrl+shift+l"])
process = { foreground = { name = "codex" } }
assert(route(context) == false and invoked == 0, "Codex must receive the original key")
process = { foreground = { name = "zsh" } }
assert(route(context) == true and invoked == 1, "Shell must open Rex copy mode")
process = { last_exit = { exit_code = 0 } }
assert(route(context) == true and invoked == 2, "Exited terminals must remain copyable")
process, process_error = nil, "process lookup failed"
local ok, err = pcall(route, context)
assert(not ok and tostring(err):find(process_error, 1, true) and invoked == 2)
process, process_error, invoke_error = {}, nil, "copy mode failed"
ok, err = pcall(route, context)
assert(not ok and tostring(err):find(invoke_error, 1, true))
print("PASS: Ctrl+Shift+L passes through to Codex, opens copy mode elsewhere, and reports errors")
