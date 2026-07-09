local java_filetypes = { "java" }

local function get_short_path(path)
  -- Ensure the directory exists before asking Windows for its short path
  vim.fn.mkdir(path, "p")
  local cmd = 'cmd /c for %i in ("' .. path .. '") do @echo %~si'
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  local short = result:gsub("%s+", "")
  -- Fall back to the original path if conversion fails
  return (short ~= "" and short or path)
end

return {
    "mfussenegger/nvim-jdtls",
    ft = java_filetypes,
    opts = function()
        local lombok_jar = vim.fn.expand("$MASON/share/jdtls/lombok.jar")
        local base_cmd = { vim.fn.exepath("jdtls") }
        if vim.fn.filereadable(lombok_jar) == 1 then
            table.insert(base_cmd, string.format("--jvm-arg=-javaagent:%s", lombok_jar))
        end
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
                local config = vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/config"
                return get_short_path(config)
            end,
            jdtls_workspace_dir = function(project_name)
                local workspace = vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/workspace"
                return get_short_path(workspace)
            end,

            cmd = base_cmd,

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
            -- Override resolve support to exclude additionalTextEdits — blink.cmp calling
            -- completionItem/resolve for additionalTextEdits causes jdtls to throw
            -- "Invalid completion proposal" when the document changes between completion
            -- and resolve, which eventually kills the LSP session.
            local caps = require("blink.cmp").get_lsp_capabilities()
            caps = vim.tbl_deep_extend("force", caps, {
                textDocument = {
                    completion = {
                        completionItem = {
                            snippetSupport = false,
                            labelDetailsSupport = false,
                            deprecatedSupport = true,
                            preselectSupport = false,
                            insertReplaceSupport = false,
                        }
                    }
                }
            })
            caps.textDocument.completion.completionItem.resolveSupport = nil
            local config = {
                cmd = opts.full_cmd(opts),
                root_dir = opts.root_dir(fname),
                capabilities = caps,
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
