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

function M.install()
    return ensure_composer(
        ---@type ServerInstallerFunction
        function(_, callback, ctx)
            process.spawn(M.composer_cmd, {
                args = {
                    "install",
                    "--no-interaction",
                    "--no-dev",
                    "--optimize-autoloader",
                    "--classmap-authoritative",
                },
                cwd = ctx.install_dir,
                stdio_sink = ctx.stdio_sink,
            }, callback)
        end
    )
end

return M
