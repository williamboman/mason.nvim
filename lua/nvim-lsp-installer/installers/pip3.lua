local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local shell = require "nvim-lsp-installer.installers.shell"

local M = {}

local REL_INSTALL_DIR = "venv"

function M.packages(packages)
    local venv_activate_cmd = platform.is_win() and (".\\%s\\Scripts\\activate"):format(REL_INSTALL_DIR)
        or ("source ./%s/bin/activate"):format(REL_INSTALL_DIR)

    return shell.polyshell(
        ("python3 -m venv %q && %s && pip3 install -U %s"):format(
            REL_INSTALL_DIR,
            venv_activate_cmd,
            table.concat(packages, " ")
        )
    )
end

function M.executable(root_dir, executable)
    return path.concat { root_dir, REL_INSTALL_DIR, platform.is_win() and "Scripts" or "bin", executable }
end

return M
