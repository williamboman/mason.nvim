local shell = require("nvim-lsp-installer.installers.shell")

local M = {}

M.REL_INSTALL_DIR = "venv"

function M.packages(packages)
    return shell.raw(("./%s/bin/pip3 install -U %s"):format(M.REL_INSTALL_DIR, table.concat(packages, "")), {
        prefix = ("set -euo pipefail; python3 -m venv %q;"):format(M.REL_INSTALL_DIR)
    })
end

return M
