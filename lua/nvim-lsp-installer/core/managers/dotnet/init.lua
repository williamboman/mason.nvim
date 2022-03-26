local process = require "nvim-lsp-installer.process"
local M = {}

---@param package string
function M.package(package)
    ---@async
    ---@param ctx InstallContext
    return function(ctx)
        ctx.receipt:with_primary_source(ctx.receipt.dotnet(package))
        ctx.spawn.dotnet {
            "tool",
            "update",
            "--tool-path",
            ".",
            ctx.requested_version
                :map(function(version)
                    return { "--version", version }
                end)
                :or_else(vim.NIL),
            package,
        }
    end
end

function M.env(root_dir)
    return {
        PATH = process.extend_path { root_dir },
    }
end

return M
