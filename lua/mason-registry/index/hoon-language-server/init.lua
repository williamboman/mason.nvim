local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "hoon-language-server",
    desc = [[Language Server for Hoon. Middleware to translate between the Language Server Protocol and your Urbit.]],
    homepage = "https://github.com/urbit/hoon-language-server",
    languages = { Pkg.Lang.Hoon },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "@urbit/hoon-language-server", bin = { "hoon-language-server" } },
}
