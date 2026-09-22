return {
  "nvim-treesitter/nvim-treesitter",
  -- `main` is a full, incompatible rewrite of `master`. Required because
  -- `master` is locked for Nvim 0.11 backward-compat and will never get the
  -- fix for the query_predicates.lua crash on Nvim 0.12+
  -- (https://github.com/nvim-treesitter/nvim-treesitter/issues/8618).
  branch = "main",
  lazy = false,
  build = ":TSUpdate",

  config = function()
    require("nvim-treesitter").setup()

    require("nvim-treesitter").install({
      "java",
      "lua",
      "vim",
      "vimdoc",
      "query",
      "bash",
      "json",
      "markdown",
      "javascript",
      "typescript",
      "tsx",
      "css",
      "html",
    })

    -- `main` no longer attaches highlighting itself (no `highlight.enable`
    -- option). Start it per filetype for any language whose parser is
    -- installed -- the equivalent of the old blanket `enable = true`.
    -- Indentation is intentionally left unconfigured: it's opt-in per
    -- filetype here (`indentexpr`), and custom Java indentation already
    -- lives in ftplugins, which treesitter indent would fight.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        local lang = vim.treesitter.language.get_lang(args.match) or args.match
        if vim.tbl_contains(require("nvim-treesitter").get_installed("parsers"), lang) then
          vim.treesitter.start()
        end
      end,
    })

    -- Recovers from the highlighter's decoration provider getting disabled
    -- (e.g. after a query-predicate crash while rendering a hover float),
    -- without needing a full :e buffer reload.
    vim.keymap.set("n", "<leader>tr", function()
      vim.treesitter.stop(0)
      vim.treesitter.start(0)
    end, { desc = "Restart treesitter highlighting for buffer" })
  end,
}
