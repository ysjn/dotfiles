vim.opt.breakindent = true
vim.opt.scrolloff = 30
vim.opt.foldmethod = "indent"

-- set root to .git or cwd
vim.g.root_spec = { ".git", "cwd" }

vim.diagnostic.config({
  float = {
    header = false,
    border = "rounded",
    focusable = false,
  },
})

-- to avoid conflicts with Prettier
vim.g.lazyvim_prettier_needs_config = true
