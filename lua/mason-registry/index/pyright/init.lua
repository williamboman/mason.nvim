local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "pyright",
    desc = [[Static type checker for Python]],
    homepage = "https://github.com/microsoft/pyright",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "pyright", bin = { "pyright", "pyright-langserver" } },
}
