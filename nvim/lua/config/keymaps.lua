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
vim.keymap.set("v", "p", '"_dP', opts("Paste"))
vim.keymap.set({ "n", "v" }, "d", '"_d', opts("Delete"))
vim.keymap.set({ "n", "v" }, "D", '"_D', opts("Delete Right"))
vim.keymap.set({ "n", "v" }, "s", '"_s', opts("Delete"))
vim.keymap.set({ "n", "v" }, "S", '"_S', opts("Delete Right"))
vim.keymap.set({ "n", "v" }, "c", '"_c', opts("Change"))
vim.keymap.set({ "n", "v" }, "C", '"_C', opts("Change Right"))

-- Move caret to start/end of line
vim.keymap.set({ "n", "v" }, "<c-h>", "^", opts())
vim.keymap.set({ "n", "v" }, "<c-l>", "$", opts())

-- Move page up/down then re-center buffer
vim.keymap.set("n", "<c-u>", "<c-u>zz", opts())
vim.keymap.set("n", "<c-d>", "<c-d>zz", opts())

-- Close all buffer and open dashboard
vim.keymap.set("n", "<leader>bx", "<Cmd>%bd<CR><Cmd>Dashboard<CR>", opts("Close all buffer"))

-- Re-open most recent buffer
vim.keymap.set("n", "<leader>bz", "<c-o>", opts("Close all buffer"))

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

-- Use egrepify instead of default live_grep
vim.keymap.set("n", "<leader>/", function()
  require("telescope").extensions.egrepify.egrepify({ cwd = LazyVim.root() })
end, opts("Grep with args (root dir)"))

-- Clear all marks
vim.keymap.set("n", "<A-m>", "<cmd>delm! | delm A-Z0-9<CR><cmd>wviminfo!<CR><cmd>echo 'Clear all marks'<CR>", opts())

-- Tree split join
vim.keymap.set("n", "<leader>j", require("treesj").toggle, opts("Split or Join"))

-- Marks
local marks = require("marks")
vim.keymap.set("n", "<c-m>", marks.set_next, opts("Set next available lowercase mark"))
vim.keymap.set("n", "m", marks.next, opts("Next mark"))
vim.keymap.set("n", "M", marks.prev, opts("Previous mark"))

-- Oil
vim.keymap.set("n", "<leader>e", "<CMD>Oil --float<CR>", opts("Open parent directory (float)"))
vim.keymap.set("n", "<leader>E", "<CMD>Oil<CR>", opts("Open parent directory"))
