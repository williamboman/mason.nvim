local M = {}

M.is_win = vim.fn.has "win32" == 1
M.is_unix = vim.fn.has "unix" == 1

return M
