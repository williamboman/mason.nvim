local path = require "nvim-lsp-installer.path"
local process = require "nvim-lsp-installer.process"

local M = {}

function M.packages(packages)
    return function(server, callback, context)
        local c = process.chain {
            env = process.graft_env {
                GO111MODULE = "on",
                GOBIN = server.root_dir,
                GOPATH = server.root_dir,
            },
            cwd = server.root_dir,
            stdio_sink = context.stdio_sink,
        }

        c.run("go", vim.list_extend({ "get", "-v" }, packages))
        c.run("go", { "clean", "-modcache" })

        c.spawn(callback)
    end
end

function M.executable(root_dir, executable)
    return path.concat { root_dir, executable }
end

return M
