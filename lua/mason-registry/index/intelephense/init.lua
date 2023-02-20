local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "intelephense",
    desc = [[Professional PHP tooling for any Language Server Protocol capable editor.]],
    homepage = "https://intelephense.com",
    languages = { Pkg.Lang.PHP },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "intelephense", bin = { "intelephense" } },
}
