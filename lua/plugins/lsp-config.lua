return {
  {
    -- installs and manages lsps
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    -- ensures that lsps are installed
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        -- add the language server here first
        ensure_installed = {
          "lua_ls",
          "jdtls",
        }
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      'saghen/blink.cmp',
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
    },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      vim.lsp.config('*', {
        capabilities = capabilities
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            format = {
              enable = true,
              defaultConfig = {
                indent_style = "space",
                indent_size = "2",
                quote_style = "double",
                max_line_length = "100",
              },
            },
          },
        },
      })
      -- lsp servers
      vim.lsp.enable('lua_ls')
      vim.lsp.enable("jdtls")
      -- lsp config keybinds
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
      vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, {})

      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.lua",
        callback = function(args)
          vim.lsp.buf.format({ bufnr = args.buf, async = false })
        end,
      })
    end
  },
}
