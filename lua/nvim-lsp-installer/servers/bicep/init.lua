local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local std = require "nvim-lsp-installer.core.managers.std"
local github = require "nvim-lsp-installer.core.managers.github"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "bicep" },
        homepage = "https://github.com/Azure/bicep",
        ---@param ctx InstallContext
        installer = function(ctx)
            std.ensure_executable("dotnet", { help_url = "https://dotnet.microsoft.com/download" })
            ctx.fs:mkdir "vscode"
            ctx:chdir("vscode", function()
                -- The bicep-langserver.zip is a bit broken on POSIX systems - so we download it via the VSCode distribution
                -- instead. See https://github.com/Azure/bicep/issues/3704.
                github.unzip_release_file({
                    repo = "Azure/bicep",
                    asset_file = "vscode-bicep.vsix",
                }).with_receipt()
            end)
            ctx.fs:rename(path.concat { "vscode", "extension", "bicepLanguageServer" }, "langserver")
            ctx.fs:rmrf "vscode"
            ctx:chdir "langserver"
        end,
        default_options = {
            cmd = { "dotnet", path.concat { root_dir, "Bicep.LangServer.dll" } },
        },
    }
end
