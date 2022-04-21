require "nvim-lsp-installer.notify"(
    (
        "%s has been deprecated. See https://github.com/williamboman/nvim-lsp-installer/wiki/Async-infrastructure-changes-notice"
    ):format "nvim-lsp-installer.installers.gem",
    vim.log.levels.WARN
)

local path = require "nvim-lsp-installer.path"
local Data = require "nvim-lsp-installer.data"
local process = require "nvim-lsp-installer.process"
local installers = require "nvim-lsp-installer.installers"
local std = require "nvim-lsp-installer.installers.std"
local platform = require "nvim-lsp-installer.platform"

local M = {}

M.gem_cmd = platform.is_win and "gem.cmd" or "gem"

---@param packages string[] @The Gem packages to install. The first item in this list will be the recipient of the server version, should the user request a specific one.
function M.packages(packages)
    return installers.pipe {
        std.ensure_executables {
            { "ruby", "ruby was not found in path, refer to https://wiki.openstack.org/wiki/RubyGems." },
            { "gem", "gem was not found in path, refer to https://wiki.openstack.org/wiki/RubyGems." },
        },
        ---@type ServerInstallerFunction
        function(_, callback, ctx)
            local pkgs = Data.list_copy(packages or {})

            ctx.receipt:with_primary_source(ctx.receipt.gem(pkgs[1]))
            for i = 2, #pkgs do
                ctx.receipt:with_secondary_source(ctx.receipt.gem(pkgs[i]))
            end

            if ctx.requested_server_version then
                -- The "head" package is the recipient for the requested version. It's.. by design... don't ask.
                pkgs[1] = ("%s:%s"):format(pkgs[1], ctx.requested_server_version)
            end

            process.spawn(M.gem_cmd, {
                args = {
                    "install",
                    "--no-user-install",
                    "--install-dir=.",
                    "--bindir=bin",
                    "--no-document",
                    table.concat(pkgs, " "),
                },
                cwd = ctx.install_dir,
                stdio_sink = ctx.stdio_sink,
            }, callback)
        end,
    }
end

---@param root_dir string
function M.env(root_dir)
    return {
        GEM_HOME = root_dir,
        GEM_PATH = root_dir,
        PATH = process.extend_path { path.concat { root_dir, "bin" } },
    }
end

return M
