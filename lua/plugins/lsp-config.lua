return{
    {
        -- installs and manages lsps
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end
    },
    {
        -- ensures that lsps are installed
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup({
                -- add the language server here first
                ensure_installed = {
                    "lua_ls",
                }
            })
        end
    },
    {
        -- config the lsp interactions
        -- between neovim and lsp
        "neovim/nvim-lspconfig",
        config = function()
            -- lsp servers
            vim.lsp.enable('lua_ls')

            -- lsp config keybinds
            vim.keymap.set('n','K',vim.lsp.buf.hover,{})
            vim.keymap.set('n','gd',vim.lsp.buf.definition,{})
            vim.keymap.set({'n','v'},'<leader>ca',vim.lsp.buf.code_action,{})
        end
    },
}
