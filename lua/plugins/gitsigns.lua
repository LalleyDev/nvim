return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~_" },
      untracked = { text = "┆" },
    },
    -- also color the line number so the change type is visible at a glance
    numhl = true,
    on_attach = function(buf)
      local gs = require("gitsigns")
      local map = function(l, r, desc)
        vim.keymap.set("n", l, r, { buffer = buf, desc = desc })
      end
      map("]h", function() gs.nav_hunk("next") end, "Next hunk")
      map("[h", function() gs.nav_hunk("prev") end, "Prev hunk")
      map("<leader>hp", gs.preview_hunk, "Preview hunk")
      map("<leader>hi", gs.preview_hunk_inline, "Preview hunk inline")
      map("<leader>hs", gs.stage_hunk, "Stage hunk")
      map("<leader>hr", gs.reset_hunk, "Reset hunk")
      map("<leader>hb", function()
        gs.blame_line({ full = true })
      end, "Blame line")
      map("<leader>hd", gs.diffthis, "Diff against index")
    end,
  },
  config = function(_, opts)
    require("gitsigns").setup(opts)

    -- Force distinct colors; many themes make add/change/delete look alike.
    -- Re-applied on ColorScheme since themes reset highlights when switched.
    local function set_hl()
      vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#7fd962" })
      vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#e5c07b" })
      vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#f7768e" })
      vim.api.nvim_set_hl(0, "GitSignsChangedelete", { fg = "#ff9e64" })
      vim.api.nvim_set_hl(0, "GitSignsUntracked", { fg = "#7aa2f7" })
      vim.api.nvim_set_hl(0, "GitSignsAddNr", { link = "GitSignsAdd" })
      vim.api.nvim_set_hl(0, "GitSignsChangeNr", { link = "GitSignsChange" })
      vim.api.nvim_set_hl(0, "GitSignsDeleteNr", { link = "GitSignsDelete" })
      vim.api.nvim_set_hl(0, "GitSignsChangedeleteNr", { link = "GitSignsChangedelete" })
      vim.api.nvim_set_hl(0, "GitSignsTopdeleteNr", { link = "GitSignsDelete" })
      vim.api.nvim_set_hl(0, "GitSignsUntrackedNr", { link = "GitSignsUntracked" })
    end
    set_hl()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })
  end,
}
