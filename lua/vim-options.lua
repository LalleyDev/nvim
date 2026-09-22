-- vim.cmd("set expandtab")
-- vim.cmd("set tabstop=4")
-- vim.cmd("set softtabstop=4")
-- vim.cmd("set shiftwidth=4")
-- vim.cmd("set relativenumber")

-- nvim-treesitter (main) compiles parsers via `tree-sitter build`, which
-- picks its C compiler from $CC. Prefer zig: a single-binary toolchain
-- that needs no MSVC/Windows SDK.
vim.env.CC = "zig cc"

-- shortcuts
-- quickfix movement
vim.keymap.set("n","<M-j>","<cmd>cnext<CR>")
vim.keymap.set("n","<M-k>","<cmd>cprev<CR>")

-- telescope
vim.keymap.set("n","<M-k>","<cmd>cprev<CR>")

-- general keymaps

-- Normal Mode: Toggle comment on current line
vim.keymap.set("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment line" })
vim.keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment line" })

-- Visual Mode: Toggle comment on selection
vim.keymap.set("v", "<C-/>", "gc", { remap = true, desc = "Toggle comment selection" })
vim.keymap.set("v", "<C-_>", "gc", { remap = true, desc = "Toggle comment selection" })

-- Quality of life terminal keymaps
vim.keymap.set("t","<esc><esc>","<c-\\><c-n>")

-- Diagnostics
vim.diagnostic.config({
    virtual_text = {
        prefix = "●",
        spacing = 4,
    },
    signs = true,
    underline = true,
    update_in_insert = false,
})
