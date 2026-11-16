rex.bind("ctrl+k>v", "pane.split.right")
rex.bind("ctrl+k>h", "pane.split.down")
rex.bind("ctrl+k>z", "pane.zoom")

local confirming_sessions = {}
rex.action({
	name = "close_pane_or_session",
	title = "Close Pane or Session",
	run = function(ctx)
		if not ctx.session_id or not ctx.block_id then
			error("閉じるpaneを特定できません。", 0)
		end
		if confirming_sessions[ctx.session_id] then
			return
		end
		local result, err = rex.call("session.list_blocks", { session_id = ctx.session_id })
		if not result then
			error(err, 0)
		end
		if #result.blocks > 1 then
			rex.client.queue("pane.close")
			return
		end
		if #result.blocks ~= 1 or result.blocks[1].block_id ~= ctx.block_id then
			error("閉じるpaneの構成が変わりました。", 0)
		end
		local view, view_err = rex.call("session.view", { session_id = ctx.session_id })
		if not view then
			error(view_err, 0)
		end
		confirming_sessions[ctx.session_id] = true
		local ok, confirmation, exec_err = pcall(rex.exec, {
			"/usr/bin/osascript",
			"-e",
			[[on run argv
try
	set answer to display dialog "セッション「" & (item 1 of argv) & "」を閉じますか？" & return & "最後のpaneと、そこで実行中の処理を終了します。" with title "Rex" buttons {"キャンセル", "閉じる"} default button "閉じる" cancel button "キャンセル" giving up after 20
	if gave up of answer then return "cancel"
	return "close"
on error number -128
	return "cancel"
end try
end run]],
			view.label or "無題",
		}, { timeout = 25 })
		confirming_sessions[ctx.session_id] = nil
		if not ok then
			error(confirmation, 0)
		end
		if not confirmation then
			error(exec_err, 0)
		end
		if confirmation.timed_out then
			return
		end
		if not confirmation.ok then
			error(confirmation.stderr, 0)
		end
		if not confirmation.stdout:match("^close%s*$") then
			return
		end
		result, err = rex.call("session.list_blocks", { session_id = ctx.session_id })
		if not result then
			error(err, 0)
		end
		if #result.blocks ~= 1 or result.blocks[1].block_id ~= ctx.block_id then
			error("確認中にpane構成が変わったため、閉じませんでした。", 0)
		end
		local closed, close_err = rex.call("session.destroy", { session_id = ctx.session_id })
		if not closed then
			error(close_err, 0)
		end
	end,
})
rex.bind("ctrl+k>x", "close_pane_or_session")

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

dofile("/opt/homebrew/opt/rexflash/share/rexflash/rexflash.lua")({
	hint_key = "ctrl+k>f",
	flash_key = "ctrl+k>/",
})

rex.action({
	name = "attention_jump",
	title = "Jump to Agent Needing Attention",
	run = function(ctx)
		local sessions, err = rex.call("session.attach_all", { event_scope = "session" })
		if not sessions then
			error(err, 0)
		end
		local priority = { blocked = 1, error = 2, done = 2 }
		local target
		for _, session in ipairs(sessions.sessions or {}) do
			local result, list_err = rex.call("session.list_blocks", { session_id = session.session_id })
			if not result then
				error(list_err, 0)
			end
			for _, block in ipairs(result.blocks or {}) do
				if
					block.creator_name == "com.superlogical.terminal"
					and block.placement == "placed"
					and block.block_id ~= ctx.block_id
				then
					local status, status_err = rex.block.call("com.superlogical.terminal", "program_status", {
						session_id = session.session_id,
						block_id = block.block_id,
					})
					if not status then
						error(status_err, 0)
					end
					for _, record in ipairs(status.records or {}) do
						local rank = priority[record.state]
						-- Reports share the server's timezone; strip it to compare fractional seconds.
						local updated = record.updated_at:gsub("Z$", ""):gsub("[+-]%d%d:%d%d$", "")
						if
							rank
							and (not target or rank < target.rank or (rank == target.rank and updated > target.updated))
						then
							target = {
								session_id = session.session_id,
								window_id = block.window_id,
								block_id = block.block_id,
								rank = rank,
								updated = updated,
							}
						end
					end
				end
			end
		end
		if target then
			local focused, focus_err = rex.call("session.focus_block", {
				session_id = target.session_id,
				block_id = target.block_id,
			})
			if not focused then
				error(focus_err, 0)
			end
			rex.client.queue("session.select", { session_id = target.session_id, window_id = target.window_id })
		end
	end,
})
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
