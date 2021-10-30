local path = require "nvim-lsp-installer.path"
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
        function(_, callback, context)
            local pkgs = Data.list_copy(packages or {})
            local c = process.chain {
                env = process.graft_env {
                    GO111MODULE = "on",
                    GOBIN = context.install_dir,
                    GOPATH = context.install_dir,
                },
                cwd = context.install_dir,
                stdio_sink = context.stdio_sink,
            }

            if context.requested_server_version then
                -- The "head" package is the recipient for the requested version. It's.. by design... don't ask.
                pkgs[1] = ("%s@%s"):format(pkgs[1], context.requested_server_version)
            end

            c.run("go", vim.list_extend({ "get", "-v" }, pkgs))
            c.run("go", { "clean", "-modcache" })

            c.spawn(callback)
        end,
    }
end

---@param root_dir string @The directory to resolve the executable from.
---@param executable string
function M.executable(root_dir, executable)
    return path.concat { root_dir, executable }
end

return M
