local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "gradle-language-server",
    desc = [[Gradle language server.]],
    homepage = "https://github.com/microsoft/vscode-gradle",
    languages = { Pkg.Lang.Gradle },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                asset_file = _.format "vscjava.vscode-gradle-%s.vsix",
                repo = "microsoft/vscode-gradle",
            })
            .with_receipt()

        ctx.fs:rename(path.concat { "extension", "lib" }, "lib")
        ctx.fs:rmrf "extension"
        ctx:link_bin(
            "gradle-language-server",
            ctx:write_shell_exec_wrapper(
                "gradle-language-server",
                ("java -jar %q"):format(
                    path.concat { ctx.package:get_install_path(), "lib", "gradle-language-server.jar" }
                )
            )
        )
    end,
}
