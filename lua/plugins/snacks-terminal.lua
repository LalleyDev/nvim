-- Toggleable terminal (snacks.nvim). Lazy merges this with the snacks spec in
-- theme.lua. The old hand-rolled terminal is kept in lua/terminal.lua.
--
-- Shell: on Linux/macOS it is $SHELL. On Windows set `windows_shell` to
-- "powershell" (pwsh if installed, else Windows PowerShell) or "gitbash";
-- if the chosen one is missing it falls back to the other.
local windows_shell = "powershell"

local function powershell()
  if vim.fn.executable("pwsh") == 1 then
    return { "pwsh", "-NoLogo" }
  end
  if vim.fn.executable("powershell") == 1 then
    return { "powershell", "-NoLogo" }
  end
end

-- Find Git Bash next to git.exe rather than taking `bash` from PATH, which on
-- Windows is often the WSL launcher in System32.
local function gitbash()
  local git = vim.fn.exepath("git")
  if git == "" then
    return
  end
  local root = vim.fs.dirname(vim.fs.dirname(git)) -- <Git>\cmd\git.exe -> <Git>
  local bash = vim.fs.joinpath(root, "bin", "bash.exe")
  if vim.fn.executable(bash) == 1 then
    return { bash, "--login", "-i" }
  end
end

local function shell_cmd()
  if vim.fn.has("win32") == 0 then
    return nil -- snacks uses vim.o.shell
  end
  if windows_shell == "gitbash" then
    return gitbash() or powershell()
  end
  return powershell() or gitbash()
end

return {
  "folke/snacks.nvim",
  opts = {
    terminal = {
      win = { position = "bottom", height = 0.3 },
    },
  },
  keys = {
    { "<space>lt", function() Snacks.terminal(shell_cmd()) end, desc = "Toggle terminal" },
  },
}
