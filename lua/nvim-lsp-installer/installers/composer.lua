local path = require "nvim-lsp-installer.path"
local fs = require "nvim-lsp-installer.fs"
local Data = require "nvim-lsp-installer.data"
local installers = require "nvim-lsp-installer.installers"
local std = require "nvim-lsp-installer.installers.std"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"

local M = {}

function M.packages(packages)
    local composer = platform.is_win and "composer.bat" or "composer"

    return installers.pipe {
        std.ensure_executables {
            { "php", "php was not found in path. Refer to https://www.php.net/." },
            { composer, "composer was not found in path. Refer to https://getcomposer.org/download/." },
        },
        function(server, callback, context)
            local c = process.chain {
                cwd = server.root_dir,
                stdio_sink = context.stdio_sink,
            }

            if not (fs.file_exists(path.concat { server.root_dir, "composer.json" })) then
                c.run(composer, { "init", "--no-interaction", "--stability=dev" })
                c.run(composer, { "config", "prefer-stable", "true" })
            end

            local pkgs = Data.list_copy(packages or {})
            if context.requested_server_version then
                -- The "head" package is the recipient for the requested version. It's.. by design... don't ask.
                pkgs[1] = ("%s:%s"):format(pkgs[1], context.requested_server_version)
            end

            c.run(composer, vim.list_extend({ "require" }, pkgs))
            c.spawn(callback)
        end,
    }
end

function M.executable(root_dir, executable)
    return path.concat { root_dir, "vendor", "bin", platform.is_win and ("%s.bat"):format(executable) or executable }
end

return M
