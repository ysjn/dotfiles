return {
  { "mg979/vim-visual-multi" },
  { "christoomey/vim-tmux-navigator", lazy = false },
  { "RyanMillerC/better-vim-tmux-resizer", lazy = false },
  { "akinsho/git-conflict.nvim", lazy = true, config = true },

  {
    "echasnovski/mini.surround",
    opts = {
      mappings = {
        add = "gsa", -- Add surrounding in Normal and Visual modes
        delete = "gsd", -- Delete surrounding
        replace = "gsr", -- Replace surrounding
      },
    },
  },

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
    dependencies = { "nvim-telescope/telescope-live-grep-args.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { "/node_modules/", "package-lock.json", "yarn.lock" },
          mappings = {
            n = {
              ["q"] = "close",
              ["<C-a>"] = function(p_bufnr)
                require("telescope.actions").send_selected_to_qflist(p_bufnr)
                vim.cmd.cfdo("edit")
              end,
              ["<C-r>"] = function(p_bufnr)
                -- send results to quick fix list
                require("telescope.actions").send_to_qflist(p_bufnr)
                local qflist = vim.fn.getqflist()
                local paths = {}
                local hash = {}
                for k in pairs(qflist) do
                  local path = vim.fn.bufname(qflist[k]["bufnr"]) -- extract path from quickfix list
                  if not hash[path] then -- add to paths table, if not already appeared
                    paths[#paths + 1] = path
                    hash[path] = true -- remember existing paths
                  end
                end
                -- execute live_grep_args with search scope
                require("telescope").extensions.live_grep_args.live_grep_args({ search_dirs = paths })
              end,
            },
          },
        },
      })
      require("telescope").load_extension("live_grep_args")
    end,
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
