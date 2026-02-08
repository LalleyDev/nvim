return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
    auto_installed = true,
    lazy = false,
    sync_install = false,
    highlight = {enable = true},
    indent = {enable = true},
}
