local path = require("nvim-lsp-installer.path")
local shell = require("nvim-lsp-installer.installers.shell")

local M = {}

function M.packages(packages)
    return shell.raw(("go get %s"):format(table.concat(packages, " ")), {
        prefix = [[set -euo pipefail; export GO111MODULE=on; export GOBIN="$PWD"; export GOPATH="$PWD";]]
    })
end

function M.executable(root_dir, executable)
    return path.concat { root_dir, executable }
end

return M
