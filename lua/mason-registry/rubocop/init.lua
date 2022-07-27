local Pkg = require "mason-core.package"
local gem = require "mason-core.managers.gem"

return Pkg.new {
    name = "rubocop",
    desc = [[The Ruby Linter/Formatter that Serves and Protects]],
    homepage = "https://rubocop.org",
    languages = { Pkg.Lang.Ruby },
    categories = { Pkg.Cat.Formatter, Pkg.Cat.Linter },
    install = gem.packages { "rubocop", bin = { "rubocop" } },
}
