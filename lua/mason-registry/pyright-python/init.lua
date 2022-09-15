local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "pyright-python",
    desc = [[Python command line wrapper for pyright, a static type checker.]],
    homepage = "https://github.com/RobertCraigie/pyright-python",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.LSP },
    install = pip3.packages { "pyright", bin = { "pyright", "pyright-langserver" } },
}
