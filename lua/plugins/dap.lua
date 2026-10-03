-- lua/plugins/dap.lua
--
-- nvim-dap reads ./.vscode/launch.json (comments allowed, trailing commas not)
-- on every dap.continue(), so launch configs work in any project as long as
-- each config's "type" has an adapter below (or, for "java", from jdtls).
-- The configurations below show up alongside launch.json ones in the picker.
--
-- Keymaps live in lsp-config.lua; they require("dap"), which loads this spec.

-- vscode-js-debug, which serves the node/chrome launch.json types
local js_debug = vim.fn.stdpath("data") .. "/mason/bin/js-debug-adapter"

local js_filetypes = {
  "javascript", "typescript", "javascriptreact", "typescriptreact", "vue", "svelte",
}

local function ensure_js_debug()
  if vim.fn.executable(js_debug) == 1 then
    return
  end
  local registry = require("mason-registry")
  registry.refresh(function()
    local ok, pkg = pcall(registry.get_package, "js-debug-adapter")
    if ok and not pkg:is_installed() and not pkg:is_installing() then
      vim.notify("Installing js-debug-adapter", vim.log.levels.INFO)
      pkg:install()
    end
  end)
end

local function setup_js_adapters(dap)
  for _, type in ipairs({ "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal" }) do
    dap.adapters[type] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = { command = js_debug, args = { "${port}" } },
    }
  end
  -- VS Code still accepts the old "node"/"chrome" type names and routes them
  -- to js-debug's pwa-* types; do the same so existing launch.json files work.
  for _, type in ipairs({ "node", "chrome", "msedge" }) do
    dap.adapters[type] = function(callback, config)
      config.type = "pwa-" .. type
      callback(dap.adapters[config.type])
    end
  end
end

-- nvim-jdtls registers the real "java" adapter, but only once jdtls attaches
-- to a Java buffer (javalsp.lua). This stand-in covers starting a launch.json
-- java config from any other buffer: it loads a Java file from the project in
-- the background, which starts jdtls, then hands off to the real adapter.
local function setup_java_bootstrap(dap)
  local function bootstrap(callback, config)
    local function fail(msg)
      dap.adapters.java = bootstrap
      vim.notify(msg, vim.log.levels.WARN)
    end

    if #vim.lsp.get_clients({ name = "jdtls" }) > 0 then
      return fail("jdtls is running but registered no debug adapter; is java-debug-adapter "
        .. "installed (:Mason)?")
    end
    local file = vim.fs.find(function(name)
      return name:match("%.java$") ~= nil
    end, { path = vim.fn.getcwd(), type = "file", limit = 1 })[1]
    if not file then
      return fail("No .java file under " .. vim.fn.getcwd() .. " to start jdtls with")
    end

    -- jdtls.setup_dap() does nothing while any java adapter is set
    dap.adapters.java = nil
    vim.notify("Starting jdtls to debug " .. config.name)
    vim.fn.bufload(vim.fn.bufadd(file))

    local timer = assert(vim.uv.new_timer())
    local waited = 0
    timer:start(250, 250, vim.schedule_wrap(function()
      waited = waited + 250
      if dap.adapters.java then
        timer:close()
        dap.adapters.java(callback, config)
      elseif waited >= 120000 then
        timer:close()
        fail("Timed out waiting for jdtls to start")
      end
    end))
  end

  if not dap.adapters.java then
    dap.adapters.java = bootstrap
  end
end

-- js-debug only probes Chrome's usual install paths, so point it at whichever
-- Chromium-based browser is actually installed.
local function find_browser()
  for _, exe in ipairs({ "chromium", "google-chrome-stable", "google-chrome", "brave" }) do
    local path = vim.fn.exepath(exe)
    if path ~= "" then
      return path
    end
  end
  return nil
end

-- package.json scripts, for picking which one to run under the debugger
local function npm_scripts()
  local ok, pkg = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile("package.json"), "\n"))
  end)
  local scripts = ok and pkg.scripts and vim.tbl_keys(pkg.scripts) or {}
  table.sort(scripts)
  return scripts
end

-- Config fields run inside a coroutine, so a field can prompt asynchronously.
local function pick_npm_script()
  local co = coroutine.running()
  local scripts = npm_scripts()
  if #scripts == 0 then
    return { "run", vim.fn.input("npm script: ", "dev") }
  end
  vim.ui.select(scripts, { prompt = "npm script" }, function(choice)
    coroutine.resume(co, choice)
  end)
  local choice = coroutine.yield()
  return choice and { "run", choice } or require("dap").ABORT
end

-- Shared by every node config: step only through project code, and follow
-- source maps (ts, vite) but not ones shipped inside node_modules.
local node_defaults = {
  cwd = "${workspaceFolder}",
  sourceMaps = true,
  skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
  resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
}

local function node(config)
  return vim.tbl_extend("force", { type = "pwa-node" }, node_defaults, config)
end

