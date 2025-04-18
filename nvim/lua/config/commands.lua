vim.api.nvim_create_user_command("ApplyMacro", function(opts)
  local rangeStart = opts.line1
  local rangeEnd = opts.line2
  local register = "q"
  vim.cmd(string.format("%d,%dnormal! @%s", rangeStart, rangeEnd, register))
end, { range = true })
