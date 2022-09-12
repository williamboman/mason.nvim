local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"
local platform = require "mason-core.platform"

return Pkg.new {
    name = "phpmd",
    desc = _.dedent [[
        PHPMD is a spin-off project of PHP Depend and aims to be a PHP equivalent of the well known Java tool PMD.
        PHPMD can be seen as an user friendly frontend application for the raw metrics stream measured by PHP Depend.
    ]],
    homepage = "https://github.com/phpmd/phpmd",
    languages = { Pkg.Lang.PHP },
    categories = { Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "phpmd/phpmd",
                asset_file = "phpmd.phar",
                out_file = platform.is.win and "phpmd.phar" or "phpmd",
            })
            .with_receipt()
        platform.when {
            unix = function()
                std.chmod("+x", { "phpmd" })
                ctx:link_bin("phpmd", "phpmd")
            end,
            win = function()
                ctx:link_bin("phpmd", ctx:write_php_exec_wrapper("phpmd", "phpmd.phar"))
            end,
        }
    end,
}
