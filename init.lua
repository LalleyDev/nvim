-- LSP debug logging: every message to/from language servers goes to
-- stdpath("log")/lsp.log (nvim-data/lsp.log). Set before lazy so it is in
-- effect when jdtls starts. The file is never rotated and grows quickly at
-- this level, so set it back to "warn" once done debugging.
-- vim.lsp.log.set_level("debug")

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
