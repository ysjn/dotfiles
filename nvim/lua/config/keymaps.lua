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

vim.keymap.del("n", "<leader>|")
vim.keymap.del("n", "<leader>-")

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

-- Move Lines
vim.keymap.set("n", "<A-C-k>", "<cmd>m .-2<cr>==", opts("Move up"))
vim.keymap.set("n", "<A-C-j>", "<cmd>m .+1<cr>==", opts("Move down"))
vim.keymap.set("i", "<A-C-j>", "<esc><cmd>m .+1<cr>==gi", opts("Move down"))
vim.keymap.set("i", "<A-C-k>", "<esc><cmd>m .-2<cr>==gi", opts("Move up"))
vim.keymap.set("v", "<A-C-j>", ":m '>+1<cr>gv=gv", opts("Move down"))
vim.keymap.set("v", "<A-C-k>", ":m '<-2<cr>gv=gv", opts("Move up"))

-- Move between splits in NeoVim windows and Tmux panes
vim.keymap.set("n", "<A-h>", "<cmd>TmuxNavigateLeft<CR>", opts())
vim.keymap.set("n", "<A-j>", "<cmd>TmuxNavigateDown<CR>", opts())
vim.keymap.set("n", "<A-k>", "<cmd>TmuxNavigateUp<CR>", opts())
vim.keymap.set("n", "<A-l>", "<cmd>TmuxNavigateRight<CR>", opts())

-- Resize splits for NeoVim windows Panes and Tmux panes
vim.keymap.set("n", "<A-H>", "<cmd>TmuxResizeLeft<CR>", opts())
vim.keymap.set("n", "<A-J>", "<cmd>TmuxResizeDown<CR>", opts())
vim.keymap.set("n", "<A-K>", "<cmd>TmuxResizeUp<CR>", opts())
vim.keymap.set("n", "<A-L>", "<cmd>TmuxResizeRight<CR>", opts())

-- Split windows
vim.keymap.set("n", "<leader>v", "<cmd>vsplit<CR>", opts("Split window right"))
vim.keymap.set("n", "<leader>h", "<cmd>split<CR>", opts("Split window below"))
-- Cannot override <leader>/ @see: https://github.com/LazyVim/LazyVim/issues/63#issuecomment-1383718679
-- vim.keymap.set("n", "<leader>/", "<cmd>Telescope live_grep_args<CR>", opts("Grep with args (root dir)"))
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep_args<CR>", opts("Grep with args (root dir)"))
-- Clear all marks
vim.keymap.set("n", "<A-m>", "<cmd>delm! | delm A-Z0-9<CR><cmd>wviminfo!<CR><cmd>echo 'Clear all marks'<CR>", opts())
