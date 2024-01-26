-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local opts = { noremap = true, silent = true }

-- remove default mapping
vim.keymap.del({ "i", "x", "n", "s" }, "<C-s>")

-- send yanked text to black hole register
vim.keymap.set("v", "p", '"_dP', opts)
vim.keymap.set({ "n", "v" }, "dd", '"_dd', opts)

-- Move caret to start/end of line
vim.keymap.set({ "n", "v" }, "<c-h>", "^", opts)
vim.keymap.set({ "n", "v" }, "<c-l>", "$", opts)

vim.keymap.set("n", "<A-h>", "<cmd>TmuxNavigateLeft<CR>", opts)
vim.keymap.set("n", "<A-j>", "<cmd>TmuxNavigateDown<CR>", opts)
vim.keymap.set("n", "<A-k>", "<cmd>TmuxNavigateUp<CR>", opts)
vim.keymap.set("n", "<A-l>", "<cmd>TmuxNavigateRight<CR>", opts)
