local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

return Pkg.new {
    name = "php-cs-fixer",
    desc = _.dedent [[
        Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP
        servers, linters, and formatters.
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
