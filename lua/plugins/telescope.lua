local map = function(mode, keymap, func, desc)
  vim.keymap.set(mode, keymap, func, { desc = desc, })
end


return {
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- optional but recommended
      -- change make to the desired build
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      require("telescope").setup {
        extensions = {
          fzf = {}
        }
      }
      local builtin = require("telescope.builtin")

      map("n", "<space>fd", builtin.find_files, "Find Files")
      map("n", "<leader>fg", builtin.live_grep, "Grep Folder")
      map("n", "<leader>fh", builtin.help_tags, "Find Help")
      map("n", "<leader>fv", builtin.treesitter, "Find In Treesitter")
      map("n", "<leader>fb", builtin.current_buffer_fuzzy_find, "Find In Current Buffer")

      map("n", "<space>fc", function()
        local opts = require("telescope.themes").get_ivy({
          wd = vim.fn.stdpath("config")
        })
        builtin.find_files(opts)
      end, "Find Config")

      -- map("n", "<space>ft", function()
      --   local opts = require("telescope.themes").get_ivy({
      --     cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
      --   })
      --   builtin.find_files(opts)
      -- end, "Find Themes")
      --
      -- map("n", "<space>fts", function()
      --   local opts = require("telescope.themes").get_dropdown({})
      --   builtin.git_status(opts)
      -- end, "Find Themes")
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
