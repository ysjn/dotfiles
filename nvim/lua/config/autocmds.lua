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
  group = vim.api.nvim_create_augroup("RefocusFloatSimple", { clear = true }),
  desc = "Refocus Lazygit or fzf-lua input terminal when coming back from tmux pane",
  callback = function()
    -- コマンドライン編集中は奪わない
    if vim.api.nvim_get_mode().mode == "c" then
      return
    end

    local best_win, best_z = nil, -1

    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg and cfg.relative ~= "" and cfg.focusable ~= false then -- float & フォーカス可
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_is_valid(buf) then
          local bt = vim.bo[buf].buftype
          local ft = vim.bo[buf].filetype
          local name = (vim.api.nvim_buf_get_name(buf) or ""):lower()
          local z = tonumber(cfg.zindex) or 0

          local is_lazygit = ft == "lazygit" or name:find("lazygit", 1, true)
          local is_fzf = ft == "fzf" or ft == "fzf-lua" or name:find("fzf", 1, true)

          -- Lazygit はそのまま対象、fzf は "入力側(terminal)" のみ対象
          local is_target = is_lazygit or (is_fzf and bt == "terminal")

          if is_target and z > best_z then
            best_win, best_z = win, z
          end
        end
      end
    end

    if best_win and best_win ~= vim.api.nvim_get_current_win() then
      pcall(vim.api.nvim_set_current_win, best_win)
      -- 入力系なので insert 開始
      pcall(vim.cmd, "startinsert")
    end
  end,
})
