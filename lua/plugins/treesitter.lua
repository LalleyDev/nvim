return {
  "nvim-treesitter/nvim-treesitter",
  -- The classic branch. Unlike `main`, it compiles parsers itself by
  -- invoking a C compiler directly (no tree-sitter CLI needed), and it
  -- supports zig natively -- which the `main` branch's tree-sitter build
  -- cannot use on Windows (LLVM vs zig target-triple mismatch).
  branch = "master",
  lazy = false,
  build = ":TSUpdate",

  config = function()
    -- Guard the interim: after changing `branch` above, lazy still has the
    -- old `main` checkout on disk until `:Lazy sync` runs. On `main` there
    -- is no `nvim-treesitter.configs`, so bail quietly instead of erroring
    -- on every startup until the branch is actually swapped.
    local ok, configs = pcall(require, "nvim-treesitter.configs")
    if not ok then
      return
    end

    -- Prefer zig as the compiler: a single-binary toolchain that needs no
    -- MSVC/Windows SDK. Fall back to any system compiler if present.
    require("nvim-treesitter.install").compilers = {
      "zig",
      "cc",
      "gcc",
      "clang",
      "cl",
    }

    configs.setup({
      ensure_installed = {
        "java",
        "lua",
        "vim",
        "vimdoc",
        "query",
        "bash",
        "json",
        "markdown",
      },

      sync_install = false,
      auto_install = true,

      highlight = { enable = true },

      -- Left off deliberately: custom Java indentation lives in ftplugins,
      -- and treesitter indent would fight it.
      indent = { enable = false },
    })
  end,
}
