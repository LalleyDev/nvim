vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set relativenumber")

-- shortcuts
-- quickfix movement
vim.keymap.set("n","<M-j>","<cmd>cnext<CR>")
vim.keymap.set("n","<M-k>","<cmd>cprev<CR>")

-- telescope
vim.keymap.set("n","<M-k>","<cmd>cprev<CR>")
