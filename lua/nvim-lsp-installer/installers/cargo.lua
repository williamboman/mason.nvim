local process = require "nvim-lsp-installer.process"
local path = require "nvim-lsp-installer.path"

local M = {}

---@param crate string The crate to install.
function M.crate(crate)
    ---@type ServerInstallerFunction
    return function(_, callback, ctx)
        local args = { "install", "--root", ".", "--locked" }
        if ctx.requested_server_version then
            vim.list_extend(args, { "--version", ctx.requested_server_version })
        end
        vim.list_extend(args, { crate })

        ctx.receipt:with_primary_source(ctx.receipt.cargo(crate))

        process.spawn("cargo", {
            cwd = ctx.install_dir,
            args = args,
            stdio_sink = ctx.stdio_sink,
        }, callback)
    end
end

---@param root_dir string The directory to resolve the executable from.
function M.env(root_dir)
    return {
        PATH = process.extend_path { path.concat { root_dir, "bin" } },
    }
end

return M
