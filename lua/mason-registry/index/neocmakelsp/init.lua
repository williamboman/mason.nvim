local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "neocmakelsp",
    desc = [[CMake LSP implementation based on Tower and Tree-sitter]],
    homepage = "https://github.com/Decodetalkers/neocmakelsp",
    languages = { Pkg.Lang.CMake },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("neocmakelsp", { bin = { "neocmakelsp" } }),
}
