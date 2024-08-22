return {
  { "christoomey/vim-tmux-navigator", event = "VeryLazy" },
  { "RyanMillerC/better-vim-tmux-resizer", event = "VeryLazy" },
  { "mg979/vim-visual-multi", event = "VeryLazy" },
  { "vimpostor/vim-tpipeline", event = "VeryLazy" },

  {
    "akinsho/git-conflict.nvim",
    event = "BufRead",
    config = true,
  },

  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    config = function()
      require("ts_context_commentstring").setup({
        enable_autocmd = false,
      })
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },

  {
    "folke/noice.nvim",
    opts = function(_, opts)
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "No information",
        },
        opts = { skip = true },
      })

      opts.presets.lsp_doc_border = true
    end,
  },

  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 5000,
    },
  },

  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "BufRead",
    opts = { use_default_keymaps = false },
  },

  {
    "chentoast/marks.nvim",
    event = "BufRead",
    opts = { default_mappings = false },
  },

  {
    "echasnovski/mini.surround",
    opts = {
      mappings = {
        add = "gsa",
        delete = "gsd",
        replace = "gsr",
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
    keys = {
      { "<leader>e", vim.NIL },
      { "<leader>E", vim.NIL },
      {
        "<leader>fe",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = LazyVim.root() })
        end,
        desc = "Explorer NeoTree (Root Dir)",
      },
      {
        "<leader>fE",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
        end,
        desc = "Explorer NeoTree (cwd)",
      },
    },
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
        },
      },
    },
  },

  {
    "stevearc/oil.nvim",
    event = "VeryLazy",
    opts = {
      keymaps = {
        ["<C-v>"] = "actions.select_vsplit",
        ["<C-c>"] = "actions.close",
        ["<esc>"] = "actions.close",
        ["q"] = "actions.close",
        ["<C-r>"] = "actions.refresh",
      },
      view_options = {
        show_hidden = true,
      },
      delete_to_trash = true,
      float = {
        padding = 10,
      },
    },
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      -- "nvim-telescope/telescope-live-grep-args.nvim",
      "fdschmidt93/telescope-egrepify.nvim",
    },
    keys = {
      -- Override <leader>/
      -- @see: https://github.com/LazyVim/LazyVim/issues/63#issuecomment-1383718679
      { "<leader><space>", vim.NIL },
      { "<leader>/", vim.NIL },
    },
    opts = function()
      local actions = require("telescope.actions")
      require("telescope").load_extension("egrepify")
      return {
        defaults = {
          file_ignore_patterns = { ".git/", "/node_modules/", "package-lock.json", "yarn.lock" },
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden", -- include hidden files and directories
            "--trim", -- remove indentations in search results
          },
          mappings = {
            n = {
              ["q"] = "close",
              ["<C-a>"] = {
                function(p_bufnr)
                  actions.send_selected_to_qflist(p_bufnr)
                  vim.cmd.cfdo("edit")
                end,
                type = "action",
                opts = {
                  nowait = true,
                  silent = true,
                  desc = "Open selected files",
                },
              },
              ["<C-r>"] = {
                function(p_bufnr)
                  -- send results to quick fix list
                  actions.send_to_qflist(p_bufnr)

                  local qflist = vim.fn.getqflist()
                  local paths = {}
                  local hash = {}
                  for k in pairs(qflist) do
                    local path = vim.fn.bufname(qflist[k]["bufnr"]) -- extract path from quick fix list
                    if not hash[path] then -- add to paths table, if not already appeared
                      paths[#paths + 1] = path
                      hash[path] = true -- remember existing paths
                    end
                  end

                  -- show search scope with message
                  vim.notify("find in ...\n  " .. table.concat(paths, "\n  "))

                  -- execute live_grep_args with search scope
                  require("telescope").extensions.egrepify.egrepify({ search_dirs = paths })
                end,
                type = "action",
                opts = {
                  nowait = true,
                  silent = true,
                  desc = "Live grep on results",
                },
              },
            },
          },
        },
        pickers = {
          find_files = { hidden = true }, -- include hidden files and directories
        },
      }
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
      document_highlight = { enabled = false },
      inlay_hints = { enabled = false },
    },
  },

  {
    "nvimtools/none-ls.nvim",
    lazy = true,
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      {
        "jay-babu/mason-null-ls.nvim",
        opts = {
          ensure_installed = { "cspell", "markuplint" },
          automatic_installation = true,
          methods = { code_actions = false },
        },
      },
      "davidmh/cspell.nvim",
      "nvimtools/none-ls-extras.nvim",
    },
    opts = function()
      local null_ls = require("null-ls")
      local cspell = require("cspell")
      return {
        debounce = 500,
        temp_dir = "/tmp",
        sources = {
          null_ls.builtins.diagnostics.markuplint.with({
            filetypes = { "html", "javascriptreact", "typescriptreact" },
            prefer_local = "node_modules/.bin",
            condition = function(utils)
              return vim.fn.executable("markuplint") > 0
                and utils.root_has_file({
                  ".markuplintrc",
                  ".markuplintrc.json",
                  ".markuplintrc.yaml",
                  ".markuplintrc.yml",
                  ".markuplintrc.js",
                  ".markuplintrc.ts",
                })
            end,
            diagnostics_postprocess = function(diagnostic)
              diagnostic.severity = vim.diagnostic.severity["WARN"]
            end,
          }),
          cspell.diagnostics.with({
            diagnostics_postprocess = function(diagnostic)
              diagnostic.severity = vim.diagnostic.severity["HINT"]
            end,
          }),
          cspell.code_actions,
          require("none-ls.diagnostics.eslint"),
          require("none-ls.code_actions.eslint"),
        },
      }
    end,
  },

  {
    "echasnovski/mini.pairs",
    opts = function()
      local neigh_pattern = "[%s][%s]"
      return {
        mappings = {
          ["("] = { action = "open", pair = "()", neigh_pattern = neigh_pattern },
          ["["] = { action = "open", pair = "[]", neigh_pattern = neigh_pattern },
          ["{"] = { action = "open", pair = "{}", neigh_pattern = neigh_pattern },

          [")"] = { action = "close", pair = "()", neigh_pattern = neigh_pattern },
          ["]"] = { action = "close", pair = "[]", neigh_pattern = neigh_pattern },
          ["}"] = { action = "close", pair = "{}", neigh_pattern = neigh_pattern },

          ['"'] = { action = "closeopen", pair = '""', neigh_pattern = neigh_pattern, register = { cr = false } },
          ["'"] = { action = "closeopen", pair = "''", neigh_pattern = neigh_pattern, register = { cr = false } },
          ["`"] = { action = "closeopen", pair = "``", neigh_pattern = neigh_pattern, register = { cr = false } },
        },
      }
    end,
  },
}
