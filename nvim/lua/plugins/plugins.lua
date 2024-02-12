return {
  { "mg979/vim-visual-multi" },
  { "christoomey/vim-tmux-navigator", lazy = false },
  { "RyanMillerC/better-vim-tmux-resizer", lazy = false },
  { "akinsho/git-conflict.nvim", lazy = true, config = true },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
    config = function()
      vim.filetype.add({ extension = { mdx = "markdown.mdx" } })
      vim.treesitter.language.register("markdown", "mdx")
    end,
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
        },
      },
    },
  },

  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        file_ignore_patterns = { "/node_modules/", "package-lock.json", "yarn.lock" },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = { eslint = {} },
      setup = {
        eslint = function()
          require("lazyvim.util").lsp.on_attach(function(client)
            if client.name == "eslint" then
              client.server_capabilities.documentFormattingProvider = true
            elseif client.name == "tsserver" then
              client.server_capabilities.documentFormattingProvider = false
            end
          end)
        end,
      },
    },
  },

  {
    "jay-babu/mason-null-ls.nvim",
    lazy = true,
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      {
        "nvimtools/none-ls.nvim",
        opts = function()
          local null_ls = require("null-ls")
          return {
            sources = {
              null_ls.builtins.diagnostics.markuplint.with({
                filetypes = { "html", "javascriptreact", "typescriptreact" },
              }),
              null_ls.builtins.diagnostics.cspell.with({
                diagnostics_postprocess = function(diagnostic)
                  diagnostic.severity = vim.diagnostic.severity["HINT"]
                end,
              }),
              null_ls.builtins.code_actions.cspell,
            },
          }
        end,
      },
    },
    config = function()
      require("mason-null-ls").setup({
        ensure_installed = {},
        automatic_installation = true,
        automatic_setup = true,
      })
    end,
  },
}
