local Pkg = require "mason-core.package"
local path = require "mason-core.path"
local std = require "mason-core.managers.std"
local github = require "mason-core.managers.github"

return Pkg.new {
    name = "bicep-lsp",
    desc = [[Bicep is a declarative language for describing and deploying Azure resources]],
    homepage = "https://github.com/Azure/bicep",
    languages = { Pkg.Lang.Bicep },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        std.ensure_executable("dotnet", { help_url = "https://dotnet.microsoft.com/download" })
        ctx.fs:mkdir "vscode"
        ctx:chdir("vscode", function()
            -- The bicep-langserver.zip is a bit broken on POSIX systems - so we download it via the VSCode distribution
            -- instead. See https://github.com/Azure/bicep/issues/3704.
            github
                .unzip_release_file({
                    repo = "Azure/bicep",
                    asset_file = "vscode-bicep.vsix",
                })
                .with_receipt()
        end)
        ctx.fs:rename(path.concat { "vscode", "extension", "bicepLanguageServer" }, "bicepLanguageServer")
        ctx.fs:rmrf "vscode"

        ctx:link_bin(
            "bicep-lsp",
            ctx:write_shell_exec_wrapper(
                "bicep-lsp",
                ("dotnet %q"):format(path.concat {
                    ctx.package:get_install_path(),
                    "bicepLanguageServer",
                    "Bicep.LangServer.dll",
                })
            )
        )
    end,
}
