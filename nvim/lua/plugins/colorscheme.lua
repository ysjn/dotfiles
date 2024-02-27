return {
  {
    "Shatur/neovim-ayu",
    lazy = true,
    priority = 1000,
    config = function()
      local colors = require("ayu.colors")
      colors.generate(true)
      require("ayu").setup({
        overrides = {
          Normal = { bg = "None" },
          Visual = { bg = colors.selection_bg },

          -- ColorColumn = { bg = "None" },
          SignColumn = { bg = "None" },
          Folded = { bg = "None" },
          FoldColumn = { bg = "None" },
          CursorLine = { bg = "None" },
          CursorColumn = { bg = "None" },
          WhichKeyFloat = { bg = "None" },

          DiagnosticHint = { fg = colors.guide_normal },
          DiagnosticUnderlineHint = { sp = colors.guide_active, undercurl = true },
        },
      })

      local ayu_lualine = require("lualine.themes.ayu")
      ayu_lualine.visual.b.bg = "None"
      ayu_lualine.replace.b.bg = "None"
      ayu_lualine.inactive.a.bg = colors.panel_shadow
      ayu_lualine.inactive.b.bg = colors.panel_shadow
      ayu_lualine.inactive.c.bg = colors.panel_shadow
      ayu_lualine.normal.b.bg = "None"
      ayu_lualine.normal.c.bg = "None"
      ayu_lualine.insert.b.bg = "None"
      require("lualine").setup({
        options = {
          theme = ayu_lualine,
          component_separators = { left = "|", right = "|" },
        },
        sections = {
          lualine_z = {},
        },
      })

      require("bufferline").setup({
        options = {
          themable = true,
          show_buffer_close_icons = false,
          always_show_bufferline = true,
          max_name_length = 50,
          name_formatter = function(buf)
            if string.match(buf.path, "/pc/") then
              return "[PC]" .. vim.fn.fnamemodify(buf.path, ":t")
            elseif string.match(buf.path, "/smp/") then
              return "[SMP]" .. vim.fn.fnamemodify(buf.path, ":t")
            end
          end,
          indicator = { style = "underline" },
          offsets = {
            {
              filetype = "neo-tree",
              text = "Neo-tree",
              highlight = "Directory",
              text_align = "left",
            },
          },
        },
        highlights = {
          separator = {
            fg = colors.panel_shadow,
          },
          separator_selected = {
            bg = colors.panel_shadow,
          },
          buffer_selected = {
            sp = colors.accent,
            bold = false,
            italic = false,
          },
        },
      })
    end,
  },

  {
    "rcarriga/nvim-notify",
    opts = {
      background_colour = "#000000",
    },
  },

  {
    "ggandor/leap.nvim",
    config = function()
      local colors = require("ayu.colors")
      colors.generate(true)
      vim.api.nvim_set_hl(0, "LeapBackdrop", { link = "Comment" })
      vim.api.nvim_set_hl(0, "LeapLabelPrimary", {
        fg = colors.bg,
        bg = colors.lsp_parameter,
        bold = true,
        -- nocombine = true,
      })
    end,
  },

  {
    "b0o/incline.nvim",
    event = "VeryLazy",
    opts = {
      hide = { cursorline = true },
      window = {
        margin = { vertical = 0 },
        winhighlight = {
          active = { Normal = "IncSearch" },
          inactive = { Normal = "Pmenu" },
        },
      },
    },
  },

  {
    "levouh/tint.nvim",
    config = {
      tint = -70,
      saturation = 0.5,
      highlight_ignore_patterns = {
        "LineNr",
        "WinSeparator",
        "DiagnosticHint",
        "Comment",
      },
    },
  },
}
