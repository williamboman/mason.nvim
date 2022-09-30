local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local _ = require "mason-core.functional"
local path = require "mason-core.path"

return Pkg.new {
    name = "java-debug-adapter",
    desc = [[The debug server implementation for Java. It conforms to the debugger adapter protocol.]],
    homepage = "https://github.com/microsoft/java-debug",
    languages = { Pkg.Lang.Java },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "microsoft/vscode-java-debug",
                asset_file = _.format "vscjava.vscode-java-debug-%s.vsix",
            })
            .with_receipt()

        ctx.fs:rmrf(path.concat { "extension", "images" })
        ctx.fs:rmrf(path.concat { "extension", "dist" })
    end,
}
