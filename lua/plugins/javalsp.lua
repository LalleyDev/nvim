local java_filetypes = { "java" }

-- Windows helper: convert long paths to short paths when possible.

local function get_short_path(path)
  vim.fn.mkdir(path, "p")

  if vim.fn.has("win32") == 0 then
    return path
  end

  local cmd = 'cmd /c for %i in ("' .. path .. '") do @echo %~si'
  local handle = io.popen(cmd)

  if not handle then
    return path
  end

  local result = handle:read("*a")
  handle:close()

  local short = result:gsub("%s+", "")

  return short ~= "" and short or path
end

return {
  "mfussenegger/nvim-jdtls",
  ft = java_filetypes,

  dependencies = {
    "mfussenegger/nvim-dap",
    "williamboman/mason.nvim",
  },

  opts = function()
    --------------------------------------------------------------------------
    -- Java Debug Adapter bundles
    --------------------------------------------------------------------------

    local bundles = {}

    local ok, mason_registry = pcall(require, "mason-registry")

    if ok and mason_registry.has_package("java-debug-adapter") then
      local java_debug =
          mason_registry.get_package("java-debug-adapter")

      if java_debug:is_installed() then
        local java_debug_path =
            java_debug:get_install_path()

        local debug_bundles = vim.fn.glob(
          java_debug_path
          .. "/extension/server/com.microsoft.java.debug.plugin-*.jar",
          true,
          true
        )

        vim.list_extend(bundles, debug_bundles)

        if #debug_bundles == 0 then
          vim.notify(
            "java-debug-adapter is installed, but its debug JAR was not found",
            vim.log.levels.WARN
          )
        end
      else
        vim.notify(
          "java-debug-adapter is not installed. Install it with :Mason",
          vim.log.levels.WARN
        )
      end
    else
      vim.notify(
        "Mason package java-debug-adapter was not found",
        vim.log.levels.WARN
      )
    end

    --------------------------------------------------------------------------
    -- JDTLS command
    --------------------------------------------------------------------------

    local lombok_jar =
        vim.fn.expand("$MASON/share/jdtls/lombok.jar")

    local jdtls_path = vim.fn.exepath("jdtls")

    if jdtls_path == "" then
      vim.notify(
        "jdtls executable was not found in PATH",
        vim.log.levels.ERROR
      )
    end

    local base_cmd = {
      jdtls_path,
      "--jvm-arg=-Djava.import.generatesMetadataFilesAtProjectRoot=false",
      "--jvm-arg=-Xmx8G",
    }

    if vim.fn.filereadable(lombok_jar) == 1 then
      table.insert(
        base_cmd,
        string.format(
          "--jvm-arg=-javaagent:%s",
          lombok_jar
        )
      )
    end

    --------------------------------------------------------------------------
    -- JDTLS options
    --------------------------------------------------------------------------

    return {
      bundles = bundles,

      root_dir = function(path)
        return vim.fs.root(path, {
          "pom.xml",
          "build.gradle",
          "settings.gradle",
          ".git",
        })
      end,

      project_name = function(root_dir)
        if root_dir then
          return vim.fs.basename(root_dir)
        end

        return nil
      end,

      jdtls_config_dir = function(project_name)
        local config =
            vim.fn.stdpath("data")
            .. "/jdtls/"
            .. project_name
            .. "/config"

        return get_short_path(config)
      end,

      jdtls_workspace_dir = function(project_name)
        local workspace =
            vim.fn.stdpath("data")
            .. "/jdtls/"
            .. project_name
            .. "/workspace"

        return get_short_path(workspace)
      end,

      cmd = base_cmd,

      full_cmd = function(jdtls_opts)
        local fname =
            vim.api.nvim_buf_get_name(0)

        local root_dir =
            jdtls_opts.root_dir(fname)

        local project_name =
            jdtls_opts.project_name(root_dir)

        local cmd =
            vim.deepcopy(jdtls_opts.cmd)

        if project_name then
          vim.list_extend(cmd, {
            "-configuration",
            jdtls_opts.jdtls_config_dir(project_name),

            "-data",
            jdtls_opts.jdtls_workspace_dir(project_name),
          })
        end

        return cmd
      end,
    }
  end,

  config = function(_, opts)
    --------------------------------------------------------------------------
    -- Java DAP configuration
    --------------------------------------------------------------------------

    local dap = require("dap")

    dap.configurations.java = {
      {
        type = "java",
        request = "launch",
        name = "Debug Current Java Class",

        mainClass = function()
          local file =
              vim.fn.expand("%:p")

          local relative =
              file:match("src/main/java/(.+)%.java$")
              or file:match("src/test/java/(.+)%.java$")

          if relative then
            return (relative:gsub("[/\\]", "."))
          end

          return vim.fn.expand("%:t:r")
        end,

        projectName = function()
          local pom = vim.fs.find("pom.xml", {
            path = vim.fn.expand("%:p:h"),
            upward = true,
          })[1]

          if pom then
            return vim.fs.basename(
              vim.fs.dirname(pom)
            )
          end

          return vim.fn.fnamemodify(
            vim.fn.getcwd(),
            ":t"
          )
        end,
      },
    }


    --------------------------------------------------------------------------
    -- Start or attach JDTLS
    --------------------------------------------------------------------------

    local function attach_jdtls()
      local fname =
          vim.api.nvim_buf_get_name(0)

      if fname == "" then
        return
      end

      local root_dir =
          opts.root_dir(fname)

      if not root_dir then
        vim.notify(
          "Could not find Java project root",
          vim.log.levels.WARN
        )

        return
      end

      ------------------------------------------------------------------------
      -- Blink capabilities
      ------------------------------------------------------------------------

      local caps =
          require("blink.cmp").get_lsp_capabilities()

      caps = vim.tbl_deep_extend(
        "force",
        caps,
        {
          textDocument = {
            completion = {
              completionItem = {
                snippetSupport = false,
                labelDetailsSupport = false,
                deprecatedSupport = true,
                preselectSupport = false,
                insertReplaceSupport = false,
              },
            },
          },
        }
      )

      -- Remove resolve support to avoid the JDTLS completion issue.
      caps.textDocument.completion
      .completionItem
      .resolveSupport = nil

      ------------------------------------------------------------------------
      -- JDTLS configuration
      ------------------------------------------------------------------------
      local java_settings = {
        java = {
          import = { generatesMetadataFilesAtProjectRoot = false },
          format = { enabled = true, comments = { enabled = false } },
          signatureHelp = {
            enabled = true,
          },
          contentProvider = {
            preferred = "fernflower",
          },
        },
      }

      local config = {
        cmd = opts.full_cmd(opts),

        root_dir = root_dir,

        capabilities = caps,

        init_options = {
          bundles = opts.bundles,
          settings = java_settings,
        },
        settings = java_settings,


        ----------------------------------------------------------------------
        -- JDTLS attached
        ----------------------------------------------------------------------

        on_attach = function(client, bufnr)
          local jdtls = require("jdtls")
          -- Stop blink from sending completionItem/resolve requests.
          -- We advertise no resolveSupport (see caps above), so resolve
          -- returns nothing useful, yet blink still fires it while
          -- server_capabilities.completionProvider.resolveProvider is true.
          -- Those stale resolves are what trigger the JDTLS
          -- "Invalid completion proposal" IllegalStateException in the log.
          --------------------------------------------------------------------

          if client.server_capabilities.completionProvider then
            client.server_capabilities
            .completionProvider
            .resolveProvider = false
          end

          --------------------------------------------------------------------
          -- Java keymaps
          --------------------------------------------------------------------

          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc, })
          end

          map("<leader>co", jdtls.organize_imports, "Organize Imports")
          map("<leader>cr", vim.lsp.buf.rename, "Rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Code Action")

          map("<leader>cdb", dap.toggle_breakpoint, "Toggle Breakpoint")
          map("<leader>cds", dap.continue, "Start Debug")

          -- local dapui = require("dapui")
          -- local widgets = require("dap.ui.widgets")

          -- Session control
          -- map("<leader>cdc", dap.continue, "Continue / Start")
          -- map("<leader>cdr", dap.restart, "Restart Session")
          -- map("<leader>cdl", dap.run_last, "Run Last Config")
          -- map("<leader>cdx", dap.terminate, "Terminate Session")
          -- map("<leader>cdd", dap.disconnect, "Disconnect")
          -- map("<leader>cdp", dap.pause, "Pause Thread")
          --
          -- -- Stepping
          -- map("<leader>cdo", dap.step_over, "Step Over")
          -- map("<leader>cdi", dap.step_into, "Step Into")
          -- map("<leader>cdO", dap.step_out, "Step Out")
          -- map("<leader>cdC", dap.run_to_cursor, "Run to Cursor")
          -- map("<leader>cdg", dap.goto_, "Jump to Line (skip execution)")
          --
          -- -- Breakpoints
          -- map("<leader>cdb", dap.toggle_breakpoint, "Toggle Breakpoint")
          -- map("<leader>cdB", function()
          --   dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
          -- end, "Conditional Breakpoint")
          -- map("<leader>cdL", function()
          --   dap.set_breakpoint(nil, nil, vim.fn.input("Log message: "))
          -- end, "Log Point")
          -- map("<leader>cdE", function()
          --   dap.set_exception_breakpoints({ "all" })
          -- end, "Break on Exceptions")
          -- map("<leader>cdX", dap.clear_breakpoints, "Clear All Breakpoints")
          --
          -- -- Stack navigation
          -- map("<leader>cdk", dap.up, "Up Stack Frame")
          -- map("<leader>cdj", dap.down, "Down Stack Frame")

          -- Inspection
          -- map("<leader>cdh", widgets.hover, "Hover Value")
          -- map("<leader>cdv", function()
          --   widgets.centered_float(widgets.scopes)
          -- end, "Scopes (float)")
          -- map("<leader>cdf", function()
          --   widgets.centered_float(widgets.frames)
          -- end, "Frames (float)")
          -- map("<leader>cdt", function()
          --   widgets.centered_float(widgets.threads)
          -- end, "Threads (float)")
          -- map("<leader>cde", dapui.eval, "Eval Expression")
          -- map("<leader>cdE", function()
          --   dapui.eval(vim.fn.input("Expression: "))
          -- end, "Eval Input")
          --
          -- -- UI / REPL
          -- map("<leader>cdu", dapui.toggle, "Toggle DAP UI")
          -- map("<leader>cdR", dap.repl.toggle, "Toggle REPL")
        end,
      }

      local jdtls = require("jdtls")

      jdtls.start_or_attach(config)

      ------------------------------------------------------------------------
      -- Configure DAP after JDTLS has started.
      ------------------------------------------------------------------------

      vim.schedule(function()
        jdtls.setup_dap({
          hotcodereplace = "auto",
        })
      end)
    end



    --------------------------------------------------------------------------
    -- Attach when opening Java files
    --------------------------------------------------------------------------

    vim.api.nvim_create_autocmd("FileType", {
      pattern = java_filetypes,
      callback = attach_jdtls,
    })

    --------------------------------------------------------------------------
    -- Attach immediately if already in a Java file
    --------------------------------------------------------------------------

    if vim.bo.filetype == "java" then
      attach_jdtls()
    end
  end,
}
