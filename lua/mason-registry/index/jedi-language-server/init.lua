local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "jedi-language-server",
    desc = [[A Python language server exclusively for Jedi. If Jedi supports it well, this language server should too.]],
    homepage = "https://github.com/pappasam/jedi-language-server",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.LSP },
    install = pip3.packages { "jedi-language-server", bin = { "jedi-language-server" } },
}
