local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

return Pkg.new {
    name = "php-cs-fixer",
    desc = _.dedent [[
        The PHP Coding Standards Fixer (PHP CS Fixer) tool fixes your code to follow standards; whether you want to
        follow PHP coding standards as defined in the PSR-1, PSR-2, etc., or other community driven ones like the
        Symfony one. You can also define your (team's) style through configuration.')
    ]],
    homepage = "https://github.com/FriendsOfPHP/PHP-CS-Fixer",
    languages = { Pkg.Lang.PHP },
    categories = { Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "FriendsOfPHP/PHP-CS-Fixer",
                asset_file = "php-cs-fixer.phar",
                out_file = "php-cs-fixer",
            })
            .with_receipt()
        std.chmod("+x", { "php-cs-fixer" })
        ctx:link_bin("php-cs-fixer", "php-cs-fixer")
    end,
}
