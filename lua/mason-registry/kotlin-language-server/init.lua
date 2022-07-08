local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"
local path = require "mason-core.path"

return Pkg.new {
    name = "kotlin-language-server",
    desc = [[Kotlin code completion, linting and more for any editor/IDE using the Language Server Protocol]],
    homepage = "https://github.com/fwcd/kotlin-language-server",
    languages = { Pkg.Lang.Kotlin },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "fwcd/kotlin-language-server",
                asset_file = "server.zip",
            })
            .with_receipt()
        ctx:link_bin(
            "kotlin-language-server",
            path.concat {
                "server",
                "bin",
                platform.is.win and "kotlin-language-server.bat" or "kotlin-language-server",
            }
        )
    end,
}
