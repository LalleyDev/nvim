local theme = "cat"

if theme == "tokyo" then
    return{
        "folke/tokyonight.nvim",
        lazy = true,
        opts = { style = "moon" },
    }
elseif theme == "cat" then
    return{
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            -- latte, frappe, macchiato, mocha
            vim.cmd.colorscheme "catppuccin-macchiato"
        end
    }
end
