local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"

local M = {}

function M.packages(packages)
    return function(server, callback, context)
        process.spawn(platform.is_win and "npm.cmd" or "npm", {
            args = vim.list_extend({ "install" }, packages),
            cwd = server.root_dir,
            stdio_sink = context.stdio_sink,
        }, callback)
    end
end

function M.executable(root_dir, executable)
    return path.concat {
        root_dir,
        "node_modules",
        ".bin",
        platform.is_win and ("%s.cmd"):format(executable) or executable,
    }
end

return M
