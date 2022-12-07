local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "neocmakelsp",
    desc = [[CMake lsp based on Tower and treesitter]],
    homepage = "https://github.com/Decodetalkers/neocmakelsp",
    languages = { Pkg.Lang.CMake },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("neocmakelsp", { bin = { "neocmakelsp" } }),
}
