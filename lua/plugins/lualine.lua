return {
  "nvim-lualine/lualine.nvim",
  config = function()
    require("lualine").setup({
      options = {
        theme = "auto"
        -- theme = "dracula"
        -- theme = 'gruvbox_dark'
      }
    })
  end
}
