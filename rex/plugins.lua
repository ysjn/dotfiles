dofile(os.getenv("HOME") .. "/.local/share/nvim/lazy/smart-splits-backend-rex/rex/lua/smart-splits-rex/init.lua").setup()

dofile(os.getenv("HOME") .. "/.local/share/rex/plugins/rex-copy-mode/copy-mode.lua").setup({
	key = false,
	nvim = os.getenv("HOME") .. "/dev/dotfiles/rex/copy-mode-nvim",
	rex = "/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex",
})

dofile("/opt/homebrew/opt/rexflash/share/rexflash/rexflash.lua")({
	bin = os.getenv("HOME") .. "/dev/rexflash/target/release/rexflash",
})

return {
	copy_mode = function(ctx)
		local process, err = rex.block.call("com.superlogical.terminal", "process", {
			session_id = ctx.session_id,
			block_id = ctx.block_id,
		})
		if not process then
			error(err or "Cannot determine the foreground process for copy mode", 0)
		end
		-- Codex owns its alternate-screen history, so it must receive the original key.
		-- shortcut: detects foreground Codex only; extend for SSH if needed.
		if process.foreground and process.foreground.name == "codex" then
			return false
		end
		local _, copy_err = rex.invoke("copy_mode")
		if copy_err then
			error(copy_err, 0)
		end
		return true
	end,
}
