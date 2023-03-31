local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "sqlfmt",
    desc = [[sqlfmt formats your dbt SQL files so you don't have to.]],
    homepage = "https://sqlfmt.com/#",
    languages = { Pkg.Lang.SQL },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "shandy-sqlfmt[jinjafmt]", bin = { "sqlfmt" } },
}
