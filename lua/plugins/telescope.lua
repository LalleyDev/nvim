return {
    {
        'nvim-telescope/telescope.nvim', version = '*',
        dependencies = {
            'nvim-lua/plenary.nvim',
            -- optional but recommended
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        },
        config = function()
            require('telescope').setup {
                -- extensions = {
                --     fzf = {}
                -- }
            }
            local builtin = require("telescope.builtin")

            vim.keymap.set('n','<space>fd', builtin.find_files,{})
            vim.keymap.set('n','<leader>fg', builtin.live_grep,{})
            vim.keymap.set('n','<leader>fh', builtin.help_tags,{})

            vim.keymap.set('n','<space>en', function()
                local opts = require('telescope.themes').get_ivy({
                    cwd = vim.fn.stdpath("config")
                })
                builtin.find_files(opts)
            end)

            vim.keymap.set('n','<space>ep', function()
                local opts = require('telescope.themes').get_ivy({
                    cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
                })
                builtin.find_files(opts)
            end)



        end
    },
    {
        "nvim-telescope/telescope-ui-select.nvim",
        config = function()
            require("telescope").setup({
              extensions = {
                ["ui-select"] = {
                  require("telescope.themes").get_dropdown {
                  }
                }
              }
            })
            require("telescope").load_extension("ui-select")
        end
    },
}
