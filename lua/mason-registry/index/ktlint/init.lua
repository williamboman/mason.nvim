local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"
local path = require "mason-core.path"
local platform = require "mason-core.platform"

return Pkg.new {
    name = "ktlint",
    desc = [[An anti-bikeshedding Kotlin linter with built-in formatter]],
    homepage = "https://github.com/pinterest/ktlint",
    languages = { Pkg.Lang.Kotlin },
    categories = { Pkg.Cat.Formatter, Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "pinterest/ktlint",
                asset_file = "ktlint",
                out_file = "ktlint",
            })
            .with_receipt()

        platform.when {
            unix = function()
                std.chmod("+x", { "ktlint" })
                ctx:link_bin("ktlint", "ktlint")
            end,
            win = function()
                ctx:link_bin(
                    "ktlint",
                    ctx:write_shell_exec_wrapper(
                        "ktlint",
                        ("java -jar %q"):format(path.concat { ctx.package:get_install_path(), "ktlint" })
                    )
                )
            end,
        }
    end,
}
