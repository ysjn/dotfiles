return {
  { "christoomey/vim-tmux-navigator", lazy = false },
  { "RyanMillerC/better-vim-tmux-resizer", lazy = false },
  { "akinsho/git-conflict.nvim", config = true },

  { "mg979/vim-visual-multi", event = "VeryLazy" },

  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = { use_default_keymaps = false },
  },

  {
    "chentoast/marks.nvim",
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
    keys = {
      -- Override <leader>/
      -- @see: https://github.com/LazyVim/LazyVim/issues/63#issuecomment-1383718679
      { "<leader>/", vim.NIL },
    },
    opts = function()
      local actions = require("telescope.actions")
      require("telescope").load_extension("live_grep_args")
      return {
        defaults = {
          file_ignore_patterns = { "/node_modules/", "package-lock.json", "yarn.lock" },
          mappings = {
            n = {
              ["q"] = "close",
              ["<C-a>"] = {
                function(p_bufnr)
                  actions.send_selected_to_qflist(p_bufnr)
                  vim.cmd.cfdo("edit")
                end,
                "Open selected files",
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
                  require("telescope").extensions.live_grep_args.live_grep_args({ search_dirs = paths })
                end,
                "Live grep on results",
              },
            },
          },
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
    },
    opts = function()
      local null_ls = require("null-ls")
      local cspell = require("cspell")
      return {
        debounce = 500,
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
        },
      }
    end,
  },

  {
    "L3MON4D3/LuaSnip",
    config = function()
      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local f = ls.function_node

      local clipboard = function()
        return vim.fn.getreg() .. ""
      end

      local snippets = {
        s({ trig = "cl", dscr = "console.log" }, { t('console.log("'), f(clipboard), t('", '), f(clipboard), t(")") }),
      }

      ls.add_snippets("typescript", snippets)
      ls.add_snippets("typescriptreact", snippets)
      ls.add_snippets("javascript", snippets)
      ls.add_snippets("javascriptreact", snippets)
    end,
  },
}
