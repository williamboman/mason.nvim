local path = require "nvim-lsp-installer.path"
local fs = require "nvim-lsp-installer.fs"
local Data = require "nvim-lsp-installer.data"
local installers = require "nvim-lsp-installer.installers"
local std = require "nvim-lsp-installer.installers.std"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"

local M = {}

M.composer_cmd = platform.is_win and "composer.bat" or "composer"

---@param installer ServerInstallerFunction
local function ensure_composer(installer)
    return installers.pipe {
        std.ensure_executables {
            { "php", "php was not found in path. Refer to https://www.php.net/." },
            { M.composer_cmd, "composer was not found in path. Refer to https://getcomposer.org/download/." },
        },
        installer,
    }
end

---@param packages string[] @The Gem packages to install. The first item in this list will be the recipient of the server version, should the user request a specific one.
function M.packages(packages)
    return ensure_composer(
        ---@type ServerInstallerFunction
        function(_, callback, context)
            local c = process.chain {
                cwd = context.install_dir,
                stdio_sink = context.stdio_sink,
            }

            if not (fs.file_exists(path.concat { context.install_dir, "composer.json" })) then
                c.run(M.composer_cmd, { "init", "--no-interaction", "--stability=dev" })
                c.run(M.composer_cmd, { "config", "prefer-stable", "true" })
            end

            local pkgs = Data.list_copy(packages or {})
            if context.requested_server_version then
                -- The "head" package is the recipient for the requested version. It's.. by design... don't ask.
                pkgs[1] = ("%s:%s"):format(pkgs[1], context.requested_server_version)
            end

            c.run(M.composer_cmd, vim.list_extend({ "require" }, pkgs))
            c.spawn(callback)
        end
    )
end

function M.install()
    return ensure_composer(
        ---@type ServerInstallerFunction
        function(_, callback, context)
            process.spawn(M.composer_cmd, {
                args = {
                    "install",
                    "--no-interaction",
                    "--no-dev",
                    "--optimize-autoloader",
                    "--classmap-authoritative",
                },
                cwd = context.install_dir,
                stdio_sink = context.stdio_sink,
            }, callback)
        end
    )
end

---@param root_dir string @The directory to resolve the executable from.
---@param executable string
function M.executable(root_dir, executable)
    return path.concat { root_dir, "vendor", "bin", platform.is_win and ("%s.bat"):format(executable) or executable }
end

return M
