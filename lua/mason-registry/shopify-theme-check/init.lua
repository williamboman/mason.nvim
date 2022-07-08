local Pkg = require "mason-core.package"
local gem = require "mason-core.managers.gem"

return Pkg.new {
    name = "shopify-theme-check",
    desc = [[The Ultimate Shopify Theme Linter]],
    homepage = "https://github.com/Shopify/theme-check",
    languages = { Pkg.Lang.Liquid },
    categories = { Pkg.Cat.LSP, Pkg.Cat.Linter },
    install = gem.packages { "theme-check", bin = { "theme-check-language-server" } },
}
