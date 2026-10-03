return {
  "nvim-lualine/lualine.nvim",
  config = function()
    -- A macro left recording silently disables blink.cmp (it bails out on
    -- reg_recording()), which looks exactly like "completion is broken".
    -- Surface it so an accidental `q<reg>` can't go unnoticed.
    local function macro_recording()
      local reg = vim.fn.reg_recording()
      if reg == "" then
        return ""
      end
      return "recording @" .. reg
    end

    require("lualine").setup({
      options = {
        theme = "auto"
        -- theme = "dracula"
        -- theme = 'gruvbox_dark'
      },
      -- Only lualine_c is overridden; the other sections keep their defaults.
      sections = {
        lualine_c = {
          "filename",
          { macro_recording, color = "DiagnosticWarn" },
        },
      },
    })

    -- lualine refreshes on its own timer, so without these the indicator can
    -- lag behind the moment recording starts or stops.
    vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
      group = vim.api.nvim_create_augroup("lualine_macro_indicator", { clear = true }),
      callback = function()
        -- RecordingLeave fires *before* reg_recording() clears, so defer.
        vim.schedule(function()
          require("lualine").refresh()
        end)
      end,
    })
  end
}
