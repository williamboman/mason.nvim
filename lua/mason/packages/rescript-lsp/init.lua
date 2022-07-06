local Pkg = require "mason.core.package"
local github = require "mason.core.managers.github"

return Pkg.new {
    name = "rescript-lsp",
    desc = [[Language Server for ReScript.]],
    homepage = "https://github.com/rescript-lang/rescript-vscode",
    languages = { Pkg.Lang.ReScript },
    categories = { Pkg.Cat.LSP },
    ---@async
    install = function()
        github
            .unzip_release_file({
                repo = "rescript-lang/rescript-vscode",
                asset_file = function(version)
                    return ("rescript-vscode-%s.vsix"):format(version)
                end,
            })
            .with_receipt()
    end,
}
