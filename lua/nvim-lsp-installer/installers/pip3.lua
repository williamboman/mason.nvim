local path = require("nvim-lsp-installer.path")
local shell = require("nvim-lsp-installer.installers.shell")

local M = {}

local REL_INSTALL_DIR = "venv"

function M.packages(packages)
    return shell.raw(("./%s/bin/pip3 install -U %s"):format(REL_INSTALL_DIR, table.concat(packages, "")), {
        prefix = ("set -euo pipefail; python3 -m venv %q;"):format(REL_INSTALL_DIR)
    })
end

function M.executable(root_dir, executable)
    return path.concat { root_dir, REL_INSTALL_DIR, "bin", executable }
end

return M
