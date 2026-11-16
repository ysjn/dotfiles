return function(plugins)
	rex.bind("ctrl+k>v", "pane.split.right")
	rex.bind("ctrl+k>h", "pane.split.down")
	rex.bind("ctrl+k>z", "pane.zoom")
	rex.bind("ctrl+k>x", "close_pane_or_session")

	rex.bind("ctrl+k>c", "session.new")
	rex.bind("ctrl+k>shift+p", "session.previous")
	rex.bind("ctrl+k>shift+n", "session.next")

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

	rex.mode("sidebar", { exclusive = true })
	rex.bind("ctrl+k>g", "client.mode.enter", { name = "sidebar" })
	rex.bind("sidebar/j", "client.tab.next")
	rex.bind("sidebar/k", "client.tab.previous")
	rex.bind("sidebar/enter", "client.mode.exit")
	rex.bind("sidebar/escape", "client.mode.exit")
end
