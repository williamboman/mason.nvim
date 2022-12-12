local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"
local path = require "mason-core.path"

return Pkg.new {
    name = "kotlin-debug-adapter",
    desc = [[Kotlin/JVM debugging for any editor/IDE using the Debug Adapter Protocol]],
    homepage = "https://github.com/fwcd/kotlin-debug-adapter",
    languages = { Pkg.Lang.Kotlin },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "fwcd/kotlin-debug-adapter",
                asset_file = "adapter.zip",
            })
            .with_receipt()
        ctx:link_bin(
            "kotlin-debug-adapter",
            path.concat {
                "adapter",
                "bin",
                platform.is.win and "kotlin-debug-adapter.bat" or "kotlin-debug-adapter",
            }
        )
    end,
}
