local process = require "nvim-lsp-installer.process"
local path = require "nvim-lsp-installer.path"

local M = {}

---@param crates string[] The crates to install.
function M.crates(crates)
    ---@type ServerInstallerFunction
    return function(_, callback, ctx)
        local args = { "install", "--root", ".", "--locked" }
        if ctx.requested_server_version then
            vim.list_extend(args, { "--version", ctx.requested_server_version })
        end
        vim.list_extend(args, crates)

        process.spawn("cargo", {
            cwd = ctx.install_dir,
            args = args,
            stdio_sink = ctx.stdio_sink,
        }, callback)
    end
end

---@param root_dir string The directory to resolve the executable from.
---@param executable string
function M.executable(root_dir, executable)
    return path.concat { root_dir, "bin", executable }
end

return M
