local path = require "nvim-lsp-installer.path"
local fs = require "nvim-lsp-installer.fs"
local Data = require "nvim-lsp-installer.data"
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
        local pkgs = Data.list_copy(packages or {})
        local c = process.chain {
            cwd = server.root_dir,
            stdio_sink = context.stdio_sink,
        }
        -- stylua: ignore start
        if not (fs.dir_exists(path.concat { server.root_dir, "node_modules" }) or
               fs.file_exists(path.concat { server.root_dir, "package.json" }))
        then
            c.run(npm, { "init", "--yes", "--scope=lsp-installer" })
        end

        if context.requested_server_version and #pkgs > 0 then
            -- The "head" package is the recipient for the requested version. It's.. by design... don't ask.
            pkgs[1] = ("%s@%s"):format(pkgs[1], context.requested_server_version)
        end

        -- stylua: ignore end
        c.run(npm, vim.list_extend({ "install" }, pkgs))
        c.spawn(callback)
    end)
end

-- @alias for packages
M.install = M.packages

function M.exec(executable, args)
    return function(server, callback, context)
        process.spawn(M.executable(server.root_dir, executable), {
            args = args,
            cwd = server.root_dir,
            stdio_sink = context.stdio_sink,
        }, callback)
    end
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
