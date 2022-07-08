local Pkg = require "mason-core.package"
local gem = require "mason-core.managers.gem"

return Pkg.new {
    name = "sorbet",
    desc = [[Sorbet is a fast, powerful type checker designed for Ruby.]],
    homepage = "https://sorbet.org/",
    languages = { Pkg.Lang.Ruby },
    categories = { Pkg.Cat.LSP },
    install = gem.packages { "sorbet", bin = { "srb" } },
}
