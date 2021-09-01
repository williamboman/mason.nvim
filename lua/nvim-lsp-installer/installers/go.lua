local path = require "nvim-lsp-installer.path"
local shell = require "nvim-lsp-installer.installers.shell"

local M = {}

function M.packages(packages)
    return function(server, callback)
        local shell_installer = shell.polyshell(
            ("go get -v %s && go clean -modcache"):format(table.concat(packages, " ")),
            {
                env = {
                    GO111MODULE = "on",
                    GOBIN = server._root_dir,
                    GOPATH = server._root_dir,
                },
            }
        )

        shell_installer(server, callback)
    end
end

function M.executable(root_dir, executable)
    return path.concat { root_dir, executable }
end

return M
