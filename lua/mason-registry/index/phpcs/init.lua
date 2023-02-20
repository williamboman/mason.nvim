local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"
local platform = require "mason-core.platform"

return Pkg.new {
    name = "phpcs",
    desc = [[phpcs tokenizes PHP, JavaScript and CSS files to detect violations of a defined standard.]],
    homepage = "https://github.com/squizlabs/PHP_CodeSniffer",
    languages = { Pkg.Lang.PHP },
    categories = { Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "squizlabs/PHP_CodeSniffer",
                asset_file = "phpcs.phar",
                out_file = platform.is.win and "phpcs.phar" or "phpcs",
            })
            .with_receipt()
        platform.when {
            unix = function()
                std.chmod("+x", { "phpcs" })
                ctx:link_bin("phpcs", "phpcs")
            end,
            win = function()
                ctx:link_bin("phpcs", ctx:write_php_exec_wrapper("phpcs", "phpcs.phar"))
            end,
        }
    end,
}
