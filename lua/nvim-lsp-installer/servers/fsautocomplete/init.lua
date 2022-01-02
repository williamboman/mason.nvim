local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.process"
local std = require "nvim-lsp-installer.installers.std"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "f#" },
        homepage = "https://github.com/fsharp/FsAutoComplete",
        installer = {
            std.ensure_executables {
                {
                    "dotnet",
                    "dotnet was not found in path. Refer to https://dotnet.microsoft.com/download for installation instructions.",
                },
            },
            ---@type ServerInstallerFunction
            function(_, callback, ctx)
                process.spawn("dotnet", {
                    args = { "tool", "update", "--tool-path", ".", "fsautocomplete" },
                    cwd = ctx.install_dir,
                    stdio_sink = ctx.stdio_sink,
                }, function(success)
                    if not success then
                        ctx.stdio_sink.stderr "Failed to install fsautocomplete.\n"
                        callback(false)
                    else
                        callback(true)
                    end
                end)
            end,
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
