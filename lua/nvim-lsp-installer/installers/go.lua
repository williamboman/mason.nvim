require "nvim-lsp-installer.notify"(
    (
        "%s has been deprecated. See https://github.com/williamboman/nvim-lsp-installer/wiki/Async-infrastructure-changes-notice"
    ):format "nvim-lsp-installer.installers.go",
    vim.log.levels.WARN
)

local std = require "nvim-lsp-installer.installers.std"
local installers = require "nvim-lsp-installer.installers"
local process = require "nvim-lsp-installer.process"

local M = {}

---@param packages string[] The Go packages to install. The first item in this list will be the recipient of the server version, should the user request a specific one.
function M.packages(packages)
    return installers.pipe {
        std.ensure_executables { { "go", "go was not found in path, refer to https://golang.org/doc/install." } },
        ---@type ServerInstallerFunction
        function(_, callback, ctx)
            local c = process.chain {
                env = process.graft_env {
                    GOBIN = ctx.install_dir,
                },
                cwd = ctx.install_dir,
                stdio_sink = ctx.stdio_sink,
            }

            -- Install the head package
            do
                local head_package = packages[1]
                ctx.receipt:with_primary_source(ctx.receipt.go(head_package))
                local version = ctx.requested_server_version or "latest"
                c.run("go", { "install", "-v", ("%s@%s"):format(head_package, version) })
            end

            -- Install secondary packages
            for i = 2, #packages do
                local package = packages[i]
                ctx.receipt:with_secondary_source(ctx.receipt.go(package))
                c.run("go", { "install", "-v", ("%s@latest"):format(package) })
            end

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
