local Pkg = require "mason-core.package"
local gem = require "mason-core.managers.gem"

return Pkg.new {
    name = "erb-lint",
    desc = [[erb-lint is a tool to help lint your ERB or HTML files using the included linters or by writing your own]],
    homepage = "https://github.com/Shopify/erb-lint",
    languages = { Pkg.Lang.HTML, Pkg.Lang.Ruby },
    categories = { Pkg.Cat.Linter },
    install = gem.packages { "erb_lint", bin = { "erblint" } },
}
