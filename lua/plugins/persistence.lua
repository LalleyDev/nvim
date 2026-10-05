return {
  "folke/persistence.nvim",
  event = "BufReadPre", -- only start session saving when an actual file is opened
  opts = {},
  keys = {
    { "<leader>qs", function() require("persistence").load() end,                desc = "Restore session for cwd" },
    { "<leader>qS", function() require("persistence").select() end,              desc = "Select session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    { "<leader>qd", function() require("persistence").stop() end,                desc = "Don't save current session" },
  },
}
