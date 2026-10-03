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
    -- mason-lspconfig warns and skips ensure_installed/automatic_enable if
    -- mason.setup() has not run yet; declare the edge instead of relying on
    -- lazy.nvim's spec ordering.
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        -- add the language server here first
        ensure_installed = {
          "lua_ls",
          "jdtls",
          "html",
          "cssls",
          "tailwindcss",
          "jsonls",
          "eslint",
        },
        -- Java is driven exclusively by nvim-jdtls (see javalsp.lua).
        -- Exclude jdtls here so mason-lspconfig's automatic_enable does
        -- not ALSO start a plain lspconfig jdtls client on Java buffers,
        -- which would double-attach and desync edits/completions.
        automatic_enable = {
          exclude = { "jdtls" },
        },
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "saghen/blink.cmp",
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

      vim.lsp.config("*", {
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
      -- NOTE: jdtls is intentionally NOT enabled here. It is started by
      -- nvim-jdtls in javalsp.lua. Enabling it here too would attach a
      -- second Java client and cause completion/diagnostic desyncs.
      vim.lsp.enable("lua_ls")
      vim.lsp.enable("tsc")
      vim.lsp.enable("html")
      vim.lsp.enable("cssls")
      vim.lsp.enable("tailwindcss")
      vim.lsp.enable("jsonls")
      vim.lsp.enable("eslint")
      -- lsp config keybinds
      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})

      -- debug keybinds (any language; adapters and configs are in dap.lua).
      -- Each requires dap on first use, which lazy-loads it.
      local function dap_map(lhs, fn, desc, mode)
        vim.keymap.set(mode or "n", lhs, function() fn(require("dap")) end, { desc = desc })
      end

      -- Session control
      dap_map("<leader>cds", function(dap) dap.continue() end, "Start / Continue")
      dap_map("<leader>cdr", function(dap) dap.restart() end, "Restart Session")
      dap_map("<leader>cdl", function(dap) dap.run_last() end, "Run Last Config")
      dap_map("<leader>cdx", function(dap) dap.terminate() end, "Terminate Session")
      dap_map("<leader>cdd", function(dap) dap.disconnect() end, "Disconnect")
      dap_map("<leader>cdp", function(dap) dap.pause() end, "Pause Thread")

      -- Labels of every task launch.json can start: each config's pre/post
      -- task plus their dependsOn chains from tasks.json. Read from the files
      -- rather than the live session, so this still finds a background task
      -- (e.g. a vite dev server) left running after the debuggee has exited.
      local function launch_task_labels()
        local vscode = require("dap.ext.vscode")
        local ok, configs = pcall(vscode.getconfigs)
        local depends = {}
        local tasks_path = vim.fn.getcwd() .. "/.vscode/tasks.json"
        if vim.fn.filereadable(tasks_path) == 1 then
          local text = table.concat(vim.fn.readfile(tasks_path), "\n")
          local tasks_ok, tasks = pcall(vscode.json_decode, text, { skip_comments = true })
          for _, task in ipairs(tasks_ok and tasks.tasks or {}) do
            local deps = task.dependsOn
            depends[task.label or ""] = type(deps) == "string" and { deps } or deps or {}
          end
        end

        local labels = {}
        local function add(label)
          if label and not labels[label] then
            labels[label] = true
            for _, dep in ipairs(depends[label] or {}) do
              add(dep)
            end
          end
        end
        for _, config in ipairs(ok and configs or {}) do
          add(config.preLaunchTask)
          add(config.postDebugTask)
        end
        return labels
      end

      -- Stop every debug session, the launch.json tasks overseer is running
      -- for them, and the UI.
      dap_map("<leader>cdq", function(dap)
        for _, session in pairs(dap.sessions()) do
          dap.set_session(session)
          dap.terminate()
        end

        local stopped = {}
        if package.loaded.overseer then
          local labels = launch_task_labels()
          for _, task in ipairs(require("overseer").list_tasks()) do
            if labels[task.name] then
              if task:is_running() then
                table.insert(stopped, task.name)
              end
              task:dispose(true)
            end
          end
        end

        require("dapui").close()
        vim.notify(#stopped > 0 and ("Stopped debugging and " .. table.concat(stopped, ", "))
          or "Stopped debugging")
      end, "Quit Debugging (sessions, tasks, UI)")

      -- Stepping
      dap_map("<leader>cdo", function(dap) dap.step_over() end, "Step Over")
      dap_map("<leader>cdi", function(dap) dap.step_into() end, "Step Into")
      dap_map("<leader>cdO", function(dap) dap.step_out() end, "Step Out")
      dap_map("<leader>cdC", function(dap) dap.run_to_cursor() end, "Run to Cursor")

      -- Breakpoints
      dap_map("<leader>cdb", function(dap) dap.toggle_breakpoint() end, "Toggle Breakpoint")
      dap_map("<leader>cdB", function(dap)
        vim.ui.input({ prompt = "Breakpoint condition: " }, function(cond)
          if cond then
            dap.set_breakpoint(cond)
          end
        end)
      end, "Conditional Breakpoint")
      dap_map("<leader>cdL", function(dap)
        vim.ui.input({ prompt = "Log message: " }, function(msg)
          if msg then
            dap.set_breakpoint(nil, nil, msg)
          end
        end)
      end, "Log Point")
      dap_map("<leader>cdX", function(dap) dap.clear_breakpoints() end, "Clear All Breakpoints")

      -- Stack navigation
      dap_map("<leader>cdk", function(dap) dap.up() end, "Up Stack Frame")
      dap_map("<leader>cdj", function(dap) dap.down() end, "Down Stack Frame")

      -- Inspection
      local function widget(name)
        return function()
          local widgets = require("dap.ui.widgets")
          widgets.centered_float(widgets[name])
        end
      end
      dap_map("<leader>cdh", function() require("dap.ui.widgets").hover() end, "Hover Value")
      dap_map("<leader>cdv", widget("scopes"), "Scopes (float)")
      dap_map("<leader>cdf", widget("frames"), "Frames (float)")
      dap_map("<leader>cdt", widget("threads"), "Threads (float)")
      dap_map("<leader>cde", function() require("dapui").eval() end, "Eval Expression", { "n", "v" })

      -- UI / REPL
      dap_map("<leader>cdu", function() require("dapui").toggle() end, "Toggle DAP UI")
      dap_map("<leader>cdR", function(dap) dap.repl.toggle() end, "Toggle REPL")

      -- html/cssls/jsonls/tsc can all advertise their own formattingProvider,
      -- which would race prettier (via none-ls) for the same edit. Pin
      -- formatting to a single client per filetype so saves stay deterministic.
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = true }),
        pattern = {
          "*.lua",
          "*.js", "*.jsx", "*.ts", "*.tsx",
          "*.css", "*.json",
        },
        callback = function(args)
          local is_lua = vim.bo[args.buf].filetype == "lua"
          vim.lsp.buf.format({
            bufnr = args.buf,
            async = false,
            filter = function(client)
              if is_lua then
                return client.name == "lua_ls"
              end
              return client.name == "null-ls"
            end,
          })
        end,
      })
    end
  },
}
