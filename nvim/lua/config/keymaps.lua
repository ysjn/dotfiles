-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- disable leap
vim.keymap.del("n", "s")
vim.keymap.del("n", "S")

-- Telescope file_browser
vim.keymap.set("n", "<Space>fb", "<Cmd>Telescope file_browser<CR>", { desc = "file browser" })
