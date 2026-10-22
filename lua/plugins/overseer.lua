-- Task runner that reads .vscode/tasks.json and runs launch.json
-- "preLaunchTask"/"postDebugTask" for nvim-dap (which ignores them itself).
return {
  "stevearc/overseer.nvim",
  cmd = { "OverseerRun", "OverseerToggle" },
  keys = {
    { "<leader>or", "<cmd>OverseerRun<CR>",        desc = "Run task" },
    { "<leader>ot", "<cmd>OverseerToggle!<CR>",    desc = "Toggle task list" },
    { "<leader>os", "<cmd>OverseerShell<CR>",      desc = "Run shell command as task" },
    { "<leader>oa", "<cmd>OverseerTaskAction<CR>", desc = "Task action (restart, stop, ...)" },
  },
  opts = {
    -- enabled from dap.lua instead, once nvim-dap itself is loaded
    dap = false,
  },
}
