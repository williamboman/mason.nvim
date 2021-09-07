local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"

local M = {}

local REL_INSTALL_DIR = "venv"

function M.packages(packages)
    return function(server, callback, context)
        local c = process.chain {
            cwd = server.root_dir,
            stdio_sink = context.stdio_sink,
        }

        c.run("python3", { "-m", "venv", REL_INSTALL_DIR })
        c.run(M.executable(server.root_dir, "pip3"), vim.list_extend({ "install", "-U" }, packages))

        c.spawn(callback)
    end
end

function M.executable(root_dir, executable)
    return path.concat { root_dir, REL_INSTALL_DIR, platform.is_win and "Scripts" or "bin", executable }
end

return M
