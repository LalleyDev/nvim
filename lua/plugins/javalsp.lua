local java_filetypes = { "java" }

return {
  "mfussenegger/nvim-jdtls",
  ft = java_filetypes,
  opts = function()
    return {
      -- Standard root detection
      root_dir = function(path)
        return vim.fs.root(path, { ".git", "pom.xml" })
      end,

      -- Project-specific workspace naming
      project_name = function(root_dir)
        return root_dir and vim.fs.basename(root_dir)
      end,

      -- Paths for JDTLS data
      jdtls_config_dir = function(project_name)
        return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/config"
      end,
      jdtls_workspace_dir = function(project_name)
        return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/workspace"
      end,

      -- Base command (assumes 'jdtls' is in your $PATH via Mason or manual install)
      cmd = { "jdtls" },
      
      full_cmd = function(opts)
        local fname = vim.api.nvim_buf_get_name(0)
        local root_dir = opts.root_dir(fname)
        local project_name = opts.project_name(root_dir)
        local new_cmd = vim.deepcopy(opts.cmd)
        
        if project_name then
          vim.list_extend(new_cmd, {
            "-configuration", opts.jdtls_config_dir(project_name),
            "-data", opts.jdtls_workspace_dir(project_name),
          })
        end
        return new_cmd
      end,
    }
  end,
  config = function(_, opts)
    local function attach_jdtls()
      local fname = vim.api.nvim_buf_get_name(0)
      
      -- Minimal config for start_or_attach
      local config = {
        cmd = opts.full_cmd(opts),
        root_dir = opts.root_dir(fname),
        -- Integrate blink.cmp capabilities here
        capabilities = require("blink.cmp").get_lsp_capabilities(),
        settings = {
          java = {
            signatureHelp = { enabled = true },
            contentProvider = { preferred = 'fernflower' },
          }
        }
      }

      require("jdtls").start_or_attach(config)
    end

    -- Create the autocmd to trigger JDTLS on Java files
    vim.api.nvim_create_autocmd("FileType", {
      pattern = java_filetypes,
      callback = attach_jdtls,
    })

    -- Native Keymaps (No Which-Key)
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == "jdtls" then
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
          end

          map("<leader>co", require("jdtls").organize_imports, "Organize Imports")
          -- map("<leader>cr", vim.lsp.buf.rename, "Rename")
          -- map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
        end
      end,
    })

    -- Run once if current file is Java
    if vim.bo.filetype == "java" then
      attach_jdtls()
    end
  end,
}
