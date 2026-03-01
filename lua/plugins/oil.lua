return{
    {
        'stevearc/oil.nvim',
        lazy=false,
        --@module 'oil'
        --@type oul.SetupOpts
        opts={},
        dependencies = {{"echasnovski/mini.icons",opts = {}}},
        config = function()
            require("oil").setup()
            vim.keymap.set("n", "<space>-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
        end
    }
}
