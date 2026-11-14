return {
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
}
