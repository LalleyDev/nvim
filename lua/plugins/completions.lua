-- Modeled on LazyVim's blink.cmp setup:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/coding/blink.lua
return {
  "saghen/blink.cmp",
  dependencies = { "rafamadriz/friendly-snippets" },

  version = "1.*",

  opts = {
    -- <C-y> accept, <C-space> open, <C-n>/<C-p> select, <C-e> close
    keymap = { preset = "default" },

    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = "mono",
    },

    completion = {
      -- add () after accepting a function/method
      accept = { auto_brackets = { enabled = true } },
      -- highlight the label with treesitter for lsp items
      menu = { draw = { treesitter = { "lsp" } } },
      -- Only show the documentation popup when manually triggered (<C-space>)
      documentation = { auto_show = false },
    },

    signature = { enabled = true },

    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
      per_filetype = {
        lua = { inherit_defaults = true, "lazydev" },
      },
      providers = {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100, -- show at a higher priority than lsp
        },
      },
    },

    cmdline = {
      enabled = true,
      keymap = { preset = "cmdline" },
      completion = {
        list = { selection = { preselect = false } },
        menu = {
          auto_show = function()
            return vim.fn.getcmdtype() == ":"
          end,
        },
      },
    },

    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
