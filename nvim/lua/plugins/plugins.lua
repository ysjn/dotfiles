return {
  { "christoomey/vim-tmux-navigator", event = "VeryLazy" },
  { "RyanMillerC/better-vim-tmux-resizer", event = "VeryLazy" },
  { "mg979/vim-visual-multi", event = "VeryLazy" },
  { "OlegGulevskyy/better-ts-errors.nvim", event = "VeryLazy" },
  { "ray-x/lsp_signature.nvim", event = "VeryLazy" },
  { "nacro90/numb.nvim", event = "VeryLazy", config = true },

  {
    "folke/snacks.nvim",
    opts = function()
      local urls = {
        branch = "/tree/{branch}",
        file = "/blob/{branch}/{file}#L{line_start}-L{line_end}",
        permalink = "/blob/{commit}/{file}#L{line_start}-L{line_end}",
        commit = "/commit/{commit}",
      }
      return {
        gitbrowse = {
          url_patterns = {
            ["ghe"] = urls,
            ["partner"] = urls,
          },
        },
      }
    end,
  },

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
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "Failed to run `config` for lualine.nvim",
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
    "nvim-mini/mini.surround",
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
        ["<C-h>"] = false,
        ["<C-l>"] = false,
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
    "neovim/nvim-lspconfig",
    opts = {
      servers = { eslint = {} },
      setup = {
        eslint = function(_)
          local eslint_config_files = {
            "eslint.config.js",
            "eslint.config.mjs",
            "eslint.config.cjs",
            ".eslintrc.*",
            ".eslintrc",
          }

          local function has_eslint_config()
            for _, pattern in ipairs(eslint_config_files) do
              if vim.fn.glob(pattern) ~= "" then
                return true
              end
            end
            return false
          end

          if not has_eslint_config() then
            return true
          end

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
      "nvim-lua/plenary.nvim",
      {
        "jay-babu/mason-null-ls.nvim",
        opts = {
          ensure_installed = { "cspell", "markuplint" },
          methods = { code_actions = false },
        },
      },
      "davidmh/cspell.nvim",
      "nvimtools/none-ls-extras.nvim",
    },
    opts = function()
      local null_ls = require("null-ls")
      local cspell = require("cspell")
      local DIAGNOSTICS_ON_OPEN = null_ls.methods.DIAGNOSTICS_ON_OPEN
      local DIAGNOSTICS_ON_SAVE = null_ls.methods.DIAGNOSTICS_ON_SAVE
      return {
        debounce = 500,
        temp_dir = "/tmp",
        sources = {
          null_ls.builtins.diagnostics.markuplint.with({
            extra_filetypes = {
              "javascriptreact",
              "typescriptreact",
            },
            extra_args = { "--locale", "ja" },
            prefer_local = "node_modules/.bin",
            to_temp_file = false,
            condition = function(utils)
              -- execute only when config file is found
              return vim.fn.executable("markuplint") > 0 and utils.root_has_file_matches("%.?markuplint.*")
            end,
            method = { DIAGNOSTICS_ON_OPEN, DIAGNOSTICS_ON_SAVE },
          }),
          cspell.diagnostics.with({
            diagnostics_postprocess = function(diagnostic)
              diagnostic.severity = vim.diagnostic.severity["HINT"]
            end,
            method = { DIAGNOSTICS_ON_OPEN, DIAGNOSTICS_ON_SAVE },
          }),
          cspell.code_actions,
          -- none-ls-extras
          require("none-ls.diagnostics.eslint").with({
            method = { DIAGNOSTICS_ON_OPEN, DIAGNOSTICS_ON_SAVE },
            condition = function(utils)
              return utils.root_has_file_matches("eslint.config.*")
                or utils.root_has_file_matches(".eslintrc.*")
                or utils.root_has_file_matches(".eslintrc")
            end,
          }),
          require("none-ls.code_actions.eslint").with({
            condition = function(utils)
              return utils.root_has_file_matches("eslint.config.*")
                or utils.root_has_file_matches(".eslintrc.*")
                or utils.root_has_file_matches(".eslintrc")
            end,
          }),
        },
      }
    end,
  },

  {
    "nvim-mini/mini.pairs",
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

  {
    "folke/sidekick.nvim",
    opts = {
      cli = {
        win = {
          config = function()
            vim.b.miniindentscope_disable = true
          end,
          keys = {
            navigate_left = {
              "<A-h>",
              function()
                vim.cmd("TmuxNavigateLeft")
              end,
            },
            navigate_right = {
              "<A-l>",
              function()
                vim.cmd("TmuxNavigateRight")
              end,
            },
            new_line = {
              "<CR>",
              function(t)
                local buf = vim.api.nvim_get_current_buf()
                local total_lines = vim.api.nvim_buf_line_count(buf)
                local last_non_empty_line = ""
                for i = total_lines, 1, -1 do
                  local line = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1] or ""
                  if line:match("%S") then
                    last_non_empty_line = line
                    break
                  end
                end

                local is_insert_mode = last_non_empty_line:match("^%s*%-%- INSERT %-%-%s*$") ~= nil

                if is_insert_mode then
                  t:send("\n")
                else
                  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
                end
              end,
            },
            submit = {
              "<A-CR>",
              function()
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
              end,
            },
          },
        },
      },
    },
    keys = {
      {
        "<leader>aa",
        function()
          require("sidekick.cli").toggle({ filter = { installed = true } })
        end,
        desc = "Sidekick Toggle",
      },
      {
        "<leader>as",
        function()
          require("sidekick.cli").select({ filter = { installed = true } })
        end,
        desc = "Sidekick Select CLI",
      },
    },
  },
}
