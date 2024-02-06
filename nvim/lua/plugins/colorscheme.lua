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
          ColorColumn = { bg = "None" },
          SignColumn = { bg = "None" },
          Folded = { bg = "None" },
          FoldColumn = { bg = "None" },
          CursorLine = { bg = "None" },
          CursorColumn = { bg = "None" },
          WhichKeyFloat = { bg = "None" },
          VertSplit = { bg = "None" },
          Visual = { bg = colors.selection_bg },
        },
      })

      -- lualine
      local ayu_lualine = require("lualine.themes.ayu")
      ayu_lualine.visual.b.bg = "None"
      ayu_lualine.replace.b.bg = "None"
      ayu_lualine.inactive.a.bg = "None"
      ayu_lualine.inactive.b.bg = "None"
      ayu_lualine.inactive.c.bg = "None"
      ayu_lualine.normal.b.bg = "None"
      ayu_lualine.normal.c.bg = "None"
      ayu_lualine.insert.b.bg = "None"
      require("lualine").setup({
        options = {
          theme = ayu_lualine,
          globalstatus = false,
          component_separators = { left = "|", right = "|" },
        },
        sections = {
          lualine_z = {},
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
        nocombine = true,
      })
    end,
  },
}
