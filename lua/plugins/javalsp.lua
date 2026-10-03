-- Java via nvim-jdtls, modeled on LazyVim's java extra:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/lang/java.lua
--
-- Differences from the previous setup, which let jdtls drift out of sync:
--   * plain blink.cmp capabilities (no stripped snippet/resolve/insertReplace
--     support and no forced resolveProvider = false)
--   * default incremental sync, no detach/re-attach resync hacks
--   * bundles found through $MASON/share, like LazyVim
--   * keymaps and dap set up on LspAttach, once jdtls is actually attached
local java_filetypes = { "java" }

-- installed by mason in addition to jdtls (which mason-lspconfig installs)
local mason_packages = { "jdtls", "java-debug-adapter", "java-test" }

-- set once jdtls has registered the real "java" dap adapter (see LspAttach)
local dap_registered = false

-- Same as vim.lsp.config.jdtls.root_markers from nvim-lspconfig: the first
-- list (multi-module / git root) wins over the second (single-module).
local root_markers = {
  { "mvnw",      "gradlew", "settings.gradle", "settings.gradle.kts", ".git" },
  { "build.xml", "pom.xml", "build.gradle",    "build.gradle.kts" },
}

local function ensure_mason_packages()
  local registry = require("mason-registry")
  registry.refresh(function()
    for _, name in ipairs(mason_packages) do
      local ok, pkg = pcall(registry.get_package, name)
      if ok and not pkg:is_installed() and not pkg:is_installing() then
        vim.notify("Installing " .. name .. " (restart nvim when it finishes)", vim.log.levels.INFO)
        pkg:install()
      end
    end
  end)
end

-- get jdtls launcher on windows even if username includes space
local function jdtls_launcher()
  if vim.fn.has("win32") == 0 then
    local exe = vim.fn.exepath("jdtls")
    return exe ~= "" and { exe } or nil
  end
  local python = vim.fn.exepath("python")
  local script = vim.fn.expand("$MASON/packages/jdtls/bin/jdtls")
  if python == "" or vim.fn.filereadable(script) == 0 then
    return nil
  end
  return { python, script }
end

-- Debug + test jars jdtls loads as plugins. The test runner jar and jacoco
-- agent ship in the same folder but are not bundles (see the nvim-jdtls README).
-- java-test also ships an unversioned copy of its plugin jar, plus asm jars
-- that jdtls already has in its own plugins/ folder; passing either makes
-- jdtls log "Failed to load extension bundles ... A bundle is already
-- installed", so both are skipped.
local function get_bundles()
  local registry = require("mason-registry")
  local bundles = {} ---@type string[]
  if registry.is_installed("java-debug-adapter") then
    bundles = vim.fn.glob("$MASON/share/java-debug-adapter/com.microsoft.java.debug.plugin-*.jar",
      false, true)
    if registry.is_installed("java-test") then
      local jdtls_plugins = {} ---@type table<string, boolean>
      for _, jar in ipairs(vim.fn.glob("$MASON/share/jdtls/plugins/*.jar", false, true)) do
        jdtls_plugins[vim.fs.basename(jar)] = true
      end
      local test_jars = vim.fn.glob("$MASON/share/java-test/*.jar", false, true)
      vim.list_extend(
        bundles,
        vim.tbl_filter(function(jar)
          return not jar:match("com%.microsoft%.java%.test%.runner%-jar%-with%-dependencies%.jar$")
              and not jar:match("jacocoagent%.jar$")
              and not jar:match("com%.microsoft%.java%.test%.plugin%.jar$")
              and not jdtls_plugins[vim.fs.basename(jar)]
        end, test_jars)
      )
    end
  end
  return bundles
end

local function set_keymaps(bufnr)
  local jdtls = require("jdtls")
  local dap = require("dap")

  local map = function(lhs, rhs, desc, mode)
    vim.keymap.set(mode or "n", lhs, rhs, { buffer = bufnr, desc = desc })
  end

  -- LSP
  map("<leader>co", jdtls.organize_imports, "Organize Imports")
  map("<leader>cr", vim.lsp.buf.rename, "Rename")
  map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { "n", "v" })
  map("<leader>cgs", jdtls.super_implementation, "Goto Super")
  map("<leader>cf", vim.lsp.buf.references, "Find All Instances")

  -- Refactoring (from LazyVim)
  map("<leader>cxv", jdtls.extract_variable_all, "Extract Variable")
  map("<leader>cxc", jdtls.extract_constant, "Extract Constant")
  map("<leader>cxm", [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], "Extract Method",
    "x")
  map("<leader>cxv", [[<ESC><CMD>lua require('jdtls').extract_variable_all(true)<CR>]],
    "Extract Variable", "x")
  map("<leader>cxc", [[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]],
    "Extract Constant", "x")

  -- Debug keymaps are global, in lsp-config.lua.

  -- Testing
  -- jdtls streams pass/fail results into the dap-repl buffer
  -- asynchronously, after the short-lived test-runner DAP session
  -- has already ended -- which is also when dapui.close() (see
  -- dap.lua) tears down its embedded repl panel. Opening the repl
  -- directly in its own bottom split, outside dapui's lifecycle,
  -- keeps it visible for the results.
  local function open_repl_bottom()
    dap.repl.open({ height = 15 }, "botright split")
  end

  map("<leader>ctc", function()
    open_repl_bottom()
    jdtls.test_class()
  end, "Test Class")
  map("<leader>ctm", function()
    open_repl_bottom()
    jdtls.test_nearest_method()
  end, "Test Nearest Method")
  map("<leader>ctp", function()
    open_repl_bottom()
    jdtls.pick_test()
  end, "Pick Test")

  -- jdtls's inline ✓/✗ marks and diagnostics reflect the *last*
  -- test run, not live compiler state -- it only clears them at
  -- the start of the next run (jdtls/junit.lua), so a stale ✗
  -- stays inline even after the underlying code is fixed and
  -- saved until you run the test again. This clears them by hand.
  map("<leader>ctx", function()
    local junit_ns = vim.api.nvim_create_namespace("junit")
    vim.api.nvim_buf_clear_namespace(bufnr, junit_ns, 0, -1)
    vim.diagnostic.reset(junit_ns, bufnr)
  end, "Clear Test Results")
