local Pkg = require "mason-core.package"
local composer = require "mason-core.managers.composer"

return Pkg.new {
    name = "pint",
    desc = [[Laravel Pint is an opinionated PHP code style fixer for minimalists.]],
    homepage = "https://laravel.com/docs/9.x/pint",
    languages = { Pkg.Lang.PHP },
    categories = { Pkg.Cat.Formatter },
    install = composer.packages {
        "laravel/pint",
        bin = {
            "pint",
        },
    },
}
