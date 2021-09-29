local M = {}

local uname = vim.loop.os_uname()

local arch_aliases = {
    ["x86_64"] = "x64",
    ["aarch64"] = "arm64",
}

M.arch = arch_aliases[uname.machine] or uname.machine

M.is_win = vim.fn.has "win32" == 1
M.is_unix = vim.fn.has "unix" == 1
M.is_mac = vim.fn.has "mac" == 1
M.is_linux = not M.is_mac and M.is_unix

-- PATH separator
M.path_sep = M.is_win and ";" or ":"

return M
