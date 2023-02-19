local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "awk-language-server",
    desc = [[Language Server for AWK]],
    homepage = "https://github.com/Beaglefoot/awk-language-server",
    languages = { Pkg.Lang.AWK },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "awk-language-server", bin = { "awk-language-server" } },
}
