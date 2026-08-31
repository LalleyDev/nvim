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
      { "<leader>e", group = "explorer" },
      { "<leader>b", group = "buffer explorer" }
    }, {
    })
    local opts = {
      preset = "modern",
      delay = 400
    }
    wk.setup(opts)
  end
}
