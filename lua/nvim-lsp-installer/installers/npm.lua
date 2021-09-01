local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local shell = require "nvim-lsp-installer.installers.shell"

local M = {}

function M.packages(packages)
    return shell.polyshell(("npm install %s"):format(table.concat(packages, " ")))
end

function M.executable(root_dir, executable)
    return path.concat {
        root_dir,
        "node_modules",
        ".bin",
        platform.is_win() and ("%s.cmd"):format(executable) or executable,
    }
end

return M
