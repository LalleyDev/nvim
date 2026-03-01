return{
    {
        'ThePrimeagen/harpoon',
        dependencies={
            "nvim-lua/plenary.nvim"
        },
        config = function()
            require("harpoon").setup({ })
            local ui = require("harpoon.ui")
            local mark = require("harpoon.mark")

            -- mark/ add the files to harpoon
            vim.keymap.set("n","<space>m",mark.add_file)

            -- see the files that have been marked
            vim.keymap.set("n","<space>v",ui.toggle_quick_menu)

            vim.keymap.set("n", "<space>1", function() ui.nav_file(1) end, { desc = "Harpoon file 1" })
            vim.keymap.set("n", "<space>2", function() ui.nav_file(2) end, { desc = "Harpoon file 2" })
            vim.keymap.set("n", "<space>3", function() ui.nav_file(3) end, { desc = "Harpoon file 3" })
            vim.keymap.set("n", "<space>4", function() ui.nav_file(4) end, { desc = "Harpoon file 4" })

        end
    },
}
