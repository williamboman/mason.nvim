local Pkg = require "mason-core.package"
local composer = require "mason-core.managers.composer"

return Pkg.new {
    name = "psalm",
    desc = [[A static analysis tool for finding errors in PHP applications]],
    homepage = "https://psalm.dev/",
    languages = { Pkg.Lang.PHP },
    categories = { Pkg.Cat.LSP },
    install = composer.packages {
        "vimeo/psalm",
        bin = {
            "psalm",
            "psalm-language-server",
            "psalm-plugin",
            "psalm-refactor",
            "psalter",
        },
    },
}
