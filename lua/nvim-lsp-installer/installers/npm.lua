local path = require("nvim-lsp-installer.path")
local shell = require("nvim-lsp-installer.installers.shell")

local M = {}

function M.packages(packages)
    return shell.raw(("npm install %s"):format(table.concat(packages, " ")))
end

function M.executable(root_dir, executable)
    return path.concat { root_dir, "node_modules", ".bin", executable }
end

return M
