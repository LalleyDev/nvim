-- local theme = "tokyo"
local theme = "gruv"
-- local theme = "cat"
-- local theme = "default"

if theme == "tokyo" then
    return{
        "folke/tokyonight.nvim",
        lazy = false,
        opts = { style = "moon" },
        config = function()
            -- night, storm, day, moon
            vim.cmd.colorscheme "tokyonight"
        end
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
elseif theme == "gruv" then
    return{
        "ellisonleao/gruvbox.nvim",
        priority = 1000 ,
        config = true,
        opts = {},
        config = function()
            vim.o.background = "dark"
            vim.cmd.colorscheme "gruvbox"
        end
    }
elseif theme == "default" then
    return{
    }
end
