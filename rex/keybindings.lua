return function(plugins)
	rex.bind("ctrl+k>v", "pane.split.right")
	rex.bind("ctrl+k>shift+v", "pane.split.left")
	rex.bind("ctrl+k>h", "pane.split.down")
	rex.bind("ctrl+k>z", "pane.zoom")
	rex.bind("ctrl+k>x", "close_pane_or_session")

	rex.bind("ctrl+k>c", "session.new")

	for index = 1, 9 do
		rex.bind("ctrl+k>" .. index, "session_goto_number", { index = index })
	end

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

	rex.bind("ctrl+shift+l", plugins.copy_mode)
	-- TODO: shortcut: Codex main-view scroll keys are fixed, migrate to Codex keymap settings once supported.
	for key, page in pairs({ b = "\27[5~", f = "\27[6~" }) do
		rex.bind("ctrl+" .. key, function(ctx)
			if not ctx.block_id then
				return false
			end
			local process, err = rex.block.call("com.superlogical.terminal", "process", {
				session_id = ctx.session_id,
				block_id = ctx.block_id,
			})
			if not process then
				error(err or "Cannot determine the foreground process for page scrolling", 0)
			end
			if not process.foreground or process.foreground.name ~= "codex" then
				return false
			end
			local written, write_err = rex.block.call("com.superlogical.terminal", "write", {
				session_id = ctx.session_id,
				block_id = ctx.block_id,
				args = { data = page:rep(3) },
			})
			if not written then
				error(write_err or "Cannot send page key to Codex", 0)
			end
			return true
		end)
	end
	rex.bind("ctrl+k>f", "rexflash_hint")
	rex.bind("ctrl+k>/", "rexflash_flash")
	rex.bind("ctrl+k>k", "attention_jump")

	rex.mode("resize", { exclusive = true })
	rex.bind("ctrl+k>r", "client.mode.enter", { name = "resize" })
	rex.bind("resize/h", "pane.resize", { direction = "left" })
	rex.bind("resize/j", "pane.resize", { direction = "down" })
	rex.bind("resize/k", "pane.resize", { direction = "up" })
	rex.bind("resize/l", "pane.resize", { direction = "right" })
	rex.bind("resize/enter", "client.mode.exit")
	rex.bind("resize/escape", "client.mode.exit")

	rex.bind("alt+j", "client.tab.next")
	rex.bind("alt+k", "client.tab.previous")
end
