-- Task runner that reads .vscode/tasks.json and runs launch.json
-- "preLaunchTask"/"postDebugTask" for nvim-dap (which ignores them itself).
return {
  "stevearc/overseer.nvim",
  cmd = { "OverseerRun", "OverseerToggle" },
  opts = {
    -- enabled from dap.lua instead, once nvim-dap itself is loaded
    dap = false,
  },
}
