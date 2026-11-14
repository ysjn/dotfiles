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

dofile(os.getenv("HOME") .. "/.local/share/rex/plugins/rex-copy-mode/copy-mode.lua").setup({
	key = false,
	nvim = os.getenv("HOME") .. "/dev/dotfiles/rex/copy-mode-nvim",
	rex = "/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex",
})
rex.bind("ctrl+shift+l", function(ctx)
	local process, err = rex.block.call("com.superlogical.terminal", "process", {
		session_id = ctx.session_id,
		block_id = ctx.block_id,
	})
	if not process then
		error(err or "Cannot determine the foreground process for copy mode", 0)
	end
	-- Codex owns its alternate-screen history, so it must receive the original key.
	-- shortcut: detects foreground Codex only; extend for SSH/tmux if needed.
	if process.foreground and process.foreground.name == "codex" then
		return false
	end
	local _, copy_err = rex.invoke("copy_mode")
	if copy_err then
		error(copy_err, 0)
	end
	return true
end)

-- Herdr-only: agent navigation (ctrl+k>p/n), attention jump (ctrl+k>k), Fingers (ctrl+k>f),
-- plugin manager (ctrl+k>ctrl+p), and Radar (ctrl+k>,) have no equivalent action.
-- Navigate-mode keys stay unbound so ordinary terminal input is preserved.

rex.mode("resize", { exclusive = true })
rex.bind("ctrl+k>r", "client.mode.enter", { name = "resize" })
rex.bind("resize/h", "pane.resize", { direction = "left" })
rex.bind("resize/j", "pane.resize", { direction = "down" })
rex.bind("resize/k", "pane.resize", { direction = "up" })
rex.bind("resize/l", "pane.resize", { direction = "right" })
rex.bind("resize/enter", "client.mode.exit")
rex.bind("resize/escape", "client.mode.exit")

rex.mode("sidebar", { exclusive = true })
rex.bind("ctrl+k>g", "client.mode.enter", { name = "sidebar" })
rex.bind("sidebar/j", "client.tab.next")
rex.bind("sidebar/ctrl+n", "client.tab.next")
rex.bind("sidebar/k", "client.tab.previous")
rex.bind("sidebar/ctrl+p", "client.tab.previous")
rex.bind("sidebar/cmd+.", "client.sidebar.activity.toggle")
rex.bind("sidebar/enter", "client.mode.exit")
rex.bind("sidebar/escape", "client.mode.exit")
