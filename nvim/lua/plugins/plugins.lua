return {
  {
    "christoomey/vim-tmux-navigator",
    cond = vim.env.TMUX ~= nil and vim.env.TMUX ~= "" and vim.env.HERDR_ENV ~= "1",
    event = "VeryLazy",
  },
  {
    "RyanMillerC/better-vim-tmux-resizer",
    cond = vim.env.TMUX ~= nil and vim.env.TMUX ~= "" and vim.env.HERDR_ENV ~= "1",
    event = "VeryLazy",
  },
  {
    "lmilojevicc/herdr-splits.nvim",
    cond = vim.env.HERDR_ENV == "1",
    event = "VeryLazy",
    config = function()
      require("herdr-splits").setup({
        nav_keys = { left = "<M-h>", down = "<M-j>", up = "<M-k>", right = "<M-l>" },
        resize_keys = { left = "<M-S-h>", down = "<M-S-j>", up = "<M-S-k>", right = "<M-S-l>" },
        nav_at_edge = "stop",
      })
    end,
  },
  {
    "smart-splits-nvim/smart-splits.nvim",
    version = "^3.0.0",
    cond = function()
      return vim.env.HERDR_ENV ~= "1"
        and (vim.env.TMUX == nil or vim.env.TMUX == "")
        and vim.env.REX_SESSION ~= nil
        and vim.env.REX_SESSION ~= ""
        and vim.env.REX_BLOCK ~= nil
        and vim.env.REX_BLOCK ~= ""
    end,
    dependencies = {
      { "rawnly/smart-splits-backend-rex", main = "smart-splits-backend-rex", opts = {} },
    },
    opts = {
      move = { at_edge = "stop" },
      mux = { backend = "smart-splits-backend-rex" },
    },
    keys = function()
      local splits = require("smart-splits")
      return {
        { "<M-h>", splits.move_cursor_left, mode = { "n", "t" }, desc = "Navigate left" },
        { "<M-j>", splits.move_cursor_down, mode = { "n", "t" }, desc = "Navigate down" },
        { "<M-k>", splits.move_cursor_up, mode = { "n", "t" }, desc = "Navigate up" },
        { "<M-l>", splits.move_cursor_right, mode = { "n", "t" }, desc = "Navigate right" },
        { "<M-H>", splits.resize_left, mode = { "n", "t" }, desc = "Resize left" },
        { "<M-J>", splits.resize_down, mode = { "n", "t" }, desc = "Resize down" },
        { "<M-K>", splits.resize_up, mode = { "n", "t" }, desc = "Resize up" },
        { "<M-L>", splits.resize_right, mode = { "n", "t" }, desc = "Resize right" },
      }
    end,
  },

  { "mg979/vim-visual-multi", event = "VeryLazy" },
  { "OlegGulevskyy/better-ts-errors.nvim", event = "VeryLazy" },
  { "ray-x/lsp_signature.nvim", event = "VeryLazy" },
  { "nacro90/numb.nvim", event = "VeryLazy", config = true },
  {
    "fasterius/simple-zoom.nvim",
    event = "VeryLazy",
    opts = { hide_tabline = false },
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
      local pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()
      require("Comment").setup({
        pre_hook = function(ctx)
          -- Neovim 0.12 returns nil for missing parsers, which Comment.nvim cannot handle.
          local ok, parser = pcall(vim.treesitter.get_parser, 0)
          if ok and parser == nil then
            return require("Comment.ft").get(vim.bo.filetype, ctx.ctype) or vim.bo.commentstring
          end
          return pre_hook(ctx)
        end,
      })
    end,
  },

  {
    "folke/noice.nvim",
    opts = function(_, opts)
      local filters = {
        { event = "notify", find = "No information" },
      }

      for _, filter in ipairs(filters) do
        table.insert(opts.routes, {
          filter = filter,
          opts = { skip = true },
        })
      end

      opts.presets.lsp_doc_border = true
    end,
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
    init = function()
      vim.filetype.add({ extension = { mdx = "markdown.mdx" } })
      vim.treesitter.language.register("markdown", { "mdx", "markdown.mdx" })
    end,
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
        border = "rounded",
      },
      confirmation = {
        border = "rounded",
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

          vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(event)
              local client = vim.lsp.get_client_by_id(event.data.client_id)
              if client and client.name == "eslint" then
                client.server_capabilities.documentFormattingProvider = true
              elseif client and client.name == "tsserver" then
                client.server_capabilities.documentFormattingProvider = false
              end
            end,
          })
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
}
