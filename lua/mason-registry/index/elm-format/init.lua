local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "elm-format",
    desc = [[elm-format formats Elm source code according to a standard set of rules based on the official Elm Style Guide]],
    homepage = "https://github.com/avh4/elm-format",
    languages = { Pkg.Lang.Elm },
    categories = { Pkg.Cat.Formatter },
    install = npm.packages { "elm-format", bin = { "elm-format" } },
}
