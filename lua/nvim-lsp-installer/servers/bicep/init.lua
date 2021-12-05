local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "bicep" },
        homepage = "https://github.com/Azure/bicep",
        installer = {
            std.ensure_executables {
                { "dotnet", "dotnet is required to run the bicep language server." },
            },
            -- The bicep-langserver.zip is a bit broken on POSIX systems - so we download it via the VSCode distribution
            -- instead. See https://github.com/Azure/bicep/issues/3704.
            context.use_github_release_file("Azure/bicep", "vscode-bicep.vsix"),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file, "vscode")
            end),
            std.rename(path.concat { "vscode", "extension", "bicepLanguageServer" }, "langserver"),
            std.rmrf "vscode",
            context.set_working_dir "langserver",
        },
        default_options = {
            cmd = { "dotnet", path.concat { root_dir, "Bicep.LangServer.dll" } },
        },
    }
end
