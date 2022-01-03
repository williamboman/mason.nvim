local std = require "nvim-lsp-installer.installers.std"
local installers = require "nvim-lsp-installer.installers"
local Data = require "nvim-lsp-installer.data"
local process = require "nvim-lsp-installer.process"

local M = {}

---@param packages string[] @The Go packages to install. The first item in this list will be the recipient of the server version, should the user request a specific one.
function M.packages(packages)
    return installers.pipe {
        std.ensure_executables { { "go", "go was not found in path, refer to https://golang.org/doc/install." } },
        ---@type ServerInstallerFunction
        function(_, callback, ctx)
            local pkgs = Data.list_copy(packages or {})
            local c = process.chain {
                env = process.graft_env {
                    GO111MODULE = "on",
                    GOBIN = ctx.install_dir,
                    GOPATH = ctx.install_dir,
                },
                cwd = ctx.install_dir,
                stdio_sink = ctx.stdio_sink,
            }

            if ctx.requested_server_version then
                -- The "head" package is the recipient for the requested version. It's.. by design... don't ask.
                pkgs[1] = ("%s@%s"):format(pkgs[1], ctx.requested_server_version)
            end

            ctx.receipt:with_primary_source(ctx.receipt.go(pkgs[1]))
            for i = 2, #pkgs do
                ctx.receipt:with_secondary_source(ctx.receipt.go(pkgs[i]))
            end

            c.run("go", vim.list_extend({ "get", "-v" }, pkgs))
            c.run("go", { "clean", "-modcache" })

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
