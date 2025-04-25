local prefill_edit_window = function(request)
  require("avante.api").edit()
  local code_bufnr = vim.api.nvim_get_current_buf()
  local code_winid = vim.api.nvim_get_current_win()
  if code_bufnr == nil or code_winid == nil then
    return
  end
  vim.api.nvim_buf_set_lines(code_bufnr, 0, -1, false, { request })
  vim.api.nvim_win_set_cursor(code_winid, { 1, #request + 1 })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-s>", true, true, true), "v", true)
end

local avante_actions = {
  write_comment = "Add concise comments in Japanese above the properties and functions.",
  refactor_code = "Refactor this code to be more readable and efficient.",
}

vim.keymap.set("v", "<leader>aj", function()
  prefill_edit_window(avante_actions.write_comment)
end, { desc = "avente: Add comments" })

vim.keymap.set("v", "<leader>ar", function()
  prefill_edit_window(avante_actions.refactor_code)
end, { desc = "avente: Refactor code" })

return {}
