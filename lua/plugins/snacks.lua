return {
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      picker = { enabled = true },
      lazygit = { enabled = true },
    },
    keys = {
      {
        "<leader>th",
        function()
          Snacks.picker.colorschemes({ layout = "ivy" })
        end,
        desc = "Pick colorscheme",
      },
      { "<leader>gg", function() Snacks.lazygit() end,           desc = "Lazygit" },
      { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git status" },
      { "<leader>gd", function() Snacks.picker.git_diff() end,   desc = "Git diff (hunks)" },
    },
  },
}
