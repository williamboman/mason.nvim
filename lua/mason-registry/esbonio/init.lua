local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "esbonio",
    desc = [[A Language Server for Sphinx projects.]],
    homepage = "https://pypi.org/project/esbonio/",
    languages = { Pkg.Lang.Sphinx },
    categories = { Pkg.Cat.LSP },
    install = pip3.packages { "esbonio", bin = { "esbonio" } },
}
