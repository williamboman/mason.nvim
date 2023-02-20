local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "emmet-ls",
    desc = [[Emmet support based on LSP.]],
    homepage = "https://github.com/aca/emmet-ls",
    languages = { Pkg.Lang.Emmet },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "emmet-ls", bin = { "emmet-ls" } },
}
