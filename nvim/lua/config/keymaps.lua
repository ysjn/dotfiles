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
vim.keymap.set("n", "<cr>", "<cr>")
vim.keymap.set("n", "q:", "<nop>", opts())
vim.keymap.set("v", "g?", "<nop>", opts())

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

-- yank to end of line
vim.keymap.set("n", "Y", "y$", opts("yank to end of line"))

-- use q as prefix
vim.keymap.set("n", "q", function()
  if vim.fn.reg_recording() == "" then
    vim.api.nvim_feedkeys("qq", "n", false)
  else
    vim.api.nvim_feedkeys("q", "n", false)
  end
end, opts("record macro"))
vim.keymap.set("n", "@", function()
  if vim.fn.reg_recording() == "" then
    vim.api.nvim_feedkeys("@q", "n", false)
  else
    vim.api.nvim_feedkeys("q@q", "n", false)
  end
end, opts("execute macro"))

-- Move caret to start/end of line
vim.keymap.set({ "n", "v" }, "<c-h>", "^", opts())
vim.keymap.set({ "n", "v" }, "<c-l>", "$", opts())

-- Close all buffer and open dashboard
vim.keymap.set(
  "n",
  "<leader>bx",
  "<Cmd>lua Snacks.bufdelete.all()<CR><Cmd>lua Snacks.dashboard()<CR>",
  opts("Close all buffer")
)
-- Mover buffers
vim.keymap.set("n", "<leader>b<", "<Cmd>BufferLineMovePrev<CR>", opts("Move buffer prev"))
vim.keymap.set("n", "<leader>b>", "<Cmd>BufferLineMoveNext<CR>", opts("Move buffer next"))

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
vim.keymap.set("n", "<leader>v", "<cmd>vsplit<CR><c-w>h<cmd>:bn<cr><c-w>l", opts("Split window right"))
vim.keymap.set("n", "<leader>h", "<cmd>split<CR>", opts("Split window below"))

-- Clear all marks
vim.keymap.set("n", "<A-m>", "<cmd>delm! | delm A-Z0-9<CR><cmd>wviminfo!<CR><cmd>echo 'Clear all marks'<CR>", opts())

-- Tree split join
vim.keymap.set("n", "<leader>j", require("treesj").toggle, opts("Split or Join"))

-- Marks
local marks = require("marks")
vim.keymap.set("n", "<c-m>", marks.set_next, opts("Set next available lowercase mark"))
vim.keymap.set("n", "m", marks.next, opts("Next mark"))
vim.keymap.set("n", "M", marks.prev, opts("Previous mark"))

local function get_current_oil_dir()
  local oil = require("oil")
  local cwd = oil.get_current_dir()
  if cwd == nil then
    cwd = LazyVim.root()
  else
    oil.close()
  end
  local short_cwd = require("plenary.path"):new(cwd):make_relative(LazyVim.root())
  return {
    cwd = cwd,
    results_title = "Results in " .. short_cwd .. "/",
  }
end

-- Use oil.nvim current directory to scope Telescope find_files
vim.keymap.set("n", "<leader><space>", function()
  require("telescope.builtin").find_files(get_current_oil_dir())
end, opts("Find Files"))
-- Use egrepify instead of default live_grep
vim.keymap.set("n", "<leader>/", function()
  require("telescope").extensions.egrepify.egrepify(get_current_oil_dir())
end, opts("Grep with args (root dir)"))

-- Oil
vim.keymap.set("n", "<leader>e", "<CMD>Oil --float<CR>", opts("Open parent directory (float)"))
vim.keymap.set("n", "<leader>E", function()
  local oil = require("oil")
  oil.open()
  vim.wait(1000, function()
    return oil.get_cursor_entry() ~= nil
  end)
  if oil.get_cursor_entry() then
    oil.open_preview()
  end
end, opts("Open parent directory"))

-- lazygit integration
-- @see: https://github.com/kdheepak/lazygit.nvim/issues/22#issuecomment-1815426074
local Util = require("lazyvim.util")

-- Function to check clipboard with retries
local function getRelativeFilepath(retries, delay)
  local relative_filepath
  for i = 1, retries do
    relative_filepath = vim.fn.getreg("+")
    if relative_filepath ~= "" then
      return relative_filepath -- Return filepath if clipboard is not empty
    end
    vim.loop.sleep(delay) -- Wait before retrying
  end
  return nil -- Return nil if clipboard is still empty after retries
end

-- Function to handle editing from Lazygit
function LazygitEdit(original_buffer)
  local current_bufnr = vim.fn.bufnr("%")
  local channel_id = vim.fn.getbufvar(current_bufnr, "terminal_job_id")

  if not channel_id then
    vim.notify("No terminal job ID found.", vim.log.levels.ERROR)
    return
  end

  vim.fn.chansend(channel_id, "\15") -- \15 is <c-o>
  vim.cmd("close") -- Close Lazygit

  local relative_filepath = getRelativeFilepath(5, 50)
  if not relative_filepath then
    vim.notify("Clipboard is empty or invalid.", vim.log.levels.ERROR)
    return
  end

  local winid = vim.fn.bufwinid(original_buffer)

  if winid == -1 then
    vim.notify("Could not find the original window.", vim.log.levels.ERROR)
    return
  end

  vim.fn.win_gotoid(winid)
  vim.cmd("e " .. relative_filepath)
end

-- Function to start Lazygit in a floating terminal
function StartLazygit()
  local current_buffer = vim.api.nvim_get_current_buf()
  local float_term = Snacks.terminal.open({ "lazygit" }, { cwd = Util.root(), esc_esc = false, ctrl_hjkl = false })

  vim.api.nvim_buf_set_keymap(
    float_term.buf,
    "t",
    "<c-e>",
    string.format([[<Cmd>lua LazygitEdit(%d)<CR>]], current_buffer),
    { noremap = true, silent = true }
  )
end

vim.api.nvim_set_keymap("n", "<leader>gg", [[<Cmd>lua StartLazygit()<CR>]], { noremap = true, silent = true })
