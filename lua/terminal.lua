
-- This is the floating terminal
vim.keymap.set("n","<space>lt",function()
    vim.cmd.vnew()
    vim.cmd.term("powershell")
    vim.cmd.wincmd("J")
    vim.api.nvim_win_set_height(0,15)
    vim.cmd("startinsert")
end)


local state = {
    floating = {
        buf = -1,
        win = -1,
    }
}

local function open_floating_terminal(opts)
    opts = opts or {}
    -- Calculate dimensions (80% of editor size)
    local width = math.ceil(vim.o.columns * 0.8)
    local height = math.ceil(vim.o.lines * 0.8)
    local row = math.ceil((vim.o.lines - height) / 2 - 1)
    local col = math.ceil((vim.o.columns - width) / 2)

    -- Create the floating window configuration
    local winconfig = {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    }

    -- Create a new buffer and open the window
    --local buf = vim.api.nvim_create_buf(false, true)
    local buf = nil
    if vim.api.nvim_buf_is_valid(opts.buf) then
        buf = opts.buf
    else
        buf = vim.api.nvim_create_buf(false, true)
    end

    local win = vim.api.nvim_open_win(buf, true, winconfig)


    return{ buf = buf, win=win }

end

local toggle_terminal = function()
    if not vim.api.nvim_win_is_valid(state.floating.win) then
        state.floating = open_floating_terminal { buf = state.floating.buf }
        if vim.bo[state.floating.buf].buftype ~= "terminal" then
            vim.cmd.terminal("powershell")
            vim.cmd("startinsert")
        end
    else
        vim.api.nvim_win_hide(state.floating.win)
    end
end

vim.api.nvim_create_user_command("Floatt",toggle_terminal,{})
vim.keymap.set({"n","t"}, "<space>t", toggle_terminal)


