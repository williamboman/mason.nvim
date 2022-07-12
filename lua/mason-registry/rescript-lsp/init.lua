local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

return Pkg.new {
    name = "rescript-lsp",
    desc = [[Language Server for ReScript.]],
    homepage = "https://github.com/rescript-lang/rescript-vscode",
    languages = { Pkg.Lang.ReScript },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "rescript-lang/rescript-vscode",
                asset_file = function(version)
                    return ("rescript-vscode-%s.vsix"):format(version)
                end,
            })
            .with_receipt()

        ctx:link_bin(
            "rescript-lsp",
            ctx:write_node_exec_wrapper(
                "rescript-lsp",
                path.concat {
                    "extension",
                    "server",
                    "out",
                    "server.js",
                }
            )
        )
    end,
}
