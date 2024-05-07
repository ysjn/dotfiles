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
          NormalFloat = { bg = "None" },
          FloatShadow = { bg = "None" },
          FloatShadowThrough = { bg = "None" },
          Visual = { bg = colors.selection_bg },

          SignColumn = { bg = "None" },
          Folded = { bg = "None" },
          FoldColumn = { bg = "None" },
          CursorLine = { bg = "None" },
          CursorColumn = { bg = "None" },
          WhichKeyFloat = { bg = "None" },

          VertSplit = {
            fg = colors.panel_border,
            bg = "None",
          },

          TreesitterContext = { bg = colors.line },

          ["@lsp.typemod.variable.local"] = { fg = colors.lsp_parameter },
          ["@lsp.type.property.typescriptreact"] = { fg = colors.fg },
          ["@lsp.type.member.typescriptreact"] = { fg = colors.func },
          ["htmlTagName"] = { fg = colors.markup },

          DiagnosticHint = { fg = colors.vcs_added_bg },
          DiagnosticUnderlineHint = {
            sp = colors.comment,
            undercurl = true,
          },
        },
      })

      local ayu_lualine = require("lualine.themes.ayu")
      ayu_lualine.normal.b.bg = "None"
      ayu_lualine.insert.b.bg = "None"
      ayu_lualine.visual.b.bg = "None"
      ayu_lualine.replace.b.bg = "None"
      ayu_lualine.normal.c.bg = "None"

      local icons = require("lazyvim.config").icons
      require("lualine").setup({
        options = {
          theme = ayu_lualine,
          component_separators = { left = "|", right = "|" },
        },
        sections = {
          lualine_c = {
            {
              "diagnostics",
              symbols = {
                error = icons.diagnostics.Error,
                warn = icons.diagnostics.Warn,
                info = icons.diagnostics.Info,
                hint = icons.diagnostics.Hint,
              },
            },
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            { "filename", file_status = true, path = 1 },
          },
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
          indicator = {
            icon = " ",
            style = "icon",
          },
          separator_style = { "", "" },
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
          buffer_visible = {
            fg = colors.fg,
            bg = colors.guide_normal,
          },
          buffer_selected = {
            fg = colors.bg,
            bg = colors.special,
            bold = false,
            italic = false,
          },
          modified_selected = {
            fg = colors.vcs_removed,
            bg = colors.special,
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
      })
    end,
  },

  {
    "b0o/incline.nvim",
    event = "VeryLazy",
    opts = {
      window = {
        margin = { vertical = 0 },
        winhighlight = {
          active = { Normal = "CurSearch" },
          inactive = { Normal = "Pmenu" },
        },
      },
    },
  },

  {
    "levouh/tint.nvim",
    event = "VeryLazy",
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
