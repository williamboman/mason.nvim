local std = require "nvim-lsp-installer.installers.std"
local installers = require "nvim-lsp-installer.installers"
local process = require "nvim-lsp-installer.process"

local M = {}

---@param package string The Go package to install.
function M.package(package)
    return installers.pipe {
        std.ensure_executables { { "go", "go was not found in path, refer to https://golang.org/doc/install." } },
        ---@type ServerInstallerFunction
        function(_, callback, ctx)
            local c = process.chain {
                env = process.graft_env {
                    GO111MODULE = "on",
                    GOBIN = ctx.install_dir,
                    GOPATH = ctx.install_dir,
                },
                cwd = ctx.install_dir,
                stdio_sink = ctx.stdio_sink,
            }

            ctx.receipt:with_primary_source(ctx.receipt.go(package))

            local version = ctx.requested_server_version or "latest"
            local pkg = ("%s@%s"):format(package, version)

            c.run("go", { "install", "-v", pkg })

            c.spawn(callback)
        end,
    }
end

function M.env(root_dir)
    return {
        PATH = process.extend_path { root_dir },
    }
end

return M
