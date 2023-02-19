local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "foam-language-server",
    desc = [[A language server for OpenFOAM case files]],
    homepage = "https://github.com/FoamScience/foam-language-server",
    languages = { Pkg.Lang.OpenFOAM },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "foam-language-server", bin = { "foam-ls" } },
}
