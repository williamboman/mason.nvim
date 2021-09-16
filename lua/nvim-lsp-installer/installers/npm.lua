local path = require "nvim-lsp-installer.path"
local installers = require "nvim-lsp-installer.installers"
local std = require "nvim-lsp-installer.installers.std"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"

local M = {}

local npm = platform.is_win and "npm.cmd" or "npm"

local function ensure_npm(installer)
    return installers.pipe {
        std.ensure_executables {
            { "node", "node was not found in path. Refer to https://nodejs.org/en/." },
            {
                "npm",
                "npm was not found in path. Refer to https://docs.npmjs.com/downloading-and-installing-node-js-and-npm.",
            },
        },
        installer,
    }
end

function M.packages(packages)
    return ensure_npm(function(server, callback, context)
        process.spawn(npm, {
            args = vim.list_extend({ "install" }, packages),
            cwd = server.root_dir,
            stdio_sink = context.stdio_sink,
        }, callback)
    end)
end

function M.install(production)
    return ensure_npm(function(server, callback, context)
        process.spawn(npm, {
            args = production and { "install", "--production" } or { "install" },
            cwd = server.root_dir,
            stdio_sink = context.stdio_sink,
        }, callback)
    end)
end

function M.run(script)
    return ensure_npm(function(server, callback, context)
        process.spawn(npm, {
            args = { "run", script },
            cwd = server.root_dir,
            stdio_sink = context.stdio_sink,
        }, callback)
    end)
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
