-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "json", "jsonc" },
  callback = function()
    vim.wo.spell = false
    vim.wo.conceallevel = 0
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "GitConflictDetected",
  callback = function()
    vim.notify("Conflict detected in " .. vim.fn.expand("<afile>"))
    vim.keymap.set("n", "cww", function()
      engage.conflict_buster()
      create_buffer_local_mappings()
    end)
  end,
})

vim.api.nvim_create_autocmd("CmdwinEnter", {
  callback = function()
    vim.keymap.set("n", "q", "<Cmd>quit<CR>", { noremap = true, silent = true })
    vim.keymap.set("n", "<esc>", "<Cmd>quit<CR>", { noremap = true, silent = true })
  end,
})

vim.api.nvim_create_autocmd("CmdwinLeave", {
  callback = function()
    vim.keymap.del("n", "q")
    vim.keymap.del("n", "<esc>")
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ConsoleLog", { clear = true }),
  pattern = "javascript,javascriptreact,typescript,typescriptreact",
  callback = function()
    vim.keymap.set("n", "<c-c>", "A<CR>console.log()<Esc>i")
    vim.keymap.set("i", "<c-c>", "<Esc>Aconsole.log()<Esc>i")
    vim.keymap.set("x", "<c-c>", "yA<CR>console.log(`<Esc>pA: `, <Esc>pA)<Esc>")
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("BiomeFormat", { clear = true }),
  pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local configFound = vim.fs.find({ "biome.json" }, { path = filename, upward = true })[1]

    if configFound then
      vim.defer_fn(function()
        local cmd = { "biome", "check", "--write", filename }
        local cwd = vim.fs.dirname(configFound)

        vim.system(cmd, {
          cwd = cwd,
        }, function(obj)
          if obj.code == 0 then
            vim.schedule(function()
              vim.cmd("checktime")
            end)
          end
        end)
      end, 100)
    end
  end,
})

vim.api.nvim_create_autocmd("FocusGained", {
  desc = "Focus visible Snacks Lazygit float, when coming back from other tmux pane",
  callback = function()
    if vim.api.nvim_get_mode().mode == "c" then
      return
    end
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg and cfg.relative ~= "" then
        local buf = vim.api.nvim_win_get_buf(win)
        local name = (vim.api.nvim_buf_get_name(buf) or ""):lower()
        if name:find("lazygit", 1, true) then
          pcall(vim.api.nvim_set_current_win, win)
          pcall(vim.cmd, "startinsert")
          break
        end
      end
    end
  end,
})
