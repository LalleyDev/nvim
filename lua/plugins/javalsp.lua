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

      -- NEW: Paths redirected to nvim-data/projects/
      jdtls_project_base = function(project_name)
        return vim.fn.stdpath("data") .. "/projects/" .. project_name
      end,

      -- Base command
      cmd = { "jdtls" },
      
      full_cmd = function(opts, project_name)
        local base = opts.jdtls_project_base(project_name)
        local new_cmd = vim.deepcopy(opts.cmd)
        
        if project_name then
          vim.list_extend(new_cmd, {
            "-configuration", base .. "/config",
            "-data", base .. "/workspace",
          })
        end
        return new_cmd
      end,
    }
  end,
  config = function(_, opts)
    local function attach_jdtls()
      local fname = vim.api.nvim_buf_get_name(0)
      local root_dir = opts.root_dir(fname)
      local project_name = opts.project_name(root_dir)

      if not project_name then return end

      local base_dir = opts.jdtls_project_base(project_name)
      
      local config = {
        cmd = opts.full_cmd(opts, project_name),
        root_dir = root_dir,
        -- Integrate blink.cmp capabilities
        capabilities = require("blink.cmp").get_lsp_capabilities(),
        
        -- This is the magic part that redirects the metadata storage
        init_options = {
          workspaceStorage = {
            storagePath = base_dir .. "/storage"
          },
        },

        settings = {
          java = {
            signatureHelp = { enabled = true },
            contentProvider = { preferred = 'fernflower' },
            -- Prevents JDTLS from being too aggressive with project-root files
            configuration = {
              updateBuildConfiguration = "interactive",
            },
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

    -- Native Keymaps
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
