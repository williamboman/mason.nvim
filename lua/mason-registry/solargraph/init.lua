local Pkg = require "mason-core.package"
local gem = require "mason-core.managers.gem"

return Pkg.new {
    name = "solargraph",
    desc = [[Solargraph is a Ruby gem that provides intellisense features through the language server protocol.]],
    homepage = "https://solargraph.org",
    languages = { Pkg.Lang.Ruby },
    categories = { Pkg.Cat.LSP },
    install = gem.packages { "solargraph", bin = { "solargraph" } },
}
