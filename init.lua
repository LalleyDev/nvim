require("config.lazy")

vim.keymap.set("n","<space><space>x","<cmd>source %<CR>");

vim.api.nvim_create_autocmd('TextYankPost',{
    desc = 'highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank',{clear = true}),
    callback = function()
        vim.highlight.on_yank()
    end,
})

