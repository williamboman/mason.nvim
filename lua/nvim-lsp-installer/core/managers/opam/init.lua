local Data = require "nvim-lsp-installer.data"
local path = require "nvim-lsp-installer.path"
local process = require "nvim-lsp-installer.process"

local M = {}

local list_copy = Data.list_copy

---@param packages string[] @The opam packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.packages(packages)
    ---@async
    ---@param ctx InstallContext
    return function(ctx)
        local pkgs = list_copy(packages)

        ctx.receipt:with_primary_source(ctx.receipt.opam(pkgs[1]))
        for i = 2, #pkgs do
            ctx.receipt:with_secondary_source(ctx.receipt.opam(pkgs[i]))
        end

        ctx.requested_version:if_present(function(version)
            pkgs[1] = ("%s.%s"):format(pkgs[1], version)
        end)

        ctx.spawn.opam {
            "install",
            "--destdir=.",
            "--yes",
            "--verbose",
            pkgs,
        }
    end
end

function M.env(root_dir)
    return {
        PATH = process.extend_path { path.concat { root_dir, "bin" } },
    }
end

return M
