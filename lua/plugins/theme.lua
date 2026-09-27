-- Themes are all installed; pick one with <leader>th (snacks.nvim picker) and it is
-- remembered across restarts.

local default_theme = "catppuccin-macchiato"
local theme_file = vim.fn.stdpath("data") .. "/last_colorscheme"

local function save_theme(name)
  local f = io.open(theme_file, "w")
  if f then
    f:write(name)
    f:close()
  end
end

local function load_theme()
  local f = io.open(theme_file, "r")
  if not f then
    return nil
  end
  local name = f:read("*l")
  f:close()
  return name
end

-- Once lazy.nvim has finished starting up: apply the saved theme, then start
-- saving any future changes.
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  once = true,
  callback = function()
    local name = load_theme() or default_theme
    if not pcall(vim.cmd.colorscheme, name) then
      pcall(vim.cmd.colorscheme, default_theme)
    end

    -- The picker restores the old theme if you cancel it,
    -- so a cancelled preview is never kept.
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("PersistColorscheme", { clear = true }),
      callback = function(args)
        save_theme(args.match)
      end,
    })
  end,
})

return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    -- night, storm, day, moon
    opts = { style = "moon" },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    -- latte, frappe, macchiato, mocha (each shows up in the picker)
    opts = {},
  },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
  },
  { "EdenEast/nightfox.nvim" },
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      picker = { enabled = true },
    },
    keys = {
      {
        "<leader>th",
        function()
          Snacks.picker.colorschemes({ layout = "ivy" })
        end,
        desc = "Pick colorscheme",
      },
    },
  },
}
