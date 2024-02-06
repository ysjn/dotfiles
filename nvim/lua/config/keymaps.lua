-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local opts = function(desc)
  return { noremap = true, silent = true, desc = desc }
end

-- remove default mapping
vim.keymap.del({ "i", "x", "n", "s" }, "<C-s>")
vim.keymap.del({ "n", "v" }, "s")
vim.keymap.del({ "n", "v" }, "S")

-- leap
vim.keymap.set("n", "f", function()
  require("leap").leap({ target_windows = { vim.api.nvim_get_current_win() } })
end)

-- send yanked text to black hole register
vim.keymap.set("v", "p", '"_dP', opts())
vim.keymap.set({ "n", "v" }, "dd", '"_dd', opts("Delete Line"))
vim.keymap.set({ "n", "v" }, "dh", '"_dh', opts("Delete Left"))
vim.keymap.set({ "n", "v" }, "dj", '"_dj', opts("Delete Down"))
vim.keymap.set({ "n", "v" }, "dk", '"_dk', opts("Delete Up"))
vim.keymap.set({ "n", "v" }, "dl", '"_dl', opts("Delete Right"))
vim.keymap.set({ "n", "v" }, "D", '"_D', opts("Delete Right"))

-- Move caret to start/end of line
vim.keymap.set({ "n", "v" }, "<c-h>", "^", opts())
vim.keymap.set({ "n", "v" }, "<c-l>", "$", opts())

vim.keymap.set("n", "<A-h>", "<cmd>TmuxNavigateLeft<CR>", opts())
vim.keymap.set("n", "<A-j>", "<cmd>TmuxNavigateDown<CR>", opts())
vim.keymap.set("n", "<A-k>", "<cmd>TmuxNavigateUp<CR>", opts())
vim.keymap.set("n", "<A-l>", "<cmd>TmuxNavigateRight<CR>", opts())

-- Clear all marks
vim.keymap.set("n", "<A-m>", "<cmd>delm! | delm A-Z0-9<CR><cmd>wviminfo!<CR><cmd>echo 'Clear all marks'<CR>", opts())
