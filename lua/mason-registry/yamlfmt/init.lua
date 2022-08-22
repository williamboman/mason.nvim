local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "yamlfmt",
    desc = [[yamlfmt is an extensible command line tool or library to format yaml files.]],
    homepage = "https://github.com/google/yamlfmt",
    categories = { Pkg.Cat.Formatter },
    languages = { Pkg.Lang.YAML },
    install = go.packages { "github.com/google/yamlfmt/cmd/yamlfmt", bin = { "yamlfmt" } },
}
