-- lua/plugins/dap.lua
return {
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      -- Required by nvim-dap-ui v3+. Omitting it gives a
      -- "module 'nio' not found" error on first launch.
      "nvim-neotest/nvim-nio",
    },
    -- Loaded on demand by the java spec's dependencies, but also expose
    -- these so it works standalone in other languages.
    keys = {
      {
        "<leader>cdu",
        function() require("dapui").toggle() end,
        desc = "Toggle DAP UI",
      },
      {
        "<leader>cde",
        function() require("dapui").eval() end,
        mode = { "n", "v" },
        desc = "Eval Expression",
      },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dap.defaults.java.console = "internalConsole"

      dapui.setup({
        icons = { expanded = "", collapsed = "", current_frame = "" },
        layouts = {
          {
            position = "left",
            size = 40,
            elements = {
              { id = "scopes",      size = 0.35 },
              { id = "breakpoints", size = 0.20 },
              { id = "stacks",      size = 0.25 },
              { id = "watches",     size = 0.20 },
            },
          },
          {
            position = "bottom",
            size = 12,
            elements = {
              { id = "repl",    size = 0.5 },
              { id = "console", size = 0.5 },
            },
          },
        },
        floating = {
          border = "rounded",
          mappings = { close = { "q", "<Esc>" } },
        },
      })

      ------------------------------------------------------------------------
      -- Open/close the UI automatically with the session.
      -- The named key (dapui_config) makes these idempotent, so re-sourcing
      -- this file will not stack duplicate listeners.
      ------------------------------------------------------------------------
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

      ------------------------------------------------------------------------
      -- Breakpoint signs
      ------------------------------------------------------------------------
      vim.fn.sign_define("DapBreakpoint", {
        text = "●",
        texthl = "DiagnosticError",
        numhl = "",
      })
      vim.fn.sign_define("DapBreakpointCondition", {
        text = "◆",
        texthl = "DiagnosticWarn",
        numhl = "",
      })
      vim.fn.sign_define("DapLogPoint", {
        text = "◆",
        texthl = "DiagnosticInfo",
        numhl = "",
      })
      vim.fn.sign_define("DapStopped", {
        text = "▶",
        texthl = "DiagnosticOk",
        linehl = "Visual",
        numhl = "",
      })
      vim.fn.sign_define("DapBreakpointRejected", {
        text = "○",
        texthl = "DiagnosticHint",
        numhl = "",
      })
    end,
  },

  ----------------------------------------------------------------------------
  -- Inline variable values next to the source while stopped.
  ----------------------------------------------------------------------------
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {
      enabled = true,
      commented = false,
      virt_text_pos = "eol",
      -- Java stack frames can produce very long inline values.
      display_callback = function(variable)
        local value = variable.value:gsub("%s+", " ")
        if #value > 60 then
          value = value:sub(1, 57) .. "..."
        end
        return " " .. variable.name .. " = " .. value
      end,
    },
  },
}
