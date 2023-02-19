local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "elm-language-server",
    desc = [[Language server implementation for Elm]],
    homepage = "https://github.com/elm-tooling/elm-language-server",
    languages = { Pkg.Lang.Elm },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "@elm-tooling/elm-language-server", bin = { "elm-language-server" } },
}
