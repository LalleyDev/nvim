require("config.lazy")

vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>");
vim.keymap.set("v", "<leader>x", ":lua<CR>", { desc = "Execute selection as Lua" })

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyReload",
  callback = function()
    -- single line, no message history, no hit-enter
    vim.api.nvim_echo({ { " Config Reloaded", "MoreMsg" } }, false, {})
  end,
})