local function setup_js_configurations(dap)
  local configs = {
    -- Node >= 23.6 strips TypeScript types itself, so .ts files run directly.
    node({
      name = "Node: launch current file",
      request = "launch",
      program = "${file}",
    }),
    node({
      name = "Node: run npm script",
      request = "launch",
      runtimeExecutable = "npm",
      runtimeArgs = pick_npm_script,
      console = "integratedTerminal",
    }),
    node({
      -- for a process started with `node --inspect` (or NODE_OPTIONS=--inspect)
      name = "Node: attach to process",
      request = "attach",
      processId = function()
        return require("dap.utils").pick_process({ filter = "node" })
      end,
    }),
    {
      -- Start `npm run dev` yourself first; this debugs the browser side.
      name = "Vite: launch browser",
      type = "pwa-chrome",
      request = "launch",
      url = function()
        return vim.fn.input("Dev server URL: ", "http://localhost:5173")
      end,
      webRoot = "${workspaceFolder}",
      runtimeExecutable = find_browser(),
      sourceMaps = true,
      skipFiles = { "**/node_modules/**", "**/@vite/**" },
    },
    node({
      -- debugs vite.config.*, plugins and SSR code, not the browser bundle
      name = "Vite: debug dev server",
      request = "launch",
      runtimeExecutable = "npx",
      runtimeArgs = { "vite" },
      console = "integratedTerminal",
    }),
  }

  for _, ft in ipairs(js_filetypes) do
    dap.configurations[ft] = configs
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "williamboman/mason.nvim",
      "stevearc/overseer.nvim",
    },
    config = function()
      local dap = require("dap")
      -- runs launch.json preLaunchTask/postDebugTask from .vscode/tasks.json
      require("overseer").enable_dap()
      local dapui = require("dapui")
      -- launch.json java configs without "console" default to integratedTerminal,
      -- where java-debug waits on nvim to start the JVM in a terminal and times
      -- out ("Failed to launch debuggee in terminal"), notably on restart.
      -- internalConsole lets java-debug own the JVM, so terminate/restart also
      -- reliably kill the old process. Output is routed to the dap-ui console
      -- panel further down.
      dap.listeners.on_config.java_console = function(config)
        if config.type ~= "java" or config.console then
          return config
        end
        local copy = vim.deepcopy(config)
        copy.console = "internalConsole"
        return copy
      end

      ensure_js_debug()
      setup_js_adapters(dap)
      setup_js_configurations(dap)
      setup_java_bootstrap(dap)

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
      -- Java program output -> dap-ui console panel.
      -- internalConsole (see java_console above) sends program output as
      -- events that nvim-dap prints in the REPL. Write stdout/stderr into the
      -- console panel's buffer instead; adapter messages stay in the REPL.
      ------------------------------------------------------------------------
      local function java_console_buf()
        local buf = dapui.elements.console.buffer()
        if vim.bo[buf].buftype ~= "terminal" then
          return buf
        end
        -- An earlier integratedTerminal session (npm script, vite) left its
        -- terminal here, which can't be written to. Delete it so dap-ui makes
        -- a fresh one. dap-ui closes a panel whose buffer is swapped, so
        -- reopen the layout around the delete instead if it is showing.
        local showing = #vim.fn.win_findbuf(buf) > 0
        if showing then
          dapui.close()
        end
        vim.api.nvim_buf_delete(buf, { force = true })
        local fresh = dapui.elements.console.buffer()
        if showing then
          dapui.open()
        end
        return fresh
      end

      -- dap-ui makes the console buffer read-only
      local function set_console_lines(buf, first, last, lines)
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, first, last, false, lines)
        vim.bo[buf].modifiable = false
      end

      local function java_console_append(text)
        local buf = java_console_buf()
        local lines = vim.split((text:gsub("\r", "")), "\n", { plain = true })
        -- output arrives in chunks, not whole lines: continue the last line
        local last = vim.api.nvim_buf_line_count(buf)
        lines[1] = vim.api.nvim_buf_get_lines(buf, last - 1, last, false)[1] .. lines[1]
        set_console_lines(buf, last - 1, last, lines)
        local new_last = vim.api.nvim_buf_line_count(buf)
        for _, win in ipairs(vim.fn.win_findbuf(buf)) do
          vim.api.nvim_win_set_cursor(win, { new_last, 0 })
        end
      end

      dap.defaults.java.on_output = function(_, body)
        if body.category == "stdout" or body.category == "stderr" then
          java_console_append(body.output)
        elseif body.category ~= "telemetry" then
          require("dap.repl").append(body.output, "$", { newline = false })
        end
      end

      -- start each java session (including restarts) with an empty console
      dap.listeners.before.launch.java_console_output = function(session)
        if session.config.type == "java" then
          set_console_lines(java_console_buf(), 0, -1, {})
        end
      end

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

  {
    "rcarriga/nvim-dap-ui",
    lazy = true,
    -- Required by nvim-dap-ui v3+. Omitting it gives a
    -- "module 'nio' not found" error on first launch.
    dependencies = { "nvim-neotest/nvim-nio" },
  },

  ----------------------------------------------------------------------------
  -- Inline variable values next to the source while stopped.
  ----------------------------------------------------------------------------
  {
    "theHamsta/nvim-dap-virtual-text",
    lazy = true,
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
