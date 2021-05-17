local shell = require("nvim-lsp-installer.installers.shell")

local M = {}

function M.packages(packages)
    return shell.raw(("npm install %s"):format(table.concat(packages, " ")))
end

return M
