local java_filetypes = { "java" }

local function get_short_path(path)
  -- Windows helper: convert long paths to short paths when possible.
  -- This can help with paths that contain spaces.
  vim.fn.mkdir(path, "p")

  if vim.fn.has("win32") == 0 then
    return path
  end

  local cmd = 'cmd /c for %i in ("' .. path .. '") do @echo %~si'
  local handle = io.popen(cmd) if not handle then
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
    local bundles = {}

    ------------------------------------------------------------------------
    -- Java Debug Adapter
    ------------------------------------------------------------------------

    local ok, mason_registry = pcall(require, "mason-registry")

    if ok then
      local java_debug = mason_registry.get_package("java-debug-adapter")

      if java_debug:is_installed() then
        local java_debug_path = java_debug:get_install_path()

        local debug_bundle = vim.fn.glob(
          java_debug_path
          .. "/extension/server/com.microsoft.java.debug.plugin-*.jar",
          true
        )

        if debug_bundle ~= "" then
          table.insert(bundles, debug_bundle)
        else
          vim.notify(
            "Java debug adapter JAR was not found",
            vim.log.levels.WARN
          )
        end
      else
        vim.notify(
          "java-debug-adapter is not installed. Install it with :Mason",
          vim.log.levels.WARN
        )
      end
    end

    ------------------------------------------------------------------------
    -- JDTLS command
    ------------------------------------------------------------------------

    local lombok_jar =
    vim.fn.expand("$MASON/share/jdtls/lombok.jar")

    local base_cmd = {
      vim.fn.exepath("jdtls"),
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

    ------------------------------------------------------------------------
    -- Return JDTLS options
    ------------------------------------------------------------------------

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
      end,

      jdtls_config_dir = function(project_name)
        local config =
        vim.fn.stdpath("cache")
        .. "/jdtls/"
        .. project_name
        .. "/config"

        return get_short_path(config)
      end,

      jdtls_workspace_dir = function(project_name)
        local workspace =
        vim.fn.stdpath("cache")
        .. "/jdtls/"
        .. project_name
        .. "/workspace"

        return get_short_path(workspace)
      end,

      cmd = base_cmd,

      full_cmd = function(jdtls_opts)
        local fname = vim.api.nvim_buf_get_name(0)

        local root_dir =
        jdtls_opts.root_dir(fname)

        local project_name =
        jdtls_opts.project_name(root_dir)

        local new_cmd =
        vim.deepcopy(jdtls_opts.cmd)

        if project_name then
          vim.list_extend(new_cmd, {
            "-configuration",
            jdtls_opts.jdtls_config_dir(project_name),

            "-data",
            jdtls_opts.jdtls_workspace_dir(project_name),
          })
        end

        return new_cmd
      end,
    }
  end,

  config = function(_, opts)

    ------------------------------------------------------------------------
    -- Configure Java DAP
    ------------------------------------------------------------------------

    local dap = require("dap")

    dap.configurations.java = {
      {
        type = "java",
        request = "launch",
        name = "Debug Current Java Class",

        mainClass = function()
          local file = vim.fn.expand("%:p")

          -- Remove the Maven source directory from the path.
          local relative =
          file:match("src/main/java/(.+)%.java$")
          or file:match("src/test/java/(.+)%.java$")

          if relative then
            -- Convert:
            --
            -- com/example/Main
            --
            -- into:
            --
            -- com.example.Main
            return (relative:gsub("[/\\]", "."))
          end

          -- Fallback to the current filename.
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

    ------------------------------------------------------------------------
    -- Start / attach JDTLS
    ------------------------------------------------------------------------

    local function attach_jdtls()
      local fname = vim.api.nvim_buf_get_name(0)

      if fname == "" then
        return
      end

      local root_dir = opts.root_dir(fname)

      if not root_dir then
        vim.notify(
          "Could not find Java project root",
          vim.log.levels.WARN
        )
        return
      end

      ----------------------------------------------------------------------
      -- Blink capabilities
      ----------------------------------------------------------------------

      local caps =
      require("blink.cmp").get_lsp_capabilities()

      caps = vim.tbl_deep_extend("force", caps, {
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
      })

      -- Remove resolve support to avoid the JDTLS completion issue you were
      -- working around.
      caps.textDocument.completion.completionItem.resolveSupport = nil

      ----------------------------------------------------------------------
      -- JDTLS configuration
      ----------------------------------------------------------------------

      local config = {
        cmd = opts.full_cmd(opts),

        root_dir = root_dir,

        capabilities = caps,

        init_options = {
          bundles = opts.bundles,
        },

        settings = {
          java = {
            signatureHelp = {
              enabled = true,
            },

            contentProvider = {
              preferred = "fernflower",
            },
          },
        },

        --------------------------------------------------------------------
        -- JDTLS attached
        --------------------------------------------------------------------

        on_attach = function(_, bufnr)
          ------------------------------------------------------------------
          -- Setup Java debugger
          ------------------------------------------------------------------

          local jdtls = require("jdtls")

          jdtls.setup_dap({
            hotcodereplace = "auto",
          })

          ------------------------------------------------------------------
          -- Keymaps
          ------------------------------------------------------------------

          local map = function(lhs, rhs, desc)
            vim.keymap.set( "n", lhs, rhs, { buffer = bufnr, desc = desc, })
          end

          map( "<leader>co", jdtls.organize_imports, "Organize Imports")

          map( "<leader>cr", vim.lsp.buf.rename, "Rename")

          map( "<leader>ca", vim.lsp.buf.code_action, "Code Action")
        end,
      }

      require("jdtls").start_or_attach(config)
    end

    ------------------------------------------------------------------------
    -- Start JDTLS when opening Java files
    ------------------------------------------------------------------------

    vim.api.nvim_create_autocmd("FileType", {
      pattern = java_filetypes,
      callback = attach_jdtls,
    })

    ------------------------------------------------------------------------
    -- If we're already in a Java file
    ------------------------------------------------------------------------

    if vim.bo.filetype == "java" then
      attach_jdtls()
    end
  end,
}
