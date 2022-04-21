require "nvim-lsp-installer.notify"(
    (
        "%s has been deprecated. See https://github.com/williamboman/nvim-lsp-installer/wiki/Async-infrastructure-changes-notice"
    ):format "nvim-lsp-installer.installers.composer",
    vim.log.levels.WARN
)

local installers = require "nvim-lsp-installer.installers"
local std = require "nvim-lsp-installer.installers.std"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"
local fs = require "nvim-lsp-installer.fs"
local path = require "nvim-lsp-installer.path"
local Data = require "nvim-lsp-installer.data"

local list_copy = Data.list_copy

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

---@param packages string[] The composer packages to install. The first item in this list will be the recipient of the server version, should the user request a specific one.
function M.require(packages)
    return ensure_composer(
        ---@type ServerInstallerFunction
        function(_, callback, ctx)
            local pkgs = list_copy(packages)
            local c = process.chain {
                cwd = ctx.install_dir,
                stdio_sink = ctx.stdio_sink,
            }

            ctx.receipt:with_primary_source(ctx.receipt.composer(pkgs[1]))
            for i = 2, #pkgs do
                ctx.receipt:with_secondary_source(ctx.receipt.composer(pkgs[i]))
            end

            if not (fs.file_exists(path.concat { ctx.install_dir, "composer.json" })) then
                c.run(M.composer_cmd, { "init", "--no-interaction", "--stability=stable" })
            end

            if ctx.requested_server_version then
                -- The "head" package is the recipient for the requested version. It's.. by design... don't ask.
                pkgs[1] = ("%s:%s"):format(pkgs[1], ctx.requested_server_version)
            end

            c.run(M.composer_cmd, vim.list_extend({ "require" }, pkgs))
            c.spawn(callback)
        end
    )
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

---@param root_dir string The directory to resolve the executable from.
function M.env(root_dir)
    return {
        PATH = process.extend_path { path.concat { root_dir, "vendor", "bin" } },
    }
end

return M
