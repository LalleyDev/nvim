return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
    ensure_installed = {"lua"},
    sync_install = false,
    highlight = {enable = true},
    indent = {enable = true},

}