end

return {
  "mfussenegger/nvim-jdtls",
  ft = java_filetypes,
  dependencies = {
    "williamboman/mason.nvim",
    "saghen/blink.cmp",
    "mfussenegger/nvim-dap",
    "rcarriga/nvim-dap-ui",
  },
  opts = function()
    local cmd = {
      -- Must be a JVM system property so it is in effect *before* the
      -- initial project import runs; sent via settings it arrives too late.
      "--jvm-arg=-Djava.import.generatesMetadataFilesAtProjectRoot=false",
      "--jvm-arg=-Xmx8G",
    }
    local lombok_jar = vim.fn.expand("$MASON/share/jdtls/lombok.jar")
    if vim.fn.filereadable(lombok_jar) == 1 then
      table.insert(cmd, string.format("--jvm-arg=-javaagent:%s", lombok_jar))
    end

    return {
      root_dir = function(path)
        return vim.fs.root(path, root_markers)
      end,

      -- How to find the project name for a given root dir.
      project_name = function(root_dir)
        return root_dir and vim.fs.basename(root_dir)
      end,

      -- Where are the config and workspace dirs for a project?
      -- stdpath("data") rather than "cache": on Windows cache is %TEMP%\nvim,
      -- which Storage Sense / Disk Cleanup can wipe, forcing a full reindex.
      jdtls_config_dir = function(project_name)
        return vim.fn.stdpath("data") .. "/jdtls/" .. project_name .. "/config"
      end,
      jdtls_workspace_dir = function(project_name)
        return vim.fn.stdpath("data") .. "/jdtls/" .. project_name .. "/workspace"
      end,

      cmd = cmd,
      full_cmd = function(opts)
        local fname = vim.api.nvim_buf_get_name(0)
        local root_dir = opts.root_dir(fname)
        local project_name = opts.project_name(root_dir)
        local full = vim.deepcopy(opts.cmd)
        if project_name then
          vim.list_extend(full, {
            "-configuration",
            opts.jdtls_config_dir(project_name),
            "-data",
            opts.jdtls_workspace_dir(project_name),
          })
        end
        return full
      end,

      dap = { hotcodereplace = "auto", config_overrides = {} },
      -- set to false to skip the main class scan (slow on large projects)
      dap_main = {},

      settings = {
        java = {
          import = { generatesMetadataFilesAtProjectRoot = false },
          format = { enabled = true, comments = { enabled = false } },
          signatureHelp = { enabled = true },
          contentProvider = { preferred = "fernflower" },
          inlayHints = {
            parameterNames = {
              enabled = "all",
            },
          },
        },
      },
    }
  end,

  config = function(_, opts)
    ensure_mason_packages()

    local bundles = get_bundles()

    local function attach_jdtls()
      local fname = vim.api.nvim_buf_get_name(0)
      if fname == "" then
        return
      end

      local launcher = jdtls_launcher()
      -- mason may have only just installed it (first start)
      if not launcher then
        vim.notify("jdtls is not installed yet; check :Mason and reopen the file",
          vim.log.levels.WARN)
        return
      end
      local cmd = vim.list_extend(launcher, opts.full_cmd(opts))

      -- Existing server will be reused if the root_dir matches.
      require("jdtls").start_or_attach({
        cmd = cmd,
        root_dir = opts.root_dir(fname),
        init_options = {
          bundles = bundles,
        },
        settings = opts.settings,
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })
    end

    -- Attach the jdtls for each java buffer. This plugin loads on the java
    -- filetype, so the autocmd doesn't run for the first file; that one is
    -- attached directly below.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("jdtls_attach", { clear = true }),
      pattern = java_filetypes,
      callback = attach_jdtls,
    })

    -- Setup keymaps and dap after the lsp is fully attached.
    -- https://github.com/mfussenegger/nvim-jdtls#nvim-dap-configuration
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("jdtls_lsp_attach", { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not (client and client.name == "jdtls") then
          return
        end

        set_keymaps(args.buf)

        if #bundles > 0 then
          -- Drop dap.lua's on-demand stand-in, or setup_dap() keeps it and
          -- never registers the real adapter. Only the first attach; after
          -- that the adapter set is jdtls's own.
          if not dap_registered then
            require("dap").adapters.java = nil
            dap_registered = true
          end
          require("jdtls").setup_dap(opts.dap)
          if opts.dap_main then
            require("jdtls.dap").setup_dap_main_class_configs(opts.dap_main)
          end
        end
      end,
    })

    -- Avoid race condition by calling attach the first time, since the autocmd won't fire.
    attach_jdtls()
  end,
}
