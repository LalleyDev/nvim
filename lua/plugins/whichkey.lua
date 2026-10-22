return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  -- keys = {
  --   {
  --     "<leader>?",
  --     function()
  --       require("which-key").show({ global = false })
  --     end,
  --     desc = "Buffer Local Keymaps (which-key)",
  --   },
  -- },
  config = function()
    local wk = require("which-key")
    wk.add({
      { "<leader>f", group = "file" },
      { "<leader>g", group = "git" },
      { "<leader>h", group = "git hunk" },
      { "<leader>o", group = "overseer (tasks)" },
      { "<leader>q", group = "session" },
      { "<leader>t", group = "tools" },
      { "<leader>c", group = "code" },
      { "<leader>cd", group = "debug" },
      { "<leader>ct", group = "test" },
      { "<leader>cx", group = "extract" },
      { "<leader>cg", group = "goto" },
    }, {
    })
    local opts = {
      preset = "modern",
      delay = 400
    }
    wk.setup(opts)
  end
}
