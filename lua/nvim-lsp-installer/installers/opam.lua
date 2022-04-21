require "nvim-lsp-installer.notify"(
    (
        "%s has been deprecated. See https://github.com/williamboman/nvim-lsp-installer/wiki/Async-infrastructure-changes-notice"
    ):format "nvim-lsp-installer.installers.opam",
    vim.log.levels.WARN
)

local std = require "nvim-lsp-installer.installers.std"
local installers = require "nvim-lsp-installer.installers"
local process = require "nvim-lsp-installer.process"
local path = require "nvim-lsp-installer.path"
local Data = require "nvim-lsp-installer.data"

local list_copy = Data.list_copy

local M = {}

---@param packages string[] The OPAM packages to install. The first item in this list will be the recipient of the server version, should the user request a specific one.
function M.packages(packages)
    return installers.pipe {
        std.ensure_executables {
            { "opam", "opam was not found in path, refer to https://opam.ocaml.org/doc/Install.html" },
        },
        ---@type ServerInstallerFunction
        function(_, callback, ctx)
            local pkgs = list_copy(packages)

            ctx.receipt:with_primary_source(ctx.receipt.opam(pkgs[1]))
            for i = 2, #pkgs do
                ctx.receipt:with_secondary_source(ctx.receipt.opam(pkgs[i]))
            end

            if ctx.requested_server_version then
                pkgs[1] = ("%s.%s"):format(pkgs[1], ctx.requested_server_version)
            end

            local install_args = {
                "install",
                ("--destdir=%s"):format(ctx.install_dir),
                "--yes",
                "--verbose",
            }
            vim.list_extend(install_args, pkgs)

            process.spawn("opam", {
                args = install_args,
                cwd = ctx.install_dir,
                stdio_sink = ctx.stdio_sink,
            }, callback)
        end,
    }
end

function M.env(root_dir)
    return {
        PATH = process.extend_path { path.concat { root_dir, "bin" } },
    }
end

return M
