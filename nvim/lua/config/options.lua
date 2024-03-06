-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.breakindent = true
vim.opt.scrolloff = 15
vim.opt.foldmethod = "indent"

vim.diagnostic.config({
  float = {
    header = false,
    border = "rounded",
    focusable = false,
  },
})
