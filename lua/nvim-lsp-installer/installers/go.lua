local path = require("nvim-lsp-installer.path")
local shell = require("nvim-lsp-installer.installers.shell")

local M = {}

function M.packages(packages)
    return shell.raw(('export GOBIN="$PWD"; export GOPATH="$PWD"; go get %s;'):format(table.concat(packages, " ")), {
        env = {
            GO111MODULE = "on",
        },
    })
end

function M.executable(root_dir, executable)
    return path.concat { root_dir, executable }
end

return M
