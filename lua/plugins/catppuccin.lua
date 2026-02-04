return { 
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        -- latte, frappe, macchiato, mocha
        vim.cmd.colorscheme "catppuccin-macchiato"
    end
}
