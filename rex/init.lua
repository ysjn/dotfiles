rex.bind("ctrl+k>v", "pane.split.right")
rex.bind("ctrl+k>h", "pane.split.down")
rex.bind("ctrl+k>z", "pane.zoom")
rex.bind("ctrl+k>x", "pane.close")

rex.bind("ctrl+k>c", "session.new")
rex.bind("ctrl+k>shift+p", "session.previous")
rex.bind("ctrl+k>shift+n", "session.next")

rex.action({
	name = "session_goto_number",
	title = "Go to Session Number",
	args = {
		type = "object",
		properties = { index = { type = "integer", minimum = 1, maximum = 9 } },
		required = { "index" },
		additionalProperties = false,
	},
	run = function(ctx, args)
		local result, err = rex.call("session.list")
		if err ~= nil then
			error(err, 0)
		end
		-- Resolve the server's current session order each time, including reordering.
		local session = (result.sessions or {})[args.index]
		if session then
			rex.client.queue("session.select", { session_id = session.session_id })
		end
	end,
})

for index = 1, 9 do
	rex.bind("ctrl+k>" .. index, "session_goto_number", { index = index })
end

dofile(os.getenv("HOME") .. "/.local/share/nvim/lazy/smart-splits-backend-rex/rex/lua/smart-splits-rex/init.lua").setup()
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind("alt+" .. key, "smart_splits_focus", { direction = direction, key = "alt+" .. key })
	rex.bind("alt+shift+" .. key, "smart_splits_resize", { direction = direction, key = "alt+shift+" .. key })
end

rex.bind("ctrl+k>shift+h", "pane.move.left")
rex.bind("ctrl+k>shift+j", "pane.move.down")
rex.bind("ctrl+k>shift+k", "pane.move.up")
rex.bind("ctrl+k>shift+l", "pane.move.right")

rex.bind("ctrl+k>shift+e", "pane.balance")
rex.bind("shift+cmd+p", "client.palette.toggle")

-- Herdr-only: copy mode (ctrl+k>[, ctrl+u)
-- agent navigation (ctrl+k>p/n), attention jump (ctrl+k>k), Fingers (ctrl+k>f),
-- plugin manager (ctrl+k>ctrl+p), and Radar (ctrl+k>,) have no equivalent action.
-- Navigate-mode keys stay unbound so ordinary terminal input is preserved.

rex.mode("repeat", { exclusive = true })
rex.bind("ctrl+k>r", "client.mode.enter", { name = "repeat" })
rex.bind("repeat/h", "pane.resize", { direction = "left" })
rex.bind("repeat/j", "pane.resize", { direction = "down" })
rex.bind("repeat/k", "pane.resize", { direction = "up" })
rex.bind("repeat/l", "pane.resize", { direction = "right" })
rex.bind("repeat/enter", "client.mode.exit")
rex.bind("repeat/escape", "client.mode.exit")
