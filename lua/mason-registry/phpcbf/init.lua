local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"
local platform = require "mason-core.platform"
local path = require "mason-core.path"

return Pkg.new {
    name = "phpcbf",
    desc = _.dedent [[
        PHP_CodeSniffer(phpcbf) automatically corrects coding standard violations that would be detected by PHP_CodeSniffer(phpcs).
    ]],
    homepage = "https://github.com/squizlabs/PHP_CodeSniffer",
    languages = { Pkg.Lang.PHP },
    categories = { Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "squizlabs/PHP_CodeSniffer",
                asset_file = "phpcbf.phar",
                out_file = platform.is.win and "phpcbf.phar" or "phpcbf",
            })
            .with_receipt()
        platform.when {
            unix = function()
                std.chmod("+x", { "phpcbf" })
                ctx:link_bin("phpcbf", "phpcbf")
            end,
            win = function()
                ctx:link_bin(
                    "phpcbf",
                    ctx:write_shell_exec_wrapper(
                        "phpcbf",
                        ("php %q"):format(path.concat {
                            ctx.package:get_install_path(),
                            "phpcbf.phar",
                        })
                    )
                )
            end,
        }
    end,
}
