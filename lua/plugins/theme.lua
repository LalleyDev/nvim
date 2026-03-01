local theme = "tokyo"
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
elseif theme == "default" then
    return{
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
