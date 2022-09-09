local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"
local platform = require "mason-core.platform"
local path = require "mason-core.path"

return Pkg.new {
    name = "twigcs",
    desc = _.dedent [[
        The missing checkstyle for twig!
        Twigcs aims to be what phpcs is to php.
        It checks your codebase for violations on coding standards.
    ]],
    homepage = "https://github.com/friendsoftwig/twigcs",
    languages = { Pkg.Lang.Twig },
    categories = { Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "friendsoftwig/twigcs",
                asset_file = "twigcs.phar",
                out_file = platform.is.win and "twigcs.phar" or "twigcs",
            })
            .with_receipt()
        platform.when {
            unix = function()
                std.chmod("+x", { "twigcs" })
                ctx:link_bin("twigcs", "twigcs")
            end,
            win = function()
                ctx:link_bin(
                    "twigcs",
                    ctx:write_shell_exec_wrapper(
                        "twigcs",
                        ("php %q"):format(path.concat {
                            ctx.package:get_install_path(),
                            "twigcs.phar",
                        })
                    )
                )
            end,
        }
    end,
}
