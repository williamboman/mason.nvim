require "nvim-lsp-installer.notify"(
    (
        "%s has been deprecated. See https://github.com/williamboman/nvim-lsp-installer/wiki/Async-infrastructure-changes-notice"
    ):format "nvim-lsp-installer.installers.dotnet",
    vim.log.levels.WARN
)

local installers = require "nvim-lsp-installer.installers"
local std = require "nvim-lsp-installer.installers.std"
local process = require "nvim-lsp-installer.process"

local M = {}

---@param installer ServerInstallerFunction
local function ensure_dotnet(installer)
    return installers.pipe {
        std.ensure_executables {
            {
                "dotnet",
                "dotnet was not found in path. Refer to https://dotnet.microsoft.com/download for installation instructions.",
            },
        },
        installer,
    }
end

---@param package string
function M.package(package)
    return ensure_dotnet(
        ---@type ServerInstallerFunction
        function(_, callback, ctx)
            local args = {
                "tool",
                "update",
                "--tool-path",
                ".",
            }
            if ctx.requested_server_version then
                vim.list_extend(args, { "--version", ctx.requested_server_version })
            end
            vim.list_extend(args, { package })
            process.spawn("dotnet", {
                args = args,
                cwd = ctx.install_dir,
                stdio_sink = ctx.stdio_sink,
            }, callback)
            ctx.receipt:with_primary_source(ctx.receipt.dotnet(package))
        end
    )
end

function M.env(root_dir)
    return {
        PATH = process.extend_path { root_dir },
    }
end

return M
