local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"
local platform = require "mason-core.platform"
local path = require "mason-core.path"

return Pkg.new {
    name = "phpstan",
    desc = _.dedent [[
        PHP Static Analysis Tool - discover bugs in your code without running it!
    ]],
    homepage = "https://github.com/phpstan/phpstan",
    languages = { Pkg.Lang.PHP },
    categories = { Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "phpstan/phpstan",
                asset_file = "phpstan.phar",
                out_file = platform.is.win and "phpstan.phar" or "phpstan",
            })
            .with_receipt()
        platform.when {
            unix = function()
                std.chmod("+x", { "phpstan" })
                ctx:link_bin("phpstan", "phpstan")
            end,
            win = function()
                ctx:link_bin("phpstan", ctx:write_php_exec_wrapper("phpstan", "phpstan.phar"))
            end,
        }
    end,
}
